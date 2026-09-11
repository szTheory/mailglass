---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 25
subsystem: ci-contracts
tags: [exunit, mix-aliases, hermetic-ci, installed-boundary, repository-truth]
requires:
  - phase: 164-24
    provides: installed production-boundary tests and immutable-loader fixture coverage
provides:
  - hermetic required CI alias that excludes only controlled-host installed-boundary tests
  - explicit non-vacuous installed-boundary alias for controlled maintainer hosts
  - drift contracts binding CI workflow usage to exact Mix alias scopes
affects: [verify.ci_lane_contract, phase-164-closeout, SuiteFloor, TRTH-03]
actuals:
  tokens: 3280
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [exact include-exclude alias pairs, controlled-host test authority, source-level CI drift contracts]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-25-SUMMARY.md
  modified:
    - mix.exs
    - test/scripts/phase_164_closeout_test.exs
    - test/scripts/ci_parity_drift_test.exs
    - test/scripts/scheduled_control_evidence_test.exs
    - test/support/suite_floor.ex
    - test/scripts/suite_floor_contract_test.exs
    - config/test_exceptions.exs
key-decisions:
  - "The generic required lane retains test/scripts directory discovery and excludes exactly phase_164_installed_production_boundary; no workflow or required-lane topology changes are needed."
  - "Installed-host assertions remain fail-closed under one explicit preferred-test-environment alias and are never treated as repository-runner evidence."
patterns-established:
  - "Host-specific test authority is isolated by an exact ExUnit describe tag paired with exact required-exclude and controlled-host-only aliases."
  - "CI drift tests verify both alias semantics and the unchanged workflow call site, with negative controls for missing or broadened scopes."
requirements-completed: [TRTH-03]
coverage:
  - id: D1
    description: "The required verify.ci_lane_contract lane runs all repository-tracked test/scripts contracts without reading maintainer-local installed files."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix verify.ci_lane_contract: 372 tests, 0 failures, 5 controlled-host exclusions"
        status: pass
    human_judgment: false
  - id: D2
    description: "The installed production boundary remains explicitly runnable and non-vacuous on a controlled host."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix verify.phase_164.installed_boundary: 5 tests, 0 failures, 36 excluded"
        status: pass
    human_judgment: false
  - id: D3
    description: "CI and source drift contracts fail if the exact alias pair disappears, broadens, or moves fixture-backed loader proof behind the host-only tag."
    requirement: TRTH-03
    verification:
      - kind: unit
        ref: "focused CI/scheduled/SuiteFloor/exception contracts: 54 tests, 0 failures"
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-09-10
status: complete
---

# Phase 164 Plan 25: Hermetic Required CI Boundary Summary

**Required CI now exercises the complete repository-source contract suite while five fail-closed installed-command tests remain isolated behind one explicit controlled-host alias.**

## Performance

- **Duration:** 13 minutes
- **Started:** 2026-09-10T23:44:09Z
- **Completed:** 2026-09-10T23:57:08Z
- **Tasks:** 2
- **Files modified:** 7 implementation/contract files

## Accomplishments

- Preserved `test/scripts/` auto-discovery while excluding exactly `phase_164_installed_production_boundary` from the protected required alias.
- Added `mix verify.phase_164.installed_boundary` with a preferred test environment and an exact five-test host-only selection.
- Added alias/workflow/source negative controls proving the required job cannot invoke host proof, the pair cannot become empty or broad, and immutable-loader fixtures remain required coverage.
- Passed the complete repository-only lane with 372 tests and zero failures, plus the separate installed boundary with five tests and zero failures.

## Task Commits

1. **Task 1 RED: Add failing alias authority contract** — `fddae100`
2. **Task 1 GREEN: Isolate installed boundary from required CI** — `8f68142a`
3. **Task 2: Lock hermetic required CI scope** — `b3fc0516`

## Files Created/Modified

- `mix.exs` — exact required exclusion, explicit installed-boundary alias, and preferred test environment.
- `test/scripts/phase_164_closeout_test.exs` — non-vacuous alias-authority contract without weakening installed-host assertions.
- `test/scripts/ci_parity_drift_test.exs` — exact alias pair, unchanged workflow call, fixture placement, and negative controls.
- `test/scripts/scheduled_control_evidence_test.exs` — parsed Mix alias assertions and proof that protected CI never invokes the host alias.
- `test/support/suite_floor.ex` and `test/scripts/suite_floor_contract_test.exs` — fail-closed recognition of the deliberate host-only exclusion.
- `config/test_exceptions.exs` — corrected stale line identity for the existing historical docs skip.

## Decisions Made

- The fixed CI topology remains unchanged: the existing required job continues to call only `mix verify.ci_lane_contract`.
- Fixture-backed immutable-loader and repository finalizer tests remain outside the controlled-host tag; installed-command tests are neither skipped nor converted to conditional success.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Issue] Registered the new deliberate exclusion with SuiteFloor**
- **Found during:** Task 1 tracer verification and Task 2 complete required-lane run
- **Issue:** SuiteFloor correctly rejected the new exclusion as an unknown tag, and its source contract still pinned the prior two-source vocabulary and old alias text.
- **Fix:** Added only `phase_164_installed_production_boundary` to the known exclusion set and updated the bidirectional source contract while keeping expected per-schema exclusions unchanged.
- **Files modified:** `test/support/suite_floor.ex`, `test/scripts/suite_floor_contract_test.exs`
- **Verification:** Required closeout run passed 36/36; focused drift set passed 54/54; complete required lane passed 372/372.
- **Committed in:** `8f68142a`, `b3fc0516`

**2. [Rule 3 - Blocking Issue] Corrected a stale historical-skip registry line**
- **Found during:** Task 2 complete required-lane run
- **Issue:** The pre-existing registry named line 482 while the unchanged historical `@tag :skip` now resides at line 516, making the required registry contract fail.
- **Fix:** Updated the exact source-line identity without changing or adding any skip.
- **Files modified:** `config/test_exceptions.exs`
- **Verification:** `test_exceptions_contract_test.exs` passed in the 54-test focused gate and the 372-test required lane.
- **Committed in:** `b3fc0516`

---

**Total deviations:** 2 auto-fixed blocking contract issues.
**Impact on plan:** Both fixes preserve fail-closed anti-vacuity behavior; no CI topology, product behavior, dependencies, or release authority changed.

## TDD Evidence

- Task 1 RED failed on the original directory-only alias, then GREEN passed 36 repository-source tests and the separate five-test installed boundary.
- Task 2 RED exposed the stale alias source assertion; the final test-only contract commit passed focused and complete required scopes.
- No refactor-only commit was needed.

## Known Stubs

None.

## Issues Encountered

The complete required lane initially found its own expected SuiteFloor contract drift and an unrelated stale exception-registry line identity. Both were repaired narrowly and the entire lane then passed.

## User Setup Required

None. The approved installed command and approval record remain unchanged and are required only for the explicit controlled-host alias.

## Next Phase Readiness

- Plan 164-26 can proceed with protected CI no longer coupled to `/Users/jon` installation state.
- Canonical repository identity, trusted executable lookup, protected-main integration, and terminal finalization remain owned by later gap-closure plans.

## Self-Check: PASSED

- All seven implementation/contract files exist and task commits `fddae100`, `8f68142a`, and `b3fc0516` are present in Git history.
- Task 1 repository-source gate passed 36 tests with five host-only exclusions; the controlled-host alias passed all five selected tests.
- Task 2 focused contracts passed 54 tests and the complete required alias passed 372 tests with zero failures.
- `git diff --check` and focused formatting checks passed; no goal-blocking stubs or unrun verification commands remain.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-10*
