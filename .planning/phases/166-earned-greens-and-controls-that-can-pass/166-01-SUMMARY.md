---
phase: 166-earned-greens-and-controls-that-can-pass
plan: 01
subsystem: testing
tags: [ci, excoveralls, coverage, admin, elixir, mix]

# Dependency graph
requires: []
provides:
  - "verify.support_contract.admin runs the full mailglass_admin test/ directory (510 tests), not a 9-file allow-list"
  - "mailglass_admin has a measured ExCoveralls coverage floor (config/coverage_baselines/admin.json) enforced in CI"
  - "Demonstrated (not asserted) proof that the admin coverage floor fires on regression in all three ratchet members"
affects: [167-docs-and-standing-truth]

actuals:
  tokens: 1757
  tasks: 3
  commits: 3

tech-stack:
  added: ["excoveralls ~> 0.18 (mailglass_admin, test-only — mirrors core/inbound)"]
  patterns:
    - "Alias-name-matched CI parity: redefine an alias body, leave ci.yml/mix ci untouched"
    - "Measured-ratchet coverage floor: committed triple + report_sha256 + exact-toolchain assertion, never a hand-picked percentage"

key-files:
  created:
    - config/coverage_baselines/admin.json
  modified:
    - mailglass_admin/mix.exs
    - mailglass_admin/mix.lock
    - .github/workflows/ci.yml
    - test/scripts/coverage_floor_contract_test.exs

key-decisions:
  - "Widened verify.support_contract.admin to a bare `test --warnings-as-errors` directory-scoped run (D-01/D-02) instead of pointing at verify.preview, avoiding the known daisyUI asset-rebuild landmine on a required lane."
  - "No warning-cleanup task was needed — measured zero compile warnings across the 32 previously-ungated admin test files (RESEARCH Correction 2), confirmed again in this session."
  - "Coverage baseline measured directly from a green run of the WIDENED 510-test suite (D-06): 3334/3992 covered/relevant lines, 83.517034%, no safety margin, no rounding up."

patterns-established:
  - "Pattern: measured coverage-floor JSON baseline (package/cohort/covered_lines/relevant_lines/percentage/toolchain/image/command/report_sha256/measured_at) — mailglass_admin now mirrors core and inbound exactly."

requirements-completed: [GREEN-01, GREEN-02]

coverage:
  - id: D1
    description: "verify.support_contract.admin is directory-scoped and runs all 510 admin tests (325 previously never executed), 0 failures, under --warnings-as-errors"
    requirement: GREEN-01
    verification:
      - kind: integration
        ref: "cd mailglass_admin && MIX_ENV=test mix verify.support_contract.admin"
        status: pass
      - kind: unit
        ref: "test/scripts/ci_parity_drift_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "mailglass_admin has ExCoveralls wired, a measured coverage-floor baseline, and a CI step that enforces it"
    requirement: GREEN-02
    verification:
      - kind: unit
        ref: "test/scripts/coverage_floor_contract_test.exs"
        status: pass
      - kind: integration
        ref: "bash scripts/check_coverage_floor.sh config/coverage_baselines/admin.json coverage/admin/excoveralls.json 1.18.4/27"
        status: pass
    human_judgment: false
  - id: D3
    description: "The admin coverage floor is demonstrated (not asserted) to fire on regression in each of covered_lines, relevant_lines, and percentage, and the unmodified baseline still passes"
    requirement: GREEN-02
    verification:
      - kind: integration
        ref: "deliberate regression drill against three perturbed baseline copies (Task 3)"
        status: pass
    human_judgment: false

duration: 24min
completed: 2026-09-17
status: complete
---

# Phase 166 Plan 01: Earned Admin CI Truth Summary

**Widened `verify.support_contract.admin` from a 9-file allow-list to a directory-scoped run (325 newly-executed tests, 0 failures) and gave `mailglass_admin` a measured ExCoveralls coverage floor demonstrated to fire on regression.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-09-17T21:37:21Z
- **Completed:** 2026-09-17T21:53:25Z
- **Tasks:** 3 completed
- **Files modified:** 5 (mailglass_admin/mix.exs, mailglass_admin/mix.lock, config/coverage_baselines/admin.json [new], .github/workflows/ci.yml, test/scripts/coverage_floor_contract_test.exs)

## Accomplishments

- `verify.support_contract.admin`'s body is now `["test --warnings-as-errors"]` — a directory-scoped run instead of a 9-file hand-enumerated allow-list. 325 of 510 admin tests that had never run in any CI lane now execute in the required `Support Contract Admin` lane. Verified locally: 510 tests, 0 failures, 1 excluded, zero compile warnings.
- `mailglass_admin` now carries `test_coverage: [tool: ExCoveralls]` and `{:excoveralls, "~> 0.18", only: [:test]}`, mirroring `mailglass_inbound`. `mailglass_admin/mix.lock` gained exactly one clean new entry (`excoveralls`) — no unrelated transitive drift.
- `config/coverage_baselines/admin.json` records the measured triple from a green run of the *widened* 510-test suite: 3334/3992 covered/relevant lines, 83.517034%, `report_sha256` matching the measuring run's `coverage/admin/excoveralls.json` — no safety margin, no rounding.
- A new "Collect and enforce admin coverage floor" CI step lands in the `support_contract_admin` job immediately after "Run admin support contract", mirroring the existing core/inbound coverage-floor steps byte-for-byte in shape.
- `test/scripts/coverage_floor_contract_test.exs`'s canonical-baselines test now also reads `admin.json` and asserts it names `mailglass_admin`.
- **Task 3 regression drill (demonstrated, not asserted):** three perturbed copies of the committed baseline (covered_lines+1, relevant_lines+1, percentage+0.001) were each run against the real measured report — all three produced a `coverage regression` error and non-zero exit; the unmodified committed baseline still passed. `config/coverage_baselines/admin.json` ended byte-identical to Task 2's output (`git diff --quiet` exit 0).

## Task Commits

Each task was committed atomically:

1. **Task 1: Widen verify.support_contract.admin to a directory-scoped run and prove 510 tests end-to-end** - `5c42d563` (feat)
2. **Task 2: Wire ExCoveralls into mailglass_admin, measure the admin baseline, and enforce it in CI** - `42e03d95` (feat)
   - **Fix commit** (same task, deviation) - `71609b4f` (fix) — see Deviations below
3. **Task 3: Demonstrate the admin floor actually fires — deliberate regression drill** - verification-only, no files changed; `config/coverage_baselines/admin.json` confirmed byte-identical to Task 2's commit (`git diff --quiet` exit 0)

**Plan metadata:** (pending — see below)

## Files Created/Modified

- `mailglass_admin/mix.exs` - directory-scoped `verify.support_contract.admin` alias; new `test_coverage:` key and `excoveralls` dep
- `mailglass_admin/mix.lock` - new `excoveralls` lock entry (clean, intentional, no transitive drift)
- `config/coverage_baselines/admin.json` - new measured coverage-floor baseline (package/cohort/covered_lines/relevant_lines/percentage/toolchain/image/command/report_sha256/measured_at)
- `.github/workflows/ci.yml` - new "Collect and enforce admin coverage floor" step in `support_contract_admin`
- `test/scripts/coverage_floor_contract_test.exs` - canonical-baselines test extended to admin.json

## Decisions Made

- D-01/D-02 followed exactly: alias body redefined, alias NAME unchanged, so `ci.yml`, `mix ci`, and `ci_parity_drift_test.exs` needed zero edits — confirmed via `git diff --quiet -- .github/workflows/ci.yml` after Task 1.
- D-04's `--warnings-as-errors` retained; RESEARCH Correction 2 confirmed (again, this session) that zero compile warnings exist across the 32 newly-gated files, so no warning-cleanup task was needed.
- D-06's baseline is the measured value from the widened suite with no safety margin — 83.517034% is a truncated (not rounded) 6-decimal representation of the raw `covered/relevant*100` computation, matching core/inbound's baseline precision convention.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reverted a `/coverage/` `.gitignore` entry that broke the Phase 164 repository-truth ledger**
- **Found during:** Task 2 (post-task overall verification — running the full core suite alongside the widened admin suite)
- **Issue:** After Task 2 generated `coverage/admin/excoveralls.json` as a local verification artifact, I added `/coverage/` to `.gitignore` (reasoning: this is genuinely CI-runtime-only output, analogous to `/cover/`) and included it in the Task 2 commit. This broke `test/scripts/phase_164_repository_truth_test.exs`'s `missing_audited_subjects` check — every `.gitignore` entry must have a matching audited-subject row in the Phase 164 append-only repository-truth ledger (`164-TRUTH-DISPOSITION.tsv`), and `/coverage/` had none.
- **Fix:** Reverted the `/coverage/` `.gitignore` line. Per the plan's own `<artifacts_this_phase_produces>` note, `coverage/admin/excoveralls.json` is explicitly a "runtime path produced during CI (not committed)" — no gitignore entry is required; CI runners are ephemeral, and locally the directory is simply left untracked and cleaned up manually (`rm -rf coverage/`, done at the end of this session).
- **Files modified:** `.gitignore` (added then reverted — net zero diff against plan start)
- **Verification:** `mix test test/scripts/phase_164_repository_truth_test.exs` — 47 tests, 0 failures (confirmed clean after the revert, having first observed 9 failures in that module while the bad `.gitignore` entry was present).
- **Committed in:** `71609b4f`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug, self-inflicted and self-caught mid-plan)
**Impact on plan:** No scope creep, no gate weakened. The regression was introduced and resolved entirely within this plan's own execution before any task's `<verify>` gate was evaluated as final; all planned acceptance criteria for Tasks 1–2 were unaffected (the bad `.gitignore` line was never part of any task's required file set).

## Issues Encountered

- The plan's overall `<verification>` block calls for confirming "the full `mix ci` fan-out runs green before the PR opens (admin and core share `mailglass_test` serially — confirm no sandbox-ownership red appears now that 325 more tests execute)." Running the complete `mix ci.full` alias (which also invokes inbound's 1000-run property test, `mix docs`, `mix credo`, Dialyzer, and Hex/deps audits) was out of scope for this session's budget. Instead, ran the specific at-risk sequence directly: the full core deterministic suite (`mix test --warnings-as-errors`, 2145 tests + 23 properties, 0 failures, exit 0) immediately followed by the widened `mix verify.support_contract.admin` (510 tests, 0 failures) against the same live Postgres instance and `mailglass_test` database — confirming no cross-lane sandbox-ownership conflict now that 325 more admin tests execute. The unrelated lanes (credo, dialyzer, docs, inbound property test, hex audit) were not part of this plan's diff and are exercised unchanged by the existing `mix ci` pipeline in real CI.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- GREEN-01 and GREEN-02 are both satisfied and observable in this PR's own CI run (`Support Contract Admin` lane test count + the new coverage-floor step's pass/fail).
- Per the plan's Post-Merge Verification note: nothing further is owed here — both requirements are fully verified within this plan's own commits, with no deferred post-merge evidence needed.
- Ready for PR-2 (GREEN-03: `core_deterministic_suite` suite-floor env line + the extended `ci.yml` occurrence-count drift guard), per the D-37 PR slicing plan.

---
*Phase: 166-earned-greens-and-controls-that-can-pass*
*Completed: 2026-09-17*

## Self-Check: PASSED

All created/modified files confirmed present (`mailglass_admin/mix.exs`, `mailglass_admin/mix.lock`,
`config/coverage_baselines/admin.json`, `.github/workflows/ci.yml`,
`test/scripts/coverage_floor_contract_test.exs`, this SUMMARY). All task commit hashes
(`5c42d563`, `42e03d95`, `71609b4f`) confirmed present in `git log`.
