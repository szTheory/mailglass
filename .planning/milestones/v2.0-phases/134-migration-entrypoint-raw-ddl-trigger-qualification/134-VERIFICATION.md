---
phase: 134-migration-entrypoint-raw-ddl-trigger-qualification
verified: 2026-07-02T21:35:00Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: none
  note: initial verification
---

# Phase 134: Migration Entrypoint + Raw-DDL/Trigger Qualification Verification Report

**Phase Goal:** Inject `prefix:` at `Mailglass.Migration.up/down`, add `maybe_create_schema/1`
(`create_schema: false` escape hatch) + `maybe_drop_schema/1` (`RESTRICT`), hand-qualify the v01
immutability trigger + function (schema-scoped, `SET search_path = ''`), the v01/v03 CHECK
constraints, and all `down/0` raw drops; `citext` stays in `public`.
**Verified:** 2026-07-02T21:35:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (Success Criterion) | Status | Evidence |
|---|---|---|---|
| 1 | `Mailglass.Migration.up/down` thread `prefix: Config.schema()` into the v01–v05 dispatcher | ✓ VERIFIED | `lib/mailglass/migration.ex:31,41` — both `up/1` and `down/1` call `Keyword.put_new(opts, :prefix, Mailglass.Config.schema())`; `put_new` means explicit caller prefix wins; `migrated_version/1` untouched |
| 2 | `up/1` issues `CREATE SCHEMA IF NOT EXISTS` for non-public prefix honoring `create_schema: false`; `down/1` drops with `RESTRICT` only if created and only after tables gone | ✓ VERIFIED | `postgres.ex:22,103-108` (`maybe_create_schema` first action of `up/1`, gated `create_schema: true`); `:141` `Map.put_new(:create_schema, prefix != "public")` honors explicit `false`; `:97` `if target == 0, do: maybe_drop_schema` (version-0-only); `:113-115` `DROP SCHEMA IF EXISTS ... RESTRICT`. Both axes migrate up+down green (23 tests each) |
| 3 | Events trigger + function created IN configured schema (`<schema>.mailglass_raise_immutability`, `SET search_path = ''`), no global-name collision | ✓ VERIFIED | `v01.ex:138,141,156` — `CREATE OR REPLACE FUNCTION #{q}.mailglass_raise_immutability() ... SET search_path = ''`; trigger `ON #{q}.mailglass_events EXECUTE FUNCTION #{q}...`. Physical DB probe under `MAILGLASS_SCHEMA=mailglass`: function lives ONLY in `mailglass`, `proconfig = ["search_path=\"\""]` |
| 4 | v01/v03 CHECK constraints + every `down/0` raw drop hand-qualified to runtime prefix | ✓ VERIFIED | v01 `stream_scope` CHECK ADD/DROP `#{q}.mailglass_suppressions` (`v01.ex:182,189`); v03 complaint CHECK ADD/DROP (`v03.ex:23-27,38`); `v01.down/1(opts)` reads `opts[:prefix]`, threads into all `drop(table(prefix:))` + qualifies raw `DROP TRIGGER`/`DROP FUNCTION` (`v01.ex:219-234`); every interpolation site preceded by `Identifier.validate!/2` |
| 5 | LOAD-BEARING: up/down against non-public prefix succeeds, `citext` unqualified (stays public), immutability trigger raises SQLSTATE 45A01 under `mailglass` with NO search_path pin | ✓ VERIFIED | `MAILGLASS_SCHEMA=mailglass` targeted run: 23 tests, 0 failures. Immutability test has ZERO `SET search_path` (grep clean); asserts 45A01 on UPDATE+DELETE (`schema_isolation_immutability_test.exs:114-137`). Physical probe: `citext` in `public`, `mailglass.mailglass_events` present. `v01.ex:18` `CREATE EXTENSION IF NOT EXISTS citext` UNqualified |
| 6 | grep/Credo guard fails build if any mailglass schema module declares `@schema_prefix` | ✓ VERIFIED | `credo_checks/no_schema_prefix_attribute.ex` (AST-based `{:@, meta, [{:schema_prefix, _, args}]}`, path-scoped `lib/mailglass/`); registered `.credo.exs:86`; 5-case test green; `grep -rn "@schema_prefix" lib/mailglass/` → none; `mix credo --strict` clean on all phase files |
| 7 | D-06 CI matrix axis: full core suite runs under BOTH `schema: "public"` and `schema: "mailglass"` on Core Full Suite Advisory | ✓ VERIFIED | `advisory-matrix.yml`: both jobs carry public+mailglass rows (2 each), both export `MAILGLASS_SCHEMA: ${{ matrix.schema }}` (lines 105,193), both keep `--exclude requires_workspace`, name preserves "Core Full Suite Advisory" substring. `config/runtime.exs:41-47` reads `MAILGLASS_SCHEMA` guarded to `:test`. Both axes proven passable locally |

**Score:** 7/7 truths verified (0 present, behavior-unverified)

The two behavior-dependent truths (SC-2 lifecycle, SC-5 append-only 45A01 invariant) were exercised
behaviorally — the load-bearing 45A01 trigger fires under `mailglass` with no search_path pin (targeted
test run green + direct DB probe), not merely present in source.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/mailglass/migration.ex` | prefix injection | ✓ VERIFIED | `up/1`+`down/1` `Keyword.put_new(:prefix, Config.schema())` |
| `lib/mailglass/migrations/postgres.ex` | `maybe_create_schema/1` + `maybe_drop_schema/1` | ✓ VERIFIED | Both present + wired; RESTRICT; version-0-gated drop |
| `lib/mailglass/migrations/postgres/v01.ex` | qualified fn+trigger+CHECK, prefix-threaded down/1 | ✓ VERIFIED | All qualified; `SET search_path = ''`; citext unqualified |
| `lib/mailglass/migrations/postgres/v03.ex` | qualified complaint CHECK both directions | ✓ VERIFIED | ADD/DROP qualified in up/1 and down/1 |
| `credo_checks/no_schema_prefix_attribute.ex` | build-time `@schema_prefix` guard | ✓ VERIFIED | AST-based, path-scoped, registered, tested |
| `test/mailglass/schema_isolation_immutability_test.exs` | 45A01-without-path-pin proof | ✓ VERIFIED | Created; 6 tests; no search_path pin; green under mailglass axis |
| `test/mailglass/schema_axis_boot_order_test.exs` | fail-closed physical-table proof | ✓ VERIFIED | Asserts physical `mailglass.mailglass_events` via information_schema; green both axes |
| `config/runtime.exs` | MAILGLASS_SCHEMA test-env override | ✓ VERIFIED | Guarded `config_env() == :test`, non-empty value |
| `.github/workflows/advisory-matrix.yml` | schema axis both jobs | ✓ VERIFIED | public+mailglass rows, MAILGLASS_SCHEMA export, requires_workspace preserved |

### Key Link Verification

| From | To | Via | Status |
|---|---|---|---|
| `Migration.up/down` | dispatcher | `Config.schema()` → `Keyword.put_new(:prefix)` → `Postgres.up/down` | ✓ WIRED |
| `Postgres.up/1` | `CREATE SCHEMA` | `with_defaults` (`create_schema: prefix != public`) → `maybe_create_schema` | ✓ WIRED |
| `Postgres.change/3 :down` | `DROP SCHEMA RESTRICT` | `record_version(0)` → `maybe_drop_schema` guarded `target == 0` | ✓ WIRED |
| `v01.up/1` | qualified fn+trigger | `Identifier.validate!` → `q = inspect(prefix)` → qualified `execute` | ✓ WIRED |
| advisory-matrix.yml | `Config.schema/0` | `MAILGLASS_SCHEMA` env → `runtime.exs` → `config :mailglass, :schema` | ✓ WIRED |
| credo check | strict ruleset | registered in `.credo.exs` extra_checks | ✓ WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase tests, public axis | `mix test <migration+3 schema tests>` (fresh DB) | 23 tests, 0 failures | ✓ PASS |
| Phase tests, mailglass axis (LOAD-BEARING) | `MAILGLASS_SCHEMA=mailglass mix test <same>` (fresh DB) | 23 tests, 0 failures | ✓ PASS |
| Credo guard regression | `mix test no_schema_prefix_attribute_test + checks_have_tests_test` | 5 tests, 0 failures | ✓ PASS |
| Physical schema probe (mailglass axis) | `information_schema` + `pg_proc`/`pg_extension` query | `mailglass.mailglass_events` present; fn only in `mailglass` w/ `search_path=""`; citext in `public` | ✓ PASS |
| Credo strict on phase files | `mix credo --strict <6 phase files>` | no issues | ✓ PASS |
| No `@schema_prefix` in tree | `grep -rn @schema_prefix lib/mailglass/` | none | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|---|---|---|---|
| MIGR-01 | 134-01 | ✓ SATISFIED | `migration.ex` prefix injection (SC-1) |
| MIGR-02 | 134-01 | ✓ SATISFIED | `maybe_create_schema`/`maybe_drop_schema` (SC-2) |
| MIGR-03 | 134-02 | ✓ SATISFIED | schema-qualified fn+trigger, `SET search_path = ''` (SC-3) |
| MIGR-04 | 134-02 | ✓ SATISFIED | v01/v03 CHECKs + down drops qualified (SC-4) |
| MIGR-05 | 134-02 | ✓ SATISFIED | citext-public + 45A01-no-path-pin proof green (SC-5) |
| MIGR-06 | 134-03 | ✓ SATISFIED | NoSchemaPrefixAttribute guard (SC-6) |

All 6 declared requirement IDs cross-reference to REQUIREMENTS.md (lines 53-71, all `[x]`;
status table lines 153-158 all "Complete"). No orphaned requirements — REQUIREMENTS.md maps
exactly MIGR-01..06 to Phase 134, all claimed by plans.

### Anti-Patterns Found

None. No unreferenced `TBD`/`FIXME`/`XXX`/`HACK`/`PLACEHOLDER` markers in any phase-owned file.
All phase-134-modified files are `mix format --check-formatted` clean.

### Pre-Existing / Out-of-Scope Conditions (confirmed, not phase regressions)

- **D-15 credo warning** in `mailglass_inbound/lib/mailglass_inbound/application.ex` — file last
  touched by `feat(132-02)` (commit `90647119`), NOT by phase 134. `mix credo --strict` exits 16
  solely due to this pre-existing item; all phase-134 files are credo-clean. Correctly logged in
  `deferred-items.md`.
- **~216 full-`mix test` connection-pool failures** — verified pre-existing by the executor (identical
  count with changes stashed); affected files pass in isolation. Phase-owned targeted tests green.
  Correctly logged in `deferred-items.md`.
- **Format drift** in `test/mailglass/repo_test.exs` + `lib/mailglass/outbound.ex` — both Phase-133
  files, out of scope. Logged in `deferred-items.md`.

These are pre-existing and correctly scoped out per the phase note; not counted against this phase.

### Gaps Summary

None. All seven success criteria are verified against the actual codebase with both source-level
evidence and behavioral proof. The load-bearing MIGR-05 guarantee (SQLSTATE 45A01 under the
`mailglass` schema with no `search_path` pin) was exercised by running the targeted immutability
suite under `MAILGLASS_SCHEMA=mailglass` (green) and confirmed by direct physical DB probing
(function schema-scoped with empty search_path, citext in public, events table physically present).
The dual-schema CI axis is wired and proven locally passable under both `public` and `mailglass`.

All 9 phase commits verified present in history. Test DB restored to clean public state post-verification.

---

_Verified: 2026-07-02T21:35:00Z_
_Verifier: Claude (gsd-verifier)_
