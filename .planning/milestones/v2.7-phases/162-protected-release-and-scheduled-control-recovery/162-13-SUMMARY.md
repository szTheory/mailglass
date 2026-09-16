---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 13
subsystem: repository hygiene
tags: [elixir, mix-task, github-cli, json, evidence]
requires:
  - phase: 162-11
    provides: "Three-state CI-run evidence handling with non-raising JSON shape validation"
provides:
  - "Bounded cannot-check evidence for malformed or non-list successful GitHub PR-list responses"
  - "Regression coverage through audit and JSON CLI boundaries"
affects: [repository-hygiene, AUTO-04, phase-162-verification]
tech-stack:
  added: []
  patterns:
    - "Treat zero-exit external JSON as usable only after decoding and top-level shape validation"
key-files:
  created: []
  modified:
    - dev/mix/tasks/mailglass.repo.hygiene.ex
    - test/mix/tasks/mailglass.repo.hygiene_test.exs
key-decisions:
  - "Successful gh pr list output must decode to a JSON list before policy classification."
  - "Malformed and non-list PR observations are cannot-check evidence, never inferred empty lists."
patterns-established:
  - "Reuse ci_state/1's decode-and-shape guard for external GitHub list responses."
requirements-completed: [AUTO-04]
coverage:
  - id: D1
    description: "Malformed or non-list successful PR-list responses serialize as bounded cannot-check evidence and exit nonzero."
    requirement: AUTO-04
    verification:
      - kind: integration
        ref: "test/mix/tasks/mailglass.repo.hygiene_test.exs#bounds malformed and non-list successful PR responses as cannot-check JSON evidence"
        status: pass
    human_judgment: false
  - id: D2
    description: "Valid empty and nonempty PR lists retain pass and blocked policy semantics."
    requirement: AUTO-04
    verification:
      - kind: integration
        ref: "test/mix/tasks/mailglass.repo.hygiene_test.exs#bounds malformed and non-list successful PR responses as cannot-check JSON evidence"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-08-24
status: complete
---

# Phase 162 Plan 13: Bounded PR-List Evidence Summary

**Repository hygiene now preserves malformed successful PR-list output as inspectable cannot-check JSON evidence instead of raising before its result boundary.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-08-24T20:37:02Z
- **Completed:** 2026-08-24T20:41:42Z
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Replaced the raising PR-list decoder with decode-and-list-shape validation.
- Classified malformed and non-list zero-exit responses as cannot-check with inspect/retry guidance.
- Preserved existing empty-list pass and one-PR blocked details through audit and JSON CLI coverage.

## Task Commits

1. **Task 1: Trace malformed successful PR bytes through bounded cannot-check JSON** - `af22dba0` (test RED), `b33d619d` (fix GREEN)

## Files Created/Modified

- `dev/mix/tasks/mailglass.repo.hygiene.ex` - Validates successful PR-list JSON is list-shaped before classification.
- `test/mix/tasks/mailglass.repo.hygiene_test.exs` - Exercises malformed/non-list PR output plus retained valid-list behavior at audit and CLI boundaries.

## Decisions Made

- A zero process exit proves command transport only; PR policy evidence requires decodable list-shaped JSON.
- Invalid PR JSON remains unknown (`cannot-check`) and preserves the existing aggregate, JSON, summary, artifact, and nonzero-exit path.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs --seed 0` — passed (18 tests).
- `mix test test/scripts/release_trigger_recovery_test.exs test/mix/tasks/mailglass.repo.hygiene_test.exs --seed 0` — passed.
- `git diff --check -- dev/mix/tasks/mailglass.repo.hygiene.ex test/mix/tasks/mailglass.repo.hygiene_test.exs` — passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

AUTO-04's malformed successful PR-list boundary is now bounded and serializable; no release authority, workflow topology, or post-publish recovery behavior changed.

## Self-Check: PASSED

- Required production and regression files exist.
- TDD RED and GREEN commits exist in git history.

---
*Phase: 162-protected-release-and-scheduled-control-recovery*
*Completed: 2026-08-24*
