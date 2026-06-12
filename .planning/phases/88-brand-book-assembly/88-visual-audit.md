# Phase 88 Visual Audit — brandbook-fable/index.html

**Audited:** 2026-06-12
**Tooling:** agent-browser CLI (Playwright-backed) against `file:///Users/jon/projects/mailglass/brandbook-fable/index.html`
**Screenshots:** `/tmp/mg-88-audit/` (47 files, uncommitted by design)
**Iterations:** 2 (one read-and-fix pass, one zero-defect confirmation pass)

## Iteration log

| Iteration | Defects found (read from screenshots) | Fixes applied |
|---|---|---|
| 1 | (a) Masthead essence line wrapped with an orphan ("through." alone) at 1440 — `.essence` max-width 30ch too narrow. (b) Favicon `<img>` on the Ink chip rendered invisible whenever the viewer's OS prefers light (the SVG's internal `prefers-color-scheme` follows the OS, not the page toggle); mirrored failure on the Paper chip for OS-dark viewers. (c) Pinned-state labels ("secondary · focus-visible") wrapped to two lines, breaking row rhythm in the gallery state grid. (d) Palette swatch grid laid out 5/5/2 — ragged last row instead of core-six / evolved-six rows. (e) Social avatars blended invisibly into same-colored logo chips — the square plate (the documented exception) had no visible boundary. (f) Paper and Mist swatch chips were indistinguishable from the white card behind them. Additionally, smooth-scroll CSS made mid-animation screenshots land off-target (audit-tooling artifact, captures redone with `behavior:'instant'`). | (a) `.essence` max-width 30ch → 46ch; renders as one clean line at 1440, wraps naturally at 390. (b) Replaced both favicon scale-row `<img>`s with inline two-shape SVGs carrying explicit fills — light expression (Ink pane `#0D1B2A` + Glass seal) on the Paper chip, dark expression (Mist pane `#EAF6FB` + Glass seal) on the Ink chip — deterministic in every OS/theme combination; prose explains the shipped file self-adapts and the live browser-tab favicon demonstrates it. (c) `.state-label` 11px → 10.5px + `white-space: nowrap`; all 15 state cells now align in clean variant rows. (d) Swatch grid minmax 168px → 140px → six columns at 1440: row 1 = core six, row 2 = evolved six. (e) 1px box-shadow plate outline on both avatars (`#C7DCE5` on Paper, `#315069` on Ink). (f) Hairline `border-bottom` on swatch chips. |
| 2 | None. Re-read: masthead (light+dark), 6/6 swatch grid (light+dark), state grid alignment, scale row with both favicon expressions legible (light+dark), input focus ring, tabs (click + ArrowRight), live hover in dark, mobile swatches/scale/matrix at 390 in both themes. Zero defects — pass recorded. | — |

## Final-pass screenshot inventory (all read)

- `i1-light-1440.png` / `i1-dark-1440.png` — full page, both themes, 1440px
- `i1-light-390.png` / `i1-dark-390.png` — full page, both themes, 390px
- `i1-masthead-light.png`, `i1-masthead-dark.png`, `i2-masthead-light.png` — masthead/header
- `i1-sec-{essence,voice,color,type,contrast,components,logo,applications,usage}.png` — per-section closeups, light
- `i1-gallery-closeup.png`, `i1-gallery-dark.png`, `i2-states-light.png` — component gallery both themes
- `i1-focus-button.png` (Glass ring on secondary button via Tab), `i2-focus-input.png` (ring + accent border on the recipient input) — keyboard focus evidence
- `i1-logo-grid-light.png`, `i1-logo-grid-dark.png`, `i1-logo-scale-light.png`, `i2-scale-light.png`, `i2-scale-dark.png` — logo system both themes; light-expression assets confirmed only on light chips; monochrome currentColor reads on Ink and Glass chips; 16px favicon row legible on both grounds after fix
- `i1-matrix-light.png`, `i1-matrix-dark2.png`, `i1-mob-matrix.png` — contrast matrix both themes + mobile overflow-scroll
- `i1-mob-{masthead,gallery,logo,matrix}.png`, `i2-mob-swatches-dark.png`, `i2-mob-scale-light.png` — 390px closeups both themes
- `i2-swatches-light.png`, `i2-swatches-dark.png` — fixed 6/6 palette grid
- `i2-tabs.png` — tab strip after real click + ArrowRight (Source selected, panel swapped)
- `i2-hover-dark.png` — live hover state in dark theme

## Runtime assertions (scripted, same browser session)

| Assertion | Result |
|---|---|
| Light theme: matrix row text-on-background renders **16.74** | PASS (read from the rendered DOM) |
| Light theme: matrix row accent-on-surface renders **4.82** | PASS |
| Toggle click sets `data-theme="dark"` on the root element | PASS |
| Matrix recomputes on toggle: text-on-background flips 16.74 → **15.80** (`#EAF6FB` on `#0D1B2A`) | PASS — value differs from light |
| Matrix renders 45 rows in both themes | PASS |
| `document.title` set ("mailglass — brand book") and `link[rel=icon]` present (assets/favicon.svg) | PASS |
| Zero requests to http(s) origins; session log shows only file:// loads (index.html, tokens.css, 7 SVG asset loads), all 200 | PASS |
| Zero page errors / console errors across the session | PASS |
| No horizontal body overflow at 390px (`scrollWidth == innerWidth`) | PASS |
| Tabs: real click selects (aria-selected, hidden toggling, focus), ArrowRight roves + selects | PASS |
| Keyboard Tab reaches buttons and inputs; focus ring visible in screenshots | PASS |
| OS-preference default honored: with no `data-theme` attribute, emulated dark/light media flips the page | PASS |

## Final gate sweep (after all fixes)

- Task 1 automated gates re-run verbatim: **PASS** (`TASK1-GATES-PASS`)
- Task 2 automated gates re-run verbatim, including the extended process-vocabulary denylist across all five reader-facing files: **PASS** (`TASK2-GATES-PASS`)
- Budgets: index.html 77,675 bytes (limit 153,600); brand-book.md 25,600 bytes (limit 30,720); README.md 2,530 bytes (limit 6,144)
- Inline script budget: 91 physical lines (limit 150)
- `git status --porcelain` touches only `brandbook-fable/` and `.planning/` paths

**Verdict:** iteration 2 produced zero defects across every screenshot read. The book renders coherently in both themes at 1440 and 390, every specimen re-skins on toggle, the matrix is live, and the logo chips honor the usage rules.
