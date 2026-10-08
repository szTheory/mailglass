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
