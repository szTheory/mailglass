# Phase 24: Tenant-Safe Webhook Replay with Audit Context - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a tenant-safe operator workflow for replaying a webhook from the admin surface, with durable audit context for who triggered it, what was replayed, and when.

This phase is about safe targeted replay of already-received webhook requests. It is not a general event-store backfill system, not a bulk incident replay product, and not a semantic reprocessing framework for arbitrary domain state rebuilds.

</domain>

<decisions>
## Implementation Decisions

### Replay target shape
- **D-24-01:** The canonical replay unit is a single `mailglass_webhook_events` row, not a `mailglass_deliveries` row and not a normalized `mailglass_events` child row.
- **D-24-02:** The operator delivery screen may expose replay as a convenience entrypoint, but it must resolve to one exact raw webhook row before any replay occurs.
- **D-24-03:** If a selected delivery has exactly one replayable raw webhook row, the UI may preselect it. If it has multiple replayable rows, the operator must choose one explicitly. If it has none, replay is unavailable and the UI must say why.
- **D-24-04:** Do not ship “replay latest,” “replay all for this delivery,” or any broader batch/window replay surface in Phase 24. Those are separate incident-recovery capabilities with materially higher blast radius.

### Replay UX
- **D-24-05:** Replay should be initiated from the selected-delivery detail experience, not from the master list.
- **D-24-06:** Use a server-rendered LiveView modal for replay confirmation. Do not use a browser `confirm()` and do not navigate to a separate replay page in Phase 24.
- **D-24-07:** The modal must show the exact replay target context before confirmation: provider, webhook timestamp, provider event id, and the delivery linkage if present.
- **D-24-08:** Replay result UX should stay in place on the same LiveView: transient flash plus durable audit/result visibility in the detail pane. Operators should inspect, confirm, get the result, and continue without leaving context.

### Auth and tenant safety
- **D-24-09:** Replay is a `:destructive_action` through the existing `MailglassAdmin.Auth` seam.
- **D-24-10:** Recent-auth is required only when `recent_auth_at` is missing or stale. Do not force a fresh step-up for every replay click.
- **D-24-11:** The replay authorization check must happen at action time in the LiveView event handler or server-side replay command path, not only at mount time.
- **D-24-12:** Replay commands must require `tenant_id`, `webhook_event_id`, and actor context. Delivery id may be passed as contextual metadata, but it is not the replay identity.
- **D-24-13:** Tenant scope must be enforced before target lookup, before audit writes, and before replay execution. No unscoped replay lookup path is acceptable.

### Audit durability and visibility
- **D-24-14:** Durable replay audit facts belong in the append-only `mailglass_events` ledger, not as the primary source of truth on mutable `mailglass_webhook_events` fields.
- **D-24-15:** Phase 24 should emit explicit replay audit events for at least:
  - replay requested
  - replay succeeded
  - replay failed
- **D-24-16:** Replay audit metadata must capture enough operator context to answer “who replayed what, when, and with what outcome?” without consulting transient UI state.
- **D-24-17:** Replay audit facts should appear both inline in the selected delivery’s timeline when relevant and in a dedicated replay-history view or filtered read model. Flash alone is insufficient.
- **D-24-18:** If convenience summary fields are later added to `mailglass_webhook_events`, they are secondary cached projections only, never the audit source of truth.

### Scope and safety boundaries
- **D-24-19:** Phase 24 replay is delivery-layer recovery, not domain-state rebuild. Replaying a webhook means re-running the verified ingest path for one stored inbound request, with existing idempotency and verification boundaries still intact.
- **D-24-20:** Do not expose partial replay of normalized child events from one raw provider request unless a later phase proves that semantic split is safe.
- **D-24-21:** Duplicate/no-op outcomes are valid and should be surfaced clearly to operators. Manual replay must not imply that downstream side effects definitely changed.
- **D-24-22:** Broader “replay all failures,” time-window replays, or rebuild/backfill flows remain deferred until there is explicit product intent, throttling strategy, and stronger incident-ops design.

### Decision posture for downstream agents
- **D-24-23:** Downstream planning and execution should remain decisive by default: research tradeoffs, choose the coherent default, and avoid escalating routine local choices back to the user.
- **D-24-24:** Escalate only if a choice would materially change:
  - tenant trust boundaries
  - replay retention or raw-payload lifecycle policy
  - public admin/router/auth contract
  - long-term maintainer burden through new replay modes or background infrastructure
  - user-visible safety semantics that would surprise operators

### the agent's Discretion
- Exact freshness window length for stale recent-auth, as long as it is enforced server-side and documented clearly.
- Exact replay audit event names, as long as they are explicit, append-only, and easy to query.
- Exact placement of the replay CTA within the detail pane, as long as it does not appear in the master list and the confirmation flow remains contextual and low-surprise.
- Exact replay-history presentation shape, as long as it is backed by append-only ledger facts rather than mutable “last replay” fields.

</decisions>

<specifics>
## Specific Ideas

- The operator surface should stay delivery-first in the UI while remaining webhook-row-first in the actual replay command semantics.
- Strong DX here means:
  - exact target selection
  - tenant-safe lookup by construction
  - one server-side auth seam
  - one canonical replay command
  - explicit duplicate/no-op outcomes
  - durable audit evidence without inventing a second truth store
- The user preference for this project remains:
  - research first
  - choose coherent defaults
  - escalate only for truly high-impact contract choices

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and current project posture
- `.planning/ROADMAP.md` — Phase 24 goal, dependency on Phase 23, and replay scope anchor.
- `.planning/PROJECT.md` — v0.4 operator-confidence goal, Phoenix-first package posture, maintainer constraints, and multi-tenant-first product stance.
- `.planning/REQUIREMENTS.md` — `REPLAY-01`, `REPLAY-02`, `REPLAY-03` requirement definitions.
- `.planning/STATE.md` — current milestone state and the fact that Phase 23 finished the auth seam for future destructive actions.
- `.planning/METHODOLOGY.md` — project-level decisive-by-default and honest-surface lenses.

### Prior phase constraints now locked
- `.planning/phases/22-operator-data-foundation/22-UI-SPEC.md` — operator screen contract, read-only baseline, and detail-pane interaction model.
- `.planning/phases/23-production-admin-mount-and-step-up-auth/23-01-SUMMARY.md` — operator route/session boundary split.
- `.planning/phases/23-production-admin-mount-and-step-up-auth/23-02-SUMMARY.md` — adopter-owned auth seam and normalized `recent_auth_at` context for future destructive actions.
- `.planning/phases/23-production-admin-mount-and-step-up-auth/23-03-SUMMARY.md` — locked production operator mount docs and non-goals carried into Phase 24.
- `.planning/milestones/v0.3-phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md` — decisive-by-default project posture and prior GSD preference capture.

### Existing implementation seams
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — current delivery-first operator LiveView that must host replay affordances.
- `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` — candidate location for replay CTA and immediate replay-result visibility.
- `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` — current inline event-history renderer to extend with replay audit events.
- `mailglass_admin/lib/mailglass_admin/auth.ex` — canonical auth/actor normalization seam.
- `mailglass_admin/lib/mailglass_admin/operator/mount.ex` — mount-time operator authorization context.
- `lib/mailglass/operator/deliveries.ex` — tenant-scoped delivery read model.
- `lib/mailglass/operator/timeline.ex` — tenant-scoped timeline read model for ledger events.
- `lib/mailglass/webhook/webhook_event.ex` — raw inbound webhook storage and replayable target identity.
- `lib/mailglass/webhook/ingest.ex` — verified ingest/idempotency path the replay flow should reuse rather than fork semantically.
- `lib/mailglass/events.ex` — append-only audit write surface.
- `lib/mailglass/events/event.ex` — ledger event schema and allowed type discipline.
- `lib/mailglass/tenancy.ex` — tenant stamping and scoped-query invariants.

### External precedent and ecosystem priors
- `https://docs.stripe.com/webhooks?lang=node` — manual resend is event-targeted and distinct from automatic retries.
- `https://docs.stripe.com/webhooks/process-undelivered-events?locale=en-GB` — manual recovery is still idempotency-sensitive and separate from provider retry semantics.
- `https://docs.github.com/en/webhooks/testing-and-troubleshooting-webhooks/viewing-webhook-deliveries` — delivery inspection details worth surfacing in operator UX.
- `https://docs.github.com/en/webhooks/testing-and-troubleshooting-webhooks/redelivering-webhooks` — explicit redelivery of a specific delivery, not blanket semantic reprocessing.
- `https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/sudo-mode` — recent-auth model for sensitive actions.
- `https://hexdocs.pm/phoenix_live_view/security-model.html` — action-time server-side enforcement expectations for LiveView.
- `https://shopify.dev/docs/apps/build/webhooks/troubleshooting-webhooks` — operator-facing delivery troubleshooting signals and failure handling posture.
- `https://hookdeck.com/` — delivery inspection/replay positioning as operator tooling, not generic state rebuild.
- `https://hexdocs.pm/oban/unique_jobs.html` — dedupe primitive for any queued replay execution path.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MailglassAdmin.Auth` and `MailglassAdmin.Operator.Mount` already define the exact seam Phase 24 should use for replay authorization.
- `MailglassAdmin.OperatorLive` already preserves URL-backed selection state, making in-place replay UX a better fit than route-heavy flows.
- `Mailglass.Webhook.WebhookEvent` already stores the exact raw payload identity replay should target.
- `Mailglass.Webhook.Ingest` already embodies the verified ingest/idempotent persistence path; replay should reuse this behavior rather than inventing a parallel semantic path.
- `Mailglass.Events.append/1` already provides the append-only audit surface needed for replay breadcrumbs.

### Established Patterns
- Public/operator route surfaces stay explicit and narrowly scoped.
- Tenant-aware read models fail loud when `tenant_id` is missing.
- Append-only ledger facts are the durable truth; mutable tables are for operational/process state.
- The operator UI is master-detail and read-mostly; destructive actions should be contextual and server-driven.

### Integration Points
- The replay service must join operator auth context, tenant scope, raw webhook row lookup, and append-only audit writes in one coherent path.
- The operator delivery detail surface needs a replayable-target resolver that maps a selected delivery to zero, one, or many raw webhook rows without guessing.
- Timeline rendering will need to distinguish provider lifecycle events from operator replay audit events without confusing the two.
- Any queued replay execution must preserve tenant context and dedupe/idempotency guarantees end-to-end.

</code_context>

<deferred>
## Deferred Ideas

- Replay all failed webhook deliveries for a tenant/provider/time window.
- Delivery-wide or batch replay with throttling/backpressure controls.
- General backfill/rebuild tooling for projections or domain state beyond webhook delivery recovery.
- Mutable summary fields on webhook rows as a primary replay audit mechanism.
- Partial replay of normalized child events from a shared raw provider payload.

</deferred>

---

*Phase: 24-tenant-safe-webhook-replay-with-audit-context*
*Context gathered: 2026-05-01*
