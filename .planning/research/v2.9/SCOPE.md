# v2.9 scope: Operator, Preview & Email UI Refinement

**Date:** 2026-10-07
**Status:** Approved by the owner on 2026-10-07. Milestone v2.9 is active for planning; implementation has not started. Canonical requirements and phase ownership are in [REQUIREMENTS.md](../../REQUIREMENTS.md) and [ROADMAP.md](../../ROADMAP.md). Product discovery and Impeccable initialization are complete.

## Goal

Engineers, support/on-call operators, email authors, and recipients can complete Mailglass's existing journeys through a coherent, readable, responsive experience with clear actions and truthful outcomes. Deliver a working baseline for optional owner feedback after bounded automated and visual acceptance.

## Settled direction

- Engineers and support/on-call operators are equal primary Admin audiences. Authors and recipients have distinct needs.
- The owner selected code-first in `.impeccable/config.json`; root `PRODUCT.md` owns durable product truth.
- Use Impeccable in Operate mode for admin/preview and apply the relevant Kowalski guidance to purposeful interaction/motion work. Preserve Mailglass identity and the sender identity of recipient messages.
- Favor familiar controls, clear hierarchy, coherent domain language, readable essential text, comfortable spacing, and mobile usability. Choose layout and disclosure according to the task.
- Use shared components/tokens and remove superseded rules. Keep the existing LiveView/HEEx and adopter-facing prebuilt asset model.
- Automate routine verification and inspect actual rendered results. Owner feedback is optional refinement, not recurring manual acceptance labor.

## Research decision

Reuse the source-backed stocktake in `.planning/notes/2026-10-07-mailglass-ui-refinement-scope.md`, current source, existing browser/LiveView checks, gallery/Storybook, and previous UI inventories. Skip a fresh four-part domain/ecosystem research round for this milestone: no new product category or stack is proposed. This is a milestone-local decision, not a change to `workflow.research` or phase-specific research settings.

Targeted research remains appropriate for a named implementation uncertainty. A small first-party reference comparison may guide a real layout decision. Historical screenshot inventories, ratings, and old success counts are not verification of new source.

## Coverage and boundaries

Include shell/navigation/account/theme, Email health, deliveries and suppression investigation, exact-target replay, inbound routing/evidence/recovery, developer preview, public email components and examples, built-in unsubscribe GET pages, and the review/demo surfaces needed to inspect them. Inventory interactions and states, not just routes.

Fix demonstrated correctness problems needed by these existing journeys even when a correction touches core/inbound code. Preserve stable API, authorization, tenant, replay, rendering, and protocol contracts. A new capability or expensive compatibility change requires an explicit scope decision.

**Approved unsubscribe boundary:** improve the existing built-in browser GET and invalid/expired responses so they explain the actual state and available supported path without claiming an unsubscribe occurred. Preserve configured host redirects and the existing protocol POST response/idempotency behavior. Adding an interactive confirmation/submission journey or preference center is deferred; the current GET page must not promise an action it cannot perform. This approved boundary closes the open initialization question.

## Seed dispositions

| Seed | Disposition | Reason |
| --- | --- | --- |
| SEED-004 sent-email snapshot retention | Keep deferred | Adds retention, persistence, access, and privacy policy. Improve presentation of existing evidence only. |
| SEED-005 native HEEx assigns pipeline | Keep deferred | Changes stable authoring/rendering semantics. Examples must use supported rendering paths and document their actual behavior. |
| SEED-008 delivery absence detection | Keep deferred | New provider preflight/threshold detection belongs to a capability milestone. UI must still distinguish absent evidence from success. |
| SEED-003 ecosystem integrations | Keep deferred | Unrelated product expansion. |
| SEED-006 CI efficiency | Keep deferred | Reuse existing lanes; no pipeline redesign is needed for visual refinement. |
| SEED-007 sandbox ownership leak | Historical, already implemented | Do not reopen completed work without a reproduced regression. |

Seed files remain unchanged. No pending todo has been identified as a direct UI requirement to promote.

## Acceptance carried through every phase

1. Identify the user job and concrete defect or documented improvement before editing. Capture representative current output and the source/fixture/route/theme/viewport that produced it.
2. Inspect representative desktop and mobile, light and dark together; exercise System theme, intermediate breakpoints, zoom, and reduced motion where changes affect them. Cover applicable empty, filtered-empty, loading/busy, error, permission, stale/disconnected, zero/one/many, long, and non-ASCII states.
3. Use rendered forms and controls to prove behavior. Preserve account/filter/object context through actual handoffs and back navigation. Exact IDs, times, and consequences remain available without exposing unnecessary message data.
4. Use existing component/LiveView, accessibility, token/conformance, browser, and mounted asset checks. Add focused regression coverage for demonstrated gaps. Update an obsolete presentation assertion together with its replacement behavior and rationale; retain substantive safety checks.
5. Use one batched visual inspection, one corrective batch, and one confirmation round per coherent delivery slice. Further work requires a concrete unresolved blocker. No recurring paid visual judge, new required AI lane, manufactured score increase, or exhaustive cross-product screenshot matrix.
6. Treat public email output and the separate AtlasDesk demo renderer explicitly. Browser captures establish preview behavior; preserve MSO/VML and plaintext protections and state the actual limits of email-client evidence.
7. Keep generated admin bundles with relevant source changes. Mutating fixtures use disposable data. Preserve feedback-preview state and other projects' services.

## Workspace and lifecycle continuity

Local `main` has a preserved WIP commit and pre-existing changes; its remote-tracking reference is stale. The prior session completed the cleanup PR and verified merged main. Before execution, reconcile the local baseline with that merged source without discarding work, and record which checkout the preview serves. Milestone initialization does not authorize resetting local changes.

The outgoing milestone is v2.8. Numbering continues at Phase 168. The residual Phase 167.1 directory is archived under `milestones/v2.8-phases/` through the GSD lifecycle as part of initialization. The old v2.8 'no Phase 168' limit applied to that completed milestone only.

Use the GSD SDK for the state switch. Preserve accumulated history; make the current focus and next command unambiguous. Commit only owned planning/product/config artifacts and exact archive moves. Do not stage unrelated local changes.

Milestone version v2.9 is a planning label, not a Hex version instruction. Finish the implementation through the existing PR and required-check process. Any future merge/publication uses its applicable authorization and release workflow; the earlier cleanup-PR approval was specific to that PR.

## Inputs

- Root `PRODUCT.md`, `.impeccable/config.json`
- `.planning/notes/2026-10-07-mailglass-ui-refinement-scope.md`
- `.planning/PROJECT.md`, `MILESTONES.md`, `ROADMAP.md`, `STATE.md`, and seeds
- `brandbook/brand-book.md`, `brandbook/copy/microcopy.md`
- `mailglass_admin/docs/design-system.md`, `operator-trust.md`, and current components/CSS
- `guides/jobs.md`, `guides/unsubscribe.md`, `guides/run-the-demo.md`
- Existing core/admin tests, `reference/demo_app`, and sibling-project lessons recorded in the stocktake

Milestone discovery and initialization include source review, not a new app boot, runtime UI audit, test run, or current CI claim.
