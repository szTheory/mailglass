# Phase 121 — Deferred Items

Out-of-scope discoveries logged during execution (not fixed — see deviation scope boundary).

## [121-01] Pre-existing warning: operator_live.ex:505 `selected_delivery={nil}`

- **Found during:** Plan 121-01, Task 1 compile gate
- **Issue:** `mix compile --warnings-as-errors` fails on a pre-existing shipped Phase 120 warning — `attribute "selected_delivery" in DeliveriesList.deliveries_list/1 must be a :map, got: nil` at `operator_live.ex:505`. The file is unmodified by this plan (`git diff --stat` empty).
- **Why deferred:** Out of scope per the deviation scope boundary — only auto-fix issues DIRECTLY caused by this task's changes. This is Deliveries (Phase 120) code; the analogous inbound site was fixed by omitting the defaulted attr.
- **Suggested fix:** Omit the explicit `selected_delivery={nil}` (it defaults to nil) in operator_live.ex's deliveries-empty-pane, mirroring the inbound fix.
