---
phase: 135-inbound-package-schema-isolation
plan: "03"
subsystem: mailglass_inbound/test-harness + CI
tags: [schema-isolation, inbound, dual-schema, CI, test-harness, INB-03]
dependency_graph:
  requires: [135-01, 135-02]
  provides: [INB-03]
  affects:
    - mailglass_inbound/test/test_helper.exs
    - mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
    - .github/workflows/advisory-matrix.yml
tech_stack:
  added: []
  patterns:
    - "MAILGLASS_SCHEMA env → Config.schema/0 alignment via put_env + persistent_term erase"
    - "search_path Postgrex parameter for raw SQL schema routing in non-public runs"
    - "Ecto.Migrator.up with inline wrapper migration (runner process pattern)"
    - "schema_opts/0 private helper for explicit prefix on direct repo calls"
    - "schema: [public, mailglass] advisory CI matrix axis mirroring core D-06"
key_files:
  created: []
  modified:
    - mailglass_inbound/test/test_helper.exs
    - mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
    - .github/workflows/advisory-matrix.yml
decisions:
  - "D-12: MAILGLASS_SCHEMA read in test_helper.exs (inbound has no runtime.exs); default to public"
  - "D-13: --seed 0 pins test ordering to dodge phase-45 property-test pool flake"
  - "search_path = schema on TestRepo connections so unqualified TRUNCATE TABLE targets correct schema"
  - "schema_opts/0 in persist.ex mirrors facade put_prefix/1 for direct repo.insert/one calls"
  - "schema_migrations cleanup: purge stale test-version entries from non-public schema after start"
  - "Inline TestMigration.Install wrapper drives Migration.up/1 via Ecto.Migrator.up/4 (runner required)"
metrics:
  duration: "~60 minutes"
  completed: "2026-07-03T09:30:29Z"
  tasks: 2
  files: 3
status: complete
---

# Phase 135 Plan 03: Dual-Schema Validation — Test Harness + Advisory CI Summary

Stand up the dual-schema validation: rewire `test_helper.exs` to migrate via
`MailglassInbound.Migration.up(prefix: schema)` reading `MAILGLASS_SCHEMA` and align
the facade's `Config.schema/0` to the same value; fix `persist.ex` to qualify direct
repo calls with `prefix:`; add a non-blocking `mailglass_inbound` CI job on the
`schema: [public, mailglass]` axis — proving the inbound suite green under both schemas.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Rewire test_helper.exs to Migration.up/1 with MAILGLASS_SCHEMA dual-schema alignment | ddefdc33 | test_helper.exs, persist.ex |
| 2 | Add mailglass_inbound dual-schema advisory CI job | 76f2be0e | advisory-matrix.yml |

## What Was Built

### Task 1: Dual-Schema Test Harness

**`mailglass_inbound/test/test_helper.exs` — five-part alignment:**

1. **Schema from env:** `schema = System.get_env("MAILGLASS_SCHEMA") || "public"` (mirrors core runtime.exs D-12).

2. **App env alignment:** `Application.put_env(:mailglass_inbound, :schema, schema)` before migration so `Config.schema/0` warms to the right value.

3. **Persistent_term cache reset:** `:persistent_term.erase({MailglassInbound.Config, :schema})` forces re-warm from the updated app env rather than the stale "public" boot-warmed value.

4. **Ecto.Migrator.up/4 driver:** An inline `MailglassInbound.TestMigration.Install` module drives `Migration.up(prefix: schema, repo: TestRepo)` inside `Ecto.Migrator.up(repo, 99_000_000_000_000, Install, log: false)` within the `with_repo` pool-override block. This satisfies the `Migrations.Postgres` requirement for an active `Ecto.Migration.Runner` process.

5. **search_path for raw SQL:** When `schema != "public"`, adds `parameters: [search_path: schema]` to the TestRepo Postgrex connection config. This ensures raw SQL queries (`TRUNCATE TABLE mailglass_inbound_records CASCADE` in test setup blocks) target the configured schema rather than defaulting to `public`.

6. **schema_migrations cleanup:** After `TestRepo.start_link()`, deletes stale test-version entries from `<schema>.schema_migrations` (keeping only the install slot `99_000_000_000_000`). Prevents `migrations_test.exs` from seeing previously-applied monotonic version slots (which would cause Ecto.Migrator to skip re-running them, leaving `inb_mig_test` schema uncreated).

**`mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` — schema_opts/0 fix:**

Added a private `schema_opts/0` helper returning `[prefix: MailglassInbound.Config.schema()]` and threaded it through all direct `repo.insert/one` calls:
- `repo.insert(changeset, schema_opts())` in `insert_record/5`
- `repo.insert(schema_opts())` in `insert_evidence/5`
- `repo.one(query, schema_opts())` in all four `load_duplicate` / `load_by_provider_message_id` variants

This ensures that when `persist.ex` is called with `repo: TestRepo` (bypassing the facade), all DB operations still target the configured schema — matching what `MailglassInbound.Repo.put_prefix/1` does for facade calls. Without this, `inbound_records` and `evidence` would land in `public` while `execution_runs` (inserted via `InboundRecords.insert_execution_run` which always uses the facade) landed in `mailglass`, causing FK constraint violations.

### Task 2: Dual-Schema Advisory CI Job

Added `mailglass_inbound_dual_schema_advisory` to `.github/workflows/advisory-matrix.yml`:
- `schema: [public, mailglass]` matrix axis on Elixir 1.18 / OTP 27
- `defaults.run.working-directory: mailglass_inbound` scopes all steps
- Inbound-scoped deps cache key (`inbound-${{ runner.os }}-mix-...`)
- `mix ecto.create -r MailglassInbound.TestRepo --quiet`
- `MAILGLASS_SCHEMA: ${{ matrix.schema }}` exported to the run step
- `mix test --seed 0` (D-13 anti-flake)
- Advisory / non-blocking: not added to any required-status gate

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Ecto.Migration.Runner required for Migration.up/1**
- **Found during:** Task 1 implementation
- **Issue:** `MailglassInbound.Migrations.Postgres` uses `use Ecto.Migration` and calls `execute/1` / `create/1`, which require an active `Ecto.Migration.Runner` process started by `Ecto.Migrator.up/4`. The plan specified calling `MailglassInbound.Migration.up(prefix: schema)` directly inside `with_repo`, but this raises `"could not find migration runner process"`.
- **Fix:** Defined an inline `MailglassInbound.TestMigration.Install` module (same pattern as `migrations_test.exs` `PrefixUpMigration`) and drove it via `Ecto.Migrator.up(repo, 99_000_000_000_000, Install, log: false)`.
- **Files modified:** `mailglass_inbound/test/test_helper.exs`
- **Commit:** `ddefdc33`

**2. [Rule 2 - Missing critical functionality] persist.ex bypasses facade prefix injection**
- **Found during:** Task 1 verification — `MAILGLASS_SCHEMA=mailglass mix test` showed 50 failures with FK constraint violations (`inbound_record_id does not exist`)
- **Issue:** `Ingress.Persist` accepts a `repo:` option and calls `repo.insert(changeset)` / `repo.one(query)` directly. When tests pass `repo: TestRepo`, the facade `MailglassInbound.Repo.put_prefix/1` is bypassed — `inbound_records` and `evidence` land in `public` (no prefix). But `execution_runs` is inserted via `InboundRecords.insert_execution_run` (always uses facade → `mailglass`). FK constraint on `mailglass.replay_runs.inbound_record_id → mailglass.records` fails.
- **Fix:** Added `schema_opts/0` private helper in `persist.ex` returning `[prefix: MailglassInbound.Config.schema()]`; threaded it through all 6 direct `repo.insert/one` call sites.
- **Files modified:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex`
- **Commit:** `ddefdc33`

**3. [Rule 1 - Bug] search_path required for raw SQL schema routing in tests**
- **Found during:** Task 1 verification — after fixing the FK issue, async:false tests using `TRUNCATE TABLE mailglass_inbound_records CASCADE` still failed: TRUNCATE hit `public` (Postgres default) while facade-prefixed reads checked `mailglass`, causing test isolation failures (count assertions saw data from other tests).
- **Fix:** Added `parameters: [search_path: schema]` to TestRepo Postgrex connection config when `schema != "public"`. This makes unqualified raw SQL (`TRUNCATE TABLE`, `query!/2`) target the configured schema.
- **Files modified:** `mailglass_inbound/test/test_helper.exs`
- **Commit:** `ddefdc33`

**4. [Rule 1 - Bug] schema_migrations pollution across test runs in non-public schema**
- **Found during:** Task 1 verification — `migrations_test.exs` failures even with search_path fix: `System.unique_integer([:positive, :monotonic]) + 80_000_000_000_000` generates low monotonic values (1,2,3...) on each run; with `search_path=mailglass`, Ecto.Migrator records these in `mailglass.schema_migrations` but `on_exit` only cleans `public.schema_migrations`. Second run: same version slots already applied → migrator skips → `inb_mig_test` schema not created → test fails.
- **Fix:** After `TestRepo.start_link()`, delete all entries from `schema_migrations` except the stable install slot `99_000_000_000_000` when `schema != "public"`.
- **Files modified:** `mailglass_inbound/test/test_helper.exs`
- **Commit:** `ddefdc33`

## Verification Results

```
cd mailglass_inbound && MAILGLASS_SCHEMA=mailglass mix test --seed 0
→ 3 properties, 388 tests, 0 failures ✓

cd mailglass_inbound && mix test --seed 0
→ 3 properties, 388 tests, 0 failures ✓

python3 YAML axis check
→ OK mailglass_inbound_dual_schema_advisory ['mailglass', 'public'] ✓
```

## Known Stubs

None — all functionality is fully wired. The dual-schema proof is end-to-end:
facades, migrations, and test isolation all agree on the configured schema.

## Threat Surface Scan

No new network endpoints, auth paths, or file access patterns introduced. The
`MAILGLASS_SCHEMA` env value flows into `Config.schema/0` (validated by
`Mailglass.Identifier.validate!/2`) and `parameters: [search_path: ...]` (Postgrex
connection parameter). The CI matrix only supplies the fixed literals `"public"` /
`"mailglass"`. T-135-06 (dual-schema green claimed but never exercised) and T-135-07
(phase-45 property-test pool flake) are both mitigated as designed.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| `mailglass_inbound/test/test_helper.exs` | FOUND |
| `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` | FOUND |
| `.github/workflows/advisory-matrix.yml` | FOUND |
| `.planning/phases/135-inbound-package-schema-isolation/135-03-SUMMARY.md` | FOUND |
| Commit `ddefdc33` (Task 1) | FOUND |
| Commit `76f2be0e` (Task 2) | FOUND |
| `MAILGLASS_SCHEMA=mailglass mix test --seed 0` | 0 failures |
| `mix test --seed 0` | 0 failures |
| YAML axis check | OK |
