defmodule Mailglass.Operator.Deliveries do
  @moduledoc """
  Tenant-scoped read model for recent operator delivery browsing.
  """

  import Ecto.Query

  alias Mailglass.Outbound.Delivery
  alias Mailglass.{Repo, Tenancy}

  @default_limit 50
  @max_limit 100
  @default_window_hours 168

  @type filters :: map() | keyword()

  @spec list_recent_deliveries(filters(), keyword()) :: [map()]
  def list_recent_deliveries(filters, opts \\ []) do
    normalized = normalize_filters(filters)
    tenant_id = fetch_tenant_id!(normalized)
    limit = limit_from(normalized, opts)

    Delivery
    |> where([delivery], delivery.tenant_id == ^tenant_id)
    |> maybe_filter_provider(normalized[:provider])
    |> maybe_filter_status(normalized[:status])
    |> maybe_filter_event(normalized[:event] || normalized[:last_event_type])
    |> maybe_filter_window(normalized[:window_hours] || normalized[:recent_window_hours])
    |> order_by([delivery], desc: delivery.last_event_at, desc: delivery.inserted_at, desc: delivery.id)
    |> limit(^limit)
    |> select([delivery], %{
      id: delivery.id,
      tenant_id: delivery.tenant_id,
      recipient: delivery.recipient,
      provider: delivery.provider,
      status: delivery.status,
      last_event_type: delivery.last_event_type,
      last_event_at: delivery.last_event_at,
      inserted_at: delivery.inserted_at
    })
    |> Tenancy.scope(tenant_id)
    |> Repo.all()
  end

  defp normalize_filters(filters) when is_list(filters), do: Map.new(filters)
  defp normalize_filters(filters) when is_map(filters), do: Map.new(filters)

  defp fetch_tenant_id!(%{tenant_id: tenant_id}) when is_binary(tenant_id) and tenant_id != "", do: tenant_id
  defp fetch_tenant_id!(_filters), do: raise(ArgumentError, "tenant_id is required")

  defp limit_from(filters, opts) do
    filters
    |> Map.get(:limit, Keyword.get(opts, :limit, @default_limit))
    |> case do
      limit when is_integer(limit) and limit > 0 -> min(limit, @max_limit)
      _ -> @default_limit
    end
  end

  defp maybe_filter_provider(query, provider) when is_binary(provider) and provider != "" do
    where(query, [delivery], delivery.provider == ^provider)
  end

  defp maybe_filter_provider(query, _provider), do: query

  defp maybe_filter_status(query, status) when is_atom(status) and not is_nil(status) do
    where(query, [delivery], delivery.status == ^status)
  end

  defp maybe_filter_status(query, _status), do: query

  defp maybe_filter_event(query, event) when is_atom(event) and not is_nil(event) do
    where(query, [delivery], delivery.last_event_type == ^event)
  end

  defp maybe_filter_event(query, _event), do: query

  defp maybe_filter_window(query, nil) do
    since = DateTime.add(Mailglass.Clock.utc_now(), -@default_window_hours, :hour)
    where(query, [delivery], delivery.last_event_at >= ^since)
  end

  defp maybe_filter_window(query, window_hours) when is_integer(window_hours) and window_hours > 0 do
    since = DateTime.add(Mailglass.Clock.utc_now(), -window_hours, :hour)
    where(query, [delivery], delivery.last_event_at >= ^since)
  end

  defp maybe_filter_window(query, _window_hours), do: query
end
