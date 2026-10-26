---
phase: 168-shared-workspace-and-usable-baseline
plan: "02"
subsystem: ui
tags: [phoenix-liveview, heex, tailwind, accessibility, operator]

requires:
  - phase: 168-01
    provides: shared Account context, operator navigation, and tenant-scoped filters
provides:
  - readable Health and Delivery surfaces at narrow, desktop, and zoomed widths
  - stable busy and validation feedback for operator and inbound filters
  - truthful stale/unavailable copy and exact full-detail evidence
affects: [168-03, 168-04, operator-ui, delivery-investigation]

actuals:
  tokens: 76454
  tasks: 3
  commits: 3
  plan_head_before: be146c327f37ec5e9775aed65b298c4dcf9c88c3
  plan_head_after: d2b64cda89fed70e299046bacfb0a3d49bb1a03a

tech-stack:
  added: []
  patterns:
    - fixed-width LiveView busy submit labels prevent adjacent action movement
    - filter invalid-value tests inspect field option DOM rather than embedded client JavaScript
    - UTC timestamps remain exact in visible detail and copy affordance

key-files:
  created:
    - .planning/phases/168-shared-workspace-and-usable-baseline/artifacts/plan02/168-task2-inbound-keyboard-focus.png
    - .planning/phases/168-shared-workspace-and-usable-baseline/artifacts/plan02/168-task2-inbound-validation-320.png
  modified:
    - .planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md
    - .planning/phases/168-shared-workspace-and-usable-baseline/deferred-items.md
    - .planning/WINDOWS.md
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/test/mailglass_admin/components_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/mailglass_admin/voice_test.exs

key-decisions:
  - "Keep Health cards in a three-column layout only at the desktop breakpoint after 768px review showed the smaller layout compressed labels."
  - "Use a fixed-width `Applying filters…` button state so LiveView pending feedback does not move the Clear filters action."
  - "Keep Account context in the shared shell and remove stale test expectations for duplicate filter-level Account controls."
  - "Use exact approved stale/unavailable copy and never manufacture an observation time for stale data."

patterns-established:
  - "At narrow widths, wrap exact Delivery identifiers and use labeled focusable scroll regions for wide tables."
  - "Verify invalid filters against the rendered option element so the Phoenix client bundle cannot satisfy a broad document-text assertion."

requirements-completed: [UXF-03, UXF-04, UXF-06]

coverage:
  - id: D1
    description: "Health and Deliveries use readable hierarchy and retain exact long Delivery evidence."
    requirement: UXF-03
    verification:
      - kind: unit
        ref: "mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1 (87 tests)"
        status: pass
      - kind: manual_procedural
        ref: "168-BASELINE.md — Task 1 rendered matrix, light/dark widths, zoom-equivalent reflow, and overflow confirmation"
        status: pass
    human_judgment: true
    rationale: "Reading order, wrapping, and contrast require direct visual judgment at the target widths."
  - id: D2
    description: "Operator and inbound filters expose stable busy, focus, and validation states with retained input."
    requirement: UXF-04
    verification:
      - kind: unit
        ref: "mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --seed 1 (246 tests)"
        status: pass
      - kind: manual_procedural
        ref: "168-BASELINE.md — Task 2 keyboard, 200% zoom, and touch-emulation confirmation"
        status: pass
    human_judgment: true
    rationale: "Focus appearance and responsive touch-emulated controls need direct browser inspection."
  - id: D3
    description: "Account chooser, empty, stale, unavailable, and full-detail copy preserve their actual causes and exact evidence."
    requirement: UXF-06
    verification:
      - kind: unit
        ref: "mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/voice_test.exs --seed 1 (98 tests, 0 failures, 1 excluded)"
        status: pass
      - kind: manual_procedural
        ref: "168-BASELINE.md — Task 3 no-activity, filtered-empty, stale/unavailable, and long-detail review"
        status: pass
    human_judgment: true
    rationale: "The operator-facing meaning of observed status and recovery text requires contextual review."

duration: 53min
completed: 2026-10-07
status: complete
---

# Phase 168 Plan 02: Shared Workspace and Usable Baseline Summary

**Health, Deliveries, and shared filters now preserve readable operational facts, stable pending feedback, and cause-specific recovery across narrow, desktop, and zoomed views.**

## Performance

- **Duration:** 53 minutes
- **Started:** 2026-10-07T19:09:29Z
- **Completed:** 2026-10-07T20:02:41Z
- **Tasks:** 3
- **Files modified:** 34

## Accomplishments

- Set the shared body and label type sizes, moved Health metrics to a readable desktop breakpoint, constrained the hidden tooltip that caused page overflow, and kept long Delivery details readable.
- Added fixed-width busy submit feedback to Operator and Inbound filters. Corrected invalid-filter tests to inspect actual option elements and aligned component tests with the shared Account shell.
- Replaced fabricated stale time and generic Delivery error copy with approved recovery wording; verified exact Unicode names, provider IDs, Delivery IDs, recipient, and UTC timestamp in full detail.
- Recorded a light/dark width matrix, filter state review, account boundary evidence, corrections, and confirmation in `168-BASELINE.md`. Fixed Windows ledger item #37.

## Task Commits

1. **Task 1: Make Health and Deliveries readable at width and zoom with exact evidence** - `2786cb13` (`fix`)
2. **Task 2: Complete labeled filter and shared control states** - `d890570f` (`fix`)
3. **Task 3: Keep shared domain copy and full values truthful in working tasks** - `d2b64cda` (`fix`)

## Files Created/Modified

- `mailglass_admin/assets/css/app.css` and `mailglass_admin/priv/static/app.css` - Shared type tokens and generated asset bundle.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` and `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` - Working-screen hierarchy, busy feedback, and cause-specific copy.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - Stable busy feedback for the inbound filter action.
- `mailglass_admin/test/mailglass_admin/components_test.exs`, `inbound_live_test.exs`, `operator_live_test.exs`, and `voice_test.exs` - Focused filter, copy, empty-state, and exact-value assertions.
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md` - Rendered evidence and correction record.
- `.planning/phases/168-shared-workspace-and-usable-baseline/deferred-items.md` and `.planning/WINDOWS.md` - Closed invalid-filter and tooltip overflow records.
- `.planning/phases/168-shared-workspace-and-usable-baseline/artifacts/plan02/` - Task 1 light/dark viewport captures and Task 2 keyboard/validation captures.

## Decisions Made

- Kept Health metric cards in three columns only at the desktop breakpoint after 768px review showed the smaller layout compressed labels.
- Used a 160px busy submit width to keep the adjacent Clear filters action in place while `Applying filters…` is visible.
- Scoped invalid-filter tests to their actual option DOM; broad document text also includes Phoenix's embedded client code.
- Used the approved stale/unavailable copy and removed the hard-coded 14:32 stale timestamp because it could imply an unobserved measurement.

## Deviations from Plan

### Verification repairs and copy alignment

**1. Narrowed invalid-filter assertions and updated stale component wrapper tests**
- **Found during:** Task 2
- **Issue:** Full-document `not-real` assertions also matched embedded Phoenix JavaScript, and component tests still expected Account filters removed by Plan 01.
- **Fix:** Asserted that invalid values are absent from the actual select options while keeping the recovery-copy, input-retention, tenant-scope, and filter-order checks.
- **Files modified:** `components_test.exs`, `inbound_live_test.exs`, `operator_live_test.exs`
- **Verification:** Task 2 focused suite passed 246 tests with 0 failures.
- **Committed in:** `d890570f`

**2. Updated obsolete chooser copy expectations in the existing voice test**
- **Found during:** Task 3
- **Issue:** Two assertions expected title-cased copy that no longer matched the locked Account strings after Plan 01.
- **Fix:** Updated only the chooser copy assertions and link label to the exact approved wording; retained the existing syntax repair and all substantive checks.
- **Files modified:** `voice_test.exs`
- **Verification:** Task 3 focused suite passed 98 tests with 0 failures and 1 pre-existing excluded test.
- **Committed in:** `d2b64cda`

**Total deviations:** 2 verification/copy alignment repairs. **Impact:** These changes removed known false-negative checks while preserving validation, account-scope, and chooser behavior guarantees.

## Issues Encountered

- The first Task 2 component suite run revealed obsolete wrapper expectations and invalid whole-document text assertions. Both were corrected and the full focused suite passed.
- The source and served CSS SHA-256 remained identical at `f69967633993c46a60cdb72e21e11c9ea7147574efda513964476bd7e562a20e`; Tasks 2 and 3 did not require CSS changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 is complete. Health, Deliveries, shared filters, and truthful Delivery recovery now have focused verification and rendered evidence. Plans 03 and 04 can use the recorded baseline and should preserve the exact Account and Delivery semantics.

---
*Phase: 168-shared-workspace-and-usable-baseline*
*Completed: 2026-10-07*

## Self-Check: PASSED

- Summary file exists at the expected plan path.
- Task commits `2786cb13`, `d890570f`, and `d2b64cda` are ancestors of HEAD.
- The persisted plan ledger measures 3 commits from `be146c327f37ec5e9775aed65b298c4dcf9c88c3` through `d2b64cda89fed70e299046bacfb0a3d49bb1a03a`.
