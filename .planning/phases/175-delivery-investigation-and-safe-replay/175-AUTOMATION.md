# Phase 175 automated proof and reproduction

This record closes the Phase 175 machine-observable requirements against the retained current-source cold/warm receipts. It does not claim provider delivery, hosted CI execution, or an owner aesthetic verdict. Deterministic acceptance is automated under METHODOLOGY.md D-52.

## Reproduce and check

From the repository root, with Docker Compose and the existing pinned toolchains available:

```sh
bash scripts/run_demo_browser_evidence.sh --phase174 --phase175 --pilot
node scripts/check_phase175_evidence.cjs --evidence-dir .planning/phases/175-delivery-investigation-and-safe-replay/artifacts/phase175 --pilot
node --test --test-reporter=tap scripts/check_phase175_evidence.test.cjs
node --test --test-reporter=tap scripts/check_phase174_evidence.test.cjs
bash scripts/gsd-regression-gate.sh
```

The wrapper owns one isolated Compose project and test database, serial cold/warm resets, one browser worker, source hashing, receipt validation, and teardown. It composes Phase 175 with the established Phase 174 runner and checker. The persisted demo test can also be run by itself:

```sh
ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix reference/demo_app/assets run test:e2e -- --grep "outbound replay from the demo"
```

The current isolated Admin/auth run used `MIX_ENV=test`, `POSTGRES_HOST=demo_db`, `POSTGRES_USER=postgres`, `POSTGRES_PASSWORD=postgres`, a run-specific `MIX_BUILD_PATH`, and the Phase 175 browser-test database. The focused operator/component/Inbound/auth tests and subsequent correction tests passed; the full counts are in [175-REVIEW-FIXES.md](175-REVIEW-FIXES.md). The complete current-source browser selection and persisted demo outcome are included in the run below. The full regression gate passed Node contracts 42/42, core renderer 81/81, Admin LiveView/component 661 tests (0 failures, 1 excluded), Inbound deterministic 480 tests (0 failures, 3 excluded), and connected Operator/Preview browser cases 31/31.

## Current-source run identity and coverage

| Field | Cold | Warm |
| --- | --- | --- |
| Run ID | `mailglass-evidence-20261027221513-96275-31939-cold` | `mailglass-evidence-20261027221513-96275-31939-warm` |
| Source revision | `0deab1a14e28a8fb32d06a7d9e864d8d0fe508a0` | same |
| Phase 175 source digest | `d01817a07796768cbf874ba35715aa3945a3f59971104b362e82417244901fa7` | same |
| Phase 174 source digest | `13694a3171535116a61d8ef3ed8c102cb5a664ef1d5c53fc9d401c58ba1d681c` | same |
| Expected / executed | Demo 4/4; Admin 10/10; fidelity 10/10; Axe 26/26 | same |
| Layout checks | Delivery 6/6; Inbound 6/6 | same |
| Axe outcome | 0 violations; 116 incomplete, separately triaged | same |

The exact selected and executed inventories, including source locations, are in `artifacts/phase175/phase175/execution.json`; the case reports are beside it under `phase175/{cold,warm}/`. The checker requires exact nonempty expected/executed IDs and rejects missing, malformed, duplicate, unexpected, failed, skipped, stale-source, and wrong-source evidence. It decodes every required PNG and binds its pixel width and minimum height to the observed viewport, DPR, browser zoom, screenshot scale, document width, and measured body content height. Its seven Phase 175 Node tests pass, including representative 320×2153, 1440×1363, and 640×4316 PNG fixtures plus wrong-width, 1×1, too-short, corrupt-image, and adversarial-path cases. The independent earlier 116-incomplete report remains retained for triage, and the failed report with two untriaged findings remains marked failed. All current reports are retained after the isolated Compose project and volumes were removed; `phase175/run.json` records completed cleanup and volume removal.

### Captured screenshot geometry

Both cold and warm receipts contain the same observed capture geometry:

| Capture | PNG pixels | Observed CSS viewport | DPR / screenshot scale | Document width | Measured body content height |
| --- | ---: | ---: | ---: | ---: | ---: |
| 320px responsive | 320×2153 | 320×1924 | 1 / 1 | 320 | 2153 |
| 1440px responsive | 1440×1363 | 1440×1924 | 1 / 1 | 1440 | 1363 |
| Actual 200% browser zoom | 640×4316 | 320×2324 effective; 1440×900 initial | DPR 2 initial, 4 effective / 2 | 320 | 2157 |

The zoom capture therefore has a minimum required image height of 4314 pixels from the observed content height and scale; its decoded height is 4316. The checker compares these observed receipts instead of relying on hard-coded device-specific dimensions.

The fresh combined runner exited 0 against revision `0deab1a14e28a8fb32d06a7d9e864d8d0fe508a0`; both Phase 174 and Phase 175 cold/warm receipt checkers pass against the durable copies. The monitored `reference/demo_app/mix.lock` SHA-256 stayed `1472692952d9ddbd91df7a116a4b5cf28f717ca3369a7a04bf80cc94b39711d7` before and after the 450.753-second run. A preceding run exposed the cause: Compose started `mix deps.get` against the read/write workspace bind and resolved newer compatible versions of `boundary` and `websock_adapter`, making the final selected-source digest stale. `reference/demo_app/mix.exs` now constrains these already-locked versions with `override: true`, and the Demo startup runs `mix deps.get --check-locked`. An isolated `MIX_ENV=dev mix deps.get --check-locked` probe selected boundary 0.11.0 and websock_adapter 0.6.0 and left the lock byte-identical. The final runner stdout is retained in `artifacts/phase175/runner-success-mailglass-evidence-20261027221513-96275-31939.log`, and the isolated probe transcript is `artifacts/phase175/dependency-resolution-probe.log`. The exact lock delta and historical failure markers remain under `artifacts/phase175/runner-failures/`; those failed runs are history, not current proof.

### Named Demo and connected Admin cases

Each cold/warm condition executed these four Demo cases:

- `delivery-investigation.spec.js:23:Phase 175 retained Delivery scenario inventory and production composition`
- `delivery-investigation.spec.js:128:Phase 175 connected Delivery empty states use exact headings, guidance, and actions`
- `outbound-replay.spec.js:19:outbound replay from the demo completes and records a durable no-change outcome`
- `storybook-fidelity.spec.js:859:Phase 175 fidelity: current Delivery story, connected focus, assets, themes and actual zoom`

Each condition executed these ten Admin cases:

- `flows.spec.js:1586:Phase 175 Delivery tracer`
- `flows.spec.js:1689:Phase 175 Delivery recovery`
- `flows.spec.js:1773:Phase 175 Delivery safety keeps exact target, denial and no-change outcomes visible`
- `flows.spec.js:1917:Phase 175 Delivery layout U1/U2/U3/U5/U6: technical wrapping, reachable replay review and real zoom`
- `flows.spec.js:2113:Phase 175 suppression refresh`
- `flows.spec.js:2187:Phase 175 suppression policy`
- `phase175-inbound.spec.js:60:Phase 175 Inbound full: confirm reports recorded Mailbox outcome and refreshes evidence`
- `phase175-inbound.spec.js:121:Phase 175 Inbound full: Escape closes review and returns focus to its detail trigger`
- `phase175-inbound.spec.js:132:Phase 175 Inbound quick: review preserves Account, filters, selection and keyboard context`
- `phase175-inbound.spec.js:176:Phase 175 Inbound layout U1/U2/U3/U5/U6: Unicode subject, Mailbox and replay at real zoom`

The fidelity inventory is exactly `story:delivery-investigation-fjordline-long-unicode`, `theme:delivery-investigation:system-light-dark-and-explicit-stability`, `fidelity:delivery-investigation:320:dark`, `fidelity:delivery-investigation:375:light`, `fidelity:delivery-investigation:768:dark`, `fidelity:delivery-investigation:1280:light`, `fidelity:delivery-investigation:1440:dark`, `assets:storybook-css-and-six-font-faces`, `fidelity:delivery-investigation:real-200-percent-zoom`, and `hook:storybook-host-connected-and-production-quick-view-focus-return`. Each ID is selected and executed exactly once per condition.

The 26 Axe IDs are the following 13 scenario/state pairs, each run in both `light` and `dark`: `qv-delivery-normal::normal`, `qv-delivery-first::first`, `qv-delivery-last::last`, `qv-delivery-single-unicode::single-unicode`, `delivery-investigation-northstar-normal::normal-permitted-review`, `delivery-investigation-fjordline-long-unicode::long-unicode`, `delivery-investigation-suppression-stale::stale-retained-match`, `delivery-investigation-replay-ambiguous::replay-ambiguous`, `qv-inbound-normal::normal`, `qv-inbound-first::first`, `qv-inbound-last::last`, `qv-inbound-single-unicode::single-unicode`, and `qv-inbound-unavailable::unavailable`. The two route-only empty scenarios remain explicitly excluded from the isolated Storybook Axe inventory.

## Actual route, iframe, assets, and layout

The checked story route is `http://demo:4015/dev/storybook/delivery_investigation?variation_id=fjordline_long_unicode`. The Storybook frame is inline `about:srcdoc` (no `src` attribute), document origin `null`; its owner and readable parent origin are both `http://demo:4015`. Cold `srcdoc` is 22,213 bytes with SHA-256 `9c21e24f5a53a9dfbfeb9cef0674510e48473ec56cc7c99a266b7375b22ac741`; warm is the same size with SHA-256 `05a7814d7e08445a1da490524722f45ccaca4fb48038506c537a387e2810083e`. This records the actual iframe source and parent-access result for the current frame mode.

The connected route is Account-scoped at `http://demo:4015/ops/mail?delivery_id=01a17f2a-5e7f-7708-9df6-cd23387ab35a&tenant_id=northstar&window_hours=168` in cold evidence and `http://demo:4015/ops/mail?delivery_id=01a17f2d-45da-7056-bfe7-957135e0b1a7&tenant_id=northstar&window_hours=168` in warm evidence. Both point to the current Delivery route and each condition records connected hook and focus-return proof.

| Served asset | Current URL | Identity |
| --- | --- | --- |
| Production CSS | `http://demo:4015/dev/mail/css-21549168ce191c96f1ac179e72be0631` | 137,731 bytes; SHA-256 `25d98d52acc81cd0a797011b4160e5a3c4a7a8d8fa42929cb15a262bdd839a00`; HTTP 200 and matches built CSS |
| Inter 400 | `http://demo:4015/dev/mail/fonts/inter-400.woff2` | SHA-256 `384c8fc185e86cb09d4536a12ec8092363502350373bdd067352a3111ac5f626` |
| Inter 700 | `http://demo:4015/dev/mail/fonts/inter-700.woff2` | SHA-256 `ec6aab29115563f7a189c0df4e09df2f78bc773893a663d69fde2a01bb1169a0` |
| Inter Tight 400 | `http://demo:4015/dev/mail/fonts/inter-tight-400.woff2` | SHA-256 `13b7701a70fa25bcb4779872af7324f35d3c790bd632acaaa1b2c832b92e17be` |
| Inter Tight 700 | `http://demo:4015/dev/mail/fonts/inter-tight-700.woff2` | SHA-256 `b22c0b7ab571ec8b221c07b795b725a4d23d4a55c07304cc988d41946ebb7258` |
| IBM Plex Mono 400 | `http://demo:4015/dev/mail/fonts/ibm-plex-mono-400.woff2` | SHA-256 `6fb6d369366499c3cb499183ba9fdebb3ccbbc259d8ebcd7d738519d9574d340` |
| IBM Plex Mono 700 | `http://demo:4015/dev/mail/fonts/ibm-plex-mono-700.woff2` | SHA-256 `bedf8f843a0b5c1b7cf9efcc12590a2dfffc8a7b806ffff73ad1ebebf260078a` |

All six WOFF2 faces loaded. The story-owned System preference resolved from the live OS dark preference; the fidelity suite also selects explicit Light and Dark and checks stable owner state. Delivery and Inbound each executed six layout cases spanning 320, 375, 768, 1280, and 1440 CSS-pixel widths. The 200% browser tab zoom produced an effective 320-pixel viewport and document width of 320 pixels for the Storybook capture. Durable screenshots and the source-bound fidelity receipts are under `artifacts/phase175/phase175/{cold,warm}/`.

## Requirement proof pointers

| Requirement | Status and exact proof entry |
| --- | --- |
| UXF-12 | Automated: [Technical evidence](#technical-evidence-uxf-12); Demo story and both Admin detail surfaces are source-bound and separately exercised. |
| OUTUX-07 | Automated: [Suppression refresh and policy](#suppression-refresh-and-policy-outux-07-outux-08), including external changes, stale retained evidence, unavailable reads and scoped retry. |
| OUTUX-08 | Automated: [Suppression refresh and policy](#suppression-refresh-and-policy-outux-07-outux-08), including unknown expiry and read-only removal wording. |
| REPLAY-04 | Automated: [Replay path](#replay-path-replay-04-through-replay-08), exact quick/full selection in both domains. |
| REPLAY-05 | Automated: [Replay path](#replay-path-replay-04-through-replay-08), unavailable reason ordering and stale/denied exact-target rejection. |
| REPLAY-06 | Automated: [Replay path](#replay-path-replay-04-through-replay-08), shared shell, named Close, Escape, focus containment and trigger return. |
| REPLAY-07 | Automated: [Replay path](#replay-path-replay-04-through-replay-08), actual-result toast and durable outcome; Inbound result remains separately described. |
| REPLAY-08 | Automated: [Replay path](#replay-path-replay-04-through-replay-08), inline error, explicit retry/fresh review and duplicate/stale safety. |

### UI acceptance proof matrix

Every row below maps the validation predicate to the current-source case or test suite that exercises its acceptance family. The full exact selected/executed case IDs and receipts remain in `phase175/execution.json` and the condition reports.

| UI predicate | Current automated proof |
| --- | --- |
| U1/empty | `delivery-investigation.spec.js#Phase 175 connected Delivery empty states use exact headings, guidance, and actions`; `operator_live_test.exs` empty/stale/unavailable assertions; `inbound_live_test.exs` empty/error distinctions. |
| U1/loading | `flows.spec.js#Phase 175 suppression refresh` and `flows.spec.js#Phase 175 Delivery recovery`; server suite also covers in-flight/duplicate replay guards. |
| U1/error | `flows.spec.js#Phase 175 Delivery recovery`; `flows.spec.js#Phase 175 suppression refresh`; `phase175-inbound.spec.js#Phase 175 Inbound full: confirm reports recorded Mailbox outcome and refreshes evidence`. |
| U1/populated | `flows.spec.js#Phase 175 Delivery tracer`; `phase175-inbound.spec.js#Phase 175 Inbound quick: review preserves Account, filters, selection and keyboard context`; `delivery-investigation.spec.js#Phase 175 retained Delivery scenario inventory and production composition`. |
| U1/partial | `operator_live_test.exs#Phase 175 suppression policy states removal support, unknown expiry, and safe missing values`; `inbound/components_test.exs#full Inbound technical facts stay open with long Unicode identifiers`. |
| U1/overflow | `flows.spec.js#Phase 175 Delivery layout U1/U2/U3/U5/U6: technical wrapping, reachable replay review and real zoom`; `phase175-inbound.spec.js#Phase 175 Inbound layout U1/U2/U3/U5/U6: Unicode subject, Mailbox and replay at real zoom`; fidelity 320/200% cases. |
| U1/zero-one-many | `delivery-investigation.spec.js#Phase 175 retained Delivery scenario inventory and production composition`; `operator_live_test.exs#Phase 175 Delivery entry keeps same-looking ambiguous requests separate`; expected/executed fidelity IDs include first/last/single and exact story identities. |
| U1/long-text | Delivery and Inbound layout cases above; fidelity cases `fidelity:delivery-investigation:320:dark`, `fidelity:delivery-investigation:real-200-percent-zoom`. |
| U2/overflow | Delivery and Inbound layout cases above; both receipts record width and document-width results for the 320px boundary and real 200% browser zoom. |
| U2/long-text | Delivery and Inbound layout cases above; `storybook-fidelity.spec.js#Phase 175 fidelity: current Delivery story, connected focus, assets, themes and actual zoom`. |
| U3/empty | `delivery-investigation.spec.js#Phase 175 connected Delivery empty states use exact headings, guidance, and actions`; `flows.spec.js#Phase 175 suppression policy`; server empty-state tests in Operator and Inbound suites. |
| U3/loading | `flows.spec.js#Phase 175 suppression refresh`; replay pending/consumed duplicate guards in `operator_live_test.exs` and `inbound_live_test.exs`. |
| U3/error | `flows.spec.js#Phase 175 Delivery recovery`; `flows.spec.js#Phase 175 suppression refresh`; Inbound full confirmation case above. |
| U3/populated | Delivery tracer and Inbound quick browser cases above; `delivery-investigation.spec.js#Phase 175 retained Delivery scenario inventory and production composition`. |
| U3/partial | `flows.spec.js#Phase 175 suppression policy`; `components_test.exs` and `inbound/components_test.exs` missing/empty-value rendering assertions. |
| U3/overflow | Delivery and Inbound layout cases above; fidelity viewport/zoom receipts. |
| U3/zero-one-many | Retained Delivery scenario inventory; `operator_live_test.exs#Phase 175 Delivery entry keeps same-looking ambiguous requests separate`; exact 26-case Axe inventory keeps each distinct story state/theme pair. |
| U3/long-text | Delivery and Inbound layout cases above; fidelity 320px and real 200% zoom cases. |
| U4/loading | `phase175-inbound.spec.js#Phase 175 Inbound full: confirm reports recorded Mailbox outcome and refreshes evidence`; `phase175-inbound.spec.js#Phase 175 Inbound quick: review preserves Account, filters, selection and keyboard context`; Inbound LiveView replay review tests. |
| U4/error | Inbound full confirmation case; `operator_live_test.exs#Phase 175 Delivery recovery re-reviews the exact request after command failure`; connected error stays in the open review. |
| U4/long-text | `phase175-inbound.spec.js#Phase 175 Inbound layout U1/U2/U3/U5/U6: Unicode subject, Mailbox and replay at real zoom`; Delivery layout case and 320/200% fidelity evidence. |
| U5/empty | Demo connected empty-state case; `flows.spec.js#Phase 175 suppression policy`; Operator and Inbound LiveView empty/unavailable assertions. |
| U5/loading | Inbound full/quick cases; `flows.spec.js#Phase 175 Delivery recovery`; replay pending and duplicate assertions in both LiveView suites. |
| U5/error | Delivery recovery; Inbound full confirmation; `flows.spec.js#Phase 175 suppression refresh`. |
| U5/partial | `operator_live_test.exs#Phase 175 suppression policy states removal support, unknown expiry, and safe missing values`; `inbound/components_test.exs#full Inbound technical facts stay open with long Unicode identifiers`. |
| U5/overflow | Delivery and Inbound layout cases above; fidelity real 200% zoom receipts. |
| U5/long-text | Delivery and Inbound layout cases above; fidelity 320px and 200% zoom captures. |
| U6/overflow | Delivery and Inbound layout cases above; reports record 320/375/768/1280/1440 widths and 2x zoom effective width. |
| U6/long-text | Delivery and Inbound layout cases above; long Unicode Storybook case plus connected Inbound Mailbox case. |

### Technical evidence (UXF-12)

The Demo retained scenario, fidelity route, and Admin browser layout cases are listed above. The full focused Admin/auth run includes `operator_live_test.exs`, `components_test.exs`, `inbound_live_test.exs`, `inbound/components_test.exs`, and `auth_actions_contract_test.exs` (353 tests, no failures). Specific proof sources are `MailglassAdmin.Operator.DetailHeader`, `MailglassAdmin.Inbound.DetailHeader`, `flows.spec.js#Phase 175 Delivery layout`, `phase175-inbound.spec.js#Phase 175 Inbound layout`, and the fidelity receipt’s connected route and 320/200%-zoom screenshots. Technical facts are visible without expansion; missing and long Unicode values use the bounded presentation.

### Suppression refresh and policy (OUTUX-07, OUTUX-08)

The selected cases are `flows.spec.js#Phase 175 suppression refresh` and `flows.spec.js#Phase 175 suppression policy`. The corresponding server/component cases are in `mailglass_admin/test/mailglass_admin/operator_live_test.exs` and `components_test.exs`. The separate scenario IDs are `delivery-investigation-suppression-stale`, `delivery-investigation-suppression-unavailable`, and `delivery-investigation-unknown-expiry`. The evidence distinguishes fresh, empty, stale-retained, and unavailable reads; a retry is Account-scoped and real. Unknown expiry is not represented as permanent, and removal is explained without an invented mutation control.

### Replay path (REPLAY-04 through REPLAY-08)

The exact Demo durable success is `outbound-replay.spec.js#outbound replay from the demo completes and records a durable no-change outcome`; the final selected Demo run proves the no-change branch and a durable actual audit result, and the existing reset-token guard/grants remain intact. The connected cases are the ten Admin names above, especially Delivery tracer/recovery/safety and Inbound full/quick. Server proofs remain in `operator_live_test.exs` and `inbound_live_test.exs`; the auth-actions contract suite remains in the focused command. Toast text reports the actual result. It does not claim that a provider delivered mail. Inbound replay records its Mailbox outcome separately from a queued request.

## Axe incomplete findings and history

Current cold and warm reports each contain 116 Axe incomplete findings, zero violations, zero unapproved violations, and zero untriaged findings. Incomplete findings remain incomplete and are not counted as violations or as a clean accessibility pass. Current independently reviewed supplements are in the checked `phase175/{cold,warm}/axe.json`; current approval and review records remain in `mailglass_admin/docs/storybook-axe-approved.json`.

| Retained report | Source identity | Recorded result | File SHA-256 |
| --- | --- | --- | --- |
| Prior 114-incomplete receipt | revision `e3e9b4bf377e580e0cce37e071ebc7d60852a1fb`; digest `1d20bcbcecd6af9ca1d6d8822c6b902e7a597399dc63ef5598d316c2ab608bbb` | 114 incomplete; prior committed review | `93d342f6f836d17a6f2ab42c89fb1d59c93de44f0c4a617ee78c7ad809d8cdbc` |
| Failed 116-incomplete run | revision `5d581f906864652b16fc2b5c99e95e75833bfc86`; digest `bb0739ed948da68f2d4bfc11a1ccc88700d45b659bd21a295b7a039674718884` | 116 incomplete, 2 untriaged; retained as failed evidence | `42c23f0c7f60fc67a34163b174f6bc886f1cc6dfaa1ca97f3da0e5f24ab16f64` |
| Independent Axe 116 run | same revision and digest as failed run | 26/26 cases, 0 violations, 116 incomplete; independent rendered review | `8e2a4f8a592fd98422030f0672a7b04ffe6a1a87b1e0892e5f4390f92de97a8a` |

The failed 116-incomplete report has exactly two new fingerprints relative to the prior 114 report and removes none: `color-contrast` on `[".min-w-0:nth-child(2) > .mono.mt-1.break-all"]`, scenario `delivery-investigation-northstar-normal`, state `normal-permitted-review`, once in Light and once in Dark. Phase 175-01 intentionally made grouped technical details visible by default, so Axe now observes the provider event ID that was hidden when the earlier report was measured. An independent current-source run repeated the finding. Rendered supplemental sampling measured 17.393900941155273:1 in Light and 14.09097818327338:1 in Dark at 16px/400 against a 4.5:1 minimum. The samples are explanatory triage only; both findings remain Axe-incomplete. The earlier failed report is not replaced by the later passing checker run.

## Feedback and ownership

`fb-technical-details`, `fb-suppression-refresh`, and `fb-replay-review` are automated with scenario IDs and this record’s anchors in `reference/persona_spec/quick_view_scenarios.json`. Other Phase 175 feedback rows were left unchanged. `fb-storybook-fidelity` remains partial with final STORY-07/UIQ ownership in Phase 178. The eight descriptor-less prohibition-recall flags in the plans remain `flagged-unverified`; no check descriptor was fabricated and positive behavior tests do not silently clear them.

## Placement, cost, and limits

The checker tests are in the existing `scripts/gsd-regression-gate.sh` and the existing GitHub Actions `Demo Browser Evidence (Docker Compose / Chromium)` job. That job runs the current combined selector and uploads its owned artifacts; it adds no required branch-protection context. No hosted run or hosted runner-minute measurement was observed for this revision. The provisional ceilings remain five added wall minutes and ten runner minutes, but only the local wall observation below is measured.

The runner records **44,408 ms (0.74013 minutes) of attributable incremental local Phase 175 wall time** across cold/warm selected operator runs: 23,933 ms cold and 20,358 ms warm, plus checker overhead. This is within the provisional five-minute added wall allowance. The figure is only the attributable Phase 175 increment; it is not total combined-workflow wall time or a hosted runner-cost estimate. Phase 174 setup, browser installation, Demo/Axe scans, and teardown are retained separately and are not charged again to Phase 175. Teardown completed in 2,280 ms and removed the owned volumes. The local run used the isolated `mailglass_demo_phase175_05` database because the default Demo DB retained a migration ledger without the Demo schema; the default database was not repaired or modified.

The selected evidence covers the declared current Chromium/viewport/theme/state inventory, not all browsers, devices, operating systems, or every viewport/theme Cartesian combination. Story rendering proves presentation; connected routes and server tests prove selected actions and recorded outcomes. The CI job remains outside required contexts; no hosted CI execution or hosted runner cost is claimed. Axe incomplete findings remain incomplete, and eight descriptor-less prohibition-recall flags remain flagged-unverified. Phase 178 retains STORY-07/UIQ final ownership.
