# Phase 82: Logo and SVG Asset System - Pattern Map

**Mapped:** 2026-06-06
**Files analyzed:** 12 implementation targets
**Analogs found:** 12 / 12 targets, with product/admin files treated as read-only boundary constraints

## File Extraction

Phase 82 should create or modify only brandbook logo/SVG surface files.

Required or likely implementation targets:

- `brandbook/logo-options.md`
- `brandbook/assets/options/option-a-folded-pane.svg`
- `brandbook/assets/options/option-b-pane-lines.svg`
- `brandbook/assets/options/option-c-inspection-pane.svg`
- `brandbook/assets/logo-primary.svg`
- `brandbook/assets/logo-mark.svg`
- `brandbook/assets/logo-monochrome.svg`
- `brandbook/assets/favicon.svg`
- `brandbook/assets/social-avatar.svg`
- `brandbook/brand-book.md`
- `brandbook/index.html`
- `brandbook/README.md`

Extraction basis:

- `82-CONTEXT.md:37-44` locks this to logo/SVG brandbook updates and excludes package code, admin UI code, public APIs, release workflow, package allowlists, validation scripts, and public copy surfaces.
- `82-CONTEXT.md:104-113` lets the planner choose the option-review artifact format and whether to add temporary option SVG files.
- `82-RESEARCH.md:104-118` names the architecture map: `brandbook/logo-options.md`, optional `brandbook/assets/options/*.svg`, five final SVG assets, and three logo-specific docs.
- `82-UI-SPEC.md:21-27` names the same in-scope files and docs; `82-UI-SPEC.md:141-160` names required construction for each final asset.
- `.planning/ROADMAP.md:85-99` and `.planning/REQUIREMENTS.md:50-59` require five editable SVG assets, multiple direction review, accessible metadata, no raster/font/glossy/paper-plane/mascot complexity.

`brandbook/assets/options/*.svg` is conditional in upstream docs. If the planner chooses inline SVG snippets inside `brandbook/logo-options.md` instead of separate option files, keep the same SVG construction pattern and omit the option files.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `brandbook/logo-options.md` | documentation / logo review artifact | file-I/O Markdown evidence-to-decision transform | `brandbook/brand-audit.md` row-addressable register plus `brandbook/brand-book.md` logo guidance | strong role-match |
| `brandbook/assets/options/option-a-folded-pane.svg` | SVG option sketch | static SVG transform; visual evidence | `brandbook/assets/logo-mark.svg` and `brandbook/assets/logo-primary.svg` | role-match |
| `brandbook/assets/options/option-b-pane-lines.svg` | SVG option sketch | static SVG transform; visual evidence | `brandbook/assets/logo-mark.svg` plus `brandbook/examples/ui-primitives.svg` flat-pane style | role-match |
| `brandbook/assets/options/option-c-inspection-pane.svg` | SVG option sketch | static SVG transform; visual evidence | `brandbook/assets/logo-mark.svg` plus `brandbook/examples/readme-header.svg` source-native mark specimen | role-match |
| `brandbook/assets/logo-primary.svg` | SVG primary lockup | static SVG transform; live text + shape geometry | existing `brandbook/assets/logo-primary.svg` | exact target |
| `brandbook/assets/logo-mark.svg` | SVG icon-only mark | static SVG transform; shape geometry | existing `brandbook/assets/logo-mark.svg` | exact target |
| `brandbook/assets/logo-monochrome.svg` | SVG monochrome mark | static SVG transform; currentColor shape geometry | existing `brandbook/assets/logo-monochrome.svg` | exact target |
| `brandbook/assets/favicon.svg` | SVG favicon | static SVG transform; small-size icon geometry | existing `brandbook/assets/favicon.svg` plus `brandbook/brand-audit.md` favicon risk row | exact target, risk constraint |
| `brandbook/assets/social-avatar.svg` | SVG social avatar | static SVG transform; reversed/dark avatar composition | existing `brandbook/assets/social-avatar.svg` plus `brandbook/examples/palette.svg` dark-surface pattern | exact target |
| `brandbook/brand-book.md` | source brand guidance | Markdown source-of-truth text transform | existing `brandbook/brand-book.md` logo and artifact sections | exact target |
| `brandbook/index.html` | direct-open static brandbook preview | local HTML/CSS/SVG references | existing `brandbook/index.html` logo display and status sections | exact target |
| `brandbook/README.md` | brandbook directory guide | Markdown artifact-policy transform | existing `brandbook/README.md` use/export policy | exact target |

## Read-Only Boundary References

| Reference File | Use In Phase 82 | Warning |
|---|---|---|
| `brandbook/brand-audit.md` | Source of `BRAND-GAP-04`, `BRAND-GAP-05`, `BRAND-GAP-06`, option-review requirement, small-size risk, and duplicate-ID risk | Do not rewrite or renumber audit rows. Use as cited evidence. |
| `brandbook/tokens.json` | Source palette/type/spacing/radius guidance for SVGs and brandbook copy | Do not imply product admin UI consumes this directly. |
| `brandbook/tokens.css` | Static HTML token mechanics and direct-open preview styling | Avoid adding build steps, preprocessors, imports, or font-face. |
| `mailglass_admin/docs/design-system.md` | Implemented admin UI boundary and accent/flatness discipline | Do not modify product/admin design-system docs in this phase. |
| `mailglass_admin/priv/static/mailglass-logo.svg` | Evidence that admin static logo is an older placeholder | Do not replace admin static asset in Phase 82. Product integration is out of scope. |

## Pattern Assignments

### `brandbook/logo-options.md` (documentation / logo review artifact, file-I/O Markdown transform)

**Primary analog:** `brandbook/brand-audit.md`

Use the audit's candid, row-addressable decision style. It opens with status, sources, and a clear non-overclaim:

```markdown
Phase 80 scope: this file is the audit and gap-register gate for v1.8.
The existing `brandbook/` files are draft inputs from commit `572f3eb2`,
not approved Phase 81-84 outputs.
```

Source lines: `brandbook/brand-audit.md:5-10`.

Copy the table-driven register style for option comparison and final selection criteria:

```markdown
| BRAND-GAP-NN | Classification | Severity | Surface | Evidence | Rationale | Target Phase | Acceptance / Closeout Cue |
|---|---|---:|---|---|---|---|---|
| BRAND-GAP-04 | ADD | 4 | Logo system | `brandbook/assets/*.svg` is one credible draft direction; D-11 requires multiple-option review | Avoid premature final logo approval and brand churn. | Phase 82 | Phase 82 compares multiple credible mark directions before selecting or refining the final system. |
```

Source lines: `brandbook/brand-audit.md:136-151`.

The Phase 82 handoff row is the strongest closeout checklist for this file:

```markdown
| Phase 82 | Logo and SVG asset system: compare multiple credible directions; resolve favicon, monochrome, dark/reversed variants, duplicate `title`/`desc` IDs, live text versus outlined distribution, and fold ambiguity. | BRAND-GAP-04, BRAND-GAP-05, BRAND-GAP-06 |
```

Source lines: `brandbook/brand-audit.md:170-178`.

**Apply to `logo-options.md`:**

- Include at least three directions: folded pane draft, simplified pane/message-lines, inspection/pane-forward.
- Include visual evidence; do not make the review prose-only.
- Compare 16px clarity, 32px clarity, wordmark-first fit, brand-center alignment, forbidden trope avoidance, monochrome/currentColor viability, reversed/dark viability, path complexity, editability, accessible metadata, and unique ID strategy.
- Include a "Selected direction" or "Final refinement" section so future agents can audit why final assets changed.
- Cite `BRAND-GAP-04`, `BRAND-GAP-05`, and `BRAND-GAP-06`.

### `brandbook/assets/options/option-a-folded-pane.svg` (SVG option sketch, static SVG visual evidence)

**Primary analog:** `brandbook/assets/logo-mark.svg`

Use the existing folded-pane mark as option A evidence. It is credible but not final by default:

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96" role="img" aria-labelledby="title desc">
  <title id="title">Mailglass mark</title>
  <desc id="desc">A flat pane mark with an implied message fold, representing visible email.</desc>
  <g fill="none" stroke-linecap="round" stroke-linejoin="round">
    <rect x="18" y="16" width="60" height="64" rx="10" fill="#F8FBFD" stroke="#0D1B2A" stroke-width="5"/>
```

Source lines: `brandbook/assets/logo-mark.svg:1-6`.

The ambiguity to preserve for comparison, not necessarily final use:

```xml
<path d="M48 80V58l30 22" fill="#EAF6FB" stroke="#0D1B2A" stroke-width="5"/>
<path d="M50 59l14 10" stroke="#277B96" stroke-width="4"/>
```

Source lines: `brandbook/assets/logo-mark.svg:9-10`.

**Required adaptation:** use unique option IDs such as `mg-option-a-title` and `mg-option-a-desc`; label the file as draft option evidence in title/desc.

### `brandbook/assets/options/option-b-pane-lines.svg` (SVG option sketch, static SVG visual evidence)

**Primary analog:** `brandbook/assets/logo-mark.svg`

Start from the existing pane/message-line geometry, but remove or simplify the triangular fold:

```xml
<rect x="18" y="16" width="60" height="64" rx="10" fill="#F8FBFD" stroke="#0D1B2A" stroke-width="5"/>
<path d="M28 32h40" stroke="#277B96" stroke-width="5"/>
<path d="M28 46h26" stroke="#5C6B7A" stroke-width="4"/>
<path d="M28 60h18" stroke="#5C6B7A" stroke-width="4"/>
```

Source lines: `brandbook/assets/logo-mark.svg:5-8`.

**Supporting analog:** `brandbook/examples/ui-primitives.svg`

Use flat panes, modest radius, border-first construction, restrained accent:

```xml
<rect width="320" height="180" rx="8" fill="#FFFFFF" stroke="#C7DCE5"/>
<text x="24" y="42" fill="#0D1B2A" font-family="Inter Tight, Inter, sans-serif" font-size="24" font-weight="700">Delivery timeline</text>
<text x="24" y="74" fill="#5C6B7A" font-family="Inter, sans-serif" font-size="15">One place for rendered output, provider events, and operator action.</text>
```

Source lines: `brandbook/examples/ui-primitives.svg:8-16`.

**Required adaptation:** keep it shape-only, simple, and small-size-safe. Use unique option IDs such as `mg-option-b-title` and `mg-option-b-desc`.

### `brandbook/assets/options/option-c-inspection-pane.svg` (SVG option sketch, static SVG visual evidence)

**Primary analog:** `brandbook/examples/readme-header.svg`

Use source-native SVG shape/text conventions and avoid external assets:

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="640" viewBox="0 0 1280 640" role="img" aria-labelledby="title desc">
  <title id="title">Mailglass README header specimen</title>
  <desc id="desc">A restrained README header composition for Mailglass.</desc>
  <rect width="1280" height="640" fill="#F8FBFD"/>
```

Source lines: `brandbook/examples/readme-header.svg:1-5`.

The specimen's existing mark group shows compact source-native geometry to adapt, while option C should push the pane/inspection idea instead of adding generic icon metaphors:

```xml
<g transform="translate(112 116)">
  <rect x="0" y="0" width="72" height="80" rx="12" fill="#F8FBFD" stroke="#0D1B2A" stroke-width="5"/>
  <path d="M14 21h44" stroke="#277B96" stroke-width="5" stroke-linecap="round"/>
  <path d="M14 38h30" stroke="#5C6B7A" stroke-width="4" stroke-linecap="round"/>
```

Source lines: `brandbook/examples/readme-header.svg:6-11`.

**Required adaptation:** keep the option clearly inspectable/email-oriented. Reject it in `logo-options.md` if it becomes too abstract or loses message affordance.

### `brandbook/assets/logo-primary.svg` (SVG primary lockup, static SVG with live text)

**Primary analog:** existing `brandbook/assets/logo-primary.svg`

Preserve the source lockup shape: accessible root, live SVG text, token colors, no embedded fonts:

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="420" height="112" viewBox="0 0 420 112" role="img" aria-labelledby="title desc">
  <title id="title">Mailglass primary logo</title>
  <desc id="desc">Mailglass wordmark with a pane mark that implies visible email.</desc>
```

Source lines: `brandbook/assets/logo-primary.svg:1-3`.

Live text pattern:

```xml
<text x="116" y="68" fill="#0D1B2A" font-family="Inter Tight, Inter, system-ui, -apple-system, sans-serif" font-size="46" font-weight="700" letter-spacing="0">mailglass</text>
<text x="119" y="91" fill="#5C6B7A" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="13" font-weight="400" letter-spacing="0">email, made visible</text>
```

Source lines: `brandbook/assets/logo-primary.svg:12-13`.

**Required adaptation:** change `aria-labelledby="title desc"` and repeated IDs to `aria-labelledby="mg-logo-primary-title mg-logo-primary-desc"` with matching IDs. Update the mark group to the selected/refined direction, but keep live wordmark text editable.

### `brandbook/assets/logo-mark.svg` (SVG icon-only mark, static SVG geometry)

**Primary analog:** existing `brandbook/assets/logo-mark.svg`

Use simple path geometry, source token colors, and a shape-only mark:

```xml
<g fill="none" stroke-linecap="round" stroke-linejoin="round">
  <rect x="18" y="16" width="60" height="64" rx="10" fill="#F8FBFD" stroke="#0D1B2A" stroke-width="5"/>
  <path d="M28 32h40" stroke="#277B96" stroke-width="5"/>
  <path d="M28 46h26" stroke="#5C6B7A" stroke-width="4"/>
```

Source lines: `brandbook/assets/logo-mark.svg:4-8`.

**Required adaptation:** update to selected/refined mark. Use `mg-logo-mark-title` and `mg-logo-mark-desc`; avoid text, raster, fonts, scripts, `foreignObject`, data payloads, external refs, glossy treatment, mascot logic, and unnecessary path complexity.

### `brandbook/assets/logo-monochrome.svg` (SVG monochrome mark, currentColor geometry)

**Primary analog:** existing `brandbook/assets/logo-monochrome.svg`

Preserve the simple `currentColor` construction:

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96" role="img" aria-labelledby="title desc">
  <title id="title">Mailglass monochrome mark</title>
  <desc id="desc">A single-color pane mark with an implied message fold.</desc>
  <g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">
```

Source lines: `brandbook/assets/logo-monochrome.svg:1-4`.

Current path pattern:

```xml
<rect x="18" y="16" width="60" height="64" rx="10" stroke-width="5"/>
<path d="M28 32h40" stroke-width="5"/>
<path d="M28 46h26" stroke-width="4"/>
```

Source lines: `brandbook/assets/logo-monochrome.svg:5-10`.

**Required adaptation:** use selected/refined shape and IDs `mg-logo-monochrome-title` / `mg-logo-monochrome-desc`. Keep `currentColor` unless a specific final geometry makes it impractical.

### `brandbook/assets/favicon.svg` (SVG favicon, small-size geometry)

**Primary analog:** existing `brandbook/assets/favicon.svg`

Existing small-size root and compact construction:

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32" role="img" aria-labelledby="title desc">
  <title id="title">Mailglass favicon</title>
  <desc id="desc">Compact pane mark for Mailglass.</desc>
```

Source lines: `brandbook/assets/favicon.svg:1-3`.

Risky folded-corner geometry:

```xml
<path d="M16 28v-8l11 8" fill="#EAF6FB" stroke="#0D1B2A" stroke-width="2" stroke-linejoin="round"/>
```

Source lines: `brandbook/assets/favicon.svg:7-7`.

**Risk analog:** `brandbook/brand-audit.md`

```markdown
| BRAND-GAP-05 | REWORK | 4 | Favicon / small mark | `brandbook/assets/favicon.svg` uses a compact lower triangular fold at 32x32 | The fold may read as document corner, envelope, or send-arrow ambiguity at small sizes. | Phase 82 | Phase 82 records small-size visual review and final disposition for fold ambiguity. |
```

Source lines: `brandbook/brand-audit.md:149-151`.

**Required adaptation:** use the final small-size-safe mark, review 16px and 32px, and use IDs `mg-favicon-title` / `mg-favicon-desc`.

### `brandbook/assets/social-avatar.svg` (SVG social avatar, reversed/dark composition)

**Primary analog:** existing `brandbook/assets/social-avatar.svg`

Preserve dark/reversed construction:

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512" role="img" aria-labelledby="title desc">
  <title id="title">Mailglass social avatar</title>
  <desc id="desc">Mailglass pane mark on an Ink background.</desc>
  <rect width="512" height="512" rx="96" fill="#0D1B2A"/>
```

Source lines: `brandbook/assets/social-avatar.svg:1-4`.

Dark-surface mark accent pattern:

```xml
<rect x="18" y="16" width="60" height="64" rx="10" fill="#F8FBFD" stroke="#A6EAF2" stroke-width="5"/>
<path d="M28 32h40" stroke="#277B96" stroke-width="5"/>
```

Source lines: `brandbook/assets/social-avatar.svg:6-11`.

**Supporting analog:** `brandbook/examples/palette.svg`

```xml
<rect width="520" height="116" rx="10" fill="#0D1B2A"/>
<text x="28" y="44" fill="#EAF6FB" font-family="Inter Tight, Inter, sans-serif" font-size="24" font-weight="700">Dark surface</text>
<text x="28" y="76" fill="#A6EAF2" font-family="IBM Plex Mono, ui-monospace, monospace" font-size="15">Glass shifts toward Ice on dark backgrounds.</text>
```

Source lines: `brandbook/examples/palette.svg:59-68`.

**Required adaptation:** update to the selected/refined mark and use IDs `mg-social-avatar-title` / `mg-social-avatar-desc`. Record reversed/dark-background disposition in `logo-options.md` and brandbook guidance.

### `brandbook/brand-book.md` (source brand guidance, Markdown transform)

**Primary analog:** existing `brandbook/brand-book.md`

Preserve the brand center and phase-status discipline:

```markdown
The brand center is intentionally stable per `BRAND-GAP-12`: Mailglass makes
email visible, mail you can see through, and Glass is a metaphor, not a visual
excuse.
```

Source lines: `brandbook/brand-book.md:19-21`.

Current logo section to update from draft posture to Phase 82 disposition:

```markdown
## Logo System

Mailglass is wordmark-first. The mark is secondary.

The mark should suggest a pane with an implied message fold. It should not look
like a paper plane, mailbox, chat bubble, send arrow, or glossy app icon.
```

Source lines: `brandbook/brand-book.md:129-141`.

Artifact rules to preserve:

```markdown
Prefer:

- Markdown
- HTML
- SVG
- JSON
- CSS variables
```

Source lines: `brandbook/brand-book.md:235-250`.

**Required adaptation:** cite/link the option review, record selected/refined logo direction, final disposition for primary/mark/monochrome/favicon/avatar/reversed use, and keep Phase 83 copy/specimens plus Phase 84 validation proof unclaimed.

### `brandbook/index.html` (direct-open static brandbook preview, local HTML/CSS/SVG references)

**Primary analog:** existing `brandbook/index.html`

Preserve direct-open local references:

```html
<link rel="icon" href="assets/favicon.svg" type="image/svg+xml">
<link rel="stylesheet" href="tokens.css">
```

Source lines: `brandbook/index.html:6-9`.

Preserve token-based logo preview CSS:

```css
.logo-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: var(--mg-space-md);
  align-items: stretch;
}

.logo-box {
  display: grid;
  min-height: 180px;
  place-items: center;
```

Source lines: `brandbook/index.html:253-277`.

Logo section that must change from draft status to approved Phase 82 logo-system language:

```html
<section class="section" id="logo">
  <h2>Logo System</h2>
  <p>Mailglass is wordmark-first. The mark is secondary and should suggest a pane with an implied message fold. It must not become a paper plane, mailbox, send arrow, or glossy app icon. These local SVGs are useful draft evidence until Phase 82 completes logo review.</p>
```

Source lines: `brandbook/index.html:428-435`.

**Required adaptation:** update only logo-specific status wording and asset references if needed. Keep semantic HTML, local CSS/SVG links, no scripts, and no remote assets.

### `brandbook/README.md` (brandbook directory guide, Markdown transform)

**Primary analog:** existing `brandbook/README.md`

Keep the concise artifact inventory style:

```markdown
- `index.html` - static HTML brandbook. Open directly in a browser.
- `brand-audit.md` - critical pressure test of the current brand system.
- `brand-book.md` - concise source-of-truth brand guidance.
- `tokens.json` - implementation tokens for tooling.
- `tokens.css` - CSS custom properties for docs and marketing prototypes.
- `assets/` - editable SVG logo and mark files.
- `examples/` - small SVG specimens for palette, type, UI, README/docs, and social framing.
```

Source lines: `brandbook/README.md:10-18`.

Preserve operating rules and forbidden visual logic:

```markdown
- Keep the brand self-contained in this directory unless product code needs a
  specific token or asset.
- Do not commit font binaries, large raster exports, Figma files, screenshots,
  or generated PNG batches by default.
- Prefer SVG, Markdown, JSON, CSS, and plain HTML.
- Keep Glass (`#277B96`) as an accent, not a background flood.
- Do not introduce glassmorphism, bevels, glossy reflections, mascots, paper
  planes, or marketing-email imagery.
```

Source lines: `brandbook/README.md:20-32`.

Export policy to preserve:

```markdown
Commit:

- SVG logos and specimens.
- JSON/CSS tokens.
- Markdown and HTML guidance.
```

Source lines: `brandbook/README.md:34-53`.

**Required adaptation:** add `logo-options.md` and, if created, `assets/options/` to the inventory/policy. Do not expand this into a logo pack, PNG export policy, or launch/social copy surface.

## Shared Patterns

### Unique Accessible SVG IDs

Apply to all final SVGs and option SVGs. Current assets prove the accessible metadata shape but also show the collision risk:

```xml
role="img" aria-labelledby="title desc"
<title id="title">Mailglass mark</title>
<desc id="desc">A flat pane mark with an implied message fold, representing visible email.</desc>
```

Source lines: `brandbook/assets/logo-mark.svg:1-3`.

Use these final IDs from `82-UI-SPEC.md:152-160` and `82-RESEARCH.md:167-179`:

| Asset | Title ID | Description ID |
|---|---|---|
| `logo-primary.svg` | `mg-logo-primary-title` | `mg-logo-primary-desc` |
| `logo-mark.svg` | `mg-logo-mark-title` | `mg-logo-mark-desc` |
| `logo-monochrome.svg` | `mg-logo-monochrome-title` | `mg-logo-monochrome-desc` |
| `favicon.svg` | `mg-favicon-title` | `mg-favicon-desc` |
| `social-avatar.svg` | `mg-social-avatar-title` | `mg-social-avatar-desc` |

Recommended option IDs: `mg-option-a-title`, `mg-option-a-desc`, `mg-option-b-title`, `mg-option-b-desc`, `mg-option-c-title`, `mg-option-c-desc`.

### Source-Native SVG Safety

Apply to all SVGs:

- Keep `xmlns`, `viewBox`, `role="img"`, `title`, `desc`, and `aria-labelledby`.
- Use flat `rect`, `path`, `g`, and `text` where needed.
- No raster images, embedded fonts, scripts, `foreignObject`, data/base64 payloads, external references, font-face, JS, design-tool clutter, or remote SVG sources.
- Keep primary lockup live-text; keep compact marks shape-only where practical.

### Visual Construction

Source tokens and examples establish the visual language:

```json
"ink": { "value": "#0D1B2A", "description": "Raw palette source value for primary text, dark surfaces, and code-adjacent structure" },
"glass": { "value": "#277B96", "description": "Raw palette source value for the restrained brand accent, links, focus, and selected states; not a default border or background flood" },
"ice": { "value": "#A6EAF2", "description": "Raw palette source value for bright supporting accent and dark-surface highlight" },
"mist": { "value": "#EAF6FB", "description": "Raw palette source value for subtle surfaces and quiet panes" },
"paper": { "value": "#F8FBFD", "description": "Raw palette source value for primary light background" },
"slate": { "value": "#5C6B7A", "description": "Raw palette source value for secondary text, metadata, and subdued structure" }
```

Source lines: `brandbook/tokens.json:9-23`.

CSS token names used by `index.html`:

```css
--mg-bg: var(--mg-paper);
--mg-surface-subtle: var(--mg-mist);
--mg-border: #c7dce5;
--mg-text: var(--mg-ink);
--mg-accent: var(--mg-glass);
```

Source lines: `brandbook/tokens.css:14-28`.

Admin design-system boundary reinforces flat, token-based, restrained accent behavior:

```markdown
**Accent discipline (the 10% rule):** `primary`/Glass appears only on the
selected-row border, the primary CTA, the active nav/timeline node, and focus
emphasis. It is never the default border or badge color.
```

Source lines: `mailglass_admin/docs/design-system.md:51-54`.

### Product/Admin Scope Boundary

`mailglass_admin/priv/static/mailglass-logo.svg` is an older placeholder and explicitly says a future brand-book glyph should supersede it:

```xml
<!--
  mailglass logo - v0.1 placeholder.
  Sets wordmark in Inter Tight 700 at Ink (#0D1B2A).
  Brand book section 7 will supersede with the canonical glyph in a future revision.
-->
```

Source lines: `mailglass_admin/priv/static/mailglass-logo.svg:1-6`.

Do not touch it in Phase 82. Context and research say product/admin implementation code is out of scope.

### Validation Patterns For Planner

Use source assertions and parse checks during execution, but do not add committed validation scripts in Phase 82:

```bash
git diff --check -- brandbook/logo-options.md brandbook/brand-book.md brandbook/index.html brandbook/README.md brandbook/assets
xmllint --noout brandbook/assets/*.svg brandbook/assets/options/*.svg
rg -n 'BRAND-GAP-04|BRAND-GAP-05|BRAND-GAP-06|Selected direction|16px|32px|currentColor|reversed|unique ID' brandbook/logo-options.md brandbook/brand-book.md brandbook/index.html brandbook/README.md
! rg -n '<script|<image|foreignObject|data:|base64|(^|[[:space:]<])(?:xlink:href|href|src)\s*=\s*(?:"|\x27)https?://|url\(\s*(?:"|\x27)?https?://|@font-face|font-face' brandbook/assets/*.svg brandbook/assets/options/*.svg
! rg -n 'paper plane|chat bubble|mailbox-on-post|send arrow|mascot|glossy' brandbook/assets/*.svg brandbook/assets/options/*.svg
```

Source lines: `82-RESEARCH.md:261-268`.

## Anti-Patterns

- Treating the current folded pane as approved without comparing alternatives.
- Creating a prose-only option review with no SVG visual evidence.
- Adding detail to fix favicon ambiguity instead of simplifying the mark.
- Leaving repeated `id="title"` and `id="desc"` across inlineable SVG assets.
- Adding raster exports, PNG packs, font binaries, PDFs, Figma/vendor files, screenshots, remote assets, scripts, or build tools.
- Editing product/admin implementation code, package allowlists, root README, Hex/HexDocs copy, public APIs, release workflow, or validation scripts.
- Replacing the admin placeholder logo in Phase 82.
- Introducing paper planes, mailbox-on-post imagery, chat bubbles, send arrows, glossy app-icon treatment, mascot logic, glassmorphism, bevels, decorative gradients, blobs, or unnecessary path complexity.

## No Analog Found

No target is completely unsupported by local patterns. The only missing exact structure is `brandbook/assets/options/`, which should copy the existing SVG asset/specimen conventions rather than introduce a new asset pipeline.

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `brandbook/assets/options/*.svg` | SVG option sketches | static SVG visual evidence | No existing options directory exists, but `brandbook/assets/*.svg` and `brandbook/examples/*.svg` are strong source-native analogs. |

## Recommended Plan Shape

One plan is sufficient if it contains explicit tasks for:

1. Add `brandbook/logo-options.md` and option SVG evidence, compare directions, and record final selected/refined direction.
2. Update five final SVG assets with selected/refined mark, unique accessible IDs, source-native safety, and small-size/reversed/currentColor dispositions.
3. Update logo-specific wording in `brandbook/brand-book.md`, `brandbook/index.html`, and `brandbook/README.md`.
4. Run parse, grep, diff, and out-of-scope boundary checks.

If the planner splits work, keep review/selection before final asset edits so `LOGO-02` remains auditable.

## Metadata

**Analog search scope:** `brandbook/`, `brandbook/assets/`, `brandbook/examples/`, `mailglass_admin/docs/design-system.md`, `mailglass_admin/priv/static/mailglass-logo.svg`, Phase 80-82 planning artifacts.
**Files scanned:** 20 source/planning files plus phase inputs.
**Pattern extraction date:** 2026-06-06.
