# Phase 73 — Inbound Release Checklist

## Repo-proved before publish

1. `mix mailglass.publish.check --package mailglass_inbound` exits 0.
   Proof fields:
   - Exit status: 0
   - Summary path: `.planning/publish/mailglass_inbound-publish-summary.json`

2. `mix verify.stability_contract` green (inbound-preflight-consistency test passes).
   Proof fields:
   - Result: 6 tests, 0 failures (run: `mix test test/mailglass/stability_contract_test.exs`)

3. `.planning/publish/mailglass_inbound-publish-summary.json` reviewed.
   Proof fields:
   - `source_ref`: `v1.0.0`
   - `source_ref_pattern`: `mailglass_inbound-v%{version}`
   - Publish pin: `mailglass_inbound_publish_pin: "== 1.3.0"`

## Manual/external proof

1. Fallback dispatch if publish fan-out fails.
   Proof fields:
   - Fallback dispatch used: not run
   - Fallback tag: not run
   - Fallback workflow run URL: not run

2. Live package and docs verification.
   Proof fields:
   - Hex URLs: pending
   - HexDocs URLs: pending

3. 60-minute smoke and release decision window.
   Proof fields:
   - Post-publish smoke run URL: not run
   - Smoke start time: pending
   - Smoke decision time: pending
   - 60-minute outcome: not run

Use `73-01-RELEASE-RECORD.md` to store the filled values above.
