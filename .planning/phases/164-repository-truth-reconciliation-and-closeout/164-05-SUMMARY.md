---
phase: 164-repository-truth-reconciliation-and-closeout
plan: "05"
subsystem: repository-closeout
tags: [bash, json, git, ci, scheduled-controls, evidence]
requires:
  - phase: 164-04
    provides: complete exact-one disposition ledger
provides:
  - fail-closed exact-main repository closeout report
  - fixture-backed contract for volatile evidence composition
  - stable post-merge maintainer usage contract
affects: [repository-closeout, MAINTAINING.md]
tech-stack:
  added: []
  patterns: [atomic volatile JSON reports, identity-bound evidence composition, fail-closed status precedence]
key-files:
  created:
    - scripts/closeout_repository_truth.sh
    - test/scripts/phase_164_closeout_test.exs
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-CLOSEOUT.md
  modified: []
key-decisions:
  - Closeout remains read-only and writes volatile report evidence under the existing ignored tmp/ rule.
  - A quiet verdict requires exact main, exact successful CI, current provenance-valid controls, and a valid exact-one ledger.
metrics:
  duration: 9m
  completed_date: 2026-08-26
  tasks_completed: 2
  files_changed: 3
status: complete
---

# Phase 164 Plan 05: Repository Truth Closeout Summary

A rerunnable closeout command now composes exact-main Git state, repository hygiene, preservation proof, the disposition ledger, exact CI, and scheduled-control provenance into one atomic, fail-closed volatile JSON report.

## Completed Work

1. Added `scripts/closeout_repository_truth.sh` and a disposable-repository ExUnit contract.
   - Requires `--repo`, `--ledger`, a positive `--ci-run-id`, and `--output`.
   - Writes component source/result files and an aggregate report atomically, including on non-pass outcomes.
   - Rejects malformed, unavailable, pending, stale, mismatched, or incomplete evidence and has no dispatch, merge, publish, or authorization operation.
2. Added `164-CLOSEOUT.md` with the exact protected-merge invocation and the durable-ledger versus volatile-report boundary.

## Verification

- RED: `mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check` failed before the closeout command existed.
- GREEN: the focused contract passed with 4 tests and 0 failures.
- `bash -n scripts/closeout_repository_truth.sh` passed.
- `mix ci.fast` passed (Credo reported no issues).
- Documentation acceptance grep confirmed all four CLI flags, the required output path, D-10 through D-12, non-pass precedence, and volatile/untracked handling.

## TDD Gate Compliance

- RED: `96f6f1a1` added the failing disposable-fixture closeout contract.
- GREEN: `a24f1613` implemented the fail-closed wrapper and completed the contract.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected the fixture scheduled-control stub to write to the actual `--output` argument and execute from the fixture repository.
   - **Found during:** Task 1 GREEN verification.
   - **Fix:** Bound the wrapper and stub to the supplied repository so dynamic SHA fixtures could not accidentally read the main working tree.
   - **Files modified:** `scripts/closeout_repository_truth.sh`, `test/scripts/phase_164_closeout_test.exs`.
   - **Verification:** focused fixture contract passed.
   - **Commit:** `a24f1613`.

**Total deviations:** 1 auto-fixed. **Impact:** Ensures the exact-repository identity guarantee is real rather than test-environment-dependent.

## Known Stubs

None.

## Self-Check: PASSED

- The wrapper, focused test, and durable usage contract exist at their recorded paths.
- Task commits `96f6f1a1`, `a24f1613`, and `2084725c` exist in Git history.
