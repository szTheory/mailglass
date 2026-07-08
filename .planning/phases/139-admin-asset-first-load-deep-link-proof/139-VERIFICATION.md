---
phase: 139-admin-asset-first-load-deep-link-proof
verified: 2026-07-08T13:49:23Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
requirement_coverage:
  - id: AAU-01
    status: satisfied
    evidence: "First-HTML href matrix in mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs passed for preview, scenario, error, gallery, operator, inbound, query, and alternate routes."
  - id: AAU-02
    status: satisfied
    evidence: "Playwright hard-load proof passed 12 direct page.goto route cases and asserts CSS/font status, content type, origin, and mount-root path."
  - id: AAU-03
    status: satisfied
    evidence: "Alternate /alt/dev/console and /secure/console macro mounts are test-only and covered by ExUnit and Playwright proofs without public router option changes."
  - id: AAU-04
    status: satisfied
    evidence: "Browser gate inspects requestfailed plus response events and asserts token-backed computed font/background styling without screenshots or pixel diffs."
  - id: GATE-03
    status: satisfied
    evidence: "Fast Conn/LiveView assertions and serialized npm run test:operator-browser proof both passed."
automated_checks:
  - command: "cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs test/mailglass_admin/mount_path_test.exs --warnings-as-errors"
    result: "PASS - 21 tests, 0 failures"
  - command: "cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --warnings-as-errors"
    result: "PASS - 7 tests, 0 failures"
  - command: "cd mailglass_admin && npm run test:operator-browser -- --grep \"admin asset hard load\""
    result: "PASS - 12 Playwright tests, 0 failures"
  - command: "cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/router_test.exs --warnings-as-errors"
    result: "PASS - 15 tests, 0 failures"
human_verification: []
next_action: "Proceed to Phase 140 documentation/reconciliation; no Phase 139 gaps found."
---

# Phase 139: Admin Asset First-Load/Deep-Link Proof Verification Report

**Phase Goal:** Preserve and harden current mount-aware stylesheet URLs across preview, operator, inbound, query deep-link, and arbitrary alternate mount paths.
**Verified:** 2026-07-08T13:49:23Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Generated stylesheet hrefs are rooted at the effective mount path for preview, scenario, error, gallery, operator, inbound, query deep-link, and alternate paths. | VERIFIED | `admin_asset_url_test.exs` defines 13 first-HTML route cases and parses exactly one root-layout stylesheet link. It asserts exact `/<mount>/css-<hash>` hrefs, root-relative/same-origin shape, and rejects bare/nested `gallery`, `inbound`, `__error__`, and mailable/scenario-relative hrefs. Focused ExUnit command passed: 21 tests, 0 failures. |
| 2 | Direct hard loads do not request CSS/fonts relative to nested LiveView paths. | VERIFIED | `admin-assets.spec.js` creates 12 independent `admin asset hard load:` Playwright cases. `collectAssetResponses/2` listens before navigation, captures stylesheet/font responses, asserts 200 status, expected content type, same origin, and paths under `<mount>/css-` or `<mount>/fonts/`. Browser grep passed: 12 tests, 0 failures. |
| 3 | The same proof passes when admin is mounted at arbitrary alternate paths. | VERIFIED | `endpoint_case.ex` adds test-only macro mounts at `/alt/dev/console` and `/secure/console` with unique live session names. Both the ExUnit href matrix and Playwright hard-load matrix include alternate preview, operator, and inbound route cases. |
| 4 | Browser verification fails on CSS/font 404s and asserts token-backed computed styling after direct `page.goto` loads. | VERIFIED | The browser spec checks `requestfailed` and `response.status()`, not DOM readiness alone; it requires stylesheet and font responses, checks `text/css` and `font/woff2`, waits for `document.fonts.ready`, checks `document.fonts.check()`, body/heading font families and weights, root dark theme, and token-backed background colors. |
| 5 | Existing `MountPathHook` / `MountPath` / layout strategy is preserved. | VERIFIED | Router macros still emit scoped asset routes and include `MailglassAdmin.MountPathHook`; `MountPathHook` assigns `:mount_path` from request URI; `Layouts.css_url/1` calls `mounted_asset_url/2`; the fallback calls `MailglassAdmin.MountPath.base/1`. No public router asset-root option, duplicate CSS/font route, `<base>`, redirect asset fix, screenshot, or pixel-diff evidence was found in phase files. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `mailglass_admin/test/support/endpoint_case.ex` | Alternate test-only preview and operator/inbound macro mounts | VERIFIED | Contains `/alt/dev` + `/secure` scopes, unique `:mailglass_admin_preview_alt` and `:mailglass_admin_operator_alt`, and reuses existing public macros with existing operator auth/session/on_mount/inbound options. |
| `mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs` | Focused first-HTML stylesheet href route matrix | VERIFIED | Substantive 13-case matrix; uses direct `get/2`, Floki link extraction, exact mount-root href assertion, and nested-relative refutations. |
| `mailglass_admin/test/mailglass_admin/mount_path_test.exs` | Pure `MountPath.base/1` route-shape coverage | VERIFIED | Existing pure tests cover index, mailable/scenario, `__error__`, gallery, inbound, root, and single-segment mount behavior. |
| `mailglass_admin/e2e/admin-assets.spec.js` | Focused Playwright network and computed-style proof | VERIFIED | Contains route cases, `loginOperatorForAssetRoute`, `collectAssetResponses`, `assertDirectAssetLoad`, and `assertTokenBackedStyles`; included by the `e2e` Playwright test directory. |
| `mailglass_admin/test/mailglass_admin/token_parity_test.exs` | Token-backed compiled CSS parity proof | VERIFIED | Reads `priv/static/app.css`, verifies daisyUI `--color-*` slots resolve through `var(--mg-*)`, and checks oracle parity against `brandbook/tokens.json`. |
| `mailglass_admin/priv/static/app.css` | Compiled bundle with relative font URLs and token-backed CSS | VERIFIED | 114,683 bytes; contains `@font-face`, `url(./fonts/inter-400.woff2)`, `url(./fonts/inter-tight-700.woff2)`, token declarations, `body{font-family:Inter`, and heading font declarations. Bundle test passed and post-browser-run `git diff` was clean. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `admin_asset_url_test.exs` | `layouts/root.html.heex` / `Layouts.css_url/1` | Direct `get/2` first HTML parsed with Floki | VERIFIED | The test does not import `Layouts`; it verifies the rendered root layout by parsing the actual HTTP response. This is stronger than source import evidence. |
| `layouts.ex` | `mount_path.ex` | `mounted_asset_url/2` fallback and `asset_mount_path/1` | VERIFIED | `Layouts.css_url/1` builds `css-<hash>` through `mounted_asset_url/2`; `asset_mount_path/1` calls `MailglassAdmin.MountPath.base/1`. |
| `endpoint_case.ex` | `router.ex` | Alternate scopes reuse public router macros | VERIFIED | `/alt/dev` calls `mailglass_admin_routes/2`; `/secure` calls `mailglass_operator_routes/2`. |
| `admin-assets.spec.js` | `endpoint_case.ex` | Browser route cases include default and alternate macro mounts | VERIFIED | Route matrix includes `/alt/dev/console...`, `/secure/console...`, and `/secure/console/inbound...`. |
| `admin-assets.spec.js` | `package.json` / `playwright.config.cjs` | `npm run test:operator-browser` runs `playwright test --config=playwright.config.cjs --workers=1` over `./e2e` | VERIFIED | The focused spec lives under `mailglass_admin/e2e`; the serialized browser command ran the 12 `admin asset hard load` tests successfully. |
| `admin-assets.spec.js` | `priv/static/app.css` font URLs | Browser observes CSS-relative font responses under the effective mount root | VERIFIED | Spec asserts font response paths start with `<mount>/fonts/`; generated CSS contains `url(./fonts/*.woff2)`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `layouts/root.html.heex` | Stylesheet `href` | `css_url(assigns)` -> `mounted_asset_url(assigns, "css-" <> css_hash())` | Yes - rendered HTML includes the hashed CSS route and the ExUnit matrix parses it from HTTP responses | VERIFIED |
| `MountPathHook` / `MountPath` | `:mount_path` socket assign | `handle_params` URI path -> `MountPath.base/1` | Yes - route matrix proves emitted hrefs are rooted for nested, query, and alternate paths | VERIFIED |
| `router.ex` asset macros | CSS/font routes | `__asset_routes__/0` inside each macro scope | Yes - Playwright observed 200 CSS and font responses under default and alternate mount roots | VERIFIED |
| `priv/static/app.css` | Relative font URLs and token CSS | Compiled bundle generated from admin CSS source | Yes - bundle/token tests passed; Playwright computed-style proof observed applied fonts/backgrounds | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Fast first-HTML href and mount-path proof | `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs test/mailglass_admin/mount_path_test.exs --warnings-as-errors` | 21 tests, 0 failures | PASS |
| Serialized direct browser hard-load proof | `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset hard load"` | 12 Playwright tests, 0 failures | PASS |
| Token-backed bundle parity | `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --warnings-as-errors` | 7 tests, 0 failures | PASS |
| Alternate macro route safety | `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/router_test.exs --warnings-as-errors` | 15 tests, 0 failures | PASS |
| Bundle drift after browser rebuild | `git diff -- mailglass_admin/priv/static/app.css ...` | No diff | PASS |

The test output still includes the known pre-existing Phoenix component attribute warning at `mailglass_admin/lib/mailglass_admin/operator_live.ex:505` plus optional Oban warnings. The focused commands exited 0 with `--warnings-as-errors`; the warning is outside the Phase 139 modified files and did not block the target gates.

### Probe Execution

Step 7c: SKIPPED - no phase-declared or conventional `scripts/**/tests/probe-*.sh` probes were found for Phase 139.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| AAU-01 | 139-01 | First HTML emits current-mount rooted stylesheet hrefs for preview, scenario, error, gallery, operator, inbound, and query routes. | SATISFIED | `admin_asset_url_test.exs` route matrix and 21-test ExUnit pass. |
| AAU-02 | 139-02 | Hard refreshes/direct deep links load CSS/fonts with 200 responses and expected content types; nested routes do not request nested-relative assets. | SATISFIED | Playwright network proof asserts response status, content type, origin, and mount-root path; 12-test browser pass. |
| AAU-03 | 139-01, 139-02 | Same asset proof passes for arbitrary alternate mount path without public router macro options. | SATISFIED | Test-only `/alt/dev/console` and `/secure/console` macro mounts are covered by ExUnit and Playwright; router option schema has no asset-root option. |
| AAU-04 | 139-02 | Browser gate fails on CSS/font 404s and asserts token-backed computed styling after direct `page.goto` loads. | SATISFIED | Spec checks failed requests, HTTP status, content types, font readiness/checks, computed font families/weights, theme, and token backgrounds. |
| GATE-03 | 139-01, 139-02 | Admin URL robustness has fast generated-href assertions and serialized browser proof. | SATISFIED | ExUnit href proof and `npm run test:operator-browser -- --grep "admin asset hard load"` both passed. |

No Phase 139 requirement IDs were orphaned: `.planning/REQUIREMENTS.md` maps AAU-01, AAU-02, AAU-03, AAU-04, and GATE-03 to Phase 139, and both plans claim the expected subset.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| None | - | - | - | No unreferenced `TBD`, `FIXME`, or `XXX`; no screenshot/pixel-diff assertions; no `<base>` tag; no public asset-root router option; no duplicate nested CSS/font route; no product expansion/redesign evidence in Phase 139 files. |

### Human Verification Required

None. The behavior-dependent claims were exercised by automated tests: first-HTML state via ExUnit HTTP responses and hard-load/network/computed-style behavior via Playwright direct `page.goto` route cases.

### Gaps Summary

No blocking gaps found. Phase 139 achieved the roadmap success criteria and satisfies AAU-01, AAU-02, AAU-03, AAU-04, and GATE-03.

---

_Verified: 2026-07-08T13:49:23Z_
_Verifier: the agent (gsd-verifier)_
