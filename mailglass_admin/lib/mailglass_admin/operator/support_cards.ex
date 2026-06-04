defmodule MailglassAdmin.Operator.SupportCards do
  @moduledoc """
  Read-only tenant-scoped support cues for the selected delivery context.

  Two-tier hierarchy per 74-UI-SPEC.md Support-Card Primary/Secondary Hierarchy Layout:
  - Tier 1: full card containers for non-zero/actionable counts (failed ingest, orphan backlog)
  - Tier 2: compact horizontal row for zero-state items and the always-informational suppression count
  """

  use Phoenix.Component

  alias MailglassAdmin.Operator.RepairState

  attr(:support_summary, :map, required: true)
  attr(:support_state, :map, required: true)
  attr(:suppression_count, :integer, default: nil)

  def support_cards(assigns) do
    ~H"""
    <section
      data-testid="operator-support-cards"
      class="card rounded-box border border-base-300 bg-base-200 p-md"
    >
      <div class="flex flex-wrap items-start justify-between gap-sm">
        <div class="space-y-1">
          <h3 class="text-body font-bold text-base-content">Support cards</h3>
          <p class="text-label text-secondary">
            Tenant-scoped facts from the current support window.
          </p>
        </div>
        <span class="badge badge-outline">Read-only</span>
      </div>

      <%!-- Tier 1: non-zero/actionable counts — full card containers --%>
      <div class="flex flex-col gap-lg mt-md">
        <article
          :if={@support_summary && @support_summary.failed_ingest.count > 0}
          class="card bg-base-200 border border-base-300 rounded-box p-lg"
          data-testid="support-card-failed-ingest-tier1"
        >
          <div class="text-display font-bold text-error">
            {@support_summary.failed_ingest.count}
          </div>
          <p class="text-body text-secondary">Recent failures (last 24h)</p>

          <div :if={@support_summary.failed_ingest.latest} class="mt-sm space-y-2">
            <p class="text-label text-secondary">
              Exemplar webhook row: {@support_summary.failed_ingest.latest.provider_event_id}
            </p>
            <button
              type="button"
              phx-click="open_support_exemplar"
              phx-value-focus="failed_ingest"
              phx-value-webhook_event_id={@support_summary.failed_ingest.latest.webhook_event_id}
              data-testid="support-card-failed-ingest-drilldown"
              class="btn btn-sm btn-primary mt-sm"
            >
              View failures
            </button>

            <dl
              :if={focused?(@support_state, :failed_ingest)}
              data-testid="support-card-failed-ingest-detail"
              class="grid gap-sm text-body text-secondary"
            >
              <div>
                <dt class="text-label font-bold uppercase tracking-[0.08em]">Webhook row ID</dt>
                <dd class="mono mt-1 text-base-content">
                  {@support_summary.failed_ingest.latest.webhook_event_id}
                </dd>
              </div>
              <div>
                <dt class="text-label font-bold uppercase tracking-[0.08em]">Provider event</dt>
                <dd class="mt-1 text-base-content">
                  {@support_summary.failed_ingest.latest.provider_event_id}
                </dd>
              </div>
            </dl>
          </div>
        </article>

        <article
          :if={@support_summary && @support_summary.orphan_backlog.count > 0}
          class="card bg-base-200 border border-base-300 rounded-box p-lg"
          data-testid="support-card-orphan-backlog-tier1"
        >
          <div class="text-display font-bold text-warning">
            {@support_summary.orphan_backlog.count}
          </div>
          <p class="text-body text-secondary">Orphan backlog</p>

          <div :if={@support_summary.orphan_backlog.oldest} class="mt-sm space-y-2">
            <p class="text-label text-secondary">
              Oldest unmatched fact: {@support_summary.orphan_backlog.oldest.provider_event_id}
            </p>
            <button
              type="button"
              phx-click="open_support_exemplar"
              phx-value-focus="orphan_backlog"
              phx-value-event_id={@support_summary.orphan_backlog.oldest.event_id}
              data-testid="support-card-orphan-backlog-drilldown"
              class="btn btn-sm btn-primary mt-sm"
            >
              View backlog
            </button>

            <dl
              :if={focused?(@support_state, :orphan_backlog)}
              data-testid="support-card-orphan-backlog-detail"
              class="grid gap-sm text-body text-secondary"
            >
              <div>
                <dt class="text-label font-bold uppercase tracking-[0.08em]">Event ID</dt>
                <dd class="mono mt-1 text-base-content">
                  {@support_summary.orphan_backlog.oldest.event_id}
                </dd>
              </div>
              <div>
                <dt class="text-label font-bold uppercase tracking-[0.08em]">Provider event</dt>
                <dd class="mt-1 text-base-content">
                  {@support_summary.orphan_backlog.oldest.provider_event_id}
                </dd>
              </div>
            </dl>
          </div>
        </article>

        <article
          :if={@support_summary && replay_any_nonzero?(@support_summary.replay_outcomes.counts)}
          class="card bg-base-200 border border-base-300 rounded-box p-lg"
          data-testid="support-card-replay-outcomes-tier1"
        >
          <div class="text-display font-bold text-error">
            {@support_summary.replay_outcomes.counts.failed}
          </div>
          <p class="text-body text-secondary">
            Replay outcomes: {replay_count_summary(@support_summary.replay_outcomes.counts)}
          </p>

          <div :if={@support_summary.replay_outcomes.latest} class="mt-sm space-y-2">
            <p class="text-label text-secondary">
              Exemplar replay audit: {RepairState.effect_label(@support_summary.replay_outcomes.latest.outcome) ||
                @support_summary.replay_outcomes.latest.outcome}
            </p>
            <button
              type="button"
              phx-click="open_support_exemplar"
              phx-value-focus="replay_outcomes"
              phx-value-event_id={@support_summary.replay_outcomes.latest.event_id}
              phx-value-delivery_id={@support_summary.replay_outcomes.latest.delivery_id}
              data-testid="support-card-replay-outcomes-drilldown"
              class="btn btn-sm btn-primary mt-sm"
            >
              Open replay audit
            </button>
            <p class="mono text-label text-secondary">
              {@support_summary.replay_outcomes.latest.event_id}
            </p>
          </div>
        </article>
      </div>

      <%!-- Tier 2: zero-state compact row — informational items always visible --%>
      <div class="border-t border-base-300 flex flex-wrap gap-md items-center py-sm text-label text-secondary mt-md">
        <span :if={not (@support_summary && @support_summary.failed_ingest.count > 0)}>
          No failures
        </span>
        <span
          :if={not (@support_summary && @support_summary.failed_ingest.count > 0) and not (@support_summary && @support_summary.orphan_backlog.count > 0)}
          aria-hidden="true"
        >·</span>
        <span :if={not (@support_summary && @support_summary.orphan_backlog.count > 0)}>
          No orphan backlog
        </span>
        <span aria-hidden="true">·</span>
        <span data-testid="support-card-suppression-count">
          Active suppressions: {if @suppression_count, do: @suppression_count, else: "—"}
        </span>
        <span
          :if={@support_summary && @support_summary.reconcile_facts.reconciled_count > 0}
          aria-hidden="true"
        >·</span>
        <span :if={@support_summary && @support_summary.reconcile_facts.reconciled_count > 0}>
          Reconciled: {@support_summary.reconcile_facts.reconciled_count}
        </span>
        <span
          :if={@support_summary && @support_summary.reconcile_facts.still_unmatched_count > 0}
          aria-hidden="true"
        >·</span>
        <span
          :if={@support_summary && @support_summary.reconcile_facts.still_unmatched_count > 0}
          data-testid="support-card-reconcile-facts-drilldown"
        >
          <button
            type="button"
            phx-click="open_support_exemplar"
            phx-value-focus="reconcile_facts"
            phx-value-event_id={
              @support_summary.reconcile_facts.latest_reconciled &&
                @support_summary.reconcile_facts.latest_reconciled.event_id
            }
            phx-value-delivery_id={
              @support_summary.reconcile_facts.latest_reconciled &&
                @support_summary.reconcile_facts.latest_reconciled.delivery_id
            }
            class="btn btn-ghost btn-sm px-3"
          >
            Unmatched pressure: {@support_summary.reconcile_facts.still_unmatched_count}
          </button>
        </span>
      </div>

      <div
        :if={drilldown_banner(@support_state)}
        data-testid="support-card-drilldown-banner"
        class="mt-md rounded-box border border-primary/30 bg-primary/5 px-md py-sm text-body text-base-content"
      >
        {drilldown_banner(@support_state)}
      </div>
    </section>
    """
  end

  defp replay_any_nonzero?(counts) do
    counts.failed > 0 or counts.noop > 0 or counts.replayed > 0
  end

  defp replay_count_summary(counts) do
    "failed #{counts.failed} · no change #{counts.noop} · new work #{counts.replayed}"
  end

  defp drilldown_banner(%{focus: :failed_ingest}), do: "Showing failed ingest webhook row"
  defp drilldown_banner(%{focus: :orphan_backlog}), do: "Showing unmatched reconcile fact"
  defp drilldown_banner(%{focus: :replay_outcomes}), do: "Showing replay audit fact"
  defp drilldown_banner(%{focus: :reconcile_facts}), do: "Showing reconcile fact"
  defp drilldown_banner(_support_state), do: nil

  defp focused?(%{focus: focus}, current_focus), do: focus == current_focus
  defp focused?(_support_state, _current_focus), do: false
end
