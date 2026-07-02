---
phase: 128-mix-ci-parity-completion-folds-in-pr-104
verified: 2026-07-01T18:35:00Z
status: passed
score: 14/14 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 128: `mix ci` Parity Completion Verification Report

**Phase Goal:** Complete `mix ci` so it equals the mergeable surface (add Installer Host Smoke + trust lane), ship tiered `ci.fast`/`ci`/`ci.browser` aliases + sibling aliases + `make ci`, a manifest-membership parity-drift test (shared source with GATE-03), Postgres/network preflight brand-voice guard, remove deprecated `verify.phase_NN` pass-throughs, land the CONTRIBUTING copy.
**Verified:** 2026-07-01T18:35:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (roadmap success criteria + PLAN must_haves)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix ci` alias body runs all 5 required gates (support_contract.core, admin via cmd --cd, compile --no-optional-deps, reference_host.journey + trust checkpoint, consumer_install_smoke.sh LAST) | ✓ VERIFIED | mix.exs:357-376 — all 5 present; installer smoke is the final step (line 375), preceded by preflight_network.sh (line 374) |
| 2 | Parity-drift test fails when a required CI lane isn't covered (identity+flag-set, anti-vacuity, negative-control) | ✓ VERIFIED | ci_parity_drift_test.exs — matcher table (l.93-127), anti-vacuity bijection (l.154-203), negative-control removes installer step and asserts uncovered (l.205-221). Ran: 10/10 pass |
| 3 | `mix ci`/`ci.setup` with no Postgres prints an actionable brand-voice message, not a raw crash | ✓ VERIFIED | preflight_postgres.sh:52 single brand-voice line, exits 1, no stacktrace. Ran with unreachable host → "Postgres isn't reachable at 203.0.113.1:1. Start it, or set POSTGRES_HOST / POSTGRES_PORT." exit non-zero. Wired first in ci (mix.exs:358) and ci.setup (mix.exs:339) |
| 4 | CONTRIBUTING points at `mix ci` with no `verify.phase_07`; 6 deprecated `verify.phase` pass-throughs removed | ✓ VERIFIED | `grep -c verify.phase_07` = 0 in both mix.exs and CONTRIBUTING.md; no verify.phase_01..04/_07 aliases or preferred_envs entries remain (phase67/69 legitimately retained); CONTRIBUTING documents ci.setup/ci.fast/ci/ci.browser |
| 5 | Phase 127 durable consume: no `--seed 0` in any ci inbound step + committed test refuting any `--seed` token in flattened root ci alias | ✓ VERIFIED | inbound ci step is `test --exclude property` (inbound mix.exs:62, root mix.exs:365) with no seed; committed durable assertion ci_parity_drift_test.exs:223-231; ci.yml `--seed` count = 0 |
| 6 | `mix ci.fast` = static/no-DB subset of `mix ci` | ✓ VERIFIED | ci.fast (mix.exs:347-352) = format/compile w-a-e/no-optional-deps/credo; nested as first real step of ci (mix.exs:359) |
| 7 | `mix ci.browser` opt-in Node tier + `mix ci.setup` creates core+inbound test DBs | ✓ VERIFIED | ci.browser (mix.exs:380-385) npm/playwright; ci.setup (mix.exs:338-342) creates both TestRepos |
| 8 | ci/ci.fast/ci.setup/ci.browser pinned to :test in cli/0 preferred_envs (root + siblings) | ✓ VERIFIED | root mix.exs:49-52; admin mix.exs:36-37; inbound mix.exs:41-42. `mix help ci`/`ci.fast` resolve cleanly |
| 9 | Sibling admin+inbound define ci/ci.fast; inbound ci test step no --seed 0 | ✓ VERIFIED | admin ci→verify.support_contract.admin (mix.exs:195-197); inbound ci→verify.support_contract.inbound + test --exclude property (mix.exs:59-62), no seed |
| 10 | make ci/ci-fast/ci-browser in .PHONY + make help; make ci exports MAILGLASS_PATH | ✓ VERIFIED | Makefile:27 .PHONY, :63-69 targets with `## ` doc comments; ci exports `MAILGLASS_PATH="$$(pwd)"` (:64) |
| 11 | Single ci_lanes source lists 5 required + advisory lanes, read by BOTH GATE-03 and parity-drift | ✓ VERIFIED | ci_lanes.ex — required_lanes/0 (5, verbatim ci.yml), advisory_lanes/0; single-source grep shows definition + 2 readers only |
| 12 | required_checks_test reads @required_leaf_names from shared source; GATE-03 still passes | ✓ VERIFIED | required_checks_test.exs:19 `MapSet.new(Mailglass.CILanes.required_lanes())` (inline literal gone); GATE-03 set-equality ran green |
| 13 | Parity-drift asserts ci ∪ ci.browser covers every required+advisory lane by identity | ✓ VERIFIED | ci_parity_drift_test.exs:143-152 coverage-by-identity; passed |
| 14 | Anti-vacuity guards (empty step-set / empty ci_lanes / bijection) | ✓ VERIFIED | ci_parity_drift_test.exs:154-203; passed |

**Score:** 14/14 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mix.exs` | ci family + preferred_envs; 6 pass-throughs removed | ✓ VERIFIED | Aliases at 338-385; preferred_envs 49-52; verify.phase_07 count 0; phase67/69 retained |
| `mailglass_admin/mix.exs` | ci/ci.fast + preferred_envs | ✓ VERIFIED | Aliases 190-197; preferred_envs 36-37 |
| `mailglass_inbound/mix.exs` | ci/ci.fast, no seed pin | ✓ VERIFIED | Aliases 55-62; preferred_envs 41-42; no --seed |
| `Makefile` | ci/ci-fast/ci-browser in .PHONY | ✓ VERIFIED | Lines 27, 63-69 |
| `CONTRIBUTING.md` | repointed, no verify.phase_07 | ✓ VERIFIED | grep 0; documents tiered workflow; Commit Guidelines intact |
| `scripts/preflight_postgres.sh` | brand-voice PG probe | ✓ VERIFIED | Executable, bash -n ok, fail-closed behaviorally confirmed |
| `scripts/preflight_network.sh` | brand-voice network probe | ✓ VERIFIED | Executable, bash -n ok, brand-voice line at :46 |
| `test/support/ci_lanes.ex` | single lane source | ✓ VERIFIED | Mailglass.CILanes compiled module, 5 required verbatim |
| `test/scripts/ci_parity_drift_test.exs` | MIXCI-03 test | ✓ VERIFIED | 4 tests substantive, all pass |
| `test/scripts/required_checks_test.exs` | GATE-03 rewired | ✓ VERIFIED | Reads shared source; 6 tests pass |

### Key Link Verification

| From | To | Via | Status |
|------|-----|-----|--------|
| ci alias | ci.fast (first real step) | fail-fast cheap-first | ✓ WIRED (mix.exs:359) |
| ci/ci.setup | preflight_postgres.sh (first step) | cmd bash | ✓ WIRED (mix.exs:358, 339) |
| installer smoke | preflight_network.sh (precedes) | cmd bash | ✓ WIRED (mix.exs:374 before 375) |
| root ci | siblings | cmd --cd | ✓ WIRED (mix.exs:363-365) |
| GATE-03 + parity-drift | ci_lanes.ex | Mailglass.CILanes.required_lanes/0 | ✓ WIRED (single-source grep) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Integration meta-tests | `mix test required_checks_test.exs ci_parity_drift_test.exs --warnings-as-errors` | 10 tests, 0 failures | ✓ PASS |
| Preflight fail-closed | `POSTGRES_HOST=203.0.113.1 POSTGRES_PORT=1 bash preflight_postgres.sh` | brand-voice line, exit≠0, no stacktrace | ✓ PASS |
| Alias resolution | `MIX_ENV=test mix help ci` / `ci.fast` | resolve, no MIX_ENV error | ✓ PASS |
| Preflight syntax | `bash -n` both scripts | ok | ✓ PASS |

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| MIXCI-01 | `mix ci` = mergeable surface (5 required gates) | ✓ SATISFIED | Truth 1; all 5 gates + installer last |
| MIXCI-02 | Tiered env-pinned aliases + siblings + make ci | ✓ SATISFIED | Truths 6-10 |
| MIXCI-03 | Parity-drift test, shared source with GATE-03 | ✓ SATISFIED | Truths 11-14; 10/10 tests pass |
| MIXCI-04 | Postgres/network preflight brand-voice guard | ✓ SATISFIED | Truth 3; behavioral fail-closed confirmed |
| MIXCI-05 | Remove deprecated pass-throughs + CONTRIBUTING | ✓ SATISFIED | Truth 4; grep count 0 |

All 5 requirement IDs marked `[x]` in REQUIREMENTS.md and each maps to verified artifacts. No orphaned requirements.

### Anti-Patterns Found

None. No TBD/FIXME/XXX debt markers in any modified file. No stubs — all deliverables are functional alias/script/test/doc code.

Minor cosmetic note (not a gap): the comment block at mix.exs:186-188 still reads "The `verify.phase_NN` keys below are deprecated one-cycle pass-throughs... Remove them in the next release cycle" even though those keys are now removed. This is a stale-comment cosmetic issue only; the functional removal is complete and grep-verified (count 0). Does not affect goal achievement.

### Gaps Summary

None. All 14 must-haves and all 5 requirement IDs verified against the actual codebase. The two scoped DB-free meta-tests (the integration gate) run green (10/10), the preflight guard fails closed with a brand-voice message behaviorally, the alias family resolves under :test, the 6 deprecated pass-throughs are removed (grep 0), and the Phase 127 `--seed` deletion is durably guarded by a committed assertion. SUMMARY claims match the codebase.

---

_Verified: 2026-07-01T18:35:00Z_
_Verifier: Claude (gsd-verifier)_
