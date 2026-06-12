# Phase 90 Checkpoint — Maintainer A/B Walkthrough + Sign-off (GATE-03)

**status: approved**
**Presented:** 2026-06-11

## Open these two side by side

- **Codex (frozen at 09a84dd4):** `file:///Users/jon/projects/mailglass/brandbook/index.html`
- **Fable (the challenger):** `file:///Users/jon/projects/mailglass/brandbook-fable/index.html`

## The 12 differentiators — check each in the fable book

- [ ] **DIF-01 — Outlined, font-independent logo assets:** section 07 Logo, every lockup chip — letterforms identical with no Avenir Next installed; compare codex's typed wordmark.
- [ ] **DIF-02 — Purpose-drawn wordmark (integer grid, optical-correction pass, outlined paths):** section 07, `logo-typemark.svg` chip — drawn stems and overshoot, not typed text.
- [ ] **DIF-03 — Demonstrated dark mode:** header theme toggle — flip it and watch EVERY specimen, table, and code block re-skin (codex has no toggle at all).
- [ ] **DIF-04 — Live HTML component gallery with real hover/focus/disabled states plus forced-state rows:** section 06 Components — hover the buttons, tab to focus rings, see the forced-state rows.
- [ ] **DIF-05 — Computed WCAG contrast matrix, rendered in-page and recomputed on theme toggle:** section 05 Contrast — 45 pairs with live ratios + AA/AAA badges; flip the toggle and watch them recompute.
- [ ] **DIF-06 — Zero process leakage:** browse any page/file under `brandbook-fable/` — reader-facing language only (machine-proven by the gate's denylist check, Run 1).
- [ ] **DIF-07 — Landing-page blueprint:** open `file:///Users/jon/projects/mailglass/brandbook-fable/examples/landing-page.html` — working, self-contained, toggle-aware.
- [ ] **DIF-08 — Branded transactional email specimen (client-safe):** open `file:///Users/jon/projects/mailglass/brandbook-fable/examples/email-template.html` — table layout, inline styles, dark-scheme survival.
- [ ] **DIF-09 — Per-surface copy library plus seven-noun microcopy:** `brandbook-fable/copy/copy-blocks.md` + `copy/microcopy.md` — paste-ready, all seven nouns.
- [ ] **DIF-10 — Worked diagram-language spec:** section 08 Surfaces, diagram-language figure (full SVG at `examples/diagram-language.svg`) — node shapes, stroke weights, arrowheads by recipe.
- [ ] **DIF-11 — Small-size-true favicon (≤3 shapes, legible at 16px):** section 07's 16px chips + the favicon-16-light/dark verdicts in `90-gate-evidence.md` (2 shapes, both color schemes legible).
- [ ] **DIF-12 — Social-card template (1200×630 source SVG) with documented PNG export path:** section 08 social-card figure + section 09 Usage export note (`examples/og-card.svg`).

## What to compare

- Toggle both books to dark — codex cannot; fable re-skins every specimen live.
- Codex wordmark vs fable outlined wordmark — codex types Avenir Next and degrades on any machine without it; fable's drawn paths render identically everywhere.
- Component galleries — codex ships static pictures; fable ships live elements with real `:hover`/`:focus-visible`/`:disabled` states.
- Open one example page from each from `file://` — fable's landing + email blueprints are working self-contained HTML; codex has no equivalents.
- Squint-test both favicons at tab size (16px) — fable's 2-shape redraw vs codex's full mark scaled down.

## Gate status

GATE-01 + GATE-02 are mechanically proven: the 9-check scripted gate passed in
full (Run 1, sentinel GATE-PASS) and all 8 browser-evidence screenshots passed
their read verdicts — see `90-gate-evidence.md` in this directory.

## Sign-off (GATE-03 — the milestone's final human step)

Winner ADOPTION (folder rename, README propagation) is deferred to a future
milestone per REQUIREMENTS — this sign-off only closes v1.9.

- **Verdict:** _(empty — awaiting maintainer)_
- **Punch list:** _(empty — awaiting maintainer)_
- **Date:** _(empty)_

Reply **"approve"**, or **"punch list:"** followed by numbered items (recorded
here; fixes happen in-phase — fix in `brandbook-fable/`, full gate.sh re-run
recorded in `90-gate-evidence.md`, evidence refreshed — before close).

## Maintainer Sign-off (closes GATE-03)

- **Verdict:** APPROVED — "I LOVE THE NEW BRANDBOOK"
- **Punch list:** none
- **Date:** 2026-06-12
- **Effect:** GATE-03 satisfied; Phase 90 complete; v1.9 milestone ready to close.
  Winner adoption (folder rename, README/HexDocs propagation) remains deferred
  to a future milestone per REQUIREMENTS.
