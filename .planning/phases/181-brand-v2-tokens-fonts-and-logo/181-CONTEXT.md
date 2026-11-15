# Phase 181: Brand v2 Tokens, Fonts and Logo - Context

**Gathered:** 2026-11-14 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

In one coordinated change, the admin dashboard takes on brand v2.0 colors, typography and mark in light and dark. Every contrast pair and font asset is verified by tests, and the host's email defaults stay exactly as they were. Requirements BRTOK-01..06. No copy, layout or status-word changes (Phase 182), no docs/README/ExDoc/ICO favicon work (Phase 183), no backend or data-capture features.
</domain>

<decisions>
## Implementation Decisions

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
- **D-23 (planning amendment, 2026-11-15):** **`docs/design-system.md` false-value corrections happen in this phase; the broader prose rewrite stays Phase 183.** Rows and sentences in `mailglass_admin/docs/design-system.md` that would otherwise state a value this phase changes are corrected in the plan that changes the value: the token table rows (181-01), the shadow tint sentence (181-01), and the type-weights row and paragraph (181-02, "400/600"). Reason: a doc stating a weight, shadow or colour the bundle no longer loads would mislead adopters and would fail the tests that pin those strings (`token_parity_test` design-system assertion, `docs_contract_test`). Edits are limited to correcting false values; voice, structure and every other paragraph stay as they are for Phase 183. This narrows the Deferred Ideas line "design-system.md prose beyond the token table" to "beyond these false-value corrections".

### Claude's Discretion
- Exact role-map file layout, hex values for the genuinely designed slots (within D-05 and D-07), table/column order in the contrast test, test file names, and whether the glyph scan and arrow scan share one file.
- Whether `font-synthesis-weight: none` is added as a guard (D-10).
- The new `brand_pin.exs` verb name and manifest shape (D-18), within the stated constraints.

### Folded Todos
None (`todo.match-phase 181` returned 0 matches).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` (Phase 181, lines ~138-152) and `.planning/REQUIREMENTS.md` (BRTOK-01..06, lines 24-31)
- `.planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-CONTEXT.md` (D-16..D-19 brand pin; D-24..D-26 lanes and commit kinds)
- `.planning/phases/180-reproducible-admin-bundle-and-before-catalog/180-CONTEXT.md` (D-01..D-09 bundle gate, D-10..D-15 `<html>` theme ownership, D-17..D-24 before-catalog)
- `.planning/research/brand-v2-adoption/LENS-FINDINGS.md` (sections B, D) and `MILESTONE-PROPOSAL.md` (P3)
- `.planning/METHODOLOGY.md` (shift-left verification, mutation protocol)
- `brandbook/brand.pin.json`, `brandbook/v2/brand.json` (contrastPairs, palette, `never`, logo, type), `brandbook/v2/OFL-*.txt`, `scripts/brand_pin.exs`, `test/scripts/brand_pin_test.exs`
- `brandbook/tokens.css`, `brandbook/tokens.json` (v1, to be rewritten)
- `mailglass_admin/assets/css/app.css`, `mailglass_admin/assets/vendor/heroicons-inline.js`, `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`, `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/priv/static/{favicon.svg,mailglass-logo.svg,fonts/}`
- `mailglass_admin/test/mailglass_admin/{brand_test,token_parity_test,accessibility_test,bundle_test,assets_test,before_catalog_manifest_test,axe_baseline_test}.exs`
- `mailglass_admin/scripts/check-conformance.sh` (BOLD-GATE), `.planning/publish/mailglass_admin-files.expected`, `mailglass_admin/docs/design-system.md`
- Pinned brand zip: `https://raw.githubusercontent.com/szTheory/mailglass-brand/240bdd214746b956162b8d4f2f82d4b178106eff/mailglass-brand.zip` (sha256 `ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b`; `assets/fonts/web/`, `assets/fonts/OFL-*.txt`, `assets/icon/favicon.svg`, lockup SVGs)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mailglass_admin/test/mailglass_admin/accessibility_test.exs` luminance helper (extract to `test/support/`, fix threshold).
- `scripts/brand_pin.exs` verify/entry machinery and `test/scripts/brand_pin_test.exs` tamper harness (extend, do not fork).
- `phase175_prohibition_contract_test.exs` as the mutation-proven contract test template.
- Phase 180 `mix mailglass_admin.assets.build --check` and `bundle_reproducibility_contract_test.exs` (the regenerated bundle must pass them).
- `assets.ex` already embeds CSS/logo/favicon with `@external_resource`; fonts follow the same pattern.

### Established Patterns
- `app.css` imports `brandbook/tokens.css` (line ~9); daisyUI theme blocks map `--color-*` to `var(--mg-color-*)`; compiled bundle inlines all 39 roles.
- Hand-authored assets (`hooks.js`, `heroicons-inline.js`, logo, favicon, fonts) have no generator; only `app.css` is generated and drift-gated.
- Tests pin literal strings across `docs/design-system.md`, gallery, storybook, `tokens.css`; fix order is source -> `app.css` -> build -> pinned tests -> axe baseline last.
- A new `hero-*` icon renders invisibly unless its SVG is embedded in `heroicons-inline.js` and the bundle rebuilt.

### Integration Points
- Core email defaults (`config.ex`, `theme.ex`, `components.ex` button colors, VML golden) are untouched and share nothing with `brandbook/tokens.*`.
- Demo app (`reference/demo_app`) storybook and e2e specs hold hand-duplicated hexes and font names; update them so advisory lanes stay green.
- `.planning/research/brand-v2-adoption/before-catalog/<catalog_id>/superseded.json` marker is coupled to every bundle change.
</code_context>

<specifics>
## Specific Ideas

- The logo must follow `<html data-theme>`, never `prefers-color-scheme` (the favicon is the one exception, because tab chrome follows the OS).
- Do not invent hues: every designed slot value is a book hex or a composite of two, with its derivation written down.
- The `·` to `•` swap is a font-forced visible change; it is not a Phase 182 copy decision.
</specifics>

<deferred>
## Deferred Ideas

- ICO/PNG favicons, 16/24/32 px browser favicon check, ExDoc logo/CSS, README `<picture>`, design-system.md prose beyond the token table and the D-23 false-value corrections: Phase 183.
- CLAUDE.md line "CI runs `git diff --exit-code`" and brand/PRODUCT.md edits: Phase 183 with owner sign-off.
- Re-subsetting the fonts to add `·` or arrows: rejected (breaks pin); revisit only if the book ships a wider subset.
- `docs/ui-baseline-scores.json` rescoring: Phase 182 reviewer.

### Reviewed Todos (not folded)
None — analysis stayed within phase scope.
</deferred>
