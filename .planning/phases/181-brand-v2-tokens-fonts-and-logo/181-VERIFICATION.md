---
phase: 181-brand-v2-tokens-fonts-and-logo
verified: 2026-11-15T19:35:06Z
status: passed
score: 18/18 must-haves verified
covered_files:
  - .planning/phases/181-brand-v2-tokens-fonts-and-logo/181-01-PLAN.md
  - .planning/phases/181-brand-v2-tokens-fonts-and-logo/181-01-SUMMARY.md
  - .planning/phases/181-brand-v2-tokens-fonts-and-logo/181-02-PLAN.md
  - .planning/phases/181-brand-v2-tokens-fonts-and-logo/181-02-SUMMARY.md
  - .planning/phases/181-brand-v2-tokens-fonts-and-logo/181-03-PLAN.md
  - .planning/phases/181-brand-v2-tokens-fonts-and-logo/181-03-SUMMARY.md
  - .planning/phases/181-brand-v2-tokens-fonts-and-logo/181-04-PLAN.md
  - .planning/phases/181-brand-v2-tokens-fonts-and-logo/181-04-SUMMARY.md
  - brandbook/brand.pin.json
  - brandbook/tokens.css
  - brandbook/tokens.json
  - brandbook/v2/favicon.svg
  - brandbook/v2/mailglass-lockup-dark.svg
  - brandbook/v2/mailglass-lockup-light.svg
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/assets/vendor/heroicons-inline.js
  - mailglass_admin/docs/axe-baseline.json
  - mailglass_admin/docs/design-system.md
  - mailglass_admin/e2e/admin-assets.spec.js
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/operator.spec.js
  - mailglass_admin/e2e/phase169-journey.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/controllers/assets.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/layouts/root.html.heex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
  - mailglass_admin/lib/mailglass_admin/operator/repair_state.ex
  - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
  - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
  - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/priv/static/app.css
  - mailglass_admin/priv/static/favicon.svg
  - mailglass_admin/priv/static/fonts/OFL-AtkinsonHyperlegibleMono.txt
  - mailglass_admin/priv/static/fonts/OFL-AtkinsonHyperlegibleNext.txt
  - mailglass_admin/priv/static/fonts/OFL-FunnelDisplay.txt
  - mailglass_admin/priv/static/fonts/a-display-600.woff2
  - mailglass_admin/priv/static/fonts/a-mono-400.woff2
  - mailglass_admin/priv/static/fonts/a-mono-600.woff2
  - mailglass_admin/priv/static/fonts/ui-400.woff2
  - mailglass_admin/priv/static/fonts/ui-400i.woff2
  - mailglass_admin/priv/static/fonts/ui-600.woff2
  - mailglass_admin/priv/static/mailglass-logo.svg
  - mailglass_admin/scripts/check-conformance.sh
  - mailglass_admin/test/mailglass_admin/accessibility_test.exs
  - mailglass_admin/test/mailglass_admin/assets_test.exs
  - mailglass_admin/test/mailglass_admin/brand_test.exs
  - mailglass_admin/test/mailglass_admin/bundle_test.exs
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/contrast_contract_test.exs
  - mailglass_admin/test/mailglass_admin/font_assets_contract_test.exs
  - mailglass_admin/test/mailglass_admin/glyph_contract_test.exs
  - mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs
  - mailglass_admin/test/mailglass_admin/operator/repair_state_test.exs
  - mailglass_admin/test/mailglass_admin/operator_live_test.exs
  - mailglass_admin/test/mailglass_admin/preview_live_test.exs
  - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  - mailglass_admin/test/support/contrast.ex
  - mailglass_admin/test/support/glyph_scan.ex
  - reference/demo_app/assets/e2e/outbound-replay.spec.js
  - reference/demo_app/assets/e2e/phase178-stories.spec.js
  - reference/demo_app/assets/e2e/storybook-fidelity.spec.js
  - reference/demo_app/storybook/foundations.story.exs
  - reference/demo_app/storybook/quick_views/delivery.story.exs
  - reference/demo_app/storybook/quick_views/inbound.story.exs
  - scripts/brand_pin.exs
  - scripts/check_phase174_evidence.cjs
  - scripts/check_phase174_evidence.test.cjs
  - scripts/check_phase175_evidence.cjs
  - scripts/check_phase175_evidence.test.cjs
  - test/scripts/brand_pin_test.exs
covered_digest: "v4:sha256:09ae9f1b0bbda33ed902d5fd656d2ecc2ceb497a40f4d8ee76195f369d7c3eab"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 181: Brand v2 Tokens, Fonts and Logo Verification Report

**Phase Goal:** In one coordinated change, the admin dashboard takes on brand v2.0 colors, typography and mark in light and dark. Every contrast pair and font asset is verified by tests, and the host's email defaults stay exactly as they were.
**Verified:** 2026-11-15T19:35:06Z
**Status:** passed
**Re-verification:** No, initial verification
**HEAD verified:** `67de3dc46e2d853d3c84466dcdd2412402332c4f` (tree clean before and after verification; every scratch artifact the verifier created was deleted)
**Phase base:** `9bd70fa5`

## Goal Achievement

The goal is achieved in the codebase. I did not rely on the four SUMMARYs. I re-derived the token parity, designed-colour recomputation and book contrast ratios in a standalone Python script that does not reuse the project's test helpers, ran the required admin lane and the root contract files myself, ran two source mutations of my own, observed the rendered result in a real Chromium page, and re-checked every prohibition by command.

### Observable Truths

Source: the five ROADMAP success criteria (the contract), merged with the plan `must_haves.truths`. Plan truths that restate a ROADMAP criterion are folded into it.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | **SC1.** All 39 `--mg-color-*` roles and the 2 logo roles resolve to v2 values in the light, dark and system (`prefers-color-scheme`) blocks, feed the 20 daisyUI slots, and the bundle passes the drift gate and `token_parity_test` | VERIFIED | Standalone script: tokens.json resolves 41 roles per tier; the compiled `priv/static/app.css` has exactly one light, one dark and one `@media (prefers-color-scheme:dark)` system block, each carrying all 41 roles with zero missing, extra or differing values (the only textual differences are `#fff` vs `#ffffff` minifier shortening). 123 `--mg-*` hex declarations (`grep` prints 123). The `@media (prefers-color-scheme:dark){:root:not([data-theme=light])...` wrapper is present. 0 v1 hexes in the bundle and in `brandbook/tokens.css`. `app.css` maps 20 `--color-*` slots per theme to `var(--mg-*)` roles. `mix verify.support_contract.admin` printed `Admin bundle matches a fresh build (138509 bytes).` and passed (see Behavioral Spot-Checks). |
| 2 | **SC2.** A static contrast test checks every declared pair per theme and lowering any pair below its ratio fails it; `mix.lock` gains no dependency | VERIFIED | Independent Python recompute (WCAG 2.2, 0.04045): all 12 brand.json `contrastPairs` x 2 themes meet `minimum` and are within 0.02 of the published ratio (e.g. descriptor dark 8.08, artwork light 3.05, link dark 8.24). `contrast_contract_test.exs` (1335 lines, no skip, no sleep) covers book pairs, admin pairs, slot and designed-value coverage guards, the three book `never` rules, opacity-utility guard and component alpha-text guard. **Verifier mutation:** aliasing dark `text-muted` to `{palette.control-edge-dark}` made 7 tests fail across `contrast_contract_test`, `token_parity_test` and `accessibility_test`, naming `descriptor (dark): text-muted #8b7d72 on background #1d1713 is 4.45:1, below the 4.5:1 minimum`; restored byte-identical (`cmp`), tree clean. `git diff 9bd70fa5 HEAD -- mix.lock mailglass_admin/mix.lock mailglass_inbound/mix.lock mailglass_admin/package-lock.json` is empty. |
| 3 | **SC3.** Funnel Display at 600 and the other faces from six bundled woff2 files with OFL texts; a static required-lane contract proves no remote font/stylesheet URL and served fonts equal `@allowed_fonts`; a font outside the allow-list returns 404 | VERIFIED | `priv/static/fonts` holds exactly six woff2 (a-display-600, ui-400, ui-600, ui-400i, a-mono-400, a-mono-600) and three `OFL-*.txt`; the six retired woff2 are gone. `assets.ex` has `@external_resource` per font, an explicit `@font_files` list, a name-to-bytes `@fonts` map, `@allowed_fonts` = sorted keys, `allowed_fonts/0`, and `call(conn, :font)` does `Map.fetch(@fonts, name)` (no filesystem path from a request). Bundle has six `@font-face` rules with `font-display:swap` and relative `./fonts/` URLs, no remote `url(`/`@import`, 0 occurrences of `font-weight:700`; `app.css` sets `--font-weight-bold: 600`. `font_assets_contract_test.exs` (582 lines) is in the required lane. **Verifier mutation:** a stray `inter-400.woff2` in the fonts dir made `font_assets_contract_test` fail (`24 tests, 2 failures`, set-equality named) and `brand_pin.exs verify` fail with `asset_unlisted`; removed, `brand pin ok`, 9 files, tree clean. No CDN host appears anywhere in `lib/`, `app.css`, or the bundle. |
| 4 | **SC4.** The new logo and favicon appear in the admin, the `←` glyph is gone from every screen, `brand_test` and `accessibility_test` pass, and the axe baseline is regenerated exactly once, as the phase's last change | VERIFIED | `Components.logo/1` is an inline SVG with the pinned viewBox and four paths; `cmp` shows `priv/static/mailglass-logo.svg` == `brandbook/v2/mailglass-lockup-light.svg` and `priv/static/favicon.svg` == `brandbook/v2/favicon.svg`; the four `d` values in the component equal both pinned lockups in order; light fills `#2A1D17/#1895C2/#1895C2/#0A6488`, dark `#F3EEEA/#46B6E8/#46B6E8/#A8E4F7`. `.mg-logo-glass{fill:var(--mg-logo-glass)}` and `.mg-logo-overlap{fill:var(--mg-logo-overlap)}` are in the bundle. Called at `admin_shell.ex:39` and `gallery_live.ex:169`; no `<img>` of the logo anywhere in `lib/`. All rendered arrows are gone: every remaining U+2190-2193 in `lib/` is in a `#` comment or `@doc`; the back link and both "Open full detail" links use `hero-arrow-left` / `hero-arrow-right`, which exist in `heroicons-inline.js` and the bundle. `brand_test`, `accessibility_test` pass inside the lane. Axe: `git rev-list --count 9bd70fa5..HEAD -- docs/axe-baseline.json` = 1 (`644412c3`); `git diff --name-only 644412c3..HEAD` outside `.planning` is empty; the persisted diff adds 0 `color-contrast` lines; `current.run_id` `axe-2026-11-15T17-11-33-992Z` is fresh (base was `axe-2026-06-21T15-53-05-411Z`), `prior` equals the base's `prior`, `schema_version` 1. |
| 5 | **SC5.** `config.ex`, `theme.ex`, email button colours and the VML goldens show no diff, and their existing tests pass without edits | VERIFIED | `git diff --quiet 9bd70fa5 HEAD -- lib test/mailglass test/fixtures test/support mix.lock mailglass_admin/mix.lock mailglass_inbound/mix.lock mailglass_admin/package-lock.json` exits 0. Files changed outside `.planning`: `brandbook`, `mailglass_admin`, `reference`, `scripts`, and one root `test/scripts/brand_pin_test.exs` (not a host-email file). `test/mailglass/components/vml_preservation_test.exs` passed unedited in my root targeted run (150 total, 0 failures, 1 skipped). |
| 6 | **D-03/D-05.** Every non-designed palette hex equals a brand.json hex found by name; every designed value recomputes from two palette entries; no hue outside the book | VERIFIED | Standalone script: 0 non-designed palette entries lack book provenance or have a hex absent from brand.json; all 11 designed entries (`link-hover-light #12526C`, `overlay-dark #362D27`, `selected-dark #323535`, eight `*-bg` tints) recompute to the stored hex under Elixir `round/1` semantics (half away from zero). |
| 7 | **D-04.** Parity compares every one of the 41 roles in all three blocks, selects each block by exact selector, and a one-value mutation turns it red | VERIFIED | Re-derived independently (truth 1) and exercised by my mutation (truth 2): the changed dark role was reported in both the "dark block" and "system block" lines of `token_parity_test`. In-test teeth per block exist (`detectors have teeth` test failed correctly under the mutation). See WR-04 note below on the unwrapped `@media` assertion (advisory). |
| 8 | **D-06/D-07.** Shared helper uses the 0.04045 threshold; coverage guards fail when a slot is in no pair; the three book `never` rules are enforced | VERIFIED | `support/contrast.ex` uses `0.04045`; `0.03928` is gone from `accessibility_test.exs` and `contrast.ex`. Tests present: slot coverage, designed-value coverage, "roles described as unreferenced by admin CSS really are", and one test per never rule (logo Glass, Sand Line, Deep Glass), each with planted-violation teeth. |
| 9 | **D-20.** The before-catalog `superseded.json` is bound to the final bundle sha256 and root layout blob | VERIFIED | `shasum -a 256 priv/static/app.css` = `8c57857f...b89b` = `superseded_by.bundle_sha256`; `git hash-object root.html.heex` = `c89fca34...e519` = `root_layout_git_blob_sha`. `before_catalog_manifest_test` passes in the lane. |
| 10 | **D-18.** Every new asset entered through `brand_pin.exs`; `brand.pin.json` is not hand-edited; owned dirs are exactly `brandbook/v2` and `priv/static/fonts`; woff2 hashes are zip-sourced | VERIFIED | `mix run --no-start scripts/brand_pin.exs verify` prints `brand pin ok`; `test/scripts/brand_pin_test.exs` passes (76 tests per the SUMMARY, part of my 150-test root run). `verify` flags `asset_unlisted` for an unlisted file (my mutation) and `asset_hash_mismatch` is covered by teeth. The pin lists 16 shipped entries. |
| 11 | **D-11/D-12.** Compile-time embed, `allowed_fonts/0` is the map keys, other names (retired Inter 400, an OFL text, an encoded traversal) get 404 with an empty body | VERIFIED | `assets.ex` read directly. Real-server observation: `GET /dev/mail/fonts/ui-400.woff2` is `200 font/woff2`; `inter-400.woff2` is `404`; `OFL-FunnelDisplay.txt` is `404`. `assets_test.exs` covers each allowed face (200, `font/woff2`, `wOF2` body), the retired name, the OFL texts and traversal. |
| 12 | **D-09/D-10.** `font-bold` maps to 600; Funnel Display on h1-h3, Atkinson Hyperlegible Next on body, Atkinson Hyperlegible Mono (ligatures off) on code; tabular numerals on `time, td` and the two mobile email list containers | VERIFIED | Bundle: `h1,h2,h3{...font-family:Funnel Display,Arial Narrow,...}` and the `.mg-admin-root` mirror, `time,td{font-variant-numeric:tabular-nums}`; `tabular-nums` appears on the `<ul>` at `operator/deliveries_list.ex:247` and `inbound/records_list.ex:288`. All asserted in `font_assets_contract_test` with teeth. |
| 13 | **D-14/F2.** Publish allowlist lists the six woff2 and three OFL texts and none of the retired six; evidence scripts name the v2 fonts | VERIFIED | `.planning/publish/mailglass_admin-files.expected` lines 82-90 list the nine files; `mix mailglass.publish.check --allowlist-only --package mailglass_admin` printed `create=2 update=1 unchanged=2 conflict=0`; `node --test` of the four evidence files: `tests 42, pass 42, fail 0`. |
| 14 | **D-17/BRTOK-04.** No U+2190-2193 in any rendered `lib` string; every `hero-<name>` has a bundle rule; contract proves both | VERIFIED | Direct `grep -P` over `mailglass_admin/lib` (comments/docs only, listed in Anti-Patterns). `glyph_contract_test.exs` (484 lines, arrow scan with no allow-list, hero-rule check, 17 teeth) passes in the lane. `ICON-EXISTS-GATE` inside `check-conformance.sh` prints OK. |
| 15 | **D-13.** Rendered `·` is `•`; subset contract is bound to the six pinned woff2 sha256 values | VERIFIED | `grep '·' mailglass_admin/lib` returns only the `@moduledoc` text in `inbound/records_list.ex:12` (docs are ignored by the AST scan by design, F7). Root layout title suffix reads ` • mailglass`. `glyph_contract_test` passes, including the pin-hash binding. |
| 16 | **D-19/D-08.** The axe baseline is regenerated once, by the producer, last, with no new `color-contrast` rule; `axe_baseline_test` passes | VERIFIED | See truth 4 (commit count 1, fresh `run_id`, preserved `prior`, 0 `color-contrast` lines, nothing outside `.planning` after the commit). The baseline's persisted cells: deliveries and inbound 0 violations in all three themes; preview `aria-allowed-attr: 1` in all three (pre-existing, unchanged). The `:where(.label)` rule the executor added (commit `2fae6975`) fixed a real light-theme `color-contrast` regression found before persisting; I confirmed that the "never persist a regression" fallback fired exactly as the plan prescribes. |
| 17 | **Rendered outcome (direct observation).** In a real browser, light, dark and system render v2 colours, the v2 typemark follows the page theme, and fonts load from the admin origin | VERIFIED | Throwaway Playwright probe against the real admin test server (deleted afterwards). Light: text `rgb(42,29,23)` (Espresso), logo panes `rgb(24,149,194)`, overlap `rgb(10,100,136)`, word `rgb(42,29,23)`. Explicit dark: text `rgb(243,238,234)`, panes `rgb(70,182,232)`, overlap `rgb(168,228,247)`. System (dark OS, no `data-theme`): the same dark values, which exercises the `@media` block. h1 is `"Funnel Display"` at weight 600 in all three; body is `"Atkinson Hyperlegible Next"`; logo is 117 px wide at `h-6`; loaded faces `Funnel Display 600`, `Atkinson Hyperlegible Next 400/600`, `Atkinson Hyperlegible Mono 400`; every request origin was `http://127.0.0.1:4101` (the admin host) and every font URL was under `/dev/mail/fonts/`. This is verifier-observed evidence, not a committed test. |
| 18 | **Backstop truths** (`verification: backstop`): `mix verify.support_contract.admin` passes at plan end with mutation proofs recorded; the 181-04 phase gate (root suite, allowlist, conformance trio, node tests) passes | VERIFIED (qualified) | Observed directly: admin lane exit 0, `1521 tests, 0 failures, 1 excluded`; conformance trio and `check_test_exceptions` OK; allowlist OK; node 42/42; `mix format --check-formatted` clean in both roots; mutation proofs are recorded in all four SUMMARYs and two were independently re-run by me (truths 2, 3). **Qualification:** I did not re-run the bare full root `mix test` (instructed not to). The 181-04 SUMMARY records `2370 tests, 1 failure`; the one failure is `Phase164RepositoryTruthTest` and I independently attributed it to the environment (see Environmental Note), so the backstop statement holds. |

**Score:** 18/18 truths verified (0 present-but-behavior-unverified, 0 overrides).

### Deferred Items

Items not met but explicitly addressed in a later phase. Only items with specific roadmap evidence are listed here.

| # | Item | Addressed In | Evidence |
|---|------|--------------|----------|
| 1 | `CLAUDE.md` Brand & Voice still states the v1 palette and typography (review IN-03) | Phase 183 | ROADMAP Phase 183 SC3: "the CLAUDE.md/PRODUCT.md updates are drafted and waiting for owner sign-off"; also CONTEXT D-23 and Deferred Ideas |
| 2 | ICO/PNG favicons, ExDoc logo/CSS, README brand assets, `design-system.md` prose beyond the false-value corrections | Phase 183 | ROADMAP Phase 183 SC1, SC2, SC3, SC5 |

Note: the `::placeholder` contrast item and the demo `&rarr;` entity are NOT listed as deferred here, because neither appears in any later phase's goal or success criteria (they are recorded as warnings below, per the conservative-match rule).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brandbook/tokens.json` | v2 palette with `book`/`designed` provenance, 39 roles x 2 tiers, `logo` group | VERIFIED | 37 palette entries, 41 resolved roles per tier, provenance checked by script |
| `brandbook/tokens.css` | v2 values, logo roles in all three blocks | VERIFIED | `--mg-logo-glass:` and `--mg-logo-overlap:` each appear 3 times; 0 v1 hexes |
| `mailglass_admin/priv/static/app.css` | rebuilt bundle, byte-identical to a fresh build | VERIFIED | `--check` line printed by the lane; 138509 bytes; sha256 bound in the marker |
| `mailglass_admin/test/support/contrast.ex` | shared helper on 0.04045 | VERIFIED | 132 lines, pure |
| `mailglass_admin/test/mailglass_admin/contrast_contract_test.exs` | book pairs, admin pairs, guards, never rules, teeth | VERIFIED | 1335 lines (plan min 150) |
| `mailglass_admin/test/mailglass_admin/token_parity_test.exs` | three-block parity, palette cross-check | VERIFIED | 743 lines, contains `prefers-color-scheme` |
| `mailglass_admin/test/mailglass_admin/font_assets_contract_test.exs` | static D-12 proof with teeth | VERIFIED | 582 lines (plan min 100) |
| `mailglass_admin/test/mailglass_admin/glyph_contract_test.exs`, `support/glyph_scan.ex` | arrow, subset, hero-rule contracts | VERIFIED | 484 and 171 lines (plan min 120) |
| `mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs` | byte, path, token identity, safety, teeth | VERIFIED | 517 lines (plan min 110) |
| `scripts/brand_pin.exs` | `extend` verb | VERIFIED | `verify` and the tamper tests exercise it |
| `brandbook/brand.pin.json` | 16 shipped entries, two owned dirs | VERIFIED | `verify` prints `brand pin ok` |
| `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` | compile-time font map, `allowed_fonts/0` | VERIFIED | read; `@external_resource` loop at line 348 |
| `mailglass_admin/lib/mailglass_admin/components.ex` | inline `logo/1` with `mg-logo-*` classes | VERIFIED | 2 `mg-logo-glass`, 1 `mg-logo-overlap`; 0 `data-glyph`/`sealed-flap` |
| `mailglass_admin/priv/static/{mailglass-logo,favicon}.svg` | byte copies of the pinned files | VERIFIED | `cmp` identical |
| `mailglass_admin/docs/axe-baseline.json` | regenerated once by the producer | VERIFIED | provenance checks above |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `brandbook/tokens.css` | `priv/static/app.css` | `@import "../../../brandbook/tokens.css"` (`app.css:10`) | WIRED | bundle carries every role; `--check` byte compare |
| `token_parity_test.exs` | `brandbook/tokens.json` | oracle compare against the compiled bundle | WIRED | my mutation turned it red naming both blocks |
| `contrast_contract_test.exs` | `brandbook/v2/brand.json` | `color.contrastPairs[]`, `color.never[]` read by name | WIRED | 12 pairs x 2 themes resolve |
| `before_catalog_manifest_test.exs` | `superseded.json` | `bundle_sha256`, `root_layout_git_blob_sha` | WIRED | both equal live values |
| `components.ex` `logo/1` | `brandbook/tokens.css` | class `mg-logo-*` -> `fill: var(--mg-logo-*)` -> theme block | WIRED | observed in a real browser per theme |
| `admin_shell.ex` / `gallery_live.ex` | `Components.logo/1` | `<Components.logo ...>` | WIRED | lines 39 and 169 |
| `app.css` `@font-face` | `priv/static/fonts` via `/fonts/:name` route | `url('./fonts/...')`, `get("/fonts/:name", Assets, :font)` | WIRED | observed 200 for an allowed face |
| `assets.ex` | `priv/static/fonts` | `@external_resource` + `File.read!` | WIRED | compile-time map |
| `operator_live.ex`, both quick views | `heroicons-inline.js` | `hero-arrow-left` / `hero-arrow-right` | WIRED | rules present in the bundle |
| `axe_baseline_test.exs` | `docs/axe-baseline.json` | only-forward ratchet | WIRED | passes in the lane |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Header typemark | `.mg-logo-glass` / `.mg-logo-overlap` fill | `--mg-logo-*` in the active theme block | Yes: computed fills observed per theme in Chromium | FLOWING |
| Headings and body | `font-family` / `font-weight` | `@font-face` -> `/fonts/:name` -> compile-time bytes | Yes: faces reported `loaded`, requests same-origin | FLOWING |
| daisyUI slots | `--color-*` | `var(--mg-color-*)` from the theme blocks | Yes: computed text colour matches token values | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Required lane (cold-equivalent warm run) | `cd mailglass_admin && mix verify.support_contract.admin` | `Admin bundle matches a fresh build (138509 bytes).` then `1521 tests, 0 failures, 1 excluded`, exit 0 | PASS |
| Pin provenance | `mix run --no-start scripts/brand_pin.exs verify` | `brand pin ok` | PASS |
| Root contract files | `mix test test/scripts/brand_pin_test.exs test/mailglass/docs_contract_test.exs test/scripts/icon_exists_gate_test.exs test/mailglass/components/vml_preservation_test.exs test/scripts/timeout_evidence_ci_contract_test.exs --warnings-as-errors --seed 0` | 150 total, 149 executed, 0 failures, 1 skipped | PASS |
| Conformance gates | `check-conformance.sh`, `check_motion_conformance.sh`, `check-conformance-advisory.sh`, `check_test_exceptions.sh` | all four print `OK` | PASS |
| Publish allowlist | `MIX_ENV=test mix mailglass.publish.check --allowlist-only --package mailglass_admin` | `conflict=0` | PASS |
| Evidence scripts | `node --test` over the four evidence/contract files | 42 pass, 0 fail | PASS |
| Format | `mix format --check-formatted` in `mailglass_admin` and root | clean | PASS |
| BRTOK-06 scope | `git diff --quiet 9bd70fa5 HEAD -- lib test/mailglass test/fixtures test/support <4 lockfiles>` | exit 0 | PASS |
| Mutation: contrast | dark `text-muted` aliased darker | 7 failures naming `descriptor (dark) ... 4.45:1` | PASS (red as required, restored) |
| Mutation: fonts | stray `inter-400.woff2` | contract 2 failures, `asset_unlisted`; restored | PASS (red as required, restored) |

### Probe Execution

Step 7c: SKIPPED. No `scripts/*/tests/probe-*.sh` exists, and no PLAN declares a probe (the phase's proofs are ExUnit/node contract tests, which were run above).

### Requirements Coverage

Plan frontmatter `requirements:` unions to BRTOK-01..06; `.planning/REQUIREMENTS.md` maps exactly BRTOK-01..06 to Phase 181. No orphaned IDs.

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|----------------|-------------|--------|----------|
| BRTOK-01 | 181-01 | Brand v2 tokens and an explicit role map for every admin colour role, light and dark: 39 `--mg-color-*` roles + 2 logo roles feeding 20 daisyUI slots | SATISFIED | Truths 1, 6, 7; `token_parity_test` + `--check` in the required lane |
| BRTOK-02 | 181-01, 181-03 | Static contrast test per theme against the book's ratios, no new dependency | SATISFIED | Truths 2, 8; lockfile diff empty; verifier mutation |
| BRTOK-03 | 181-02, 181-03, 181-04 | Six woff2 (~52 KB, no CDN) with OFL texts, `@external_resource`, `@allowed_fonts`, 600 mapping | SATISFIED | Truths 3, 10-13, 15; fonts total 52,508 bytes per SUMMARY and `ls` sizes (8164+7492+7484+9164+10584+9620) |
| BRTOK-04 | 181-03, 181-04 | Logo and favicon replace the current ones; the `←` glyph is replaced | SATISFIED | Truths 4, 14, 17 |
| BRTOK-05 | 181-01, 181-04 | `brand_test`, `token_parity_test`, `accessibility_test` updated; axe baseline regenerated once, last | SATISFIED | Truths 4, 16 |
| BRTOK-06 | 181-04 | Core email defaults unchanged, proven by existing tests passing without edits | SATISFIED | Truth 5 |

### Prohibitions (`must_haves.prohibitions`, all `verification: test`)

Every prohibition in the four plans is `status: resolved`, `verification: test`, so none is routed to the judgment-tier soft gate and none is an unverified flag.

| Prohibition | Result | Evidence |
|-------------|--------|----------|
| No colour that is neither a brand.json hex nor an alpha composite of two (181-01) | HELD | Standalone provenance script: 0 orphans, 11 designed composites recompute |
| Logo Glass never text/control; Sand Line never border-input; Deep Glass never dark text (181-01) | HELD | one test per rule with planted-violation teeth, green in the lane |
| No dependency / lockfile change (181-01, 02, 03) | HELD | lockfile diff from `9bd70fa5` empty |
| No edit to core lib, core tests, fixtures, root test/support (181-01, 02, 04) | HELD | scope diff exit 0 |
| No remote font/stylesheet URL (181-02) | HELD | bundle grep for remote `url(`/`@import` is empty; teeth per pattern |
| No asset bypassing `brand_pin.exs`, no hand-edited pin (181-02) | HELD | `verify` ok; `extend` teeth in `brand_pin_test` |
| No re-subset/rename of pinned woff2 (181-02) | HELD | `verify` ok; glyph contract binds six sha256 values |
| No U+2190-2193 in rendered lib text (181-03) | HELD | direct grep + arrow scan with no allow-list |
| No rendered glyph outside the 170-codepoint subset except exact allow-listed gallery fixtures (181-03) | HELD | scan green; only gallery CJK and U+000D allow-listed with reasons |
| No edit to fixture data containing U+00B7 or Phase 182 copy (181-03) | HELD | `operator_fixtures.ex` not in the phase diff |
| No `<img>` logo, no `prefers-color-scheme` in the logo (181-04) | HELD | no `<img ... logo>` in lib; logo classes read theme-block tokens (observed per theme) |
| No hand-roll of the typemark/favicon path data (181-04) | HELD | component `d` values equal both pinned lockups; shipped copies `cmp`-identical |
| axe baseline not hand-edited, regenerated once, no `color-contrast` (181-04) | HELD | commit count 1, fresh `run_id`, preserved `prior`, 0 added `color-contrast` lines |
| No ICO/PNG favicons, ExDoc, README changes (181-04, `deferred`) | HELD | none in the phase diff |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `mailglass_admin/test/mailglass_admin/contrast_contract_test.exs` | ~298-303 | `::placeholder` exempted although it measures about 3.13:1 on Sand and 3.23:1 on White (daisyUI 50% mix) | WARNING | A rendered text pair (the `Subject or recipient` hint in `inbound/filters_form.ex:34`) is below the 4.5:1 floor the same file enforces elsewhere. Not new: the retired v1 palette measured about 3.3:1, axe does not evaluate placeholder pseudo-text, and the exemption is reasoned and staleness-checked, so the gap is disclosed and held. It is not scheduled in any later ROADMAP phase (Phase 182/183 criteria do not mention it), so it will not close by itself. |
| `reference/demo_app/storybook/foundations.story.exs` | 36 | `&rarr;` entity (U+2192) in demo storybook copy | INFO | Advisory demo page, outside `mailglass_admin/lib` and outside the arrow scan; already recorded as deferred item 2 / review IN-01. No `←` or `&larr;` remains anywhere in the demo. |
| Debt-marker gate (`TBD`/`FIXME`/`XXX`) | n/a | none in any added line of the changed text files | none | passes |
| `TODO`/`HACK`/`PLACEHOLDER` in added lines of `lib`, `app.css`, `tokens.css` | n/a | none | none | passes |

The advisory code review (`181-REVIEW.md`: 0 critical, 6 warning, 5 info, dispositions in `181-REVIEW-DISPOSITION.md`) was read and spot-checked against the code. None of its findings contradicts a must-have: WR-04 (the `@media` wrapper is not asserted by parity) I confirmed by reading, but the wrapper is present in the bundle and my browser probe exercised it (system theme under a dark OS rendered dark values); WR-03 (un-fingerprinted immutable caching) is a future-update risk, not a current defect, because the new woff2 files have new names. These stay open follow-ups, non-blocking.

### Regression Gate Browser Flake: reported faithfully (not hidden, not overstated)

**Observation from the orchestrator:** `bash scripts/gsd-regression-gate.sh` exits 1 at HEAD in 3 of 3 runs because of one Playwright test, `e2e/structural.spec.js:2655 › Preview: Phase 178 axe cell matches the committed baseline`, which times out (`test.slow()`, 90 s) with `browserContext.newPage: Target page, context or browser has been closed` inside `AxeBuilder.analyze` on the third (`system`) iteration. Everything else in the gate passes.

**What I did and found:**

1. **Could not reproduce it.** Three runs on this machine all passed: (a) the isolated cell (1 passed; 32.6 s that time, which is one ~30 s stalled scan inside the 90 s budget); (b) the full 37-test trio `phase170-journey + flows + structural` with the gate's `--grep` and `--workers=1` (`37 passed (23.6s)`, axe cell 3.3 s); (c) the same trio with `CI=1` and a random `BROWSER_SERVER_PORT`, which is exactly how `run_browser_suite` in the gate invokes it (`37 passed (26.2s)`, axe cell 3.3 s, `37 passed` summary, exit 0). I did not run the whole `gsd-regression-gate.sh` end to end, so the specific condition the orchestrator hit (the browser suite running last after the core, admin and inbound suites) is not reproduced here.
2. **Phase 181 did not change the test.** `git diff 9bd70fa5 HEAD -- mailglass_admin/e2e/structural.spec.js` touches only `ACCENT_LIGHT_RGB` (+ comment) and the three font-weight tests (700 -> 600). The failing cell and `e2e/axe-baseline.spec.js` are unchanged.
3. **The same failure with the same signature is already documented and measured in Phase 180.** `.planning/phases/180-reproducible-admin-bundle-and-before-catalog/deferred-items.md` item 4 records `Test timeout of 90000ms exceeded` followed by `browserContext.newPage: Target page, context or browser has been closed` thrown from `AxeBuilder.analyze` at `structural.spec.js:2671`, in 4 of 4 suite runs and in the full `npm run test:operator-browser` (`353 passed, 1 failed`), on the Phase 180 tree, before Phase 181 started. Its measured cause: `@axe-core/playwright` runs `axe.runPartial` inside the email `<iframe sandbox="allow-same-origin">`; when the scan begins after the LiveView has connected, that partial run stalls about 30 s (about 1.1 s if the scan starts before the connect). The test scans three themes inside one 90 s budget, so three stalls exceed it.
4. **I re-measured that mechanism at HEAD** with a throwaway spec (deleted): an unsettled scan took 1.09 s and a settled scan (`.phx-connected` plus 1 s) took 29.18 s, reproducing Phase 180's 29.2 s constant. So whether a run passes (about 3-35 s) or times out (3 x 29 s plus overhead is over 90 s) depends on whether the scan wins the race against the LiveView connect, which depends on machine load. The orchestrator's runs show load (the box was at load average 8+ during my session, with many logged-in users and other browsers open).
5. **The assertion the test makes is satisfied.** In every run that completed, all three themes equalled the committed baseline (`aria-allowed-attr: 1` on `#assigns-plan`, no `color-contrast`).

**Assessment:**

- It is a timing-dependent, pre-existing flake of an advisory lane (`operator_browser_gate`), with a measured root cause that predates Phase 181. It is not a Phase 181 goal, requirement or must-have failure, and no required lane is affected (the required `support_contract_admin` lane is green).
- I cannot prove Phase 181 had zero effect on the odds of losing the race: Phase 180 itself observed that markup changes can move the race across the timing window, and Phase 181 changed head and header markup (fonts, inline logo). I did not run an A/B at `9bd70fa5`. What the evidence supports is: the failure mode exists at the base, the constant is unchanged, and the test body is unchanged.
- **Consequence for the workflow:** `scripts/gsd-regression-gate.sh` (the project `test_command`) can exit 1 on this one test in a loaded environment. That should not be read as a Phase 181 regression. It is routed as a separate follow-up, not a Phase 181 gap.
- **Suggested follow-up (outside Phase 181, owner decision per Phase 180):** scan the admin page only, `new AxeBuilder({ page }).exclude('iframe[title^="Email HTML preview"]')`, in the Phase 178 cell and in `axe-baseline.spec.js`. Phase 180 measured that the committed Preview cells are identical with and without the stall, so no baseline regeneration is implied. Alternatively wait for the settled page and analyse once per theme in separate tests. Neither belongs in this phase's frozen "axe once, last" scope.

### Environmental Note: `Phase164RepositoryTruthTest`

The 181-04 SUMMARY reports one root-suite failure, `git runtime rules do not conceal the retired finalize-phase extension paths` (`test/scripts/phase_164_repository_truth_test.exs:261`). I verified it is environmental: `git check-ignore -v .gsd/extensions/finalize-phase/index.ts` names the rule `.gsd/.gitignore:1:*`; that file is untracked (`git ls-files .gsd` is empty), 2 bytes (`*`), dated Oct 7, before this phase; no Phase 181 commit touches `.gitignore` or `.gsd` (0 commits); and in a fresh `git clone` of HEAD the same `git check-ignore` exits 1 (path not ignored), i.e. the `refute ignored?` assertion would hold on a clean checkout. I did not run the bare full root suite.

### Human Verification Required

None. Per D-52 every acceptance criterion in this phase is machine-observable and is covered by a required-lane test, a deterministic command, or (for the rendered outcome) a verifier-run browser probe. All prohibitions are test-tier. The browser same-origin and 404 checks remain labelled advisory in the plan and are not cited as the required proof; the required proof is `font_assets_contract_test` and `assets_test`, which I ran.

### Gaps Summary

No gaps. All five ROADMAP success criteria and all merged plan truths are verified against the codebase, all six BRTOK requirements are accounted for with no orphans, and every prohibition holds.

Non-blocking items for the owner or the next phase to pick up (none changes the status):

1. **Regression-gate flake** in the advisory Playwright axe cell (above): pre-existing, not attributable to Phase 181, not reproduced in three independent runs here; suggested hardening is the Phase 180 follow-up.
2. **`::placeholder` contrast exemption** (about 3.1-3.2:1 on the light theme): disclosed and test-held but not scheduled in any ROADMAP phase; recommend adding it explicitly to Phase 182's scope so it does not stall.
3. **Open advisory review items** WR-01 to WR-05 and IN-02, IN-04, IN-05 (test-hardening and docs wording); IN-01 and IN-03 are tracked as deferred.

---

_Verified: 2026-11-15T19:35:06Z_
_Verifier: Claude (gsd-verifier)_
