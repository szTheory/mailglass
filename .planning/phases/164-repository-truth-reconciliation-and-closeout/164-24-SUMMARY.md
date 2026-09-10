---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 24
subsystem: immutable-finalization-authority
tags: [git, installed-loader, repository-truth, adversarial-regression, lifecycle-records]
requires:
  - phase: 164-23
    provides: approved mode-0500 external loader and immutable installation/rollback tuple
provides:
  - production installed-command proof for moving HEAD, missing history pairs, and hostile retired-extension attacks
  - canonical truth-ledger coverage for the approved external installation artifacts
  - truthful lifecycle records through Plan 164-24 without a terminal-evidence claim
affects: [finalize-phase, repository-truth, TRTH-01, TRTH-02, TRTH-03, phase-164-terminal-proof]
actuals:
  tokens: 16208
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [approval-first installed-command tests, captured-OID private dispatch, portable file-mode assertions]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-24-SUMMARY.md
  modified:
    - test/scripts/phase_164_closeout_test.exs
    - test/scripts/phase_164_repository_truth_test.exs
    - test/mailglass/docs_contract_test.exs
    - scripts/validate_repository_truth.exs
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-VALIDATION.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md
    - dev/toolchain/Dockerfile
    - compose.toolchain.yml
key-decisions:
  - "Installed-boundary tests authenticate the immutable Plan 164-23 approval tuple before every direct subprocess attack and never import the retired checkout extension."
  - "Plan 164-24 records automated production-boundary proof only; ordinary verification, protected-metadata integration, and terminal evidence remain separate later lifecycle events."
patterns-established:
  - "Production authority regressions invoke /Users/jon/.local/bin/mailglass-finalize-phase directly after approval/summary/digest/mode parity checks."
  - "Pinned Linux verification uses portable File.Stat mode checks and explicitly supplies the ESM/archive utilities required by the lifecycle suite."
requirements-completed: [TRTH-01, TRTH-02, TRTH-03]
coverage:
  - id: D1
    description: "The approved installed command accepts one captured private dispatch and rejects moving HEAD plus deleted Plan/Summary pairs 10, 20, and 24 before Bash."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "phase_164_installed_production_boundary: 5 selected, 46 excluded, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "An assume-unchanged executable payload at the retired extension path is never evaluated by direct installed-command dispatch."
    requirement: TRTH-03
    verification:
      - kind: security
        ref: "hostile retired-extension marker subprocess regression"
        status: pass
    human_judgment: false
  - id: D3
    description: "Canonical ledger, current documentation, release-gate, and scheduled-control contracts remain green after installed-authority migration."
    requirement: TRTH-01, TRTH-02
    verification:
      - kind: test
        ref: "pinned Elixir 1.18.4 / OTP 27 focused suite: 120 tests, 0 failures, 1 historical skip"
        status: pass
      - kind: integration
        ref: "scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger .../164-TRUTH-DISPOSITION.tsv"
        status: pass
    human_judgment: false
duration: 21min
completed: 2026-09-10
status: complete
---

# Phase 164 Plan 24: Installed Production Boundary Proof Summary

**The approved external finalizer now has direct subprocess proof against moving HEAD, missing history pairs, and hostile retired-extension mutation, while lifecycle records remain explicitly non-terminal.**

## Performance

- **Duration:** 21 minutes
- **Started:** 2026-09-10T21:17:46Z
- **Completed:** 2026-09-10T21:39:04Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added five approval-first installed-command regressions covering the accepted private-dispatch path, moving HEAD, deleted pairs 10/20/24, hostile retired-extension bytes, and distinct installation/current OIDs.
- Extended the canonical disposition ledger and production validator through the Plan 164-23 summary, external proposal/approval, installed loader, conditional rollback identity, and current roadmap.
- Reconciled validation and finalization records through Plan 164-24 with exact installed OID/digest evidence and an explicit statement that ordinary verification, protected-metadata integration, and terminal finalization remain pending.
- Passed the complete focused suite on the pinned Elixir 1.18.4 / OTP 27 toolchain: 120 tests, 0 failures, 1 historical skip.

## Installed Boundary Evidence

- Installation OID: `7f57e1cd0aafe6d236624da98f7292e86e6de697`
- Installed/source SHA-256: `ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9`
- Installed executable: `/Users/jon/.local/bin/mailglass-finalize-phase`, regular non-symlink mode `0500`
- Approval record: `/Users/jon/.local/share/mailglass/checkpoints/164-23-install-approval.env`, regular non-symlink mode `0400`
- Task 1 targeted run: 5 selected, 46 excluded, 0 failures
- Task 2 pinned focused run: 120 tests, 0 failures, 1 historical skip
- Canonical validator: `repository truth ledger: valid`
- Node and Bash syntax checks plus `git diff --check`: passed

## Task Commits

1. **Task 1 RED: Add failing installed-boundary regressions** — `0fa2f41f`
2. **Task 1 GREEN: Prove installed production boundary** — `ab8bc007`
3. **Task 2: Reconcile automated lifecycle records and canonical truth** — `65b06574`

## Files Created/Modified

- `test/scripts/phase_164_closeout_test.exs` — installed-command attacks, strict approval authority, portable mode checks, and removal of obsolete retired-extension execution tests.
- `test/scripts/phase_164_repository_truth_test.exs` — disposable clones consume the current canonical ledger under test.
- `test/mailglass/docs_contract_test.exs` — manifest-derived version and lifecycle-record contracts.
- `scripts/validate_repository_truth.exs` and `164-TRUTH-DISPOSITION.tsv` — canonical relationships and dispositions for current external installation evidence.
- `164-VALIDATION.md` and `164-FINALIZATION.md` — exact Plan 164-24 results and non-terminal lifecycle status.
- `dev/toolchain/Dockerfile` and `compose.toolchain.yml` — pinned-suite Node/archive support, ESM execution mode, and read-only approved installation inputs.

## Decisions Made

- The test authority is the exact external installed path plus the immutable approval/summary tuple; a test-local source import is not accepted as production proof.
- Historical Task 1 counts remain the observed 5 selected / 46 excluded result, while the post-reconciliation complete suite is recorded separately as 120 tests.
- Terminal finalization was not run or represented as evidence in this plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Added canonical dispositions for approved installation artifacts**
- **Found during:** Task 2 complete validator run
- **Issue:** The canonical artifact derivation now included the Plan 164-23 summary, roadmap, proposal, approval, installed loader, and conditional rollback identity, but the ledger and relationship allowlist stopped at the pre-installation set.
- **Fix:** Added stable ledger rows and exact canonical relationship hashes, including fail-closed external-current semantics.
- **Files modified:** `164-TRUTH-DISPOSITION.tsv`, `scripts/validate_repository_truth.exs`, `test/scripts/phase_164_repository_truth_test.exs`
- **Commit:** `65b06574`

**2. [Rule 3 - Blocking Issue] Completed the pinned toolchain's lifecycle-test dependencies**
- **Found during:** Task 2 pinned verification
- **Issue:** The image lacked Node and zip/unzip support and could not see the separately protected installed executable and approval record; Debian Node 18 also treated extensionless ESM as CommonJS.
- **Fix:** Added the required utilities, ESM default type, and read-only exact external file mounts.
- **Files modified:** `dev/toolchain/Dockerfile`, `compose.toolchain.yml`
- **Commit:** `65b06574`

**3. [Rule 1 - Bug] Removed obsolete execution tests for the retired project extension**
- **Found during:** Task 2 complete suite
- **Issue:** Eleven tests still attempted to invoke `.gsd/extensions/finalize-phase`, which Plan 164-22 deliberately removed from production authority.
- **Fix:** Removed only the retired-extension dispatcher/transitive execution cases and their now-unused helpers; retained the hostile-extension non-evaluation attack against the installed command.
- **Files modified:** `test/scripts/phase_164_closeout_test.exs`
- **Commit:** `65b06574`

**4. [Rule 1 - Bug] Made file-mode verification portable across macOS and Linux**
- **Found during:** Task 2 pinned verification
- **Issue:** BSD `stat -f %Lp` assertions failed in the Linux gating container.
- **Fix:** Asserted permission bits through `File.Stat.mode` and `Bitwise.band/2`.
- **Files modified:** `test/scripts/phase_164_closeout_test.exs`
- **Commit:** `65b06574`

## TDD Gate Compliance

- RED commit `0fa2f41f` established five failing installed-boundary tests before helper implementation.
- GREEN commit `ab8bc007` implemented the approval-first production fixture and passed all five attacks.
- No refactor-only commit was required.

## Known Stubs

None.

## Issues Encountered

The pinned toolchain initially surfaced missing runtime utilities, Linux-incompatible mode checks, and stale tests for the retired extension authority. All were corrected within Task 2 and the exact verification command subsequently passed.

## User Setup Required

None. Plan 164-23's approved external installation remains unchanged.

## Next Phase Readiness

- Automated installed-boundary proof and current lifecycle records are complete through Plan 164-24.
- Ordinary verification, protected metadata integration, and the final installed terminal run remain intentionally pending; this summary is not terminal closeout evidence.

## Self-Check: PASSED

- All four planned primary artifacts exist.
- Task commits `0fa2f41f`, `ab8bc007`, and `65b06574` exist in Git history.
- The pinned complete suite, canonical validator, loader syntax, shell syntax, and diff checks passed after the final changes.
- No goal-blocking stubs or unrun verification commands remain.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-10*
