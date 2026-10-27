defmodule MailglassAdmin.Inbound.ReplayModal do
  @moduledoc """
  Exact-target replay review for one selected inbound record.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias Phoenix.LiveView.JS

  attr(:open?, :boolean, required: true)
  attr(:record, :map, default: nil)
  attr(:review, :map, default: nil)
  attr(:busy?, :boolean, default: false)
  attr(:feedback, :map, default: nil)

  def replay_modal(assigns) do
    ~H"""
    <%= if @open? and is_map(@record) and is_map(@review) do %>
      <Components.replay_dialog
        id="inbound-replay-modal"
        title_id="inbound-replay-modal-title"
        description_id="inbound-replay-modal-description"
        close_id="inbound-replay-close"
        close_event="close_replay"
        described_by="inbound-replay-eligibility"
      >
        <:title>Review inbound replay</:title>
        <:description>
          Replay uses the recorded Mailbox identity with currently deployed code against the stored inbound message. It does not evaluate current router rules or redeliver through the provider.
        </:description>
        <:body>
          <p
            :if={@feedback}
            id="inbound-replay-feedback"
            data-testid="inbound-replay-feedback"
            role={if @feedback.kind == :error, do: "alert", else: "status"}
            aria-live={if @feedback.kind == :error, do: "assertive", else: "polite"}
            class={[
              "mt-md rounded-box border p-sm text-body",
              if(@feedback.kind == :error,
                do: "border-error bg-error/10 text-base-content",
                else: "border-success bg-success/10 text-base-content"
              )
            ]}
          >
            {@feedback.text}
          </p>

          <dl
            id="inbound-replay-identity"
            data-review-id={@review.review_id}
            class="mt-lg grid min-w-0 gap-sm rounded-box border border-base-300 bg-base-200 p-md text-body sm:grid-cols-2 [&_dd]:[overflow-wrap:anywhere]"
          >
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
        </:body>
        <:actions>
          <div class="mt-lg flex flex-wrap justify-end gap-sm">
            <button
              :if={@feedback && @feedback.kind == :error}
              id="inbound-replay-review-again"
              type="button"
              phx-click="review_replay_again"
              phx-disable-with="Checking recorded Mailbox…"
              class="btn btn-ghost min-h-11 px-md"
            >
              Review again
            </button>
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
        </:actions>
      </Components.replay_dialog>
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
