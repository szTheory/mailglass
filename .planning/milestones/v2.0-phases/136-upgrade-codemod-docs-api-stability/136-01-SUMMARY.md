---
phase: 136-upgrade-codemod-docs-api-stability
plan: 01
subsystem: upgrade-codemod
tags: [migration, mix-task, schema-isolation, ddl, upgrade-path]
status: complete
requires: []
provides:
  - "mix mailglass.upgrade.v2_schema"
  - "Mix.Tasks.Mailglass.Upgrade.V2Schema.migration_body/2"
affects:
  - "adopter upgrade path to 2.0 schema isolation"
tech-stack:
  added: []
  patterns:
    - "plain use Mix.Task file-emitter (mirrors mailglass.gen.migration; no Igniter, no compile guard)"
    - "byte-parity DDL transcription from the shipped fresh-install v01 trigger/function"
    - "async: false / :schema_isolation DDL test with baseline-restore on_exit"
key-files:
  created:
    - lib/mix/tasks/mailglass.upgrade.v2_schema.ex
    - test/mailglass/upgrade_v2_schema_generation_test.exs
    - test/mailglass/upgrade_v2_schema_migration_test.exs
  modified: []
key-decisions:
  - "Unrolled the four ALTER TABLE ... SET SCHEMA statements explicitly (not a for-comprehension) so the emitted body is greppable AND the down direction registers correctly with the Ecto migration runner."
  - "Emitted down/0 drops the emptied mailglass schema (RESTRICT, IF EXISTS) so a reversed DB is byte-indistinguishable from a never-moved 1.x install."
  - "Emitted up/0 re-asserts the version-marker COMMENT after the move (A2 defense-in-depth) reading current_version/0 at generation time (A1: never hard-codes '5')."
  - "Used ~s|...| delimiters for the DROP FUNCTION ... immutability() lines (the () inside the SQL breaks ~s(...) paren-balancing)."
requirements-completed:
  - UPG-01
  - UPG-04
coverage:
  - deliverable: "mix mailglass.upgrade.v2_schema emits a compilable, idempotent Route B move migration (four ALTER ... SET SCHEMA under SET LOCAL lock_timeout, byte-parity 45A01 trigger/function, working down/0)"
    verification:
      - kind: test
        ref: "test/mailglass/upgrade_v2_schema_generation_test.exs#migration_body/2 (UPG-01 emitter — content contract)"
        status: pass
    human_judgment: false
  - deliverable: "Generated migration, applied over a 1.x public seed, moves all four tables to mailglass.*, 45A01 fires under the moved schema with NO search_path pin, version comment + citext survive, down reverses to public and drops the schema"
    verification:
      - kind: test
        ref: "test/mailglass/upgrade_v2_schema_migration_test.exs#UPG-04: generated move migration relocates the 1.x public install to mailglass.*"
        status: pass
    human_judgment: false
  - deliverable: "Emitter produces a compilable MailglassReferenceHost.Repo.Migrations.MoveMailglassToSchema from the frozen baseline's app module without touching host_app pins/locks"
    verification:
      - kind: test
        ref: "test/mailglass/upgrade_v2_schema_generation_test.exs#UPG-04: emitter produces a valid migration for reference/host_app's app module"
        status: pass
    human_judgment: false
duration: 6 min
completed: 2026-07-03
---

# Phase 136 Plan 01: Upgrade codemod (mix mailglass.upgrade.v2_schema) Summary

Ships `mix mailglass.upgrade.v2_schema` — a plain `use Mix.Task` file-emitter that writes a Route B `MoveMailglassToSchema` migration relocating mailglass's four core tables from `public` into the `mailglass` schema, with byte-parity 45A01 trigger/function recreation so a moved DB is indistinguishable from a fresh-installed one, plus an end-to-end proof over a 1.x `public` seed.

## Accomplishments

- **`Mix.Tasks.Mailglass.Upgrade.V2Schema`** (`lib/mix/tasks/mailglass.upgrade.v2_schema.ex`): plain `use Boundary` + `use Mix.Task` (no Igniter, no compile guard → `--no-optional-deps --warnings-as-errors` stays green). `run/1` parses a strict `--schema` allowlist (default `"mailglass"`, validated via `Mailglass.Identifier.validate!/2` before interpolation), discovers the adopter app module by regex over `mix.exs`, and writes `#{timestamp}_move_mailglass_to_schema.exs` — idempotent via a wildcard (`unchanged <path>` on re-run). `migration_body/2` is exposed as a testable entrypoint.
- **Emitted migration `up/0`**: `SET LOCAL lock_timeout = '5s'` → `CREATE SCHEMA IF NOT EXISTS` → four explicit `ALTER TABLE public.<t> SET SCHEMA` → drop+recreate the immutability function/trigger schema-qualified (byte-parity with `v01.ex:136-159`: `SET search_path = ''`, `RAISE SQLSTATE '45A01'`, `BEFORE UPDATE OR DELETE`, `FOR EACH ROW EXECUTE FUNCTION`) → re-assert the version-marker `COMMENT` (dynamic `current_version/0`). No `@disable_ddl_transaction`, no citext.
- **Emitted migration `down/0`**: reverses the move (tables back to `public`, `public`-qualified function/trigger restored, version comment re-asserted) and drops the emptied `mailglass` schema (RESTRICT / IF EXISTS).
- **`upgrade_v2_schema_generation_test.exs`** (14 tests): asserts the emitted body compiles, uses the discovered app module, contains all four moves, `SET LOCAL lock_timeout`, `CREATE SCHEMA`, the byte-parity 45A01/search_path markers, both `up`/`down`, no `@disable_ddl_transaction`, no citext; plus the idempotent-wildcard filesystem run; plus a `reference/host_app`-app-module describe block proving a compilable `MailglassReferenceHost.Repo.Migrations.MoveMailglassToSchema` (UPG-04, no pin bump).
- **`upgrade_v2_schema_migration_test.exs`** (integration, DDL): seeds the 1.x `public` install via `Mailglass.Migration.up(prefix: "public")`, applies the EMITTED move bytes through `Ecto.Migrator`, then asserts all four tables live under `mailglass.*`, `public` is empty of mailglass tables, UPDATE/DELETE raise 45A01 under the moved schema with no path pin, the version comment survived (read dynamically), a mixed-case citext address resolves, and `down` reverses to `public` with the schema gone.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Emitted `for`-comprehension ALTER loop broke the down direction and grep assertions**
- **Found during:** Task 2
- **Issue:** The research SQL used `for t <- @tables, do: execute(...)` for the four table moves. The comprehension's `execute` calls did not register correctly with the Ecto migration runner in the `down` direction (down left tables un-moved), and the loop meant the literal `ALTER TABLE public.<t> SET SCHEMA` strings never appeared in the emitted source (breaking the greppable content contract in the emitter test).
- **Fix:** Unrolled both directions into four explicit `execute ~s(ALTER TABLE ... SET SCHEMA ...)` statements.
- **Files modified:** lib/mix/tasks/mailglass.upgrade.v2_schema.ex
- **Verification:** both test files GREEN
- **Commit:** ffeb84ed

**2. [Rule 3 - Blocker] `~s(...)` paren-balancing broke on `mailglass_raise_immutability()`**
- **Found during:** Task 2
- **Issue:** `execute ~s(DROP FUNCTION IF EXISTS public.mailglass_raise_immutability())` — the `()` inside the SQL closed the `~s(` sigil early, raising `MismatchedDelimiterError` when the emitted body was compiled.
- **Fix:** Switched those two lines to `~s|...|` delimiters.
- **Files modified:** lib/mix/tasks/mailglass.upgrade.v2_schema.ex
- **Verification:** emitted body compiles (`Code.string_to_quoted/1` assertion passes)
- **Commit:** ffeb84ed

**3. [Rule 2 - Missing critical] Emitted `down/0` did not drop the emptied schema; plan required "schema is gone"**
- **Found during:** Task 2
- **Issue:** The research `down/0` moved tables back to `public` but left the (now empty) `mailglass` schema behind. The plan must-have requires "`down` reverses the move: all four tables are back in `public` and the schema is gone."
- **Fix:** Added `execute ~s(DROP SCHEMA IF EXISTS "#{@schema}")` (RESTRICT — only fires when empty) at the end of the emitted `down/0`.
- **Files modified:** lib/mix/tasks/mailglass.upgrade.v2_schema.ex
- **Verification:** migration test "down reverses ... the schema is gone" passes
- **Commit:** ffeb84ed

**4. [Rule 1 - Bug] Migration test poisoned the shared DB by dropping the public baseline without restoring it**
- **Found during:** Task 2
- **Issue:** The test's `on_exit` dropped the public mailglass baseline tables (and the move relocated them into `mailglass`, dropped CASCADE on teardown). The original `restore_suite_baseline_schema` only re-migrated under `MAILGLASS_SCHEMA=mailglass`, so on the default suite the shared DB was left without `public.mailglass_*` tables — the next boot's citext probe hit an absent `mailglass_suppressions` and exhausted (`citext probe exhausted after 11 attempts`).
- **Fix:** Generalized `restore_suite_baseline_schema` to always clear the boot `schema_migrations` rows and re-run the mailglass migrations into `Config.schema()` (mirrors the sibling immutability test's teardown). Also made the wrapper `down/0` reverse-the-move only (not tear down the seed) so the "four tables back in public" assertion holds.
- **Files modified:** test/mailglass/upgrade_v2_schema_migration_test.exs
- **Verification:** `mix test --only schema_isolation --seed 0` → 34 tests, 0 failures (no cross-file poisoning)
- **Commit:** ffeb84ed

**Total deviations:** 4 auto-fixed (2 bugs, 1 blocker, 1 missing-critical). **Impact:** none on the plan's public surface — the emitted migration and task API match the plan spec; the fixes made the emitted DDL correct and kept the shared test DB clean.

## Gate Results

Commands run (from the plan `<verification>`):

| Gate | Command | Result |
|------|---------|--------|
| Emitter unit + migration execution | `mix test test/mailglass/upgrade_v2_schema_generation_test.exs test/mailglass/upgrade_v2_schema_migration_test.exs --seed 0` | PASS — 17 tests, 0 failures (later 20 with the Task 3 host_app block) |
| Generation test (final, Task 3) | `mix test test/mailglass/upgrade_v2_schema_generation_test.exs --seed 0` | PASS — 14 tests, 0 failures |
| schema_isolation axis (default schema) | `mix test --only schema_isolation --seed 0` | PASS — 34 tests, 0 failures (1297 excluded) |
| no-optional-deps warnings-as-errors | `mix compile --no-optional-deps --warnings-as-errors` | PASS — clean (no Igniter, no compile guard) |
| format | `mix format --check-formatted <3 files>` | PASS |
| credo strict | `mix credo --strict lib/mix/tasks/mailglass.upgrade.v2_schema.ex` | PASS — no issues |
| host_app untouched | `git status --short reference/host_app/` | PASS — clean (no pin/lock bump) |

### Known environmental gate note (NOT a regression)

`MAILGLASS_SCHEMA=mailglass mix test --only schema_isolation --seed 0` fails at **boot** with `citext probe exhausted after 11 attempts` in `test_helper.exs`. This reproduces with ONLY the untouched, pre-existing `schema_isolation_immutability_test.exs` on a freshly `ecto.drop`/`ecto.create`d DB — i.e. it fires before any of this plan's test code runs, in files this plan does not modify (`test_helper.exs`, `test/support/citext_probe.ex`). It is a pre-existing local environmental flake on the mailglass CI axis (consistent with repo memory on this axis + citext OID fragility). The default-axis `:schema_isolation` run (the axis where this plan's `:schema_isolation` tests actually execute) is fully green.

## Deferred Issues

None.

## Self-Check: PASSED

- Created files exist on disk: `lib/mix/tasks/mailglass.upgrade.v2_schema.ex`, `test/mailglass/upgrade_v2_schema_generation_test.exs`, `test/mailglass/upgrade_v2_schema_migration_test.exs` — all FOUND.
- Commits present in git log: `810667f5` (test), `ffeb84ed` (feat), `245c3a29` (test) — all FOUND.
- All plan `<success_criteria>` re-verified green on the default axis.
