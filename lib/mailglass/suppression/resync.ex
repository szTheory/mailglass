defmodule Mailglass.Suppression.Resync do
  @moduledoc """
  Tenant-scoped suppression rebuild from the append-only event ledger.
  """

  import Ecto.Query

  alias Mailglass.{Clock, Repo, SuppressionStore, Tenancy}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.AutoSuppress
  alias Mailglass.Suppression.Entry

  @default_window_days 90
  @default_page_size 100
  @max_page_size 100
  @conflict_target {:unsafe_fragment, "(tenant_id, address, scope, COALESCE(stream, ''))"}

  @type result :: %{
          scanned: non_neg_integer(),
          would_insert: non_neg_integer(),
          inserted: non_neg_integer(),
          existing: non_neg_integer(),
          dry_run: boolean(),
          tenant_id: String.t(),
          from: DateTime.t(),
          to: DateTime.t(),
          candidates: [map()]
        }

  @spec run(keyword()) :: {:ok, result()} | {:error, term()}
  def run(opts) when is_list(opts) do
    with {:ok, tenant_id} <- fetch_tenant_id(opts),
         {:ok, window} <- parse_window(opts),
         {:ok, totals} <- resync_pages(tenant_id, window, opts, initial_totals()) do
      {:ok,
       totals |> Map.drop([:missing_keys]) |> Map.merge(result_metadata(tenant_id, window, opts))}
    end
  end

  defp fetch_tenant_id(opts) do
    case Keyword.get(opts, :tenant_id) do
      tenant_id when is_binary(tenant_id) and tenant_id != "" -> {:ok, tenant_id}
      _ -> {:error, :tenant_id_required}
    end
  end

  defp parse_window(opts) do
    now = Clock.utc_now()
    default_from = DateTime.add(now, -@default_window_days, :day)

    with {:ok, from} <- parse_datetime(Keyword.get(opts, :from, default_from), :from),
         {:ok, to} <- parse_datetime(Keyword.get(opts, :to, now), :to),
         :ok <- validate_window(from, to) do
      {:ok, %{from: from, to: to}}
    end
  end

  defp parse_datetime(%DateTime{} = value, _field), do: {:ok, value}

  defp parse_datetime(value, field) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> {:ok, datetime}
      _ -> {:error, {:invalid_datetime, field, value}}
    end
  end

  defp validate_window(from, to) do
    case DateTime.compare(from, to) do
      :gt -> {:error, {:invalid_window, from, to}}
      _ -> :ok
    end
  end

  defp resync_pages(tenant_id, window, opts, totals, cursor \\ nil) do
    page = fetch_page(tenant_id, window, cursor, page_size(opts))

    case page do
      [] ->
        {:ok, totals}

      rows ->
        with {:ok, candidates} <- candidates_for_page(tenant_id, rows),
             {:ok, candidates} <- mark_existing(candidates, opts, totals.missing_keys),
             {:ok, inserted} <- maybe_apply(candidates, opts),
             {:ok, next_totals} <- accumulate(totals, candidates, inserted) do
          resync_pages(tenant_id, window, opts, next_totals, page_cursor(rows))
        end
    end
  end

  defp fetch_page(tenant_id, %{from: from, to: to}, cursor, size) do
    Event
    |> join(:inner, [event], delivery in Delivery, on: delivery.id == event.delivery_id)
    |> where([event, delivery], event.tenant_id == ^tenant_id and delivery.tenant_id == ^tenant_id)
    |> where([event], event.occurred_at >= ^from and event.occurred_at <= ^to)
    |> where([event], event.type in [:complained, :unsubscribed, :bounced])
    |> maybe_after(cursor)
    |> select([event, delivery], {event, delivery})
    |> order_by([event], asc: event.occurred_at, asc: event.id)
    |> limit(^size)
    |> Tenancy.scope(tenant_id)
    |> Repo.all()
  end

  defp maybe_after(query, nil), do: query

  defp maybe_after(query, {occurred_at, id}) do
    where(
      query,
      [event],
      event.occurred_at > ^occurred_at or
        (event.occurred_at == ^occurred_at and event.id > ^id)
    )
  end

  defp candidates_for_page(tenant_id, rows) do
    rows
    |> Enum.reduce([], fn {event, delivery}, candidates ->
      case AutoSuppress.build_attrs(event, delivery) do
        {:ok, :skip} ->
          candidates

        {:ok, attrs} ->
          candidate = %{event: event, attrs: attrs, tenant_id: tenant_id, status: nil}

          if Enum.any?(candidates, &(candidate_key(&1) == candidate_key(candidate))) do
            candidates
          else
            [candidate | candidates]
          end
      end
    end)
    |> Enum.reverse()
    |> then(&{:ok, &1})
  end

  defp mark_existing(candidates, opts, missing_keys) do
    keys = Enum.map(candidates, &lookup_key/1)

    results =
      SuppressionStore.check_many(
        suppression_store(),
        keys,
        batch_size: batch_size(opts)
      )

    candidates
    |> Enum.zip(results)
    |> Enum.reduce_while({:ok, []}, fn {candidate, result}, {:ok, marked} ->
      case status_for(candidate, result, missing_keys) do
        {:ok, status} -> {:cont, {:ok, [%{candidate | status: status} | marked]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> then(fn
      {:ok, marked} -> {:ok, Enum.reverse(marked)}
      error -> error
    end)
  end

  defp status_for(candidate, result, missing_keys) do
    if Map.has_key?(missing_keys, candidate_key(candidate)) do
      {:ok, :missing}
    else
      status_for_unseen(candidate, result)
    end
  end

  defp status_for_unseen(_candidate, :not_suppressed), do: {:ok, :missing}

  defp status_for_unseen(candidate, {:suppressed, entry}) do
    if same_suppression?(candidate.attrs, entry), do: {:ok, :existing}, else: {:ok, :missing}
  end

  defp status_for_unseen(_candidate, {:error, reason}), do: {:error, reason}
  defp status_for_unseen(_candidate, _result), do: {:error, :invalid_bulk_result}

  defp maybe_apply(candidates, opts) do
    if Keyword.get(opts, :dry_run, false), do: {:ok, 0}, else: apply_missing(candidates, opts)
  end

  defp apply_missing(candidates, opts) do
    candidates
    |> Enum.filter(&(&1.status == :missing))
    |> Enum.map(& &1.attrs)
    |> Enum.chunk_every(batch_size(opts))
    |> Enum.reduce_while({:ok, 0}, fn rows, {:ok, inserted} ->
      case upsert_chunk(rows, opts) do
        {:ok, count} -> {:cont, {:ok, inserted + count}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp upsert_chunk([], _opts), do: {:ok, 0}

  defp upsert_chunk(rows, opts) do
    default = fn chunk -> insert_chunk(chunk) end

    case Keyword.get(opts, :upsert_fun) do
      fun when is_function(fun, 2) -> fun.(rows, default)
      fun when is_function(fun, 1) -> fun.(rows)
      nil -> default.(rows)
    end
  end

  defp insert_chunk(rows) do
    rows = Enum.map(rows, &insert_row/1)

    Ecto.Multi.new()
    |> Ecto.Multi.insert_all(
      :suppressions,
      Entry,
      rows,
      Repo.multi_opts(on_conflict: :nothing, conflict_target: @conflict_target)
    )
    |> Repo.multi()
    |> case do
      {:ok, %{suppressions: {count, _entries}}} -> {:ok, count}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  defp insert_row(attrs) do
    attrs
    |> Map.put(:id, Ecto.UUID.generate())
    |> Map.put(:inserted_at, Clock.utc_now())
  end

  defp initial_totals do
    %{scanned: 0, would_insert: 0, inserted: 0, existing: 0, candidates: [], missing_keys: %{}}
  end

  defp accumulate(totals, candidates, inserted) do
    {:ok,
     %{
       totals
       | scanned: totals.scanned + length(candidates),
         would_insert: totals.would_insert + Enum.count(candidates, &(&1.status == :missing)),
         inserted: totals.inserted + inserted,
         existing: totals.existing + Enum.count(candidates, &(&1.status == :existing)),
         candidates: totals.candidates ++ Enum.map(candidates, &candidate_summary/1),
         missing_keys:
           Enum.reduce(candidates, totals.missing_keys, fn candidate, missing_keys ->
             if candidate.status == :missing,
               do: Map.put(missing_keys, candidate_key(candidate), true),
               else: missing_keys
           end)
     }}
  end

  defp candidate_summary(candidate) do
    %{
      address: candidate.attrs.address,
      scope: candidate.attrs.scope,
      stream: Map.get(candidate.attrs, :stream),
      reason: candidate.attrs.reason,
      event_type: candidate.event.type,
      status: candidate.status
    }
  end

  defp result_metadata(tenant_id, window, opts) do
    %{
      dry_run: Keyword.get(opts, :dry_run, false),
      tenant_id: tenant_id,
      from: window.from,
      to: window.to
    }
  end

  defp page_cursor(rows) do
    {event, _delivery} = List.last(rows)
    {event.occurred_at, event.id}
  end

  defp lookup_key(candidate) do
    %{
      tenant_id: candidate.tenant_id,
      address: candidate.attrs.address,
      stream: Map.get(candidate.attrs, :stream)
    }
  end

  defp candidate_key(candidate) do
    {candidate.tenant_id, String.downcase(candidate.attrs.address), candidate.attrs.scope,
     Map.get(candidate.attrs, :stream)}
  end

  defp same_suppression?(attrs, %Entry{} = entry) do
    String.downcase(attrs.address) == String.downcase(entry.address) and
      attrs.scope == entry.scope and Map.get(attrs, :stream) == entry.stream
  end

  defp same_suppression?(_attrs, _entry), do: false

  defp page_size(opts) do
    bounded_size(
      Keyword.get(
        opts,
        :page_size,
        Application.get_env(:mailglass, :suppression_resync_page_size, @default_page_size)
      )
    )
  end

  defp batch_size(opts), do: bounded_size(Keyword.get(opts, :batch_size, @default_page_size))

  defp bounded_size(size) when is_integer(size) and size > 0, do: min(size, @max_page_size)
  defp bounded_size(_size), do: @default_page_size

  defp suppression_store do
    Application.get_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.Ecto)
  end
end
