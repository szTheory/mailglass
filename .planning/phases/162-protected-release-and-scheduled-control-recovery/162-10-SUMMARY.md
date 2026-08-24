---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 10
subsystem: release automation
tags: [github-actions, release-please, exunit, protected-dispatch]
requires:
  - phase: 162-08
    provides: bounded scheduled proposal discovery and result control
provides:
  - Protected exact-digest releases bypass the proposal-only post-merge tail.
  - An executable regression covers the one-proposal to zero-proposal lifecycle.
affects: [release-please, protected release recovery, AUTO-03]
tech-stack:
  added: []
  patterns: [candidate-digest predicate consistently scopes proposal-only workflow steps]
key-files:
  created: []
  modified: [.github/workflows/release-please.yml, test/scripts/release_trigger_recovery_test.exs]
key-decisions:
  - "A nonempty candidate digest selects the protected lifecycle; every proposal-only reporting consumer requires an empty digest."
requirements-completed: [AUTO-03]
coverage:
  - id: D1
    description: "Exact protected dispatch merges and creates a release without a zero-row post-merge proposal query causing proposal_missing."
    requirement: AUTO-03
    verification:
      - kind: integration
        ref: "test/scripts/release_trigger_recovery_test.exs#protected exact-digest release bypasses proposal-only control after its merge leaves no open proposal"
        status: pass
    human_judgment: false
duration: 4m
completed: 2026-08-24
status: complete
---

# Phase 162 Plan 10: Protected Release Tail Isolation Summary

**Protected exact-digest releases now finish outside the proposal-only capture, artifact, and failure-gate lifecycle after merge.**

## Performance

- **Duration:** 4m
- **Started:** 2026-08-24T19:41:28Z
- **Completed:** 2026-08-24T19:48:00Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Required an empty candidate digest for proposal capture, result writing, summary, upload, final gating, and proposal-candidate upload.
- Preserved ordinary push, schedule, and digest-free dispatch behavior while making the protected lifecycle mutually exclusive.
- Added a protected lifecycle regression that records required-check validation, merge, release creation, and the resulting zero open proposals.

## Task Commits

1. **Task 1: Trace a completed protected release past the post-merge zero-proposal state** - `cc427af1` (test), `aee58c02` (fix)

## Files Created/Modified

- `.github/workflows/release-please.yml` - Gates every proposal-only tail consumer on an empty candidate digest.
- `test/scripts/release_trigger_recovery_test.exs` - Exercises the protected merge/release lifecycle and predicate boundary.

## Decisions Made

- A nonempty exact candidate digest is the sole protected-release selector; no proposal-control artifact or gate is applicable after that authority path completes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test harness bug] Used string environment keys for the lifecycle shell fixture**
- **Found during:** Task 1
- **Issue:** `System.cmd/3` rejects atom keys in its `env` option.
- **Fix:** Passed `COMMAND_LOG` and `PROPOSAL_STATE` as string-keyed environment pairs.
- **Files modified:** `test/scripts/release_trigger_recovery_test.exs`
- **Verification:** Focused lifecycle regression passed.
- **Committed in:** `aee58c02`

**Total deviations:** 1 auto-fixed (Rule 1)

## Verification

- `mix test test/scripts/release_trigger_recovery_test.exs:310 test/scripts/release_trigger_recovery_test.exs:398 test/scripts/release_trigger_recovery_test.exs:441 test/scripts/release_trigger_recovery_test.exs:533 --seed 0` — 4 tests, 0 failures.
- `mix test test/scripts/release_trigger_recovery_test.exs --seed 0` — completed successfully.
- `mix test test/scripts/phase_162_release_reconciliation_test.exs test/scripts/release_trigger_recovery_test.exs --seed 0` — completed successfully.

## Known Stubs

None.

## Next Phase Readiness

Plan 11 can repair the remaining malformed successful GitHub CI response path without changing this protected-release boundary.

## Self-Check: PASSED

- Found `.github/workflows/release-please.yml` and `test/scripts/release_trigger_recovery_test.exs`.
- Found task commits `cc427af1` and `aee58c02`.
