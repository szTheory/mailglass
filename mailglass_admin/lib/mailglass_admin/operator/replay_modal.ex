defmodule MailglassAdmin.Operator.ReplayModal do
  @moduledoc """
  Server-rendered replay confirmation modal for the operator delivery detail view.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.RepairState
  alias Phoenix.LiveView.JS

  attr(:open?, :boolean, required: true)
  attr(:delivery, :map, default: nil)
  attr(:replay_targets, :map, default: nil)
  attr(:selected_target_id, :string, default: nil)
  attr(:review_id, :string, default: nil)
  attr(:account_label, :string, default: nil)
  attr(:pending?, :boolean, default: false)
  attr(:consumed?, :boolean, default: false)

  def replay_modal(assigns) do
    ~H"""
    <%= if @open? and @delivery do %>
      <div
        class="motion-tab-swap mg-layer-overlay-scrim mg-overlay-scrim mg-overscroll-contain fixed inset-0 flex items-center justify-center overflow-hidden p-4"
        phx-remove={
          JS.hide(time: 150, transition: {"ease-out duration-150", "opacity-100", "opacity-0"})
        }
      >
        <div
          id="operator-replay-modal"
          data-testid="operator-replay-modal"
          role="dialog"
          aria-modal="true"
          aria-labelledby="replay-modal-title"
          aria-describedby="replay-modal-description"
          phx-hook="ModalFocusTrap"
          phx-mounted={JS.focus(to: "#operator-replay-close")}
          phx-key="Escape"
          phx-window-keydown="close_replay"
          class="motion-overlay mg-layer-overlay-panel mg-inbound-replay-dialog relative my-md w-full shrink-0 overflow-y-auto rounded-box border border-base-300 bg-base-100 p-lg shadow-overlay"
          phx-remove={
            JS.hide(
              time: 150,
              transition: {"ease-out duration-150", "opacity-100 scale-100", "opacity-0 scale-[0.98]"}
            )
          }
        >
          <%!-- Wrap to the last currently focusable action: Confirm when enabled, otherwise Cancel. --%>
          <span tabindex="0" aria-hidden="true" data-focus-trap="start"></span>
          <div class="flex items-start justify-between gap-md">
            <div class="space-y-1">
              <h2 id="replay-modal-title" class="text-heading font-bold text-base-content">
                Review webhook replay
              </h2>
              <p id="replay-modal-description" class="text-body text-secondary">
                Replay reprocesses the full stored request through current normalization. It may add Events or update Delivery and suppression records for multiple Deliveries in this Account. It does not resend outbound mail or prove provider receipt.
              </p>
            </div>

            <button
              id="operator-replay-close"
              type="button"
              phx-click="close_replay"
              class="btn btn-ghost min-h-11 px-4"
            >
              Close replay review
            </button>
          </div>

          <%= case @replay_targets do %>
            <% %{status: :exact, candidate: candidate} -> %>
              <div class="mt-6 space-y-4">
                <p class="text-body text-base-content">
                  Review the exact stored request before confirming.
                </p>
                <.target_card candidate={candidate} selected={true} />
              </div>
            <% %{status: :ambiguous, candidates: candidates} -> %>
              <div class="mt-6 space-y-4">
                <p class="text-body text-base-content">
                  Replay is <span class="font-bold">{RepairState.availability_label(:ambiguous)}</span>.
                  Choose the exact stored request to review. No request is selected for you.
                </p>

                <form id="operator-replay-targets" phx-change="choose_replay_target" class="space-y-3">
                  <%= for candidate <- candidates do %>
                    <.target_choice
                      candidate={candidate}
                      selected={candidate.webhook_event_id == @selected_target_id}
                    />
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

          <div
            :if={reviewed_target(@replay_targets, @selected_target_id)}
            class="mt-6 rounded-box border border-base-300 bg-base-200 p-4"
            data-testid="operator-replay-reviewed-target"
          >
            <p class="mb-3 text-label font-bold text-base-content">Reviewed request</p>
            <dl class="grid gap-sm text-body sm:grid-cols-2">
              <div class="min-w-0">
                <dt class="text-label text-secondary">Account</dt>
                <dd class="mt-1 break-words text-base-content">{present(@account_label)}</dd>
              </div>
              <div class="min-w-0">
                <dt class="text-label text-secondary">Stored webhook/request ID</dt>
                <dd class="mono mt-1 break-all text-base-content">{reviewed_target(@replay_targets, @selected_target_id).webhook_event_id}</dd>
              </div>
              <div class="min-w-0">
                <dt class="text-label text-secondary">Provider</dt>
                <dd class="mt-1 break-words text-base-content">{String.upcase(reviewed_target(@replay_targets, @selected_target_id).provider || "unknown")}</dd>
              </div>
              <div class="min-w-0">
                <dt class="text-label text-secondary">Received</dt>
                <dd class="mt-1 break-words text-base-content"><Components.timestamp at={reviewed_target(@replay_targets, @selected_target_id).webhook_timestamp} /></dd>
              </div>
            </dl>
          </div>

          <p :if={@pending?} role="status" aria-live="polite" class="mt-4 text-body text-secondary">
            Replaying the reviewed request…
          </p>

          <div class="mt-6 flex flex-wrap justify-end gap-sm">
            <button
              id="operator-replay-cancel"
              type="button"
              phx-click="close_replay"
              class="btn btn-ghost min-h-11 px-5"
            >
              Cancel
            </button>
            <button
              :if={confirm_enabled?(@replay_targets, @selected_target_id)}
              id="operator-replay-confirm"
              type="button"
              phx-click={JS.push("confirm_replay") |> JS.focus(to: "#operator-replay-close")}
              phx-value-review={@review_id}
              phx-disable-with="Replaying…"
              disabled={@pending? or @consumed?}
              aria-live="polite"
              data-testid="operator-replay-confirm"
              class="btn btn-error min-h-11 px-5"
            >
              {if(@pending?, do: "Replaying…", else: "Confirm replay")}
            </button>
          </div>
          <%!-- Focus-trap end sentinel: Tab off the last control lands here and wraps to the first control (Close). --%>
          <span tabindex="0" aria-hidden="true" data-focus-trap="end"></span>
        </div>
      </div>
    <% end %>
    """
  end

  attr(:candidate, :map, required: true)
  attr(:selected, :boolean, default: false)

  defp target_choice(assigns) do
    assigns =
      assigns
      |> assign(:input_id, target_input_id(assigns.candidate))
      |> assign(:description_id, target_description_id(assigns.candidate))
      |> assign(:label, target_label(assigns.candidate))
      |> assign(:description, target_description(assigns.candidate))

    ~H"""
    <div class={target_card_class(@selected)}>
      <div class="flex items-start gap-sm">
        <input
          id={@input_id}
          type="radio"
          name="webhook_event_id"
          value={@candidate.webhook_event_id}
          checked={@selected}
          aria-describedby={@description_id}
          class="radio mt-1"
        />
        <div class="min-w-0 flex-1 space-y-3">
          <div class="space-y-1">
            <label for={@input_id} class="cursor-pointer text-body font-bold text-base-content">
              {@label}
            </label>
            <p id={@description_id} class="text-label text-secondary">
              {@description}
            </p>
          </div>
          <.selected_target_cue selected={@selected} />
          <.target_summary candidate={@candidate} />
        </div>
      </div>
    </div>
    """
  end

  defp target_card(assigns) do
    ~H"""
    <div class={target_card_class(@selected)}>
      <.selected_target_cue selected={@selected} />
      <.target_summary candidate={@candidate} />
    </div>
    """
  end

  attr(:selected, :boolean, required: true)

  defp selected_target_cue(assigns) do
    ~H"""
    <p :if={@selected} class="mb-3 inline-flex items-center gap-1 text-label font-bold text-error">
      <Components.icon name="hero-check-circle" class="h-5 w-5" /> Selected target
    </p>
    """
  end

  attr(:candidate, :map, required: true)

  defp target_summary(assigns) do
    ~H"""
    <div>
      <div class="flex flex-wrap items-start justify-between gap-sm">
        <div class="space-y-1">
          <p class="text-body font-bold text-base-content">
            {String.upcase(@candidate.provider || "unknown")}
          </p>
          <p data-testid="operator-replay-target-id" class="mono text-label text-secondary">
            {@candidate.webhook_event_id}
          </p>
        </div>
        <p class="text-label text-secondary">
          <Components.timestamp at={@candidate.webhook_timestamp} />
        </p>
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

  defp confirm_enabled?(%{status: :exact, candidate: candidate}, selected_target_id),
    do: candidate.webhook_event_id == selected_target_id

  defp confirm_enabled?(%{status: :ambiguous}, selected_target_id),
    do: is_binary(selected_target_id) and selected_target_id != ""

  defp confirm_enabled?(_replay_targets, _selected_target_id), do: false

  defp reviewed_target(%{status: :exact, candidate: candidate}, selected_target_id) do
    if candidate.webhook_event_id == selected_target_id, do: candidate, else: nil
  end

  defp reviewed_target(%{status: :ambiguous, candidates: candidates}, selected_target_id) do
    Enum.find(candidates, &(&1.webhook_event_id == selected_target_id))
  end

  defp reviewed_target(_replay_targets, _selected_target_id), do: nil

  defp present(nil), do: "Unavailable"
  defp present(""), do: "Unavailable"
  defp present(value), do: value

  defp target_card_class(selected) do
    [
      "rounded-box border p-4",
      selected && "border-error bg-error/5",
      !selected && "border-base-300 bg-base-200"
    ]
  end

  defp target_input_id(candidate) do
    safe_id =
      candidate.webhook_event_id
      |> to_string()
      |> String.replace(~r/[^A-Za-z0-9_-]+/, "-")
      |> String.trim("-")

    "operator-replay-target-" <> if(safe_id == "", do: "unknown", else: safe_id)
  end

  defp target_description_id(candidate), do: target_input_id(candidate) <> "-description"

  defp target_label(candidate) do
    "#{String.upcase(candidate.provider || "unknown")} webhook target"
  end

  defp target_description(candidate) do
    "Provider event #{present(candidate.provider_event_id)}. " <>
      "Webhook event #{present(candidate.webhook_event_id)}. " <>
      "Delivery linkage #{present(candidate.delivery_provider_message_id)}."
  end
end
