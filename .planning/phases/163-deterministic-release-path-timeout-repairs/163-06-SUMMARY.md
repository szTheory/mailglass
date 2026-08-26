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
  - Freeze cf91502b as the code-only repair SHA and obtain protected evidence through a normal PR trigger.
requirements-completed: []
completed: 2026-08-26
status: complete
---

# Phase 163 Plan 06: Local Integration Summary

**Both unchanged complete release-path gates passed first attempt, and the code-only implementation is frozen at `cf91502b282af884a7d12877977e1258a2b2ec94` for protected PR evidence.**

## Local integration

| Lane | Exact command | Result |
| --- | --- | --- |
| Deterministic core | `mix test --warnings-as-errors` | 23 properties, 1,964 tests, 0 failures, 7 intentional skips; 174.7s |
| Operator browser | `CI=true npm run test:operator-browser` | 176 passed, 1 intentional skip; 3.3m; no retry |

The browser run reached readiness in 204ms, passed the repaired 117-cell body in 37,344ms, and passed its sibling in 3,041ms. The workflow contract, `actionlint`, evidence recorders/reporters, and all phase-owned formatter checks passed.

## Automated protected handoff

Commits `9b1a7c0c`, `7b51ba44`, `5d125ad2`, and `cf91502b` add `scripts/ci_monitor.cjs` and five Node contract tests, then roll those tests into the existing Node-enabled operator-browser job. The wrapper exposes workflow state, bounded `runs`, exact-run `inspect`, PR identity/check inspection, policy-safe title repair, `watch`/`fail-fast`, failed logs, and file-backed PR creation; it never dispatches, merges, or releases.

Branch `phase-163-deterministic-timeout-repairs` was pushed and PR #228 opened through that observable path. DTRM-02 and DTRM-04 remain pending only until their normally triggered exact-SHA jobs are terminal and successful.

---
*Plan status: local integration complete; protected evidence delegated to CI*
