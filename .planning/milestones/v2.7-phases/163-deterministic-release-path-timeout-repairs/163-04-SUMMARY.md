---
phase: 163-deterministic-release-path-timeout-repairs
plan: 04
subsystem: testing
tags: [postgresql, property-testing, failure-evidence, ci]
provides:
  - Bounded exact-SHA non-reproduction with an approved no-speculation disposition.
  - Sanitized SQLSTATE 57014 recurrence capture in the existing deterministic CI lane.
key-files:
  created:
    - test/support/timeout_evidence.ex
    - test/mailglass/test_support/timeout_evidence_test.exs
  modified:
    - test/mailglass/properties/idempotency_convergence_test.exs
    - test/mailglass/properties/webhook_idempotency_convergence_test.exs
    - test/test_helper.exs
key-decisions:
  - Accept bounded non-reproduction without a database repair; capture the next protected recurrence automatically.
requirements-completed: [DTRM-01]
completed: 2026-08-26
status: complete
---

# Phase 163 Plan 04: Database Timeout Evidence Summary

**The historical SQLSTATE 57014 was recovered but did not recur in three exact-SHA attempts or the complete current suite, so the approved outcome preserves the 1,000-run invariants and installs sanitized failure-only recurrence evidence instead of speculating about a repair.**

## Accomplishments

- Bound the original failure to run `32433156236`, job `96628985134`, and SHA `81e738e74d59d1ab36c3e1dc3adc03ad6d0c0b84`.
- Recorded three unseeded exact-SHA first-attempt passes and an honest inconclusive owner verdict.
- Added versioned exact-run manifests and structured 57014 observation at stable database operation boundaries; raw exceptions, SQL, and generated data are excluded and the original exception is re-raised.
- Retained both `max_runs: 1000` properties, their generators, ten-minute owners, cleanup/settle behavior, schemas, APIs, and all finite database/job limits.

## Verification

- Focused contracts and both properties: 2 properties, 6 tests, 0 failures in 64.4s.
- Full deterministic suite: 23 properties, 1,964 tests, 0 failures, 7 intentional skips in 174.7s.
- Recorder tests prove sanitization, exact identity, fail-through behavior, and rejection of unsafe free-form labels.

## Commits

- `3832678f` — immutable historical reconstruction.
- `29eb8b3f` — structured database recurrence recorder and property wiring.
- `f46aad8b` — failure-only CI artifact upload.

## Decision

The maintainer approved automatic `re-scope/defer-dtrm-01`: bounded non-reproduction plus recurrence capture satisfies DTRM-01. No database timeout value, fixture semantics, production transaction, or property contract changed.

---
*Plan status: complete without human UAT*
