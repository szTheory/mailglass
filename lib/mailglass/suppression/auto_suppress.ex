defmodule Mailglass.Suppression.AutoSuppress do
  @moduledoc """
  Centralized webhook-driven suppression projection helpers.
  """

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.Entry

  @source "webhook:auto_suppress"
  @conflict_target {:unsafe_fragment, "(tenant_id, address, scope, COALESCE(stream, ''))"}

  @spec apply(Ecto.Repo.t() | module(), term()) ::
          {:ok, Entry.t() | :inserted | :skip | :orphan_skipped | :no_event_row}
          | {:error, term()}
  def apply(repo, {:matched, %Delivery{} = delivery, %Event{} = event}) do
    start = System.monotonic_time(:microsecond)

    with {:ok, attrs} <- build_attrs(event, delivery),
         {:ok, entry} <- insert(repo, attrs) do
      maybe_emit_auto_added(start, delivery.tenant_id, entry)
      {:ok, :inserted}
    end
  end

  def apply(_repo, :no_event_row), do: {:ok, :no_event_row}
  def apply(_repo, {:ok, :no_event_row}), do: {:ok, :no_event_row}
  def apply(_repo, :orphan_skipped), do: {:ok, :orphan_skipped}
  def apply(_repo, {:ok, :orphan_skipped}), do: {:ok, :orphan_skipped}
  def apply(_repo, nil), do: {:ok, :skip}
  def apply(_repo, _other), do: {:ok, :skip}

  @spec build_attrs(Event.t(), Delivery.t()) :: {:ok, map() | :skip}
  def build_attrs(%Event{} = event, %Delivery{} = delivery) do
    case suppression_shape(event, delivery) do
      :skip ->
        {:ok, :skip}

      attrs ->
        {:ok,
         Map.merge(attrs, %{
           tenant_id: delivery.tenant_id,
           address: delivery.recipient,
           source: @source,
           metadata: metadata_for(event, delivery)
         })}
    end
  end

  @spec insert(Ecto.Repo.t() | module(), map() | :skip) :: {:ok, Entry.t() | :skip} | {:error, term()}
  def insert(_repo, :skip), do: {:ok, :skip}

  def insert(repo, attrs) when is_map(attrs) do
    attrs
    |> Entry.changeset()
    |> repo.insert(
      on_conflict: :nothing,
      conflict_target: @conflict_target,
      returning: true
    )
  end

  defp maybe_emit_auto_added(_start, _tenant_id, :skip), do: :ok

  defp maybe_emit_auto_added(start, tenant_id, %Entry{} = entry) do
    duration_us = System.monotonic_time(:microsecond) - start

    :telemetry.execute(
      [:mailglass, :suppression, :auto_added, :stop],
      %{duration_us: duration_us},
      %{
        tenant_id: tenant_id,
        scope: entry.scope,
        reason: entry.reason,
        source: entry.source,
        expires_at?: not is_nil(entry.expires_at)
      }
    )
  end

  defp suppression_shape(%Event{type: :complained}, _delivery) do
    %{scope: :address, reason: :complaint}
  end

  defp suppression_shape(%Event{type: :unsubscribed}, %Delivery{stream: stream}) when not is_nil(stream) do
    %{scope: :address_stream, stream: stream, reason: :unsubscribe}
  end

  defp suppression_shape(%Event{type: :bounced, reject_reason: :bounced}, _delivery) do
    %{scope: :address, reason: :hard_bounce}
  end

  defp suppression_shape(%Event{type: :deferred}, _delivery), do: :skip
  defp suppression_shape(%Event{}, _delivery), do: :skip

  defp metadata_for(event, delivery) do
    %{
      "delivery_id" => delivery.id,
      "event_id" => event.id,
      "event_type" => Atom.to_string(event.type),
      "provider" => Map.get(event.metadata || %{}, "provider"),
      "provider_event_id" => Map.get(event.metadata || %{}, "provider_event_id")
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
