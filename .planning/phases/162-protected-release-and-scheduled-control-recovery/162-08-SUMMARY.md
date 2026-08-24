---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 08
subsystem: release automation
tags: [github-actions, release-please, scheduled-control, regression-test]
requires:
  - phase: 162-06
    provides: proposal capture outputs and proposal-control artifact seam
  - phase: 162-07
    provides: protected post-publish control recovery
provides:
  - Exact scheduled open-proposal discovery before capture
  - Bounded pending evidence for an idle release schedule
  - Executable zero/one/multiple/unavailable discovery regression coverage
affects: [release-please, protected-release, scheduled-control, AUTO-03]
tech-stack:
  added: []
  patterns:
    - Exact argument-sensitive GitHub CLI fixture for workflow shell extraction
    - Pending success allowed only for a serialized idle schedule reason
key-files:
  created: []
  modified:
    - .github/workflows/release-please.yml
    - test/scripts/release_trigger_recovery_test.exs
key-decisions:
  - "Only an exact zero-row scheduled proposal query may skip capture as pending/no_open_proposal."
  - "The final proposal-control gate accepts pending only when its reason is no_open_proposal."
patterns-established:
  - "Scheduled absence is evidence-backed: query exact proposal identity before treating no work as a no-op."
requirements-completed: [AUTO-03]
status: complete
---

# Phase 162 Plan 08: Scheduled Idle Proposal Recovery Summary

**An empty-digest hourly release schedule now records and uploads truthful `pending` / `no_open_proposal` evidence without gaining protected release authority.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-08-24T14:33:00-04:00
- **Completed:** 2026-08-24T14:48:00-04:00
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Added exact `gh pr list` discovery after proposal-only release/sibling synchronization and before capture.
- Kept active and ambiguous proposal paths in existing capture, while unavailable discovery remains cannot-check.
- Serialized discovery status/reason into the existing JSON, summary, and upload path before the final gate.
- Added executable workflow-shell fixtures for zero, one, multiple, and unavailable discovery outcomes, with authority-operation logging.

## Verification

- `mix test test/scripts/release_trigger_recovery_test.exs:398 --seed 0` — PASS
- `mix test test/scripts/release_trigger_recovery_test.exs:491 --seed 0` — PASS
- `mix test test/scripts/phase_162_release_reconciliation_test.exs test/scripts/release_trigger_recovery_test.exs --seed 0` — PASS (25 tests, 0 failures)

## TDD Gate Compliance

- RED: `753805fb` added the failing idle-schedule behavioral regression.
- GREEN: `cb5020c7` implemented the narrow discovery, writer, and final-gate control flow.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- Both modified workflow and fixture files exist.
- RED and GREEN commits exist in Git history.
- Focused and combined required verification commands passed.
