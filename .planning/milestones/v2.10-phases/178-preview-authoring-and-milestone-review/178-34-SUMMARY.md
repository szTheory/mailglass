---
phase: 178-preview-authoring-and-milestone-review
plan: "34"
subsystem: hosted-evidence
tags: [cycle08, github-actions, exact-sha, fail-closed]
requires:
  - phase: 178
    provides: Cycle 07 stop, Plan 33 local time-window repair, and Cycle 08 fresh approval packet
provides:
  - Cycle 08 exact-SHA approval, one fast-forward push, five attempt-1 workflow receipts, and a fail-closed stop
  - Explicit no-cost/no-preview state and evidence for the follow-up architecture-contract correction
affects: [178-23, 178-24, UIQ-06, UIQ-07, UIQ-08]
actuals:
  tasks: 3
  hosted_writes: 1
  workflow_runs: 5
commits: 0
plan_head_before: 0942d667c50247b7794bc52cbadcc2b65a850d61
plan_head_after: 0942d667c50247b7794bc52cbadcc2b65a850d61
tech-stack:
  added: []
  patterns:
    - Bind every approval and hosted receipt to a full candidate SHA.
    - Stop before remaining remote writes when a required or unclassified lane fails.
key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-RECOVERY-CYCLE-08.json
    - .planning/phases/178-preview-authoring-and-milestone-review/178-CYCLE-08-SUMMARY.md
  modified:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
    - .planning/phases/178-preview-authoring-and-milestone-review/COVERAGE.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
key-decisions:
  - Stop after Inbound Test failed because Mailglass.Clock was missing from the inbound package architecture allowlist; do not update the PR body or dispatch CI.
  - Keep Cycle 08 cost unmeasured and its conditionally approved preview ineligible; Plans 23–24 remain blocked.
requirements-completed: []
duration: about 34min
completed: 2026-11-02
status: complete
---

# Phase 178 Plan 34 Summary

**Cycle 08 is complete as a documented fail-closed stop; the new candidate failed the inbound architecture contract before the remaining hosted operations.**

## Performance

- **Started:** 2026-11-02T17:06:19Z (based on the prior state update)
- **Completed:** 2026-11-02T17:43:00.025Z
- **Tasks:** 3/3 completed, including the approval checkpoint and final evidence capture.
- **Files modified:** recovery record, cycle/plan summaries, automation and coverage/state/roadmap tracking; ignored hosted receipts are retained separately.

## Accomplishments

- Froze candidate 0942d667c50247b7794bc52cbadcc2b65a850d61 after the updated plans and tracking metadata were committed. The read-only preflight matched Cycle 07’s final remote/PR/ledger snapshot.
- Prepared the ignored approval and PR-body packets, copied the canonical baseline inputs byte-for-byte, and recorded the owner’s separate hosted and conditional-preview approvals for the exact SHA.
- Performed one approved non-forced fast-forward push. The push reached GitHub; the environment could not update its local remote-tracking ref because .git is read-only. No retry was made.
- Observed five candidate runs, all attempt 1 at the exact SHA: three passed; CI and Advisory Matrix failed on the same architecture-contract omission. Required Inbound Test and CI Green failed; both schema advisory tests failed. Demo Browser Evidence passed.
- Stopped before the approved PR body update and ci.yml dispatch. Cost remains unmeasured, no cost disposition was created, and the conditional preview remains unused and ineligible.
- Preserved Cycle 07 unchanged. Plans 23–24 remain blocked and the phase requirements UIQ-06/07/08 remain open.

## Evidence and diagnosis

The architecture test’s per-file allowlist for lib/mailglass_inbound/internal/operator/records.ex admits Mailglass.Tenancy but omits Mailglass.Clock. The new production code calls the shared Mailglass.Clock.utc_now/0; the CI failure is the architecture guard, not Docker or the Demo Browser Evidence lane. The smallest follow-up is to add the shared clock module to that file’s allowlist, then validate locally before preparing a fresh candidate. Cycle 08 approval does not authorize operations on a changed SHA.

Raw run/job/artifact records, 34 job logs, and 192 downloaded CI artifact files are retained under reference/demo_app/tmp/phase178_candidate/recovery-cycle-08/. SHA-256 manifests were verified for all 467 listed evidence files. See [178-CYCLE-08-SUMMARY.md](178-CYCLE-08-SUMMARY.md) and [178-RECOVERY-CYCLE-08.json](178-RECOVERY-CYCLE-08.json).

## Issues and limits

- PR #317 is still open/draft, now at the Cycle 08 head, but its body update was withheld; the body still describes Cycle 07. The next authorized candidate cycle should update it only after its own fresh approval and exact-SHA checks.
- No local preview, merge, release, publication, or deployment occurred.
- The host exposed .git read-only after the push, so the GSD summary/state changes below cannot be committed from this session. Workspace files are updated; the execution environment is the blocker.

## Next action

Continue locally with the architecture-allowlist correction and its planned verification. Freeze a new candidate only after the correction is committed, then request fresh exact-SHA approval before any hosted write or preview. No user action is needed until that new packet is ready.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-11-02*
