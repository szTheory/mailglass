defmodule Mailglass.Outbound.PayloadPruner do
  @moduledoc """
  Bounded, explicit-tenant payload content pruning.

  Each call transitions at most one deterministic batch of expired
  content-bearing rows into audit-preserving `:expired` tombstones. It never
  sweeps tenants, deletes rows, or treats a dispatching claim as retry-safe.
  """

  import Ecto.Query

  alias Mailglass.{Clock, Config, Repo, Tenancy}
  alias Mailglass.Outbound.Payload

  @prunable_states [:terminal, :discarded, :abandoned, :uncertain, :legacy]

  @spec prune(keyword()) :: {:ok, non_neg_integer()} | {:error, :tenant_required}
  def prune(opts) when is_list(opts) do
    case Keyword.get(opts, :tenant_id) do
      tenant_id when is_binary(tenant_id) ->
        if byte_size(String.trim(tenant_id)) > 0,
          do: prune_tenant(tenant_id),
          else: {:error, :tenant_required}

      _ ->
        {:error, :tenant_required}
    end
  end

  def prune(_opts), do: {:error, :tenant_required}

  defp prune_tenant(tenant_id) do
    now = Clock.utc_now()
    batch_size = Config.outbound_payload_retention()[:prune_batch_size]

    query =
      from(p in Payload,
        where:
          p.tenant_id == ^tenant_id and p.lifecycle_state in ^@prunable_states and
            not is_nil(p.envelope) and not is_nil(p.expires_at) and p.expires_at <= ^now,
        order_by: [asc: p.expires_at, asc: p.id],
        limit: ^batch_size,
        select: {p.id, p.lifecycle_state}
      )
      |> Tenancy.scope(tenant_id)

    payloads = Repo.all(query)

    multi =
      Enum.reduce(payloads, Ecto.Multi.new(), fn {id, state}, multi ->
        cas =
          from(p in Payload,
            where:
              p.id == ^id and p.tenant_id == ^tenant_id and p.lifecycle_state == ^state and
                not is_nil(p.envelope),
            update: [
              set: [lifecycle_state: :expired, envelope: nil, scrubbed_at: ^now, claimed_at: nil]
            ]
          )
          |> Tenancy.scope(tenant_id)

        Ecto.Multi.update_all(multi, {:expire, id}, cas, [], Repo.multi_opts())
      end)

    case Repo.multi(multi) do
      {:ok, changes} ->
        {:ok, Enum.count(changes, fn {_key, {count, _}} -> count == 1 end)}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end
end
