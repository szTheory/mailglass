---
schema_version: 1
open_count: 1
waived_count: 0
fixed_count: 2
total_count: 3
last_updated: 2026-07-30T01:49:09.727Z
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
  }
]
````
