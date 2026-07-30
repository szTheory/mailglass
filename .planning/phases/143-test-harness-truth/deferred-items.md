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

## From Plan 143-07

Both items above (`@emitted_body` dead attribute, `redefining module
Mailglass.TestRepo.Migrations.*` warnings) are RESOLVED by this plan — see
`test/mailglass/upgrade_v2_schema_migration_test.exs` (dead attribute
removed) and `Mailglass.TestSupport.SandboxOwnership.reloading_flat_migrations/1`
(scopes `Code.put_compiler_option(:ignore_module_conflict, true)` around
every flat-`priv/repo/migrations/`-reloading `Ecto.Migrator.run/4` call site
in `migration_test.exs`, `upgrade_v2_schema_migration_test.exs`,
`schema_prefix_hardening_test.exs`, `schema_isolation_integration_test.exs`,
`schema_isolation_immutability_test.exs`, restored in an `after` block so a
genuine redefinition warning elsewhere still surfaces). The "down reverses
the move" pre-existing failure is also RESOLVED — root-caused to
`Ecto.Migrator.up/4`'s and `down/4`'s own schema_migrations bookkeeping
being ambient-current-schema-dependent absent an explicit `:prefix`; both
calls now pin `prefix: "public"` (safe: `public` always exists and is never
dropped by any file in this suite, and the wrapper's run-unique version
number never collides with the flat baseline migrations' own bookkeeping).

### NEW: `schema_isolation_immutability_test.exs`'s "migrating down against prefix mailglass succeeds" test — pre-existing failure on the mailglass axis, same bookkeeping-ambiguity ROOT CAUSE, NOT fixable by the same technique

- **Found during:** Plan 143-07, investigating whether the same
  `Ecto.Migrator.down/4` bookkeeping-ambiguity root cause (fixed in
  `upgrade_v2_schema_migration_test.exs` via `prefix: "public"`) also affects
  this file's structurally identical `PrefixedWrapperMigration` down/4 call.
- **Symptom:** `test "migrating down against prefix mailglass succeeds and
  the schema is gone"` fails on the mailglass axis (confirmed reproducible on
  the parent commit, before any 143-07 change touched this file) —
  `Ecto.Migrator.down/4`'s "is this version applied?" check misses the
  version `up/4` recorded (the identical shape to the "down reverses the
  move" bug), leaving the `mailglass` schema behind (`schema_count == 1`
  instead of `0`).
- **Why the `upgrade_v2_schema_migration_test.exs` fix does NOT transfer
  here:** `PrefixedWrapperMigration.up/0` calls
  `Mailglass.Migration.up(prefix: "mailglass", repo: ...)`, which internally
  uses `Ecto.Migration`'s `create table(prefix: ...)` DSL macros — and Ecto
  explicitly VALIDATES that a migration's own `create table(prefix: ...)`
  matches the outer `Ecto.Migrator.up/4`/`down/4` call's `:prefix` option,
  raising `Ecto.MigrationError: the :prefix option "mailglass" does not
  match the migrator prefix "public"` the moment `prefix: "public"` is
  applied outside. `upgrade_v2_schema_migration_test.exs`'s
  `MoveWrapperMigration` avoided this entirely because its content is raw
  `execute/1` SQL strings (no `create table(prefix: ...)` macro use), so no
  such validation applies there — confirmed by reproducing the
  `Ecto.MigrationError` live when the same `prefix: "public"` fix was applied
  here, then reverting it.
- **Why deferred, not fixed:** `schema_isolation_immutability_test.exs` is
  not named as a Class A candidate in `143-MECHANISM.md`'s three-class
  inventory (only `migration_test.exs`, `upgrade_v2_schema_migration_test.exs`,
  and `schema_prefix_hardening_test.exs` are), and a correct fix here needs a
  DIFFERENT mechanism than the one this plan validated elsewhere (e.g.
  threading `prefix: "mailglass"` through consistently on both up/4 and
  down/4 instead of "public", which needs its own from-scratch verification
  this plan's time budget does not cover safely). Confirmed reproducible
  identically on the parent commit (public axis: 6/6 pass; mailglass axis: 1
  pre-existing failure, same test, same shape) before and after this plan's
  Class B `with_schema!/2` migration and the `reloading_flat_migrations/1`
  warning fix, neither of which touch this defect.
- **Impact on this plan's acceptance criteria:** none of this plan's Task 1
  or Task 2 acceptance criteria name this file's down-test; Task 3's
  full-suite `:baseline_missing`/`:config_schema_drift` tallies are the
  binding bar and are evaluated against the full suite, not this isolated
  file.
- **Suggested fix (not applied here):** thread `prefix: Mailglass.Config.schema()`
  (here always `"mailglass"`, since this test never overrides `:schema`)
  through BOTH the `up/4` and `down/4` calls consistently instead of
  `"public"` — the schema already exists by the time each call runs (created
  by the `up/4` call's own `Mailglass.Migration.up/1` before this test even
  starts), so the chicken-and-egg risk that ruled out this approach for
  `upgrade_v2_schema_migration_test.exs` (schema not yet existing when
  `ensure_schema_migrations_table!` runs) does not apply the same way here —
  worth a dedicated follow-up plan/verification pass.

### Isolated 5-file mailglass-axis run artifact — NOT independently investigated further

- **Found during:** Plan 143-07, running
  `MAILGLASS_SCHEMA=mailglass mix test test/mailglass/schema_prefix_hardening_test.exs
  test/mailglass/schema_isolation_integration_test.exs
  test/mailglass/schema_isolation_immutability_test.exs
  test/mailglass/shipped_migration_divergence_test.exs
  test/mailglass/upgrade_v2_schema_migration_test.exs` (Task 1's own literal
  verify command, extended to the mailglass axis as extra diligence) against
  a genuinely fresh database (`mix ecto.drop && mix ecto.create` immediately
  before).
- **Symptom:** `shipped_migration_divergence_test.exs` shows 4 failures
  (`schema_migrations_pkey` unique-constraint violations) not reproduced when
  the full suite runs (143-MECHANISM.md's own mailglass-axis capture records
  only 10 total `42P01` hits across the ENTIRE 200+-file suite, far fewer
  than this 5-file isolated run's own failure count).
- **Why deferred, not fixed:** `shipped_migration_divergence_test.exs` is not
  named as a Class A/B candidate in `143-MECHANISM.md` and is not in this
  plan's `files_modified`. Confirmed reproducible identically on the parent
  commit under the same isolated-5-file, fresh-DB condition (not a
  regression). Isolated-file-subset runs are known to differ from the full
  suite (other files establish/restore state a subset run does not see) —
  Task 3's actual full-suite run on both axes is the binding measurement,
  not this isolated combination.
- **Impact on this plan's acceptance criteria:** none directly — Task 1's own
  `<verify>` block only requires the PUBLIC axis for this exact file
  combination (confirmed 24/24 tests passing there, unchanged from parent).

## From Plan 143-07 Task 3 (post-fix full-suite verification)

### `Mailglass.RepoTest` — LIVE Class B `config_schema_drift` bug found and FIXED (not deferred)

- **Found during:** Task 3's own required post-fix full-suite run
  (`MAILGLASS_SANDBOX_TRACE=1 mix test --warnings-as-errors --exclude
  requires_workspace --seed 0`, public axis) — 104 failures, almost all
  `relation "mailglass.mailglass_suppressions" does not exist` starting at
  `Mailglass.Compliance.UnsubscribeControllerTest`, the sync module
  immediately following `Mailglass.RepoTest` in `--seed 0`'s (unshuffled)
  execution order.
- **Root cause:** `test/mailglass/repo_test.exs`'s two schema-overriding
  `setup` blocks restored via `Application.delete_env(:mailglass, :schema)`
  instead of `Application.put_env(:mailglass, :schema, "public")`. Deleting
  the key does not restore config/test.exs's `"public"` boot pin — the very
  next `Mailglass.Config.schema/0` call (here, `SuiteTruthFormatter`'s own
  drift probe, or any later DataCase-based test) re-warms `:persistent_term`
  via `Mailglass.Config.warm_schema/0`'s own `Application.get_env(:mailglass,
  :schema, "mailglass")` — whose *default* is `"mailglass"`, not `"public"`.
  Confirmed directly: `Application.delete_env/2` then
  `Application.get_env(key, "mailglass")` returns `"mailglass"`.
- **Why fixed here despite not being in `files_modified` or named in
  `143-MECHANISM.md`'s inventory:** the coordinator's own instruction is
  explicit — "The ledger names the culprits, not the research candidates...
  If 143-MECHANISM.md's inventory disagrees ... the ledger wins." This
  plan's Task 3 must-have is a hard "ZERO `:config_schema_drift` violations
  suite-wide" bar; leaving a live, evidence-confirmed Class B source unfixed
  would make that bar unreachable regardless of what else this plan does.
- **Fix:** both setups now call `SandboxOwnership.with_schema!/2` (the same
  restore-first seam Task 1 built), which captures via `Config.schema/0`
  and restores via `Application.put_env/3` — never `delete_env/2`.
- **Verified:** post-fix full-suite public-axis run: 104 failures -> 6 (the
  6 remaining are unrelated pre-existing `Rewrite.Error`s, logged below).

### `SchemaPrefixHardeningTest`'s `assert_public_delivery_absent!/1` and `unsubscribe_event_count/2` — Rule 1 fix (not deferred)

- **Found during:** Task 3's mailglass-axis full-suite run — 2 failures,
  `relation "public.mailglass_deliveries"/"public.mailglass_events" does not
  exist` (`42P01`), NOT a drift symptom: `public.mailglass_*` genuinely does
  not exist at all under a clean mailglass-axis run until some OTHER file
  transiently creates it, which is a STRONGER form of "the row/event is not
  in public" than an empty table — the correct assertion outcome, not a
  test failure.
- **Root cause:** both helpers used `TestRepo.query!` (raises on a missing
  relation) instead of checking existence first, unlike the sibling
  `public_row_count/2` pattern already established in
  `schema_isolation_integration_test.exs`.
- **Fix:** added `public_table_exists?/1` (same `information_schema.tables`
  check as the sibling file) and route both helpers through it, treating "no
  such table" as count 0 rather than raising.
- **Verified:** both axes pass in isolation on a genuinely fresh DB
  (previously only reproducible on the exact "nothing has created
  `public.mailglass_*` yet" mailglass-axis ordering the full suite exercises).

### `Mailglass.PersistenceIntegrationTest`'s `migrated_version/0 == 0` on the mailglass axis — deferred, lib-level, out of test-harness scope

- **Found during:** Task 3's mailglass-axis full-suite run.
- **Symptom:** `assert Mailglass.Migration.migrated_version() ==
  Mailglass.Migrations.Postgres.current_version()` — `left: 0, right: 5`.
  Reproduces standalone (`mix test test/mailglass/persistence_integration_test.exs`
  on a fresh mailglass-axis DB, nothing else in the suite involved) — NOT an
  ordering/leak artifact.
- **Root cause:** `Mailglass.Migrations.Postgres.migrated_version/1`'s
  `with_defaults/2` hardcodes `@default_prefix "public"`
  (`lib/mailglass/migrations/postgres.ex:8,134`) — the test calls
  `Mailglass.Migration.migrated_version()` with NO args, so the query always
  targets `public.mailglass_events`'s pg_class comment, which genuinely
  carries no comment on the mailglass axis (the real marker lives under
  `mailglass.mailglass_events`). The test needed to pass
  `prefix: Mailglass.Config.schema()` explicitly and does not.
- **Why deferred, not fixed:** the fix lives in a LIBRARY default
  (`lib/mailglass/migrations/postgres.ex`) or requires threading an explicit
  `:prefix` through this specific test call site — `lib/` is out of this
  plan's `files_modified` scope entirely, and this is a general
  schema-isolation-axis test coverage gap (D-06/Success Criterion 7's
  territory from Phase 134), not a Sandbox-ownership leak (Class A/B/C) —
  HARNESS-01/02's actual target. `persistence_integration_test.exs` is not
  named in `143-MECHANISM.md`'s three-class inventory.
- **Suggested fix (not applied here):** either change the test call site to
  `Mailglass.Migration.migrated_version(prefix: Mailglass.Config.schema())`,
  or (a larger, Phase-134-adjacent change) make
  `Mailglass.Migrations.Postgres`'s own default prefix resolve through
  `Mailglass.Config.schema()` rather than a hardcoded `"public"` literal.

### Pre-existing `Rewrite.Error: no source found` failures (Igniter generator tests) — unrelated subsystem, deferred

- **Found during:** Task 3's full-suite runs, both axes (6 failures on
  public, matching subset on mailglass): `test/mailglass/upgrade/v0_2_test.exs`
  and `test/mix/tasks/mailglass.gen.mailable_test.exs`.
- **Symptom:** `** (Rewrite.Error) no source found for "lib/..."` inside
  `assert_file_content/3`, an Igniter/Rewrite test-fixture helper.
- **Why deferred, not fixed:** reproduces identically in isolation
  (`mix test test/mailglass/upgrade/v0_2_test.exs
  test/mix/tasks/mailglass.gen.mailable_test.exs`), unrelated to any file
  this plan touches (both files last modified at commits `b3acce29` /
  `750e5eda`, long before Phase 143). This is an Igniter/Rewrite dependency
  version or test-fixture issue in the code-generation subsystem —
  completely unrelated to Sandbox ownership (Class A/B/C), which is
  HARNESS-01/02's actual target. Not named in `143-MECHANISM.md`.
- **Impact on this plan's acceptance criteria:** none of Task 3's tracked
  classes (`:pool_mode_leaked`, `:config_schema_drift`, `:baseline_missing`,
  `:cannot_verify`) are implicated — these are ordinary `ExUnit` test
  failures in an unrelated subsystem, counted in `total`/failures like any
  other pre-existing red, not masked or excluded.
