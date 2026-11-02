# Phase 175 — Delivery investigation and safe replay review

## Reproduce the current proof

From the repository root, run the existing isolated cold/warm browser job and then check the retained receipts:

```sh
bash scripts/run_demo_browser_evidence.sh --phase174 --phase175 --pilot
node scripts/check_phase175_evidence.cjs --evidence-dir .planning/phases/175-delivery-investigation-and-safe-replay/artifacts/phase175 --pilot
node --test --test-reporter=tap scripts/check_phase175_evidence.test.cjs
```

The runner reuses the Phase 174 isolated Compose project, serial reset, source provenance, browser output and cleanup. The current retained run is `mailglass-evidence-20261027205816-4815-29177`, source revision `fc262b989c1c38ab86376437ff2dc4b1ef4ea9a8`, Phase 175 source digest `0700f87bb124f955131e20fd8f69fcf87c0a50a499aa636d954b49dc9400eedb`, and Phase 174 source digest `7ee933bd225c6f8ae0ddf04aaa6edf2c4b07ebb99cf7cede21972e6e970897ae`. Durable cold/warm reports, exact expected/executed IDs, input hashes, and captures are in `.planning/phases/175-delivery-investigation-and-safe-replay/artifacts/phase175/`.

The current complete run executed 4 Demo, 10 connected Admin, 10 fidelity, and 26 Axe cases in both cold and warm conditions. All expected cases executed once. Delivery and Inbound each passed six layout cases across the five declared widths, including actual 200% browser zoom. Each Axe report has zero violations and 116 separately triaged incomplete findings; incomplete is not a pass. Focused Admin/UI/checker tests are listed in `175-REVIEW-FIXES.md`. The existing regression gate passed Node contracts 41/41, core renderer 81/81, Admin LiveView/component 661 tests (0 failures, 1 excluded), Inbound deterministic 480 tests (0 failures, 3 excluded), and 31 connected Operator/Preview cases. The hosted Demo Browser Evidence job remains advisory.

The story route is `http://demo:4015/dev/storybook/delivery_investigation?variation_id=fjordline_long_unicode`; its production CSS is served at `http://demo:4015/dev/mail/css-21549168ce191c96f1ac179e72be0631`, 137,731 bytes, SHA-256 `25d98d52acc81cd0a797011b4160e5a3c4a7a8d8fa42929cb15a262bdd839a00`. All six Inter, Inter Tight and IBM Plex Mono WOFF2 faces loaded with matching source hashes. Storybook uses an inline `about:srcdoc` iframe with 22,213-byte source; cold/warm SHA-256 values are `9c21e24f5a53a9dfbfeb9cef0674510e48473ec56cc7c99a266b7375b22ac741` and `05a7814d7e08445a1da490524722f45ccaca4fb48038506c537a387e2810083e`; owner and readable parent origins both match `http://demo:4015`. The connected Account route, URL/asset identities, exact case IDs, responsive screenshots, and actual 200%-zoom capture are retained in `phase175/execution.json` and the cold/warm fidelity reports.

## Behavior proved

- Full Delivery and Inbound details display grouped technical evidence without a disclosure action. Current connected cases cover long Unicode content and narrow/200% zoom wrapping.
- Suppression refresh is Account-scoped and distinguishes ready, empty, stale retained facts and unavailable reads. Unknown expiry stays unknown; removal language does not invent a control.
- Delivery and Inbound replay reviews preserve exact record and Account identity. Unavailable, stale, denied, ambiguous, failed, successful and no-change outcomes keep their domain-specific facts and protections.
- The existing durable demo replay now asserts its accessible toast and the actual persisted no-change audit result. The toast names the result; it does not claim provider delivery. Inbound's recorded Mailbox result remains separate from a queued request.
- Replay failure remains visible in the open review with a safe retry/fresh-review path. Close, Escape, focus containment and return to the initiating detail trigger are covered.

Exact requirement-to-case mapping, all selected/executed IDs, accessibility history and CI/cost limits are in [175-AUTOMATION.md](../../.planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md).

## Current limits

The retained reports are local Chromium evidence for the named case inventory and source revision. They do not establish a hosted CI run or a hosted runner-minute cost. The existing `Demo Browser Evidence (Docker Compose / Chromium)` job consumes the combined selector but remains outside required branch-protection contexts. Incremental Phase 175 local attribution is 42,290 ms (0.70483 minutes), including the cold/warm selected operator runs and checker overhead; it is not total combined-workflow runtime. The provisional five-minute added wall / ten-minute runner budgets do not replace a future hosted measurement.

The current reports retain 116 Axe incomplete findings per condition, with zero violations and zero untriaged findings. Two additional Light/Dark incomplete fingerprints appeared after technical details became visible by default; independent rendered checks measured contrast above the stated minimum, but those Axe results remain incomplete. The older 114 report and the failed untriaged 116 report remain separately retained for review.

Machine-observable acceptance closes under D-52 without owner UAT. Descriptor-less prohibition flags remain flagged-unverified. Final STORY-07/UIQ reconciliation remains assigned to Phase 178.
