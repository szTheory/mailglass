defmodule MailglassAdmin.Inbound.DetailHeader do
  @moduledoc """
  Selected inbound-record summary header.

  Sibling of `MailglassAdmin.Operator.DetailHeader` (D-48-13). Receives the
  detail read-model map `%{record: %InboundRecord{}, mailbox:, outcome:,
  outcome_reason:, evidence:}` from `MailglassInbound.Internal.Operator.Detail`.

  CRITICAL (Pitfall 2): the `:suppression_flagged` field does NOT exist on any
  Phase 48 schema — it lands in Phase 49. The flag is read with
  `Map.get(record, :suppression_flagged, false)`, NEVER via dot-access on a missing
  struct key (which raises `KeyError`). The IOPS-05 copy renders only when the flag
  is truthy, so it is forward-compatible scaffolding that simply never renders until
  Phase 49.
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
      <div class="flex flex-wrap items-start justify-between gap-4">
        <div class="space-y-2">
          <div class="flex flex-wrap items-center gap-2">
            <h2 class="text-xl font-bold text-base-content">
              {Components.mask_recipient(@record.envelope_recipient)}
            </h2>
            <span class={["badge", badge_class(@outcome)]}>
              {outcome_label(@outcome)}
            </span>
          </div>
          <p class="mono text-xs text-secondary">{@record.id}</p>
          <p
            :if={suppression_flagged?(@record)}
            data-testid="inbound-suppression-flag"
            class="text-sm text-warning"
          >
            Sender suppressed: this message was flagged, not bounced, to preserve diagnostic signal.
          </p>
        </div>

        <dl class="grid gap-3 text-sm text-secondary sm:grid-cols-2">
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Tenant</dt>
            <dd class="mt-1 text-base-content">{@record.tenant_id}</dd>
          </div>
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Provider</dt>
            <dd class="mt-1 text-base-content">{String.upcase(@record.provider || "unknown")}</dd>
          </div>
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">From</dt>
            <dd class="mt-1 text-base-content">{Components.mask_recipient(@record.envelope_recipient)}</dd>
          </div>
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Subject</dt>
            <dd class="mt-1 text-base-content">{present(@record.subject)}</dd>
          </div>
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Received</dt>
            <dd class="mono mt-1 text-base-content">{format_datetime(@record.received_at)}</dd>
          </div>
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Matched mailbox</dt>
            <dd class="mt-1 text-base-content">{matched_mailbox(@mailbox)}</dd>
          </div>
        </dl>
      </div>

      <div class="mt-6 flex flex-wrap items-start justify-between gap-4 border-t border-base-300 pt-4">
        <div class="space-y-1">
          <h3 class="text-sm font-bold uppercase tracking-[0.08em] text-secondary">Replay</h3>
          <p class="text-sm text-base-content">{replay_hint(@outcome)}</p>
        </div>

        <button
          type="button"
          phx-click="open_replay"
          data-testid="inbound-replay-open"
          disabled={replay_disabled?(@outcome)}
          class={["btn btn-error min-h-11 px-5", replay_disabled?(@outcome) && "btn-disabled"]}
        >
          Replay inbound
        </button>
      </div>
    </article>
    """
  end

  # Pitfall 2 — defensive read; the field does not exist until Phase 49.
  defp suppression_flagged?(record), do: Map.get(record, :suppression_flagged, false)

  # Pitfall 1 — a :no_match record can never replay (no prior matched mailbox).
  defp replay_disabled?(:no_match), do: true
  defp replay_disabled?(_outcome), do: false

  defp replay_hint(:no_match),
    do: "Replay is unavailable: this message did not match any mailbox."

  defp replay_hint(_outcome),
    do: "Replay re-runs mailbox routing against the stored message and records a new replay run."

  defp matched_mailbox(mailbox) when is_binary(mailbox) and mailbox != "", do: mailbox
  defp matched_mailbox(_mailbox), do: "No match"

  defp badge_class(:accept), do: "badge-success"
  defp badge_class(:no_match), do: "badge-warning"
  defp badge_class(outcome) when outcome in [:reject, :bounce, :failed], do: "badge-error"
  defp badge_class(:ignore), do: "badge-outline"
  defp badge_class(_outcome), do: "badge-outline"

  defp outcome_label(nil), do: "Pending"

  defp outcome_label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_datetime(nil), do: "Pending"

  defp format_datetime(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")

  defp present(value) when value in [nil, ""], do: "—"
  defp present(value), do: value
end
