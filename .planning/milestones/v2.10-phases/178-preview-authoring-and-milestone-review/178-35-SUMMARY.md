---
phase: 178-preview-authoring-and-milestone-review
plan: "35"
subsystem: testing
tags: [inbound, architecture-contract, ci, recovery]
requires: []
provides:
  - Cycle 09 source candidate with passing local inbound checks
  - Recorded standing authorization for the bounded no-PII PR and CI sequence
  - Explicit preview boundary: deferred and not authorized
affects: [178-36, 178-23, 178-24]
actuals:
  tokens: 1200
  tasks: 2
  commits: 1
tech-stack:
  added: []
  patterns: [exact-source recovery records, fail-closed hosted evidence]
key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-35-SUMMARY.md
  modified:
    - mailglass_inbound/test/mailglass_inbound/architecture_port_test.exs
    - .planning/phases/178-preview-authoring-and-milestone-review/178-RECOVERY-CYCLE-09.json
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
    - .planning/STATE.md
    - .planning/ROADMAP.md
requirements-completed: [UIQ-06, UIQ-07, UIQ-08]
coverage: []
duration: 25min
completed: 2026-11-02
status: complete
---

# Phase 178 Plan 35 Summary

**Cycle 09 candidate `5ad5329a6d0f17da0edce3af6b4a987bc3219023` passed its local checks and is approved for the bounded PR/CI sequence; preview remains deferred.**

## Accomplishments

- Added the shared `Mailglass.Clock` module to the inbound architecture-port allowlist. This is the one-file follow-up to Cycle 08's failing contract check; no production code or dependency changed.
- Confirmed the committed source hash, candidate ancestry, local test receipts, and unchanged Cycle 08 record.
- Recorded the owner's standing permission for a no-PII PR push and normal/phase-required checks without per-SHA prompts. The packet records one fast-forward push, at most one body-only PR update, one gated `ci.yml` dispatch, attempt 1 only, at most eight workflows, and no retries, reruns, or cancellations.
- Recorded preview as deferred. It remains unauthorized until the hosted and cost gates pass and the owner makes a separate decision.
- Recorded the Cycle 08 CI timing review and a scoped follow-up for fail-closed path-aware lane selection. No lane is skipped for this mixed UI PR.

## Local Verification

- Focused architecture contract: 3 tests passed.
- Inbound suite without the separate property invocation: 481 tests passed.
- Gated convergence property invocation: 3 properties passed.
- Formatter check and `git diff --check` passed.
- PII scan of outgoing changed source lines found no email, phone, or credential-like matches.

Full command/result receipts are in `reference/demo_app/tmp/phase178_candidate/recovery-cycle-09/local-verification-receipts.md`.

## Task Commit

1. **Task 1: repair and verify the architecture allowlist** — `5ad5329a6d0f17da0edce3af6b4a987bc3219023` (`test(inbound): allow shared clock architecture edge`).
2. **Task 2: record the hosted and preview decisions** — stored in the Cycle 09 recovery record and approval packet. No new source commit was made, so the approved candidate SHA stays unchanged.

## CI Timing Lesson

Cycle 08's PR workflow used 113.53 runner-minutes over 17m11s. The operator and demo browser lanes are required for this mixed UI PR's exact-SHA evidence, so skipping them is unsafe. Inbound-only path classification may save about 58 runner-minutes in future runs, while the measured wall-time saving here would have been about 72 seconds because the deterministic suite remained the critical path. The follow-up todo lists the classifier cases and the required-check safeguards.

## Next Step

Plan 36 may perform the approved hosted sequence after it rechecks the candidate, target branch, PR, and release ledger. Stop at the first disqualifying CI result. Do not launch a preview in Plan 36. Plans 23 and 24 remain blocked until exact-SHA hosted/cost evidence passes and preview is separately authorized.

---
*Phase: 178*
*Completed: 2026-11-02*
