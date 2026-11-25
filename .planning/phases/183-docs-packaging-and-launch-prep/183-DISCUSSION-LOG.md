# Phase 183: Docs, Packaging and Launch Prep - Discussion Log (Assumptions Mode)

> **Audit trail only.** Decisions captured in `183-CONTEXT.md`; this log preserves their evidence and consequences.

**Date:** 2026-11-16  
**Phase:** 183-docs-packaging-and-launch-prep  
**Mode:** assumptions (autonomous continuation)  
**Areas analyzed:** README renderer compatibility; ExDoc; package contents; design docs; favicon evidence; trademark gate; launch boundary and plan budget.

## Evidence Sources

- `.planning/research/brand-v2-adoption/PHASE-183-A-readme-hexpm.md`
- `.planning/research/brand-v2-adoption/PHASE-183-C-design-system-docs.md`
- `.planning/research/brand-v2-adoption/PHASE-183-D-lint-allowlist.md`
- `.planning/research/brand-v2-adoption/PHASE-183-E-favicon-social-gate.md`
- `183-RESEARCH.md` (synthesis and local ExDoc 0.40.4 source inspection)
- `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` Phase 183 scope; `.planning/PROJECT.md` owner hand-off rules
- `deps/ex_doc/lib/ex_doc/formatter.ex`, `formatter/html.ex`, `formatter/config.ex`, and the pinned ExDoc CSS
- `.planning/research/brand-v2-adoption/trademark-search.json`; Phase 179 `179-VERIFICATION.md` and `179-REVIEW-DISPOSITION.md`

## Assumptions Presented

| ID | Assumption / decision | Confidence | Evidence | If wrong |
|---|---|---|---|---|
| D-01 | Use paired theme-specific README images because Hex.pm strips picture/source and ExDoc does not follow the Hex/GitHub theme toggle through OS media queries. | Confident | Phase 183 A live/source investigation and renderer-specific CSS. | GitHub's fragment convention could change; screenshots and an extractor contract expose breakage. |
| D-02 | Pin README images to the full immutable SHA of the asset commit instead of creating and pushing a remote tag. | Likely | Phase 183 A documents the tag requirement and a SHA fallback; project authorization excludes remote tag publication. | If public URLs must use a readable version tag, a later authorized operation can add it and update the README. |
| D-03 | Preserve ExDoc's Lato body type and theme toggle; add only code-color CSS and use SVG v2 mark/favicon assets. | Confident | ExDoc 0.40.4 local formatter accepts SVG, supports copied assets and head-tag injection; shipped CSS uses Lato and class selectors without `prefers-color-scheme`. | A custom selector might override future ExDoc CSS; generated output checks constrain the override to code colors. |
| D-04 | Keep the admin design guide, add root design guidance and a parity-checked `.impeccable` config, and scope the Inter exception to the unsubscribe template. | Likely | Phase 183 C analysis; `brand.json` and `tokens.json` are the pinned sources. | A glob or token can drift; the proposed contract checks token parity and matching tracked paths. |
| D-05 | Add brand assets through `brand_pin.exs update`; capture favicon evidence across three engines and recompute metrics from committed PNG bytes. | Confident | Phase 183 E report and existing brand-pin/catalog patterns. | Automated `<img>` rendering cannot prove Safari tab chrome; disclose this limit and keep a physical-device check optional. |
| D-06 | Harden WR-01/WR-02 and keep announcement/TM claims blocked while allowing package/code checks. | Confident | Phase 179 verifier reproductions; current record is `caution` and `register_checked:false`; Phase 183 E maps the gate. | A too-broad scan could block ordinary prose; use explicit file classes, exclusions and mutation cases. |
| D-07 | Do not update canonical CLAUDE.md/PRODUCT.md, publish, send the announcement, upload the social card or alter personal avatars. | Confident | Phase 183 requirements and project owner-handoff boundary. | This leaves manual follow-up after the phase; drafts/checklist make that follow-up concrete. |
| D-08 | Fit BRDOC-01..06 into exactly two plans. | Confident | ROADMAP has a maximum of 20 plans and Phase 182 ended at 18. | If the plan checker finds the evidence cannot fit coherently, stop for owner direction rather than exceed the cap. |

## Corrections Made

No owner correction was requested during this autonomous resume. The evidence-backed README recommendation amends the current literal `<picture>` wording; the planner must update the requirement and roadmap text together. The user can still veto the documented recommendations before a public ref or release is created.

## Auto-Resolved

- Personal GitHub/Gravatar avatar change: skip; use only repository-scoped social preview assets.
- README source ref: immutable commit SHA, not a new remote tag.
- Public launch claims: remain blocked by the existing trademark record.
- Plan count: maximum two.

## External Research

- ExDoc official project/docs: https://github.com/elixir-lang/ex_doc
- ExDoc 0.40.4 implementation is installed locally under `deps/ex_doc/`; no new dependency is needed.
- Hex.pm, GitHub rendering and favicon evidence is retained in the four original area reports.
