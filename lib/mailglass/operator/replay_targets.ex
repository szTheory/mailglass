defmodule Mailglass.Operator.ReplayTargets do
  @moduledoc """
  Tenant-scoped read model for resolving a delivery detail selection to
  exact replayable webhook rows.
  """

  import Ecto.Query

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.{Repo, Tenancy}

  @type filters :: map() | keyword()

  @spec list_delivery_targets(filters()) ::
          {:ok, map()} | {:error, :delivery_not_found}
  def list_delivery_targets(filters) do
    normalized = normalize_filters(filters)
    tenant_id = fetch_tenant_id!(normalized)
    delivery_id = fetch_delivery_id!(normalized)

    case fetch_delivery(tenant_id, delivery_id) do
      nil ->
        {:error, :delivery_not_found}

      %Delivery{} = delivery ->
        events = fetch_delivery_events(tenant_id, delivery_id)
        candidates = resolve_candidates(tenant_id, delivery, events)
        {:ok, outcome(delivery, events, candidates)}
    end
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

  defp fetch_delivery(tenant_id, delivery_id) do
    Delivery
    |> where([delivery], delivery.tenant_id == ^tenant_id and delivery.id == ^delivery_id)
    |> limit(1)
    |> Tenancy.scope(tenant_id)
    |> Repo.one()
  end

  defp fetch_delivery_events(tenant_id, delivery_id) do
    Event
    |> where([event], event.tenant_id == ^tenant_id and event.delivery_id == ^delivery_id)
    |> order_by([event], desc: event.occurred_at, desc: event.inserted_at, desc: event.id)
    |> select([event], %{
      id: event.id,
      type: event.type,
      metadata: event.metadata
    })
    |> Tenancy.scope(tenant_id)
    |> Repo.all()
  end

  defp resolve_candidates(tenant_id, %Delivery{} = delivery, events) do
    events
    |> Enum.map(&replay_ref/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.map(&load_candidate(tenant_id, delivery, &1))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq_by(& &1.webhook_event_id)
    |> Enum.sort_by(
      &{DateTime.to_unix(&1.webhook_timestamp, :microsecond), &1.webhook_event_id},
      :desc
    )
  end

  defp replay_ref(%{metadata: metadata}) when is_map(metadata) do
    cond do
      is_binary(metadata["webhook_event_id"]) and metadata["webhook_event_id"] != "" ->
        {:webhook_event_id, metadata["webhook_event_id"]}

      is_binary(metadata["webhook_provider_event_id"]) and
        metadata["webhook_provider_event_id"] != "" and
        is_binary(metadata["provider"]) and metadata["provider"] != "" ->
        {:webhook_provider_event_id, metadata["provider"], metadata["webhook_provider_event_id"]}

      true ->
        nil
    end
  end

  defp replay_ref(_event), do: nil

  defp load_candidate(tenant_id, %Delivery{} = delivery, {:webhook_event_id, webhook_event_id}) do
    query =
      from(webhook_event in "mailglass_webhook_events",
        where: field(webhook_event, :id) == type(^webhook_event_id, Ecto.UUID),
        select: %{
          id: field(webhook_event, :id),
          provider: field(webhook_event, :provider),
          provider_event_id: field(webhook_event, :provider_event_id),
          received_at: field(webhook_event, :received_at)
        },
        limit: 1
      )

    case Repo.one(Tenancy.scope(query, tenant_id)) do
      webhook_event when is_map(webhook_event) -> candidate(delivery, webhook_event)
      nil -> nil
    end
  end

  defp load_candidate(
         tenant_id,
         %Delivery{} = delivery,
         {:webhook_provider_event_id, provider, provider_event_id}
       ) do
    query =
      from(webhook_event in "mailglass_webhook_events",
        where:
          field(webhook_event, :provider) == ^provider and
            field(webhook_event, :provider_event_id) == ^provider_event_id,
        select: %{
          id: field(webhook_event, :id),
          provider: field(webhook_event, :provider),
          provider_event_id: field(webhook_event, :provider_event_id),
          received_at: field(webhook_event, :received_at)
        },
        limit: 1
      )

    case Repo.one(Tenancy.scope(query, tenant_id)) do
      webhook_event when is_map(webhook_event) -> candidate(delivery, webhook_event)
      nil -> nil
    end
  end

  defp candidate(%Delivery{} = delivery, webhook_event) when is_map(webhook_event) do
    %{
      webhook_event_id: normalize_uuid(webhook_event.id),
      provider: webhook_event.provider,
      webhook_timestamp: normalize_timestamp(webhook_event.received_at),
      provider_event_id: webhook_event.provider_event_id,
      delivery_id: delivery.id,
      delivery_provider_message_id: delivery.provider_message_id
    }
  end

  defp outcome(%Delivery{} = delivery, events, []) do
    %{
      status: :unavailable,
      reason: unavailable_reason(events),
      delivery_id: delivery.id,
      candidates: []
    }
  end

  defp outcome(%Delivery{} = delivery, _events, [candidate]) do
    %{
      status: :exact,
      delivery_id: delivery.id,
      candidate: candidate,
      candidates: [candidate]
    }
  end

  defp outcome(%Delivery{} = delivery, _events, candidates) do
    %{
      status: :ambiguous,
      reason: :multiple_candidates,
      delivery_id: delivery.id,
      candidates: candidates
    }
  end

  defp unavailable_reason([]), do: :no_delivery_events

  defp unavailable_reason(events) do
    if Enum.any?(events, &sendgrid_event?/1) do
      :historical_sendgrid_batch
    else
      :missing_replay_linkage
    end
  end

  defp sendgrid_event?(%{metadata: metadata}) when is_map(metadata),
    do: metadata["provider"] == "sendgrid"

  defp sendgrid_event?(_event), do: false

  defp normalize_uuid(value) when is_binary(value) and byte_size(value) == 16,
    do: Ecto.UUID.load!(value)

  defp normalize_uuid(value), do: value

  defp normalize_timestamp(%DateTime{} = timestamp), do: timestamp

  defp normalize_timestamp(%NaiveDateTime{} = timestamp),
    do: DateTime.from_naive!(timestamp, "Etc/UTC")
end
