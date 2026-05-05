# Phase 33: Observability & Incident Support - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Give operators one coherent way to diagnose production delivery issues using the telemetry, backlog signals, replay/reconcile behavior, and admin capabilities mailglass already ships or can honestly expose in a mountable Phoenix support surface.

This phase is about making production support legible and trustworthy. It is not a hosted observability product, not a full embedded APM/dashboard suite, not a cross-tenant incident console, and not a new generalized analytics surface.

</domain>

<decisions>
## Implementation Decisions

### Support surface shape
- **D-33-01:** Phase 33 should ship a hybrid support surface:
  - one canonical operator-facing troubleshooting guide in docs
  - narrow operator-facing support entrypoints inside the existing `mailglass_admin` delivery UI
- **D-33-02:** Do not build a separate in-app observability dashboard or incident center in Phase 33. That would overbroaden the product promise and duplicate LiveDashboard / PromEx / APM territory.
- **D-33-03:** The admin surface should act as the operator starting point for one selected delivery and current support cues, while docs remain the canonical explanation layer for telemetry, incident diagnosis, and escalation paths.
- **D-33-04:** Support guidance, telemetry naming, and admin copy must use the same language. Phase 33 should reduce drift between `guides/telemetry.md`, `guides/webhook-troubleshooting.md`, `guides/webhooks.md`, and the operator UI.

### Incident playbook shape
- **D-33-05:** The troubleshooting guide should use a hybrid information architecture:
  - symptom-first index for operator entry
  - pipeline-stage drilldowns for canonical diagnosis steps
- **D-33-06:** Operators should be able to start from real support prompts such as:
  - “customer says the email never arrived”
  - “provider is retrying or timing out”
  - “orphan backlog is growing”
  - “replay completed but nothing changed”
  and then land on one canonical stage-specific checklist.
- **D-33-07:** Stage drilldowns should reflect the actual mailglass support model:
  - delivery send / projection state
  - webhook signature + ingest
  - orphan / reconcile backlog
  - replay / reconcile repair actions
- **D-33-08:** Every incident path should explicitly distinguish:
  - provider lifecycle facts
  - operator-triggered replay facts
  - background reconcile facts
  Do not flatten these into one vague “repair” story.
- **D-33-09:** Each troubleshooting branch should include an explicit “mailglass can tell you this / mailglass cannot tell you this” note so the support surface stays honest about the boundary between app-local evidence and provider-side evidence.

### Backlog and health signals
- **D-33-10:** Phase 33 should add read-only summary indicators to the existing operator surface rather than requiring operators to infer support posture from raw telemetry or CLI output alone.
- **D-33-11:** Summary indicators should be support-oriented and exemplar-friendly, not chart-heavy. They should answer “what needs attention now?” and lead operators toward a concrete delivery, webhook identity, or reconcile run.
- **D-33-12:** Candidate support cues for this phase include:
  - recent webhook ingest failures
  - orphan count and oldest orphan age
  - reconcile linked vs still-unmatched outcomes
  - replay outcomes split into failed / no change / new work
  - webhook silence or stall cues when they can be stated honestly
- **D-33-13:** Keep deeper dashboarding and time-series visualization optional and external-first via LiveDashboard, OpenTelemetry, PromEx, Grafana, Sentry, Honeycomb, or similar adopter tooling. Phase 33 should not make those stacks mandatory.
- **D-33-14:** Support cues in the admin surface must not imply real-time guarantees, fleet-wide completeness, or provider-side truth that the codebase cannot actually prove.

### PII and privacy posture
- **D-33-15:** Keep the hard no-PII rule for telemetry, logs, and docs. The existing whitelist posture remains structural and should not be relaxed in Phase 33.
- **D-33-16:** Do not overcorrect into a fully redacted operator UI that makes real support work impossible. Mailglass still needs to satisfy the core JTBD of diagnosing a specific message problem.
- **D-33-17:** Adopt a middle-ground UI privacy posture:
  - keep tenant-scoped operator detail useful for authorized operators
  - mask the most human-identifying fields by default in overview-style surfaces where practical
  - require explicit reveal or stronger auth posture for exact human-facing identifiers when appropriate
- **D-33-18:** Any masking/reveal posture introduced here is presentation-layer minimization, not a substitute for route auth, mount auth, action-time auth, tenant scoping, or data redaction at log/inspect boundaries.
- **D-33-19:** Future search, exports, summaries, notes, or AI-assisted support features must be treated as new PII leak paths and held to the same privacy posture. Do not solve only the header/list surface and leave secondary leak paths open.

### Support model and telemetry contract
- **D-33-20:** Phase 33 should stay delivery-centric. Support flows should start from a selected delivery where possible and use telemetry / backlog signals to explain what happened around that delivery, rather than introducing a separate generic observability product surface.
- **D-33-21:** Preserve exactness:
  - replay is exact-target and delivery-entrypoint only
  - reconcile is background-first sweep / backfill behavior
  - provider retries are external lifecycle facts
  The UI and docs must not blur these.
- **D-33-22:** Favor exemplars over aggregates. If a summary signal is surfaced, the operator should be able to drill toward a concrete delivery, raw webhook row, or durable audit fact rather than stopping at a green/red status pill.
- **D-33-23:** Integration guidance should include safe, minimal examples for adopter observability backends using the existing telemetry contract, especially LiveDashboard / OpenTelemetry / Sentry / Honeycomb style integrations, without making them required for mailglass supportability.

### Recommendation-first workflow posture
- **D-33-24:** Downstream research, planning, and implementation for this phase should remain recommendation-first and decisive by default:
  - research broadly
  - synthesize one coherent recommendation set
  - avoid pushing routine local tradeoffs back to the user
- **D-33-25:** Escalate only when a choice would materially change:
  - raw payload retention or audit retention semantics
  - public admin / router / auth / session contract
  - tenant trust boundaries
  - default privacy posture or exposed metadata fields
  - a materially broader product promise, such as a true embedded observability console
- **D-33-26:** This recommendation-first posture should be applied earlier in GSD-style downstream workflows where the codebase, ecosystem norms, and project vision already point to a coherent default. Only very impactful contract or trust decisions should come back to the user.

### the agent's Discretion
- Exact support-card layout, naming, and placement within the existing operator LiveView.
- Exact symptom taxonomy and stage headings for the troubleshooting guide, as long as the hybrid symptom-first plus stage-drilldown structure remains intact.
- Exact thresholds, windows, and wording for support summary indicators, as long as they remain honest, tenant-safe, and exemplar-oriented.
- Exact reveal/masking behavior for operator-visible identifiers, as long as support usefulness remains intact and privacy minimization stays stronger than the current default.

</decisions>

<specifics>
## Specific Ideas

- The best Phase 33 shape is:
  - one canonical operator troubleshooting guide
  - one delivery-centric admin support surface
  - one stable PII-safe telemetry contract
  - one background-first reconcile story documented the same way everywhere
- Strong precedent to borrow from:
  - Stripe and GitHub for exact delivery inspection and manual replay separation
  - Shopify for backlog and retry-oriented webhook troubleshooting
  - Sentry for legible issue timelines and operator-first triage
  - Hookdeck for operator ergonomics, but not for full control-plane scope
- The desired operator feeling is:
  - “I can tell what happened.”
  - “I know what mailglass can prove.”
  - “I know the next safe action.”
  - “I’m not being lied to by a shallow green dashboard.”
- The desired downstream workflow feeling is:
  - recommendation-first
  - cohesive
  - minimal option sprawl
  - escalate only on genuinely high-impact contract or trust choices

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project posture
- `.planning/ROADMAP.md` — Phase 33 goal, success criteria, and milestone position.
- `.planning/PROJECT.md` — v0.6 production-maturity framing, maintainer budget, support posture, and privacy constraints.
- `.planning/REQUIREMENTS.md` — `MAT-02` requirement definition.
- `.planning/STATE.md` — current milestone state and Phase 33 as active planning target.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, and recommendation-first lenses.

### Prior locked context that constrains this phase
- `.planning/milestones/v0.4-phases/24-tenant-safe-webhook-replay-with-audit-context/24-CONTEXT.md` — exact replay semantics, action-time auth, and operator audit posture.
- `.planning/milestones/v0.4-phases/25-deliverability-doctor/25-CONTEXT.md` — honest diagnostics and “say only what the system can prove” posture.
- `.planning/phases/32-replay-reconcile-hardening/32-CONTEXT.md` — replay/reconcile wording, availability model, and recommendation-first posture for support-critical repair semantics.

### Current docs and operator contract
- `guides/telemetry.md` — current telemetry guide that Phase 33 should tighten and align with shipped signals.
- `guides/webhook-troubleshooting.md` — current webhook incident guidance that should become more canonical and production-support oriented.
- `guides/webhooks.md` — current webhook telemetry contract, provider behavior notes, and reconcile guidance.
- `mailglass_admin/README.md` — public operator surface contract and current replay/support claims.

### Existing implementation seams
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — current delivery-centric operator surface and the natural integration point for support cues.
- `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` — current delivery detail summary and candidate support-identity surface.
- `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` — current timeline renderer that already separates lifecycle and repair audit facts.
- `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex` — shared operator wording for replay availability, outcomes, and effect.
- `mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex` — action-time auth seam for support-sensitive operations.
- `lib/mailglass/operator/deliveries.ex` — delivery read model anchoring the delivery-centric support story.
- `lib/mailglass/operator/timeline.ex` — append-only delivery event timeline read model.
- `lib/mailglass/operator/replay_history.ex` — replay audit read model and operator-facing repair history.
- `lib/mailglass/webhook/telemetry.ex` — webhook telemetry surface and safe dimensions.
- `lib/mailglass/telemetry.ex` — broader telemetry policy and whitelist posture.
- `lib/mailglass/webhook/reconciler.ex` — background reconcile behavior and sweep semantics.
- `lib/mix/tasks/mailglass.reconcile.ex` — CLI fallback contract for reconcile support flows.

### External precedents and ecosystem priors
- `https://hexdocs.pm/phoenix_live_view/security-model.html` — mount-time and action-time LiveView security posture.
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.html` — mountable Phoenix support surface posture.
- `https://hexdocs.pm/plug/Plug.Telemetry.html` — idiomatic request instrumentation in Plug/Phoenix systems.
- `https://hexdocs.pm/ecto/Ecto.Repo.html` — Ecto telemetry integration posture.
- `https://hexdocs.pm/ecto/Ecto.Schema.html` — field redaction and inspect boundaries.
- `https://docs.stripe.com/webhooks` — webhook delivery/retry model and support posture.
- `https://docs.stripe.com/webhooks/process-undelivered-events?locale=en-GB` — explicit manual recovery and idempotent backlog processing.
- `https://docs.github.com/en/webhooks/using-webhooks/handling-failed-webhook-deliveries` — failed-delivery handling and scheduled recovery posture.
- `https://shopify.dev/docs/apps/build/webhooks/troubleshooting-webhooks` — webhook metrics, retries, and operator troubleshooting model.
- `https://hookdeck.com/` — webhook operator ergonomics and observability-as-product reference point.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The current `mailglass_admin` operator surface already gives Phase 33 a tenant-scoped delivery detail, timeline, and replay history base to build on.
- `Mailglass.Webhook.Telemetry` already defines most of the raw support signals Phase 33 needs; the gap is support translation, not missing instrumentation primitives.
- `MailglassAdmin.Operator.RepairState` already provides a shared wording seam for replay outcomes and can anchor broader support-language consistency.
- `mix mailglass.reconcile` already exists as the honest CLI fallback for background-first orphan resolution.

### Established Patterns
- The codebase prefers mountable Phoenix surfaces with adopter-owned auth, not hosted infrastructure.
- Telemetry is structured, PII-whitelisted, and intended for external integration rather than raw payload dumping.
- Repair semantics are already moving toward explicit, low-claim wording and durable audit facts.
- The project consistently prefers smaller honest surfaces over brochure-style comprehensiveness.

### Integration Points
- Phase 33 should connect docs, support cards, delivery detail, replay history, timeline wording, and telemetry examples into one support contract.
- Summary indicators should be read-only and derived from truthful read models or telemetry-backed support facts, not from new mutable “incident state” tables.
- The troubleshooting guide should route operators from symptoms to:
  - exact telemetry names
  - exact admin evidence
  - exact safe repair action
  - exact escalation boundary
- Any privacy changes in the operator surface must be designed together with future search/export/summary surfaces so masking does not become partial theater.

</code_context>

<deferred>
## Deferred Ideas

- A separate in-app observability dashboard or “incident center” with charts, fleet views, and broad historical trend UI.
- Cross-tenant support or repair surfaces.
- Bulk replay, bulk backfill, or generalized operator recovery consoles.
- Mandatory Prometheus / Grafana / OpenTelemetry / Sentry integrations as part of the core mailglass support contract.
- Any feature that implies mailglass can replace provider consoles, external telemetry backends, or adopter-specific infrastructure observability.

</deferred>

---

*Phase: 33-observability-incident-support*
*Context gathered: 2026-05-05*
