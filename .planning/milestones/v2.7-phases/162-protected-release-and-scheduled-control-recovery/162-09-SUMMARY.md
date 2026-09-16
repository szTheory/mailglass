---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 09
subsystem: ci-hygiene
tags: [elixir, exunit, github-actions, gh, git]
requires:
  - phase: 162-03
    provides: "Three-state repository-hygiene audit, JSON result, and artifact-first workflow rendering"
provides:
  - "Immutable checkout-SHA CI selection for detached scheduled hygiene runs"
  - "Argument-sensitive detached-HEAD regression coverage for CI evidence"
affects: [repository-hygiene, scheduled-controls, phase-162-verification]
tech-stack:
  added: []
  patterns:
    - "Select GitHub Actions evidence by checked-out immutable SHA and validate returned headSha"
key-files:
  created: []
  modified:
    - dev/mix/tasks/mailglass.repo.hygiene.ex
    - test/mix/tasks/mailglass.repo.hygiene_test.exs
key-decisions:
  - "Scheduled hygiene CI evidence is selected with exact HEAD SHA via gh --commit, never an inferred branch."
requirements-completed: [AUTO-04]
coverage:
  - id: D1
    description: "Detached scheduled checkout queries ci.yml using its exact SHA and only passes a matching completed-success run."
    requirement: AUTO-04
    verification:
      - kind: integration
        ref: "mix test test/mix/tasks/mailglass.repo.hygiene_test.exs --seed 0"
        status: pass
      - kind: integration
        ref: "mix test test/scripts/release_trigger_recovery_test.exs test/mix/tasks/mailglass.repo.hygiene_test.exs --seed 0"
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-08-24
status: complete
---

# Phase 162 Plan 09: Scheduled CI SHA Selection Summary

**Repository hygiene now finds scheduled CI by the detached checkout's immutable SHA, and accepts only a matching completed-success result.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-08-24T18:40:00Z
- **Completed:** 2026-08-24T18:45:18Z
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Replaced branch-based CI selection with `gh run list --commit <HEAD SHA>` while retaining returned `headSha`, terminal status, and conclusion validation.
- Added a real detached-HEAD fixture whose fake `gh` rejects missing or unequal selector arguments.
- Covered matching, absent, incomplete, failed, wrong-head, and unavailable CI query outcomes without changing workflow authority or rendering.

## Task Commits

1. **Task 1: Trace scheduled detached HEAD through an exact-SHA CI query and validated result** - `417e4827` (test), `eff6892d` (fix)

## Files Created/Modified

- `dev/mix/tasks/mailglass.repo.hygiene.ex` - Selects `ci.yml` by exact checked-out SHA.
- `test/mix/tasks/mailglass.repo.hygiene_test.exs` - Validates detached checkout and exact `gh` query behavior.

## Decisions Made

- Use `git rev-parse HEAD` as the sole CI selector so a scheduled detached checkout cannot claim unrelated or branch-inferred evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the argument-validating fake `gh` shell fixture**
- **Found during:** Task 1
- **Issue:** Bash parsed `$10` as `${1}0`, which rejected an otherwise exact JSON-fields argument.
- **Fix:** Used `${10}` and limited argv logging/validation to `gh run` calls, preserving normal fake PR-list responses.
- **Files modified:** `test/mix/tasks/mailglass.repo.hygiene_test.exs`
- **Verification:** Focused hygiene suite and Wave 5 blocker gate passed.
- **Committed in:** `eff6892d`

---

**Total deviations:** 1 auto-fixed (Rule 1: 1).
**Impact on plan:** The fixture correction was necessary for the required exact-argument test and did not expand the production surface.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- AUTO-04's detached scheduled-CI selector is covered locally; a future real scheduled run remains separate operational evidence.
- No workflow topology, permission, authority, dependency, API, or schema changes were introduced.

## Self-Check: PASSED

- Confirmed both modified task files exist.
- Confirmed `417e4827` and `eff6892d` exist in git history.
- Confirmed no workflow file changed and no stubs were introduced in task files.

---
*Phase: 162-protected-release-and-scheduled-control-recovery*
*Completed: 2026-08-24*
