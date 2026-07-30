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
