---
phase: 156-delivery-correctness-and-bounded-execution
reviewed: 2026-08-17T05:18:00Z
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

**Reviewed:** 2026-08-17T05:18:00Z
**Depth:** deep
**Files Reviewed:** 34
**Status:** issues_found

## Summary

The prior replay atom-allocation, ETS caller-crash, Plug-only router, and internal replay module-resolution findings are closed in the same-process path. Focused inbound router/worker/replay suites pass (53 tests). The RouterRegistry redesign is nevertheless not durable or bound to a specific record: an application restart empties its authority map, and job JSON can select a different registered route authority. The phase is not clean.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Router authority is lost on application restart, so durable jobs never recover

**File:** `mailglass_inbound/lib/mailglass_inbound/execution/router_registry.ex:55-70`, `mailglass_inbound/lib/mailglass_inbound/execution.ex:149-152`, `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex:26-28`

**Issue:** `route_authority` is persisted in the job, but its mailbox index exists only in the RouterRegistry GenServer state. On application or registry restart, `init/1` resets that state to `%{}` (line 56); a queued job with a nonempty authority then calls `RouterRegistry.resolve/2`, receives `{:error, :unavailable}`, and the worker returns a retry (lines 26-28). Nothing repopulates that exact authority unless a new ingress request happens to register the same router. Retrying is therefore only temporary: after `max_attempts` the already-accepted durable message becomes dead work. This violates the durable execution/restart contract the Oban path is meant to provide.

**Fix:** Make authoritative router data recoverable at boot, not just while the ingress process remains alive. For example, configure and validate the finite router set in application config and rebuild its indexes during registry initialization; map a persisted opaque router ID to that configured set. Add an integration test that enqueues through the Plug-only path, restarts the registry/application before `Worker.perform/1`, and proves the exact queued job executes (or has an explicit documented durable recovery path independent of new ingress traffic).

### CR-02: Tampered job args can switch a delivery to any currently registered mailbox

**File:** `mailglass_inbound/lib/mailglass_inbound/execution.ex:128-152`, `mailglass_inbound/lib/mailglass_inbound/execution/router_registry.ex:63-70`

**Issue:** The registry restricts a supplied `{route_authority, mailbox}` pair to registered modules, but both selector values still come from the Oban job (`validate_job_route/2` passes `job_args["route_authority"]` at lines 128-136). If two routers have been registered in the process, an attacker who modifies job JSON can replace both fields with Router B's authority ID and one of Router B's mailbox names. `resolve/2` then returns that module and production loading/execution invokes it. There is no record/evidence-bound router identity to prove the selected authority was the one that routed this inbound message. This is a confused-deputy version of the original arbitrary mailbox dispatch problem: job data selects any currently authorized handler, not merely the route recorded at ingress.

**Fix:** Bind the selected router identity and mailbox to trusted persistence at ingress (or protect the durable job arguments with a keyed integrity proof verified before lookup). On perform, derive both from that trusted binding before registry lookup rather than trusting the job selectors. Add a two-router test that mutates an enqueued job to Router B/mailbox B and asserts it is rejected without loading or executing either mailbox.

---

_Reviewed: 2026-08-17T05:18:00Z_
_Reviewer: gsd-code-reviewer_
_Depth: deep_
