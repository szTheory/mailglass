defmodule Mailglass.Operator.Timeline do
  @moduledoc """
  Tenant-scoped read model for operator delivery event timelines.
  """

  import Ecto.Query

  alias Mailglass.Events.Event
  alias Mailglass.{Repo, Tenancy}

  @default_limit 100
  @max_limit 250

  @type filters :: map() | keyword()

  @spec list_delivery_events(filters(), keyword()) :: [map()]
  def list_delivery_events(filters, opts \\ []) do
    normalized = normalize_filters(filters)
    tenant_id = fetch_tenant_id!(normalized)
    delivery_id = fetch_delivery_id!(normalized)
    limit = limit_from(normalized, opts)

    Event
    |> where([event], event.tenant_id == ^tenant_id and event.delivery_id == ^delivery_id)
    |> order_by([event], asc: event.occurred_at, asc: event.inserted_at, asc: event.id)
    |> limit(^limit)
    |> select([event], %{
      id: event.id,
      tenant_id: event.tenant_id,
      delivery_id: event.delivery_id,
      type: event.type,
      occurred_at: event.occurred_at,
      reject_reason: event.reject_reason,
      metadata: event.metadata,
      normalized_payload: event.normalized_payload,
      inserted_at: event.inserted_at
    })
    |> Tenancy.scope(tenant_id)
    |> Repo.all()
  end

  defp normalize_filters(filters) when is_list(filters), do: Map.new(filters)
  defp normalize_filters(filters) when is_map(filters), do: Map.new(filters)

  defp fetch_tenant_id!(%{tenant_id: tenant_id}) when is_binary(tenant_id) and tenant_id != "", do: tenant_id
  defp fetch_tenant_id!(_filters), do: raise(ArgumentError, "tenant_id is required")

  defp fetch_delivery_id!(%{delivery_id: delivery_id})
       when is_binary(delivery_id) and delivery_id != "",
       do: delivery_id

  defp fetch_delivery_id!(_filters), do: raise(ArgumentError, "delivery_id is required")

  defp limit_from(filters, opts) do
    filters
    |> Map.get(:limit, Keyword.get(opts, :limit, @default_limit))
    |> case do
      limit when is_integer(limit) and limit > 0 -> min(limit, @max_limit)
      _ -> @default_limit
    end
  end
end
