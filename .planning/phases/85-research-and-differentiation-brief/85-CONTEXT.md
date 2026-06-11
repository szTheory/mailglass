# Phase 85: Research and Differentiation Brief - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Approved milestone plan (maintainer-approved via plan mode, 2026-06-11) + v1.9 milestone research

<domain>
## Phase Boundary

Phase 85 produces the decision foundation for the entire fable brand book —
a forensic audit of the codex `brandbook/` (frozen at commit `09a84dd4`) and a
locked differentiation brief — **before any `brandbook-fable/` artifact is
authored**. All Phase 85 artifacts live in `.planning/phases/85-*/`. Nothing
is created under `brandbook-fable/` in this phase.

</domain>

<decisions>
## Implementation Decisions

### Audit (BRIEF-01)
- The audit is a row-addressable defect/gap register of the codex brandbook:
  each row has a stable ID, file-and-line evidence, severity, and the fable
  response (exploit / fix / ignore).
- Every claimed weakness MUST be verified against actual file contents — no
  straw men. Three already-verified defects to re-confirm and extend:
  (1) `brandbook/assets/logo-primary.svg:17` live `<text>` in macOS-only
  Avenir Next + a gradient its own brand-book.md forbids;
  (2) `brandbook/tokens.json:70,75-76` planning-language leakage referencing
  a contrast validation that never ran;
  (3) dark tokens defined in tokens.css/tokens.json but never demonstrated in
  index.html.
- Also audit what codex did WELL (it has semantic state tokens, callout/code
  roles, a dark token set) — false differentiators discredit the A/B.

### Differentiation brief (BRIEF-02)
- ≤12 differentiators, each with a one-line "why it earns its bytes".
  Starting draft (validate, prune, or replace — do not pad): outlined
  font-independent logo; integrated custom typemark; demonstrated dark mode
  with toggle; live HTML component gallery; shipped WCAG contrast matrix;
  zero planning-language leakage; landing-page blueprint; branded email
  specimen; per-surface copy library + domain-noun microcopy; diagram
  language spec.
- The brief locks the brand-book section outline (consumed by Phase 88) and
  an explicit kill-list (personas, mission statements, mood boards,
  print/stationery, icon libraries, motion videos — already excluded in
  REQUIREMENTS.md Out of Scope; the brief may extend this).
- The brief defines the `brandbook-fable/` file manifest (~21 files across
  root, assets/, examples/, copy/) with size budgets: folder ≤ 500 KB,
  index.html ≤ 150 KB, no file > 100 KB.

### Inputs already on disk (do not regenerate)
- `.planning/research/v1.9-brandbook-fable/SUMMARY.md` + the four research
  files (BRAND-SYSTEMS, LOGO-CRAFT, TOKENS-A11Y, PITFALLS-PORTABILITY) —
  milestone-level research is DONE; Phase 85 consumes it.
- The audit reads `brandbook/` once; later creative phases work from the
  brief + seeds only (anti-derivative rule).

### Claude's Discretion
- Audit register format and row taxonomy.
- How to organize the brief (single file vs. brief + manifest), as long as
  both BRIEF requirements are satisfied and downstream phases (86-90) can
  consume it without reading codex's brandbook again.
- Whether to fold the 28-pitfall register's phase mappings into the brief or
  reference PITFALLS-PORTABILITY.md directly.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope and requirements
- `.planning/REQUIREMENTS.md` — BRIEF-01/02 texts and milestone scope locks
- `.planning/ROADMAP.md` — Phase 85 goal and success criteria

### Research (consumed, not regenerated)
- `.planning/research/v1.9-brandbook-fable/SUMMARY.md` — synthesis + settled decisions
- `.planning/research/v1.9-brandbook-fable/BRAND-SYSTEMS.md` — pattern catalog, steal/avoid lists, HTML book guidance
- `.planning/research/v1.9-brandbook-fable/PITFALLS-PORTABILITY.md` — 28 phase-mapped pitfalls, AI-cliché checklist

### Audit target (read-only, frozen)
- `brandbook/` at commit `09a84dd4` — especially brand-book.md, tokens.json,
  tokens.css, index.html, assets/logo-primary.svg, examples/

### Brand strategy seeds
- `prompts/mailglass-brand-book.md` — locked essence, voice, palette/type seeds

</canonical_refs>

<specifics>
## Specific Ideas

- The brief is the anti-thrash and anti-derivative contract for the milestone:
  Phases 86-89 work from the brief + seeds, never from codex's files.
- Honest A/B framing matters to the maintainer: verified defects only,
  acknowledge codex strengths, kill false differentiators.

</specifics>

<deferred>
## Deferred Ideas

None — phase scope fully defined by BRIEF-01/02 and the approved milestone plan.

</deferred>

---

*Phase: 85-research-and-differentiation-brief*
*Context gathered: 2026-06-11 via approved-plan express path*
