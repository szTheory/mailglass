defmodule MailglassAdmin.Operator.ReplayModal do
  @moduledoc """
  Server-rendered replay confirmation modal for the operator delivery detail view.
  """

  use Phoenix.Component

  alias MailglassAdmin.Operator.RepairState

  attr(:open?, :boolean, required: true)
  attr(:delivery, :map, default: nil)
  attr(:replay_targets, :map, default: nil)
  attr(:selected_target_id, :string, default: nil)

  def replay_modal(assigns) do
    ~H"""
    <%= if @open? and @delivery do %>
      <div class="motion-tab-swap fixed inset-0 z-40 flex items-center justify-center bg-base-content/40 p-4">
        <div
          data-testid="operator-replay-modal"
          role="dialog"
          aria-modal="true"
          aria-labelledby="replay-modal-title"
          phx-key="Escape"
          phx-window-keydown="close_replay"
          class="motion-overlay w-full max-w-2xl rounded-box border border-base-300 bg-base-100 p-6 shadow-overlay"
        >
          <div class="flex items-start justify-between gap-md">
            <div class="space-y-1">
              <h2 id="replay-modal-title" class="text-heading font-bold text-base-content">
                Replay webhook for {@delivery.recipient}
              </h2>
              <p class="text-body text-secondary">
                Re-dispatches the stored webhook request through Mailbox routing and records a new Event in the append-only ledger. Confirm to replay.
              </p>
            </div>

            <button type="button" phx-click="close_replay" class="btn btn-ghost btn-sm">
              Close
            </button>
          </div>

          <%= case @replay_targets do %>
            <% %{status: :exact, candidate: candidate} -> %>
              <div class="mt-6 space-y-4">
                <p class="text-body text-base-content">
                  Replay is <span class="font-bold">{RepairState.availability_label(:exact)}</span>.
                  Confirm to replay that stored request.
                </p>
                <.target_card candidate={candidate} selected={true} />
              </div>
            <% %{status: :ambiguous, candidates: candidates} -> %>
              <div class="mt-6 space-y-4">
                <p class="text-body text-base-content">
                  Replay is <span class="font-bold">{RepairState.availability_label(:ambiguous)}</span>.
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
                <div class="rounded-box border border-warning bg-warning/10 p-4 text-body text-base-content">
                  <p class="font-bold">Replay unavailable</p>
                  <p class="mt-1">
                    Replay is <span class="font-bold">{RepairState.availability_label(:unavailable)}</span>. {RepairState.unavailable_reason_copy(
                      reason
                    )}
                  </p>
                </div>
              </div>
            <% _ -> %>
              <div class="mt-6 rounded-box border border-warning bg-warning/10 p-4 text-body text-base-content">
                Replay target resolution is still loading for this delivery.
              </div>
          <% end %>

          <div class="mt-6 flex flex-wrap justify-end gap-sm">
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

  attr(:candidate, :map, required: true)
  attr(:selected, :boolean, default: false)

  defp target_card(assigns) do
    ~H"""
    <div class={[
      "rounded-box border p-4",
      @selected && "border-error bg-error/5",
      !@selected && "border-base-300 bg-base-200"
    ]}>
      <div class="flex flex-wrap items-start justify-between gap-sm">
        <div class="space-y-1">
          <p class="text-body font-bold text-base-content">
            {String.upcase(@candidate.provider || "unknown")}
          </p>
          <p class="mono text-label text-secondary">{@candidate.webhook_event_id}</p>
        </div>
        <p class="mono text-label text-secondary">{format_datetime(@candidate.webhook_timestamp)}</p>
      </div>

      <dl class="mt-4 grid gap-sm text-body text-secondary sm:grid-cols-2">
        <div>
          <dt class="text-label uppercase font-bold">Provider event</dt>
          <dd class="mt-1 text-base-content">{present(@candidate.provider_event_id)}</dd>
        </div>
        <div>
          <dt class="text-label uppercase font-bold">Delivery linkage</dt>
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

  defp present(nil), do: "Unavailable"
  defp present(""), do: "Unavailable"
  defp present(value), do: value

  defp format_datetime(nil), do: "Pending"

  defp format_datetime(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
end
