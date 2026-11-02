---
phase: 178-preview-authoring-and-milestone-review
plan: "15"
subsystem: testing
tags: [Playwright, Mix, CI, Storybook, Demo]

requires:
  - phase: 178-13
    provides: The CI node-test dependency guard and recorded advisory-run disposition.
  - phase: 178-14
    provides: The classified PR-run Operator result and self-diagnosing focus checks.
provides:
  - A fresh local re-gate of every lane affected by plans 178-13 and 178-14.
  - Unit-matched browser expectations and a cold/warm Demo pilot bound to one gate SHA.
  - A re-frozen candidate with both remote refs as ancestors, ready for a new owner checkpoint.
affects: [178-16, 178-17, 178-18, 178-19]

actuals:
  tokens: 6456
  tasks: 3
  commits: 14

tech-stack:
  added: []
  patterns:
    - Saved gate logs start with the tested commit and end with the command exit code.
    - Operator summary counts and Demo pilot receipt counts are compared in their declared units.
key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-15-SUMMARY.md
  modified:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md
    - .planning/phases/178-preview-authoring-and-milestone-review/178-VALIDATION.md
    - .planning/phases/178-preview-authoring-and-milestone-review/178-REVIEW-DISPOSITION.md
    - reference/demo_app/mix.lock
    - mailglass_admin/test/scripts/ci_node_test_requires_contract_test.exs
    - mailglass_admin/test/mailglass_admin/browser_server_readiness_test.exs
    - mailglass_admin/test/support/endpoint_case.ex
    - mailglass_admin/test/support/operator_browser_server.ex
    - reference/demo_app/assets/e2e/quick-views.spec.js
key-decisions:
  - Refresh only the named Demo dependency: phoenix_html 4.3.0 to 4.4.0.
  - Keep the single documented local-only Phase 164 repository-truth failure as an explicit exception; do not alter its contract.
  - Leave hosted-dependent acceptance rows pending until a new owner-approved hosted run verifies the re-frozen candidate.
patterns-established:
  - Fixture-owned synchronization markers live inside the disposable fixture root so parallel tests cannot mutate shared repository state.
  - Hosted cost expectations use the same execution unit as the local Operator summary or Demo pilot receipt.
requirements-completed: [UIQ-06, UIQ-07, UIQ-08]

coverage:
  - id: D1
    description: Every affected local lane was re-gated on one committed SHA, with the only known local-only failure identified by exact test.
    requirement: UIQ-08
    verification:
      - kind: integration
        ref: reference/demo_app/tmp/phase178_candidate/rerun-gate/*.log; 178-AUTOMATION.md re-gate table
        status: pass
    human_judgment: false
  - id: D2
    description: Cold and warm Demo pilot receipts are bound to the gate SHA and both Phase 178 story specs pass.
    requirement: UIQ-06
    verification:
      - kind: automated_ui
        ref: reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101214833-39818-11964/phase174/{cold,warm}/playwright-report.json and execution.json
        status: pass
    human_judgment: false
  - id: D3
    description: Expected and executed Operator and Demo counts match in their declared units.
    requirement: UIQ-07
    verification:
      - kind: integration
        ref: scripts/phase178_cost_disposition.cjs counts against rerun-gate/operator-suite.log, phase174/cost.json and rerun-disposition-inputs/expected.json
        status: pass
    human_judgment: false
  - id: D4
    description: The recorded candidate is a plain fast-forward from both remote refs and has no source changes after the gate.
    requirement: UIQ-08
    verification:
      - kind: other
        ref: 178-15 task 3 verify; rerun_candidate_sha in 178-AUTOMATION.md
        status: pass
    human_judgment: false

duration: 112min
completed: 2026-11-01
status: complete
plan_base_sha: bd85b98f73408aec30e891f394a2414c320a9f04
plan_head_before: bd85b98f73408aec30e891f394a2414c320a9f04
plan_head_after: ab0808fa8f5851e6fdbd9f0d8c5c190bcd7d459a
rerun_candidate_sha: 255422cbe6e16c570ccb465246c2394fa3190866
---

# Phase 178 Plan 15: Re-gate and Re-freeze Summary

**The fixed UIQ candidate passed its affected local gates and is frozen at a new SHA for the next owner checkpoint.**

## Performance

- **Duration:** 1h 52m
- **Started:** 2026-11-01T20:12:45Z
- **Completed:** 2026-11-01T22:04:34Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Re-ran all affected candidate lanes on gate head baf5685e1a9b943d41b884b007fdea5fa45fa498. Fixed review and gate findings in isolated commits, including the browser readiness fixture race, a bounded immutable-loader test timeout, screenshot capture stability, Credo parser nesting, and workspace-evidence fixture cleanup.
- Ran a fresh cold and warm Demo pilot. Both Phase 178 story receipts passed in both reports, Phase 174/175 checkers passed, and the pilot source revision matched the gate head.
- Compared expected and executed counts in the same units: Operator was 310 passed plus one named guarded skip, with no failures or flakes; each Demo condition was 111 Demo, 6 hooks, 26 fidelity and 26 axe checks, totaling 169.
- Repointed the acceptance closure and validation records at the gap-plan verifies. The three hosted-dependent rows remain pending.
- Froze candidate 255422cbe6e16c570ccb465246c2394fa3190866 after the gate, with no source changes between the gate and candidate.

## Re-gate Results

| Gate | Result |
|---|---|
| Gate integrity | Pass; no protected-path diff from the phase base. |
| Node lists, CI monitor, candidate self-test | Pass: 63 + 5 + 11 checks; CI monitor 5/5. |
| CI require-guard contract | Pass: 4 tests, 0 failures. |
| CI lane contract | 511 total; one documented local-only failure at phase_164_repository_truth_test.exs:261, 31 excluded. This is the only accepted local red. |
| Format and strict Credo | Pass; 81 checks and 565 files, no Credo issues. |
| Admin suite | Pass: 1205 tests, 0 failures, 1 excluded. |
| Operator Browser Gate | 310 passed, one named guarded skip, 0 failed, 0 flaky; 311 tests listed. Projected hosted time is 1203 seconds, within the 1440-second margin. |
| Demo list and lock | 111 tests listed; locked dependencies match after the named phoenix_html refresh. Known cowlib advisory only. |
| Demo cold/warm pilot | Pass: 169 expected and executed checks per condition, both pilot checkers pass, both Phase 178 story receipts are ok. |
| Unaffected CI lanes | Compile, inbound, installer, Dialyzer, trust and design-conformance input scopes had no changed paths. |

Saved reporter output for each gate is under reference/demo_app/tmp/phase178_candidate/rerun-gate/; each log is headed by the gate SHA and records its exit status. The expected-count file declares the Operator Playwright summary unit and Demo pilot receipt unit separately. Demo list count 111 is not compared to receipt total 169.

## Candidate Freeze

- **Gate head:** baf5685e1a9b943d41b884b007fdea5fa45fa498
- **Frozen candidate:** 255422cbe6e16c570ccb465246c2394fa3190866, subject: docs(178-15): point acceptance closure at gap plans.
- Both origin/main (8328093e4a07d28251ec7f02dd0f37cda2fd6a7b) and origin/gsd/v2.10-ui-repairs-storybook (2bdf18161182beeb286435b556f26e205976e658) are ancestors of the candidate. The candidate is 396 commits ahead of main and 45 ahead of the branch.
- The remote branch still equals its pre-freeze SHA; the read-only workflow check found no run newer than 40904249445. No remote write was made.
- The post-candidate freeze record is ab0808fa8f5851e6fdbd9f0d8c5c190bcd7d459a and contains planning records only.

## Task Commits

1. **Task 1: Re-gate, gap review and fixes** — 12 commits: f90c37e6, 06bf61f3, 397c8391, 5ed3906a, 1cc410df, 0bf53dd4, ad10d639, 9b716fbb, 5d625006, 9929cea2, ea1e09b1, baf5685e.
2. **Task 2: Update acceptance closure and validation** — 255422cb.
3. **Task 3: Freeze candidate and prove fast-forward ancestry** — ab0808fa.

## Decisions Made

The lock update was limited to phoenix_html 4.3.0 to 4.4.0, as named by the locked-dependency check. The one local-only Phase 164 failure remains documented rather than changing an unrelated repository-truth rule. Hosted evidence stays pending until a new approval and hosted verification cover the exact candidate.

## Deviations from Plan

The re-gate exposed two additional test-harness issues: Credo rejected the test parser nesting, and workspace-evidence cleanup could race through a shared sync marker. Both were fixed and reviewed before the gate head was recorded. The test runner documented Phase 164 local-only failure remained the sole exception.

## Issues Encountered

The CI lane contract returned its expected local-only Phase 164 failure. Its repository-specific .gsd/.gitignore mismatch is not present in hosted CI; the recorded evidence confirms this exact case is the sole failure. No other lane failed in the final gate.

## User Setup Required

None.

## Next Phase Readiness

Plan 178-16 must refresh the live refs, scope and runbook URLs before presenting a new owner checkpoint. The user is the next decision-maker at that checkpoint. Approve-all permits the candidate fast-forward push, draft PR #317 body update and one CI dispatch; approve-push-and-pr-only omits the dispatch and does not bind hosted evidence to the candidate; decline makes no remote change. No rerun or merge is included.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-11-01*
