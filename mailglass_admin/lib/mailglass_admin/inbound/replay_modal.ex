defmodule MailglassAdmin.Inbound.ReplayModal do
  @moduledoc """
  Server-rendered replay confirmation modal for the inbound record detail view.

  Sibling of `MailglassAdmin.Operator.ReplayModal` (the design contract), SIMPLIFIED: inbound
  replay has no ambiguous-multi target (IADM-03 — the replay target is the record
  itself), so there is no multi-target branch, no target cards, and no
  confirm-enabled predicate. `Confirm replay` is always enabled while the modal is
  open.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias Phoenix.LiveView.JS

  attr :open?, :boolean, required: true
  attr :record, :map, default: nil

  def replay_modal(assigns) do
    ~H"""
    <%= if @open? and @record do %>
      <div
        class="motion-tab-swap mg-layer-overlay-scrim mg-overlay-scrim fixed inset-0 flex items-center justify-center p-4"
        phx-remove={
          JS.hide(time: 150, transition: {"ease-out duration-150", "opacity-100", "opacity-0"})
        }
      >
        <div
          id="inbound-replay-modal"
          data-testid="inbound-replay-modal"
          role="dialog"
          aria-modal="true"
          aria-labelledby="inbound-replay-modal-title"
          phx-key="Escape"
          phx-window-keydown="close_replay"
          class="motion-overlay mg-layer-overlay-panel w-full max-w-2xl rounded-box border border-base-300 bg-base-100 p-6 shadow-overlay"
          phx-remove={
            JS.hide(
              time: 150,
              transition: {"ease-out duration-150", "opacity-100 scale-100", "opacity-0 scale-[0.98]"}
            )
          }
        >
          <div class="flex items-start justify-between gap-md">
            <div class="space-y-1">
              <h2 id="inbound-replay-modal-title" class="text-heading font-bold text-base-content">
                Replay inbound for {Components.mask_recipient(@record.envelope_recipient)}
              </h2>
              <p class="text-body text-secondary">
                Re-runs Mailbox routing against the stored InboundMessage and records a new replay run in the append-only ledger. Confirm to replay.
              </p>
            </div>

            <button type="button" phx-click="close_replay" class="btn btn-ghost min-h-11 px-4">
              Close
            </button>
          </div>

          <div class="mt-6 flex flex-wrap justify-end gap-sm">
            <button type="button" phx-click="close_replay" class="btn btn-ghost min-h-11 px-5">
              Cancel
            </button>
            <button
              type="button"
              phx-click="confirm_replay"
              data-testid="inbound-replay-confirm"
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
end
