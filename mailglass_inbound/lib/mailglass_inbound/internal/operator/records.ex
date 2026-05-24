defmodule MailglassInbound.Internal.Operator.Records do
  @moduledoc false
  # Tenant-scoped read model for recent inbound-record browsing (IADM-01 seam).
  #
  # Mirrors `Mailglass.Operator.Deliveries`: a tenant is REQUIRED, but a blank or
  # missing tenant returns `[]` rather than raising (D-48-04, tenant-required-or-
  # empty — the admin gateway must never surface a crash on an unset tenant).
  # Every query applies `Mailglass.Tenancy.scope/2` AND an explicit `tenant_id`
  # where-clause (T-48-01) — this is inbound's FIRST `Tenancy.scope/2` usage.
  # Reads go through the `MailglassInbound.Repo` host-repo facade, never a bare
  # repo. The optional outcome filter is cast against `ExecutionRun.__outcomes__/0`
  # and resolved via a subquery on the ExecutionRun lineage schema (Pitfall 7:
  # ExecutionRun, not the replay-run schema).

  import Ecto.Query

  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Repo
  alias Mailglass.Tenancy

  @default_limit 50
  @max_limit 100
  @default_window_hours 168

  @type filters :: map() | keyword()

  @spec list_records(filters(), keyword()) :: [map()]
  def list_records(filters, opts \\ []) do
    normalized = normalize_filters(filters)

    case fetch_tenant_id(normalized) do
      {:ok, tenant_id} ->
        limit = limit_from(normalized, opts)

        InboundRecord
        |> where([record], record.tenant_id == ^tenant_id)
        |> maybe_filter_provider(normalized[:provider])
        |> maybe_filter_outcome(tenant_id, normalized[:outcome])
        |> maybe_filter_window(normalized[:window_hours] || normalized[:recent_window_hours])
        |> order_by([record],
          desc: record.received_at,
          desc: record.inserted_at,
          desc: record.id
        )
        |> limit(^limit)
        |> select([record], %{
          id: record.id,
          tenant_id: record.tenant_id,
          provider: record.provider,
          provider_message_id: record.provider_message_id,
          message_id: record.message_id,
          envelope_recipient: record.envelope_recipient,
          subject: record.subject,
          received_at: record.received_at,
          inserted_at: record.inserted_at
        })
        |> Tenancy.scope(tenant_id)
        |> Repo.all()

      :blank ->
        []
    end
  end

  defp normalize_filters(filters) when is_list(filters), do: Map.new(filters)
  defp normalize_filters(filters) when is_map(filters), do: Map.new(filters)

  # Tenant-required-or-empty (D-48-04). Unlike the outbound analog's
  # `fetch_tenant_id!` (which raises), a blank/missing tenant returns `:blank` so
  # the caller can yield `[]` — the admin gateway must not crash on an unset
  # tenant context.
  defp fetch_tenant_id(%{tenant_id: tenant_id}) when is_binary(tenant_id) and tenant_id != "",
    do: {:ok, tenant_id}

  defp fetch_tenant_id(_filters), do: :blank

  defp limit_from(filters, opts) do
    filters
    |> Map.get(:limit, Keyword.get(opts, :limit, @default_limit))
    |> case do
      limit when is_integer(limit) and limit > 0 -> min(limit, @max_limit)
      _ -> @default_limit
    end
  end

  defp maybe_filter_provider(query, provider) when is_binary(provider) and provider != "" do
    where(query, [record], record.provider == ^provider)
  end

  defp maybe_filter_provider(query, _provider), do: query

  # Outcome filter: keep only records that have at least one execution run with
  # the requested outcome. The outcome value is cast against the closed
  # `ExecutionRun.__outcomes__/0` allow-list — an unknown value is IGNORED (the
  # filter is dropped) and never reaches SQL.
  defp maybe_filter_outcome(query, tenant_id, outcome) do
    case cast_outcome(outcome) do
      {:ok, outcome} ->
        matching_ids =
          from(run in ExecutionRun,
            where: run.tenant_id == ^tenant_id and run.outcome == ^outcome,
            select: run.inbound_record_id
          )

        where(query, [record], record.id in subquery(matching_ids))

      :ignore ->
        query
    end
  end

  defp cast_outcome(outcome) when is_atom(outcome) and not is_nil(outcome) do
    if outcome in ExecutionRun.__outcomes__(), do: {:ok, outcome}, else: :ignore
  end

  defp cast_outcome(outcome) when is_binary(outcome) and outcome != "" do
    cast_outcome(safe_existing_atom(outcome))
  end

  defp cast_outcome(_outcome), do: :ignore

  defp safe_existing_atom(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> nil
  end

  defp maybe_filter_window(query, nil) do
    since = DateTime.add(DateTime.utc_now(), -@default_window_hours, :hour)
    where(query, [record], record.received_at >= ^since)
  end

  defp maybe_filter_window(query, window_hours)
       when is_integer(window_hours) and window_hours > 0 do
    since = DateTime.add(DateTime.utc_now(), -window_hours, :hour)
    where(query, [record], record.received_at >= ^since)
  end

  defp maybe_filter_window(query, _window_hours), do: query
end
