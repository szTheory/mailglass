---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
plan: "03"
subsystem: database
tags: [postgres, ecto, migrations, payload-lifecycle, security]
requires:
  - phase: 150-private-envelope-and-atomic-durable-enqueue
    provides: V06 private outbound payload storage
provides:
  - Prefix-safe V07 lifecycle state, reason, claim, and tombstone constraints
  - Refusal-before-DDL downgrade protection for non-recoverable payload facts
affects: [151-04, outbound-payload-lifecycle, durable-dispatch]
tech-stack:
  added: []
  patterns: [prefix-qualified migration preflight, conditionally reversible lifecycle migration]
key-files:
  created: [lib/mailglass/migrations/postgres/v07.ex, test/mailglass/v07_migration_test.exs]
  modified: [lib/mailglass/migrations/postgres.ex, test/mailglass/migration_test.exs]
key-decisions:
  - "Downgrade refuses before DDL whenever V07-only lifecycle facts cannot be represented by V06."
  - "V06 payload bytes remain untouched on upgrade; clean recoverable rows are the only reversible state."
patterns-established:
  - "Migration rollback preflights query the explicit schema before changing catalog state."
requirements-completed: [PRIV-01, PRIV-02, PRIV-04]
coverage:
  - id: D1
    description: "V07 persists all nine closed lifecycle states with bounded reason, claim, and content combinations."
    requirement: PRIV-01
    verification:
      - kind: integration
        ref: "test/mailglass/v07_migration_test.exs#the state, reason, claim, and content checks enforce the lifecycle matrix"
        status: pass
    human_judgment: false
  - id: D2
    description: "Hostile-search-path V06 rows upgrade safely; only clean recoverable rows down and re-up."
    requirement: PRIV-04
    verification:
      - kind: integration
        ref: "mix test test/mailglass/v06_migration_test.exs test/mailglass/v07_migration_test.exs test/mailglass/migration_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-08-03
status: complete
---

# Phase 151 Plan 03: Payload Lifecycle Migration Summary

**Prefix-safe V07 payload lifecycle schema with explicit tombstone states and lossless-only downgrade protection.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-08-03T02:39:54Z
- **Completed:** 2026-08-03T02:42:50Z
- **Tasks:** 1/1
- **Files modified:** 4

## Accomplishments

- Added V07 lifecycle state, bounded reason, claim, and content checks for recoverable, dispatching, scrubbed, expired, terminal, discarded, abandoned, uncertain, and legacy payloads.
- Added a deterministic state/expiry index and preserved explicit schema prefixing across DDL and preflight queries.
- Made downgrade fail before catalog mutation when a claim, non-recoverable state, reason, or contentless tombstone would be lost; clean V06-compatible rows round-trip exactly.

## Task Commits

1. **Task 1: Prove the V07 lifecycle schema under a hostile search path** - `0d79b02b` (test), `4f4b6413` (feat)

## Files Created/Modified

- `lib/mailglass/migrations/postgres/v07.ex` - V07 lifecycle schema and safe conditional rollback.
- `lib/mailglass/migrations/postgres.ex` - Exposes V07 as the current migration version.
- `test/mailglass/v07_migration_test.exs` - Hostile-path lifecycle, refusal, matrix, and round-trip proof.
- `test/mailglass/migration_test.exs` - Dispatcher version assertion.

## Decisions Made

- The downgrade preflight is the first V07 down action so failures cannot leave a partially downgraded catalog.
- V07 allows only clean `recoverable` rows to return to V06; it never invents content or coerces lifecycle facts.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The focused suite and the V06/V07/migration suite passed; the latter emits existing Ecto test-version ordering warnings only.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Later payload lifecycle workers can rely on the closed V07 state contract and the pre-DDL downgrade safety boundary.

## Self-Check: PASSED

- Confirmed V07 migration and focused migration test files exist.
- Confirmed commits `0d79b02b` and `4f4b6413` exist in git history.
