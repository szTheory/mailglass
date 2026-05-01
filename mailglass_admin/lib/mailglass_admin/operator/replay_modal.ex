defmodule MailglassAdmin.Operator.ReplayModal do
  @moduledoc """
  Server-rendered replay confirmation modal for the operator delivery detail view.
  """

  use Phoenix.Component

  attr :open?, :boolean, required: true
  attr :delivery, :map, default: nil
  attr :replay_targets, :map, default: nil
  attr :selected_target_id, :string, default: nil

  def replay_modal(assigns) do
    ~H"""
    <%= if @open? and @delivery do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-base-content/40 p-4">
        <div
          data-testid="operator-replay-modal"
          class="w-full max-w-2xl rounded-box border border-base-300 bg-base-100 p-6 shadow-2xl"
        >
          <div class="flex items-start justify-between gap-4">
            <div class="space-y-1">
              <h2 class="text-lg font-bold text-base-content">Replay webhook for {@delivery.recipient}</h2>
              <p class="text-sm text-secondary">
                Replay is delivery-detail initiated, tenant-scoped, and recorded in the append-only ledger.
              </p>
            </div>

            <button type="button" phx-click="close_replay" class="btn btn-ghost btn-sm">
              Close
            </button>
          </div>

          <%= case @replay_targets do %>
            <% %{status: :exact, candidate: candidate} -> %>
              <div class="mt-6 space-y-4">
                <p class="text-sm text-base-content">
                  This delivery resolves to one exact webhook target. Confirm to replay that stored request.
                </p>
                <.target_card candidate={candidate} selected={true} />
              </div>

            <% %{status: :ambiguous, candidates: candidates} -> %>
              <div class="mt-6 space-y-4">
                <p class="text-sm text-base-content">
                  Choose one webhook target. The operator UI will not guess across multiple replayable webhook rows.
                </p>

                <form id="operator-replay-targets" phx-change="choose_replay_target" class="space-y-3">
                  <%= for candidate <- candidates do %>
                    <label class="block cursor-pointer">
                      <input
                        type="radio"
                        name="webhook_event_id"
                        value={candidate.webhook_event_id}
                        checked={candidate.webhook_event_id == @selected_target_id}
                        class="sr-only"
                      />
                      <.target_card
                        candidate={candidate}
                        selected={candidate.webhook_event_id == @selected_target_id}
                      />
                    </label>
                  <% end %>
                </form>
              </div>

            <% %{status: :unavailable, reason: reason} -> %>
              <div class="mt-6 space-y-4">
                <div class="rounded-box border border-warning bg-warning/10 p-4 text-sm text-base-content">
                  <p class="font-bold">Replay unavailable</p>
                  <p class="mt-1">{unavailable_copy(reason)}</p>
                </div>
              </div>

            <% _ -> %>
              <div class="mt-6 rounded-box border border-warning bg-warning/10 p-4 text-sm text-base-content">
                Replay target resolution is still loading for this delivery.
              </div>
          <% end %>

          <div class="mt-6 flex flex-wrap justify-end gap-3">
            <button type="button" phx-click="close_replay" class="btn btn-ghost min-h-11 px-5">
              Cancel
            </button>
            <button
              :if={confirm_enabled?(@replay_targets, @selected_target_id)}
              type="button"
              phx-click="confirm_replay"
              data-testid="operator-replay-confirm"
              class="btn btn-error min-h-11 px-5"
            >
              Confirm replay
            </button>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  attr :candidate, :map, required: true
  attr :selected, :boolean, default: false

  defp target_card(assigns) do
    ~H"""
    <div class={["rounded-box border p-4", @selected && "border-error bg-error/5", !@selected && "border-base-300 bg-base-200"]}>
      <div class="flex flex-wrap items-start justify-between gap-3">
        <div class="space-y-1">
          <p class="text-sm font-bold text-base-content">{String.upcase(@candidate.provider || "unknown")}</p>
          <p class="mono text-xs text-secondary">{@candidate.webhook_event_id}</p>
        </div>
        <p class="mono text-xs text-secondary">{format_datetime(@candidate.webhook_timestamp)}</p>
      </div>

      <dl class="mt-4 grid gap-3 text-sm text-secondary sm:grid-cols-2">
        <div>
          <dt class="text-xs font-bold uppercase tracking-[0.08em]">Provider event</dt>
          <dd class="mt-1 text-base-content">{present(@candidate.provider_event_id)}</dd>
        </div>
        <div>
          <dt class="text-xs font-bold uppercase tracking-[0.08em]">Delivery linkage</dt>
          <dd class="mt-1 text-base-content">{present(@candidate.delivery_provider_message_id)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  defp confirm_enabled?(%{status: :exact}, _selected_target_id), do: true

  defp confirm_enabled?(%{status: :ambiguous}, selected_target_id),
    do: is_binary(selected_target_id) and selected_target_id != ""

  defp confirm_enabled?(_replay_targets, _selected_target_id), do: false

  defp unavailable_copy(:historical_sendgrid_batch),
    do: "Historical SendGrid child events do not safely imply one raw webhook identity."

  defp unavailable_copy(:missing_replay_linkage),
    do: "Historical rows without exact webhook linkage cannot be replayed safely."

  defp unavailable_copy(:no_delivery_events),
    do: "This delivery does not yet have any linked webhook events to replay."

  defp unavailable_copy(_reason), do: "Replay target resolution is unavailable for this delivery."

  defp present(nil), do: "Unavailable"
  defp present(""), do: "Unavailable"
  defp present(value), do: value

  defp format_datetime(nil), do: "Pending"
  defp format_datetime(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
end
