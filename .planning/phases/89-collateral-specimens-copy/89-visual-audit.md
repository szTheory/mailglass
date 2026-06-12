# Phase 89 Visual Audit — collateral specimens

**Audited:** 2026-06-12
**Tooling:** agent-browser CLI against `file://` paths (landing, email, index) plus a throwaway SVG harness page at `/tmp/fable-89-audit/svg-harness.html` rendering each specimen via `<img>` on a #FFFFFF ground and a #0d1117 (GitHub-dark) ground
**Screenshots:** `/tmp/fable-89-audit/` (uncommitted by design)
**Iterations:** 3 (initial read-and-fix pass; fix confirmation; final zero-defect pass with pixel-level verification)

## Iteration log

| Iteration | Defects found (read from screenshots) | Fixes applied |
|---|---|---|
| 1 | (a) **diagram-language.svg: flow arrows overran into the next node** — the connector line was drawn 88px into a 60px gap, so each arrowhead landed inside the following pane and touched the first stencil letter (visible on MESSAGE, DELIVERY, EVENT). (b) Audit-environment artifacts (not artifact defects): the landing-page iframe inside index.html rendered dark while the book was light — stale `mg-theme=dark` persisted in the landing page's own file:// localStorage partition from an earlier direct toggle; and the browser's emulated color scheme drifted back to the system (dark) preference across viewport changes, which mislabeled one capture. | (a) Recomputed connector geometry: lines now run x+176 → x+214 inside each 60px gap with the 12px head ending 4px clear of the next node's stroke. Re-rendered: MAILABLE → MESSAGE → DELIVERY → EVENT reads cleanly, heads clear of borders and labels. (b) Cleared the partitioned localStorage key at its own origin and pinned `set media light` before each capture sequence; relabeled the one mis-named capture. |
| 2 | None in the artifacts. agent-browser's element-screenshot of cross-origin file:// iframes proved unreliable (solid-color captures), so iframe verification switched to full-viewport captures cropped with sips. | Verification-method change only; no artifact edits. |
| 3 | None — zero defects. Final pass re-read: landing 1440+390 both themes, email 640+390 both schemes, all four SVGs on white and #0d1117, index section 08 at 1440+390 both themes with iframe crops and pixel-value reads. | — |

## Surfaces read

- **landing-page.html, 1440px light + dark** — left-anchored documentation composition holds; hero mark redraws from live tokens in both themes (Ink+Glass on light, Mist+Ice on dark); install snippet and code blocks legible on the sunken surface; comparison row and footer intact; toggle re-skins everything.
- **landing-page.html, 390px light + dark** — single column, features stack, code blocks scroll horizontally without page overflow (`scrollWidth == innerWidth` = 390), mark and CTAs visible in both themes.
- **email-template.html, 640px and 390px** — table layout intact at both widths, nothing overflows; dark scheme (emulated `prefers-color-scheme: dark`) flips ground to Ink, card to raised navy, wordmark to Mist, CTA stays Glass with Paper text; light scheme shows Mist ground, Paper card, Ink text. Both schemes read by screenshot.
- **SVG harness, white #FFFFFF ground** — readme-header (Glass lockup + Slate tagline) crisp; docs-page framing hierarchy reads; og-card lockup left-anchored on its Paper ground; diagram-language legend + flow legible, stencil labels clear.
- **SVG harness, #0d1117 ground (GitHub-dark img sandbox simulation)** — readme-header fully legible: Glass 3.93:1, Slate (display-size tagline only) 3.46:1 on #0d1117 (computed); docs-page, og-card, and diagram-language carry their own Paper grounds and read fine on dark.
- **index.html section 08, 1440px + 390px, light + dark** — all six figures render; the four SVG figures sit on fixed light chips that hold in dark mode (pixel-verified: page bg `13,27,42` Ink with chip bg `248,251,253` Paper at 390 dark); both iframes load and show their light specimens deterministically in both book themes (verified by sips crops of the live viewport: landing hero and email card both light inside the dark book); "Open the file" links present in all six captions.

## Pixel-level assertions (final pass)

| Assertion | Result |
|---|---|
| Light 390: page bg pixel = (248, 251, 253) = Paper, heading pixel = (13, 27, 42) = Ink | PASS |
| Dark 390: page bg pixel = (13, 27, 42) = Ink; readme-header chip pixel = (248, 251, 253) = Paper (chip holds) | PASS |
| Dark/light 1440: page bg pixels flip Ink/Paper as expected | PASS |
| Landing iframe inside dark book: hero renders light (crop read: Paper hero, Ink headline, Ink+Glass mark) | PASS |
| Email iframe inside dark book: renders light (crop read: Mist ground, Paper card, Glass CTA) | PASS |
| No horizontal overflow at 390 (`document.body.scrollWidth == 390`) | PASS |
| readme-header fills computed against both grounds: Glass 4.82 / 3.93, Slate 5.47 / 3.46 — all >= 3.0 | PASS |

**Verdict:** iteration 3 produced zero defects across every screenshot read. The one real artifact defect found (diagram arrow overrun) was fixed in iteration 1 and confirmed in iteration 2.
