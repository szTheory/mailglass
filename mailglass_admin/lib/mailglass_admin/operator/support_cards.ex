defmodule MailglassAdmin.Operator.SupportCards do
  @moduledoc """
  Read-only tenant-scoped support cues for the selected delivery context.
  """

  use Phoenix.Component

  alias MailglassAdmin.Operator.RepairState

  attr(:support_summary, :map, required: true)
  attr(:support_state, :map, required: true)

  def support_cards(assigns) do
    ~H"""
    <section
      data-testid="operator-support-cards"
      class="card rounded-box border border-base-300 bg-base-200 p-6"
    >
      <div class="flex flex-wrap items-start justify-between gap-3">
        <div class="space-y-1">
          <h3 class="text-base font-bold text-base-content">Support cards</h3>
          <p class="text-sm text-secondary">
            Tenant-scoped facts from the current support window.
          </p>
        </div>
        <span class="badge badge-outline">Read-only</span>
      </div>

      <div class="mt-4 grid gap-4 xl:grid-cols-2">
        <article class="rounded-box border border-base-300 bg-base-100 p-4">
          <div class="flex items-start justify-between gap-3">
            <div>
              <h4 class="text-sm font-bold text-base-content">Failed ingest</h4>
              <p class="mt-1 text-sm text-secondary">
                Recent webhook rows that failed before mailglass could project durable delivery facts.
              </p>
            </div>
            <span class="badge badge-error badge-outline">
              {@support_summary.failed_ingest.count}
            </span>
          </div>

          <div :if={@support_summary.failed_ingest.latest} class="mt-4 space-y-2">
            <p class="text-xs text-secondary">
              Exemplar webhook row: {@support_summary.failed_ingest.latest.provider_event_id}
            </p>
            <button
              type="button"
              phx-click="open_support_exemplar"
              phx-value-focus="failed_ingest"
              phx-value-webhook_event_id={@support_summary.failed_ingest.latest.webhook_event_id}
              data-testid="support-card-failed-ingest-drilldown"
              class="btn btn-ghost btn-sm px-3"
            >
              Open webhook row
            </button>

            <dl
              :if={focused?(@support_state, :failed_ingest)}
              data-testid="support-card-failed-ingest-detail"
              class="grid gap-2 text-sm text-secondary"
            >
              <div>
                <dt class="text-xs font-bold uppercase tracking-[0.08em]">Webhook row ID</dt>
                <dd class="mono mt-1 text-base-content">
                  {@support_summary.failed_ingest.latest.webhook_event_id}
                </dd>
              </div>
              <div>
                <dt class="text-xs font-bold uppercase tracking-[0.08em]">Provider event</dt>
                <dd class="mt-1 text-base-content">
                  {@support_summary.failed_ingest.latest.provider_event_id}
                </dd>
              </div>
            </dl>
          </div>
        </article>

        <article class="rounded-box border border-base-300 bg-base-100 p-4">
          <div class="flex items-start justify-between gap-3">
            <div>
              <h4 class="text-sm font-bold text-base-content">Orphan backlog</h4>
              <p class="mt-1 text-sm text-secondary">
                Current unmatched webhook facts waiting on reconcile linkage.
              </p>
            </div>
            <span class="badge badge-warning badge-outline">
              {@support_summary.orphan_backlog.count}
            </span>
          </div>

          <div :if={@support_summary.orphan_backlog.oldest} class="mt-4 space-y-2">
            <p class="text-xs text-secondary">
              Oldest unmatched fact: {@support_summary.orphan_backlog.oldest.provider_event_id}
            </p>
            <button
              type="button"
              phx-click="open_support_exemplar"
              phx-value-focus="orphan_backlog"
              phx-value-event_id={@support_summary.orphan_backlog.oldest.event_id}
              data-testid="support-card-orphan-backlog-drilldown"
              class="btn btn-ghost btn-sm px-3"
            >
              Open unmatched fact
            </button>

            <dl
              :if={focused?(@support_state, :orphan_backlog)}
              data-testid="support-card-orphan-backlog-detail"
              class="grid gap-2 text-sm text-secondary"
            >
              <div>
                <dt class="text-xs font-bold uppercase tracking-[0.08em]">Event ID</dt>
                <dd class="mono mt-1 text-base-content">
                  {@support_summary.orphan_backlog.oldest.event_id}
                </dd>
              </div>
              <div>
                <dt class="text-xs font-bold uppercase tracking-[0.08em]">Provider event</dt>
                <dd class="mt-1 text-base-content">
                  {@support_summary.orphan_backlog.oldest.provider_event_id}
                </dd>
              </div>
            </dl>
          </div>
        </article>

        <article class="rounded-box border border-base-300 bg-base-100 p-4">
          <div class="flex items-start justify-between gap-3">
            <div>
              <h4 class="text-sm font-bold text-base-content">Replay outcomes</h4>
              <p class="mt-1 text-sm text-secondary">
                Replay audit facts stay separate from provider lifecycle facts.
              </p>
            </div>
            <span class="badge badge-outline">
              {replay_count_summary(@support_summary.replay_outcomes.counts)}
            </span>
          </div>

          <div :if={@support_summary.replay_outcomes.latest} class="mt-4 space-y-2">
            <p class="text-xs text-secondary">
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
              class="btn btn-ghost btn-sm px-3"
            >
              Open replay audit
            </button>
            <p class="mono text-xs text-secondary">
              {@support_summary.replay_outcomes.latest.event_id}
            </p>
          </div>
        </article>

        <article class="rounded-box border border-base-300 bg-base-100 p-4">
          <div class="flex items-start justify-between gap-3">
            <div>
              <h4 class="text-sm font-bold text-base-content">Reconcile facts</h4>
              <p class="mt-1 text-sm text-secondary">
                Linked facts and still unmatched pressure stay separate from replay audit.
              </p>
            </div>
            <span class="badge badge-outline">
              linked {@support_summary.reconcile_facts.reconciled_count} · pressure {@support_summary.reconcile_facts.still_unmatched_count}
            </span>
          </div>

          <div :if={@support_summary.reconcile_facts.latest_reconciled} class="mt-4 space-y-2">
            <p class="text-xs text-secondary">
              Exemplar linked fact: {@support_summary.reconcile_facts.latest_reconciled.reconciled_provider_event_id}
            </p>
            <button
              type="button"
              phx-click="open_support_exemplar"
              phx-value-focus="reconcile_facts"
              phx-value-event_id={@support_summary.reconcile_facts.latest_reconciled.event_id}
              phx-value-delivery_id={@support_summary.reconcile_facts.latest_reconciled.delivery_id}
              data-testid="support-card-reconcile-facts-drilldown"
              class="btn btn-ghost btn-sm px-3"
            >
              Open linked fact
            </button>
            <p class="mono text-xs text-secondary">
              {@support_summary.reconcile_facts.latest_reconciled.event_id}
            </p>
          </div>
        </article>
      </div>

      <div
        :if={drilldown_banner(@support_state)}
        data-testid="support-card-drilldown-banner"
        class="mt-4 rounded-box border border-primary/30 bg-primary/5 px-4 py-3 text-sm text-base-content"
      >
        {drilldown_banner(@support_state)}
      </div>
    </section>
    """
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
