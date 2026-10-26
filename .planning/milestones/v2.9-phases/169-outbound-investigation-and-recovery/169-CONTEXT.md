# Phase 169: Outbound Investigation and Recovery - Context

**Gathered:** 2026-10-07 (assumptions mode, expanded specialist research)
**Status:** Ready for UI design contract and planning
**Decision authority:** The owner requested breadth/depth research through useful diminishing returns, cohesive recommendations, and automatic adoption. The decisions below are adopted under that instruction; another preference interview is unnecessary.

<domain>
## Phase Boundary

Operators can investigate outbound mail and take supported exact-target recovery actions with truthful evidence and preserved context. Phase 169 owns OUTUX-01–05: scoped Email health, delivery selection and return, recorded provider/event evidence, current suppression and webhook investigation, and exact stored webhook replay.

Carry forward Phase 168's shared workspace and interaction contract. Correct demonstrated defects required by these existing journeys, including narrow core corrections. Preserve public query contracts, host authorization, Account scope, rendering, and replay semantics. Inbound, developer preview, recipient output, and final milestone delivery retain their ownership in Phases 170–173.
</domain>

<decisions>
## Implementation Decisions

### Journey and information hierarchy

- **D-01 — One coherent investigation:** Retain Health → Deliveries → Quick view → full detail → recovery → return. Health identifies a recorded concern; the list locates a delivery; Quick view confirms identity and recorded state; full detail explains evidence; confirmation reviews the action. Engineers and support/on-call remain equal primary audiences. Lead with ordinary domain language and provide exact technical evidence at the point it helps.
- **D-02 — Task-appropriate composition:** Retain a native comparison table where the fields fit and cards at narrow widths. Preserve Phase 168's 16px body/14px label scale; reduce repeated framing before reducing text. Place existing filters above results, keep the applied window/context visible when collapsed, and retain explicit Apply/Clear behavior. Detail should read as identity/state → timeline → current suppression → clearly scoped Account webhook evidence, with discoverable replay eligibility and review action. Exact breakpoint, spacing, and action placement belong in UI-SPEC.
- **D-03 — Filter meaning:** Preserve provider, event, window, and page semantics. Name the event filter for what it queries: the latest recorded event, including applicable audit event types. Do not imply it searches all historical events or computes delivery success. Preserve valid custom positive window deep links while guarding malformed, unsupported-shaped, and numerically unsafe inputs. Keep draft and committed filter values distinct; reveal invalid fields and retain useful input.

### Health and evidence handoffs

- **D-04 — Observation scope and window:** Keep the validated URL window, currently defaulting to seven days/168 hours, and display the actual interval consistently. Recorded processing failures count persisted failed/dead webhook rows by receipt time; unmatched evidence counts unresolved event records in the interval; replay/reconcile counts describe recorded audit facts. Active suppression counts describe currently active records, independently of the observation window. Provider/event delivery filters do not silently constrain Account metrics. Counts must identify their unit; suppression records are not a recipient count.
- **D-05 — Honest uncertainty:** Available zero, empty in the requested window, missing selection, read unavailable, partial evidence, and retained stale data are distinct states. Zero counts support only a limited observation statement. Remove universal healthy claims. Display actual last-checked information where supplied; disconnection or failed refresh must not create fresh or zero evidence. Keep useful unaffected panels visible when another read fails. Provider absence detection, health scoring, and invented age thresholds remain deferred.
- **D-06 — Matching destinations:** A metric's action must open evidence of that same kind. Failed webhook processing leads to failed-webhook evidence; unmatched records lead to unmatched evidence. Name a single latest/oldest example as an example. An active-suppression total may have a separately named historical suppressed-delivery link, but the populations must remain distinguishable. Existing exact support links must retain and resolve their requested Account-scoped object, or explain its unavailability; a newer exemplar must never silently replace it. Standalone support evidence remains usable when there are no matching deliveries.

### Identity, navigation, and refreshing

- **D-07 — Exact selection:** Resolve a requested delivery by selected Account and exact ID independently of list page, provider/event filters, or time window. Explain when a valid delivery is outside current results. Keep requested identity independently of the loaded row so a temporary failure or list reorder does not erase it. Malformed IDs and missing/foreign IDs receive recoverable, non-disclosing states. Activity-derived Account options remain navigation aids and never become an authorization allowlist.
- **D-08 — Return and history:** Preserve Account, committed filters, and page through Quick view/full-detail handoffs. Explicit Back to deliveries clears selection, full-detail mode, and exact support focus and returns to the list; it must not reopen Quick view. Browser Back/Forward reflects actual deliberate navigation. Keep page-relative previous/next and position only when the selected delivery is on that page. Account switching clears all object/evidence IDs, page, and transient confirmation, retaining only compatible filter/category context. Preserve custom mounts and established URL compatibility.
- **D-09 — Live state:** Retain existing Account-scoped PubSub invalidation and reread persisted facts. Provide a supported refresh/retry path. Preserve selection, useful filter drafts, focus, and review identity through refresh; do not drop a selected delivery merely because its latest event stops matching the list. Do not label all panels continuously live: delivery notifications do not establish complete support/suppression freshness. Keep current synchronous bounded reads unless measured blocking justifies targeted async with protection against results from an old Account/request.

### Recorded state and timeline

- **D-10 — Separate facts:** Preserve existing domain atoms and projections. Present local dispatch/handoff, provider observations, and replay/reconcile audit facts according to their meaning. A latest audit event must not become a delivery outcome, and an unrecognized event must not fall through to a confident success. Dispatch establishes provider handoff; provider-reported delivery establishes receiving-mail-server acceptance. Tracking observations do not establish human reading. Keep earlier adverse history visible. Do not invent a new lifecycle inference engine or require per-row ledger scans.
- **D-11 — Source and time:** Classify replay by its explicit event types, not the mere presence of `webhook_event_id` metadata. Show source and exact stored time with a correct label. Current webhook ingestion/replay commonly records local Mailglass time; show provider occurrence time only when actually stored and attributed. Keep missing values unavailable. Provide readable UTC values and useful stored precision; a copy affordance uses a semantic control, leaves the original value visible, and reports success/failure accessibly.
- **D-12 — Bounded history with reachable selected evidence:** Preserve chronological ordering and the current first-100 timeline presentation, using a 101st row through the existing limit option to establish overflow. Explicitly disclose additional undisplayed events. Keep latest replay evidence separately available through existing replay-history data. If an existing exact event/support link targets an event outside the displayed slice, show that scoped selected fact separately with its relationship to the slice; do not substitute a visible row or declare it absent. A narrow internal exact read is permitted to repair this existing handoff. General history pagination/search/export is deferred. Do not describe the existing unbounded ReplayHistory query as bounded.

### Suppression and Account context

- **D-13 — Association:** Keep selected-delivery ledger facts, a current matching suppression, and Account-wide support facts visibly separate. Show association to this delivery, another delivery, or no established delivery only when recorded linkage proves it. Do not attach an unlinked Account exemplar to whichever delivery happens to be selected. Replace generic Support cards and misleading multi-record action labels with concrete subject and scope.
- **D-14 — Current suppression truth:** Show the current matching recorded suppression's scope, reason, source, and expiry when available, explicitly distinguishing it from historical suppression events. Existing reads select one active Ecto match; neither a displayed match nor no match proves the full configured-store/provider policy. Address/domain scope spans streams within this Account; it is not cross-Account global scope. Correct the reader's policy-removal classification to the public command behavior: complaint/unsubscribe removal is blocked; policy removal is supported. Expiry and removal eligibility are separate facts. Offer accurate host/API investigation guidance without a new Admin mutation or a promise that removing one record permits delivery.

### Exact-target recovery and trust

- **D-15 — Review the actual request:** Keep the existing modal and zero/one/many candidate behavior. Zero explains unavailability; one displays an explicit reviewed target; many require a deliberate choice. Prefer Review webhook replay for the opener and Confirm replay for submission. Show Account, delivery linkage, provider, stored webhook/request identity, and received time. Explain that replay reprocesses the stored request through current normalization and may record events or update delivery/suppression records for its contents within the Account. A provider batch can affect multiple deliveries. Correct outbound Mailbox-routing copy and do not imply a new outbound send or provider receipt.
- **D-16 — Bind confirmation to reviewed identity:** Freeze the exact reviewed webhook ID even when there is one candidate. At confirmation re-resolve current Account/delivery eligibility and membership of that same target, then run the existing host action-time authorization immediately before execution. Disappearance, replacement, or materially changed reviewed facts require refreshed review; never substitute a different candidate. Preserve host-owned recent-auth semantics, selected context, and useful denial/stale guidance. No new package authorization policy or account allowlist.
- **D-17 — One local submission:** Retain visible pending feedback and disabled confirmation, and enforce a server-side consumed/open-review guard against duplicate queued confirmations. Dismissal must not imply cancellation of a submitted command. Existing transactions/idempotency retain their scope; do not promise exactly-once across tabs/operators or add automatic retries, distributed locks, or a public nonce API for this UI refinement.
- **D-18 — Truthful outcomes:** Requested is a recorded request, not completion. New work means newly recorded normalized event rows; no change means no new normalized rows, while audit records can still be written. These outcomes do not establish mail delivery, event linkage, or cleared Health counts. Show known counts only where the existing result supports them. A requested record with no terminal fact means completion has not been recorded; do not call it indefinitely running or infer failure. Keep command feedback and persisted evidence distinct when refresh/audit persistence fails; never promise a terminal audit without evidence. Preserve earlier history and selected Account/delivery after supported failure or denial.
- **D-19 — Recovery boundaries:** Replay and background reconciliation remain separate. Reconcile links existing unmatched evidence; it is not a generic delivery-detail repair action. Guidance must point to supported host/provider investigation or existing maintenance documentation according to the cause. Correct the trust guide's mixed inbound/outbound wording while preserving common exact-target, session, and authorization guarantees. No resend, batch recovery UI, manual reconcile UI, or suppression-removal control is introduced.

### Accessibility, visual consistency, and performance

- **D-20 — Semantic interactions:** Use native table structure with an explicit link/button for opening a delivery; optional row clicking may enhance pointer use. Do not implement a partial ARIA grid. Keep filter disclosures named and expanded state accurate. Scope keyboard shortcuts so inputs, copy buttons, scrolling, and other controls retain their native keys. Preserve the shared dialog focus hook, inspect background interaction containment, and restore focus to the originating visible control or a logical visible fallback after reflow/removal. Announce changed identity and outcomes once, not the full timeline on every update.
- **D-21 — Coherent visual language:** Carry forward the current brandbook, Phase 168 tokens/type, 44px interaction target baseline, and Light/Dark/System behavior. Use neutral treatment for policy/no-change information, actual failure treatment for failures, and established sensitive-action styling for confirmation. A successful replay/no-change count must not appear as an error merely because it is nonzero. No new theme, density setting, icon vocabulary, component library, or visual identity is needed.
- **D-22 — Immediate frequent work:** Record navigation, keyboard work, filter application, and live patches remain immediate. Remove repeated timeline choreography. Retain only brief purposeful occasional overlay motion under the shared reduced-motion rules. Show local pending state for real pending work and placeholders only where content is actually absent. Avoid optimistic replay completion, fabricated progress, value replacement during copying, and decorative work that delays investigation.

### Architecture, privacy, and acceptance

- **D-23 — Small compatible boundaries:** Keep data/domain queries in core via Mailglass.Repo and explicit tenancy/schema-prefix handling, presentation in shared Admin presenters/components, and interaction state in LiveView. Preserve existing stable operator query signatures, returns, atoms, ordering, and pagination. UI load-state tags belong at the Admin boundary. Any required exact-read seam must be explicitly classified/exported for sibling use without silently expanding the stable adopter API. Avoid broad rescue-to-empty handling; handle known unavailable reads narrowly and keep programming/configuration failures observable to maintainers.
- **D-24 — Bounded ordinary work:** Retain the 20-row paginated list, deterministic ordering, and small Quick view projection. Load heavy detail only when requested; avoid per-row support/history queries. Handle out-of-range pages distinctly from empty Accounts. Existing COUNT/OFFSET and replay-history costs remain disclosed; source inspection is not a performance measurement. Add caching, indexes, streaming, async, or query restructuring only for demonstrated cost needed by this journey. No new frontend toolchain, dependency, host configuration, migration campaign, or architectural rewrite.
- **D-25 — Relevant safe detail:** Preserve masking in list/Quick view and existing authorization for detailed evidence. Render only explicitly chosen diagnostic fields; metadata is not uniformly safe. Keep raw/signed webhook bodies, sessions, and arbitrary errors out of UI, URLs, client logs, and telemetry. Host actor identifiers may themselves be identifying; do not enrich them or describe them as automatically anonymous. Exact values help investigation without creating a raw-payload browser/export feature.
- **D-26 — Connected acceptance:** Capture current rendered output and source/fixture/route/theme/viewport before edits, then use focused core/LiveView/browser acceptance for the actual connected journey. Cover off-page/out-of-window exact links, Account changes, preserved filters/history, empty/unavailable/stale distinctions, matching Health destinations, timeline overflow/exact selection, suppression scope/expiry, zero/one/many/replaced/denied replay targets, duplicate submit, and all recorded outcomes. Include long/non-ASCII data, representative desktop/mobile/intermediate widths, keyboard/touch, zoom, themes, reduced motion, and relevant disconnect/latency/copy failures. Reuse the bounded inspection → corrective batch → confirmation cycle. Update misleading old assertions with their replacement behavior; preserve substantive trust checks. Keep generated assets with source. Source research here is not runtime proof.

### Agent's Discretion

- The owner delegated routine choices and adoption of the coherent synthesis. Exact layout values, extraction boundaries, safe field allowlists, wording refinements, and fixture organization can be resolved in UI design/planning within these decisions.
- Use Impeccable Operate and relevant Kowalski guidance with the incumbent code-first world. The current brandbook and shipped Phase 168 implementation govern conflicts with historical prompts.
- Further research should resolve a named implementation uncertainty. The three tracks examined 36 comparisons and converged; generic framework/dashboard research is no longer useful. No pending todos matched Phase 169.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** Paths are relative to the repository root.

- `PRODUCT.md`, `.planning/ROADMAP.md` (Phase 169), `.planning/REQUIREMENTS.md` (OUTUX-01–05), `.planning/research/v2.9/SCOPE.md` — product truth, ownership, requirements, scope and bounded acceptance.
- `.planning/METHODOLOGY.md` — recommendation-first research, honest surface area, compatibility ergonomics.
- `.planning/phases/169-outbound-investigation-and-recovery/169-DECISION-BRIEF.md` — supporting tradeoffs, evidence, source links, and resolved conflicts; this CONTEXT is the decision authority.
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-CONTEXT.md` — inherited shared decisions.
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md` — shared interaction and visual contract.
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-VERIFICATION.md` and `.planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md` — implementation and evidence baseline.
- `brandbook/brand-book.md`, `brandbook/copy/microcopy.md`, `mailglass_admin/docs/design-system.md` — current identity, voice, and shared components; reconcile dated examples with source and approved decisions.
- `docs/api_stability.md`, `mailglass_admin/docs/api_stability.md`, `mailglass_admin/docs/operator-trust.md` — stable seams. The last file's mixed replay-domain prose is an identified correction target, not authority to change outbound runtime semantics.
- `guides/jobs.md`, `guides/operator-incident-support.md`, `guides/run-the-demo.md` — existing jobs, operational handoffs, and reproducible host.

The decision brief identifies relevant historical `prompts/` inputs and verified primary references. Their speculative roadmaps/configuration do not expand this phase. DISCUSSION-LOG is an audit trail, not downstream decision input.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — existing Health/list/quick/full journey, URL state, PubSub, support focus, replay orchestration.
- `mailglass_admin/lib/mailglass_admin/operator/` — DeliveriesList, FiltersForm, QuickView, DetailHeader, Timeline, SupportCards, SuppressionCard, ReplayModal, RepairState, Shell, and DestructiveAction.
- `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`, `mailglass_admin/assets/css/app.css` — shared controls, timestamp/copy enhancement, focus hook, tokens, and motion.
- `lib/mailglass/operator/` — bounded delivery page, ledger timeline, Account support aggregation, current suppression match, exact replay targets, replay history.

### Established Patterns and Correction Seams

- Exact selection currently searches the loaded page; empty-list rendering can hide detail/support. Exact support URL IDs can outlive Account changes or be replaced visually by moving exemplars.
- Health's hard-coded 24h labels disagree with passed 168h defaults; nil can appear as zero/healthy; several count destinations describe different populations.
- Timeline uses earliest 100 events and classifies normal linked webhook events as replay by metadata. Recorded time is often local; latest replay history may lie beyond the displayed timeline.
- `lib/mailglass/suppression.ex` owns removal rules; the operator reader's policy classification conflicts with it. Operator suppression reads use Ecto while the send store is configurable.
- `lib/mailglass/webhook/replay.ex` reprocesses an entire stored request and distinguishes event insertion from audit writes. Requested-only records can exist. The cached one-target selection can ignore the reviewed ID, and a consumed-dialog guard needs focused coverage.

### Integration Points

- Preserve Mailglass.Repo, Tenancy, host schema prefix, actor/session whitelisting, action-time authorization, optional package mounts, and custom route prefixes.
- Reuse existing core/Admin tests, `mailglass_admin/e2e/`, browser fixtures, gallery, and `reference/demo_app`. Product checks and rendered evidence run during implementation; none were run during this discussion.
</code_context>

<specifics>
## Specific Ideas

- The owner asked for expert breadth/depth, viable tradeoffs, Elixir/Phoenix idioms, successful product lessons, all relevant personas/jobs, and automatic adoption of the best cohesive recommendations.
- Three research tracks covered UX/accessibility/visual language, Phoenix/Ecto/navigation/DX, and evidence/recovery/trust. Their distinct alternatives are recorded in the decision brief; repeated findings were consolidated here.
- Preserve useful familiar controls. Make uncertainty and action consequences clear at the point of decision. Keep implementation narration and project-phase language out of normal operator copy.
- Research is source/documentation based. No fresh browser review, application run, product test, remote CI claim, implementation, or formal phase plan was produced by this discussion.
</specifics>

<deferred>
## Deferred Ideas

- General timeline pagination/search/export, comprehensive failed-webhook queues, new recipient/subject search, saved filters, and bulk recovery are separate capabilities.
- Resend, suppression mutation UI, manual reconciliation UI, new provider timestamps/backfills, provider absence detection, raw-body reveal/retention, and new policy/permission knobs remain outside this refinement.
- Framework migration, stream/async/cache rewrites, dependency upgrades, CI architecture changes, and new visual/animation libraries need a demonstrated separate rationale.
- Inbound, preview, recipient output, and final shared documentation/CI delivery retain later-phase ownership. Update directly affected outbound truth documentation in this phase.
- No new backlog work was approved and no pending todos matched. These dispositions record considered alternatives; they do not create roadmap commitments.
</deferred>
