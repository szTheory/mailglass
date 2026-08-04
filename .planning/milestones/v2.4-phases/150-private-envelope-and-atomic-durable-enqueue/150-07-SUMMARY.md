---
phase: 150-private-envelope-and-atomic-durable-enqueue
plan: "07"
subsystem: database
tags: [postgres, ecto, migrations, schema-prefix, payload-privacy]
requires:
  - phase: 150-05
    provides: V05 delivery schema before private-payload storage
provides:
  - Dedicated V05→V06→down→up hostile-search-path catalog lifecycle proof
  - Canonical legacy-metadata and zero-backfill migration evidence
affects: [phase-151-payload-lifecycle, phase-153-generated-host-proof]
tech-stack:
  added: []
  patterns: [guarded scratch schemas, catalog-qualified migration assertions]
key-files:
  created: [test/mailglass/v06_migration_test.exs]
  modified: [lib/mailglass/migrations/postgres/v06.ex]
key-decisions:
  - "V06 retains Ecto :utc_datetime_usec DDL, catalog-proven as PostgreSQL timestamp without time zone."
  - "Temporary migration-runner versions are deleted immediately so migration regression modules remain isolated."
patterns-established:
  - "Prefix-sensitive migration tests build prerequisites in a guarded scratch schema and assert pg_catalog objects by explicit namespace."
requirements-completed: [ENVL-05]
coverage:
  - id: D1
    description: V06 target-prefix table, columns, FK, indexes, partial predicate, no-backfill, rollback, and exact re-up are runtime-proven.
    requirement: ENVL-05
    verification:
      - kind: integration
        ref: mix test test/mailglass/v06_migration_test.exs test/mailglass/migration_test.exs test/mailglass/schema_prefix_hardening_test.exs --warnings-as-errors
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-08-02
status: complete
---

# Phase 150 Plan 07: V06 Hostile-Path Migration Proof Summary

**Dedicated Postgres catalog proof now verifies V06 payload DDL remains prefix-bound, preserves legacy metadata without backfill, and rolls back/re-applies exactly.**

## Performance

- **Duration:** 12 min
- **Completed:** 2026-08-02
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Added a serial guarded-scratch V05→V06 lifecycle test with decoy and public collision checks under a restored hostile search path.
- Catalog-asserted all ten payload columns, same-prefix cascade FK, three owned indexes, and the normalized `expires_at IS NOT NULL` predicate.
- Proved zero payload backfill, byte/canonical legacy metadata preservation, V06-only down behavior, and an identical post-re-up signature.

## Task Commits

1. **Task 150-07-01: Prove the exact hostile-path V06 lifecycle and no-backfill contract** — `33f99698` (test)
2. **Task 150-07-01 follow-up: isolate temporary migration bookkeeping** — `dc742674` (fix)

## Files Created/Modified

- `test/mailglass/v06_migration_test.exs` — direct lifecycle/canonical catalog regression coverage in guarded scratch schemas.
- `lib/mailglass/migrations/postgres/v06.ex` — added the standard internal module documentation marker.

## Decisions Made

- V06's existing prefix-qualified DDL was already correct; no storage behavior or backfill logic was added.
- The expected physical type for Ecto `:utc_datetime_usec` is `timestamp without time zone`, as proven by `pg_catalog.format_type/2`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Isolated temporary Ecto migration bookkeeping versions**
- **Found during:** Task 150-07-01
- **Issue:** A temporary V05 runner version could remain visible to adjacent migration regression modules, causing an out-of-order migration assertion failure in the combined gate.
- **Fix:** Delete each temporary setup/operation `schema_migrations` version immediately after its DDL has committed.
- **Files modified:** `test/mailglass/v06_migration_test.exs`
- **Verification:** Combined V06, migration, and schema-prefix regression gate passes.
- **Committed in:** `dc742674`

**Total deviations:** 1 auto-fixed (Rule 1).

## Issues Encountered

- The initial direct callback attempt ran outside Ecto's migration runner. The dedicated wrapper preserves direct V06 module execution while supplying the required migration-runner context.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

V06's exact reversible storage contract is proven and ready for Phase 151 payload lifecycle work.

## Self-Check: PASSED

- `test/mailglass/v06_migration_test.exs` exists.
- Task commits `33f99698` and `dc742674` exist.
