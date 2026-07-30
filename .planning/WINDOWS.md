---
schema_version: 1
open_count: 2
waived_count: 0
fixed_count: 6
total_count: 8
last_updated: 2026-07-30T18:46:50.738Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 143 | deviation | test/mailglass/upgrade_v2_schema_migration_test.exs | 214 | Pre-existing 'down reverses the move' test failure on the mailglass schema axis (Class-A-adjacent restoration defect, confirmed on parent commit before 143-06's migration) — deferred to plan 143-07 | fixed |  | 2026-07-30T00:59:47.000Z | 2026-07-30T01:48:58.587Z |
| 2 | 143 | lint-warning | test/mailglass/migration_test.exs |  | redefining module Mailglass.TestRepo.Migrations.* warnings abort --warnings-as-errors runs after successful execution (pre-existing, both migration_test.exs and upgrade_v2_schema_migration_test.exs already in plan 143-07's files_modified) | fixed |  | 2026-07-30T00:59:47.064Z | 2026-07-30T01:48:58.722Z |
| 3 | 143 | deviation | test/mailglass/schema_isolation_immutability_test.exs | 213 | Pre-existing 'migrating down against prefix mailglass succeeds' failure on the mailglass axis — same Ecto.Migrator.down/4 bookkeeping-ambiguity root cause as the upgrade_v2_schema_migration_test.exs down-test fixed in 143-07, but the prefix:"public" fix does not transfer here (PrefixedWrapperMigration's create table(prefix:"mailglass") DSL macros raise Ecto.MigrationError when the outer migrator prefix differs); needs prefix: Mailglass.Config.schema() instead, deferred to a follow-up | fixed |  | 2026-07-30T01:49:09.727Z | 2026-07-30T05:09:01.520Z |
| 4 | 143 | deviation | test/mailglass/persistence_integration_test.exs | 228 | migrated_version() == 0 on the mailglass axis (reproduces standalone) — Mailglass.Migrations.Postgres.migrated_version/1 hardcodes @default_prefix "public" (lib/mailglass/migrations/postgres.ex:8), a lib-level default unrelated to Sandbox-ownership Class A/B/C; needs prefix: Mailglass.Config.schema() threaded through, out of this plan's test-only files_modified scope | fixed |  | 2026-07-30T02:20:04.900Z | 2026-07-30T03:36:44.010Z |
| 5 | 143 | deviation | test/mailglass/upgrade/v0_2_test.exs |  | Pre-existing Rewrite.Error: no source found failures (Igniter/Rewrite generator test-fixture subsystem, unrelated to Sandbox ownership) — reproduces standalone, last touched at commits b3acce29/750e5eda long before Phase 143; also affects test/mix/tasks/mailglass.gen.mailable_test.exs | fixed |  | 2026-07-30T02:20:05.006Z | 2026-07-30T03:36:44.079Z |
| 6 | 143 | deviation | test/mailglass/properties/webhook_signature_failure_test.exs | 75 | Transient SandboxOwnership.LeakError on the mailglass-axis full-suite run only (not reproducible standalone, 2/2 clean isolated runs) — same benign settle-delay-under-heavy-pool-churn class 143-05 fixed for webhook_idempotency_convergence_test.exs via widened settle_attempts/interval_ms; this property may need the same widened window if it recurs. Class C/D-17 territory (143-04/05/08), not this plan's Class A/B scope | open |  | 2026-07-30T02:31:56.233Z |  |
| 7 | 143 | deviation | test/mailglass/schema_isolation_immutability_test.exs | 217 | SUPERSEDES id 3's suggested fix: prefix: Mailglass.Config.schema() ("mailglass") for the outer Ecto.Migrator up/4+down/4 calls was implemented and empirically reproduces a genuine ~20s+ Postgres lock deadlock in do_lock_for_migrations (not just a failed assertion) — Ecto's own schema_migrations bookkeeping table then lives inside the very 'mailglass' schema this test's down/0 drops via DROP SCHEMA...RESTRICT, and the migration body's DROP runs before Migrator's own bookkeeping DELETE, so RESTRICT never sees an empty schema. Reverted to original code (clean, non-hanging failure). Real fix needs either bypassing Ecto.Migrator's public API (call the private Ecto.Migration.Runner.run/8 directly) or a Rule-4 architectural change to how the shipped Vxx migration modules thread :prefix through create table(...) DSL calls — both out of test-only scope. See 143-07-SUMMARY.md Orchestrator-directed gap closure section for full evidence. | fixed |  | 2026-07-30T03:37:03.181Z | 2026-07-30T05:09:01.453Z |
| 8 | 143 | unrun-verify | .github/workflows/advisory-matrix.yml |  | 143-10: no post-change advisory-matrix.yml dispatch with MAILGLASS_SUITE_FLOOR live (process constraints forbid dispatch); the 1.19/OTP 28 legs now enforce floors measured on the 1.18 legs and have never executed on this branch | open |  | 2026-07-30T18:46:50.738Z |  |

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
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-30T01:49:09.727Z",
    "resolved_at": "2026-07-30T05:09:01.520Z"
  },
  {
    "id": 4,
    "kind": "deviation",
    "phase": "143",
    "file": "test/mailglass/persistence_integration_test.exs",
    "line": 228,
    "description": "migrated_version() == 0 on the mailglass axis (reproduces standalone) — Mailglass.Migrations.Postgres.migrated_version/1 hardcodes @default_prefix \"public\" (lib/mailglass/migrations/postgres.ex:8), a lib-level default unrelated to Sandbox-ownership Class A/B/C; needs prefix: Mailglass.Config.schema() threaded through, out of this plan's test-only files_modified scope",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-30T02:20:04.900Z",
    "resolved_at": "2026-07-30T03:36:44.010Z"
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "143",
    "file": "test/mailglass/upgrade/v0_2_test.exs",
    "line": null,
    "description": "Pre-existing Rewrite.Error: no source found failures (Igniter/Rewrite generator test-fixture subsystem, unrelated to Sandbox ownership) — reproduces standalone, last touched at commits b3acce29/750e5eda long before Phase 143; also affects test/mix/tasks/mailglass.gen.mailable_test.exs",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-30T02:20:05.006Z",
    "resolved_at": "2026-07-30T03:36:44.079Z"
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "143",
    "file": "test/mailglass/properties/webhook_signature_failure_test.exs",
    "line": 75,
    "description": "Transient SandboxOwnership.LeakError on the mailglass-axis full-suite run only (not reproducible standalone, 2/2 clean isolated runs) — same benign settle-delay-under-heavy-pool-churn class 143-05 fixed for webhook_idempotency_convergence_test.exs via widened settle_attempts/interval_ms; this property may need the same widened window if it recurs. Class C/D-17 territory (143-04/05/08), not this plan's Class A/B scope",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T02:31:56.233Z",
    "resolved_at": null
  },
  {
    "id": 7,
    "kind": "deviation",
    "phase": "143",
    "file": "test/mailglass/schema_isolation_immutability_test.exs",
    "line": 217,
    "description": "SUPERSEDES id 3's suggested fix: prefix: Mailglass.Config.schema() (\"mailglass\") for the outer Ecto.Migrator up/4+down/4 calls was implemented and empirically reproduces a genuine ~20s+ Postgres lock deadlock in do_lock_for_migrations (not just a failed assertion) — Ecto's own schema_migrations bookkeeping table then lives inside the very 'mailglass' schema this test's down/0 drops via DROP SCHEMA...RESTRICT, and the migration body's DROP runs before Migrator's own bookkeeping DELETE, so RESTRICT never sees an empty schema. Reverted to original code (clean, non-hanging failure). Real fix needs either bypassing Ecto.Migrator's public API (call the private Ecto.Migration.Runner.run/8 directly) or a Rule-4 architectural change to how the shipped Vxx migration modules thread :prefix through create table(...) DSL calls — both out of test-only scope. See 143-07-SUMMARY.md Orchestrator-directed gap closure section for full evidence.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-30T03:37:03.181Z",
    "resolved_at": "2026-07-30T05:09:01.453Z"
  },
  {
    "id": 8,
    "kind": "unrun-verify",
    "phase": "143",
    "file": ".github/workflows/advisory-matrix.yml",
    "line": null,
    "description": "143-10: no post-change advisory-matrix.yml dispatch with MAILGLASS_SUITE_FLOOR live (process constraints forbid dispatch); the 1.19/OTP 28 legs now enforce floors measured on the 1.18 legs and have never executed on this branch",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T18:46:50.738Z",
    "resolved_at": null
  }
]
````
