---
phase: 144-signal-drift-integrity
plan: 01
subsystem: ci-integrity
tags: [github-actions, branch-protection, bash, exunit, hermetic-integration]
requires:
  - phase: 141-lane-truth-foundation
    provides: publish-gating lane classification and CI lane contract seam
provides:
  - Shared truthful clean/drift/cannot-check branch-protection outcome seam
  - Scheduled verify-before-reassert workflow with sticky drift reporting
  - Hermetic fake-gh integration evidence for branch-protection workflows
affects: [branch-protection, ci, scheduled-workflows, publish-gating]
tech-stack:
  added: []
  patterns: [shared shell outcome seam, hermetic external-CLI integration harness]
key-files:
  created: [scripts/branch-protection-outcome.sh]
  modified: [.github/workflows/ci.yml, .github/workflows/branch-protection-drift.yml, test/scripts/branch_protection_truth_test.exs, test/scripts/required_checks_test.exs]
key-decisions:
  - "Use a repository-internal shared outcome script so advisory and scheduled workflows report identical closed states."
  - "Keep observed drift sticky after scheduled reassertion; repair cannot erase the initial comparison result."
  - "Replace the tracer's manual approval with permanent hermetic E2E evidence using the real scripts and a fake gh executable."
patterns-established:
  - "GitHub API workflow behavior is verified through real scripts with per-process fake CLI binaries and no global environment mutation."
requirements-completed: [TRUTH-02, TRUTH-03]
coverage:
  - id: D1
    description: "Branch-protection outcomes distinguish clean, drift, and cannot-check and only clean is green."
    requirement: TRUTH-02
    verification:
      - kind: integration
        ref: "mix test test/scripts/branch_protection_truth_test.exs test/scripts/required_checks_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Scheduled owner workflow verifies before canonical reassertion and keeps observed drift non-green."
    requirement: TRUTH-03
    verification:
      - kind: e2e
        ref: "test/scripts/branch_protection_truth_test.exs#scheduled reassertion verifies with GET before PUT and keeps observed drift sticky"
        status: pass
    human_judgment: false
  - id: D3
    description: "Required protection context is parsed from Guard Release Trigger's display name, not its YAML id."
    requirement: TRUTH-03
    verification:
      - kind: integration
        ref: "test/scripts/required_checks_test.exs#required check identity derives from Guard Release Trigger's parsed display name"
        status: pass
    human_judgment: false
metrics:
  duration: 28min
  completed: 2026-07-31
  status: complete
---

# Phase 144 Plan 01: Honest Branch-Protection Outcomes Summary

**Shared shell outcome handling makes both branch-protection workflows fail honestly and proves their real verify/reassert path hermetically.**

## Performance

- **Duration:** 28 min
- **Completed:** 2026-07-31T20:49:32Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Made the Branch Protection Advisory publish-gating job visibly fail for drift, unavailable verification, and unknown results while preserving its exclusion from `ci_green.needs`.
- Added the shared `branch-protection-outcome.sh` seam, which invokes the canonical verifier and retains the original drift classification after scheduled reassertion.
- Added hermetic integration coverage that runs real outcome/setup/verify scripts against a temporary fake `gh`, including API and tooling failure paths, GET-before-PUT ordering, and exact required-context identity.

## Task Commits

1. **Task 1: Prove one honest Branch Protection Advisory path end to end** — `b4335f7c` (`feat`)
2. **Task 2: Extend the honest outcome and identity contract to the scheduled owner workflow** — `86b0349e` (`feat`)

## Files Created/Modified

- `scripts/branch-protection-outcome.sh` — shared closed-outcome probe and reporter for the two workflows.
- `.github/workflows/ci.yml` — Branch Protection Advisory delegates to the shared seam and retains its authoritative `if: always()` reporter.
- `.github/workflows/branch-protection-drift.yml` — scheduled owner workflow probes before reasserting and reports the observed result authoritatively.
- `test/scripts/branch_protection_truth_test.exs` — hermetic real-script integration matrix with fake `gh` and anti-vacuity source checks.
- `test/scripts/required_checks_test.exs` — parsed display-name identity contract and historical-id negative control.

## Decisions Made

- The common shell seam is repository-internal and adds no public API, dependency, workflow, or desired-state registry.
- The permanent CI gate replaces human verification: `mix verify.ci_lane_contract` discovers the script contracts through its `test/scripts` directory scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Added hermetic workflow E2E evidence and shared outcome seam**
- **Found during:** Task 2
- **Issue:** The original tracer source-contract check could not prove actual verifier, reassertion, external CLI failure, or report behavior without manual approval.
- **Fix:** Added a repository-internal outcome script and a temporary fake-`gh` integration harness that executes the real verify/setup/outcome scripts with real `jq`.
- **Files modified:** `scripts/branch-protection-outcome.sh`, both workflows, and both contract tests.
- **Verification:** Focused 14-test integration matrix and `mix verify.ci_lane_contract` (122 tests) passed.
- **Committed in:** `86b0349e`

**Total deviations:** 1 auto-fixed (Rule 2, user-approved).

## Issues Encountered

None after the RED→GREEN→REFACTOR integration cycle.

## User Setup Required

None — the permanent gate is hermetic and requires no credentials or live GitHub mutation.

## Next Phase Readiness

The branch-protection truth seam is available for subsequent Phase 144 work; no human UAT artifact or manual verification remains for this plan.

## Self-Check: PASSED

- Found `scripts/branch-protection-outcome.sh`.
- Found task commits `b4335f7c` and `86b0349e` in git history.
