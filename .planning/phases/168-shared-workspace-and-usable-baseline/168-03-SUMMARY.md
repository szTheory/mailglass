---
phase: 168-shared-workspace-and-usable-baseline
plan: "03"
subsystem: ui
tags: [phoenix-liveview, heex, tailwind, accessibility, appearance, feedback]

requires:
  - phase: 168-02
    provides: readable Health and Deliveries surfaces, corrected stale/unavailable copy, and shared filter states
provides:
  - visible persisted System, Light, and Dark appearance choices across shared chrome
  - accessible feedback semantics, exact UTC timestamp names, and long-copy wrapping
  - updated rendered review evidence with explicit coverage limits
affects: [168-04, operator-ui, preview-ui, accessibility]

actuals:
  tokens: 67987
  tasks: 2
  commits: 2
  plan_head_before: 840d8bd72ddd1d0061a994208aa426be8300434c
  plan_head_after: e5f77bf3a2c065201180899480f478b77ec2af72

tech-stack:
  added: []
  patterns:
    - visible theme preference labels remain paired with native radios and persisted choice
    - alert/status feedback includes explicit live-region semantics and wrapping content
    - timestamp controls expose the exact recorded UTC value without hover

key-files:
  created: []
  modified:
    - .planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/test/mailglass_admin/components_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs

key-decisions:
  - "Keep System, Light, and Dark as visible labels beside the existing native radio controls and persisted preference."
  - "Give error feedback alert semantics and success feedback status semantics, with stable identifiers and keyboard-accessible dismissal."
  - "Expose exact UTC timestamps in accessible names while rendering missing timestamps as Unavailable."

patterns-established:
  - "Status meaning is expressed in text and live-region semantics, not only icon or color."
  - "Long status and recovery copy wraps inside the feedback region, and missing observation times are never invented."

requirements-completed: [UXF-04, UXF-05, UXF-06, UXF-07, UXF-08]

coverage:
  - id: D1
    description: "The shared appearance picker visibly exposes the selected System, Light, or Dark preference across operator and preview chrome."
    requirement: UXF-04
    verification:
      - kind: unit
        ref: "mix test test/mailglass_admin/components_test.exs test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1 (106 tests)"
        status: pass
      - kind: manual_procedural
        ref: "168-BASELINE.md — Plan 168-03 Task 1 Review and Confirmation"
        status: pass
    human_judgment: true
    rationale: "OS color-scheme changes were not directly emulated during browser review."
  - id: D2
    description: "Feedback and status expose readable semantics, exact timestamps, keyboard-accessible dismissal, and wrapping long copy."
    requirement: UXF-07
    verification:
      - kind: unit
        ref: "mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --seed 1 (248 tests)"
        status: pass
      - kind: unit
        ref: "mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1 (8 tests)"
        status: pass
      - kind: manual_procedural
        ref: "168-BASELINE.md — Plan 168-03 Task 2 Review and Confirmation"
        status: pass
    human_judgment: true
    rationale: "The demo did not provide a transient error, missing asset, or pending state to trigger live; reduced-motion was not emulated."

duration: 5min
completed: 2026-10-07
status: complete
commits: 2
plan_head_before: 840d8bd72ddd1d0061a994208aa426be8300434c
plan_head_after: e5f77bf3a2c065201180899480f478b77ec2af72
---

# Phase 168 Plan 03: Shared Workspace and Usable Baseline Summary

**The shared appearance picker now names its persisted preference, while feedback, outcome labels, and exact timestamps remain accessible through operator and preview chrome.**

## Performance

- **Duration:** 5 minutes from first task commit to completion (implementation began earlier; exact start time was not captured)
- **Started:** 2026-10-07T16:08:57-04:00 (first task commit; implementation began earlier)
- **Completed:** 2026-10-07T16:13:16-04:00
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added visible Appearance, System, Light, and Dark labels while preserving the existing single selected radio and preference persistence across operator and preview navigation.
- Added explicit alert/status live-region semantics, stable feedback IDs, accessible dismissal controls, long-copy wrapping, and a truthful unavailable timestamp fallback.
- Exposed the exact recorded UTC time through the timestamp's accessible name and kept existing status labels tied to observed domain facts.
- Rebuilt the checked-in stylesheet and confirmed its served response hash matches the generated artifact.
- Recorded live theme, zoom, feedback, status, timestamp, and served-bundle evidence in `168-BASELINE.md`, including states that could not be emulated.

## Task Commits

1. **Task 1: Show the persisted System, Light and Dark choice in the shared picker** - `031aee42` (`feat`)
2. **Task 2: Keep feedback and icon states readable without repeated motion** - `e5f77bf3` (`feat`)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/components.ex` - Visible theme choices, semantic feedback, timestamp accessibility, and wrapping data-state copy.
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` - Stable and accessible shell feedback regions.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - Stable identifier on the representative refresh detail region.
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` - Removed fabricated stale observation time.
- `mailglass_admin/priv/static/app.css` - Generated bundle for the changed HEEx utilities.
- `mailglass_admin/test/mailglass_admin/components_test.exs` and `inbound_live_test.exs` - Appearance, feedback, timestamp, and stale-copy assertions.
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md` - Rendered review evidence and limits.

## Decisions Made

- Kept the existing native radio controls and persistence path, adding visible labels rather than a second preference source.
- Used alert semantics for errors and status semantics for non-error feedback, with keyboard-accessible dismissal and stable IDs.
- Made a missing timestamp say `Unavailable` and exposed present values as exact UTC timestamps without hover.
- Kept Preview email appearance independent from the operator chrome preference.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed an unverified stale observation time**
- **Found during:** Task 2
- **Issue:** The Inbound stale state rendered a synthetic `Showing InboundMessages as of 14:32` value that implied an observation time the application had not recorded.
- **Fix:** Replaced it with the truthful `This view may be out of date.` notice and explicit refresh guidance.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`, `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`
- **Verification:** Focused inbound LiveView and component suites passed; the test rejects the fabricated time.
- **Committed in:** `e5f77bf3`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Removed misleading status copy directly related to the planned feedback/status surface.

## Issues Encountered

- The demo had no live transient error, missing icon/font asset, or pending event available for direct interaction. Focused tests cover the relevant semantics, dismissal, and long-copy behavior.
- Browser review used the host's Light OS appearance and did not emulate an OS appearance transition or reduced-motion preference. Those limits are recorded in the baseline.
- Test runs emitted existing warnings that Oban was unavailable; the focused tests still passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 03 is complete and the shared appearance and feedback controls have focused tests plus rendered evidence. Plan 04 can use the recorded operator/preview preference boundary and accessible status patterns. The phase as a whole is not complete until the remaining plan is executed and verified.

---
*Phase: 168-shared-workspace-and-usable-baseline*
*Completed: 2026-10-07*

## Self-Check: PASSED

- Summary file exists at the expected plan path.
- Task commits `031aee42` and `e5f77bf3` are ancestors of HEAD.
- The persisted plan ledger measures 2 commits from `840d8bd72ddd1d0061a994208aa426be8300434c` through `e5f77bf3a2c065201180899480f478b77ec2af72`.
