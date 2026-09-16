---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 09
subsystem: repository-closeout
tags: [closeout, repository-truth, path-validation, ledger]
dependency_graph:
  requires: [164-08]
  provides: [canonical-closeout-boundary, authoritative-ledger-validation]
  affects: [TRTH-02, TRTH-03]
tech_stack:
  added: []
  patterns: [physical-path-identity, ignored-output-gate, post-write-porcelain-check]
key_files:
  created: []
  modified:
    - scripts/closeout_repository_truth.sh
    - test/scripts/phase_164_closeout_test.exs
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-CLOSEOUT.md
decisions:
  - Closeout accepts only the physical canonical repository, Phase 164 ledger, and ignored tmp output boundary.
  - The shared full-ledger validator, rather than a local partial parser, decides ledger validity.
metrics:
  duration: 5m
  completed_date: 2026-08-27
  tasks_completed: 2
  files_modified: 3
status: complete
---

# Phase 164 Plan 09: Canonical Closeout Boundary Summary

The closeout CLI now binds its volatile report to the canonical checkout, authoritative Phase 164 ledger, and ignored `tmp/` output boundary, with post-write cleanliness enforcement.

## Completed Tasks

1. **Reject noncanonical repository, ledger, and output paths** — `38e7076f`
   - Resolves repository and ledger identity physically and rejects every noncanonical alternative before evidence collection.
   - Invokes the shared validator for the exact authoritative ledger and replaces the partial AWK parser.
   - Requires ignored output/component paths beneath canonical `tmp/`, then samples stable porcelain after component and report writes.
   - Replaced disposable positive-fixture coverage with negative integration contracts.

2. **Correct the durable closeout contract** — `380b5a95`
   - Documents exact enforced repository, ledger, and output paths.
   - Records full validator semantics, existing root ignore requirement, and post-write porcelain check without a time-bound pass snapshot.

## Verification

Passed:

```text
mix test test/scripts/phase_164_repository_truth_test.exs test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check
bash -n scripts/closeout_repository_truth.sh
```

Result: 10 tests, 0 failures; shell syntax passed.

## Decisions Made

- Canonical path identity is a hard closeout precondition, not a caller-selectable fixture setting.
- Only the authoritative ledger can enter the closeout validator; semantic validation remains centralized in `validate_repository_truth.exs`.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- `scripts/closeout_repository_truth.sh`, `test/scripts/phase_164_closeout_test.exs`, and `164-CLOSEOUT.md` exist.
- Commits `38e7076f` and `380b5a95` exist in Git history.
