---
phase: 144-signal-drift-integrity
reviewed: 2026-07-31T21:25:00Z
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
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 144: Code Review Report

**Reviewed:** 2026-07-31T21:25:00Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The prior review findings are resolved: the recovery preflight binds `gh` to the workflow repository; computed icons spanning lines are handled and have a valid positive fixture; and the contributor guidance matches the PAT-backed/fail-loud behavior. The focused contract suite passes (37 tests). Two defects remain: the icon gate is still fail-open for several unsupported runtime expressions, and repo hygiene reports a repository without an upstream as release-clean.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Unsupported dynamic icon expressions bypass the fail-closed gate

**Classification:** BLOCKER

**File:** `mailglass_admin/scripts/check-conformance.sh:169-188`
**Issue:** `extract_dynamic_icon_references` records an expression as unresolved only when it contains `<>` or `#{`. Direct runtime expressions such as `name={@runtime_icon}`, `name={option.icon}`, and `name={icon_for(state)}` match neither branch and emit nothing. The separate `hero-*` text scan cannot validate a runtime value that is not represented as a complete source literal, so a new invalid icon supplied through one of these expressions can ship while the gate reports clean. The existing negative test covers only `"hero-" <> @runtime_icon` (`test/scripts/icon_exists_gate_test.exs:64-80`), leaving the simpler fail-open forms untested.

**Fix:** Treat every `name={...}` expression that is not an explicitly supported finite literal form as unresolved. For example, add a final `else` that writes `"$file:$line_number: dynamic expression"` to `unresolved_dynamic_icons`, then add fixtures for `@runtime_icon`, a map field, and a helper call that assert a non-zero result. If those forms are intentionally supported, resolve them from a bounded declaration instead of silently accepting arbitrary values.

## Warnings

### WR-01: Repo hygiene accepts a repository with no upstream as clean

**Classification:** WARNING

**File:** `dev/mix/tasks/mailglass.repo.hygiene.ex:107-123,367-369`
**Issue:** When `git rev-list @{upstream}...HEAD` fails, `git_state/1` records `%{status: "unknown"}` in `upstream_status` but resets `ahead` and `behind` to zero. `blocked?` ignores `upstream_status`, so this check returns `:pass`; the aggregate can therefore return `:pass` even though it did not establish that the checked-out release branch is aligned with any upstream. The clean test intentionally uses a newly initialized repository with no remote/upstream (`test/mix/tasks/mailglass.repo.hygiene_test.exs:154-173`), so the suite currently locks in this false-green behavior.

**Fix:** Return `unknown(:git_state, ...)` (or include `upstream_status != :ok` in `blocked?`) when the upstream comparison fails, and add a test that asserts a repository without `@{upstream}` makes the aggregate non-success. Keep the existing ahead/behind diagnostics only for a successfully resolved upstream.

---

_Reviewed: 2026-07-31T21:25:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
