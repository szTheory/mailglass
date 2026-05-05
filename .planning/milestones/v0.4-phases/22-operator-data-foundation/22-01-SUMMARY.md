---
phase: 22-operator-data-foundation
plan: "01"
subsystem: api
tags: [operator, ecto, postgres, deliveries, timeline, suppressions]
requires: []
provides:
  - tenant-scoped recent delivery query seam in core mailglass
  - append-only event timeline query seam for operator delivery detail
  - read-only suppression projection with reversibility metadata for operator UI
affects: [mailglass_admin, phase-23-production-admin-mount, operator-ui]
tech-stack:
  added: []
  patterns: [core operator read models, tenant-scoped Ecto queries, read-only suppression projection]
key-files:
  created:
    - lib/mailglass/operator/deliveries.ex
    - lib/mailglass/operator/timeline.ex
    - lib/mailglass/operator/suppressions.ex
    - test/mailglass/operator/deliveries_test.exs
    - test/mailglass/operator/timeline_test.exs
    - test/mailglass/operator/suppressions_test.exs
  modified:
    - test/support/generators.ex
key-decisions:
  - "Operator queries require explicit tenant_id inputs and bounded default limits to prevent cross-tenant leakage and unbounded scans."
  - "Suppression visibility is projected as read-only reversibility metadata and copy, not as mutation affordances."
patterns-established:
  - "Pattern 1: keep operator-facing Ecto reads in lib/mailglass/operator/* so LiveViews consume shaped data instead of ad hoc queries."
  - "Pattern 2: derive suppression reversibility once in core mailglass and render the resulting enum/copy in later admin UI phases."
requirements-completed: [ADMIN-02, ADMIN-03, ADMIN-04]
duration: 4min
completed: 2026-05-01
---

# Phase 22 Plan 01: Operator Data Foundation Summary

**Tenant-scoped operator read models for recent deliveries, append-only event timelines, and suppression reversibility state**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-01T01:59:00Z
- **Completed:** 2026-05-01T02:03:37Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Added `Mailglass.Operator.Deliveries.list_recent_deliveries/2` with compact tenant-aware filters, recency ordering, and bounded limits.
- Added `Mailglass.Operator.Timeline.list_delivery_events/2` backed directly by `Mailglass.Events.Event` with explicit chronological ordering.
- Added `Mailglass.Operator.Suppressions.get_delivery_suppression_state/2` with read-only reversibility modeling for later operator UI copy.

## Task Commits

1. **Task 1 RED: Add recent-deliveries and timeline query tests** - `f1e0600` (`test`)
2. **Task 1 GREEN: Add recent-deliveries and timeline query modules** - `549cd2b` (`feat`)
3. **Task 2 RED: Add suppression projection tests** - `1231e16` (`test`)
4. **Task 2 GREEN: Add suppression projection seam** - `56b56b5` (`feat`)

## Files Created/Modified
- `lib/mailglass/operator/deliveries.ex` - recent delivery query seam with tenant, provider, status, event, limit, and window filtering.
- `lib/mailglass/operator/timeline.ex` - tenant-scoped event timeline query over the append-only ledger.
- `lib/mailglass/operator/suppressions.ex` - suppression visibility projection with immutable versus reversible operator state.
- `test/mailglass/operator/deliveries_test.exs` - recent-delivery tenant, filter, and recency coverage.
- `test/mailglass/operator/timeline_test.exs` - delivery timeline tenant and chronology coverage.
- `test/mailglass/operator/suppressions_test.exs` - suppression visibility, immutability, and read-only behavior coverage.
- `test/support/generators.ex` - fixture support for provider and status fields used by operator tests.

## Decisions Made
- Required explicit `tenant_id` in each operator seam instead of falling back to ambient tenancy so query callers stay honest at the trust boundary.
- Defaulted operator reads to bounded limits and recent windows so later URL-backed admin filters stay compact and safe.
- Modeled suppression reversibility centrally in core mailglass and included operator copy strings to keep later UI templates policy-thin.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed nil atom filters building invalid Ecto comparisons**
- **Found during:** Task 1 GREEN (Add recent-deliveries and timeline query modules)
- **Issue:** `nil` satisfied `is_atom/1`, causing `delivery.status == nil` and `delivery.last_event_type == nil` query errors.
- **Fix:** Tightened filter guards to reject `nil` before building status or event predicates.
- **Files modified:** `lib/mailglass/operator/deliveries.ex`
- **Verification:** `mix test test/mailglass/operator/deliveries_test.exs test/mailglass/operator/timeline_test.exs --warnings-as-errors`
- **Committed in:** `549cd2b`

**2. [Rule 3 - Blocking] Extended delivery fixtures for operator filter coverage**
- **Found during:** Task 1 GREEN (Add recent-deliveries and timeline query modules)
- **Issue:** `Generators.delivery_fixture/1` ignored `provider` and `status`, and later passed `status: nil`, preventing the new operator tests from seeding valid filter fixtures.
- **Fix:** Added `provider` support and defaulted `status` to `:queued` while still allowing explicit overrides.
- **Files modified:** `test/support/generators.ex`
- **Verification:** `mix test test/mailglass/operator/deliveries_test.exs test/mailglass/operator/timeline_test.exs --warnings-as-errors`
- **Committed in:** `549cd2b`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both fixes were required for correctness and testability. No scope creep.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Phase 23 can consume stable core query/projection seams instead of embedding Ecto logic inside admin LiveViews.
- Recent delivery filters, timeline ordering, and suppression reversibility policy are now covered by focused backend tests.

## Self-Check

PASSED

- Verified summary and all operator module/test files exist on disk.
- Verified task commits `f1e0600`, `549cd2b`, `1231e16`, and `56b56b5` exist in git history.

---
*Phase: 22-operator-data-foundation*
*Completed: 2026-05-01*
