# Phase 81: Brandbook Source and Token System - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-06
**Phase:** 81-brandbook-source-and-token-system
**Mode:** assumptions
**Areas analyzed:** phase boundary, draft artifact treatment, brand center, token system, admin design-system boundary, static HTML

## Assumptions Presented

### Phase Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 81 should only revise `brandbook/index.html`, `brandbook/brand-book.md`, `brandbook/tokens.json`, and `brandbook/tokens.css`; logo assets, specimens/copy blocks, repo hygiene scripts, package allowlist proof, and validation gates stay in Phases 82-84. | Likely | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md`, `brandbook/brand-audit.md` |

### Draft Artifact Treatment

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 81 should remove or soften any wording that treats the current `brandbook/` set as approved/final, while still preserving useful draft material. | Confident | `brandbook/brand-audit.md` `BRAND-GAP-01`, `.planning/STATE.md`, `brandbook/README.md`, `brandbook/index.html` |

### Brand Center

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Preserve the current brand center: "Mailglass makes email visible," "Mail you can see through," thoughtful-maintainer voice, Phoenix-native transactional/operational positioning, and "glass is a metaphor, not a visual excuse." | Confident | `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `brandbook/brand-book.md`, `brandbook/brand-audit.md`, `prompts/mailglass-brand-book.md` |

### Token System

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep tokens small, role-based, and brandbook-scoped: palette, semantic light/dark roles, state, callout, code, typography, spacing, radius, border, shadow, focus, and motion. Add explicit text vs non-text contrast guidance, especially for callouts and state colors. | Likely | `brandbook/tokens.json`, `brandbook/tokens.css`, `brandbook/brand-audit.md` `BRAND-GAP-08`, `mailglass_admin/docs/design-system.md` |

### Admin Design-System Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The brandbook must align with `mailglass_admin/docs/design-system.md` but must not replace or fork the implemented admin UI token system. Admin remains Tailwind v4 + daisyUI semantic mechanics; brandbook tokens are for docs, marketing, examples, and future collateral. | Confident | `mailglass_admin/docs/design-system.md`, `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md` D-10, `brandbook/README.md`, `brandbook/tokens.json` meta notes |

### Static HTML

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep `brandbook/index.html` direct-open, static, and source-native; update content to reflect Phase 80's audit/register posture and token guidance, without adding build tooling or external asset services. | Likely | `.planning/ROADMAP.md`, `brandbook/index.html`, `brandbook/README.md`, `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md` D-17 |

## Corrections Made

No corrections. The maintainer selected option 1, "Yes, proceed," after the
assumptions were presented.

## External Research

No new external research was performed for Phase 81. Phase 80 already captured
the relevant accessibility, token, design-system, docs, and ecosystem lessons;
Phase 81 is a repo-grounded reconciliation of those decisions against the
source brandbook and token artifacts.
