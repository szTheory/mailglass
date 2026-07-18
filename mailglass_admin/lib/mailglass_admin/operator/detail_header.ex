defmodule MailglassAdmin.Operator.DetailHeader do
  @moduledoc """
  Selected delivery summary header.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.Accounts
  alias MailglassAdmin.Operator.RepairState

  attr(:delivery, :map, required: true)
  attr(:replay_targets, :map, default: nil)
  attr(:latest_replay, :map, default: nil)
  attr(:account_labels, :map, default: %{})

  def detail_header(assigns) do
    ~H"""
    <Components.card
      padding={:lg}
      data-testid="operator-detail-header"
      data-group-card="operator-detail-header"
    >
      <div class="flex flex-wrap items-start justify-between gap-md">
        <div class="space-y-sm">
          <div class="flex flex-wrap items-center gap-sm">
            <h2 class="text-heading font-bold text-base-content">{@delivery.recipient}</h2>
            <Components.status_badge status={Components.delivery_display_status(@delivery)} />
          </div>
          <p class="mono text-label text-secondary">{@delivery.id}</p>
          <p :if={present?(@delivery.mailable)} class="text-body text-secondary">
            {@delivery.mailable}
          </p>
        </div>

        <dl class="grid gap-sm text-body text-secondary sm:grid-cols-2">
          <div>
            <dt class="text-label font-bold uppercase">Account</dt>
            <dd
              class="mt-xs text-base-content"
              title={Accounts.title(@delivery.tenant_id, @account_labels)}
            >
              {Accounts.label(@delivery.tenant_id, @account_labels)}
            </dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase">Provider</dt>
            <dd class="mt-xs text-base-content">{String.upcase(@delivery.provider || "unknown")}</dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase">Stream</dt>
            <dd class="mt-xs text-base-content">{label(@delivery.stream)}</dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase">Latest event</dt>
            <dd class="mt-xs text-base-content">{label(@delivery.last_event_type)}</dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase">Updated</dt>
            <dd class="mt-xs text-base-content"><Components.timestamp at={@delivery.last_event_at} /></dd>
          </div>
          <div :if={present?(@delivery.provider_message_id)}>
            <dt class="text-label font-bold uppercase">Provider message</dt>
            <dd class="mono mt-xs text-base-content">{@delivery.provider_message_id}</dd>
          </div>
        </dl>
      </div>

      <div class="mt-lg flex flex-wrap items-start justify-between gap-md border-t border-base-300 pt-md">
        <div class="max-w-prose space-y-xs">
          <h3 class="text-body font-bold uppercase text-secondary">Webhook replay</h3>
          <p class="text-label text-secondary">
            Re-runs the provider's original webhook through mailglass to re-derive this
            delivery's status — for when an event was mis-processed.
          </p>
          <p class="text-body text-base-content">{RepairState.availability_hint(@replay_targets)}</p>
          <p :if={@latest_replay} class="text-label text-secondary">
            Last replay: {RepairState.latest_replay_summary(@latest_replay)} at <Components.timestamp at={@latest_replay.occurred_at} />
          </p>
        </div>

        <button
          id="replay-open-btn"
          type="button"
          phx-click="open_replay"
          data-testid="operator-replay-open"
          class={["btn min-h-11 px-md", replay_cta_class(@replay_targets)]}
        >
          Replay webhook
        </button>
      </div>
    </Components.card>
    """
  end

  # Replay is a benign recovery action, never destructive — so the CTA is never
  # error-red. It leads with primary emphasis when a webhook target is ready and
  # steps back to a quiet ghost when replay is unavailable (the button still opens
  # the modal, which explains why).
  defp replay_cta_class(%{status: status}) when status in [:exact, :ambiguous],
    do: "btn-primary"

  defp replay_cta_class(_replay_targets), do: "btn-ghost"

  defp label(nil), do: "Unknown"

  defp label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp present?(value), do: value not in [nil, ""]
end
