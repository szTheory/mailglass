# Phase 90 Gate Evidence — brandbook-fable/ (GATE-01 + GATE-02)

- **Date:** 2026-06-11
- **HEAD:** `106229bd`
- **Gate script:** `.planning/phases/90-quality-gate-and-uat/gate.sh` (run from repo root)
- **Frozen codex baseline:** `09a84dd4`

## Documented denylist exclusion (the only one)

Check 4's process-vocabulary denylist filters exactly one false-positive
pattern: `align-items:[[:space:]]*baseline`. `brandbook-fable/index.html` uses
the functional CSS value `align-items: baseline` twice; `baseline` there is a
CSS keyword, not process vocabulary, and rewriting working layout CSS to dodge
a denylist word would be wrong (same rationale as decision [79-01]
text-base-content). NO other exclusion is applied — any other hit is a real
leak that must be fixed in the source file.

## Scripted Gate Runs (GATE-01)

### Run 1 — 2026-06-11, HEAD 106229bd — verbatim output

```
CHECK-1 PASS
CHECK-2 PASS
CHECK-3 PASS
CHECK-4 PASS
CHECK-5 PASS
CHECK-6 PASS
CHECK-7 PASS (folder 256 KB, index.html 79789 B)
CHECK-8 PASS (2 shape elements, 16x16 viewBox)
CHECK-9 PASS
GATE-PASS
```

Exit code: 0. All 9 checks passed on the first full run; no fixes to
`brandbook-fable/` were required.

| Check | What it proves | Result |
|---|---|---|
| 1 | All 12 SVGs xmllint-parse; inventory exactly 8 assets + 6 examples (4 SVG + 2 HTML) | PASS |
| 2 | tokens.json parses as JSON | PASS |
| 3 | Every href/src resolves locally per-file; zero external URLs / url(http) / @import / fetch / script-src | PASS |
| 4 | Zero process-vocabulary hits (Phase 88/89 base regex + word-bounded extension; single documented CSS exclusion) | PASS |
| 5 | Zero `<text` and zero `font-family` in assets/ AND examples/ SVGs | PASS |
| 6 | Zero `<rect>` in every mark; the two square social avatars carry exactly one 240x240 plate each (documented exception) | PASS |
| 7 | Folder 256 KB <= 500 KB; index.html 79,789 B <= 153,600 B; no file > 100 KB | PASS |
| 8 | Favicon: 2 shape elements (<= 3), viewBox="0 0 16 16" | PASS |
| 9 | Tree clean outside .planning/; frozen brandbook/ identical to 09a84dd4; nothing outside brandbook-fable/ + .planning/ changed in 09a84dd4..HEAD | PASS |

## Browser Evidence (GATE-02)

- **Tooling:** agent-browser (Playwright-driven) against `file://` paths —
  zero network by construction. Emulated media pinned per capture
  (`set media light` / `set media dark`); stale per-origin `mg-theme`
  localStorage cleared before every theme-sensitive capture (Phase 89 lesson).
- **Screenshots:** `/tmp/fable-90-evidence/` — an untracked tmp directory
  outside the repo; nothing from this evidence set landed inside the repo.
  The favicon harness (`favicon-harness.html`, throwaway) also lives there.
- Every screenshot below was READ; verdicts are observations from the pixels,
  not assumptions.

| File | Page + viewport + theme | Verdict |
|---|---|---|
| index-1440-light.png | index.html, 1440px, light (full page) | PASS — full book renders light end to end: Paper ground, all 9 sections, swatches, matrix, gallery, logo chips, specimen figures all present |
| index-1440-dark.png | index.html, 1440px, dark via the page `#theme-toggle` (data-theme="dark" confirmed, body bg 13,27,42 = Ink) | PASS — the toggle re-skins the entire book: every section, table, code block, specimen card goes Ink; the deliberate fixed light chips under the four SVG specimen figures and the two light iframes hold (by design, per the Phase 89 chip pattern) |
| index-390-light.png | index.html, 390px, light (full page) | PASS — single-column reflow, nothing clipped; `document.body.scrollWidth == 390 == window.innerWidth` (no horizontal overflow, eval-verified) |
| landing-1440-light.png | examples/landing-page.html, 1440px, light | PASS — left-anchored documentation composition; hero "Transactional email for Phoenix, made visible." with token-drawn mark, install snippet, feature grid, real code block, "Why not just Swoosh?" compare row, fragment-link footer |
| landing-1440-dark.png | examples/landing-page.html, 1440px, dark via its `#theme-toggle` (data-theme="dark", bg Ink confirmed) | PASS — toggle re-skins everything: Ink ground, hero mark redraws Mist+Ice, code blocks legible on sunken surface, compare row and footer intact |
| email-600.png | examples/email-template.html, 600px viewport | PASS — brand-true at email width: Mist ground, Paper card, Ink wordmark, Glass CTA with white label, maintainer-voice sign-in copy, footer with Help/Security links; table layout intact, no overflow |
| favicon-16-light.png | favicon harness, light scheme — img at exactly 16px + 8x pixelated magnification | PASS — at 16px the Ink pane silhouette with flap-of-light and seal reads clearly on white; magnified copy confirms pane, lit flap triangle, half-lit seal (white inside pane, Glass #277B96 below) |
| favicon-16-dark.png | favicon harness, emulated `prefers-color-scheme: dark` | PASS — the favicon's own media query fired inside the img-loaded SVG: pane flipped Ink→Mist, Glass seal held; 16px instance clearly legible on the dark ground |

**Supplemental close-ups** (same dark session, captured to ground the
"re-skinned everything" verdicts at readable scale — beyond the required 8):

| File | What it shows |
|---|---|
| supp-contrast-dark.png | Section 05 Contrast Matrix in dark: "Showing the dark theme — 45 pairs", per-pair computed ratios (15.80, 14.09, …) with AA/AAA pass badges — recomputed on toggle |
| supp-gallery-dark.png | Section 06 Component Gallery in dark: live buttons with forced-state rows (default/hover/active/focus-visible/disabled), inputs, select, checkbox — all token-driven and re-skinned |
| supp-logo-dark.png | Section 07 Logo System in dark: asset manifest table plus lockup chips holding their fixed light/dark surfaces while the page is dark |

Note: one capture iteration was needed for the supplemental shots only — the
page's smooth scrolling meant the first `scrollIntoView` screenshots caught
the scroll mid-flight (an audit-environment artifact, not an artifact defect);
re-captured with `behavior: 'instant'` plus a settle wait. No rendering defect
was found in any artifact; no fix to `brandbook-fable/` was needed and no gate
re-run was triggered.
