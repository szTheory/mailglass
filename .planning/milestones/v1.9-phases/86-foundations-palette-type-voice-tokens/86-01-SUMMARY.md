---
phase: 86-foundations-palette-type-voice-tokens
plan: 01
subsystem: brand
tags: [design-tokens, dtcg, css-custom-properties, wcag, dark-mode, brandbook]

# Dependency graph
requires:
  - phase: 85-research-and-differentiation-brief
    provides: differentiation brief (non-negotiables, file manifest, pitfall mapping) + TOKENS-A11Y research (fix hexes, dark ramp, token architecture)
provides:
  - brandbook-fable/tokens.json — DTCG-2025.10-style two-tier tokens (36 palette values + 39 semantic color roles per theme + font/text/space/radius/focus)
  - brandbook-fable/tokens.css — genuinely usable --mg-* custom properties with full dark parity (three-state toggle pattern)
  - 86-foundations-decisions.md — evolve-vs-keep records + script-computed both-theme WCAG matrix (192 pair rows)
  - the four decided dark feedback backgrounds (#142B22 / #2B2314 / #2E1B1E / #11293A), all contrast-verified
affects: [87-logo, 88-book-assembly, 89-collateral, 90-quality-gate]

# Tech tracking
tech-stack:
  added: []
  patterns: [two-tier DTCG tokens (palette -> semantic roles, no numeric ramps), three-state theme toggle (:root light + data-theme dark + prefers-color-scheme media block), computed-not-asserted contrast proof]

key-files:
  created:
    - brandbook-fable/tokens.json
    - brandbook-fable/tokens.css
    - .planning/phases/86-foundations-palette-type-voice-tokens/86-foundations-decisions.md
  modified: []

key-decisions:
  - "Dark feedback backgrounds adopted at first candidates, all verified: success-bg #142B22 (6.56 vs #8BB77F), warning-bg #2B2314 (7.37 vs #E0A955), error-bg #2E1B1E (6.65 vs #E29089), info-bg #11293A (11.18 vs #A6EAF2)"
  - "Six research fix hexes bound to roles: glass-deep #1D637A (link/accent-text/info-text light), glass-deepest #174E61 (hover/active), amber-deep #96520E (warning-text), slate-soft #74909F (border-input light), slate-bright #62809A (border-input dark), crimson-bright #E29089 (error-text dark)"
  - "Type scale locked: display 44 / h1 36 / h2 30 / h3 24 / body 16 / small 14 / code 14 px"
  - "Worst-surface figures recomputed against the SHIPPED surface set (surface-selected is the worst surface in both themes); the decision-record matrix is authoritative over research worst-case quotes"
  - "border-input <3:1 on selected surfaces resolved as a usage rule (form controls never sit on selected rows), not a darker border token"

patterns-established:
  - "Palette tier uses brand-named descriptive modifiers (glass-deep, pine-shadow), never numeric ramps"
  - "Every --mg-color-* role declared exactly 3x in tokens.css (light, dark attr, dark media) with byte-identical dark blocks"
  - "Process-vocabulary denylist grep gated in-phase over brandbook-fable/, not deferred"

requirements-completed: [FOUND-01, FOUND-02, FOUND-03, FOUND-04]

# Metrics
duration: ~25min
completed: 2026-06-11
---

# Phase 86 Plan 01: Foundations — Palette, Type, Voice, Tokens Summary

**Contrast-proven two-tier token foundation (tokens.json + tokens.css) with complete 39-role light/dark parity, six computed fix hexes, four newly decided dark feedback backgrounds, and a 192-row script-computed WCAG matrix in the decision record.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-11T15:54:42Z
- **Completed:** 2026-06-11T16:18:00Z
- **Tasks:** 3/3
- **Files modified:** 3 created

## Accomplishments

- First `brandbook-fable/` artifacts shipped: DTCG-2025.10-style `tokens.json`
  (136 `$value` tokens, two tiers, no legacy dialect) and genuinely usable
  `tokens.css` (39 color roles x 3 blocks with byte-identical dark
  declarations, honest font fallback stacks, three-state toggle support).
- The v1.8 root failures are fixed at the foundation layer: contrast computed
  in-phase (not "later"), dark role set complete (39/39, parity-checked both
  in JSON and CSS), planning-language grep gate green from the first draft.
- Decision record carries evolve-vs-keep rows for every seed decision with
  contrast math, the adopted dark ramp, and the full both-theme matrix
  (192 hex-bearing rows incl. on-solid pairs and SC 1.4.11 non-text checks)
  with a usage rule per pair — Phase 88's rendering input.
- All four open dark feedback backgrounds decided and verified on first
  computation: `{kind}-text` >= 4.5:1 on `{kind}-bg` holds for all four
  (6.56 / 7.37 / 6.65 / 11.18).

## Task Commits

Each task was committed atomically:

1. **Task 1: Verify open hexes, author tokens.json + tokens.css** - `e5a67a7d` (feat)
2. **Task 2: Compute full WCAG matrix, write decision record** - `7c039b6c` (docs)
3. **Task 3: Consolidated hygiene + completeness gate** - no commit (all 8 gates green on the committed files; no fixes needed)

## Files Created/Modified

- `brandbook-fable/tokens.json` - Two-tier DTCG-style tokens: 36 brand-named palette values, 39 semantic color roles per theme (aliased), font/text/space/radius/focus groups (14,140 bytes, budget 16,384)
- `brandbook-fable/tokens.css` - Flat `--mg-*` custom properties: `:root` light block, `[data-theme="dark"]` block, `prefers-color-scheme` media block with identical declarations (5,759 bytes, budget 10,240)
- `.planning/phases/86-foundations-palette-type-voice-tokens/86-foundations-decisions.md` - Evolve-vs-keep records + 192-row computed contrast matrix + method statement for identical recomputation

## Decisions Made

- **Dark feedback backgrounds (Claude's discretion, contract met):** starting
  candidates all passed on first verification and were adopted unchanged —
  `#142B22` / `#2B2314` / `#2E1B1E` / `#11293A`, named pine-shadow /
  amber-shadow / crimson-shadow / ice-shadow in the palette tier.
- **Palette tint naming:** descriptive `-tint` (light callout surfaces) and
  `-shadow` (dark callout surfaces) modifiers; `mist-edge`/`ink-edge` for
  decorative hairlines, `slate-faint`/`slate-dim` for disabled text,
  `mist-soft` for dark muted text. No numeric ramps anywhere.
- **Space/radius/focus (discretion):** plan-suggested minimal set adopted
  verbatim (xs 4 … 2xl 64; radius 4/8/12/9999; 2px ring + 2px offset).

## Deviations from Plan

### Reconciled computed-vs-expected values

**1. [Reconciliation] Worst-surface contrast figures lower than research quotes**
- **Found during:** Task 2 (full matrix computation)
- **Issue:** Research quoted dark worst cases against a surface that did not
  ship (e.g. text-muted `#B8CAD4` "7.41 worst", text "11.37 worst"). Against
  the shipped surface set, `surface-selected #1B3E55` is the worst dark
  surface: text 10.22 (still AAA), text-muted 6.66 (AA, fails AAA there).
- **Resolution:** All research-claimed contexts reproduce exactly; the delta
  is surface-set scope, not math. Matrix recorded as authoritative; text-muted
  documented as AA on selected rows (matching the light theme's AA-only
  guarantee). No token change.
- **Commit:** 7c039b6c

**2. [Reconciliation] border-input below 3:1 on selected surfaces (both themes)**
- **Found during:** Task 2 (non-text SC 1.4.11 checks)
- **Issue:** Full-matrix coverage exposed border-input at 2.91 (light) / 2.72
  (dark) on `surface-selected` — a context research never claimed (its
  guarantee contexts 3.24/3.06 light, 4.20/3.75/3.22 dark all reproduce).
- **Resolution:** Usage rule recorded — form controls never sit on
  selected-row surfaces; darkening the border tokens would over-weight every
  normal form. Flagged for Phase 88's gallery to respect.
- **Commit:** 7c039b6c

### Auto-fixed Issues

**1. [Rule 1 - Bug] Task 3 gate-4 checker matched the CSS header comment**
- **Found during:** Task 3 (first gate run)
- **Issue:** The throwaway block-extraction one-liner found
  `[data-theme="dark"]` inside the file's header comment and diffed the light
  block against the media block, reporting a false mismatch.
- **Fix:** Checker strips comments and anchors the selector at line start;
  re-run showed the dark attr and media blocks byte-identical (40
  declarations each). The shipped CSS was never wrong; no file changed.
- **Files modified:** none (throwaway /tmp checker only)

## Known Stubs

None — both token files are complete and consumable as shipped; no
placeholder values, no empty roles.

## Self-Check: PASSED

- brandbook-fable/tokens.json: FOUND
- brandbook-fable/tokens.css: FOUND
- 86-foundations-decisions.md: FOUND
- Commit e5a67a7d: FOUND
- Commit 7c039b6c: FOUND
