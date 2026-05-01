---
phase: 25
plan: "03"
title: Deliverability analyzers and shared formatter
summary: MX and BIMI analyzers now run alongside SPF, DKIM, and DMARC, and both human and JSON output render from the shared deliverability result contract.
commits:
  - 03dbee9
  - 6f70fe9
files_changed:
  - lib/mailglass/deliverability.ex
  - lib/mailglass/deliverability/mx.ex
  - lib/mailglass/deliverability/bimi.ex
  - lib/mailglass/deliverability/formatter.ex
  - test/mailglass/deliverability/mx_test.exs
  - test/mailglass/deliverability/bimi_test.exs
  - test/mailglass/deliverability/formatter_test.exs
  - test/mailglass/deliverability_test.exs
verification:
  - mix test test/mailglass/deliverability_test.exs test/mailglass/deliverability/mx_test.exs test/mailglass/deliverability/bimi_test.exs --warnings-as-errors
  - mix test test/mailglass/deliverability/formatter_test.exs --warnings-as-errors
---

# Phase 25 Plan 03 Summary

## Outcome

Implemented the remaining DNS analyzers and formatter for Phase 25.

- `Mailglass.Deliverability.run/1` now orchestrates `SPF`, `DKIM`, `DMARC`, `MX`, and `BIMI` explicitly in deterministic order.
- `Mailglass.Deliverability.MX` distinguishes present MX, explicit Null MX, absent MX ambiguity, and malformed MX data.
- `Mailglass.Deliverability.BIMI` evaluates only `default._bimi.<domain>`, treats missing BIMI as `warn`, and threads DMARC posture into BIMI readiness messaging.
- `Mailglass.Deliverability.Formatter` renders grouped human output and stable JSON from the shared `Result` contract.

## Verification

- `mix test test/mailglass/deliverability_test.exs test/mailglass/deliverability/mx_test.exs test/mailglass/deliverability/bimi_test.exs --warnings-as-errors` — passed
- `mix test test/mailglass/deliverability/formatter_test.exs --warnings-as-errors` — passed

## Commits

- `03dbee9` `feat(25-03): add mx and bimi deliverability analyzers`
- `6f70fe9` `feat(25-03): add shared deliverability formatter`

## Deviations from Plan

None. The implementation stayed within the plan-owned files and followed the plan’s DNS-only runtime contract.
