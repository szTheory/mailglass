# Phase 169 Pre-Edit Rendered Baseline

Captured 2026-10-07 20:15 EDT, before any production source edits for Phase 169. These captures use the running Phase 168 implementation and the default isolated browser fixture; they are not Phase 168 images or reconstructed mockups.

## Provenance

- **Checkout:** `/Users/jon/projects/mailglass`
- **Revision:** `987ae8c854a9056b6d34fe279bb74f043dc1f68e`
- **Dirty-source manifest before baseline harness:** no dirty product source. Pre-existing workspace changes were `D .planning/.continue-here.md`, `D .planning/HANDOFF.json`, `M .planning/STATE.md`, `M .planning/config.json`, and `M .planning/state.json`. The harness added `mailglass_admin/e2e/phase169-journey.spec.js`; the captures are under this baseline's `artifacts/before/` directory.
- **Runtime:** Erlang/OTP `27.3.4.15`, Elixir `1.18.4` compiled for OTP 27. These installed asdf versions were selected per command; `.tool-versions` was not changed.
- **Browser:** Playwright with HeadlessChrome `147.0.7727.15`; browser platform `MacIntel`, host platform `darwin`; device scale factor `1`, zoom `100%`.
- **Theme and fixture:** System theme; `OperatorFixtures.seed_browser_scenario!/0`, Account `browser-tenant`, with the stored Postmark webhook request `browser-exact-delivery`.
- **Server:** isolated test fixture at `http://127.0.0.1:4102`; the app readiness route returned HTTP 200 and the browser-login route returned HTTP 302 before capture.
- **Served CSS:** `http://127.0.0.1:4102/ops/mail/css-46c5513216b039eb39744c07b419436c`
- **CSS SHA-256:** source `mailglass_admin/assets/css/app.css`: `2810f438d6452966d00f02e4a41cc203f414af6a9cc3a36a17099ae4af87a9f9`; built `mailglass_admin/priv/static/app.css`: `c04faaedbf0bb15352be22f0afa040b7f87119a6a89f59e3d96c2012b6aa42b7`; served response: `c04faaedbf0bb15352be22f0afa040b7f87119a6a89f59e3d96c2012b6`. The test compared the served response bytes to the built asset bytes and passed.

## Capture Method

Command: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 169 pre-edit baseline"`

Result: **2 passed**, one named case for each viewport. The case reset the scenario to the default seed, logged into the selected Account, and captured Health → Deliveries → Quick view → full detail → replay review at 390×1000 and 1440×1000 CSS pixels. The URL-selected Delivery was outside no special query constraints; the captured IDs were `01a118dd-c98b-7fa9-beaf-30c916080437` at 390px and `01a118dd-cf7a-7d84-a80f-3484d76b0ca8` at 1440px. Routes were the mounted `/ops/mail` overview, `/ops/mail?tenant_id=browser-tenant&view=deliveries`, then the same mounted route with the exact `delivery_id` and finally `full=1`. The replay review opened for the seeded exact stored request.

## Before Captures

| State | 390px | 1440px |
|---|---|---|
| Health | [health-390.png](artifacts/before/health-390.png) | [health-1440.png](artifacts/before/health-1440.png) |
| Deliveries | [deliveries-390.png](artifacts/before/deliveries-390.png) | [deliveries-1440.png](artifacts/before/deliveries-1440.png) |
| Quick view | [quick-view-390.png](artifacts/before/quick-view-390.png) | [quick-view-1440.png](artifacts/before/quick-view-1440.png) |
| Full detail | [detail-390.png](artifacts/before/detail-390.png) | [detail-1440.png](artifacts/before/detail-1440.png) |
| Replay review | [replay-review-390.png](artifacts/before/replay-review-390.png) | [replay-review-1440.png](artifacts/before/replay-review-1440.png) |

The browser harness and source/built asset hashes are retained with this record so the before/after comparison can distinguish served styling from checked-out source. These screenshots document the existing implementation only; they do not claim the Phase 169 criteria are already satisfied.

## After Evidence — Plan 169-05

Captured and verified 2026-10-07 from checkout `e45aa8e1b82f97dd45e08c67c9cfe6fdd7f31d68` (Plan 169-05 changes were uncommitted during these runs). The browser fixture was the isolated `seed_browser_scenario!/0` for Account `browser-tenant`, served from `http://127.0.0.1:4102`. The after matrix selected the in-app System theme; Playwright's broader structural suite separately exercises light, dark, System, and reduced-motion emulation. The after run used a 100% Playwright viewport, with the separate native Chrome 200% inspection recorded below.

The browser recorded the exact route sequence Health → Deliveries → Quick view → full detail → replay review at 320, 390, 768, and 1440 CSS px. It saved [health](artifacts/after/health-320.png), [Deliveries](artifacts/after/deliveries-320.png), [Quick view](artifacts/after/quick-view-320.png), [full detail](artifacts/after/detail-320.png), and [replay review](artifacts/after/replay-review-320.png) at each width by substituting `320` with `390`, `768`, and `1440`. Each after capture came from the exact connected app state, not a mock. The before directory and its provenance were not modified; the named immutability assertion checked all ten original before-image checksums during the full browser run.

| CSS viewport | Main content width | Collection view | Page overflow | Body / label | Decorative icons |
|---:|---:|---|---:|---|---:|
| 320 | 320 | Cards | 0 px | 16 / 14 px | 17 hidden from assistive tech |
| 390 | 390 | Cards | 0 px | 16 / 14 px | 17 hidden from assistive tech |
| 768 | 528 | Cards | 0 px | 16 / 14 px | 17 hidden from assistive tech |
| 1440 | 1200 | Table | 0 px | 16 / 14 px | 17 hidden from assistive tech |

The 44 px open-delivery target floor, modal background containment, focused replay review, missing optional logo media, copy/failure behavior, and exact connected route assertions passed. At native Chrome browser zoom **200%**, I inspected Health → Deliveries → Quick view → full detail → replay review in Chrome with DevTools docked. Chrome showed its native 200% zoom setting; the effective CSS viewport was 630×368 at DPR 4 (`visualViewport.scale` 1). Keyboard focus moved visibly from Close replay review into the modal to Cancel. This is actual browser zoom, not a viewport resize or CSS transform. It demonstrates one current route family at that native setting; it does not establish the entire route/theme/touch matrix at 200% or a physical-device result. One transient Chrome `InvalidStateError: Transition was aborted because of invalid state. Viewport size changed` occurred during the dock/zoom route transition and did not reproduce; its cause remains unconfirmed.

### Current asset and revision provenance

- **Checkout revision at test time:** `e45aa8e1b82f97dd45e08c67c9cfe6fdd7f31d68`.
- **Dirty source manifest:** `docs/api_stability.md`; `mailglass_admin/docs/api_stability.md`; `mailglass_admin/e2e/{gallery-matrix,operator,phase168-plan03-acceptance,phase169-journey,structural}.spec.js`; `mailglass_admin/lib/mailglass_admin/{gallery_live,operator/detail_header,operator/timeline}.ex`; `mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs`; `mailglass_admin/test/support/operator_fixtures.ex`; and generated `mailglass_admin/priv/static/app.css`. The 20 new/updated `artifacts/after/*.png` files are intentional captures. The browser harness also regenerated two Phase 168 review-fix captures; the parent confirmed they were clean before this run, and I restored those generated outputs from `HEAD` before handoff. The original three local planning changes (`D .planning/.continue-here.md`, `D .planning/HANDOFF.json`, `M .planning/config.json`) remain untouched and unstaged.
- **CSS source SHA-256:** `8f3b778ecc1a29bda84e78a5c5b7e5b1f060e2be1c9bca5eaa2c1ca0a6791298`.
- **Built and served CSS SHA-256:** `b3eb383048f32a875a8641623db4edb1afd3d2e7c6775097f9429ecf7c2447bd` for both, byte-equal in the browser assertion.
- **Versioned served CSS URL:** `http://127.0.0.1:4102/ops/mail/css-6ca6fae7c95efbf0157c3c8066d8a86d`.
- The browser observed zero non-local requests. Source, built, and served styles were checked against the same run; no remote assets were needed.
- Installed runtime selected without installing packages or changing the committed project pin: Erlang/OTP `27.3.4.15`, Elixir `1.18.4` for OTP 27, Node `22.14.0`. A temporary local `.tool-versions` override was removed after commands because the repository's exact Erlang/Elixir patch pins are not installed in this environment.

### Final verification at this checkout

| Command / selection | Result | Runtime |
|---|---|---:|
| `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 169 rendered"` | 2 passed, 0 failed | 5.5 s |
| `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 169 connected"` | 9 passed, 0 failed | 14.3 s |
| Core operator selection, seed 1 (`deliveries_test`, `timeline_test`, `support_summary_test`, `suppressions_test`, `replay_targets_test`) | 39 passed, 0 failed, 0 excluded | 38 s command wall; ExUnit 0.2 s |
| `(cd mailglass_admin && MIX_ENV=test mix test --seed 1)` | 537 passed, 0 failed, 1 excluded | 5 s command wall; ExUnit 4.5 s |
| `(cd mailglass_admin && MIX_ENV=test mix mailglass_admin.assets.build)` | Passed | 1 s |
| Admin token parity and bundle tests, seed 1 | 9 passed, 0 failed | 1 s command wall; ExUnit 0.09 s |
| `BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser` (unfiltered; includes `operator.spec.js`, `flows.spec.js`, gallery, structural, Phase 168 and Phase 169 cases) | 197 passed, 0 failed, 1 skipped of 198 tests | 2.7 min |

The final unfiltered browser run rebuilt assets before tests and again asserted the served stylesheet bytes equal `priv/static/app.css`. The two initial non-elevated browser launch attempts failed before test bodies because macOS denied Chromium's MachPortRendezvous startup; the authorized host-process reruns above passed. The first final Admin run also caught one stale fail-closed manifest citation for the renamed responsive browser test. I updated the citation and reran the complete Admin suite successfully. Neither setup issue was counted as a passing test.

### Visual review and bounded corrections

I applied the Impeccable and Emil design-engineering reviews, then visually inspected the after captures at 320 px Health, 768 px Deliveries and full detail, and 1440 px replay review. Essential labels and controls remained visible; the 768 px app uses cards because its actual main content is 528 px, while the 1440 px app uses the table at 1200 px of content. The modal backdrop and reviewed target/request/action groups remain distinct and readable. The existing overlay motion is brief; no new animation was warranted. Quick view and replay review captures disabled animation so they show settled content, not a mid-transition frame. The Plan 169 gallery matrix had exposed two dev-gallery specimens overflowing at 768 because three theme wrappers were squeezed into one cell row. I changed the dev-only theme wrappers to remain stacked until `xl`; both the all-specimen and long-value stress matrix now pass. I also updated the incumbent overview drill-through and responsive-layout assertions to the approved support-focus/content-width behavior, their fail-closed test-title citation, and the repeated replay feedback assertion to check stable node/text/detail and no detail re-animation rather than internal DOM repatch count.

The final explicit “Back to deliveries” action clears selected Delivery, full-detail mode, and exact support-event focus, does not reopen Quick view, and preserves Account plus committed provider/event/window/page. This matches `169-UI-SPEC.md` § Back to deliveries; exact support IDs are required across intermediate support, Quick view, and full-detail navigation, not after that explicit final Back. Earlier test assertions expecting support IDs to survive final Back were corrected to match the approved contract.

### Terminal audit persistence proof boundary

The browser proves the real successful replay command, then a one-shot `replay_history` **read** failure after the command; known local command feedback remains visible while persisted history cannot be refreshed. Existing LiveView/ExUnit coverage proves the requested-only audit fact does not imply completion and preserves known command feedback when audit-history reading is unavailable (`operator_live_test.exs`, tests around lines 1119–1142). No browser or ExUnit fault injection makes the terminal audit database **write/insert** fail. Therefore terminal-audit persistence failure is not proven as a live injected write-failure scenario; the UI correctly separates request/command feedback from persisted audit evidence, and the write-failure injection remains an explicit evidence limit.

### Prohibitions still flagged, not verified

The phase probe serializer does not yet encode direct enforcement judgments for these prohibitions. They remain **FLAGGED / UNVERIFIED**, despite the passing tests, and must not be treated as green:

1. **OUTUX-01:** Never present partial or time-limited Health observations as universal clearance for outbound mail.
2. **OUTUX-02:** Never silently substitute a different Account or Delivery when the requested identity cannot be resolved.
3. **OUTUX-03:** Never describe provider handoff, tracking, or replay audit as inbox placement or human reading.
4. **OUTUX-04:** Never imply that one matching suppression or unmatched Event grants permission to send or a generic repair action.
5. **OUTUX-05:** Never describe stored webhook replay as resend, distributed exactly-once execution, or completed work from requested-only evidence.

The automated coverage is current at the checkout revision above. Native zoom was observed on one route family only; actual physical-device touch and manual OS appearance switching were not performed. The Impeccable package supplied `detect` rather than the skill reference's `audit` command: `audit` returned “Unknown command”; the available detector completed on the changed UI files without output, so no scored audit report is claimed.

## After Evidence — Bounded UI Audit Remediation

Captured 2026-10-07 from checkout `8b6c7cc6e96b99991c3c0bec7a6d9e4ca9c5d10e` on the authorized native Chromium host process, with `BROWSER_SERVER_PORT=4102`, Erlang/OTP `27.3.4.15`, and Elixir `1.18.4` for OTP 27. The Phase 169 rendered matrix refreshed all 20 `artifacts/after/*.png` captures from connected Health → Deliveries → Quick view → full detail → replay review states. The rendered test rechecked all ten `artifacts/before/*.png` checksums successfully. Two unrelated Phase 168 review-fix images regenerated by the full browser suite were restored byte-for-byte from `HEAD`.

| CSS viewport | Health main width | Health metric columns | Page overflow |
|---:|---:|---:|---:|
| 320 | 320 | 1 | 0 px |
| 390 | 390 | 1 | 0 px |
| 768 | 528 | 2 | 0 px |
| 1440 | 1200 | 2 | 0 px |

The rendered browser assertions checked the approved `Observed from {start} to {end} UTC ({hours} hours)` copy at the default 168-hour interval and a validated 24-hour deep link, with the interval and check time preceding the metric grid. They checked that two columns start at the exact 768px shell breakpoint. Full detail DOM geometry confirmed identity/outcome → timeline → current suppression → Account support → replay action. Replay-ready, zero-target, and multiple-target review behavior and modal focus/return continued to pass. The repeated card “Open delivery” copy computed to the existing `--mg-color-link` token in the active System theme.

### Verification after remediation

| Command / selection | Result |
|---|---|
| Focused `operator_live_test.exs` | 100 passed, 0 failed |
| Full Admin `mix test --seed 1` | 538 passed, 0 failed, 1 excluded |
| Asset build | Passed |
| Token parity + bundle tests | 9 passed, 0 failed |
| Phase 169 rendered browser selection | 2 passed, 0 failed |
| Phase 169 connected browser selection | 9 passed, 0 failed |
| Full Admin browser suite on port 4102 | 197 passed, 0 failed, 1 skipped of 198 |

The built CSS SHA-256 was `51140ae26d35c0a9a4d8e67467f85eb1e3d7377045d4c1504ca9270852608c0b`; the browser recorded the same hash for the served versioned stylesheet and asserted served bytes equal `priv/static/app.css`. CSS source SHA-256 remains `8f3b778ecc1a29bda84e78a5c5b7e5b1f060e2be1c9bca5eaa2c1ca0a6791298`. The known fixture boundary warning at `test/support/operator_fixtures.ex:305` remained; it was outside the four authorized corrections.
