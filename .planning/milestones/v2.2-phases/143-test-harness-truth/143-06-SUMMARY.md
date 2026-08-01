---
phase: 143-test-harness-truth
plan: 06
subsystem: testing
tags: [ecto, sandbox, dbconnection, exunit, harness-01, d-06, d-07, d-12]

# Dependency graph
requires:
  - phase: 143-test-harness-truth (plan 04)
    provides: "Mailglass.TestSupport.SandboxOwnership.unsandboxed_module/1 — the setup callback this plan routes all nine :auto-mode files through, with its documented reverse-on_exit ordering guarantee"
provides:
  - "All nine :auto-mode files (three properties, four schema-isolation/divergence, two non-trivial-teardown migration files) now switch pool mode exclusively through setup :unsandboxed_module. Zero raw Sandbox.mode/2 calls remain in any of them."
  - "The reverse on_exit ordering guarantee is empirically confirmed, not just reasoned about: each file's own baseline-restore on_exit still runs while :auto is in effect, verified via repeated (5-10x) individual and combined runs on both schema axes plus explicit before/after teardown-sequence comparison for the two D-12-designated non-trivial files."
  - ":mode can now join plan 143-08's Credo forbidden-function list — all nine call sites are behind the sanctioned door."
affects: [143-07, 143-08, 143-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "When a file's raw mode(:auto)/mode(:manual) pair sat inside ONE setup block, the migration splits it into TWO setup callbacks (setup :unsandboxed_module declared first, then the file's own setup do...end) — reverse on_exit registration order reconstitutes the exact original statement sequence (baseline restore work, then mode(:manual) last) without merging or reordering any of the file's own teardown logic."
    - "A test file's own on_exit ordering claim is proven, not assumed: for D-12's two non-trivial-teardown files, the before/after callback sequence was written out and diffed line-by-line before the migration was considered done, and each file was run TWICE consecutively (the cheap detector for an incomplete restore) rather than once."

key-files:
  created: []
  modified:
    - test/mailglass/properties/idempotency_convergence_test.exs
    - test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs
    - test/mailglass/properties/webhook_suppression_convergence_test.exs
    - test/mailglass/schema_prefix_hardening_test.exs
    - test/mailglass/schema_isolation_integration_test.exs
    - test/mailglass/schema_isolation_immutability_test.exs
    - test/mailglass/shipped_migration_divergence_test.exs
    - test/mailglass/migration_test.exs
    - test/mailglass/upgrade_v2_schema_migration_test.exs

key-decisions:
  - "Task 1 (the three property files) was already committed on disk when this execution began (commit a91ba1d2, from a prior session) — verified against the plan's own acceptance criteria rather than redone."
  - "Task 2's four schema-isolation/divergence files carry a one-line comment pointing each affected setup at 143-MECHANISM.md's three-class inventory, naming which Class (A and/or B) that file is a candidate for. The drift/restoration defect itself is left completely unchanged, per the plan's explicit prohibition — closing it is plan 143-07's job."
  - "migration_test.exs's setup is split into setup :unsandboxed_module (new, first) plus the file's existing setup do...end (unchanged body except the removed trailing mode(:manual) call) — the conditional restoration logic (unless baseline_tables_present?() do restore_suite_baseline_schema() end) is untouched, confirmed via git diff showing no line inside that block other than the surrounding structural change."
  - "upgrade_v2_schema_migration_test.exs's migration is identical in shape: setup :unsandboxed_module first, the file's own setup (schema drop, seed, migrate, config override) second, with its multi-statement on_exit (drop schema, cleanup schema_migrations, recreate citext, restore config, restore baseline) kept intact minus the trailing mode(:manual) call."
  - "Neither non-trivial file was migrated to Sandbox.unboxed_run/2 — both drive Ecto.Migrator.with_repo/2, which spawns a process unboxed_run cannot cover (documented inline in migration_test.exs since before this plan)."

patterns-established:
  - "Before migrating a file with non-trivial teardown, write out its on_exit registration sequence (what runs, in what order) BEFORE editing, then write out the resulting sequence AFTER editing and confirm they match once the reverse-registration rule is applied. A green test run alone does not discharge this — the sequences must be read and compared (D-12)."

requirements-completed: [HARNESS-01]

coverage:
  - id: D1
    description: "The three property files (idempotency_convergence_test.exs, unsubscribe_post_idempotency_property_test.exs, webhook_suppression_convergence_test.exs) route pool-mode acquisition through setup :unsandboxed_module; zero raw Sandbox.mode/2 calls remain; verified individually on both schema axes with unchanged test counts"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "mix test test/mailglass/properties/ --warnings-as-errors (17 properties, 1 test, 0 failures) -- re-verified at the end of Task 3 to confirm it stays green"
        status: pass
    human_judgment: false
  - id: D2
    description: "The four schema-isolation and divergence files (schema_prefix_hardening_test.exs, schema_isolation_integration_test.exs, schema_isolation_immutability_test.exs, shipped_migration_divergence_test.exs) route pool-mode acquisition through setup :unsandboxed_module with a Class A/B hand-off comment where 143-MECHANISM.md names the file as a candidate; the drift/restoration defect is left unchanged (no Application.put_env or persistent_term line in the diff); mix verify.schema_prefix exits 0"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "mix test <the four files> --warnings-as-errors on the public axis: 18 tests, 0 failures, reproduced across 6 consecutive combined runs plus 10 consecutive individual runs of schema_prefix_hardening_test.exs after an initial transient external-contention flake was ruled out by baseline comparison"
        status: pass
      - kind: unit
        ref: "mix verify.schema_prefix exits 0 (74 tests, 0 failures across its two internal test invocations)"
        status: pass
      - kind: other
        ref: "MAILGLASS_SCHEMA=mailglass combined run reproduces the SAME 18 tests / 5 pre-existing failures as the parent commit (confirmed by reverting the four files and re-running 3x) -- the known Class A/B schema-restoration asymmetry deferred to plan 143-07, not a regression"
        status: pass
    human_judgment: false
  - id: D3
    description: "migration_test.exs and upgrade_v2_schema_migration_test.exs (D-12's non-trivial-teardown files) are migrated with their before/after on_exit sequences written out and confirmed identical modulo the documented reverse-registration reordering; each passes twice consecutively on its stated axis; migration_test.exs's conditional restoration block is byte-for-byte unchanged"
    requirement: "HARNESS-01"
    verification:
      - kind: unit
        ref: "mix test test/mailglass/migration_test.exs --warnings-as-errors, public axis, run twice consecutively: 12 tests, 0 failures both times"
        status: pass
      - kind: unit
        ref: "MAILGLASS_SCHEMA=mailglass mix test test/mailglass/upgrade_v2_schema_migration_test.exs --warnings-as-errors, run twice consecutively: 6 tests, 1 failure both times -- the SAME pre-existing 'down reverses the move' failure confirmed on the parent commit via 3 separate reverted runs, not a regression"
        status: pass
      - kind: other
        ref: "git diff -- test/mailglass/migration_test.exs shows the conditional restoration block (unless baseline_tables_present?() do ... end) with no line changed inside it other than the surrounding setup-split structure and an added hand-off comment"
        status: pass
    human_judgment: false

duration: ~2h (includes empirical investigation of a transient flake, a genuine full-run test-DB corruption from a pre-existing restoration bug, and two mix ecto.drop/create resets)
completed: 2026-07-30
status: complete
---

# Phase 143 Plan 06: Route the Nine :auto-Mode Files Through the Door Summary

**All nine `:auto`-mode files (three property tests, four schema-isolation/divergence files, and the two D-12-designated non-trivial-teardown migration files) now acquire and release pool-wide `:auto` mode exclusively through `SandboxOwnership.unsandboxed_module/1`, with the reverse-`on_exit`-ordering guarantee empirically confirmed rather than assumed, and every pre-existing schema-restoration failure encountered along the way traced back to the parent commit before being left untouched for plan 143-07.**

## Performance

- **Duration:** ~2h (includes debugging a transient external-contention flake in `schema_prefix_hardening_test.exs`, discovering and recovering from a genuine local-DB corruption caused by a pre-existing `upgrade_v2_schema_migration_test.exs` restoration bug, and two `mix ecto.drop`/`mix ecto.create` resets to restore a clean baseline)
- **Tasks:** 3 (`type="auto"`)
- **Files modified:** 9 (all nine `:auto`-mode call sites named in the plan)

## Accomplishments

- **Task 1** (three property files) was already committed on disk at the start of this execution (`a91ba1d2`, from a prior session). Verified against the plan's own acceptance criteria — zero raw `Sandbox.mode/2` calls, `unsandboxed_module` present, no async/skip changes — rather than redone.
- **Task 2** (four schema-isolation/divergence files) migrated: `schema_prefix_hardening_test.exs`, `schema_isolation_integration_test.exs`, `schema_isolation_immutability_test.exs`, `shipped_migration_divergence_test.exs`. Each gained `setup :unsandboxed_module` before its own `setup do...end`, with the raw `mode(:auto)`/`mode(:manual)` pair removed and a one-line hand-off comment pointing at `143-MECHANISM.md`'s three-class inventory where that file is named a Class A/B candidate. The drift/restoration defect itself is untouched.
- An initial combined public-axis run of the four Task 2 files showed 4 failures in `shipped_migration_divergence_test.exs` and, separately, 2 failures running `schema_prefix_hardening_test.exs` alone. Both were investigated by reverting the files to the parent commit and re-running the identical command multiple times: the parent commit passed cleanly every time, which at first looked like a genuine regression, but repeating BOTH the migrated and baseline versions 6-10x each showed the migrated version also passes cleanly every time on repeat — the original failures were a transient external factor (this environment runs concurrent agent processes against the same local Postgres instance; 143-05's own SUMMARY documented the identical class of contention). Confirmed not a regression via volume, not via a single lucky run.
- **Task 3** (the two D-12-designated non-trivial-teardown files) migrated: `migration_test.exs` and `upgrade_v2_schema_migration_test.exs`. For each, the on_exit sequence was read and written out BEFORE editing, the migration applied, and the resulting sequence re-read and compared — see "Teardown Sequence Verification" below. Both pass their required verification (each run twice consecutively) with unchanged test counts, except one pre-existing failure in `upgrade_v2_schema_migration_test.exs` on the mailglass axis, confirmed identical on the parent commit (see Deviations).
- While verifying Task 3, `upgrade_v2_schema_migration_test.exs`'s already-known-broken "down reverses the move" test failed as expected (it does on the parent commit too), but its incomplete restoration left the shared local Postgres test database in a state where `public.mailglass_suppressions` no longer existed — corrupting a SUBSEQUENT, unrelated `migration_test.exs` run at `test_helper.exs` boot (before any test even started). Recovered via `mix ecto.drop -r Mailglass.TestRepo && mix ecto.create -r Mailglass.TestRepo`, confirmed clean via a smoke test, and left the database in a fully clean, migrated state at the end of this plan (confirmed via a final combined `properties/` + `migration_test.exs` + `upgrade_v2_schema_migration_test.exs` run on both axes).
- All nine files now satisfy the plan's full success criteria: zero raw `Sandbox.mode/2` calls, exactly one `setup :unsandboxed_module` line each, zero `unboxed_run` migrations, and zero async-attribute or skip-tag changes across the whole plan diff.

## Teardown Sequence Verification (D-12)

**`migration_test.exs`** — module-level setup, applies to every test in the file:

*Before:*
1. `Sandbox.mode(TestRepo, :auto)`
2. register `on_exit`: `unless baseline_tables_present?() do restore_suite_baseline_schema() end` → `Sandbox.mode(TestRepo, :manual)`

*After:*
1. `setup :unsandboxed_module` (registered FIRST) — sets `:auto`, registers its own `on_exit` (mode → `:manual`) FIRST
2. file's own `setup do...end` (registered SECOND) — registers `on_exit`: `unless baseline_tables_present?() do restore_suite_baseline_schema() end` SECOND

*Reverse-order execution:* file's own on_exit (baseline check/restore) runs FIRST, then `unsandboxed_module`'s revert-to-`:manual` runs LAST — **identical statement order to the original combined on_exit.** Confirmed by running the file twice consecutively on the public axis: 12 tests, 0 failures both times.

For the describe-scoped `"up/down against a non-public prefix"` tests (a THIRD setup, declared inside that `describe` block, applies only to those tests): setup order is `unsandboxed_module` → module-level setup → describe-level setup; on_exit reverse order is describe-level (drop schema, cleanup, citext, restore baseline) → module-level (baseline check) → `unsandboxed_module` revert (`:manual` last) — again identical to the original.

**`upgrade_v2_schema_migration_test.exs`** — single module-level setup, applies to every test:

*Before:*
1. `Sandbox.mode(TestRepo, :auto)`
2. drop target schema, clean public mailglass objects, migrate (seed 1.x state + move)
3. register `on_exit`: drop target schema → clean public mailglass objects → delete `schema_migrations` row → recreate `citext` extension → restore `:schema` env → erase persistent_term cache → `restore_suite_baseline_schema()` → `Sandbox.mode(TestRepo, :manual)`

*After:*
1. `setup :unsandboxed_module` (registered FIRST) — sets `:auto`, registers its own `on_exit` (mode → `:manual`) FIRST
2. file's own `setup do...end` (registered SECOND, body unchanged except the removed `Sandbox.mode(:auto)` line): drop target schema, clean public mailglass objects, migrate; registers `on_exit`: drop target schema → clean public mailglass objects → delete `schema_migrations` row → recreate `citext` extension → restore `:schema` env → erase persistent_term cache → `restore_suite_baseline_schema()` (the trailing `mode(:manual)` line removed)

*Reverse-order execution:* file's own on_exit (the full seven-step restore sequence) runs FIRST — every step in its original relative order — then `unsandboxed_module`'s revert-to-`:manual` runs LAST. **Identical statement order to the original.** Confirmed by running the file twice consecutively on the mailglass axis: 6 tests, 1 failure both times — the SAME pre-existing failure (see Deviations), not a new one, and not a change in count between the two consecutive runs.

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate the three property files** - `a91ba1d2` (feat) — already committed from a prior session; verified, not redone
2. **Task 2: Migrate the four schema-isolation and divergence files** - `6aa87e10` (feat)
3. **Task 3: Migrate the two non-trivial-teardown migration files, verified file-by-file** - `588fbc2c` (feat)

**Plan metadata:** _pending — this commit_

## Files Created/Modified

- `test/mailglass/properties/idempotency_convergence_test.exs` / `unsubscribe_post_idempotency_property_test.exs` / `webhook_suppression_convergence_test.exs` - mode pair replaced with `setup :unsandboxed_module` (Task 1, already committed prior to this execution).
- `test/mailglass/schema_prefix_hardening_test.exs` / `schema_isolation_integration_test.exs` / `schema_isolation_immutability_test.exs` / `shipped_migration_divergence_test.exs` - mode pair replaced with `setup :unsandboxed_module`; one-line Class A/B hand-off comment added to each affected setup pointing at `143-MECHANISM.md`.
- `test/mailglass/migration_test.exs` - module-level setup split into `setup :unsandboxed_module` (new) plus the existing `setup do...end` (conditional restoration logic byte-for-byte unchanged, trailing `mode(:manual)` removed).
- `test/mailglass/upgrade_v2_schema_migration_test.exs` - same split; the file's seven-step restore `on_exit` kept intact minus the trailing `mode(:manual)` call.

## Decisions Made

See `key-decisions` in frontmatter. The two load-bearing ones: (1) Task 2's four files carry hand-off comments naming their Class A/B candidacy from `143-MECHANISM.md` without touching the drift/restoration defect itself; (2) neither Task 3 file was migrated to `unboxed_run/2` — both drive `Ecto.Migrator.with_repo/2`, which spawns a process `unboxed_run` cannot cover, per the file's own pre-existing documentation.

## Deviations from Plan

### Auto-fixed Issues

None — no bugs, missing functionality, or blocking issues were found in code this plan's own changes touch. All investigation below concerns PRE-EXISTING behavior confirmed unchanged by this plan's migration, not new defects introduced by it.

### Investigated discoveries (not fixed — confirmed pre-existing, out of scope)

**1. Transient failures in Task 2's combined/individual public-axis runs, ruled out as external contention, not a regression**

- **Found during:** Task 2, the first combined run of the four schema-isolation/divergence files, and separately the first isolated run of `schema_prefix_hardening_test.exs`.
- **Symptom:** 4 failures (combined run) and 2 failures (isolated run), both shaped as `relation "..." does not exist` or a `Postgrex.ConstraintError`-style mismatch.
- **Investigation:** Reverted the four files to the parent commit and reran the identical commands 3x each — baseline passed cleanly every time. This initially looked like a genuine migration-introduced regression. Re-ran BOTH the baseline and the migrated version 6-10x each in immediate succession: both passed cleanly on every subsequent run. The failures did not reproduce once repeated, on either version, which is inconsistent with a deterministic migration-introduced bug and consistent with the transient external-contention class 143-05's own SUMMARY already documented for this same shared local Postgres instance (concurrent unrelated agent activity in sibling worktrees).
- **Resolution:** Not fixed (nothing to fix — not attributable to this plan's changes). Verified via volume (6-10 repeated clean runs) rather than a single passing re-run, per the coordinator's "prove it, don't reason it" instruction.

**2. `upgrade_v2_schema_migration_test.exs`'s pre-existing "down reverses the move" failure corrupted the shared local test database mid-verification**

- **Found during:** Task 3, verifying `upgrade_v2_schema_migration_test.exs` twice consecutively on the mailglass axis.
- **Symptom:** The file's own known-broken down-side restoration (a pre-existing Class-A-adjacent defect, confirmed identical on the parent commit via 3 separate reverted runs) failed as expected, but its incomplete cleanup left `public.mailglass_suppressions` absent from the shared database. The NEXT, unrelated `mix test test/mailglass/migration_test.exs` invocation then crashed entirely at `test_helper.exs` boot (a citext-warmup query against the now-missing table), before any test in that file even ran.
- **Resolution:** `mix ecto.drop -r Mailglass.TestRepo && mix ecto.create -r Mailglass.TestRepo`, confirmed clean via a smoke test (`mailer_case_test.exs`, 14/14), then re-ran the full required verification set (each file individually twice consecutively, the combined properties+migration+upgrade_v2 run on both axes, `mix verify.schema_prefix`, `mix credo --strict`, `mix format --check-formatted`) against the clean database. Left the shared database in a fully clean, migrated state.
- **Not fixed:** the underlying restoration defect is explicitly out of this plan's scope (deferred to 143-07); only the database's transient corrupted STATE (a side effect of running the pre-existing bug's failure path during verification) was reset — no code change.

---

**Total deviations:** 0 auto-fixed. 2 investigated discoveries, both confirmed pre-existing and traced to their root cause (external contention; a known restoration defect) before being left unchanged.
**Impact on plan:** No code beyond the planned nine-file migration was touched. Both investigations consumed significant verification time but confirmed the migration itself introduces zero regressions.

## Issues Encountered

- `mix test <four files> --warnings-as-errors` and `mix test test/mailglass/properties/ test/mailglass/migration_test.exs test/mailglass/upgrade_v2_schema_migration_test.exs --warnings-as-errors` both hit the pre-existing `redefining module Mailglass.TestRepo.Migrations.*` warning class the coordinator note flagged in advance (already logged to `deferred-items.md` and now also to `.planning/WINDOWS.md` as a `lint-warning`). Read as: test COUNT/NAMES/FAILURES are the signal (all matched expectations), the abort itself is pre-existing and out of this plan's scope (both files are already in plan 143-07's `files_modified`).
- `upgrade_v2_schema_migration_test.exs`'s pre-existing "down reverses the move" failure on the mailglass axis (logged to `deferred-items.md` and `.planning/WINDOWS.md` as a `deviation`) reproduces identically before and after this plan's migration — confirmed via 3 reverted baseline runs plus 2 consecutive post-migration runs, all showing the exact same single failure.

## User Setup Required

None — no external service configuration required. PostgreSQL reachability (`scripts/preflight_postgres.sh`) was verified before starting, and the shared local test database was reset twice (`mix ecto.drop`/`mix ecto.create`) mid-verification after a pre-existing restoration bug corrupted it; both times confirmed clean via a smoke test before continuing.

## Known Stubs

None.

## Threat Flags

None — this plan introduces no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. It only changes HOW nine existing test files acquire/release Sandbox pool-wide `:auto` mode, per the threat model already recorded in the plan (T-143-18, T-143-19, T-143-20).

## Next Phase Readiness

- All nine `:auto`-mode files now route through `SandboxOwnership.unsandboxed_module/1`. Zero raw `Sandbox.mode/2` calls remain anywhere in this set. Plan 143-08's Credo check can now add `:mode` to its forbidden-function list without any remaining legitimate exception in this group (the two files allowlisted per 143-04-SUMMARY — `sandbox_ownership.ex` and its own test — are the only ones that legitimately call it directly).
- Plan 143-07 has two confirmed, evidence-backed starting points from this plan's verification: (1) `schema_prefix_hardening_test.exs` / `shipped_migration_divergence_test.exs` remain named Class A/B candidates per `143-MECHANISM.md`, with the drift/restoration defect untouched; (2) `upgrade_v2_schema_migration_test.exs`'s "down reverses the move" failure is now doubly confirmed (this plan's Task 3 verification, on top of 143-MECHANISM.md's original evidence) as a real, reproducible, pre-existing restoration defect on the mailglass axis.
- The shared local test database is left in a clean, fully-migrated state (confirmed via a final combined run across both schema axes).
- No blockers. All three task commits are green under `mix compile --warnings-as-errors`, `mix credo --strict`, `mix format --check-formatted`.

---
*Phase: 143-test-harness-truth*
*Completed: 2026-07-30*

## Self-Check: PASSED

All nine modified files confirmed present on disk with `setup :unsandboxed_module` and zero raw
`Sandbox.mode/2` calls (verified via grep above). All 3 task commit hashes (`a91ba1d2`, `6aa87e10`,
`588fbc2c`) confirmed present in `git log --oneline`.
