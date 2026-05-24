defmodule MailglassInbound.Internal.Operator.Timeline do
  @moduledoc false
  # Tenant-scoped execution-lineage timeline for one inbound record (IADM-01 seam).
  #
  # Mirrors `MailglassInbound.Internal.Replay`'s `latest_fresh_run` query shape
  # but returns ALL execution runs (fresh AND replay) for a record, ordered
  # chronologically (`executed_at` ascending) for timeline display — it drops the
  # `limit: 1` and the `source == :fresh` filter. It reads the ExecutionRun
  # lineage schema, never the replay-run schema (Pitfall 7: the ExecutionRun row
  # is the one carrying `:no_match` + `source`). A blank/missing tenant returns
  # `[]` (D-48-04). Every query applies
  # `Mailglass.Tenancy.scope/2` + an explicit `tenant_id` where-clause (T-48-01)
  # and runs through the `MailglassInbound.Repo` facade.

  import Ecto.Query

  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.Repo
  alias Mailglass.Tenancy

  @type filters :: map() | keyword()

  @spec list_runs(filters(), keyword()) :: [map()]
  def list_runs(filters, _opts \\ []) do
    normalized = normalize_filters(filters)

    with {:ok, tenant_id} <- fetch_tenant_id(normalized),
         {:ok, record_id} <- fetch_record_id(normalized) do
      ExecutionRun
      |> where(
        [run],
        run.tenant_id == ^tenant_id and run.inbound_record_id == ^record_id
      )
      |> order_by([run],
        asc: run.executed_at,
        asc: run.inserted_at,
        asc: run.id
      )
      |> select([run], %{
        id: run.id,
        source: run.source,
        mailbox: run.mailbox,
        outcome: run.outcome,
        outcome_reason: run.outcome_reason,
        executed_at: run.executed_at,
        inserted_at: run.inserted_at
      })
      |> Tenancy.scope(tenant_id)
      |> Repo.all()
    else
      :blank -> []
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
end
