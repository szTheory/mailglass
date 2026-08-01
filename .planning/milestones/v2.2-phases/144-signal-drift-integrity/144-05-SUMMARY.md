---
phase: 144-signal-drift-integrity
plan: 05
subsystem: release-integrity
tags: [github-actions, release-please, exunit, documentation, hermetic-contract]
requires:
  - phase: 144-signal-drift-integrity
    provides: CI lane contract collection and linked-release idempotency precedent
provides:
  - Bounded, anti-vacuous release-please recovery state-machine contract
  - Maintainer runbook for the accepted hourly recovery and safe fallbacks
affects: [release-please, release-recovery, contributing-guide, ci-lane-contract]
tech-stack:
  added: []
  patterns: [bounded workflow parsing, in-memory negative controls, bounded runbook contract]
key-files:
  created: [test/scripts/release_trigger_recovery_test.exs]
  modified: [CONTRIBUTING.md]
key-decisions:
  - "Keep the existing minute-17 hourly recovery topology and prove it rather than adding a workflow or trigger."
  - "Document workflow_dispatch as the direct recovery path and manually creating missing GitHub releases as the last-resort canonical release: published fan-out."
patterns-established:
  - "Recovery source contracts parse nonempty trigger, step, and action blocks before checking semantics, then exercise in-memory removals."
requirements-completed: [TRUTH-04]
coverage:
  - id: D1
    description: "Release-please preserves push, manual, and minute-17 hourly recovery with convergent preflight state handling."
    requirement: TRUTH-04
    verification:
      - kind: integration
        ref: "mix test test/scripts/release_trigger_recovery_test.exs --warnings-as-errors"
        status: pass
      - kind: integration
        ref: "mix verify.ci_lane_contract"
        status: pass
    human_judgment: false
metrics:
  duration: 4min
  completed: 2026-07-31
  status: complete
---

# Phase 144 Plan 05: Hourly Release-Trigger Recovery Summary

**The existing minute-17 recovery path is now mechanically pinned and documented with its bounded delay, idempotent branches, and safe manual fallbacks.**

## Performance

- **Duration:** 4 min
- **Completed:** 2026-07-31T21:08:41Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added a hermetic workflow contract that parses bounded nonempty trigger, preflight, and release-action blocks before asserting their recovery semantics.
- Proved manifest-derived expected tags, full-tag no-op, partial linked-tag failure, `autorelease: tagged` no-op, pending-release execution, and the shared `should_run` action guard.
- Rewrote the existing contributor recovery section to state the minute-17 hourly cadence, up-to-one-hour bound, observed roughly-30-minute cost, direct dispatch, and last-resort GitHub-release fan-out.

## Task Commits

1. **Task 1: Encode the existing recovery state machine as an anti-vacuous contract** — `8cf0877d` (`test`), `3c0b37c4` (`feat`), `2ccf3425` (`refactor`)
2. **Task 2: Document the bounded hourly self-heal and safe fallbacks where maintainers look** — `e8e9d954` (`test`), `66278621` (`docs`), `3be88577` (`refactor`)

## Verification

- `mix test test/scripts/release_trigger_recovery_test.exs --warnings-as-errors` — 4 tests, 0 failures.
- `mix verify.ci_lane_contract` — 133 tests, 0 failures.

## TDD Gate Compliance

- Task 1 and Task 2 each recorded RED, GREEN, and GREEN-only refactor commits; the final focused contract passes all four recovery/runbook assertions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Scoped the full-tag and tagged-label no-op assertions to their own preflight branches**
- **Found during:** Task 1
- **Issue:** A whole-preflight assertion could satisfy the full-tag check with the tagged-label `should_run=false` output.
- **Fix:** Added bounded shell-branch extraction so removal of the full-tag output cannot be masked by another no-op branch.
- **Files modified:** `test/scripts/release_trigger_recovery_test.exs`
- **Committed in:** `3c0b37c4`

## Issues Encountered

None after the focused contract's branch-bounding correction.

## User Setup Required

None — all evidence is local, hermetic, and does not dispatch a workflow or create a release.

## Next Phase Readiness

Phase 144's selected anti-recursion recovery is protected against workflow and runbook drift without changing the existing release topology.

## Self-Check: PASSED

- Found `test/scripts/release_trigger_recovery_test.exs` and `CONTRIBUTING.md`.
- Found all six RED, GREEN, and REFACTOR task commits in git history.
- No known stubs, skipped tests, or unrun verification remain.
