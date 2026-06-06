# Phase 81: Brandbook Source and Token System - Pattern Map

**Mapped:** 2026-06-06
**Files analyzed:** 4 implementation targets
**Analogs found:** 4 / 4 targets, with Phase 80 audit and admin design-system as constraints

## File Extraction

Phase 81 modifies exactly these files:

- `brandbook/brand-book.md`
- `brandbook/tokens.json`
- `brandbook/tokens.css`
- `brandbook/index.html`

This comes from `81-CONTEXT.md` decisions D-01 and D-02. Logo assets,
specimens, README/package/docs copy, repo-hygiene scripts, product UI code,
public APIs, and release workflow are read-only for this phase.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `brandbook/brand-book.md` | source brand guidance | Markdown source-of-truth text | `brandbook/brand-audit.md` Phase 81 handoff plus existing `brand-book.md` | exact target, strong constraint analog |
| `brandbook/tokens.json` | structured token source | JSON role/value metadata | existing `tokens.json` plus `mailglass_admin/docs/design-system.md` token-layer rules | exact target, strong product-boundary analog |
| `brandbook/tokens.css` | direct-open token CSS | CSS custom properties consumed by static HTML | existing `tokens.css` plus admin `:root`/semantic-token discipline | exact target, medium analog |
| `brandbook/index.html` | direct-open static brandbook preview | local HTML/CSS/SVG file references | existing `index.html` plus Phase 80 draft-input posture | exact target, strong source-native analog |

## Read-Only References

| Reference File | Use In Phase 81 | Warning |
|---|---|---|
| `brandbook/brand-audit.md` | Source of `BRAND-GAP-01`, `BRAND-GAP-08`, `BRAND-GAP-12` and Phase 81 handoff | Do not edit or renumber audit rows. |
| `brandbook/assets/*.svg` | Draft display evidence used by `index.html` | Do not revise logo assets in Phase 81. |
| `brandbook/examples/*.svg` | Draft specimen evidence used by `index.html` | Do not revise specimen assets in Phase 81. |
| `brandbook/README.md` | Directory artifact policy evidence | Do not change repo-hygiene docs before Phase 84. |
| `mailglass_admin/docs/design-system.md` | Implemented admin UI constraint source | Do not fork product UI mechanics or require direct consumption of brandbook CSS. |

## Pattern Assignments

### `brandbook/brand-book.md`

Current strengths:

- Contains the concept: `Core idea: **Mailglass makes email visible.**`
- Contains the principle: `Glass is a metaphor, not a visual excuse.`
- Already rejects outbound sales, generic AI tools, paper-plane clones, and glassmorphism.
- Already says to use semantic tokens over raw hex and to keep focus rings obvious.

Required hardening:

- Add Phase 80 status language: existing `brandbook/` artifacts are draft inputs, not approved final v1.8 outputs.
- Cite `BRAND-GAP-01`, `BRAND-GAP-08`, and `BRAND-GAP-12` as source guidance anchors.
- Add a clearer product/admin boundary: `mailglass_admin/docs/design-system.md` governs implemented admin UI mechanics; this brandbook guides source brand, docs, collateral, and lightweight examples.
- Add text-vs-non-text callout/state guidance, including the info callout/background caution from `BRAND-GAP-08`.
- Preserve the current voice and positioning without broad rewrite.

### `brandbook/tokens.json`

Current strengths:

- Has `$schema`, `meta`, `palette`, `color.light`, `color.dark`, `color.state`, `color.callout`, `color.code`, `typography`, `space`, `radius`, `border`, `shadow`, `focus`, and `motion`.
- `meta.notes` already says product admin UI may map these into its own Tailwind/daisyUI layer.
- Glass, Ice, Ink, Mist, Paper, Slate, Pine, Amber, and Crimson values already match the brand direction.

Required hardening:

- Strengthen `meta.notes` so product admin UI does not directly consume `brandbook/tokens.css` by default.
- Add descriptions or comments-by-description for raw palette versus semantic roles.
- Add callout/state descriptions that separate text color usage from border/background/non-text usage.
- Ensure descriptions do not claim Phase 84 contrast validation is already complete.

### `brandbook/tokens.css`

Current strengths:

- Exposes practical `--mg-*` custom properties for palette, semantic surfaces, state, callout, code, typography, spacing, radius, border, shadow, focus, and motion.
- Has `[data-theme="dark"]` overrides.
- Has `.mg-focusable:focus-visible`.
- Has `prefers-reduced-motion: reduce` duration collapse.

Required hardening:

- Keep CSS aligned with JSON role names and HTML usage.
- If the plan adds CSS comments, they should clarify role usage without becoming a second framework.
- Avoid external imports, font-face declarations, preprocessors, and new build requirements.

### `brandbook/index.html`

Current strengths:

- Opens directly from disk.
- Uses local `tokens.css`, local favicon, local logo assets, and local specimen links.
- Provides a compact source browser for concept, color, type, tokens, logo, voice, surfaces, artifacts, and QA.

Required hardening:

- Add copy that states current logos/specimens are draft evidence until Phase 82/83.
- Add copy that the brand center is approved and preserved by `BRAND-GAP-12`.
- Add token/admin-boundary language aligned with `mailglass_admin/docs/design-system.md`.
- Keep all references local and script-free.

## Required Source Assertions

The final plans should make these assertions checkable:

- `brandbook/brand-book.md` contains `BRAND-GAP-01`, `BRAND-GAP-08`, `BRAND-GAP-12`.
- `brandbook/brand-book.md` contains `Mailglass makes email visible` and `glass is a metaphor, not a visual excuse`.
- `brandbook/brand-book.md` names `mailglass_admin/docs/design-system.md` and says it remains the implemented product UI source of truth.
- `brandbook/tokens.json` parses with `jq -e .`.
- `brandbook/tokens.json` contains descriptions for semantic roles and text/non-text callout usage.
- `brandbook/tokens.css` contains required role groups and `prefers-reduced-motion`.
- `brandbook/index.html` contains draft-status language and has no `http://`, `https://`, `<script`, or `cdn`.
- Out-of-scope paths remain unchanged.

## Anti-Patterns

- Replacing the source brandbook from scratch and losing the existing voice.
- Writing token guidance that encourages raw hex use in implementation.
- Treating `state.info` on `callout.infoBackground` as approved normal text.
- Turning brandbook tokens into the product admin UI framework.
- Editing logo SVGs, specimens, README, package files, or product UI code.
- Adding Node, a build step, browser automation, screenshots, or contrast scripts.

## Recommended Plan Shape

One implementation plan is sufficient if it has explicit tasks for:

1. Source brandbook posture and brand center.
2. Token JSON/CSS semantic-role and callout/state guidance.
3. Static HTML status and local-reference hardening.
4. Verification and boundary checks.

If the planner chooses two plans, split Markdown/HTML source copy from JSON/CSS
token artifacts. Both plans must carry the same phase boundary and
admin-design-system constraints.
