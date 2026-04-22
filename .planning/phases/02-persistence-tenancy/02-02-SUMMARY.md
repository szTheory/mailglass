---
phase: 02-persistence-tenancy
plan: 02
subsystem: persistence
tags: [migration, ddl, postgres, immutability, trigger, integration-test]

# Dependency graph
requires:
  - phase: 02-persistence-tenancy
    provides: "Mailglass.EventLedgerImmutableError, Mailglass.ConfigError (from Phase 1 + 02-01), Mailglass.Repo facade with SQLSTATE 45A01 translation active, Mailglass.TestRepo + DataCase + config/test.exs DB wiring"
provides:
  - "Mailglass.Migration public API (up/0, down/0, migrated_version/0) — the stable adopter-facing surface Phase 7's mix mailglass.gen.migration will emit wrappers against"
  - "Mailglass.Migrations.Postgres version dispatcher (Oban-style pg_class comment tracking on mailglass_events table)"
  - "Mailglass.Migrations.Postgres.V01 — the full Phase 2 DDL: three tables (mailglass_deliveries, mailglass_events, mailglass_suppressions), citext extension, mailglass_raise_immutability() plpgsql function, BEFORE UPDATE OR DELETE trigger raising SQLSTATE 45A01, 11 indexes, mailglass_suppressions_stream_scope_check CHECK constraint"
  - "priv/repo/migrations/00000000000001_mailglass_init.exs — synthetic test migration (8-line adopter-facing wrapper shape) run by test_helper.exs at suite start"
  - "test/test_helper.exs runs Ecto.Migrator.with_repo + start_link on Mailglass.TestRepo so every mix test run lands the Phase 2 schema"
  - "End-to-end SQLSTATE 45A01 translation chain is integration-tested against the live trigger (trigger → %Postgrex.Error{} → Mailglass.Repo → Mailglass.EventLedgerImmutableError)"
affects: [02-persistence-tenancy plans 03-06, 03-outbound-send, 04-webhook-ingest, 05-admin-liveview]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Oban-style version-tracking via `pg_catalog.obj_description` on a COMMENT ON TABLE — version marker lives on mailglass_events (the append-only ledger is the architecturally load-bearing table; the deliveries table is a projection)"
    - "8-line synthetic test migration runs the exact Mailglass.Migration.up/0 adopters hit via mix ecto.migrate — zero test-only DDL fork"
    - "Ecto.Adapters.SQL.Sandbox.mode(:auto) for DDL-issuing integration tests, revert to :manual on_exit — DDL cannot roll back in the sandbox transactional wrapper so ownership tracking is disabled for the test's lifetime only"
    - "Explicit repo injection in Mailglass.Migration.migrated_version/0 — callable outside an Ecto.Migrator runner context by passing :repo through opts to the dispatcher"
    - "Partial unique index `where:` clause fragments match the Ecto conflict_target fragments character-for-character (Pitfall 1 — Plan 05 Events writer consumes `(idempotency_key) WHERE idempotency_key IS NOT NULL` verbatim)"

key-files:
  created:
    - "lib/mailglass/migration.ex — public API: up/0, down/0, migrated_version/0 + Postgres adapter dispatcher (61 lines)"
    - "lib/mailglass/migrations/postgres.ex — version dispatcher with pg_class COMMENT version tracking (99 lines)"
    - "lib/mailglass/migrations/postgres/v01.ex — Phase 2 DDL: 3 tables + 11 indexes + trigger function + trigger + CHECK (207 lines)"
    - "priv/repo/migrations/00000000000001_mailglass_init.exs — 8-line synthetic test migration"
    - "test/mailglass/migration_test.exs — up/down round-trip, version tracking, idempotency, DDL artifact verification (186 lines)"
    - "test/mailglass/events_immutability_test.exs — SQLSTATE 45A01 translation chain integration test (79 lines)"
  modified:
    - "test/test_helper.exs — runs Ecto.Migrator.with_repo + start_link(TestRepo) + Sandbox.mode(:manual)"

key-decisions:
  - "Mailglass.Migration.migrated_version/0 resolves and injects the configured Repo explicitly before dispatching, making it safe to call outside an Ecto.Migrator runner context. up/0 and down/0 still rely on being called from within a migration runner (via the 8-line wrapper + Ecto.Migrator), matching the adopter contract exactly."
  - "Migration tests use Ecto.Adapters.SQL.Sandbox.mode(:auto) in setup, flipping back to :manual on_exit. DDL (CREATE TABLE, DROP, CREATE TRIGGER, COMMENT ON TABLE) cannot roll back inside the sandbox transactional wrapper, so ownership tracking is disabled for these tests' lifetime only. DataCase-using tests in the same run remain isolated under :manual."
  - "Synthetic test migration at priv/repo/migrations/00000000000001_mailglass_init.exs is the 8-line wrapper adopters will get from mix mailglass.gen.migration (Phase 7 D-36/D-37). test_helper.exs runs it through Ecto.Migrator.with_repo, then explicitly start_links the TestRepo (with_repo stops the repo it started) so tests can check out connections."
  - "Partial unique index on mailglass_events.idempotency_key uses WHERE idempotency_key IS NOT NULL — character-for-character match required with the conflict_target fragment the Plan 05 Events writer will use. Any change to either site requires coordinated changes in both."
  - "UUIDv7 PK declared as `add :id, :uuid, primary_key: true` in the migration (not an Ecto auto-assigned type). The Mailglass.Schema macro from Plan 01 stamps UUIDv7 as the autogenerate source at the schema layer; the migration just declares the SQL column type."

patterns-established:
  - "Pattern 1 — Oban-style public migration API: Mailglass.Migration.{up,down,migrated_version}/1 with adapter-dispatched implementation. Postgres only at v0.1 per PROJECT.md; non-Postgres adapters raise ConfigError :invalid with an actionable context."
  - "Pattern 2 — pg_class COMMENT version marker on the architecturally-central table. mailglass_events is the chosen target because (a) it is append-only and therefore never dropped mid-lifecycle, (b) it's the load-bearing architectural invariant and so its existence implies the whole schema has been migrated. Oban's equivalent is oban_jobs."
  - "Pattern 3 — Synthetic test migration via Ecto.Migrator.with_repo + Ecto.Migrator.run/4 in test_helper.exs. Matches the exact code path adopters hit; the module-redefinition warning when with_repo re-loads the same .exs file during the 'idempotency' / 'down then up' tests is expected and harmless (emitted by the Elixir runtime loader, not the compiler)."
  - "Pattern 4 — DDL integration tests use Sandbox.mode(:auto) in setup, revert to :manual on_exit. This keeps DataCase-based tests in the same run isolated while allowing migration DDL (non-transactional) to execute against the real DB. Applied in test/mailglass/migration_test.exs."

requirements-completed: [PERSIST-01, PERSIST-02, PERSIST-03, PERSIST-04, PERSIST-06, TENANT-01]

# Metrics
duration: 39min
completed: 2026-04-22
---

# Phase 02 Plan 02: Migration DDL + SQLSTATE 45A01 Translation Proof Summary

**Mailglass.Migration public API + Oban-pattern Postgres dispatcher + V01 ships the full Phase 2 DDL (3 tables, citext extension, plpgsql immutability trigger, stream/scope CHECK, 11 indexes). Synthetic 8-line test migration + test_helper.exs wiring means mix test boots against the same schema adopters get. Two integration tests prove the end-to-end SQLSTATE 45A01 translation chain: live trigger → %Postgrex.Error{} → Mailglass.Repo → Mailglass.EventLedgerImmutableError. Phase 2 ROADMAP success criterion 1 is now demonstrably satisfied.**

## Performance

- **Duration:** 39 min
- **Started:** 2026-04-22T18:04:30Z (right after 02-01 completed)
- **Completed:** 2026-04-22T18:43:19Z
- **Tasks:** 2
- **Files created:** 6
- **Files modified:** 1

## Accomplishments

- `Mailglass.Migration.{up,down,migrated_version}/1` is the stable public API — the 8-line adopter wrapper pattern Phase 7's `mix mailglass.gen.migration` will emit against. Postgres-only at v0.1; non-Postgres repo raises `Mailglass.ConfigError.new(:invalid, context: %{adapter: other, reason: "Postgres only at v0.1"})`.
- `Mailglass.Migrations.Postgres` dispatcher tracks version in `pg_class` COMMENT on `mailglass_events`. `migrated_version/1` runs a single `pg_catalog.obj_description` query and returns an integer — safe to call outside an Ecto.Migrator runner.
- `Mailglass.Migrations.Postgres.V01` is the per-version DDL module. Ordering follows the landmine guidance from 02-RESEARCH §L2: citext extension first, then three tables + their indexes, then the trigger function, then the trigger, then the suppressions CHECK constraint + indexes. Every `execute` with a rollback inverse uses the two-arg form so `down/1` is exact.
- `mailglass_events_idempotency_key_idx` uses the `WHERE idempotency_key IS NOT NULL` predicate verbatim — this is the string Plan 05's `Events.append` will pass as `conflict_target: {:unsafe_fragment, ...}`.
- `mailglass_suppressions_stream_scope_check` is the DB-level D-07 invariant: scope=address_stream implies stream NOT NULL; scope in (address, domain) implies stream IS NULL. Belt-and-suspenders with Plan 03's changeset-level `validate_scope_stream_coupling/1`.
- `priv/repo/migrations/00000000000001_mailglass_init.exs` is the 8-line synthetic test migration. `test_helper.exs` runs it via `Ecto.Migrator.with_repo(TestRepo, fn repo -> Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false) end)` + explicit `start_link` (with_repo stops the repo it started) + `Sandbox.mode(:manual)`.
- `test/mailglass/migration_test.exs` (8 tests): table creation, trigger installed, pg_class version marker seeded to 1, idempotency (rerun is a no-op), all four `mailglass_events` indexes present, CHECK constraint present, citext extension installed, full down + re-up round-trip with version-counter reset to 0.
- `test/mailglass/events_immutability_test.exs` (3 tests): UPDATE raises `EventLedgerImmutableError` through `Mailglass.Repo.transact/1`, DELETE does the same, the translated error carries `pg_code: "45A01"` and a `:type in [:update_attempt, :delete_attempt]`.
- Full `mix test --warnings-as-errors` suite: **106 tests, 0 failures, 1 skipped** (the pre-existing compile-time accessibility check property test).
- `mix credo --strict`: no new warnings introduced; all 7 software design suggestions + 1 code readability issue are pre-existing from Plans 01-01 through 02-01.

## Task Commits

1. **Task 1: Migration public API + Postgres dispatcher + V01 DDL + synthetic test migration** — `627b925` (feat)
2. **Task 2: test_helper migration runner + migration integration test + SQLSTATE 45A01 integration test** — `0e7a6b8` (feat)

## Files Created/Modified

**Created (6):**
- `lib/mailglass/migration.ex` — 61 lines
- `lib/mailglass/migrations/postgres.ex` — 99 lines
- `lib/mailglass/migrations/postgres/v01.ex` — 207 lines
- `priv/repo/migrations/00000000000001_mailglass_init.exs` — 7 lines
- `test/mailglass/migration_test.exs` — 186 lines
- `test/mailglass/events_immutability_test.exs` — 79 lines

**Modified (1):**
- `test/test_helper.exs` — added 19 lines for Ecto.Migrator.with_repo + start_link + Sandbox.mode(:manual)

## Decisions Made

- **Explicit repo injection in `migrated_version/0`:** The dispatcher's `migrated_version/1` uses `Map.get_lazy(opts, :repo, fn -> repo() end)`; `repo()` comes from `use Ecto.Migration` and only works inside an Ecto.Migrator runner. The public API `Mailglass.Migration.migrated_version/0` calls it from arbitrary contexts (tests, Phase 6 lint checks), so we inject the Repo explicitly before dispatching. `up/0` and `down/0` remain runner-bound — they're called from the 8-line adopter wrapper, not directly.
- **Sandbox mode flip for DDL tests:** Migration tests use `Sandbox.mode(:auto)` in setup, `:manual` on_exit. DDL (CREATE TABLE, DROP TABLE, CREATE TRIGGER, COMMENT ON TABLE) is non-transactional in Postgres and cannot roll back inside the sandbox transactional wrapper. `:auto` mode disables ownership tracking so every process (including the `Ecto.Migrator.with_repo` subprocess) checks out connections on demand. DataCase tests in the same run remain isolated because `on_exit` restores `:manual`.
- **Synthetic migration drives test_helper:** The synthetic `00000000000001_mailglass_init.exs` is the identical 8-line wrapper shape Phase 7's `mix mailglass.gen.migration` will emit for adopters. Running it through `Ecto.Migrator.with_repo` + `Ecto.Migrator.run/4` means the test suite exercises the same migration code path adopters hit via `mix ecto.migrate` — zero test-only DDL fork (D-37).
- **pg_class comment on mailglass_events, not deliveries:** The version marker lives on the events table because (a) it's append-only and never dropped mid-lifecycle, (b) it's the architecturally load-bearing invariant (the append-only ledger is the whole point of Phase 2). Deliveries are mutable projections; using them as the version anchor would couple schema evolution to projection shape.
- **UUIDv7 at schema layer, :uuid at migration layer:** The `Mailglass.Schema` macro from Plan 01 stamps `{:id, UUIDv7, autogenerate: true}` as the Ecto-side autogenerator. The migration uses `add :id, :uuid, primary_key: true` — the SQL column type is the native Postgres `uuid`, and the UUIDv7-specific generation happens at the Elixir layer. When Postgres 18 lands `uuidv7()` natively, adopters change to `default: fragment("uuidv7()")` without a schema change (D-27).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] Added explicit :repo injection to `Mailglass.Migration.migrated_version/0`**

- **Found during:** Task 2 test run
- **Issue:** The dispatcher's `migrated_version/1` (Oban-verbatim pattern) calls `Map.get_lazy(opts, :repo, fn -> repo() end)`. The `repo()` helper comes from `use Ecto.Migration` and only works inside an Ecto.Migrator runner process. Calling `Mailglass.Migration.migrated_version()` directly (as the test asserts in `test "seeds the pg_class comment version marker to 1"`) triggered `(RuntimeError) could not find migration runner process for #PID<...>`.
- **Fix:** Mailglass.Migration.migrated_version/0 now does `Keyword.put_new(opts, :repo, resolve_repo())` before dispatching. The adapter-side `Map.get_lazy` fallback is preserved for in-runner callers.
- **Files modified:** `lib/mailglass/migration.ex`
- **Committed in:** `0e7a6b8` (Task 2)

**2. [Rule 3 — Blocking] Sandbox mode for migration test setup**

- **Found during:** Task 2 test run
- **Issue:** `config/test.exs` configures `pool: Ecto.Adapters.SQL.Sandbox` with `mode :manual`. In `:manual` mode every process must check out explicitly. `Ecto.Migrator.with_repo/2` spawns a subprocess to run migrations, which has no owner and cannot acquire a connection. Tried `{:shared, self()}` first — failed because ExUnit's `on_exit` callback runs in a different process, so the shared owner is already dead by then.
- **Fix:** `setup` does `Sandbox.mode(TestRepo, :auto)` (no ownership tracking for these tests' lifetime) and `on_exit` reverts to `:manual` so DataCase tests in the same run remain isolated. This is only safe because migration tests don't share data with schema-aware tests.
- **Files modified:** `test/mailglass/migration_test.exs`
- **Committed in:** `0e7a6b8` (Task 2)

**Total deviations:** 2 auto-fixed (both blocking — neither was architectural)
**Impact on plan:** Both were operational issues in test plumbing, not architectural changes. The migration code itself lands exactly as the plan specified; the sandbox and repo-injection fixes are testing-infrastructure adjustments. Plans 03-06 that consume this migration machinery are unaffected.

## Issues Encountered

None beyond the two deviations above. The DDL itself landed verbatim from the plan's `<ddl_reference>` block — no reordering, no omitted columns.

One module-redefinition runtime warning is emitted when the `idempotency` and `down/0` tests re-run `Ecto.Migrator.with_repo`, which reloads `priv/repo/migrations/00000000000001_mailglass_init.exs`. This is a harmless warning from the Elixir loader (not the compiler), does not fail `--warnings-as-errors`, and doesn't affect test correctness. Suppressing it would require either moving the synthetic migration out of the test suite's compile path (undesirable — we want adopter-fidelity) or wrapping the Migrator calls in a guard that doesn't re-load the file (not possible with the public Ecto.Migrator API).

## Downstream Landmines Flagged for Future Plans

- **Plan 02-03 (Ecto schemas):** The `Event` schema's default for `inserted_at` should NOT be set in the changeset — the migration has `default: fragment("now()")` at the DB layer, and Ecto will issue the column back on INSERT via `read_after_writes: true`. Don't double up.
- **Plan 02-03:** `Suppression.Entry` schema's `:address` field maps to a `citext` column. The Ecto type is still `:string`; defense-in-depth is a `downcase_address/1` changeset step (plan 03) on top of citext's case-insensitive comparison.
- **Plan 02-04:** DataCase needs no migration changes — the schema already exists when tests boot. The `Mailglass.Tenancy.put_current/1` refactor still only flips the `Process.put(:mailglass_tenant_id, ...)` line in DataCase's setup.
- **Plan 02-05 (Events.append):** The `conflict_target` fragment MUST be `"(idempotency_key) WHERE idempotency_key IS NOT NULL"` — character-for-character match with `mailglass_events_idempotency_key_idx`. Any divergence breaks the partial-index match and Postgres falls back to full table lock.
- **Plan 02-06 (SuppressionStore.Ecto):** The `record/1` upsert target is `mailglass_suppressions_tenant_address_scope_idx` — conflict_target is `{:unsafe_fragment, "(tenant_id, address, scope, COALESCE(stream, ''))"}`. The `COALESCE(stream, '')` string must match the migration's index definition exactly.
- **Plans 03-06 in general:** The mailglass_events table is append-only at the DB level. Any test or code path that tries `Repo.update(event)` or `Repo.delete(event)` will raise `EventLedgerImmutableError`. This is a feature, not a bug — code reviewers should treat such call sites as Rule 1 auto-fix candidates (bug in the calling code).

## Threat Surface Scan

No new security-relevant surface introduced that isn't documented in the plan's `<threat_model>`. All T-02-02 (tampering — immutability trigger), T-02-02b (raw SQL bypass — tested at DB level), T-02-04 (replay amplification — idempotency partial unique), T-02-05 (info disclosure — tenant-leading unique index), T-02-06 (case-normalization — citext), T-02-07 (accepted — citext extension dropped in down/0) dispositions all hold as documented.

## Next Plan Readiness

- `mix compile --warnings-as-errors` passes.
- `mix compile --no-optional-deps --warnings-as-errors` passes.
- `mix test --warnings-as-errors` passes (106 tests, 0 failures, 1 skipped).
- `mix credo --strict` introduces no new warnings.
- The live `mailglass_events_immutable_trigger` has been exercised in CI-style integration tests — Phase 2 ROADMAP success criterion 1 is satisfied.
- Plan 02-03 (Ecto schemas) is unblocked — schemas now target a live DB with the DDL in place.

## Self-Check: PASSED

All 6 created files exist on disk:
- `lib/mailglass/migration.ex`
- `lib/mailglass/migrations/postgres.ex`
- `lib/mailglass/migrations/postgres/v01.ex`
- `priv/repo/migrations/00000000000001_mailglass_init.exs`
- `test/mailglass/migration_test.exs`
- `test/mailglass/events_immutability_test.exs`

All 2 task commits present in `git log --oneline`:
- `627b925` (Task 1 feat)
- `0e7a6b8` (Task 2 feat)

---
*Phase: 02-persistence-tenancy*
*Completed: 2026-04-22*
