defmodule MailglassAdmin.Operator.ReplayAction do
  @moduledoc "Final full-detail section for replay eligibility and review."

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.RepairState

  attr(:replay_targets, :map, default: nil)
  attr(:latest_replay, :map, default: nil)
  attr(:replay_history_read_state, :atom, default: :ready)
  attr(:replay_command_feedback, :string, default: nil)

  def replay_action(assigns) do
    ~H"""
    <Components.card
      padding={:lg}
      data-testid="operator-replay-action"
      data-group-card="operator-replay-action"
    >
      <div class="flex flex-wrap items-start justify-between gap-md">
        <div class="space-y-xs">
          <h2 class="text-body font-bold uppercase text-secondary">Webhook replay</h2>
          <p class="text-body text-base-content">{RepairState.availability_hint(@replay_targets)}</p>
          <p
            :if={@replay_command_feedback}
            role="status"
            aria-live="polite"
            data-testid="operator-replay-command-feedback"
            class="text-label text-secondary"
          >
            {@replay_command_feedback}
          </p>
          <div
            :if={@replay_history_read_state in [:unavailable, :stale]}
            role="status"
            aria-live="polite"
            data-testid="operator-replay-evidence-unavailable"
            class="flex flex-wrap items-center gap-sm text-label text-secondary"
          >
            <span>{RepairState.replay_evidence_unavailable_copy()}</span>
            <button
              type="button"
              phx-click="retry_replay_evidence"
              class="btn btn-ghost min-h-11"
            >
              Refresh replay evidence
            </button>
          </div>
          <p :if={@latest_replay} class="text-label text-secondary">
            Last retrieved replay evidence: {RepairState.latest_replay_summary(@latest_replay)} at
            <Components.timestamp at={@latest_replay.occurred_at} />
          </p>
        </div>

        <button
          id="replay-open-btn"
          type="button"
          phx-click="open_replay"
          data-testid="operator-replay-open"
          class="btn btn-primary min-h-11 px-md"
        >
          Review webhook replay
        </button>
      </div>
    </Components.card>
    """
  end
end
