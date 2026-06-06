# Phase 82: Logo and SVG Asset System - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-06
**Phase:** 82-logo-and-svg-asset-system
**Mode:** assumptions
**Areas analyzed:** Phase Boundary, Logo Direction, SVG Accessibility And Distribution, Small-Size Monochrome And Dark Use, Methodology

## Assumptions Presented

### Phase Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 82 should update the logo/SVG brandbook surface, not package code or admin UI code. It may add a durable logo-option review artifact under `brandbook/` and update logo-specific wording in `brandbook/index.html` / `brandbook/brand-book.md` if needed, but it should not touch README, Hex copy, public APIs, release workflow, or `mailglass_admin` implementation. | Confident | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md`; `.planning/phases/81-brandbook-source-and-token-system/81-CONTEXT.md`; `brandbook/index.html`; `mailglass_admin/mix.exs` |

### Logo Direction

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The current pane/message-fold mark is a credible starting direction, but Phase 82 should compare three compact options before finalizing: current folded pane, simplified pane/message lines with no triangular fold, and a more inspection/pane-forward mark. Default final posture should stay wordmark-first and refine toward the simplest small-size-safe pane mark. | Likely | `brandbook/brand-audit.md` rows `BRAND-GAP-04` and `BRAND-GAP-05`; `brandbook/assets/*.svg`; `brandbook/brand-book.md` |

### SVG Accessibility And Distribution

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Final SVGs should keep `role="img"`, `title`, `desc`, `viewBox`, no rasters/fonts/scripts/external refs, and unique accessibility IDs per asset instead of repeated `id="title"` / `id="desc"`. Keep the primary lockup editable with live text for source use; keep favicon/mark/avatar path-only; defer outlined wordmark exports unless a real launch surface needs pixel-exact distribution. | Confident | `brandbook/assets/logo-primary.svg`; `brandbook/assets/logo-mark.svg`; `brandbook/assets/logo-monochrome.svg`; `brandbook/assets/favicon.svg`; `brandbook/assets/social-avatar.svg`; `brandbook/brand-audit.md` row `BRAND-GAP-06`; `brandbook/README.md` export policy |

### Small-Size, Monochrome, And Dark Use

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 82 should explicitly prove or revise favicon, monochrome, and reversed/dark use. If the triangular fold still reads like a document corner, envelope, or send arrow at 16-32px, simplify it rather than adding detail. | Likely | `brandbook/brand-audit.md` row `BRAND-GAP-05`; `brandbook/assets/favicon.svg`; `brandbook/assets/logo-monochrome.svg`; `brandbook/assets/social-avatar.svg`; `brandbook/tokens.json`; `brandbook/tokens.css` |

### Methodology

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Decisive-by-default and recommendation-first apply here: the repo already points to a narrow default. Honest Surface Area also applies: Phase 82 should approve logo assets only, and leave copy/specimens/validation/package proof to Phases 83-84. | Confident | `.planning/METHODOLOGY.md`; `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; Phase 80 and Phase 81 contexts |

## Corrections Made

No corrections - all assumptions confirmed.

## External Research

No external research was performed. The local audit, brandbook, tokens, and SVG
assets provided enough evidence for Phase 82 planning context.
