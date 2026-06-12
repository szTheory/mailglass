# Phase 88: Brand Book Assembly - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Approved milestone plan + 85-differentiation-brief (locked section outline) + 87-decision-record + BRAND-SYSTEMS research

<domain>
## Phase Boundary

Phase 88 builds the standalone brand book: `brandbook-fable/index.html`,
`brand-book.md`, `README.md`, and finalizes the token files' status. This is
the craft phase — the HTML book is itself the strongest specimen of the
brand and the primary A/B artifact against `brandbook/index.html`.

</domain>

<decisions>
## Implementation Decisions

### index.html (BOOK-04/05/06)
- Fully self-contained: embedded CSS (tokens.css content inlined or linked
  relatively — linking `tokens.css` relatively is allowed since it ships in
  the same folder; zero external/network requests either way), no webfonts,
  no JS frameworks. The ONLY script is a small theme toggle (~20 lines).
- Light/dark: manual toggle + `prefers-color-scheme` default. The toggle
  re-skins EVERY specimen on the page via the `[data-theme="dark"]` token
  reassignments (the Geist pattern from BRAND-SYSTEMS research — this is
  the differentiator that closes the codex "dark undemonstrated" defect).
- Section outline: USE THE PHASE 85 BRIEF'S LOCKED OUTLINE VERBATIM (9
  sections). Do not invent a different structure.
- Live component gallery: REAL buttons/inputs/badges/alerts/tabs/code
  blocks built from the token custom properties with working hover/focus/
  disabled states (focus visible via keyboard). Not pictures.
- Contrast matrix: rendered as a table computed at page load from the token
  values by ~20 lines of inline JS (the BRAND-SYSTEMS "can never drift from
  tokens" rigor signal), with a noscript fallback note. Data must agree with
  the Phase 86 computed record (spot-check anchors: Ink/Paper 16.74,
  Glass/white 4.82).
- Logo system section: all 8 canonical assets shown per the decision
  record's usage rules — light expression on light surface, mono/
  currentColor demonstrated on dark, favicon at actual 16/32px, the color
  program table, and the usage rules stated (primary never on dark).
- Voice section, imagery/diagram language summary per the brief outline.
- Size budget: index.html ≤ 150 KB.

### brand-book.md (BOOK-07)
- Parallel source-of-truth markdown, LLM-scannable: consistent heading
  grammar, exact hex/px values inline, tables. Covers the same ground as
  index.html (it is the text master; the HTML is the rendered experience).
- Born-finished language: zero process vocabulary, no references to the old
  brandbook, no phase/plan/milestone words. Reads as if the brand always
  existed.

### README.md (BOOK-07)
- Orientation (what this folder is, how to view index.html), usage rules
  digest, export policy (SVG-first; PNG exports generated locally only when
  a launch surface needs them; og-card SVG is a template, not a direct
  og:image — crawlers don't render SVG).

### Tokens finalization (carried from Phase 86)
- Remove any "draft" status implications if present (there should be none);
  tokens.json/tokens.css are already hygiene-clean — verify, don't rewrite.

### Self-verification (non-negotiable)
- Playwright audit before completion: screenshot light + dark full pages,
  the component gallery (hover/focus states via keyboard emulation where
  feasible), the logo section, and mobile width (390px). READ the
  screenshots, fix visual issues, re-render. The book must be beautiful —
  "a work of art, amazing reference for llm and human."
- file:// compatibility: no fetch() of local JSON (file:// blocks it — the
  contrast matrix JS must read token values from CSS custom properties via
  getComputedStyle, not fetch tokens.json).

### Claude's Discretion
- Page design language (within tokens + brief outline): layout, nav
  (sidebar vs top), typography rhythm. Make it distinctly mailglass — calm,
  precise, glass-as-metaphor — and clearly better-crafted than the codex
  book's generic two-column.
- How much of tokens.css to inline vs link.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/85-research-and-differentiation-brief/85-differentiation-brief.md` — THE LOCKED SECTION OUTLINE + differentiators + kill-list + budgets
- `.planning/phases/87-logo-tournament/87-decision-record.md` — asset mapping, color program, usage rules
- `.planning/phases/86-foundations-palette-type-voice-tokens/86-foundations-decisions.md` — contrast matrix data + evolve-vs-keep records (source for voice/type sections)
- `.planning/research/v1.9-brandbook-fable/BRAND-SYSTEMS.md` — HTML book guidance, steal/avoid patterns
- `.planning/research/v1.9-brandbook-fable/PITFALLS-PORTABILITY.md` — file:// rules, honest font stacks
- `brandbook-fable/tokens.css` + `tokens.json` + `assets/` — the materials
- `prompts/mailglass-brand-book.md` — voice seeds for the voice section
- `.planning/REQUIREMENTS.md` — BOOK-04..07

</canonical_refs>

<specifics>
## Specific Ideas

- The A/B is decided largely on this page. The codex book is a competent
  generic two-column doc; this one must feel designed — the brand's own
  calm precision applied to itself.
- Demonstrate, don't claim: dark mode shown live, contrast computed live,
  components actually focusable.

</specifics>

<deferred>
## Deferred Ideas

- Landing page, email template, specimen SVGs, copy library — Phase 89.
- Final gate scripts — Phase 90.

</deferred>

---

*Phase: 88-brand-book-assembly*
*Context gathered: 2026-06-11 via approved-plan express path*
