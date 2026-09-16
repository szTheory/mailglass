---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 36
subsystem: repository-truth-closeout
tags: [protected-main, github-actions, ci-provenance, authority-chain, squash-merge]
status: complete
requires:
  - phase: 164-35
    provides: executable authority-chain repair and exact 01-39 repository contract
provides:
  - exact protected-main identity for the integrated authority-chain repair
  - independently validated successful attempt-one normal push CI identity
  - bounded main SHA and CI run handoff for the replacement proposal
affects: [phase-164-37-proposal-approval, phase-164-38-installation, phase-164-39-final-reconciliation]
actuals:
  tokens: 2961
  tasks: 1
  commits: 5
tech-stack:
  added: []
  patterns:
    - select protected CI by exact SHA and identity fields rather than run ordering
    - preserve divergent local history before recreating a canonical tracking branch
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-36-SUMMARY.md
  modified:
    - test/scripts/phase_164_closeout_test.exs
    - test/mailglass/docs_contract_test.exs
key-decisions:
  - "Protected integration used an immediate squash merge only after every PR check passed; no auto-merge, direct main push, protection bypass, workflow dispatch, or rerun occurred."
  - "The admissible CI authority is run 34650810638: workflow CI, event push, attempt one, branch main, exact head 52c07a5051d269b307831a2210f53dec0dd1ff65, completed successfully."
  - "Hosted tool permissions are normalized only inside disposable test fixtures through fixture-owned wrappers; production trusted paths and ownership checks remain strict."
patterns-established:
  - "Exact-main handoff: fetched origin/main, local main HEAD, and CI head SHA must be the same full OID, with two consecutive clean porcelain reads."
  - "Normal-CI identity: require workflow, event, attempt, branch, head SHA, status, conclusion, and numeric database ID to agree independently."
requirements-completed: [TRTH-03]
coverage:
  - id: D1
    description: "The complete authority-chain repair and Plan 164-35 summary are integrated through the normal protected-main workflow."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "GitHub PR #249 squash merge 52c07a5051d269b307831a2210f53dec0dd1ff65"
        status: pass
    human_judgment: false
  - id: D2
    description: "The exact integrated main SHA has a successful normally triggered attempt-one push CI run with every identity field in agreement."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "GitHub Actions CI run 34650810638"
        status: pass
    human_judgment: false
duration: 1h 35m
completed: 2026-09-11
main_sha: 52c07a5051d269b307831a2210f53dec0dd1ff65
ci_run_id: 34650810638
---

# Phase 164 Plan 36: Protected Integration and Exact CI Attestation Summary

**The executable authority repair is on protected `main`, bound to one independently validated successful attempt-one normal push CI run.**

## Performance

- **Duration:** 1 hour 35 minutes
- **Started:** 2026-09-11T20:31:26Z
- **Completed:** 2026-09-11T22:05:48Z
- **Tasks:** 1
- **Files modified:** 2 test-contract files before protected integration

## Accomplishments

- Integrated the complete Plan 164-35 repair and summary through PR #249 using the repository's normal protected squash-merge workflow.
- Reconciled static-analysis, transitional-history, and hosted-tool portability failures found by PR CI without weakening production trust checks.
- Established `main_sha=52c07a5051d269b307831a2210f53dec0dd1ff65 ci_run_id=34650810638` from a clean canonical checkout and independent GitHub run metadata.
- Preserved lifecycle ordering: no proposal, approval, installed replacement, rollback object, finalization mode, schedule operation, completion metadata, or terminal evidence was produced.

## Task Commits

1. **Static-analysis repair:** `4bc18acc`
2. **Transitional-history contract repair:** `54529c72`
3. **Cross-host executable discovery repair:** `dd383681`
4. **Fixture-owned trusted-tool wrapper repair:** `2c47a604`
5. **Protected squash integration:** `52c07a50`

## Files Created/Modified

- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-36-SUMMARY.md` — exact protected-main and attempt-one push-CI handoff.
- `test/scripts/phase_164_closeout_test.exs` — lower-complexity parsing helpers plus portable, safely owned disposable trusted-tool wrappers.
- `test/mailglass/docs_contract_test.exs` — transitional contract distinguishing tracked 01-39 authority from the still-installed 01-34 predecessor.

## Decisions Made

- The explicit maintainer authorization selected a synchronous squash merge after all required checks were green; GitHub protection remained authoritative throughout.
- The push run was selected by exact SHA and independently checked fields, not by timestamp or list position.
- The diverged local `main` history was retained under `main-pre-164-36-squash`; pre-existing planning edits were retained in the named `preserve pre-164-36 planning edits` stash before reconstructing canonical `main`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reduced approval parser complexity required by Credo Strict**

- **Found during:** Initial PR CI
- **Issue:** The new approval parser exceeded the repository's nesting and cyclomatic-complexity ratchet.
- **Fix:** Split line parsing and key validation into focused helpers without changing accepted bytes or failure behavior.
- **Files modified:** `test/scripts/phase_164_closeout_test.exs`
- **Verification:** Credo Strict and the static-analysis exception ledger passed locally and on GitHub.
- **Committed in:** `4bc18acc`

**2. [Rule 3 - Blocking] Reconciled transitional history expectations**

- **Found during:** PR Support Contract Core
- **Issue:** The documentation contract still asserted tracked terminal range 01-34 even though Plan 164-35 deliberately advanced tracked source to 01-39 while installed authority remains 01-34 until Plan 164-38.
- **Fix:** Asserted the two ordered truths separately.
- **Files modified:** `test/mailglass/docs_contract_test.exs`
- **Verification:** Lifecycle and support-contract suites passed locally and on GitHub.
- **Committed in:** `54529c72`

**3. [Rule 3 - Blocking] Made disposable authority fixtures portable across CI hosts**

- **Found during:** PR Mix Task Tests
- **Issue:** Copied fixture loaders retained macOS-only executable paths; direct hosted-tool paths then failed the production-safe ownership/mode checks on GitHub runners.
- **Fix:** Rewrote only disposable fixture identities to current-host tools through fixture-owned regular executable wrappers with safe ownership and mode. Production path assertions remain exact.
- **Files modified:** `test/scripts/phase_164_closeout_test.exs`
- **Verification:** `mix verify.phase_164.authority_closure` passed 4 tests; `mix verify.ci_lane_contract` passed 397 tests; PR and protected-main Mix Task Tests passed.
- **Committed in:** `dd383681`, `2c47a604`

---

**Total deviations:** 3 auto-fixed blockers. Every change was required to make the planned authority contract reproducible under the repository's actual protected CI environment; no lifecycle authority was broadened.

## Verification

- Local `mix verify.phase_164.authority_closure`: 4 tests, 0 failures, 60 excluded, 0 SuiteFloor violations.
- Local `mix verify.ci_lane_contract`: 397 tests, 0 failures, 11 excluded, 0 SuiteFloor violations.
- Local focused Credo Strict: 1 file, 43 functions, no issues.
- Local static-analysis ledger check: current, owned, expiring, and non-growing.
- PR run `34649479739` for head `2c47a604428cf4787e7ee1f09ae74a42cba79246`: completed successfully; every reported check passed except one intentionally skipped advisory matrix entry.
- Canonical branch: `main`.
- Canonical HEAD: `52c07a5051d269b307831a2210f53dec0dd1ff65`.
- Fetched `refs/remotes/origin/main`: `52c07a5051d269b307831a2210f53dec0dd1ff65`.
- Two consecutive `git status --porcelain=v1` reads: empty.
- Push CI database ID: `34650810638`.
- Push CI fields: workflow `CI`, event `push`, attempt `1`, branch `main`, head SHA `52c07a5051d269b307831a2210f53dec0dd1ff65`, status `completed`, conclusion `success`.
- No workflow dispatch or rerun was used.

## Issues Encountered

- GitHub queued the final `CI Green` aggregate briefly after all substantive jobs passed; it later ran normally and succeeded without intervention.
- Local `main` contained the pre-squash feature history and could not fast-forward to the single squash commit. The history was preserved under `main-pre-164-36-squash`, then local `main` was recreated as a clean tracking branch at `origin/main`.

## User Setup Required

None - protected integration and CI attestation are complete.

## Next Phase Readiness

- Plan 164-37 may consume only `main_sha=52c07a5051d269b307831a2210f53dec0dd1ff65 ci_run_id=34650810638` as its protected-source handoff.
- The replacement proposal and exact human approval remain pending Plan 164-37.
- Installation, rollback creation, installed-boundary verification, finalization, completion metadata, and terminal no-later-write evidence remain pending their separately ordered plans.

## Self-Check: PASSED

- PR #249 is merged and the fetched protected-main SHA contains the complete repair.
- Local `main`, `origin/main`, and the exact push run head SHA agree byte-for-byte.
- The run is the successful attempt-one normal `CI` push event for branch `main`.
- The checkout was observed clean twice before writing this summary.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-11*
