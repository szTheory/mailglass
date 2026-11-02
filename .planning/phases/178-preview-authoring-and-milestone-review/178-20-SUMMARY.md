---
phase: "178-preview-authoring-and-milestone-review"
plan: "20"
subsystem: "demo evidence recovery"
tags: [lockfiles, local-evidence, candidate-freeze]
dependency_graph:
  requires: []
  provides: ["reviewed local recovery candidate with source/evidence hashes"]
  affects: ["178-21", "UIQ-06", "UIQ-07", "UIQ-08"]
tech_stack:
  added: []
  patterns: ["run-scoped Compose volumes", "SHA-256 candidate/evidence ledger"]
key_files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-RECOVERY-REVIEW.md
    - .planning/phases/178-preview-authoring-and-milestone-review/178-RECOVERY.json
  modified:
    - mix.lock
    - mailglass_admin/mix.lock
    - mailglass_inbound/mix.lock
    - compose.demo.yml
    - scripts/run_demo_browser_evidence.sh
    - scripts/test_run_demo_browser_evidence.sh
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
decisions:
  - "Keep the checkout on main; record gsd/v2.10-ui-repairs-storybook as the future remote target ref."
  - "Reuse the saved cold/warm pilot only after selected-source digests match the committed recovery bytes."
  - "Keep hosted, preview, and owner authority unset; UIQ-06/07/08 remain open."
metrics:
  duration: "5m 8s"
  completed: "2026-11-02"
  tasks: 3
  files: 9
  commits: 3
  plan_head_before: "74b312c4c27c3c0226c7a9049fb4f6b56b960b84"
  plan_head_after: "ae019b19a417985b8b9b333597c6f476b7979da1"
status: complete
actuals:
  tokens: 11006
  tasks: 3
  commits: 3
---

# Phase 178 Plan 20: Local Recovery Candidate Freeze Summary

The Hex-audited lock fixes and Demo Browser Evidence environment/ownership recovery are reviewed and frozen as a local candidate with byte-matched cold/warm provenance.

## Completed

- Updated only the `phoenix_html` entry from 4.3.0 to 4.4.0 in the root, Admin, and Inbound lock graphs.
- Reviewed `demo_e2e` cache sharing, locked Admin test-dependency resolution, per-run Compose isolation, cleanup scope, and Phase 175 evidence ownership. The review found no high-severity ASVS L1 issues.
- Recorded the preexisting dirty-workspace inventory and explicitly staged only the paths assigned to each task.
- Froze candidate `f5138e94cd32daf29720f794cf3fbb464c3f1b86` on the unchanged local `main` checkout. The `candidate.branch` field records the future target ref `gsd/v2.10-ui-repairs-storybook`.
- Added the source/evidence SHA-256 ledger in [178-RECOVERY.json](178-RECOVERY.json) and the review in [178-RECOVERY-REVIEW.md](178-RECOVERY-REVIEW.md). The historical stop candidate `255422cbe6e16c570ccb465246c2394fa3190866` and `rerun_*` fields remain intact.

## Verification

The refreshed [178-VERIFICATION.md](178-VERIFICATION.md) records passing local Hex audit, root/Admin/Inbound locked-dependency checks, wrapper contract, shell syntax, Compose config, and the fresh cold/warm pilot. The plan reused these recorded gates rather than rerunning the expensive checks. The pilot's saved source revision was dirty (`afc308405b36da7f4d86bb795129d0acc680517c`); recomputed Phase 174 and Phase 175 selected-source digests matched the saved receipts and the frozen source bytes. This establishes local provenance only.

Plan verifications passed: the lock graphs are clean after commit and select 4.4.0; the Demo recovery paths are clean after commit and the saved pilot receipt exists; and the recovery JSON verifier confirmed the candidate SHA, six matching Git/source/worktree hashes, evidence hashes, passing review, and unset authority. The working tree remains on `main`.

The local pilot recorded 169/169 Phase 174 cases per condition, 10/10 Phase 175 Admin cases and 26/26 Axe cases per condition, zero Axe violations, and 2.205 added local minutes. That is not hosted runner cost. Hosted authority, preview authority, and owner decision remain unset. UIQ-06 hosted evidence, UIQ-07 hosted cost/count disposition, and UIQ-08 remain open.

## Commits

- `af510ff8` — `chore(178-20): update Hex-audited phoenix_html lock graphs`
- `f5138e94` — `fix(178-20): repair demo evidence dependencies and ownership`
- `ae019b19` — `docs(178-20): freeze local recovery candidate`

## Deviations from Plan

None. No hosted or preview action was authorized or performed; plans 178-18 and 178-19 remain untouched.

## Self-Check: PASSED

- Recovery review, JSON, and SUMMARY files exist and are non-empty.
- All three task commits are ancestors of the current `main` HEAD.
- Candidate blobs, working source files, and all saved evidence files match their recorded SHA-256 values.
- The six recovery source files are clean after commit; only the new SUMMARY remains uncommitted from this plan.
- Plans 178-18 and 178-19 still have no summaries and were not executed.
