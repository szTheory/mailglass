---
schema_version: 1
open_count: 10
waived_count: 0
fixed_count: 10
total_count: 20
last_updated: 2026-08-24T20:37:02.538Z
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
| 8 | 143 | unrun-verify | .github/workflows/advisory-matrix.yml |  | 143-10: no post-change advisory-matrix.yml dispatch with MAILGLASS_SUITE_FLOOR live (process constraints forbid dispatch); the 1.19/OTP 28 legs now enforce floors measured on the 1.18 legs and have never executed on this branch | fixed | Closed 2026-07-31: advisory-matrix.yml ran on main with MAILGLASS_SUITE_FLOOR live; the 1.19/OTP 28 legs executed for the first time and passed with the floor enforced (run 30635221221: executed 1623 >= floor 1576). See 143-MAIN-GREEN-EVIDENCE.md. | 2026-07-30T18:46:50.738Z | 2026-07-31T14:05:00.000Z |
| 9 | 143 | unrun-verify | .github/workflows/advisory-matrix.yml |  | 143-11: no push/dispatch run confirming the post-rename runtime job names (research assumption A5); process constraints forbid dispatch. Owned by 143-12's promotion checkpoint. | fixed | Closed 2026-07-31: post-rename runtime job names confirmed on main runs 30607136165 (schedule) and 30635221221 (push) — 'Core Full Suite (...)' and 'Core Full Suite Next Toolchain Advisory (...)' both reported as expected. A5 confirmed. | 2026-07-30T19:20:38.246Z | 2026-07-31T14:05:00.000Z |
| 10 | 143 | unmet-truth | test/mailglass/compliance/unsubscribe_test.exs | 29 | 143-12 Finding B: setup on_exit restores via Application.put_all_env, which CANNOT remove the :tenancy key the test adds (lines 103/216) — leaking a tenancy resolver whose scope/2 applies as: :scoped globally. Causes nondeterministic Ecto.Query.CompileError in SupportSummary/schema_isolation tests (observed CI run 30571989203, seed 590679, mailglass leg). Sibling unsubscribe_property_test.exs:52 already carries the explicit delete_env fix. Blocks HARNESS-04 promotion: the lane proposed for publish-veto fails nondeterministically. | fixed |  | 2026-07-30T19:58:33.370Z | 2026-07-30T21:11:14.430Z |
| 11 | 143 | unrun-verify | .planning/phases/143-test-harness-truth/143-PROMOTION-CHECKPOINT.md |  | 143-12 conditions 3 and 4 NOT RUN: no tag-shaped-ref workflow_dispatch of advisory-matrix.yml and no gate-self-test.yml deliberate-failure probe against the renamed Core Full Suite lane. Process constraints forbid pushing and triggering Actions. Verbatim dispatch commands recorded in 143-PROBE-EVIDENCE.md and the checkpoint. | fixed | Closed 2026-07-31: condition 3 run on a tag-shaped ref (both gating legs green, tag deleted); condition 4 probe observed both gating legs FAILURE on the injected regression (run 30599206217). Recorded in 143-PROBE-EVIDENCE.md, including that the probe was manual because gate-self-test.yml cannot trigger CI on a GITHUB_TOKEN-opened PR. | 2026-07-30T19:58:41.893Z | 2026-07-31T14:05:00.000Z |
| 12 | 143 | unmet-truth | test/support/suite_truth_formatter.ex | 239 | SuiteTruthFormatter.async_false?/1 is DEAD CODE: it reads %ExUnit.TestModule{}.tags[:async], but that field is %{} for every module on Elixir 1.19.5 (verified by dumping the struct live at :module_finished; the module's own __ex_unit__/0 also returns tags: %{}). The expression is therefore nil == false, i.e. false, on every boundary — so ALL FOUR module-boundary probes (Class A baseline_missing, Class B config_schema_drift, Class C pool_mode_leaked, and the :cannot_verify paths) have NEVER executed, and the ledger's '0 record(s)' has never meant anything. 143-MECHANISM.md section 7 attributed the quiet ledger to the boundary-only observation window; that explanation is incomplete — the probes were not observing a narrow window, they were not observing at all. async-ness IS available from %ExUnit.Test{}.tags[:async] at :test_started/:test_finished. Fixing it locally (learn per-module from test events; report :unknown as :cannot_verify) made the real suite report 103 module-boundary violations on the public axis at seed 590679: 88 app_env_drift, 13 cannot_verify, 2 pool_mode_leaked. NOT SHIPPED in the app-env gap closure: resurrecting it turns ~15 unrelated pre-existing Class A/C defects into gating-lane violations under MAILGLASS_SUITE_FLOOR=1 and needs its own plan with per-defect mutation proofs. | open |  | 2026-07-30T21:11:45.856Z |  |
| 13 | 143 | unmet-truth | test/support/suite_floor.ex | 787 | SuiteFloor reports formatter_violations=0 from a DEAD formatter. SuiteTruthFormatter's own unit tests call handle_cast({:suite_finished, ...}) directly with synthetic quiet state, which writes %{signature_tally: %{}, violations: []} to the shared :persistent_term key. The moduledoc argues this is safe because the live formatter's :suite_finished write always comes last — true only while the formatter survives the run. Observed live: when probe_baseline_tables/2 raised (DBConnection.ConnectionError propagating out of baseline_tally), the GenServer died mid-suite, never reached :suite_finished, and SuiteFloor read the unit tests' synthetic snapshot and printed 'already_shared=0, formatter_violations=0' plus '0 violation(s)' — a green report from an instrument that had crashed. read_formatter_tally/0's :unavailable -> :cannot_verify path cannot fire because the key is always populated by the unit tests. Needs a liveness/run-identity marker in the snapshot, not just its presence. | open |  | 2026-07-30T21:11:45.918Z |  |
| 14 | 143 | unmet-truth | test/mailglass/webhook/providers/ses/cert_cache_test.exs |  | Two REAL Class C sandbox-ownership leaks are live and invisible today, surfaced only by locally fixing SuiteTruthFormatter's dead async gate (see the async_false?/1 entry): Mailglass.Webhook.Providers.SES.CertCacheTest leaves the pool in {:shared, pid} at its module boundary, and Mailglass.UpgradeV2SchemaGenerationTest does too (Mailglass.Outbound.DeliverManyTest was separately observed leaving it in :auto). HARNESS-01's ':already_shared count is exactly zero' passes vacuously alongside these because the tally counts raised failures, not leaked pool modes, and the probe that would have named them never ran. | open |  | 2026-07-30T21:11:45.979Z |  |
| 15 | 143 | unmet-truth | test/support/data_case.ex |  | Application env is mutated concurrently by async: true modules, so no whole-env restore can be installed in the shared case templates today. Adding SandboxOwnership.with_app_env!(:mailglass) to DataCase/MailerCase/WebhookCase was tried and reverted: its verification raised for Mailglass.ComplianceTest and Mailglass.Operator.TimelineTest with NO key added or removed (a VALUE differed), i.e. a concurrent writer moved the env between one module's restore and its verify. Root cause is the pre-existing policy violation, not the seam: compliance_test.exs (:tracking, :compliance) and clock_test.exs (:clock) are async: true while mutating env the code under test reads, which this repo's own async policy (D-11 reason 2) already forbids. Phase 143 may not change any file's async: value, so both use per-key fetch_env/delete_env restores instead and the case templates remain unguarded. | open |  | 2026-07-30T21:11:46.041Z |  |
| 16 | 143 | unmet-truth | config/test.exs | 19 | config :mailglass, tenancy: is pinned to Mailglass.Tenancy.SingleTenant at boot, but mid-suite the key holds nil. Found when a mechanism-test precondition asserting get_env(:mailglass, :tenancy) != nil failed inside the full suite while passing standalone. Origin is the presence-blind restore chain: once any module leaves :tenancy absent or nil, every later 'prior_tenancy = get_env(...); put_env(..., prior_tenancy)' site propagates the nil forward. Benign today only because Mailglass.Tenancy.resolver/0 maps nil back to SingleTenant; it is still undetected global-state drift on a key config/test.exs pins, and it is what makes any get_env-with-default read of :tenancy resolve to nil instead of its default. | open |  | 2026-07-30T21:11:46.106Z |  |
| 17 | 143 | unrun-verify | .github/workflows/publish-hex.yml |  | gate-ci-green's advisory-matrix dispatch-and-poll has never executed on a real release SHA; only a live release (or plan 143-14's rehearsal) can confirm the tag-ref dispatch, the shared 30-minute deadline, and the fan-out settle behave as designed | open |  | 2026-07-31T15:09:13.616Z |  |
| 18 | 143 | lint-warning | test/support/suite_floor.ex |  | SuiteFloor executed_nudge fires on the gating toolchain: 1630 executed vs pinned floor 1575 on the mailglass axis, 55 above the 40-test nudge margin. Advisory only, halts nothing. Already over margin on main before this plan (run 30635221221 showed 1623 vs 1576). Re-pinning must be measured from a real CI run per 143-10's protocol, not locally | open |  | 2026-07-31T15:09:13.698Z |  |
| 19 | 157 | deviation | lib/mailglass/suppression_store/ecto.ex | 205 | Nil stream bulk predicate bug auto-fixed during Plan 157-07. | open |  | 2026-08-17T09:01:29.628Z |  |
| 20 | 162 | unrun-verify | test/scripts/release_trigger_recovery_test.exs |  | Complete release-trigger recovery test file exceeded the interactive runner window before final completion. | open |  | 2026-08-24T20:37:02.538Z |  |

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
    "status": "fixed",
    "reason": "Closed 2026-07-31: advisory-matrix.yml ran on main with MAILGLASS_SUITE_FLOOR live; the 1.19/OTP 28 legs executed for the first time and passed with the floor enforced (run 30635221221: executed 1623 >= floor 1576). See 143-MAIN-GREEN-EVIDENCE.md.",
    "recorded_at": "2026-07-30T18:46:50.738Z",
    "resolved_at": "2026-07-31T14:05:00.000Z"
  },
  {
    "id": 9,
    "kind": "unrun-verify",
    "phase": "143",
    "file": ".github/workflows/advisory-matrix.yml",
    "line": null,
    "description": "143-11: no push/dispatch run confirming the post-rename runtime job names (research assumption A5); process constraints forbid dispatch. Owned by 143-12's promotion checkpoint.",
    "status": "fixed",
    "reason": "Closed 2026-07-31: post-rename runtime job names confirmed on main runs 30607136165 (schedule) and 30635221221 (push) — 'Core Full Suite (...)' and 'Core Full Suite Next Toolchain Advisory (...)' both reported as expected. A5 confirmed.",
    "recorded_at": "2026-07-30T19:20:38.246Z",
    "resolved_at": "2026-07-31T14:05:00.000Z"
  },
  {
    "id": 10,
    "kind": "unmet-truth",
    "phase": "143",
    "file": "test/mailglass/compliance/unsubscribe_test.exs",
    "line": 29,
    "description": "143-12 Finding B: setup on_exit restores via Application.put_all_env, which CANNOT remove the :tenancy key the test adds (lines 103/216) — leaking a tenancy resolver whose scope/2 applies as: :scoped globally. Causes nondeterministic Ecto.Query.CompileError in SupportSummary/schema_isolation tests (observed CI run 30571989203, seed 590679, mailglass leg). Sibling unsubscribe_property_test.exs:52 already carries the explicit delete_env fix. Blocks HARNESS-04 promotion: the lane proposed for publish-veto fails nondeterministically.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-30T19:58:33.370Z",
    "resolved_at": "2026-07-30T21:11:14.430Z"
  },
  {
    "id": 11,
    "kind": "unrun-verify",
    "phase": "143",
    "file": ".planning/phases/143-test-harness-truth/143-PROMOTION-CHECKPOINT.md",
    "line": null,
    "description": "143-12 conditions 3 and 4 NOT RUN: no tag-shaped-ref workflow_dispatch of advisory-matrix.yml and no gate-self-test.yml deliberate-failure probe against the renamed Core Full Suite lane. Process constraints forbid pushing and triggering Actions. Verbatim dispatch commands recorded in 143-PROBE-EVIDENCE.md and the checkpoint.",
    "status": "fixed",
    "reason": "Closed 2026-07-31: condition 3 run on a tag-shaped ref (both gating legs green, tag deleted); condition 4 probe observed both gating legs FAILURE on the injected regression (run 30599206217). Recorded in 143-PROBE-EVIDENCE.md, including that the probe was manual because gate-self-test.yml cannot trigger CI on a GITHUB_TOKEN-opened PR.",
    "recorded_at": "2026-07-30T19:58:41.893Z",
    "resolved_at": "2026-07-31T14:05:00.000Z"
  },
  {
    "id": 12,
    "kind": "unmet-truth",
    "phase": "143",
    "file": "test/support/suite_truth_formatter.ex",
    "line": 239,
    "description": "SuiteTruthFormatter.async_false?/1 is DEAD CODE: it reads %ExUnit.TestModule{}.tags[:async], but that field is %{} for every module on Elixir 1.19.5 (verified by dumping the struct live at :module_finished; the module's own __ex_unit__/0 also returns tags: %{}). The expression is therefore nil == false, i.e. false, on every boundary — so ALL FOUR module-boundary probes (Class A baseline_missing, Class B config_schema_drift, Class C pool_mode_leaked, and the :cannot_verify paths) have NEVER executed, and the ledger's '0 record(s)' has never meant anything. 143-MECHANISM.md section 7 attributed the quiet ledger to the boundary-only observation window; that explanation is incomplete — the probes were not observing a narrow window, they were not observing at all. async-ness IS available from %ExUnit.Test{}.tags[:async] at :test_started/:test_finished. Fixing it locally (learn per-module from test events; report :unknown as :cannot_verify) made the real suite report 103 module-boundary violations on the public axis at seed 590679: 88 app_env_drift, 13 cannot_verify, 2 pool_mode_leaked. NOT SHIPPED in the app-env gap closure: resurrecting it turns ~15 unrelated pre-existing Class A/C defects into gating-lane violations under MAILGLASS_SUITE_FLOOR=1 and needs its own plan with per-defect mutation proofs.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T21:11:45.856Z",
    "resolved_at": null
  },
  {
    "id": 13,
    "kind": "unmet-truth",
    "phase": "143",
    "file": "test/support/suite_floor.ex",
    "line": 787,
    "description": "SuiteFloor reports formatter_violations=0 from a DEAD formatter. SuiteTruthFormatter's own unit tests call handle_cast({:suite_finished, ...}) directly with synthetic quiet state, which writes %{signature_tally: %{}, violations: []} to the shared :persistent_term key. The moduledoc argues this is safe because the live formatter's :suite_finished write always comes last — true only while the formatter survives the run. Observed live: when probe_baseline_tables/2 raised (DBConnection.ConnectionError propagating out of baseline_tally), the GenServer died mid-suite, never reached :suite_finished, and SuiteFloor read the unit tests' synthetic snapshot and printed 'already_shared=0, formatter_violations=0' plus '0 violation(s)' — a green report from an instrument that had crashed. read_formatter_tally/0's :unavailable -> :cannot_verify path cannot fire because the key is always populated by the unit tests. Needs a liveness/run-identity marker in the snapshot, not just its presence.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T21:11:45.918Z",
    "resolved_at": null
  },
  {
    "id": 14,
    "kind": "unmet-truth",
    "phase": "143",
    "file": "test/mailglass/webhook/providers/ses/cert_cache_test.exs",
    "line": null,
    "description": "Two REAL Class C sandbox-ownership leaks are live and invisible today, surfaced only by locally fixing SuiteTruthFormatter's dead async gate (see the async_false?/1 entry): Mailglass.Webhook.Providers.SES.CertCacheTest leaves the pool in {:shared, pid} at its module boundary, and Mailglass.UpgradeV2SchemaGenerationTest does too (Mailglass.Outbound.DeliverManyTest was separately observed leaving it in :auto). HARNESS-01's ':already_shared count is exactly zero' passes vacuously alongside these because the tally counts raised failures, not leaked pool modes, and the probe that would have named them never ran.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T21:11:45.979Z",
    "resolved_at": null
  },
  {
    "id": 15,
    "kind": "unmet-truth",
    "phase": "143",
    "file": "test/support/data_case.ex",
    "line": null,
    "description": "Application env is mutated concurrently by async: true modules, so no whole-env restore can be installed in the shared case templates today. Adding SandboxOwnership.with_app_env!(:mailglass) to DataCase/MailerCase/WebhookCase was tried and reverted: its verification raised for Mailglass.ComplianceTest and Mailglass.Operator.TimelineTest with NO key added or removed (a VALUE differed), i.e. a concurrent writer moved the env between one module's restore and its verify. Root cause is the pre-existing policy violation, not the seam: compliance_test.exs (:tracking, :compliance) and clock_test.exs (:clock) are async: true while mutating env the code under test reads, which this repo's own async policy (D-11 reason 2) already forbids. Phase 143 may not change any file's async: value, so both use per-key fetch_env/delete_env restores instead and the case templates remain unguarded.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T21:11:46.041Z",
    "resolved_at": null
  },
  {
    "id": 16,
    "kind": "unmet-truth",
    "phase": "143",
    "file": "config/test.exs",
    "line": 19,
    "description": "config :mailglass, tenancy: is pinned to Mailglass.Tenancy.SingleTenant at boot, but mid-suite the key holds nil. Found when a mechanism-test precondition asserting get_env(:mailglass, :tenancy) != nil failed inside the full suite while passing standalone. Origin is the presence-blind restore chain: once any module leaves :tenancy absent or nil, every later 'prior_tenancy = get_env(...); put_env(..., prior_tenancy)' site propagates the nil forward. Benign today only because Mailglass.Tenancy.resolver/0 maps nil back to SingleTenant; it is still undetected global-state drift on a key config/test.exs pins, and it is what makes any get_env-with-default read of :tenancy resolve to nil instead of its default.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T21:11:46.106Z",
    "resolved_at": null
  },
  {
    "id": 17,
    "kind": "unrun-verify",
    "phase": "143",
    "file": ".github/workflows/publish-hex.yml",
    "line": null,
    "description": "gate-ci-green's advisory-matrix dispatch-and-poll has never executed on a real release SHA; only a live release (or plan 143-14's rehearsal) can confirm the tag-ref dispatch, the shared 30-minute deadline, and the fan-out settle behave as designed",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-31T15:09:13.616Z",
    "resolved_at": null
  },
  {
    "id": 18,
    "kind": "lint-warning",
    "phase": "143",
    "file": "test/support/suite_floor.ex",
    "line": null,
    "description": "SuiteFloor executed_nudge fires on the gating toolchain: 1630 executed vs pinned floor 1575 on the mailglass axis, 55 above the 40-test nudge margin. Advisory only, halts nothing. Already over margin on main before this plan (run 30635221221 showed 1623 vs 1576). Re-pinning must be measured from a real CI run per 143-10's protocol, not locally",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-31T15:09:13.698Z",
    "resolved_at": null
  },
  {
    "id": 19,
    "kind": "deviation",
    "phase": "157",
    "file": "lib/mailglass/suppression_store/ecto.ex",
    "line": 205,
    "description": "Nil stream bulk predicate bug auto-fixed during Plan 157-07.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-17T09:01:29.628Z",
    "resolved_at": null
  },
  {
    "id": 20,
    "kind": "unrun-verify",
    "phase": "162",
    "file": "test/scripts/release_trigger_recovery_test.exs",
    "line": null,
    "description": "Complete release-trigger recovery test file exceeded the interactive runner window before final completion.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-24T20:37:02.538Z",
    "resolved_at": null
  }
]
````
