# Phase 02 Deferred Items

## Pre-existing flaky test (found during 02-05 execution)

**File:** `test/mailglass/tenancy_test.exs:116`
**Test:** `behaviour contract — SingleTenant implements @behaviour Mailglass.Tenancy`
**Frequency:** ~1 in 5 runs
**Root cause candidate:** `function_exported?/3` can return `false` when the target module is not yet loaded in the calling process's code cache. The module IS defined (compile-time @impl annotation would have caught a missing scope/2) but `function_exported?` checks loaded state, not definition. Fix: use `Code.ensure_loaded?(Mailglass.Tenancy.SingleTenant) and function_exported?(Mailglass.Tenancy.SingleTenant, :scope, 2)`.
**Scope:** Not touched by Plan 05 or Plan 06; pre-exists from Plan 04. Logging here rather than auto-fixing per SCOPE BOUNDARY rule.

## Postgrex type cache stale after migration_test down-then-up (found during 02-06 execution)

**Files:** `test/mailglass/migration_test.exs` (cause) + `test/mailglass/persistence_integration_test.exs` (symptom)
**Trigger:** The `drops all three tables + trigger + function + citext in reverse order` test in `migration_test.exs` runs `Ecto.Migrator.run(..., :down, all: true)` followed by `:up, all: true`. Dropping and recreating the `citext` extension gives it a fresh Postgres OID. Postgrex caches type info in (a) each worker-connection's local cache and (b) a shared `Postgrex.TypeServer` process keyed by `{module, key}` under `Postgrex.TypeManager`. Both caches retain the pre-drop OID. The first query that touches `mailglass_suppressions.address` (the only :citext column) through a poisoned worker surfaces as `(Postgrex.Error) ERROR XX000 (internal_error) cache lookup failed for type NNNNNN`.
**Current mitigation (Plan 06):**
- `config/test.exs` adds `disconnect_on_error_codes: [:internal_error]` — any worker that hits the cache-lookup error auto-disconnects; its next checkout reconnects with a fresh type bootstrap.
- `test/mailglass/persistence_integration_test.exs` adds a per-test `probe_until_clean/1` helper that issues a harmless citext query up to 5 times. Poisoned workers fail the probe (and disconnect via the above), clean workers succeed immediately; by the time the real test body runs the sandbox-owned worker is guaranteed clean.
**Residual issue:** Attempts to kill the shared `Postgrex.TypeServer` processes in either `migration_test`'s teardown or `persistence_integration_test`'s `setup_all` cascaded into `DBConnection.ConnectionError "awaited on another connection that failed to bootstrap types"` across unrelated tests (property test, other DataCase-using tests). The shared TypeServer is load-bearing; killing it while the pool has in-flight bootstrap attempts causes cascading failures.
**Candidate fixes (deferred, not Plan 06-scoped):**
1. Migrate `mailglass_suppressions.address` from `:citext` to `:text` + `LOWER(address)` indexes. Eliminates the extension dependency entirely. Trade-off: lose case-insensitive UNIQUE; would need a functional unique index. D-07 / D-09 compatible but a schema migration.
2. Replace migration_test's "down then up" with a narrower verification that doesn't drop the citext extension (e.g., drop and re-create only our three tables + trigger, leaving the extension intact).
3. Use `Ecto.Adapters.SQL.Sandbox.unboxed_run/2` in the persistence_integration_test so its connections bypass the polluted pool entirely.
4. Stop + restart the TestRepo via an ExUnit `on_exit(:suite)` callback after migration_test completes; adds ~1s to the suite but guarantees fresh connections.
**Why deferred:** The current mitigation makes `mix test --warnings-as-errors` green across 212 tests + 2 properties except for the pre-existing Plan 04 flake. Resolving this architecturally requires choosing one of the candidate fixes above, which is a Phase 6 cleanup concern (lint-time + CI hardening). Logged here for the Phase 6 planner to pick up alongside the LINT-03 / LINT-09 work.
