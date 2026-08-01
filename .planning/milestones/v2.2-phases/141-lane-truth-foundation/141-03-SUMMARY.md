---
phase: 141-lane-truth-foundation
plan: 03
subsystem: ci
tags: [ci, github-actions, credo, conformance, lane-classification]

# Dependency graph
requires:
  - phase: 141-01
    provides: "Mailglass.CIYaml job_names/1 parser and mix verify.ci_lane_contract meta-test seam"
provides:
  - "conformance_gates — new BEAM-free ci.yml job (Design System Conformance (shell gates)) running the three design-system shell scripts"
  - "Slimmed credo_strict — now only the suppression-docs shell gate + mix credo --strict"
  - "ci_lanes.ex moduledoc records the new lane's parity exclusion (D-12) and cites MAINTAINING.md by section, not line range"
affects: [141-04, 141-05, 141-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Job-boundary split without duplicating OTP/Elixir setup, dep cache, or dep install — the new job is a checkout plus three greps, matching the shape of the existing branch_protection_advisory job"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - test/support/ci_lanes.ex

key-decisions:
  - "Display name is `Design System Conformance (shell gates)`, not `(Elixir 1.18 / OTP 27)` — the job runs no Elixir at all (RESEARCH F4), and every other `(Elixir 1.18 / OTP 27)` suffix in ci.yml is BEAM-bearing."
  - "credo_strict's display name is deliberately unchanged — this is what collapses D-11's six atomic-rename sites to three (RESEARCH F9): ci.yml:395, ci_lanes.ex:63, and the two ci_parity_drift_test.exs references all needed no edit."
  - "This is a split, not a promotion — neither job entered ci_green.needs (unchanged, still 5 entries). conformance_gates falls into the same unrecognized-but-blocking-if-red tier credo_strict already occupied; classification is deferred to plan 141-04."
  - "SEED-006 cost input corrected: the extra runner costs ~20-40s (checkout + three shell scripts, no OTP/Elixir setup, no dep cache/install), not D-13's original 2-3 minute estimate."

patterns-established:
  - "New BEAM-free ci.yml jobs copy the branch_protection_advisory shape (job key -> name: -> runs-on: -> straight to steps:) but must explicitly add needs: [changes] and if: needs.changes.outputs.code == 'true' — that job omits both, which would be wrong for a job gated by the path filter."

requirements-completed: [CONFORM-04]

coverage:
  - id: D1
    description: "credo_strict split into credo_strict (Credo + suppression-docs gate) and conformance_gates (three design-system shell gates), each nameable from a failed run's job list alone"
    requirement: "CONFORM-04"
    verification:
      - kind: unit
        ref: "grep -cE '^    name: ' .github/workflows/ci.yml == 24"
        status: pass
      - kind: unit
        ref: "mix verify.ci_lane_contract (21 tests, 0 failures)"
        status: pass
      - kind: unit
        ref: "mix test test/scripts/conformance_advisory_test.exs --warnings-as-errors (3 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "ci_lanes.ex moduledoc records Design System Conformance (shell gates) as an intentional mix ci parity exclusion (D-12) and replaces the stale MAINTAINING.md line-range citation with a section citation"
    requirement: "CONFORM-04"
    verification:
      - kind: unit
        ref: "mix test test/scripts/ci_parity_drift_test.exs --warnings-as-errors (4 tests, 0 failures)"
        status: pass
      - kind: unit
        ref: "git diff -U0 test/support/ci_lanes.ex — no @required_lanes/@advisory_lanes_* attribute lines touched"
        status: pass
    human_judgment: false

# Metrics
duration: 4min
completed: 2026-07-28
status: complete
---

# Phase 141 Plan 03: Split `credo_strict` into `credo_strict` + `conformance_gates` Summary

**Renamed nothing, split one job in two: `credo_strict` keeps its display name and now runs only Credo, while the new BEAM-free `conformance_gates` job carries the three design-system shell gates, so a failed CI run's job list names what actually failed.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-28T21:25:32Z
- **Completed:** 2026-07-28T21:28:44Z
- **Tasks:** 2 completed
- **Files modified:** 2

## Accomplishments
- `ci.yml` now declares 24 named jobs (was 23): `credo_strict` (`Credo Strict (Elixir 1.18 / OTP 27)`, 6 steps: checkout, setup, cache, install, suppression-docs gate, `mix credo --strict`) and the new `conformance_gates` (`Design System Conformance (shell gates)`, 4 steps: checkout + the three moved design-system shell gates), inserted immediately before `dialyzer:`.
- The split is a proven pure move: each of the five shell/mix invocations (suppression-docs, motion, hard-fail conformance, advisory conformance, `mix credo --strict`) appears exactly once in the whole file; the load-bearing advisory-arms step name (`Verify design-system conformance (advisory arms — TYPE-lg/xl + TRACK)`) survives byte-for-byte, verified against `test/scripts/conformance_advisory_test.exs`'s marker-split.
- `conformance_gates` is genuinely BEAM-free — no OTP/Elixir setup, no dep cache, no dep install were copied, since all three scripts read only checked-in source (RESEARCH F4). Its only `uses:` step is the pinned `actions/checkout@9c091bb...` copied verbatim, and it keeps `needs: [changes]` + the `code == 'true'` path filter so docs-only pushes still skip it (and `gate-ci-green` already treats skipped as non-blocking).
- `ci_green.needs` is byte-unchanged (still 5 entries, confirmed both by a bounded line count and a diff-based check for the five required-lane keys) — nothing was promoted or demoted; posture before/after this plan is identical.
- `test/support/ci_lanes.ex`'s moduledoc now records `Design System Conformance (shell gates)` as an intentional `mix ci` parity exclusion (D-12: no local-parity step exists for the three shell scripts) and cites `MAINTAINING.md` by section name (`§ "Required Checks"`) instead of a hardcoded line range that plan 141-06's rewrite would have broken (F8). `@required_lanes`, `@advisory_lanes_ci`, and `@advisory_lanes_browser` are untouched — verified by a diff scoped to attribute/string-literal lines returning zero hits.

## Task Commits

Each task was committed atomically:

1. **Task 1: Split `credo_strict` into `credo_strict` + `conformance_gates`** - `4abfcc39` (ci)
2. **Task 2: Record the new lane's parity exclusion and fix the stale `MAINTAINING.md` citation in `ci_lanes.ex`** - `5df79936` (docs)

_Note: neither task used TDD scaffolding — both are direct edits to existing declarative/prose artifacts (YAML job graph, module doc), verified by the plan's grep/awk acceptance criteria and the pre-existing meta-test suite._

## Files Created/Modified
- `.github/workflows/ci.yml` - `credo_strict` slimmed to 6 steps (checkout/setup/cache/install/suppression-docs/`mix credo --strict`); new `conformance_gates` job (4 steps: checkout + three design-system shell gates) inserted before `dialyzer:`
- `test/support/ci_lanes.ex` - Moduledoc gains a D-12 parity-exclusion bullet for the new lane and swaps the stale `MAINTAINING.md` line-range citation for a section citation

## Decisions Made
- Display name `Design System Conformance (shell gates)` chosen over D-08's `(Elixir 1.18 / OTP 27)` recommendation — the job is not BEAM-bearing, and that suffix would mislead (documented in the plan; consequence honored here).
- `credo_strict`'s display name deliberately preserved, collapsing the atomic-rename site count from six to three per RESEARCH F9.
- Corrected SEED-006 cost input: the extra runner costs **~20-40 seconds** (checkout + three greps, no OTP/Elixir setup or dep install), not D-13's original 2-3 minute estimate — recorded here as the input that milestone should use, without acting on it (SEED-006 stays sequenced after v2.2).

## Deviations from Plan

None — plan executed exactly as written. Both tasks' acceptance criteria (grep counts, awk-bounded region checks, ASCII/em-dash scoping, `ci_green.needs` diff assertions) all passed on first attempt; no auto-fixes were needed.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: `.github/workflows/ci.yml` (modified, verified 24 named jobs)
- FOUND: `test/support/ci_lanes.ex` (modified, verified moduledoc-only diff)
- FOUND: commit `4abfcc39` (Task 1)
- FOUND: commit `5df79936` (Task 2)
