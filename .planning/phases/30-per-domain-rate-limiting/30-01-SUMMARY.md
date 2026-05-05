# Phase 30-01 Summary: Multi-Bucket Rate Limiting

## Changes
- **Config Schema:** Updated `Mailglass.Config` to support three independent rate limit buckets: `:tenant_recipient`, `:global_recipient`, and `:sender_domain`.
- **Backward Compatibility:** Added normalization logic in `Mailglass.Config` and `Mailglass.RateLimiter` to wrap old-style flat rate limit config into the `:tenant_recipient` bucket.
- **RateLimiter Refactor:**
    - Refactored `Mailglass.RateLimiter.check/3` to `check/1` (accepting `%Mailglass.Message{}`).
    - Implemented sequential bucket checks: `tenant_recipient` -> `global_recipient` -> `sender_domain`.
    - Maintained atomic `:ets.update_counter/4` logic with tagged keys to prevent collisions.
    - Added a backward compatibility shim for `check/3`.
- **Outbound Integration:** Updated `Mailglass.Outbound` to call `RateLimiter.check(msg)` in all dispatch paths (sync, async, batch preflight).

## Verification Results
- `mix test test/mailglass/config_test.exs`: PASSED (23 tests)
- `mix test test/mailglass/rate_limiter_test.exs`: PASSED (10 tests, including new multi-bucket cases)
- `mix test test/mailglass/outbound_test.exs`: PASSED (14 tests)

## Success Criteria Status
- [x] All three rate limit types can be configured independently.
- [x] Exhausting any one of the three buckets results in a `RateLimitError`.
- [x] Transactional mail remains unthrottled.
