---
phase: "183"
slug: "docs-packaging-and-launch-prep"
status: draft
shadcn_initialized: false
preset: none
created: "2026-11-16"
---

# Phase 183 — UI Design Contract

> Visual contract for the static README, HexDocs, and brand-asset surfaces in this phase. No application dashboard or interaction is added.

## Design System

| Property | Value |
|----------|-------|
| Tool | Repo-owned brand v2 tokens; existing Phoenix.Component, Tailwind v4 and vendored daisyUI remain in place. No shadcn setup or UI dependency. |
| Preset | Not applicable |
| Component library | Existing hand-authored Phoenix components; none added for this phase |
| Icon library | Existing vendored Heroicons for Admin only; no icons added to docs |
| Font | README follows its renderer. Brand-authored docs use Funnel Display, Atkinson Hyperlegible Next and Mono. ExDoc remains on its built-in Lato face and theme toggle. |

`brandbook/v2/brand.json` and `brandbook/tokens.json` are the brand authorities. Do not use retired v1 `brandbook/brand-book.md` values. README and ExDoc renderer chrome stay renderer-owned; this phase adds no typography or general layout CSS.

## Component Inventory

Could not enumerate: this phase adds no UI components or component package; the app's reusable components are hand-authored Phoenix functions in `mailglass_admin/lib/mailglass_admin/components.ex`.

This is a non-exhaustive list of existing known-good patterns, not an allowlist.

| Component | Import path | Notes |
|-----------|-------------|-------|
| `logo/1` | `MailglassAdmin.Components.logo/1` | Existing inline SVG follows the Admin's explicit theme tokens. It is not the README or ExDoc asset. |

## Spacing Scale

Use the existing Admin 4px-grid scale: 4, 8, 16, 24, 32, 48 and 64px. README and ExDoc layout spacing remains renderer-owned; add no layout CSS. Keep logo proportions and clear space from the brand spec. Favicon captures use the required 16, 24 and 32px sizes.

Exceptions: 96px minimum on-screen typemark width; favicon capture sizes 16/24/32px are fixed media dimensions, not spacing tokens.

## Typography

Brand-authored design guidance uses exactly four sizes and two weights. External rendered docs keep their native styles; in particular, ExDoc retains Lato and receives no font-size or weight override.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | 400 | 1.55 |
| Code | 13px | 400 | 1.5 |
| Heading | 28px | 600 | 1.2 |
| Display | 56px | 600 | 1.05 |

Sources: `brandbook/v2/brand.json` type hierarchy. ExDoc's bundled Lato 400/700 is a locked renderer exception from CONTEXT D-04.

## Color

The 60/30/10 roles apply to standalone brand artwork. Host-provided README/ExDoc surfaces and ExDoc links remain controlled by their renderers.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Light `#F6F1E8`; dark `#1D1713` | Brand artwork ground only; do not add a tile behind lockups. |
| Secondary (30%) | Light `#FFFFFF`; dark `#2A211B` | Existing raised surfaces where a brand asset needs them; no new doc chrome. |
| Accent (10%) | Light logo glass `#1895C2` / overlap `#0A6488`; dark glass `#46B6E8` / overlap `#A8E4F7` | Preserve the pinned logo/favicon artwork. ExDoc code-token colors are limited to syntax blocks. |
| Destructive | None | There are no destructive UI actions in this phase. |

Accent reserved for: the v2 logo and favicon artwork, and ExDoc syntax spans in code blocks. Do not add accent controls or decorative surfaces; leave README and ExDoc link styling to each renderer. The logo stays on the matching light/dark artwork and is never inverted or recolored.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | None; this phase adds static documentation and assets, not an interactive flow. |
| Empty state heading | Not applicable; no data collection or empty view. |
| Empty state body | Not applicable. |
| Error state | A missing, unreadable or pin-mismatched asset fails validation. In rendered README, keep `alt="mailglass"` so the name remains available if an image fails. |
| Destructive confirmation | None; no destructive UI action. |

README header contract: the H1 and both lockup alt values are lowercase `mailglass`; keep the tagline `See your email before it ships. Trace it after.` outside the artwork. Do not add a ™/® claim or present the blocked announcement draft as publishable.

## Surface and Asset Contract

| Surface | Required treatment |
|---------|--------------------|
| GitHub / Hex.pm README | Use separate light and dark lockup `<img>` elements with `#gh-light-mode-only` and `#gh-dark-mode-only`. Use absolute `raw.githubusercontent.com/szTheory/mailglass/...` URLs pinned to asset commit `7781b4b1ceeca940e5f892530b1cf05430b54d7c`; check the referenced bytes against the brand pin. The asset ref becomes reachable when its task-scoped commit is pushed; do not create or push a remote tag. Do not use `<picture>`: Hex.pm strips it and would leave the wrong variant in its dark theme. Keep typemark clear space at one quarter of its height and width at least 96px. |
| ExDoc / HexDocs | Use the v2 mark's matching light/dark variants plus favicon in core, admin and inbound docs. ExDoc's own class-driven light/dark switch selects the logo and theme; do not key it to the OS. Custom CSS may set syntax colors only: no `prefers-color-scheme`, no body font change, and no link or layout restyle. |
| Admin favicon capture | Keep the `/favicon.svg` route and v2 SVG. Capture light and dark at 16, 24 and 32px in Chromium, Firefox and WebKit. Bind each unique catalog to the favicon SHA and recompute legibility metrics from captured PNG bytes. Cross-engine byte-identical screenshots are not required. Real Safari tab-chrome appearance remains unobserved and is not an acceptance gate. |
| Package assets | Ship only declared brand assets and license texts through the brand-pin extension flow. Do not ship the full `brandbook/` tree or v1 social-avatar assets. |

No logo animation or sound. Social-preview instructions are repository-scoped and include a read-back check; do not upload assets, edit personal avatars, publish, release or announce in this phase.

## UI Considerations

Applicable state considerations resolved: 6 applicable, 6 explicitly resolved, 0 backstop, 0 unresolved, 0 unclassified (UI-consideration probe).

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| Empty | README/ExDoc logo, favicon | Resolved (explicit) | These are required static media; a missing or unreadable asset fails validation. README retains lowercase `mailglass` alt text. |
| Loading | README/ExDoc logo, favicon capture | Resolved (explicit) | Add no custom loader. Browser capture waits for image decode before saving evidence. |
| Error | README/ExDoc logo, favicon | Resolved (explicit) | Missing, undecodable or pin-mismatched bytes fail validation; README exposes the lowercase `mailglass` alt text. |
| Populated | README/ExDoc logo, favicon | Resolved (explicit) | Render the theme-matched lockup; ExDoc follows its own class-driven theme toggle. Captures cover both themes and required favicon sizes. |
| Long text | README heading and tagline | Resolved (explicit) | Keep one lowercase H1; the separate tagline may wrap as renderer text. Do not stretch, crop or truncate the lockup. |
| Overflow | README lockup and tagline | Resolved (explicit) | Constrain the lockup to available content width while preserving its ratio; keep the typemark at least 96px wide and allow the tagline to wrap without horizontal scrolling. |

Lists, forms, navigation, partial data and zero/one/many states are not present in this static-docs phase.

## Registry Safety

No shadcn initialization, third-party registry, block, or UI dependency is used.

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [ ] Dimension 7 Inventory Provenance: FLAG — inventory is intentionally non-exhaustive; no new UI components are added.

**Approval:** approved with one non-blocking inventory provenance flag; planning may proceed.
