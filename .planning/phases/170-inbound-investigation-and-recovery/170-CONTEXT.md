# Phase 170: Inbound Investigation and Recovery - Context

**Gathered:** 2026-10-08 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Operators can explain a received message's routing and perform permitted recovery with truthful outcomes. Phase 170 owns INUX-01 through INUX-04: finding and inspecting an inbound record, understanding its routing and execution evidence, progressively inspecting permitted evidence, and replaying an eligible record with accurate feedback.

Refine the existing Admin inbound journey and its supporting read seams. Preserve Account/tenant isolation, authorization, route-binding, append-only execution-history, optional-package, stable API, and existing LiveView/HEEx contracts. Broader search, bulk recovery, new retention policy, provider redelivery, and changes to package architecture remain outside this phase.
</domain>

<decisions>
## Implementation Decisions

### Account-scoped investigation and return context
- **D-01:** Keep Account, filters, page, selected inbound record, and Quick view/full-detail state in URL navigation. Resolve a requested record by exact ID within the selected Account even when it is outside the current page or filters; explain that it is outside the current results without disclosing foreign-Account existence. Return to the same Account, filter, and page context. Account changes clear selected record and transient replay state while retaining compatible filters.
- **D-02:** Distinguish a successful empty read, no filter matches, out-of-range page, unavailable selection, inbound package unavailable, and failed/unavailable read. Reserve “no records” for a successful empty read. Do not silently convert missing optional support or read failures into an empty result.

### Routing and execution truth
- **D-03:** Persisted ExecutionRun facts and durable route bindings are the historical record. The routing-clause trace evaluates the currently configured router; label it as a current routing simulation and never imply it proves which rules ran when the message arrived. Historical per-clause snapshots and deployment-version pinning are outside this phase.
- **D-04:** Use the same latest fresh execution disposition for list and detail summaries. Keep earlier fresh and replay runs in chronological history instead of allowing an older matched run to overwrite a later fresh result. Distinguish matched Mailbox, no match, failed execution, and missing execution history. A Mailbox outcome is not evidence of provider delivery or recipient receipt. Keep exact times, source, and IDs available where they support investigation; never infer missing facts.

### Progressive evidence and privacy
- **D-05:** Lead with masked record identity and useful safe diagnostic facts, then disclose routing, execution history, and stored evidence progressively. Keep raw provider payload/MIME redacted by default behind the existing action-time :reveal_raw capability. Reset revealed state when record or Account selection changes.
- **D-06:** Project an explicit safe set of verification facts. Apply a field-level display policy to route matcher values and actual subject/header values; mask or withhold sensitive values in ordinary trace output. Do not render arbitrary provider facts, raw exception text, or stack traces. Keep payloads out of URLs, logs, and telemetry. Do not add a new reveal capability or raw export surface.

### Replay eligibility and confirmation
- **D-07:** Determine replay eligibility from the selected record’s stored evidence, durable route binding, execution history, and resolvable Mailbox. Explain distinct no-prior-match, missing-history, and unsafe legacy-binding cases before confirmation where possible. Do not reconstruct an old route by evaluating current route rules or atomizing persisted module text.
- **D-08:** Describe replay as running the recorded Mailbox identity with currently deployed code against the stored inbound message. Keep it distinct from a current-router simulation and from provider delivery/redelivery. At confirmation, re-resolve the exact Account-scoped record and eligibility, then invoke the host’s existing :replay_inbound authorization immediately before execution. Keep tenant scoping at the read and replay seams.
- **D-09:** Keep replay as a single selected-record action. Show local pending/busy feedback and prevent duplicate submission from the same open confirmation. “Busy” describes the in-flight local action unless the runtime supplies a distinct contention fact; do not imply a global lock or add retries. Preserve selected record, Account, and history after denial, failure, or completion.

### Outcome wording and retained history
- **D-10:** Report a replay run being recorded separately from the Mailbox outcome. Distinguish a recorded failed execution from a replay command that failed before a run was recorded. Show “requested” or “queued” only when an authoritative runtime fact supplies that state; current synchronous replay success is reported from the returned/persisted run.
- **D-11:** Show “no change” only when an explicit inbound command result or persisted fact says so. Do not infer it from :ignore, an unchanged message projection, or an empty/unavailable reread. The current inbound replay path appends an ExecutionRun and exposes Mailbox outcomes; the outbound definition based on newly normalized Event rows does not transfer. If planning finds no authoritative inbound no-change fact, surface that requirement gap and resolve it without inventing a result or broadening the public execution contract.
- **D-12:** Keep command feedback separate from a later timeline read. Display terminal history only when the scoped read provides it; represent an unavailable refresh as unavailable. If background execution changes a selected record, refresh its lineage from a real completion signal or identify the displayed history as stale.

### Interaction and dependency posture
- **D-13:** Reuse the existing Admin shell, LiveView/HEEx components, brand, type scale, spacing, themes, and focus patterns from Phase 168. Use native links/buttons and semantic lists/tables as content requires; do not add a partial ARIA grid. Preserve keyboard and touch access, narrow-screen readability, zoom, reduced-motion behavior, and the established 44px target baseline.
- **D-14:** Keep disclosures operable by keyboard with truthful expanded state. Announce action results and waiting states accessibly without moving focus. Keep replay confirmation named, modal behavior truthful, focus contained and returned, and a visible close/cancel action.
- **D-15:** Keep the runtime optional inbound gateway and internal read/replay seams. Preserve tenant predicates plus Tenancy.scope/2, host schema-prefix handling, stable adopter APIs, and the existing Auth adapter. Add only a narrow internal projection or gateway operation if eligibility needs it. Prefer the existing stack and a smaller dependency tree; no new dependency or frontend framework is justified by this phase.

### the agent's Discretion
- Choose the exact responsive arrangement and order of existing summary, timeline, trace, evidence, and replay controls within the inherited Phase 168 design contract.
- Select the smallest safe allowlist and masking rules for diagnostic facts based on provider schemas and existing product policy; keep the behavior explicit and covered with sensitive fixtures.
- Choose narrow Admin-boundary error/state representations that distinguish unavailable reads from successful empty reads while preserving internal programming/configuration failures for maintainers.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** Paths are relative to the repository root.

### Product scope and requirements
- PRODUCT.md — durable product truth, audiences, and package boundaries.
- .planning/PROJECT.md — active v2.9 milestone direction and inherited constraints.
- .planning/ROADMAP.md — Phase 170 goal, success criteria, and phase boundary.
- .planning/REQUIREMENTS.md — INUX-01 through INUX-04.
- .planning/research/v2.9/SCOPE.md — approved code-first direction, bounded acceptance, and deferred work.
- .planning/METHODOLOGY.md — recommendation-first synthesis, honest surface area, and compatibility ergonomics.

### Inherited UI and operator decisions
- .planning/phases/168-shared-workspace-and-usable-baseline/168-CONTEXT.md — shared workspace, Account context, interaction, theme, and accessibility decisions.
- .planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md — shared visual and interaction contract.
- .planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md — reproducible host and asset baseline.
- .planning/phases/169-outbound-investigation-and-recovery/169-CONTEXT.md — sibling investigation patterns, exact context, trust boundaries, truthful outcomes, and acceptance limits.

### Inbound contracts and operator guidance
- mailglass_admin/docs/operator-trust.md — host authorization timing and the distinction between inbound Mailbox recovery and outbound provider-request replay.
- mailglass_admin/docs/api_stability.md — stable Admin adopter surface.
- mailglass_inbound/docs/api_stability.md — stable inbound APIs and internal read/replay boundaries.
- mailglass_inbound/docs/inbound-operator.md — inbound replay eligibility, durable route bindings, tenant requirement, and CLI semantics.
- mailglass_admin/docs/design-system.md — current shared controls and tokens; reconcile documentation with source.
- guides/jobs.md — operator and maintainer jobs.
- guides/operator-incident-support.md — incident-support handoffs.
- guides/run-the-demo.md — reproducible demo host and acceptance setup.
- brandbook/brand-book.md and brandbook/copy/microcopy.md — visual identity and product voice.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- mailglass_admin/lib/mailglass_admin/inbound_live.ex owns URL state, Account/tenant selection, list/detail loading, evidence reveal, replay confirmation, and result feedback.
- mailglass_admin/lib/mailglass_admin/inbound/records_list.ex, quick_view.ex, detail_header.ex, timeline.ex, routing_trace.ex, evidence_card.ex, replay_modal.ex, and destructive_action.ex provide the current inbound presentation and interaction surfaces.
- mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex is the runtime gateway that preserves the optional inbound package boundary.
- mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex, detail.ex, and timeline.ex provide tenant-scoped read models. mailglass_inbound/lib/mailglass_inbound/internal/replay.ex and execution.ex contain durable route resolution and execution behavior.
- Existing focused checks include mailglass_admin/test/mailglass_admin/inbound_live_test.exs, mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs, mailglass_inbound/test/mailglass_inbound/internal/operator/, and mailglass_inbound/test/mailglass_inbound/replay_test.exs.

### Established Patterns
- Inbound reads combine an explicit tenant predicate with Tenancy.scope/2; replay requires tenant_id and independently scopes record/evidence reads.
- Admin avoids a compile-time dependency on mailglass_inbound through a conditionally compiled gateway and runtime apply/3 calls.
- URL parameters preserve filter and selection state; Quick view is a light list projection and Full detail loads timeline, routing, and evidence.
- ExecutionRun is append-only and distinguishes fresh from replay source. The current list reads the latest fresh run, while Detail prefers the latest matched fresh run; align summary disposition.
- Replay resolves the stored route binding to an allowed current Mailbox identity. The routing trace instead reflects the router currently mounted in the session.
- Raw payload/MIME begins redacted and :reveal_raw is checked through the existing host Auth seam. Current verification-facts rendering and route trace actuals need a field-level privacy policy.
- Missing optional support currently can render like genuine empty data; gateway/read failures also need an explicit Admin state rather than a false empty result.

### Integration Points
- Admin LiveView connects to inbound records, summary, detail, timeline, route explanation, and replay through the optional gateway. Keep any new eligibility read internal and tenant-scoped.
- MailglassInbound.Repo and Tenancy own schema-prefix and tenant boundaries; the Auth adapter owns host permission and recent-auth policy.
- Replay uses the recorded Mailbox identity and current deployed implementation. Execution runs and the scoped timeline are the evidence for its outcome.
- Inbound insert PubSub currently carries an ID and preserves the active selection when adding a new list row. Confirm how a selected timeline learns about later background execution completion; use a real completion signal or visible stale/unavailable state.
</code_context>

<specifics>
## Specific Ideas

- The owner accepted the recommendation set and explicitly prefers a smaller dependency tree: “another copy/paste is better than another dep.” Reuse existing LiveView/HEEx, shared components, and native semantics; add a dependency only if a demonstrated requirement cannot be met well with the current stack.
- Label current router evaluation as a current simulation. Describe replay as executing the recorded Mailbox identity with current code, not as replaying provider delivery or evaluating current route rules.
- “No change” applies to inbound only when an explicit inbound execution result or persisted fact supports it. Never infer it from :ignore.
- External primary guidance reviewed: Phoenix LiveView 1.2.12 push_patch/handle_params URL-state behavior; W3C ARIA disclosure keyboard and expanded-state pattern; WCAG 2.2 status-message guidance; OWASP authorization and logging guidance. Rails Action Mailbox was reviewed as an ecosystem example of explicit inbound lifecycle states; its asynchronous processing and retention defaults are not adopted.
- Discussion included source review and external documentation research only. No app boot, product test, implementation, or current remote CI verification was performed.
</specifics>

<deferred>
## Deferred Ideas

- Persisted historical route snapshots or deployment-version pinning would add new evidence/retention semantics; current trace is explicitly labeled as a simulation.
- General inbound search, timeline pagination/export, bulk replay, provider redelivery, manual reconciliation, raw evidence export, and new retention policy are separate capabilities.
- New authorization capabilities or policy knobs, public API changes, framework migration, and new frontend dependencies are out of scope unless planning identifies a concrete requirement that cannot be met within existing contracts.
- No pending todos matched Phase 170.
</deferred>

---

*Phase: 170-inbound-investigation-and-recovery*
*Context gathered: 2026-10-08*
