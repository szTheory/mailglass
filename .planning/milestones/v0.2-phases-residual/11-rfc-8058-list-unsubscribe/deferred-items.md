# Deferred Items

## 2026-04-28

- `mix credo --strict` still fails on pre-existing readability issues outside plan `11-02` scope:
  - `lib/mix/tasks/mailglass.upgrade.v0_2.ex:1`
  - `test/mailglass/upgrade/v0_2_test.exs:1`
  - `lib/mailglass/stream.ex:54`
  - `test/mailglass/stream_test.exs:60`
  - `test/credo_checks/stream_policy_consistent_test.exs:65`
- `mix credo --strict` also reports an existing tenant-scoping warning in `lib/mailglass/compliance/unsubscribe_controller.ex:21`, which belongs to a later Phase 11 slice and was not modified by plan `11-02`.
