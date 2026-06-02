defmodule MailglassAdmin.Operator.Timeline do
  @moduledoc """
  Read-only delivery timeline in chronological order.
  """

  use Phoenix.Component

  alias MailglassAdmin.Operator.RepairState

  attr(:timeline_events, :list, required: true)
  attr(:highlight_event_id, :string, default: nil)

  def timeline(assigns) do
    ~H"""
    <article
      data-testid="operator-timeline"
      class="card rounded-box border border-base-300 bg-base-200 p-6"
    >
      <div class="mb-4 flex items-center justify-between gap-3">
        <h3 class="text-base font-bold text-base-content">Event timeline</h3>
        <span class="text-xs text-secondary">Chronological order</span>
      </div>

      <%= if @timeline_events == [] do %>
        <p class="text-sm text-secondary">
          No delivery events have been recorded for this item yet.
        </p>
      <% else %>
        <ol class="motion-timeline space-y-4">
          <%= for {event, index} <- Enum.with_index(@timeline_events) do %>
            <li
              data-testid="operator-timeline-event"
              data-event-id={event.id}
              data-highlighted={
                if highlighted?(@highlight_event_id, event.id), do: "true", else: "false"
              }
              class="flex gap-3"
            >
              <div class="mt-1 flex flex-col items-center">
                <span class={["h-3 w-3 rounded-full", event_dot_class(event.type)]}></span>
                <span :if={index < length(@timeline_events) - 1} class="mt-2 h-full w-px bg-base-300">
                </span>
              </div>
              <div class={[
                "min-w-0 flex-1 rounded-box border bg-base-100 p-4",
                event_container_class(@highlight_event_id, event.id)
              ]}>
                <div class="flex flex-wrap items-start justify-between gap-3">
                  <div class="space-y-1">
                    <div class="flex flex-wrap items-center gap-2">
                      <p class="text-sm font-bold text-base-content">{event_label(event.type)}</p>
                      <span :if={event_badge(event.type)} class={badge_class(event.type)}>
                        {event_badge(event.type)}
                      </span>
                    </div>
                    <p class="text-xs text-secondary">
                      {metadata_summary(event.type, event.metadata)}
                    </p>
                    <p class="mono text-xs text-secondary">{event.id}</p>
                    <p :if={event.reject_reason} class="text-sm text-secondary">
                      Reason: {label(event.reject_reason)}
                    </p>
                  </div>
                  <p class="mono text-xs text-secondary">{format_datetime(event.occurred_at)}</p>
                </div>
              </div>
            </li>
          <% end %>
        </ol>
      <% end %>
    </article>
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

  defp badge_class(type)
       when type in [:webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed],
       do: "badge badge-outline badge-error"

  defp badge_class(:reconciled), do: "badge badge-outline badge-warning"
  defp badge_class(_type), do: "badge badge-outline"

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

  defp format_datetime(nil), do: "Pending"

  defp format_datetime(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")

  defp event_dot_class(:webhook_replay_failed), do: "bg-error"

  defp event_dot_class(type) when type in [:webhook_replay_requested, :webhook_replay_succeeded],
    do: "bg-warning"

  defp event_dot_class(:reconciled), do: "bg-accent"
  defp event_dot_class(_type), do: "bg-primary"
end
