---
schema_version: 1
open_count: 3
waived_count: 0
fixed_count: 2
total_count: 5
last_updated: 2026-07-30T02:20:05.006Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 143 | deviation | test/mailglass/upgrade_v2_schema_migration_test.exs | 214 | Pre-existing 'down reverses the move' test failure on the mailglass schema axis (Class-A-adjacent restoration defect, confirmed on parent commit before 143-06's migration) — deferred to plan 143-07 | fixed |  | 2026-07-30T00:59:47.000Z | 2026-07-30T01:48:58.587Z |
| 2 | 143 | lint-warning | test/mailglass/migration_test.exs |  | redefining module Mailglass.TestRepo.Migrations.* warnings abort --warnings-as-errors runs after successful execution (pre-existing, both migration_test.exs and upgrade_v2_schema_migration_test.exs already in plan 143-07's files_modified) | fixed |  | 2026-07-30T00:59:47.064Z | 2026-07-30T01:48:58.722Z |
| 3 | 143 | deviation | test/mailglass/schema_isolation_immutability_test.exs | 213 | Pre-existing 'migrating down against prefix mailglass succeeds' failure on the mailglass axis — same Ecto.Migrator.down/4 bookkeeping-ambiguity root cause as the upgrade_v2_schema_migration_test.exs down-test fixed in 143-07, but the prefix:"public" fix does not transfer here (PrefixedWrapperMigration's create table(prefix:"mailglass") DSL macros raise Ecto.MigrationError when the outer migrator prefix differs); needs prefix: Mailglass.Config.schema() instead, deferred to a follow-up | open |  | 2026-07-30T01:49:09.727Z |  |
| 4 | 143 | deviation | test/mailglass/persistence_integration_test.exs | 228 | migrated_version() == 0 on the mailglass axis (reproduces standalone) — Mailglass.Migrations.Postgres.migrated_version/1 hardcodes @default_prefix "public" (lib/mailglass/migrations/postgres.ex:8), a lib-level default unrelated to Sandbox-ownership Class A/B/C; needs prefix: Mailglass.Config.schema() threaded through, out of this plan's test-only files_modified scope | open |  | 2026-07-30T02:20:04.900Z |  |
| 5 | 143 | deviation | test/mailglass/upgrade/v0_2_test.exs |  | Pre-existing Rewrite.Error: no source found failures (Igniter/Rewrite generator test-fixture subsystem, unrelated to Sandbox ownership) — reproduces standalone, last touched at commits b3acce29/750e5eda long before Phase 143; also affects test/mix/tasks/mailglass.gen.mailable_test.exs | open |  | 2026-07-30T02:20:05.006Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "143",
    "file": "test/mailglass/upgrade_v2_schema_migration_test.exs",
    "line": 214,
    "description": "Pre-existing 'down reverses the move' test failure on the mailglass schema axis (Class-A-adjacent restoration defect, confirmed on parent commit before 143-06's migration) — deferred to plan 143-07",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-30T00:59:47.000Z",
    "resolved_at": "2026-07-30T01:48:58.587Z"
  },
  {
    "id": 2,
    "kind": "lint-warning",
    "phase": "143",
    "file": "test/mailglass/migration_test.exs",
    "line": null,
    "description": "redefining module Mailglass.TestRepo.Migrations.* warnings abort --warnings-as-errors runs after successful execution (pre-existing, both migration_test.exs and upgrade_v2_schema_migration_test.exs already in plan 143-07's files_modified)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-30T00:59:47.064Z",
    "resolved_at": "2026-07-30T01:48:58.722Z"
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "143",
    "file": "test/mailglass/schema_isolation_immutability_test.exs",
    "line": 213,
    "description": "Pre-existing 'migrating down against prefix mailglass succeeds' failure on the mailglass axis — same Ecto.Migrator.down/4 bookkeeping-ambiguity root cause as the upgrade_v2_schema_migration_test.exs down-test fixed in 143-07, but the prefix:\"public\" fix does not transfer here (PrefixedWrapperMigration's create table(prefix:\"mailglass\") DSL macros raise Ecto.MigrationError when the outer migrator prefix differs); needs prefix: Mailglass.Config.schema() instead, deferred to a follow-up",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T01:49:09.727Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "deviation",
    "phase": "143",
    "file": "test/mailglass/persistence_integration_test.exs",
    "line": 228,
    "description": "migrated_version() == 0 on the mailglass axis (reproduces standalone) — Mailglass.Migrations.Postgres.migrated_version/1 hardcodes @default_prefix \"public\" (lib/mailglass/migrations/postgres.ex:8), a lib-level default unrelated to Sandbox-ownership Class A/B/C; needs prefix: Mailglass.Config.schema() threaded through, out of this plan's test-only files_modified scope",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T02:20:04.900Z",
    "resolved_at": null
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "143",
    "file": "test/mailglass/upgrade/v0_2_test.exs",
    "line": null,
    "description": "Pre-existing Rewrite.Error: no source found failures (Igniter/Rewrite generator test-fixture subsystem, unrelated to Sandbox ownership) — reproduces standalone, last touched at commits b3acce29/750e5eda long before Phase 143; also affects test/mix/tasks/mailglass.gen.mailable_test.exs",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T02:20:05.006Z",
    "resolved_at": null
  }
]
````
