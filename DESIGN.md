---
name: "mailglass"
description: "See your email before it ships. Trace it after."
colors:
  background: "#F6F1E8"
  surface: "#FFFFFF"
  text: "#2A1D17"
  text-muted: "#665850"
  accent: "#0A6488"
  border: "#DDD3C4"
  status-delivered: "#1D6B3C"
  status-delayed: "#855300"
  status-failed: "#B3261E"
  logo-glass: "#1895C2"
typography:
  display:
    fontFamily: "'Funnel Display', 'Arial Narrow', system-ui, sans-serif"
    fontSize: "36px"
    fontWeight: 600
  body:
    fontFamily: "'Atkinson Hyperlegible Next', system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "16px"
    fontWeight: 400
  mono:
    fontFamily: "'Atkinson Hyperlegible Mono', ui-monospace, 'SF Mono', Consolas, monospace"
    fontSize: "14px"
    fontWeight: 400
rounded:
  sm: "4px"
  md: "8px"
  lg: "12px"
  full: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "40px"
  2xl: "64px"
components:
  status-delivered:
    textColor: "{colors.status-delivered}"
    size: "20px"
  status-delayed:
    textColor: "{colors.status-delayed}"
    size: "20px"
---

> **Pending owner sign-off:** the palette, type, tagline and mark wait for owner sign-off where `CLAUDE.md` or `PRODUCT.md` still differ. Follow `brandbook/v2/brand.json` and `brandbook/tokens.json`; review the paired drafts at `.planning/research/brand-v2-adoption/owner-signoff/SIGNOFF.md`.

## Overview

**Two Panes, One Email.** The two panes let you see the email before it ships and inspect its delivery record after. The tagline stays beside the mark, not inside it.

`brandbook/v2/brand.json` defines identity and voice. `brandbook/tokens.json` defines the resolved design tokens. The typemark is the logo: its first letter is drawn as two overlapping panes of glass.

## Colors

The light palette pairs Sand and White surfaces with Espresso text. Deep Glass is the interface accent; Sand Line marks dividers. The dark palette pairs Roast and Roast Surface with Bone text, Bright Glass accents and Roast Line dividers. Muted Espresso and Muted Bone carry secondary text.

**Accent discipline:** reserve Deep Glass and Bright Glass for links, focus, active navigation and the primary action. Logo Glass is artwork only, never text, links or controls. Status colors support the status word and never replace it.

## Typography

Use Funnel Display at weight 600 for headings and page titles; never use it for identifiers, addresses or code. Use Atkinson Hyperlegible Next at weights 400 and 600 for body and interface text. Use Atkinson Hyperlegible Mono for identifiers, addresses, headers, commands and code. Write “to” instead of arrow glyphs.

## Layout

Use the existing 4px spacing grid and design for narrow screens first. Keep interactive targets at least 44px high. The full typemark stays at least 96px wide, with clear space equal to one quarter of its height on every side.

## Elevation & Depth

Use borders and surface color to establish hierarchy. Keep ordinary surfaces flat; reserve the overlay shadow for modals and popovers. The sidecar names the six restrained motions; use ease-out, animate transform or opacity only, and honor reduced motion.

## Shapes

Use the documented small, medium and large radii for controls and surfaces. Reserve the full radius for circular controls or indicators. Keep the typemark undistorted, on the matching theme background, with no tile behind it.

## Components

Pair every status mark with its word: Sent, Delivered, Delayed, Failed or Not sent. `brandbook/status-marks.json` defines the marks; the mark and its color support the word. Use the matching light or dark typemark unchanged, with its clear space. Logo use by others does not imply endorsement or certification.

## Do's and Don'ts

### Do

- Use the matching light or dark typemark and keep one quarter of its height clear on every side.
- Keep the product name lowercase in prose and write the delivery status beside its mark.
- Use the logo unchanged to refer to mailglass; use by others does not imply endorsement or certification.

### Don't

- Do not use logo Glass for text, links or controls, and do not put a shape behind the typemark.
- Do not add a tagline or descriptor inside the logo, recolor the mark or make patterns from its arches.
- Do not use the retired sealed-flap identity or imply that a status mark replaces its word.
