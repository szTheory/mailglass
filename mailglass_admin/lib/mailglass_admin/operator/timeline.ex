defmodule MailglassAdmin.Operator.Timeline do
  @moduledoc """
  Read-only delivery timeline in chronological order.
  """

  use Phoenix.Component

  attr :timeline_events, :list, required: true

  def timeline(assigns) do
    ~H"""
    <article data-testid="operator-timeline" class="card rounded-box border border-base-300 bg-base-200 p-6">
      <div class="mb-4 flex items-center justify-between gap-3">
        <h3 class="text-base font-bold text-base-content">Event timeline</h3>
        <span class="text-xs text-secondary">Chronological order</span>
      </div>

      <%= if @timeline_events == [] do %>
        <p class="text-sm text-secondary">
          No delivery events have been recorded for this item yet.
        </p>
      <% else %>
        <ol class="space-y-4">
          <%= for {event, index} <- Enum.with_index(@timeline_events) do %>
            <li class="flex gap-3">
              <div class="mt-1 flex flex-col items-center">
                <span class={["h-3 w-3 rounded-full", event_dot_class(event.type)]}></span>
                <span :if={index < length(@timeline_events) - 1} class="mt-2 h-full w-px bg-base-300"></span>
              </div>
              <div class="min-w-0 flex-1 rounded-box border border-base-300 bg-base-100 p-4">
                <div class="flex flex-wrap items-start justify-between gap-3">
                  <div class="space-y-1">
                    <div class="flex flex-wrap items-center gap-2">
                      <p class="text-sm font-bold text-base-content">{label(event.type)}</p>
                      <span :if={replay_event?(event.type)} class="badge badge-outline badge-error">
                        Replay audit
                      </span>
                    </div>
                    <p class="text-xs text-secondary">{metadata_summary(event.metadata)}</p>
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

  defp metadata_summary(metadata) when is_map(metadata) do
    if replay_metadata?(metadata) do
      replay_metadata_summary(metadata)
    else
      default_metadata_summary(metadata)
    end
  end

  defp metadata_summary(_metadata), do: "mailglass ledger"

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
    provider = Map.get(metadata, "provider")
    actor_id = Map.get(metadata, "actor_id")
    outcome = replay_outcome_label(Map.get(metadata, "outcome"))
    failure_reason = Map.get(metadata, "failure_reason")

    [provider && String.upcase(provider), actor_id, outcome, failure_reason]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> case do
      [] -> "Replay audit"
      values -> Enum.join(values, " · ")
    end
  end

  defp format_datetime(nil), do: "Pending"
  defp format_datetime(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")

  defp replay_event?(type),
    do: type in [:webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed]

  defp replay_metadata?(metadata), do: is_binary(Map.get(metadata, "webhook_event_id"))

  defp replay_outcome_label("noop"), do: "No new work"
  defp replay_outcome_label("replayed"), do: "New work applied"
  defp replay_outcome_label("failed"), do: "Failed"
  defp replay_outcome_label(_outcome), do: nil

  defp event_dot_class(:webhook_replay_failed), do: "bg-error"
  defp event_dot_class(type) when type in [:webhook_replay_requested, :webhook_replay_succeeded], do: "bg-warning"
  defp event_dot_class(_type), do: "bg-primary"
end
