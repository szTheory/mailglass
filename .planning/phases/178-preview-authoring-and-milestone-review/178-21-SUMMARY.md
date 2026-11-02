---
phase: 178-preview-authoring-and-milestone-review
plan: "21"
subsystem: hosted-evidence
tags: [github-actions, approval, ci, recovery]
requires:
  - phase: 178-20
    provides: frozen recovery candidate f5138e94cd32daf29720f794cf3fbb464c3f1b86
provides:
  - Fresh SHA-bound approval and receipts for one branch push, PR body update, and CI dispatch
  - Attempt-1 run identities, outcomes, and captured Preview Capture Advisory failure log
affects: [178-22, 178-23, 178-24, UIQ-06, UIQ-07, UIQ-08]
actuals:
  tokens: 5294
  tasks: 3
  commits: 2
tech-stack:
  added: []
  patterns: [exact-SHA approval, attempt-1-only hosted observation]
key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-21-SUMMARY.md
    - reference/demo_app/tmp/phase178_candidate/dispatch-preview-capture-advisory.log
  modified:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-RECOVERY.json
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
key-decisions:
  - "Owner approve-all applied only to candidate f5138e94cd32daf29720f794cf3fbb464c3f1b86 and the three displayed hosted operations."
  - "No retry or preview launch followed the dispatch run's advisory failure; no later plan was executed."
requirements-completed: []
duration: 57min
completed: 2026-11-02
status: complete
commits: 2
plan_head_before: 118b0aae9338ee12f22ed8b94b02ee4e81a9f117
plan_head_after: 4897e924386426ab150ebf18bd75356514daf9c0
---

# Phase 178 Plan 21: SHA-bound hosted recovery cycle Summary

Fresh approval bound exactly three one-time hosted operations to the frozen candidate; both attempt-1 CI runs were observed and the advisory failure log was retained.

## Performance

- **Duration:** 57 minutes from the recorded preapproval snapshot to the final run result
- **Started:** 2026-11-02T00:21:50Z (preapproval snapshot)
- **Completed:** 2026-11-02T01:18:53Z
- **Tasks:** 3/3
- **Files modified:** 2, plus this summary

## Accomplishments

- Recorded the owner's verbatim `approve-all` for SHA `f5138e94cd32daf29720f794cf3fbb464c3f1b86`, including the exact fast-forward push, body-only update to PR #317, one `ci.yml` dispatch, and conditional local-preview authority.
- Pushed the candidate branch once, updated only the body of draft PR #317 once, then dispatched CI once after the automatic PR run's required and Demo checks passed.
- Observed only attempt 1 for [PR run 41368588479](https://github.com/szTheory/mailglass/actions/runs/41368588479) and [dispatch run 41370082849](https://github.com/szTheory/mailglass/actions/runs/41370082849). The PR run passed. The dispatch run completed with 25/26 jobs passing; Demo Browser Evidence, Operator Browser Gate, and CI Green passed. Its only failure was Preview Capture Advisory, whose captured log reports missing `inotify-tools` and a server-process exit code 1.
- Confirmed the target branch still equals the candidate, remote `main` remains at its preapproval SHA, PR #317 remains open/draft, and the release-ledger hash is unchanged. All three authorized operations were consumed; none remain unspent.

## Verification

- Plan 178-21 run-identity verifier passed; both run records are attempt 1 at the exact candidate SHA with distinct `pull_request` and `workflow_dispatch` events.
- Captured advisory log SHA-256: `a3278b3b93c95ef8b7bf4ee34ba6c196cd62302bb35991154bfc03934618dda9`.
- Preapproval body, checkpoint, expected-count input, and release-ledger hashes matched their recorded values.
- No retry, preview launch, merge, release, publication, deployment, or later-plan action occurred.

## Outcome and remaining work

Plan 21's one-time operation and run-receipt objective is complete. The dispatch workflow's overall conclusion is failure because the Preview Capture Advisory job could not start its file-system/live-reload service; no rerun was authorized. The conditional preview was not launched. UIQ-06, UIQ-07, and UIQ-08 remain open; no follow-on plan was executed in this task.

## Deviations from Plan

None. The advisory failure was recorded as an attempt-1 result with its complete log, without retry.

## Self-Check: PASSED

The summary, receipt documents, and captured advisory log exist; both Plan 21 task commits are ancestors of the current local `main` HEAD; the log hash matches the receipt; and the preview remains `not_started`.
