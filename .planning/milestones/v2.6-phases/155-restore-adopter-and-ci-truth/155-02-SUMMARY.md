---
phase: 155
plan: 02
subsystem: migration-version-detection
tags: [postgres, ecto, migrations, fail-closed, inbound]
requires:
  - 155-01
provides:
  - typed migration catalog failures
  - distinct absent-anchor semantics for core and inbound
affects:
  - generated migration wrappers
  - upgrade and rollback control flow
tech-stack:
  added: []
  patterns: [explicit-catalog-classification, injected-query-result-seam, typed-fail-closed-errors]
key-files:
  created:
    - lib/mailglass/migration_version_error.ex
  modified:
    - lib/mailglass/migration.ex
    - lib/mailglass/migrations/postgres.ex
    - test/mailglass/migration_test.exs
    - mailglass_inbound/lib/mailglass_inbound/migration.ex
    - mailglass_inbound/lib/mailglass_inbound/migrations/postgres.ex
    - mailglass_inbound/test/mailglass_inbound/migrations_test.exs
decisions:
  - Version zero is returned only for an empty catalog result, never a query or metadata failure.
  - Core and inbound share the error type but retain independent anchor names, package tags, and version ranges.
metrics:
  tasks_completed: 2
  task_commits: 3
status: complete
---

# Phase 155 Plan 02: Fail-Closed Migration Metadata Summary

Core and inbound migration readers now distinguish a genuinely absent anchor from corrupt, impossible, or unavailable catalog metadata before executing migration DDL.

## Completed Tasks

1. Core catalog classification — `cfbd3130`, `52783b37`
2. Independent inbound catalog classification — `f6b846f1`

## What Changed

- Added `Mailglass.MigrationVersionError` with stable reason atoms, package and prefix context, and a PII-free actionable message.
- Core and inbound readers classify empty rows as version zero, parse only complete bounded integers, and raise for missing comments, malformed comments, unexpected shapes, out-of-range versions, and query errors.
- Both `up/1` paths classify the anchor before schema-creation DDL, so metadata failures stop migration work early.
- Added injected catalog-result coverage plus real scratch-schema anchor tests for both independent anchors.

## Verification

- Passed: `cd mailglass_inbound && mix test test/mailglass_inbound/migrations_test.exs --warnings-as-errors` — 14 tests, 0 failures.
- Scoped core catalog tests passed as part of `mix test test/mailglass/migration_test.exs --warnings-as-errors`.
- The full core file remains blocked by a pre-existing teardown collision: its legacy `down/0` test cannot drop `mailglass_deliveries` because `mailglass_outbound_payloads_delivery_id_fkey` depends on it. This is outside the Plan 155-02 files/behavior.
- `cd mailglass_inbound && mix format --check-formatted` remains blocked by pre-existing formatting drift in unrelated inbound ingress, model, router, and test files; Plan 155-02 files were formatted.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Made the existing inbound export test load its module before `function_exported?/3`.
- **Found during:** Task 2 verification
- **Issue:** `function_exported?/3` returned false when the module had not yet been loaded in a randomized focused test run.
- **Fix:** Added `Code.ensure_loaded!/1` before the export assertions.
- **Files modified:** `mailglass_inbound/test/mailglass_inbound/migrations_test.exs`
- **Commit:** `f6b846f1`

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed `lib/mailglass/migration_version_error.ex` exists.
- Confirmed commits `cfbd3130`, `52783b37`, and `f6b846f1` exist.
