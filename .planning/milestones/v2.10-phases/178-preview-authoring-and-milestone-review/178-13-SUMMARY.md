---
phase: 178-preview-authoring-and-milestone-review
plan: "13"
subsystem: testing
tags: [node, Playwright, ExUnit, CI, cost-disposition]

requires: []
provides:
  - CI node --test package-resolution contract and lazy Playwright loading for the Storybook supplement
  - Playwright summary parsing that avoids duplicate GitHub notice counts
  - Recorded-advisory input for measuring an Operator Browser Gate failure safely
affects: [178-14, 178-15, 178-17]

actuals:
  tokens: 8023
  tasks: 4
  commits: 7

tech-stack:
  added: []
  patterns:
    - Guard CI node --test loads against the package roots installed earlier in that job
    - Preserve local summary parsing while filtering untimestamped continuation lines in timestamped logs
    - Require a recorded run-and-job match before measuring an advisory Operator failure

key-files:
  created:
    - test_js/support/ci-require-guard.cjs
    - test/scripts/ci_node_test_requires_contract_test.exs
  modified:
    - mailglass_admin/e2e/support/storybook-axe-supplement.cjs
    - scripts/phase178_cost_disposition.cjs
    - scripts/phase178_cost_disposition.test.cjs

key-decisions:
  - Move the Playwright require into verifyStoryAccessibility so pure Storybook evidence helpers load without an install.
  - Ignore untimestamped continuation lines only when parsing a timestamped GitHub Actions log.
  - Measure a failed Operator Browser Gate only when an advisory record matches its measured run ID and exact job name.

requirements-completed: ["UIQ-06", "UIQ-07", "UIQ-08"]

coverage:
  - id: D1
    description: "The Demo Storybook evidence test loads without locally installed Playwright, and CI node --test entry files are checked against their job install roots."
    requirement: "UIQ-08"
    verification:
      - kind: unit
        ref: "test/scripts/ci_node_test_requires_contract_test.exs: 4 tests, 0 failures"
        status: pass
      - kind: unit
        ref: "node --test mailglass_admin/e2e/support/storybook-axe.test.cjs: 24 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Timestamped hosted Operator summary lines are counted once, and untimestamped local summaries retain their existing behavior."
    requirement: "UIQ-07"
    verification:
      - kind: unit
        ref: "scripts/phase178_cost_disposition.test.cjs: GitHub notice continuation and untimestamped summary cases"
        status: pass
      - kind: integration
        ref: "saved run 40904235961 operator-gate.log: counts command reports 309 passed, 1 skipped, 1 failed, 0 flaky; 3 summary lines; mismatch false"
        status: pass
    human_judgment: false
  - id: D3
    description: "The disposition measures a failed Operator job only with a matching recorded advisory red and keeps every other required success check."
    requirement: "UIQ-07"
    verification:
      - kind: unit
        ref: "node --test scripts/phase178_cost_disposition.test.cjs: 17 tests, 0 failures"
        status: pass
      - kind: unit
        ref: "node --test --test-reporter=tap --test-name-pattern='advisory red' scripts/phase178_cost_disposition.test.cjs: 4 tests, 0 failures"
        status: pass
      - kind: other
        ref: "CLI fixture: advisory-red file SHA-256 is recorded, output is reproducible, and an unmatched red exits 1 with ERROR"
        status: pass
    human_judgment: false

duration: 29min
completed: 2026-11-01
status: complete
plan_base_sha: d9620e49e8bf2e9adb424ca92b80d8746a4108be
plan_head_before: d9620e49e8bf2e9adb424ca92b80d8746a4108be
plan_head_after: befeb47e
---

# Phase 178 Plan 13: Hosted Evidence and Cost Disposition Summary

**The Demo Storybook evidence step now loads without a local Playwright install, hosted Operator counts are no longer doubled, and advisory Operator failures are measured only from an exact recorded match.**

## Performance

- **Duration:** about 29 minutes
- **Started:** 2026-11-01T19:15:31Z
- **Completed:** 2026-11-01T19:44:55Z
- **Tasks:** 4
- **Files modified:** 5

## Accomplishments

- Added a preload guard and ExUnit contract test that parses every CI `node --test` step, models earlier npm install roots per job, and records every loaded test file. Moved the `@playwright/test` require into `verifyStoryAccessibility`; the workflow and test lane remain unchanged.
- Fixed hosted count parsing to accept only timestamped summary lines when a log has GitHub timestamps. Untimestamped local logs retain their existing behavior.
- Added `disposition --advisory-reds <file>`. A completed Operator Browser Gate failure is measured only when a recorded line matches that run ID and exact job name. The output records its conclusion, matched titles, source keys and hashes; Demo, Support and CI Green still require success.

## Task Commits

1. **178-13-01: Reproduce and fix the hosted Playwright module-load failure** — `71122b66` (RED), `92704fc2` (GREEN)
2. **178-13-02: Prove the require guard with hermetic fixtures** — `534a6898`
3. **178-13-03: Count hosted Operator summaries once** — `b2102ced` (RED), `a6a136e0` (GREEN)
4. **178-13-04: Measure a recorded advisory Operator red** — `33e485a5` (RED), `befeb47e` (GREEN)

## RED and GREEN evidence

The require-guard RED run named the affected job, test, package and requiring file:

> job demo_browser_evidence, step Test Storybook evidence and review contracts, file mailglass_admin/e2e/support/storybook-axe.test.cjs
>
> Cannot find module '@playwright/test' required by storybook-axe-supplement.cjs: not installed by this CI job

That evidence is saved in `reference/demo_app/tmp/phase178_candidate/gap13-red.log`. After the lazy require, the contract test passed; the Storybook axe suite passed all 24 tests. The contract suite also passed all three hermetic require cases: disallowed top-level load rejects, allowed-root load passes, and an uncalled lazy require passes.

Before the count fix, the synthetic GitHub notice case reported 618 passed and 2 skipped instead of 309 and 1. The RED log is `reference/demo_app/tmp/phase178_candidate/gap13-counts-red.log`. The final disposition test file passed 17 tests. The saved hosted PR log for run 40904235961 now reports 309 passed, 1 skipped, 1 failed, 0 flaky across 3 summary lines, with no mismatch.

The advisory-red RED run failed all four new cases, including measurement, refusal conditions, required-job protections, and CLI input handling. The excerpt is saved in `reference/demo_app/tmp/phase178_candidate/gap13-advisory-red.log`. GREEN passed all 17 tests, including all 4 tests selected by the `advisory red` name pattern. The CLI fixture verified the input hash, reproducible output, empty-file handling, line-numbered malformed-input errors, and exit status 1 for an unmatched red.

## Lane results

| Check | Result |
|---|---|
| ExUnit require contract | 4 tests, 0 failures |
| Root formatter and strict Credo | Both passed |
| CI unguarded node lists | 57 tests passed; CI monitor list 5 tests passed |
| Cost disposition node tests | 17 tests, 0 failures |
| `mix verify.ci_lane_contract --timeout 120000` | 511 tests, 1 failure, 31 excluded; the sole failure is `test/scripts/phase_164_repository_truth_test.exs:261` |

The sole lane failure is the known local-only `.gsd/.gitignore` artifact: the untracked local ignore file makes `.gsd/extensions/finalize-phase/index.ts` appear ignored, while `.gsd` is absent from tracked files. The evidence and four proofs are recorded in [178-12-SUMMARY.md](./178-12-SUMMARY.md). The original 60-second per-test timeout was too short under suite load; the isolated Phase 164 case took 56.7 seconds. The bounded 120-second retry completed with only the known local-only failure. No test assertion or timeout configuration was changed. Full lane output is in `reference/demo_app/tmp/phase178_candidate/ci-lane-contract-bounded.log`.

## Files Created/Modified

- `test_js/support/ci-require-guard.cjs` — rejects bare package resolution outside the job's allowed install roots and records loaded entry files.
- `test/scripts/ci_node_test_requires_contract_test.exs` — CI workflow parsing and hermetic guard contract.
- `mailglass_admin/e2e/support/storybook-axe-supplement.cjs` — lazy Playwright require inside the only helper that uses it.
- `scripts/phase178_cost_disposition.cjs` — single-count timestamp handling and recorded advisory-red input.
- `scripts/phase178_cost_disposition.test.cjs` — RED/GREEN parser and advisory-red coverage.

## Decisions Made

- Chose the lazy require over adding an `npm ci` to Demo Browser Evidence or moving the test to Operator Browser Gate. An install would add time to the measured job and tie it to another lockfile; moving the test would separate the Storybook evidence contract from the lane that guards it. The source-level lazy require preserves both job cost and lane placement.
- Kept untimestamped local summary parsing unchanged. In timestamped GitHub logs, untimestamped continuation lines repeat the reporter's summary and are skipped.
- Required a line from 178-17 to match both the measured run ID and exact Operator Browser Gate job. Other jobs and unmatched or non-failure Operator conclusions retain the existing failure behavior.

## Deviations from Plan

1. The repository lane needed a bounded 120-second per-test timeout for its existing 56.7-second Phase 164 case under suite load. The code and test timeout settings were not changed.
2. The plan requested a Claude co-author trailer, but this repo is configured to use the Codex runtime. No Claude attribution was added to Codex-authored commits.

**Impact:** no product or gate scope changed. The bounded retry still reports the one previously established local-only Phase 164 failure.

## Issues Encountered

- An initial test assertion assumed an advisory line for run 200 would be validated without measuring that run. The fixture was corrected to include the dispatch run, matching the plan's measured-run contract; the implementation was unchanged.

## User Setup Required

None.

## Next Phase Readiness

Plan 178-13 is complete and plan 178-14 is next in dependency order. UIQ-06, UIQ-07 and UIQ-08 remain shared requirements across the remaining gap plans, so they were not marked complete here.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-11-01*
