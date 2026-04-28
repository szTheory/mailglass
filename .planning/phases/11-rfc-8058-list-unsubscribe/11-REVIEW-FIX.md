---
phase: 11-rfc-8058-list-unsubscribe
review_path: .planning/phases/11-rfc-8058-list-unsubscribe/REVIEW.md
reviewed: 2026-04-28T10:21:36Z
fixed_at: 2026-04-28T11:24:00Z
fix_scope: critical_warning
findings_in_scope: 2
fixed: 2
skipped: 0
iteration: 1
status: all_fixed
commits:
  - c6af5e3
  - 685d0f8
---

# Phase 11 Review Fix Report

## Summary

Resolved both warning-level findings from `REVIEW.md`.

## Fixed

### WR-01: Outbound unsubscribe links now use the persisted delivery id

- Commit: `c6af5e3`
- Updated `Mailglass.Outbound` to assign a stable `delivery_id` before unsubscribe headers are generated and to persist that same id through sync, async, and batch flows.
- Added outbound coverage proving the emitted unsubscribe token verifies to the stored delivery id for both `deliver/2` and `deliver_later/2`.

### WR-02: Controller tamper tests now prove token invalidation before exercising the route

- Commit: `685d0f8`
- Replaced brittle last-character mutation in the controller tests with a helper that mutates a token segment and asserts `Mailglass.Compliance.Unsubscribe.verify_token/1` returns `{:error, :invalid}` before issuing the GET/POST request.

## Verification

- `mix test test/mailglass/compliance/unsubscribe_controller_test.exs`
- `mix test test/mailglass/outbound_test.exs test/mailglass/outbound/deliver_later_test.exs`

## Notes

- The `Info` finding about summary accuracy remains out of scope for `critical_warning` mode.
