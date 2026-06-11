# Phase 87: Logo Tournament - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Approved milestone plan + 85-differentiation-brief + LOGO-CRAFT research + Phase 86 tokens

<domain>
## Phase Boundary

Phase 87 runs the bounded logo tournament and ends with canonical assets in
`brandbook-fable/assets/`. The tournament itself (option SVGs, gallery pages,
decision record) lives in `.planning/phases/87-logo-tournament/tournament/`
and never ships in `brandbook-fable/`.

**This phase contains the milestone's only HARD PAUSE: after round 1 is
presented, NOTHING proceeds until the maintainer picks 1-2 options. No
auto-advance, no inferring a default.**

</domain>

<decisions>
## Implementation Decisions

### Round 1 field (LOGO-05) — exactly 8 options, 2 per axis
- **Axis A — integrated custom typemark ×2:** "mailglass" with ONE earned
  modification worked into the letterforms. Prime site per LOGO-CRAFT: the
  l·g·l cluster at the mail|glass seam (counter-as-lens g, negative-space
  pane between the l pair, baseline-breaking g descender). The ss pair is the
  riskiest site — avoid unless the result is unambiguous. FedEx/Braun bar:
  every other glyph flawless, word fully legible to viewers who never notice
  the trick.
- **Axis B — mark + tight wordmark lockup ×2:** NEW mark concepts (not
  codex's envelope+pane; not any A-R or 07r shape from v1.8). Mark must
  physically break a boundary: overshoot cap height, cross the baseline, or
  interlock with the first letter. Gap ≤ 0.4× mark width.
- **Axis C — monogram/glyph ×2:** `mg` ligature or single-glyph construction,
  16px-honest BY DESIGN (≤3 shapes at 16px, redrawn not scaled).
- **Axis D — negative space ×2:** the see-through idea carried by absence
  (void pane, shared figure/ground cut). No literal broken glass.
- Each option generated independently from the brand essence ("mail you can
  see through") — not derived from a shared sketch.

### Hard constraints (LOGO-06) — pre-flight screen, fix or replace before showing
- NO rectangular background plate behind any mark (no rounded-rect container,
  no badge, no plate). Options sit on the raw page background.
- Visible boundary-break at presentation size.
- Tight lockup: mark and name read as one unit.
- NO subtitle/slogan in the main lockup.
- Legible at 16px AND 32px (actual-size renders produced and checked).
- Works in single-color mono (currentColor) and on the dark theme.
- **NEVER touch the lowercase i dot** (burned in v1.8 — hard ban).
- No glassmorphism, bevels, lens flares, literal broken glass, paper planes,
  mailboxes, send arrows, chat bubbles, mascots, generic node-graphs.
- Honor the brief's banned-motif families and the v1.8 rejected evidence:
  do not revive ANY A-R option shape or the 07r envelope+pane structure.
- Valid standalone SVG, unique IDs, title/desc, role="img", viewBox.

### Craft discipline (from LOGO-CRAFT.md — follow exactly)
- Integer grid: x-height 100 units, stem weight S=22, consistent stroke
  logic across all glyphs.
- Optical corrections: thinned horizontals (~0.85×S), 3-unit round
  overshoot, joint thinning at branch connections.
- Letterforms drawn as paths from the per-glyph geometry recipes for
  m/a/i/l/g/s in LOGO-CRAFT.md. Round-1 options may use live text ONLY for
  throwaway comparison, never in anything presented — all presented
  wordmarks are paths.
- Run the 8-point AI-letterform self-audit on every option (curve quality,
  stroke-weight consistency, joint handling, spacing rhythm, baseline/
  x-height discipline, overshoot, counter shapes, optical centering).
- Lockup gap 0.5-0.75× x-height where axis B applies.

### Self-verification BEFORE the pause (anti-thrash, non-negotiable)
- Render the gallery in a real browser (Playwright, screenshots to ignored
  tmp/ dir) and VISUALLY AUDIT each option at full size, 32px, 16px, mono,
  and dark before presenting. Fix craft failures found. An option that fails
  the checklist is fixed or replaced, never shown.
- Use the Phase 86 tokens for all gallery colors (light + dark sections).

### Presentation (LOGO-07)
- Gallery: `.planning/phases/87-logo-tournament/tournament/round-1.html` —
  self-contained, opens from file://, light AND dark sections.
- Per option, a fixed evidence strip: (1) large render on light, (2) same on
  dark, (3) 32px + 16px actual-size in a fake browser-tab/favicon row,
  (4) mono/currentColor, (5) in-context fake GitHub README header,
  (6) ≤1 line of rationale.
- Options labeled 1-8, neutral, unranked.
- HARD PAUSE: present gallery path + summary to maintainer, ask for 1-2
  picks (or directional notes). If ALL 8 rejected: ONE replacement round of
  8 drawing on the failure notes, then pause again. Two consecutive full
  rejections → STOP and discuss (circuit breaker — no more generation).

### Refinement + promotion (LOGO-07, LOGO-08) — happens AFTER the pause
- Round 2: 4-6 variants of the pick(s); each variant changes ONE named
  parameter family (weight / motif intensity / gap / proportion / baseline
  relationship). Same evidence-strip format. Round 3 (≤4 candidates) is the
  hard cap.
- Promotion: winner outlined/cleaned, expanded to the full asset set in
  `brandbook-fable/assets/`: logo-primary.svg, logo-typemark.svg,
  logo-mark.svg, logo-monochrome.svg (currentColor), logo-with-tagline.svg
  (ONLY variant with a subtitle), favicon.svg (redrawn 16px-honest ≤3
  shapes), social-avatar.svg + social-avatar-dark.svg (square canvas is the
  documented plate exception). Zero `font-family` anywhere in assets/.
  Unique IDs, title/desc per asset. Decision record written.

### Plan structure note
- Split plans at the pause: 87-01 = build + pre-flight + gallery + present
  (ends at checkpoint). 87-02 = refinement rounds + promotion (blocked until
  the maintainer's selection is recorded). Do NOT plan 87-02's variants in
  detail — they depend on the picks; keep it structural.

### Claude's Discretion
- The 8 specific concepts (within the axes + constraints).
- Gallery page design (must use fable tokens, no plates behind marks).
- Color usage per option (Ink/Glass/glass-deep/Ice from tokens; mono must
  still work).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Craft + constraints (the spec for this phase)
- `.planning/research/v1.9-brandbook-fable/LOGO-CRAFT.md` — precedents, l·g·l cluster, grid + optical corrections, per-glyph geometry, 16px rules, self-audit checklist
- `.planning/phases/85-research-and-differentiation-brief/85-differentiation-brief.md` — banned motifs, compositional stance, ownable axis, non-negotiables
- `.planning/research/v1.9-brandbook-fable/PITFALLS-PORTABILITY.md` — SVG portability rules, AI-cliché screening
- `brandbook-fable/tokens.css` + `tokens.json` — colors for gallery + assets

### Negative evidence (what NOT to make — read once, do not imitate)
- `.planning/milestones/v1.8-phases/82-logo-and-svg-asset-system/82-02-CHECKPOINT.md` — the rejection history

### Requirements
- `.planning/REQUIREMENTS.md` — LOGO-05..08
- `.planning/ROADMAP.md` — Phase 87 success criteria + checkpoint annotation

</canonical_refs>

<specifics>
## Specific Ideas

- The maintainer responds to RENDERS, not essays. Rationale lines are ≤1
  sentence. The gallery is itself a brand artifact — calm, precise, no hype.
- The maintainer explicitly wants typemark options that are "a fully worked
  in custom type treatment", not "a shitty icon to the left of basic text".
  Axis A options are the chance to win the whole A/B here.

</specifics>

<deferred>
## Deferred Ideas

- Asset integration into the book — Phase 88.
- README header / social usage — Phase 89.

</deferred>

---

*Phase: 87-logo-tournament*
*Context gathered: 2026-06-11 via approved-plan express path*
