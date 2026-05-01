defmodule Mailglass.Operator.ReplayHistory do
  @moduledoc """
  Tenant-scoped read model for replay audit history on one delivery.
  """

  import Ecto.Query

  alias Mailglass.Events.Event
  alias Mailglass.{Repo, Tenancy}

  @replay_types [:webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed]

  @type filters :: map() | keyword()

  @spec list_delivery_replay_history(filters()) :: [map()]
  def list_delivery_replay_history(filters) do
    normalized = normalize_filters(filters)
    tenant_id = fetch_tenant_id!(normalized)
    delivery_id = fetch_delivery_id!(normalized)

    Event
    |> where([event], event.tenant_id == ^tenant_id and event.delivery_id == ^delivery_id)
    |> where([event], event.type in ^@replay_types)
    |> order_by([event], asc: event.occurred_at, asc: event.inserted_at, asc: event.id)
    |> select([event], %{
      id: event.id,
      tenant_id: event.tenant_id,
      delivery_id: event.delivery_id,
      type: event.type,
      occurred_at: event.occurred_at,
      inserted_at: event.inserted_at,
      actor_id: fragment("?->>'actor_id'", event.metadata),
      webhook_event_id: fragment("?->>'webhook_event_id'", event.metadata),
      webhook_provider_event_id: fragment("?->>'webhook_provider_event_id'", event.metadata),
      provider: fragment("?->>'provider'", event.metadata),
      outcome: fragment("?->>'outcome'", event.metadata),
      failure_reason: fragment("?->>'failure_reason'", event.metadata),
      metadata: event.metadata
    })
    |> Tenancy.scope(tenant_id)
    |> Repo.all()
  end

  defp normalize_filters(filters) when is_list(filters), do: Map.new(filters)
  defp normalize_filters(filters) when is_map(filters), do: Map.new(filters)

  defp fetch_tenant_id!(%{tenant_id: tenant_id}) when is_binary(tenant_id) and tenant_id != "",
    do: tenant_id

  defp fetch_tenant_id!(_filters), do: raise(ArgumentError, "tenant_id is required")

  defp fetch_delivery_id!(%{delivery_id: delivery_id})
       when is_binary(delivery_id) and delivery_id != "",
       do: delivery_id

  defp fetch_delivery_id!(_filters), do: raise(ArgumentError, "delivery_id is required")
end
