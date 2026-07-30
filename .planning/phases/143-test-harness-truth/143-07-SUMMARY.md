---
phase: 143-test-harness-truth
plan: 07
subsystem: testing
tags: [ecto, sandbox, postgres, exunit, harness-01, harness-02, d-31, d-11, d-17]

# Dependency graph
requires:
  - phase: 143-test-harness-truth (plan 04)
    provides: "Mailglass.TestSupport.SandboxOwnership — checkout!/1, unsandboxed_module/1, probe/1, assert_manual!/3, baseline_tables_present?/1, LeakError, the sanctioned acquire/release door this plan's schema seam joins"
  - phase: 143-test-harness-truth (plan 06)
    provides: "All nine :auto-mode files routed through unsandboxed_module/1 — the substrate this plan's Class A/B fixes build on"
  - phase: 143-test-harness-truth (plan 03)
    provides: "143-MECHANISM.md's three-class inventory — the evidence-backed Class A/B candidate list this plan started from (and, per the coordinator, was authorized to widen when the full-suite ledger named different modules)"
provides:
  - "Mailglass.TestSupport.SandboxOwnership.with_schema!/2 — the restore-first schema-override seam (D-31 Class B fix), used by every confirmed schema-overriding test file; on_exit is registered before the override is even applied, so a raise anywhere after still restores the boot schema"
  - "Unconditional, verified migration-baseline restoration (D-31 Class A fix) in migration_test.exs, upgrade_v2_schema_migration_test.exs, and schema_prefix_hardening_test.exs — no presence/axis guard decides whether to restore; every restore ends by calling SandboxOwnership.baseline_tables_present?/1 and raises naming the absent relations on a false or :cannot_verify result"
  - "Both HARNESS-02 --warnings-as-errors blockers fixed: the dead @emitted_body attribute removed, and SandboxOwnership.reloading_flat_migrations/1 scopes Code.put_compiler_option(:ignore_module_conflict, true) around every flat-migrations-path Migrator.run call site so the 'redefining module Mailglass.TestRepo.Migrations.*' warning class no longer aborts a fully successful run"
  - "The 'down reverses the move' pre-existing failure fixed at its actual root cause: Ecto.Migrator's own schema_migrations bookkeeping is ambient-current-schema-dependent absent an explicit :prefix, letting a down/4 call silently miss the version its own up/4 call recorded and no-op as :already_down; upgrade_v2_schema_migration_test.exs now pins prefix: \"public\" on both calls"
  - "A LIVE, previously-undocumented Class B config_schema_drift source found and closed: test/mailglass/repo_test.exs restored via Application.delete_env/2 instead of put_env/3, leaving the :schema key ABSENT so the next Config.schema/0 call silently re-cached the wrong compiled-in default (\"mailglass\") for the rest of the suite — this alone accounted for ~100 of the ~180 pre-fix public-axis failures"
  - "Post-fix full-suite verification on both schema axes: zero SuiteTruthFormatter violations in all four tracked classes (pool_mode_leaked, config_schema_drift, baseline_missing, cannot_verify), total test count above the pre-fix ledger on both axes, excluded/skipped unchanged"
affects: [143-08, 143-09, 143-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Restore-first ordering, generalized beyond pool-mode acquisition (143-04/05/06) to Application-env config overrides: capture the current value, register the on_exit restore, THEN apply the override — never override-then-register. Applies to any process-global state a test temporarily flips."
    - "A restore is not 'done' until it is VERIFIED against the same probe a formatter/monitor would use (SandboxOwnership.baseline_tables_present?/1), and a failed verification raises naming what's missing rather than returning quietly — a presence/axis guard that decides 'looks fine, skip the restore' is the exact 'cannot verify, reports green' shape this milestone exists to kill, wherever it appears (a conditional on_exit, or an axis-scoped early return in a helper function)."
    - "Ecto.Migrator's own schema_migrations bookkeeping resolves via the calling connection's ambient current_schema (search_path) when no explicit :prefix is passed — NOT via Mailglass.Config.schema(). Two migrator calls issued from a pool-reused (not freshly-started) Ecto.Migrator.with_repo/2 invocation can land on DIFFERENT physical bookkeeping tables if pool connections differ in session history. Pin an explicit, stable :prefix (here, \"public\" — always exists, never dropped) on any up/4+down/4 pair whose content is raw execute/1 SQL (not create table(prefix: ...) DSL macros, which Ecto validates against the outer :prefix and will reject a mismatch)."
    - "Application.delete_env/2 is not a restore — it leaves the key ABSENT, and Application.get_env/3's own default (not the config/test.exs boot pin) silently takes over on the next read. Always restore via put_env/3 to the CAPTURED value, never delete_env/2, when a config/test.exs pin exists."

key-files:
  created: []
  modified:
    - test/support/sandbox_ownership.ex
    - test/mailglass/migration_test.exs
    - test/mailglass/upgrade_v2_schema_migration_test.exs
    - test/mailglass/schema_prefix_hardening_test.exs
    - test/mailglass/schema_isolation_integration_test.exs
    - test/mailglass/schema_isolation_immutability_test.exs
    - test/mailglass/repo_test.exs
    - test/mailglass/test_support/sandbox_ownership_test.exs
    - .planning/phases/143-test-harness-truth/deferred-items.md
    - .planning/WINDOWS.md

key-decisions:
  - "The ledger, not the research candidates, drove final scope: two files outside this plan's original files_modified (test/mailglass/repo_test.exs, and two assertion helpers in schema_prefix_hardening_test.exs) were fixed because the REQUIRED full-suite run named them as live, evidence-confirmed Class A/B sources — per the coordinator's explicit instruction that a ledger disagreement with 143-MECHANISM.md's inventory is resolved in the ledger's favor."
  - "shipped_migration_divergence_test.exs was left unmigrated for Task 1's schema seam — it has no config :mailglass, :schema override to close, confirmed by direct read, matching the plan's own 'where a file has no override, leave it alone' instruction."
  - "upgrade_v2_schema_migration_test.exs's vestigial capture-and-restore-to-itself dead code (a schema override that never actually happened) was removed rather than migrated, since there was no real override for the with_schema!/2 seam to close — this also satisfies the acceptance criterion's literal grep=0 bar across all five Task 1 files."
  - "schema_isolation_immutability_test.exs's structurally-identical down/4 bookkeeping-ambiguity bug (same shape as upgrade_v2_schema_migration_test.exs's fixed 'down reverses the move') was investigated and found NOT fixable by the same prefix: \"public\" technique — its PrefixedWrapperMigration uses Ecto's create table(prefix: ...) DSL macros, which Ecto explicitly validates against the outer migrator :prefix and rejects on mismatch (confirmed by reproducing the raise live, then reverting). Logged as a deferred item with the correct alternative fix (prefix: Mailglass.Config.schema(), which needs the schema to already exist — true here, unlike the file where this technique originated) rather than forced through."
  - "persistence_integration_test.exs's migrated_version() == 0 failure on the mailglass axis is a lib-level bug (Mailglass.Migrations.Postgres's hardcoded @default_prefix \"public\"), confirmed to reproduce standalone (not an ordering/leak artifact) and explicitly out of this plan's test-only files_modified scope — deferred, not fixed."
  - "Six Rewrite.Error: no source found failures (Igniter generator tests, two files) are a confirmed pre-existing, unrelated-subsystem defect (last touched at commits long predating Phase 143, reproduces standalone) — deferred, not investigated further."
  - "No floor/ceiling/threshold constant was pinned from these measurements, per D-27 — that stays with plan 143-10 against a green CI run."

patterns-established:
  - "with_schema!/2 (test/support/sandbox_ownership.ex) is now the sanctioned door for D-11's reason two (Application.put_env/3 on a key the code under test reads) when that key is config :mailglass, :schema specifically — mirroring unsandboxed_module/1's restore-first, registered-before-the-override discipline for pool mode."
  - "SandboxOwnership.reloading_flat_migrations/1 scopes Code.put_compiler_option(:ignore_module_conflict, true) around a single Ecto.Migrator.run/4 call against the flat migrations directory, restoring the prior value in an after block — a genuine redefinition warning anywhere else in the same run still surfaces; this is not a global compiler-warning silence."

requirements-completed: [HARNESS-01, HARNESS-02]

coverage:
  - id: D1
    description: "Class B (config_schema_drift) closed via SandboxOwnership.with_schema!/2 — restore-first ordering (capture, register on_exit, THEN override) — used by every confirmed schema-overriding file: schema_prefix_hardening_test.exs, schema_isolation_integration_test.exs, schema_isolation_immutability_test.exs, and (discovered during Task 3's full-suite run) repo_test.exs, whose prior Application.delete_env/2 restore left the :schema key absent and silently re-cached the wrong compiled-in default"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "mix test test/mailglass/schema_prefix_hardening_test.exs test/mailglass/schema_isolation_integration_test.exs test/mailglass/schema_isolation_immutability_test.exs test/mailglass/shipped_migration_divergence_test.exs test/mailglass/upgrade_v2_schema_migration_test.exs --warnings-as-errors (24 tests, 0 failures, unchanged from parent)"
        status: pass
      - kind: unit
        ref: "mix test test/mailglass/repo_test.exs --warnings-as-errors (28 tests, 0 failures)"
        status: pass
      - kind: unit
        ref: "mix test test/mailglass/test_support/sandbox_ownership_test.exs --warnings-as-errors, both axes (16 tests, 0 failures each — includes the 3 new with_schema!/2 mechanism-level regression tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Class A (baseline_missing) closed via unconditional, verified restoration in migration_test.exs, upgrade_v2_schema_migration_test.exs, and schema_prefix_hardening_test.exs — no presence/axis guard decides whether to restore; every restore ends by calling SandboxOwnership.baseline_tables_present?/1 and raises naming the absent relations on a false or :cannot_verify result. The 'down reverses the move' pre-existing failure fixed at its root cause (Ecto.Migrator schema_migrations bookkeeping ambiguity, prefix: \"public\" pin)"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "mix test test/mailglass/migration_test.exs test/mailglass/upgrade_v2_schema_migration_test.exs --warnings-as-errors, run twice consecutively, both axes (18 tests, 0 failures, all four runs)"
        status: pass
      - kind: unit
        ref: "mix test test/mailglass/migration_test.exs followed by mix test test/mailglass/outbound/ --warnings-as-errors (12/0 then 1 property + 77 tests / 0 failures — downstream tables survive)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Both HARNESS-02 --warnings-as-errors blockers fixed (dead @emitted_body attribute removed; SandboxOwnership.reloading_flat_migrations/1 scopes ignore_module_conflict around every flat-migrations-path Migrator.run call site across 5 files)"
    requirement: "HARNESS-02"
    verification:
      - kind: unit
        ref: "mix test test/mailglass/migration_test.exs test/mailglass/upgrade_v2_schema_migration_test.exs --warnings-as-errors no longer aborts after successful execution (both axes, confirmed twice consecutively)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Post-fix full-suite verification on both schema axes: SuiteTruthFormatter ledger reports zero records (zero violations across all four tracked classes) on both axes; total test count exceeds the pre-fix ledger on both axes; excluded/skipped counts unchanged"
    requirement: "HARNESS-02"
    verification:
      - kind: unit
        ref: "MAILGLASS_SANDBOX_TRACE=1 mix test --warnings-as-errors --exclude requires_workspace --seed 0 (public axis): 1454->1478 tests, 180->6 failures, excluded 13->13, skipped 7->7, ledger 0 record(s)"
        status: pass
      - kind: unit
        ref: "MAILGLASS_SANDBOX_TRACE=1 MAILGLASS_SCHEMA=mailglass mix test --warnings-as-errors --exclude requires_workspace --seed 0: 1453->1477 tests, 18->8 failures, excluded 14->14, skipped 7->7, ledger 0 record(s)"
        status: pass
    human_judgment: false

duration: ~2h10min (includes deep root-cause investigation of Ecto.Migrator's schema_migrations bookkeeping ambiguity and a live full-suite Class B discovery outside the plan's original file scope)
completed: 2026-07-30
status: complete
---

# Phase 143 Plan 07: Close Class A and Class B, Prove the Full Suite Green Summary

**Class B closed via a restore-first `with_schema!/2` seam (used by 4 files, including a live drift source discovered mid-plan in `repo_test.exs`); Class A closed via unconditional, verified baseline restoration; both `--warnings-as-errors` blockers and the "down reverses the move" root cause fixed; post-fix full-suite runs on both schema axes report zero violations across all four tracked leak classes with more tests executing than the pre-fix baseline, not fewer.**

## Performance

- **Duration:** ~2h10min (five full-suite runs at ~3-6 minutes each were required to separate genuine Class A/B mechanism from local-environment DB-history artifacts, plus a deep dive into `Ecto.Migrator`'s undocumented schema_migrations bookkeeping resolution)
- **Tasks:** 3 planned (`type="auto"`), plus 2 deviation commits driven by required full-suite verification evidence
- **Files modified:** 8 test files + 1 support module + 2 planning-ledger files

## Accomplishments

- **`SandboxOwnership.with_schema!/2`** — the restore-first schema-override seam. Captures `Mailglass.Config.schema()`, registers the `on_exit` restore (via `Application.put_env/3` — never `delete_env/2`) on the very next statement, THEN applies the override, THEN asserts it took effect (raising a composed message naming the mismatch if not). Inverts the exact ordering every confirmed Class B candidate got backwards: override, then work that can raise, then a trailing restore a mid-setup raise skips entirely.
- Routed the three confirmed Class B candidates through the seam: `schema_prefix_hardening_test.exs`, `schema_isolation_integration_test.exs`, `schema_isolation_immutability_test.exs`. `shipped_migration_divergence_test.exs` has no override to migrate (confirmed by direct read, left unchanged per the plan's own instruction).
- **Class A closed with unconditional, verified restoration.** `migration_test.exs`'s presence-guarded restore (`unless baseline_tables_present?() do ... end`) is now unconditional, reuses `SandboxOwnership.baseline_tables_present?/1` (the local re-implementation removed), and raises naming absent relations on a false/`:cannot_verify` result. Same pattern applied to a second `describe` block in the same file, to `upgrade_v2_schema_migration_test.exs`'s teardown, and to `schema_prefix_hardening_test.exs`'s axis-conditional `restore_suite_baseline_schema/0` (its `if MAILGLASS_SCHEMA in [nil, "", "public"] do :ok` early return was exactly the "looks fine, skip the restore" shape D-31 targets — removed, made unconditional, and idempotent since the underlying restore goes through `Mailglass.Migration.up/1`'s own pg_class-comment version check, independent of Ecto's `schema_migrations` bookkeeping).
- **Both `--warnings-as-errors` blockers fixed, not silenced.** The dead `@emitted_body` module attribute is removed. `SandboxOwnership.reloading_flat_migrations/1` scopes `Code.put_compiler_option(:ignore_module_conflict, true)` around every call site that re-scans the flat `priv/repo/migrations/` directory (5 files), restoring the prior value in an `after` block — a genuine redefinition warning anywhere else in the same run still surfaces.
- **Root-caused and fixed the "down reverses the move" pre-existing failure.** `Ecto.Migrator.up/4`'s and `down/4`'s own `schema_migrations` bookkeeping resolves via the calling connection's *ambient current_schema* when no explicit `:prefix` is passed — not via `Mailglass.Config.schema()`. Because `Ecto.Migrator.with_repo/2` reuses the already-started, long-lived Sandbox pool (rather than starting a fresh connection with predictable session state), two migrator calls in the same test can land on *different* physical `schema_migrations` tables. `upgrade_v2_schema_migration_test.exs`'s wrapper migration now pins `prefix: "public"` on both its `up/4` and `down/4` calls — safe because `public` always exists and is never dropped by any file in this suite, and the wrapper's run-unique version number never collides with the flat baseline migrations' own bookkeeping. Confirmed stable across 4 consecutive runs (2 per axis).
- **Investigated the same bug shape in `schema_isolation_immutability_test.exs`, confirmed the fix does NOT transfer.** Its `PrefixedWrapperMigration` calls `Mailglass.Migration.up(prefix: "mailglass", ...)`, which uses Ecto's `create table(prefix: ...)` DSL macros — and Ecto explicitly *validates* that a migration's own table prefix matches the outer migrator's `:prefix` option, raising `Ecto.MigrationError` on mismatch (reproduced live, then reverted). Logged as a deferred item with the correct alternative fix.
- **A live, previously-unknown Class B source found and closed via the plan's own required verification step.** Task 3's full-suite public-axis run surfaced 104 failures — almost all `relation "mailglass.mailglass_suppressions" does not exist`, starting at the sync module immediately following `Mailglass.RepoTest`. Root-caused to `repo_test.exs`'s two schema-overriding setups restoring via `Application.delete_env(:mailglass, :schema)` instead of `put_env(:mailglass, :schema, "public")` — deleting the key leaves it *absent*, and `Mailglass.Config.warm_schema/0`'s own `Application.get_env(:mailglass, :schema, "mailglass")` default (not config/test.exs's `"public"` boot pin) silently re-caches the wrong value for the rest of the suite the moment anything next calls `Config.schema/0`. Confirmed directly in isolation (`delete_env` then `get_env(key, "mailglass")` returns `"mailglass"`). Per the coordinator's explicit instruction ("the ledger names the culprits... the ledger wins"), fixed rather than deferred: both setups now route through `with_schema!/2`. Public-axis failures: 104 → 6.
- **Fixed two `SchemaPrefixHardeningTest` assertion helpers** (`assert_public_delivery_absent!/1`, `unsubscribe_event_count/2`) that raised `42P01` instead of asserting `0` when `public.mailglass_deliveries`/`events` genuinely does not exist on a clean mailglass-axis run — a stronger form of "absent from public" than an empty table, not a failure. Both now check existence first via `public_table_exists?/1`, matching the established pattern in `schema_isolation_integration_test.exs`'s `public_row_count/2`.
- **Widened `with_schema!/2` with an injectable `:schema_fun`** (mirroring `assert_manual!/3`'s `probe_fun:` idiom) so the "did not take effect" raise path is testable with a synthetic mismatch rather than a real Application-env race, and added 3 mechanism-level regression tests to `sandbox_ownership_test.exs` (13 → 16).
- **Post-fix full-suite verification on both schema axes: zero SuiteTruthFormatter violations in all four tracked classes** (`:pool_mode_leaked`, `:config_schema_drift`, `:baseline_missing`, `:cannot_verify`), with more tests executing than the pre-fix ledger on both axes and `excluded`/`skipped` unchanged.

## Post-Fix vs. Pre-Fix Ledger Comparison

| Metric | Public (pre) | Public (post) | Mailglass (pre) | Mailglass (post) |
|---|---|---|---|---|
| Total tests | 1454 | **1478** | 1453 | **1477** |
| Failures | 180 | **6** | 18 | **8** |
| Excluded | 13 | 13 | 14 | 14 |
| Skipped | 7 | 7 | 7 | 7 |
| Ledger violations (all 4 classes) | n/a (pre-fix) | **0 record(s)** | n/a (pre-fix) | **0 record(s)** |

Both axes: total ≥ pre-fix (no lost tests), `excluded`/`skipped` unchanged, zero tracked-class violations. No floor/ceiling/threshold constant was pinned from these numbers (D-27 — that's plan 143-10's job against a green CI run).

**Residual failures (all confirmed pre-existing and out of this plan's Class A/B/C scope, logged to `deferred-items.md` and `.planning/WINDOWS.md`, not masked):**
- 6 (both axes): `Rewrite.Error: no source found` in two Igniter generator test files — unrelated subsystem, reproduces standalone, last touched at commits long predating Phase 143.
- +1 (mailglass axis): `persistence_integration_test.exs`'s `migrated_version() == 0` — a lib-level bug (`Mailglass.Migrations.Postgres`'s hardcoded `@default_prefix "public"`), reproduces standalone, out of this plan's test-only file scope.
- +1 (mailglass axis): `schema_isolation_immutability_test.exs`'s "migrating down against prefix mailglass succeeds" — the confirmed-but-not-transferable down/4 bookkeeping bug described above.

## Task Commits

1. **Task 1: Add the restore-first schema seam and close Class B** - `a7be5f27` (feat)
2. **Task 2: Close Class A — unconditional, verified baseline restoration** - `be7017b7` (fix)
3. **Deviation: fix the two un-deferred HARNESS-02 `--warnings-as-errors` blockers** - `41d301cd` (fix)
4. **Deviation: close a live Class B leak found by the required full-suite run** - `3c79d72c` (fix)
5. **Task 3: post-fix three-class verification on both schema axes** - `9ec801e4` (test)

**Plan metadata:** _pending — this commit_

## Files Created/Modified

- `test/support/sandbox_ownership.ex` - `with_schema!/2` (restore-first schema seam, D-31 Class B), `reloading_flat_migrations/1` (HARNESS-02's redefining-module warning fix), `:schema_fun` injectable seam on `with_schema!/2`.
- `test/mailglass/migration_test.exs` - unconditional + verified baseline restoration (both `on_exit` blocks); local `baseline_tables_present?/0` removed in favor of `SandboxOwnership.baseline_tables_present?/1`; all flat-migration `Migrator.run` call sites wrapped in `reloading_flat_migrations/1`.
- `test/mailglass/upgrade_v2_schema_migration_test.exs` - `with_schema!/2` sweep found no override to migrate (vestigial dead code removed instead); `prefix: "public"` pinned on the wrapper migration's `up/4`/`down/4` calls (fixes "down reverses the move"); unconditional + verified restoration; dead `@emitted_body` attribute removed; `reloading_flat_migrations/1` wrap.
- `test/mailglass/schema_prefix_hardening_test.exs` - `with_schema!/2` for its schema override; axis-conditional `restore_suite_baseline_schema/0` guard removed (unconditional + verified); `assert_public_delivery_absent!/1`/`unsubscribe_event_count/2` fixed to treat a missing `public.*` table as count 0; `reloading_flat_migrations/1` wrap.
- `test/mailglass/schema_isolation_integration_test.exs` / `schema_isolation_immutability_test.exs` - `with_schema!/2` for their schema overrides; `reloading_flat_migrations/1` wrap.
- `test/mailglass/repo_test.exs` - both schema-overriding `setup` blocks migrated from `Application.delete_env/2` to `SandboxOwnership.with_schema!/2` (the live Class B fix found via full-suite verification).
- `test/mailglass/test_support/sandbox_ownership_test.exs` - 3 new mechanism-level regression tests for `with_schema!/2` and `baseline_tables_present?/1`'s missing-relation path (13 → 16 tests).
- `.planning/phases/143-test-harness-truth/deferred-items.md` / `.planning/WINDOWS.md` - prior deferred items resolved; new out-of-scope discoveries logged, not masked.

## Decisions Made

See `key-decisions` in frontmatter. The load-bearing one: the required full-suite run, not the original file inventory, determined final scope — `repo_test.exs` and two `schema_prefix_hardening_test.exs` helpers were fixed because live evidence named them, per the coordinator's explicit "the ledger wins" instruction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `test/mailglass/repo_test.exs` restored `:schema` via `delete_env/2` instead of `put_env/3`, causing a live, suite-wide Class B drift**

- **Found during:** Task 3's required full-suite public-axis verification run.
- **Issue:** `Application.delete_env(:mailglass, :schema)` leaves the key absent rather than restoring config/test.exs's `"public"` pin; `Mailglass.Config.warm_schema/0`'s own default (`"mailglass"`) silently took over on the next `Config.schema/0` call, poisoning the rest of the suite (~100 downstream failures).
- **Fix:** both setups now route through `SandboxOwnership.with_schema!/2`.
- **Files modified:** `test/mailglass/repo_test.exs`
- **Verification:** public-axis full-suite failures 104 → 6; `mix test test/mailglass/repo_test.exs --warnings-as-errors` 28/0.
- **Committed in:** `3c79d72c`

**2. [Rule 1 - Bug] `SchemaPrefixHardeningTest`'s public-absence assertions raised instead of asserting on a genuinely-missing `public.*` table**

- **Found during:** Task 3's mailglass-axis full-suite verification run.
- **Issue:** `TestRepo.query!` raises `42P01` when `public.mailglass_deliveries`/`events` doesn't exist at all (the correct state on a clean mailglass-axis run), instead of the intended "0 rows" assertion.
- **Fix:** added `public_table_exists?/1`, routed both helpers through it.
- **Files modified:** `test/mailglass/schema_prefix_hardening_test.exs`
- **Verification:** both axes pass in isolation on a genuinely fresh DB.
- **Committed in:** `3c79d72c`

**3. [Rule 1 - Bug] "down reverses the move" — Ecto.Migrator schema_migrations bookkeeping ambiguity**

- **Found during:** Task 2, re-investigating the pre-existing deferred failure the coordinator un-deferred.
- **Issue:** `Ecto.Migrator.up/4`/`down/4` resolve `schema_migrations` bookkeeping via ambient current_schema (not `Config.schema()`) absent an explicit `:prefix`; a pool-reused migrator connection can land on a different physical bookkeeping table than the one the matching `up/4` call wrote to, so `down/4` silently no-ops as `:already_down`.
- **Fix:** pinned `prefix: "public"` on both calls in `upgrade_v2_schema_migration_test.exs`'s wrapper migration.
- **Files modified:** `test/mailglass/upgrade_v2_schema_migration_test.exs`
- **Verification:** stable across 4 consecutive runs (2 per axis).
- **Committed in:** `be7017b7`

**4. [Rule 1 - Bug, coordinator-un-deferred] Dead `@emitted_body` attribute + redefining-module warnings**

- **Found during:** Task 2/verification; explicitly un-deferred by the coordinator.
- **Fix:** attribute removed; `SandboxOwnership.reloading_flat_migrations/1` added and wired into every flat-migrations-path `Migrator.run` call site.
- **Files modified:** `test/mailglass/upgrade_v2_schema_migration_test.exs`, `test/support/sandbox_ownership.ex`, `test/mailglass/migration_test.exs`, `test/mailglass/schema_prefix_hardening_test.exs`, `test/mailglass/schema_isolation_integration_test.exs`, `test/mailglass/schema_isolation_immutability_test.exs`
- **Verification:** `--warnings-as-errors` runs no longer abort after successful execution.
- **Committed in:** `41d301cd`

---

**Total deviations:** 4 auto-fixed (all Rule 1 bugs, all necessary to reach this plan's own must-haves). No scope creep beyond what the required verification evidence demanded — every widened-scope fix is documented with its own investigation trail.
**Impact on plan:** Two files outside the original `files_modified` list (`repo_test.exs`, and helpers in `schema_prefix_hardening_test.exs` beyond its Class B seam) were touched because the plan's own Task 3 verification step named them as live culprits — exactly the scenario the plan's `<coordinator_note>` anticipated and authorized.

## Issues Encountered

- **Local DB axis-alternation corruption, repeatedly, as the coordinator warned in advance.** Running the mailglass axis then the public axis back-to-back against this shared local Postgres instance (without an intervening `mix ecto.drop`/`create`) repeatedly produced `42P01` errors unrelated to any code change — confirmed each time by resetting and re-running cleanly. This is a LOCAL-ONLY artifact: CI creates a fresh database per matrix-axis job (confirmed by reading `.github/workflows/advisory-matrix.yml`), so this exact scenario never occurs there.
- **A regression test I wrote initially hardcoded the wrong boot-schema assumption.** `sandbox_ownership_test.exs`'s new "restores the captured schema" test asserted `original == "public"`, which is only true on the default axis — the mailglass-axis full-suite run caught this immediately (own-goal). Fixed to capture the boot value live rather than hardcoding either axis's value.
- **Deep, undocumented Ecto.Migrator behavior required direct empirical verification** (not assumption) to root-cause the "down reverses the move" bug: confirmed via direct `psql`/`elixir -e` probes that (a) `Ecto.Migrator.with_repo/2` reuses an already-started repo's pool rather than establishing a fresh, predictable connection; (b) `CREATE TABLE IF NOT EXISTS`'s existence check is schema-local, not search-path-wide; (c) `Ecto.Migration`'s `create table(prefix: ...)` DSL macros validate against the outer migrator's `:prefix` and raise on mismatch, while raw `execute/1` SQL does not.

## User Setup Required

None — no external service configuration required. PostgreSQL reachability (`scripts/preflight_postgres.sh`) was verified before starting; the shared local test database was reset via `mix ecto.drop`/`mix ecto.create` numerous times during investigation (documented in Issues Encountered) and is left in a clean, fully-migrated state.

## Known Stubs

None.

## Threat Flags

None — this plan introduces no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. `with_schema!/2` and `reloading_flat_migrations/1` are test-infrastructure-only additions matching the threat model's own T-143-21/22/23 mitigations (unconditional verified restoration; restore via the same Application.put_env + cache-invalidation path the override used, never writing `Mailglass.Config`'s cache directly; restore-first ordering removing the drift window entirely).

## Next Phase Readiness

- Class A and Class B are closed with restore-first, verified mechanisms matching Class C's own discipline from plans 143-04/05/06. `checkout!/1`, `unsandboxed_module/1`, and `with_schema!/2` now form a complete restore-first family for D-11's three async:false reasons.
- Two genuinely out-of-scope, confirmed-pre-existing defects remain open and documented, not masked: `persistence_integration_test.exs`'s lib-level default-prefix gap (needs a `lib/` change, out of this plan's test-only scope) and `schema_isolation_immutability_test.exs`'s down/4 bookkeeping bug (needs `prefix: Mailglass.Config.schema()` plus schema pre-existence handling, a different technique than the one validated here — a real, bounded follow-up).
- A transient `SandboxOwnership.LeakError` was observed once (not reproducible in 2/2 standalone re-runs) in `webhook_signature_failure_test.exs` on a mailglass-axis full-suite run — logged as Class C/D-17 territory (143-04/05/08's domain), consistent with 143-05's own documented settle-window tuning pattern.
- Plan 143-08 (the Credo forbidden-function classifier) can now also forbid direct `config :mailglass, :schema` overrides outside `with_schema!/2`'s own implementation, mirroring the `:mode`/`:checkout` allowlist precedent from 143-04/06.
- No blockers. All five commits are green under `mix compile --warnings-as-errors`, `mix credo --strict`, `mix format --check-formatted`.

---
*Phase: 143-test-harness-truth*
*Completed: 2026-07-30*

## Self-Check: PASSED

`.planning/phases/143-test-harness-truth/143-07-SUMMARY.md` confirmed present on disk.
All 5 commit hashes (`a7be5f27`, `be7017b7`, `41d301cd`, `3c79d72c`, `9ec801e4`) confirmed
present in `git log --oneline --all`.
