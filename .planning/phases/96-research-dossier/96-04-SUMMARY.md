---
phase: 96-research-dossier
plan: "04"
subsystem: ui
tags: [dark-mode, tokens, wcag, contrast, accessibility, brandbook, daisyui]

requires:
  - phase: 95-audit-apparatus-quality-ratchet-v2
    provides: GAP-03 registration (preview ignores dark theme), Phase 86 dark-feedback contrast figures, baseline scores

provides:
  - DARK-LD-01..08 locked decisions for dark-mode elevation, borders, focus-ring, accent, status, preview chrome, and OS integration
  - Computed WCAG contrast ratios for all [data-theme="dark"] token pairs
  - GAP-03 close prescription for Phase 100 (preview chrome dark)
  - Critical accessibility finding: --mg-color-border #315069 fails WCAG 1.4.11 on dark surfaces

affects: [phase-97, phase-98, phase-99, phase-100, phase-101, phase-102, phase-103]

tech-stack:
  added: []
  patterns:
    - "Codebase-led dossier: reason over real token values + computed contrast ratios before locking decisions"
    - "Adversarial synthesis: critic-then-lock pass challenges each draft against hard constraints + GAP rows"
    - "Axis-ownership cross-reference: DARK-MODE locks rendering, COMPONENT-STATES locks which states exist, MOTION locks how they animate"

key-files:
  created:
    - .planning/research/v1.11/DARK-MODE.md
  modified: []

key-decisions:
  - "DARK-LD-01: Dark surface elevation tier order confirmed correct — sunken #0A1521 < base #0D1B2A < raised #152538 < overlay #1F3049 < selected #1B3E55 (brighter = higher in dark)"
  - "DARK-LD-02: Dark structural border upgrade mandatory — --mg-color-border #315069 fails WCAG 1.4.11 (2.06:1); dark app.css must override base-300 to border-input #62809A (4.20:1) for interactive boundaries"
  - "DARK-LD-03: Dark focus-ring --mg-color-focus-ring #A6EAF2 (Ice) confirmed — 12.98:1 on base surface, 8.40:1 worst-case on selected — all pass WCAG 1.4.11"
  - "DARK-LD-05: Phase 86 dark-feedback contrast figures confirmed locked — success #142B22/6.56:1, warning #2B2314/7.37:1, error #2E1B1E/6.65:1, info #11293A/11.18:1"
  - "DARK-LD-06: GAP-03 close prescription — preview_live.ex already emits data-theme correctly; Phase 100 must confirm audit URL uses ?theme=dark and produce visual diff showing Ink #0D1B2A background"
  - "DARK-LD-08: OS dark-mode integration — do not unconditionally assign dark_chrome: false at mount; defer to daisyUI prefersdark:true CSS behavior when no URL param present"

requirements-completed: [RESEARCH-04]

duration: 45min
completed: 2026-06-14
---

# Phase 96 Plan 04: Dark-Mode Research Dossier Summary

**Dark-mode research dossier with 8 DARK-LD-NN locked decisions covering elevation tier ordering, structural border WCAG 1.4.11 fix, focus-ring Ice token confirmation, accent 10% rule, Phase 86 status-feedback extension, and GAP-03 (preview ignores dark theme) close prescription for Phase 100**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-14
- **Completed:** 2026-06-14
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `.planning/research/v1.11/DARK-MODE.md` with full codebase-grounded dark token inventory: extracted all `[data-theme="dark"]` values from `brandbook/tokens.css` lines 89–138 and computed WCAG contrast ratios across all surface tier pairs
- Identified critical accessibility finding: `--mg-color-border` (#315069) fails WCAG 1.4.11 (non-text contrast ≥3:1) on all dark surfaces (2.06:1 on base, 1.83:1 on raised) — locked mandatory upgrade to `--mg-color-border-input` (#62809A, 4.20:1) for all interactive boundaries in dark mode (DARK-LD-02)
- Confirmed focus-ring Ice (#A6EAF2) achieves 12.98:1 minimum on dark base — all surface tiers clear WCAG 1.4.11 3:1 with large margin; no alternate token needed (DARK-LD-03)
- Extended Phase 86 dark-feedback figures to the LOCKED DECISION block (DARK-LD-05) and locked GAP-03 implementation prescription in DARK-LD-06: phase 100 must produce visual diff confirming preview dark chrome renders Ink #0D1B2A background
- Adversarial synthesis (Section 6) revised 3 draft decisions, strengthening GAP-03 prescription from "audit URL fix" to verifiable implementation requirement, confirming border upgrade as mandatory accessibility (not aesthetic), and making accent 10% rule explicit for dark mode

## Task Commits

1. **Task 1: Research dark-mode pitfalls and lock decisions over existing tokens** - `3f5a076b` (docs)

## Files Created/Modified

- `/Users/jon/projects/mailglass/.planning/research/v1.11/DARK-MODE.md` — 513-line dark-mode research dossier with 8 DARK-LD-NN locked decisions, full token inventory, contrast ratios, 5-pitfall external synthesis, gap analysis, adversarial synthesis

## Decisions Made

- DARK-LD-01: Elevation tier order locked (5 tiers, brighter=higher, confirmed correct in existing tokens)
- DARK-LD-02: Structural border upgrade from #315069 → #62809A in dark (mandatory WCAG 1.4.11 fix; requires app.css `mailglass-dark` theme block change in downstream phase)
- DARK-LD-03: Focus-ring Ice #A6EAF2 confirmed — no change to tokens.css needed
- DARK-LD-04: Dark accent 10% rule explicit — Ice #A6EAF2 permitted only on selected-row border, active nav, primary CTA text/icon, focus-ring; not as fills or default borders
- DARK-LD-05: Phase 86 status-feedback figures confirmed locked verbatim
- DARK-LD-06: GAP-03 prescription — Phase 100 must verify handle_params sets dark_chrome:true from ?theme=dark, confirm audit URL, produce visual diff (acceptance gate)
- DARK-LD-07: Dark interactive input border = border-input #62809A (4.20:1); filters_form and tenant_chip inherit
- DARK-LD-08: OS dark-mode: do not force dark_chrome:false at mount; daisyUI prefersdark:true should activate when no URL param present

## Deviations from Plan

None — plan executed exactly as written. Research-only phase; all findings came from direct token analysis and computed contrast ratios.

## Issues Encountered

None. The `preview_live.ex` investigation initially suggested GAP-03 might be a missing `data-theme` attribute, but the code at line 225 already emits it correctly. The adversarial synthesis (Challenge 1) refined the prescription from a docs-only note to a verifiable implementation requirement, which is within the plan's scope for the adversarial pass.

## Known Stubs

None. Research dossier only — no UI rendering.

## Threat Flags

None. Research-only phase; no executable attack surface introduced.

## Self-Check

Verification grep results (all pass):

```
grep -l "## LOCKED DECISION"   → DARK-MODE.md FOUND
grep -c "DARK-LD-"             → 24 (≥6 required)
grep "GAP-03"                  → 7 matches (≥1 in LOCKED DECISION section)
grep "focus-ring"              → multiple matches
grep "#142B22"                 → multiple matches (Phase 86 figures confirmed)
grep "[data-theme=\"dark\"]"   → multiple matches
grep "brandbook/tokens.css"    → multiple matches
```

## Self-Check: PASSED

All acceptance criteria met. DARK-MODE.md exists at
`.planning/research/v1.11/DARK-MODE.md`, contains `## LOCKED DECISION`, has 8 DARK-LD-NN
rows (24 total occurrences including body cross-references), GAP-03 appears in the Closes-GAP
column of DARK-LD-06, all rows have non-empty Constraint-binding cells, and no locked
decision endorses glassmorphism (it appears in Constraint-binding cells only as a banned
pattern).

## Next Phase Readiness

- DARK-LD-01..08 ready for citation by Phase 97 (components), Phase 98/99/100 (surfaces), Phase 103 (verification)
- GAP-03 close prescription locked — Phase 100 has a verifiable acceptance gate
- DARK-LD-02 border-upgrade finding must be addressed in Phase 97 or 98 (whichever first touches the dark daisyUI theme block in app.css)
- All 5 dossiers now complete (MOTION.md, IA.md, COMPONENT-STATES.md, DARK-MODE.md); MICROCOPY.md remains (96-05)

---
*Phase: 96-research-dossier*
*Completed: 2026-06-14*
