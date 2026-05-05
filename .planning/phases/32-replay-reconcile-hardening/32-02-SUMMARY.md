# Phase 32 Plan 32-02 Summary

## Outcome

Replay wording now flows through one shared presenter seam:
`MailglassAdmin.Operator.RepairState`. Operator surfaces describe replay
availability as `ready`, `choice required`, or `unavailable`; replay
audit outcomes as `requested`, `completed`, or `failed`; and completed
effects as `new work` or `no change`.

## Changes

- Added `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex`
  to centralize replay availability, outcome, effect, flash, and audit
  summary wording.
- Updated `DetailHeader`, `ReplayModal`, `Timeline`, and
  `OperatorLive` to use presenter-driven wording while preserving the
  `Replay audit` badge and replay as the only delivery-detail repair
  action.
- Expanded the existing focused tests to lock the standardized replay
  vocabulary and preserve the durable `:replayed` versus `:noop`
  backend contract.

## Verification

- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors`
- `mix test test/mailglass/operator/timeline_test.exs test/mailglass/webhook/replay_test.exs --warnings-as-errors`
- `rg -n "ready|choice required|unavailable|requested|completed|failed|new work|no change" mailglass_admin/lib/mailglass_admin/operator mailglass_admin/test/mailglass_admin/operator_live_test.exs test/mailglass/operator/timeline_test.exs`

## Deviations

- No replay or reconcile architecture changes were needed.
- No task commits were created. The required files already sat in a
  dirty tree with pre-existing Phase 32-01 edits, especially
  `mailglass_admin/lib/mailglass_admin/operator_live.ex` and
  `mailglass_admin/test/mailglass_admin/operator_live_test.exs`, so an
  atomic task commit would have mixed this plan with unrelated
  in-progress work.
