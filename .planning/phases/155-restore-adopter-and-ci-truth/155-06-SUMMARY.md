---
phase: 155-restore-adopter-and-ci-truth
plan: 06
subsystem: ci
tags: [github-actions, branch-protection, fail-closed, regression-tests]
requires:
  - phase: 155-05
    provides: Generated-host adoption proof while the protected CI identity remains stable
provides:
  - Fail-closed CI Green aggregate policy for detector and required-lane outcomes
  - Structural changes dependency with required-leaf registry parity tests
affects: [branch-protection, release-gating, phase-156]
tech-stack:
  added: []
  patterns: [explicit-aggregate-inputs, closed-ci-result-policy, mutation-backed-workflow-contracts]
key-files:
  created: [scripts/ci_green_policy.sh, test/scripts/ci_green_policy_test.exs]
  modified: [.github/workflows/ci.yml, test/scripts/required_checks_test.exs]
key-decisions:
  - "CI Green delegates to a shell policy with explicit detector and leaf inputs; it never infers docs-only status from skipped leaves."
  - "changes is a structural ci_green dependency, deliberately excluded from the required check registry and leaf set-equality comparison."
requirements-completed: [QUAL-02]
coverage:
  - id: D1
    description: "CI Green fails closed for failed classification, invalid detector output, and every non-success required code-lane result."
    requirement: QUAL-02
    verification:
      - kind: unit
        ref: "mix test test/scripts/ci_green_policy_test.exs test/scripts/required_checks_test.exs test/scripts/lane_classification_drift_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "A successful explicit docs-only classification is the sole path that permits required leaves to be skipped while the protected check identity remains unchanged."
    requirement: QUAL-02
    verification:
      - kind: unit
        ref: "test/scripts/ci_green_policy_test.exs#only a successful docs-only classification permits skipped required leaves"
        status: pass
      - kind: other
        ref: "actionlint .github/workflows/ci.yml"
        status: pass
    human_judgment: false
status: complete
---

# Phase 155 Plan 06: CI Green Fail-Closed Aggregate Summary

**CI Green now trusts only a successful explicit change classification, requiring exact leaf success for code changes while safely allowing skips exclusively on verified docs-only runs.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-08-17T02:23:00Z
- **Completed:** 2026-08-17T02:28:04Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added a deterministic, fail-closed policy that validates detector state, a closed boolean code value, and unique explicit required-leaf result pairs.
- Wired `changes` directly into the unchanged `CI Green` aggregate and passed every required leaf to the policy without altering the protected branch-check identity.
- Added black-box decision-table coverage and mutation-backed workflow-contract tests for missing dependencies, leaf deletions, and removed policy wiring.

## Task Commits

1. **Task 1: Fail CI Green when detector or one required code lane is not successful** - `4231b3ed` (`test`), `3fb369cf` (`feat`), `e1168481` (`feat`)
2. **Task 2: Permit only successfully classified docs-only skips and preserve lane-set truth** - `7248ad68` (`test`), `4049f2ec` (`test`)

## Files Created/Modified

- `scripts/ci_green_policy.sh` - Validates the complete aggregate decision table and reports unacceptable inputs by lane.
- `test/scripts/ci_green_policy_test.exs` - Executes detector, code-path, docs-only, malformed-input, and negative result cases against the real script.
- `.github/workflows/ci.yml` - Preserves `CI Green` and `if: always()` while passing direct `changes` and leaf inputs to the policy.
- `test/scripts/required_checks_test.exs` - Keeps `changes` structural, preserves required-leaf set equality, and proves mutation failures.

## Decisions Made

- `changes` is an aggregate control input rather than a required leaf or branch-protection context, so it is asserted separately before required-lane set equality.
- Unknown, empty, failed, and cancelled leaf outcomes block the aggregate; only `success` is acceptable for code changes, and docs-only additionally permits `skipped`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made the policy portable under Bash strict mode**
- **Found during:** Task 1
- **Issue:** Expanding a declared-but-empty array under Bash 3.2 with `set -u` raised an unbound-variable error before policy evaluation.
- **Fix:** Used a safe empty-array expansion for duplicate detection.
- **Files modified:** `scripts/ci_green_policy.sh`
- **Verification:** Focused policy suite passes under the local Bash runtime.
- **Committed in:** `3fb369cf`

**Total deviations:** 1 auto-fixed (Rule 1)

## Known Stubs

None.

## Issues Encountered

`state.advance-plan` could not parse the pre-existing `Plan: —` position marker in `STATE.md`; progress, metrics, decisions, session, roadmap plan counts, and QUAL-02 traceability were updated through their dedicated handlers.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Protected `CI Green` now has an executable fail-closed contract without changing branch-protection identity or the required-lane registry.

## Self-Check: PASSED

- All four plan artifacts exist.
- Task commits `4231b3ed`, `3fb369cf`, `7248ad68`, `e1168481`, and `4049f2ec` exist in git history.
- `bash -n scripts/ci_green_policy.sh`, `actionlint .github/workflows/ci.yml`, the focused 66-test suite, and `mix format --check-formatted` passed.
