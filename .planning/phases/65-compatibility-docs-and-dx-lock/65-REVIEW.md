---
phase: 65-compatibility-docs-and-dx-lock
reviewed: 2026-06-01T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - guides/compatibility-and-deprecations.md
  - lib/mix/tasks/mailglass.docs.check.ex
  - mailglass_admin/docs/operator-trust.md
  - mailglass_inbound/README.md
  - mailglass_inbound/docs/inbound-install.md
  - mailglass_inbound/docs/inbound-operator.md
  - mailglass_inbound/docs/inbound-routing-debug.md
  - mailglass_inbound/docs/inbound-testing.md
  - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---
# Phase 65: Code Review Report

**Reviewed:** 2026-06-01T00:00:00Z  
**Depth:** standard  
**Files Reviewed:** 9  
**Status:** issues_found

## Summary

Reviewed the listed docs, docs-check task, and docs contract test for correctness, security posture, and drift-check reliability. Found one contract contradiction in inbound provider support claims and two checker robustness defects that create false-positive/false-negative risk.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Inbound provider support contract is internally contradictory

**Classification:** BLOCKER  
**File:** `mailglass_inbound/docs/inbound-install.md:159`  
**Issue:** The install guide states “The four supported providers are `:postmark`, `:sendgrid`, `:mailgun`, and `:ses`”, while canonical docs in the same reviewed scope declare providers beyond Postmark/SendGrid as deferred (for example [mailglass_inbound/README.md](/Users/jon/projects/mailglass/mailglass_inbound/README.md):259). This creates a behavioral/docs regression in the published support contract and can mislead adopters into relying on unsupported lanes.  
**Fix:** Align install guide wording with the canonical contract. Example:
```md
The stable provider lanes in this slice are `:postmark` and `:sendgrid`.
Mailgun and SES guides are integration references and not part of the current stable provider contract.
```

## Warnings

### WR-01: `--path` CLI scope is not honored by Tier-1 contract checks

**Classification:** WARNING  
**File:** `lib/mix/tasks/mailglass.docs.check.ex:427`  
**Issue:** `docs_paths(opts)` is computed, but `tier1_surface_issues/0`, `preview_boundary_issues/0`, and `trust_boundary_issues/0` ignore that scope and always evaluate hardcoded paths. This makes `mix mailglass.docs.check --path ...` behavior inconsistent with task usage docs and increases false-positive failures for targeted checks.  
**Fix:** Thread selected paths through all check functions and filter rule/path lists accordingly.
```elixir
issues =
  leak_issues(paths)
  |> Kernel.++(tier1_surface_issues(paths))
  |> Kernel.++(preview_boundary_issues(paths))
  |> Kernel.++(trust_boundary_issues(paths))
```

### WR-02: Exact token matching in docs checker is brittle and prone to false failures

**Classification:** WARNING  
**File:** `lib/mix/tasks/mailglass.docs.check.ex:485`  
**Issue:** `String.contains?/2` on exact required tokens (including punctuation/casing-sensitive phrases) makes CI fail on benign editorial changes that preserve semantics. This is a maintainability risk and weak signal-to-noise for release-gating checks.  
**Fix:** Use regex-based semantic checks for unstable prose, normalize whitespace/case for token checks, and reserve exact literals for truly invariant command/module names.
```elixir
normalized = content |> String.downcase() |> String.replace(~r/\s+/, " ")
# then match resilient regex tokens for prose clauses
```

---

_Reviewed: 2026-06-01T00:00:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
