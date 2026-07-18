defmodule MailglassAdmin.Operator.Timeline do
  @moduledoc """
  Read-only delivery timeline in chronological order.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.RepairState

  attr(:timeline_events, :list, required: true)
  attr(:highlight_event_id, :string, default: nil)

  def timeline(assigns) do
    ~H"""
    <Components.card
      padding={:lg}
      data-testid="operator-timeline"
      data-group-card="operator-timeline"
    >
      <div class="mb-md flex items-center justify-between gap-sm">
        <h3 class="text-body font-bold text-base-content">Event timeline</h3>
        <span class="text-label text-secondary">Chronological order</span>
      </div>

      <%= if @timeline_events == [] do %>
        <p class="text-body text-secondary">
          No delivery events have been recorded for this item yet.
        </p>
      <% else %>
        <% last_index = length(@timeline_events) - 1 %>
        <ol class="motion-timeline -mb-lg">
          <%= for {event, index} <- Enum.with_index(@timeline_events) do %>
            <li
              data-testid="operator-timeline-event"
              data-event-id={event.id}
              data-highlighted={
                if highlighted?(@highlight_event_id, event.id), do: "true", else: "false"
              }
            >
              <div class="relative pb-lg">
                <%!-- Continuous rail: the connector lives in this padding-inclusive
                      box so h-full spans the gap down to the next dot. Omitted on
                      the last (most recent) event. --%>
                <span
                  :if={index < last_index}
                  aria-hidden="true"
                  class="absolute left-1.5 top-4 -ml-px h-full w-px bg-base-300"
                >
                </span>
                <div class="relative flex gap-md">
                  <span class={[
                    "z-10 mt-1.5 h-3 w-3 shrink-0 rounded-full border-2 border-base-100",
                    dot_class(event.type),
                    latest_ring_class(event.type, index == last_index)
                  ]}>
                  </span>
                  <div class={[
                    "min-w-0 flex-1 rounded-box border bg-base-100 p-md",
                    event_container_class(@highlight_event_id, event.id)
                  ]}>
                    <div class="flex flex-wrap items-start justify-between gap-sm">
                      <div class="space-y-xs">
                        <div class="flex flex-wrap items-center gap-sm">
                          <p class="text-body font-bold text-base-content">{event_label(event.type)}</p>
                          <Components.status_badge :if={event_badge(event.type)} status={event.type} size={:sm} />
                          <span
                            :if={index == last_index}
                            class="text-label font-bold uppercase text-secondary"
                          >
                            Latest
                          </span>
                        </div>
                        <p class="text-label text-secondary">
                          {metadata_summary(event.type, event.metadata)}
                        </p>
                        <p class="mono text-label text-secondary">{event.id}</p>
                        <p :if={event.reject_reason} class="text-body text-secondary">
                          Reason: {label(event.reject_reason)}
                        </p>
                      </div>
                      <p class="text-label text-secondary"><Components.timestamp at={event.occurred_at} /></p>
                    </div>
                  </div>
                </div>
              </div>
            </li>
          <% end %>
        </ol>
      <% end %>
    </Components.card>
    """
  end

  defp label(nil), do: "Unknown"

  defp label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp event_label(type) do
    RepairState.replay_event_label(type) || RepairState.reconcile_event_label(type) || label(type)
  end

  defp event_badge(type), do: RepairState.event_badge(type)

  defp metadata_summary(type, metadata) when is_map(metadata) do
    cond do
      replay_metadata?(metadata) ->
        replay_metadata_summary(metadata)

      type == :reconciled ->
        RepairState.reconcile_metadata_summary(metadata)

      true ->
        default_metadata_summary(metadata)
    end
  end

  defp metadata_summary(_type, _metadata), do: "mailglass ledger"

  defp default_metadata_summary(metadata) do
    provider = Map.get(metadata, "provider") || Map.get(metadata, :provider)
    source = Map.get(metadata, "source") || Map.get(metadata, :source)

    [provider, source]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> case do
      [] -> "mailglass ledger"
      values -> Enum.join(values, " · ")
    end
  end

  defp replay_metadata_summary(metadata) do
    metadata
    |> Map.put_new("outcome_label", inferred_outcome_label(metadata))
    |> RepairState.replay_metadata_summary()
  end

  defp event_container_class(highlight_event_id, event_id) when highlight_event_id == event_id,
    do: "border-primary ring-1 ring-primary/40"

  defp event_container_class(_highlight_event_id, _event_id), do: "border-base-300"

  defp highlighted?(highlight_event_id, event_id), do: highlight_event_id == event_id

  defp replay_metadata?(metadata), do: is_binary(Map.get(metadata, "webhook_event_id"))

  defp inferred_outcome_label(metadata) do
    cond do
      Map.has_key?(metadata, "failure_reason") or Map.has_key?(metadata, :failure_reason) ->
        "failed"

      Map.has_key?(metadata, "outcome") or Map.has_key?(metadata, :outcome) ->
        "completed"

      true ->
        "requested"
    end
  end

  # Dot color derives from the SAME classification as the status badge
  # (`Components.status_tone/1`), so the dot and the badge on a row always agree.
  defp dot_class(type) do
    case Components.status_tone(type) do
      :success -> "bg-success"
      :error -> "bg-error"
      :warning -> "bg-warning"
      :accent -> "bg-primary"
      :neutral -> "bg-secondary"
    end
  end

  # The most recent event carries a tone-matched halo so "where things stand now"
  # reads at a glance (and a single-event timeline reads as intentional, not orphaned).
  defp latest_ring_class(_type, false), do: nil

  defp latest_ring_class(type, true) do
    case Components.status_tone(type) do
      :success -> "ring-2 ring-success/40"
      :error -> "ring-2 ring-error/40"
      :warning -> "ring-2 ring-warning/40"
      :accent -> "ring-2 ring-primary/40"
      :neutral -> "ring-2 ring-secondary/40"
    end
  end
end
