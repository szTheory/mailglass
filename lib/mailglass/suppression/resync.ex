defmodule Mailglass.Suppression.Resync do
  @moduledoc """
  Tenant-scoped suppression rebuild from the append-only event ledger.
  """

  import Ecto.Query

  alias Mailglass.{Clock, Repo, Tenancy}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.AutoSuppress
  alias Mailglass.Suppression.Entry

  @default_window_days 90

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
         candidates <- select_candidates(tenant_id, window),
         {:ok, inserted} <- maybe_apply(candidates, Keyword.get(opts, :dry_run, false)) do
      would_insert = count_status(candidates, :missing)
      existing = count_status(candidates, :existing)

      {:ok,
       %{
         scanned: length(candidates),
         would_insert: would_insert,
         inserted: inserted,
         existing: existing,
         dry_run: Keyword.get(opts, :dry_run, false),
         tenant_id: tenant_id,
         from: window.from,
         to: window.to,
         candidates: Enum.map(candidates, &candidate_summary/1)
       }}
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

  defp select_candidates(tenant_id, %{from: from, to: to}) do
    Event
    |> join(:inner, [event], delivery in Delivery, on: delivery.id == event.delivery_id)
    |> where([event, delivery], event.tenant_id == ^tenant_id and delivery.tenant_id == ^tenant_id)
    |> where([event], event.occurred_at >= ^from and event.occurred_at <= ^to)
    |> where([event], event.type in [:complained, :unsubscribed, :bounced])
    |> select([event, delivery], {event, delivery})
    |> order_by([event], asc: event.occurred_at, asc: event.id)
    |> Tenancy.scope(tenant_id)
    |> Repo.all()
    |> Enum.flat_map(fn {event, delivery} ->
      case AutoSuppress.build_attrs(event, delivery) do
        {:ok, :skip} ->
          []

        {:ok, attrs} ->
          [
            %{
              event: event,
              delivery: delivery,
              attrs: attrs,
              status: existing_status(tenant_id, attrs)
            }
          ]
      end
    end)
  end

  defp maybe_apply(_candidates, true), do: {:ok, 0}

  defp maybe_apply(candidates, false) do
    candidates
    |> Enum.filter(&(&1.status == :missing))
    |> Enum.reduce_while({:ok, 0}, fn candidate, {:ok, inserted} ->
      case AutoSuppress.insert(Repo, candidate.attrs) do
        {:ok, _entry} -> {:cont, {:ok, inserted + 1}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp existing_status(tenant_id, attrs) do
    query =
      from(entry in Entry,
        where:
          entry.tenant_id == ^tenant_id and
            entry.address == ^attrs.address and
            entry.scope == ^attrs.scope,
        limit: 1
      )
      |> maybe_where_stream(Map.get(attrs, :stream))

    case Repo.one(Tenancy.scope(query, tenant_id)) do
      nil -> :missing
      %Entry{} -> :existing
    end
  end

  defp maybe_where_stream(query, nil) do
    where(query, [entry], is_nil(entry.stream))
  end

  defp maybe_where_stream(query, stream) do
    where(query, [entry], entry.stream == ^stream)
  end

  defp count_status(candidates, status) do
    Enum.count(candidates, &(&1.status == status))
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
end
