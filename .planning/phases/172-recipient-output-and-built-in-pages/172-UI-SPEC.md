---
phase: "172"
slug: "recipient-output-and-built-in-pages"
status: draft
shadcn_initialized: false
preset: none
created: "2026-10-09"
---

# Phase 172 — UI Design Contract

> Visual and interaction contract for the public transactional email components and the built-in recipient-facing unsubscribe pages. These are separate surfaces: a browser render demonstrates generated markup only and does not establish rendering behavior in a delivered email client.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — existing Mailglass design system; no shadcn |
| Preset | Not applicable |
| Component library | Phoenix.Component / HEEx for email output and server-rendered pages |
| Icon library | None required; use existing Mailglass logo asset only where useful |
| Font | Email: Arial, Helvetica, sans-serif fallback; browser page: existing Mailglass UI stack (Inter, system-ui, sans-serif) |

Preserve the existing `Mailglass.Components` API, HEEx escaping, inline styles/CSS-inliner, presentation-table semantics, MSO conditional/VML paths, and HTML fallbacks. Do not add a dependency or introduce browser JavaScript. The email component surface is authored email content; it has no browser loading, hover, or focus state. The unsubscribe surface is a lightweight, server-rendered HTML document and must not grow into a form or preference center.

**Primary visual anchor:** In email output, the message heading and its live body copy establish the reading hierarchy; the specific CTA is the only primary action and receives the restrained accent treatment. On unsubscribe pages, the single state heading and its recovery paragraph form the focal content. Use no decorative image or extra panel to compete with either message.

---

## Component Inventory

Enumerated by `node -e 'const fs=require("fs");const s=fs.readFileSync("lib/mailglass/components.ex","utf8");const names=[...new Set([...s.matchAll(/^  def ([a-z_]+)\(assigns\) do$/gm)].map(m=>m[1]))];const v=fs.readFileSync("mix.exs","utf8").match(/@version "([^"]+)"/);console.log(names.length+" "+names.join(", ")+" mailglass@"+v[1])'` — 11 components — `mailglass@2.6.0` — 2026-10-09.

This is a non-exhaustive inventory of first-party public HEEx components, not a closed allowlist. The unsubscribe page uses the existing embedded HEEx template path rather than a component library.

| Component | Import path | Notes |
|-----------|-------------|-------|
| `container/1` | `Mailglass.Components` | Fluid 100% presentation-table wrapper with a 600px maximum-width inner table. |
| `section/1` | `Mailglass.Components` | Full-width section and padded cell; use 4px-grid padding values. |
| `row/1`, `column/1` | `Mailglass.Components` | Existing responsive columns and surgical MSO ghost-table fallback; preserve both paths. |
| `heading/1`, `text/1` | `Mailglass.Components` | Semantic, live text with established theme-aware inline styles and plaintext markers. |
| `button/1`, `link/1` | `Mailglass.Components` | Keep meaningful action labels; preserve VML plus HTML fallback for buttons and useful label-plus-destination plaintext. |
| `img/1` | `Mailglass.Components` | Provide meaningful alt text for informative imagery; content must remain understandable if the image is absent. |
| `hr/1`, `preheader/1` | `Mailglass.Components` | Use only when useful to content hierarchy; preheader remains hidden from the message body/plaintext. |

---

## Spacing Scale

Use the inherited 4px grid for HTML email and browser-page spacing.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline alignment and compact icon/text gaps |
| sm | 8px | Related inline content |
| md | 16px | Body rhythm and narrow-screen page padding |
| lg | 24px | Email section padding and browser-page padding |
| xl | 32px | Major content grouping |
| 2xl | 48px | Large breaks where the content needs them |
| 3xl | 64px | Page-level breathing room on wide viewports |

Exceptions: none. Email width remains fluid with a 600px table fallback; do not use fixed heights around variable text. A real email button keeps a minimum 44px action area where the existing button/VML contract permits. Inline prose links remain inline. The built-in pages render no interactive controls, so no hit target is introduced.

---

## Typography

Use exactly the inherited 400 and 700 weights and a 14/16/20/28px scale. Email font declarations must be inline and degrade to the safe stack; never depend on a downloaded font.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Supporting label | 14px | 400 | 1.4 |
| Body | 16px | 400 | 1.5 |
| Email heading | 20px | 700 | 1.2 |
| Page title / display | 28px | 700 | 1.2 |

Use 16px as the minimum running text size. Allow user/browser text scaling and natural wrapping. Use heading levels in document order; don't fake a heading with only font styling.

---

## Color

The 60/30/10 split is an approximate surface-area guide for the browser page and email layout. Email styles use explicit inline hex values, not CSS custom properties.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `Paper #F8FBFD` / email content `#FFFFFF` | Light ground and primary reading surface; remain consistent with brandbook transactional email rules. |
| Secondary (30%) | `Mist #EAF6FB` | Restrained section/support surface and email fallback areas, not a competing content panel. |
| Accent (10%) | `Glass #277B96`; body-size link text `accent-text #1D637A` | Reserve Glass for the primary email CTA fill and small brand accents; use the AA-safe accent-text for readable links. |
| Destructive | `#B42318` | Invalid/expired status cue only, paired with explicit state text; this phase adds no destructive control. |

Accent reserved for: the public email action button fill and small existing Mailglass brand accents. Links use `#1D637A` on light surfaces. Do not use accent as a general background wash or rely on color to distinguish content/state. Keep text/background combinations at WCAG AA contrast or better. The recipient pages use the established light token values and do not add a theme control or dark-mode claim.

---

## Copywriting Contract

Use Mailglass's calm, exact voice. State facts in present tense, distinguish the result of a GET from a completed unsubscribe, and don't promise client rendering outcomes. Preserve named sender and scenario copy; use descriptive action/link labels rather than generic “Click here.”

| Element | Copy |
|---------|------|
| Primary email CTA | Use the scenario's specific verb + noun (for example, `View invoice`); no generic CTA. |
| Empty state heading | Not applicable — both surfaces are a single rendered message/page, not a data collection. Missing images receive meaningful alt/fallback content rather than an empty-state panel. |
| Empty state body | Not applicable — preserve the message's essential text and action when images are unavailable. |
| Valid unsubscribe page | Heading: `Unsubscribe`. Body: `You have not been unsubscribed. Visiting this page does not change your subscription.` Follow with: `To unsubscribe, use your mail app's unsubscribe control when available, or contact the sender using the details in the message.` If the valid page identifies the recipient, HTML-escape the dynamic recipient value. |
| Invalid link page (404) | Heading: `This unsubscribe link is not valid.` Body: `Check the message for a current link, or contact the sender using the details in the message.` Do not include token or recipient data. |
| Expired link page (410) | Heading: `This unsubscribe link has expired.` Body: `Use your mail app's unsubscribe control when available, or contact the sender using the details in the message.` Do not include token or recipient data. |
| Destructive confirmation | None — the valid GET page has no submit action; the existing protocol POST is not a rendered browser interaction and its behavior stays unchanged. |

---

## Interaction and Responsive Contract

- **Email surface:** Preserve ordinary live HTML text and descriptive link purpose. Use fluid email-safe table widths and inline styles, with the existing 600px width fallback. Keep content readable when images and enhanced CSS are unavailable. Avoid fixed-height text regions. Preserve table `role="presentation"`, existing HEEx escaping, CSS-inliner behavior, and surgical MSO/VML and HTML fallback markup.
- **Plaintext companion:** Keep heading/paragraph order and essential action context. Every meaningful link retains a readable label and destination exactly once, including nested or unmarked anchors; buttons retain their existing useful label-plus-URL meaning. Do not change caller-supplied `text_body` replacement semantics in this phase.
- **Browser page surface:** Render one semantic document with `lang`, UTF-8, viewport metadata, one descriptive `<h1>`, and readable paragraphs. Use a centered content column no wider than 36rem, 24px wide-screen outer padding and 16px at narrow widths. At 320 CSS px and 200% zoom, text wraps without page-level horizontal scrolling. Keep the valid, invalid (404), and expired (410) messages visually and textually distinct. Keep the valid GET informational and non-mutating; do not add forms, buttons, preference controls, or unsupported completion claims.
- **Accessibility and privacy:** Keep explicit state text understandable without color or imagery. Preserve meaningful image alternatives and descriptive link names. Escape dynamic recipient text on valid pages. Invalid/expired pages expose no recipient, token, or other delivery-specific data. Since these pages render no controls, no keyboard-focus styling or 44px control is required; any later rendered link/control must gain a visible keyboard focus and at least a 44×44px target.
- **Evidence boundary:** HTML component output, plaintext output, and browser rendering establish Mailglass renderer/page behavior only. They do not prove rendering in Gmail, Outlook, Apple Mail, image-disabled states, or email-client dark modes.

---

## UI Considerations

The deterministic state probe found **13 applicable considerations**: 11 resolved explicitly, 2 dismissed with reasons, 0 backstop, and 0 unresolved. Email-client loading/blocking behavior belongs to recipient clients; the resolved rows cover Mailglass output and server-rendered page behavior.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| overflow | Email body | ✅ resolved | At 320 CSS px and 200% zoom in the browser render, fluid content remains reachable without page-level horizontal overflow or fixed-height text clipping. This does not certify inbox-client behavior. |
| long-text | Email body | ✅ resolved | Long and non-ASCII copy remains complete live text; use natural height and wrapping without truncating essential content. |
| loading | Email CTA and inline links | dismissed | These are static email links. Loading/navigation state belongs to the recipient's email client or browser; Mailglass adds no client-side request state. |
| error | Email CTA and inline links | dismissed | Link failure or navigation errors belong to the recipient's email client or browser; no submit/retry UI is in this phase. |
| long-text | Email CTA and inline links | ✅ resolved | Use concise descriptive labels; inline labels may wrap without truncation, and meaningful destinations remain in the HTML link and generated plaintext exactly once. |
| empty | Email images | ✅ resolved | Informative images have purpose-based alternatives and adjacent essential copy; decorative images use an empty alternative. The action and message remain understandable when images are unavailable. |
| loading | Email images | dismissed | Image fetch/loading behavior is controlled by the recipient client and is not observable or controllable in Mailglass's generated markup. |
| error | Email images | dismissed | Image blocking/fetch failure is controlled by the recipient client; the supported contract is meaningful alternatives and live text, not client image-state UI. |
| populated | Email images | ✅ resolved | When an image is displayed it supplements the live message; its essential purpose is available through its alternative text and nearby copy. |
| overflow | Generated plaintext | ✅ resolved | The complete text output remains available in order; browser output wraps for reading without hiding or truncating content. |
| long-text | Generated plaintext | ✅ resolved | Long/non-ASCII content and meaningful link destinations are retained; each actionable destination appears once with a readable label. |
| overflow | Unsubscribe page | ✅ resolved | At 320 CSS px and 200% zoom, page copy wraps inside the centered content column without clipping or page-level horizontal scrolling. |
| long-text | Unsubscribe page | ✅ resolved | Long or non-ASCII dynamic recipient text remains escaped and wraps; invalid/expired pages contain no recipient or token values. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | None | Not applicable — no shadcn or third-party registry; use existing first-party HEEx components. |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS
- [ ] Dimension 7 Inventory Provenance: PASS

**Approval:** pending
