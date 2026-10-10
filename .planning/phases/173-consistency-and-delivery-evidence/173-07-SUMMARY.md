---
phase: 173-consistency-and-delivery-evidence
plan: 07
subsystem: testing
tags: [playwright, docker-compose, png-evidence, exact-sha, css]
requires:
  - phase: 173-06
    provides: Candidate evidence producer, preview Compose contract, and delivery walkthrough
provides:
  - Six current and pinned-baseline synthetic PNG pairs from a clean detached candidate
  - A retained review URL verified against the candidate SHA, five routes, and served Admin CSS bytes
  - An incomplete delivery disposition recording owner acceptance, full local checks, and CI gaps
affects: [UIQ-02, UIQ-03, Phase-173-verification]
actuals:
  tokens: 13887 # chars/4 across disposition, both checkpoint JSON files, and summary
  tasks: 2
  commits: 0 # No tracked task changes; evidence outputs are ignored runtime artifacts.
  commits: 0
plan_head_before: 3d6314bae62729b921b6ed7049adbda5181c5b64
plan_head_after: 3d6314bae62729b921b6ed7049adbda5181c5b64
tech-stack:
  added: []
  patterns: [Detached clean candidate evidence, isolated retained Compose preview, exact-SHA incomplete delivery record]
key-files:
  created:
    - reference/demo_app/tmp/demo_browser_evidence/phase173-gap-disposition.json
    - .planning/phases/173-consistency-and-delivery-evidence/173-07-SUMMARY.md
  modified: []
key-decisions:
  - "Bind current browser and preview evidence to candidate SHA 3d6314bae62729b921b6ed7049adbda5181c5b64."
  - "Keep the retained preview and detached candidate running; record scoped cleanup commands for the owner."
  - "Leave UIQ-03 incomplete because exact-SHA CI Green, protected README acceptance, and the full local gate are unproven."
patterns-established:
  - "A delivery disposition can retain locally verifiable evidence while clearly listing external prerequisites."
requirements-completed: [UIQ-02]
coverage:
  - id: D1
    description: Six current synthetic browser captures and six validated baseline pairs are bound to one clean candidate SHA.
    requirement: UIQ-02
    verification:
      - kind: automated_ui
        ref: reference/demo_app/tmp/demo_browser_evidence/retained/checkpoint.json and six current/baseline PNG SHA-256 comparisons
        status: pass
    human_judgment: false
  - id: D2
    description: A retained preview for the same candidate SHA serves five required routes and Admin CSS bytes matching the candidate bundle.
    verification:
      - kind: integration
        ref: http://127.0.0.1:64514/dev/mail; five HTTP route probes; served CSS SHA-256
        status: pass
    human_judgment: false
  - id: D3
    description: UIQ-03 delivery prerequisites are recorded as incomplete with exact-SHA CI and protected owner acceptance unresolved.
    verification:
      - kind: other
        ref: reference/demo_app/tmp/demo_browser_evidence/phase173-gap-disposition.json; gh run list --commit 3d6314bae62729b921b6ed7049adbda5181c5b64 --workflow CI returned []
        status: pass
    human_judgment: false
duration: 21min
completed: 2026-10-10
status: complete
---

# Phase 173 Plan 07: Current Candidate Evidence Summary

**Six validated synthetic browser capture pairs and a live retained preview are tied to clean candidate `3d6314bae62729b921b6ed7049adbda5181c5b64`; UIQ-03 remains incomplete.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-10-10T11:40:00Z
- **Completed:** 2026-10-10T12:01:11Z
- **Tasks:** 2
- **Files modified:** 16 runtime and summary artifacts

## Accomplishments

- Ran the focused synthetic browser producer from detached candidate `/private/tmp/mailglass-phase173-gap.TrXwThCj/candidate` at SHA `3d6314bae62729b921b6ed7049adbda5181c5b64`. Its retained checkpoint reports `passed`, `candidate_dirty=false`, and six captures. Independent byte hashing verified six current PNGs and six pinned baseline PNGs against their checkpoint SHA-256 values.
- Started and retained Compose project `mailglass-phase173-review-3d6314ba-20261010115642-72946-14875` on HTTP port `64514` and DB port `64515`. The owner review URL is [http://127.0.0.1:64514/dev/mail](http://127.0.0.1:64514/dev/mail). The `/`, `/health`, `/dev/mail`, `/dev/mail/gallery`, and `/dev/storybook/primitives/nav_link?variation_id=long_label` routes each returned HTTP 200.
- Verified the versioned Admin CSS route `/dev/mail/css-7ad717cac50971a2b37f819f8c45975e`. Source CSS SHA-256 is `218a8b6932504a29f92f21d1ac3518e6a5e0fac6f67a86e179defc2c1b958f05`; built and served CSS hashes both equal `91c0b80fd5d2d9dd42d6501b615f3167b5f25a13beed92894e11fdfa1b6abff1`.
- Read-only `gh run list --commit 3d6314bae62729b921b6ed7049adbda5181c5b64 --workflow CI` returned no runs. The disposition remains `incomplete`: protected README owner acceptance is unverified, the full local regression gate was not run under the protected-file constraint, and exact-SHA required `CI Green` is absent. No UIQ-03 or Phase 173 completion claim is made.

## Task Commits

No task-specific Git commits were made. Browser evidence and the disposition JSON are ignored runtime artifacts; the only tracked plan output is this summary.

## Files Created/Modified

- `reference/demo_app/tmp/demo_browser_evidence/phase173-gap-disposition.json` — exact-SHA checkpoint, PNG hashes, route and CSS evidence, CI/owner/local-check gaps, and scoped cleanup commands.
- `/private/tmp/mailglass-phase173-gap.TrXwThCj/candidate/reference/demo_app/tmp/demo_browser_evidence/checkpoint.json` — raw producer checkpoint retained alongside the sanitized checkpoint.
- `/private/tmp/mailglass-phase173-gap.TrXwThCj/candidate/reference/demo_app/tmp/demo_browser_evidence/retained/` — checkpoint and six current/baseline PNG pairs for the clean candidate.
- `.planning/phases/173-consistency-and-delivery-evidence/173-07-SUMMARY.md` — this handoff.

## Decisions Made

- The captured candidate SHA remains the evidence identity. The summary commit is a documentation closeout and does not change the candidate used by the browser run or preview.
- UIQ-02 is complete with current synthetic browser evidence. UIQ-03 remains open pending owner acceptance, full local checks, and required CI Green for the exact SHA.
- Keep the review Compose project and detached worktree available for owner review. Do not run the recorded cleanup commands until review is finished.

## Deviations from Plan

None. The focused runtime and preview startup each modified only the detached candidate's `reference/demo_app/mix.lock`; each mutation was recorded and restored in that candidate before evidence acceptance. The original checkout's lockfile was untouched.

## Issues Encountered

- The initial detached worktree creation and Docker BuildKit operations encountered sandbox permission denials. The orchestrator provisioned the planned detached worktree and retried the exact local runtime commands with elevated access.
- The task intentionally did not run the broad candidate gate, read either protected input, query or modify external systems beyond read-only GitHub CI metadata, or perform visual UAT.

## Retained Resources and Scoped Cleanup

Keep the project and candidate worktree running for owner review. After review, cleanup in this order:

1. `MAILGLASS_DEMO_HTTP_PORT=64514 MAILGLASS_DEMO_DB_PORT=64515 docker compose -p mailglass-phase173-review-3d6314ba-20261010115642-72946-14875 -f /private/tmp/mailglass-phase173-gap.TrXwThCj/candidate/compose.demo.yml down --volumes --remove-orphans`
2. `git worktree remove --force -- /private/tmp/mailglass-phase173-gap.TrXwThCj/candidate`

The same exact commands are stored in the ignored disposition JSON. Neither command was run.

## Next Phase Readiness

UIQ-02 has current local evidence and the owner can review the retained URL above. UIQ-03 and Phase 173 remain unresolved until a separately authorized path provides protected README acceptance, proves the full local gate, and finds successful required `CI Green` for the same final SHA. The retained preview is synthetic browser evidence and does not certify delivered-email client rendering.

## Self-Check: PASSED

- The summary file exists.
- The retained checkpoint and all twelve PNG files exist in the detached candidate; their hashes match the validated checkpoint.
- Candidate HEAD is the recorded SHA and its tracked/untracked status is clean.
- The new Compose project is healthy; all five routes and the served-to-built CSS hash check passed.
- No task-specific Git commit exists because the task evidence outputs are ignored; the summary-only closeout is committed separately.

---
*Plan: 173-07*
*Completed: 2026-10-10*
