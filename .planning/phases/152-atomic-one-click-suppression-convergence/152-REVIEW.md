---
phase: 152-atomic-one-click-suppression-convergence
reviewed: 2026-08-03T15:05:00Z
depth: deep
files_reviewed: 15
files_reviewed_list:
  - docs/api_stability.md
  - guides/production-go-live-checklist.md
  - guides/unsubscribe.md
  - lib/mailglass/compliance/unsubscribe_controller.ex
  - lib/mailglass/compliance/unsubscribe_convergence.ex
  - lib/mailglass/config.ex
  - lib/mailglass/lifecycle.ex
  - test/mailglass/compliance/unsubscribe_controller_test.exs
  - test/mailglass/compliance/unsubscribe_test.exs
  - test/mailglass/docs/unsubscribe_guide_test.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/outbound/preflight_test.exs
  - test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs
  - test/mailglass/schema_prefix_hardening_test.exs
  - test/mailglass/stability_contract_test.exs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 152: Code Review Re-review Report

**Reviewed:** 2026-08-03T15:05:00Z
**Depth:** deep
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The fixes in `56060ff0`, `4f7a7a99`, and `f3f1902d` resolve five of the six original findings: effects are again tenant-scoped; bounded attrs/logs exclude the address, token, and exception payload; the failure seam is test-compiled and process-local; normal replay/concurrency tests now assert the suppression; and the real one-click-to-preflight bridge is exercised. The focused fix suite passed: 49 tests, including one property, with no failures.

One blocker remains: promoting an existing expiring suppression is not treated as newly completed convergence when the event also existed, and the promotion is not concurrency-safe for the required created-only effects gate.

## Critical Issues

### CR-01: Temporary-suppression promotion is classified as a replay and cannot safely gate effects

**File:** `lib/mailglass/compliance/unsubscribe_convergence.ex:54-80`
**Issue:** `ensure_permanent_unsubscribe/2` can change an existing expired/future-expiring same-identity suppression to permanent at lines 123-136, but `classify_result/1` decides `:created` solely from the two insert sentinels at lines 75-78. If the unsubscribe event and temporary suppression both pre-exist, both inserts conflict, the suppression is materially promoted, and the result is incorrectly `:already_converged`; the controller emits no lifecycle/broadcast effect for that newly completed permanent opt-out.

The update is also an unconditional `repo.update/2` on the refetched struct. Two concurrent requests can both observe the old temporary row, both promote it, and neither result carries a winner signal. Simply adding the promotion to the current `:created` condition would then allow duplicate effects. This violates the locked created-only/concurrency requirement for a repaired convergence.

**Fix:** Make promotion a named transaction result with an atomic single-winner signal. For example, issue a prefix-explicit conditional update constrained to `expires_at IS NOT NULL` (and the exact identity), inspect its affected-row/returning result, and set `:created` only for the request that performed that update. The zero-row path must refetch the permanent canonical row and return `:already_converged`. Add a true concurrent test with a pre-existing unsubscribe event plus expiring same-identity suppression; assert one permanent row and exactly one lifecycle/broadcast effect.

---

_Reviewed: 2026-08-03T15:05:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
