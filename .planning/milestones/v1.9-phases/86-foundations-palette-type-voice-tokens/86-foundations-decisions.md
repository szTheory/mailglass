# Phase 86 Foundations Decisions — Palette, Type, Voice, Tokens

**Decided:** 2026-06-11
**Source of truth for values:** `brandbook-fable/tokens.json` (every hex below matches the shipped file; the one exception is the rejected codex dark error value `#D47368`, cited as evidence only)
**Requirements:** FOUND-01 (evolve-vs-keep), FOUND-03 (computed contrast matrix)

## Method

All ratios in this record were computed (not copied) with the WCAG 2.x
relative-luminance formula, run against the final shipped token hexes in
`brandbook-fable/tokens.json`:

- For each sRGB 8-bit channel `c`: `c' = c/255`; `c_lin = c'/12.92` if
  `c' <= 0.04045`, else `((c'+0.055)/1.055)^2.4`
- `L = 0.2126*R_lin + 0.7152*G_lin + 0.0722*B_lin`
- `ratio = (L_lighter + 0.05) / (L_darker + 0.05)`
- Thresholds: AA normal >= 4.5, AAA normal >= 7.0, AA large >= 3.0,
  AAA large >= 4.5; non-text UI components/focus indicators >= 3.0 (SC 1.4.11)

Phase 88 and Phase 90 can recompute identically (sRGB 8-bit, 0.04045
threshold). The generator script was a throwaway run from `/tmp`
(`mg_contrast.py` / `mg_matrix.py`) and is not committed anywhere.

**Worst-surface convention:** "worst" figures below come from the computed
matrix over the SHIPPED surface set. The worst light surface for most text
roles is `surface-selected #DDF2F7`; the worst dark surface is
`surface-selected #1B3E55`. (Upstream research quoted worst cases against a
different surface set, so some figures here are lower than the research
tables; the matrix in this record is authoritative.)

## 1. Evolve-vs-Keep Records (FOUND-01)

### Palette — KEEP (seed values verified passing in their roles)

| Decision | Token | Hex | Role(s) | Computed ratios (passing) |
|---|---|---|---|---|
| KEEP | Ink | `#0D1B2A` | light text; dark background/surface; dark text-inverse/on-solid | 16.74 on Paper, 17.39 on white, 15.01 worst light surface (selected); as on-solid text: 7.60 on pine-bright, 8.26 on amber-bright, 7.11 on crimson-bright, 12.98 on Ice |
| KEEP | Glass | `#277B96` | light accent (non-text), focus-ring, info-border; solid fills with white text | 4.82 on white (AA normal PASS), 4.64 on Paper; >= 4.16 on every light surface as a >= 3:1 non-text indicator; white-on-Glass 4.82 |
| KEEP | Ice | `#A6EAF2` | dark accent, accent-text, link, focus-ring, info-text/border/solid | 12.98 on Ink, 8.40 worst dark surface (selected) — AAA everywhere |
| KEEP | Mist | `#EAF6FB` | light surface-sunken, info-bg; dark text | as dark text: 15.80 base, 10.22 worst dark surface (selected) — AAA everywhere |
| KEEP | Paper | `#F8FBFD` | light background | carrier surface; Ink on Paper 16.74 |
| KEEP | Slate | `#5C6B7A` | light text-muted, border-strong | 5.26 Paper / 4.72 worst (selected) — AA normal everywhere, fails AAA; usage rule: use `text` where AAA matters |
| KEEP | Pine | `#166534` | light success-text/border/solid | 6.86 Paper, 6.26 on success-bg `#E8F3EA`, 6.15 worst (selected); white-on-Pine 7.13 (AAA) |
| KEEP | Crimson | `#B42318` | light error-text/border/solid | 6.33 Paper, 5.52 on error-bg `#FAE7E5`, 5.67 on selected; white-on-Crimson 6.57 |
| KEEP | Amber (borders/solids only) | `#A95F10` | light warning-border/solid | >= 3:1 non-text on all light surfaces (4.67 Paper, 4.40 Mist); white-on-Amber 4.85 (AA) — but FAILS as normal text on Mist at 4.40, hence amber-deep below |

### Palette — EVOLVE (six computed fix values; each fixes a failing seed ratio)

| Decision | New token | Hex | Role(s) | Seed failure it fixes | Computed passing ratios |
|---|---|---|---|---|---|
| EVOLVE | glass-deep | `#1D637A` | light link, accent-text, info-text/solid | Glass `#277B96` fails AA normal text on Mist (4.37), selected `#DDF2F7` (4.16), info-bg (4.37) | 6.48 Paper, 6.74 white, 6.12 Mist/info-bg, 5.81 worst light surface (selected) — AA normal on EVERY light surface; white-on-it 6.74 |
| EVOLVE | glass-deepest | `#174E61` | light link-hover, link-active | hover must not drop below the default link's contrast | 8.79 Paper, 9.14 white, 8.30 Mist, 7.88 worst (selected) — AAA normal on every light surface; contrast RISES on hover |
| EVOLVE | amber-deep | `#96520E` | light warning-text | Amber `#A95F10` fails AA normal on Mist (4.40) | 5.76 Paper, 5.98 white, 5.43 Mist, 5.68 on warning-bg `#FFF8F0`, 5.16 worst (selected) — one warning-text value that passes everywhere |
| EVOLVE | slate-soft | `#74909F` | light border-input | seed decorative border `#C7DCE5` is ~1.4:1 — fails SC 1.4.11 for control boundaries | 3.24 Paper, 3.37 white, 3.06 Mist — >= 3:1 on all input-bearing light surfaces (see matrix note on selected rows) |
| EVOLVE | slate-bright | `#62809A` | dark border-input, border-strong | codex dark border `#315069` is 1.83–2.06 — decorative only | 4.20 base, 3.75 raised, 3.22 overlay, 4.44 sunken — >= 3:1 on all input-bearing dark surfaces |
| EVOLVE | crimson-bright | `#E29089` | dark error-text/border/solid | codex `#D47368` FAILS AA on overlay (computed 4.09, reproduced) and raised surfaces | 7.11 base, 6.34 raised, 5.44 overlay, 4.60 worst (selected), 6.65 on error-bg `#2E1B1E` — AA normal on every dark surface; Ink-on-it 7.11 (AAA) |

### Palette — ADOPT (codex dark ramp, independently re-verified)

| Decision | Token | Hex | Role | Verification (computed) |
|---|---|---|---|---|
| ADOPT | ink | `#0D1B2A` | dark background/surface | Mist text 15.80, muted 10.30, Ice 12.98 |
| ADOPT | ink-raised | `#152538` | dark surface-raised | Mist text 14.09, muted 9.19, Ice 11.58 |
| ADOPT | ink-overlay | `#1F3049` | dark surface-overlay | Mist text 12.09, muted 7.89, Ice 9.94 |
| ADOPT | ink-sunken | `#0A1521` | dark surface-sunken | Mist text 16.70, Ice 13.72 |
| ADOPT | ink-selected | `#1B3E55` | dark surface-selected | Mist text 10.22, Ice 8.40 — the worst dark surface for every text role; all primary text roles still pass AA |
| ADOPT | ink-edge | `#315069` | dark decorative border | 1.83–2.06 vs dark surfaces — hairlines only, never a control boundary (slate-bright owns inputs) |
| ADOPT | mist-soft | `#B8CAD4` | dark text-muted | 10.30 base, 7.89 overlay, 6.66 on selected — AAA on all surfaces except selected rows (AA there); see Deviation note below |
| ADOPT | slate-dim | `#6B7E8F` | dark text-disabled | 4.15 base / 3.70 raised — exempt under SC 1.4.3 but kept legible; codex had no dark disabled role |
| ADOPT | ice-bright | `#D6F7FB` | dark link-hover/active | 15.37 base, 9.94 worst (selected) — AAA everywhere |
| ADOPT | pine-bright | `#8BB77F` | dark success-text/border/solid | 7.60 base, 6.78 raised, 4.92 worst (selected); Ink-on-it 7.60 |
| ADOPT | amber-bright | `#E0A955` | dark warning-text/border/solid | 8.26 base, 7.37 raised, 5.34 worst (selected); Ink-on-it 8.26 |

### Palette — DECIDED (the four open dark feedback backgrounds)

Low-chroma hue tints near the raised-surface lightness; the contract is
`{kind}-text >= 4.5:1 on {kind}-bg`. All four starting candidates verified
clean on the first computation — adopted without adjustment:

| Decision | Token | Hex | Pairs with | Computed ratio | Verdict |
|---|---|---|---|---|---|
| DECIDED | pine-shadow (success-bg dark) | `#142B22` | success-text `#8BB77F` | 6.56 | PASS AA normal (>= 4.5) |
| DECIDED | amber-shadow (warning-bg dark) | `#2B2314` | warning-text `#E0A955` | 7.37 | PASS AAA normal |
| DECIDED | crimson-shadow (error-bg dark) | `#2E1B1E` | error-text `#E29089` | 6.65 | PASS AA normal |
| DECIDED | ice-shadow (info-bg dark) | `#11293A` | info-text `#A6EAF2` | 11.18 | PASS AAA normal |

This closes the codex parity gap: dark callout backgrounds now exist as
first-class roles, so dark feedback callouts render with verified contrast
instead of falling back to light tints.

### Light feedback tints — KEEP (verified against their text values)

| Token | Hex | Pairs with | Ratio |
|---|---|---|---|
| pine-tint (success-bg) | `#E8F3EA` | Pine `#166534` | 6.26 |
| amber-tint (warning-bg) | `#FFF8F0` | amber-deep `#96520E` | 5.68 |
| crimson-tint (error-bg) | `#FAE7E5` | Crimson `#B42318` | 5.52 |
| info-bg | `#EAF6FB` (Mist) | glass-deep `#1D637A` | 6.12 |
| ice-tint (surface-selected) | `#DDF2F7` | all light text roles | worst pair: text-muted 4.72 (AA) |
| slate-faint (text-disabled) | `#9AA8B4` | — | 2.34 on Paper — exempt under SC 1.4.3; never color alone |

### Typography — KEEP (with the honest-fallback statement)

- KEEP the named stack: **Inter Tight** (display), **Inter** (UI/body),
  **IBM Plex Mono** (code) — as *named preferences*.
- **Honest-fallback fact, recorded explicitly: Inter is preinstalled on no
  major OS.** No webfonts ship (scope lock: no `@font-face`, no network
  requests), so most viewers see the system fallback, not Inter. The shipped
  stacks in `tokens.css` therefore carry the full honest chain:
  - display: `"Inter Tight", Inter, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", sans-serif`
  - ui: `Inter, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", sans-serif`
  - mono: `"IBM Plex Mono", ui-monospace, SFMono-Regular, Menlo, Consolas, monospace`
- Type scale decided (px tokens, within the seed ranges):
  **display 44 / h1 36 / h2 30 / h3 24 / body 16 / small 14 / code 14**.
- Space scale: xs 4 / sm 8 / md 16 / lg 24 / xl 40 / 2xl 64.
  Radius: sm 4 / md 8 / lg 12 / full 9999. Focus ring: 2px width, 2px offset.

### Voice — KEEP

The thoughtful-maintainer seeds stand unchanged: **calm, exact, confident
(not cocky), warm (not cute)**. Errors are specific and composed; docs prefer
the direct word. The full voice system (say/don't-say pairs, per-surface
copy, seven-noun microcopy) ships in Phases 88/89, not here.

## 2. Computed Contrast Matrix (FOUND-03)

Both themes, every text-role x surface-role pair, plus on-solid pairs and the
non-text >= 3.0 checks. Computed from the shipped `tokens.json` hexes with the
method above. Anchor sanity values reproduced: Ink on Paper **16.74**, Glass
on white **4.82** (AA pass — Glass remains a valid solid-fill/large-text
accent on white), Glass on Mist **4.37** (FAIL — this is why accent text on
tinted surfaces routes through glass-deep `#1D637A`), glass-deep on Mist
**6.12**, rejected codex dark error `#D47368` on overlay **4.09** (FAIL —
why crimson-bright `#E29089` replaced it).

**Global usage rules distilled from the matrix:**

- **Glass `#277B96` (light accent):** icons, strong borders, focus rings,
  large text (>= 24px / 19px bold) on Paper/white, and solid fills with white
  text (4.82). **Never normal-size text on Mist / selected / info surfaces**
  (4.37 / 4.16 / 4.37 — all FAIL): use `accent-text` (glass-deep) there.
- **text-muted (both themes):** AA only on light (5.26 worst-typical) — use
  `text` where AAA matters. On dark it is AAA except on selected rows (6.66).
- **text-disabled (both themes):** exempt under SC 1.4.3 — a legibility
  courtesy, never the only signal of a disabled state.
- **link-hover/active:** chosen so contrast RISES on interaction in both
  themes (light 6.48 → 8.79 on Paper; dark 12.98 → 15.37 on base).
- **border-input:** >= 3:1 on every input-bearing surface in both themes.
  Form controls are not placed on `surface-selected` (light 2.91 / dark 2.72
  — below 3:1): selected rows highlight existing content, they do not host
  form fields. If a future surface needs inputs inside selected rows, a
  dedicated border value must be added and verified.
- **focus-ring:** passes >= 3:1 on every surface in both themes (light worst
  4.16; dark worst 8.40) — one ring value per theme, no exceptions needed.
- **Dark accent is Ice, not Glass:** Glass on Ink is 3.61 (large-text only);
  every dark accent/link/info role uses Ice `#A6EAF2` (8.40 worst — AAA).

### Light theme — text roles x surfaces

| Foreground role | Hex | Background role | Hex | Ratio | AA normal | AAA normal | AA large | AAA large | Usage rule |
|---|---|---|---|---:|---|---|---|---|---|
| text | #0D1B2A | background | #F8FBFD | 16.74 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text | #0D1B2A | surface | #FFFFFF | 17.39 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text | #0D1B2A | surface-raised | #FFFFFF | 17.39 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text | #0D1B2A | surface-overlay | #FFFFFF | 17.39 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text | #0D1B2A | surface-sunken | #EAF6FB | 15.80 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text | #0D1B2A | surface-selected | #DDF2F7 | 15.01 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text-muted | #5C6B7A | background | #F8FBFD | 5.26 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| text-muted | #5C6B7A | surface | #FFFFFF | 5.47 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| text-muted | #5C6B7A | surface-raised | #FFFFFF | 5.47 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| text-muted | #5C6B7A | surface-overlay | #FFFFFF | 5.47 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| text-muted | #5C6B7A | surface-sunken | #EAF6FB | 4.97 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| text-muted | #5C6B7A | surface-selected | #DDF2F7 | 4.72 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| text-disabled | #9AA8B4 | background | #F8FBFD | 2.34 | FAIL | FAIL | FAIL | FAIL | Exempt under SC 1.4.3 — legibility courtesy only; never color alone |
| text-disabled | #9AA8B4 | surface | #FFFFFF | 2.43 | FAIL | FAIL | FAIL | FAIL | Exempt under SC 1.4.3 — legibility courtesy only; never color alone |
| text-disabled | #9AA8B4 | surface-raised | #FFFFFF | 2.43 | FAIL | FAIL | FAIL | FAIL | Exempt under SC 1.4.3 — legibility courtesy only; never color alone |
| text-disabled | #9AA8B4 | surface-overlay | #FFFFFF | 2.43 | FAIL | FAIL | FAIL | FAIL | Exempt under SC 1.4.3 — legibility courtesy only; never color alone |
| text-disabled | #9AA8B4 | surface-sunken | #EAF6FB | 2.21 | FAIL | FAIL | FAIL | FAIL | Exempt under SC 1.4.3 — legibility courtesy only; never color alone |
| text-disabled | #9AA8B4 | surface-selected | #DDF2F7 | 2.10 | FAIL | FAIL | FAIL | FAIL | Exempt under SC 1.4.3 — legibility courtesy only; never color alone |
| accent-text | #1D637A | background | #F8FBFD | 6.48 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| accent-text | #1D637A | surface | #FFFFFF | 6.74 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| accent-text | #1D637A | surface-raised | #FFFFFF | 6.74 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| accent-text | #1D637A | surface-overlay | #FFFFFF | 6.74 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| accent-text | #1D637A | surface-sunken | #EAF6FB | 6.12 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| accent-text | #1D637A | surface-selected | #DDF2F7 | 5.81 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| link | #1D637A | background | #F8FBFD | 6.48 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| link | #1D637A | surface | #FFFFFF | 6.74 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| link | #1D637A | surface-raised | #FFFFFF | 6.74 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| link | #1D637A | surface-overlay | #FFFFFF | 6.74 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| link | #1D637A | surface-sunken | #EAF6FB | 6.12 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| link | #1D637A | surface-selected | #DDF2F7 | 5.81 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| link-hover | #174E61 | background | #F8FBFD | 8.79 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-hover | #174E61 | surface | #FFFFFF | 9.14 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-hover | #174E61 | surface-raised | #FFFFFF | 9.14 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-hover | #174E61 | surface-overlay | #FFFFFF | 9.14 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-hover | #174E61 | surface-sunken | #EAF6FB | 8.30 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-hover | #174E61 | surface-selected | #DDF2F7 | 7.88 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-active | #174E61 | background | #F8FBFD | 8.79 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-active | #174E61 | surface | #FFFFFF | 9.14 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-active | #174E61 | surface-raised | #FFFFFF | 9.14 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-active | #174E61 | surface-overlay | #FFFFFF | 9.14 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-active | #174E61 | surface-sunken | #EAF6FB | 8.30 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-active | #174E61 | surface-selected | #DDF2F7 | 7.88 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| accent | #277B96 | background | #F8FBFD | 4.64 | PASS | FAIL | PASS | PASS | AA pass here, but reserve for icons/borders/large text/solid fills; body-size accent copy uses accent-text |
| accent | #277B96 | surface | #FFFFFF | 4.82 | PASS | FAIL | PASS | PASS | AA pass here, but reserve for icons/borders/large text/solid fills; body-size accent copy uses accent-text |
| accent | #277B96 | surface-raised | #FFFFFF | 4.82 | PASS | FAIL | PASS | PASS | AA pass here, but reserve for icons/borders/large text/solid fills; body-size accent copy uses accent-text |
| accent | #277B96 | surface-overlay | #FFFFFF | 4.82 | PASS | FAIL | PASS | PASS | AA pass here, but reserve for icons/borders/large text/solid fills; body-size accent copy uses accent-text |
| accent | #277B96 | surface-sunken | #EAF6FB | 4.37 | FAIL | FAIL | PASS | FAIL | FAIL for normal text — route accent text on tinted surfaces through accent-text (glass-deep) |
| accent | #277B96 | surface-selected | #DDF2F7 | 4.16 | FAIL | FAIL | PASS | FAIL | FAIL for normal text — route accent text on tinted surfaces through accent-text (glass-deep) |

### Light theme — feedback text x surfaces

| Foreground role | Hex | Background role | Hex | Ratio | AA normal | AAA normal | AA large | AAA large | Usage rule |
|---|---|---|---|---:|---|---|---|---|---|
| success-text | #166534 | success-bg | #E8F3EA | 6.26 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| success-text | #166534 | background | #F8FBFD | 6.86 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| success-text | #166534 | surface-raised | #FFFFFF | 7.13 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| success-text | #166534 | surface-selected | #DDF2F7 | 6.15 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| warning-text | #96520E | warning-bg | #FFF8F0 | 5.68 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| warning-text | #96520E | background | #F8FBFD | 5.76 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| warning-text | #96520E | surface-raised | #FFFFFF | 5.98 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| warning-text | #96520E | surface-selected | #DDF2F7 | 5.16 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| error-text | #B42318 | error-bg | #FAE7E5 | 5.52 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| error-text | #B42318 | background | #F8FBFD | 6.33 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| error-text | #B42318 | surface-raised | #FFFFFF | 6.57 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| error-text | #B42318 | surface-selected | #DDF2F7 | 5.67 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| info-text | #1D637A | info-bg | #EAF6FB | 6.12 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| info-text | #1D637A | background | #F8FBFD | 6.48 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| info-text | #1D637A | surface-raised | #FFFFFF | 6.74 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| info-text | #1D637A | surface-selected | #DDF2F7 | 5.81 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |

### Light theme — on-solid pairs

| Foreground role | Hex | Background role | Hex | Ratio | AA normal | AAA normal | AA large | AAA large | Usage rule |
|---|---|---|---|---:|---|---|---|---|---|
| success-on-solid | #FFFFFF | success-solid | #166534 | 7.13 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| warning-on-solid | #FFFFFF | warning-solid | #A95F10 | 4.85 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| error-on-solid | #FFFFFF | error-solid | #B42318 | 6.57 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| info-on-solid | #FFFFFF | info-solid | #1D637A | 6.74 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| text-inverse | #FFFFFF | accent | #277B96 | 4.82 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |

### Light theme — non-text >= 3.0 checks (SC 1.4.11)

| Component role | Hex | Against surface | Hex | Ratio | >= 3.0 |
|---|---|---|---|---:|---|
| border-input | #74909F | background | #F8FBFD | 3.24 | PASS |
| border-input | #74909F | surface | #FFFFFF | 3.37 | PASS |
| border-input | #74909F | surface-raised | #FFFFFF | 3.37 | PASS |
| border-input | #74909F | surface-overlay | #FFFFFF | 3.37 | PASS |
| border-input | #74909F | surface-sunken | #EAF6FB | 3.06 | PASS |
| border-input | #74909F | surface-selected | #DDF2F7 | 2.91 | FAIL |
| focus-ring | #277B96 | background | #F8FBFD | 4.64 | PASS |
| focus-ring | #277B96 | surface | #FFFFFF | 4.82 | PASS |
| focus-ring | #277B96 | surface-raised | #FFFFFF | 4.82 | PASS |
| focus-ring | #277B96 | surface-overlay | #FFFFFF | 4.82 | PASS |
| focus-ring | #277B96 | surface-sunken | #EAF6FB | 4.37 | PASS |
| focus-ring | #277B96 | surface-selected | #DDF2F7 | 4.16 | PASS |

Rule for the one light non-text FAIL: form controls are never placed on
selected-row surfaces; `border-input` guarantees >= 3:1 on
background/surface/raised/overlay/sunken only.

### Dark theme — text roles x surfaces

| Foreground role | Hex | Background role | Hex | Ratio | AA normal | AAA normal | AA large | AAA large | Usage rule |
|---|---|---|---|---:|---|---|---|---|---|
| text | #EAF6FB | background | #0D1B2A | 15.80 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text | #EAF6FB | surface | #0D1B2A | 15.80 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text | #EAF6FB | surface-raised | #152538 | 14.09 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text | #EAF6FB | surface-overlay | #1F3049 | 12.09 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text | #EAF6FB | surface-sunken | #0A1521 | 16.70 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text | #EAF6FB | surface-selected | #1B3E55 | 10.22 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text-muted | #B8CAD4 | background | #0D1B2A | 10.30 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text-muted | #B8CAD4 | surface | #0D1B2A | 10.30 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text-muted | #B8CAD4 | surface-raised | #152538 | 9.19 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text-muted | #B8CAD4 | surface-overlay | #1F3049 | 7.89 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text-muted | #B8CAD4 | surface-sunken | #0A1521 | 10.89 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text-muted | #B8CAD4 | surface-selected | #1B3E55 | 6.66 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| text-disabled | #6B7E8F | background | #0D1B2A | 4.15 | FAIL | FAIL | PASS | FAIL | Exempt under SC 1.4.3 — legibility courtesy only; never color alone |
| text-disabled | #6B7E8F | surface | #0D1B2A | 4.15 | FAIL | FAIL | PASS | FAIL | Exempt under SC 1.4.3 — legibility courtesy only; never color alone |
| text-disabled | #6B7E8F | surface-raised | #152538 | 3.70 | FAIL | FAIL | PASS | FAIL | Exempt under SC 1.4.3 — legibility courtesy only; never color alone |
| text-disabled | #6B7E8F | surface-overlay | #1F3049 | 3.17 | FAIL | FAIL | PASS | FAIL | Exempt under SC 1.4.3 — legibility courtesy only; never color alone |
| text-disabled | #6B7E8F | surface-sunken | #0A1521 | 4.38 | FAIL | FAIL | PASS | FAIL | Exempt under SC 1.4.3 — legibility courtesy only; never color alone |
| text-disabled | #6B7E8F | surface-selected | #1B3E55 | 2.68 | FAIL | FAIL | FAIL | FAIL | Exempt under SC 1.4.3 — legibility courtesy only; never color alone |
| accent-text | #A6EAF2 | background | #0D1B2A | 12.98 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| accent-text | #A6EAF2 | surface | #0D1B2A | 12.98 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| accent-text | #A6EAF2 | surface-raised | #152538 | 11.58 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| accent-text | #A6EAF2 | surface-overlay | #1F3049 | 9.94 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| accent-text | #A6EAF2 | surface-sunken | #0A1521 | 13.72 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| accent-text | #A6EAF2 | surface-selected | #1B3E55 | 8.40 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link | #A6EAF2 | background | #0D1B2A | 12.98 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link | #A6EAF2 | surface | #0D1B2A | 12.98 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link | #A6EAF2 | surface-raised | #152538 | 11.58 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link | #A6EAF2 | surface-overlay | #1F3049 | 9.94 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link | #A6EAF2 | surface-sunken | #0A1521 | 13.72 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link | #A6EAF2 | surface-selected | #1B3E55 | 8.40 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-hover | #D6F7FB | background | #0D1B2A | 15.37 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-hover | #D6F7FB | surface | #0D1B2A | 15.37 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-hover | #D6F7FB | surface-raised | #152538 | 13.71 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-hover | #D6F7FB | surface-overlay | #1F3049 | 11.77 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-hover | #D6F7FB | surface-sunken | #0A1521 | 16.25 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-hover | #D6F7FB | surface-selected | #1B3E55 | 9.94 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-active | #D6F7FB | background | #0D1B2A | 15.37 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-active | #D6F7FB | surface | #0D1B2A | 15.37 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-active | #D6F7FB | surface-raised | #152538 | 13.71 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-active | #D6F7FB | surface-overlay | #1F3049 | 11.77 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-active | #D6F7FB | surface-sunken | #0A1521 | 16.25 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| link-active | #D6F7FB | surface-selected | #1B3E55 | 9.94 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |

### Dark theme — feedback text x surfaces

| Foreground role | Hex | Background role | Hex | Ratio | AA normal | AAA normal | AA large | AAA large | Usage rule |
|---|---|---|---|---:|---|---|---|---|---|
| success-text | #8BB77F | success-bg | #142B22 | 6.56 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| success-text | #8BB77F | background | #0D1B2A | 7.60 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| success-text | #8BB77F | surface-raised | #152538 | 6.78 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| success-text | #8BB77F | surface-selected | #1B3E55 | 4.92 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| warning-text | #E0A955 | warning-bg | #2B2314 | 7.37 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| warning-text | #E0A955 | background | #0D1B2A | 8.26 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| warning-text | #E0A955 | surface-raised | #152538 | 7.37 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| warning-text | #E0A955 | surface-selected | #1B3E55 | 5.34 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| error-text | #E29089 | error-bg | #2E1B1E | 6.65 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| error-text | #E29089 | background | #0D1B2A | 7.11 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| error-text | #E29089 | surface-raised | #152538 | 6.34 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| error-text | #E29089 | surface-selected | #1B3E55 | 4.60 | PASS | FAIL | PASS | PASS | Safe for normal text (AA); use text where AAA matters |
| info-text | #A6EAF2 | info-bg | #11293A | 11.18 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| info-text | #A6EAF2 | background | #0D1B2A | 12.98 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| info-text | #A6EAF2 | surface-raised | #152538 | 11.58 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| info-text | #A6EAF2 | surface-selected | #1B3E55 | 8.40 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |

### Dark theme — on-solid pairs

| Foreground role | Hex | Background role | Hex | Ratio | AA normal | AAA normal | AA large | AAA large | Usage rule |
|---|---|---|---|---:|---|---|---|---|---|
| success-on-solid | #0D1B2A | success-solid | #8BB77F | 7.60 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| warning-on-solid | #0D1B2A | warning-solid | #E0A955 | 8.26 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| error-on-solid | #0D1B2A | error-solid | #E29089 | 7.11 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| info-on-solid | #0D1B2A | info-solid | #A6EAF2 | 12.98 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |
| text-inverse | #0D1B2A | accent | #A6EAF2 | 12.98 | PASS | PASS | PASS | PASS | Safe at any text size including fine print |

### Dark theme — non-text >= 3.0 checks (SC 1.4.11)

| Component role | Hex | Against surface | Hex | Ratio | >= 3.0 |
|---|---|---|---|---:|---|
| border-input | #62809A | background | #0D1B2A | 4.20 | PASS |
| border-input | #62809A | surface | #0D1B2A | 4.20 | PASS |
| border-input | #62809A | surface-raised | #152538 | 3.75 | PASS |
| border-input | #62809A | surface-overlay | #1F3049 | 3.22 | PASS |
| border-input | #62809A | surface-sunken | #0A1521 | 4.44 | PASS |
| border-input | #62809A | surface-selected | #1B3E55 | 2.72 | FAIL |
| focus-ring | #A6EAF2 | background | #0D1B2A | 12.98 | PASS |
| focus-ring | #A6EAF2 | surface | #0D1B2A | 12.98 | PASS |
| focus-ring | #A6EAF2 | surface-raised | #152538 | 11.58 | PASS |
| focus-ring | #A6EAF2 | surface-overlay | #1F3049 | 9.94 | PASS |
| focus-ring | #A6EAF2 | surface-sunken | #0A1521 | 13.72 | PASS |
| focus-ring | #A6EAF2 | surface-selected | #1B3E55 | 8.40 | PASS |

Same rule as light: form controls never sit on selected-row surfaces.

## 3. Notes

- **Phase 88 rendering input:** the matrix data above (structured markdown
  tables, one row per pair, hexes matching `tokens.json` exactly) is the
  input for the brand book's in-page contrast matrix. Per the brief (DIF-05),
  the book recomputes the ratios from the tokens at runtime so the rendered
  matrix can never drift from the shipped hexes; this record is the reference
  the runtime output must agree with.
- **Generator script:** a throwaway python script run from `/tmp`
  (relative-luminance formula above, ~30 lines). Not committed — re-derive
  from the Method section when needed.
- **Deviation (worst-surface figures):** upstream research quoted some dark
  worst-case ratios against surfaces that did not ship (e.g. text-muted
  `#B8CAD4` "7.41 worst", text `#EAF6FB` "11.37 worst"). Against the shipped
  surface set the worst dark surface is `surface-selected #1B3E55`: text
  10.22 (still AAA), text-muted 6.66 (AA — AAA holds on every other dark
  surface). No token change needed; the role guarantee for text-muted is AA,
  matching the light theme. This record's computed figures are authoritative.
- **Deviation (border-input on selected surfaces):** full-matrix coverage
  shows `border-input` falls below 3:1 on `surface-selected` in both themes
  (2.91 light / 2.72 dark) — a context upstream research never claimed. All
  research-claimed contexts reproduce exactly. Resolved as a usage rule
  (form controls never sit on selected rows) rather than darkening the
  border tokens, which would over-weight every normal form.
