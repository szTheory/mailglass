---
phase: 152
fixed_at: 2026-08-03T15:00:00Z
review_path: .planning/phases/152-atomic-one-click-suppression-convergence/152-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 152: Code Review Fix Report

**Source review:** `.planning/phases/152-atomic-one-click-suppression-convergence/152-REVIEW.md`

## Fixed Issues

### CR-01: Tenant-restored post-commit effects

**Files modified:** `unsubscribe_controller.ex`, `unsubscribe_controller_test.exs`
**Commit:** `56060ff0`
**Applied fix:** Lifecycle and broadcast effects now execute in a second Delivery-tenant context after convergence commits; effect attributes omit the recipient address.

### CR-02: Expiring conflict suppressions

**Files modified:** `unsubscribe_convergence.ex`, `preflight_test.exs`
**Commit:** `56060ff0`
**Applied fix:** Same-identity expiring suppressions are promoted in the convergence transaction to permanent unsubscribe facts. Existing permanent suppressions remain unchanged.

### CR-03: Stable database-boundary failure response

**Files modified:** `unsubscribe_controller.ex`, `unsubscribe_convergence.ex`, `unsubscribe_controller_test.exs`
**Commit:** `4f7a7a99`
**Applied fix:** Expected database/refetch exceptions and repository exits map to a bounded error and byte-empty 500; raw exception contents are not logged.

### WR-01: Production mutable failure switch

**Files modified:** `unsubscribe_convergence.ex`, `unsubscribe_controller_test.exs`
**Commit:** `56060ff0`
**Applied fix:** Failure injection is test-compiled and process-local; production no longer reads an application configuration switch.

### WR-02: Concurrent pair assertion

**Files modified:** `unsubscribe_post_idempotency_property_test.exs`
**Commit:** `56060ff0`
**Applied fix:** Concurrent and replay proofs now assert exactly one active address-stream suppression in addition to the event.

### WR-03: Real one-click to preflight bridge

**Files modified:** `preflight_test.exs`
**Commit:** `56060ff0`
**Applied fix:** The integration test creates a Delivery through Outbound, posts its signed token, then exercises matching, normalized, unrelated-stream, transactional, and other-tenant sends.

## Verification

`mix test test/mailglass/compliance/unsubscribe_controller_test.exs test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs test/mailglass/outbound/preflight_test.exs`

Result: **47 tests, 0 failures** (including one property).

---

_Fixer: gsd-code-fixer_

## Re-review Follow-up

### CR-01: Atomic temporary-suppression promotion

**Files modified:** `unsubscribe_convergence.ex`, `unsubscribe_post_idempotency_property_test.exs`
**Applied fix:** Promotion is now a prefix-explicit conditional `update_all` restricted to the exact suppression identity and non-null expiry. The returning row is the sole promotion winner; zero-row concurrent losers refetch the permanent canonical row and report `:already_converged`. The created classification includes only that winner. A four-way concurrent repair test proves one permanent suppression and one lifecycle/broadcast effect pair.
