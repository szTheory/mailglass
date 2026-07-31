---
phase: 144-signal-drift-integrity
reviewed: 2026-07-31T21:38:26Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/branch-protection-drift.yml
  - scripts/branch-protection-outcome.sh
  - test/scripts/branch_protection_truth_test.exs
  - test/scripts/required_checks_test.exs
  - dev/mix/tasks/mailglass.repo.hygiene.ex
  - test/mix/tasks/mailglass.repo.hygiene_test.exs
  - mailglass_admin/scripts/check-conformance.sh
  - test/scripts/icon_exists_gate_test.exs
  - .github/workflows/publish-hex.yml
  - .github/workflows/post-publish-smoke.yml
  - test/scripts/linked_release_concurrency_test.exs
  - CONTRIBUTING.md
  - test/scripts/release_trigger_recovery_test.exs
  - .github/workflows/release-please.yml
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 144: Code Review Report

**Reviewed:** 2026-07-31T21:38:26Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The final fix correctly checks out before reading the manifest, rejects absent or malformed manifests, binds `gh` to the workflow repository, and fails closed for non-404 release API failures. The scoped tests pass (42 tests). One release-recovery control-flow path still bypasses those protections and contradicts the documented idempotent schedule/manual recovery contract.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: BLOCKER — scheduled and manual recovery bypass the manifest/tag preflight

**File:** `.github/workflows/release-please.yml:65`

**Issue:** `schedule` and `workflow_dispatch` events do not provide `github.event.head_commit.message`. `COMMIT_MESSAGE` is therefore empty, `pr_number` remains empty, and this early branch writes `should_run=true` and exits before reading the manifest or querying any releases. Thus the hourly path never reaches the documented “all expected tags already exist” no-op and can rerun release-please after an already-published release—the exact stale rerun that the guard was intended to prevent. It also means the new manifest validation and 404-vs-API-error fail-closed logic are not applied to either recovery trigger. The tests only execute a fabricated merge-commit message, so they do not cover the normal scheduled/manual event shape.

**Fix:** Derive the merged release PR (for example, from the commit/ref via GitHub API) without making tag validation conditional on it, or move manifest parsing and the all-present/partial-state decision before the `pr_number` early return. Only use the PR-label query when a PR number is available. Add executable fixtures with an empty `COMMIT_MESSAGE` that prove all-present tags produce `should_run=false`, partial tags fail, and 403/API failures fail without setting `should_run`.

---

_Reviewed: 2026-07-31T21:38:26Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
