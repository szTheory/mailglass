# Phase 90: Quality Gate and Maintainer UAT - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Approved milestone plan + REQUIREMENTS GATE-01..03

<domain>
## Phase Boundary

Phase 90 proves `brandbook-fable/` is standalone, clean, and A/B-ready via a
scripted gate + browser evidence, then hands the maintainer the side-by-side
A/B walkthrough for sign-off. Gate evidence lives in `.planning/phases/90-*/`;
fixes (if any) go to `brandbook-fable/`.

</domain>

<decisions>
## Implementation Decisions

### Scripted gate (GATE-01) — one consolidated script run, all checks recorded
1. `xmllint --noout` every SVG in brandbook-fable/ (assets + examples).
2. `python3 -m json.tool brandbook-fable/tokens.json`.
3. Local-reference integrity: every href/src in every HTML file resolves to
   a file on disk; zero `https?://` external URLs anywhere (html+css+svg).
4. Process-vocabulary denylist (case-insensitive): phase, plan, milestone,
   codex, gsd, tournament, checkpoint, draft, TBD, option-, variant-, req-,
   baseline → zero hits across brandbook-fable/ ("plan" must not
   false-positive on words like "transparent" — use word boundaries; the
   established Phase 88/89 denylist command is the precedent).
5. `font-family` and `<text` in brandbook-fable/assets/*.svg → zero.
6. No background-plate rect behind any mark (structural check + the
   documented square social-avatar exception).
7. Size budgets: folder ≤ 500 KB, index.html ≤ 150 KB, no file > 100 KB.
8. Favicon ≤ 3 shape elements; viewBox 0 0 16 16.
9. Scope: working tree clean; frozen brandbook/ untouched since 09a84dd4;
   no file outside brandbook-fable/ + .planning/ changed during v1.9 phases
   88-90 (commit-range check).

### Browser evidence (GATE-02)
- Playwright screenshots to a gitignored tmp dir: index.html light + dark
  (1440), 390px mobile, favicon at 16px light + emulated-dark, landing page
  light/dark, email at 600px. READ each screenshot; confirm rendering.
- Record the evidence index (filenames + verdicts) in
  `.planning/phases/90-quality-gate-and-uat/90-gate-evidence.md`.

### Maintainer UAT (GATE-03) — the milestone's final human step
- Present the maintainer with the A/B: `brandbook/index.html` (codex) vs
  `brandbook-fable/index.html` (fable) side by side, plus a one-screen
  summary of what to look at (the 12 differentiators as a checklist).
- The maintainer's sign-off (or punch list) is recorded; punch-list items
  get fixed in-phase before close.

### Claude's Discretion
- Gate script organization (inline bash vs a small script in the phase dir
  — NOT shipped inside brandbook-fable/).

</decisions>

<canonical_refs>
## Canonical References

- `.planning/REQUIREMENTS.md` — GATE-01..03 (the gate IS the requirement text)
- `.planning/phases/85-research-and-differentiation-brief/85-differentiation-brief.md` — the 12 differentiators (UAT checklist source) + budgets
- `.planning/phases/87-logo-tournament/87-decision-record.md` — plate exception + usage rules
- Phase 88/89 plan gate commands — the established denylist/size/reference check forms

</canonical_refs>

<specifics>
## Specific Ideas

- The gate must not weaken any check that Phases 86-89 already enforced —
  it re-proves them all on the final state in one place.

</specifics>

<deferred>
## Deferred Ideas

- A/B winner adoption (renaming folders, README propagation) — future
  milestone per REQUIREMENTS.

</deferred>

---

*Phase: 90-quality-gate-and-uat*
*Context gathered: 2026-06-11 via approved-plan express path*
