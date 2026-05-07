# Phase 29-02 Summary: Webhook & Idempotency Assertions

Completed the implementation of high-level webhook test helpers, resolving integration friction for simulating provider callbacks.

## Changes

### `test/support/webhook_case.ex`
- Implemented `assert_webhook_processed(provider, fixture_name, opts)` macro:
    - Loads provider-specific fixtures dynamically.
    - Dispatches through the `Mailglass.Webhook.Plug` pipeline.
    - Verifies 2xx response and waits for PubSub broadcast.
- Implemented `assert_webhook_idempotent(provider, fixture_name, opts)` macro:
    - Verifies that a duplicate payload returns 2xx but suppresses duplicate PubSub signals.
- Implemented `assert_delivery_state(id, status)` macro:
    - Checks both `delivery.status` and `delivery.last_event_type` for flexible state assertions.
- Implemented `assert_delivery_event_count(id, count)` macro:
    - Verifies the number of events linked to a delivery.

### `lib/mailglass/webhook/plug.ex`
- Fixed `KeyError` by correctly accessing provider from event metadata.
- Implemented replay detection in `broadcast_post_commit/1` to skip PubSub broadcasts for events already present in the ledger (D-03).

### `test/support/webhook_case_test.exs`
- Created a comprehensive test suite for the new helpers.
- Verified successful matching, state updates, and idempotency protection.

## Verification Results

- `mix test test/support/webhook_case_test.exs` PASSED.
- Verified that `Projector` updates `last_event_type` and `terminal` correctly when given valid monotonic timestamps.
- Verified that duplicate webhooks are ingested as replays with no duplicate side effects.

## Requirement Coverage
- [x] TEST-02: User can simulate and assert webhook handling easily in tests.
