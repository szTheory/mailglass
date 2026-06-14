---
phase: 98-operator-deliveries-surface
plan: 02
subsystem: ui
tags: [operator, deliveries, responsive, empty-states, liveview]

requires:
  - phase: 98-operator-deliveries-surface
    provides: GAP-06/GAP-07/GAP-08 anti-churn anchors and nil-safe operator foundation
provides:
  - IA-LD-03 responsive master-detail grid for operator deliveries
  - Mobile filter disclosure using Phoenix.LiveView.JS.toggle
  - Mobile detail reveal with back affordance
  - COPY-LD-01/COPY-LD-02 deliveries empty-state split
affects: [operator, deliveries, phase-99-patterns]

tech-stack:
  added: []
  patterns:
    - Stateless LiveView.JS toggle for mobile filters
    - filters_active? signal excludes tenant scope and window from content-filter comparison

key-files:
  created:
    - .planning/phases/98-operator-deliveries-surface/98-02-SUMMARY.md
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs

key-decisions:
  - "The literal 1440 tier uses min-[1440px]:grid-cols-[33%_67%], which passes the existing conformance gate."
  - "The mobile filter disclosure uses JS.toggle and does not add socket assigns or server-side toggle events."
  - "filters_active?/1 treats tenant_id as scope and window_hours as time range, not content filters, so tenant-present empty history renders the true empty state."

patterns-established:
  - "Operator list empty-state reset actions use data-testid=\"operator-empty-filtered\" to distinguish them from the always-present filter-form clear button."
  - "390px selected-detail mode hides the master list with max-md:hidden and clears delivery_id through build_path/4."

requirements-completed: [GROUP-01, PAGE-01, PAGE-02, RESP-01, A11Y-01, A11Y-02]

duration: 8 min
completed: 2026-06-14
---

# Phase 98 Plan 02: Operator Deliveries IA Summary

**Responsive operator master-detail IA with mobile filters and distinct delivery empty states**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-14T19:29:33Z
- **Completed:** 2026-06-14T19:37:33Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Replaced the non-conformant `lg:minmax` master-detail grid with the locked 768px and 1440px percentage splits.
- Added a 390px selected-detail mode with `operator-detail-back` clearing `delivery_id` through `build_path/4`.
- Added a 390px filter disclosure controlled by `JS.toggle(to: "#operator-filter-panel")`, with filters always visible at `md+`.
- Split the deliveries empty branch into filtered-empty and truly-empty variants with COPY-LD-01/COPY-LD-02 copy.
- Removed the remaining `tracking-[...]` occurrence from `operator_live.ex`.

## Task Commits

The implementation was committed as one coupled render-tree change:

1. **Tasks 1-3: Responsive IA, filter disclosure, and filters_active? empty states** - `351f3247` (feat)

**Plan metadata:** pending in this commit.

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - Grid, mobile filters, mobile back link, orientation-strip placement, filters_active? helper.
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` - `filters_active?` attr and COPY-LD-01/COPY-LD-02 empty-state branches.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - Updated empty-state expectation and added component tests for filtered/truly empty list states.

## Decisions Made

- Used `min-[1440px]:grid-cols-[33%_67%]` for literal 1440px fidelity per the plan resolution.
- Used text caret `v` for the filter toggle to avoid adding a heroicon to the vendored plugin.
- Excluded `tenant_id` as well as `window_hours` in `filters_active?/1`; tenant is a scope, not a content filter, so an empty tenant history should render COPY-LD-02 rather than COPY-LD-01.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Excluded tenant scope from filters_active?/1**
- **Found during:** Task 3 (COPY-LD-01/COPY-LD-02 signal)
- **Issue:** The plan text excluded only `window_hours`, which would make every tenant-scoped no-history page look filtered because `tenant_id` differs from the empty default.
- **Fix:** Dropped both `tenant_id` and `window_hours` before comparing filter params.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`
- **Verification:** `mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` passed with 28 tests, 0 failures.
- **Committed in:** `351f3247`

---

**Total deviations:** 1 auto-fixed (1 missing critical).
**Impact on plan:** The deviation preserves the UI-SPEC distinction between tenant-scoped truly-empty history and actively filtered-empty results.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- Grid/filter/list grep checks — all returned `OK`.
- `cd mailglass_admin && bash scripts/check-conformance.sh` — `OK: design-system conformance clean.`
- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` — 28 tests, 0 failures.

## Next Phase Readiness

98-03 can now complete the remaining in-pane tracking cleanup and add an operator-scoped regression assertion across the full operator source set.

---
*Phase: 98-operator-deliveries-surface*
*Completed: 2026-06-14*
