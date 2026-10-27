# Requirements: mailglass v2.10

**Milestone:** UI Repairs & Faithful Storybook
**Defined:** 2026-10-26
**Status:** Approved 2026-10-26; implementation pending
**Core value:** Email you can see, audit, and trust before it ships.

## Scope authority and admission

The owner confirmed the next envelope on 2026-10-26 and chose reuse of the supplied research. [UPSTREAM-SCOPE.md](research/ui-quality-engine/UPSTREAM-SCOPE.md) is the upstream authority; the [rolling proposal](research/ui-quality-engine/MILESTONE-PROPOSAL.md) supplies future direction without admitting later envelopes. The [current feedback register](todos/2026-10-26-owner-review-health-preview-controls.md), [earlier feedback](todos/2026-10-25-owner-review-pr302-ui-feedback.md), and [Health note](todos/2026-10-25-health-overview-layout-owner-feedback.md) identify the repairs.

Selected seeds: SEED-009 within this envelope, SEED-261010-hjp, and the live-filter portion of SEED-261010-gad. Custom dates remain deferred. Existing research is reused; no project-wide research preference changes. Requirement numbering continues historical category maxima, including REPLAY-03 and STORY-02; these are new repair obligations, not reopened historical requirements.

## v2.10 Requirements

### Shared workspace and investigation controls

- [ ] **UXF-09**: An operator can use a compact Account control that clearly scopes Health, Deliveries and Inbound without suggesting Account-scoped Preview data.
- [ ] **UXF-10**: An operator entering Preview can return to the originating Account through a validated host-approved local destination, with a clear direct-entry fallback.
- [ ] **UXF-11**: An operator can use quieter previous/next controls on both quick views with readable position, coherent Close, 44px targets, accessible names, focus and disabled boundaries.
- [ ] **UXF-12**: An operator opening full Delivery or Inbound detail can read grouped technical evidence below primary facts without first expanding a disclosure.

### Direct collection filtering

- [ ] **FILTER-01**: An operator changing a select filter on either collection sees valid filters apply immediately without a visible Apply button.
- [ ] **FILTER-02**: An operator searching either collection gets debounced URL-backed results while retaining typed input, focus and an immediate Enter commit.
- [ ] **FILTER-03**: An operator can use Back/Forward, Clear and pagination with canonical filter state, useful history, page reset on changed filters and preserved Account isolation.
- [ ] **FILTER-04**: An operator encountering invalid filters or a failed read sees specific draft/error or stale-result feedback without silent fallback results or misleading empty states.

### Health and suppression evidence

- [ ] **OUTUX-06**: An operator can scan Health's actionable issues in a readable composition with grouped period/freshness/Refresh and subordinate activity, retaining specific deep links and truthful populations.
- [ ] **OUTUX-07**: An operator can refresh suppression evidence and retry a failed read through a consistently placed action with truthful ready, empty, stale and unavailable outcomes.
- [ ] **OUTUX-08**: An operator can understand suppression expiry and supported removal in plain language, without an invented removal button or treating unknown expiry as never expiring.

### Useful Inbound evidence

- [ ] **INUX-05**: An authorized operator can read complete ordinary Inbound sender/recipient addresses, with truthful missing, multiple-address and Unicode presentation and distinct envelope/header meanings.
- [ ] **INUX-06**: An operator can read a coherent Raw provider source card with grouped title/reveal/privacy controls and compact facts while existing reveal authorization and safe evidence projections remain enforced.

### Replay review and outcomes

- [ ] **REPLAY-04**: An operator can enter replay review from either quick view as well as full detail for the exact selected eligible record.
- [ ] **REPLAY-05**: An operator can understand why replay is unavailable before opening a dialog, without a dead-end primary replay action.
- [ ] **REPLAY-06**: An operator can review a concise, identifiable stored request in a shared accessible dialog with X-close, Escape, focus containment/return and a clearly labelled primary action.
- [ ] **REPLAY-07**: An operator completing a permitted replay sees the dialog close, an accessible success toast and updated evidence reflecting the actual domain outcome.
- [ ] **REPLAY-08**: An operator whose replay fails sees an inline error in the open dialog and a safe retry or explained re-review path without flicker, hidden errors or an unexplained disabled-review dead end.

### Preview authoring controls

- [ ] **PRVUX-05**: An author can restore scenario defaults through an intentionally aligned secondary action with clear wording and the existing reset behavior.
- [ ] **PRVUX-06**: An author editing sample values gets useful parsing, validation and read-only guidance without repetitive generic type helpers.
- [ ] **PRVUX-07**: An author can identify and choose a readable scenario with secondary module context, accessible exact technical identity and disambiguation of duplicate humanized names.

### Faithful retained Storybook scenarios

- [x] **STORY-03**: A maintainer can open Storybook and navigate its root, sidebar and deep links under the configured mount prefix without broken destinations.
- [ ] **STORY-04**: A maintainer can review repaired areas using production CSS and actual loaded production font faces/weights with matching UI, display and code roles.
- [ ] **STORY-05**: A maintainer can review repaired areas in Light, Dark and System with explicit theme ownership and correct response to OS preference changes in System mode.
- [ ] **STORY-06**: A maintainer can exercise hook-dependent retained scenarios through shared production hook behavior while Storybook owns its own socket lifecycle.
- [ ] **STORY-07**: A maintainer can find retained production-component pattern/area/job scenarios for each repair, including one complete Delivery investigation path and relevant reachable adverse states.

### Reproducible evidence and bounded upkeep

- [ ] **UIQ-04**: A maintainer can trace every named feedback item to its current-source disposition, owning requirement, retained scenario and actual behavior evidence.
- [ ] **UIQ-05**: A maintainer running the selected accessibility sweep gets fresh rule/target/state comparisons against approved findings and a failing result for missing, failed or incomplete expected execution.
- [ ] **UIQ-06**: A maintainer can reproduce source-identified story/real-route fidelity receipts and connected interaction evidence across representative themes, widths, keyboard/focus, zoom and reduced-motion conditions.
- [ ] **UIQ-07**: A maintainer can see measured added cold/warm PR wall time and runner cost, explicit coverage and justified check placement without weakened existing gates or hidden omissions.
- [ ] **UIQ-08**: The owner can review the repaired milestone in a documented working preview with current assets, committed task changes and required CI passing on the identified delivery candidate.

## Acceptance applying to every repair slice

These requirements are capabilities to prove, not evidence of completed implementation. Each owning slice delivers a repaired real situation, shared production presentation, a retained synthetic scenario and the cheapest proof of actual behavior. Do not defer stories or interaction proof to a catalogue-only milestone. Establish Storybook fidelity early and complete one Delivery investigation/recovery path early; expand infrastructure only when an admitted repair consumes it.

- **Trust boundaries:** LiveViews retain loading, params, commands and authorization. Share meaningful plain-data presentation and hook implementation incrementally; do not introduce a generic view/fixture framework. Preserve Account isolation, exact replay correlation, action-time authorization/revalidation, audit/idempotency and outbound-versus-inbound command distinctions. A successful no-change replay must not claim a new event or a resent email. Existing demo auth grants, contract guards and successful replay evidence remain completed safeguards.
- **Navigation decision:** UXF-10 admits only a validated host-approved local return destination. Prove mount-prefix handling, invalid/external destination rejection and direct-entry fallback. It conveys navigation context only; do not widen Preview auth/session whitelists or use Account to scope sample rendering. Do not describe current static Northstar links as dynamic return support. Implementation must preserve the host-friendly mounting/configuration contract.
- **Filtering:** Use existing canonical form → URL → parameter/read ownership. No per-keystroke history flood; deliberate filter/history behavior must be documented and connected-tested on both surfaces. Cover rapid typing/select/Enter, Clear during pending debounce, focused Back/Forward, reconnect, page >1 changes, invalid input and read failure. Native debounce around 300ms is an implementation starting point, not a locked requirement; new asynchronous/cancellation machinery requires demonstrated need.
- **Evidence privacy:** Unmask ordinary authorized contact displays; do not blanket-unmask raw payloads, routing/header/matcher diagnostics, telemetry or logs. Audit ordinary fields and retain genuine missing-value truth. Test/capture data is synthetic; Helios is empty by absence and is not assumed selectable. Ready suppression refresh must remain a real scoped read unless an equivalent broader refresh is proved, including expiry/external-change and partial-failure behavior.
- **Composition and interaction:** Compare bounded Health grouping alternatives at real widths. Use one design pass plus one adversarial check per repair unless a material issue remains. Follow the current brand and user-facing language. Use the ux-writing skill during replay-copy implementation, as requested in the owner feedback. Preserve reading order, visible focus, target sizes and non-color status cues; confirm stale/unavailable content and exact values remain intelligible.
- **Scenarios and projections:** Start with Northstar/Fjordline/Helios normal, empty and long/Unicode facts. Separate pure declarations/builders from persistence materializers and check representative pure-to-persisted projections for the selected repairs. Accept supported partial/late/out-of-order facts; bound history. Retain normal, filtered-empty, one/many/boundary, unknown/failure, stale and permitted/denied states only where reachable. Each retained case records ID, role/job, source, important state and reason to survive. Minimal metadata/manifest must account for expected/executed, failed/missing/zero-story cases. No profile quota or Cartesian expansion.
- **Fidelity receipt:** Record source revision, actual story and connected URLs, successful CSS response bytes/digest, intended font family/weight, matching loaded faces and successful font assets, computed roles, theme/OS preference and relevant hook behavior. A CSS family declaration, fonts-ready or FontFaceSet.check alone is insufficient. Check applicable adapters against both resolved Admin/demo LiveView clients and pinned Storybook; an upgrade is not a prerequisite.
- **Responsive/accessibility evidence:** Light/dark cover repaired states; use representative 320/375/768/1280/1440 landmarks, defect widths and real pane/content boundaries without screenshotting every equivalent combination. STORY-05 owns System/OS changes; interaction-owning slices own keyboard/focus and reduced motion; UIQ-06 ensures real browser zoom evidence. Static stories prove rendering; URL/history, authorization, replay, persistence and critical hook transitions require connected proof. Distinguish axe violations, separately triaged incomplete findings, and missing/incomplete execution; no vacuous pass or quiet rebaseline. Do not turn unrelated accessibility debt into a cleanup prerequisite.
- **Cost and gate truth:** Reuse ExUnit/Playwright/axe, existing dependencies and CI lanes. Pilot provisional additional ≤5 PR wall minutes / ≤10 runner-minutes including setup under cold/warm conditions. These are unmeasured budgets, not guaranteed performance. The Ecto demo still needs Postgres. If exceeded, remove duplication/measure placement and document tradeoffs; do not silently weaken coverage or gates. Required/advisory placement must be evidenced in actual CI; advisory critique remains labelled advisory, without aesthetic precision claims.
- **Review delivery:** A working preview and required CI support review; no merge, release, publication or deployment follows automatically. D-52 closes machine-observable acceptance through current automated evidence. Record evidence limits, owner judgment where needed, and disposition of temporary services/artifacts. An old JSON total or aesthetic score cannot close current acceptance.

## Feedback coverage

Every unresolved row is admitted. Any later exclusion needs an explicit destination, reason and owner approval rather than silent deferral.

| Named feedback | Owning requirement(s) |
| --- | --- |
| Health crowding, freshness/Refresh grouping, activity hierarchy | OUTUX-06 |
| Preview reset alignment/weight and repetitive helpers | PRVUX-05, PRVUX-06 |
| Readable selected Preview scenario/module identity | PRVUX-07 |
| Compact Account context and coherent Preview return | UXF-09, UXF-10 |
| Auto-apply both collections, no Apply | FILTER-01–04 |
| Quiet quick-view arrows on both surfaces | UXF-11 |
| Raw provider source hierarchy and privacy/reveal grouping | INUX-06 |
| Suppression Refresh/Retry and truthful wording | OUTUX-07, OUTUX-08 |
| Complete ordinary authorized Inbound addresses | INUX-05 |
| Quick-view replay, truthful availability, concise dialog/X, success toast and inline errors/retry | REPLAY-04–08 |
| Technical evidence visible by default on full detail | UXF-12 |
| Storybook navigation, fonts/themes/hooks and stories beyond primitives | STORY-03–07 |

UIQ-04–08 and the shared acceptance obligations apply across these rows. Phase ownership will be filled by the roadmap.

## Future requirements

- Deeper whole-job Delivery/Inbound/Preview and separate author/recipient output/unsubscribe GET scenarios, driven by uncovered supported risk after these repairs ship.
- Self-hosted/global/B2C profiles only when a distinct supported job, interaction, content or layout risk justifies them; six is a candidate ceiling, not a quota.
- F7 demo token-route mounting as a separately named integration candidate; no inferred interactive unsubscribe submission flow.
- Useful Gallery case/assertion migration with keep/merge/prune/defer accounting, then consolidation only where the maintenance payoff justifies it. Preserve the published route pending compatibility disposition.
- Custom date ranges and timezone/DST semantics from the unselected portion of SEED-261010-gad.
- Broader persistent-disclosure state preservation, Preview iframe connect/reload behavior and Inbound initial-load flash remain separate backlog items unless a selected repair exposes a direct blocker. Do not imply this milestone closes all copies of a related pattern.

## Out of scope

| Item | Reason |
| --- | --- |
| Exhaustive Gallery migration, fully storied app or six materialized adopter products | Trim speculative breadth before deferring named repairs; reassess after useful slices ship. |
| Rebrand, replacement design system or iOS imitation | Preserve the current brand and craft direction. |
| Account-aware Preview, broader sensitive disclosure, new provider/capability growth | Changes product or trust contracts beyond UI repairs. |
| Custom dates and interactive unsubscribe submission | Separate compatibility-aware capability work; neither blocks admitted repairs. |
| Public Gallery route removal | Requires a concrete compatibility disposition. |
| Generic view/fixture framework, finding database, calibration/judge service or speculative dependencies | No evidence these are necessary for the selected repairs or one-maintainer upkeep. |
| CI-wide efficiency redesign or weakened gates | Measure the added checks narrowly and preserve existing contracts. |
| Automatic package version bump, merge, publication or deployment | Milestone initialization and preview acceptance do not authorize a release ceremony. |

## Traceability

Requirements and [roadmap](ROADMAP.md) confirmed 2026-10-26. Each of the 31 requirements is assigned to exactly one phase; no implementation is marked complete.

| Requirement | Phase | Status |
| --- | --- | --- |
| UXF-09 | Phase 177 | Pending |
| UXF-10 | Phase 177 | Pending |
| UXF-11 | Phase 174 | Pending |
| UXF-12 | Phase 175 | Pending |
| FILTER-01 | Phase 176 | Pending |
| FILTER-02 | Phase 176 | Pending |
| FILTER-03 | Phase 176 | Pending |
| FILTER-04 | Phase 176 | Pending |
| OUTUX-06 | Phase 177 | Pending |
| OUTUX-07 | Phase 175 | Pending |
| OUTUX-08 | Phase 175 | Pending |
| INUX-05 | Phase 176 | Pending |
| INUX-06 | Phase 176 | Pending |
| REPLAY-04 | Phase 175 | Pending |
| REPLAY-05 | Phase 175 | Pending |
| REPLAY-06 | Phase 175 | Pending |
| REPLAY-07 | Phase 175 | Pending |
| REPLAY-08 | Phase 175 | Pending |
| PRVUX-05 | Phase 178 | Pending |
| PRVUX-06 | Phase 178 | Pending |
| PRVUX-07 | Phase 178 | Pending |
| STORY-03 | Phase 174 | Complete |
| STORY-04 | Phase 174 | Pending |
| STORY-05 | Phase 174 | Pending |
| STORY-06 | Phase 174 | Pending |
| STORY-07 | Phase 178 | Pending |
| UIQ-04 | Phase 178 | Pending |
| UIQ-05 | Phase 174 | Pending |
| UIQ-06 | Phase 178 | Pending |
| UIQ-07 | Phase 178 | Pending |
| UIQ-08 | Phase 178 | Pending |

**Coverage:** 31 requirements; 31 assigned exactly once; 0 unmapped; 0 duplicated.

---
*Last updated: 2026-10-26 after owner approval of all 31 requirements and the Phase 174–178 roadmap.*
