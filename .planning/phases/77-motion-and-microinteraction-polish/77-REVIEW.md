---
phase: 77-motion-and-microinteraction-polish
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/e2e/operator.spec.js
  - scripts/check_motion_conformance.sh
  - .github/workflows/ci.yml
  - mailglass_admin/test/mailglass_admin/voice_test.exs
  - mailglass_admin/test/support/citext_probe.ex
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: resolved
resolution: WR-01 and WR-02 fixed in commit cdc54b6a; IN-01 deferred to Phase 79 conformance audit (theoretical, no current risk)
---

# Phase 77: Code Review Report

**Reviewed:** 2026-06-04
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 77 fixes GAP-19 (motion-reveal re-fire bug) by adding record-keyed `id` attributes to the two bare `motion-reveal` divs in `operator_live.ex` and `inbound_live.ex`, ships a CI conformance grep gate for banned motion tokens, adds Playwright regression tests for MOTION-01/MOTION-02, and fixes two pre-existing test-suite blockers (`voice_test.exs` script noise and `citext_probe.ex` Boundary warnings).

The two LiveView interpolations are correct: `@selected_delivery.id` is non-nil in the `true ->` branch (the preceding `is_nil(@selected_delivery)` arm exhausts nil), and `@detail.record.id` is safe because the `true ->` arm is only reached when `@detail` is non-nil and `detail.fetch/2` guarantees `record:` is a non-nil `%InboundRecord{}`. All third-party CI actions are SHA-pinned. The `voice_test.exs` script-stripping regex is correct; the `citext_probe.ex` Boundary declaration follows the documented pattern.

Two issues require attention before the skipped Playwright inbound test is un-skipped in Phase 78, and one gap in the conformance grep gate should be corrected.

## Warnings

### WR-01: Skipped Playwright inbound test navigates to the wrong URL

**File:** `mailglass_admin/e2e/operator.spec.js:249` (also comment at line 240)

**Issue:** The skipped `test.skip("inbound detail pane carries record-keyed id ...")` body calls `page.goto('/ops/inbound?tenant_id=${tenantId}')`. The actual route is `/ops/mail/inbound` — the `mailglass_operator_routes "/mail"` macro mounts the scope at `/mail` inside the `/ops` scope, placing the inbound LiveView at `/ops/mail/inbound`. This is confirmed by the ExUnit `@base_path "/ops/mail/inbound"` in `inbound_live_test.exs:13`. The test is currently skipped so it does not cause CI failures, but when Phase 78 removes the `test.skip` wrapper the test will hit a 404 or redirect instead of the inbound surface, and `#inbound-detail-<id>` will never be found.

The implementation comment at line 240 (`// 1. Navigate to /ops/inbound?...`) has the same wrong path.

**Fix:**
```javascript
// Line 240 comment:
//   1. Navigate to /ops/mail/inbound?tenant_id=browser-tenant

// Line 249:
await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
```

---

### WR-02: THRASH_PATTERN in check_motion_conformance.sh misses duration-301 through duration-399

**File:** `scripts/check_motion_conformance.sh:18`

**Issue:** The Pass A pattern is:
```
duration-300|duration-[4-9][0-9][0-9]|duration-[0-9]{4,}
```
This catches exactly `duration-300`, then `duration-400` through `duration-999`, then `duration-1000+`. The values `duration-301` through `duration-399` are not matched. The UI-SPEC ceiling is 300ms, so `duration-301` through `duration-399` are all banned tokens that the gate should block. The gap means a future contributor could add `class="duration-350"` in a HEEx template and CI would not catch it.

The 77-RESEARCH.md Anchor 4 specifies the intended range as `duration-[3-9][0-9][0-9]` (not `[4-9]`), confirming this is a deviation from the spec.

**Fix:**
```bash
# Replace the duration sub-pattern in THRASH_PATTERN:
THRASH_PATTERN='transition-height|transition-max-height|transition-padding|transition-all|duration-[3-9][0-9][0-9]|duration-[0-9]{4,}'
```
Note: `duration-[3-9][0-9][0-9]` subsumes `duration-300` (which starts at 300), so the explicit `duration-300` alternative can be dropped.

## Info

### IN-01: ease-in[^-] pattern produces a false negative when "ease-in" appears at end of a line

**File:** `scripts/check_motion_conformance.sh:28`

**Issue:** The Pass B easing pattern `ease-in[^-]` requires a non-hyphen character to follow `ease-in`. When `ease-in` appears at the end of a line (followed only by the newline that `grep -E` consumes as a line delimiter), the pattern does not match. In practice Tailwind class attributes in HEEx always follow `ease-in` with a closing quote or space (`class="ease-in"`, `class="ease-in something"`), so the closing quote character satisfies `[^-]` and the match succeeds. The only undetected case is `ease-in` at the absolute end of a file with no trailing character — an extremely unlikely HEEx authoring pattern.

This is a theoretical gap, not a practical regression risk, and the current codebase is clean. No code change is strictly required; documenting it here so Phase 79's full conformance audit can assess whether a more explicit pattern (`ease-in([^-]|$)` with `-P` PCRE, or `ease-in[ "'"]` anchored to known delimiters) is worth the added complexity.

**Fix (optional):** If stricter detection is needed, use PCRE:
```bash
EASE_PATTERN='ease-in-out|ease-linear|ease-in(?!-)'
if grep -rP "$EASE_PATTERN" "$LIB" 2>/dev/null; then
```
`grep -P` (PCRE) is available on Ubuntu CI (GNU grep) but not guaranteed on macOS without `brew install grep`. Alternatively, the current `ease-in[^-]` pattern is acceptable given the practical impossibility of the edge case in real HEEx.

---

_Reviewed: 2026-06-04_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
