---
schema_version: 1
open_count: 2
waived_count: 0
fixed_count: 0
total_count: 2
last_updated: 2026-07-30T00:59:47.064Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 143 | deviation | test/mailglass/upgrade_v2_schema_migration_test.exs | 214 | Pre-existing 'down reverses the move' test failure on the mailglass schema axis (Class-A-adjacent restoration defect, confirmed on parent commit before 143-06's migration) — deferred to plan 143-07 | open |  | 2026-07-30T00:59:47.000Z |  |
| 2 | 143 | lint-warning | test/mailglass/migration_test.exs |  | redefining module Mailglass.TestRepo.Migrations.* warnings abort --warnings-as-errors runs after successful execution (pre-existing, both migration_test.exs and upgrade_v2_schema_migration_test.exs already in plan 143-07's files_modified) | open |  | 2026-07-30T00:59:47.064Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "143",
    "file": "test/mailglass/upgrade_v2_schema_migration_test.exs",
    "line": 214,
    "description": "Pre-existing 'down reverses the move' test failure on the mailglass schema axis (Class-A-adjacent restoration defect, confirmed on parent commit before 143-06's migration) — deferred to plan 143-07",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T00:59:47.000Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "lint-warning",
    "phase": "143",
    "file": "test/mailglass/migration_test.exs",
    "line": null,
    "description": "redefining module Mailglass.TestRepo.Migrations.* warnings abort --warnings-as-errors runs after successful execution (pre-existing, both migration_test.exs and upgrade_v2_schema_migration_test.exs already in plan 143-07's files_modified)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T00:59:47.064Z",
    "resolved_at": null
  }
]
````
