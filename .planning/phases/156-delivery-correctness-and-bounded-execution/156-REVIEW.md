---
phase: 156-delivery-correctness-and-bounded-execution
reviewed: 2026-08-17T05:08:00Z
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

**Reviewed:** 2026-08-17T05:08:00Z
**Depth:** deep
**Files Reviewed:** 34
**Status:** issues_found

## Summary

The prior replay atom-allocation and ETS caller-crash findings are fixed: replay carries the finite-decoded provider through its result, and the shared bucket denies instead of raising during an absent-table window. Focused re-review suites passed (51 tests total). However, the new mailbox allowlist has made the documented ingress configuration unable to execute durable jobs, and the parallel internal replay path still resolves a persisted mailbox string into an arbitrary loaded module. The phase is not clean.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: The mailbox allowlist breaks every documented durable ingress configuration

**File:** `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex:20-22`, `mailglass_inbound/lib/mailglass_inbound/execution.ex:341-353`

**Issue:** The ingress documentation configures the router only on `MailglassInbound.Ingress.Plug` (for example `router: MyApp.MailglassInboundRouter` in `mailglass_inbound/README.md:143-155` and `docs/inbound-install.md:146-157`). `maybe_execute/2` then calls `Execution.dispatch(result)` without that option (`ingress/plug.ex:629-634`). The new worker pre-validates every durable job with `Execution.validate_job_route(args, [])`, which can only consult `Application.get_env(:mailglass_inbound, :router)`. `MailglassInbound.Config` neither declares nor validates that application key. Therefore an adopter following the documented, supported Plug-only setup will persist a matched inbound record, enqueue successfully, and have its Oban worker permanently cancel it before loading or executing the mailbox. The security control silently converts a supported normal path into message loss.

**Fix:** Preserve the router authority across the async boundary without trusting job input blindly. At minimum, make the router an explicit validated required application configuration for durable execution and update the documented installation/migration contract; preferably persist a stable router identity at enqueue and verify it against a configured allowlist before resolving the mailbox. Pass a test with no global `:mailglass_inbound, :router`, a router supplied only to the ingress Plug, and assert the resulting durable job executes rather than being cancelled.

### CR-02: Internal replay still invokes a mailbox selected from persisted data

**File:** `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex:74-97,139-142`

**Issue:** The new worker path no longer trusts the `"mailbox"` job argument, but `Internal.Replay` obtains `ExecutionRun.mailbox` from the database, converts it through `String.to_existing_atom/1`, and passes it to `Execution.execute/2`. That is the same arbitrary-loaded-module dispatch boundary the original CR-02 identified, just on the replay path: a corrupt execution-run record can select any loaded module with `process/1`. It also leaves a non-finite persisted-string decoder in the phase's purported closed-value coverage.

**Fix:** Route replay mailbox resolution through the same trusted configured-router allowlist (extract a shared internal resolver rather than duplicating it), returning the existing `:replay_mailbox_missing` typed error for unknown or unauthorized names. Add a replay regression with a loaded sentinel module and a persisted mailbox string; assert it fails without invoking the sentinel or allocating atoms.

---

_Reviewed: 2026-08-17T05:08:00Z_
_Reviewer: gsd-code-reviewer_
_Depth: deep_
