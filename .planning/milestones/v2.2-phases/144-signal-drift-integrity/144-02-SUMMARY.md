---
phase: 144-signal-drift-integrity
plan: 02
subsystem: tooling
tags: [elixir, mix-task, github, branch-protection, hermetic-tests]
requires:
  - phase: 144-01
    provides: Honest branch-protection workflow outcome contract
provides:
  - Repo-hygiene classification that distinguishes verified protection drift from unavailable verification
  - Hermetic regression coverage for verifier, credential, tooling, and endpoint failures
affects: [repo-hygiene, release-checks, branch-protection]
tech-stack:
  added: []
  patterns: [canonical-drift-prefix-classification, non-success-unknown-aggregate, hermetic-path-fixtures]
key-files:
  created: []
  modified:
    - dev/mix/tasks/mailglass.repo.hygiene.ex
    - test/mix/tasks/mailglass.repo.hygiene_test.exs
key-decisions:
  - "Only verifier output beginning DRIFT: is classified as verified branch-protection drift."
  - "Existing :unknown remains the per-check cannot-check vocabulary, while any unknown check blocks aggregate success."
requirements-completed: [TRUTH-06]
coverage:
  - id: D1
    description: "Repo hygiene distinguishes clean branch protection, verified drift, and unavailable verification without a network dependency."
    requirement: TRUTH-06
    verification:
      - kind: integration
        ref: "mix test test/mix/tasks/mailglass.repo.hygiene_test.exs --warnings-as-errors"
        status: pass
      - kind: integration
        ref: "mix verify.mix_tasks"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-07-31
status: complete
---

# Phase 144 Plan 02: Repo Hygiene Truth Summary

**Repo hygiene now reports only canonical `DRIFT:` output as branch-protection drift and treats missing tooling, credentials, and inaccessible verification as non-successful cannot-check outcomes.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-31T20:51:00Z
- **Completed:** 2026-07-31T20:55:00Z
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Classified absent verifier, absent `gh`, absent/empty `GH_TOKEN`, and non-canonical verifier failures as explicit `:unknown` cannot-check results with actionable recovery.
- Kept `:blocked` exclusively for canonical verifier output beginning `DRIFT:` and retained the established check-map, text, and JSON status vocabulary.
- Made aggregate hygiene status fail closed whenever any sub-check is not `:pass`.
- Added hermetic temporary verifier and `PATH` fixtures that exercise clean, drift, prerequisite, and 403-style endpoint cases without contacting GitHub.

## Task Commits

1. **Task 1: Lock repo-hygiene branch-protection classification with executable cases** - `9ac67c37` (test), `147e4fe7` (fix)

## Files Created/Modified

- `dev/mix/tasks/mailglass.repo.hygiene.ex` - Truthful branch-protection classification and fail-closed aggregate/CLI status semantics.
- `test/mix/tasks/mailglass.repo.hygiene_test.exs` - Deterministic full-audit fixtures and outcome-classification regression tests.

## Decisions Made

- Canonical `DRIFT:` is the sole nonzero verifier signal that represents observed configuration drift; all other nonzero outcomes mean verification could not be completed.
- `:unknown` remains the private per-check status to preserve result-map compatibility, and aggregates to `:blocked` so a partial audit can never present as success.

## Verification

- `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs --warnings-as-errors` — 9 tests, 0 failures.
- `mix verify.mix_tasks` — 55 tests, 0 failures.
- `mix format --check-formatted test/mix/tasks/mailglass.repo.hygiene_test.exs dev/mix/tasks/mailglass.repo.hygiene.ex` — passed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The repo-hygiene CLI now shares the phase-wide fail-loud semantics for unavailable branch-protection verification. Subsequent Phase 144 plans can rely on its distinct clean, drift, and cannot-check outcomes.

## Self-Check: PASSED

- Confirmed both modified source/test files exist.
- Confirmed TDD RED and GREEN commits `9ac67c37` and `147e4fe7` exist.

---
*Phase: 144-signal-drift-integrity*
*Completed: 2026-07-31*
