---
phase: 164-repository-truth-reconciliation-and-closeout
plan: "06"
subsystem: repository-closeout
tags: [protected-main, ci, scheduled-controls, evidence, checkpoint]
requires:
  - phase: 164-02
    provides: authority-correct protected release and recovery documentation
  - phase: 164-03
    provides: manifest-derived current package compatibility guidance
  - phase: 164-05
    provides: read-only exact-main closeout command and durable usage contract
provides:
  - immutable protected-main SHA and normal CI run identity for Plan 164-07
  - approved current scheduled-control evidence for that exact protected-main identity
affects: [164-07, repository-closeout, protected-ci, scheduled-controls]
tech-stack:
  added: []
  patterns: [exact-SHA handoff, normal-event CI provenance, scheduled-proof-without-manual-substitution]
key-files:
  created: [.planning/phases/164-repository-truth-reconciliation-and-closeout/164-06-SUMMARY.md]
  modified: []
key-decisions:
  - "Plan 164-07 must re-query the supplied SHA and run ID rather than trusting this handoff alone."
  - "The approved scheduled evidence remains normal scheduled-control proof; no manual dispatch, publication, force-push, or authority change was used."
requirements-completed: [TRTH-01, TRTH-02, TRTH-03]
coverage:
  - id: D1
    description: "Protected main and normal CI are handed to the read-only closeout plan as one exact identity pair."
    requirement: TRTH-01
    verification:
      - kind: integration
        ref: "git rev-parse HEAD/origin/main and gh run view 33020041269"
        status: pass
    human_judgment: false
  - id: D2
    description: "Applicable scheduled-control evidence is current for the exact protected-main SHA without manual substitution."
    requirement: TRTH-02
    verification:
      - kind: manual_procedural
        ref: "Approved human-verification checkpoint for main SHA 00bce87d77ce9d8a74ad0f42de5d8ce71ef054fb"
        status: pass
    human_judgment: true
    rationale: "Scheduled controls are external time-bound evidence and the approved checkpoint confirms their applicability without authorizing a substitute run."
  - id: D3
    description: "The plan preserves protected release authority by recording observations only."
    requirement: TRTH-03
    verification:
      - kind: unit
        ref: "mix test test/scripts/phase_164_repository_truth_test.exs test/scripts/phase_164_closeout_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check"
        status: pass
    human_judgment: false
metrics:
  duration: 1m
  completed_date: 2026-08-27
  tasks_completed: 1
  files_changed: 1
status: complete
---

# Phase 164 Plan 06: Protected-main closeout evidence Summary

Exact protected-main evidence is pinned for the final read-only closeout: `main_sha=00bce87d77ce9d8a74ad0f42de5d8ce71ef054fb` and normally triggered successful CI run `ci_run_id=33020041269`.

## Accomplishments

1. Completed the approved protected-main checkpoint after confirming local `HEAD` and `origin/main` both equal `00bce87d77ce9d8a74ad0f42de5d8ce71ef054fb`.
2. Re-queried CI run `33020041269`: workflow `CI`, event `push`, terminal `completed/success`, and `headSha` exactly equals the supplied main SHA.
3. Recorded the approval that applicable scheduled controls have current evidence for the same SHA, with no manual dispatch, alternate SHA, forced publication, or authority-changing workaround.

## Verification

- `test -x scripts/closeout_repository_truth.sh` — passed.
- `mix test test/scripts/phase_164_repository_truth_test.exs test/scripts/phase_164_closeout_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check` — passed: 49 tests, 0 failures, 1 existing skipped.
- `gh run view 33020041269 --json databaseId,workflowName,headSha,event,status,conclusion,url` — confirmed the exact normal push CI identity and terminal success.

## Decisions Made

- Plan 164-07 receives the immutable `main_sha` and `ci_run_id` above, but independently revalidates them before producing a final report.
- Scheduled-control proof remains human-approved time-bound evidence; manual dispatch is never an equivalent substitute.

## Deviations from Plan

None - plan executed exactly as written after its required human-verification checkpoint was approved.

## Known Stubs

None.

## Next Phase Readiness

Plan 164-07 can run the read-only closeout command using CI run `33020041269` against protected main SHA `00bce87d77ce9d8a74ad0f42de5d8ce71ef054fb`.

## Self-Check: PASSED

- The summary records the exact supplied protected-main and CI-run identities.
- The closeout command and all four local contract files exist and passed the plan verification suite.
