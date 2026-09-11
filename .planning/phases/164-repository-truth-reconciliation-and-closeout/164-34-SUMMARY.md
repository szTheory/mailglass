---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 34
subsystem: repository-truth-closeout
tags: [evidence-reconciliation, repository-truth, lifecycle, security, tdd]
status: complete
requires:
  - phase: 164-29
    provides: real installed-command proof and hermetic repository suites
  - phase: 164-30
    provides: bounded incomplete-authority diagnostics
  - phase: 164-33
    provides: approved active 01-34 installed-loader tuple
provides:
  - observed Plan 164-29/30/33 evidence bound to named production seams
  - exact-one repair-plan ledger inventory with current canonical relationships
  - exact 01-34 post-summary lifecycle handoff with T-164-109 pending
affects: [phase-164-ordinary-verification, protected-completion-metadata, terminal-finalization]
tech-stack:
  added: []
  patterns:
    - separate repository-only CI from controlled-host installation readiness
    - canonical NUL-delimited ledger relationship digests
    - bounded tagged authority-root diagnostics
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-34-SUMMARY.md
  modified:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-VALIDATION.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-SECURITY.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv
    - scripts/validate_repository_truth.exs
    - test/mailglass/docs_contract_test.exs
    - test/scripts/phase_164_repository_truth_test.exs
    - config/test_exceptions.exs
key-decisions:
  - "Observed implementation evidence remains distinct from ordinary verification, protected completion metadata, and terminal capture."
  - "Plan 164-27 remains immutable prior provenance; the active installation is only the exact Plan 164-32 approval tuple proven by Plan 164-33."
  - "Plan 164-34 reaches execute-plan readiness without marking TRTH-01/02/03 or Phase 164 complete."
requirements-completed: []
duration: 25m
completed: 2026-09-11
actuals:
  tokens: 17996
  tasks: 2
  commits: 5
plan_head_before: 2e982d6d732d9951e4ac467b93ff6888988317b6
---

# Phase 164 Plan 34: Repair Evidence and Ledger Reconciliation Summary

**Durable closeout records now report the real 01-34 installed authority, bounded repository-truth behavior, and hermetic repository CI while preserving the terminal no-later-write boundary as pending.**

## Performance

- **Duration:** 25 minutes
- **Started:** 2026-09-11T04:45:12Z
- **Completed:** 2026-09-11T05:09:47Z
- **Tasks:** 2
- **Files modified:** 8 implementation/evidence files

## Accomplishments

- Replaced stale fixture/raising-path closure prose with fresh production-seam results: 7 controlled-host tests passed with 54 excluded, 3 incomplete-authority tests passed with 25 excluded, and the final repository-only lane passed 398 tests with exactly 7 host tests excluded.
- Reconciled the exact PLAN/SUMMARY history to 01-34 and established that `164-34-SUMMARY.md` precedes ordinary verification, completion-only metadata, protected-main integration, attempt-1 exact-main remote evidence, and terminal ignored capture.
- Bound every tracked subject modified by Plans 164-29 through 164-34 to exactly one current retained ledger row, refreshed its approved evidence reference, and updated canonical relationship digests.
- Preserved T-164-109 as the sole high-severity open lifecycle threat. No finalization mode, requirement completion, phase completion, CI dispatch/rerun, release, or publication occurred.

## Task Commits

1. **Task 1 RED: Reconciliation record contracts** — `14eae3b7`
2. **Task 1 GREEN: Repair evidence and lifecycle records** — `ca469656`
3. **Task 2 RED: Repair-plan ledger contract** — `6ed603fa`
4. **Task 2 GREEN: Exact-one ledger authority and canonical relationships** — `22b901fd`
5. **Verification repair: Preserve the exhaustive-lane exception registry** — `6a9b1c77`

## Files Created/Modified

- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-VALIDATION.md` — current Plan 164-29/30/33 commands, counts, failure directions, and ordinary-verification handoff.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-SECURITY.md` — T-164-110 through T-164-132 dispositions with T-164-109 still open.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md` — active Plan 164-32/33 tuple, Plan 164-27 prior provenance, exact 01-34 history, and unchanged terminal ordering.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` — refreshed Plan 164-29 through 164-34 evidence references without duplicate subjects or disposition changes.
- `scripts/validate_repository_truth.exs` — approved evidence vocabulary and canonical relationship hashes for the reconciled rows.
- `test/mailglass/docs_contract_test.exs` — TDD contracts for current evidence, threat coverage, exact history, and the no-later-write lifecycle.
- `test/scripts/phase_164_repository_truth_test.exs` — exact-one repair-plan inventory plus missing, duplicate, and stale-canonical negative controls.
- `config/test_exceptions.exs` — moved intentional-skip source location after the documentation contract expanded.

## Decisions Made

- The active controlled-host installation is source OID `1cfee7802de808f690fe5413b22a57e7ab802488`, SHA-256 `f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac`, and mode 0500. The exact Plan 164-27 OID/digest and rollback remain prior provenance only.
- The repository-only alias and controlled-host alias remain separate authorities: one proves host-independent exhaustive collection, the other proves the real approval/install tuple.
- Ledger evidence was updated in place for the 13 repair-plan subjects. The existing `test/test_helper.exs` M-34 row remains singular; no second row was added.
- Execute-plan readiness does not authorize ordinary verification output, protected completion metadata, requirement completion, phase completion, or terminal evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the Plan 164-34 lifecycle assertion scope**

- **Found during:** Task 1 GREEN verification
- **Issue:** The new test looked for phase-wide alias requirements only inside task-level `<automated>` elements, although the plan places that requirement in its overall verification block.
- **Fix:** Asserted the plan-wide `both distinct repository/controlled-host aliases` contract while retaining exact task-command and no-finalization checks.
- **Files modified:** `test/mailglass/docs_contract_test.exs`
- **Commit:** `ca469656`

**2. [Rule 1 - Bug] Advanced the intentional-skip registry after test-line movement**

- **Found during:** Plan-level `mix verify.ci_lane_contract`
- **Issue:** New documentation assertions moved an existing intentional skip from line 680 to 704, so the bidirectional exception registry correctly failed on the stale location.
- **Fix:** Updated the single registry source location and recorded the final post-expansion 398-test result.
- **Files modified:** `config/test_exceptions.exs`, `test/mailglass/docs_contract_test.exs`, `164-VALIDATION.md`, `164-SECURITY.md`
- **Commit:** `6a9b1c77`

---

**Total deviations:** 2 auto-fixed bugs. Both were directly caused by this plan's test changes; neither changed lifecycle authority or terminal scope.

## TDD Gate Compliance

- Task 1 RED failed on the intended missing `Plans 164-29 through 164-34` record assertion; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- Task 1 GREEN passed both non-vacuous documentation groups (3 selected each) before commit and again at the tracer feedback gate.
- Task 2 RED failed on the intended stale finalization evidence reference; the evidence checker again returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- Task 2 GREEN passed 30 repository-truth tests and the standalone canonical validator. No separate refactor was needed.

## Verification

- `phase_164_gap_reconciliation`: 3 selected, 0 failures, 43 excluded.
- `phase_164_lifecycle_contract`: 3 selected, 0 failures, 43 excluded.
- Full `phase_164_repository_truth_test.exs`: 30 tests, 0 failures.
- Standalone canonical validator: `repository truth ledger: valid`.
- `mix verify.phase_164.installed_boundary`: 7 selected, 0 failures, 54 excluded.
- `mix verify.ci_lane_contract`: 398 selected, 0 failures, 7 excluded.
- `git diff --check`: passed.
- No pre-verification or terminal finalization mode ran.

## Known Stubs

None.

## Threat Flags

None. The authority-root reads, installed executable, approval/rollback objects, and terminal lifecycle are pre-existing planned trust boundaries covered by T-164-109 through T-164-132; this plan introduced no new endpoint, schema, package, or file-access authority.

## Next Phase Readiness

- Plan 164-34 execution records are ready for ordinary Phase 164 verification.
- TRTH-01, TRTH-02, TRTH-03, phase completion, protected-main remote evidence, and terminal capture remain pending for their separately authorized lifecycle steps.

## Self-Check: PASSED

- All created and modified files exist.
- All five task/deviation commits are present.
- Canonical repository-truth validation remains valid with `164-34-SUMMARY.md` present.
