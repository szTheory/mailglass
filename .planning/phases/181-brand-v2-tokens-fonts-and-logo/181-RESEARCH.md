# Phase 181: Brand v2 Tokens, Fonts and Logo - Research

**Researched:** 2026-11-15
**Domain:** Design-token swap, self-hosted font delivery, inline-SVG logo, and asset provenance for a mountable Phoenix LiveView admin (Tailwind 4.1.12 standalone + daisyUI 5.5.19, Elixir 1.18.4 / OTP 27)
**Confidence:** HIGH for stack, file locations, test impact and pitfalls (every claim below was read or run in this session, including a scratch Tailwind build with the proposed tokens). MEDIUM for the *designed* role values (a design call inside Claude's Discretion; contrast-verified, not owner-reviewed).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Wording amendments (BRTOK-01, BRTOK-03, ROADMAP criteria 1 and 3)
- **D-01:** **"36 slots" is not a number in the code; amend it the way Phase 179 amended 25 to 26.** Real contract: 39 `--mg-color-*` roles per theme (`brandbook/tokens.json`, `color.light`/`color.dark`), 20 daisyUI `--color-*` slots per theme (`mailglass_admin/assets/css/app.css` ~32-51, 69-88) that consume 15 of those roles, plus 2 new logo roles per theme (`--mg-logo-glass`, `--mg-logo-overlap`). The role map covers all 39 roles plus the 2 logo roles in light and dark. A plan task amends "36" in BRTOK-01, ROADMAP and PROJECT.md wording; a module/test doc says why so nobody "fixes" it back.
- **D-02:** **"Seven woff2 files" is six.** The pinned zip's `assets/fonts/web/` holds six woff2 (`a-display-600`, `ui-400`, `ui-600`, `ui-400i`, `a-mono-400`, `a-mono-600`; 52,508 bytes) and a seventh file that is `fonts.css`. Amend BRTOK-03 and criterion 3 to six. This is a family swap (Inter, Inter Tight and IBM Plex are removed; Funnel Display, Atkinson Hyperlegible Next and Atkinson Hyperlegible Mono replace them). There is no 700 face and no Inter Tight in the zip.

### Token source, role map and parity (BRTOK-01)
- **D-03:** **No generator.** Rewrite `brandbook/tokens.json` and `brandbook/tokens.css` **in place** to v2, keeping the `--mg-color-*` role names and the `palette` plus `color.<tier>.<role>` shape with `{palette.x}` aliases. Palette entries take v2 names (sand, espresso, deep-glass, ...). A test cross-checks each palette hex against `brandbook/v2/brand.json` by name. Reason: core never reads these files; only the admin build and admin tests do (plus the retired v1 book pages `brandbook/index.html`, `examples/landing-page.html`). Phase 180 D-08 already lists `brandbook/tokens.css` as a build input Phase 181 edits, and Phase 179 D-17 left v1 alone only "until Phase 181". The research recommendation of `mix mailglass_admin.tokens.gen` was rejected on cost: a second `--check` for about 120 hand lines that a parity test can prove.
- **D-04:** **Extend `token_parity_test` to every role in all three CSS blocks**: light `:root`, `[data-theme=dark|mailglass-dark]`, and the `@media (prefers-color-scheme: dark)` system block. Today the media block is checked by nothing (`extract_mg_token_value/3` covers only the first light occurrence and the `[data-theme=dark]` blocks), and Phase 180 D-10 relies on it for system mode.
- **D-05:** **Slots with no v2 source are built only from book hexes** (reuse one, or alpha-composite two). No new hue. Each designed value records its derivation in its `tokens.json` `$description` and is covered by a contrast pair (D-07).
  - Book sources that exist: Sunken Sand `#ECE5D8` (light sunken/selected), Control Edge `#857569` (dark `#8B7D72` appears only in prose in `brand.json` `color.secondary[3].role`), the status `textLight`/`textDark` hexes as solids, code ground `#14100D` (dark sunken candidate).
  - Genuinely designed: `*-bg` (10% tint, matching the existing `bg-error/10`, `bg-success/10`, `bg-warning/10` usage), `info-*` (Deep Glass / Bright Glass; the book has no info hue and red means only Failed), `text-disabled`, `link-hover`/`link-active`, dark sunken, dark selected, dark overlay.
  - Shadow tints in the `app.css` `@theme` (~128-130) move from navy `rgb(13 27 42 / …)` to an Espresso tint.

### Static contrast test (BRTOK-02)
- **D-06:** A new admin test file plus a pure luminance/contrast helper in `mailglass_admin/test/support/`. No new dependency; `mix.lock` is unchanged. Use the WCAG 2.2 sRGB threshold **0.04045** (the book's), not the 0.03928 in the existing `accessibility_test.exs` helper (~106-133).
- **D-07:** Two pair sets, per theme:
  - **Book pairs:** every `brandbook/v2/brand.json` `color.contrastPairs[]` entry (12 per theme), resolved through the tokens, each at or above its `minimum` and within ±0.02 of the published `contrast`.
  - **Admin pairs:** a table in the test of the pairs the CSS actually renders: each daisyUI X on X-content, `text-{success,warning,error,primary,secondary}` on base-100/base-200 and on their own 10% tint (alpha-composited), border-input and focus ring on base-100/base-200 (>= 3.0), logo glass on base-100 (>= 3.0).
  - **Coverage guard:** fails when a daisyUI slot is in no declared pair. Explicit exemptions with reasons: base-300 dividers under 3:1 (already pinned in `accessibility_test.exs` ~92-104) and disabled text.
  - **Book `never` rules enforced:** logo Glass is never a text or control role, Sand Line is never border-input, Deep Glass is never dark-theme text.
  - **Mutation proof (METHODOLOGY):** lower one role hex and the test goes red; record commands and results in the plan summary.
- **D-08:** `config/test_exceptions.exs` lists only core and inbound files, so editing `accessibility_test.exs` in place is safe. If the axe producer shows any rise in `color-contrast`, fix tokens before persisting; never bake a regression into `docs/axe-baseline.json`.

### Fonts (BRTOK-03)
- **D-09:** **Weight mapping: set `--font-weight-bold: 600` in the `app.css` `@theme`; leave all 168 `font-bold` call sites untouched.** Verified with the pinned Tailwind 4.1.12 binary in a scratch copy: the only output diff is that variable, and `.font-bold` resolves to 600. daisyUI 5.5.19 never hardcodes 700 (`.btn`, table `thead`, `.fieldset-legend`, `.card-title` hardcode 600, so they now match the 600 face exactly). `check-conformance.sh` lines ~279-283 (BOLD-GATE) bans `font-semibold`/`font-medium` in lib, and 14 admin test/e2e files pin `font-bold`, so renaming is rejected. Update the `@theme` comment (~100-107, "400/700 only") and the advisory e2e assertions (`e2e/admin-assets.spec.js:325` expects "700"; `e2e/structural.spec.js:1139` allows {400,700}) to 600.
- **D-10:** **Faces by role:** Funnel Display on h1-h3 only (the existing heading rules ~472-501); Atkinson Hyperlegible Next for body; Atkinson Hyperlegible Mono for code/pre/`.mono` with `font-variant-ligatures: none`; tabular numerals in dense text. Keep `font-display: swap` as the book's `fonts.css` does; the book's `type.*.css` stacks are the fallbacks. A 600 face requested at 700 gets no faux bold (verified in Chromium and WebKit; Firefox unverified, same threshold expected), so `font-synthesis-weight: none` is optional and harmless as a guard.
- **D-11:** **Embed fonts at compile time like CSS and logo already are** in `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`: `@external_resource`, `File.read!`, a name-to-bytes map; `@allowed_fonts` becomes the map's keys. A font outside it (for example the old `inter-400.woff2`) returns 404. This also makes the moduledoc's "embedded" claim true (today it reads from disk per request).
- **D-12:** **Required-lane proof is static** (admin `verify.support_contract.admin`): every woff2 starts with `wOF2`; the set of `priv/static/fonts/*.woff2`, `@allowed_fonts` and the `@font-face` URLs in the compiled CSS are equal; compiled CSS has no `url(http`, no `url(//`, no remote `@import`; the three OFL texts sit beside the fonts. The browser check ("every font request has the host's origin", font-outside-allowlist rejected) goes in `e2e/admin-assets.spec.js`; run it locally and record the result as evidence, **never cite it as the required proof** (Phase 180 D-04/D-13).
- **D-13:** **Glyph coverage.** The six woff2 are subset identically to 170 codepoints: Basic Latin, U+00A0, U+00B0, Latin-1 letters (incl. ×, ÷), en/em dash, curly quotes, •, …, −. **Not covered: `·` (U+00B7), `✓`, `←`, `→`**, and everything non-Latin. Decisions:
  - Replace every rendered `·` separator with `•` (U+2022): `components.ex:1584`, `operator/repair_state.ex` (74, 193, 213), `operator/support_cards.ex` (326, 337, 419), `operator/suppression_card.ex` (141-143), `operator/timeline.ex` (296, 311, 313, 317-319), `layouts/root.html.heex:7`. Planner re-greps; update the tests that pin the middot. This is a visible-text change forced by the font, not a copy change.
  - A mutation-proven test scans rendered text in `mailglass_admin/lib` (outside comments, `@doc`, `@moduledoc`) for any character outside the subset, with an allow-list for deliberate worst-case fixtures (CJK in `gallery_live.ex:691,1324`, Arabic, emoji, `Ł`, the Fjordline persona strings).
  - Do not re-subset the fonts: that breaks the pin and the zip-sourced hashes.
- **D-14:** `.planning/publish/mailglass_admin-files.expected` (~82-87) is updated **in this phase**, not Phase 183: remove the six Inter/Plex files, add the six woff2 and three OFL texts. `mix mailglass.publish.check --allowlist-only` runs in `mix_task_tests`, which is in `active_required`. `assets_test.exs:51-67` and `bundle_test.exs:37-54` (pin the Inter names) change accordingly.

### Logo, favicon and arrows (BRTOK-04)
- **D-15:** **Header and gallery use the typemark (lockup), rendered inline** (`Components.logo/1`, `components.ex:64`; used at `admin_shell.ex:39` and `gallery_live.ex:169`). The word uses `currentColor` (base-content); the two panes and the overlap use the new `--mg-logo-glass` (`#1895C2` light / `#46B6E8` dark) and `--mg-logo-overlap` (`#0A6488` / `#A8E4F7`) roles, so the logo follows `<html data-theme>` (including explicit dark on an OS in light mode) and never depends on `prefers-color-scheme`. The book forbids inverting colors, so an `<img>` of the light file in dark mode is a misuse. The `/logo.svg` route serves a byte-exact copy of the pinned `mailglass-lockup-light.svg`. Logos stay `<text>`-free (`bundle_test.exs:65-70`); height `h-6` gives about 117 px wide, above the book's 96 px minimum.
- **D-16:** **Favicon: copy the pinned zip `assets/icon/favicon.svg` verbatim** (790 B; it switches glass/overlap through `prefers-color-scheme`, which is right for tab chrome). The SVG `<link>` (`layouts/root.html.heex:10`, hash-busted route `assets.ex:325-328`) stays the only favicon. ICO/PNG favicons and the 16/24/32 px browser check belong to Phase 183.
- **D-17:** **Replace every rendered arrow in U+2190-2193**, not just the `←`: `operator_live.ex:837`, `operator/quick_view.ex:182`, `inbound/quick_view.ex:187`, and the gallery caption `gallery_live.ex:1342` ("nil → no badge"). Use drawn hero icons. `assets/vendor/heroicons-inline.js` has only `arrow-path`, `arrow-uturn-left`, `arrow-down`, so embed `arrow-left`/`arrow-right` (or chevrons) there before the rebuild. A mutation-proven contract test scans rendered `lib` text for these code points and also asserts the icon rule exists in the compiled bundle (a missing icon renders invisibly and nothing else catches it). The glyph test shares the scan with D-13.

### Asset provenance and the brand pin
- **D-18:** **Assets enter the repo only through `scripts/brand_pin.exs`**, from the pinned raw commit URL (`brandbook/brand.pin.json`) with the sha256 checked first. Fallback: a local file hashing to `ed96bb25…` (a verified copy exists at `/Users/jon/projects/abracabrand/.planning/spikes/010-shared-book-engine/sites/mailglass-brand/mailglass-brand.zip`). Never use the mutable Pages URL, never unpack into the repo tree. The script needs a new verb (or a manifest extension): `update` only re-hashes existing `shipped[]` entries (`rewrite_pin`, ~626-643) and `build_pin` hardcodes `owned_dirs`. Every shipped `to` must sit under an owned directory (`entry_issues`, ~238-244) and owned directories are set-equality checked.
  - Add `mailglass_admin/priv/static/fonts` to `owned_dirs` (six woff2 + three OFL texts; the OFL `from` paths that already ship into `brandbook/v2` may ship again).
  - Pin the logo and favicon SVGs under `brandbook/v2/`.
  - A required-lane admin test asserts `priv/static/favicon.svg`, `mailglass-logo.svg` and the inline component's path data are byte- or path-identical to the pinned copies.
  - `priv/static` root also holds `app.css` and `hooks.js`, so it cannot be an owned directory.
  - woff2 hashes come from the zip, never from `brand.json` (TTF hashes). `test/scripts/brand_pin_test.exs:103-105` ("exactly the four required assets") changes in the same `chore(brand):` operation, and `@expected_zip_sha256` is untouched (the zip does not change).

### Sequencing and plan split (about 4 plans)
- **D-19:** Order inside the phase: `brandbook/` source -> `app.css` -> build -> commit `priv/static` -> pinned tests -> axe baseline **last, once**.
  1. v2 tokens, role map, contrast test, rewritten `brand_test`/`token_parity_test`/`accessibility_test`, bundle regenerated.
  2. Pin extension with the font swap in the same change: Inter removed, `@font-face` and family rules, weight 600, compile-time embedding, `bundle_test`/`assets_test`, publish allowlist, e2e font names, middot replacement and glyph-coverage test.
  3. Logo, favicon, arrows and icons; update demo `reference/demo_app/storybook/foundations.story.exs` and `assets/e2e/storybook-fidelity.spec.js` so advisory lanes stay green.
  4. Close-out: BRTOK-06 proof, the `docs/design-system.md` token table (pinned by `token_parity_test.exs` ~205-225), and the axe baseline regenerated once, last (`PERSIST_AXE_BASELINE=1 npm run test:operator-browser -- axe-baseline.spec.js`).
- **D-20:** **Every plan that changes `app.css` (or the root layout) also updates `.planning/research/brand-v2-adoption/before-catalog/<catalog_id>/superseded.json`** so `superseded_by` equals the new bundle sha256 and root-layout blob sha. `before_catalog_manifest_test.exs` (moduledoc ~41-56) reds the required admin lane on every bundle change without it. Leave `docs/ui-baseline-scores.json` alone (LLM scores; the Phase 182 reviewer owns visual judgment); `docs/storybook-axe-approved.json` is updated only if the axe producer requires it. After test edits, rerun `scripts/check_test_exceptions.sh`.
- **D-21:** **BRTOK-06 is proven at phase scope, not by a permanent byte-pin test.** In verification, `git diff <phase-base>..HEAD` is empty for `lib/mailglass/config.ex`, `lib/mailglass/components/theme.ex`, `lib/mailglass/components.ex`, `test/fixtures/vml_golden.html` and their tests, and `core_deterministic_suite` plus `test/mailglass/components/vml_preservation_test.exs` pass unedited. Core holds its own hardcoded hexes (`config.ex:44-63`, `theme.ex:18`) and no core lib or test reads `brandbook/tokens.*`; a permanent byte-pin would freeze host email defaults a later milestone may change on purpose.
- **D-22:** Lanes and commit kinds. Everything required runs in `verify.support_contract.admin` (whole directory plus the Phase 180 `--check` step); no `ci.yml` job, no root `mix.exs` edit. Core pin tests under `test/scripts/` run in the full `core_deterministic_suite`, not the fast `verify.support_contract.core` allow-list (`mix.exs:321`); state which lane proves each requirement and never cite an advisory lane (`operator_browser_gate`, demo e2e) as proof. Commit kinds: admin `lib`/`priv/static` = `feat(admin):`; pin, `brandbook/`, `.planning`, scripts = `chore(brand):`/`docs:`; new tests in new files (test_exceptions.exs is `file:line` keyed). One open PR at a time; run `mix format --check-formatted` inside `mailglass_admin`.

### Claude's Discretion
- Exact role-map file layout, hex values for the genuinely designed slots (within D-05 and D-07), table/column order in the contrast test, test file names, and whether the glyph scan and arrow scan share one file.
- Whether `font-synthesis-weight: none` is added as a guard (D-10).
- The new `brand_pin.exs` verb name and manifest shape (D-18), within the stated constraints.

### Deferred Ideas (OUT OF SCOPE)
- ICO/PNG favicons, 16/24/32 px browser favicon check, ExDoc logo/CSS, README `<picture>`, design-system.md prose beyond the token table: Phase 183.
- CLAUDE.md line "CI runs `git diff --exit-code`" and brand/PRODUCT.md edits: Phase 183 with owner sign-off.
- Re-subsetting the fonts to add `·` or arrows: rejected (breaks pin); revisit only if the book ships a wider subset.
- `docs/ui-baseline-scores.json` rescoring: Phase 182 reviewer.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRTOK-01 | v2 tokens and explicit role map for all admin theme slots, light + dark | Complete 39-role + 2-logo-role table with palette names, book sources and computed contrast (Role Map section); compiled-bundle block selectors; three-block parity design; wording amendment locations (REQUIREMENTS.md:26, ROADMAP.md:143, PROJECT.md:24) |
| BRTOK-02 | Static contrast test per theme, no new dependency | Pair inventory (12 book + admin table), binding table pair-id to role, helper placement, 0.04045 threshold, exhaustive margin matrix, mutation commands; `mix.lock` guard command |
| BRTOK-03 | Six woff2 + OFL texts in `priv/static/fonts`, `@external_resource`, `@allowed_fonts`, weight-600 | Verified cmap (170 codepoints), GSUB features, zip hashes and sizes, compile-time embedding skeleton, `extend` pin verb design, static proof design, prototype bundle facts (minified `@font-face` form), publish allowlist lines, node evidence-script coupling |
| BRTOK-04 | New logo + favicon, `←` replaced | Lockup path structure (4 paths: word + 2 panes + overlap), byte-identity and path-identity test design, arrow sites, heroicons v2.2.0 paths, generic "every hero icon has a rule" test (baseline 29/29), AST-based glyph scan prototype |
| BRTOK-05 | `brand_test`, `token_parity_test`, `accessibility_test` updated; axe baseline regenerated once, last | Per-test break inventory, axe producer mechanics (rebuilds bundle first, one cell per test, `test.slow()`), ratchet rules |
| BRTOK-06 | Core email defaults unchanged, proven by existing tests | Phase-scope diff command set (stronger than D-21's file list), verified zero coupling from core to `brandbook/tokens.*`, `vml_preservation_test.exs` path |
</phase_requirements>

## Summary

This phase is a coordinated re-skin of one package (`mailglass_admin`) plus one script/pin extension in the monorepo root. Every input is local and deterministic: the brand zip is pinned by sha256 (verified this session: the pinned raw URL and the local fallback both hash to `ed96bb25…`), the bundle is a pure function of `app.css` + `lib/**` text + `brandbook/tokens.css` + vendored plugins + the pinned Tailwind binary, and the required lane (`verify.support_contract.admin`) already runs the byte-compare drift gate and the whole admin test directory (baseline measured this session: 1389 tests, 0 failures, about 22 s).

A scratch Tailwind 4.1.12 build with the proposed tokens, font rules and weight mapping confirmed the core mechanics: all 123 `--mg-*` declarations are emitted as plain hex (no named-colour shortening), `--font-weight-bold:600` is the only weight change and `font-weight` values in the bundle become `{400, 600, bolder, inherit, initial, var(...)}` (no 700 anywhere), no retired v1 hex survives, the bundle is 137,441 bytes (budget 150,000), and `hero-arrow-left`/`-right` are absent until vendored. The proposed role map passes every book pair (24 recomputed within 0.005 of the published ratio) and every admin pair, with a worst-case text-on-surface ratio of 5.18.

The main planning risks are not design risks. They are coupling risks that CONTEXT does not list: (1) the pin test helpers derive synthetic zips from the real pin, so adding shipped entries breaks `update` tests unless `synthetic_files/1` and `tmp_tree/1` change; (2) `scripts/check_phase174_evidence.cjs` and `check_phase175_evidence.cjs` hard-code the six Inter/Plex file names and run in `scripts/gsd-regression-gate.sh` (the project's `workflow.test_command`) and the advisory demo CI job; (3) `check-conformance.sh` HEX-GATE trips on any hex literal on a line containing "color" inside `lib/**/*.ex`; (4) `bundle_test` compares `File.ls!` output exactly, so the OFL texts break it unless it filters by extension; (5) several advisory e2e specs and the demo storybook hard-code v1 RGB/hex values and font names.

**Primary recommendation:** Follow D-19's four-plan order, keep each plan self-green (move the `design-system.md` token-table row and its pinned assertion into plan 1 with the tokens), implement the pin extension as one idempotent `extend` verb, put all `lib/` edits (middot, arrows, logo, icons) before the single final bundle rebuild of each plan, and write every new test as a pure function over injected inputs with a mutation "teeth" block so the pass is non-vacuous.

## Planner Flags (read before decomposing into plans)

| # | Flag | Why it matters | Recommendation |
|---|------|----------------|----------------|
| F1 | **Keep every plan green.** D-19 places the `design-system.md` token table in plan 4, but `token_parity_test.exs:208` pins `"base-200 | White #FFFFFF | Ink-raised #152538"` and plan 1 rewrites that test file. | A plan-1 lane run would be red on a stale doc row. | Move the token-table rows and the pinned assertion into plan 1 (docs follow tokens). Plan 4 keeps BRTOK-06 and the axe baseline. Also fix the two statements "Type weights are exactly 400 and 700" and the row `Type (400/700 only)` in plan 2 with the weight change. |
| F2 | `scripts/check_phase174_evidence.cjs:44-51` (`FONT_FILES`), `check_phase174_evidence.test.cjs:191`, `check_phase175_evidence.cjs:53-57` (the six names inside `FIDELITY_SOURCE_FILES`, declared at line 33) pin the six old file names. Baseline `node --test` of the four contract files is 42 pass / 0 fail now. | They run in `scripts/gsd-regression-gate.sh:101-104` (`workflow.test_command`) and in the advisory `demo_browser_evidence` job (ci.yml:1059). They read the files, so a deleted font throws. | Plan 2 updates the six names in all three files (count stays six, so `loadedFaces.length === 6` and `"assets:storybook-css-and-six-font-faces"` stay valid). Re-run the node tests. |
| F3 | `test/scripts/brand_pin_test.exs` is coupled to a one-directory pin beyond lines 103-105: `tmp_tree/1` (41-48) copies only `brandbook/v2`; `synthetic_pin/3` (366-379) maps over the REAL pin's `shipped[]` and does `Map.fetch!(files, entry["from"])`; `synthetic_files/1` (~338-345) has only four members. | Adding shipped entries makes every `update`/`check_zip` test crash on a missing synthetic member and the "clean copy verifies" test fail on missing fonts. | Same `chore(brand):` change: extend `synthetic_files/1` with every extension member, make `tmp_tree/1` copy every `owned_dirs` entry of the real pin, replace "exactly the four required assets" (103-105) with a test-owned expected list (four initial + extension), keep `@required_assets` as the four-asset `init` contract. |
| F4 | **HEX-GATE** (`mailglass_admin/scripts/check-conformance.sh`): `grep -rEn 'color[^#]*#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b' lib --include="*.ex"`. Required lane `conformance_gates`. | A `@doc` line such as "color is Deep Glass #0A6488" fails CI. | No hex literals on a line that contains the word "color" anywhere in `lib/**/*.ex`. Describe colors by role name in docs. |
| F5 | `bundle_test.exs:37-54` does `File.ls!(fonts_dir) |> Enum.sort() == expected`. | The three OFL texts live in the same directory (D-12/D-18). | Filter to `.woff2` for the font list and assert the OFL set separately. |
| F6 | The `root.html.heex:7` `<title>` suffix ` · mailglass` is rendered by the OS/browser tab, not by the bundled fonts. | D-13 includes it anyway (and the scan would flag it). It is also the root-layout blob the catalog marker binds to. | Do it (locked), in the same task as the first `superseded.json` update that follows, and say so in the summary: not font-forced, done for scan consistency. |
| F7 | D-13's middot list omits `inbound/records_list.ex:12` and `preview/assigns_form.ex:3`. | Both are inside `@moduledoc`, so the AST scan correctly ignores them. | No change needed; the scan (not the list) is the contract. |
| F8 | Fixture strings with `·` stay: `test/support/operator_fixtures.ex:472` (`"operator review · Ångström"`), `operator_live_test.exs:675,690` (`"東京·Ångström-"`), and the e2e pins of that fixture (`phase169-journey.spec.js:220`, `flows.spec.js:2211/2238/2255`). | They are stored data, not `lib` text; they render through the fallback font, which is a legitimate worst case. | Do not touch them. Only strings produced by `lib` change. |
| F9 | Bundle budget: `bundle_test.exs:24` caps `app.css` at 150,000 bytes; the prototype is 137,441. | About 12.5 KB headroom; two new icons plus two logo classes cost roughly 1 KB. | Fine; re-check after the final build. |
| F10 | `font-synthesis-weight: none` (D-10 discretion). | All three families ship a 600 face, so no weight synthesis can occur at 700. Italic is covered by the 400 italic face for Next only. | **Skip it.** Fewer bytes, no demonstrated need; the e2e check in D-12 is the guard. Record the decision. |
| F11 | Hard-coded v1 values in advisory specs: `e2e/admin-assets.spec.js:8-22` (`tokenBackgrounds` RGB sets), `e2e/structural.spec.js:13-14` (`ACCENT_LIGHT_RGB = "rgb(39, 123, 150)"`, used at 2383), `reference/demo_app/assets/e2e/storybook-fidelity.spec.js:727` (`"#0d1b2a" : "#f8fbfd"`), `reference/demo_app/storybook/foundations.story.exs:41-48`. | Not required-lane, but D-19.3 wants advisory lanes green. | Update to the v2 RGB values listed under "Advisory e2e values" below and run the specs locally. |
| F12 | `npm run test:operator-browser` starts with `mix mailglass_admin.assets.build` (package.json:5). Each axe cell is its own test with `test.slow()` (90 s). 180's deferred item 4 documents a ~30 s axe stall inside the Preview email iframe. | The producer can rewrite `priv/static/app.css` before scanning, and a stall is survivable (one stall per test). | Run the producer only after the bundle is final; after it finishes, `git diff --exit-code mailglass_admin/priv/static/app.css` must be clean. Do not fold the iframe exclusion into this change (180 summary: "regenerating the baseline is Phase 181's single allowed change"). |
| F13 | The v1 book pages `brandbook/index.html` and `brandbook/examples/landing-page.html` load `tokens.css` (index.html:9). | The in-place rewrite repaints them with v2 values and v1 prose. | Accepted by D-03. Do not edit them or `brandbook/assets/*` (ExDoc in all three `mix.exs` still consumes `brandbook/assets/logo-mark.svg` and `favicon.svg` until Phase 183). |
| F14 | `.planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/` has no `superseded.json` today (catalog is LIVE). | Every plan that changes `priv/static/app.css` or `root.html.heex` must leave a current marker or the required lane is red. | One marker file, rewritten (not added) by each later plan. Compute with `shasum -a 256 mailglass_admin/priv/static/app.css` and `git hash-object mailglass_admin/lib/mailglass_admin/layouts/root.html.heex`. Group "rebuild bundle + rewrite marker" in one task. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Brand values (hex, names, derivations) | Static source (`brandbook/tokens.json`, `tokens.css`) | Test layer (parity + contrast) | Single hand-written source; the bundle is generated from `tokens.css`; tests prove `tokens.json` == `tokens.css` == bundle == `brand.json`. |
| Role-to-daisyUI slot mapping | Build input (`assets/css/app.css` theme blocks) | — | The 20 slots map to roles with `var(--mg-*)`; no raw hex in theme blocks (TOKEN-01). Unchanged structure, new values. |
| Theme selection (light/dark/system) | Frontend server (`<html data-theme>` from `Layouts.root_theme/1`) | Browser (`prefers-color-scheme` only for system) | Phase 180 D-10: `<html>` owns the theme; the logo must follow it, never the media query. |
| Font delivery | API/Backend (`Controllers.Assets`, compile-time embedded map) | Static (`priv/static/fonts`), Browser (`@font-face`) | No filesystem read per request, closed allow-list, same-origin only. |
| Logo rendering | Frontend server (`Components.logo/1` inline SVG) | Browser (CSS vars via `.mg-logo-*` classes) | Inline SVG is the only way to follow `<html data-theme>`; `<img>` cannot. |
| `/logo.svg` and favicon | API/Backend (`Controllers.Assets` embeds bytes) | Static (`priv/static/*.svg`, pinned copies in `brandbook/v2`) | Byte-exact pinned copies; favicon switches by OS (tab chrome). |
| Asset provenance | Tooling (`scripts/brand_pin.exs`, `brandbook/brand.pin.json`) | Test layer (`brand_pin_test`, admin byte-identity tests) | sha256-pinned zip, owned-dir set equality, tamper tests. |
| Bundle reproducibility | Build/CI (`assets.build --check`, required lane) | Test layer (`bundle_reproducibility_contract_test`, `before_catalog_manifest_test`) | Phase 180 machinery; this phase must leave it green and keep the catalog marker current. |
| Accessibility proof | Test layer (static contrast math; axe ratchet) | Advisory browser lane | Required proof is static math over declared pairs; axe is the persisted ratchet. |

## Standard Stack

No library is added. `mix.lock`, `mailglass_admin/mix.lock`, `mailglass_inbound/mix.lock` and `package-lock.json` must show no diff.

### Core (already pinned, reused)
| Tool | Version | Purpose | Provenance |
|------|---------|---------|------------|
| Tailwind standalone binary | 4.1.12 | Generates `priv/static/app.css` (minified) | [VERIFIED: mailglass_admin/config/config.exs:7] `version: "4.1.12",` ; binary at `mailglass_admin/_build/tailwind-macos-arm64-4.1.12` |
| daisyUI (vendored) | 5.5.19 | Theme plugin, components | [VERIFIED: mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex moduledoc] "vendored daisyUI 5.5.19 and the icon plugin" |
| Heroicons (vendored inline plugin) | v2.2.0 outline | `hero-*` icon classes | [VERIFIED: assets/vendor/heroicons-inline.js header] "SVG source: heroicons v2.2.0 (tag v2.2.0), 24/outline set." |
| ExUnit, Jason, Floki | project deps | New tests | existing |
| `:zip`, `:crypto` (OTP) | OTP 27 | `brand_pin.exs` zip read + sha256 | existing in script |
| Playwright / axe | `@playwright/test ^1.59.1`, `@axe-core/playwright ^4.11.2` | Advisory browser evidence + axe producer | [VERIFIED: mailglass_admin/package.json] |

### Fonts and licenses (from the pinned zip, not installed from a registry)
| Face | File in zip (`assets/fonts/web/`) | Bytes | sha256 (first 16) |
|------|-----------------------------------|-------|-------------------|
| Funnel Display 600 | `a-display-600.woff2` | 8,164 | 3e756227e0281898 |
| Atkinson Hyperlegible Next 400 | `ui-400.woff2` | 9,164 | c9ea743af769d03c |
| Atkinson Hyperlegible Next 600 | `ui-600.woff2` | 9,620 | f3fc5d883120a058 |
| Atkinson Hyperlegible Next 400 italic | `ui-400i.woff2` | 10,584 | e24ed9e06273f44b |
| Atkinson Hyperlegible Mono 400 | `a-mono-400.woff2` | 7,492 | 6c2b7d2dd9547f14 |
| Atkinson Hyperlegible Mono 600 | `a-mono-600.woff2` | 7,484 | 27abbe6bde2ef17c |

Total 52,508 bytes. [VERIFIED: sizes and hashes computed from the local zip whose sha256 is `ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b`, identical to `brandbook/brand.pin.json` `"sha256"`; the pinned raw GitHub URL was also downloaded this session and hashes to the same value.] OFL texts (already pinned into `brandbook/v2/`): `assets/fonts/OFL-FunnelDisplay.txt` (4,382 B), `OFL-AtkinsonHyperlegibleNext.txt` (4,431 B), `OFL-AtkinsonHyperlegibleMono.txt` (4,436 B) [VERIFIED: brandbook/brand.pin.json `bytes` fields].

SVG assets to pin under `brandbook/v2/`: `assets/logo/mailglass-lockup-light.svg` (4,084 B, sha256 `26af767b48d19589…`), `assets/logo/mailglass-lockup-dark.svg` (4,084 B, `790ef5d990e80a47…`), `assets/icon/favicon.svg` (790 B, `f0c204dd56495572…`). Recommend pinning **both** lockups so a test can prove the dark fills equal the dark token values and that the path data is identical across themes (verified: identical `d` for all four paths).

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| In-place `tokens.*` rewrite (D-03, locked) | `mix mailglass_admin.tokens.gen` | Rejected by owner decision: second `--check` for about 120 hand lines. |
| One `extend` verb | Hand-editing `brand.pin.json` | Forbidden by the pin's own note ("never hand-edit"). |
| Explicit `~w()` font list feeding the compile-time map | `File.ls!` at compile time | A directory-derived allow-list would silently admit a stray file; keep the list a reviewed constant. |

**Installation:** none. Package Legitimacy Audit is not applicable: this phase installs no external package.

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | n/a | No package is installed. Fonts and SVGs come from the sha256-pinned brand zip; heroicons path data is copied from the already-vendored v2.2.0 set. |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none
Guard (BRTOK-02 success criterion 2): `git diff --exit-code -- mix.lock mailglass_admin/mix.lock mailglass_inbound/mix.lock mailglass_admin/package-lock.json`.

## Role Map (BRTOK-01) — the explicit table

### Book values used, verbatim (`brandbook/v2/brand.json`) [VERIFIED: file read this session]
- Light, lines 142-173: Sand `"hex": "#F6F1E8"`, White `"#FFFFFF"`, Espresso `"#2A1D17"`, Deep Glass `"#0A6488"`, Sand Line `"#DDD3C4"`.
- Dark, lines 174-205: Roast `"#1D1713"`, Roast Surface `"#2A211B"`, Bone `"#F3EEEA"`, Bright Glass `"#6CC6F0"`, Roast Line `"#43372E"`.
- Logo, lines 206-213: `"hex": "#1895C2"`, `"onDark": "#46B6E8"`, `"overlapLight": "#0A6488"`, `"overlapDark": "#A8E4F7"`.
- Secondary, lines 214-235: Muted Espresso `"#665850"`, Muted Bone `"#B9ADA3"`, Sunken Sand `"#ECE5D8"`, Control Edge `"#857569"` with role text `"Dark uses #8B7D72."`.
- Status, lines 236-272: Delivered `"textLight": "#1D6B3C"` / `"textDark": "#7FCB9A"`; Delayed `"#855300"` / `"#E3B25C"`; Failed `"#B3261E"` / `"#F09A93"`; Sent `"#2A1D17"` / `"#F3EEEA"`; Not sent `"#665850"` / `"#B9ADA3"`.
- Code ground (`code.ground`): light `"#EFE9DD"`, dark `"#14100D"`.
- `never` (lines 492-509): Glass "text of any size on Sand or White"; Sand Line "the only boundary of a control (use Control Edge)"; Deep Glass "text on Roast (use Bright Glass)"; "a status color" "the only way to tell a status".

### Proposed role map (all 39 `--mg-color-*` roles + 2 logo roles)
"Designed" values are alpha composites of two book hexes (D-05) and are `[ASSUMED]` design choices (Claude's Discretion), each contrast-verified by computation this session. Everything else is a verbatim book hex.

| Role | Light | Dark |
|------|-------|------|
| background | Sand `#F6F1E8` | Roast `#1D1713` |
| surface | White `#FFFFFF` | Roast Surface `#2A211B` |
| surface-raised | White `#FFFFFF` | Roast Surface `#2A211B` |
| surface-overlay | White `#FFFFFF` | designed: 6% Bone over Roast Surface = `#362D27` |
| surface-sunken | Sunken Sand `#ECE5D8` | code ground dark `#14100D` |
| surface-selected | Sunken Sand `#ECE5D8` | designed: 12% Bright Glass over Roast Surface = `#323535` |
| border | Sand Line `#DDD3C4` | Roast Line `#43372E` |
| border-input | Control Edge `#857569` | `#8B7D72` (book prose) |
| border-strong | Control Edge `#857569` | `#8B7D72` |
| text | Espresso `#2A1D17` | Bone `#F3EEEA` |
| text-muted | Muted Espresso `#665850` | Muted Bone `#B9ADA3` |
| text-disabled | Control Edge `#857569` (exempt) | `#8B7D72` (exempt) |
| text-inverse | White `#FFFFFF` | Roast `#1D1713` |
| accent, accent-text, link, focus-ring | Deep Glass `#0A6488` | Bright Glass `#6CC6F0` |
| link-hover, link-active | designed: 25% Espresso over Deep Glass = `#12526C` | Lit Glass `#A8E4F7` (book `overlapDark`) |
| success-text / -border / -solid | `#1D6B3C` | `#7FCB9A` |
| success-bg | designed: 10% `#1D6B3C` over White = `#E8F0EC` | designed: 10% `#7FCB9A` over Roast Surface = `#333228` |
| success-on-solid | White `#FFFFFF` | Roast `#1D1713` |
| warning-text / -border / -solid | `#855300` | `#E3B25C` |
| warning-bg | `#F3EEE6` | `#3D3022` |
| warning-on-solid | White | Roast |
| error-text / -border / -solid | `#B3261E` | `#F09A93` |
| error-bg | `#F7E9E8` | `#3E2D27` |
| error-on-solid | White | Roast |
| info-text / -border / -solid | Deep Glass `#0A6488` | Bright Glass `#6CC6F0` |
| info-bg | `#E6F0F3` | `#313230` |
| info-on-solid | White | Roast |
| `--mg-logo-glass` | `#1895C2` | `#46B6E8` |
| `--mg-logo-overlap` | `#0A6488` | `#A8E4F7` |

Counts: 39 roles x 3 CSS blocks = 117 declarations, plus 2 logo x 3 = 6, total 123 `--mg-*` declarations (matches the prototype bundle: `total mg decls 123`, all hex).

Rules of thumb behind the choices: `surface` is the card colour (book pairs `caption`, `application-copy`, `link` and every `status-*` pair sit on White / Roast Surface); `background` is the page; the book says the typemark sits on the page background, so do not place the logo on `surface-sunken` (glass is 2.74:1 there).

### Computed contrast (WCAG 2.2, threshold 0.04045) [VERIFIED: computed this session]
- All 24 published `contrastPairs` (12 per theme) recompute within **0.005** of the published value (largest diff 0.00496), so the D-07 tolerance of 0.02 is generous.
- Every text role (`text`, `text-muted`, `link`, `accent-text`, `*-text`) on every surface role: minimum **5.18** light (`warning-text` on `surface-sunken`), **5.64** dark (`text-muted` on `surface-selected`).
- Status text on its own `*-bg`: light 5.53 to 5.68, dark 6.06 to 6.73. `*-on-solid` on `*-solid`: light 6.49 to 6.58, dark 8.23 to 9.27.
- daisyUI pairs (X on X-content): light 5.85 to 6.58; dark 8.08 to 9.27. `text-{success,warning,error,primary,secondary}` on its own 10% tint over base-100/base-200: tightest **4.97** (light `error` over base-100), all others above 5.0.
- `border-input`: light 3.93 (Sand) / 4.42 (White); dark 4.45 (Roast) / 3.96 (Roast Surface) / 3.11 (selected). `focus-ring` >= 5.25 light, >= 6.47 dark. Logo glass on base-100: 3.05 light (book value, passes `>= 3.0`), 7.70 dark.
- Intentionally sub-3:1 (exempt, keep pinned in `accessibility_test`): `border` Sand Line on Sand **1.32**, Roast Line on Roast **1.54**.
- Never rules hold: Deep Glass on Roast is 2.69 and is not a dark text role; `border-input` is not Sand Line.

## Architecture Patterns

### System Architecture Diagram

```
brandbook/v2/brand.json (pinned, MIT)  ──cross-check by name──┐
                                                              ▼
brandbook/tokens.json (oracle: palette + color.<tier>.<role>, $extensions.source)
        │  parity (3 blocks x 41 roles)                │  contrast pairs resolve through
        ▼                                               ▼
brandbook/tokens.css ──@import──► mailglass_admin/assets/css/app.css ──► Tailwind 4.1.12 ──► priv/static/app.css
   (light | dark | system-media)        │  daisyUI theme blocks (20 slots/theme → var(--mg-*))      │  (committed, drift-gated)
                                         │  @font-face x6, --font-weight-bold:600, .mg-logo-*        │
                                         │  scans lib/** text + vendored heroicons-inline.js          │
                                         ▼                                                            ▼
brand.pin.json ─extend verb─► mailglass_admin/priv/static/fonts/* (6 woff2 + 3 OFL)        Controllers.Assets
   (sha256-pinned zip)        brandbook/v2/{lockup-light,lockup-dark,favicon}.svg   ──cp──►  embeds CSS, fonts, logo, favicon
                                                                                                      │ HTTP (same origin)
<html data-theme=…> (Layouts.root_theme) ──► Components.logo/1 inline SVG (word=currentColor; panes via var(--mg-logo-*))
                                              browser tab ──► /favicon.svg?v=<md5> (prefers-color-scheme)
required lane: assets.build --check + whole admin test dir │ core: test/scripts/brand_pin_test + publish allowlist
advisory only: Playwright (fonts origin, 404 on old font, axe producer), demo storybook
```

### Recommended file layout (new and changed)
```
brandbook/tokens.json, tokens.css                      # rewritten in place (v2)
brandbook/brand.pin.json                               # written by `extend`, never by hand
brandbook/v2/{mailglass-lockup-light,mailglass-lockup-dark,favicon}.svg   # pinned
scripts/brand_pin.exs, test/scripts/brand_pin_test.exs # `extend` verb + helper changes
mailglass_admin/assets/css/app.css                     # fonts, weight, shadows, .mg-logo-*, comments
mailglass_admin/assets/vendor/heroicons-inline.js      # + arrow-left, arrow-right
mailglass_admin/lib/mailglass_admin/controllers/assets.ex   # compile-time font map, allowed_fonts/0
mailglass_admin/lib/mailglass_admin/components.ex      # logo/1 inline typemark
mailglass_admin/priv/static/{app.css,favicon.svg,mailglass-logo.svg,fonts/*}
mailglass_admin/test/support/contrast.ex               # MailglassAdmin.TestSupport.Contrast (pure)
mailglass_admin/test/support/glyph_scan.ex             # MailglassAdmin.TestSupport.GlyphScan (pure, AST)
mailglass_admin/test/mailglass_admin/{contrast_contract,font_assets_contract,glyph_contract,logo_assets_contract}_test.exs
.planning/publish/mailglass_admin-files.expected
.planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/superseded.json
```

### Pattern 1: Three-block parity over the compiled bundle (D-04)
**What:** Parse the committed `priv/static/app.css` into the three emitted token blocks and compare every role to the `tokens.json` oracle.
**Selectors exactly as the pinned Tailwind emits them** [VERIFIED: read from current `priv/static/app.css` this session, and re-confirmed in the prototype]:
- light: `:root,[data-theme=light],[data-theme=mailglass-light]{color-scheme:light;--mg-color-background:#f8fbfd;…`
- dark: `[data-theme=dark],[data-theme=mailglass-dark]{…` (existing test already matches this)
- system: `@media (prefers-color-scheme:dark){:root:not([data-theme=light]):not([data-theme=mailglass-light]){color-scheme:dark;--mg-color-background:#0d1b2a;…`
The existing regex `~r/([^{}]+)\{([^{}]+)\}/` matches the media block's INNER rule with selector `:root:not([data-theme=light]):not([data-theme=mailglass-light])`. Select blocks by that exact selector, assert exactly one of each kind (not "first match"), and iterate all 41 roles per block. daisyUI emits a different media rule (`:root:not([data-theme]){…--color-base-100:var(…)`) that carries no `--mg-*` hex; the selector filter keeps it out. Hex normalisation (`#fff` to `#ffffff`) already exists (`normalize_hex/1`).
**Teeth:** make the comparison a pure `parity_failures(css, tokens)` and mutate the CSS string per block (one value per block) to prove each block is checked.

### Pattern 2: Pure contrast helper + declared pair tables + coverage guard (D-06/D-07)
Put `luminance/1`, `ratio/2`, `composite(fg, bg, alpha)` in `MailglassAdmin.TestSupport.Contrast` (`test/support/contrast.ex`; `elixirc_paths(:test)` includes `test/support`, so it compiles in the test env only [VERIFIED: mix.exs:87]). Test-owned binding table from book pair id to roles (valid for the proposed map; every hex equals the book hex, asserted before the ratio):

| Book pair id | fg role | bg role |
|---|---|---|
| body | text | background |
| descriptor | text-muted | background |
| caption | text-muted | surface |
| application-copy | text | surface-raised |
| link | link | surface |
| focus | focus-ring | background |
| artwork | logo glass (`--mg-logo-glass`) | background |
| status-sent | text | surface |
| status-delivered / -delayed / -failed | success-text / warning-text / error-text | surface |
| status-notsent | text-muted | surface |

Admin pairs and the daisyUI coverage guard parse the 20 slots from `assets/css/app.css` (theme blocks, source lines 29-51 and 67-88). The 20 slots are `base-100, base-200, base-300, base-content, primary, primary-content, secondary, secondary-content, accent, accent-content, neutral, neutral-content, info, info-content, success, success-content, warning, warning-content, error, error-content`. Pairs cover 19 (base-content on base-100/200; X on X-content for the 8 coloured pairs); `base-300` is the explicit exemption (decorative divider, 1.32 / 1.54).

### Pattern 3: One idempotent `extend` verb for the pin (D-18)
**What:** `mix run --no-start scripts/brand_pin.exs extend --expect-sha256 <hex> [--zip <path>]`. It keeps the pinned commit, requires `--expect-sha256 == pin["sha256"]`, obtains bytes from `--zip` (local fallback) or `fetch(pin["url"])`, checks sha256 AND `size == pin["size"]` BEFORE reading any member, appends `@extension_manifest` entries not yet in `shipped` (refusing a same-`to` entry whose `from` or bytes differ), adds the new owned dir if absent, runs `ensure_parses`, then `write_all` (assets first, pin atomically).
**Where it hooks in:** [VERIFIED: scripts/brand_pin.exs] constants `@pin_keys ~w(repo commit url sha256 size book root owned_dirs shipped note)` (line 29), `@shipped_keys ~w(from to sha256 bytes license)` (31), `@licenses ["MIT", "OFL-1.1"]` (27); `@initial_manifest` (35-44) and `@required_assets` (45) stay the four `init` assets (do NOT add extension entries to `@required_assets`: `init` builds from `@initial_manifest` and `ensure_parses` would then reject its own pin). `build_pin` hardcodes `"owned_dirs" => ["brandbook/v2"]` (621); `rewrite_pin` (627-643) re-hashes existing entries only; `entry_issues` (231-264) requires each `to` under an owned dir and each owned dir to be a safe path; `verify` (328-350) reports `{:asset_unlisted, path}` for any file in an owned dir that is not listed. `parse_options` (818-827) uses `strict: [commit: :string, expect_sha256: :string]`: add `zip: :string`. `update` already works for the new entries because `read_pin_members` (540-543) iterates `current["shipped"]`.
**Extension manifest (from → to, license):**
- six woff2: `assets/fonts/web/<name>` → `mailglass_admin/priv/static/fonts/<name>` (OFL-1.1)
- three OFL: `assets/fonts/OFL-<Face>.txt` → `mailglass_admin/priv/static/fonts/OFL-<Face>.txt` (OFL-1.1; the same `from` also ships to `brandbook/v2`; duplicate `from` is fine, only duplicate `to` is rejected)
- `assets/logo/mailglass-lockup-light.svg`, `…-dark.svg`, `assets/icon/favicon.svg` → `brandbook/v2/<basename>` (MIT)
New owned dir: `mailglass_admin/priv/static/fonts`. `priv/static` itself cannot be owned (holds `app.css`, `hooks.js`).
**Then:** `cp brandbook/v2/favicon.svg mailglass_admin/priv/static/favicon.svg` and `cp brandbook/v2/mailglass-lockup-light.svg mailglass_admin/priv/static/mailglass-logo.svg`; the byte-identity test (below) is what makes those two copies trustworthy. Keep the file name `mailglass-logo.svg` (`lib/mix/tasks/mailglass.publish.check.ex:591,617` requires `priv/static/mailglass-logo.svg`).
**Teeth to add to `brand_pin_test.exs`** (synthetic zips, no network): extend writes exactly the expected tree; twice is byte-identical; refuses a zip whose hash differs from the pin; refuses `--expect-sha256` that differs from the pin; refuses a missing member before any write; a flipped byte in any shipped font gives `:asset_hash_mismatch` for that path; a stray file under `mailglass_admin/priv/static/fonts` gives `:asset_unlisted`; an unsafe `to` gives `:path_unsafe`.

### Pattern 4: Compile-time font map (D-11)
```elixir
# lib/mailglass_admin/controllers/assets.ex — replaces the disk-reading :font clause
# Source pattern: the existing @css/@logo/@favicon embeds in this file (lines 48-52, 319-328)
@fonts_dir Path.expand("../../../priv/static/fonts", __DIR__)
@font_files ~w(
  a-display-600.woff2 a-mono-400.woff2 a-mono-600.woff2
  ui-400.woff2 ui-400i.woff2 ui-600.woff2
)
for name <- @font_files do
  @external_resource Path.join(@fonts_dir, name)
end
@fonts Map.new(@font_files, &{&1, File.read!(Path.join(@fonts_dir, &1))})
@allowed_fonts Map.keys(@fonts)

@doc false
@spec allowed_fonts() :: [String.t()]
def allowed_fonts, do: Enum.sort(@allowed_fonts)

def call(conn, :font) do
  case Map.fetch(@fonts, conn.params["name"]) do
    {:ok, bytes} -> serve(conn, bytes, "font/woff2")
    :error -> conn |> send_resp(404, "") |> halt()
  end
end
```
Current code being replaced [VERIFIED: assets.ex:406-416]: `@allowed_fonts ~w(\n    inter-400.woff2 inter-700.woff2\n    inter-tight-400.woff2 inter-tight-700.woff2\n    ibm-plex-mono-400.woff2 ibm-plex-mono-700.woff2\n  )` and `defp resolve_font(name) when name in @allowed_fonts do {:ok, Path.join([:code.priv_dir(:mailglass_admin), "static", "fonts", name])}`. Update the moduledoc paragraph (lines 30-38: "six-member `@allowed_fonts`", "2-weights-per-family", "adding a seventh weight requires…") and the comment at 403-405. A `@doc false` accessor has precedent (`hooks_hash/0`, `js_body/0`); `Controllers.Assets` is not in the stability contract test. `MailglassAdmin.Controllers.Assets.init/1` is unchanged (`:font` already allowed).

### Pattern 5: AST-based glyph scan (D-13, D-17) — prototype run this session
Collect every string literal from `Code.string_to_quoted/2` (skipping `@doc`, `@moduledoc`, `@typedoc` attribute nodes; comments are not in the AST), treat each `.heex` file as one string with `<%!-- … --%>` stripped, and report codepoints outside the subset. Prototype output over `mailglass_admin/lib` (before any fix):
```
components.ex: U+B7
gallery_live.ex: U+2192 U+5C71 U+7530 U+592A U+90CE U+30C6 U+30CA U+30F3 U+30C8
inbound/quick_view.ex: U+2192
layouts/root.html.heex: U+B7
operator/quick_view.ex: U+2192
operator/repair_state.ex: U+B7
operator/support_cards.ex: U+B7
operator/suppression_card.ex: U+B7
operator/timeline.ex: U+B7
operator_live.ex: U+2190
```
After the fixes only the gallery CJK literals remain (allow-list entries as exact `{relative_path, codepoint}` pairs, each with a reason; the `→` in the gallery caption is replaced). `~H` content is a binary inside `{:sigil_H, _, [{:<<>>, _, [bin]}, _]}`, so the AST walk covers HEEx in `.ex`; escapes such as `·` and entities are resolved/absent (none exist today: [VERIFIED: grep for `&…;` and `\u` in lib returned nothing]).
**Allowed set (test-owned literal, 170 codepoints):** U+0020-007E (95), U+00A0, U+00B0, U+00C0-00FF (64), U+2013, U+2014, U+2018, U+2019, U+201C, U+201D, U+2022, U+2026, U+2212. [VERIFIED: fontTools cmap of all six woff2: identical 170-codepoint sets; `·` U+00B7, `✓`, `←`, `→` absent; `•` and `…` and `−` present.] Elixir cannot read a woff2 cmap without a Brotli dependency, so bind the literal to the font bytes instead: the test also asserts that the six pinned sha256 values in `brand.pin.json` equal the six hashes recorded next to the literal (a font update through `brand_pin.exs update` then fails the test and forces a re-derived subset). Record the derivation command in the test moduledoc: `python3 -c "from fontTools.ttLib import TTFont; print(sorted(TTFont(path).getBestCmap()))"`.
**Arrow rule (D-17):** the same scan with the stricter set U+2190-2193 and no allow-list, plus an icon-rule check (below).

### Pattern 6: Inline typemark that follows `<html data-theme>` (D-15)
The pinned lockup has four `<path>` elements in this order [VERIFIED: parsed the zip's `mailglass-lockup-light.svg`]: word `fill="#2A1D17"` (3,417-char `d`), pane `fill="#1895C2"` (178), pane `#1895C2` (183), overlap `fill="#0A6488"` (89); `viewBox="34.0 -840.0 5323.8 1092.0" width="1000" height="205"`; dark file has identical `d` values and fills `#F3EEEA / #46B6E8 / #46B6E8 / #A8E4F7`; no `<text>`, no `font-family`.
- Component: `<svg viewBox="34.0 -840.0 5323.8 1092.0" role="img" aria-label="mailglass" class={@class}>` with path 1 `fill="currentColor"`, paths 2-3 `class="mg-logo-glass"`, path 4 `class="mg-logo-overlap"`; path data copied byte-for-byte from the pinned file. Remove the old `data-part`/`data-glyph` markup and fix the `@doc` ("sealed-flap").
- `app.css` (hand-authored, like `.mg-focus-ring`): `.mg-logo-glass { fill: var(--mg-logo-glass); }` and `.mg-logo-overlap { fill: var(--mg-logo-overlap); }`. Prototype build confirmed the minified output `.mg-logo-glass{fill:var(--mg-logo-glass)}`. A class declaring `fill:` is not a token assignment, so `root_theme_ownership_contract_test` (which forbids assigning `--mg-*`/`--color-*`) is unaffected. No lib file consumes `--mg-*` directly today [VERIFIED: grep of `lib` and `assets/css` found `--mg-` only in `app.css` theme blocks/comments], so a class in `app.css` keeps that boundary.
- Size: `h-6` (24 px) x aspect 5323.8/1092 = 4.875 gives 117 px, above the 96 px book minimum. Assert the aspect and the `h-6` class in the contract test.

### Anti-Patterns to Avoid
- **Reading the font cmap at test time** without a dependency (impossible) or adding a woff2/Brotli dep (breaks "no dependency").
- **Hand-editing `brand.pin.json`**, or pinning `priv/static` root.
- **`<img src=logo.svg>` in dark mode**: the book forbids inverting; the file is the light drawing.
- **`prefers-color-scheme` inside the inline logo or any lib CSS**: Phase 180 D-10 (theme ownership). Only the favicon file uses it.
- **Quoting hex on a line containing "color" in lib `.ex`** (HEX-GATE).
- **Editing `docs/axe-baseline.json` by hand** or regenerating it more than once.
- **Touching `lib/mailglass/**`, `test/mailglass/**`, `test/fixtures`, `test/support`** (BRTOK-06).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Logo drawing | A redrawn or re-traced typemark | Pinned `mailglass-lockup-light.svg` path data, copied byte-for-byte | The book forbids redrawing the m; byte identity is testable. |
| Arrow glyphs | Unicode arrows, CSS triangles | Heroicons v2.2.0 `arrow-left` `M10.5 19.5L3 12M3 12L10.5 4.5M3 12H21`, `arrow-right` `M13.5 4.5L21 12M21 12L13.5 19.5M21 12H3` | [VERIFIED: raw.githubusercontent.com/tailwindlabs/heroicons v2.2.0 `src/24/outline/arrow-left.svg` and `arrow-right.svg`, fetched this session]. Fonts have no arrows (book: "None of the three has the arrow characters"). The existing icons use the same 24px outline family. |
| Asset download/verify | curl + sha256sum shell | `brand_pin.exs extend` | Hash-before-read, safe member names, tamper tests already exist. |
| Token generator | `tokens.gen` task | Parity + palette cross-check tests (D-03) | Owner decision. |
| WCAG math dependency | A hex/contrast Hex package | 25-line pure module | D-06; `mix.lock` must not change. |
| Bundle drift detection | Custom diff | `mix mailglass_admin.assets.build --check` and `bundle_reproducibility_contract_test` | Phase 180 already owns it. |

**Key insight:** every risk in this phase is a *coupling* that is invisible until a test or gate trips (pinned strings, file lists, hex regexes, name pins). The cheap defence is to make each new check a pure function with a mutation block and to grep for every old value (old hex, old font name, `·`, `←`, `→`) before declaring a plan done.

## Runtime State Inventory

This is a rebrand/font-swap phase, so each category is answered explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None. The admin has no database state keyed by colour or font names. The only persisted UI state is the theme cookie `mailglass_admin_theme_v2` holding `light`/`dark`/`system` [VERIFIED: `e2e/structural.spec.js:905` `{ name: "mailglass_admin_theme_v2", value: theme … }`], which is unchanged. | None. |
| Live service config | None in a UI/DB. Host apps that run a CSP: all fonts remain same-origin under the admin mount (`<mount>/fonts/<name>`), so `font-src 'self'` still holds; the font file names change (`inter-*` to `a-*`/`ui-*`). | Document nothing; verify in e2e that every font response origin equals the page origin (already asserted in `admin-assets.spec.js`). |
| OS-registered state | None. | None. |
| Secrets/env vars | None. `HEX_API_KEY` and the release ledger are untouched (`.planning/release-target.json` must not be edited). | None. |
| Build artifacts | (1) `priv/static/app.css` (committed, regenerated every plan). (2) Compile-time embeds in `Controllers.Assets` (`@css`, `@favicon`, `@logo`, new `@fonts`) are cached in `_build`; `@external_resource` triggers recompilation, but run `mix compile` after changing fonts. (3) `.planning/publish/mailglass_admin-files.expected` (Hex tarball file list). (4) The before-catalog `superseded.json`. (5) `docs/axe-baseline.json`. (6) Immutable HTTP caching: fonts are served with `cache-control: public, max-age=31536000, immutable` and stable names, so an adopter's browser could keep a stale font if a future book update reused a name; the new names differ from the old ones, so there is no stale collision now. (7) Published 2.6.0 on Hex still carries the old fonts until the next release; no migration needed. | Rebuild + marker per plan; update the allowlist in plan 2; regenerate the axe baseline once, last. |

## Common Pitfalls

### Pitfall 1: A plan goes green locally but the marker or allowlist is stale
**What goes wrong:** `before_catalog_manifest_test` or `mailglass.publish.check --allowlist-only` is red.
**Why:** Every bundle byte change moves `superseded_by`; every new/removed shipped file moves the allowlist.
**How to avoid:** One task per plan: rebuild bundle, recompute `shasum -a 256` + `git hash-object`, rewrite `superseded.json`, run the lane. Verified constants [VERIFIED: before_catalog_manifest_test.exs:88-110]: `@superseded_schema "mailglass.before_catalog.superseded.v1"`, `@superseded_keys ~w(schema catalog_id superseded_by superseded_in reason)`, `@superseded_by_keys ~w(bundle_sha256 root_layout_git_blob_sha)`; `superseded_in` and `reason` must be non-empty strings; `catalog_id` must equal `before-9eb9dee-20261115T022124Z`; the red message prints both current values.
**Warning signs:** "marked superseded but still matches" (marker present on a live catalog) or "superseded_by.bundle_sha256 is … but the checkout's current app.css sha256 is …".

### Pitfall 2: The bundle changes because of prose in `lib/**`
**What goes wrong:** `assets.build --check` red after a doc-only edit.
**Why:** Tailwind scans `lib/**` as plain text; any word that is a utility (`italic`, `container`, `table`, `grid`, `hidden`…) emits a class. Phase 180 already needed `@source not inline("prose")` for this.
**How to avoid:** Finish all `lib/` edits first, then build once, then run `--check`. Never edit `lib/` after the final build of a plan.

### Pitfall 3: Minified font-face form breaks naive assertions
**What goes wrong:** A test searching for `url('./fonts/…')` or quoted family names fails.
**Why:** [VERIFIED: prototype output] `@font-face{font-family:Funnel Display;font-style:normal;font-weight:600;font-display:swap;src:url(./fonts/a-display-600.woff2)format("woff2")}` (family unquoted, `url()` unquoted, no space before `format`).
**How to avoid:** Parse with a tolerant regex (`url\(\s*["']?\.\/fonts\/([^"')\s]+)`), compare family names after stripping quotes, and assert `font-display:swap` on all six blocks.

### Pitfall 4: `assets_test` favicon assertions are string-exact
**What goes wrong:** `assets_test.exs:100-101` asserts `~s(viewBox="0 0 16 16")` and `"prefers-color-scheme: dark"` (with a space). The pinned favicon has `viewBox="0 0 32 32"` and `@media (prefers-color-scheme:dark)` (no space) [VERIFIED: favicon.svg bytes read from the zip].
**How to avoid:** Update to `viewBox="0 0 32 32"` and a regex `prefers-color-scheme:\s*dark`; add the byte-identity assertion against `brandbook/v2/favicon.svg`. `assets_test.exs:52-61` (`inter-400.woff2`) becomes an iteration over `allowed_fonts/0` with a `wOF2` body check, plus 404s for `inter-400.woff2`, `OFL-FunnelDisplay.txt` and the traversal case.

### Pitfall 5: Old v1 hex survives somewhere
**What goes wrong:** `brand_test` currently asserts the six v1 hexes are present; after the swap they must be absent.
**How to avoid:** Rewrite `brand_test` to assert the six v2 anchors (`#f6f1e8`, `#2a1d17`, `#0a6488`, `#ddd3c4`, `#1d1713`, `#6cc6f0`) and `refute` the retired v1 set (`#0d1b2a`, `#277b96`, `#a6eaf2`, `#eaf6fb`, `#f8fbfd`, `#5c6b7a`, `#152538`, `#c7dce5`, `#315069`) plus `rgb(13 27 42` (shadow tints). [VERIFIED: the prototype bundle contains none of them.] Keep the "visual DON'Ts" (no `backdrop-filter:`, no `box-shadow: inset`, `--depth: 0`, `--noise: 0`).

### Pitfall 6: hero icon renders invisibly
**What goes wrong:** `<Components.icon name="hero-arrow-left">` draws nothing if the vendored plugin lacks the icon or the bundle was not rebuilt.
**How to avoid:** Add the two icons to `assets/vendor/heroicons-inline.js` (the `icons` object, key without the `hero-` prefix, single-line SVG string like its neighbours), rebuild, and add a generic test: every `hero-<name>` literal in `lib/**` has a `.hero-<name>` rule in the bundle. [VERIFIED baseline: 29 literals used, 29 rules, 0 missing, 0 unused], so the generic test is green today and goes red on a missing rule.

### Pitfall 7: Tests that pin the middot
**Lib-derived pins to update** [VERIFIED: grep]: `operator_live_test.exs:486` (`"Address · Account-local"`), `:1838`, `:1875`, `:2142` (`"Last replay: … · …"`), `operator/repair_state_test.exs` lines 8, 15, 49, 60, 69, `components_test.exs:636,638` (`"… UTC · Click to copy"`), `preview_live_test.exs:1575` (`refute … =~ " · "`, change to `" • "` or the refute becomes vacuous). Advisory e2e: `phase169-journey.spec.js:218,274`, `flows.spec.js:1995,2306`, `operator.spec.js:221,335,392,719`. Fixture-derived `·` stays (F8).

### Pitfall 8: `font-bold` now means 600; selector assumptions
`e2e/admin-assets.spec.js:325` expects `"700"` and `e2e/structural.spec.js:1139-1171` allows `{400, 700}`; update to 600. The BOLD-GATE comment (`check-conformance.sh:279-281`: "Only weights 400 and 700 are loaded; … Use font-bold or the default weight only") should read 400/600. `b, strong { font-weight: bolder }` computes to 700 and matches the 600 face (no synthesis: the matched face is already >= 600).

### Pitfall 9: Producer runs rebuild the bundle
`npm run test:operator-browser` = `mix mailglass_admin.assets.build && playwright test …`. Run it last; verify `git diff --exit-code mailglass_admin/priv/static/app.css` afterwards. The producer writes only `current` (it preserves `prior`) and refuses a `run_id` equal to `prior.run_id`; `axe_baseline_test` then enforces the only-forward ratchet and `system <= dark`. The committed baseline has no `color-contrast` rule today (all cells are 1 violation of `scrollable-region-focusable` or `aria-allowed-attr`), so any `color-contrast` appearing after the swap is a regression to fix in tokens before persisting (D-08).

### Pitfall 10: macOS `.DS_Store` in an owned directory
`verify` lists every file (hidden included) under `owned_dirs`; a Finder-created `.DS_Store` in `brandbook/v2` or `mailglass_admin/priv/static/fonts` makes local `verify` red. Not an issue in CI. Delete it.

## Code Examples

### Superseded marker (rewritten by every plan that moves the bundle or root layout)
```json
{
  "schema": "mailglass.before_catalog.superseded.v1",
  "catalog_id": "before-9eb9dee-20261115T022124Z",
  "superseded_by": {
    "bundle_sha256": "<shasum -a 256 mailglass_admin/priv/static/app.css>",
    "root_layout_git_blob_sha": "<git hash-object mailglass_admin/lib/mailglass_admin/layouts/root.html.heex>"
  },
  "superseded_in": "Phase 181 plan 181-0N: <what moved the bytes>",
  "reason": "Brand v2 tokens, fonts and logo replace the captured v1 look; PNGs, cases.json and manifest.json stay immutable."
}
```

### tokens.json palette entry with a machine-checked source (recommended shape, within D-03)
```json
"deep-glass": {
  "$value": "#0A6488",
  "$description": "Links, focus ring, current tab, the one main button per screen. Logo overlap on light.",
  "$extensions": { "mailglass": { "book": "color.light/Deep Glass" } }
},
"tint-success-light": {
  "$value": "#E8F0EC",
  "$description": "Designed: 10% of status-delivered-light over white. Success callout surface.",
  "$extensions": { "mailglass": { "designed": { "over": "white", "color": "status-delivered-light", "alpha": 0.1 } } }
}
```
The palette cross-check test resolves `book` (a `list/Name` lookup in `brand.json`, by name) and recomputes `designed` composites. This satisfies D-03 ("cross-checks each palette hex against `brand.json` by name") and D-05 ("each designed value records its derivation") with a derivation that cannot rot.

### Contract-test skeleton (pure function + teeth), mirrors `before_catalog_manifest_test`
```elixir
defmodule MailglassAdmin.ContrastContractTest do
  use ExUnit.Case, async: true
  alias MailglassAdmin.TestSupport.Contrast

  # Pure: takes parsed tokens + brand map, returns a list of failure strings.
  defp failures(tokens, brand), do: book_pair_failures(tokens, brand) ++ admin_pair_failures(tokens)

  test "committed tokens satisfy every declared pair" do
    assert failures(read_tokens(), read_brand()) == []
  end

  test "teeth: lowering text-muted below 4.5 on background is red" do
    mutated = put_in(read_tokens(), ["color", "light", "text-muted", "$value"], "#9A8E84")
    assert Enum.any?(failures(mutated, read_brand()), &(&1 =~ "descriptor"))
  end
end
```

### Static font proof (D-12) core assertions
```elixir
woff2 = fonts_dir |> File.ls!() |> Enum.filter(&String.ends_with?(&1, ".woff2")) |> Enum.sort()
assert woff2 == MailglassAdmin.Controllers.Assets.allowed_fonts()
assert css_font_urls(css) == woff2                      # tolerant regex, Pitfall 3
for f <- woff2, do: assert(match?(<<"wOF2", _::binary>>, File.read!(Path.join(fonts_dir, f))))
refute css =~ ~r/url\(\s*["']?(https?:)?\/\//
refute css =~ ~r/@import\s+(url\()?\s*["']?(https?:)?\/\//
assert Enum.sort(ofl_files) == ~w(OFL-AtkinsonHyperlegibleMono.txt OFL-AtkinsonHyperlegibleNext.txt OFL-FunnelDisplay.txt)
# face table: family+style+weight -> file (catches a 600 face pointing at the 400 file)
assert faces(css) == [
  {"Funnel Display", "normal", 600, "a-display-600.woff2"},
  {"Atkinson Hyperlegible Next", "normal", 400, "ui-400.woff2"},
  {"Atkinson Hyperlegible Next", "normal", 600, "ui-600.woff2"},
  {"Atkinson Hyperlegible Next", "italic", 400, "ui-400i.woff2"},
  {"Atkinson Hyperlegible Mono", "normal", 400, "a-mono-400.woff2"},
  {"Atkinson Hyperlegible Mono", "normal", 600, "a-mono-600.woff2"}
]
```

### app.css font section (source form; the pinned book's `fonts.css` rules with relative `./fonts/` URLs)
```css
@font-face{font-family:'Funnel Display';font-style:normal;font-weight:600;font-display:swap;src:url('./fonts/a-display-600.woff2') format('woff2')}
@font-face{font-family:'Atkinson Hyperlegible Next';font-style:normal;font-weight:400;font-display:swap;src:url('./fonts/ui-400.woff2') format('woff2')}
@font-face{font-family:'Atkinson Hyperlegible Next';font-style:normal;font-weight:600;font-display:swap;src:url('./fonts/ui-600.woff2') format('woff2')}
@font-face{font-family:'Atkinson Hyperlegible Next';font-style:italic;font-weight:400;font-display:swap;src:url('./fonts/ui-400i.woff2') format('woff2')}
@font-face{font-family:'Atkinson Hyperlegible Mono';font-style:normal;font-weight:400;font-display:swap;src:url('./fonts/a-mono-400.woff2') format('woff2')}
@font-face{font-family:'Atkinson Hyperlegible Mono';font-style:normal;font-weight:600;font-display:swap;src:url('./fonts/a-mono-600.woff2') format('woff2')}
```
[VERIFIED: these six rules are the pinned zip's `assets/fonts/web/fonts.css` with `./fonts/` prefixed.] Stacks from `brand.json` `type.*.css` (lines 517, 524, 531): display `'Funnel Display', 'Arial Narrow', system-ui, sans-serif`; text `'Atkinson Hyperlegible Next', system-ui, -apple-system, 'Segoe UI', sans-serif`; mono `'Atkinson Hyperlegible Mono', ui-monospace, 'SF Mono', Consolas, monospace`. Edit sites in `app.css` [VERIFIED: read this session]: `@theme` comment and weights (98-107), `@theme` body (108-145; add `--font-weight-bold: 600;` and move shadows to `rgb(42 29 23 / 0.06)` / `rgb(42 29 23 / 0.18)` at 133-134 and the comment at 129-131), `@font-face` block (147-188), `:root` font properties (193-196), `body`/`h1,h2,h3`/`code,pre,.mono` (472-484), `.mg-admin-root` mirrors (490-506). Add `font-variant-ligatures: none` to both mono rules. `.font-mono` utilities resolve through `:root { --font-mono }` (the unlayered declaration overrides Tailwind's layered default; [VERIFIED: compiled `.font-mono{font-family:var(--font-mono)}` and the prototype's `--font-mono:"Atkinson Hyperlegible Mono",ui-monospace,"SF Mono",Consolas,monospace`]), so the many `font-mono` call sites follow without edits. `tnum` is retained in the Atkinson Next faces (GSUB features `locl, pnum, tnum`); the mono faces have `locl, zero` only and no `liga`, so `font-variant-ligatures: none` is a belt-and-braces rule there. Apply `font-variant-numeric: tabular-nums` where the book requires it (dense lists, times, columns); that is a CSS-only addition in `app.css` (e.g. on `time`, `td`, `.tabular-nums`), not a lib class change.

### Heroicons entries to add (`assets/vendor/heroicons-inline.js`, same one-line shape as `"arrow-path"`)
```js
"arrow-left": "<svg xmlns=\"http://www.w3.org/2000/svg\" fill=\"none\" viewBox=\"0 0 24 24\" stroke-width=\"1.5\" stroke=\"currentColor\" aria-hidden=\"true\" data-slot=\"icon\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" d=\"M10.5 19.5L3 12M3 12L10.5 4.5M3 12H21\"/></svg>",
"arrow-right": "<svg xmlns=\"http://www.w3.org/2000/svg\" fill=\"none\" viewBox=\"0 0 24 24\" stroke-width=\"1.5\" stroke=\"currentColor\" aria-hidden=\"true\" data-slot=\"icon\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" d=\"M13.5 4.5L21 12M21 12L13.5 19.5M21 12H3\"/></svg>",
```
Call sites: `<Components.icon name="hero-arrow-left" class="mr-xs h-4 w-4" />` at `operator_live.ex:837` and `name="hero-arrow-right"` with `ml-xs h-4 w-4` at `operator/quick_view.ex:182` and `inbound/quick_view.ex:187` (same pattern as the existing `<Components.icon name="hero-chevron-down" class="h-4 w-4 rotate-90" />` at `quick_view.ex:74`). The accessible names ("Back to deliveries", "Open full detail") do not change because the glyph was already `aria-hidden`. The gallery caption `gallery_live.ex:1342` has no room for an icon: reword without an arrow (for example `reject_reason: nil, no badge`); `gallery_live.ex` caption tests do not pin it [VERIFIED: grep found no test or e2e reference to "no badge"]. Update the stale header comment ("All 31 hero-* outline icons") while there.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| WCAG sRGB threshold 0.03928 | 0.04045 | WCAG 2.1 errata 2022-02-22 (editorial); W3C techniques now use 0.04045 | `accessibility_test.exs` helper uses the old constant (line 132); no practical effect on 8-bit colours but the new helper uses 0.04045 per D-06. [CITED: https://w3.org/WAI/WCAG21/errata, https://www.w3.org/WAI/WCAG22/Techniques/general/G18.html] |
| Inter / Inter Tight / IBM Plex (400/700, six woff2, 118,652 B) | Funnel Display 600 + Atkinson Hyperlegible Next 400/600/400i + Mono 400/600 (six woff2, 52,508 B) | Brand v2.0, 2026-11-13 | Smaller payload; 600 replaces 700; Latin subset only. |
| Navy/teal sealed-flap mark | Two overlapping panes, azure, in espresso/bone | Brand v2.0 | Inline typemark; favicon is the m drawn for 16/32 px. |
| Fonts read from disk per request | Compile-time embedded map | This phase (D-11) | Moduledoc claim becomes true; allow-list = map keys. |

**Deprecated/outdated:** Inter-family names in `check_phase17x_evidence`, demo e2e and `foundations.story.exs`; the `Type (400/700 only)` doc rows; the BOLD-GATE comment; `.impeccable/config.json` brand reason and CLAUDE.md typography lines (Phase 183, not here).

## Advisory e2e values (v2 RGB for the specs that hard-code v1)

| Value | Hex | RGB |
|-------|-----|-----|
| light background (Sand) | `#F6F1E8` | `rgb(246, 241, 232)` |
| light surface (White) | `#FFFFFF` | `rgb(255, 255, 255)` |
| light sunken/selected | `#ECE5D8` | `rgb(236, 229, 216)` |
| dark background (Roast) | `#1D1713` | `rgb(29, 23, 19)` |
| dark surface (Roast Surface) | `#2A211B` | `rgb(42, 33, 27)` |
| dark overlay | `#362D27` | `rgb(54, 45, 39)` |
| dark sunken | `#14100D` | `rgb(20, 16, 13)` |
| dark selected | `#323535` | `rgb(50, 53, 53)` |
| light accent (Deep Glass) | `#0A6488` | `rgb(10, 100, 136)` |
| dark accent (Bright Glass) | `#6CC6F0` | `rgb(108, 198, 240)` |

Specs: `mailglass_admin/e2e/admin-assets.spec.js:8-22` (token backgrounds, plus font checks at 289-294, 313, 324-325), `mailglass_admin/e2e/structural.spec.js:13-14` (`ACCENT_LIGHT_RGB`) and 1139-1171 (weights), demo `storybook-fidelity.spec.js:499-504, 569-571, 619-622, 727, 1061-1062, 1088`, `phase178-stories.spec.js:88`, `foundations.story.exs:41-48`. The structural accent allowlist asserts the accent colour only appears on allowlisted elements; with v2 the accent equals the link/focus colour, so run it and adjust if links legitimately use it.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Dark `surface` and `surface-raised` are both Roast Surface `#2A211B` (book pairs `caption`, `application-copy`, `link`, `status-*` sit on it). | Role Map | Low: a different dark `surface` only changes which pair binds; the pair table is test-owned. |
| A2 | Designed values (`#12526C`, the four light and four dark `*-bg` tints, `#362D27`, `#323535`) are acceptable to the owner. They are composites of book hexes, contrast-verified, but not visually reviewed. | Role Map | Medium visual, zero a11y: Phase 182's reviewer owns visual judgment; the values can change without touching tests if the pair table still passes. |
| A3 | `text-disabled` = Control Edge is acceptable (WCAG exempts inactive controls; 3.93 light / 4.45 dark). | Role Map | Low. |
| A4 | Axe will report no new `color-contrast` rule on the three surfaces x three themes after the swap. Not measured: the producer was not run (it rewrites `docs/axe-baseline.json`). All static pairs pass with margin. | Pitfall 9 | Medium: surfaces with opacity (`opacity-60/40`) or composites outside the pair table could trip axe; D-08 says fix tokens before persisting. |
| A5 | Firefox shows no faux bold when 700 resolves to the 600 face (CONTEXT D-10 verified Chromium/WebKit only). | Fonts | Low: the mapping makes `font-bold` request 600, and `bolder` resolves to a face that already satisfies the bold threshold. |
| A6 | The designed hexes in this document still emit as plain hex through lightningcss. Verified for exactly the proposed values; a changed value could collide with a CSS named colour and be shortened to a name. | Pattern 1 | Low: the parity test fails loudly ("not found as inlined declaration"); handle by choosing a different hex or normalising names. |
| A7 | `font-synthesis-weight: none` is unnecessary (F10). | Planner Flags | Low. |
| A8 | The title suffix change (F6) is cosmetic. | Planner Flags | Low. |
| A9 | The `extend` verb name and `$extensions.mailglass` shape are Claude's Discretion choices. | Pattern 3, Code Examples | Low. |

## Open Questions

1. **Should the axe producer's Preview scan exclude the email iframe?**
   - What we know: 180 deferred item 4 measured a ~30 s axe stall inside the script-disabled `srcdoc` email iframe; each producer cell is its own `test.slow()` test (90 s), so one stall per test is survivable; 180's summary says baseline regeneration is "Phase 181's single allowed change".
   - What's unclear: whether the stall hits the producer on this machine.
   - Recommendation: do not edit the spec; run the producer once, last. If a cell times out, re-run that cell, do not change scan scope in this phase.
2. **Does the v2 accent colour (Deep Glass) trip the advisory "accent only on allowlisted elements" check?**
   - What we know: `structural.spec.js:13-21` allowlists `aria-selected`, `aria-current`, `.btn-primary`, `:focus-visible`.
   - Unclear: whether links now match the accent RGB.
   - Recommendation: run the spec locally in plan 3; update the allowlist (links) if required; advisory only.
3. **Do any tests outside the inspected files hard-code `font-bold` weight 700 or old family names?**
   - Known: 14 admin test/e2e files pin the class `font-bold` (unchanged); the computed weight assertions are in the two e2e files above.
   - Recommendation: re-grep `700`, `"Inter`, `IBM Plex` across `mailglass_admin/{test,e2e}` and `reference/demo_app/{test,assets/e2e}` at the start of plan 2.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP with ASDF env | all `mix` commands | ✓ | needs `export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` (`.tool-versions` pins 27.3.4.13, not installed; bare `mix` fails misleadingly) | none; the tracked `.tool-versions` is the CI contract, do not "fix" it |
| Tailwind 4.1.12 binary | `assets.build`, `--check` | ✓ | `mailglass_admin/_build/tailwind-macos-arm64-4.1.12` | `Tailwind.install()` downloads it |
| Postgres | admin test suite | ✓ | 14.17 accepting on `/tmp:5432` | — |
| Node + npm + Playwright + Chromium | axe producer, e2e (advisory) | ✓ | Node 26.10.0, npm 11.19.1, `node_modules/.bin/playwright`, chromium builds cached | — |
| Docker | demo e2e (advisory, optional) | ✓ | 29.5.2 | skip demo specs, record as not run |
| Network (raw.githubusercontent.com) | `extend` download | ✓ | pinned URL fetched and hashed this session | `--zip <path>` with the local file hashing to `ed96bb25…` |
| Python + fontTools + brotli | scratch cmap derivation only | ✓ (not required by the repo) | fonttools 4.62.1, brotli 1.2.0 | the 170-codepoint set is recorded in this document |

**Missing dependencies with no fallback:** none. **Missing with fallback:** none.
Baselines measured this session (clean tree, commit `9bd70fa5`): admin `mix test --warnings-as-errors --seed 0` = 1389 tests, 0 failures, 1 excluded, about 22 s; `mix test test/scripts/brand_pin_test.exs` green; `mix run --no-start scripts/brand_pin.exs verify` = `brand pin ok`; `MIX_ENV=test mix mailglass.publish.check --allowlist-only --package mailglass_admin` = unchanged/unchanged in about 2 s; the three conformance scripts print `OK`; `node --test` of the four evidence contract files = 42 pass.

## Validation Architecture

Skip condition not met (`workflow.nyquist_validation` is `true` in `.planning/config.json`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18.4 / OTP 27); `node --test` for the evidence scripts; Playwright (advisory) |
| Config file | `mailglass_admin/test/test_helper.exs`; `mailglass_admin/mix.exs` aliases (`verify.support_contract.admin`); root `mix.exs` |
| Quick run (admin) | `cd mailglass_admin && mix test test/mailglass_admin/{token_parity,brand,accessibility,contrast_contract,bundle,assets,font_assets_contract,glyph_contract,logo_assets_contract,before_catalog_manifest}_test.exs` (a few seconds) |
| Full required lane | `cd mailglass_admin && mix verify.support_contract.admin` (runs `mailglass_admin.assets.build --check` first, then `test --warnings-as-errors` over the whole directory) |
| Core pin + allowlist | `mix test test/scripts/brand_pin_test.exs` ; `mix run --no-start scripts/brand_pin.exs verify` ; `MIX_ENV=test mix mailglass.publish.check --allowlist-only --package mailglass_admin` |
| Conformance gates (required `conformance_gates`) | `bash mailglass_admin/scripts/check-conformance.sh && bash scripts/check_motion_conformance.sh && bash mailglass_admin/scripts/check-conformance-advisory.sh` |
| Format | `cd mailglass_admin && mix format --check-formatted` and root `mix format --check-formatted` |
| Evidence scripts (gsd gate + advisory CI) | `node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BRTOK-01 | tokens.json == tokens.css == bundle for 41 roles x 3 blocks; palette hex == brand.json by name; designed values recompute from their sources | unit (static) | `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs` | ✅ rewrite |
| BRTOK-01 | v2 anchors present, v1 hexes absent, depth/noise/glassmorphism rules | unit | `mix test test/mailglass_admin/brand_test.exs` | ✅ rewrite |
| BRTOK-01 | bundle is what the generator produces; catalog marker current | gate + unit | `mix mailglass_admin.assets.build --check` ; `mix test test/mailglass_admin/{bundle_reproducibility_contract,before_catalog_manifest}_test.exs` | ✅ (marker file ❌ Wave 0 each plan) |
| BRTOK-02 | 12 book pairs per theme resolve through tokens, >= minimum, within 0.02; admin pair table; daisyUI coverage guard; `never` rules | unit | `mix test test/mailglass_admin/contrast_contract_test.exs` | ❌ Wave 0 |
| BRTOK-02 | existing sub-3:1 divider pins and updated pairs use the shared helper | unit | `mix test test/mailglass_admin/accessibility_test.exs` | ✅ rewrite |
| BRTOK-02 | no dependency added | shell | `git diff --exit-code -- mix.lock mailglass_admin/mix.lock mailglass_inbound/mix.lock mailglass_admin/package-lock.json` | ✅ |
| BRTOK-03 | woff2 magic, set equality (dir = allow-list = CSS URLs), face table, no remote URL/import, OFL texts, 404 for old/OFL/traversal names, bytes served equal files | unit + endpoint | `mix test test/mailglass_admin/{font_assets_contract,assets,bundle}_test.exs` | ❌ new file; ✅ edits |
| BRTOK-03 | pin ships exactly the expected assets; hashes; owned-dir set equality; extend teeth | unit | `mix test test/scripts/brand_pin_test.exs` (root) | ✅ edit |
| BRTOK-03 | Hex tarball file list | task | `MIX_ENV=test mix mailglass.publish.check --allowlist-only --package mailglass_admin` | ✅ (`.expected` edit) |
| BRTOK-03 | no `·` (and nothing outside the 170-codepoint subset) in rendered lib text | unit | `mix test test/mailglass_admin/glyph_contract_test.exs` | ❌ Wave 0 |
| BRTOK-04 | favicon and `/logo.svg` byte-identical to pinned copies; inline path data and fill-to-token mapping identical to the pinned lockups; `<text>`-free; no `<script`/`href`/`<image`; width >= 96 px; no U+2190-2193 in rendered lib text; every `hero-*` literal has a bundle rule | unit | `mix test test/mailglass_admin/{logo_assets_contract,glyph_contract,assets,bundle}_test.exs` | ❌ Wave 0 |
| BRTOK-05 | axe ratchet: no cell or rule regresses `prior`, system <= dark | unit | `mix test test/mailglass_admin/axe_baseline_test.exs` | ✅ |
| BRTOK-05 | baseline regenerated once, last | producer (advisory run, evidence) | `cd mailglass_admin && PERSIST_AXE_BASELINE=1 npm run test:operator-browser -- axe-baseline.spec.js` then `git diff --exit-code priv/static/app.css` | ✅ |
| BRTOK-06 | core defaults untouched | phase-scope diff + existing tests | `git diff --exit-code <PHASE_BASE>..HEAD -- lib test/mailglass test/fixtures test/support` (superset of D-21's `config.ex`, `theme.ex`, `components.ex`, `vml_golden.html`) ; `mix test test/mailglass/components/vml_preservation_test.exs` ; root `mix test --warnings-as-errors` (`core_deterministic_suite`) | ✅ |

`<PHASE_BASE>` is `9bd70fa5` (HEAD when this research ran); record the SHA at execute start in plan 1.

### Mutation proofs to record in each plan summary (METHODOLOGY: break, observe red, restore)
- BRTOK-01 parity: edit one role in `brandbook/tokens.json` (e.g. `color.light.text-muted` alias to another palette key) then `mix test test/mailglass_admin/token_parity_test.exs` is red; `git checkout brandbook/tokens.json`. Block coverage is proven by the in-test teeth (one mutated value per block: light, dark, system). Rebuild-level proof: edit the system block in `brandbook/tokens.css`, rebuild, parity red; restore, rebuild.
- BRTOK-02: lower one role (e.g. `text-muted` dark to `#6B6058`) then `mix test test/mailglass_admin/contrast_contract_test.exs` red naming the pair; restore. Each `never` rule has a planted violation in the teeth block.
- BRTOK-03: (a) `mv priv/static/fonts/ui-400.woff2 priv/static/fonts/ui-400x.woff2` then font contract red; (b) copy any file to `priv/static/fonts/inter-400.woff2` then red (set equality) and `brand_pin verify` red (`:asset_unlisted`); (c) flip one byte of a woff2 then `brand_pin verify` red (`:asset_hash_mismatch`); (d) change one CSS `url(./fonts/…)` then red; each restored with `git checkout`.
- BRTOK-03/04 glyph: add `·` to a `lib` string and `←` to a HEEx template then glyph contract red; restore.
- BRTOK-04: remove `arrow-left` from the vendored plugin and rebuild then the hero-rule test red; alter one `d` in `Components.logo/1` then path-identity red; append a byte to `priv/static/favicon.svg` then byte-identity red (and the drift/`favicon_hash` test still green, proving the byte-identity test is the one that catches it).
- BRTOK-06: touch a comment in `lib/mailglass/components/theme.ex` then the phase-scope diff command is non-empty (red); restore.

### Sampling Rate
- **Per task commit:** the quick admin command above (plus `mix test test/scripts/brand_pin_test.exs` when the pin or scripts moved).
- **Per plan merge:** `cd mailglass_admin && mix verify.support_contract.admin`, the conformance trio, `mix format --check-formatted` in both roots, the allowlist task after plan 2, the node evidence tests after plan 2.
- **Phase gate:** root `mix test --warnings-as-errors` (`core_deterministic_suite`) + admin lane + inbound untouched; then the axe producer once; then `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `mailglass_admin/test/support/contrast.ex` (`MailglassAdmin.TestSupport.Contrast`) — BRTOK-02
- [ ] `mailglass_admin/test/support/glyph_scan.ex` (`MailglassAdmin.TestSupport.GlyphScan`) — BRTOK-03/04
- [ ] `mailglass_admin/test/mailglass_admin/contrast_contract_test.exs` — BRTOK-02
- [ ] `mailglass_admin/test/mailglass_admin/font_assets_contract_test.exs` — BRTOK-03
- [ ] `mailglass_admin/test/mailglass_admin/glyph_contract_test.exs` — BRTOK-03/04
- [ ] `mailglass_admin/test/mailglass_admin/logo_assets_contract_test.exs` — BRTOK-04
- [ ] `.planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/superseded.json` — every bundle-moving plan
- No new framework or dependency. New tests go in NEW files (test_exceptions.exs is `file:line` keyed, though it lists only core and inbound files; `bash scripts/check_test_exceptions.sh` passes today and scans only `test/mailglass` and `mailglass_inbound/test`).

## Security Domain

`security_enforcement` is absent from config, so it is enabled.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication / V3 Session | no | untouched (theme cookie only stores `light`/`dark`/`system`) |
| V4 Access Control | no | untouched |
| V5 Input Validation | yes | font route accepts only names that are keys of a compile-time map; everything else is a 404 with an empty body (path traversal `..%2F..%2Fetc%2Fpasswd` stays covered by `assets_test`) |
| V6 Cryptography | yes (integrity only) | sha256 via `:crypto` for the pin; no hand-rolled crypto |
| V10 Malicious Code / V14 Config & supply chain | yes | assets enter only through the sha256-pinned zip (hash checked before any member is read), tamper tests, set-equality of owned dirs, no dependency added |
| V12 Files and Resources | yes | no filesystem read at request time for fonts after D-11; served SVGs are static pinned bytes |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via `/fonts/:name` | Tampering / Info disclosure | closed map lookup, 404 otherwise; test with encoded traversal and with the retired `inter-400.woff2` |
| Tampered or substituted brand asset | Tampering | sha256 pin + `brand_pin_test` tamper cases + byte-identity tests for the two `priv/static` SVG copies |
| Active content in a served/inlined SVG | Tampering / Elevation | assert pinned SVGs contain no `<script`, `on*=`, `<foreignObject`, `<image`, `href=`/`xlink:href`, `url(http`; the inline component has none |
| Third-party font fetch leaking host usage | Info disclosure | static proof: no `url(http`, no `url(//`, no remote `@import` in the bundle; e2e asserts every font response has the page origin |
| Font license non-compliance (OFL-1.1 requires the license with distribution) | Legal / Repudiation | three OFL texts shipped beside the fonts in the Hex tarball (`priv/static` is in `package/files`) and pinned |
| Stale immutable cache of a replaced font | Integrity (availability) | new, distinct file names now; document that a future same-name replacement needs a new name |

## Project Constraints (from CLAUDE.md)
- Toolchain: `export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` before any `mix`; the tracked `.tool-versions` is the CI contract.
- Zero-human-UAT / shift-left (D-52): Claude runs the evidence; must-NOT prohibitions are mutation-proven contract tests; owner hand-off is limited to ship/no-ship, brand identity, credentials, the `hex-publish` approval and physical devices. Never present a "reply yes if this matches" checkpoint for something a machine can observe.
- Decision policy: research first, decide, document; escalate only genuinely strategic forks. Nothing in this phase meets that bar (the open items above are all reversible).
- Commit/branch: Conventional Commits enforced; squash-merge; one open PR at a time; `docs(state):` for STATE.md; never edit STATE.md by hand. Admin `lib`/`priv/static` = `feat(admin):`; pin, `brandbook/`, scripts, `.planning` = `chore(brand):`/`docs:`. All third-party GitHub Actions stay SHA-pinned (no workflow edits here).
- Do not write to `mailglass_admin/priv/static/` without committing the rebuilt bundle (CI `git diff --exit-code`).
- Do not hand-edit `.planning/release-target.json`; no release ceremony in this phase.
- Brand and voice: errors and microcopy stay specific and calm; lowercase `mailglass`; no glassmorphism, bevels or lens flares (enforced by `brand_test`); typography (Inter) text in CLAUDE.md and `brandbook/brand-book.md` is Phase 183 with owner sign-off.
- Engineering DNA relevant here: optional-deps and `compile --no-optional-deps --warnings-as-errors` lanes unaffected; no PII in telemetry (no telemetry touched).
- MIT license for all packages; OFL-1.1 applies only to the three font families and ships with them.

## Recommended Plan Decomposition (about 4 plans; planner decides)

1. **181-01 Tokens, role map, contrast gate (BRTOK-01, BRTOK-02, BRTOK-05 part).** Wording amendments (REQUIREMENTS.md:26, ROADMAP.md:143, PROJECT.md:24; BRTOK-03 and criterion 3 "seven" to six at REQUIREMENTS.md:28 and ROADMAP.md:145, can ride here or plan 2). Rewrite `brandbook/tokens.json` + `tokens.css` (v2 palette, 39 roles x 3 blocks, 2 logo roles x 3, `--mg-font-*` stacks, header comment). `app.css`: theme-block comments (v1 colour names), shadow tints, file header. New `contrast.ex`, `contrast_contract_test`; rewrite `brand_test`, `token_parity_test` (three-block parity, palette cross-check, design-system pin), `accessibility_test`; `docs/design-system.md` token table and its pinned assertion (F1). Rebuild bundle, `superseded.json`, lane, mutation proofs. Commit kinds: `chore(brand):` for `brandbook/` and docs, `feat(admin):` for `app.css`/`priv/static`/tests that ship with them.
2. **181-02 Pin extension + fonts + glyphs (BRTOK-03).** `brand_pin.exs` `extend` + `brand_pin_test` changes (F3); run it (writes fonts, OFL copies, three SVGs, rewrites the pin); `git rm` the six Inter/Plex woff2; `app.css` font block, families, `--font-weight-bold`, ligatures, tabular numerals; `assets.ex` compile-time map and moduledoc; `bundle_test`, `assets_test`, `font_assets_contract_test`; `.planning/publish/mailglass_admin-files.expected`; middot replacement across the seven lib files plus the root layout title and the tests/e2e that pin it; `glyph_scan.ex` + `glyph_contract_test`; node evidence scripts (F2); e2e font names/weights; BOLD-GATE comment; `design-system.md` weight statements. Rebuild, marker, lane, allowlist task, node tests, conformance trio.
3. **181-03 Logo, favicon, arrows (BRTOK-04).** Copy pinned SVGs into `priv/static` (`favicon.svg`, `mailglass-logo.svg`); inline `Components.logo/1`; `.mg-logo-*` classes; vendor `arrow-left`/`arrow-right`; replace the four arrows; `logo_assets_contract_test` (byte identity, path identity, fill-to-token, size, safety), generic hero-rule test, arrow scan; `assets_test` favicon edits; demo story + storybook/phase178 specs and the other hard-coded colour/font specs (F11). Rebuild, marker, lane.
4. **181-04 Close-out (BRTOK-05, BRTOK-06).** BRTOK-06 phase-scope diff + `vml_preservation_test` + root `core_deterministic_suite`; confirm `mix.lock` diff empty; final lane runs and the conformance trio; run advisory e2e locally and record results as evidence (never as proof); then the axe producer once, last (`PERSIST_AXE_BASELINE=1 npm run test:operator-browser -- axe-baseline.spec.js`), verify the bundle is unchanged, `axe_baseline_test` green; summary with the acceptance-to-test table and lane per requirement.

## Sources

### Primary (HIGH confidence) — read or executed this session
- `/Users/jon/projects/mailglass/.planning/phases/181-brand-v2-tokens-fonts-and-logo/181-CONTEXT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `PROJECT.md`, `CLAUDE.md`, `.planning/config.json`, `.planning/METHODOLOGY.md`
- `brandbook/{tokens.json,tokens.css,brand.pin.json,v2/brand.json}`; pinned zip (local copy, sha256 verified; pinned raw URL downloaded and hashed): `assets/fonts/web/*`, `assets/icon/favicon.svg`, `assets/logo/mailglass-lockup-{light,dark}.svg`
- `mailglass_admin/{assets/css/app.css,assets/vendor/heroicons-inline.js,lib/mailglass_admin/controllers/assets.ex,lib/mailglass_admin/components.ex,lib/mailglass_admin/layouts/root.html.heex,lib/mix/tasks/mailglass_admin.assets.build.ex,config/config.exs,mix.exs,package.json,docs/design-system.md,docs/axe-baseline.json,priv/static/*}`
- `mailglass_admin/test/mailglass_admin/{token_parity,brand,accessibility,bundle,assets,before_catalog_manifest,bundle_reproducibility_contract,axe_baseline,root_theme_ownership_contract,phase175_prohibition_contract}_test.exs`, `mailglass_admin/e2e/{admin-assets,structural,axe-baseline}.spec.js`, `mailglass_admin/scripts/check-conformance.sh`
- `scripts/brand_pin.exs`, `test/scripts/brand_pin_test.exs`, `scripts/{gsd-regression-gate.sh,check_phase174_evidence.cjs,check_phase175_evidence.cjs,check_test_exceptions.sh,check_motion_conformance.sh}`, `lib/mix/tasks/mailglass.publish.check.ex`, `.planning/publish/mailglass_admin-files.expected`, `config/quality/ci_policy.exs`, `.github/workflows/ci.yml`
- Phase 180 artifacts: `180-CONTEXT.md`, `deferred-items.md`, `180-03-SUMMARY.md`, `180-04-SUMMARY.md`, `180-VERIFICATION.md`
- Scratch evidence (not committed): a copy of `assets/` + `lib/` built with the pinned Tailwind binary against the proposed tokens/fonts/weight (123 hex declarations, no 700, no v1 hex, 137,441 B); fontTools cmap/GSUB inspection of the six woff2; an Elixir AST prototype of the glyph scan; Python recomputation of every contrast pair; baseline test runs listed under Environment Availability.

### Secondary (MEDIUM confidence)
- [WCAG 2.1 errata](https://w3.org/WAI/WCAG21/errata) and [WCAG 2.2 technique G18](https://www.w3.org/WAI/WCAG22/Techniques/general/G18.html): sRGB threshold 0.04045 replaced 0.03928 (editorial). The normative WCAG 2.2 glossary text itself could not be fetched in full.
- [heroicons v2.2.0 `arrow-left.svg`](https://raw.githubusercontent.com/tailwindlabs/heroicons/v2.2.0/src/24/outline/arrow-left.svg) and [`arrow-right.svg`](https://raw.githubusercontent.com/tailwindlabs/heroicons/v2.2.0/src/24/outline/arrow-right.svg): path data fetched this session.

### Tertiary (LOW confidence)
- None. Firefox faux-bold behavior is carried from CONTEXT D-10 and listed as A5.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH (no additions; pinned versions read from files).
- Architecture and file locations: HIGH (every path and line read this session; line numbers match the current tree at `9bd70fa5`).
- Role-map values: MEDIUM (book hexes verbatim; designed composites are a design call, contrast-verified).
- Pitfalls and coupling inventory: HIGH for the items found by grep/run; the e2e/advisory list is best-effort (re-grep at plan start, Open Question 3).

**Research date:** 2026-11-15
**Valid until:** 2026-12-15 for facts about this tree (invalidated by any commit to `mailglass_admin/`, `brandbook/`, `scripts/brand_pin.exs` or Phase 182 work landing first); the pinned brand zip is immutable.
