---
phase: 134-migration-entrypoint-raw-ddl-trigger-qualification
plan: 01
subsystem: migrations
tags: [schema-isolation, migration, postgres, ddl, MIGR-01, MIGR-02]
requires:
  - "132: Mailglass.Identifier validator + Config.schema/0 accessor"
  - "133: Mailglass.Repo facade prefix injection"
provides:
  - "Mailglass.Migration.up/down inject prefix: Config.schema() (Keyword.put_new)"
  - "Mailglass.Migrations.Postgres.maybe_create_schema/1 (CREATE SCHEMA, first up action)"
  - "Mailglass.Migrations.Postgres.maybe_drop_schema/1 (DROP SCHEMA ... RESTRICT at version 0)"
affects:
  - "134-02: raw-DDL/trigger qualification builds on the CREATE/DROP SCHEMA lifecycle"
  - "135: inbound mirrors this entrypoint pattern"
tech-stack:
  added: []
  patterns:
    - "Keyword.put_new for config-default-with-caller-override"
    - "Map.put_new create_schema computation honors explicit create_schema: false"
    - "inspect/1 double-quotes an already-Identifier-validated prefix at every interpolation site"
    - "RESTRICT (never CASCADE) on schema drop for data safety"
key-files:
  created: []
  modified:
    - lib/mailglass/migration.ex
    - lib/mailglass/migrations/postgres.ex
    - test/mailglass/migration_test.exs
decisions:
  - "[134-01] Migration.up/down are the MIGR-01 prefix-injection surface; migrated_version/1 stays untouched (its :repo-only injection + dispatcher's public default is correct for the read-only version query)."
  - "[134-01] maybe_drop_schema fires from change/3's :down branch guarded on Enum.min(range)-1 == 0 (full teardown to version 0), never on partial down-migrations."
  - "[134-01] The non-public-prefix round-trip test requires a SET LOCAL search_path CRUTCH (v01's trigger/function are still unqualified — 134-02's job); the test proves only the CREATE/DROP SCHEMA lifecycle 134-01 owns."
  - "[134-01] The down-side RESTRICT contract is proven via the exact DDL maybe_drop_schema emits (DROP SCHEMA IF EXISTS \"<prefix>\" RESTRICT), NOT by driving Mailglass.Migration.down/1 — the full v01 down runs an unqualified DROP EXTENSION citext (134-02-owned) that would corrupt the shared public.citext baseline mid-suite."
metrics:
  duration: "~13 min"
  completed: 2026-07-03
  tasks: 3
  files: 3
status: complete
---

# Phase 134 Plan 01: Migration Entrypoint Prefix Injection + CREATE/DROP SCHEMA Lifecycle Summary

Wired `Mailglass.Migration.up/down` to inject the runtime `prefix: Config.schema()` and made the Postgres dispatcher physically `CREATE SCHEMA IF NOT EXISTS` (first up action, gated on `create_schema: true` with a `create_schema: false` escape hatch) and `DROP SCHEMA ... RESTRICT` (only after a full teardown to version 0) — the layer that lets a non-`public` schema exist before the v01–v05 tables land in it and be torn down cleanly (MIGR-01, MIGR-02).

## What Was Built

- **MIGR-01 — entrypoint prefix injection.** `Mailglass.Migration.up/1` and `down/1` now `Keyword.put_new(opts, :prefix, Mailglass.Config.schema())` before dispatching. `Keyword.put_new` means an explicit caller `:prefix` (test harness, targeted adopter migration) still wins over the config default. `migrated_version/1` is unchanged.
- **MIGR-02 — CREATE/DROP SCHEMA lifecycle.** Added `maybe_create_schema/1` (first action of `up/1`, after `with_defaults/2`, before `migrated_version/1`) issuing `CREATE SCHEMA IF NOT EXISTS "<prefix>"` only when `create_schema: true`; and `maybe_drop_schema/1` called from `change/3`'s `:down` branch, guarded on the teardown reaching version 0, issuing `DROP SCHEMA IF EXISTS "<prefix>" RESTRICT`. `with_defaults/2`'s existing `create_schema: prefix != "public"` via `Map.put_new` means `public` never issues the DDL and an explicit `create_schema: false` (locked-down prod role) is honored. Prefix is re-validated via `validate_identifier!/2` before every new interpolation site (WR-01 chokepoint).
- **Regression proof.** New `describe` block in `migration_test.exs` proves: (1) `up` creates the `mailglass` schema + its three tables and re-up is a no-op; (2) `DROP SCHEMA RESTRICT` refuses a non-empty schema and succeeds once empty (data-safety, never CASCADE); (3) `create_schema: false` operates against a pre-existing operator-owned schema without issuing `CREATE SCHEMA`. Stable across seeds 0/7/42 and re-runnable.

## Key Links

- `Migration.up/down` → `Config.schema()` → `Keyword.put_new(:prefix)` → `Postgres.up/down`
- `Postgres.up/1` → `with_defaults/2` (computes `create_schema: prefix != "public"`) → `maybe_create_schema/1` → `CREATE SCHEMA`
- `Postgres.change/3 :down` → drops all tables → `record_version(target=0)` → `maybe_drop_schema/1` → `DROP SCHEMA ... RESTRICT`

## Deviations from Plan

### Auto-fixed / re-scoped issues

**1. [Rule 3 - Blocking] `Mailglass.Migration.up/down` require an `Ecto.Migration.Runner` context**
- **Found during:** Task 3
- **Issue:** The plan's `<behavior>` described calling `Mailglass.Migration.up(prefix: "mailglass", repo: TestRepo)` directly. That raises `RuntimeError: could not find migration runner process` because the dispatcher's `execute()`-based DDL needs an active runner.
- **Fix:** Drive up through `Ecto.Migrator.up/4` via inline wrapper migration modules (the same path adopters hit via `mix ecto.migrate`, matching the sibling `schema_isolation_integration_test.exs`).
- **Files:** `test/mailglass/migration_test.exs`
- **Commit:** `23e95459`

**2. [Rule 4 boundary - re-scoped] The full non-public-prefix down cannot be green at the 134-01 boundary; the down-side RESTRICT proof was surgically scoped**
- **Found during:** Task 3
- **Issue:** Driving `Mailglass.Migration.down/1` runs v01's **unqualified** raw DDL: `CREATE TRIGGER … ON mailglass_events` (no `CREATE TRIGGER IF NOT EXISTS` in Postgres → `42710 duplicate_object` against the coexisting `public.mailglass_events`) and `DROP EXTENSION IF EXISTS citext` (drops the shared `public.citext` the rest of the suite depends on → `2BP01`, and mid-suite OID staleness). Schema-qualifying v01's trigger/function/CHECKs + `down/0` drops (and removing the search_path crutch) is **explicitly Plan 134-02's load-bearing task** per the ROADMAP and the plan's own repeated notes.
- **Fix:** (a) The `up` round-trip test uses a documented `SET LOCAL search_path` crutch (like the sibling integration test) to prove the schema-create lifecycle. (b) The down-side RESTRICT contract is proven via the **exact DDL `maybe_drop_schema/1` emits** (`DROP SCHEMA IF EXISTS "<prefix>" RESTRICT`), NOT via `Mailglass.Migration.down/1` — proving MIGR-02's data-safety guarantee without invoking v01's 134-02-owned citext drop. (c) A baseline safety net re-creates `public.citext` in `on_exit`.
- **Rationale:** This honors the ROADMAP's 134-01/134-02 split (D-06 defers the search_path-free full round-trip + `citext`/trigger qualification to 134-02). All MIGR-01/02 deliverables (prefix injection, CREATE SCHEMA first-action gating, DROP SCHEMA RESTRICT-never-CASCADE, `create_schema: false` escape hatch) are proven.
- **Files:** `test/mailglass/migration_test.exs`
- **Commit:** `23e95459`

## Deferred Issues

Logged to `deferred-items.md` (out of scope — scope boundary):
- Pre-existing `mix format` drift in `test/mailglass/repo_test.exs` and `lib/mailglass/outbound.ex` (both last touched by Phase 133 commits, not by Phase 134). All Phase-134-modified files are format-clean.

Explicitly handed to Plan 134-02 (per ROADMAP, not a regression here):
- v01 events-immutability trigger + `mailglass_raise_immutability()` function are still `public`-hardcoded (unqualified `CREATE TRIGGER … ON mailglass_events`); v01/v03 CHECKs and all `down/0` drops likewise. Qualifying them (with `SET search_path=''` on the function) + removing the search_path crutch + guarding the shared-`citext` drop is 134-02's scope, including the load-bearing SQLSTATE 45A01 regression under `mailglass` with no search_path pin.

## Verification

- `mix test test/mailglass/migration_test.exs --warnings-as-errors` — 12 tests, 0 failures (includes the 3 new non-public-prefix tests); stable across seeds 0/7/42 and re-runnable.
- `mix compile --warnings-as-errors` — clean.
- `mix format --check-formatted` on the three modified files — clean.
- `mix credo --strict lib/mailglass/migration.ex lib/mailglass/migrations/postgres.ex` — no issues.
- Sibling `test/mailglass/schema_isolation_integration_test.exs` — 4 tests, 0 failures; baseline `public.citext` intact after runs (verified both directions).
- Manual reasoning: with `config/test.exs` pinning `:schema` to `"public"`, the default suite injects `prefix: "public"`, `create_schema` is false, and NO CREATE/DROP SCHEMA is issued — existing behavior byte-for-byte unchanged (the 9 pre-existing migration tests stay green).

## Self-Check: PASSED

- FOUND: lib/mailglass/migration.ex (modified)
- FOUND: lib/mailglass/migrations/postgres.ex (modified)
- FOUND: test/mailglass/migration_test.exs (modified)
- FOUND commit 0d0d70dc (feat 134-01 entrypoint prefix injection)
- FOUND commit 43e3c657 (feat 134-01 maybe_create_schema/maybe_drop_schema)
- FOUND commit 23e95459 (test 134-01 schema lifecycle regression)
