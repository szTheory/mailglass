# Phase 30-02 Summary: Sensible Defaults & Documentation

## Changes
- **Sensible Defaults:** Implemented and enforced default rate limits for all three buckets:
    - `:tenant_recipient`: 100/min
    - `:global_recipient`: 1000/min
    - `:sender_domain`: 500/min
- **Documentation:**
    - Created a new operator guide `guides/rate-limiting.md` explaining the multi-bucket strategy, configuration, and transactional bypass.
    - Updated `README.md` to include the new guide.

## Verification Results
- `mix test test/mailglass/rate_limiter_test.exs`: PASSED (all tests including defaults)
- Manual check: `guides/rate-limiting.md` exists and is comprehensive.

## Success Criteria Status
- [x] Default limits are applied automatically without user configuration.
- [x] Documentation clearly explains the multi-bucket strategy and how to customize it.
