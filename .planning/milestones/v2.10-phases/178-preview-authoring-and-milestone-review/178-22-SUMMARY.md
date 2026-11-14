---
phase: 178-preview-authoring-and-milestone-review
plan: "22"
subsystem: hosted-evidence
tags: [github-actions, artifact-provenance, attempt-1, hosted-cost]
requires:
  - phase: 178-21
    provides: approved attempt-1 PR and dispatch run identities for candidate f5138e94cd32daf29720f794cf3fbb464c3f1b86
provides:
  - Raw attempt-1 run, job, artifact, check-run and log evidence with SHA-256 receipts
  - A fail-closed stop record that leaves hosted cost and acceptance rows open
affects: [178-23, 178-24, UIQ-06, UIQ-07, UIQ-08]
actuals:
  tokens: 10388
  tasks: 1
  commits: 1
tech-stack:
  added: []
  patterns: [attempt-1 exact-SHA evidence capture, advisory-lane placement recorded separately from failure classification]
key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-22-SUMMARY.md
  modified:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-RECOVERY.json
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
key-decisions:
  - "Preview Capture Advisory is advisory in ci.yml, but its new missing-inotify-tools setup failure lacks a prior source classification, so the plan stops with the failure preserved."
  - "Keep hosted cost not_measured and UIQ-06, UIQ-07 and UIQ-08 open; do not run Plans 178-23 or 178-24."
requirements-completed: []
duration: 13min
completed: 2026-11-02
status: halted
commits: 1
plan_head_before: e3650689bce7c053d64285fd7f437ecb05e3b9e2
plan_head_after: 3bb10b62a838755af6e2e58681e0ad853e598ff5
---

# Phase 178 Plan 22: Attempt-1 hosted evidence and stop Summary

**Both approved attempt-1 runs and their Demo artifacts are retained with hashes; a new advisory setup failure halts hosted acceptance and leaves cost unmeasured.**

## Performance

- **Duration:** 13 minutes
- **Started:** 2026-11-02T01:25:22Z
- **Completed:** 2026-11-02T01:38:41Z
- **Tasks:** 1 of 2; task 2 was not entered after the stop
- **Files modified:** 2 plan documents, plus this summary and GSD state/roadmap records

## Accomplishments

- Saved raw attempt-1 run, paginated job and artifact metadata for PR run [41368588479](https://github.com/szTheory/mailglass/actions/runs/41368588479) and dispatch run [41370082849](https://github.com/szTheory/mailglass/actions/runs/41370082849). Preserved the merged job/artifact shapes, exact-SHA check-run response, job logs, both downloadable Demo artifacts, and per-file artifact hash manifests under `reference/demo_app/tmp/demo_browser_evidence/ci/`.
- Confirmed both runs use candidate SHA `f5138e94cd32daf29720f794cf3fbb464c3f1b86`, attempt 1. `CI Green`, `Guard Release Trigger`, every CI Green dependency (including Hex Audit), and both Demo Browser Evidence jobs passed. Both Demo artifacts are present and unexpired.
- Recorded the dispatch's sole red job, Preview Capture Advisory, as an advisory-lane failure: missing `inotify-tools` prevented the file-system/live-reload worker from starting and the server exited 1. This new job-level setup failure has no prior source classification allowed by the Plan 17 protocol, so the plan stops while preserving both the raw API log and Plan 21's formatted log.
- Left all hosted-dependent acceptance rows open and `cost.status` as `not_measured`. `178-COST-DISPOSITION.json` is absent; no counts, cost or placement values were derived. Plans 178-23 and 178-24 were not run.
- Audited the post-action state read-only: PR #317 remains open and draft, remote `main` is unchanged, the candidate branch is at the candidate SHA, the release-ledger hash is unchanged, all three prior hosted operations are consumed, and the conditional preview was not launched.

## Task Commits

1. **Task 1: Capture the approved hosted attempts and preserve a stop** - `3bb10b62` (`docs`)

Task 2 was not entered because Task 1 recorded the stop required by the plan. No hosted checker or cost/count disposition was run after the stop.

## Files Created/Modified

- `178-RECOVERY.json` - Attempt-1 run/job/artifact/check-run file paths and hashes, exact required checks, advisory failure placement and stop reason.
- `178-AUTOMATION.md` - Stop details, raw and formatted log hashes, current acceptance status, and explicit no-cost/no-follow-on record.
- `reference/demo_app/tmp/demo_browser_evidence/ci/41368588479-attempt-1/` and `41370082849-attempt-1/` - Raw metadata, job logs, unexpired Demo artifacts and per-file SHA-256 manifests; these local evidence directories are not committed.

## Decisions Made

- `.github/workflows/ci.yml` excludes `preview_capture_advisory` from the `ci_green` dependency list, so the red job is recorded as advisory and is not mislabeled as required.
- The advisory placement does not make this new setup failure eligible for continuation under Plan 17. Keep the run red in the record and stop without hosted cost, count disposition, or acceptance closure.

## Deviations from Plan

**1. Preserved the existing Demo artifacts before finalizing the stop classification.**

- **Found during:** Task 1
- **Issue:** Plan 22 downloads Demo artifacts on its success path; during the initial evidence review, the two unexpired artifacts were downloaded once before the new setup failure was confirmed as a stop.
- **Fix:** Kept both downloads and hashed each file. They are documented as retained evidence only; no Phase 174/175 checker was run and no hosted receipt is claimed.
- **Files modified:** Local evidence under `reference/demo_app/tmp/demo_browser_evidence/ci/`; no source or test files.
- **Verification:** Each run's artifact listing reports its Demo artifact unexpired, the run/job metadata report Demo success, and both 152-file manifests are retained.

## Issues Encountered

- The dispatch run's `Preview Capture Advisory` job failed because `inotify-tools` was absent on its runner. The raw API log is `reference/demo_app/tmp/demo_browser_evidence/ci/41370082849-attempt-1/preview-capture-advisory.log` (SHA-256 `01bdbc9906e3ab17fae1e441f62077767e7585bac89fef7727a443d5c164fdd3`). The formatted Plan 21 log remains at `reference/demo_app/tmp/phase178_candidate/dispatch-preview-capture-advisory.log` (SHA-256 `a3278b3b93c95ef8b7bf4ee34ba6c196cd62302bb35991154bfc03934618dda9`); it has the same failure in a job-prefixed format.
- The retained Operator logs show the seven Phase 178 zoom/reduced-motion titles passing in both runs, but no receipt set is accepted after the plan stop. The Demo artifact checkers and task 2 cost/count verify were not run.
- `state.advance-plan` declined to advance because Plans 178-23/24 have no summaries. STATE records the current stop at 20/22, while ROADMAP remains in progress at 20/22.

## User Setup Required

None.

## Next Phase Readiness

Plans 178-23 and 178-24 remain unrun. The hosted cost and all three hosted-dependent acceptance rows remain open. A follow-on plan must resolve the new Preview Capture Advisory setup failure under the existing stop rules before preview or ship work continues.

## Self-Check: PASSED

- Summary exists at the required path and records `status: halted`.
- Task commit `3bb10b62` is present in `HEAD`.
- The stop log exists and its SHA-256 matches `178-RECOVERY.json`.
- `cost.status` is `not_measured`, `178-COST-DISPOSITION.json` is absent, and the three hosted acceptance rows remain open.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-11-02*
