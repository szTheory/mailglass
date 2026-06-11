# Mailglass Brandbook

This directory is the source-controlled brand system for Mailglass.

It exists so maintainers can build docs pages, README headers, package visuals,
social cards, UI prototypes, and release material without reopening prompt
history. The brand center is stable: Mailglass makes email visible.

## Use This First

- `index.html` - static HTML brandbook. Open directly in a browser.
- `brand-book.md` - concise source-of-truth brand guidance.
- `logo-concepts.html` - selected logo board and archived 07r variants.
- `logo-concepts.md` - logo selection notes and constraints.
- `logo-creative-brief.md` - decision record for the selected logo direction.
- `logo-options.md` - historical rejected A-R evidence.
- `tokens.json` - implementation tokens for tooling.
- `tokens.css` - CSS custom properties for docs and marketing prototypes.
- `assets/` - canonical SVG logo and mark files.
- `examples/` - small SVG specimens for palette, type, UI, README/docs, and social framing.

## Selected Logo Direction

Use `assets/logo-primary.svg` as the primary lockup. It is derived from
`assets/concepts/concept-07r-no-idot-02-tighter-gap.svg`: the existing mark,
a tighter mark-to-wordmark gap, and one untouched full `mailglass` wordmark.

Do not revive the rejected i-dot work. The wordmark stays one full text node:
no masks, dot cuts, dotless glyphs, split words, tspans, fake i stems, or panes
over the text.

## Operating Rules

- Keep the brand self-contained in this directory unless product code needs a
  specific token or asset.
- Prefer SVG, Markdown, JSON, CSS, and plain HTML.
- Keep Glass (`#277B96`) as an accent, not a background flood.
- Treat Glass as a metaphor for clarity and visibility, not as glassmorphism.
- Do not introduce glossy reflections, decorative gradients, mascots, paper
  planes, mailboxes, chat bubbles, send arrows, or SaaS-hype visuals.
- Treat `mailglass_admin/docs/design-system.md` as the implemented product UI
  constraint source. This brandbook is broader, but it should not contradict
  the admin design system.

## Export Policy

Commit:

- SVG logos and specimens.
- JSON/CSS tokens.
- Markdown and HTML guidance.

Generate locally when needed:

- PNG exports of logos or social cards.
- Browser screenshots of HTML examples.
- Temporary contrast reports.

Do not commit unless there is a concrete release need:

- Raster screenshot sets.
- Large social-card PNG variants.
- Font files.
- Vendor design files.

## Quality Gate

Before changing this directory, check:

- Does the change preserve "Mailglass makes email visible"?
- Does it help a maintainer build something real?
- Does it keep the selected no-i-dot logo direction intact?
- Does it avoid generic SaaS/devtool visual tropes?
- Does it still work in dark mode, light mode, small sizes, and monochrome?
- Is it source-control friendly?
