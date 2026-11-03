---
phase: 178-preview-authoring-and-milestone-review
plan: "10"
subsystem: testing
tags: [candidate-preview, runbook, ship-no-ship, not-run, precondition-unmet]
status: not-run

requires:
  - phase: 178-preview-authoring-and-milestone-review
    provides: "178-09 hosted candidate run (stopped)"
provides:
  - "A recorded not-run: plan 178-10 precondition unmet, UIQ-07/UIQ-08 remain unmet"
affects: []

plan_head_before: b1e5936fbc678c575fdb3d94a88f7046ff4b372c
plan_head_after: 47fcf28b369eab0992f803ab5e219b1df68e2820

actuals:
  tokens: 3000
  tasks: 0
  commits: 1

hosted_status: "stopped: new advisory failure (Demo Browser Evidence (Docker Compose / Chromium))"
requirements-completed: []

key-decisions:
  - "Plan did not run: its precondition (owner_decision approve + hosted_status: completed) fails because 178-09 recorded hosted_status stopped. No preview, runbook, checkpoint, Docker work or remote action occurred."
---

# Phase 178 Plan 10: Verified Working Preview Runbook Summary

**Not run: the 178-09 hosted candidate run stopped on a new advisory failure, so the plan's precondition fails and UIQ-07/UIQ-08 remain unmet.**

## Precondition evidence

Plan 178-10 runs only when 178-AUTOMATION.md records an approving `owner_decision:` AND `hosted_status: completed`. Verified from the files:

- `.planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md` line 418: `owner_decision: approve-all` (approving).
- Same file, line 460 (section "Hosted classification"): `hosted_status: stopped: new advisory failure (Demo Browser Evidence (Docker Compose / Chromium))`. `grep -E '^hosted_status: completed$'` finds nothing.
- `178-09-SUMMARY.md` frontmatter repeats `hosted_status: "stopped: new advisory failure (Demo Browser Evidence (Docker Compose / Chromium))"`.

Per the plan ("Under ... `hosted_status: stopped: <reason>` ... it does not run, and the phase records UIQ-08 as unmet") and task 178-10-01's action ("record 'not run: hosted candidate not approved or not completed' in the SUMMARY"): **not run: hosted candidate not approved or not completed.** A short "Not run" section was also added to 178-AUTOMATION.md (commit 47fcf28b).

## What did not happen

- No candidate preview or Compose project was started; `scripts/check_phase178_candidate.sh` was not run; `review_demo_count_before` was not recorded.
- `178-DELIVERY.md` was not written; no URL verification table exists.
- The ship/no-ship checkpoint (178-10-03) was not presented; no owner decision exists.
- No remote action of any kind. PR #317 stays a draft, open, unmerged.

## Blocking defect

The root Demo Browser Evidence job in `.github/workflows/ci.yml` (about line 1059) runs `node --test ... mailglass_admin/e2e/support/storybook-axe.test.cjs`. `mailglass_admin/e2e/support/storybook-axe-supplement.cjs:1` does `require("@playwright/test")`, which that job never installs, so it fails with `Cannot find module '@playwright/test'` (MODULE_NOT_FOUND) before any evidence is captured. Introduced in Phase 175 (commits 9eaa586a, a65a670d); first hosted-run by 178-09. Also recorded, undiagnosed: PR-run Operator Browser Gate failure at `e2e/flows.spec.js:2453` ("Phase174 scroll access: Inbound overflow is keyboard reachable..."), which passed in the dispatch run on the same SHA.

Moving forward needs a decision outside this plan: make `@playwright/test` available to that step (or scope the test out of the root Demo job), a new candidate freeze, and a new 178-09-02 approval.

## Requirement status

UIQ-07 and UIQ-08 remain **unmet**. No requirement was marked complete.

## Task results

| Task | Result |
|------|--------|
| 178-10-01 launch candidate | not run (precondition) |
| 178-10-02 runbook | not run |
| 178-10-03 owner checkpoint | not presented |
| 178-10-04 dispositions | not run |

## Deviations from Plan

None in execution; the plan was not run per its own precondition. The commit trailer uses `Claude Sonnet 5.5` per the orchestrator instruction, not the `Claude Opus 5.5` named in the plan text.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Commit 47fcf28b is an ancestor of HEAD; 178-AUTOMATION.md contains the "Not run" section.
