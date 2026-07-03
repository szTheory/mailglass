# Phase 137 — v2.0 Release BLOCKED: debug/gap-closure scope

**Created:** 2026-07-03 · **Status:** Release ceremony PAUSED mid-Plan-02 pending a formal debug effort.

## TL;DR

The v2.0 release trigger was cut and opened **PR #119** (`chore: release main`), targeting
**2.0.0 / 2.0.0 / 2.0.0** (D-02 rehearsal confirmed). The first-ever full-body CI of the
132–136 work surfaced **~7 distinct real regressions** (zero flakes). **8 fixes are committed +
pushed to main**; the remainder is a genuine debugging campaign, so per maintainer decision the
release is **paused and this scope is being handled as a formal debug/gap-closure effort**.

**SAFE STATE:** Nothing is published to Hex. PR #119 is **OPEN + BLOCKED**, and **auto-merge is
DISARMED** (`gh pr merge 119 --disable-auto` was run). It cannot publish on its own. Do NOT
re-arm auto-merge or merge #119 until CI is green.

> ⚠️ **AUTO-MERGE RE-ARMS ON EVERY PUSH TO MAIN.** release-please's "Arm auto-merge" step runs
> each time it regenerates the PR (i.e. after any push to main, including debug-fix commits). So
> during this pause, **after every push run `gh pr merge 119 --disable-auto` again** and verify
> `autoMergeRequest == null`. (Observed 2026-07-03: the fix-commit pushes silently re-armed it;
> re-disarmed. It stayed safe only because CI Green was red — do not rely on that.)

## Release mechanics (how to resume once green)

- Publish gate = `CI Green` (branch-protection context), which requires exactly 5 leaves:
  `compile_no_optional_deps`, `installer_host_smoke`, `support_contract_core`,
  `support_contract_admin`, `trust_lane_repo_head`. All other lanes are advisory.
- Maintainer chose **fully green** (not just required-green) before shipping this MAJOR — so the
  advisory Full Suite / browser / lint / docs lanes must also pass.
- RP PR auto-regenerates on each push to main (new head each time). Its CI run is what gates the
  merge. To resume: get main fully green → re-arm auto-merge (or admin-merge) on #119 → watch the
  publish fan-out → verify via `mix hex.info` (NOT run status; racing fan-outs) + consumer smoke
  (Plan 02 Task 4) → then Plan 03 closeout.
- **Deferred baseline advance (MUST redo post-publish):** Plan 01 bumped reference/host_app +
  reference/demo_app mix.exs to `~> 2.0`, but that deadlocked Trust Lane (2.0 unpublished). It was
  reverted to `~> 1.0` (commit `c38d20c0`). After 2.0 publishes, do the full coordinated advance
  (mix.exs `~> 2.0` + regenerate both locks, `MAILGLASS_DEMO_DEPS=hex` for demo_app, adopt the
  mailglass default schema per D-07) — this is Plan 02 Task 4 / the reference-baseline-coupling memo.

## Regression inventory (7 root causes; all real, zero flakes)

| RC | Lane(s) | Root cause | Status |
|----|---------|-----------|--------|
| RC1 | Credo Strict | 16 `D-NN` planning tokens in `mailglass_inbound/lib/` comments | ✅ FIXED `eebd300d` |
| RC2 | Docs Warnings | 2 unqualified `` `Config.schema/0` `` ExDoc autolinks in `credo_checks/no_schema_prefix_attribute.ex` | ✅ FIXED `1fb6b051` |
| RC3 | Core Full Suite (both axes, ~428 fails) | core `test/test_helper.exs` never set up a non-public schema (CREATE SCHEMA + `search_path='<schema>, public'` + migrations) | ✅ HARNESS FIXED `3169228f` — **residual per-test bugs remain (see below)** |
| RC4 | Inbound Full Suite (mailglass) | `test_helper.exs` migrator created `schema_migrations` under `search_path=mailglass` before the schema existed (3F000) | ✅ FIXED `e831b709` (388 tests now run; 1 known pool flake) |
| RC5 | **Support Contract Admin** (REQUIRED) + Operator Browser + Preview Capture | admin operator harness (`operator_live_test.exs` `Facade03WrapperMigration`) migrates **core** tables into the `mailglass` schema but **not inbound** tables → `mailglass.mailglass_inbound_records` missing; 3 lanes cascade | ❌ **NOT DONE** |
| RC6 | Demo Browser Evidence | demo hand-written migrations used unqualified `alter table(:mailglass_deliveries)` after v2.0 moved core tables to the `mailglass` schema | ✅ FIXED `adc27f88` (8 demo migrations qualified) |
| RC7 | Core Full Suite (contract) | `CITrustLaneContractTest:8` forbids a top-level `if:` on the Trust Lane job, but the PR's ci.yml now has one | ❌ **NOT DONE** |
| — | (README stability marker) | `mailglass_inbound` "Stable 1.0" root-README marker vs manifest major 2 | ✅ FIXED `22c03d82` |
| — | Format Check | `mix format` slip in outbound.ex + repo_test.exs | ✅ FIXED `86b1d5cd` |

## Remaining work for the debug effort

### 1. RC5 — admin operator harness inbound migration (REQUIRED merge-blocker)
`mailglass_admin/test/mailglass_admin/operator_live_test.exs` `setup_all` runs
`Ecto.Migrator.up(repo, version, Facade03WrapperMigration)`, whose `up` does only
`Mailglass.Migration.up(prefix: "mailglass", repo: TestRepo)`. It must ALSO create the inbound
tables in the `mailglass` schema. A naive `MailglassInbound.Migration.up` inside the same wrapper
did NOT work (inbound composes via a nested migrator, not direct DDL like core). The canonical
pattern is in `mailglass_inbound/test/test_helper.exs` (an inline wrapper migration calling
`MailglassInbound.Migration.up(prefix:, repo:)` driven by its OWN `Ecto.Migrator.up` with a
separate version slot, + `CREATE SCHEMA` first per RC4). Also heed: raw-SQL fixtures in
`operator_fixtures.ex` TRUNCATE/INSERT unqualified inbound tables — the operator harness sets the
schema via `Application.put_env`/persistent_term (prefix injection), so confirm the fixture
connection resolves to the `mailglass` schema (search_path) or the tables are reachable. This fix
should clear Support Contract Admin + Operator Browser Gate + Preview Capture Advisory (all cascade).

### 2. RC7 — Trust Lane contract test vs ci.yml `if:`
`test/mailglass/publish/ci_trust_lane_contract_test.exs:8` asserts the "Trust Lane Clean Baseline"
job in `ci.yml` has no top-level `if:` (must always run, not path-gated). The PR's ci.yml now has
`if: needs.changes.outputs.code == 'true'` on that job. Decide: remove the `if:` from the Trust
Lane job (restore always-run — likely correct given the contract's intent) OR update the contract
test if the gating is now intended. Determine when/why the `if:` was added (git blame ci.yml).

### 3. Residual full-suite per-test regressions (RC3 tail)
The RC3 harness fix took Core Full Suite from a hard crash to mostly-green, but residual REAL
bugs remain among the ~428 original failures. Confirmed example:
- `test/mailglass/migration_test.exs:146` ("down/0 drops all three tables + trigger + function +
  citext in reverse order") — FAILS under BOTH axes (independent of the harness fix; my RC3 change
  is a no-op for public). Under **public** it fails fast: after `Ecto.Migrator.run(:down, all: true)`
  the immutability function `mailglass_raise_immutability` is **NOT dropped** (`fn_rows ==
  [["mailglass_raise_immutability"]]`, expected `[]`) — a genuine `mix ecto.rollback` correctness
  bug from Phase 134's schema-qualified down path (`00000000000001_mailglass_init.exs` →
  `Mailglass.Migration.down()` → `lib/mailglass/migrations/postgres/v01.ex`). Under **mailglass**
  it times out on `lock_for_migrations` (likely a related down-path/search_path interaction).
- **Enumerate the rest:** run `MAILGLASS_SCHEMA=mailglass mix test --seed 0` and
  `MAILGLASS_SCHEMA=public mix test --seed 0` in repo root; catalog remaining failures; classify
  real-vs-flake (known flakes: `voice_test` "oops" dep-JS noise; the phase-45 inbound property-test
  DB-pool flake — passes in isolation). CI advisory-lane logs on the latest RP-PR head are the
  authoritative full-suite signal (cleaner than local DB state).

### 4. Re-verify + resume
After RC5/RC7/residuals are green locally, push, let RP regenerate #119, confirm CI **fully
green** on the PR head, then resume Plan 02 Task 2 onward (re-arm/admin-merge → publish → verify)
and Plan 03 closeout. Redo the deferred baseline advance post-publish.

## Suggested entry point
`/gsd-debug` (systematic, persistent state) scoped to "v2.0 schema-isolation full-suite
regressions," or a gap-closure plan under the milestone. All diagnoses above came from CI run
`28672395333` (head `f1917bac`) + local repro; the shipped LIBRARY code is largely correct — the
failures are test-harness / migration-rollback / lint / docs / demo drift from cross-phase
(132×133×134×135) interactions the per-phase CI never exercised together.
