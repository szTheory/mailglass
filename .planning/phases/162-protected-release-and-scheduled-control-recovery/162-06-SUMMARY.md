---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 06
subsystem: release-automation
tags: [github-actions, release-please, bash, exunit, release-control]
requires:
  - phase: 162-05
    provides: "Captured exact proposal identity and proposal-only release control contract"
provides:
  - "Truthful post-worktree proposal capture outputs for pass and blocked identities"
  - "Executable capture-to-result serialization regression coverage"
affects: [AUTO-03, release-please, protected-release]
tech-stack:
  added: []
  patterns:
    - "A single EXIT handler chains guarded cleanup with result output emission while preserving command status"
    - "Workflow shell capture is tested through extracted executable fixtures and command shims"
key-files:
  created: []
  modified:
    - .github/workflows/release-please.yml
    - test/scripts/release_trigger_recovery_test.exs
key-decisions:
  - "Proposal capture owns one status-preserving EXIT handler so cleanup cannot replace output publication."
  - "Only exact proposal identity equality passes; identity mismatch remains blocked and retains observed fields."
patterns-established:
  - "Exercise workflow shell paths after worktree creation, then pass their actual outputs to downstream result writers."
metrics:
  duration: "8m"
  completed_date: "2026-08-22"
  tasks_completed: 1
  files_modified: 2
status: complete
---

# Phase 162 Plan 06: Proposal Capture Exit Recovery Summary

Proposal-only release capture now publishes its real pass or blocked identity outcome after worktree cleanup, without granting ordinary triggers release authority.

## Tasks Completed

1. **Execute proposal capture through output emission, cleanup, and result serialization** — added an executable full-capture fixture for exact-match and identity-mismatch paths, then chained guarded cleanup and output emission in one EXIT handler.

## Verification

- `mix test test/scripts/release_trigger_recovery_test.exs --seed 0` — passed.
- `mix test test/scripts/phase_162_release_reconciliation_test.exs test/scripts/release_trigger_recovery_test.exs --seed 0` — passed.
- The full fixture proves both paths create and remove a temporary worktree; pass emits `proposal_captured` and `captured=true`, while mismatch emits `proposal_identity_mismatch` without `captured`.
- The fixture feeds emitted fields to the unchanged proposal-control writer and proves its JSON reflects those fields rather than fallback defaults.
- Fixture command logs prove no merge, tag, release, publish, or protected-dispatch operation occurs.

## Decisions Made

- Initialize `candidate_root` before trap registration; a single EXIT handler conditionally removes a created worktree, emits capture outputs, and returns the original capture status.
- Keep all existing triggers, permissions, result writer, protected exact-digest dispatch, and authority guards unchanged.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed `.github/workflows/release-please.yml` and `test/scripts/release_trigger_recovery_test.exs` exist.
- Confirmed task commits `7a6291d5` and `815ec166` exist.
