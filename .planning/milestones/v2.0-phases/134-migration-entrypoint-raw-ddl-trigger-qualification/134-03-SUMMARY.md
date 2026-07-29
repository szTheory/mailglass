---
phase: 134-migration-entrypoint-raw-ddl-trigger-qualification
plan: 03
subsystem: ci-and-lint
tags: [schema-isolation, credo, ci, matrix, MIGR-06, D-06]
requires:
  - "134-01: Mailglass.Migration.up/down prefix injection + maybe_create_schema (CREATE SCHEMA lifecycle)"
  - "134-02: schema-qualified raw DDL (immutability fn+trigger, CHECKs) — makes the mailglass axis physically passable"
  - "132/133: Config.schema/0 + Mailglass.Repo facade prefix injection"
provides:
  - "Mailglass.Credo.NoSchemaPrefixAttribute (build-time @schema_prefix guard, registered in .credo.exs)"
  - "config/runtime.exs test-env MAILGLASS_SCHEMA override of config :mailglass, :schema"
  - "schema: [public, mailglass] matrix axis on both Core Full Suite Advisory jobs"
  - "Mailglass.SchemaAxisBootOrderTest (fail-closed physical-table boot-order proof)"
  - "schema-aware migration_test + schema-isolation tests (green under both axes)"
affects:
  - "135: inbound mirrors the MAILGLASS_SCHEMA axis + @schema_prefix guard pattern"
  - "136-137: full-suite schema-isolation CI axis is now live on the advisory lane"
tech-stack:
  added: []
  patterns:
    - "AST-based Credo check: Macro.prewalk matching {:@, meta, [{:schema_prefix, _, args}]} with is_list(args) to fire only on declarations"
    - "config/runtime.exs runs AFTER config/test.exs — a guarded config_env()==:test runtime override wins over the test.exs pin"
    - "fail-closed CI axis: assert a physical mailglass.* table exists post-boot (not just Config.schema/0 string) to guard against a boot-order no-op"
    - "schema-aware test helpers: resolve Config.schema/0 instead of hardcoding table_schema='public'"
    - "restore-suite-baseline-schema in teardown: clear boot schema_migrations rows then re-migrate so a dropped baseline is genuinely recreated (not skipped as :already_up)"
    - "matrix.include 2-row expansion per toolchain for a new axis when top-level matrix keys are not used"
key-files:
  created:
    - credo_checks/no_schema_prefix_attribute.ex
    - test/mailglass/credo/no_schema_prefix_attribute_test.exs
    - test/mailglass/schema_axis_boot_order_test.exs
  modified:
    - .credo.exs
    - config/runtime.exs
    - test/support/citext_probe.ex
    - test/mailglass/migration_test.exs
    - test/mailglass/schema_isolation_integration_test.exs
    - test/mailglass/schema_isolation_immutability_test.exs
    - .github/workflows/advisory-matrix.yml
decisions:
  - "[134-03] The @schema_prefix guard is AST-based (matches the {:@, _, [{:schema_prefix, _, args}]} declaration node) rather than grep-based, mirroring NoCompileEnvOutsideConfig; path-scoped to lib/mailglass/."
  - "[134-03] The fail-closed boot-order proof asserts a PHYSICAL mailglass.mailglass_events table exists post-boot (via information_schema parameterized on table_schema), not merely that Config.schema/0 returns the string — this is the guard against a boot-order regression that migrates under public before the MAILGLASS_SCHEMA override applies."
  - "[134-03] Making the mailglass axis pass required schema-awareness fixes beyond the plan's named files: the test_helper citext probe (raw-repo calls bypassing the facade), migration_test's public-hardcoded helpers, and the schema-isolation tests' teardown (which dropped the boot baseline without restoring it). These are Rule-1/2/3 auto-fixes — the axis is a no-op without them."
  - "[134-03] Axis-switching locally requires a fresh test DB (schema_migrations tracks the boot schema); CI guarantees this per matrix row via mix ecto.create on a clean postgres service. Documented as an operational note."
metrics:
  duration: "~55 min"
  completed: 2026-07-03
  tasks: 3
  files: 10
status: complete
---

# Phase 134 Plan 03: @schema_prefix Guard + Dual-Schema CI Axis Summary

Closed MIGR-06 with a build-time Credo guard (`Mailglass.Credo.NoSchemaPrefixAttribute`) that fails on any `@schema_prefix` under `lib/mailglass/` — enforcing the pure-runtime-prefix rule (`Config.schema/0` injection) so a compile-time attribute can never invert read-vs-write prefix precedence (decision 6) — and closed Success Criterion 7 / D-06 by standing the full core suite up under BOTH the `public` and `mailglass` schemas via a new `schema: [public, mailglass]` matrix axis on the Core Full Suite Advisory jobs, wired through a `MAILGLASS_SCHEMA` runtime override and proven passable locally with a fail-closed physical-table boot-order guard.

## What Was Built

- **MIGR-06 — @schema_prefix build-time guard.** New `Mailglass.Credo.NoSchemaPrefixAttribute` (`credo_checks/`) walks the AST (`Macro.prewalk`) for a `{:@, meta, [{:schema_prefix, _, args}]}` declaration node (fires only when `args` is a non-nil list — an assignment, not a bare reference), path-scoped to `lib/mailglass/` exactly like `NoCompileEnvOutsideConfig`. Registered in `.credo.exs` `extra_checks`; carries a 3-case regression test (fires on a fixture, clean when absent, ignores files outside path scope). Green on the current tree — no mailglass module declares the attribute (132/133 use runtime facade injection). Satisfies the `checks_have_tests` meta-guard on both dimensions (test + registration).
- **D-06 — MAILGLASS_SCHEMA runtime override.** `config/runtime.exs` (which runs AFTER `config/test.exs`) now reads `MAILGLASS_SCHEMA` in the `:test` env and overrides `config :mailglass, :schema` when set to a non-empty value — layering over the `config/test.exs` "public" pin. Guarded to `config_env() == :test`; dev/prod are never affected and the default suite (env unset) keeps "public".
- **Success Criterion 7 — dual-schema CI axis.** Both Core Full Suite Advisory jobs (`core_full_suite_advisory` 1.18/27 and `core_latest_elixir_advisory` 1.19/28) gain a `schema` axis with `public` + `mailglass` rows (2-row `matrix.include` expansion per toolchain). Each "Run advisory full suite" step exports `MAILGLASS_SCHEMA: ${{ matrix.schema }}` and keeps `--exclude requires_workspace` unchanged. The job `name:` includes `${{ matrix.schema }}` while preserving the "Core Full Suite Advisory" leading substring (so `isAdvisory()` name-matching still classifies them advisory). No required `mix ci` lane touched.
- **Fail-closed boot-order proof.** New `Mailglass.SchemaAxisBootOrderTest` asserts the append-only `mailglass_events` table PHYSICALLY exists in `Config.schema/0`'s schema post-boot (via a schema-parameterized `information_schema.tables` probe), and — under `MAILGLASS_SCHEMA=mailglass` specifically — that it lands in `mailglass` (not `public`). A string-only `Config.schema()=="mailglass"` check would pass even if a boot-order regression migrated under `public`; the physical-table assertion is the fail-closed guard.
- **Schema-awareness fixes (axis enablement).** The mailglass axis is a no-op without these: the `test_helper.exs` citext probe now injects `prefix: Config.schema()` into its raw-repo `delete_all`/`insert`/`delete` (they bypassed the facade and hit the ambient `public` search_path → `42P01` → probe exhaustion at boot); `migration_test.exs`'s helpers/queries resolve the active schema via `Config.schema/0` instead of hardcoding `table_schema='public'`; and the schema-isolation tests' teardown re-migrates the suite baseline schema (clearing stale `schema_migrations` boot rows first) so a dropped `mailglass` baseline is genuinely recreated for the next test file.

## Key Links

- `credo_checks/no_schema_prefix_attribute.ex` → registered in `.credo.exs` `extra_checks` → `mix credo --strict`
- `advisory-matrix.yml` schema axis → `MAILGLASS_SCHEMA` env → `config/runtime.exs` (test) → `config :mailglass, :schema` → `Config.schema/0` → facade prefix injection + migration entrypoint
- `test_helper.exs` boot `Ecto.Migrator.run` → `Mailglass.Migration.up/0` → `Config.schema()` → CREATE SCHEMA + tables under the axis schema → `SchemaAxisBootOrderTest` physical-table proof

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] test_helper citext probe hit the wrong schema under the mailglass axis**
- **Found during:** Task 2
- **Issue:** `CitextProbe.default_probe/1` runs `repo.delete_all`/`insert`/`delete` on the RAW repo (`Mailglass.TestRepo`), which does not inject the facade schema prefix. Under `MAILGLASS_SCHEMA=mailglass`, these hit an unqualified `mailglass_suppressions` (resolving via the `public` search_path, where the table no longer exists) → `42P01 undefined_table`. The probe mistakes that for a poisoned-OID `Postgrex.Error` and retries until exhaustion, aborting the whole suite at boot (`test_helper.exs:75`).
- **Fix:** Inject `prefix: Mailglass.Config.schema()` into the probe's raw-repo `delete_all`/`insert`/`delete` calls so they resolve under the active schema. `SuppressionStore.check/1` already routed through the facade; only the raw-repo calls needed the explicit prefix.
- **Files:** `test/support/citext_probe.ex`
- **Commit:** `ace086b5`

**2. [Rule 2 - Missing schema-awareness] migration_test hardcoded table_schema='public'**
- **Found during:** Task 2
- **Issue:** `migration_test.exs`'s `table_exists?`/`column_exists?` helpers and its trigger/index/constraint/version-marker queries hardcode `public`, so all `up/0`+`down/0` tests fail under the mailglass axis (the objects live in `mailglass`). The CI axis runs the full suite, so these would fail the mailglass row.
- **Fix:** Resolve `Mailglass.Config.schema()` in the helpers and thread it (parameterized) into `information_schema`/`pg_indexes`/`pg_constraint` queries and `migrated_version(prefix:, repo:)`. Green under BOTH axes across seeds 0/7/42/123/999.
- **Files:** `test/mailglass/migration_test.exs`
- **Commit:** `ace086b5`

**3. [Rule 3 - Blocking] schema-isolation tests dropped the boot baseline without restoring it (cross-file interference)**
- **Found during:** Task 2
- **Issue:** Under the mailglass axis the suite baseline schema IS `mailglass` (boot-migrated once). Several tests (`schema_isolation_integration_test`, `schema_isolation_immutability_test`, and `migration_test`'s non-public-prefix describe block) do `DROP SCHEMA mailglass CASCADE` in teardown, destroying the baseline for every subsequent test file — a non-deterministic (seed-ordering-dependent) cascade of failures. Additionally the `public.*` isolation-comparison assertions raised `42P01` because there are no `public.mailglass_*` tables under the axis.
- **Fix:** Added `restore_suite_baseline_schema/0` to each teardown that drops the schema — it clears the stale boot `schema_migrations` rows (else `:up all` is a no-op) then re-migrates the baseline; no-op on the default public suite. The integration test's `public.*` assertions now use a `public_row_count/2` helper that returns 0 when the public table is absent (a stronger isolation proof). The migration_test non-public-prefix tests defensively `DROP SCHEMA IF EXISTS ... CASCADE` before their bare `CREATE SCHEMA` (which would otherwise raise `42P06` against the pre-existing baseline). Deterministic green across seeds 0/7/42/123/999 under both axes.
- **Files:** `test/mailglass/schema_isolation_integration_test.exs`, `test/mailglass/schema_isolation_immutability_test.exs`, `test/mailglass/migration_test.exs`
- **Commit:** `ace086b5`

## Deferred Issues

Logged to `deferred-items.md` (out of scope — scope boundary):
- **Pre-existing `mix credo --strict` D-15 warning** in `mailglass_inbound/lib/mailglass_inbound/application.ex:12` (`NoPlanningArtifactComments`). Introduced by commit `90647119` (`feat(132-02)`), verified pre-existing via `git blame` and a stash-baseline comparison — NOT touched by this plan. `mix credo --strict` exits 16 solely because of it; my new guard and all my changes are credo-clean.
- **Pre-existing full-`mix test` instability (~216 failures locally)** — a connection-pool cascade (`DBConnection.ConnectionError owner exited`) that poisons many unrelated tests once one crashes. Verified IDENTICAL (216) with my changes stashed, so it pre-dates this plan; individual affected files (e.g. `tracking/plug_test.exs`) pass in isolation. CI runs the advisory lane on fresh isolated infra where this is far less prevalent. Not introduced here.

## Operational Note

Switching schema axes **locally** requires a fresh test DB (`mix ecto.drop && mix ecto.create -r Mailglass.TestRepo`): `schema_migrations` tracks the boot schema, so a DB left in a `mailglass`-migrated state breaks a subsequent `public`-axis boot (and vice versa). CI guarantees this per matrix row via `mix ecto.create` on a clean postgres service, so the axis is deterministic in CI.

## Verification

- `mix test test/mailglass/credo/no_schema_prefix_attribute_test.exs test/mailglass/credo/checks_have_tests_test.exs --warnings-as-errors` — 5 tests, 0 failures (guard fires on fixture, is registered + tested).
- `mix credo --strict` — the ONLY warning is the pre-existing D-15 in the untouched inbound file; the new `NoSchemaPrefixAttribute` and all touched files are credo-clean (`mix credo --strict credo_checks/no_schema_prefix_attribute.ex` → no issues).
- `mix test test/mailglass/migration_test.exs --warnings-as-errors` (public axis) — 12 tests, 0 failures.
- `MAILGLASS_SCHEMA=mailglass mix test test/mailglass/migration_test.exs test/mailglass/schema_isolation_immutability_test.exs test/mailglass/schema_isolation_integration_test.exs --warnings-as-errors` — 22 tests, 0 failures (axis proven passable).
- Fail-closed proof: `Mailglass.SchemaAxisBootOrderTest` green under both axes; `mailglass.mailglass_events` physically present under `MAILGLASS_SCHEMA=mailglass` (psql count = 1).
- Determinism: all four schema/migration files together — 23 tests, 0 failures under seeds 0/7/42/123/999, under BOTH axes.
- `grep -c 'schema: "public"'` = 2 and `grep -c 'schema: "mailglass"'` = 2 in `advisory-matrix.yml` (one row per advisory job); both jobs export `MAILGLASS_SCHEMA: ${{ matrix.schema }}`; both keep `--exclude requires_workspace`; both preserve the "Core Full Suite Advisory" name substring. YAML parses (python `yaml.safe_load`; no ruby used per plan guidance).
- `mix compile --warnings-as-errors` clean; `mix format --check-formatted` clean on all touched files.
- Note (execution env): CI itself cannot run here; the green-under-both-schemas outcome is proven locally via the targeted `MAILGLASS_SCHEMA=mailglass` runs, and the CI axis exercises the full suite on push.

## Self-Check: PASSED

- FOUND: credo_checks/no_schema_prefix_attribute.ex (created)
- FOUND: test/mailglass/credo/no_schema_prefix_attribute_test.exs (created)
- FOUND: test/mailglass/schema_axis_boot_order_test.exs (created)
- FOUND: .credo.exs / config/runtime.exs / test/support/citext_probe.ex / .github/workflows/advisory-matrix.yml (modified)
- FOUND commit dc404655 (feat 134-03 NoSchemaPrefixAttribute guard)
- FOUND commit ace086b5 (feat 134-03 MAILGLASS_SCHEMA override + schema-aware suite)
- FOUND commit 223aaea3 (ci 134-03 schema axis on advisory matrix)
</content>
</invoke>
