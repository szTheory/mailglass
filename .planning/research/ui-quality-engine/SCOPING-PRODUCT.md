# Upstream scope: repair real journeys while establishing useful stories

**2026-10-26 · Recommendation for OpenGSD discovery, not requirements or a phase plan.** No implementation, dependency change or milestone activation. This refines the [rolling proposal](MILESTONE-PROPOSAL.md) after the [latest owner review](../../todos/2026-10-26-owner-review-health-preview-controls.md). Existing [persona/design research](PERSONAS-DESIGN.md) remains supporting evidence; the sequence below supersedes its suggestion to defer known Inbound/Preview repairs behind Delivery expansion.

## Boundary decision

| Approach | Benefit | Failure mode | Decision |
|---|---|---|---|
| Repair first; build stories later | Fast visible improvement | Another polish pass with weak retained scenario coverage; infrastructure repeatedly postponed | Reject as the overall sequence. Small fidelity/defect repairs can lead. |
| Story infrastructure first | Uniform tooling before UI changes | Owner's known defects wait through catalogues, fixture frameworks and multiple UI milestones | Reject. A manifest is not a user outcome. |
| **Integrated vertical slices** | Each repaired real journey gains realistic stories and appropriate connected proof | Scope can grow into full-app extraction | **Recommend. First milestone includes all currently identified feedback; defer breadth, not these repairs.** |

The owner has already supplied concrete product direction. Research should refine its boundaries and consequences, not reopen it as an interview. OpenGSD should determine implementation order, phase granularity and test allocation after reconciling current source.

## One rolling sequence

### Next milestone candidate: coherent operator and author essentials

**Outcome:** an operator can read Health, find a Delivery or received message, inspect useful evidence and understand recovery; an author can choose and edit a preview without awkward controls. Maintainers can inspect the repaired areas in a trustworthy Storybook, using the actual components.

**In scope:** every row in the feedback disposition below, plus Storybook mount/font/theme/hook fidelity and only the fixture/manifest/checking support needed to retain those repaired scenarios. Group repairs by owning pattern and journey; no complete LiveView extraction prerequisite.

**Minimum acceptance:** each feedback item has a current-source disposition, implemented outcome or explicit owner-approved exclusion; repaired controls work on real routes; supported action and account boundaries remain intact. Retained stories demonstrate normal and relevant unavailable/error/stale/boundary states. Check representative narrow/wide/container layouts in both themes, visible keyboard focus, meaningful accessible names and non-clipped exact values. Prove consequential state changes and URL/Back behavior at connected seams. Story rendering matches the production font roles, assets and themes, and explorer navigation respects the mount path. Reuse existing required checks and report advisory evidence honestly.

**Exclude:** exhaustive story migration, six fully materialized adopter products, a generic view-schema framework, rebranding, public Gallery removal, new Preview tenant/auth semantics, custom date-range expansion, interactive unsubscribe submission and CI-wide efficiency redesign.

**Stop/reassess:** close when known feedback is resolved with retained evidence, not when every component has a story. If delivery must split, split into adjacent small increments with named feedback ownership and a reason; do not silently move Preview/Inbound repairs into an indefinite later horizon. Reassess only newly uncovered contracts, cost or actual blocked dependencies.

### Following candidate: deeper scenario coverage for the same supported jobs

**Outcome:** contributors can zoom from whole jobs into areas/patterns/components and inspect distinct reachable states across Deliveries, Inbound and Preview without reconstructing a database incident.

Extend the proven composition/fixture approach to uncovered high-value states; add a new adopter profile only when it exposes a distinct supported risk. Include recipient GET/output scenarios as their own author/recipient context. Demo unsubscribe token-route mounting (F7) is a separately identified integration candidate, not an assumed new browser confirmation flow.

**Minimum acceptance:** declared job/state map, justified keep/merge/prune/defer decisions, representative pure-versus-persisted projection agreement, connected critical transitions, and measured review/check runtime. **Stop:** no extra profile or component split without a distinct user/job/state contribution; reassess from actual uncovered risk and maintainer cost.

### Later candidate: consolidate inventories and make review routine

**Outcome:** one canonical review inventory, little duplicated upkeep, triaged design findings and quick local/PR feedback.

Migrate useful Gallery cases and dependent assertions; calibrate bounded advisory review from owner-labelled examples; maintain pruning and runtime budgets. **Minimum acceptance:** every old case accounted for, meaningful regressions preserved, owner decisions retained, fresh checks cannot pass vacuously. Keep the published Gallery route until a concrete compatibility decision permits removal. **Stop:** quiet maintenance is valid once additional coverage adds no useful risk reduction.

These are rolling outcome boundaries, not three approved milestones or phase lists.

## Current feedback disposition

Source: [latest review](../../todos/2026-10-26-owner-review-health-preview-controls.md), [original owner feedback](../../todos/2026-10-25-owner-review-pr302-ui-feedback.md), and [Health-specific feedback](../../todos/2026-10-25-health-overview-layout-owner-feedback.md). All unresolved rows belong in the **next** candidate.

| Area / owning tier | Firm owner direction | Recommended treatment / hypothesis to compare |
|---|---|---|
| Health / area | Crowding and awkward columns must improve; preserve specific actionable issues and deep links | Prefer a constrained primary issue list, grouped period/freshness/refresh and subordinate activity. Compare a deliberate secondary grouping against one-column flow at real container widths. Do not invent severity ranking from counts alone or alter population definitions. |
| Reset / shared action family + Preview area | Fix inset/borderless-looking reset and redundant generic helpers | Use consistent secondary-action weight and alignment; recommend **Restore defaults**. Reset changes sample inputs; Refresh rereads evidence; Retry repeats a failed read. Share visual rules, not misleading semantics or one universal event. Preserve useful validation/type guidance. |
| Preview identity / selector pattern | Selected Mailable/scenario should look intentional, not assembled | Use readable scenario identity with module context secondary, full exact identity accessible. Test long/duplicate humanized labels. Removing the middle dot is preference, not an accessibility theorem. |
| Account / shell and Preview navigation | Compact inconsistent Account control; coherent navigation | Keep Account context where it actually scopes records. Preview currently renders sample values: no fake picker. Current navigation is static and does not prove dynamic same-Account return. If accepted downstream, scope a narrow validated navigation-only capability; a true account-aware Preview is separate product work. |
| Filters / both collections | Auto-apply selects and debounced text; no Apply button | Keep URL as committed state, truthful feedback and Back semantics; test rapid edits, no matches and Account changes. Custom date ranges are not prerequisite. |
| Quick view / shared navigation pattern | Quieter previous/next arrows in both surfaces | Remove unnecessary visual outlines, retain comfortable targets, names, focus/hover and disabled boundaries. Keep position and Close coherent; do not shrink hit areas to quiet the appearance. |
| Raw source / evidence area | Repair crowded hierarchy and disconnected control/privacy note | Group heading, reveal action and privacy explanation; compact facts and consistent label/value roles. Preserve disclosure gates and safe unavailable states. |
| Suppression / evidence area + refresh pattern | Fix Refresh placement and internal vocabulary | Place the real read action consistently with scope/freshness. Explain whether removal is supported without advertising a nonexistent UI action. Unknown expiry remains unavailable; do not say “never.” |
| Ordinary Inbound addresses / evidence presentation | Show complete sender/recipient addresses in authorized ordinary evidence | Audit ordinary displays/shared components. This is settled direction, distinct from raw source, sensitive trace/header/matcher values, telemetry, logs and screenshots. Keep those protections; explicit field inventory prevents accidental broadening. |
| Replay / shared dialog structure, distinct domain commands | Quick-view entry; truthful availability; concise review; familiar close; clear success/failure/retry | Reuse dialog structure, not outbound/inbound business semantics. No dead-end primary action when unavailable, no hidden flash behind an open dialog, no unexplained consumed/disabled review. Preserve exact target, revalidation and authorization. Retain the already-fixed demo grant and success e2e rather than fixing them twice. |
| Full detail / evidence hierarchy | Show useful technical details without default collapse | Visually group below primary facts; distinguish ordinary technical evidence from authorized raw disclosure. |
| Storybook / rendering infrastructure | Fix five-story limitation, broken navigation and serif mismatch | Fidelity first, then stories for these repaired patterns/areas/jobs. Do not critique a screenshot as production aesthetics until fonts/themes/hooks actually match. |

Local implementation evidence is named in the latest review. Direct inspections also confirm Health's 2:1 grid, Preview's `btn-ghost ... px-5` reset and the suppression-specific `retry_suppression` event: [HealthOverview](../../../mailglass_admin/lib/mailglass_admin/operator/health_overview.ex), [AssignsForm](../../../mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex), [SuppressionCard](../../../mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex).

Consistent action emphasis does not mean every action must be primary or occupy an identical coordinate. GOV.UK distinguishes main/secondary actions and descriptive labels; apply that principle rather than its specific visual style. Disclosure should preserve context and remain purposeful. [GOV.UK buttons](https://design-system.service.gov.uk/components/button/), [Primer progressive disclosure](https://primer.style/product/ui-patterns/progressive-disclosure/).

## Minimum useful personas; no theatre

Start with the existing Northstar/Fjordline/Helios cohort: many/failure, one/long/Unicode, and empty. Add explicit operator/engineer/author roles and only scenarios needed for the selected fixes. Denied/stale/unavailable are state overlays, not new biographies. Existing Helios is empty by absence and not automatically switcher-selectable. Keep that truth.

The previously proposed self-hosted, language-learning and finance profiles remain future hypotheses. Require a unique supported content/deployment/job contribution before materializing one. Synthetic scenarios are test instruments, not validated customer personas or literal digital twins.

## Adversarial objections and OpenGSD handoff

- **“All feedback is too broad.”** It crosses surfaces but mostly concerns a few action, evidence, navigation and dialog patterns. Bound by the enumerated feedback; trim speculative catalogue work first. OpenGSD may split delivery based on actual dependency/cost without losing named ownership.
- **“Shared patterns will erase domain differences.”** Share presentation rules; preserve reset/read/retry and outbound/inbound command contracts.
- **“Repairing first loses the Storybook opportunity.”** Each repair retains its useful scenario immediately. No full infrastructure programme must precede it.
- **“A new screenshot guarantees taste.”** It demonstrates a comparison, not universal quality. Machine-observable acceptance remains automated; only unresolved taste or material product decisions go to the owner.

**Handoff inputs:** current feedback ledger and precedence, proposed outcome boundaries, scope/exclusions, acceptance direction, domain/privacy constraints, preserved strengths, minimal scenario cohort, tradeoffs and reassessment triggers.

**OpenGSD owns:** current-state reconciliation, formal milestone choice, requirement IDs/wording, phase/plan decomposition, technical design validation, test assignment/gating, estimates, execution and verification. This note does not preassign phase counts or convert hypotheses into locked requirements.

**Strategic questions:** none blocks the repair scope. A genuinely account-aware Preview, sensitive disclosure beyond ordinary authorized addresses, Gallery route removal or brand change would need a concrete separate decision. Routine layout comparisons and labels should be resolved through evidence and the owner's stated direction.
