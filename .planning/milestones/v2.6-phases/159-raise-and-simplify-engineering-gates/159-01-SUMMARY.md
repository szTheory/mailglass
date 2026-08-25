---
phase: 159-raise-and-simplify-engineering-gates
plan: 01
subsystem: ci-policy
tags: [ci-green, fail-closed, policy-manifest, quality-gates]
requires: []
provides:
  - Strict active/target/advisory CI lane policy tracer
  - Exact active-evidence validation for the CI Green evaluator
  - Adversarial omission and advisory-promotion contract controls
affects: [159-02, 159-06]
tech-stack:
  added: []
  patterns: [policy-as-data, exact-set-validation, fail-closed-aggregate]
key-files:
  created:
    - config/quality/ci_policy.exs
    - test/support/ci_policy.ex
  modified:
    - scripts/ci_green_policy.sh
    - test/scripts/ci_green_policy_test.exs
    - test/scripts/required_checks_test.exs
    - test/scripts/lane_classification_drift_test.exs
key-decisions:
  - "The policy records the active protected leaf set separately from the complete target and advisory sets; no CI workflow topology changed."
  - "The shell evaluator loads active/advisory IDs from the checked-in policy, avoiding a second authoritative lane list."
patterns-established:
  - "Policy identity tests use explicit omission and advisory-promotion fixtures."
  - "CI Green requires every active leaf exactly once and rejects unknown or advisory evidence."
requirements-completed: [QUAL-03, QUAL-04, QUAL-10]
duration: 0m
completed: 2026-08-17
---

# Phase 159 Plan 01: CI Policy Tracer Summary

**Strict current/target/advisory policy data now makes the existing CI Green aggregate reject false evidence without changing workflow topology or public check identities.**

## Tasks Completed

### Task 1: Strict current/target/advisory policy manifest

- Added `config/quality/ci_policy.exs` with the eight current required leaf IDs, the complete target QUAL-03 behavior inventory, and explicitly advisory IDs.
- Added `Mailglass.CIPolicy`, which validates snake-case IDs, uniqueness, active-to-target inclusion, required behavior completeness, and required/advisory disjointness.
- Added negative controls proving that removing `:docs` and promoting an advisory lane makes policy validation fail.

Commit: `95d5f0ea test(159-01): add strict CI lane policy tracer`

### Task 2: Hardened fail-closed evidence protocol

- CI Green now loads active/advisory lane identities from the policy manifest and requires every active result exactly once.
- Unknown identities and advisory results are rejected before they can be treated as protected evidence.
- Extended evaluator fixtures cover unknown, advisory, missing, malformed, duplicate, failed, cancelled, and docs-only skipped outcomes.

Commit: `314da1c2 test(159-01): harden CI Green evidence protocol`

## Verification

Passed:

```bash
mix format --check-formatted config/quality/ci_policy.exs test/support/ci_policy.ex test/scripts/ci_green_policy_test.exs test/scripts/required_checks_test.exs test/scripts/lane_classification_drift_test.exs
mix test test/scripts/ci_green_policy_test.exs test/scripts/required_checks_test.exs test/scripts/lane_classification_drift_test.exs --warnings-as-errors
git diff --check
```

Result: 71 tests, 0 failures.

## Deviations from Plan

**[Rule 3 - Compatibility] Portable policy-manifest loading** — The first implementation used Bash `mapfile`, which is unavailable in the repository's macOS/Bash 3 execution environment. Replaced it with portable `while read` process-substitution loops. Verification: focused evaluator suite passes. Commit: `314da1c2`.

**Total deviations:** 1 auto-fixed compatibility deviation. **Impact:** no scope expansion; the evaluator remains a pure result checker and reads only checked-in policy data.

## Scope Confirmation

- `.github/workflows/ci.yml` was not changed.
- No `mailglass_admin` files or admin/operator behavior changed.
- No external dependencies were added.

## Next Plan Readiness

Plan 02 can introduce the formatter baseline and package-scoped setup action. Plan 06 can later promote only repaired target lanes using this established policy tracer.
