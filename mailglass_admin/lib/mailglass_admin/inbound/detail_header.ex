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
          subject={@record.subject}
          recipient={@record.envelope_recipient}
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
            <dd class="mt-xs text-base-content">{sender_display(@record)}</dd>
          </div>
          <div>
            <dt class="text-label font-bold">Provider</dt>
            <dd class="mt-xs text-base-content">{String.upcase(@record.provider || "unknown")}</dd>
          </div>
          <div>
            <dt class="text-label font-bold">Received</dt>
            <dd class="mt-xs text-base-content"><Components.timestamp at={@record.received_at} /></dd>
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
              title={Accounts.title(@record.tenant_id, @account_labels)}
            >
              {Accounts.label(@record.tenant_id, @account_labels)}
            </dd>
          </div>
        </dl>
        <Components.technical_details
          collapsible={false}
          id="inbound-detail-technical"
        >
          <div>
            <dt class="text-label font-bold text-secondary">Record ID</dt>
            <dd class="mt-xs"><Components.copy_value value={@record.id} label="Record ID" /></dd>
          </div>
          <div :if={Map.get(@record, :provider_message_id)}>
            <dt class="text-label font-bold text-secondary">Provider message ID</dt>
            <dd class="mt-xs">
              <Components.copy_value value={@record.provider_message_id} label="Provider message ID" />
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
          class={["btn btn-error min-h-11 px-md", replay_disabled?(@outcome) && "btn-disabled"]}
        >
          Review replay
        </button>
      </div>
    </Components.card>
    """
  end

  # Pitfall 2 — defensive read; the field does not exist until this milestone phase.
  defp suppression_flagged?(record), do: Map.get(record, :suppression_flagged, false)

  # The masked SENDER for the "From" cell (WR-02). `InboundRecord.from` is an
  # `{:array, :map}` of parsed address maps — the sender is PII, so each address is
  # masked through the one audited `Components.mask_recipient/1` definition (kept separate from the readable recipient identity). Address maps round-trip through JSONB as STRING keys
  # ("address"), but freshly built structs carry ATOM keys (:address); both are
  # read. An empty or malformed `from` (no usable address) degrades to the neutral
  # "Unavailable" placeholder rather than crashing or rendering a falsehood.
  defp sender_display(record) do
    record
    |> Map.get(:from, [])
    |> List.wrap()
    |> Enum.map(&address_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> case do
      [] -> "Unavailable"
      addresses -> addresses |> Enum.map(&Components.mask_recipient/1) |> Enum.join(", ")
    end
  end

  defp address_value(%{address: address}) when is_binary(address), do: address
  defp address_value(%{"address" => address}) when is_binary(address), do: address
  defp address_value(address) when is_binary(address), do: address
  defp address_value(_other), do: nil

  # Pitfall 1 — a :no_match record can never replay (no prior matched mailbox).
  defp replay_disabled?(:no_match), do: true
  defp replay_disabled?(_outcome), do: false

  defp replay_hint(:no_match),
    do: "Replay is unavailable: this message did not match any mailbox."

  defp replay_hint(_outcome),
    do:
      "Run this stored message through its recorded mailbox again. Review the replay before starting it."
end
