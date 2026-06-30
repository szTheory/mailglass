---
phase: quick-260630-f1i
plan: 01
subsystem: migrations
tags: [postgres, migrations, idempotency, deliveries, adopter-path, reproduce-first]
status: complete
requires:
  - lib/mailglass/migrations/postgres.ex (dispatcher + @current_version)
  - lib/mailglass/outbound.ex (conflict_target fragment)
  - lib/mailglass/outbound/delivery.ex (runtime schema)
provides:
  - lib/mailglass/migrations/postgres/v05.ex (deliveries idempotency DDL)
  - shipped-adopter-path migration regression test
affects:
  - adopters running Mailglass.Migration.up() (now get the idempotency columns + index)
  - next release ceremony (owes a 1.10.2 linked core+admin bump + paired inbound)
tech-stack:
  added: []
  patterns:
    - "Vnn dispatcher version step adds deliveries idempotency DDL (was a standalone TestRepo-only migration)"
    - "single-source-of-truth: TestRepo flat-file path delegates to / is covered by the shipped V-step, not a parallel definition"
key-files:
  created:
    - lib/mailglass/migrations/postgres/v05.ex
    - test/mailglass/shipped_migration_divergence_test.exs
  modified:
    - lib/mailglass/migrations/postgres.ex
    - priv/repo/migrations/00000000000002_add_idempotency_key_to_deliveries.exs
    - test/mailglass/migration_test.exs
decisions:
  - "00000000000002 reconciled to an inert no-op (not a V05.up delegation): the init wrapper 00000000000001 -> Mailglass.Migration.up/0 now reaches V05, so re-applying V05 in 00000000000002 would raise duplicate_column. The DDL has exactly one definition (V05) exercised by both paths — divergence is structurally impossible."
  - "Test exercises the genuine adopter path: an inline 8-line wrapper migration (mirroring mix mailglass.gen.migration output) driven through Ecto.Migrator, which stands up the Ecto.Migration runner that Mailglass.Migration.up/1 requires."
metrics:
  duration: ~25 min
  completed: 2026-06-30
  tasks: 3
  files: 5
---

# Phase quick-260630-f1i: Fix shipped migration deliveries divergence (add V05) Summary

Fixed a live adopter-facing correctness bug: the shipped Postgres migration dispatcher (`Mailglass.Migration.up()`, formerly `@current_version 4`) created `mailglass_deliveries` WITHOUT the `idempotency_key` / `status` / `last_error` columns and the deliveries idempotency partial unique index that the runtime (`delivery.ex:112-122`, `outbound.ex` upsert) requires. CI was green only because the internal TestRepo applied a standalone `00000000000002` migration adding those columns — a path adopters never run. A new V05 dispatcher step closes the gap, a reproduce-first test guards it, and the TestRepo path is reconciled onto the single V05 source.

## Reproduce-First Evidence (RED → GREEN)

**RED** (test committed at `4979c416`, run against `@current_version 4` with no V05):

```
4 tests, 4 failures
```

Representative failing assertions (all four prove the adopter-path divergence):
- `shipped dispatcher must create mailglass_deliveries.idempotency_key (runtime delivery.ex:112 + Outbound upsert require it)` — column absent.
- `shipped dispatcher must create mailglass_deliveries.status` — column absent.
- `shipped dispatcher must create mailglass_deliveries_idempotency_key_unique_idx` — partial unique index absent.
- Upsert round-trip: `(Postgrex.Error) ERROR 42703 ... column "idempotency_key" of relation "mailglass_deliveries" does not exist` on the first INSERT supplying the non-null deliveries columns.

**GREEN** (after V05 lands at `3ab6316a`, `@current_version 5`):

```
$ mix test test/mailglass/shipped_migration_divergence_test.exs --seed 0
....
Finished in 0.1 seconds
4 tests, 0 failures
```

Combined final gate (both suites, deterministic seed 0):

```
$ mix test test/mailglass/shipped_migration_divergence_test.exs test/mailglass/migration_test.exs --seed 0
Finished in 0.2 seconds
13 tests, 0 failures
```

`mix compile --warnings-as-errors` passes clean.

## What Changed

### Task 1 — RED adopter-path divergence test (`4979c416`, harness fix `0aa95981`)
`test/mailglass/shipped_migration_divergence_test.exs`. Drives the SHIPPED `Mailglass.Migration.up/1` dispatcher (via an inline wrapper migration through `Ecto.Migrator`, the genuine adopter path) against an isolated `mailglass_shipped_path_test` schema, asserting the three deliveries columns, the partial unique index `where`-clause (`idempotency_key IS NOT NULL`), and an idempotent `ON CONFLICT (idempotency_key) WHERE idempotency_key IS NOT NULL DO NOTHING` round-trip (the exact `outbound.ex` fragment). Tagged `@moduletag :shipped_migration_divergence`. Sandbox flips to `:auto` in setup with an `on_exit` revert to `:manual`.

Two test-harness adaptations were required because the plan's assumptions did not match the actual dispatcher code (documented as deviations below): the dispatcher does NOT itself issue `CREATE SCHEMA`, and the V01 events trigger is created with a bare (non-prefix-qualified) `ON mailglass_events`. The fix: create the isolated schema in setup and pin `search_path` to `<prefix>, public` for the migration so the trigger binds to the test schema's table while `citext` still resolves from `public`. A unique migration version per setup avoids `Ecto.Migrator`'s `:already_up` skip; the row is deleted in `on_exit` so no `schema_migrations` residue leaks.

### Task 2 — GREEN: V05 + version bump (`3ab6316a`)
- `lib/mailglass/migrations/postgres/v05.ex`: `alter table(:mailglass_deliveries, prefix: prefix)` adding `idempotency_key :text`, `status :string null:false default:"queued"`, `last_error :map` (mirrors the TestRepo `00000000000002` DDL char-for-char), then the partial unique index `mailglass_deliveries_idempotency_key_unique_idx` with `where: "idempotency_key IS NOT NULL"` — char-for-char with `outbound.ex`'s conflict_target. `prefix: prefix` threaded on every table/index op; `down/1` drops the index then removes the three columns in reverse. Append-only events trigger untouched; no PII.
- `lib/mailglass/migrations/postgres.ex`: `@current_version 4 → 5`.

### Task 3 — Reconcile TestRepo path + version markers (`544539d3`)
- `priv/repo/migrations/00000000000002_add_idempotency_key_to_deliveries.exs`: reconciled to an inert no-op (`up, do: :ok` / `down, do: :ok`) with a documenting moduledoc. The deliveries idempotency DDL is now owned solely by V05, which the init wrapper (`00000000000001` → `Mailglass.Migration.up/0`, now reaching `@current_version 5`) applies. This makes the TestRepo path and the adopter dispatcher path apply identical DDL.
- `test/mailglass/migration_test.exs`: stale assertion updated — `current version exposes V05 through the dispatcher` asserting `== 5`. Version-marker assertions comparing to `current_version()` were left untouched (they self-adjust).

## Deviations from Plan

**1. [Rule 1 - Bug] Dispatcher does not auto-create the schema**
- **Found during:** Task 1.
- **Issue:** The plan stated `Mailglass.Migration.up(prefix: PREFIX)` auto-creates the schema because `with_defaults/2` sets `create_schema: prefix != "public"`. In the actual code, `create_schema` is computed in the opts map but never acted on — nothing in `postgres.ex` issues `CREATE SCHEMA`. The dispatcher also requires an active `Ecto.Migration` runner (it issues `create`/`execute`), so a bare `Migration.up/1` call from a plain test process raises `could not find migration runner process`.
- **Fix:** Drive the dispatcher through an inline wrapper migration via `Ecto.Migrator` (the genuine adopter path), and create the isolated schema explicitly in setup.

**2. [Rule 3 - Blocking] V01 events trigger is not prefix-qualified**
- **Found during:** Task 1.
- **Issue:** V01 creates the immutability trigger with a bare `CREATE TRIGGER ... ON mailglass_events` (not prefix-qualified). Run with a test prefix it collides with the already-migrated `public` trigger (`42710 duplicate_object`), and `mailglass_suppressions.address :citext` needs the `citext` type which lives in `public`.
- **Fix:** Pin the migration connection `search_path` to `<prefix>, public` so the trigger binds to the test schema's table while `citext` resolves from `public`. The events trigger DDL itself was NOT modified (out of scope per CLAUDE.md + threat T-f1i-03).

**3. [Plan adaptation] `00000000000002` is a no-op, not a `V05.up([])` delegation**
- **Found during:** Task 3.
- **Issue:** The plan recommended `00000000000002` delegate `up, do: V05.up([])`. But the init wrapper (`00000000000001` → `Mailglass.Migration.up/0`) now dispatches through V05 (since `@current_version` is 5), so a second `V05.up` in `00000000000002` double-applies → `42701 duplicate_column`.
- **Fix:** Reconciled to an inert documented no-op. This still achieves the plan's single-source-of-truth intent — exactly one definition of the deliveries idempotency DDL (V05), applied by the dispatcher and exercised identically by both paths.

## Threat Mitigations Verified
- **T-f1i-01** (where-clause vs conflict_target): V05 index `where` is exactly `idempotency_key IS NOT NULL`; the test's upsert round-trip exercises the match at runtime (GREEN), not by inspection.
- **T-f1i-02** (adopter `:prefix` reaching DDL): V05 threads `prefix: prefix` through Ecto's parameterized `prefix:` option; the dispatcher's `validate_identifier!/2` regex-guards the prefix. No raw interpolation added in V05.
- **T-f1i-03** (events trigger): V05 touches only `mailglass_deliveries`; the append-only immutability trigger/function are untouched.

## Release Note (owed, NOT cut here)
Per CLAUDE.md release conventions, versions are bumped by Release Please's linked-versions plugin at the release ceremony, NOT by hand. `mix.exs @version` remains `1.10.1` across core/admin with inbound pins `== 1.10.1`. This fix owes a **1.10.2 linked core+admin bump + a paired `mailglass_inbound` bump** (D-13 exact-pin) at the next release cut. No `mix.exs`/inbound-pin edits were made and nothing was published to Hex.

## Self-Check: PASSED
- `lib/mailglass/migrations/postgres/v05.ex` — FOUND
- `test/mailglass/shipped_migration_divergence_test.exs` — FOUND
- Commits `4979c416`, `3ab6316a`, `544539d3`, `0aa95981` — FOUND in `git log`
- Both targeted suites green (13 tests, 0 failures); `mix compile --warnings-as-errors` clean.
