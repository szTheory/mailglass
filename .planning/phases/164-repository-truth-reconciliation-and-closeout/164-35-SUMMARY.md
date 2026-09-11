---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 35
subsystem: repository-truth-closeout
tags: [authority-chain, runtime-closure, repository-identity, tdd, ci-boundaries]
status: complete
requires:
  - phase: 164-34
    provides: reconciled 01-34 evidence, ledger authority, and pending terminal lifecycle
provides:
  - authenticated physical Mix, Elixir, and Erlang runtime closure in the exact finalization environment
  - one loader-captured authority OID enforced across both Bash boundaries and final repository observations
  - exact 01-39 history contract with separate repository, proposal, and installed-host verification lanes
affects: [phase-164-36-protected-integration, phase-164-37-proposal-approval, phase-164-38-installation, phase-164-39-final-reconciliation]
actuals:
  tokens: 17298
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns:
    - authenticate physical executables before constructing child PATH
    - pass one full authority OID explicitly across every process boundary
    - keep proposal and installed-host tests outside repository-only CI
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-35-SUMMARY.md
  modified:
    - scripts/mailglass_finalize_phase_loader.mjs
    - scripts/finalize_phase_164.sh
    - scripts/closeout_repository_truth.sh
    - test/scripts/phase_164_closeout_test.exs
    - mix.exs
    - test/support/suite_floor.ex
    - test/scripts/suite_floor_contract_test.exs
    - test/scripts/ci_parity_drift_test.exs
    - test/scripts/scheduled_control_evidence_test.exs
key-decisions:
  - "Finalization runtime authority is the versioned physical Elixir 1.19.5 / Erlang 28 closure, not asdf shims or inherited ASDF selectors."
  - "The Node-authenticated commit remains immutable data through finalizer and closeout; later HEAD observations validate it rather than recapturing authority."
  - "Proposal and installed-host groups have dedicated non-vacuous aliases and are explicitly excluded from repository-only CI."
patterns-established:
  - "Runtime closure: authenticate Mix, Elixir, and Erlang files, construct one allowlisted environment, then probe all three before dispatch."
  - "Authority handoff: require the captured full OID positionally at the finalizer and by named flag at closeout, with equality checks before evidence and after collection."
requirements-completed: [TRTH-03]
coverage:
  - id: D1
    description: "Physical Mix, Elixir, and Erlang identities execute compatible probes in the exact sanitized finalization environment."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix test test/scripts/phase_164_closeout_test.exs --exclude phase_164_installed_production_boundary --exclude phase_164_proposal_boundary --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "The loader-authenticated authority OID is mandatory through both Bash layers and a clean inter-process HEAD advance fails before evidence."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix verify.phase_164.authority_closure"
        status: pass
    human_judgment: false
  - id: D3
    description: "Exact history is 01-39 and repository, proposal, and installed-host verification selections remain distinct and non-vacuous."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix verify.ci_lane_contract"
        status: pass
      - kind: unit
        ref: "mix verify.phase_164.proposal_boundary"
        status: pass
    human_judgment: false
duration: 34m
completed: 2026-09-11
plan_head_before: 337903626d88296b230700fab30b4d17c55019ac
---

# Phase 164 Plan 35: Executable Authority Chain Closure Summary

**Finalization now runs a physically authenticated BEAM toolchain and preserves one loader-authenticated commit identity through both Bash layers and every repository observation.**

## Performance

- **Duration:** 34 minutes
- **Started:** 2026-09-11T19:54:59Z
- **Completed:** 2026-09-11T20:29:19Z
- **Tasks:** 2
- **Files modified:** 9 implementation and contract files

## Accomplishments

- Replaced unusable asdf-shim authority with physical Mix and Elixir 1.19.5-otp-28 plus Erlang 28.4.1, removed inherited ASDF selectors, and proved normalized Mix/Elixir/OTP output plus a stable probe digest in the exact child environment.
- Passed the loader's captured full authority OID into the finalizer and closeout, rejected missing, malformed, nonexistent, mismatched, or later-moving repository identities, and recorded the expected identity in closeout reports.
- Advanced immutable history to exact paired PLAN/SUMMARY identities 01-39 and added separate authority-closure and proposal-boundary aliases while keeping proposal and installed-host tests out of repository-only CI.
- Preserved every external lifecycle boundary: no proposal, approval, installation, protected-main claim, pre-verification run, terminal report, or completion metadata was produced by implementation work.

## Task Commits

1. **Task 1 RED: Runtime-closure process contracts** — `84c3d264`
2. **Task 1 GREEN: Physical BEAM runtime authentication** — `5b2b4c7a`
3. **Task 2 RED: Authority handoff and movement contracts** — `3b11d164`
4. **Task 2 GREEN: Cross-process OID preservation and lane separation** — `42b5f9c9`

## Files Created/Modified

- `scripts/mailglass_finalize_phase_loader.mjs` — physical runtime identities, exact-child probes, 01-39 manifest, and authority-OID dispatch.
- `scripts/finalize_phase_164.sh` — required authority OID, repeated exact-main checks, pinned Bash closeout invocation, and 01-39 terminal contract.
- `scripts/closeout_repository_truth.sh` — required `--expected-main-sha`, initial/final identity checks, pinned tool calls, and report identity binding.
- `test/scripts/phase_164_closeout_test.exs` — runtime, shell-boundary, movement-race, exact-history, schema, and alias regressions.
- `mix.exs` — named authority/proposal aliases and repository-only external-boundary exclusions.
- `test/support/suite_floor.ex` — deliberate allowlist registration for the proposal exclusion.
- `test/scripts/suite_floor_contract_test.exs` — six-source exclusion contract and directory-lane identity.
- `test/scripts/ci_parity_drift_test.exs` — updated exact repository-only lane scope.
- `test/scripts/scheduled_control_evidence_test.exs` — updated required CI alias contract.

## Decisions Made

- Runtime authority is established from physical, versioned executable files and successful direct probes; `.tool-versions`, shims, inherited PATH entries, and ASDF selector variables do not establish authority.
- Node captures authority once. Bash receives and validates that exact OID; it never substitutes a newly observed equal-looking repository state.
- The proposal and controlled-host selections remain explicit external boundaries. Repository CI proves their exclusion and retains the repository-safe negative fixtures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reconciled the existing CI alias and SuiteFloor contracts with the new proposal boundary**

- **Found during:** Task 2 full repository verification
- **Issue:** Three neighboring contract tests pinned the prior exact alias text, and SuiteFloor correctly reported the newly excluded proposal tag as unknown.
- **Fix:** Updated the exact alias consumers and deliberately registered `phase_164_proposal_boundary` in SuiteFloor's exclusion allowlist.
- **Files modified:** `test/scripts/ci_parity_drift_test.exs`, `test/scripts/scheduled_control_evidence_test.exs`, `test/scripts/suite_floor_contract_test.exs`, `test/support/suite_floor.ex`
- **Verification:** `mix verify.ci_lane_contract` passed 397 tests with 0 failures, 11 intentional exclusions, and 0 SuiteFloor violations.
- **Committed in:** `42b5f9c9`

---

**Total deviations:** 1 auto-fixed blocker. The additional files were existing exact consumers of the planned alias change; no runtime or lifecycle scope was added.

## TDD Gate Compliance

- Task 1 RED failed on the missing runtime-probe export and shim-only tuple; `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- Task 1 GREEN and its tracer feedback gate passed the Phase 164 closeout selection before Task 2 began.
- Task 2 RED failed on absent shell OID validators and the stale 01-34 terminal contract; its evidence record also returned `RED_EVIDENCE_OK`.
- Task 2 GREEN passed the named authority lane and the full repository CI contract after commit. No refactor commit was needed.

## Verification

- Task 1 exact gate: 53 tests, 0 failures, 11 excluded, 0 SuiteFloor violations.
- `mix verify.phase_164.authority_closure`: 4 selected tests, 0 failures, 60 excluded, 0 SuiteFloor violations.
- `mix verify.ci_lane_contract`: 397 tests, 0 failures, 11 excluded, 0 SuiteFloor violations.
- `mix verify.phase_164.proposal_boundary`: 4 selected tests, 0 failures, 60 excluded.
- `node --check scripts/mailglass_finalize_phase_loader.mjs`: passed.
- `bash -n scripts/finalize_phase_164.sh scripts/closeout_repository_truth.sh`: passed.
- `git diff --check`: passed.
- No proposal publication, approval, installation, pre-verification, terminal finalization, CI dispatch/rerun, or release operation ran.

## Issues Encountered

None beyond the auto-fixed exact-consumer contracts documented above.

## User Setup Required

None - no external service configuration was changed.

## Threat Flags

- T-164-133 through T-164-137 are mitigated by the physical runtime probe, sanitized environment, explicit OID handoff, pinned closeout command identities, and deterministic movement regression.
- T-164-109 remains open by design; terminal no-later-write evidence is reserved for Plan 164-39.

## Next Phase Readiness

- Plan 164-36 can integrate the exact 01-39 implementation on protected `main` and capture its attempt-one normal-push CI identity.
- Proposal, approval, installation, ordinary verification, completion metadata, exact-main terminal proof, and T-164-109 closure remain pending their separately authorized Plans 164-36 through 164-39.

## Self-Check: PASSED

- All created and modified files exist, and all four TDD task commits are present after `plan_head_before`.
- Fresh post-commit task and plan verification commands passed with the counts recorded above.
- The worktree contains no uncommitted implementation change; only pre-existing/workflow planning state remains outside this summary commit.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-11*
