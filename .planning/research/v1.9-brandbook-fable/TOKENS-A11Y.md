# Design-Token Architecture & Accessibility — v1.9 Brand Book Fable

**Researched:** 2026-06-11
**Mode:** Project research (token architecture + WCAG contrast)
**Overall confidence:** HIGH (contrast math computed, not estimated; DTCG status verified against w3.org/designtokens.org)
**Downstream consumer:** Phase 86 foundations executor (`brandbook-fable/tokens.json` + `tokens.css`)

## Summary

The W3C Design Tokens Community Group format reached its **first stable version (2025.10) on 2025-10-28** — the format war is over, and the stable spec settles naming (`$value`/`$type`/`$description`), aliasing (`{group.token}`), and color syntax. Critically for this milestone, the spec **does not define a theming/modes mechanism** — dark mode is expressed as parallel semantic role sets, which is exactly what a hand-maintained CSS-custom-property system wants anyway: one variable name per role, reassigned under `[data-theme="dark"]`.

For mailglass's scale (one brand book, ~20 raw colors, no build step), the right architecture is **two tiers, not three**: raw palette → semantic roles. A component tier (`button-primary-bg`) is overkill below ~3 products consuming the tokens. The prior codex `tokens.json` already has roughly the right two-tier shape; its concrete weaknesses are (a) legacy Tokens Studio property names (`value`, not `$value`), (b) stale planning language baked into descriptions ("until Phase 84 contrast validation approves…"), (c) a light-only demonstrated system with dark tokens that were never contrast-verified, and (d) an unresolved info-callout text role. All four are fixable with the recommendations below.

Contrast math (full matrix below, WCAG relative-luminance formula): the seed palette is **stronger than the prompt assumed but still has four real failures**. Glass `#277B96` is actually **4.82:1 on white** (not ~4.0) and 4.64:1 on Paper — it passes AA for normal text on white/Paper. But it **fails on Mist (4.37), on selected surfaces (4.16), and as info-callout text (4.37)** — and links inevitably sit on those tinted surfaces. The fixes: promote the existing hover value `#1D637A` to the default link/text-accent role ("glass-deep", 6.12:1 worst-case on light surfaces), darken warning text to `#96520E` (Amber fails on Mist at 4.40), replace the dark theme's error color with `#E29089` (the codex's `#D47368` fails AA on raised dark surfaces at 4.09), and add 3:1-verified input-border tokens for both themes. The dark ramp derives cleanly from Ink: `#0D1B2A → #152538 → #1F3049` surfaces with Mist text (15.8:1) and Ice accents (12.98:1) — the codex dark values were directionally right and mostly survive verification.

## Token Architecture Recommendation

### Format: DTCG-2025.10-flavored JSON, hand-maintained, hex-string values

- **Use DTCG property names:** `$value`, `$type`, `$description` (the `$` prefix is the stable-spec marker; the codex file's bare `value` is the legacy Tokens Studio dialect). Group-level `$type` (e.g. `"$type": "color"` once per group) keeps the file terse.
- **Use plain hex strings for `$value`**, e.g. `"$value": "#277B96"`. The strict 2025.10 color type is an object (`{"colorSpace": "srgb", "components": [...], "hex": "#277B96"}`) to support P3/Oklch — that is pure ceremony for a hand-maintained sRGB system with zero build tooling. Document the deviation in `meta.notes` ("hex-string color values; upgrade path to DTCG color objects if tooling ever consumes this file"). Style Dictionary and Terrazzo both accept hex strings, so the upgrade path stays open.
- **Use `{group.token}` alias syntax** for raw→semantic references (the codex already does this with `{palette.glass.value}`; under DTCG `$`-naming it becomes `{palette.glass}`). Do not use JSON Pointer `$ref` — tool-grade machinery.
- **Drop the `tokens.studio` `$schema` line** from the codex; reference the DTCG format instead.

### Tier structure: two tiers

```
Tier 1: palette.*      raw values, brand-named, no usage meaning
Tier 2: color.{theme}.* + color.feedback.* + non-color groups   semantic roles
```

- **Tier 1 (raw):** brand names with descriptive modifiers, NOT numeric weight scales — `glass`, `glass-deep`, `glass-deepest`, `ink`, `ink-raised`, `ink-overlay`, `pine`, `pine-bright`. A Radix-style 12-step ramp or Tailwind-style 50–950 scale is overkill at this size and invites unused tokens; descriptive modifiers are self-documenting at 3–4 values per family. Radix's 12-step semantics (steps 1–2 app backgrounds, 3–5 component backgrounds, 6–8 borders, 9–10 solid fills, 11–12 text) are still the best *mental model* for which roles a family must cover — use it as a checklist, not a structure.
- **Tier 2 (semantic):** the only tier `tokens.css` and the brand book reference. Every UI decision routes through a role, never through `palette.*` directly.
- **No Tier 3 (component).** With one consuming artifact (the brand book) and grep-enforced conformance, component tokens add sync burden with no payoff. daisyUI ships an entire component library on ~25 semantic colors (`base-100/200/300`, `primary` + `primary-content` pairs, `success/warning/error/info`) — proof that the semantic tier alone carries components fine at this scale.

### Semantic role inventory (per theme)

Surfaces: `background`, `surface`, `surface-raised`, `surface-overlay`, `surface-sunken`, `surface-selected`
Borders: `border` (decorative), `border-input` (≥3:1 verified), `border-strong` (emphasis)
Text: `text`, `text-muted`, `text-disabled`, `text-inverse`
Accent/link: `accent` (non-text uses), `accent-text` (AA-verified), `link`, `link-hover`, `link-active`, `focus-ring`
Feedback (×4: success/warning/error/info): `{kind}-text`, `{kind}-bg`, `{kind}-border`, `{kind}-solid` + `{kind}-on-solid`

### Interaction-state naming: suffix convention, default unsuffixed

`link` / `link-hover` / `link-active`; `surface-selected`; `text-disabled`. State is the **last** segment, default state has no suffix — matches Primer (`fgColor-default`, `bgColor-emphasis-hover`) and daisyUI conventions and reads naturally in CSS. Do **not** model a parallel `state.*` group disconnected from roles (the codex's `color.state.default/hover/active` block is ambiguous about *what* is hovered — fold states into the roles they modify). `focus` is not a state suffix; it's one global role (`focus-ring`) because mailglass uses a single focus treatment everywhere.

### Dark mode: parallel role sets, same variable names

DTCG has no standard mode mechanism, so express themes the way every real system does it:

- **tokens.json:** `color.light.*` and `color.dark.*` as sibling groups with identical role keys (the codex shape, kept). A scripted quality gate can diff the key sets to guarantee parity.
- **tokens.css:** one custom-property name per role; dark reassigns under an attribute selector:

```css
:root, [data-theme="light"] { color-scheme: light; --mg-color-text: #0D1B2A; … }
[data-theme="dark"]         { color-scheme: dark;  --mg-color-text: #EAF6FB; … }
```

This mirrors tokens.json 1:1, is grep-able, and powers the brand book's toggle with one attribute flip on `<html>`. **Rejected alternatives:** `light-dark()` (collapses both themes into single declarations — harder to keep in sync with the two JSON groups, and worse to read in a hand-maintained file); `@media (prefers-color-scheme)` alone (can't drive an explicit toggle); computed/derived dark values via `color-mix()` (untraceable to tokens.json, breaks the contrast-matrix guarantee). Set `color-scheme` per theme so form controls/scrollbars follow.

### CSS custom-property naming

`--mg-{category}-{role}[-{variant}][-{state}]`, lowercase kebab:

```
--mg-color-text          --mg-color-text-muted        --mg-color-link-hover
--mg-color-surface-raised --mg-color-error-text       --mg-color-error-bg
--mg-font-ui             --mg-space-md                --mg-radius-md
--mg-motion-fast         --mg-focus-ring-width
```

The `--mg-` prefix namespaces against any host page (Tailwind v4's `@theme` CSS-first tokens and Open Props both demonstrate that flat, prefixed custom properties ARE the deliverable — no JSON build chain required; tokens.json is the documented source of record, tokens.css is the hand-synced artifact).

### What's overkill for this system (explicit don'ts)

- Style Dictionary / Terrazzo / any build step (milestone scope-lock already forbids it)
- Component-tier tokens; multi-file token sets; `$extensions` metadata
- DTCG color-object syntax; P3/Oklch variants
- 12-step or 50–950 numeric ramps; auto-generated tint scales
- Composite tokens (`typography`, `shadow` as DTCG composite types) — keep the codex's simple scalar groups
- A `state.*` group divorced from roles (codex weakness — remove)

## Contrast Matrix (computed)

**Method (reproduce/verify with this):** WCAG 2.x relative luminance. For each sRGB channel `c ∈ {R,G,B}` in 0–255: `c' = c/255`; `c_lin = c'/12.92` if `c' ≤ 0.04045` else `((c'+0.055)/1.055)^2.4`; `L = 0.2126·R_lin + 0.7152·G_lin + 0.0722·B_lin`; ratio `= (L_lighter + 0.05)/(L_darker + 0.05)`. (WCAG 2.0's published threshold 0.03928 vs the sRGB-standard 0.04045 produces identical results for all 8-bit values.) Thresholds: AA normal ≥ 4.5, AAA normal ≥ 7.0, AA large ≥ 3.0, AAA large ≥ 4.5. Non-text UI components/focus indicators: ≥ 3.0 (SC 1.4.11).

Computed luminances: Ink 0.01037 · Glass 0.16799 · Ice 0.73363 · Mist 0.90369 · Paper 0.96043 · Slate 0.14196 · Amber 0.16657 · Crimson 0.10971 · Pine 0.09726 · White 1.0

| Foreground | Background | Ratio | AA normal | AAA normal | AA large | AAA large |
|---|---|---:|---|---|---|---|
| Ink `#0D1B2A` | Paper `#F8FBFD` | **16.74** | PASS | PASS | PASS | PASS |
| Ink `#0D1B2A` | Mist `#EAF6FB` | **15.80** | PASS | PASS | PASS | PASS |
| Slate `#5C6B7A` | Paper `#F8FBFD` | **5.26** | PASS | fail | PASS | PASS |
| Slate `#5C6B7A` | Mist `#EAF6FB` | **4.97** | PASS | fail | PASS | PASS |
| Glass `#277B96` | Paper `#F8FBFD` | **4.64** | PASS | fail | PASS | PASS |
| Glass `#277B96` | Mist `#EAF6FB` | **4.37** | **FAIL** | fail | PASS | fail |
| Paper `#F8FBFD` | Ink `#0D1B2A` | **16.74** | PASS | PASS | PASS | PASS |
| Ice `#A6EAF2` | Ink `#0D1B2A` | **12.98** | PASS | PASS | PASS | PASS |
| Glass `#277B96` | Ink `#0D1B2A` | **3.61** | **FAIL** | fail | PASS | fail |
| Ice `#A6EAF2` | Glass `#277B96` | **3.59** | **FAIL** | fail | PASS | fail |
| White `#FFFFFF` | Glass `#277B96` | **4.82** | PASS | fail | PASS | PASS |
| White `#FFFFFF` | Crimson `#B42318` | **6.57** | PASS | fail | PASS | PASS |
| White `#FFFFFF` | Pine `#166534` | **7.13** | PASS | PASS | PASS | PASS |
| White `#FFFFFF` | Amber `#A95F10` | **4.85** | PASS | fail | PASS | PASS |
| Amber `#A95F10` | Paper `#F8FBFD` | **4.67** | PASS | fail | PASS | PASS |
| Crimson `#B42318` | Paper `#F8FBFD` | **6.33** | PASS | fail | PASS | PASS |
| Pine `#166534` | Paper `#F8FBFD` | **6.86** | PASS | fail | PASS | PASS |

Supplementary computed pairs that drive the adjustments below:

| Pair | Ratio | Verdict |
|---|---:|---|
| Glass on selected surface `#DDF2F7` | 4.16 | FAIL AA normal (link text on selected rows) |
| Glass on info-callout bg `#EAF6FB` | 4.37 | FAIL AA normal (the codex's open info-text question: answer is NO) |
| Amber on Mist `#EAF6FB` | 4.40 | FAIL AA normal (warning text on tinted surfaces) |
| Crimson on error bg `#FAE7E5` | 5.52 | PASS |
| Pine on success bg `#E8F3EA` | 6.26 | PASS |
| Amber on warning bg `#FFF8F0` | 4.60 | PASS (but fails on Mist — one warning-text value should work everywhere) |
| codex dark error `#D47368` on overlay `#1F3049` | 4.09 | FAIL AA normal |
| codex dark error `#D47368` on raised-2 `#20354D` | 3.85 | FAIL AA normal |
| codex dark muted text `#B8CAD4` on worst surface `#20354D` | 7.41 | PASS AAA |
| codex dark border `#315069` on base | 2.06 | decorative-only (below 3:1) |

**Correction to the prompt's assumption:** Glass `#277B96` on white is **4.82:1**, not ~4.0 — it passes AA for normal text on white and Paper. The real problem is the tinted-surface family (Mist 4.37, selected 4.16, info bg 4.37): links and accent text inevitably land on those, so a text-safe darker Glass is still required.

## Palette Adjustments

Principle: keep the six brand colors untouched as identity anchors; add **role-grade derivatives** where a seed color fails its required context. Every value below is computed, not estimated.

### Light theme adjustments

| New raw token | Hex | Replaces/role | Computed ratios | Rationale |
|---|---|---|---|---|
| `glass-deep` | `#1D637A` | **link, accent-text, info-text** (default state) | Paper **6.48**, Mist **6.12**, selected `#DDF2F7` **5.81**, white **6.74**, info-bg **6.12**, white-on-it **6.74** | Already exists in codex as `linkHover` — promote to *default* link/text-accent. Passes AA normal on every light surface incl. all callout tints (≥5.65 on error/success/warning bgs). Same hue family as Glass (hue ≈195°). |
| `glass-deepest` | `#174E61` | **link-hover, link-active** | Paper **8.79**, Mist **8.30**, white **9.14**; white-on-it **9.14**, Mist-on-it **8.30** | Codex's `state.active` value, reused as hover/active so hover *increases* contrast. Also the AA-safe solid-button fill (white text 9.14). |
| `amber-deep` | `#96520E` | **warning-text** | Paper **5.76**, Mist **5.43**, warning-bg `#FFF8F0` **5.68**, white-on-it **5.98** | Seed Amber fails on Mist (4.40). One warning-text value that passes everywhere. Seed Amber `#A95F10` stays for warning borders/icons (≥3:1 on all light surfaces: 4.67 Paper / 4.40 Mist). |
| `slate-soft` | `#74909F` | **border-input** (light) | Paper **3.24**, Mist **3.06** | Codex border `#C7DCE5` is 1.37:1 — fine decoratively, fails SC 1.4.11 for form-control boundaries. Slate itself (5.26) is too heavy for a border; this sits between. |

**Glass `#277B96` usage rule (light):** retained for icons, decorative/strong borders, focus rings (4.64 Paper / 4.37 Mist / 4.16 selected — all ≥3:1 non-text), large text (≥24px/19px-bold) on Paper or white, and solid fills with white text (4.82). **Never normal-size body text or links on Mist/selected/info surfaces** — that's `glass-deep`'s job.

**Unchanged (verified passing):** Ink text (16.74/15.80), Slate muted text (5.26/4.97 — AA normal, document as "fails AAA; use Ink where AAA matters"), Crimson error-text (6.33 Paper, 5.97 Mist, 5.52 on error bg), Pine success-text (6.86 Paper, 6.48 Mist, 6.26 on success bg), white-on-Crimson solid (6.57), white-on-Pine solid (7.13). White-on-Amber solid (4.85) passes AA but prefer Ink-on-amber-bright for dark badges. Disabled `#9AA8B4` (2.34 on Paper) is fine — disabled controls are exempt from SC 1.4.3; keep the codex's "never color alone" description discipline, minus the planning language.

### Dark theme adjustments

| New raw token | Hex | Replaces/role | Computed ratios | Rationale |
|---|---|---|---|---|
| `crimson-bright` | `#E29089` | **error-text (dark)** — replaces codex `#D47368` | base **7.11**, raised **6.34**, overlay **5.44**, raised-2 **5.12**, selected `#1B3E55` **4.60**; Ink-on-it **7.11** | Codex `#D47368` fails AA on overlay (4.09) and raised-2 (3.85). `#E29089` passes AA normal on **every** dark surface including selected rows, and works as a solid badge fill with Ink text. |
| `slate-bright` | `#62809A` | **border-input (dark)** | base **4.20**, raised **3.75**, overlay **3.22** | Codex dark border `#315069` is 1.83–2.06:1 — decorative only. Inputs need a ≥3:1 boundary on all surfaces. |
| `slate-dim` | `#6B7E8F` | **text-disabled (dark)** | base **4.15**, raised **3.70** | Exempt from AA but should stay legible; codex had no dark disabled role. |

**Verified-passing codex dark values to keep:** `pine-bright #8BB77F` (worst case 5.47 on `#20354D`, 4.92 on selected; Ink-on-it 7.60), `amber-bright #E0A955` (worst case 5.95; 5.34 on selected; Ink-on-it 8.26), muted text `#B8CAD4` (worst case 7.41 — AAA everywhere), Ice link/accent (worst case 9.34), link-hover `#D6F7FB` (worst case 11.06).

**Glass on dark rule:** Glass `#277B96` is only **3.61** on Ink and **2.60–3.22** on raised surfaces — restrict to large text/graphics on the base background only; the dark accent is **Ice** (`Ice-on-Glass` at 3.59 also fails normal text — never set Ice text on Glass fills).

## Dark Theme Ramp

Derived from Ink's hue family (≈210–215°, desaturating slightly as surfaces lighten — the codex ramp verified well and is largely adopted). All ratios computed against the stated surfaces.

| Role | Token value | Provenance | Key computed ratios |
|---|---|---|---|
| `background` / `surface` | `#0D1B2A` (Ink) | seed | — |
| `surface-raised` (cards) | `#152538` | codex `inkRaised`, verified | Mist text 14.09 |
| `surface-overlay` (modals, pressed) | `#1F3049` | codex `inkPressed`, verified | Mist text 12.09 |
| `surface-sunken` (code wells) | `#0A1521` | codex code-bg, verified | Mist 16.70, Ice 13.72 |
| `surface-selected` | `#1B3E55` | codex, verified | Mist 10.22, Ice 8.40 |
| `border` (decorative) | `#315069` | codex; 1.83–2.06 vs surfaces — hairlines only | — |
| `border-input` (≥3:1) | `#62809A` | **new** | 4.20 / 3.75 / 3.22 (base/raised/overlay) |
| `text` | `#EAF6FB` (Mist) | seed | 15.80 base → 11.37 worst (AAA everywhere) |
| `text-muted` | `#B8CAD4` | codex, verified | 10.30 base → 7.41 worst (AAA everywhere) |
| `text-disabled` | `#6B7E8F` | **new** | 4.15 base / 3.70 raised (exempt, legible) |
| `accent` / `link` | `#A6EAF2` (Ice) | seed | 12.98 base → 9.34 worst |
| `link-hover` | `#D6F7FB` | codex, verified | 15.37 base → 11.06 worst |
| `focus-ring` | `#A6EAF2` (Ice) | seed | ≥9.34 on all surfaces (needs ≥3.0) |
| `success-text` | `#8BB77F` | codex `pineDark`, verified | 7.60 → 5.47 worst; solid+Ink-text 7.60 |
| `warning-text` | `#E0A955` | codex `amberDark`, verified | 8.26 → 5.95 worst; solid+Ink-text 8.26 |
| `error-text` | `#E29089` | **new** (replaces `#D47368`) | 7.11 → 4.60 worst; solid+Ink-text 7.11 |
| `info-text` | `#A6EAF2` (Ice) | seed | 12.98 → 8.40 worst |
| `text-inverse` (on Ice/light fills) | `#0D1B2A` (Ink) | seed | Ink-on-Ice 12.98 |

Feedback **backgrounds** on dark: derive as low-chroma tints of the surface family (e.g. error-bg ≈ `#3A2530`-range mixes); they carry no text-contrast requirement themselves — the guarantee is `{kind}-text` ≥4.5 on `{kind}-bg`, which Phase 86 should verify with the same formula once the four bg tints are picked (codex never defined dark callout bgs — a parity gap the fable book should close).

**Brand-book rendering note:** the contrast matrix section of `index.html` should render *both* themes' role-pair tables from these computed values, and the quality-gate script can recompute them (the luminance formula above is ~10 lines of JS/Python) so the rendered matrix can never drift from the shipped hexes.

## Sources

- [DTCG: Design Tokens specification reaches first stable version (2025-10-28)](https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/) — HIGH
- [Design Tokens Format Module 2025.10](https://www.designtokens.org/tr/drafts/format/) — `$value`/`$type`/`$description`, `{group.token}` aliases, color-object syntax, no built-in theming — HIGH (fetched)
- [Radix Colors: Understanding the scale](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale) — 12-step semantics (1–2 app bg, 3–5 component bg, 6–8 borders, 9–10 solid, 11–12 text) — HIGH
- [W3C Design Tokens Community Group](https://www.w3.org/community/design-tokens/) · [designtokens.org](https://www.designtokens.org/) — HIGH
- [Style Dictionary DTCG support](https://styledictionary.com/info/dtcg/) · [Terrazzo DTCG guide](https://terrazzo.app/docs/guides/dtcg/) · [Tokens Studio token-format docs](https://docs.tokens.studio/manage-settings/token-format) — confirms hex-string tolerance + legacy `value` dialect — MEDIUM
- Tailwind v4 `@theme` CSS-first tokens, Open Props flat custom properties, GitHub Primer primitives (base→functional naming, `-hover` state suffixes), daisyUI semantic colors (`base-100/200/300`, `*-content` pairs, 4 feedback colors) — training data, stable well-established facts — MEDIUM
- WCAG 2.2 SC 1.4.3 / 1.4.6 / 1.4.11 relative-luminance formula — applied directly in computation (script shown in method note) — HIGH
- All contrast ratios in this file: computed locally with the WCAG formula (Python, sRGB 8-bit, 0.04045 threshold) — HIGH
