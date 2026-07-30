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

- **UPDATE (orchestrator-directed gap closure): this suggested fix was
  implemented and empirically DISPROVEN — it is worse than the status quo,
  not better.** Pre-creating the schema and passing
  `prefix: @prefix` (`"mailglass"`) to both the setup's `up/4` call and the
  test's `down/4` call does avoid the `Ecto.MigrationError` mismatch (the
  outer `runner_prefix` now matches `PrefixedWrapperMigration`'s own
  `create table(prefix: "mailglass")` DSL calls) — but it makes Ecto's OWN
  `schema_migrations` bookkeeping table live INSIDE the very `"mailglass"`
  schema this migration's `down/0` callback drops via
  `DROP SCHEMA "mailglass" RESTRICT`. `Ecto.Migrator.async_migrate_maybe_in_
  transaction/6`'s own ordering runs the migration body (the DROP) BEFORE
  the bookkeeping DELETE that would empty the schema first — so `RESTRICT`
  can never see an empty schema at the moment it checks, regardless of any
  lock-strategy tuning. Reproduced live TWICE as a genuine ~20-60s Postgres
  lock deadlock inside `Ecto.Adapters.Postgres.do_lock_for_migrations`
  (`pg_stat_activity` confirmed one connection "idle in transaction" holding
  the table lock while a second connection was blocked waiting on it to
  execute the `DROP SCHEMA`), not merely a failed assertion. `prefix: "public"`
  was already ruled out (raises `Ecto.MigrationError` on the DSL mismatch);
  `prefix: "mailglass"` is now also ruled out (deadlocks). **There is no
  single `:prefix` value that satisfies both Ecto's DSL-consistency check
  AND avoids the self-referential-drop conflict, because Ecto's public API
  conflates "bookkeeping table location" and "DSL validation target" into
  the same option** — confirmed by reading `Ecto.Migration.__prefix__/1`
  and `Ecto.Migration.SchemaMigration.ensure_schema_migrations_table!/3`
  directly. Reverted to the original code (no explicit outer `:prefix`,
  the clean, non-hanging, single documented assertion failure). This also
  explains WHY the identical root mechanism made `test_helper.exs` exclude
  `migration_test.exs`'s own `:public_only` down block entirely on the
  mailglass axis (see that file's own comment, lines 55-58) — this is a
  known, pre-existing class of self-conflict on this axis, not unique to
  this file. The two remaining viable paths, both out of this plan's
  test-only scope: (a) bypass `Ecto.Migrator.up/4`/`down/4`'s public API
  entirely and drive `Ecto.Migration.Runner.run/8` directly (an undocumented,
  `@moduledoc false` internal — a real but riskier coupling in the same
  spirit as `SandboxOwnership.probe/1`'s `:sys.get_state/1` precedent), or
  (b) a Rule-4 architectural change to how `Mailglass.Migrations.Postgres`'s
  `Vxx` modules thread `:prefix` through `create table(...)` DSL calls (would
  affect the real shipped adopter migration path — out of scope for a
  test-harness fix). Logged as `.planning/WINDOWS.md` id 7 (supersedes id 3's
  stale suggested-fix text).

- **RESOLVED (orchestrator-directed gap closure, second pass): path (a) above
  was implemented and it closes the failure cleanly — no deadlock, no
  weakened assertion.** `test/mailglass/schema_isolation_immutability_test.exs`'s
  down-test now drives `Ecto.Migration.Runner.run/8` directly instead of
  `Ecto.Migrator.down/4`, for the down call only (the setup's `up/4` call is
  unchanged — it already worked). A throwaway probe script (not committed)
  first confirmed the ACTUAL root cause precisely, correcting the deadlock
  write-up above for the *unmodified* (no explicit `:prefix`) code path
  specifically: `Ecto.Migrator.up/4`/`down/4` conflate two concerns behind
  one `:prefix` option — the DDL validation target
  (`Ecto.Migration.__prefix__/1`, checked against the migration's own
  `create table(prefix: ...)` calls) and the `schema_migrations` bookkeeping
  location (`Ecto.Migration.SchemaMigration.ensure_schema_migrations_table!/3`,
  `versions/3`, both keyed on `opts[:prefix]` directly, with NO
  runner-prefix fallback). With no explicit `:prefix` (this test's original,
  reverted code), DDL validation is skipped entirely (fine), but bookkeeping
  resolves via the AMBIENT `search_path` (`"mailglass, public"` on this
  axis, per `test_helper.exs`). Confirmed live: at `up/4` time `mailglass`
  does not exist yet (this test's own pre-clean just dropped it), so the
  unqualified `CREATE TABLE IF NOT EXISTS schema_migrations` lands in
  `public` — the version row goes there. At `down/4` time `mailglass` now
  DOES exist (created by `up/4`'s own `maybe_create_schema/1`), and
  Postgres's `IF NOT EXISTS` existence check is scoped to the RESOLVED
  TARGET schema only (not search-path-wide) — so `ensure_schema_migrations_
  table!/3` silently creates a SECOND, empty `schema_migrations` table
  INSIDE `mailglass` (now first in the ambient search path), the version
  lookup against it comes back empty, and `Ecto.Migrator.down/4` concludes
  `:already_down` and never even attempts the `DROP SCHEMA` — no deadlock,
  no raised error, just a silently skipped rollback (confirmed via probe:
  `down/4` returned `{:ok, :already_down, []}` and `mailglass` schema count
  was still 1 afterward). This is a DIFFERENT failure mode from the
  deadlock the earlier attempt hit (that attempt forced `prefix: "mailglass"`
  explicitly on both calls, which pins bookkeeping inside `mailglass` from
  the start and hits the self-referential-drop race described above) — both
  are symptoms of the same underlying conflation, not evidence the
  conflation is unfixable. `Ecto.Migration.Runner.run/8` (the function
  `Ecto.Migrator.up/4`/`down/4` call internally; `@moduledoc false` but not
  `defp`) drives the migration module's `down/0` directly without EVER
  invoking `SchemaMigration`/`lock_for_migrations` — no bookkeeping table of
  any kind is created, queried, or orphaned inside `mailglass`, so neither
  failure mode (silent skip or deadlock) has anywhere to arise. Verified: 3
  consecutive isolated file runs green on the mailglass axis (fresh DB), 3
  consecutive full-suite runs green across both axes (public 1514/0
  ×3 including this file; mailglass 1513/0 ×2), `mix format --check-formatted`
  clean, `mix credo --strict` clean, `mix compile --warnings-as-errors`
  clean. `.planning/WINDOWS.md` ids 3 and 7 both marked `fixed`.

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

### `Mailglass.PersistenceIntegrationTest`'s `migrated_version/0 == 0` on the mailglass axis — RESOLVED (orchestrator-directed gap closure)

- **Found during:** Task 3's mailglass-axis full-suite run.
- **Symptom:** `assert Mailglass.Migration.migrated_version() ==
  Mailglass.Migrations.Postgres.current_version()` — `left: 0, right: 5`.
  Reproduces standalone (`mix test test/mailglass/persistence_integration_test.exs`
  on a fresh mailglass-axis DB, nothing else in the suite involved) — NOT an
  ordering/leak artifact.
- **Root cause:** `Mailglass.Migration.migrated_version/1` (the public
  wrapper in `lib/mailglass/migration.ex`, NOT `Mailglass.Migrations.Postgres`'s
  internal dispatcher) was the one function in that module that did NOT
  thread `Mailglass.Config.schema()` through as the `:prefix` default —
  `up/1` and `down/1` already do this (MIGR-01). The test calls
  `Mailglass.Migration.migrated_version()` with NO args, so the query always
  targeted `public.mailglass_events`'s pg_class comment, which genuinely
  carries no comment on the mailglass axis (the real marker lives under
  `mailglass.mailglass_events`).
- **RESOLVED:** fixed in `lib/mailglass/migration.ex` — `migrated_version/1`
  now does `Keyword.put_new(opts, :prefix, Mailglass.Config.schema())`,
  matching `up/1`/`down/1`'s existing pattern exactly. An explicit caller
  `:prefix` still wins via `Keyword.put_new` (no behavior change for
  `migration_test.exs`'s existing explicit-prefix call sites).
- **Also resolved as a side effect:** `shipped_migration_divergence_test.exs`'s
  4 full-suite-only cascade failures (`idempotency_key column`, `status and
  last_error columns`, `partial unique idempotency index`, `idempotent
  upsert round-trips as a no-op`) no longer reproduce — 2/2 clean full
  mailglass-axis runs post-fix (1477 tests, 1 failure both times, the one
  remaining failure being the separately-tracked
  `schema_isolation_immutability_test.exs` down-test below).
- **Verification:** `persistence_integration_test.exs` 9/9 on both axes;
  `migration_test.exs` 12/12 unchanged; full mailglass-axis suite
  1477 tests / 1 failure (down from 5-6, run-to-run); full public-axis suite
  unchanged, 1478/0.

### Pre-existing `Rewrite.Error: no source found` failures (Igniter generator tests) — RESOLVED (already fixed on this branch, commit `d459ea7e`)

- **Found during:** Task 3's full-suite runs, both axes (6 failures on
  public, matching subset on mailglass): `test/mailglass/upgrade/v0_2_test.exs`
  and `test/mix/tasks/mailglass.gen.mailable_test.exs`.
- **Symptom:** `** (Rewrite.Error) no source found for "lib/..."` inside
  `assert_file_content/3`, an Igniter/Rewrite test-fixture helper.
- **RESOLVED:** commit `d459ea7e` ("fix(143-07): assert on the composed
  igniter, not the applied one") — already present on this branch before the
  orchestrator-directed gap-closure session started, but this file was not
  updated to reflect it and `.planning/WINDOWS.md` id 5 was still `open`.
  Root cause per that commit: as of the Igniter `0.7.9 -> 0.8.0` Dependabot
  bump, `apply_igniter!/1` returns an igniter whose `rewrite` holds ZERO
  sources (applying materializes and drops them), so any `Rewrite.source!/2`
  lookup against a POST-apply igniter always raised. Fixed by asserting on
  the composed igniter and calling `apply_igniter!/1` separately.
- **Verification (re-confirmed this session):**
  `mix test test/mailglass/upgrade/v0_2_test.exs
  test/mix/tasks/mailglass.gen.mailable_test.exs --warnings-as-errors --seed 0`
  → 6 tests, 0 failures.

### `:tenancy` application-env leak from `unsubscribe_test.exs` — OPEN (found by plan 143-12, deliberately not fixed here)

- **Found during:** plan `143-12`'s promotion checkpoint, while establishing whether
  the Core Full Suite lane is stable enough to be given publish-veto power.
- **Symptom:** nondeterministic `** (Ecto.Query.CompileError) can't apply alias
  `:scoped`, binding in `from` is already aliased to `:orphan`` raised from
  `Mailglass.Operator.SupportSummary.orphan_backlog_summary/2`, failing
  `test/mailglass/schema_isolation_integration_test.exs:180` and `:290`.
  Observed live in CI run `30571989203` (mailglass gating leg, full-suite seed
  `590679`) on a **docs-only commit** (`71fcd8f5`, one file, `.planning/WINDOWS.md`),
  and green two commits later at `6bacf2ff` with `lib/` byte-identical and `main`
  unmoved.
- **Mechanism:** `Mailglass.Tenancy.scope/2` resolves via
  `Application.get_env(:mailglass, :tenancy)` — global state.
  `test/mailglass/compliance/unsubscribe_test.exs` installs a resolver whose
  `scope/2` applies `as: :scoped` (line 22), sets it at lines 103/216, and restores
  in `on_exit` with `Application.put_all_env/1` — which **merges** and therefore
  cannot remove a key absent from the saved env. `:tenancy` is in no `config/*.exs`,
  so it is never in the saved env. Any raise between the put and the in-test
  `delete_env` leaks the resolver for the rest of the suite.
- **Corroboration:** the sibling `test/mailglass/properties/unsubscribe_property_test.exs`
  already carries the fix — an explicit `Application.delete_env(:mailglass, :tenancy)`
  after `put_all_env` in `on_exit` (line 52), plus a defensive delete in `setup`
  (line 34). `unsubscribe_test.exs` has neither.
- **Why not fixed here:** out of plan `143-12`'s scope (`files_modified` is two
  planning artifacts) and not introduced by this plan's changes. It also warrants the
  same mutation proof every other guard in this phase received, which is a plan of its
  own. **Not masked, skipped, tagged away, serialized around, or weakened.**
- **Recommended fix:** add `Application.delete_env(:mailglass, :tenancy)` to
  `unsubscribe_test.exs`'s `on_exit`, then sweep the suite for the same
  `put_all_env`-restore anti-pattern — it is silent by construction and this is the
  second file known to need the explicit delete.
- **Blocking impact:** recorded as **Finding B** in `143-PROMOTION-CHECKPOINT.md`. A
  lane that flips red on a docs-only commit is not stable enough to hold publish-veto
  power under the approved blocking decision.
