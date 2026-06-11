# Phase 86: Foundations — Palette, Type, Voice, Tokens - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Approved milestone plan + Phase 85 differentiation brief + v1.9 milestone research

<domain>
## Phase Boundary

Phase 86 creates the first `brandbook-fable/` artifacts: `tokens.json` and
`tokens.css` (draft status until Phase 88 finalizes), plus the decision record
and computed contrast matrix data in `.planning/phases/86-*/`. Every later
artifact (logo gallery rendering, book, specimens) consumes these tokens.

</domain>

<decisions>
## Implementation Decisions

### Token architecture (FOUND-02) — settled by research, follow exactly
- DTCG-2025.10 style: `$value` / `$type` / `$description`, hex-string values
  (documented deviation), `{group.token}` aliases. No `$schema` line.
- Two tiers only: `palette.*` (brand-named modifiers, not numeric ramps) →
  semantic roles. No component tier, no composite tokens, no build step.
- Dark mode = parallel role sets with identical keys; one CSS variable name
  per role, reassigned under `[data-theme="dark"]` in tokens.css.
- Roles must cover: background/surface/raised-surface/border/text/
  secondary-text/link/accent/focus + interaction states (default/hover/
  active/focus/disabled/selected) + feedback (success/warning/error/info,
  each with text/background/border) + type scale, space, radius, focus-ring.
- **The codex dark block reassigned only 18 of ~70 roles (CDX audit: callout
  text computed to Mist-on-Mist, invisible). The fable dark set must be
  COMPLETE: every role that exists in light exists in dark.**

### Palette (FOUND-01) — evolve-vs-keep pre-settled by computed math
- KEEP: Ink #0D1B2A, Glass #277B96 (4.82:1 on white — passes AA for normal
  text on Paper/white), Ice #A6EAF2, Mist #EAF6FB, Paper #F8FBFD,
  Slate #5C6B7A, Pine #166534, Crimson #B42318 (light theme).
- EVOLVE (computed fix values from TOKENS-A11Y.md — verify each ratio while
  building the matrix):
  - `glass-deep #1D637A` — link/text-accent on tinted surfaces (Glass fails
    on Mist/selected/info at 4.16–4.37)
  - `glass-deepest #174E61` — hover/active of glass-deep where needed
  - `amber-deep #96520E` — warning text on Mist (Amber #A95F10 is 4.40 there)
  - `slate-soft #74909F` (light) / `slate-bright #62809A` (dark) — input
    borders (seed borders were sub-3:1 against WCAG 1.4.11)
  - `crimson-bright #E29089` — dark-theme error text (codex's #D47368 was
    3.85–4.09 on raised dark surfaces)
- ADOPT: codex dark ramp #0D1B2A (bg) → #152538 (surface) → #1F3049
  (raised), Mist text, Ice accents — independently verified clean.
- OPEN (this phase decides): the four dark feedback BACKGROUNDS
  (success/warning/error/info surface tints) — pick and contrast-verify
  against the new `{kind}-text` values.

### Contrast matrix (FOUND-03)
- Compute with the actual WCAG relative-luminance formula (a throwaway local
  script is fine; commit only the resulting data). Every text-role/surface-
  role pair in BOTH themes, AA/AAA pass-fail for normal + large text, and a
  one-line usage rule per pair. The matrix data lands in the decision record
  now; Phase 88 renders it in the book (per the brief, as a
  runtime-computed-from-tokens table — so keep the data structured).

### Typography (FOUND-01)
- KEEP the stack: Inter Tight (display), Inter (UI/body), IBM Plex Mono
  (code) as *named preferences* — but per PITFALLS research, Inter is
  preinstalled nowhere; tokens.css must declare the honest system fallback
  stack (font-family: Inter, then system-ui/-apple-system/Segoe UI/Roboto/
  Helvetica Neue/sans-serif; mono: IBM Plex Mono, ui-monospace, SFMono-
  Regular, Menlo, Consolas, monospace) and the decision record must state
  that most viewers see the fallback. No webfont embedding (scope lock).
- Type scale tokens: display/h1/h2/h3/body/small/code with px values
  (seed: 40-48 display, 30-36 h2, 22-26 h3, 16-18 body, 14 small,
  13-14 code — refine into one exact scale).

### Voice (FOUND-01, light touch)
- Voice seeds are KEEP (thoughtful maintainer, calm/exact/confident/warm) —
  record the decision in the decision record; the full voice system ships in
  Phases 88/89, not here.

### Hygiene (FOUND-04)
- Zero process vocabulary in tokens.json/tokens.css (no "phase", "plan",
  "milestone", "codex", "draft pending", "TBD"). Token descriptions describe
  USAGE, not provenance. This was codex defect CDX-level leakage — gate it
  in-phase with a grep, don't wait for Phase 90.

### UI-SPEC decision
- No separate UI-SPEC.md for this phase: the design contract is
  `85-differentiation-brief.md` + `TOKENS-A11Y.md` (tokens are the spec).
  Phase 88 (the actual page) gets the UI treatment via the brief's locked
  section outline.

### Claude's Discretion
- Exact dark feedback background tints (must pass the matrix).
- Space/radius/focus-ring token values (sensible, minimal, brand-consistent).
- Decision-record file structure.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked upstream
- `.planning/phases/85-research-and-differentiation-brief/85-differentiation-brief.md` — differentiators, non-negotiables, manifest, budgets
- `.planning/research/v1.9-brandbook-fable/TOKENS-A11Y.md` — token architecture, computed ratios, fix hexes, dark ramp
- `.planning/research/v1.9-brandbook-fable/PITFALLS-PORTABILITY.md` — font fallback honesty, file:// rules
- `.planning/REQUIREMENTS.md` — FOUND-01..04
- `.planning/ROADMAP.md` — Phase 86 success criteria

### Seeds
- `prompts/mailglass-brand-book.md` — palette/type/voice seeds

</canonical_refs>

<specifics>
## Specific Ideas

- tokens.css is what the Phase 88 live component gallery and Phase 89
  landing page import directly — it must be genuinely usable CSS, not
  documentation.
- File size sanity: tokens.json ~12 KB, tokens.css ~6 KB per the manifest.

</specifics>

<deferred>
## Deferred Ideas

- Rendering the contrast matrix in HTML — Phase 88.
- Voice system expansion (microcopy, copy blocks) — Phases 88/89.

</deferred>

---

*Phase: 86-foundations-palette-type-voice-tokens*
*Context gathered: 2026-06-11 via approved-plan express path*
