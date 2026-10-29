---
phase: 178-preview-authoring-and-milestone-review
verified: 2026-10-29T17:00:00Z
status: gaps_found
score: 3/5 must-haves verified
covered_files:
  - .github/workflows/ci.yml
  - .planning/phases/178-preview-authoring-and-milestone-review/178-01-PLAN.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-01-SUMMARY.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-02-PLAN.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-02-SUMMARY.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-03-PLAN.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-03-SUMMARY.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-04-PLAN.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-04-SUMMARY.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-05-PLAN.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-05-SUMMARY.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-06-PLAN.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-06-SUMMARY.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-07-PLAN.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-07-SUMMARY.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-08-PLAN.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-08-SUMMARY.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-09-PLAN.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-09-SUMMARY.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-10-PLAN.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-10-SUMMARY.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-11-PLAN.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-11-SUMMARY.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-12-PLAN.md
  - .planning/phases/178-preview-authoring-and-milestone-review/178-12-SUMMARY.md
  - mailglass_admin/e2e/phase178-real-zoom.spec.js
  - mailglass_admin/e2e/support/storybook-axe-supplement.cjs
  - mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex
  - mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
  - mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs
  - mailglass_admin/test/support/feedback_ledger.ex
  - reference/persona_spec/quick_view_scenarios.json
  - scripts/check_phase178_candidate.sh
  - scripts/phase178_cost_disposition.cjs
covered_digest: "v4:sha256:37e4634a6e7043d972e83d07268f62ca36a5d80b8d8807582270fae58e4281e4"
behavior_unverified: 0
overrides_applied: 0
re_verification: false
gaps:
  - truth: "Added cold/warm setup-inclusive wall time and runner cost are measured against the provisional budgets, with expected/executed counts, evidence limits and honest required/advisory placement (UIQ-07, ROADMAP SC4)"
    status: failed
    reason: "The only hosted candidate run stopped. Demo Browser Evidence failed in 11-14 s before any capture in both hosted runs (40904249445 dispatch, 40904235961 PR) on candidate 2bdf1816. No 178-COST-DISPOSITION.json exists; the hosted cost/coverage disposition was recorded as 'not measured'. Local measurements exist (Operator Browser Gate 376 s, 311 executed vs 230 baseline) but they are not the setup-inclusive hosted cold/warm measurement the requirement names."
    artifacts:
      - path: ".github/workflows/ci.yml"
        issue: "Line ~1059 'Test Storybook evidence and review contracts' runs mailglass_admin/e2e/support/storybook-axe.test.cjs in the root Demo Browser Evidence job; that job never installs @playwright/test, so the step fails with MODULE_NOT_FOUND."
      - path: "mailglass_admin/e2e/support/storybook-axe-supplement.cjs"
        issue: "Line 1 does require('@playwright/test'); fine locally (mailglass_admin deps installed), unresolvable in the Demo job. Introduced in Phase 175 (a65a670d), first exercised on hosted CI by 178-09."
    missing:
      - "Make @playwright/test resolvable for the storybook-axe.test.cjs step (install the mailglass_admin/e2e deps in the Demo job) or remove that test from the root Demo job's node --test list and run it in a lane that has the dependency; add a regression guard so the step cannot be hosted-only red again"
      - "New candidate freeze after the fix, then a fresh owner-approved push/dispatch (plan 178-09 rule: a fix needs a new freeze and a new 178-09-02 approval)"
      - "Hosted cold and warm Demo evidence run completes; run scripts/phase178_cost_disposition.cjs to write 178-COST-DISPOSITION.json against the <=5 added PR wall minutes / <=10 runner-minutes provisional budget with expected/executed counts and required-vs-advisory placement"
  - truth: "The owner can inspect the repaired milestone in a documented working preview tied to an identified source/candidate with current assets, committed task changes and passing required CI; temporary services/artifacts have explicit dispositions (UIQ-08, ROADMAP SC5)"
    status: failed
    reason: "Plan 178-10 (candidate launch, runbook, 178-DELIVERY.md, service/artifact dispositions, ship/no-ship checkpoint) did not run because its precondition (hosted_status: completed) failed. No runbook or delivery document exists. The two required contexts (CI Green, Guard Release Trigger) are success on the candidate, but the same runs conclude failure overall (Demo Browser Evidence failed; Operator Browser Gate failed in the PR run), so 'passing required CI' is only partially evidenced and the working-preview deliverable is absent."
    artifacts:
      - path: ".planning/phases/178-preview-authoring-and-milestone-review/178-DELIVERY.md"
        issue: "Does not exist (plan 178-10 not run)"
    missing:
      - "Fix the Demo job defect (above), re-freeze, re-run hosted candidate with owner approval"
      - "Execute 178-10: launch the identified-SHA candidate preview via scripts/check_phase178_candidate.sh, verify every runbook URL renders, write 178-DELIVERY.md with full URLs, record service/artifact dispositions, present the ship/no-ship checkpoint (a permitted owner hand-off under D-52)"
      - "Diagnose or classify the PR-run-only Operator Browser Gate failure at mailglass_admin/e2e/flows.spec.js:2453 ('Phase174 scroll access: Inbound overflow is keyboard reachable...'), which passed in the dispatch run on the same SHA"
partial:
  - truth: "Source/URL/asset/font/theme/hook receipts and connected checks reproduce representative light/dark, narrow/wide/container, keyboard/focus, real zoom and reduced-motion behavior (UIQ-06, first half of ROADMAP SC4)"
    status: partial
    reason: "Local evidence is present: StatCard font-role receipt, real 200% zoom spec at 320 CSS px, width/hook receipts and Chromium cases are recorded in 178-AUTOMATION.md and the 178-08 local gate (Operator Browser Gate 311 executed). The hosted Demo lane that carries the StatCard font-role and retained Preview stories receipt never ran (it failed pre-capture), so those receipts are not reproduced on hosted CI. REQUIREMENTS.md keeps UIQ-06 Pending, which is consistent. Closing the UIQ-07 gap above also closes this one."
deferred: []
---

# Phase 178: Preview Authoring and Milestone Review Verification Report

**Phase Goal:** Authors can select/edit/restore previews coherently, and the owner can review all admitted repairs through a working preview backed by retained production scenarios, reproducible current evidence and measured upkeep cost.
**Verified:** 2026-10-29
**Status:** gaps_found
**Re-verification:** No, initial verification

The author-facing product work (SC1, SC2, SC3) is delivered and verified against code and a green targeted test run. The review and evidence half of the goal (SC4 hosted cost, SC5 working preview) is not delivered: the single hosted candidate run was red on a concrete, fixable defect and plan 178-10 never ran. SUMMARY claims were re-checked against code and read-only `gh` queries; the 178-09/178-10 SUMMARY accounts are accurate.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Restore defaults is an aligned secondary action; useful parsing/validation/read-only guidance without repetitive helpers; reset/rendering behavior retained (PRVUX-05, PRVUX-06) | VERIFIED | `assigns_form.ex:73` single form-level `preview-assigns-readonly-note`, `:88-90` `phx-click="reset_assigns"` "Restore defaults". `preview_live_test.exs` and `voice_test.exs` pass (191 tests, 0 failures, seed 0). Review: `reset_assigns`/`preview_live.ex` byte-identical to phase base. |
| 2 | Readable scenario identity: module secondary, exact technical identity accessible, duplicate humanized labels disambiguated at long/Unicode and narrow widths (PRVUX-07) | VERIFIED | `scenario_label.ex` exists and is wired (`sidebar.ex:27,101`, `ScenarioLabel.build/1`). `scenario_label_test.exs` (24 tests) plus `preview_live_test.exs` selector cases and retained stories pass. 320/390 px browser cases are recorded in the local operator gate (311 executed). |
| 3 | Every named feedback item has disposition, owning requirement, retained scenario and behavior evidence; stories cover pattern/area/job incl. Delivery path; no missing/failed/zero-case hidden as success (STORY-07, UIQ-04) | VERIFIED | `feedback_ledger_test.exs`, `quick_view_projection_test.exs` ("accounting", projection agreement) and `phase178_prohibition_contract_test.exs` all pass in the 191-test run; the admin lane is full `mix test` (`verify.support_contract.admin` = `test --warnings-as-errors`), so these are merge-blocking. 12/12 rows accounted; Filters is explicitly connected-only; 2 unrendered linked scenarios counted. Hosted `Support Contract Admin` job is success on the candidate. |
| 4 | Receipts + connected checks reproduce light/dark, widths, keyboard/focus, real zoom, reduced motion; cold/warm setup-inclusive wall time and runner cost measured vs budgets with counts and placement (UIQ-06, UIQ-07) | FAILED | Hosted measurement absent: no `178-COST-DISPOSITION.json`; Demo Browser Evidence red in both runs. Local receipts exist (UIQ-06 partial). See gaps. |
| 5 | Owner can inspect repaired milestone in a documented working preview tied to a source/candidate, current assets, committed changes, passing required CI; temporary services have dispositions (UIQ-08) | FAILED | `178-DELIVERY.md` and runbook absent; 178-10 not run. Required contexts green but runs conclude failure. See gaps. |

**Score:** 3/5 truths verified (0 present, behavior-unverified)

### Hosted claims re-verified (read-only `gh`)

| Claim | Result |
|-------|--------|
| Dispatch run 40904249445 headSha = 2bdf1816...; conclusion failure | Confirmed. CI Green success; every job success except Demo Browser Evidence (failure). |
| PR run 40904235961 same SHA, failure | Confirmed. Failures: Demo Browser Evidence and Operator Browser Gate. |
| Demo failure cause | Confirmed: failed log shows `Cannot find module '@playwright/test'`, `MODULE_NOT_FOUND`. `ci.yml:1059` lists `mailglass_admin/e2e/support/storybook-axe.test.cjs`; `storybook-axe-supplement.cjs:1` requires `@playwright/test`; introduced by Phase 175 commit a65a670d. |
| PR 317 still draft/open/unmerged | Confirmed (`isDraft true`, `OPEN`, `mergedAt null`). |
| Candidate is ancestor of HEAD | Confirmed. |
| Cost disposition artifact | Absent, as claimed. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `preview/assigns_form.ex` | Restore defaults + note | VERIFIED | Substantive, wired to live route |
| `preview/scenario_label.ex` | Pure label/collision table | VERIFIED | Used by `sidebar.ex` |
| `test/support/feedback_ledger.ex` and ledger tests | UIQ-04 rule | VERIFIED | Tests pass, in default admin lane |
| `phase178_prohibition_contract_test.exs` | D-15 contract | VERIFIED | Passes |
| `e2e/phase178-real-zoom.spec.js` | Real zoom | VERIFIED locally | Advisory lane; hosted dispatch Operator Browser Gate success |
| `scripts/check_phase178_candidate.sh`, `phase178_cost_disposition.cjs` | Tooling | VERIFIED (tooling) | Never produced a hosted disposition |
| `178-COST-DISPOSITION.json` | Hosted cost record | MISSING | Not produced |
| `178-DELIVERY.md` | Working-preview runbook | MISSING | 178-10 not run |

### Requirements Coverage

| Requirement | Source | Status | Evidence |
|-------------|--------|--------|----------|
| PRVUX-05 | 178-01 | SATISFIED | Truth 1 |
| PRVUX-06 | 178-01 | SATISFIED | Truth 1 |
| PRVUX-07 | 178-04 | SATISFIED | Truth 2 |
| STORY-07 | 178-05/07/11 | SATISFIED | Truth 3 |
| UIQ-04 | 178-02/05/07/11 | SATISFIED | Truth 3 |
| UIQ-06 | 178-06/07 | PARTIAL (REQUIREMENTS.md: Pending) | Local receipts only; hosted Demo lane never ran |
| UIQ-07 | 178-03/08/09 | BLOCKED (Pending) | No hosted cost disposition |
| UIQ-08 | 178-08/09/10/12 | BLOCKED (Pending) | 178-10 not run; hosted runs red |

All 8 phase requirement IDs appear in plan frontmatter and REQUIREMENTS.md; no orphans. REQUIREMENTS.md checkbox and traceability state matches these findings.

### Anti-Patterns / Behavioral Spot-Checks

- Ran the targeted admin suite (preview_live, voice, scenario_label, quick_view_projection, feedback_ledger, phase178 prohibition): 191 tests, 0 failures, 1 excluded, seed 0.
- No debt markers or stubs found in the Preview lib files reviewed. Code review (178-REVIEW.md): 3 warnings fixed, 1 info rejected with reason, 0 open.
- Blocker (workflow/test wiring): `ci.yml:1059` step runs a test whose dependency the job does not install.
- Local-only red: core `test/scripts/phase_164_repository_truth_test.exs:261`, caused by the owner's untracked, globally ignored `.gsd/.gitignore` (the file exists and matches `*`). Not a phase 178 defect and not counted.

### Human Verification Required

None. Per D-52, every open item is machine-observable (a hosted run result, a cost JSON, a launched preview with URL checks). The only owner step in scope, the ship/no-ship checkpoint in plan 178-10, is a permitted hand-off and is gated behind the fix; it is not a human_needed row today.

### Gaps Summary

Product work is done and sound; the milestone-review evidence is not. One root cause blocks UIQ-06 hosted reproduction, UIQ-07 and UIQ-08: the Demo Browser Evidence job fails before capturing anything because `storybook-axe.test.cjs` (via `storybook-axe-supplement.cjs`) needs `@playwright/test`, which the root Demo job does not install. Fixing it requires a source/workflow change, a new candidate freeze, and a new owner-approved push and dispatch (draft PR #317 can carry it), then 178-10. Also classify the PR-run-only Operator Browser Gate failure at `flows.spec.js:2453`. Plan with `/gsd-plan-phase 178 --gaps`.

---

_Verified: 2026-10-29_
_Verifier: Claude (gsd-verifier)_
