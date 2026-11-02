---
phase: 178-preview-authoring-and-milestone-review
plan: "17"
subsystem: CI
tags: [GitHub Actions, hosted evidence, fail-closed]

requires:
  - phase: 178-16
    provides: The approved re-frozen candidate and two exact-SHA attempt-1 hosted runs.
provides:
  - Captured run metadata and all failed-job logs, with an evidence-backed stop classification.
  - An explicit not-measured cost disposition and open hosted acceptance rows.
affects: [178-18, 178-19]

actuals:
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - Required-lane and Demo evidence failures stop hosted measurement without reruns.
key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-17-SUMMARY.md
  modified:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
key-decisions:
  - Hex Audit's required-lane failure stops the plan; Demo Browser Evidence independently triggers the same stop path.
  - Hosted receipts, counts and costs remain unmeasured; no cost-disposition file was created.
patterns-established:
  - Preserve the raw attempt-1 run/job metadata and each failed job log under the ignored CI evidence directory.
requirements-completed: []

coverage:
  - id: D1
    description: Both exact-candidate runs were captured at attempt 1 and every failed job log was saved and hashed.
    requirement: UIQ-08
    verification:
      - kind: other
        ref: 178-AUTOMATION.md Re-run capture and classification; saved run/job metadata and log inventory
        status: pass
    human_judgment: false
  - id: D2
    description: Required Hex Audit and Demo Browser Evidence failures were classified as stop conditions; no rerun or measurement followed.
    requirement: UIQ-07
    verification:
      - kind: other
        ref: 178-AUTOMATION.md rerun_hosted_status, rerun_stop_job and rerun_stop_log; attempt-1 run logs
        status: pass
    human_judgment: false
  - id: D3
    description: The open draft PR, unchanged main and release ledger, successful Guard Release Trigger checks, and open hosted acceptance rows were verified.
    requirement: UIQ-08
    verification:
      - kind: other
        ref: 178-AUTOMATION.md post-action audit and Acceptance closure (D-15)
        status: pass
    human_judgment: false
  - id: D4
    description: The stopped branch records cost as not measured and leaves the cost-disposition artifact absent.
    requirement: UIQ-07
    verification:
      - kind: other
        ref: 178-AUTOMATION.md Placement, cost and limits, re-run (UIQ-07)
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-11-01
status: complete
plan_base_sha: c8d148001511498d9caafecef61cc056f88fd57c
plan_head_before: c8d148001511498d9caafecef61cc056f88fd57c
plan_head_after: 63ea403b067249783e7a265db4152daa7fa3388e
rerun_candidate_sha: 255422cbe6e16c570ccb465246c2394fa3190866
---

# Phase 178 Plan 17: Hosted Re-run Stop Summary

**Plan 17 completed its evidence capture and stopped the hosted workflow as required: Hex Audit failed a required lane, and Demo Browser Evidence also failed in both runs.**

## Accomplishments

- Saved raw run metadata, job metadata, artifact listings, and all three failed-job logs for each attempt-1 run under `reference/demo_app/tmp/demo_browser_evidence/ci/`.
- Confirmed both runs target candidate `255422cbe6e16c570ccb465246c2394fa3190866`, attempt 1. Both had failed jobs `Hex Audit`, `Demo Browser Evidence`, and `CI Green`.
- Classified Hex Audit as a required-lane red. Its logs report `phoenix_html 4.3.0 VULNERABLE!`, advisory `EEF-CVE-2026-117645` (medium), with delivery blocked in the root, Admin and Inbound applications. The frozen candidate's root `mix.lock` also records 4.3.0.
- Independently confirmed the Demo Browser Evidence stop condition. Each log shows 26 Phase 175 Axe cases passing, then an environment dependency check failing because Hex packages were unavailable; the artifact upload also failed with `EACCES` opening a cold Phase 175 Axe artifact. Neither run published a downloadable Demo evidence artifact.
- Verified Operator Browser Gate and Support Contract Admin passed in both runs, Preview Capture Advisory passed in both, and both candidate-SHA Guard Release Trigger check runs passed.
- Verified PR #317 remains open and draft at the candidate SHA, `origin/main` remains at the pre-approval SHA, the release ledger is unchanged, and both attempts remain 1.
- Opened the three hosted-dependent acceptance rows and recorded cost as not measured. No UIQ-06 hosted receipts, hosted count disposition or cost figures were produced, and no cost-disposition artifact was created.

## Hosted Run Results

| Run | Event | Result |
|---:|---|---|
| 41358618944 | pull_request | Completed with failure: Hex Audit, Demo Browser Evidence, and CI Green. |
| 41358616440 | workflow_dispatch | Completed with failure: Hex Audit, Demo Browser Evidence, and CI Green. |

The CI Green logs name `hex_audit=failure` as the required-lane blocker. Demo Browser Evidence is also a stop by plan rule, regardless of advisory classification. The saved Hex Audit stop log is `reference/demo_app/tmp/demo_browser_evidence/ci/41358618944-attempt-1/hex-audit.log` (SHA-256 `5d0fa908bfcad34fee14e083e10ad862ff09a25ecff33981c368fe0bcb5c1551`). All failed-job log paths, hashes, job URLs, and raw metadata paths are recorded in `178-AUTOMATION.md`.

## Performance

- **Duration:** about 7 minutes
- **Started:** about 2026-11-01T23:05Z, after Plan 16 bookkeeping
- **Completed:** 2026-11-01T23:12Z
- **Tasks:** 2
- **Tracked files modified by the tasks:** 1

## Task Commits

1. **Task 1: Capture and classify hosted evidence** — `dc752bec`.
2. **Task 2: Record the not-measured cost disposition** — `63ea403b`.

## Evidence Checks

- Stop-path check passed: the designated log is non-empty, the PR remains open and draft, `origin/main` is unchanged, the release ledger is unchanged, and both runs are attempt 1 at the frozen SHA.
- Evidence inventory check passed: each run has metadata and non-empty logs for all three failed jobs; neither artifact listing contains a Demo Browser Evidence artifact.
- Closure check passed: UIQ-06, UIQ-07 and UIQ-08 are open with the recorded hosted-stop reason; no hosted row remains pending or claims closure.
- Cost stop-path check passed: the not-measured section appears exactly once and no cost-disposition artifact exists.
- No product test suite was run; only the plan's evidence and stop-path verifications were executed.

## Plan Boundary

The plan's stop rule says plans 178-18 and 178-19 do not run. The phase remains incomplete, and UIQ-06, UIQ-07 and UIQ-08 remain unmet for this candidate. The next useful step is to address the root Hex Audit finding and the Demo evidence environment/upload failure, then freeze a new candidate and obtain fresh approval before any additional hosted run.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-11-01*

## Self-Check: PASSED

- The designated stop log is non-empty and its SHA-256 matches the automation record.
- All three hosted-dependent acceptance rows are open with the recorded stop reason.
- The captured run IDs, attempts and candidate SHA match the saved metadata.
