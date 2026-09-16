---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 11
subsystem: infra
tags: [elixir, mix-task, github-cli, json, ci]
requires:
  - phase: 162-09
    provides: "Exact checkout-SHA CI run selection and valid-list policy coverage"
provides:
  - "Bounded cannot-check evidence for malformed or non-list successful GitHub CLI responses"
  - "Decodable nonzero JSON CLI reporting for malformed CI evidence"
affects: [repo-hygiene, actions-summary, AUTO-04]
tech-stack:
  added: []
  patterns: ["Treat successful external-command bytes as untrusted until decoded and shape-validated"]
key-files:
  created: []
  modified:
    - dev/mix/tasks/mailglass.repo.hygiene.ex
    - test/mix/tasks/mailglass.repo.hygiene_test.exs
key-decisions:
  - "Malformed and non-list gh run-list responses are unavailable evidence, not policy blocks."
  - "Valid lists retain the exact SHA, completed, and success-conclusion checks."
requirements-completed: [AUTO-04]
coverage:
  - id: D1
    description: "Malformed and non-list zero-exit GitHub CI responses produce decodable cannot-check JSON and a nonzero CLI exit."
    requirement: AUTO-04
    verification:
      - kind: integration
        ref: "mix test test/mix/tasks/mailglass.repo.hygiene_test.exs --seed 0"
        status: pass
      - kind: integration
        ref: "mix test test/scripts/release_trigger_recovery_test.exs test/mix/tasks/mailglass.repo.hygiene_test.exs --seed 0"
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-08-24
status: complete
---

# Phase 162 Plan 11: Bounded GitHub CI Evidence Summary

**Malformed successful GitHub CI run-list output now becomes serialized cannot-check evidence instead of escaping the repository-hygiene Mix task.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-08-24T15:50:00Z
- **Completed:** 2026-08-24T15:53:00Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Replaced the raising CI response decode with non-raising JSON and run-list shape classification.
- Preserved exact checkout-SHA, completed-status, and success-conclusion validation for valid run lists.
- Added audit and real JSON CLI coverage for malformed and non-list zero-exit `gh` fixtures.

## Task Commits

1. **Task 1: Trace malformed successful GitHub bytes through bounded JSON and nonzero CLI evidence** - `037fdf5e` (test RED), `833df307` (fix GREEN)

## Files Created/Modified

- `dev/mix/tasks/mailglass.repo.hygiene.ex` - Classifies malformed and non-list `gh run list` responses as cannot-check.
- `test/mix/tasks/mailglass.repo.hygiene_test.exs` - Exercises malformed and non-list fixtures through audit and JSON CLI boundaries.

## Decisions Made

- Successful command execution alone is not valid remote evidence; decode and list-shape failures remain unavailable evidence with a retry/inspection action.
- Valid empty, mismatched, incomplete, and failed lists remain policy-blocked, distinct from malformed or unavailable evidence.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The initial regression correctly failed at `Jason.decode!/1`; the expected RED result confirmed the external-input trust-boundary defect.

## TDD Gate Compliance

- RED: `037fdf5e` adds the failing malformed/non-list CI fixture.
- GREEN: `833df307` implements the non-raising decode and passes the focused and Wave 6 gates.

## Next Phase Readiness

AUTO-04's malformed-success CI evidence gap is closed without changing workflow topology, result schema, permissions, or release authority.

## Self-Check: PASSED

- Confirmed both modified source/test files and this summary exist.
- Confirmed RED commit `037fdf5e` and GREEN commit `833df307` exist in git history.

---
*Phase: 162-protected-release-and-scheduled-control-recovery*
*Completed: 2026-08-24*
