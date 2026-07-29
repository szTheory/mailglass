---
phase: 135-inbound-package-schema-isolation
plan: "02"
subsystem: mailglass_inbound/migrations
tags: [migrations, schema-isolation, inbound, postgres, INB-02]
status: complete

dependency_graph:
  requires:
    - 135-01 (MailglassInbound.Config.schema/0 + MailglassInbound.Repo.put_prefix/1)
    - lib/mailglass/migration.ex (mirror template)
    - lib/mailglass/migrations/postgres.ex (mirror template)
    - Mailglass.Identifier.validate!/2 (single unquoted-identifier chokepoint, D-11)
  provides:
    - MailglassInbound.Migration (public migration entrypoint)
    - MailglassInbound.Migrations.Postgres (runner + CREATE/DROP SCHEMA lifecycle)
    - MailglassInbound.Migrations.Postgres.V01 (final-state snapshot, all 3 tables)
    - Mix.Tasks.Mailglass.Inbound.Gen.Migration (delegating-wrapper generator)
    - test/mailglass_inbound/migrations_test.exs (up/down round-trip proof)
  affects:
    - mailglass_inbound/priv/repo/migrations/ (7 loose .exs files deleted)
    - Adopters: install path now stable (single delegating wrapper, not 7 files to copy)

tech_stack:
  added: []
  patterns:
    - Oban-precedent version-dispatcher chain: Migration -> Migrations.Postgres -> V01
    - Independent pg_class version anchor (mailglass_inbound_records, not mailglass_events)
    - Keyword.put_new prefix injection (explicit caller prefix wins)
    - Final-state snapshot (D-08): collapses 7 historical migrations into 1 clean V01
    - Prefix threading via Ecto DSL keyword (D-09: no :prefix on references())
    - Identifier validation at every raw DDL interpolation (T-135-03, D-11)
    - RESTRICT (never CASCADE) for DROP SCHEMA (T-135-04)

key_files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/migration.ex
    - mailglass_inbound/lib/mailglass_inbound/migrations/postgres.ex
    - mailglass_inbound/lib/mailglass_inbound/migrations/postgres/v01.ex
    - mailglass_inbound/lib/mix/tasks/mailglass.inbound.gen.migration.ex
    - mailglass_inbound/test/mailglass_inbound/migrations_test.exs
  modified: []
  deleted:
    - mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs
    - mailglass_inbound/priv/repo/migrations/20260506180000_add_postmark_ingress_idempotency.exs
    - mailglass_inbound/priv/repo/migrations/20260506210000_generalize_replay_runs_to_execution_lineage.exs
    - mailglass_inbound/priv/repo/migrations/20260506220000_add_sendgrid_fingerprint_and_replay_contract_fields.exs
    - mailglass_inbound/priv/repo/migrations/20260523120000_add_mailgun_fingerprint_index.exs
    - mailglass_inbound/priv/repo/migrations/20260523130000_add_ses_fingerprint_index.exs
    - mailglass_inbound/priv/repo/migrations/20260525000000_add_suppression_flagged_to_inbound_records.exs

decisions:
  - "D-08: V01 inlines suppression_flagged, raw_mime_fingerprint generated column, and replay_runs nullable columns at final state — no backfill execute() calls in a snapshot migration"
  - "D-09: references() carries no :prefix; FK inherits the enclosing create table block prefix (Ecto DSL guarantee)"
  - "D-10: V01 contains zero raw #{prefix}. DDL — only the runner owns CREATE/DROP SCHEMA/COMMENT interpolation"
  - "D-11: Every raw interpolation gated through Mailglass.Identifier.validate!/2 before inspect/1"
  - "Down driver test pattern: PrefixDownDriver.up/0 calls Migration.down/1 to get DDL into the active Runner context — mirrors core migration_test.exs inline-migration approach"

metrics:
  duration: "13 minutes"
  completed_at: "2026-07-03T08:56:44Z"
  tasks_completed: 3
  tasks_total: 3
  files_created: 5
  files_deleted: 7
---

# Phase 135 Plan 02: Inbound Migration Stack — Version-Dispatcher + V01 Snapshot Summary

Prefix-aware inbound migration stack mirroring core + Oban precedent: `MailglassInbound.Migration` entrypoint, `Migrations.Postgres` runner with `CREATE SCHEMA IF NOT EXISTS` at the head, single `V01` final-state snapshot collapsing 7 historical loose `.exs` files, and a delegating-wrapper generator — with an independent `mailglass_inbound_records` pg_class version anchor (D-07).

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | MailglassInbound.Migration entrypoint + Postgres runner | 9ffd8d20 | migration.ex, migrations/postgres.ex |
| 2 | V01 final-state snapshot + delete 7 loose migration files | 1c14a41a | migrations/postgres/v01.ex, priv/repo/migrations/ (7 deleted) |
| 3 | mix mailglass.inbound.gen.migration generator + round-trip test | 65bde07d | mix/tasks/mailglass.inbound.gen.migration.ex, migrations_test.exs |

## What Was Built

### Task 1: MailglassInbound.Migration + Migrations.Postgres

`MailglassInbound.Migration` mirrors `Mailglass.Migration` exactly:
- `up/0`, `down/0`, `up/1`, `down/1` — default args give zero-arity wrappers for free
- `up/1` injects `prefix: MailglassInbound.Config.schema()` via `Keyword.put_new` (explicit caller prefix wins)
- `migrated_version/1` injects `:repo` from `Application.get_env(:mailglass_inbound, :repo)`
- Adapter dispatch: `Ecto.Adapters.Postgres` -> `Migrations.Postgres`; anything else raises clear `RuntimeError`

`MailglassInbound.Migrations.Postgres` runner:
- `@current_version 1`, `@initial_version 1`, `@default_prefix "public"`
- `up/1`: `maybe_create_schema` (gated on `create_schema: true`, default `prefix != "public"`) FIRST, then version-dispatch
- `down/1`: version-dispatch THEN `maybe_drop_schema` at version 0 only
- `migrated_version/1`: queries `pg_class`/`pg_namespace` join on `mailglass_inbound_records` (D-07 independent anchor)
- `maybe_create_schema`: `CREATE SCHEMA IF NOT EXISTS "#{prefix}"` (Identifier.validate! before inspect)
- `maybe_drop_schema`: `DROP SCHEMA IF EXISTS "#{prefix}" RESTRICT` (never CASCADE, T-135-04)
- `record_version`: `COMMENT ON TABLE "#{prefix}".mailglass_inbound_records IS '#{version}'`
- No `use Boundary` on either module (inbound does not run the boundary compiler)

### Task 2: V01 Final-State Snapshot

`MailglassInbound.Migrations.Postgres.V01` collapses all 7 historical migrations into a single greenfield final-state snapshot:

**mailglass_inbound_records** (tables ordered FK-parent first):
- All base columns from migration 1 + `suppression_flagged :boolean, null: false, default: false` (migration 7, inline)
- Base indexes: `[:tenant_id]`, `[:tenant_id, :provider]`
- Postmark idempotency partial unique index (migration 2): `[:tenant_id, :provider, :provider_message_id] WHERE provider_message_id IS NOT NULL`

**mailglass_inbound_evidence**:
- Base columns + `raw_mime_fingerprint :text STORED GENERATED` (migration 4, inline — expression is same-row column only, no raw DDL needed)
- `unique_index([:inbound_record_id])`, `index([:tenant_id])`
- 3 provider fingerprint partial unique indexes (sendgrid/mailgun/ses, migrations 4/5/6)
- `inbound_record_id` FK via `references/2` with NO `:prefix` (D-09)

**mailglass_inbound_replay_runs**:
- `replay_id` and `mailbox` NULLABLE (migration 3 final state), `source :text NOT NULL DEFAULT 'replay'` (migration 3, inline)
- No backfill `execute()` or `ALTER COLUMN ... DROP NOT NULL` (D-08: forward-only, empty-table)
- Both FKs via `references/2` with NO `:prefix` (D-09)
- `unique_index([:tenant_id, :replay_id])`, `index([:tenant_id, :inbound_record_id])`, `index([:tenant_id, :inbound_evidence_id])`

`down/1` drops in reverse FK order: replay_runs -> evidence -> records. No raw `#{prefix}.` DDL in V01 (D-10).

The 7 loose `.exs` files in `priv/repo/migrations/` were deleted. The directory is now empty.

### Task 3: Generator + Round-Trip Test

`Mix.Tasks.Mailglass.Inbound.Gen.Migration`:
- Emits an 8-line delegating wrapper (`def up, do: MailglassInbound.Migration.up()`)
- Idempotent: detects existing `*_mailglass_inbound_install.exs` and skips
- No `use Boundary`, no `create table` stub (corrects the known bug in core's generator)
- `use Mix.Task` only, `mailglass.inbound.*` namespace (4th verb alongside doctor/prune/replay)

`migrations_test.exs` proves the full lifecycle under prefix `"inb_mig_test"`:
- up creates schema + all 3 tables + all indexes; `migrated_version` returns `current_version`
- down to version 0 drops all 3 tables + DROP SCHEMA RESTRICT; `migrated_version` returns 0
- `migrated_version` transitions: 0 before up, current_version after up, 0 after full down
- D-07 anchor: version comment is on `mailglass_inbound_records`, not `mailglass_events`
- `create_schema: false` skips CREATE SCHEMA; tables land in pre-existing schema
- `Migration.up/0` and `down/0` are exported (zero-arity wrappers compile)

All 7 tests green with `--seed 0`.

## Threat Mitigations Applied

| Threat ID | Mitigation Applied |
|-----------|-------------------|
| T-135-03 | Every raw DDL interpolation (CREATE SCHEMA, DROP SCHEMA, COMMENT ON TABLE) gated through `Mailglass.Identifier.validate!/2` before `inspect/1` in both `Migrations.Postgres` and `V01.down/1` |
| T-135-04 | `DROP SCHEMA IF EXISTS "<prefix>" RESTRICT` (never CASCADE) in `maybe_drop_schema/1`; fires only at version 0 teardown after all tables are dropped |
| T-135-05 | Inbound version anchor on `mailglass_inbound_records`; core anchor on `mailglass_events` — fully independent version lines even in a shared schema |

## Deviations from Plan

None — plan executed exactly as written. One implementation detail note:

**Down-driver test pattern:** `PrefixDownDriver.up/0` calls `Migration.down/1` inside the active Ecto.Migration Runner context (driven via `Ecto.Migrator.up(repo, down_version, PrefixDownDriver)`). This mirrors core's `migration_test.exs` inline-migration approach for exercising DDL that requires a live Runner process. The plan specified the round-trip test prove up/down; this approach is the standard pattern for testing migration down paths without loose .exs files.

**Initial test flakiness (self-correcting):** The first test run after deleting the 7 loose `.exs` files showed test failures because leftover DB state (`inb_mig_test` schema) from a partial prior run was present. Once the stale schema was dropped by the on_exit cleanup, subsequent runs are fully stable and deterministic. The `on_exit` block cleans `DROP SCHEMA IF EXISTS inb_mig_test CASCADE` which eliminates this class of flakiness going forward.

## Self-Check: PASSED

Files exist:
- /Users/jon/projects/mailglass/mailglass_inbound/lib/mailglass_inbound/migration.ex — FOUND
- /Users/jon/projects/mailglass/mailglass_inbound/lib/mailglass_inbound/migrations/postgres.ex — FOUND
- /Users/jon/projects/mailglass/mailglass_inbound/lib/mailglass_inbound/migrations/postgres/v01.ex — FOUND
- /Users/jon/projects/mailglass/mailglass_inbound/lib/mix/tasks/mailglass.inbound.gen.migration.ex — FOUND
- /Users/jon/projects/mailglass/mailglass_inbound/test/mailglass_inbound/migrations_test.exs — FOUND

Commits exist:
- 9ffd8d20 — Task 1 (entrypoint + runner)
- 1c14a41a — Task 2 (V01 snapshot + delete loose files)
- 65bde07d — Task 3 (generator + round-trip test)

Loose files: priv/repo/migrations/ contains no .exs files — CONFIRMED
references() with prefix: — none in v01.ex — CONFIRMED
create table in generator — absent — CONFIRMED
All verifications: mix compile --warnings-as-errors, mix format --check-formatted, mix test --seed 0: PASSED
