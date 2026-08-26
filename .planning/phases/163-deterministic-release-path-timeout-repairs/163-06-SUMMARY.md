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
  - Freeze f8bf029f as the final code-only repair SHA after three protected recurrence diagnoses and obtain successor evidence through a normal PR trigger.
requirements-completed: []
completed: 2026-08-26
status: complete
---

# Phase 163 Plan 06: Local Integration Summary

**Both complete release-path gates passed first attempt, and the code-only implementation is frozen at `f8bf029faf87d8dda0ef1a36fe6ebbe6e2ab60d6` with exact protected PR evidence.**

## Local integration

| Lane | Exact command | Result |
| --- | --- | --- |
| Deterministic core | `mix test --warnings-as-errors` | 23 properties, 1,964 tests, 0 failures, 7 intentional skips; 174.7s |
| Operator browser | `CI=true npm run test:operator-browser` | 176 passed, 1 intentional skip; 3.7m after the final protected recurrence repair; no retry |

The final browser run reached readiness in 230ms, passed the repaired 117-cell body in 45.6s, and passed the two last repaired structural bodies in 11.4s and 8.9s. Their exact focused command passed first attempt in 23.6s. The workflow contract, `actionlint`, evidence recorders/reporters, and all phase-owned formatter checks passed.

## Automated protected handoff

Commits `9b1a7c0c`, `7b51ba44`, `5d125ad2`, `cf91502b`, and `d27de4b6` add `scripts/ci_monitor.cjs` and five Node contract tests, then roll those tests into the existing Node-enabled operator-browser job. The wrapper exposes workflow state, bounded `runs`, exact-run `inspect`, PR identity/check inspection, policy-safe title repair, `watch`/`fail-fast`, failed/job logs, artifact listing/download, and file-backed PR creation; it never dispatches, merges, or releases.

Three normally triggered protected runs published safe evidence for browser recurrences. Commits `e8c6260f`, `9d0bcacf`, and `f8bf029f` repair only the exact owners. The normally triggered exact-code successor `33002642359` passed both named release-path jobs; DTRM-02 and DTRM-04 are complete.

---
*Plan status: local integration complete; protected evidence reconciled by Plans 07–08*
