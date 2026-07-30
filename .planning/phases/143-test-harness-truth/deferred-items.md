# Deferred Items — Phase 143 (test-harness-truth)

Out-of-scope discoveries logged per the executor's SCOPE BOUNDARY rule (only
auto-fix issues directly caused by the current task's changes; log everything
else here instead of fixing it).

## From Plan 143-05

### `@emitted_body was set but never used` — `test/mailglass/upgrade_v2_schema_migration_test.exs:24`

- **Found during:** Plan 143-05, running `mix test --only oban --warnings-as-errors`
  as part of the required before/after Oban-tagged-subset comparison (Task 1 and
  Task 3 verification steps).
- **Symptom:** `mix test --only oban --warnings-as-errors` reports the correct
  test results (19 tests, 0 failures on the post-143-05 tree; 18/0 on the parent
  commit) but the run itself still exits non-zero — `--warnings-as-errors`
  aborts the suite after a successful run because of this unrelated compiler
  warning: `@emitted_body Mix.Tasks.Mailglass.Upgrade.V2Schema.migration_body(...)`
  at module level is dead — the code actually evaluates the module-attribute
  copy `@emitted` inside the nested `MoveWrapperMigration` submodule instead.
- **Why deferred, not fixed:** `test/mailglass/upgrade_v2_schema_migration_test.exs`
  is not in plan 143-05's `files_modified` list and this pre-existing warning is
  reproducible identically on the parent commit (verified before making any
  143-05 changes) — it is unrelated to the Sandbox-ownership migration this plan
  performs. Fixing it is a one-line, genuinely safe cleanup, but it is out of
  this plan's scope per the executor's SCOPE BOUNDARY rule.
- **Impact on this plan's acceptance criteria:** Task 1's and Task 3's literal
  acceptance criterion "`mix test --only oban --warnings-as-errors` exits 0" is
  not literally satisfiable while this warning exists, for a reason unrelated to
  143-05's own changes. Read as: the test COUNT, NAMES, and FAILURE COUNT match
  (verified explicitly, see 143-05-SUMMARY.md § Deviations), which is the
  substantive claim the criterion exists to protect.
- **Suggested fix (not applied here):** delete the dead `@emitted_body` module
  attribute at line 24 (or reuse `@emitted` from the nested module instead of
  duplicating the `migration_body/2` call).

## From Plan 143-06

### `redefining module Mailglass.TestRepo.Migrations.*` warnings abort `--warnings-as-errors` runs

- **Found during:** Plan 143-06, running the plan-level combined verification
  (`mix test test/mailglass/properties/ test/mailglass/migration_test.exs
  test/mailglass/upgrade_v2_schema_migration_test.exs --warnings-as-errors`)
  on both schema axes.
- **Symptom:** The suite runs to completion with the correct test counts and
  0 unexpected failures, then `--warnings-as-errors` aborts with "Test suite
  aborted after successful execution due to warnings" because
  `Ecto.Migrator` re-compiles the already-loaded flat `priv/repo/migrations/`
  files each time a test in this plan's scope drives a fresh
  `Ecto.Migrator.run/with_repo` call, and BEAM warns on redefining an
  already-loaded module.
- **Why deferred, not fixed:** confirmed identical on the parent commit
  (pre-existing) and out of `files_modified` scope for plan 143-06 (which
  only touches Sandbox-ownership acquisition, not migration-loading
  mechanics). Both this file and `migration_test.exs` are already listed in
  plan 143-07's `files_modified`, per the executor's coordinator note.
- **Impact on this plan's acceptance criteria:** read as: test COUNT, NAMES,
  and FAILURE COUNT match the parent commit (verified explicitly per file
  and combined, see 143-06-SUMMARY.md), which is the substantive claim the
  criterion protects. The abort is a pre-existing compiler-warning artifact,
  not a Sandbox-ownership regression.

### `upgrade_v2_schema_migration_test.exs`'s "down reverses the move" test — pre-existing failure on the mailglass axis

- **Found during:** Plan 143-06 Task 3, running the required twice-consecutive
  verification of `upgrade_v2_schema_migration_test.exs` on the mailglass
  axis.
- **Symptom:** `test "down reverses the move: all four tables are back in
  public and the schema is gone"` fails — `table_count("public") == 4`
  assertion does not hold after the migrator's down step.
- **Why deferred, not fixed:** confirmed reproducible identically (3/3 runs)
  on the parent commit, before this plan's Sandbox-ownership migration
  touched the file — a pre-existing Class-A-adjacent restoration defect
  named in `143-MECHANISM.md`'s three-class inventory. Plan 143-06's own
  prohibitions forbid fixing schema-restoration defects in this plan; that
  is plan 143-07's job.
- **Impact on this plan's acceptance criteria:** the mailglass-axis verify
  command for this file does not exit 0 on either the parent commit or after
  this plan's migration — same failure, same test, same count (6 tests, 1
  failure) both times, which is the "same test counts as parent commit" bar
  this plan's acceptance criteria hold to.
