defmodule MailglassAdmin.Operator.Timeline do
  @moduledoc """
  Read-only delivery timeline in chronological order.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.RepairState

  attr(:timeline_events, :list, required: true)
  attr(:highlight_event_id, :string, default: nil)
  attr(:read_state, :atom, default: :ready)
  attr(:selected_event, :map, default: nil)

  def timeline(assigns) do
    visible_events = Enum.take(assigns.timeline_events, 100)
    selected_event_id = get_in(assigns, [:selected_event, :event, :id])

    selected_event_visible? =
      assigns.selected_event && assigns.selected_event.status == :ready &&
        selected_event_id in Enum.map(visible_events, & &1.id)

    assigns =
      assigns
      |> assign(:visible_events, visible_events)
      |> assign(:has_more_events?, length(assigns.timeline_events) > 100)
      |> assign(:selected_event_visible?, selected_event_visible?)

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

      <%= if @read_state == :unavailable do %>
        <div role="status" data-testid="operator-timeline-unavailable" class="space-y-sm">
          <p class="text-body text-secondary">
            These Delivery events could not be loaded. Other available sections remain visible.
          </p>
          <button type="button" phx-click="retry_timeline" class="btn btn-ghost min-h-11">
            Retry details
          </button>
        </div>
      <% else %>
        <%= if @visible_events == [] do %>
        <p class="text-body text-secondary">
          No events are recorded for this Delivery.
        </p>
        <% else %>
        <ol class="space-y-lg">
          <%= for {event, index} <- Enum.with_index(@visible_events) do %>
            <li
              data-testid="operator-timeline-event"
              data-event-id={event.id}
              data-highlighted={
                if highlighted?(@highlight_event_id, event.id), do: "true", else: "false"
              }
              class="flex gap-sm"
            >
              <div class="mt-xs flex flex-col items-center">
                <span class={["h-3 w-3 rounded-full", event_dot_class(event.type)]}></span>
                <span :if={index < length(@visible_events) - 1} class="mt-sm h-full w-px bg-base-300">
                </span>
              </div>
              <div class={[
                "min-w-0 flex-1 rounded-box border bg-base-100 p-md",
                event_container_class(@highlight_event_id, event.id)
              ]}>
                <div class="flex flex-wrap items-start justify-between gap-sm">
                  <div class="space-y-xs">
                    <div class="flex flex-wrap items-center gap-sm">
                      <p class="text-body font-bold text-base-content">{event_label(event.type)}</p>
                      <Components.status_badge :if={event_badge(event.type)} status={event.type} size={:sm} />
                    </div>
                    <p class="text-label text-secondary">
                      {source_summary(event.type, event.metadata)}
                    </p>
                    <p class="mono min-w-0 break-all text-label text-secondary">{event.id}</p>
                    <Components.copy_button value={event.id} label="Copy event ID" />
                    <p :if={provider_reference(event)} class="mono min-w-0 break-all text-label text-secondary">
                      Provider Event ID: {provider_reference(event)}
                    </p>
                    <p :if={event.reject_reason} class="text-body text-secondary">
                      Reason: {label(event.reject_reason)}
                    </p>
                  </div>
                  <div class="min-w-0 text-label text-secondary">
                    <p>Recorded time</p>
                    <Components.timestamp at={event.occurred_at} />
                    <Components.copy_button
                      :if={event.occurred_at}
                      value={Components.timestamp_value(event.occurred_at)}
                      label="Copy recorded time"
                    />
                    <p :if={Map.get(event, :provider_occurred_at)} class="mt-xs break-words">
                      Provider occurrence time: {Map.get(event, :provider_occurred_at)}
                    </p>
                    <p :if={is_nil(event.occurred_at)} class="break-words">Unavailable</p>
                  </div>
                </div>
              </div>
            </li>
          <% end %>
        </ol>
        <p :if={@has_more_events?} class="mt-md text-body text-secondary" data-testid="operator-timeline-overflow">
          At least one additional Event is not shown in this timeline. The full history is not available in this view.
        </p>
        <% end %>
      <% end %>

      <section :if={@selected_event && not @selected_event_visible?} class="mt-lg border-t border-base-300 pt-lg" data-testid="operator-timeline-selected-event">
        <h4 class="text-body font-bold text-base-content">Selected event</h4>
        <%= if @selected_event.status == :ready and @selected_event.event &&
            @selected_event.event.id not in Enum.map(@visible_events, & &1.id) do %>
          <p class="mt-xs text-body text-secondary">
            This exact Event is outside the displayed timeline. It is shown here because the link selected it.
          </p>
          <div class="mt-sm min-w-0 space-y-xs rounded-box border border-base-300 bg-base-100 p-md">
            <p class="break-words font-bold">{event_label(@selected_event.event.type)}</p>
            <p class="break-words text-label text-secondary">
              {source_summary(@selected_event.event.type, @selected_event.event.metadata)}
            </p>
            <p class="mono min-w-0 break-all text-label text-secondary">{@selected_event.event.id}</p>
            <Components.copy_button value={@selected_event.event.id} label="Copy event ID" />
            <p :if={provider_reference(@selected_event.event)} class="mono min-w-0 break-all text-label text-secondary">
              Provider Event ID: {provider_reference(@selected_event.event)}
            </p>
            <p :if={@selected_event.event.reject_reason} class="break-words text-body text-secondary">
              Reason: {label(@selected_event.event.reject_reason)}
            </p>
            <p class="text-label text-secondary">Recorded time</p>
            <Components.timestamp at={@selected_event.event.occurred_at} />
            <Components.copy_button
              :if={@selected_event.event.occurred_at}
              value={Components.timestamp_value(@selected_event.event.occurred_at)}
              label="Copy recorded time"
            />
            <p :if={is_nil(@selected_event.event.occurred_at)} class="break-words">Unavailable</p>
            <p :if={provider_time(@selected_event.event)} class="break-words text-label text-secondary">
              Provider occurrence time: {provider_time(@selected_event.event)}
            </p>
          </div>
        <% else %>
          <p class="mt-xs text-body text-secondary" data-testid="operator-timeline-selected-event-unavailable">
            This Event could not be read for the selected Delivery. The displayed timeline is unchanged.
          </p>
        <% end %>
      </section>
    </Components.card>
    """
  end

  defp label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp event_label(type) do
    RepairState.replay_event_label(type) || RepairState.reconcile_event_label(type) ||
      if(
        type in [
          :queued,
          :sent,
          :delivered,
          :failed,
          :bounced,
          :deferred,
          :suppressed,
          :complained,
          :unsubscribed,
          :opened,
          :clicked
        ],
        do: label(type),
        else: "Unknown event"
      )
  end

  defp event_badge(type), do: RepairState.event_badge(type)

  defp source_summary(type, metadata) when is_map(metadata) do
    cond do
      type in [:webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed] ->
        replay_metadata_summary(type, metadata)

      type == :reconciled ->
        RepairState.reconcile_metadata_summary(metadata)

      true ->
        default_metadata_summary(metadata)
    end
  end

  defp source_summary(_type, _metadata), do: "Source unavailable"

  defp default_metadata_summary(metadata) do
    provider = Map.get(metadata, "provider") || Map.get(metadata, :provider)
    source = Map.get(metadata, "source") || Map.get(metadata, :source)

    [provider, source]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> case do
      [] -> "Source unavailable"
      values -> Enum.join(values, " · ")
    end
  end

  defp provider_time(event) do
    metadata = Map.get(event, :metadata, %{}) || %{}
    Map.get(metadata, "provider_occurred_at") || Map.get(metadata, :provider_occurred_at)
  end

  defp provider_reference(event) do
    metadata = Map.get(event, :metadata, %{}) || %{}
    Map.get(metadata, "provider_event_id") || Map.get(metadata, :provider_event_id)
  end

  defp replay_metadata_summary(:webhook_replay_requested, _metadata), do: "Replay audit · requested"
  defp replay_metadata_summary(:webhook_replay_failed, _metadata), do: "Replay audit · failed"

  defp replay_metadata_summary(:webhook_replay_succeeded, metadata) do
    case Map.get(metadata, "outcome") || Map.get(metadata, :outcome) do
      "replayed" -> "Replay audit · completed · new work"
      "noop" -> "Replay audit · completed · no change"
      _ -> "Replay audit · completed"
    end
  end

  defp event_container_class(highlight_event_id, event_id) when highlight_event_id == event_id,
    do: "border-primary ring-1 ring-primary/40"

  defp event_container_class(_highlight_event_id, _event_id), do: "border-base-300"

  defp highlighted?(highlight_event_id, event_id), do: highlight_event_id == event_id

  defp event_dot_class(:webhook_replay_failed), do: "bg-error"

  defp event_dot_class(type) when type in [:webhook_replay_requested, :webhook_replay_succeeded],
    do: "bg-warning"

  defp event_dot_class(:reconciled), do: "bg-accent"
  defp event_dot_class(_type), do: "bg-primary"
end
