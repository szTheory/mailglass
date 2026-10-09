defmodule MailglassAdmin.Inbound.ReplayModal do
  @moduledoc """
  Exact-target replay review for one selected inbound record.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr(:open?, :boolean, required: true)
  attr(:record, :map, default: nil)
  attr(:review, :map, default: nil)
  attr(:busy?, :boolean, default: false)

  def replay_modal(assigns) do
    ~H"""
    <%= if @open? and is_map(@record) and is_map(@review) do %>
      <div
        class="motion-tab-swap mg-layer-overlay-scrim mg-overlay-scrim mg-overscroll-contain fixed inset-0 flex items-center justify-center overflow-hidden p-md"
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
          aria-describedby="inbound-replay-modal-description inbound-replay-eligibility"
          tabindex="-1"
          phx-hook="ModalFocusTrap"
          phx-mounted={JS.focus(to: "#inbound-replay-close")}
          phx-window-keydown="close_replay"
          phx-key="Escape"
          class="motion-overlay mg-layer-overlay-panel mg-inbound-replay-dialog relative my-md w-full shrink-0 overflow-y-auto rounded-box border border-base-300 bg-base-100 p-lg shadow-overlay"
          phx-remove={
            JS.hide(
              time: 150,
              transition: {"ease-out duration-150", "opacity-100 scale-100", "opacity-0 scale-[0.98]"}
            )
          }
        >
          <span tabindex="0" aria-hidden="true" data-focus-trap="start"></span>
          <div class="flex items-start justify-between gap-md">
            <div class="space-y-sm">
              <h2 id="inbound-replay-modal-title" class="text-heading font-bold text-base-content">
                Review inbound replay
              </h2>
              <p id="inbound-replay-modal-description" class="text-body text-secondary">
                Replay uses the recorded Mailbox identity with currently deployed code against the stored inbound message. It does not evaluate current router rules or redeliver through the provider.
              </p>
            </div>
            <button
              id="inbound-replay-close"
              type="button"
              phx-click="close_replay"
              class="btn btn-ghost min-h-11 shrink-0 px-md"
            >
              Close replay review
            </button>
          </div>

          <dl class="mt-lg grid gap-sm rounded-box border border-base-300 bg-base-200 p-md text-body sm:grid-cols-2">
            <div class="min-w-0">
              <dt class="text-label text-secondary">Account ID</dt>
              <dd class="mono mt-xs break-all text-base-content">{@review.tenant_id}</dd>
            </div>
            <div class="min-w-0">
              <dt class="text-label text-secondary">Inbound message ID</dt>
              <dd class="mono mt-xs break-all text-base-content">{@review.record_id}</dd>
            </div>
            <div class="min-w-0 sm:col-span-2">
              <dt class="text-label text-secondary">Mailbox</dt>
              <dd class="mono mt-xs break-all text-base-content">
                Recorded Mailbox: {mailbox_label(@review.eligibility)}
              </dd>
            </div>
          </dl>

          <p
            id="inbound-replay-eligibility"
            role="status"
            aria-live="polite"
            class={[
              "mt-md rounded-box border p-md text-body",
              eligible?(@review.eligibility) && "border-success bg-success/10 text-base-content",
              not eligible?(@review.eligibility) && "border-warning bg-warning/10 text-base-content"
            ]}
          >
            {eligibility_copy(@review.eligibility)}
          </p>

          <div class="mt-lg flex flex-wrap justify-end gap-sm">
            <button
              id="inbound-replay-cancel"
              type="button"
              phx-click="close_replay"
              class="btn btn-ghost min-h-11 px-md"
            >
              Cancel
            </button>
            <button
              id="inbound-replay-confirm"
              type="button"
              phx-click={JS.push("confirm_replay") |> JS.focus(to: "#inbound-replay-close")}
              phx-disable-with="Replaying…"
              disabled={@busy? or not eligible?(@review.eligibility)}
              aria-live="polite"
              data-testid="inbound-replay-confirm"
              class="btn btn-error min-h-11 px-md"
            >
              {if(@busy?, do: "Replaying…", else: "Confirm replay")}
            </button>
          </div>
          <span tabindex="0" aria-hidden="true" data-focus-trap="end"></span>
        </div>
      </div>
    <% end %>
    """
  end

  defp eligible?(%{status: :eligible, mailbox: mailbox})
       when is_binary(mailbox) and mailbox != "",
       do: true

  defp eligible?(_eligibility), do: false

  defp mailbox_label(%{status: :eligible, mailbox: mailbox}) when is_binary(mailbox), do: mailbox
  defp mailbox_label(_eligibility), do: "Unavailable"

  defp eligibility_copy(%{status: :eligible}),
    do: "Eligible: this exact record can replay through its recorded Mailbox."

  defp eligibility_copy(%{reason: :no_prior_match}),
    do:
      "No mailbox matched this message when it was received, so there is no recorded Mailbox to replay."

  defp eligibility_copy(%{reason: :execution_history_missing}),
    do: "No execution history is recorded for this message."

  defp eligibility_copy(%{reason: :invalid_mailbox}),
    do: "The original Mailbox binding is missing or unsafe, so its identity cannot be resolved."

  defp eligibility_copy(%{reason: :mailbox_unavailable}),
    do: "The recorded Mailbox is not available in this deployment."

  defp eligibility_copy(%{reason: :missing_evidence}),
    do: "Stored inbound evidence is unavailable."

  defp eligibility_copy(%{reason: :record_unavailable}),
    do: "This record is no longer available in the selected Account."

  defp eligibility_copy(%{reason: :read_unavailable}),
    do: "Eligibility could not be checked because inbound data is temporarily unavailable."

  defp eligibility_copy(%{reason: :package_unavailable}),
    do: "Inbound support is unavailable, so replay eligibility could not be checked."

  defp eligibility_copy(_eligibility),
    do: "Replay eligibility could not be checked."
end
