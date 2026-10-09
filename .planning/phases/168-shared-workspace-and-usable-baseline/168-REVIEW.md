---
phase: 168-shared-workspace-and-usable-baseline
reviewed: 2026-10-09T00:15:20Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
  - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  - mailglass_admin/e2e/flows.spec.js
findings:
  critical: 0
  warning: 0
  info: 1
  total: 1
status: issues_found
---

# Phase 168: Code Review Report

**Reviewed:** 2026-10-09T00:15:20Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Re-reviewed the original three-file scope after fixer commit `f92542e4`. The spacing guard now covers all six requested cases: `hover:-mt-0.5`, `sm:-mt-2xs`, `supports-[display:grid]:-mt-0.5`, `[&:hover]:sm:-mt-2xs`, `[&:has([data-state=open])]:-mt-0.5`, and `group-hover/item:-mt-0.5`. The Phase 168 browser assertion checks the rendered Inbound reveal stack's computed 4px row gap, and the EvidenceCard uses `gap-xs`. No tests were run, per instruction. The pre-existing `can_reveal?` INFO remains valid; it is supplied as `false` for the denied gallery specimen but never affects the rendered reveal button. The LiveView event still performs server-side authorization, so this is not an authorization bypass.

## Narrative Findings (AI reviewer)

### IN-01: `can_reveal?` is an unused component attribute

**Severity:** INFO
**File:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:29`
**Issue:** The component declares `can_reveal?` but never reads it. `GalleryLive` passes `false` for the denied specimen, yet the Reveal button at lines 50-59 remains rendered and actionable. The supplied capability state therefore does not control the component affordance, making the denied specimen inconsistent with its assigns. The Inbound LiveView still authorizes the reveal event server-side, so this does not expose raw payloads by itself.
**Fix:** Use `@can_reveal?` to hide or disable the reveal control when capability is absent, or remove the attribute and its callers if reveal availability is meant to be represented only by `reveal_state`.

---

_Reviewed: 2026-10-09T00:15:20Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
