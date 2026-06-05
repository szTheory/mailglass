---
phase: 77-motion-and-microinteraction-polish
plan: 01
subsystem: ui
tags: [liveview, heex, motion, animation, operator_live, inbound_live]

# Dependency graph
requires:
  - phase: 76-component-library-and-design-system-hardening
    provides: token-migrated HEEx templates including operator_live.ex and inbound_live.ex
provides:
  - Record-keyed id attributes on motion-reveal divs in operator and inbound detail panes
  - GAP-19 (sev 3) fixed: entrance animation fires once per delivery/inbound selection
affects:
  - 77-02
  - 77-03
  - 77-04
  - 79-verification-and-visual-regression-hardening

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Record-keyed id on motion-reveal element: id={'delivery-detail-#{record.id}'} causes LiveView replace (not patch) on selection change, firing entrance animation exactly once"
    - "GAP-19 fix is HEEx-attribute-only (D-03 constraint): no CSS changes, no new classes, no new deps"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs

key-decisions:
  - "D-01: operator_live.ex uses @selected_delivery.id (non-nil in true -> branch) for the motion-reveal id"
  - "D-02 (corrected): inbound_live.ex uses @detail.record.id, NOT @selected_record.id — nil-safe in URL-injected edge case per RESEARCH.md Anchor 2"
  - "D-03: GAP-19 fix is HEEx-attribute-only; no CSS keyframes or app.css changes"

patterns-established:
  - "Motion re-fire pattern: add record-keyed id to motion-reveal divs to trigger LiveView element replacement on selection change"

requirements-completed:
  - MOTION-01

# Metrics
duration: 3min
completed: 2026-06-04
---

# Phase 77 Plan 01: Motion-Reveal Re-Fire Fix Summary

**Record-keyed id attributes added to bare motion-reveal divs in operator and inbound detail panes, fixing GAP-19 (sev 3): entrance animations now fire exactly once per delivery/inbound selection via LiveView element replacement**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-06-04T16:09:00Z
- **Completed:** 2026-06-04T16:11:56Z
- **Tasks:** 2
- **Files modified:** 4 (2 implementation, 2 test)

## Accomplishments

- Added `id={"delivery-detail-#{@selected_delivery.id}"}` to `operator_live.ex:442` motion-reveal div
- Added `id={"inbound-detail-#{@detail.record.id}"}` to `inbound_live.ex:341` motion-reveal div
- Used `@detail.record.id` (not `@selected_record.id`) per RESEARCH.md Anchor 2 nil-safety correction
- mix compile --no-optional-deps --warnings-as-errors exits 0; 189 tests, 1 pre-existing voice_test failure only

## Task Commits

Each task was committed atomically (TDD: RED then GREEN):

1. **RED: Failing tests for motion-reveal record-keyed id** - `020aea69` (test)
2. **GREEN: Add record-keyed id to both motion-reveal divs** - `8184da8f` (feat)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - Line 442: added `id={"delivery-detail-#{@selected_delivery.id}"}` attribute to motion-reveal div (+1/-1)
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - Line 341: added `id={"inbound-detail-#{@detail.record.id}"}` attribute to motion-reveal div (+1/-1)
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - Added describe "motion-reveal re-fire fix" with D-01 test
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - Added describe "motion-reveal re-fire fix" with D-02 test

## Decisions Made

- Used `@detail.record.id` instead of `@selected_record.id` in inbound_live.ex per RESEARCH.md Anchor 2: `@detail.record` is the `%InboundRecord{}` struct guaranteed non-nil in the `true ->` branch; `@selected_record` could theoretically be nil on URL-injected inbound_id mismatch, causing a nil.id crash.
- D-03 constraint strictly honoured: no CSS changes, no new Tailwind classes, no new deps.
- Anti-churn contract satisfied: both changes cite GAP-19 (sev 3) from the Phase 74 gap register.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Worktree deps/ and _build/ were not present; resolved by symlinking to the main project's deps and _build directories. Tests ran cleanly from the worktree after symlinking. This is a known worktree execution pattern.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- GAP-19 motion-reveal re-fire fix complete; motion vocabulary foundation ready for Phase 77 Plans 02-04
- No blocking concerns; all phase-level verification criteria met

## Self-Check: PASSED

- `/Users/jon/projects/mailglass/.claude/worktrees/agent-a6ce47919de268541/mailglass_admin/lib/mailglass_admin/operator_live.ex:442` contains `id={"delivery-detail-#{@selected_delivery.id}"}` — CONFIRMED
- `/Users/jon/projects/mailglass/.claude/worktrees/agent-a6ce47919de268541/mailglass_admin/lib/mailglass_admin/inbound_live.ex:341` contains `id={"inbound-detail-#{@detail.record.id}"}` — CONFIRMED
- Commits `020aea69` (RED) and `8184da8f` (GREEN) exist in git log — CONFIRMED
- mix compile --no-optional-deps --warnings-as-errors exits 0 — CONFIRMED
- 189 tests, 1 pre-existing voice_test failure (no regressions) — CONFIRMED

---
*Phase: 77-motion-and-microinteraction-polish*
*Completed: 2026-06-04*
