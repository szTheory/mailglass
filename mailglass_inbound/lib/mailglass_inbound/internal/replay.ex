defmodule MailglassInbound.Internal.Replay do
  @moduledoc false

  import Ecto.Query

  alias Mailglass.Tenancy
  alias MailglassInbound.Execution
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.InboundRecord

  @matched_outcomes [:accept, :ignore, :reject, :bounce]

  defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]

  # T-49-17 cross-tenant replay guard. Every load (record, evidence, execution
  # runs) is scoped by tenant via an explicit `tenant_id` where-clause AND
  # `Mailglass.Tenancy.scope/2` — the same defence-in-depth pattern as
  # `Internal.Operator.Records` (T-48-01). `:tenant_id` is REQUIRED; a missing or
  # blank tenant is a programmer error and raises (fail-loud, mirroring
  # `Mailglass.Tenancy.tenant_id!/0`). Callers — the replay mix task and the admin
  # replay gateway — MUST supply the tenant that owns the record. A foreign-tenant
  # id resolves to nil → `{:error, :not_found}`, never a cross-tenant replay.
  @spec replay(Ecto.UUID.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def replay(inbound_record_id, opts \\ []) when is_binary(inbound_record_id) and is_list(opts) do
    repo = Keyword.get(opts, :repo, MailglassInbound.Repo)
    execution = Keyword.get(opts, :execution, Execution)
    tenant_id = require_tenant!(opts)

    with %InboundRecord{} = record <- load_record(repo, inbound_record_id, tenant_id),
         %InboundEvidence{} = evidence <- load_evidence(repo, inbound_record_id, tenant_id),
         {:ok, mailbox} <- resolve_mailbox(repo, inbound_record_id, tenant_id, opts),
         payload = replay_payload(record, evidence, mailbox),
         {:ok, result} <- execution.execute(payload, source: :replay) do
      {:ok, result}
    else
      nil -> {:error, :not_found}
      {:error, _reason} = error -> error
    end
  end

  defp require_tenant!(opts) do
    case Keyword.get(opts, :tenant_id) do
      tenant_id when is_binary(tenant_id) and tenant_id != "" ->
        tenant_id

      _ ->
        raise ArgumentError,
              "MailglassInbound.Internal.Replay.replay/2 requires a non-empty :tenant_id " <>
                "option — replay loads are tenant-scoped to prevent cross-tenant replay (T-49-17)."
    end
  end

  defp load_record(repo, inbound_record_id, tenant_id) do
    from(record in InboundRecord,
      where: record.id == ^inbound_record_id and record.tenant_id == ^tenant_id,
      limit: 1
    )
    |> Tenancy.scope(tenant_id)
    |> repo.one(schema_opts())
  end

  defp load_evidence(repo, inbound_record_id, tenant_id) do
    from(evidence in InboundEvidence,
      where:
        evidence.inbound_record_id == ^inbound_record_id and
          evidence.tenant_id == ^tenant_id,
      limit: 1
    )
    |> Tenancy.scope(tenant_id)
    |> repo.one(schema_opts())
  end

  defp resolve_mailbox(repo, inbound_record_id, tenant_id, opts) do
    case latest_matched_fresh_run(repo, inbound_record_id, tenant_id) do
      %ExecutionRun{mailbox: mailbox} when is_binary(mailbox) and mailbox != "" ->
        resolve_mailbox_module(mailbox, opts)

      nil ->
        case latest_fresh_run(repo, inbound_record_id, tenant_id) do
          %ExecutionRun{outcome: :no_match} ->
            {:error, {:replay_mailbox_missing, %{reason: :no_prior_match}}}

          nil ->
            {:error, {:replay_mailbox_missing, %{reason: :execution_history_missing}}}

          _other ->
            {:error, {:replay_mailbox_missing, %{reason: :no_prior_match}}}
        end
    end
  end

  defp resolve_mailbox_module(mailbox, opts) do
    case Execution.resolve_mailbox(mailbox, opts) do
      {:ok, module} ->
        {:ok, module}

      {:error, :unavailable} ->
        {:error, {:replay_mailbox_missing, %{reason: :authority_unavailable}}}

      {:error, _reason} ->
        {:error, {:replay_mailbox_missing, %{reason: :invalid_mailbox}}}
    end
  end

  defp latest_matched_fresh_run(repo, inbound_record_id, tenant_id) do
    from(run in ExecutionRun,
      where:
        run.inbound_record_id == ^inbound_record_id and
          run.tenant_id == ^tenant_id and
          run.source == :fresh and
          not is_nil(run.mailbox) and
          run.outcome in ^@matched_outcomes,
      order_by: [desc: run.inserted_at],
      limit: 1
    )
    |> Tenancy.scope(tenant_id)
    |> repo.one(schema_opts())
  end

  defp latest_fresh_run(repo, inbound_record_id, tenant_id) do
    from(run in ExecutionRun,
      where:
        run.inbound_record_id == ^inbound_record_id and
          run.tenant_id == ^tenant_id and
          run.source == :fresh,
      order_by: [desc: run.inserted_at],
      limit: 1
    )
    |> Tenancy.scope(tenant_id)
    |> repo.one(schema_opts())
  end

  defp replay_payload(record, evidence, mailbox) do
    message = Execution.message_from_record(record)

    %{
      status: :inserted,
      message: message,
      inbound_record: record,
      inbound_evidence: evidence,
      route: %{status: :matched, mailbox: mailbox}
    }
  end
end
