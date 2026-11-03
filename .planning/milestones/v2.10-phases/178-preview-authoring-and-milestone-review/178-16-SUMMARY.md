---
phase: 178-preview-authoring-and-milestone-review
plan: "16"
subsystem: CI
tags: [GitHub Actions, CI, candidate-freeze, approval]

requires:
  - phase: 178-15
    provides: The re-frozen candidate, local gate evidence, and unit-matched hosted cost inputs.
provides:
  - A fresh owner decision and the exactly approved push, draft PR update and single CI dispatch.
  - Attempt-1 pull_request and workflow_dispatch run records bound to the candidate SHA.
affects: [178-17, 178-18, 178-19]

actuals:
  tokens: 2105
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - Remote workflow evidence is identified by event, attempt and exact candidate SHA.
key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-16-SUMMARY.md
  modified:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
key-decisions:
  - The user's fresh approval selected approve-all for the exact re-frozen candidate.
  - Keep the hosted acceptance rows pending until plan 178-17 verifies the hosted evidence.
patterns-established:
  - Keep approved remote actions, timestamps, outputs and run IDs in one local audit record.
requirements-completed: [UIQ-07, UIQ-08]

coverage:
  - id: D1
    description: The user-approved fast-forward push, draft PR body update and one CI dispatch were completed in order.
    requirement: UIQ-08
    verification:
      - kind: other
        ref: 178-AUTOMATION.md Re-run remote actions; branch, PR and release-ledger post-action checks
        status: pass
    human_judgment: false
  - id: D2
    description: Both triggered runs completed at attempt 1 with head SHA equal to the approved candidate.
    requirement: UIQ-07
    verification:
      - kind: other
        ref: gh run view 41358618944 and 41358616440; both event/attempt/SHA checks pass
        status: pass
    human_judgment: false
  - id: D3
    description: The pre-approval self-check reproduces zero deltas for exact baseline jobs and the review URLs resolve.
    verification:
      - kind: integration
        ref: rerun-disposition-inputs/self-check.json and plan 178-16 task 1 read-only verifies
        status: pass
    human_judgment: false

duration: 53min
completed: 2026-11-01
status: complete
plan_base_sha: e08b10231a12c97260c41faeff4cdcb336bc2452
plan_head_before: e08b10231a12c97260c41faeff4cdcb336bc2452
plan_head_after: 0623c53bf1c5c4570fc611c3cc4b2fe1bd8abc92
rerun_candidate_sha: 255422cbe6e16c570ccb465246c2394fa3190866
---

# Phase 178 Plan 16: Hosted Re-run Approval Summary

**The owner-approved candidate was pushed by fast-forward, the draft PR was updated, and one dispatch was issued; both exact-SHA runs completed with failures.**

## Performance

- **Duration:** 53 min
- **Started:** 2026-11-01T22:09:51Z
- **Completed:** 2026-11-01T23:03:19Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Resolved the live PR, run and compare URLs; confirmed the review branch had not moved; measured the current scope and reproduced the baseline cost pipeline with all exact-name job deltas at zero.
- Recorded the user's reply selecting approve-all, then pushed candidate 255422cbe6e16c570ccb465246c2394fa3190866 by fast-forward, updated draft PR #317, and issued exactly one ci.yml dispatch.
- Identified pull_request run 41358618944 and workflow_dispatch run 41358616440. Both completed at attempt 1 with the candidate SHA.
- Verified the review PR remains open and draft, main remains at its pre-approval SHA, the branch equals the candidate, and .planning/release-target.json is unchanged.
- Left the three hosted-dependent acceptance rows pending for plan 178-17 to classify.

## Hosted Run Results

| Run | Event | Result |
|---:|---|---|
| 41358618944 | pull_request | Completed, failure. Hex Audit and Demo Browser Evidence failed; CI Green failed. |
| 41358616440 | workflow_dispatch | Completed, failure. Hex Audit and Demo Browser Evidence failed; CI Green failed. |

Support Contract Admin passed in both runs. Demo Browser Evidence failed in both, so the hosted UIQ-06 receipts and UIQ-07 measurement are not established. Plan 178-17 must inspect the saved logs and artifacts and record an honest stop if the Demo failure is confirmed. No rerun or merge is authorized or performed.

## Task Commits

1. **Task 1: Record pre-approval state and prepare the checkpoint** — 28ba7868.
2. **Task 2: Owner decision checkpoint** — the user replied: I approve all your recommendations from above.
3. **Task 3: Execute approved remote actions and wait for completion** — 0623c53b.

## Decisions Made

The user explicitly selected approve-all for the exact candidate SHA. The approved actions were limited to the branch fast-forward, PR #317 body update, and one CI dispatch. The hosted failures do not authorize a retry; they must be classified and recorded by plan 178-17.

## Deviations from Plan

The PR body template called for Claude Code attribution. Repository instructions specify Codex as the active runtime, so the draft body uses accurate OpenAI Codex attribution. GitHub added one trailing blank line when storing the body; normalized content matches the approved local draft.

## Issues Encountered

Both runs failed in Hex Audit and Demo Browser Evidence, which made CI Green fail. These hosted failures are not classified in this plan. The next plan must inspect the saved evidence before changing acceptance status. No further remote action has been taken.

## User Setup Required

None.

## Next Phase Readiness

Plan 178-17 should inspect the attempt-1 artifacts and logs for both runs, verify whether the Demo failure is classifiable, and follow its fail-closed stop rule. The three hosted-dependent acceptance rows remain pending until that review writes their disposition.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-11-01*
