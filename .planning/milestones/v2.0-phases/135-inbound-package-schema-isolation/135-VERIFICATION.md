---
phase: 135-inbound-package-schema-isolation
verified: 2026-07-03T11:00:00Z
status: passed
score: 3/3
behavior_unverified: 0
overrides_applied: 0
---

# Phase 135: Inbound Package Schema Isolation — Verification Report

**Phase Goal:** Bring `mailglass_inbound` onto the same schema-isolation contract on its own version line — config key + facade threading + converting its loose `change/0` migration files to the prefix-aware version-dispatcher pattern core uses.

**Verified:** 2026-07-03
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `MailglassInbound.Repo` threads `put_prefix/1` through delegated reads/writes (insert/one/all/get), resolving inbound tables to the configured schema. `multi_opts/1` vacuously satisfied per approved planning adjustment (D-03 — zero Multi builders in inbound; YAGNI). | VERIFIED | `repo.ex` line 66: `defp put_prefix(opts), do: Keyword.put_new(opts, :prefix, MailglassInbound.Config.schema())` wired through `insert/2` (line 30), `one/2` (line 34), `all/2` (line 43), `get/3` (line 46). `transact/2` and `multi/2` correctly excluded. No `@schema_prefix` confirmed by grep. |
| 2 | Inbound's loose `change/0` migration files are converted to the prefix-aware version-dispatcher pattern (`MailglassInbound.Migration.up/down` + `Migrations.Postgres.V01`) issuing `CREATE SCHEMA IF NOT EXISTS` at the head with `prefix:` on every create table/index. | VERIFIED | All 4 artifacts present and substantive. `migration.ex`: `Keyword.put_new(opts, :prefix, MailglassInbound.Config.schema())` at line 34/44. `migrations/postgres.ex`: `@current_version 1`, `maybe_create_schema/1` issues `CREATE SCHEMA IF NOT EXISTS #{inspect(prefix)}` (line 108), `maybe_drop_schema` uses RESTRICT (never CASCADE). `v01.ex`: 3 tables with `prefix: prefix` on every `create table`/`index`/`unique_index` (15 create calls), zero `references()` carrying explicit `:prefix` (D-09 satisfied). 7 loose `.exs` files deleted — `priv/repo/migrations/` is empty. Generator emits delegating wrapper, no `create table` stub. |
| 3 | The inbound suite runs green under both `schema: "public"` and `schema: "mailglass"`. | VERIFIED | Orchestrator ran `mix test --seed 0` (388 tests / 0 failures) and `MAILGLASS_SCHEMA=mailglass mix test --seed 0` (388 tests / 0 failures). `test_helper.exs` reads `MAILGLASS_SCHEMA`, aligns `Config.schema/0` via `Application.put_env` + `:persistent_term.erase`, migrates via inline `TestMigration.Install` wrapper + `Ecto.Migrator.up/4`. `persist.ex` has `schema_opts/0` private helper (line 17) wired through all 6 direct `repo.insert/one` call sites (lines 163, 207, 248, 281, 310, 406). Advisory CI job `mailglass_inbound_dual_schema_advisory` present in `advisory-matrix.yml` (line 250) with `schema: [public, mailglass]` matrix, `MAILGLASS_SCHEMA: ${{ matrix.schema }}`, `--seed 0`, advisory/non-blocking. |

**Score:** 3/3 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mailglass_inbound/lib/mailglass_inbound/repo.ex` | `put_prefix/1` wired through insert/one/all/get | VERIFIED | Present and substantive. `Keyword.put_new` semantics confirmed. `transact/2`/`multi/2` excluded as designed. |
| `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex` | Inline `prefix: MailglassInbound.Config.schema()` on `delete_batched/3` DELETE; advisory-lock SQL unprefixed; `## Schema qualification` moduledoc | VERIFIED | Line 211: `prefix: MailglassInbound.Config.schema()` on `repo.delete_all(...)`. Advisory-lock `query!` calls unprefixed. Moduledoc section at line 14. |
| `mailglass_inbound/test/mailglass_inbound/repo_prefix_test.exs` | Schema-isolation assertions for facade default + prune DELETE target | VERIFIED | File exists. 8 deterministic tests covering facade prefix injection (via `CaptureRepo` fake) and prune DELETE schema target (real DB, non-existent schema assertion). |
| `mailglass_inbound/lib/mailglass_inbound/migration.ex` | Public migration API; `up/0`,`down/0`,`up/1`,`down/1`; `Keyword.put_new` prefix injection | VERIFIED | Present. All four arities via default args. `Keyword.put_new(opts, :prefix, MailglassInbound.Config.schema())` at lines 34 and 44. Adapter dispatch to `Migrations.Postgres`. |
| `mailglass_inbound/lib/mailglass_inbound/migrations/postgres.ex` | Runner with `CREATE SCHEMA IF NOT EXISTS` at head, `DROP SCHEMA … RESTRICT` at version 0, `mailglass_inbound_records` pg_class anchor, `Mailglass.Identifier.validate!/2` at every interpolation | VERIFIED | All present. `maybe_create_schema/1` + `maybe_drop_schema/1` guard on `create_schema` opt. `with_defaults/2` defaults `create_schema: true` when `prefix != "public"`. Version anchor queries `pg_class` on `mailglass_inbound_records` (line 67). `validate_identifier!` delegating to `Mailglass.Identifier.validate!/2` called at every raw DDL interpolation. |
| `mailglass_inbound/lib/mailglass_inbound/migrations/postgres/v01.ex` | Final-state snapshot; 3 tables; all historical indexes; `prefix:` on every table/index; no `references()` with explicit `:prefix` | VERIFIED | Present. 3 tables in FK-parent order (records → evidence → replay_runs). All historical indexes confirmed (base, postmark idempotency, 3 provider fingerprint, replay_runs indexes). Zero `references(…, prefix: …)` calls — D-09 satisfied. |
| `mailglass_inbound/lib/mix/tasks/mailglass.inbound.gen.migration.ex` | Delegating wrapper generator; no `create table` stub; `use Mix.Task` only | VERIFIED | Emits 8-line wrapper with `def up, do: MailglassInbound.Migration.up()` / `def down, do: MailglassInbound.Migration.down()`. Zero `create table` occurrences confirmed. `use Mix.Task` only (no `use Boundary`). |
| `mailglass_inbound/priv/repo/migrations/` | Empty — all 7 loose `.exs` files deleted | VERIFIED | `ls *.exs` returns nothing. Directory confirmed empty. |
| `mailglass_inbound/test/mailglass_inbound/migrations_test.exs` | up/down round-trip test under non-public prefix | VERIFIED | File exists. Tests cover: up creates all 3 tables + indexes, `migrated_version` transitions, full down drops tables + DROP SCHEMA RESTRICT, `create_schema: false` honored, D-07 anchor on `mailglass_inbound_records`. |
| `mailglass_inbound/test/test_helper.exs` | Rewired to `Migration.up/1`; `MAILGLASS_SCHEMA`-driven alignment of migrated schema + `Config.schema/0` | VERIFIED | Reads `MAILGLASS_SCHEMA` (line 53-57), `Application.put_env` (line 60), `:persistent_term.erase` (line 66), inline `TestMigration.Install` wrapper (line 70-82), `Ecto.Migrator.up/4` (line 109), `search_path` patch for non-public schemas (lines 93-99), `schema_migrations` cleanup (lines 131-136). |
| `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` | `schema_opts/0` private helper wired through all direct `repo.insert/one` call sites (Wave-2 Rule-2 fix) | VERIFIED | `schema_opts/0` at line 17 returning `[prefix: MailglassInbound.Config.schema()]`. Wired through 6 call sites at lines 163, 207, 248, 281, 310, 406. |
| `.github/workflows/advisory-matrix.yml` | `mailglass_inbound_dual_schema_advisory` job with `schema: [public, mailglass]` matrix, `MAILGLASS_SCHEMA` exported, `--seed 0`, advisory | VERIFIED | Job at line 250. Matrix with `schema: "public"` and `schema: "mailglass"` on Elixir 1.18 / OTP 27. `MAILGLASS_SCHEMA: ${{ matrix.schema }}` at line 322. `mix test --seed 0` at line 323. Not added to any required-status gate. |

---

## Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| `MailglassInbound.Repo.put_prefix/1` | `MailglassInbound.Config.schema/0` | `Keyword.put_new(opts, :prefix, MailglassInbound.Config.schema())` | WIRED |
| `MailglassInbound.Migration.up/1` | `MailglassInbound.Migrations.Postgres.up/1` | `migrator().up(opts)` via adapter dispatch | WIRED |
| `Migrations.Postgres.up/1` | `V01.up/1` | `change(@initial_version..opts.version, :up, opts)` → `Module.concat([__MODULE__, "V01"]) |> apply(:up, [opts])` | WIRED |
| `Mailglass.Identifier.validate!/2` | Every raw DDL interpolation in `Migrations.Postgres` | Called in `maybe_create_schema/1`, `maybe_drop_schema/1`, `record_version/2`, and `with_defaults/2` | WIRED |
| `MAILGLASS_SCHEMA` env | `Migration.up(prefix: schema)` AND `Config.schema/0` | `test_helper.exs`: `Application.put_env(:mailglass_inbound, :schema, schema)` + `:persistent_term.erase` + inline `TestMigration.Install` | WIRED |
| `persist.ex` direct repo calls | `MailglassInbound.Config.schema/0` | `schema_opts()` private helper passed as opts to all `repo.insert/one` calls | WIRED |

---

## Behavioral Spot-Checks

Step 7b: The orchestrator ran the full inbound suite under both schema axes before submitting. Behavioral evidence is sufficient; re-running the suite is explicitly waived per orchestrator instruction. Single-named behavioral tests are not repeated here.

| Behavior | Evidence | Status |
|----------|----------|--------|
| `put_prefix/1` injects `prefix: Config.schema()` on facade reads/writes | `repo_prefix_test.exs` via `CaptureRepo` fake (8 tests) | PASS (orchestrator ran full suite: 388/0) |
| Prune DELETE targets configured schema, not `public` | `repo_prefix_test.exs` non-public schema assertion (delete 0 rows in wrong schema) | PASS (same suite run) |
| Migration up/down round-trip under non-public prefix | `migrations_test.exs` (7 tests under `"inb_mig_test"` prefix) | PASS |
| Full suite green under `schema: "mailglass"` | `MAILGLASS_SCHEMA=mailglass mix test --seed 0` = 388 tests / 0 failures | PASS (orchestrator) |
| Full suite green under default `schema: "public"` | `mix test --seed 0` = 388 tests / 0 failures | PASS (orchestrator) |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| INB-01 | 135-01 | `MailglassInbound.Repo` threads `put_prefix/1` through delegated reads/writes (multi_opts/1 vacuously satisfied) | SATISFIED | `repo.ex` `put_prefix/1` wired on insert/one/all/get |
| INB-02 | 135-02 | Loose `change/0` migration files converted to version-dispatcher pattern with `CREATE SCHEMA IF NOT EXISTS` and `prefix:` threading | SATISFIED | Implementation complete — `migration.ex` + `migrations/postgres.ex` + `v01.ex` + generator present; 7 loose `.exs` files deleted |
| INB-03 | 135-03 | Inbound suite runs green under both `schema: "public"` and `schema: "mailglass"` | SATISFIED | 388 tests / 0 failures on both axes confirmed by orchestrator |

**Note — REQUIREMENTS.md tracking gap (WARNING, not BLOCKER):** INB-02 remains `[ ]` (unchecked) and "Pending" in the REQUIREMENTS.md tracking table (lines 84, 164) despite the implementation being fully delivered. This is a documentation inconsistency — the codebase evidence is unambiguous. The checkbox and tracking row should be updated to `[x]` / "Complete" as a follow-up before milestone close.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None detected | — | — | — | — |

No `TBD`, `FIXME`, or `XXX` markers found in any phase-modified file. No return-null stubs, hardcoded empty-data returns, or orphaned artifacts detected.

---

## Human Verification Required

None. All truths are statically verifiable or covered by the orchestrator's dual-schema test runs (388/0 on both axes).

---

## Gaps Summary

No gaps in implementation. The only finding is a documentation tracking inconsistency: REQUIREMENTS.md has INB-02 as `[ ]` / "Pending" while the implementation is fully delivered in commit `1c14a41a` (V01 snapshot) and `9ffd8d20` (migration entrypoint + runner). This should be resolved before milestone close by updating the checkbox and tracking row to `[x]` / "Complete".

---

_Verified: 2026-07-03T11:00:00Z_
_Verifier: Claude (gsd-verifier)_
