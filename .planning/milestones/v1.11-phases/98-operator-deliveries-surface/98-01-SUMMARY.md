---
phase: 98-operator-deliveries-surface
plan: 01
subsystem: ui
tags: [operator, deliveries, accessibility, nil-guards, ratchet]

requires:
  - phase: 97-cross-surface-component-layer
    provides: shared operator component token and focus-ring conventions
provides:
  - Operator GAP anchors GAP-06..GAP-09 for downstream Phase 98 anti-churn citations
  - Suppressed status attr allowlist with existing neutral fallback rendering
  - Nil-safe operator support and replay handler reads
  - Novel-shape suppression card fallback rendering
affects: [operator, deliveries, ratchet-gap-register, phase-98]

tech-stack:
  added: []
  patterns:
    - Minimal nil-safe selected_delivery reads via get_in/2 and existing error branches
    - Suppression card novel-shape maps fall back to locked COPY-LD-14 copy

key-files:
  created:
    - .planning/phases/98-operator-deliveries-surface/98-01-SUMMARY.md
  modified:
    - .planning/RATCHET-GAP-REGISTER.md
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs

key-decisions:
  - "CR-03 keeps :suppressed on the attr allowlist only; status_class/status_icon/status_label fallback clauses remain the single phantom-atom behavior."
  - "CR-01 extends the catch-all beyond body_copy/1 to headline/1 and nil-safe field reads so novel-shape suppression maps cannot raise during render."
  - "CR-02 makes the existing :no_selected_delivery branch reachable for confirm_replay without changing replay happy-path flow."

patterns-established:
  - "Operator CR regression coverage lives in a dedicated CR-01/02/03 nil-guards describe block."
  - "Phase 98 downstream build plans cite newly seeded GAP-06..GAP-09 rows at severity >=3."

requirements-completed: [A11Y-01]

duration: 15 min
completed: 2026-06-14
---

# Phase 98 Plan 01: Operator Foundation Hardening Summary

**Operator ratchet anchors and nil-safe delivery handlers for the deliveries surface foundation**

## Performance

- **Duration:** 15 min
- **Started:** 2026-06-14T19:18:26Z
- **Completed:** 2026-06-14T19:33:26Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Seeded GAP-06 through GAP-09 with run_id `2026-06-14-phase-98`, giving the remaining Phase 98 build plans valid sev>=3 anti-churn anchors.
- Added `:suppressed` to the shared `status_badge/1` attr values while preserving the locked neutral fallback behavior.
- Hardened suppression-card and selected-delivery paths against novel-shape maps and nil selected deliveries.
- Added focused CR-01/02/03 regression coverage in `operator_live_test.exs`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Seed four sev>=3 operator GAP rows in the RATCHET register** - `47146978` (docs)
2. **Task 2: CR-03 — add :suppressed to status_badge attr values list** - `9c9f2957` (fix)
3. **Task 3: CR-01 catch-alls, CR-02 nil-safe reads, and unit tests** - `a1d988df` (fix)

**Plan metadata:** pending in this commit.

## Files Created/Modified

- `.planning/RATCHET-GAP-REGISTER.md` - Added GAP-06..GAP-09 without changing GAP-01..GAP-05.
- `mailglass_admin/lib/mailglass_admin/components.ex` - Added `:suppressed` to `status_badge/1` values.
- `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex` - Added fallback headline/body copy and nil-safe map field reads.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - Replaced nil-prone selected_delivery reads and made the no-selected replay branch reachable.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - Added CR regression tests for suppression fallback, status badge fallback, support exemplar, and replay nil paths.

## Decisions Made

- Preserved STATE-LD-05 phantom-atom fallback behavior by not adding any explicit `:suppressed` status class/icon/label clauses.
- Used the existing `{:error, :no_selected_delivery}` branch in `confirm_replay` rather than adding a new replay branch or changing successful replay flow.
- Treated missing suppression-card map fields as `nil` / `"Unknown"` so the locked fallback copy can render for novel-shape suppression maps.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Nil-safe suppression-card field reads**
- **Found during:** Task 3 (CR-01 nil-guard coverage)
- **Issue:** Adding `headline/1` and `body_copy/1` catch-alls was not enough; rendering `%{}` still raised on direct `.scope`, `.reason`, `.stream`, and `.source` access.
- **Fix:** Replaced direct map field reads with `Map.get/2` / `Map.get/3` in the suppression-card details.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex`
- **Verification:** `mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` passed with 26 tests, 0 failures.
- **Committed in:** `a1d988df`

**2. [Rule 2 - Missing Critical] Reachable no-selected replay error branch**
- **Found during:** Task 3 (CR-02 nil-guard coverage)
- **Issue:** `confirm_replay` already had a `{:error, :no_selected_delivery}` branch, but the first `with` pattern could fail with the raw assigns map before reaching it.
- **Fix:** Converted the first `with` clause to use `socket.assigns.selected_delivery || {:error, :no_selected_delivery}`.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`
- **Verification:** `mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` passed with 26 tests, 0 failures.
- **Committed in:** `a1d988df`

---

**Total deviations:** 2 auto-fixed (2 missing critical).
**Impact on plan:** Both fixes were necessary to satisfy the plan's no-raise behavior. No scope expansion beyond CR-01/02 robustness.

## Issues Encountered

- The initial focused test run failed on the novel-shape suppression render and an overly strict patch assertion. Both were corrected before commit.

## User Setup Required

None - no external service configuration required.

## Verification

- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` — 26 tests, 0 failures.
- `cd mailglass_admin && bash scripts/check-conformance.sh` — `OK: design-system conformance clean.`
- `grep -c '^| GAP-0[6789] ' .planning/RATCHET-GAP-REGISTER.md | grep -qx 4 && echo OK` — `OK`.

## Next Phase Readiness

Wave 2 can now cite GAP-06/GAP-07/GAP-08/GAP-09 and safely introduce `:suppressed` / novel-shape operator states without crashing the existing components.

---
*Phase: 98-operator-deliveries-surface*
*Completed: 2026-06-14*
