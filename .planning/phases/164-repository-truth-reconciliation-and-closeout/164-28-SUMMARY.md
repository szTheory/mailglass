---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 28
subsystem: repository-truth-closeout
tags: [repository-truth, security, lifecycle, installed-loader, terminal-boundary]
requires:
  - phase: 164-27
    provides: hardened installed loader with canonical repository, trusted toolchain, ancestry, and exact 01-28 authority
provides:
  - reconciled validation and security evidence for all Plan 164-25 through 164-27 repairs
  - exact PLAN/SUMMARY pair-set contract for 01 through 28
  - contract-checked post-summary verifier, protected-metadata, CI, schedule, and no-later-write order
affects: [phase-164-verification, phase-164-terminal-proof, TRTH-01, TRTH-02, TRTH-03]
actuals:
  tokens: 13667
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [named production-seam reconciliation, exact lifecycle ordering, distinct repository and controlled-host verification lanes]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-28-SUMMARY.md
  modified:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-VALIDATION.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-SECURITY.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv
    - scripts/validate_repository_truth.exs
    - test/mailglass/docs_contract_test.exs
    - config/test_exceptions.exs
key-decisions:
  - "Plans 164-25 through 164-27 close the four implementation findings, while T-164-109 and terminal protected-main evidence remain explicitly pending until the post-execution lifecycle runs."
  - "The only authorized terminal history is exactly one PLAN and SUMMARY for every number 01 through 28; no historical subset is accepted."
  - "Plan 164-28 stops after summary readiness: ordinary verification, completion-only metadata integration, protected-main CI and schedules, and the terminal command remain later ordered boundaries."
patterns-established:
  - "Durable closure claims cite a named active regression, observed non-vacuous count, production seam, and failure direction."
  - "Repository-only CI and controlled-host installed-command proof execute as distinct explicit lanes."
requirements-completed: [TRTH-01, TRTH-02, TRTH-03]
coverage:
  - id: D1
    description: "Validation and security records map every repaired finding to its production seam, active regression, observed result, and threat disposition."
    requirement: TRTH-01, TRTH-02, TRTH-03
    verification:
      - kind: integration
        ref: "phase_164_gap_reconciliation (3 selected, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Loader, shell, validation, and finalization records agree on the exact 01-28 PLAN/SUMMARY pair set and preserve terminal no-later-write ordering."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "phase_164_lifecycle_contract (3 selected, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The focused Phase 164 suite, repository-only required lane, installed boundary, canonical ledger, and syntax checks pass under their intended authorities."
    requirement: TRTH-01, TRTH-02, TRTH-03
    verification:
      - kind: integration
        ref: "focused suite (135 tests, 0 failures, 1 historical skip)"
        status: pass
      - kind: integration
        ref: "verify.ci_lane_contract (380 selected, 0 failures, 5 controlled-host exclusions)"
        status: pass
      - kind: integration
        ref: "verify.phase_164.installed_boundary (5 selected, 0 failures)"
        status: pass
    human_judgment: false
duration: 22min
completed: 2026-09-10
status: complete
---

# Phase 164 Plan 28: Repository Truth Reconciliation and Closeout Summary

**Repaired CI, repository authority, trusted-tool, ancestry, and installation findings are reconciled into active proof records, with the exact 01-28 post-summary terminal lifecycle locked without executing it.**

## Performance

- **Duration:** 22 minutes
- **Started:** 2026-09-11T01:12:14Z
- **Completed:** 2026-09-11T01:34:00Z
- **Tasks:** 2
- **Files modified:** 9 tracked files, including this summary and the resolved broken-windows entry

## Accomplishments

- Replaced stale security closure language with a superseding assessment for CR-01, CR-02, CR-03, and WR-01, while leaving T-164-109 open until real terminal protected-main evidence exists.
- Added exact ledger coverage for the Plan 164-25 CI-alias subjects and bound their canonical digests in the production repository-truth validator.
- Added active documentation contracts for gap reconciliation and the exact 01-28 lifecycle, including negative controls against shortened history and accidental finalization during plan verification.
- Locked the order summary → ordinary verifier → four completion-metadata paths → protected main → attempt-1 push CI and natural schedules → ignored terminal capture → no later tracked write.

## Task Commits

1. **Task 1 RED: Add failing gap reconciliation contracts** — `02d379c5`
2. **Task 1 GREEN: Reconcile repaired gap evidence** — `892b0729`
3. **Task 2 RED: Add failing lifecycle ordering contracts** — `78005f65`
4. **Task 2 GREEN: Lock exact terminal lifecycle** — `65749043`
5. **Post-summary Rule 3 fix: Register activated Plan 28 security evidence** — `8bcf41b7`

## Decisions Made

- Treat controlled-host installation tests as readiness evidence only; they do not substitute for ordinary verification or the later terminal capture.
- Keep the phase security status pending-terminal until protected completion metadata, exact CI, and natural scheduled evidence authorize the installed command.
- Keep terminal finalization outside plan execution and do not run either finalization mode in Plan 164-28.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added missing Plan 164-25 ledger subjects**

- **Found during:** Task 1 complete-suite verification
- **Issue:** The canonical validator rejected `mix.exs` and `test/scripts/ci_parity_drift_test.exs` because the completed-plan inventory had no exact disposition rows.
- **Fix:** Added M-31/M-32 with canonical digests and extended the validator's tracked-evidence profile.
- **Files modified:** `164-TRUTH-DISPOSITION.tsv`, `scripts/validate_repository_truth.exs`
- **Commit:** `892b0729`

**2. [Rule 1 - Bug] Realigned the historical skip source pointer**

- **Found during:** Tasks 1 and 2 repository-lane verification
- **Issue:** New documentation contracts moved the one registered historical skip while `config/test_exceptions.exs` retained its old source line.
- **Fix:** Updated the exact source pointer to line 680 after all tests were added.
- **Files modified:** `config/test_exceptions.exs`
- **Commits:** `892b0729`, `65749043`

**3. [Rule 3 - Blocking] Split the incompatible literal container verification by authority**

- **Found during:** Task 2 complete verification
- **Issue:** The plan's unfiltered `make toolchain` suite attempted controlled-host tests inside the repository-only Linux container, which lacks the approved absolute Node and gh identities by design.
- **Fix:** Ran the complete focused suite locally under pinned Elixir/OTP, the repository-only CI alias with its controlled-host exclusion, and the installed-boundary alias explicitly on the controlled host. All three passed. WINDOWS entry 32 records the corrected split as fixed.
- **Files modified:** `.planning/WINDOWS.md`
- **Commit:** summary metadata commit

**4. [Rule 3 - Blocking] Registered the completed Plan 28 security record**

- **Found during:** Final committed-tree verification after the summary activated Plan 28 in completed-plan discovery
- **Issue:** The canonical validator correctly required `164-SECURITY.md`, but no exact ledger relationship existed yet.
- **Fix:** Added M-33 and bound its canonical completed-plan relationship digest in the production validator.
- **Files modified:** `164-TRUTH-DISPOSITION.tsv`, `scripts/validate_repository_truth.exs`
- **Commit:** `8bcf41b7`

## Verification

- Gap reconciliation contract: 3 selected, 0 failures.
- Lifecycle ordering contract: 3 selected, 0 failures.
- Complete focused Phase 164 suite: 135 tests, 0 failures, 1 pre-existing registered historical skip.
- Repository-only required lane: 380 selected, 0 failures, 5 controlled-host exclusions.
- Controlled-host installed boundary: 5 selected, 0 failures, 44 excluded.
- Canonical repository-truth validator: valid.
- Loader Node syntax, both shell syntax checks, and `git diff --check`: passed.
- Canonical pre-verification and terminal finalization were not invoked.

## Known Stubs

None. This plan introduced no stubs, TODOs, FIXMEs, or skipped tests. The single focused-suite skip is an existing registered compatibility fixture.

## Threat Flags

None. Changes reconcile existing trust boundaries and add fail-closed documentation contracts; they introduce no endpoint, authentication, file-access, schema, or dependency surface.

## Next Phase Readiness

- `164-28-SUMMARY.md` now exists before ordinary verification, satisfying the first terminal-order prerequisite.
- The ordinary verifier must next evaluate the tracked implementation and record `status: passed` plus its exact implementation SHA.
- Terminal finalization remains pending and must run only after completion-only metadata reaches protected `main` and exact attempt-1 CI plus natural scheduled evidence exist.

## Self-Check: PASSED

- Task commits `02d379c5`, `892b0729`, `78005f65`, `65749043`, and `8bcf41b7` exist.
- All created and modified plan files exist.
- All non-terminal acceptance checks passed under their intended repository or controlled-host authority.
- No terminal report was produced or claimed.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-10*
