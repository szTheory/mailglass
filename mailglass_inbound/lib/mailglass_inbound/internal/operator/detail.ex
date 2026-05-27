defmodule MailglassInbound.Internal.Operator.Detail do
  @moduledoc false
  # Tenant-scoped detail read model for one inbound record (IADM-01 seam).
  #
  # Reuses the query SHAPES in `MailglassInbound.Internal.Replay` (load_record,
  # load_evidence, latest_matched_fresh_run / latest_fresh_run) but ADDS a
  # `tenant_id` where-clause + `Mailglass.Tenancy.scope/2` to every query.
  # `Internal.Replay` loads by id ONLY (no tenant scope) on purpose — that is why
  # the admin tenant-gates BEFORE replay (the design contract); this read model is the tenant
  # gate. A blank/missing tenant, or a record that belongs to a different tenant,
  # returns `nil` (T-48-01, the design contract). Reads go through the `MailglassInbound.Repo`
  # facade and read the ExecutionRun lineage schema, never the replay-run schema
  # (Pitfall 7).

  import Ecto.Query

  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Repo
  alias Mailglass.Tenancy

  @matched_outcomes [:accept, :ignore, :reject, :bounce]

  @type filters :: map() | keyword()

  @type detail :: %{
          record: InboundRecord.t(),
          evidence: InboundEvidence.t() | nil,
          mailbox: String.t() | nil,
          outcome: ExecutionRun.outcome() | nil,
          outcome_reason: String.t() | nil
        }

  @spec fetch(filters(), keyword()) :: detail() | nil
  def fetch(filters, _opts \\ []) do
    normalized = normalize_filters(filters)

    with {:ok, tenant_id} <- fetch_tenant_id(normalized),
         {:ok, record_id} <- fetch_record_id(normalized),
         %InboundRecord{} = record <- load_record(tenant_id, record_id) do
      evidence = load_evidence(tenant_id, record_id)
      {mailbox, outcome, outcome_reason} = resolve_outcome(tenant_id, record_id)

      %{
        record: record,
        evidence: evidence,
        mailbox: mailbox,
        outcome: outcome,
        outcome_reason: outcome_reason
      }
    else
      _ -> nil
    end
  end

  defp normalize_filters(filters) when is_list(filters), do: Map.new(filters)
  defp normalize_filters(filters) when is_map(filters), do: Map.new(filters)

  defp fetch_tenant_id(%{tenant_id: tenant_id})
       when is_binary(tenant_id) and tenant_id != "",
       do: {:ok, tenant_id}

  defp fetch_tenant_id(_filters), do: :blank

  defp fetch_record_id(%{inbound_record_id: record_id})
       when is_binary(record_id) and record_id != "",
       do: {:ok, record_id}

  defp fetch_record_id(%{record_id: record_id})
       when is_binary(record_id) and record_id != "",
       do: {:ok, record_id}

  defp fetch_record_id(_filters), do: :blank

  # Mirrors Replay.load_record/2 but ADDS the tenant where-clause + Tenancy.scope.
  defp load_record(tenant_id, record_id) do
    InboundRecord
    |> where([record], record.id == ^record_id and record.tenant_id == ^tenant_id)
    |> limit(1)
    |> Tenancy.scope(tenant_id)
    |> Repo.one()
  end

  # Mirrors Replay.load_evidence/2 but ADDS the tenant where-clause + Tenancy.scope.
  defp load_evidence(tenant_id, record_id) do
    InboundEvidence
    |> where(
      [evidence],
      evidence.inbound_record_id == ^record_id and evidence.tenant_id == ^tenant_id
    )
    |> limit(1)
    |> Tenancy.scope(tenant_id)
    |> Repo.one()
  end

  # The matched mailbox + outcome from the latest FRESH ExecutionRun (mirrors
  # Replay.latest_matched_fresh_run/2, falling back to latest_fresh_run/2 so a
  # :no_match disposition is still surfaced). Tenant-scoped on every query.
  defp resolve_outcome(tenant_id, record_id) do
    case latest_matched_fresh_run(tenant_id, record_id) do
      %ExecutionRun{mailbox: mailbox, outcome: outcome, outcome_reason: reason} ->
        {mailbox, outcome, reason}

      nil ->
        case latest_fresh_run(tenant_id, record_id) do
          %ExecutionRun{mailbox: mailbox, outcome: outcome, outcome_reason: reason} ->
            {mailbox, outcome, reason}

          nil ->
            {nil, nil, nil}
        end
    end
  end

  defp latest_matched_fresh_run(tenant_id, record_id) do
    ExecutionRun
    |> where(
      [run],
      run.tenant_id == ^tenant_id and
        run.inbound_record_id == ^record_id and
        run.source == :fresh and
        not is_nil(run.mailbox) and
        run.outcome in ^@matched_outcomes
    )
    |> order_by([run], desc: run.inserted_at)
    |> limit(1)
    |> Tenancy.scope(tenant_id)
    |> Repo.one()
  end

  defp latest_fresh_run(tenant_id, record_id) do
    ExecutionRun
    |> where(
      [run],
      run.tenant_id == ^tenant_id and
        run.inbound_record_id == ^record_id and
        run.source == :fresh
    )
    |> order_by([run], desc: run.inserted_at)
    |> limit(1)
    |> Tenancy.scope(tenant_id)
    |> Repo.one()
  end
end
