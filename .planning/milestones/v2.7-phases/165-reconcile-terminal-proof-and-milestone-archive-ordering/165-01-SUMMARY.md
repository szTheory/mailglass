---
phase: 165-reconcile-terminal-proof-and-milestone-archive-ordering
plan: 01
subsystem: release-authority
tags: [git, milestone-archive, fail-closed, exunit, tdd]
requires:
  - phase: 164-repository-truth-reconciliation-and-closeout
    provides: immutable historical phase-finalization authority
provides:
  - authenticated v2.7 archived-milestone staging and terminal finalizer
  - separate repository and installed-boundary verification lanes
  - hostile authority fixtures for stale, moving, selected, and leaked evidence
affects: [165-02-installed-terminal-boundary, v2.7-milestone-archive]
actuals:
  tokens: 16211
  tasks: 2
  commits: 4
plan_head_before: 15176a04ed297123c51802eb5c00c9f28c9ca8a7
tech-stack:
  added: []
  patterns: [authenticated-git-manifest, staged-runtime-closure, late-authority-recheck, tdd]
key-files:
  created:
    - scripts/mailglass_finalize_milestone_loader.mjs
    - scripts/finalize_milestone_v2_7.sh
    - test/scripts/phase_165_milestone_finalizer_test.exs
  modified:
    - mix.exs
    - test/test_helper.exs
    - test/support/suite_floor.ex
key-decisions:
  - "Phase 165 terminal authority uses a separately staged v2.7 loader/finalizer and leaves the Phase 164 pair byte-identical."
  - "Installed-host proof remains opt-in and excluded from repository CI; repository fixtures authenticate and execute staged bytes only."
patterns-established:
  - "Terminal reports are written only after archived manifest, exact-run evidence, HEAD, and cleanliness authority checks, then followed by late rechecks."
  - "Installation proposals describe exact create or safe-predecessor backup/rollback tuples without mutating the canonical destination."
requirements-completed: []
coverage:
  - id: D1
    description: "A disposable repository traverses exact v2.7 archive authentication, staging, evidence selection, and ignored terminal reporting."
    verification:
      - kind: integration
        ref: "mix verify.phase_165.repository"
        status: pass
    human_judgment: false
  - id: D2
    description: "Repository CI and installed-host proof are separate, explicitly named lanes with the installed tag excluded by default."
    verification:
      - kind: integration
        ref: "mix verify.ci_lane_contract"
        status: pass
    human_judgment: false
  - id: D3
    description: "Hostile fixtures reject stale audits, incomplete or mixed archives, dirty or moving HEAD, caller-selected evidence, tracked reports, unsafe predecessors, and installed-byte drift."
    verification:
      - kind: integration
        ref: "test/scripts/phase_165_milestone_finalizer_test.exs"
        status: pass
    human_judgment: false
metrics:
  duration: 61m
  completed_date: 2026-09-13
duration: 61m
completed: 2026-09-13
status: complete
---

# Phase 165 Plan 01: Reconcile Terminal Proof and Milestone Archive Ordering Summary

**Authenticated v2.7 archive staging and fail-closed terminal reporting now run through separate repository and installed-host proof lanes without changing Phase 164 authority.**

## Performance

- **Duration:** 61m
- **Started:** 2026-09-13T15:24:52Z
- **Completed:** 2026-09-13T16:26:17Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added a pinned Node loader that authenticates one committed Git snapshot, builds a closed archived manifest, stages runtime bytes with fixed modes, and emits non-mutating installation proposals.
- Added a fail-closed v2.7 shell finalizer that selects exact attempt-1 CI and natural schedule evidence, writes ignored terminal reports, and rechecks HEAD and cleanliness after reporting.
- Added happy-path and hostile disposable-repository fixtures plus distinct repository and installed-boundary Mix aliases, with default and SuiteFloor exclusions kept explicit.

## Task Commits

1. **Task 1 RED: milestone authority lane contract** - `472f4cf4` (test)
2. **Task 1 GREEN: archived milestone authority tracer** - `17f24b2b` (feat)
3. **Task 2 RED: stale-audit authority contract** - `f984643c` (test)
4. **Task 2 GREEN: fail-closed hostile evidence matrix** - `cc2b25c9` (feat)

## Files Created/Modified

- `scripts/mailglass_finalize_milestone_loader.mjs` - Authenticates repository/archive bytes, selects evidence, stages the runtime closure, and creates exact installation proposals.
- `scripts/finalize_milestone_v2_7.sh` - Enforces v2.7 archive and evidence authority before and after terminal report creation.
- `test/scripts/phase_165_milestone_finalizer_test.exs` - Exercises the happy tracer and hostile mutation/evidence/predecessor matrix in disposable Git repositories.
- `mix.exs` and `test/test_helper.exs` - Define separate Phase 165 verification lanes and exclude installed-host proof from ordinary selection.
- `test/scripts/ci_parity_drift_test.exs`, `test/scripts/suite_floor_contract_test.exs`, `test/scripts/scheduled_control_evidence_test.exs`, `test/scripts/phase_164_closeout_test.exs`, and `test/support/suite_floor.ex` - Accept the new required installed-boundary exclusion while preserving prior CI authority semantics.

## Decisions Made

- Kept the historical Phase 164 loader/finalizer immutable; Phase 165 owns a new milestone-specific authority pair.
- Kept installation as a proposal-only boundary. The loader records exact predecessor kind, mode, digest, owner, backup, and rollback data but does not install anything.
- Required post-report HEAD and cleanliness checks so a late mutation converts the report to blocked instead of leaving a stale pass artifact.

## TDD Gate Compliance

- Task 1 RED failed because the Phase 165 verification alias and tracer implementation did not exist; `gsd-tools check tdd-red-evidence` accepted the persisted failure evidence.
- Task 1 GREEN passed 3 tracer tests plus shell syntax and formatting, then passed the tracer feedback gate a second time.
- Task 2 RED failed because stale audit evidence was initially accepted; `gsd-tools check tdd-red-evidence` accepted the persisted failure evidence.
- Task 2 GREEN passed all 12 repository tests and the complete 426-test CI lane contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking verification] Extended existing exclusion compatibility contracts for Phase 165**
- **Found during:** Task 2 full CI verification
- **Issue:** Five existing contracts and SuiteFloor's known-tag allowlist encoded the former Phase 164-only installed-boundary exclusion, causing the required lane to reject the new Phase 165 exclusion.
- **Fix:** Updated only those compatibility assertions and the allowlist to recognize `phase_165_installed_production_boundary` while retaining every existing Phase 164 exclusion and lane boundary.
- **Files modified:** `test/scripts/ci_parity_drift_test.exs`, `test/scripts/suite_floor_contract_test.exs`, `test/scripts/scheduled_control_evidence_test.exs`, `test/scripts/phase_164_closeout_test.exs`, `test/support/suite_floor.ex`
- **Verification:** Compatibility subset passed 54 tests with zero SuiteFloor violations; full required lane passed 426 tests with zero failures and zero violations.
- **Committed in:** `cc2b25c9`

**Total deviations:** 1 auto-fixed (Rule 3). **Impact:** Required compatibility maintenance only; no release-authority scope was broadened.

## Issues Encountered

- The first full CI run identified the five stale compatibility assertions above. After the minimal compatibility update, the same lane passed completely.

## Test Evidence

- `mix test test/scripts/phase_165_milestone_finalizer_test.exs --exclude phase_165_installed_production_boundary --warnings-as-errors --no-deps-check` - passed (12 tests, 0 failures, 1 excluded).
- `mix verify.phase_165.repository` - passed (12 tests, 0 failures, 1 excluded).
- `mix verify.ci_lane_contract` - passed (426 tests, 0 failures, 12 excluded; zero SuiteFloor violations).
- `bash -n scripts/finalize_milestone_v2_7.sh` - passed.
- `git diff --check HEAD --` - passed.
- Phase 164 loader/finalizer Git blob hashes remained `1c1c299c...` and `20a0ad73...` respectively.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The repository-local terminal authority and hostile evidence matrix are ready for the installed-host boundary plan.
- No blockers remain.

## Self-Check: PASSED

- All three Phase 165 implementation/test artifacts exist at their recorded paths.
- TDD commits `472f4cf4`, `17f24b2b`, `f984643c`, and `cc2b25c9` exist in Git history.
- The measured ledger base is `15176a04ed297123c51802eb5c00c9f28c9ca8a7` with four task commits through Task 2.

---
*Phase: 165-reconcile-terminal-proof-and-milestone-archive-ordering*
*Completed: 2026-09-13*
