---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
plan: "06"
subsystem: outbound payload lifecycle operations
tags: [elixir, oban, mix, payload-pruning, tenancy, optional-dependencies, privacy]
requires:
  - phase: 151-05
    provides: explicit tenant-scoped bounded payload tombstone pruner
provides:
  - optional scheduled maintenance worker and universal manual payload prune entrypoint
  - isolated Oban-free proof for direct and Mix pruning paths
affects: [payload-retention, outbound-operations, generated-host-proof]
tech-stack:
  added: []
  patterns: [conditional optional worker stub, tenant-required Mix operation, isolated runtime source-boundary audit]
key-files:
  created:
    - lib/mailglass/outbound/payload_pruner_worker.ex
    - lib/mix/tasks/mailglass.outbound.payloads.prune.ex
    - test/mailglass/outbound/payload_pruner_test.exs
  modified:
    - test/runtime/no_optional_deps_public_send.exs
key-decisions:
  - "Both scheduled and manual pruning call PayloadPruner.prune/1 with exactly one explicit tenant; no entrypoint defaults or enumerates tenants."
  - "Payload-pruner scheduling reuses :mailglass_maintenance and does not alter outbound delivery readiness."
  - "Manual output is limited to aggregate expired and retention-expired counts."
metrics:
  duration: 6min
  completed: 2026-08-03
  tasks_completed: 1
  files_modified: 4
status: complete
---

# Phase 151 Plan 06: Bounded Payload Pruning Operations Summary

**Tenant-explicit bounded payload pruning works manually everywhere and through an honest optional Oban maintenance worker.**

## Accomplishments

- Added `Mailglass.Outbound.PayloadPrunerWorker`, conditionally compiled behind `Oban.Worker`, with a false-availability stub when Oban is absent.
- Added `mix mailglass.outbound.payloads.prune --tenant TENANT_ID`; it invokes one core prune call and emits aggregate lifecycle/reason counts without tenant or payload content.
- Extended the isolated no-optional runtime harness to execute the library and exact Mix entrypoint, verify tombstones, deny tenant/private output, and reject unexpected Oban source references.

## Task Commits

1. **Task 151-06-01 RED:** `7a2fc1fb` — failing tenant-required Mix and worker parity coverage.
2. **Task 151-06-01 GREEN:** `788aacf0` — optional worker, universal Mix task, runtime proof, and passing coverage.

## Verification

- `mix test test/mailglass/outbound/payload_pruner_test.exs --only phase_151_task:t151_06_01 --warnings-as-errors` — passed (3 tests).
- `MIX_ENV=test mix verify.no_optional_runtime` — passed; the isolated direct launcher ran both pruning entrypoints without Oban.
- `mix test test/runtime/no_optional_deps_public_send_test.exs --only phase_151_task:t151_06_02 --warnings-as-errors` — passed; public catalog/table counts and private-output boundary are pinned.

## Decisions Made

- The worker accepts exactly one `mailglass_tenant_id` argument and cancels malformed or extra-argument jobs.
- The task uses the running `Mailglass.Supervisor` when available so the direct isolated runtime can invoke the real Mix entrypoint without a Mix project; ordinary invocations start Mailglass normally.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Made the Mix entrypoint direct-runtime-safe.**
- **Found during:** Task 151-06-01 no-optional runtime verification.
- **Issue:** The direct Elixir harness has no `Mix.Project`; `mix app.start` could not run even though Mailglass was already started.
- **Fix:** The task detects the existing `Mailglass.Supervisor` and only starts the application when needed.
- **Files modified:** `lib/mix/tasks/mailglass.outbound.payloads.prune.ex`
- **Verification:** The isolated no-optional runtime command passed.

## Known Stubs

None.

## Post-Plan Regression Fix

- The original runtime probe used the configured `public` schema, so its migration and seeded pruning fixtures altered the shared test database.
- The probe now uses a generated, identifier-validated `mailglass_no_optional_*` scratch schema, records a unique migration version, drops only that schema, and removes only its matching `schema_migrations` entry.
- Added a regression test that snapshots the public catalog and operational table counts around the real shell proof, and rejects private fixture content in the shell output.
- Removed three exact, prior buggy-probe rows (`tenant_id LIKE 'runtime-prune-%'` and `mailable = 'RuntimeProbe'`) from the test database. No baseline schema or user rows were targeted.

## Review Note

The repaired sequential command no longer produces public-catalog/table failures. `MIX_ENV=test mix verify.support_contract.core` still reports two unrelated existing failures in `test/mailglass/outbound_test.exs` (header lookup shape and explicit route serialization); they were present before this regression fix and are outside the runtime probe's schema boundary.

## Regression-Fix Commits

3. **Regression RED:** `124063ae` — catalog/data preservation and private-output test.
4. **Regression GREEN:** `03f2b2d3` — scratch-schema runtime isolation and logging boundary.
5. **Cleanup hardening:** `0da3f649` — enter the scratch cleanup guard before migration work.

## Self-Check: PASSED

- Confirmed the worker, Mix task, focused test, and runtime harness exist.
- Confirmed RED commit `7a2fc1fb` and GREEN commit `788aacf0` exist in git history.
