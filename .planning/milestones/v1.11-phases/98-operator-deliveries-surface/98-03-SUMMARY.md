---
phase: 98-operator-deliveries-surface
plan: 03
subsystem: ui
tags: [operator, tokens, typography, copy, conformance]

requires:
  - phase: 98-operator-deliveries-surface
    provides: GAP-07 tracking-cleanup anchor and CR suppression fallback foundation
provides:
  - Tracking-clean operator in-pane components
  - COPY-LD-14 suppression-card copy
  - Operator-scoped arbitrary tracking regression assertion
affects: [operator, deliveries, phase-99-gate-flip]

tech-stack:
  added: []
  patterns:
    - Operator-scoped source grep assertion protects advisory TRACK-GATE cleanup before the global gate flips
    - In-pane labels use text-label uppercase font-bold without arbitrary tracking

key-files:
  created:
    - .planning/phases/98-operator-deliveries-surface/98-03-SUMMARY.md
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
    - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs

key-decisions:
  - "Phase 98 removes operator-surface tracking utilities without flipping check-conformance-advisory.sh; Phase 99 still owns the global advisory gate contract."
  - "SupportCards and ReplayModal dt labels preserve their prior color by using text-label uppercase font-bold without text-secondary."
  - "SuppressionCard copy now follows COPY-LD-14 for heading, absent state, immutable body, reversible body, and fallback body."

patterns-established:
  - "Operator source-level token assertions strip comment lines before scanning for arbitrary tracking utilities."

requirements-completed: [GROUP-01, A11Y-02]

duration: 7 min
completed: 2026-06-14
---

# Phase 98 Plan 03: Operator Tracking Cleanup Summary

**Operator in-pane components are tracking-clean with locked Suppression copy and a scoped regression test**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-14T21:00:39Z
- **Completed:** 2026-06-14T21:07:39Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Removed all remaining `tracking-[0.08em]` utilities from `suppression_card.ex`, `support_cards.ex`, and `replay_modal.ex`.
- Updated `SuppressionCard` to the COPY-LD-14 heading and body copy.
- Added an operator-scoped ExUnit assertion that scans operator source files for arbitrary tracking utilities while leaving the global advisory script untouched.

## Task Commits

The cleanup and regression assertion were committed together:

1. **Tasks 1-3: Suppression copy, in-pane tracking cleanup, and scoped assertion** - `3472feb4` (fix)

**Plan metadata:** pending in this commit.

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex` - Label token cleanup and COPY-LD-14 copy.
- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex` - Removed arbitrary tracking from drilldown dt labels.
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` - Removed arbitrary tracking from replay target dt labels while preserving `shadow-overlay`.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - Updated suppression copy expectations and added the operator tracking-clean source assertion.

## Decisions Made

- Left `mailglass_admin/scripts/check-conformance-advisory.sh` unchanged because the plan explicitly defers the global advisory gate flip to Phase 99.
- Preserved `shadow-overlay` in `ReplayModal` as the modal-tier exception from STATE-LD-17.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope drift.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- Suppression-card COPY-LD-14 grep guard — `OK`.
- SupportCards/ReplayModal tracking grep guard — `OK`.
- `git diff --quiet mailglass_admin/scripts/check-conformance-advisory.sh && echo OK` — `OK`.
- `cd mailglass_admin && bash scripts/check-conformance.sh` — `OK: design-system conformance clean.`
- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` — 29 tests, 0 failures.

## Next Phase Readiness

Wave 3 can extend seeded operator state coverage knowing the operator render surface is tracking-clean and `:suppressed` / novel-shape suppression states are no-raise paths.

---
*Phase: 98-operator-deliveries-surface*
*Completed: 2026-06-14*
