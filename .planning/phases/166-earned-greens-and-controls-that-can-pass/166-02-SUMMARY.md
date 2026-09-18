---
phase: 166-earned-greens-and-controls-that-can-pass
plan: 02
subsystem: testing
tags: [ci, ex_unit, suite-floor, drift-guard, elixir, mix]

# Dependency graph
requires:
  - phase: 166-01
    provides: "verify.support_contract.admin widened to directory-scoped; admin coverage floor enforced"
provides:
  - "The required core_deterministic_suite lane enforces the suite-floor (executed-count floor, skipped ceiling, already_shared==0 signature) instead of printing 'floor not evaluated'"
  - "The MAILGLASS_SUITE_FLOOR env line in ci.yml is protected by an occurrence-count drift guard mirroring the advisory-matrix.yml trio"
affects: [167-docs-and-standing-truth]

actuals:
  tokens: 1326
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Sibling counting helper (count_ci_yml_suite_floor_env_entries/1) instead of parameterizing the existing advisory-matrix helper, keeping that trio's behavior byte-identical"
    - "Occurrence-count drift guard trio (assertion + anti-vacuity + negative-control) mirrored verbatim across a second target file"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - test/scripts/lane_classification_drift_test.exs

key-decisions:
  - "D-08 followed exactly: added a sibling `count_ci_yml_suite_floor_env_entries/1` rather than parameterizing `count_suite_floor_env_entries/1`, so the existing advisory-matrix.yml trio's behavior stays byte-identical."
  - "D-07 respected: @suite_floor_env_occurrences left at 2 (counts advisory-matrix.yml only); the new @ci_yml_suite_floor_occurrences (value 1) is a separate constant counting ci.yml only."
  - "D-38 followed: the env line and the guard trio landed in a single commit (4511c205) — neither half alone would pass (the guard's assertion would be false before the env line exists; the env line would be undefended without the guard)."
  - "D-09/D-10 confirmed, not assumed: Task 1 measured the unfiltered floor-enforced run BEFORE touching CI. No constant was re-pinned — the run passed at today's committed floors with headroom (2134 executed vs. 1576 floor, 7 skipped vs. 7 ceiling)."

patterns-established: []

requirements-completed: [GREEN-03]

coverage:
  - id: D1
    description: "core_deterministic_suite's required lane enforces the anti-vacuity suite floor (executed-count floor, skipped ceiling, already_shared==0) instead of skipping evaluation"
    requirement: GREEN-03
    verification:
      - kind: integration
        ref: "MAILGLASS_SUITE_FLOOR=1 mix test --warnings-as-errors (local, unfiltered, pre-CI-edit measurement)"
        status: pass
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs — ci.yml suite-floor occurrence guard describe block"
        status: pass
    human_judgment: false
  - id: D2
    description: "The MAILGLASS_SUITE_FLOOR env line in ci.yml is protected against silent deletion by a mirrored occurrence-count drift guard"
    requirement: GREEN-03
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs#ci.yml's required-lane suite-floor enforcement (GREEN-03) — occurrence assertion, anti-vacuity, negative control"
        status: pass
    human_judgment: false
  - id: D3
    description: "@suite_floor_env_occurrences (advisory-matrix.yml only) was left unchanged at 2, per D-07 — the new guard is a fully separate constant/helper pair"
    requirement: GREEN-03
    verification:
      - kind: unit
        ref: "grep -v '^ *#' test/scripts/lane_classification_drift_test.exs | grep -c '@suite_floor_env_occurrences 2' -> 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "The required lane's own CI run prints the FULL SUITE scope line (milestone exit criterion 2) — this is observable only in the PR's own CI run, not locally reproducible as proof of the CI edit itself"
    verification: []
    human_judgment: true
    rationale: "Local proof (Task 1) demonstrates the env var mechanism works and the numbers hold; the PR's own required-lane log line is the actual GREEN-03 acceptance criterion and can only be observed post-push, per the plan's Post-Merge Verification note."

duration: 15min
completed: 2026-09-17
status: complete
---

# Phase 166 Plan 02: Earned Greens and Controls That Can Pass — Suite-Floor Enforcement Summary

**Turned the required `core_deterministic_suite` lane's anti-vacuity suite floor from advisory to enforced by setting `MAILGLASS_SUITE_FLOOR: "1"` in `ci.yml`, and added a mirrored occurrence-count drift guard so the env line can't be silently deleted.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-09-17T21:57:00Z
- **Completed:** 2026-09-17T22:12:00Z
- **Tasks:** 2 completed
- **Files modified:** 2 (`.github/workflows/ci.yml`, `test/scripts/lane_classification_drift_test.exs`)

## Accomplishments

- **Task 1 (measurement gate, no files modified):** Ran the unfiltered `MAILGLASS_SUITE_FLOOR=1 mix test --warnings-as-errors` locally before touching CI, per D-10. Result: `23 properties, 2145 tests, 0 failures, 27 excluded, 7 skipped`. The SuiteFloor report printed `scope: FULL SUITE (MAILGLASS_SUITE_FLOOR=1) — executed floor 1576, skipped ceiling 7 enforced`, with `signature tally: already_shared=0, formatter_violations=0` and `total: 2168, excluded: 27, skipped: 7, executed: 2134`. Both committed constants held with margin: 2134 executed ≥ 1576 floor; 7 skipped ≤ 7 ceiling (exactly at the ceiling, as expected). A 558-test growth nudge printed as an advisory warning (not a failure), consistent with `@nudge_margin 40` being informational only. No constant re-pinning was needed — D-09's prediction held.
- **Task 2:** Added `MAILGLASS_SUITE_FLOOR: "1"` to `ci.yml`'s `core_deterministic_suite` job, inside the existing `Run deterministic core suite` step's `env:` block (one line, one occurrence). Extended `test/scripts/lane_classification_drift_test.exs` with a new `@ci_yml_suite_floor_occurrences 1` constant, a sibling `count_ci_yml_suite_floor_env_entries/1` helper (kept separate from `count_suite_floor_env_entries/1` rather than parameterizing it, per D-08, so the advisory-matrix.yml trio's behavior stays byte-identical), and a new `describe "ci.yml's required-lane suite-floor enforcement (GREEN-03)"` block containing the same three-test trio as the advisory-matrix analog: occurrence-count assertion, anti-vacuity, negative control. Both halves landed in one commit (D-38).

## Task Commits

Each task was committed atomically:

1. **Task 1: Demonstrate the unfiltered suite-floor run is green locally before touching CI (D-10)** — measurement-only, no files modified, no commit (verified by `git status --porcelain` returning empty after the run).
2. **Task 2: Set MAILGLASS_SUITE_FLOOR in ci.yml and extend the occurrence guard to ci.yml — one commit** — `4511c205` (feat)

**Plan metadata:** (pending — see below)

## Files Created/Modified

- `.github/workflows/ci.yml` — added `MAILGLASS_SUITE_FLOOR: "1"` to the `core_deterministic_suite` job's `Run deterministic core suite` step `env:` block (1 line)
- `test/scripts/lane_classification_drift_test.exs` — new `@ci_yml_suite_floor_occurrences` constant, new `count_ci_yml_suite_floor_env_entries/1` helper, new `describe` block with 3 tests (65 lines total)

## Decisions Made

- Followed D-08's exact template (the advisory-matrix.yml trio, quoted verbatim in `166-PATTERNS.md`) rather than inventing new test shapes — the mirror was retargeted at `ci.yml` with no structural deviation.
- Chose the "sibling helper" option over "parameterize the existing helper" (both were explicitly allowed by the plan) to guarantee zero behavior change to the already-passing advisory-matrix.yml tests.
- `test/support/suite_floor.ex` was read for context (Task 1's `read_first`) but never modified — the runtime consumer needed no code change, only its env var now being set (D-09).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The measurement gate (Task 1) confirmed D-09/D-10's prediction on the first run — no sandbox-ownership red, no floor violation, no re-pinning needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- GREEN-03 is satisfied locally (Task 1's measured proof) and the mechanism is in place for the PR's own required-lane run to print the FULL SUITE scope line — the plan's Post-Merge Verification note defers that specific log-line observation to the PR's own CI run, which is the milestone's stated exit criterion 2.
- `@suite_floor_env_occurrences` (advisory-matrix.yml, value 2) and `@ci_yml_suite_floor_occurrences` (ci.yml, value 1) are two fully independent constants reading two different files — confirmed they never collide.
- `test/support/suite_floor.ex` is unmodified (`git diff --quiet` exit 0) — the runtime enforcement logic needed no change, only its env var now being set in the one required lane.
- Ready for PR-3 of five (D-37 slicing plan): plans 03-06 remain (GREEN-04, GREEN-05, CTRL-01..03, and any remaining requirements in `.planning/phases/166-earned-greens-and-controls-that-can-pass/`).

---
*Phase: 166-earned-greens-and-controls-that-can-pass*
*Completed: 2026-09-17*

## Self-Check: PASSED

All modified files confirmed present on disk (`.github/workflows/ci.yml`, `test/scripts/lane_classification_drift_test.exs`, this SUMMARY). Commit hash `4511c205` confirmed present in `git log`. `git show --stat --pretty=format: 4511c205` lists exactly the two expected files. `git diff --quiet -- test/support/suite_floor.ex` confirms it is unmodified. All plan verify commands (`mix test test/scripts/lane_classification_drift_test.exs`, `grep -c 'MAILGLASS_SUITE_FLOOR: "1"' ci.yml` = 1, `@suite_floor_env_occurrences 2` count = 1, `actionlint .github/workflows/ci.yml` exit 0) re-run clean at SUMMARY-write time.
