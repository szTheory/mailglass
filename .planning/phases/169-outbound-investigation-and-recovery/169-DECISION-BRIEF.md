# Phase 169 — research and decision brief

**Date:** 2026-10-07
**Authority:** Supporting analysis for `169-CONTEXT.md`; the context owns adopted decisions. This is discussion research, not the formal implementation RESEARCH or PLAN artifact.
**Method:** Three specialist tracks examined 36 decision points, compared viable alternatives, inspected current source and relevant historical prompts, and consulted primary documentation. Recommendations were reconciled and adopted under the owner's explicit instruction. No implementation, tests, fresh rendered review, or production measurement occurred.

## Jobs and desired results

| Operator and situation | Inputs and task | Useful result |
| --- | --- | --- |
| Support answering a recipient report | Account, approximate time/provider, or a delivery link; locate and explain a delivery | An understandable observed state, exact evidence when needed, a supported next step, and a preserved return path |
| On-call assessing a concern | Account Health observations and their window; reach affected evidence | Correctly scoped facts with explicit coverage limits and unavailable observations |
| Engineer investigating event processing | Delivery/provider IDs, ledger history, failed/unmatched webhook evidence | Known associations, local/provider/audit distinctions, one eligible stored request, and a truthful replay result |

Existing outbound filters do not establish subject/recipient search. Exact links and current filters are the available inputs. Common tasks remain discoverable while technical detail is progressively available. The current Mailglass brand, shared Account context, readable type, themes, masking, and focus conventions carry forward.

## A. UX, composition, accessibility, and visual language

| Point | Adopted recommendation | Alternative: advantage / cost | Evidence and failure to avoid | Context |
| --- | --- | --- | --- | --- |
| U1. Investigation structure | Preserve Health → list → Quick view → full detail → reviewed action | Permanent master/detail reduces clicks but crowds evidence and needs a separate mobile composition | OperatorLive already has the tiered journey; Postmark's activity-to-events sequence is a useful precedent [R1]. Avoid dashboard composition that obscures the actual job. | D-01–02 |
| U2. Health meaning | Precise metric subject/window plus matching evidence | Generic labels with help are compact but leave the first-read meaning wrong | Current failed-ingest count links to failed deliveries; nil suppression can allow healthy copy. | D-04–06 |
| U3. Collection density | Table where fields fit; narrow cards; retain readable type | Cards everywhere simplify reflow but slow comparison; a scrolling table everywhere burdens phones | DeliveriesList already has table/cards. Validate fit at intermediate widths and zoom; avoid duplicate responsive focus targets. | D-02, D-21 |
| U4. Filters | Toolbar above results; explicit Apply/Clear; visible committed context | Immediate apply saves a click but changes draft/committed behavior and can churn under latency | Filters currently follow the long collection; “Status” actually queries last event. | D-03 |
| U5. Selection/return | Exact selection independent of list; Back means list | Back to Quick view is viable when named, but adds an exit step | Full detail currently preserves delivery_id on Back and reopens Quick view. Browser history can legitimately revisit it. | D-07–08 |
| U6. Status hierarchy | Clear dispatch and recorded-event meaning; deeper explanation in detail | One universal badge is dense but conflates audit with delivery; many badges everywhere create noise | Components display projection and Quick view's “Observed outcome” need source-aware wording. [R1, R11] | D-10 |
| U7. Exact values | Readable UTC/IDs; semantic copy with separate feedback; selected safe metadata disclosure | Hover/relative-only is compact but weak for incident correlation and touch | Timestamp click copying lacks equivalent native-key semantics and replaces displayed text; retain original evidence. | D-11, D-25 |
| U8. Evidence scope | Separate delivery timeline, current suppression, Account context | One combined timeline reduces navigation but implies false causation | Support summary is Account-wide; suppression is current; exemplar is not the entire failure set. | D-13–14 |
| U9. Recovery placement | Visible eligibility and Review webhook replay → existing confirmation | Inline confirmation avoids a modal but scatters target/consequence in dense evidence | ReplayModal already supports target choice; retain the protected flow and fix outbound language. | D-15–18 |
| U10. Interaction semantics | Native table controls, scoped shortcuts, full modal focus behavior | An ARIA grid adds compact keyboard navigation but requires a composite widget without an editing job | Current focusable rows/aria-selected and global keys need review. APG supports native table actions and complete modal behavior. [R3–R4] | D-20 |
| U11. Visual states | Existing restrained tokens; actual failure, policy, no-change, and selection distinct | New colors/themes differentiate panels but multiply semantics/maintenance | Replay support card can show red zero failures solely because successful replay exists. | D-21 |
| U12. Functional motion | Immediate frequent work; occasional short overlay cue; local real busy feedback | Timeline staggering can decorate first entry but adds repeated delay | Current timeline stagger conflicts with repeated operator work. Source comments do not establish zero-query Quick view. | D-22, D-24 |

## B. Phoenix, Ecto, navigation, and maintainer ergonomics

| Point | Adopted recommendation | Alternative: advantage / cost | Evidence and failure to avoid | Context |
| --- | --- | --- | --- | --- |
| A1. Exact read | Account+ID resolution independent of list using a small core projection | Loaded-row reuse plus fallback saves a common query but adds freshness paths | OperatorLive searches 20 loaded rows. Explicit tenant predicate, Tenancy scope, Repo facade, and ID validation must remain. [R7–R8] | D-07, D-23 |
| A2. URL/history | handle_params owns mutable state; patch within surface; replace only normalization | Separate detail LiveView isolates lifecycle but expands routes and return contracts | Preserve requested ID after read failure; empty-list branch must not suppress detail. [R5] | D-07–09 |
| A3. Validation/switch | Validate shapes; clear all exact IDs/page/review on Account change; preserve compatible filters | Category-only latest-evidence links are simpler, but cannot honestly retain an exact ID | support_event_id/support_webhook_event_id currently survive switch; focused UI can render a different exemplar. Options are discovery, not ACL. | D-06–08 |
| A4. Observation window | Show actual validated window, default 168h; current suppression has separate time basis | Fixed24h makes a familiar incident default but changes existing URL/query behavior and handoffs | UI hard-codes 24h while passing 168h. Count units and timestamps differ. | D-04 |
| A5. Read outcomes | Admin tags distinguish data/empty/invalid/missing/unavailable/stale; preserve core returns | Crash/reconnect for every panel is simple but discards useful work; generalized core error redesign breaks contracts | Broad rescue-to-nil creates false zero states. Ecto nil means no match, not database failure. [R8] | D-05, D-23 |
| A6. Freshness | Scoped PubSub rereads plus refresh/retry; stable requested identity and controls | “New activity” snapshot mode reduces reorder but adds workflow state; polling adds load without complete coverage | Notifications do not cover every support failure/expiry. No freshness promise beyond actual observations. | D-09 |
| A7. Projection | Keep dispatch, latest event, and ledger distinct; type-based audit classification | A new furthest-state engine offers richer synthesis but needs precedence rules and more reads | Ordinary provider rows have webhook_event_id; metadata presence currently mislabels them as replay requested. | D-10–11 |
| A8. History bound | First100 chronological +101 sentinel; selected exact fact/replay evidence separately reachable | 250 rows postpones truncation; general pagination solves more but adds API/workflow scope | Earliest100 can omit latest replay. Disclose slice; exact existing link must still be honored. | D-12 |
| A9. Delivery paging | Existing 20-row offset/page semantics and stable ordering; recover out-of-range page | Keyset scales deep pages but changes URL/total/previous-page semantics | COUNT/OFFSET costs are not measured; safe numeric parsing and honest page position are needed. | D-03, D-08, D-24 |
| A10. Read ownership/cost | Core queries; Admin presentation; small quick/full split; no per-row evidence load | An aggregate can consolidate consumers later but creates coupling and all-or-nothing failure now | SupportSummary has fixed aggregate queries, not N+1. Do not introduce row-level heavy reads. [R7, R9] | D-23–24 |
| A11. Component/API boundary | Function components, bounded assigns, existing hooks/assets; preserve stable query shapes | Stateful component/stream refactor may help other workloads but complicates current URL/focus ownership | Stable operator modules are inventoried. New exact-read helper classification must be explicit; no host build requirement. [R6] | D-20, D-23–25 |
| A12. Acceptance | Focused semantic reads + connected LiveView/browser handoffs | Screenshots/copy assertions are useful but cannot prove identity; one giant E2E is hard to diagnose | Some existing tests lock incorrect 24h/links; a “degradation” test that never fails a query proves little. | D-26 |

Framework references were checked against the Admin lock: LiveView 1.2.12, Phoenix 1.8.14, Ecto 3.14.2. The root LiveView lock differs (1.1.33). Recommended patterns need no dependency upgrade; exact implementation compatibility remains part of planning.

## C. Evidence, recovery, reliability, and trust

| Point | Adopted recommendation | Alternative: advantage / cost | Evidence and failure to avoid | Context |
| --- | --- | --- | --- | --- |
| T1. State meaning | Observed dispatch/provider/audit facts; retain adverse history | Single success badge is compact; new state machine changes domain semantics | Projector's latest pointer/terminal latch is not a business-success model. Delivered stops at receiving-server acceptance. [R10–R11] | D-10 |
| T2. Time/provenance | Explicit event-type source; exact stored UTC; provider time only when present | One unlabeled time is simple but misleading; provider timestamp expansion adds ingestion/backfill scope | Ingest/replay commonly set occurred_at from local Clock; replay time is not original provider occurrence. | D-11 |
| T3. Health uncertainty | Bounded snapshots and individually unavailable observations | Universal green feels reassuring but data cannot support it | Failed/dead persisted rows do not enumerate all ingress/signature/send failures; some persistence is host-owned. | D-04–05 |
| T4. Evidence relationship | Count to same-kind evidence; truthful exemplar; exact focus retained | Comprehensive queue is useful but adds capability; related delivery filter is cheap but wrong population | “Still unmatched” can currently link latest_reconciled; selected delivery fallback implies unproved association. | D-06, D-13 |
| T5. Suppression | Current matching Ecto record with reason/scope/expiry/limits; align policy eligibility to command | All matches would be richer but changes reader contract; historical-cause shortcut is inaccurate | Public remove rejects complaint/unsubscribe, permits policy; configurable store may differ from Ecto; one record is not all restrictions. | D-14 |
| T6. Target breadth | Confirm entire stored request; batch effect disclosed | Latest auto-pick or splitting raw batches reduces decision burden by changing semantics | One persisted request can normalize N events for multiple same-Account deliveries. No outbound send or mailbox execution occurs. | D-15 |
| T7. Action-time review | Freeze reviewed ID; re-resolve same target; host-authorize immediately before execution | Cached assigns save a read but can silently replace sole candidate; package auth policy breaks host ownership | Exact-candidate path currently ignores selected ID; PubSub can replace A with B. Disabled controls are not authorization. [R13] | D-16 |
| T8. Duplicate submission | Client pending plus server consumed-review guard | Browser disabling alone misses queued events; distributed locks/nonces add unnecessary public surface | Event idempotency can still allow an additional audit pair on duplicate confirmation. No exactly-once promise. [R12] | D-17 |
| T9. Outcome evidence | Requested/new normalized rows/no new rows/failure/unrecorded completion distinct | Generic toast is easy but weak; durable job UI invents semantics for synchronous command | Request audit precedes transaction; terminal audit can fail; noop includes zero normalized input. Orphan count is not necessarily new orphan count. | D-18 |
| T10. Safe diagnostics | Explicit existing fields and redaction; known cause only | Raw dump aids debugging but exposes data and overwhelms routine use | Schema redact protects Inspect, not templates. Host actor IDs can contain personal information. | D-25 |
| T11. Recovery boundaries | Replay reprocesses request; reconcile links old unmatched events; supported next-step guidance | One Repair action is appealing but conceals different effects | Replay does not clear original webhook status; duplicate orphan replay does not itself reconcile prior linkage. Mixed trust prose needs correction. | D-19 |
| T12. Reliability/DX | Existing tuple/atom/transaction/append-only seams; narrow demonstrated corrections and focused proof | Parallel UI truth engine duplicates domain; copy-only leaves behavioral defects | Avoid broad exception swallowing, new telemetry frameworks, and invented durable-failure guarantees. | D-23–26 |

## Synthesis: conflicts resolved

1. **Window:** preserve actual validated window/default 168h; fix prose. No new independent 24h dashboard state.
2. **History:** disclose first 100, detect overflow with existing limit, and honor existing selected exact-event links separately. No general pagination capability. Latest replay result remains accessible; the existing ReplayHistory query is unbounded and must be described honestly.
3. **Current suppression:** public removal behavior governs the contradictory operator classification. “Permanent” is inappropriate when expiry can exist. The current Ecto match is neither historical causation nor comprehensive configured-store/provider policy.
4. **Replay language:** current outbound runtime governs consequences; split mixed trust prose into explicit outbound/inbound meanings. Preserve shared host/action authorization contracts.
5. **Replay result:** prefer “new event records” / “no new event records,” with new work/no change vocabulary retained where useful. Requested without completion is unknown completion, not a perpetually running job. Do not blindly reuse UI research's early shorthand “pending.”
6. **Confirmation breadth:** a stored request may contain multiple deliveries. The selected delivery establishes entry/linkage; it does not bound all effects. Freeze reviewed identity; a changed candidate needs a new review.
7. **Stable APIs:** UI result tags stay in Admin. Narrow internal/sibling reads may repair existing exact links; do not change stable list returns or imply a new general query API.
8. **Freshness:** last-checked and stale/disconnected descriptions reflect actual UI reads. They do not establish provider-event coverage or justify an absence detector.

## Acceptance obligations to carry into planning

- Follow real controls through scoped Health → exact evidence → delivery → replay/result → return, preserving URL/context and custom mounts.
- Include empty Accounts with support evidence; window/filter emptiness; invalid/missing/foreign IDs; off-page/old selections; newer moving exemplars; failed refresh and unavailable individual queries.
- Verify source/label/window/destination agreement for every metric. Include zero counts alongside unavailable evidence and current suppressions without historical suppressed deliveries.
- Include ordinary provider events with webhook linkage, later audit events, unknown types, stored time precision, more than 100 ledger events, and selected evidence outside that slice.
- Exercise current suppression vs historical events, expiry, policy/complaint/unsubscribe eligibility, one-of-several matches, Account/stream boundaries, and configured-store evidence limitations.
- Exercise zero/one/many targets, sole-target replacement during review, lost target, denied/recent-auth failure, repeated submit, batch consequences, new/no-change/failure/requested-only result, and unavailable terminal evidence.
- Inspect semantic controls and shortcut isolation, focus containment/return after row removal or breakpoint change, copy failure, long/non-ASCII values, zoom, themes, reduced motion, repeated patches, and actual pending/disconnected behavior.

These are future proof obligations. Source demonstrates some defects and suggests concurrency/error risks; rendered behavior, latency, contrast, and failure handling require implementation-time evidence. Existing checks and one bounded visual review/correction/confirmation cycle are sufficient unless a concrete blocker remains.

## Primary references and precise lessons

Each factual summary below describes its source; application to Mailglass is our design/engineering inference. No competitor internals, failure history, popularity ranking, or current visual audit is claimed.

- **R1 — [Postmark recipient investigation](https://postmarkapp.com/support/article/1267-why-didn-t-this-recipient-receive-my-message):** scoped activity → message → recorded events/times supports the existing progressive investigation. Delivered is distinct from inbox placement; borrow sequence and bounded terminology, not its extra search/retention controls.
- **R2 — [Resend event timeline announcement](https://resend.com/changelog/email-events-timeline):** chronology with specific bounce detail is a useful precedent. This is a 2023 announcement, not a current interface audit; Mailglass's details must also work with keyboard/touch.
- **R3 — [W3C APG tables](https://www.w3.org/WAI/ARIA/apg/patterns/table/):** table structure and interactive descendants differ from a composite grid. A native table with explicit actions fits this collection.
- **R4 — [W3C APG modal dialogs](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/):** focus containment, inert background, Escape, initial focus and return guide review of the existing hook. Reading APG does not establish conformance.
- **R5 — [LiveView 1.2.12 navigation](https://phoenix-live-view.hexdocs.pm/1.2.12/live-navigation.html):** patch updates the current LiveView via handle_params; navigation mounts another; URL values need validation. Retain patch/history semantics for this journey.
- **R6 — [LiveView 1.2.12 behavior](https://phoenix-live-view.hexdocs.pm/1.2.12/Phoenix.LiveView.html):** lifecycle, stream DOM/state requirements, and async loading/error patterns inform the tradeoff. Twenty-row assigns and targeted synchronous reads remain a local choice, not a framework rule.
- **R7 — [Ecto.Query 3.14.2](https://ecto.hexdocs.pm/3.14.2/Ecto.Query.html):** composable queries, casting, prefixes, and limits support exact scoped projections and a sentinel row. A row limit does not bound every aggregate's cost.
- **R8 — [Ecto.Repo](https://ecto.hexdocs.pm/Ecto.Repo.html#c:one/2):** one returns nil on absence and raises on multiple matches. The rendered version matched 3.14.2 when consulted; nil must not represent infrastructure failure in the UI.
- **R9 — [Phoenix contexts](https://phoenix.hexdocs.pm/your_first_context.html):** coherent boundaries isolate related functionality. Supports retaining core data ownership and thin UI orchestration; no new context framework is required.
- **R10 — [Postmark delivery webhook](https://www.postmarkapp.com/developer/webhooks/delivery-webhook):** delivery reports receiving-server acceptance and provider timestamp fields. Mailglass's local recorded timestamp must not be relabeled as that provider timestamp.
- **R11 — [Anymail tracking](https://anymail.dev/en/stable/sending/tracking/):** normalized events still have provider-dependent/missing detail. Retain common taxonomy and available specific evidence without invented parity.
- **R12 — [Stripe webhook delivery behavior](https://docs.stripe.com/webhooks#event-delivery-behaviors):** duplicates and lack of ordering guarantees justify careful target/result language. Its retry model is not Mailglass's; do not import a retry capability.
- **R13 — [LiveView security](https://phoenix-live-view.hexdocs.pm/1.2.9/security-model.html):** authorize server events as well as entry/navigation. This established principle supports retaining the host callback at confirmation; hidden/disabled controls cannot replace it.

## Local evidence and authority

Primary product/scope sources: `PRODUCT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/research/v2.9/SCOPE.md`, `.planning/METHODOLOGY.md`, Phase 168 CONTEXT/UI-SPEC/current implementation. Brand authority: `brandbook/brand-book.md` and `brandbook/copy/microcopy.md`, superseding `prompts/mailglass-brand-book.md`.

Relevant historical research read across the tracks:

- `prompts/mailer-domain-language-deep-research.md` — recorded facts, event taxonomy, audience/domain nouns.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — URL state, thin LiveViews, interaction ownership.
- `prompts/ecto-best-practices-deep-research.md` — composable queries, scoped boundaries, measured costs.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — targeted concurrency, read boundaries, operational tradeoffs.
- `prompts/mailglass-engineering-dna-from-prior-libs.md` — explicit errors, append-only ledger, privacy, small integration seams.
- `prompts/Phoenix needs an email framework not another mailer.md` — prior art and normalization lessons; its historical marketing/product roadmap is not current scope.

Core evidence: `lib/mailglass/operator/{deliveries,timeline,support_summary,suppressions,replay_targets,replay_history}.ex`, `lib/mailglass/webhook/{ingest,replay,reconciler}.ex`, `lib/mailglass/suppression.ex`, `lib/mailglass/outbound/projector.ex`, `lib/mailglass/events/event.ex`, `docs/api_stability.md`.

Admin evidence: `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/operator/`, `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`, `mailglass_admin/assets/css/app.css`, `mailglass_admin/docs/{operator-trust,api_stability,design-system}.md`, current core/LiveView/browser fixtures and assertions. Brace groups are source-map shorthand, not literal tooling paths.

## Diminishing-returns stop

Every OUTUX requirement is covered from task, visual, accessibility, data, trust, reliability, compatibility, privacy, and acceptance perspectives. The three tracks converged on the same boundaries; remaining choices concern exact layout/implementation and require the UI contract or runtime evidence. More dashboard examples, framework comparisons, or generic checklists would not change an adopted decision. Stop research here; carry specific unresolved implementation questions into planning.
