---
phase: 156
plan: 01
subsystem: rate-limiting
tags: [ets, concurrency, token-bucket, inbound]
status: complete
requires: []
provides: [atomic-fixed-point-bucket, bounded-ets-admission]
affects: [core-rate-limiter, inbound-rate-limiter]
tech-stack:
  added: []
  patterns: [exact-tuple-ets-cas, owner-serialized-admission, injected-monotonic-clock]
key-files:
  created:
    - lib/mailglass/rate_limiter/atomic_bucket.ex
  modified:
    - lib/mailglass/rate_limiter.ex
    - lib/mailglass/rate_limiter/table_owner.ex
    - mailglass_inbound/lib/mailglass_inbound/rate_limiter.ex
    - mailglass_inbound/lib/mailglass_inbound/rate_limiter/table_owner.ex
    - test/mailglass/rate_limiter_test.exs
    - mailglass_inbound/test/mailglass_inbound/rate_limiter_test.exs
decisions:
  - Shared private CAS engine accepts package-local table and owner inputs.
  - Table admission is serialized and fails closed after idle-only reclamation.
metrics:
  tasks_completed: 2
  tests: 23
---

# Phase 156 Plan 01: Atomic and Bounded Rate Limiting Summary

Core and inbound limiter façades now share a fixed-point, exact-key ETS CAS engine that prevents refill overspend while retaining fractional elapsed time.

## Completed Work

- Added fixed-point token accounting using monotonic microseconds, complete observed-state CAS guards, bounded retries, and fail-closed contention handling.
- Routed missing keys through each package's table owner; owners enforce a 100,000-key default, one-hour idle expiry, and 60-second sweeping cadence.
- Preserved the core transactional bypass and both public limiter APIs, named ETS tables, telemetry/error shapes, and inbound's separate configuration namespace.
- Replaced sleep-based refill coverage with injected deterministic clocks and barrier-based concurrent callers.

## Verification

- `mix test test/mailglass/rate_limiter_test.exs test/mailglass/rate_limiter_supervision_test.exs --warnings-as-errors` — 15 tests, 0 failures.
- `cd mailglass_inbound && mix test test/mailglass_inbound/rate_limiter_test.exs --warnings-as-errors` — 8 tests, 0 failures.
- `mix format --check-formatted` — passed.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected the CAS match specification to compare the compound bucket key as well as the complete observed token state.
- **Found during:** Task 2 integration.
- **Fix:** Bound the key in the match specification and compared it using `{:const, key}`; added a two-key concurrent regression so a mutation cannot replace a different bucket.
- **Files modified:** `lib/mailglass/rate_limiter/atomic_bucket.ex`, `test/mailglass/rate_limiter_test.exs`.
- **Commit:** `c1d9849d`, `75f0b2bf`.

## Self-Check: PASSED

- Confirmed the shared engine and both owner modules exist.
- Confirmed implementation commits `254aa0fc`, `9407db0a`, `c1d9849d`, and `75f0b2bf` exist.
