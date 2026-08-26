---
phase: 163-deterministic-release-path-timeout-repairs
plan: 06
subsystem: integration
tags: [deterministic-core, operator-browser, exact-sha, ci-monitor]
provides:
  - Complete first-attempt local integration proof for both protected lanes.
  - Observable repository-local tooling for exact-run protected reconciliation.
key-files:
  created:
    - scripts/ci_monitor.cjs
    - test_js/ci-monitor.test.cjs
  modified:
    - .github/workflows/ci.yml
key-decisions:
  - Freeze 9d0bcacf as the code-only repair SHA after two protected recurrence diagnoses and obtain successor evidence through a normal PR trigger.
requirements-completed: []
completed: 2026-08-26
status: complete
---

# Phase 163 Plan 06: Local Integration Summary

**Both complete release-path gates passed first attempt, and the code-only implementation is frozen at `9d0bcacf875ad0c88155bd16bad2996c1c57b926` for successor protected PR evidence.**

## Local integration

| Lane | Exact command | Result |
| --- | --- | --- |
| Deterministic core | `mix test --warnings-as-errors` | 23 properties, 1,964 tests, 0 failures, 7 intentional skips; 174.7s |
| Operator browser | `CI=true npm run test:operator-browser` | 176 passed, 1 intentional skip; 3.8m after the final protected recurrence repair; no retry |

The final browser run reached readiness in 240ms, passed the repaired 117-cell body in 47.8s, and passed the primitive matrix in 14.4s. The exact repaired gallery and two structural bodies also passed together first attempt. The workflow contract, `actionlint`, evidence recorders/reporters, and all phase-owned formatter checks passed.

## Automated protected handoff

Commits `9b1a7c0c`, `7b51ba44`, `5d125ad2`, `cf91502b`, and `d27de4b6` add `scripts/ci_monitor.cjs` and five Node contract tests, then roll those tests into the existing Node-enabled operator-browser job. The wrapper exposes workflow state, bounded `runs`, exact-run `inspect`, PR identity/check inspection, policy-safe title repair, `watch`/`fail-fast`, failed/job logs, artifact listing/download, and file-backed PR creation; it never dispatches, merges, or releases.

Two normally triggered protected runs published safe evidence for the browser recurrences. Commits `e8c6260f` and `9d0bcacf` repair only the exact owners. Their normally triggered successor `32998989827` passed both named release-path jobs; DTRM-02 and DTRM-04 are complete.

---
*Plan status: local integration complete; protected evidence reconciled by Plans 07–08*
