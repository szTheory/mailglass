---
phase: 128-mix-ci-parity-completion-folds-in-pr-104
plan: 02
subsystem: testing
tags: [ci, mix-aliases, parity-drift, meta-test, determinism, branch-protection]

# Dependency graph
requires:
  - phase: 128-01
    provides: "The ci / ci.fast / ci.setup / ci.browser alias bodies in mix.exs (the step-sets this test parses); the --seed 0 removal from the inbound ci step"
  - phase: 126-ci-green-fan-in-gate-branch-protection-collapse
    provides: "GATE-03 set-equality + anti-vacuity precedent in required_checks_test.exs"
  - phase: 127
    provides: "DET-02 --seed 0 deletion (now made durable by this plan's committed no-seed assertion)"
provides:
  - "Mailglass.CILanes — single Elixir-side source for required + advisory CI lane identity"
  - "ci_parity_drift_test.exs — MIXCI-03 manifest-membership parity-drift test (ci ∪ ci.browser covers every required + advisory lane by identity)"
  - "Durable DET-02 guard: committed refutation of any --seed token in the flattened root ci alias"
  - "GATE-03 meta-test rewired to read the required-lane set from the shared source"
affects: [phase-131-ship, mix-ci-parity, branch-protection, ci-lane-additions]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single Elixir-side lane-identity source (Mailglass.CILanes) read by every meta-test; YAML/script copies stay as CI-side declarations the meta-tests verify against"
    - "Identity + flag-set coverage via an explicit lane->step-matcher table (not a whole-file substring superset)"
    - "flatten_alias retains alias-reference tokens alongside their transitive expansion; compares step strings against existing atom keys to avoid atom-table exhaustion"

key-files:
  created:
    - test/support/ci_lanes.ex
    - test/scripts/ci_parity_drift_test.exs
  modified:
    - test/scripts/required_checks_test.exs
    - .github/workflows/publish-hex.yml

key-decisions:
  - "Retain nested alias-reference tokens (e.g. verify.support_contract.core) in the flattened step-set alongside their expansion, so lanes named after a semantic alias match by identity while nested concrete steps stay visible for hygiene lanes + the seed guard"
  - "Match alias-key membership by comparing step strings to the existing atom key names (String.to_existing_atom), never String.to_atom on arbitrary step text"

patterns-established:
  - "One-definition-of-green: required + advisory CI lane names live once in Mailglass.CILanes; both GATE-03 and the parity-drift test read it"
  - "Fail-loud gates carry a committed negative-control assertion so the gate itself cannot rot into a vacuous pass"

requirements-completed: [MIXCI-03]

coverage:
  - id: D1
    description: "Mailglass.CILanes single Elixir-side source lists the 5 required + the advisory CI lane display names (verbatim ci.yml), documents intentional cron/live/Docker exclusions"
    requirement: "MIXCI-03"
    verification:
      - kind: unit
        ref: "test/scripts/required_checks_test.exs#ci_green.needs set-equality (GATE-03)"
        status: pass
      - kind: unit
        ref: "test/scripts/ci_parity_drift_test.exs#anti-vacuity: alias step-set, ci_lanes source, and lane/matcher table are all non-empty and bijective"
        status: pass
    human_judgment: false
  - id: D2
    description: "GATE-03 meta-test reads @required_leaf_names from Mailglass.CILanes.required_lanes() (inline literal removed) and all its assertions still pass"
    requirement: "MIXCI-03"
    verification:
      - kind: unit
        ref: "mix test test/scripts/required_checks_test.exs --warnings-as-errors (6 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Parity-drift test asserts mix ci ∪ ci.browser covers every required + advisory lane by identity + flag-set, failing loudly (with a committed negative-control) when a required lane's covering step is dropped"
    requirement: "MIXCI-03"
    verification:
      - kind: unit
        ref: "test/scripts/ci_parity_drift_test.exs#mix ci ∪ ci.browser covers every required + advisory CI lane by identity (MIXCI-03)"
        status: pass
      - kind: unit
        ref: "test/scripts/ci_parity_drift_test.exs#negative control: removing the installer-smoke step makes its lane report uncovered"
        status: pass
      - kind: manual_procedural
        ref: "Fail-loud proof: temporarily removed installer-smoke step from mix.exs ci alias — test FAILED naming 'Installer Host Smoke'; restored (no repo change committed)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Durable DET-02 guard: committed assertion refutes any --seed token in the flattened root ci alias step-set, so reintroducing --seed 0 fails CI"
    requirement: "MIXCI-03"
    verification:
      - kind: unit
        ref: "test/scripts/ci_parity_drift_test.exs#durable determinism guard: the flattened root ci alias step-set pins no fixed seed (DET-02)"
        status: pass
    human_judgment: false

# Metrics
duration: 4min
completed: 2026-07-01
status: complete
---

# Phase 128 Plan 02: Mix↔CI Parity-Drift Test + Shared CILanes Source Summary

**Hoisted the required + advisory CI lane identity to a single `Mailglass.CILanes` source and added a MIXCI-03 parity-drift test proving `mix ci ∪ ci.browser` covers every lane by identity + flag-set, with anti-vacuity guards, a committed negative-control, and a durable no-`--seed` DET-02 assertion.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-01T21:04:09Z
- **Completed:** 2026-07-01T21:08:07Z
- **Tasks:** 2
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments
- `Mailglass.CILanes` (test/support/ci_lanes.ex) is now the ONE Elixir-side definition of the required + advisory CI lane set (names verbatim to `ci.yml`), read by both the GATE-03 meta-test and the new parity-drift test — the D-LD-10 "one definition of green" seam.
- The GATE-03 meta-test (`required_checks_test.exs`) reads `@required_leaf_names` from `Mailglass.CILanes.required_lanes()` instead of an inline literal; all 6 of its tests still pass.
- New `ci_parity_drift_test.exs` asserts by identity + flag-set (via an explicit lane→step-matcher table, not a substring superset) that `mix ci ∪ ci.browser` covers every required + advisory lane, with anti-vacuity guards (non-empty step-set, non-empty ci_lanes source, full lane/matcher bijection) and a negative-control assertion that the coverage function reports "uncovered" when the installer-smoke step is removed.
- Durable DET-02 guard: a committed assertion refutes any `--seed` token in the flattened root `ci` alias step-set, so reintroducing a fixed seed fails CI — making the Phase 127 deletion durable rather than consumed-once.

## Task Commits

1. **Task 1: Shared ci_lanes source + GATE-03 rewire** - `6747fddf` (feat)
2. **Task 2: MIXCI-03 parity-drift + durable seed guard test (TDD)** - `4a3fa5a3` (feat)

_Task 2 was TDD: the first test run (RED) surfaced a real bug (atom-table exhaustion) which was fixed inline before the GREEN run; delivered as one feat commit since the sole artifact is one new test file._

## Files Created/Modified
- `test/support/ci_lanes.ex` - Single Elixir-side source: `required_lanes/0`, `advisory_lanes/0` (+ `advisory_lanes_ci/0`, `advisory_lanes_browser/0`); documents intentional cron/live/Docker exclusions with DX-MIX-CI.md footgun #4/#6 rationale.
- `test/scripts/ci_parity_drift_test.exs` - MIXCI-03 parity-drift test: flattened alias loading, lane→matcher table, coverage-by-identity assertion, anti-vacuity guards, negative-control, durable no-`--seed` assertion.
- `test/scripts/required_checks_test.exs` - `@required_leaf_names` now reads from `Mailglass.CILanes.required_lanes()` (inline MapSet literal removed).
- `.github/workflows/publish-hex.yml` - Comment marker updated (comment-only) to point at `Mailglass.CILanes` as the canonical Elixir-side source; `REQUIRED_LANES` logic unchanged.

## Decisions Made
- **Retain alias-reference tokens alongside expansion in `flatten_alias`.** Nested aliases like `verify.support_contract.core` expand to a big `test ...` step that erases the lane's identity token. Keeping BOTH the reference token and its transitive expansion lets alias-named lanes (Support Contract Core, Trust Lane Repo Head) match by identity while nested concrete steps (inside `ci.fast`) stay visible for hygiene-lane matchers and the seed guard.
- **Never `String.to_atom/1` on arbitrary step text.** Alias-key membership is checked by comparing the step string against the existing atom key names (`MapSet` of `Atom.to_string`), then resolved with `String.to_existing_atom/1` only for known keys — avoiding the atom-table exhaustion that the RED phase exposed.
- `Mix.Project.config()[:aliases]` is the preferred alias-loading path (clean lists of strings; nested refs as bare strings) — no mix.exs text parsing needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Atom-table exhaustion in nested-alias flattening**
- **Found during:** Task 2 (TDD RED run)
- **Issue:** The first `flatten_alias` implementation called `String.to_atom(step)` on every step to test `Keyword.has_key?`. Non-alias steps (e.g. the long `test test/... --warnings-as-errors` contract command) each minted a fresh atom, raising `SystemLimitError` (atom table exhausted) on all four tests.
- **Fix:** Pre-compute the alias key names as a `MapSet` of strings; test step membership against it; resolve only known keys with `String.to_existing_atom/1`.
- **Files modified:** test/scripts/ci_parity_drift_test.exs
- **Verification:** All 4 parity tests pass after the fix.
- **Committed in:** `4a3fa5a3` (Task 2 commit)

**2. [Rule 1 - Bug] Nested-alias expansion erased lane-identity tokens**
- **Found during:** Task 2 (GREEN run after fix #1)
- **Issue:** Flattening replaced `verify.support_contract.core` and `verify.reference_host.journey` with their expansions, so the identity substrings the matchers look for vanished — "Support Contract Core" and "Trust Lane Repo Head" reported uncovered.
- **Fix:** `do_flatten_alias` now emits the alias-reference token AND its transitive expansion (`[step | expansion]`), preserving identity while exposing nested steps.
- **Files modified:** test/scripts/ci_parity_drift_test.exs
- **Verification:** All 4 parity tests pass; the durable seed guard still sees all nested concrete steps.
- **Committed in:** `4a3fa5a3` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 bugs, discovered via the TDD RED→GREEN cycle within the single test-file deliverable).
**Impact on plan:** Both fixes were internal to the new test file and necessary for correctness. No scope creep; no product-code change (D-23 honored — test-support + test files only).

## Issues Encountered
None beyond the two Rule-1 bugs above, which the TDD cycle was designed to surface.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- MIXCI-03 complete: the mix↔CI parity contract is now enforced by a test that fails loudly on drift, sharing one lane-identity source with GATE-03.
- Phase 127 DET-02 is now durable (committed no-`--seed` assertion), unblocking the plain-`mix test` posture Phase 128/131 depend on.
- Phase 128 Wave 2 done. Ready for phase verification / SHIP.

## Verification Results
- `mix test test/scripts/required_checks_test.exs --warnings-as-errors` → 6 tests, 0 failures.
- `mix test test/scripts/ci_parity_drift_test.exs --warnings-as-errors` → 4 tests, 0 failures.
- Combined → 10 tests, 0 failures.
- Single-source proof: `grep -rl 'required_lanes' test/support test/scripts` → `ci_lanes.ex` (definition) + the two meta-tests (readers only); inline `@required_leaf_names` literal gone.
- Fail-loud proof (executed once, not committed): removing the installer-smoke step from the `mix ci` alias made `ci_parity_drift_test.exs` FAIL naming "Installer Host Smoke"; `mix.exs` restored clean.
- `mix.lock` unchanged (no dependency changes).

## Self-Check: PASSED

- `test/support/ci_lanes.ex` — FOUND
- `test/scripts/ci_parity_drift_test.exs` — FOUND
- `.planning/phases/128-.../128-02-SUMMARY.md` — FOUND
- Commit `6747fddf` (Task 1) — FOUND
- Commit `4a3fa5a3` (Task 2) — FOUND

---
*Phase: 128-mix-ci-parity-completion-folds-in-pr-104*
*Completed: 2026-07-01*
