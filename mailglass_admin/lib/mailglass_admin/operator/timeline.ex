defmodule MailglassAdmin.Operator.Timeline do
  @moduledoc """
  Read-only delivery timeline in chronological order.
  """

  use Phoenix.Component

  attr :timeline_events, :list, required: true

  def timeline(assigns) do
    ~H"""
    <article class="card rounded-box border border-base-300 bg-base-200 p-6">
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
                <span class="h-3 w-3 rounded-full bg-primary"></span>
                <span :if={index < length(@timeline_events) - 1} class="mt-2 h-full w-px bg-base-300"></span>
              </div>
              <div class="min-w-0 flex-1 rounded-box border border-base-300 bg-base-100 p-4">
                <div class="flex flex-wrap items-start justify-between gap-3">
                  <div class="space-y-1">
                    <p class="text-sm font-bold text-base-content">{label(event.type)}</p>
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
    provider = Map.get(metadata, "provider") || Map.get(metadata, :provider)
    source = Map.get(metadata, "source") || Map.get(metadata, :source)

    [provider, source]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> case do
      [] -> "mailglass ledger"
      values -> Enum.join(values, " · ")
    end
  end

  defp metadata_summary(_metadata), do: "mailglass ledger"

  defp format_datetime(nil), do: "Pending"
  defp format_datetime(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
end
