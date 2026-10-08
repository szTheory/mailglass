defmodule MailglassAdmin.Operator.SupportCards do
  @moduledoc """
  Read-only tenant-scoped support cues for the selected delivery context.

  Two-tier hierarchy per 74-UI-SPEC.md Support-Card Primary/Secondary Hierarchy Layout:
  - Tier 1: full card containers for non-zero/actionable counts (failed ingest, unmatched webhooks)
  - Tier 2: compact horizontal row for zero-state items and the always-informational suppression count
  """

  use Phoenix.Component

  import MailglassAdmin.Components, only: [card: 1]

  alias MailglassAdmin.Operator.RepairState

  attr(:support_summary, :map, required: true)
  attr(:support_state, :map, required: true)
  attr(:suppression_count, :integer, default: nil)
  attr(:exact_support_evidence, :map, default: %{status: :none})
  attr(:exact_delivery_path, :string, default: nil)

  def support_cards(assigns) do
    ~H"""
    <.card
      padding={:md}
      data-testid="operator-support-cards"
      data-group-card="operator-support-cards"
      class="shadow-raised"
    >
      <div class="flex flex-wrap items-start justify-between gap-sm">
        <div class="space-y-xs">
          <h3 class="text-body font-bold text-base-content">Support cards</h3>
          <p class="text-label text-secondary">
            Account-scoped facts from the current support window.
          </p>
        </div>
        <span class="badge badge-outline">Read-only</span>
      </div>

      <section
        :if={@exact_support_evidence.status != :none}
        data-testid="operator-support-exact-evidence"
        class="mt-md rounded-box border border-base-300 bg-base-100 p-md"
      >
        <h4 class="text-body font-bold text-base-content">
          {exact_evidence_title(@exact_support_evidence.focus)}
        </h4>
        <p
          :if={@exact_support_evidence.status == :unavailable}
          role="status"
          data-testid="operator-support-exact-unavailable"
          class="mt-xs text-body text-warning"
        >
          This exact Account support record could not be loaded. The requested ID is retained.
        </p>
        <p
          :if={@exact_support_evidence.status == :not_found}
          role="status"
          data-testid="operator-support-exact-not-found"
          class="mt-xs text-body text-secondary"
        >
          This exact support record is unavailable for this Account.
        </p>
        <p
          :if={@exact_support_evidence.status == :stale}
          role="status"
          data-testid="operator-support-exact-stale"
          class="mt-xs text-body text-warning"
        >
          Showing the last retrieved version of this exact record.
        </p>
        <dl
          :if={@exact_support_evidence.status in [:ready, :stale] && is_map(@exact_support_evidence.record)}
          class="mt-sm grid gap-sm text-body text-secondary"
        >
          <div>
            <dt class="text-label uppercase font-bold">Exact record ID</dt>
            <dd class="mono mt-xs break-all text-base-content" data-testid="operator-support-exact-id">
              {exact_record_id(@exact_support_evidence)}
            </dd>
          </div>
          <div :if={exact_provider(@exact_support_evidence)}>
            <dt class="text-label uppercase font-bold">Provider</dt>
            <dd class="mono mt-xs break-all text-base-content">{exact_provider(@exact_support_evidence)}</dd>
          </div>
          <div :if={exact_provider_event_id(@exact_support_evidence)}>
            <dt class="text-label uppercase font-bold">Provider event</dt>
            <dd class="mono mt-xs break-all text-base-content">
              {exact_provider_event_id(@exact_support_evidence)}
            </dd>
          </div>
          <div>
            <dt class="text-label uppercase font-bold">Recorded time</dt>
            <dd class="mt-xs break-all text-base-content">
              {exact_recorded_at(@exact_support_evidence)}
            </dd>
          </div>
          <div :if={exact_status(@exact_support_evidence)}>
            <dt class="text-label uppercase font-bold">Stored status</dt>
            <dd class="mt-xs text-base-content">{exact_status(@exact_support_evidence)}</dd>
          </div>
          <div :if={@exact_support_evidence.focus == :orphan_backlog}>
            <dt class="text-label uppercase font-bold">Delivery relationship</dt>
            <dd class="mt-xs text-base-content">
              {if @exact_support_evidence.record.delivery_id,
                do: "Linked Delivery: #{@exact_support_evidence.record.delivery_id}",
                else: "No Delivery linkage is recorded for this Event."}
            </dd>
            <.link
              :if={@exact_delivery_path}
              navigate={@exact_delivery_path}
              class="btn btn-secondary mt-sm min-h-11"
              data-testid="operator-support-linked-delivery"
            >
              Open linked Delivery {@exact_support_evidence.record.delivery_id}
            </.link>
          </div>
          <div :if={@exact_support_evidence.focus == :failed_ingest && @exact_delivery_path}>
            <dt class="text-label uppercase font-bold">Delivery relationship</dt>
            <dd class="mt-xs text-base-content">A unique linked Delivery is recorded.</dd>
            <.link
              navigate={@exact_delivery_path}
              class="btn btn-secondary mt-sm min-h-11"
              data-testid="operator-support-linked-delivery"
            >
              Open linked Delivery {@exact_support_evidence.record.delivery_id}
            </.link>
          </div>
        </dl>
        <p
          :if={@exact_support_evidence.status in [:ready, :stale] && is_nil(@exact_delivery_path) && @exact_support_evidence.focus == :failed_ingest}
          class="mt-sm text-label text-secondary"
        >
          No unique Delivery linkage is recorded for this webhook row.
        </p>
      </section>

      <%!-- Tier 1: non-zero/actionable counts — full card containers --%>
      <div class="flex flex-col gap-lg mt-md">
        <article
          :if={@support_summary && @support_summary.failed_ingest.count > 0}
          class="rounded-box bg-base-100 p-lg border-l-4 border-error"
          data-testid="support-card-failed-ingest-tier1"
        >
          <div class="text-display font-bold text-error">
            {@support_summary.failed_ingest.count}
          </div>
          <p class="text-body text-secondary">Failed webhook attempts in the selected Account window.</p>

          <div :if={@support_summary.failed_ingest.latest} class="mt-sm space-y-sm">
            <p class="text-label text-secondary">
              Exemplar webhook row: {@support_summary.failed_ingest.latest.provider_event_id}
            </p>
            <button
              type="button"
              phx-click="open_support_exemplar"
              phx-value-focus="failed_ingest"
              phx-value-webhook_event_id={@support_summary.failed_ingest.latest.webhook_event_id}
              data-testid="support-card-failed-ingest-drilldown"
              class="btn btn-primary px-md mt-sm min-h-11"
            >
              View failures
            </button>

            <dl
              :if={focused?(@support_state, :failed_ingest)}
              data-testid="support-card-failed-ingest-detail"
              class="grid gap-sm text-body text-secondary"
            >
              <div>
                <dt class="text-label uppercase font-bold">Webhook row ID</dt>
                <dd class="mono mt-xs text-base-content">
                  {@support_summary.failed_ingest.latest.webhook_event_id}
                </dd>
              </div>
              <div>
                <dt class="text-label uppercase font-bold">Provider event</dt>
                <dd class="mt-xs text-base-content">
                  {@support_summary.failed_ingest.latest.provider_event_id}
                </dd>
              </div>
            </dl>
          </div>
        </article>

        <article
          :if={@support_summary && @support_summary.orphan_backlog.count > 0}
          class="rounded-box bg-base-100 p-lg border-l-4 border-warning"
          data-testid="support-card-orphan-backlog-tier1"
        >
          <div class="text-display font-bold text-warning">
            {@support_summary.orphan_backlog.count}
          </div>
          <p class="text-body text-secondary">Unmatched Events in the selected Account window.</p>

          <div :if={@support_summary.orphan_backlog.oldest} class="mt-sm space-y-sm">
            <p class="text-label text-secondary">
              Oldest unmatched Event example: {@support_summary.orphan_backlog.oldest.provider_event_id}
            </p>
            <button
              type="button"
              phx-click="open_support_exemplar"
              phx-value-focus="orphan_backlog"
              phx-value-event_id={@support_summary.orphan_backlog.oldest.event_id}
              data-testid="support-card-orphan-backlog-drilldown"
              class="btn btn-primary px-md mt-sm min-h-11"
            >
              View evidence
            </button>

            <dl
              :if={focused?(@support_state, :orphan_backlog)}
              data-testid="support-card-orphan-backlog-detail"
              class="grid gap-sm text-body text-secondary"
            >
              <div>
                <dt class="text-label uppercase font-bold">Event ID</dt>
                <dd class="mono mt-xs text-base-content">
                  {@support_summary.orphan_backlog.oldest.event_id}
                </dd>
              </div>
              <div>
                <dt class="text-label uppercase font-bold">Provider event</dt>
                <dd class="mt-xs text-base-content">
                  {@support_summary.orphan_backlog.oldest.provider_event_id}
                </dd>
              </div>
            </dl>
          </div>
        </article>

        <article
          :if={reconcile_visible?(@support_summary)}
          class="rounded-box bg-base-100 p-lg border-l-4 border-info"
          data-testid="support-card-reconcile-facts-tier1"
        >
          <h4 class="text-body font-bold text-base-content">Reconciliation audit facts</h4>
          <p class="mt-xs text-label text-secondary">
            Recorded reconciliation facts for this Account support window.
          </p>
          <dl class="mt-sm grid gap-sm text-body text-secondary">
            <div>
              <dt class="text-label uppercase font-bold">Reconciled Events</dt>
              <dd class="mt-xs text-base-content">
                {count_or_unavailable(@support_summary.reconcile_facts.reconciled_count)}
              </dd>
            </div>
            <div>
              <dt class="text-label uppercase font-bold">Still unmatched</dt>
              <dd class="mt-xs text-base-content">
                {count_or_unavailable(@support_summary.reconcile_facts.still_unmatched_count)}
              </dd>
            </div>
          </dl>
          <button
            :if={@support_summary.reconcile_facts.latest_reconciled}
            type="button"
            phx-click="open_support_exemplar"
            phx-value-focus="reconcile_facts"
            phx-value-event_id={@support_summary.reconcile_facts.latest_reconciled.event_id}
            phx-value-delivery_id={@support_summary.reconcile_facts.latest_reconciled.delivery_id}
            data-testid="support-card-reconcile-facts-drilldown"
            class="btn btn-ghost mt-sm px-sm min-h-11"
          >
            View reconciliation audit
          </button>
        </article>

        <article
          :if={@support_summary && replay_any_nonzero?(@support_summary.replay_outcomes.counts)}
          class="rounded-box bg-base-100 p-lg border-l-4 border-error"
          data-testid="support-card-replay-outcomes-tier1"
        >
          <div class="text-display font-bold text-error">
            {@support_summary.replay_outcomes.counts.failed}
          </div>
          <p class="text-body text-secondary">
            Replay outcomes: {replay_count_summary(@support_summary.replay_outcomes.counts)}
          </p>

          <div :if={@support_summary.replay_outcomes.latest} class="mt-sm space-y-sm">
            <p class="text-label text-secondary">
              Exemplar replay audit: {RepairState.effect_label(
                @support_summary.replay_outcomes.latest.outcome
              ) ||
                @support_summary.replay_outcomes.latest.outcome}
            </p>
            <button
              type="button"
              phx-click="open_support_exemplar"
              phx-value-focus="replay_outcomes"
              phx-value-event_id={@support_summary.replay_outcomes.latest.event_id}
              phx-value-delivery_id={@support_summary.replay_outcomes.latest.delivery_id}
              data-testid="support-card-replay-outcomes-drilldown"
              class="btn btn-primary px-md mt-sm min-h-11"
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
        <span :if={summary_count(@support_summary, :failed_ingest) == 0}>
          No failed webhook attempts in this window
        </span>
        <span
          :if={summary_count(@support_summary, :failed_ingest) == 0 and summary_count(@support_summary, :orphan_backlog) == 0}
          aria-hidden="true"
        >
          ·
        </span>
        <span :if={summary_count(@support_summary, :orphan_backlog) == 0}>
          No unmatched Events in this window
        </span>
        <span :if={summary_count(@support_summary, :failed_ingest) == nil}>
          Failed webhook attempts unavailable
        </span>
        <span :if={summary_count(@support_summary, :orphan_backlog) == nil}>
          Unmatched Events unavailable
        </span>
        <span aria-hidden="true">·</span>
        <span data-testid="support-card-suppression-count">
          Active suppressions: {if @suppression_count, do: @suppression_count, else: "—"}
        </span>
      </div>

      <div
        :if={drilldown_banner(@support_state)}
        data-testid="support-card-drilldown-banner"
        class="mt-md rounded-box border border-primary/30 bg-primary/5 px-md py-sm text-body text-base-content"
      >
        {drilldown_banner(@support_state)}
      </div>
    </.card>
    """
  end

  defp exact_evidence_title(:failed_ingest), do: "Exact failed webhook"
  defp exact_evidence_title(:orphan_backlog), do: "Exact unmatched Event"
  defp exact_evidence_title(_evidence), do: "Exact support record"

  defp summary_count(summary, key) do
    case get_in(summary || %{}, [key, :count]) do
      count when is_integer(count) -> count
      _ -> nil
    end
  end

  defp reconcile_visible?(%{reconcile_facts: facts}) do
    is_integer(facts.reconciled_count) or is_integer(facts.still_unmatched_count)
  end

  defp reconcile_visible?(_summary), do: false

  defp count_or_unavailable(count) when is_integer(count), do: Integer.to_string(count)
  defp count_or_unavailable(_count), do: "Unavailable"

  defp exact_record_id(%{focus: :failed_ingest, record: %{webhook_event_id: id}}), do: id
  defp exact_record_id(%{focus: :orphan_backlog, record: %{event_id: id}}), do: id
  defp exact_record_id(_evidence), do: nil

  defp exact_provider(%{record: record}), do: record[:provider]
  defp exact_provider(_evidence), do: nil

  defp exact_provider_event_id(%{record: record}), do: record[:provider_event_id]
  defp exact_provider_event_id(_evidence), do: nil

  defp exact_recorded_at(%{record: %{received_at: %DateTime{} = at}}),
    do: DateTime.to_iso8601(at) <> " UTC"

  defp exact_recorded_at(%{record: %{occurred_at: %DateTime{} = at}}),
    do: DateTime.to_iso8601(at) <> " UTC"

  defp exact_recorded_at(_evidence), do: "Unavailable"

  defp exact_status(%{record: %{status: status}}) when is_atom(status),
    do: status |> Atom.to_string() |> String.capitalize()

  defp exact_status(%{record: %{event_type: event_type}}) when is_atom(event_type),
    do: event_type |> Atom.to_string() |> String.capitalize()

  defp exact_status(_evidence), do: nil

  defp replay_any_nonzero?(counts) do
    counts.failed > 0 or counts.noop > 0 or counts.replayed > 0
  end

  defp replay_count_summary(counts) do
    "failed #{counts.failed} · no change #{counts.noop} · new work #{counts.replayed}"
  end

  defp drilldown_banner(%{focus: :failed_ingest}), do: "Showing failed ingest webhook row"
  defp drilldown_banner(%{focus: :orphan_backlog}), do: "Showing unmatched webhook evidence"
  defp drilldown_banner(%{focus: :replay_outcomes}), do: "Showing replay audit fact"
  defp drilldown_banner(%{focus: :reconcile_facts}), do: "Showing reconcile fact"
  defp drilldown_banner(_support_state), do: nil

  defp focused?(%{focus: focus}, current_focus), do: focus == current_focus
  defp focused?(_support_state, _current_focus), do: false
end
