---
phase: 156-delivery-correctness-and-bounded-execution
reviewed: 2026-08-17T05:32:00Z
depth: deep
files_reviewed: 34
files_reviewed_list:
  - docs/api_stability.md
  - lib/mailglass/adapters/swoosh.ex
  - lib/mailglass/application.ex
  - lib/mailglass/errors/send_error.ex
  - lib/mailglass/optional_deps/oban.ex
  - lib/mailglass/outbound.ex
  - lib/mailglass/outbound/async_adapter.ex
  - lib/mailglass/outbound/async_adapter/task_supervisor.ex
  - lib/mailglass/outbound/worker.ex
  - lib/mailglass/rate_limiter.ex
  - lib/mailglass/rate_limiter/atomic_bucket.ex
  - lib/mailglass/rate_limiter/table_owner.ex
  - lib/mailglass/tracking/plug.ex
  - lib/mailglass/webhook/provider_name.ex
  - lib/mailglass/webhook/replay.ex
  - mailglass_inbound/lib/mailglass_inbound/application.ex
  - mailglass_inbound/lib/mailglass_inbound/execution.ex
  - mailglass_inbound/lib/mailglass_inbound/execution/worker.ex
  - mailglass_inbound/lib/mailglass_inbound/rate_limiter.ex
  - mailglass_inbound/lib/mailglass_inbound/rate_limiter/table_owner.ex
  - mailglass_inbound/test/mailglass_inbound/async_execution_test.exs
  - mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs
  - mailglass_inbound/test/mailglass_inbound/rate_limiter_test.exs
  - mailglass_inbound/test/mailglass_inbound/worker_test.exs
  - test/mailglass/adapters/swoosh_test.exs
  - test/mailglass/application_test.exs
  - test/mailglass/error_test.exs
  - test/mailglass/outbound/deliver_later_test.exs
  - test/mailglass/outbound/deliver_many_test.exs
  - test/mailglass/outbound/telemetry_test.exs
  - test/mailglass/outbound/worker_test.exs
  - test/mailglass/rate_limiter_test.exs
  - test/mailglass/tracking/plug_test.exs
  - test/mailglass/webhook/replay_test.exs
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 156: Code Review Report

**Reviewed:** 2026-08-17T05:32:00Z
**Depth:** deep
**Files Reviewed:** 34
**Status:** issues_found

## Summary

The durable evidence binding is written atomically with the record/evidence, tenant and evidence IDs remain jointly scoped on load, and worker job selectors now only act as mismatch checks. Named-router execution is no longer switchable by tampering with a job, replay no longer converts persisted strings into atoms, and no new PII leak or transaction-boundary defect was found. Focused inbound tests pass (52 tests) and focused core tests pass (70 tests).

Two blocking compatibility paths remain. The supported lower-level `:routes` ingress option silently acknowledges a message while dropping its durable execution, and already-queued pre-binding jobs retry a permanently unrecoverable condition until exhausted.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Oban ingress with the accepted `:routes` option acknowledges mail that can never execute

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex:411-456`, `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:616-640`, `mailglass_inbound/lib/mailglass_inbound/execution.ex:27-40,351-362`

**Issue:** `Ingress.Plug` still forwards `:routes` to persistence (lines 616-620), and `Persist` still selects a matching mailbox from that list (lines 411-426). But its durable binding contains only `status` and `mailbox` when no `:router` is given (lines 445-456), whereas `Execution.route_binding/1` accepts a matched binding only when it also contains a string router identity (lines 351-362). With Oban enabled, `dispatch/2` therefore returns `{:error, :missing_binding}`. `maybe_execute/3` intentionally discards that result (line 632) and responds 200, so the record is committed, the provider is acknowledged, and no execution job is created. A duplicate redelivery is then also skipped. Although `:routes` is documented as lower-level/package-internal, it remains a supported input to both the Plug and persistence API; this changes it into silent message loss in the durable mode.

**Fix:** Either make durable dispatch reject `:routes` before the ingress response/acknowledgement, with a typed, observable configuration error, or persist a trusted binding that can safely rehydrate the finite mailbox set without atom creation. The simplest contract is to require a compiled named `:router` whenever Oban is selected and validate it in `Plug.init/1`/configuration; do not discard a dispatch failure after committing the inbound record. Add a Plug-level Oban test using only `:routes` that proves the request fails safely before acknowledgement (if unsupported), or a full worker/restart test proving it executes (if supported).

### CR-02: Pre-binding queued jobs are retried as transient work even though retry cannot make them executable

**File:** `mailglass_inbound/lib/mailglass_inbound/execution.ex:119-126,351-362`, `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex:20-28`

**Issue:** Evidence rows created before the new `mailglass_execution_route` fact have no binding. `validate_job_route/3` maps that immutable absence to `:route_authority_unavailable` (lines 119-126), and the Oban worker returns it as a retryable error (line 27). Retrying cannot add the missing historical binding, so every queued job from before this deployment consumes all 20 attempts and becomes dead work without a migration or an explicit recovery result. Replay fails closed correctly for the same legacy condition, but the durable delivery path has neither a safe migration nor a deterministic permanent/diagnostic outcome. This breaks in-flight message delivery on upgrade.

**Fix:** Define and implement an upgrade path before shipping: migrate queued jobs/evidence using a configured finite router mapping, or classify missing legacy authority as a permanent, explicitly tagged cancellation/dead-letter outcome with an operator-visible recovery instruction rather than retrying 20 times. Add tests for a pre-binding evidence row and queued job that verify the selected migration or terminal behavior and ensure no mailbox is chosen from untrusted job data.

---

_Reviewed: 2026-08-17T05:32:00Z_
_Reviewer: gsd-code-reviewer_
_Depth: deep_
