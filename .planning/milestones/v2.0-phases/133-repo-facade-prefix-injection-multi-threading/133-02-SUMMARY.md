---
phase: 133-repo-facade-prefix-injection-multi-threading
plan: "02"
subsystem: core/schema-isolation
tags:
  - schema-prefix
  - ecto-multi
  - facade
  - integration-test
  - FACADE-03
  - FACADE-04
dependency_graph:
  requires:
    - phase: "133-01"
      provides: "put_prefix/1 + multi_opts/1 + prefix-threaded Multi builders (FACADE-01, FACADE-02)"
  provides:
    - "test/mailglass/schema_isolation_integration_test.exs — FACADE-04 end-to-end schema-isolation proof"
    - "mailglass_admin/test/.../operator_live_test.exs — FACADE-03 zero-admin-code-change render proof (separate module at bottom of file)"
    - "D-06 split recorded in ROADMAP.md + REQUIREMENTS.md (CI matrix axis moved to Phase 134)"
    - "D-08 bypass assertion: no lib/ call-site bypasses Mailglass.Repo facade (allowlist: migration.ex + repo.ex only)"
  affects:
    - "134 (migration entrypoint — depends on FACADE-04 having proven end-to-end prefix correctness)"
    - "135 (inbound mirror — mirrors this pattern)"
tech_stack:
  added: []
  patterns:
    - "setup_all-in-separate-module pattern for schema-isolated LiveView tests (setup_all inside describe is prohibited in ExUnit)"
    - "Application.put_env + :persistent_term.erase for per-test Config.schema override with restore in on_exit"
    - "Sandbox :auto mode for DDL (CREATE SCHEMA + Ecto.Migrator) in setup_all; restore :manual before per-test owner starts"
    - "D-08 bypass assertion via File.wildcard + Enum.reject allowlist + String.contains? grep"

key_files:
  created:
    - test/mailglass/schema_isolation_integration_test.exs
  modified:
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/config/test.exs
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "Admin test.exs needs config :mailglass, :schema, 'public' to match core's test.exs pin; without it, facade injects prefix: 'mailglass' and citext probe + all admin tests fail (Rule 2 auto-fix)"
  - "setup_all inside describe is prohibited in ExUnit — FACADE-03 bespoke module (MailglassAdmin.OperatorLive.Facade03SchemaIsolationTest) added at bottom of operator_live_test.exs; reproduces LiveViewCase contract manually"
  - "Citext probe skipped in FACADE-03 setup: the test does not drop/recreate the citext extension, so no stale-OID risk; the probe fails when SuppressionStore.check uses prefix 'mailglass' but probe's direct TestRepo.insert targets public"
  - "on_exit from setup_all re-flips Sandbox to :auto before cleanup queries — all per-test owners have exited by then, no owned connection available"
  - "D-08 bypass assertion allowlists migration.ex AND repo.ex (the facade itself contains the authorized Application.get_env(:mailglass, :repo) call inside repo/0)"

requirements-completed:
  - FACADE-03
  - FACADE-04

coverage:
  - id: D1
    description: "FACADE-04: schema-isolation integration test creates mailglass schema, migrates, round-trips Events.append through facade, asserts mailglass.* has rows while public.mailglass_events = 0"
    requirement: FACADE-04
    verification:
      - kind: integration
        ref: "test/mailglass/schema_isolation_integration_test.exs#FACADE-04 schema isolation: rows land under mailglass.* while public stays clean"
        status: pass
    human_judgment: false
  - id: D2
    description: "FACADE-04: operator reads (SupportSummary orphan-count, Deliveries list) resolve under mailglass prefix"
    requirement: FACADE-04
    verification:
      - kind: integration
        ref: "test/mailglass/schema_isolation_integration_test.exs#FACADE-04: orphan-count read via SupportSummary resolves under mailglass prefix"
        status: pass
    human_judgment: false
  - id: D3
    description: "FACADE-04: Tenancy.scope/2 composes with prefix (WHERE + schema both apply, per-tenant isolation holds)"
    requirement: FACADE-04
    verification:
      - kind: integration
        ref: "test/mailglass/schema_isolation_integration_test.exs#Delivery insert + Events.append round-trips under mailglass schema"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-08: no lib/mailglass call-site bypasses Mailglass.Repo facade with direct Application.get_env(:mailglass, :repo)"
    verification:
      - kind: integration
        ref: "test/mailglass/schema_isolation_integration_test.exs#D-08: no facade-bypassing lib/ call-sites"
        status: pass
    human_judgment: false
  - id: D5
    description: "FACADE-03: admin dashboard renders delivery written to mailglass schema with zero mailglass_admin/lib/ changes"
    requirement: FACADE-03
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#FACADE-03: admin zero-code-change proof - write->read->render round-trip"
        status: pass
    human_judgment: false
  - id: D6
    description: "D-06 split documented: Phase 133 ROADMAP/REQUIREMENTS no longer claim full-suite-green-under-both-schemas; Phase 134 owns CI matrix axis"
    verification:
      - kind: other
        ref: ".planning/ROADMAP.md Phase 133 criterion (4) + Phase 134 criterion (7)"
        status: pass
    human_judgment: false

duration: 11min
completed: "2026-07-02"
status: complete
---

# Phase 133 Plan 02: Schema-Isolation Integration Test + Admin Proof + D-06 Split Summary

FACADE-04 end-to-end schema-isolation round-trip test (Events.append → mailglass.* rows, public.mailglass_events = 0, operator reads + orphan-count + Tenancy.scope compose), FACADE-03 zero-admin-code-change LiveView render proof, and D-06 split recorded in ROADMAP + REQUIREMENTS.

## Performance

- **Duration:** ~11 min
- **Started:** 2026-07-02T22:52:17Z
- **Completed:** 2026-07-02T23:03:00Z
- **Tasks:** 3
- **Files modified:** 5 (2 created, 3 modified)

## Accomplishments

- FACADE-04: `test/mailglass/schema_isolation_integration_test.exs` — 4-test module with inline `PrefixedWrapperMigration` (SET LOCAL search_path pin for v01 unqualified trigger DDL), Sandbox :auto DDL setup, 5 round-trip assertions (public empty / mailglass has rows / operator reads / orphan-count subquery / Tenancy.scope), and D-08 bypass assertion (allowlisted: migration.ex + repo.ex)
- FACADE-03: `MailglassAdmin.OperatorLive.Facade03SchemaIsolationTest` bespoke module appended to `operator_live_test.exs`; write→read→render round-trip proves admin reads route through the facade unchanged; zero `mailglass_admin/lib/` changes
- D-06 split documented in ROADMAP.md + REQUIREMENTS.md: Phase 133 success criterion (4) no longer claims full-suite-green-under-both-schemas; Phase 134 now owns CI matrix axis criterion (7); both cite D-06

## Task Commits

1. **Task 1: FACADE-04 integration test + admin config fix** - `70a3e071` (feat)
2. **Task 2: FACADE-03 admin render proof + D-08 bypass fix** - `ee8e965d` (feat)
3. **Task 3: D-06 roadmap/requirements split** - `aaefe5e9` (docs)

## Files Created/Modified

- `test/mailglass/schema_isolation_integration_test.exs` — new FACADE-04 integration test module (4 tests, inline PrefixedWrapperMigration, D-08 bypass assertion)
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — appended `MailglassAdmin.OperatorLive.Facade03SchemaIsolationTest` bespoke module (FACADE-03 write→read→render proof)
- `mailglass_admin/config/test.exs` — added `config :mailglass, :schema, "public"` to match core's test.exs pin (Rule 2 auto-fix)
- `.planning/ROADMAP.md` — D-06 split: Phase 133 criterion (4) reworded; CI matrix axis added as Phase 134 criterion (7); Phase 134 detail success criteria (7) added
- `.planning/REQUIREMENTS.md` — FACADE-04 reworded: integration test portion stays; CI-matrix-axis clause deferred to Phase 134 with D-06 pointer

## Decisions Made

1. **admin config/test.exs needs `config :mailglass, :schema, "public"`** — Without it, the facade injects `prefix: "mailglass"` into all admin tests and the citext probe exhausts (tables in public, not mailglass). Mirrors core's test.exs pin exactly. The dedicated FACADE-03 test overrides this to "mailglass" explicitly for its schema-isolated run.

2. **FACADE-03 as a separate `defmodule` at bottom of the test file** — ExUnit prohibits `setup_all` inside `describe` blocks. The bespoke `MailglassAdmin.OperatorLive.Facade03SchemaIsolationTest` module has its own `setup_all` (DDL phase) and per-test `setup` (Sandbox owner + tenant stamp + conn), reproducing the LiveViewCase contract without inheriting its ordering.

3. **Citext probe skipped in FACADE-03 setup** — The FACADE-03 test does not drop/recreate citext, so no stale-OID risk. The standard probe would fail because `SuppressionStore.check` goes through the facade with `prefix: "mailglass"` while the probe's `TestRepo.insert!` targets public — conflicting schema contexts causing repeated `Postgrex.Error`.

4. **D-08 allowlists repo.ex in addition to migration.ex** — `Application.get_env(:mailglass, :repo)` inside `repo/0` (the facade itself) is the authorized call-site. The allowlist excludes both `migration.ex` (adapter introspection) and `/repo.ex` (the authorized facade private function).

5. **on_exit from setup_all re-flips to :auto before cleanup** — After all per-test owners exit, no Sandbox connection is available. Flipping to :auto temporarily allows the DROP SCHEMA + DELETE FROM schema_migrations cleanup queries to run.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Config] Added `config :mailglass, :schema, "public"` to `mailglass_admin/config/test.exs`**
- **Found during:** Pre-verification before Task 1 (ran admin tests as baseline check)
- **Issue:** The admin test config had no `:schema` key. Plan 01 added `Config.schema()` which now injects `prefix: Config.schema()` into every facade call. With no `:schema` config in admin, `Config.schema()` returned `"mailglass"` (the default). The citext probe (and all admin tests) tried to use `prefix: "mailglass"` but tables live in `public` → citext probe exhausted after 11 attempts.
- **Fix:** Added `config :mailglass, :schema, "public"` to `mailglass_admin/config/test.exs`, matching what Plan 01 added to core's `config/test.exs`.
- **Files modified:** `mailglass_admin/config/test.exs`
- **Commit:** `70a3e071`

**2. [Rule 3 - Blocking] Switched from setup_all-inside-describe to bespoke separate module for FACADE-03**
- **Found during:** Task 2 (first attempt to compile the admin test with setup_all inside describe)
- **Issue:** ExUnit raises `"cannot invoke setup_all/1-2 inside describe as setup_all always applies to all tests in a module"` at compile time.
- **Fix:** Moved the FACADE-03 proof to a separate `defmodule MailglassAdmin.OperatorLive.Facade03SchemaIsolationTest` at the bottom of the same file, with its own module-level `setup_all` (DDL phase) and per-test `setup` (Sandbox owner + tenant).
- **Files modified:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs`
- **Commit:** `ee8e965d`

**3. [Rule 1 - Bug] Credo chained Enum.reject refactoring opportunity in integration test**
- **Found during:** Task 2 verification (`mix credo --strict`)
- **Issue:** Three chained `Enum.reject/2` calls in the D-08 allowlist filter triggered Credo's "One Enum.reject/2 is more efficient" finding.
- **Fix:** Combined into a single `Enum.reject/2` with `or` predicate.
- **Files modified:** `test/mailglass/schema_isolation_integration_test.exs`
- **Commit:** `ee8e965d`

---

**Total deviations:** 3 auto-fixed (1 missing critical config, 1 blocking compile-error, 1 credo refactor)
**Impact on plan:** All auto-fixes necessary for correctness or compliance. No scope creep. FACADE-03 proof strategy unchanged (write→read→render round-trip); only the ExUnit module structure changed.

## Known Stubs

None — all integration tests write real rows to the DB and read them back. No placeholder data.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. The test's CREATE SCHEMA / DROP SCHEMA is test-only DDL with hardcoded `mailglass` schema name (no external input interpolation) per T-133-04 disposition `accept`.

## Verification Results

- `mix test test/mailglass/schema_isolation_integration_test.exs` — 4 tests, 0 failures
- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --seed 0` — 70 tests, 0 failures
- `git status --porcelain mailglass_admin/lib/` — empty (zero admin lib changes — FACADE-03 proven)
- `mix credo --strict` — 0 issues in changed files (1 pre-existing `D-15` in inbound app.ex, out of scope)
- ROADMAP.md Phase 133 criterion (4) no longer contains "full core suite runs green under BOTH"
- Phase 134 checklist and detail criteria now own the CI matrix axis (D-06)
- Both ROADMAP + REQUIREMENTS cite D-06

## Self-Check: PASSED

All created/modified files confirmed present on disk. All 3 task commits confirmed in git log.
