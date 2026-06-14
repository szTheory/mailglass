# DARK-MODE Research Dossier — v1.11 Design-System Uplift

**RESEARCH-04** | Phase 96 | Status: LOCKED
**Sourcing model:** D-07 codebase-led + external-secondary
**Axis ownership (D-08):** DARK-MODE owns *how* each state, elevation tier, and focus ring
renders in the dark theme. COMPONENT-STATES owns *which states exist*. MOTION owns *how
transitions animate*. Cross-reference by LD-ID.

---

## 1. Existing Dark Token Inventory

Source: `brandbook/tokens.css` lines 89–138 (`[data-theme="dark"]` block).

All contrast ratios computed by WCAG 2.1 relative luminance formula. AA text threshold: 4.5:1.
Non-text (borders, focus indicators, icons, UI components per WCAG 1.4.11): 3:1.

### 1.1 Surface Tier Tokens

| Token | Hex | Lightness (HLS) | Role |
|-------|-----|-----------------|------|
| `--mg-color-surface-sunken` | `#0A1521` | 0.084 | lowest tier — inset panels, code blocks |
| `--mg-color-surface` / `--mg-color-background` | `#0D1B2A` | 0.108 | base canvas (Ink brand color) |
| `--mg-color-surface-raised` | `#152538` | 0.151 | cards, filter panes, sidebar |
| `--mg-color-surface-overlay` | `#1F3049` | 0.204 | modals, popovers |
| `--mg-color-surface-selected` | `#1B3E55` | 0.220 | selected-row accent |

**Elevation inversion check (dark-mode best practice):** In dark mode, surfaces must get
*lighter* as they rise, not darker (opposite of light mode). Lightness figures confirm the
mailglass token tier satisfies this: sunken (0.084) < base (0.108) < raised (0.151) <
overlay (0.204) / selected (0.220). The 5-tier stack is correctly ordered.

### 1.2 Text Tokens — Contrast on Dark Surfaces

| Token | Hex | On `surface` (#0D1B2A) | On `surface-raised` | On `surface-sunken` | On `surface-selected` | AA? |
|-------|-----|------------------------|---------------------|---------------------|-----------------------|-----|
| `--mg-color-text` | `#EAF6FB` | 15.80:1 | 14.09:1 | 16.70:1 | 10.22:1 | YES (AAA) |
| `--mg-color-text-muted` | `#B8CAD4` | 10.30:1 | 9.19:1 | 10.89:1 | 6.66:1 | YES (AA) |
| `--mg-color-text-disabled` | `#6B7E8F` | 4.15:1 | — | — | — | Marginal (AA-large only; intentional — disabled state) |
| `--mg-color-text-inverse` | `#0D1B2A` | — | — | — | — | Used on solid fills only |

All primary and muted text tokens clear WCAG AA 4.5:1 on every surface tier. The worst case
is text-muted on surface-selected (6.66:1), which is the figure confirmed in Phase 86 [86-01].
`text-disabled` is deliberately below 4.5:1; disabled elements are exempt from contrast
requirements per WCAG 1.4.3 Success Criterion.

### 1.3 Border Tokens — Contrast on Dark Surfaces

| Token | Hex | On `surface` | On `surface-raised` | On `surface-sunken` | ≥3:1? |
|-------|-----|--------------|---------------------|---------------------|-------|
| `--mg-color-border` | `#315069` | 2.06:1 | 1.83:1 | 2.17:1 | **NO — WCAG 1.4.11 failure** |
| `--mg-color-border-input` | `#62809A` | 4.20:1 | 3.75:1 | — | YES |
| `--mg-color-border-strong` | `#62809A` | 4.20:1 | 3.75:1 | — | YES |

**Critical finding:** `--mg-color-border` (#315069) does **not** meet WCAG 1.4.11 (non-text
contrast, 3:1) on any dark surface. This token is mapped to daisyUI `base-300` in the
`mailglass-dark` daisyUI theme block (`app.css` line 70): `--color-base-300:
var(--mg-color-border)`. Every `border-base-300` in HEEx inherits this sub-threshold border
in dark mode.

**Usage context:** The design system specifies flat elevation as `border border-base-300`.
This means ALL card borders, sidebar borders, filter pane borders, and table borders in dark
mode are currently below WCAG 1.4.11. However, because `--depth: 0` means NO shadows are
used for structural differentiation — the border IS the elevation signal — this gap matters
for accessibility, not aesthetics alone.

**Disposition for LOCKED DECISIONS:** The downstream build phases (97–100) must use
`--mg-color-border-input` (#62809A) as the dark structural border, or the border token must
be brightened. This dossier locks the stronger `border-input` token for dark structural
elevation.

### 1.4 Focus Ring Token

| Token | Hex | On `surface` | On `surface-raised` | On `surface-sunken` | On `surface-selected` | On `surface-overlay` | ≥3:1? |
|-------|-----|--------------|---------------------|---------------------|-----------------------|----------------------|-------|
| `--mg-color-focus-ring` | `#A6EAF2` (Ice) | 12.98:1 | 11.58:1 | 13.72:1 | 8.40:1 | 9.94:1 | YES — all pass |

The dark focus-ring token is Ice (`#A6EAF2`) — the desaturated/lightened variant of Glass
(#277B96). Contrast ranges from 8.40:1 (worst case on selected) to 13.72:1 (sunken). All
surfaces clear WCAG 1.4.11 3:1 and WCAG 2.4.7 visible focus. No change required.

Note: the light-theme focus-ring is Glass (`#277B96`). The dark reassignment to Ice is a
correct desaturation strategy (see Section 3c below).

### 1.5 Accent / Link Tokens

| Token | Hex | On `surface` | On `surface-raised` | On `surface-selected` | AA? |
|-------|-----|--------------|---------------------|----------------------|-----|
| `--mg-color-accent` | `#A6EAF2` (Ice) | 12.98:1 | 11.58:1 | 8.40:1 | YES |
| `--mg-color-accent-text` | `#A6EAF2` | 12.98:1 | 11.58:1 | 8.40:1 | YES |
| `--mg-color-link` | `#A6EAF2` | 12.98:1 | 11.58:1 | 8.40:1 | YES |

Light-mode accent (#277B96 Glass) passes AA at 4.82:1 on white. In dark mode, the brandbook
correctly assigns Ice (#A6EAF2) — much brighter — so the same 10% accent surface-area rule
applies but the token achieves AAA contrast instead. No further desaturation is needed for
the accent in dark; if anything it could be slightly toned down, but it is not vibrant
(Ice is a pale blue-cyan) and all uses are functional (links, active nav, primary CTA text),
not decorative. The 10% rule still binds: accent does not become the default border or fill.

### 1.6 Status Feedback Tokens (Phase 86 figures)

| Status | Text token | Text hex | BG hex | Text-on-BG | Text-on-surface |
|--------|-----------|----------|--------|------------|-----------------|
| success | `--mg-color-success-text` | `#8BB77F` | `#142B22` | 6.56:1 [AA] | 7.60:1 [AA] |
| warning | `--mg-color-warning-text` | `#E0A955` | `#2B2314` | 7.37:1 [AA] | 8.26:1 [AA] |
| error | `--mg-color-error-text` | `#E29089` | `#2E1B1E` | 6.65:1 [AA] | 7.11:1 [AA] |
| info | `--mg-color-info-text` | `#A6EAF2` | `#11293A` | 11.18:1 [AA] | 12.98:1 [AA] |

Phase 86 decision [86-01] locked these figures as authoritative. This dossier confirms the
same values reading directly from `brandbook/tokens.css` lines 115–137.

---

## 2. Phase 86 Dark-Feedback Extension

Decision [86-01] in STATE.md (lines 112–113) locked:

> success-bg #142B22 (6.56), warning-bg #2B2314 (7.37), error-bg #2E1B1E (6.65),
> info-bg #11293A (11.18) — each `{kind}-text` >= 4.5:1 on its bg.

These four status-feedback pairs are LOCKED. This dossier does not re-decide them.

**Extension scope (what this dossier adds):**

1. Elevation tier ordering for dark (Section 1.1) — LOCKED here as DARK-LD-01
2. Dark structural border prescription (the #315069 sub-threshold finding) — DARK-LD-02
3. Dark focus-ring confirmation with literal values — DARK-LD-03
4. Dark accent desaturation rationale and 10% rule reaffirmation — DARK-LD-04
5. Status-feedback token confirmation (Phase 86 figures) — DARK-LD-05
6. Preview chrome dark implementation (GAP-03 close prescription) — DARK-LD-06
7. Dark interactive border (distinct from structural border) — DARK-LD-07
8. Dark-mode prefers-color-scheme media query behavior — DARK-LD-08

The Phase 86 basis also confirmed the design-system `86-foundations-decisions.md` matrix
as authoritative for worst-surface-case figures. That matrix remains the reference for
future regression testing.

---

## 3. External Pitfalls Research

Source material referenced from established best practice; verified against codebase tokens.

### 3a. Elevation Inversion (Pitfall 1)

**Pattern:** In light mode, surfaces darken as they rise (shadow-on-white creates depth). In
dark mode, shadows are invisible against dark backgrounds, so the convention INVERTS: higher
surfaces appear *lighter* by adding brightness to the surface color. Pure black (#000000) as
the base canvas is a common mistake — it creates a harsh, unnatural appearance.

**Reference:** https://web.dev/articles/prefers-color-scheme (Material Design and HIG both
use surface-tint/overlay approach); https://m3.material.io/styles/color/dark-theme (elevation
overlay system)

**mailglass status:** CORRECTLY implemented. `tokens.css` uses Ink (#0D1B2A, lightness 0.108)
as the base, not pure black. Each tier adds roughly 5-7 lightness points. Confirmed in
Section 1.1. No change required.

### 3b. Accent Desaturation (Pitfall 2)

**Pattern:** Saturated brand accent colors (e.g., a vivid blue at full chroma) create
uncomfortable vibration or "halation" effects on dark backgrounds, particularly against true-
black. Desaturated, lightened variants (≥80% brightness) are standard.

**Reference:** https://web.dev/articles/prefers-color-scheme ("Colors that work in dark mode
are washed-out versions of the colors used in light mode"); Apple Human Interface Guidelines
("Increase the contrast of colors against a dark background").

**mailglass status:** CORRECTLY implemented. Glass #277B96 (the light-mode accent) is replaced
by Ice #A6EAF2 (pale blue-cyan) in dark — a shift from a mid-saturation blue to a
near-white, high-lightness variant. Ice is not vivid/saturated. The 10% accent rule
(`design-system.md` lines 47–50) still binds and is sufficient to prevent Ice from dominating
the UI. No change required.

### 3c. Focus-Ring Contrast Degradation (Pitfall 3)

**Pattern:** A brand accent like #277B96 (Glass) may pass 3:1 on white but fail on dark
backgrounds. The focus ring must maintain ≥3:1 against its *adjacent* surface, per WCAG
1.4.11 Non-Text Contrast (UIcomponent boundary contrast) and the forthcoming WCAG 2.4.11
(Focus Appearance, WCAG 2.2).

**Reference:** https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast
("User interface components: the visual presentation of user interface components … has a
contrast ratio of at least 3:1 against adjacent color(s).")

**mailglass status (dark):** CONFIRMED PASS. Ice (#A6EAF2) as focus-ring achieves 12.98:1 on
`surface`, the worst case is 8.40:1 on `surface-selected`. All tiers pass. Light-mode Glass
(#277B96) is NOT the dark focus-ring; the dark assignment to Ice is correct.

**mailglass status (light):** Glass #277B96 on white (#FFFFFF) = 4.82:1. This passes 3:1 but
does not reach 4.5:1 — acceptable for non-text focus indicators; WCAG 1.4.11 requires 3:1
for UI components, not 4.5:1.

### 3d. Pure-Black Avoidance (Pitfall 4)

**Pattern:** #000000 as the dark base produces harsh text-on-black contrast that creates
perceived "halos" or eye strain. Ink-tinted near-blacks (#0D1B2A to #121920 range) are
preferred — still high contrast but warmer/softer.

**Reference:** https://web.dev/articles/prefers-color-scheme; Figma's dark-mode guidelines
("Use very dark gray rather than pure black for background").

**mailglass status:** CORRECTLY implemented. Background is Ink (#0D1B2A), explicitly the
brand color. Not pure black. No change required.

### 3e. Glassmorphism / Blur Temptation (Pitfall 5)

**Pattern:** Dark mode provides strong aesthetic temptation to use frosted-glass / blur
(`backdrop-filter: blur`) overlays for elevation. This violates performance and brand
constraints and is commonly seen as an anti-pattern in enterprise admin UIs.

**Reference:** https://web.dev/articles/prefers-color-scheme (avoid decorative-only effects);
CLAUDE.md ("NO glassmorphism, bevels, lens flares"); `design-system.md` line 56 (`--depth:0`
= flat).

**mailglass status:** BANNED at the design-system level (`--depth: 0`, `--noise: 0` in both
daisyUI theme blocks; `design-system.md` line 76 "no glassmorphism/bevels"). Build phases
MUST NOT introduce `backdrop-filter`, `blur-*`, or `saturate-*` on surface elements.

---

## 4. Current mailglass_admin Dark-Mode Gap Analysis

### 4.1 Focus Ring in Dark (shell.ex / preview_live.ex / components.ex)

Focus rings in the admin are rendered via Tailwind utility classes (`focus-visible:ring-2
focus-visible:ring-primary` or similar). In dark mode, `primary` maps to Ice (`#A6EAF2`)
via `app.css` line 76: `--color-primary: var(--mg-color-accent)`. Since dark accent is Ice,
focus rings in dark mode inherit Ice. All contrast ratios pass (Section 1.4). No code fix
needed for focus-ring contrast specifically.

The STATE-LD-06 decision (from COMPONENT-STATES dossier) adds focus-ring to `nav_link`
and `nav_pill` — this applies to both light and dark themes equally because the ring token
is already theme-aware.

### 4.2 Structural Border Sub-Threshold in Dark

`--mg-color-border` (#315069) maps to `base-300` in the dark daisyUI theme, used as
`border-base-300` throughout:

- `shell.ex` line 122: `border-r border-base-300` (sidebar border)
- `shell.ex` line 123: `border-b border-base-300` (sidebar header bottom)
- `preview_live.ex` line 228: `border-r border-base-300` (sidebar border)

These borders fall below WCAG 1.4.11 (2.06:1, 1.83:1 respectively on dark surfaces).

**Context consideration:** WCAG 1.4.11 applies to "user interface components" — i.e.,
interactive elements with visible boundaries. Decorative structural dividers (sidebar
separators, card hulls) between inactive surface areas may not strictly require 3:1 if
they convey no interactive affordance. However, the mailglass design system uses borders as
the SOLE elevation signal (no shadows), which makes them structural signals the user depends
on to parse layout. A conservative, accessible reading treats them as UI component boundaries.

**Decision direction:** Lock `--mg-color-border-input` (#62809A, 4.20:1 on dark surface) as
the minimum structural border in dark mode for all borders that delineate interactive regions.
For purely decorative layout separators (e.g., sidebar section dividers), `--mg-color-border`
is acceptable under a strict reading of WCAG 1.4.11, but the accessible default should prefer
border-input. See DARK-LD-02.

### 4.3 Preview Chrome Dark-Mode Gap (GAP-03)

**Evidence from GAP register (RATCHET-GAP-REGISTER.md line 136):**
> "Preview surface ignores the dark theme param — preview-*-dark PNGs are visually identical
> to light; implement dark-mode awareness in the preview chrome/shell so theme toggle affects
> preview surface"

**Codebase investigation:**

`preview_live.ex` line 225:
```
data-theme={if @dark_chrome, do: "mailglass-dark", else: "mailglass-light"}
```

The outermost `<div>` DOES set `data-theme`. The daisyUI theme blocks in `app.css` target
`[data-theme="mailglass-dark"]` (line 61: `name: "mailglass-dark"`). However, the daisyUI
theme plugin applies its token reassignments to the element that carries the `data-theme`
attribute AND its descendants — scoped via CSS specificity. When `data-theme="mailglass-dark"`
is on the outermost div, all `base-100`, `base-200`, `base-300`, `primary` etc. utility
classes inside that div should resolve to dark values.

**Diagnosis of the gap:** The Phase 95 ratchet PNGs showed preview-dark visually identical
to preview-light, scored Motion+A11y: 2 (ui-baseline-scores.json). The gap is NOT that
`data-theme` is absent — it is set on line 225 — but that the `dark_chrome` assign defaults
to `false` (line 71: `|> assign(:dark_chrome, false)`) and the URL-param pathway at
lines 87/108/123 correctly reads it. The likely cause of the visual gap is one of:

(a) The theme URL parameter is not being propagated when the Phase 95 audit script navigated
    to the preview surface, so the script hit the preview with no `?theme=dark` param, and
    `dark_chrome` stayed `false`.
(b) The daisyUI `prefersdark: true` attribute on `mailglass-dark` theme (app.css line 65)
    may interact with OS-level dark mode in the headless test environment, making light and
    dark PNGs identical if the OS was already in dark mode (so both resolved to dark tokens).

**Implementation prescription for closing GAP-03 (Phase 100):**

Phase 100 must ensure:
1. `preview_live.ex` already applies `data-theme` on the outermost wrapper — confirmed.
2. Phase 100 must verify that `?theme=dark` is included in the audit URL when capturing the
   preview-dark PNG. The audit script (`scripts/ui-audit.sh`) must use the URL
   `/dev/mail?theme=dark` for the dark capture, not just the base path.
3. If the gap persists in Phase 100 visual review, the fix is to ensure `handle_params`
   correctly assigns `dark_chrome: true` when `theme=dark` is in params. Lines 108 and 123
   already do this — verify the path from URL param into `dark_chrome` assign is intact.
4. The Phase 100 task must confirm: preview-dark PNG shows dark surface tokens (Ink #0D1B2A
   background, not Paper #F8FBFD).

The fix is an audit/URL concern in Phase 100, not a structural code change. The `data-theme`
mechanism is already wired. See DARK-LD-06.

### 4.4 Elevation Tier Missing or Absent Tokens

The dark surface tier is fully defined in `tokens.css` with 5 tiers (sunken/base/raised/
overlay/selected). All elevation tiers are present. The daisyUI mapping uses:

- `base-100` → `--mg-color-background` (base canvas, Ink)
- `base-200` → `--mg-color-surface-raised` (#152538 — cards, sidebar, filter pane)
- `base-300` → `--mg-color-border` (#315069 — borders, structural dividers)

Note: `surface-sunken` and `surface-overlay` are not mapped into a daisyUI semantic directly
— they are used as raw `--mg-color-*` CSS variables where needed (e.g., code blocks, modals).
This is correct; daisyUI only has 3 base tiers, so the extended mailglass tiers (`surface-sunken`,
`surface-overlay`, `surface-selected`) are consumed via the `--mg-color-*` namespace. Phase
97–100 build tasks must use `var(--mg-color-surface-sunken)` for inset panels and
`shadow-overlay` + `var(--mg-color-surface-overlay)` for modal backgrounds.

---

## 5. Draft Decisions

### 5a. Dark Surface Elevation Tier Mapping

| Tier | Token | Dark hex | Lightness | Usage |
|------|-------|----------|-----------|-------|
| sunken | `--mg-color-surface-sunken` | `#0A1521` | 0.084 | inset panels, code preview bg, triage slots |
| base | `--mg-color-surface` / `background` | `#0D1B2A` | 0.108 | canvas, page bg, list rows (default) |
| raised | `--mg-color-surface-raised` | `#152538` | 0.151 | cards, sidebar bg, filter pane, detail pane |
| overlay | `--mg-color-surface-overlay` | `#1F3049` | 0.204 | modal/popover bg (with `shadow-overlay`) |
| selected | `--mg-color-surface-selected` | `#1B3E55` | 0.220 | active row, selected nav item |

Ordering is correct (brighter = higher). No token change needed; build phases cite these
tokens by `--mg-color-*` name.

### 5b. Dark Focus-Ring Strategy

Retain current: `--mg-color-focus-ring` dark value = `#A6EAF2` (Ice). Contrast is 12.98:1
on base surface (worst case 8.40:1 on selected). No alternate token needed. Ring width:
`--mg-focus-ring-width: 2px` with `--mg-focus-ring-offset: 2px` (from `tokens.css` line 85–86,
theme-invariant). Build phases apply `outline outline-2 outline-offset-2` with
`outline-[var(--mg-color-focus-ring)]` or the mapped daisyUI `focus-visible:ring-2
focus-visible:ring-primary` (Ice in dark via the daisyUI primary mapping).

### 5c. Dark Accent Desaturation Rule

The 10% accent surface-area rule (design-system.md lines 47–50) governs usage.
The dark accent token (#A6EAF2, Ice) is already correctly desaturated/lightened from the
light-mode Glass (#277B96). No further numeric rule is needed. The 10% rule applies unchanged
to dark mode. Build phases must not introduce Ice as a default border, card background, or
badge fill — only selected row border, active nav node, primary CTA text, focus emphasis.

### 5d. Preview Chrome Dark Implementation (GAP-03 close signal)

The `data-theme` attribute is already emitted on the outermost preview wrapper when
`dark_chrome` is true. The fix is operational: Phase 100 must ensure the audit capture URL
includes `?theme=dark` for preview dark-mode captures, and must manually verify that
`assign(:dark_chrome, theme == "dark")` is reached from URL params. No structural code change
required unless Phase 100 visual verification shows the dark surface tokens are not rendered.

If Phase 100 visual verification DOES show the tokens failing to apply (e.g., if a nested
component or sub-view resets the theme attribute), the corrective action is:
- Ensure no child component sets `data-theme="mailglass-light"` unconditionally.
- If the preview device frame (`preview/device_frame.ex`) or the email iframe/embed
  resets `data-theme`, add the conditional there too.

### 5e. Dark Border Token for Interactive Inputs

For form controls, search inputs, and interactive filter fields in dark mode: use
`--mg-color-border-input` (#62809A, 4.20:1 on base surface). This already maps to daisyUI
`border-input` class and is the current `--mg-color-border-input` dark value — no new token.
Build phases use `border-[oklch(var(--color-border-input))]` or the Tailwind utility that
resolves through the daisyUI layer.

For structural/layout borders (sidebar dividers, card outlines, section separators): the
accessible prescriptions are:
- **Preferred (accessible):** Use `--mg-color-border-input` (#62809A) for all dark structural
  borders that delineate interactive regions.
- **Acceptable (decorative-only dividers):** Use `--mg-color-border` (#315069) only for
  purely decorative separators that carry no interactive affordance and convey no semantic
  boundary between interactive elements.

Since the admin uses borders as its primary elevation signal (flat design), the preferred
path is to upgrade structural borders to `border-input` in dark. See DARK-LD-02 / DARK-LD-07.

### 5f. Dark Status Feedback Token Confirmation

Phase 86 figures reconfirmed (Section 1.6 above). No amendment. All four pairs (success/
warning/error/info) clear AA with margin (6.56:1 to 11.18:1). Solid fills
(`--mg-color-*-solid`) use desaturated/bright palette: Pine-bright (#8BB77F), Amber-bright
(#E0A955), Crimson-bright (#E29089), Ice (#A6EAF2) — each paired with `--mg-color-*-on-solid:
#0D1B2A` for text. The Ink text on bright solid (e.g., Ink on Ice) achieves 12.98:1.

---

## 6. Adversarial Synthesis

**Critic pass** — each draft decision challenged against (a) hard design constraints and
(b) GAP-03 closure.

### Challenge 1: Does the preview chrome decision close GAP-03?

**Draft (5d):** "No structural code change required; fix is operational — audit URLs must
include `?theme=dark`."

**Critique:** This is too weak for a LOCKED decision if the gap's root cause is a code path
that never sets `dark_chrome: true`. The GAP register (RATCHET-GAP-REGISTER.md line 136)
says "preview-*-dark PNGs are visually identical to light" — this is a *visual regression in
the captured evidence*, not a documentation gap. A locked decision must prescribe a verifiable
implementation action, not just an audit URL fix.

**Revised position (DARK-LD-06):** Phase 100 MUST:
1. Confirm `dark_chrome` assign is reached from `?theme=dark` URL param via `handle_params`
   (lines 108/123 in `preview_live.ex`). If the path is broken, fix it.
2. If path is intact, the audit script must be patched to include `?theme=dark` in the
   preview-dark capture URL.
3. Either way, Phase 100 must produce a visual diff confirming preview-dark shows dark surface
   tokens (Ink #0D1B2A bg, not Paper #F8FBFD). This is the acceptance gate for GAP-03.

This is a verifiable implementation prescription, not just a docs note.

### Challenge 2: Does the border sub-threshold finding conflict with the flat-elevation constraint?

**Draft (5e):** "Upgrade structural borders to border-input (#62809A) in dark."

**Critique:** The flat-elevation constraint says elevation is BORDERS-FIRST, no shadows.
If borders below 3:1 are acceptable as "decorative dividers" (the lenient WCAG reading),
then upgrading them to 4.20:1 is a visible change that shifts the dark UI lighter in the
border lines. Does this break the "ink-through-glass" brand aesthetic?

**Revised position (DARK-LD-02):** The upgrade is correct. WCAG 1.4.11 applies to "any
visual information required to identify user interface components and states." Since mailglass
uses borders as the ONLY elevation mechanism (no shadows), borders are required visual
information — not decorative. The upgrade from #315069 to #62809A is therefore a
**mandatory accessibility fix**, not an aesthetic preference. The "ink-through-glass"
metaphor is not about having borders be invisible — it is about having surfaces be clear and
deep. A contrast-passing border is consistent with the brand. Build phases in 97–100 must
use `--mg-color-border-input` for all dark structural borders.

### Challenge 3: Does the dark accent desaturation rule (5c) need to be numeric?

**Draft (5c):** "10% rule applies unchanged; Ice token is already correctly desaturated."

**Critique:** Without a numeric rule, a future phase might introduce a bright accent badge
or secondary call-to-action that uses Ice as a fill color (violating 10%). The locked
decision should state the percentage cap explicitly.

**Revised position (DARK-LD-04):** Lock the 10% rule with explicit dark-mode application:
accent token `#A6EAF2` (Ice) must not appear on more than 10% of any surface's total pixel
area. Specific permitted uses in dark mode: selected-row left border (2px), active nav indicator,
primary CTA text/icon, focus-ring. No fill (background color) usage of Ice except for the
selected-row `surface-selected` (#1B3E55) which is a surface token, not the accent token.

### Challenge 4: Does the elevation tier order lock conflict with COMPONENT-STATES axis?

**Challenge:** COMPONENT-STATES dossier (STATE-LD-19) covers evidence_card revealed/denied
states — these may use surface-sunken for the redacted `<pre>` block. If DARK-MODE locks
`surface-sunken` to a specific hex, does that conflict?

**Answer:** No conflict. COMPONENT-STATES owns *which states use which tier* (e.g.,
"redacted pre block uses surface-sunken"). DARK-MODE owns *what surface-sunken's hex value
is in dark* (#0A1521). These are orthogonal. Cross-reference: dark rendering of STATE-LD-19
evidence_card revealed state: see DARK-LD-01 (surface-sunken = #0A1521).

### Challenge 5: Is the `prefers-color-scheme` media-query block in `tokens.css` correctly wired?

**Token file:** `brandbook/tokens.css` lines 140–191 define a media block
`@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { ... } }`. This
means OS-level dark mode applies the dark tokens to any element that does not have an explicit
`data-theme="light"` override.

**The admin shell.ex** (line 119) sets `data-theme` to either `"mailglass-dark"` or
`"mailglass-light"` on the outermost shell div. The daisyUI theme blocks (not the raw
`--mg-*` tokens) are what control the daisyUI utilities (`bg-base-100`, `text-base-content`,
etc.). The media query block in `tokens.css` sets the raw `--mg-*` vars, while the daisyUI
theme plugin in `app.css` maps those vars into `--color-base-100` etc.

**Potential gap:** If a user has OS-level dark mode AND the admin URL has no `?theme=` param,
the raw `--mg-*` tokens will be dark (from the media block) but the daisyUI `[data-theme]`
selector may not fire because `data-theme` is set explicitly to `mailglass-light` by default.
This means `base-100` would remain the light value while `--mg-color-background` becomes dark
— a split-brain state.

**Locked resolution (DARK-LD-08):** Phase 100 must add OS-dark-mode detection to the initial
shell/preview mount. If `prefers-color-scheme: dark` is detected at mount time and no
`?theme=` param is present, default to dark chrome. Implement via a Phoenix LiveView `js`
snippet or a `mount/3` check using `conn.req_headers` / browser-preference defaults.
The daisyUI `prefersdark: true` attribute on the `mailglass-dark` theme (app.css line 65)
is the correct mechanism — it makes `mailglass-dark` the default when the OS prefers dark —
but it requires the theme plugin to scope correctly (which requires `data-theme` not being
force-set to `mailglass-light` on the wrapper). Phase 100 must verify this chain.

---

## LOCKED DECISION

| LD-ID | Decision | Applies-to (surface/archetype) | Constraint-binding | Closes-GAP |
|-------|----------|-------------------------------|-------------------|------------|
| DARK-LD-01 | Dark surface elevation tier order locked: `--mg-color-surface-sunken` #0A1521 (deepest) → `--mg-color-surface` #0D1B2A (base) → `--mg-color-surface-raised` #152538 (cards/panes) → `--mg-color-surface-overlay` #1F3049 (modals) → `--mg-color-surface-selected` #1B3E55 (active row). Brighter = higher tier. Build phases cite tokens by `--mg-color-*` name, not hex literals. | All surfaces (deliveries / inbound / preview) — all card, pane, modal, and row archetypes | semantic tokens only; flat elevation (border-first, no glassmorphism/bevels/shadows except `shadow-overlay` on overlay tier); `brandbook/tokens.css` is SoT | — |
| DARK-LD-02 | Dark structural border upgrade: for ALL borders that delineate interactive regions or serve as the sole elevation boundary in dark mode, use `--mg-color-border-input` (#62809A, 4.20:1 on #0D1B2A) instead of `--mg-color-border` (#315069, 2.06:1 — WCAG 1.4.11 failure). Purely decorative non-interactive separators may retain `--mg-color-border`. In daisyUI: override the dark `--color-base-300` mapping from `var(--mg-color-border)` to `var(--mg-color-border-input)` in the `mailglass-dark` theme block in `app.css`. | All surfaces — sidebar borders, card outlines, filter pane borders, table dividers in dark mode | WCAG 1.4.11 non-text contrast ≥3:1 mandatory; semantic tokens only; flat elevation (borders are the ONLY elevation signal — they are required visual information, not decorative); `brandbook/tokens.css` is SoT | — |
| DARK-LD-03 | Dark focus-ring token confirmed: `--mg-color-focus-ring` dark value #A6EAF2 (Ice). Contrast verified: 12.98:1 on base surface, 11.58:1 on surface-raised, 8.40:1 on surface-selected (worst case — passes WCAG 1.4.11 3:1). Ring parameters: `--mg-focus-ring-width: 2px`, `--mg-focus-ring-offset: 2px` (theme-invariant per `tokens.css` lines 85–86). Build phases render focus rings via `outline outline-2 outline-offset-2 outline-[var(--mg-color-focus-ring)]` or mapped daisyUI `focus-visible:ring-2 focus-visible:ring-primary`. No alternate token needed in dark. | All surfaces — all interactive elements (buttons, nav links, inputs, tabs, select controls) | WCAG 1.4.11 non-text contrast ≥3:1 for focus indicator; WCAG 2.4.7 visible focus required; semantic tokens only; `brandbook/tokens.css` is SoT | — |
| DARK-LD-04 | Dark accent desaturation: `--mg-color-accent` dark value #A6EAF2 (Ice) is the correct desaturated variant of light-mode Glass #277B96 — no further desaturation needed. 10% accent surface-area rule applies unchanged in dark mode. Permitted uses of Ice (#A6EAF2) in dark: selected-row left border (2px line), active nav indicator dot/line, primary CTA text and icon color, focus-ring. Prohibited: default structural borders, card fills, section backgrounds, badge fills. The sole dark "fill" use of the accent color space is `surface-selected` (#1B3E55), which is a surface token, not the accent token. | All surfaces | 10%-accent rule (`design-system.md` lines 47–50); semantic tokens only; flat elevation; no glassmorphism; `brandbook/tokens.css` is SoT | — |
| DARK-LD-05 | Dark status-feedback tokens confirmed from Phase 86 [86-01]: `--mg-color-success-bg` #142B22 / `--mg-color-success-text` #8BB77F (6.56:1); `--mg-color-warning-bg` #2B2314 / `--mg-color-warning-text` #E0A955 (7.37:1); `--mg-color-error-bg` #2E1B1E / `--mg-color-error-text` #E29089 (6.65:1); `--mg-color-info-bg` #11293A / `--mg-color-info-text` #A6EAF2 (11.18:1). All `*-text` tokens also pass AA (≥4.5:1) on the base dark surface #0D1B2A. Solid fills use corresponding `--mg-color-*-solid` with `--mg-color-*-on-solid: #0D1B2A`. These values are LOCKED; do not amend. Dark rendering of STATE-LD-05 (status_badge) and all flash/toast components: see DARK-LD-05. | All surfaces — flash banners, status badges, toast notifications, triage support cards | WCAG AA 4.5:1 text contrast on all surface tiers; semantic tokens only; `brandbook/tokens.css` is SoT | — |
| DARK-LD-06 | Preview chrome dark implementation (GAP-03 close prescription): `preview_live.ex` already emits `data-theme={if @dark_chrome, do: "mailglass-dark", else: "mailglass-light"}` on the outermost wrapper (line 225). The `dark_chrome` assign is set from `?theme=dark` URL param via `handle_params` (lines 108/123). Phase 100 MUST: (1) confirm `handle_params` correctly sets `dark_chrome: true` when `?theme=dark`; (2) confirm the audit capture URL for preview dark-mode uses `?theme=dark`; (3) produce a visual comparison showing preview-dark renders Ink #0D1B2A background (not Paper #F8FBFD). If a child component resets `data-theme` unconditionally, fix it. No `data-theme` override is permitted on child wrappers inside preview_live unless it matches the parent `dark_chrome` assign. Acceptance gate: preview-*-dark.png visually distinct from preview-*-light.png (dark surfaces, Ice accent, Mist text). | preview surface — `preview_live.ex`, `preview/sidebar.ex`, `preview/device_frame.ex` | semantic tokens only; `brandbook/tokens.css` [data-theme="dark"] block drives all dark token resolution; the `mailglass-dark` daisyUI theme block in `app.css` must be the active theme when `dark_chrome` is true | GAP-03 |
| DARK-LD-07 | Dark interactive input border: form controls, filter inputs, search fields, and select menus must use `--mg-color-border-input` (#62809A) in dark mode — not `--mg-color-border` (#315069). This is the dark value of the `border-input` daisyUI token. Contrast: 4.20:1 on `surface` (#0D1B2A), 3.75:1 on `surface-raised` (#152538) — both pass WCAG 1.4.11 3:1. Dark rendering of STATE-LD-15 (filters_form inputs) and STATE-LD-11 (tenant_chip): see DARK-LD-07. | inbound/deliveries surfaces — `filters_form.ex`, `filter_section.ex`, `tenant_chip` | WCAG 1.4.11 non-text contrast ≥3:1 for input boundaries; semantic tokens only; `brandbook/tokens.css` is SoT | — |
| DARK-LD-08 | OS-level dark-mode integration: `brandbook/tokens.css` includes a `@media (prefers-color-scheme: dark)` block (lines 140–191) that reassigns `--mg-*` tokens on `:root:not([data-theme="light"])`. The daisyUI `prefersdark: true` attribute on the `mailglass-dark` theme (app.css line 65) makes `mailglass-dark` the browser default when OS prefers dark. Phase 100 must verify that when a user visits the preview surface with OS dark-mode active and no `?theme=` param, the page renders dark chrome (not split-brain: dark `--mg-*` vars but light daisyUI tokens). The correct behavior is `dark_chrome` defaulting to `true` in that case, which requires either: (a) reading `prefers-color-scheme` at the LiveView `mount/3` via a JS hook that stores the preference in a param, or (b) relying on the daisyUI `prefersdark: true` scoping at the CSS level (which only works if `data-theme` is not explicitly set to `mailglass-light` on mount). The locked rule: do not unconditionally assign `dark_chrome: false` at mount when no param is present — defer to the daisyUI `prefersdark: true` CSS behavior by setting `data-theme` only when explicitly requested via URL param. | All surfaces — initial mount behavior in `preview_live.ex` (line 71) and operator `shell.ex` | semantic tokens only; `brandbook/tokens.css` is SoT; no client JS hooks (CSS+LiveView.JS only) | — |
