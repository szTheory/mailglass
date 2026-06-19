defmodule MailglassInbound.Internal.Operator.Records do
  @moduledoc false
  # Tenant-scoped read model for recent inbound-record browsing (IADM-01 seam).
  #
  # Mirrors `Mailglass.Operator.Deliveries`: a tenant is REQUIRED, but a blank or
  # missing tenant returns `[]` rather than raising (the design contract, tenant-required-or-
  # empty — the admin gateway must never surface a crash on an unset tenant).
  # Every query applies `Mailglass.Tenancy.scope/2` AND an explicit `tenant_id`
  # where-clause (T-48-01) — this is inbound's FIRST `Tenancy.scope/2` usage.
  # Reads go through the `MailglassInbound.Repo` host-repo facade, never a bare
  # repo. The optional outcome filter is cast against `ExecutionRun.__outcomes__/0`
  # and resolved via a subquery on the ExecutionRun lineage schema (Pitfall 7:
  # ExecutionRun, not the replay-run schema).
  #
  # The list projection carries each record's real disposition (WR-01): the
  # `outcome` + `mailbox` of its LATEST FRESH ExecutionRun, resolved via correlated
  # subqueries that REUSE the same `source: :fresh` + tenant-scoping shape the
  # `Detail` read-model uses (`latest_fresh_run/2`). A record with no fresh run
  # (or `:no_match`) yields `nil` mailbox — the admin list then reads "no match".
  # The subqueries are themselves tenant-scoped (explicit `tenant_id` where), so
  # the projection can never surface a foreign tenant's disposition.

  import Ecto.Query

  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Repo
  alias Mailglass.Tenancy

  @default_limit 50
  @max_limit 100
  @default_window_hours 168

  @type filters :: map() | keyword()

  @spec list_tenants(term(), keyword()) :: [%{id: String.t(), label: String.t()}]
  def list_tenants(context, _opts \\ []) do
    from(record in InboundRecord)
    |> where([record], not is_nil(record.tenant_id) and record.tenant_id != "")
    |> Tenancy.scope(context)
    |> group_by([record], record.tenant_id)
    |> order_by([record], asc: record.tenant_id)
    |> select([record], %{id: record.tenant_id, label: record.tenant_id})
    |> Repo.all()
  end

  @spec list_records(filters(), keyword()) :: [map()]
  def list_records(filters, opts \\ []) do
    normalized = normalize_filters(filters)

    case fetch_tenant_id(normalized) do
      {:ok, tenant_id} ->
        limit = limit_from(normalized, opts)

        from(record in InboundRecord, as: :rec)
        |> where([rec: record], record.tenant_id == ^tenant_id)
        |> maybe_filter_provider(normalized[:provider])
        |> maybe_filter_outcome(tenant_id, normalized[:outcome])
        |> maybe_filter_window(normalized[:window_hours] || normalized[:recent_window_hours])
        |> maybe_filter_search(normalized[:search])
        |> order_by([rec: record],
          desc: record.received_at,
          desc: record.inserted_at,
          desc: record.id
        )
        |> limit(^limit)
        |> select([rec: record], %{
          id: record.id,
          tenant_id: record.tenant_id,
          provider: record.provider,
          provider_message_id: record.provider_message_id,
          message_id: record.message_id,
          envelope_recipient: record.envelope_recipient,
          subject: record.subject,
          received_at: record.received_at,
          inserted_at: record.inserted_at,
          # IOPS-05 (the design contract): the column is the source of truth — select it
          # directly from the :rec binding (no subquery; the flag is set at INSERT).
          suppression_flagged: record.suppression_flagged,
          outcome: subquery(latest_fresh_run_field(tenant_id, :outcome)),
          mailbox: subquery(latest_fresh_run_field(tenant_id, :mailbox))
        })
        |> Tenancy.scope(tenant_id)
        |> Repo.all()
        |> Enum.map(&cast_projected_outcome/1)

      :blank ->
        []
    end
  end

  # Correlated subquery: the named `field` of the LATEST FRESH ExecutionRun for the
  # outer `:rec` record, tenant-scoped (T-48-01). Mirrors `Detail.latest_fresh_run/2`
  # ordering (newest `inserted_at` first). Returns nil when the record has no fresh
  # run — the admin list then renders "no match"/"Pending".
  defp latest_fresh_run_field(tenant_id, field) do
    from(run in ExecutionRun,
      where:
        run.tenant_id == ^tenant_id and
          run.source == :fresh and
          run.inbound_record_id == parent_as(:rec).id,
      order_by: [desc: run.inserted_at],
      limit: 1,
      select: field(run, ^field)
    )
  end

  # A correlated subquery over an `Ecto.Enum` column projects the RAW DB string
  # (e.g. "accept"), not the cast atom — the enum load-cast only runs for a column
  # selected directly from its own schema. Restore the atom against the closed
  # `ExecutionRun.__outcomes__/0` allow-list so the admin badge (which pattern-
  # matches `:accept`/`:no_match`/…) sees the same atom `Detail` returns. An
  # unrecognized value (or nil for a record with no fresh run) stays nil.
  defp cast_projected_outcome(%{outcome: outcome} = row) do
    %{row | outcome: cast_outcome_atom(outcome)}
  end

  defp cast_outcome_atom(outcome) when is_atom(outcome), do: outcome

  defp cast_outcome_atom(outcome) when is_binary(outcome) do
    atom = safe_existing_atom(outcome)
    if atom in ExecutionRun.__outcomes__(), do: atom, else: nil
  end

  defp cast_outcome_atom(_outcome), do: nil

  defp normalize_filters(filters) when is_list(filters), do: Map.new(filters)
  defp normalize_filters(filters) when is_map(filters), do: Map.new(filters)

  # Tenant-required-or-empty (the design contract). Unlike the outbound analog's
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
    where(query, [rec: record], record.provider == ^provider)
  end

  defp maybe_filter_provider(query, _provider), do: query

  # Case-insensitive substring search (WR-03) over the tenant-scoped field set the
  # FiltersForm advertises ("subject or recipient") plus the provider message id —
  # a sensible identifier an operator pastes from a provider dashboard. A blank or
  # missing search is a no-op (the full list comes back). The user input is
  # escaped for LIKE wildcards so a literal `%`/`_` cannot widen the match, then
  # bound as a parameter (never interpolated into SQL).
  defp maybe_filter_search(query, search) when is_binary(search) do
    case String.trim(search) do
      "" ->
        query

      trimmed ->
        pattern = "%" <> escape_like(trimmed) <> "%"

        where(
          query,
          [rec: record],
          ilike(record.subject, ^pattern) or
            ilike(record.envelope_recipient, ^pattern) or
            ilike(record.provider_message_id, ^pattern)
        )
    end
  end

  defp maybe_filter_search(query, _search), do: query

  # Neutralize LIKE/ILIKE metacharacters in operator-supplied search text so `%`
  # and `_` match literally. `\` is escaped first so the escape char itself is safe.
  defp escape_like(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end

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
    where(query, [rec: record], record.received_at >= ^since)
  end

  defp maybe_filter_window(query, window_hours)
       when is_integer(window_hours) and window_hours > 0 do
    since = DateTime.add(DateTime.utc_now(), -window_hours, :hour)
    where(query, [rec: record], record.received_at >= ^since)
  end

  defp maybe_filter_window(query, _window_hours), do: query
end
