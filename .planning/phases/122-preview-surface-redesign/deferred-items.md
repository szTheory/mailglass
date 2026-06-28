# Deferred Items — Phase 122

## Plan 122-01

- **[Out of scope] Pre-existing warnings-as-errors failure in `operator_live.ex:505`**
  - `mix compile --warnings-as-errors` fails on `attribute "selected_delivery" ... must be a :map, got: nil` in `MailglassAdmin.Operator.DeliveriesList.deliveries_list/1`.
  - Pre-existing in committed code (HEAD, introduced phase 120 commit e59a6e5f), NOT caused by this plan. `preview_live.ex` itself compiles clean.
  - Not fixed here per scope boundary (only auto-fix issues directly caused by this task's changes).
