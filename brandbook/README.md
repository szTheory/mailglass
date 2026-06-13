# mailglass brand system

The complete mailglass brand: identity, voice, color tokens, typography,
contrast data, component recipes, and the logo assets. Everything here is a
text artifact — SVG, Markdown, JSON, CSS, HTML — so every change reads in a
diff.

**Essence:** Email, made visible. Mail you can see through.

## What's in this folder

| File | What it is |
|---|---|
| `index.html` | The brand book, rendered live: theme toggle, computed contrast matrix, real component gallery, logo system |
| `brand-book.md` | The text master — same nine sections, exact values, static contrast tables for both themes |
| `tokens.css` | The design tokens as CSS custom properties (`:root` light, `[data-theme="dark"]`, OS-preference media block) |
| `tokens.json` | The same values with raw palette names, for tooling |
| `assets/` | The eight logo assets — outlined paths, no live text, no font dependencies |

## How to view

Open `index.html` in any browser, straight from disk. There is no server, no
build step, and no network request — the page is complete over `file://`.
The theme follows your OS setting by default; the toggle in the header
forces light or dark and re-skins every specimen on the page, including the
contrast matrix, which is recomputed from the live token values.

`brand-book.md` opens as plain text locally and renders on any Markdown
host.

## The rules in brief

- **The primary lockup lives on light grounds only.** On Ink or any dark
  ground, use `logo-monochrome.svg` (it inherits the surrounding text color)
  or the dark expression — Mist pane, Ice seal.
- **`favicon.svg` adapts on its own** — the pane flips for OS dark mode; the
  Glass seal holds in both themes.
- **Tokens are the only color source.** Components reference roles
  (`--mg-color-*`), never raw hex. Role names hold across themes.
- **Assets are outlined paths only** — no live text, no font references.
  The wordmark renders identically everywhere, including font-less image
  sandboxes.
- **No background plate behind the mark.** The square social avatars are the
  sole exception.

## Export policy

SVG-first, always. PNG exports are generated locally only when a launch
surface requires a raster image. By default, generated PNGs, avatars, favicons,
screenshots, alternate social sizes, font files, and other rasters are not
committed.

The single v1.10 binary exception is `brandbook/examples/og-card.png`, exported
from `brandbook/examples/og-card.svg` for the GitHub repository social preview.
Regenerate it from the repo root with:

```bash
npx playwright screenshot --viewport-size=2400,1260 "file://$PWD/brandbook/examples/og-card.svg" brandbook/examples/og-card.png
```

Before upload, validate that `brandbook/examples/og-card.png` is exactly
2400x1260 and under 1 MB.

GitHub social-preview upload is a manual Settings UI step. Open the repository
Settings, find Social preview, choose Edit, choose Upload an image, and select
`brandbook/examples/og-card.png`. GitHub provides no documented write API for
this surface, so the repository keeps the source SVG plus the one committed PNG
and leaves the upload itself as a maintainer action.
