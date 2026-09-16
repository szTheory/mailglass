---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 08
subsystem: repository-truth
tags: [elixir, validation, evidence-ledger, closeout]
dependency_graph:
  requires: [164-07]
  provides: [shared-ledger-validator, audited-subject-inventory]
  affects: [closeout-repository-truth]
tech_stack:
  added: []
  patterns: [pure-tsv-parser, repository-derived-set-validation, fail-closed-cli]
key_files:
  created: [scripts/validate_repository_truth.exs]
  modified: [test/scripts/phase_164_repository_truth_test.exs, .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv]
decisions:
  - Exact currentness is an enum; stale context belongs in rationale rather than the enum field.
  - The authoritative audit inventory is derived from committed ignore rules, tracked proof, Phase 164 plans, and verification evidence.
metrics:
  duration: 4m
  completed: 2026-08-27
status: complete
---

# Phase 164 Plan 08: Shared Repository Truth Validator Summary

One shared, fail-closed Elixir validator now defines the complete repository-truth ledger contract used by the focused test and closeout seam.

## Completed Tasks

1. Extracted `Mailglass.RepositoryTruthLedger` with pure TSV parsing, exact enums, stale-outcome validation, duplicate detection, repository-derived audit inventory, and CLI failure categories.
2. Reconciled the authoritative ledger with exact `stale` currentness and current tracked evidence for the closeout artifacts, validator, and verification report.

## Verification

- `mix run scripts/validate_repository_truth.exs -- --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv`
- `mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check`
- `mix format --check-formatted scripts/validate_repository_truth.exs test/scripts/phase_164_repository_truth_test.exs`
- `git diff --check`

## Commits

- `2f7f2c14` — test(164-08): add failing shared ledger validator contract
- `b96df559` — feat(164-08): extract repository truth ledger validator
- `d5ce88f9` — fix(164-08): reconcile authoritative truth ledger

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Accepted the `mix run ... -- --repo` argument boundary in the production CLI.
- **Found during:** Task 2 verification
- **Fix:** Strip the leading argument separator before strict option parsing.
- **Files modified:** `scripts/validate_repository_truth.exs`
- **Commit:** `d5ce88f9`

## Known Stubs

None.

## Self-Check: PASSED

- Shared validator, focused test, and authoritative ledger exist.
- All three task commits are present in Git history.
