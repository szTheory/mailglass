defmodule MailglassAdmin.Inbound.DetailHeader do
  @moduledoc """
  Selected inbound-record summary header.

  Sibling of `MailglassAdmin.Operator.DetailHeader` (the design contract). Receives the
  detail read-model map `%{record: %InboundRecord{}, mailbox:, outcome:,
  outcome_reason:, evidence:}` from the internal inbound detail gateway.

  CRITICAL (Pitfall 2): the `:suppression_flagged` field does NOT exist on any
  this milestone phase schema — it lands in this milestone phase. The flag is read with
  `Map.get(record, :suppression_flagged, false)`, NEVER via dot-access on a missing
  struct key (which raises `KeyError`). The IOPS-05 copy renders only when the flag
  is truthy, so it is forward-compatible scaffolding that simply never renders until
  this milestone phase.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr :detail, :map, required: true

  def detail_header(assigns) do
    assigns =
      assign(assigns, :record, assigns.detail.record)
      |> assign(:outcome, assigns.detail[:outcome])
      |> assign(:mailbox, assigns.detail[:mailbox])

    ~H"""
    <article
      data-testid="inbound-detail-header"
      class="card rounded-box border border-base-300 bg-base-200 p-6"
    >
      <div class="flex flex-wrap items-start justify-between gap-md">
        <div class="space-y-2">
          <div class="flex flex-wrap items-center gap-2">
            <h2 class="text-heading font-bold text-base-content">
              {Components.mask_recipient(@record.envelope_recipient)}
            </h2>
            <Components.status_badge status={Components.normalize_inbound_outcome(@outcome)} />
          </div>
          <p class="mono text-label text-secondary">{@record.id}</p>
          <p
            :if={suppression_flagged?(@record)}
            data-testid="inbound-suppression-flag"
            class="text-body text-warning"
          >
            Sender suppressed: this message was flagged, not bounced, to preserve diagnostic signal.
          </p>
        </div>

        <dl class="grid gap-sm text-body text-secondary sm:grid-cols-2">
          <div>
            <dt class="text-label font-bold uppercase">Tenant</dt>
            <dd class="mt-1 text-base-content">{@record.tenant_id}</dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase">Provider</dt>
            <dd class="mt-1 text-base-content">{String.upcase(@record.provider || "unknown")}</dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase">From</dt>
            <dd class="mt-1 text-base-content">{sender_display(@record)}</dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase">Subject</dt>
            <dd class="mt-1 text-base-content">{present(@record.subject)}</dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase">Received</dt>
            <dd class="mono mt-1 text-base-content">{format_datetime(@record.received_at)}</dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase">Matched mailbox</dt>
            <dd class="mt-1 text-base-content">{matched_mailbox(@mailbox)}</dd>
          </div>
        </dl>
      </div>

      <div class="mt-6 flex flex-wrap items-start justify-between gap-md border-t border-base-300 pt-4">
        <div class="space-y-1">
          <h3 class="text-body font-bold uppercase text-secondary">Replay</h3>
          <p class="text-body text-base-content">{replay_hint(@outcome)}</p>
        </div>

        <button
          type="button"
          phx-click="open_replay"
          data-testid="inbound-replay-open"
          disabled={replay_disabled?(@outcome)}
          class={["btn btn-error min-h-11 px-md", replay_disabled?(@outcome) && "btn-disabled"]}
        >
          Replay inbound
        </button>
      </div>
    </article>
    """
  end

  # Pitfall 2 — defensive read; the field does not exist until this milestone phase.
  defp suppression_flagged?(record), do: Map.get(record, :suppression_flagged, false)

  # The masked SENDER for the "From" cell (WR-02). `InboundRecord.from` is an
  # `{:array, :map}` of parsed address maps — the sender is PII, so each address is
  # masked through the one audited `Components.mask_recipient/1` definition (same
  # treatment recipients get). Address maps round-trip through JSONB as STRING keys
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
    do: "Replay re-runs mailbox routing against the stored message and records a new replay run."

  defp matched_mailbox(mailbox) when is_binary(mailbox) and mailbox != "", do: mailbox
  defp matched_mailbox(_mailbox), do: "No match"

  defp format_datetime(nil), do: "Pending"

  defp format_datetime(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")

  defp present(value) when value in [nil, ""], do: "—"
  defp present(value), do: value
end
