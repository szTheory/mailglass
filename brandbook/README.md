# Mailglass Brandbook

This directory is the source-controlled brand system for Mailglass.

It exists so maintainers can build docs pages, README headers, landing pages,
social cards, UI prototypes, and release material without reopening the prompt
history. The historical source material still lives in `prompts/`; this folder
is the buildable version.

## Use This First

- `index.html` - static HTML brandbook. Open directly in a browser.
- `brand-audit.md` - critical pressure test of the current brand system.
- `brand-book.md` - concise source-of-truth brand guidance.
- `tokens.json` - implementation tokens for tooling.
- `tokens.css` - CSS custom properties for docs and marketing prototypes.
- `assets/` - editable SVG logo and mark files.
- `examples/` - small SVG specimens for palette, type, UI, README/docs, and social framing.

## Operating Rules

- Keep the brand self-contained in this directory unless product code needs a
  specific token or asset.
- Do not commit font binaries, large raster exports, Figma files, screenshots,
  or generated PNG batches by default.
- Prefer SVG, Markdown, JSON, CSS, and plain HTML.
- Keep Glass (`#277B96`) as an accent, not a background flood.
- Do not introduce glassmorphism, bevels, glossy reflections, mascots, paper
  planes, or marketing-email imagery.
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
- Does it avoid generic SaaS/devtool visual tropes?
- Does it still work in dark mode, light mode, small sizes, and monochrome?
- Is it source-control friendly?
