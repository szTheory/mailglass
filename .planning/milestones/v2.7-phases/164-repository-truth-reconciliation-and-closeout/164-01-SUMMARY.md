---
phase: 164-repository-truth-reconciliation-and-closeout
plan: "01"
subsystem: repository-evidence
tags: [tsv, exunit, repository-hygiene, scheduled-controls]
requires:
  - phase: 162-protected-release-and-scheduled-control-recovery
    provides: durable current-main scheduled-control proof
provides:
  - machine-checkable D-08 disposition for the stale root sweep
  - focused ExUnit contract for ledger validation and narrow cleanup
affects: [164-04, repository-closeout]
tech-stack:
  added: []
  patterns: [tracked TSV disposition ledger, locked-digest cleanup gate]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv
    - test/scripts/phase_164_repository_truth_test.exs
  modified: []
  deleted:
    - scheduled-control-sweep.json
key-decisions:
  - "D-08 removes only the verified stale root sweep and retains Phase 162 proof as the durable source."
  - "Disposition rows require a complete twelve-column schema, unique subjects, and a closed disposition enum."
patterns-established:
  - "Use a SHA-256 equality gate before deleting an untracked generated artifact."
metrics:
  duration: 4m
  completed_date: 2026-08-26
  tasks_completed: 1
  files_changed: 3
status: complete
---

# Phase 164 Plan 01: Locked stale-sweep tracer Summary

The root scheduled-control sweep is now removed only through its D-08 SHA-256-locked TSV disposition, while durable Phase 162 proof remains tracked and discoverable.

## Completed Work

- Added the twelve-field `164-TRUTH-DISPOSITION.tsv` contract with its complete, singular D-08 `remove` row.
- Added `Mailglass.Scripts.Phase164RepositoryTruthTest` covering schema, malformed rows, exact stale-sweep identity, root absence, and all six scoped ignore files.
- Verified SHA-256 `331810b4b1724452f0e2707c800230e52fabea01c3773d362b3a1240040ece7e` before deleting only `scheduled-control-sweep.json`.

## Verification

- RED: `mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check` failed because the ledger was absent and the root output remained.
- GREEN: the focused command passed with 4 tests and 0 failures.
- `mix ci.fast` passed after formatting the new test.
- The exact header, singular locked D-08 row, root absence, and no diff across the six scoped ignore files all passed.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Formatted the new ExUnit contract after `mix ci.fast` reported it as unformatted.
   - **Found during:** Task 1 verification
   - **Fix:** Ran `mix format` on the scoped test and reran focused and fast CI verification.
   - **Files modified:** `test/scripts/phase_164_repository_truth_test.exs`
   - **Commit:** 9b27db03

## Known Stubs

None.

## Self-Check: PASSED

- The D-08 ledger and repository-truth test exist.
- The root sweep is absent.
- RED, GREEN, and formatting commits `e9b3e504`, `507b7a16`, and `9b27db03` exist in Git history.
