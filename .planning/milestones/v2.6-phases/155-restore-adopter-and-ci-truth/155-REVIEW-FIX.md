---
phase: 155-restore-adopter-and-ci-truth
fixed_at: 2026-08-17T03:03:00Z
review_path: .planning/phases/155-restore-adopter-and-ci-truth/155-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 155: Code Review Fix Report

**Fixed at:** 2026-08-17T03:03:00Z
**Source review:** `.planning/phases/155-restore-adopter-and-ci-truth/155-REVIEW.md`
**Iteration:** 1

## Summary

- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Generated legacy repair can delete data after its generation-time preflight

**Files modified:** `lib/mailglass/migrations/legacy_toy.ex`, `test/mix/tasks/mailglass_legacy_repair_test.exs`
**Commit:** `5f222f5c`
**Applied fix:** Locked and revalidated the exact legacy catalog and emptiness immediately before the drop; added generate-then-insert preservation coverage.

**Follow-up correction:** `595e62ce` replaces PostgreSQL-reserved/invalid catalog expressions with valid aliases, zero-value `"char"` comparisons, and a string argument to `format(%I)`. The full focused suite now passes.

### CR-02: Generated-host proof recursively deletes an arbitrary caller-supplied directory

**Files modified:** `scripts/generated_ecto_host_proof.sh`, `test/scripts/generated_ecto_host_proof_test.exs`
**Commit:** `235ed772`
**Applied fix:** Rejected caller-owned `WORK_DIR`, created a private `mktemp -d` scratch directory, and added destructive-cleanup contract controls.

### CR-03: Push change detection converts git-diff failure into a successful docs-only classification

**Files modified:** `.github/workflows/ci.yml`, `test/scripts/ci_green_policy_test.exs`
**Commit:** `d3e175bb`
**Applied fix:** Made push diff errors diagnostic and fatal, with a mutation-based fail-closed source contract.

## Verification

- Passed: `MIX_ENV=test mix test test/mix/tasks/mailglass_legacy_repair_test.exs test/scripts/generated_ecto_host_proof_test.exs test/scripts/ci_green_policy_test.exs test/scripts/required_checks_test.exs --warnings-as-errors` — 27 tests, 0 failures.
- Passed: `mix format --check-formatted` for all modified Elixir files.
- Passed: `bash -n scripts/generated_ecto_host_proof.sh scripts/ci_green_policy.sh`.
- Passed: `actionlint .github/workflows/ci.yml`.

---

_Fixed: 2026-08-17T03:03:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
