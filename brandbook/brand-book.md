# Mailglass Brand Book

Mailglass is a Phoenix-native email framework for people who want email to feel
like real application infrastructure: inspectable, composable, previewable,
testable, and calm.

Core idea: **Mailglass makes email visible.**

Not louder. Not shinier. Clearer.

## Source Status

Phase 80 treats the current `brandbook/` files as draft inputs from commit
`572f3eb2`, not approved final Phase 81-84 outputs. This source book closes the
Phase 81 source-language part of `BRAND-GAP-01` by preserving what is already
strong, removing overclaims, and leaving final logo, specimen, copy, and proof
work to their assigned phases.

The brand center is intentionally stable per `BRAND-GAP-12`: Mailglass makes
email visible, mail you can see through, and Glass is a metaphor, not a visual
excuse.

## Brand In One Breath

Mailglass turns email from a black box into a visible system.

- Category: open-source Phoenix email framework
- Audience: senior Phoenix and Elixir teams
- Promise: compose, preview, deliver, route, and observe email with confidence
- Mood: clear, technical, humane, composed
- Not: salesy, growth-hacky, ESP-ish, "AI magic"

## Brand DNA

- Brand essence: mail you can see through
- Audience: pragmatic backend/frontend engineers building production email
- Emotional tone: calm under pressure
- Technical promise: email workflows become inspectable application flows
- Visual metaphor: clarity through panes
- Personality: exact, warm, modern, quiet, useful
- Anti-traits: flashy, cute, generic, glossy, corporate, growth-marketing-coded

This should feel like:

- a well-lit workbench
- a mail console
- a composed admin panel
- a system you can inspect before it hurts users

This should never feel like:

- an outbound-sales platform
- a neon analytics dashboard
- a generic AI tool
- a paper-plane mailer clone
- a glassmorphism theme pack

## Positioning

Primary line:

> The clear email framework for Phoenix.

Short description:

> Mailglass is a Phoenix-native framework for composing, previewing, delivering,
> routing, and observing email.

README opening:

> Mailglass brings structure and visibility to email in Elixir apps: typed
> mailables, component-based templates, previews, delivery workflows, inbound
> routing, normalized events, and operator-friendly feedback.

## Brand Principles

1. Clarity beats cleverness.
2. Visibility beats magic.
3. Calm beats hype.
4. Precision beats ornament.
5. Glass is a metaphor, not a visual excuse.

## Visual Principles

- Use panes, boundaries, layers, timelines, headers, and inspection surfaces.
- Use translucency sparingly and only where it helps explain layering.
- Prefer flat color, strong type, restrained borders, and clear hierarchy.
- Keep surfaces readable before they are atmospheric.
- Avoid decorative gradients, blobs, lens flares, bevels, chrome, and fake depth.

## Color

Raw palette:

- Ink: `#0D1B2A`
- Glass: `#277B96`
- Ice: `#A6EAF2`
- Mist: `#EAF6FB`
- Paper: `#F8FBFD`
- Slate: `#5C6B7A`
- Signal Amber: `#A95F10`
- Error Crimson: `#B42318`
- Success Pine: `#166534`

Usage:

- Ink + Paper is the default reading pair.
- Glass is the brand accent, not the default background.
- Mist creates quiet surface depth.
- Ice is strongest on dark surfaces or as a subtle structural accent.
- Semantic colors are for state, not decoration.

## Typography

Recommended stack:

- Display: Inter Tight
- UI/body: Inter
- Code/CLI/tokens: IBM Plex Mono

Rules:

- Use sentence case.
- Keep body copy roomy and readable.
- Use mono for code, RFCs, env vars, statuses, adapters, and structured values.
- Avoid oversized consumer-SaaS hero type.
- Avoid tight tracking.

## Logo System

Mailglass is wordmark-first. The mark is secondary.

The mark should suggest a pane with an implied message fold. It should not look
like a paper plane, mailbox, chat bubble, send arrow, or glossy app icon.

Use:

- primary lockup for README, landing pages, docs, and social cards
- mark for favicon, avatar, compact badges, and small UI surfaces
- monochrome mark for stamps, stickers, print, and single-color contexts

## UI Guidance

The brandbook must produce buildable UI, not mood boards.

Core components to keep aligned:

- buttons
- links
- cards
- alerts
- badges
- tabs
- code blocks
- terminal blocks
- feature grids
- comparison rows
- install snippets
- diagrams
- empty/error/success states

Component rules:

- use semantic tokens over raw hex
- treat raw palette values as source values; implementation examples should use
  semantic roles for background, surface, border, text, link, focus, state,
  callout, and code
- never rely on color alone for state
- per `BRAND-GAP-08`, state and callout colors must distinguish text use from
  non-text, border, and background use; do not promote a border/background pair
  into normal body text until contrast validation proves it
- keep focus rings obvious
- keep borders flat
- reserve shadows for overlays
- keep motion under 300ms and reduced-motion friendly

## Product UI Boundary

`mailglass_admin/docs/design-system.md` remains the implemented product UI
source of truth for the admin surface. This brandbook guides source brand,
docs, collateral, lightweight examples, and deliberate future mapping, but it
does not replace the admin Tailwind/daisyUI mechanics and is not a second admin
UI framework.

If product UI later needs these brand tokens, map them intentionally into the
existing admin token layers. Do not require `brandbook/tokens.css` to be
consumed directly by `mailglass_admin`.

## Voice

Mailglass speaks like a thoughtful maintainer.

Use:

- exact nouns
- strong verbs
- short sentences
- direct recovery guidance
- technical specifics

Avoid:

- "10x"
- "supercharge"
- "next-generation"
- "effortless magic"
- "crush your KPIs"
- "AI-powered everything"

Examples:

- Say: "Render a real message before you send it."
- Not: "Experience the full rendering lifecycle."
- Say: "Delivery blocked: recipient is on the suppression list."
- Not: "Oops! Something went wrong."

## Microcopy

Error:

> Delivery blocked: recipient is on the suppression list.

Empty:

> No deliveries match this filter.

Success:

> Preview rendered with realistic props.

Warning:

> This route matched, but the mailbox rejected the message.

## Artifact Rules

Prefer:

- Markdown
- HTML
- SVG
- JSON
- CSS variables

Avoid:

- large raster sets
- embedded fonts
- vendor design files
- generated screenshots without a concrete release purpose

## Trademark Note

The historical brand book noted a public email-related product named Mailglass
Lite. This brand system is creative direction, not trademark clearance. Human
legal review is required before major launch investment.
