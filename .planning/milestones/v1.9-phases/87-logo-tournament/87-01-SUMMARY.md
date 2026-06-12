---
phase: 87-logo-tournament
plan: 01
subsystem: brand
tags: [logo, tournament, svg, letterforms, brandbook-fable]
requires:
  - phase: 86-design-tokens
    provides: "brandbook-fable/tokens.css (gallery color system, light + dark)"
provides:
  - "8 pre-screened round-1 logo options (2 per axis A-D), hand-authored outlined-path SVGs"
  - "Self-contained rendered-evidence gallery (tournament/round-1.html)"
  - "112/112 PASS pre-flight constraint screen (87-pre-flight.md)"
  - "Hard-pause checkpoint with selection protocol (87-01-CHECKPOINT.md)"
affects: [87-02]
tech-stack:
  added: []
  patterns:
    - "LOGO-CRAFT integer grid: x-height 100u, S=22 stems, 3u overshoot, 0.5523 bezier constant, joint thinning"
    - "Inline-SVG gallery with oN- id prefixes; per-copy id stripping; Glass->Ice accent swap for dark cells"
key-files:
  created:
    - .planning/phases/87-logo-tournament/tournament/options/option-1.svg
    - .planning/phases/87-logo-tournament/tournament/options/option-2.svg
    - .planning/phases/87-logo-tournament/tournament/options/option-3.svg
    - .planning/phases/87-logo-tournament/tournament/options/option-4.svg
    - .planning/phases/87-logo-tournament/tournament/options/option-5.svg
    - .planning/phases/87-logo-tournament/tournament/options/option-6.svg
    - .planning/phases/87-logo-tournament/tournament/options/option-7.svg
    - .planning/phases/87-logo-tournament/tournament/options/option-8.svg
    - .planning/phases/87-logo-tournament/tournament/round-1.html
    - .planning/phases/87-logo-tournament/87-pre-flight.md
    - .planning/phases/87-logo-tournament/87-01-CHECKPOINT.md
  modified: []
decisions:
  - "One shared LOGO-CRAFT glyph library (m a i l g s drawn once to the per-glyph recipes) underpins every wordmark; the eight CONCEPTS are independent — the craft system is the spec, not a shared sketch"
  - "Option files keep currentColor + at most one Glass hex; the gallery swaps Glass->Ice in dark cells, mirroring the token system (accent role remap, documented in pre-flight C-08)"
  - "Favicon cells render a mark-region viewBox crop (the honest favicon candidate per option) at actual 16/32px, not the whole lockup scaled to fog"
requirements-completed: [LOGO-05, LOGO-06]
requirements-partial: [LOGO-07]
metrics:
  duration: "49 minutes"
  tasks: 3
  files-created: 11
  completed: 2026-06-11
---

# Phase 87 Plan 01: Round-1 Logo Tournament Field Summary

Eight hand-drawn outlined-path logo options (2 per axis), pre-screened 112/112 against the hard-constraint set, presented in a browser-audited self-contained evidence gallery — phase now HARD-PAUSED awaiting the maintainer's pick.

## THE PHASE IS PAUSED — READ THIS FIRST

**Plan 87-02 must NOT run.** The phase is blocked on maintainer selection in
`87-01-CHECKPOINT.md` (status: `awaiting-maintainer-selection`,
`rejection_count: 0`). The maintainer reviews
`.planning/phases/87-logo-tournament/tournament/round-1.html` and replies
`pick N`, `pick N and M`, or `reject all` with notes. No default pick may be
inferred. A second consecutive full rejection trips the circuit breaker: stop
generating, re-brief.

## The field

| # | Axis | Option | One-liner |
|---|------|--------|-----------|
| 1 | A typemark | the open loop | g descender curls into a loop that never seals |
| 2 | A typemark | the refracted stem | the "mail" l shears sideways at the seam, like refraction |
| 3 | B lockup | the through-pane | a message bar passes through a pane, visible inside |
| 4 | B lockup | the reveal | disc split by a pane edge: solid in air, open ring behind glass |
| 5 | C monogram | the lens g | circular lens + one hooked stem = a 2-shape g |
| 6 | C monogram | the mg ligature | m and g share one stem, hook breaks the baseline |
| 7 | D negative space | the slotted lens | mail slot voided clean through a solid lens edge |
| 8 | D negative space | the shared light | pane + lens overlap carried entirely by voided light |

## What was built

- **Letterform system:** m a i l g s drawn as filled outline paths on the
  LOGO-CRAFT grid (x-height 100u, stems exactly S=22 by coordinate
  arithmetic, horizontals 19-21, 3u overshoot on round extremes only,
  0.5523 handle constant, joint thinning at branches, double-story a,
  single-story g, untouchable i dot: circle d=25 at one stem-width above the
  stem). Duplicate letters ship as duplicated literal paths. Spacing:
  straight-straight 31u, round-straight 28u, round-round 26u.
- **Gallery:** `tournament/round-1.html` — tokens.css inlined whole, all 8
  SVGs inlined (canonical copy keeps oN- ids; other copies id-stripped and
  aria-hidden), six fixed evidence cells per option, whole-page dark section,
  zero external requests, no scripts, system fonts for chrome only.
- **Pre-flight:** 8 x C-01..C-14 = 112 rows, all PASS, with measured-unit
  evidence (gaps, boundary-break depths, rect-vs-viewBox percentages) and
  screenshot paths for C-05..C-08.

## Browser visual audit (anti-thrash loop)

Rendered with Playwright 1.60 loaded from a sibling project's existing
install (nothing new installed), 18 PNGs to gitignored
`tmp/87-logo-tournament/round-1/`: full-page light, full-page dark, 8 strip
close-ups, 8 favicon-row zooms at 3x. Every screenshot was read and judged.

Fix-or-replace log (caught at render, fixed BEFORE presentation; no option
needed replacement):

1. option-5 first draft read as **q** (bare ring + straight stem) — left-sweeping hook added; still 2 shapes at favicon scale
2. option-6 g-bowl counter wound clockwise (rendered solid) — reversed to counter-clockwise, counter now hollow
3. the m's inter-arch notch was a zero-width cusp (invisible) — opened to a visible V with angled tangents
4. the s spine-to-bowl junctions kinked — tangent-matched cubics + gentle bow, inflections on on-curve nodes
5. option-1 loop mouth too closed at word size — mouth widened (tip face 17.5-35u at y=154.5, 12u+ clearance to the bowl)
6. option-6 lockup gap measured 57u against a 25-37.5u bound — tightened to 30u

## Deviations from Plan

None — plan executed as written. The six render-audit fixes above are the
plan's own fix-or-replace screen operating as designed, not scope deviations.
One execution note: Playwright was loaded from
`~/projects/relyra/node_modules` (already on disk) per the plan's
"install NOTHING new" constraint.

## Known Stubs

None. The checkpoint's empty Selection section is the designed pause record,
not a stub.

## Verification

- `xmllint --noout` passes on all 8 option SVGs; every file has viewBox,
  role="img", title+desc, globally-unique oN- prefixed ids
- Zero `<text>`, zero `font-family`, zero 3+-decimal coordinates across all 8
- round-1.html: zero non-xmlns `https?://` matches; `--mg-color-` tokens inlined
- 87-pre-flight.md: exactly 112 `| option-` rows, 112 PASS
- 18 screenshots in `tmp/87-logo-tournament/round-1/` (>= 10 required)
- Nothing written under `brandbook-fable/`; `brandbook/` untouched
## Self-Check: PASSED

All 12 created files exist on disk; commits 33022db1, 8768e0b7, 86add0a9,
8a3b97e8 verified in git log. All Task 3 automated gates re-run green.
