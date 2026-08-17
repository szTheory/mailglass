---
phase: 156-delivery-correctness-and-bounded-execution
reviewed: 2026-08-17T06:03:00Z
depth: deep
files_reviewed: 36
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
  - mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs
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
  - test/mailglass/rate_limiter_supervision_test.exs
  - test/mailglass/tracking/plug_test.exs
  - test/mailglass/webhook/replay_test.exs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 156: Code Review Report

**Reviewed:** 2026-08-17T06:03:00Z
**Depth:** deep
**Files Reviewed:** 36
**Status:** issues_found

## Summary

The prior Phase 156 durable-route review remains clean: evidence authority is atomic and tenant-bound, job tampering is rejected, legacy jobs cancel safely, and no atom/PII/transaction regression was introduced.

The Plan 06 owner-serialized fallback correctly restores the missing-table path, serializes admission, reinserts a taken tuple on its normal result paths, and its focused tests pass. It nevertheless reintroduces token capacity when contended calls reach the owner out of timestamp order. The limiter is not clean.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Out-of-order fallback calls move the bucket clock backwards and mint an extra token

**File:** `lib/mailglass/rate_limiter/atomic_bucket.ex:78-100`, `lib/mailglass/rate_limiter/table_owner.ex:74-83,129-132`, `mailglass_inbound/lib/mailglass_inbound/rate_limiter/table_owner.ex:68-77,120-123`

**Issue:** `now_us` is sampled by a caller before its `GenServer.call/3`, but concurrent callers can enter the owner mailbox in a different order. `consume_taken/4` correctly clamps a negative elapsed interval to zero, then still writes the older `now_us` into both `last_us` and `last_seen` (line 99). If the latest bucket state has `last_us = 100`, a delayed caller sampled at `99` is processed next, and a subsequent call at `100` receives a full microsecond of refill that has already elapsed. This violates capacity exactly when the new fallback is used under contention, allowing requests above the configured rate.

The failure is deterministic with the public helper: `consume_taken({:k, 0, 100, 0, 100}, 1, 60_000_000, 99)` returns a row with `last_us = 99`; passing that row at `100` returns `:ok`, despite no time having elapsed after the original state at `100`.

**Fix:** Monotonically clamp the transition timestamp before both refill and replacement, e.g. `effective_now_us = max(now_us, last_us)`, and retain a monotonic `last_seen` such as `max(now_us, last_seen)`. Apply the same rule to the CAS replacement path so fast and fallback paths have identical semantics. Add core and inbound regression tests that force a newer timestamped state followed by an older fallback call and prove the next current-time call remains denied with no fractional-remainder drift.

---

_Reviewed: 2026-08-17T06:03:00Z_
_Reviewer: gsd-code-reviewer_
_Depth: deep_
