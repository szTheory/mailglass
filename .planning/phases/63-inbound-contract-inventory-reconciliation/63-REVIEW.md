---
phase: 63-inbound-contract-inventory-reconciliation
reviewed: 2026-05-31T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - mailglass_inbound/docs/api_stability.md
  - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 63: Code Review Report

**Reviewed:** 2026-05-31T00:00:00Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

The Phase 63 stability inventory doc is detailed, but the docs-contract test suite does not reliably enforce the intended contract boundaries. Multiple assertions are presence-only checks that can pass while the contract is silently reclassified or over-claimed.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Stable-vs-internal classification is not actually validated

**File:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:14`
**Issue:** The module inventory tests assert only that module strings exist somewhere in docs (`assert ... =~ module_name`). This does not verify *which section* (`stable`, `testing`, `internal`, `deferred`) contains each module. A module can be moved from `stable` to `internal` and tests still pass as long as the name appears anywhere.
**Fix:**
```elixir
# Example pattern: assert module appears under the stable section block specifically.
[_, stable_block] =
  Regex.run(~r/### `stable`\n(.*?)(?:\n### `|\z)/s, stability) ||
    flunk("Missing stable section")

assert stable_block =~ "`MailglassInbound.Ingress.Plug`"
refute Regex.match?(~r/### `internal`[\s\S]*`MailglassInbound.Ingress.Plug`/m, stability)
```

### CR-02: Deferred/public-API guardrails are vulnerable to wording drift and false negatives

**File:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:224`
**Issue:** Over-claim protections rely on exact phrase refutes (for example `refute stability =~ "public provider behaviour"`). Equivalent over-claims with minor wording changes (for example “provider behavior is public API”) bypass the suite, so Phase 63’s “do not over-claim public API” goal is not robustly enforced.
**Fix:**
```elixir
# Use broader regex guards around prohibited semantic claims:
refute Regex.match?(~r/provider .* (public|stable) .* api/i, stability)
refute Regex.match?(~r/replay .* (fresh receive|provider receipt)/i, stability)

# Also assert required "deferred" entries exist in that exact section.
[_, deferred_block] =
  Regex.run(~r/### `deferred`\n(.*?)(?:\n## |\z)/s, stability) ||
    flunk("Missing deferred section")
assert deferred_block =~ "public provider extension API"
```

## Warnings

### WR-01: Docs-contract test is tightly coupled to cross-package/repo docs

**File:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:236`
**Issue:** The suite reads and asserts on `mailglass_admin/docs/operator-trust.md`, root `mix.exs`, root docs-check task, and `MAINTAINING.md`. This makes inbound package contract verification fail due to unrelated documentation edits outside the inbound contract surface.
**Fix:** Keep this suite scoped to `mailglass_inbound` contract artifacts; move cross-repo governance checks into a separate repo-level docs/governance test file.

---

_Reviewed: 2026-05-31T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
