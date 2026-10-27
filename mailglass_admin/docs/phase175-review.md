# Phase 175 — Delivery investigation and safe replay review

## Reproduce the current proof

From the repository root, run the existing isolated cold/warm browser job and then check the retained receipts:

```sh
bash scripts/run_demo_browser_evidence.sh --phase174 --phase175 --pilot
node scripts/check_phase175_evidence.cjs --evidence-dir .planning/phases/175-delivery-investigation-and-safe-replay/artifacts/phase175 --pilot
node --test --test-reporter=tap scripts/check_phase175_evidence.test.cjs
```

The runner reuses the Phase 174 isolated Compose project, serial reset, source provenance, browser output and cleanup. The selected current run is `mailglass-evidence-20261027200450-16960-29407`, source revision `8cd973774c293cc3d95b1e8f9be489b5e4ca5caa`, Phase 175 source digest `77fdd45e830c44b07e1062af584414eb4d2c07f2747a7607aa47866cbf81153b`. Durable cold/warm reports, exact expected/executed IDs, input hashes, and captures are in `.planning/phases/175-delivery-investigation-and-safe-replay/artifacts/phase175/`.

The current complete run executed 4 Demo, 10 connected Admin, 10 fidelity, and 26 Axe cases in both cold and warm conditions. All expected cases executed once. Each Axe report has zero violations and 116 separately triaged incomplete findings; incomplete is not a pass. The focused Admin/auth suite passed 353 tests. The existing regression gate passed Node contracts 40/40, core renderer 81/81, Admin LiveView/component 658 tests (0 failures, 1 excluded), Inbound deterministic 480 tests (0 failures, 3 excluded), and 31 connected Operator/Preview cases. The hosted Demo Browser Evidence job remains advisory.

The story route is `http://demo:4015/dev/storybook/delivery_investigation?variation_id=fjordline_long_unicode`; its production CSS is served at `http://demo:4015/dev/mail/css-3cfaf2ff0d2d4bb2c2836397ce8fa6c3`, 137,809 bytes, SHA-256 `4f971db6dd8efa8d5b8af9f3ab27aac5f5abd6b3ac8cda6db03dc8af603d1359`. All six Inter, Inter Tight and IBM Plex Mono WOFF2 faces loaded with matching source hashes. Storybook uses an inline `about:srcdoc` iframe with 22,216-byte source; cold/warm SHA-256 values are `6c2907f74203de456601526c63cfa44bb30fa2491fbd5b4cd73a06295fde73c0` and `c4b2efcd7a45576c0480acf87b9e49f72f8097fcd2567998558ad7bff734dbee`; owner and readable parent origins both match `http://demo:4015`. The connected Account route, URL/asset identities, exact case IDs, and source hashes are retained in `phase175/execution.json` and the cold/warm fidelity reports.

## Behavior proved

- Full Delivery and Inbound details display grouped technical evidence without a disclosure action. Current connected cases cover long Unicode content and narrow/200% zoom wrapping.
- Suppression refresh is Account-scoped and distinguishes ready, empty, stale retained facts and unavailable reads. Unknown expiry stays unknown; removal language does not invent a control.
- Delivery and Inbound replay reviews preserve exact record and Account identity. Unavailable, stale, denied, ambiguous, failed, successful and no-change outcomes keep their domain-specific facts and protections.
- The existing durable demo replay now asserts its accessible toast and the actual persisted no-change audit result. The toast names the result; it does not claim provider delivery. Inbound's recorded Mailbox result remains separate from a queued request.
- Replay failure remains visible in the open review with a safe retry/fresh-review path. Close, Escape, focus containment and return to the initiating detail trigger are covered.

Exact requirement-to-case mapping, all selected/executed IDs, accessibility history and CI/cost limits are in [175-AUTOMATION.md](../../.planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md).

## Current limits

The retained reports are local Chromium evidence for the named case inventory and source revision. They do not establish a hosted CI run or a hosted runner-minute cost. The existing `Demo Browser Evidence (Docker Compose / Chromium)` job consumes the combined selector but remains outside required branch-protection contexts. Incremental Phase 175 local attribution is 45,255 ms (0.75425 minutes), including the cold/warm selected operator runs and checker overhead; it is not total combined-workflow runtime. The provisional five-minute added wall / ten-minute runner budgets do not replace a future hosted measurement.

The current reports retain 116 Axe incomplete findings per condition, with zero violations and zero untriaged findings. Two additional Light/Dark incomplete fingerprints appeared after technical details became visible by default; independent rendered checks measured contrast above the stated minimum, but those Axe results remain incomplete. The older 114 report and the failed untriaged 116 report remain separately retained for review.

Machine-observable acceptance closes under D-52 without owner UAT. Descriptor-less prohibition flags remain flagged-unverified. Final STORY-07/UIQ reconciliation remains assigned to Phase 178.
