defmodule MailglassAdmin.Inbound.DetailHeader do
  @moduledoc """
  Selected inbound-record summary header.

  Sibling of `MailglassAdmin.Operator.DetailHeader`. Receives the
  detail read-model map `%{record: %InboundRecord{}, mailbox:, outcome:,
  outcome_reason:, evidence:}` from the internal inbound detail gateway.

  CRITICAL (Pitfall 2): the `:suppression_flagged` field does NOT exist on any
  current schema — it lands in a future release. The flag is read with
  `Map.get(record, :suppression_flagged, false)`, NEVER via dot-access on a missing
  struct key (which raises `KeyError`). The suppression-flag copy renders only when the flag
  is truthy, so it is forward-compatible scaffolding that simply never renders until a future release.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias MailglassAdmin.Inbound.AddressList
  alias MailglassAdmin.Operator.Accounts

  attr(:detail, :map, required: true)
  attr(:account_labels, :map, default: %{})

  def detail_header(assigns) do
    assigns =
      assign(assigns, :record, assigns.detail.record)
      |> assign(:outcome, assigns.detail[:outcome])
      |> assign(:mailbox, assigns.detail[:mailbox])

    ~H"""
    <Components.card
      padding={:lg}
      data-testid="inbound-detail-header"
      data-group-card="inbound-detail-header"
    >
      <div class="min-w-0 space-y-lg">
        <Components.message_identity
          subject={Map.get(@record, :subject)}
          recipient={Map.get(@record, :envelope_recipient)}
          status={Components.normalize_inbound_outcome(@outcome)}
          context={:inbound}
          id="inbound-detail-outcome"
        />
        <p
          :if={suppression_flagged?(@record)}
          data-testid="inbound-suppression-flag"
          class="text-body text-warning"
        >
          Sender suppressed: this message was flagged, not bounced, to preserve diagnostic signal.
        </p>
        <dl class="grid min-w-0 gap-md text-body text-secondary sm:grid-cols-2 lg:grid-cols-3 [&>div]:min-w-0 [&_dd]:[overflow-wrap:anywhere]">
          <div>
            <dt class="text-label font-bold">From</dt>
            <dd class="mt-xs text-base-content" data-testid="inbound-contact-from">
              <.address_list
                entries={contact_entries(@record, :from)}
                copy_label="From address"
                missing="No From header"
              />
            </dd>
          </div>
          <div :if={contact_entries(@record, :reply_to) != []}>
            <dt class="text-label font-bold">Reply-To</dt>
            <dd class="mt-xs text-base-content" data-testid="inbound-contact-reply-to">
              <.address_list
                entries={contact_entries(@record, :reply_to)}
                copy_label="Reply-To address"
                missing="No Reply-To header"
              />
            </dd>
          </div>
          <div>
            <dt class="text-label font-bold">To</dt>
            <dd class="mt-xs text-base-content" data-testid="inbound-contact-to">
              <.address_list
                entries={contact_entries(@record, :to)}
                copy_label="To address"
                missing="No To header"
              />
            </dd>
          </div>
          <div :if={contact_entries(@record, :cc) != []}>
            <dt class="text-label font-bold">Cc</dt>
            <dd class="mt-xs text-base-content" data-testid="inbound-contact-cc">
              <.address_list
                entries={contact_entries(@record, :cc)}
                copy_label="Cc address"
                missing="No Cc header"
              />
            </dd>
          </div>
          <div>
            <dt class="text-label font-bold">Delivered to</dt>
            <dd class="mt-xs text-base-content" data-testid="inbound-contact-delivered-to">
              <Components.copy_value
                :if={Map.get(@record, :envelope_recipient)}
                value={Map.get(@record, :envelope_recipient)}
                label="Delivered to address"
              />
              <span
                :if={is_nil(Map.get(@record, :envelope_recipient))}
                class="text-label text-secondary"
              >
                Not recorded by provider
              </span>
              <p class="mt-xs text-label text-secondary">
                SMTP envelope recipient (RCPT TO), used for routing.
              </p>
            </dd>
          </div>
          <div>
            <dt class="text-label font-bold">Provider</dt>
            <dd class="mt-xs text-base-content">
              {String.upcase(Map.get(@record, :provider) || "unknown")}
            </dd>
          </div>
          <div>
            <dt class="text-label font-bold">Received</dt>
            <dd class="mt-xs text-base-content">
              <Components.timestamp at={Map.get(@record, :received_at)} />
            </dd>
          </div>
          <div>
            <dt class="text-label font-bold">Mailbox</dt>
            <dd class="mt-xs">
              <Components.mailbox_identity
                record={%{outcome: @outcome, mailbox: @mailbox}}
                id="inbound-detail-mailbox"
              />
            </dd>
          </div>
          <div>
            <dt class="text-label font-bold">Account</dt>
            <dd
              class="mt-xs text-base-content"
              title={Accounts.title(Map.get(@record, :tenant_id), @account_labels)}
            >
              {Accounts.label(Map.get(@record, :tenant_id), @account_labels)}
            </dd>
          </div>
        </dl>
        <Components.technical_details
          collapsible={false}
          id="inbound-detail-technical"
        >
          <div :if={Map.get(@record, :id)}>
            <dt class="text-label font-bold text-secondary">Record ID</dt>
            <dd class="mt-xs">
              <Components.copy_value value={Map.get(@record, :id)} label="Record ID" />
            </dd>
          </div>
          <div :if={Map.get(@record, :provider_message_id)}>
            <dt class="text-label font-bold text-secondary">Provider message ID</dt>
            <dd class="mt-xs">
              <Components.copy_value
                value={Map.get(@record, :provider_message_id)}
                label="Provider message ID"
              />
            </dd>
          </div>
        </Components.technical_details>
      </div>

      <div class="mt-lg flex flex-wrap items-start justify-between gap-md border-t border-base-300 pt-md">
        <div class="space-y-xs">
          <h3 class="text-body font-bold text-base-content">Replay</h3>
          <p class="text-body text-base-content">{replay_hint(@outcome)}</p>
        </div>

        <button
          id="inbound-replay-open-btn"
          type="button"
          phx-click="open_replay"
          phx-value-origin="full"
          data-testid="inbound-replay-open"
          disabled={replay_disabled?(@outcome)}
          class={["btn btn-primary min-h-11 px-md", replay_disabled?(@outcome) && "btn-disabled"]}
        >
          Review inbound replay
        </button>
      </div>
    </Components.card>
    """
  end

  # Pitfall 2 — defensive read; the field does not exist until this milestone phase.
  defp suppression_flagged?(record), do: Map.get(record, :suppression_flagged, false)

  defp contact_entries(record, key), do: record |> Map.get(key, []) |> AddressList.entries()

  attr(:entries, :list, required: true)
  attr(:copy_label, :string, required: true)
  attr(:missing, :string, required: true)

  defp address_list(assigns) do
    {shown, rest} = AddressList.split(assigns.entries)
    assigns = assign(assigns, shown: shown, rest: rest)

    ~H"""
    <p :if={@entries == []} class="text-label text-secondary">{@missing}</p>
    <ul :if={@shown != []} role="list" class="space-y-sm">
      <.address_item :for={entry <- @shown} entry={entry} copy_label={@copy_label} />
    </ul>
    <details :if={@rest != []} class="mt-sm">
      <summary class="mg-focus-ring min-h-11 cursor-pointer content-center rounded-field text-label font-bold text-secondary">
        Show {length(@rest)} more
      </summary>
      <ul role="list" class="mt-sm space-y-sm">
        <.address_item :for={entry <- @rest} entry={entry} copy_label={@copy_label} />
      </ul>
    </details>
    """
  end

  attr(:entry, :map, required: true)
  attr(:copy_label, :string, required: true)

  defp address_item(%{entry: %{kind: :unparseable}} = assigns) do
    ~H"""
    <li class="min-w-0 [overflow-wrap:anywhere]">
      <span class="text-label text-secondary">Unparseable address</span>
      <Components.copy_value :if={@entry.original} value={@entry.original} label={@copy_label} />
    </li>
    """
  end

  defp address_item(assigns) do
    ~H"""
    <li class="min-w-0 [overflow-wrap:anywhere]">
      <span :if={@entry.name} class="block text-base-content">{@entry.name}</span>
      <Components.copy_value value={@entry.address} label={@copy_label} />
      <p
        :if={@entry.spoof?}
        data-testid="inbound-address-spoof-cue"
        class="text-label text-warning"
      >
        Display name contains a different address.
      </p>
    </li>
    """
  end

  # Pitfall 1 — a :no_match record can never replay (no prior matched mailbox).
  defp replay_disabled?(:no_match), do: true
  defp replay_disabled?(_outcome), do: false

  defp replay_hint(:no_match),
    do: "Replay is unavailable: this message did not match any mailbox."

  defp replay_hint(_outcome),
    do:
      "Run this stored message through its recorded mailbox again. Review the replay before starting it."
end
