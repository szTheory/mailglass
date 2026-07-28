---
phase: 141-lane-truth-foundation
plan: 01
subsystem: testing
tags: [ci, github-actions, elixir, exunit, drift-detection, hex-publish]

# Dependency graph
requires: []
provides:
  - "Mailglass.CIYaml (test/support/ci_yaml.ex) — job_names/1 and matrix_job_names/1 parsers for ci.yml"
  - "verify.ci_lane_contract mix alias, wired into ci.yml's mix_task_tests job (publish-gating)"
  - "test/scripts/lane_classification_drift_test.exs — the drift meta-test seam plans 141-04/141-05 extend"
  - "F5 fix: test/scripts/ now compiles clean under --warnings-as-errors"
affects: [141-02, 141-03, 141-04, 141-05, 141-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Text-level (not YAML-parsing) regex extraction of ci.yml job structure, mirroring required_checks_test.exs's private parsers but exposed as a public test/support module"
    - "case-with-empty-set-fallback JS-array parsing so a format change fires the anti-vacuity assert instead of a MatchError"
    - "Shared private drift/2 helper reused by both the real assertion and its negative control, so a future weakening of the helper breaks the negative control too"

key-files:
  created:
    - test/support/ci_yaml.ex
    - test/scripts/lane_classification_drift_test.exs
  modified:
    - test/scripts/ci_parity_drift_test.exs
    - mix.exs
    - .github/workflows/ci.yml

key-decisions:
  - "Wired the drift meta-test into mix_task_tests (publish-gating), NOT support_contract_core (merge-gating) — registry drift blocks a Hex publish, not a PR merge, per Phase 141's explicit scope lock."
  - "verify.ci_lane_contract carries --warnings-as-errors like every sibling verify.* alias; the pre-existing dead assertion blocking that flag was removed rather than worked around."
  - "required_checks_test.exs's five defp parsers were deliberately NOT refactored to delegate to the new Mailglass.CIYaml — GATE-03 is load-bearing for this phase's own correctness; the ~20-line duplication is accepted debt."

patterns-established:
  - "Mailglass.CIYaml is the reusable ci.yml text-parser seam for future lane-classification meta-tests (141-04, 141-05)."

requirements-completed: [TRUTH-07]

coverage:
  - id: D1
    description: "publish-hex.yml's REQUIRED_LANES JS array set-equals Mailglass.CILanes.required_lanes/0, asserted by a meta-test that now actually runs in CI"
    requirement: "TRUTH-07"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs#REQUIRED_LANES (publish-hex.yml) set-equals Mailglass.CILanes.required_lanes/0"
        status: pass
    human_judgment: false
  - id: D2
    description: "The meta-test is wired into a real ci.yml job step (mix_task_tests), closing the F2 gap where a correct meta-test enforced nothing because nothing ran it"
    requirement: "TRUTH-07"
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix verify.ci_lane_contract (invoked by .github/workflows/ci.yml mix_task_tests step 'Run CI lane-contract meta-tests')"
        status: pass
    human_judgment: false
  - id: D3
    description: "No matrix-strategy ci.yml job's display name collides with REQUIRED_LANES's exact-equality match (F1 safety), machine-enforced rather than a comment"
    requirement: "TRUTH-07"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs#no matrix-strategy ci.yml job's display name appears in REQUIRED_LANES (F1 safety)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The drift comparison fails loud (not vacuously) on an injected single-entry divergence — ROADMAP criterion 1b as a standing automated assertion"
    requirement: "TRUTH-07"
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs#negative control: removing one entry from the parsed REQUIRED_LANES set makes the drift comparison report it (fail-loud property is tested)"
        status: pass
    human_judgment: false
  - id: D5
    description: "test/scripts/ compiles clean under --warnings-as-errors (F5 dead-assertion removal)"
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix test test/scripts/ --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D6
    description: "ci_green.needs (branch-protection merge-gating set) is byte-unchanged by this plan"
    verification:
      - kind: other
        ref: "awk '/^  ci_green:$/{f=1;next} /^    steps:$/{f=0} f' .github/workflows/ci.yml | grep -c trust_lane_repo_head -> 1; git diff .github/workflows/ci.yml | grep -cE '^[+-]      - (compile_no_optional_deps|installer_host_smoke|support_contract_core|support_contract_admin|trust_lane_repo_head)$' -> 0"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-28
status: complete
---

# Phase 141 Plan 01: Lane-Contract Truth Seam Summary

**Wired the first `ci.yml` lane that can observe registry drift at all: a new `Mailglass.CIYaml` parser module, a `lane_classification_drift_test.exs` meta-test proven both to detect real drift and to fail loud on injected drift, and a `verify.ci_lane_contract` alias invoked from a real `mix_task_tests` CI step — so `publish-hex.yml`'s `REQUIRED_LANES` diverging from `Mailglass.CILanes.required_lanes/0` now blocks a Hex publish.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-28
- **Tasks:** 2 (Task 1: tracer/end-to-end seam, Task 2: negative control)
- **Files modified:** 5 (2 created, 3 modified)

## Accomplishments

- Closed RESEARCH.md's **F2** gap: before this plan, no `ci.yml` lane executed `test/scripts/` at all, so any drift meta-test placed there would have satisfied ROADMAP criterion 1 on paper while enforcing nothing. The `mix_task_tests` job now runs `mix verify.ci_lane_contract` as a real step.
- Created `Mailglass.CIYaml` (`test/support/ci_yaml.ex`) exposing `job_names/1` and `matrix_job_names/1` — lifted verbatim from `required_checks_test.exs`'s private parsers, now callable from a second meta-test without refactoring the GATE-03 gate itself.
- Created `test/scripts/lane_classification_drift_test.exs` proving, by identity (not substring match), that `publish-hex.yml`'s `REQUIRED_LANES` array set-equals `Mailglass.CILanes.required_lanes/0`, that no matrix-strategy job's display name could ever collide with `REQUIRED_LANES`'s exact-equality match (RESEARCH **F1** — GitHub appends matrix values to a matrix job's runtime name), and that every parser carries an anti-vacuity guard.
- Fixed **F5**: deleted the dead `lanes != []` assertion in `ci_parity_drift_test.exs` that Elixir 1.18's type inference proves always true (a latent dead gate inside the repo's own drift-protection machinery), unblocking `--warnings-as-errors` for the new alias.
- Added a negative-control test (Task 2) that mechanically proves the fail-loud property: sanity-asserts today's agreement, removes "Installer Host Smoke" from a copy of the parsed set, and asserts the shared `drift/2` helper reports exactly that entry missing — not a vacuous pass.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end lane-contract seam — required lanes only, wired to a real CI job** - `aa004dd7` (feat)
2. **Task 2: Negative control — prove the seam fails loud instead of passing vacuously** - `abe92a3d` (test)

_Both tasks carried `tdd="true"`; verification was run against the real, non-mocked `ci.yml`/`publish-hex.yml` files rather than a separate RED/GREEN cycle, since the assertions are meta-tests over already-existing (or already-fixed) source files rather than new application behavior. Each task's `<verify>` command was run and confirmed green before committing._

## Files Created/Modified

- `test/support/ci_yaml.ex` - New `Mailglass.CIYaml` module: `job_names/1` (job_key => display_name map) and `matrix_job_names/1` (MapSet of display names for `strategy:` jobs), both parsing raw `ci.yml` source text.
- `test/scripts/lane_classification_drift_test.exs` - New meta-test: `REQUIRED_LANES` ↔ `Mailglass.CILanes.required_lanes/0` set-equality, matrix-lane exact-match safety, anti-vacuity guards, and a negative-control test proving fail-loud behavior.
- `test/scripts/ci_parity_drift_test.exs` - Deleted the dead `assert lanes != []` (F5); updated the `@moduledoc` claim to describe the surviving `== 5` guard instead.
- `mix.exs` - Added the `"verify.ci_lane_contract": ["test test/scripts/ --warnings-as-errors"]` alias (directly after `verify.mix_tasks`) and its `preferred_cli_env` entry.
- `.github/workflows/ci.yml` - Added one step, `Run CI lane-contract meta-tests` (`run: mix verify.ci_lane_contract`), to the existing `mix_task_tests` job, immediately after `Run mix-task / generator tests`. No new job, no `ci_green.needs` change.

## Decisions Made

1. **The drift meta-test is wired into `mix_task_tests`, NOT `support_contract_core`** — `mix_task_tests` is publish-gating (absent from `ci_green.needs`); wiring to a merge-gating job would have changed what blocks a PR merge, which is explicitly out of scope for Phase 141. Consequence: drift blocks a release, not a PR (accepted per plan).
2. **The alias carries `--warnings-as-errors`**, matching every sibling `verify.*` alias — the pre-existing dead assertion blocking the flag (F5) was removed as part of this task rather than worked around by dropping the flag.
3. **`required_checks_test.exs` was NOT refactored to delegate to `Mailglass.CIYaml`** — its five parsers stay `defp` and duplicated (~20 lines); GATE-03 is load-bearing for this phase's own correctness, and refactoring it mid-phase risks collateral damage. Recorded as accepted debt in the new module's `@moduledoc`.

## Deviations from Plan

None - plan executed exactly as written. Both tasks' `<action>` steps were followed verbatim; all `<acceptance_criteria>` checks (including the `ci_green.needs` byte-unchanged assertions) were run and passed without needing any code adjustment beyond the planned edits.

## Issues Encountered

None. The one `drift/2` argument-order subtlety (which tuple element represents "missing from the JS array" vs "missing from the registry" when called as `drift(broken_js_set, @required_lanes)`) was caught and corrected during authoring, before running the tests — not a runtime failure.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The `Mailglass.CIYaml` parser seam this plan built is exactly what plans 141-04 and 141-05 need to extend the classification from "required lanes only" to the full 24-row disposition ledger (publish-gating / advisory / structural axes).
- `Mailglass.CILanes.required_lanes/0` is now proven, via a CI-executed meta-test, to agree with `publish-hex.yml`'s `REQUIRED_LANES` — the one registry pairing later plans can build the remaining three pairings (`ci_lanes.ex` ↔ `MAINTAINING.md`, `ci_lanes.ex` ↔ `ci.yml` job set, `MAINTAINING.md` ↔ disposition completeness) on top of, with a working end-to-end enforcement loop as precedent.
- `ci_green.needs` (merge-gating) is untouched; nothing about what blocks a PR merge changed in this plan, consistent with the phase's scope lock.
- No blockers for 141-02 through 141-06.

---
*Phase: 141-lane-truth-foundation*
*Completed: 2026-07-28*
