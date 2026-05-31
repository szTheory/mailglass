---
phase: 61-docs-contract-boundary-enforcement
reviewed: 2026-05-31T14:52:01Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - guides/webhook-troubleshooting.md
  - guides/webhooks.md
  - lib/mix/tasks/mailglass.docs.check.ex
  - mailglass_admin/docs/operator-trust.md
  - reference/host_app/README.md
  - reference/host_app/SCOPE.md
  - test/mailglass/docs_check_task_test.exs
  - test/mailglass/docs_contract_test.exs
  - test/reference_host/trust_runner_command_contract_test.exs
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---
# Phase 61: Code Review Report

**Reviewed:** 2026-05-31T14:52:01Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed all scoped Phase 61 files at standard depth with emphasis on runtime contract-check behavior and test reliability. No direct security vulnerabilities were identified in this slice, but there are correctness/reliability defects in the docs-check task behavior and the related tests.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: `--path` does not actually scope Tier 1 checks

**File:** `lib/mix/tasks/mailglass.docs.check.ex:320`
**Issue:** `docs_paths/1` returns scoped paths for `--path`, but `tier1_surface_issues/0` (and other checks) still unconditionally read all Tier 1 files. This makes `mix mailglass.docs.check --path ...` behavior inconsistent with its documented usage and can fail unrelated docs unexpectedly.
**Fix:**
```elixir
# Pass selected paths through all checks and skip rules for files not in scope.
issues =
  leak_issues(paths)
  |> Kernel.++(tier1_surface_issues(paths))
  |> Kernel.++(preview_boundary_issues(paths))
  |> Kernel.++(trust_boundary_issues(paths))
```

### WR-02: Cross-module async flake risk from in-place doc mutation

**File:** `test/mailglass/docs_check_task_test.exs:2`
**Issue:** This module mutates shared repository files (`README.md`, `guides/preview.md`, `mailglass_admin/README.md`, `MAINTAINING.md`) during tests. `async: false` only serializes tests in this module; other modules (for example `test/mailglass/docs_contract_test.exs` with `async: true`) can run concurrently and read transient mutated content, causing nondeterministic failures.
**Fix:** Run all doc-contract suites touching shared files non-async, or isolate mutable fixtures into temp files and run the task against isolated paths so repository files are never modified during concurrent tests.

### WR-03: Command contract assertions are too broad to prevent drift

**File:** `test/reference_host/trust_runner_command_contract_test.exs:16`
**Issue:** Required tokens like `"install"` and `"send"` are substring checks over full files. These can pass on unrelated text and fail to detect command/stage drift in the actual trust-runner contract.
**Fix:** Assert specific command/stage atoms or exact list values (for example structured stage names or full command strings) instead of generic substrings.

---

_Reviewed: 2026-05-31T14:52:01Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
