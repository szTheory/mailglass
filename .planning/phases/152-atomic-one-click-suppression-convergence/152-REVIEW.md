---
phase: 152-atomic-one-click-suppression-convergence
reviewed: 2026-08-03T14:52:00Z
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
  critical: 3
  warning: 3
  info: 0
  total: 6
status: issues_found
---

# Phase 152: Code Review Report

**Reviewed:** 2026-08-03T14:52:00Z
**Depth:** deep
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The implementation correctly uses a single Multi for the nominal event/suppression inserts and focused tests pass (115 tests, one existing skip). However, the separate post-commit path loses tenant context, conflict reuse can leave a one-click target unsuppressed, and unexpected database/convergence exceptions bypass the documented byte-empty failure response. The new concurrency and preflight tests also do not assert the facts their names and docs claim, leaving these regressions undetected.

## Critical Issues

### CR-01: Separate lifecycle Multi runs outside the Delivery tenant context

**File:** `lib/mailglass/compliance/unsubscribe_controller.ex:39-43`
**Issue:** `Tenancy.with_tenant/2` ends immediately after `UnsubscribeConvergence.run/1`. `maybe_run_post_commit_effects/2`, including an adopter's separate `Ecto.Multi`, then runs under the prior request context (or no tenant), not the Delivery-derived tenant. Existing lifecycle modules can use `Tenancy.current/0` or `Tenancy.scope/1`; in a multi-tenant host this can write/read the wrong tenant or fail after the durable unsubscribe has committed. This violates the required tenant-restored post-commit compatibility sequence.
**Fix:** Keep post-commit effects inside a second `Tenancy.with_tenant(delivery.tenant_id, fn -> ... end)` block (while still after the primary transaction), and add a custom-tenancy regression test whose lifecycle Multi reads/writes through `Tenancy.current/0`.

### CR-02: Reusing an expired same-identity suppression does not enforce the unsubscribe

**File:** `lib/mailglass/compliance/unsubscribe_convergence.ex:46-55`
**Issue:** On any uniqueness conflict, the code refetches and accepts the existing row regardless of its `reason` or `expires_at` (the refetch at lines 99-109 has no active/permanent predicate). A pre-existing temporary `:manual`/`:policy` `:address_stream` row with an elapsed expiry blocks insertion, is returned as convergence success, and remains ignored by preflight. The valid one-click POST returns 200 but the next matching send is not suppressed, violating UNSUB-07/09. A future expiry creates the same failure later.
**Fix:** Make the conflict path establish a permanent effective unsubscribe fact. If a same-identity row may be reused, verify it is active and non-expiring; otherwise promote it atomically to a permanent unsubscribe suppression (or introduce a separate immutable unsubscribe identity that can coexist). Add expired and future-expiry same-identity cases to the controller-to-Outbound integration test.

### CR-03: Exceptions escape the promised byte-empty convergence failure response

**File:** `lib/mailglass/compliance/unsubscribe_controller.ex:37-43`
**Issue:** Only `{:error, ...}` results reach `respond_to_unsubscribe/2`. Exceptions from `Repo.multi/1`/the host repo, `repo.one!/2` during a canonical refetch, or a transaction connection failure escape the controller. Phoenix then renders its normal error response rather than the stable byte-empty 500 documented in the guides and API contract; development error rendering can also expose request details. Named injected failures test only the tuple-return branch.
**Fix:** Normalize expected convergence exceptions/exits at the controller/service boundary to an internal error result, log a bounded classification, and always `send_resp(conn, 500, "")` for a resolved valid Delivery. Add tests that force a refetch/query exception and a repository transaction exception and assert an empty 500 with no effects or partial pair.

## Warnings

### WR-01: Test-only failure switch is shipped as a production-wide mutable config backdoor

**File:** `lib/mailglass/compliance/unsubscribe_convergence.ex:128-138`
**Issue:** Every production request reads the undocumented global `:unsubscribe_convergence_failure_step` application setting. Any accidental runtime config, release tooling, or in-process code can make all one-click requests fail after either durable step. This test seam expands the production availability surface and is not constrained to tests.
**Fix:** Inject failure behavior only through a test-only dependency/seam, or compile the hook exclusively for `Mix.env() == :test`; do not consult a globally mutable application key on production requests.

### WR-02: The claimed concurrent pair assertion never inspects suppressions

**File:** `test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs:194-198`
**Issue:** The test is named “one event and one created-only lifecycle effect,” while the phase contract claims it proves one event/suppression pair. `durable_snapshot/1` at lines 201-208 queries only `mailglass_events`; no assertion counts or examines a suppression. A regression that omits the suppression under concurrency still passes this proof.
**Fix:** Extend the snapshot to query the Delivery-derived `:address_stream` identity and assert exactly one active suppression alongside exactly one event for all racing POSTs.

### WR-03: Preflight isolation test bypasses one-click convergence entirely

**File:** `test/mailglass/outbound/preflight_test.exs:379-423`
**Issue:** The new test inserts a suppression directly with `insert_suppression!/1`; it never creates a Delivery, signs/posts its one-click token, or verifies that Phase 152's transaction produced the row. It proves generic preflight behavior, not the required controller-to-Outbound enforcement bridge. Scope or expiry defects in convergence (including CR-02) therefore remain green.
**Fix:** Start with a real bulk Delivery and POST its signed one-click link, then invoke `Outbound.send/1` for matching, other-stream, transactional, normalized-address, and other-tenant cases. Assert the matching adapter is never called.

---

_Reviewed: 2026-08-03T14:52:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
