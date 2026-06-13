# Phase 92: Surface Propagation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-12T21:56:50-04:00
**Phase:** 92-surface-propagation
**Mode:** assumptions
**Areas analyzed:** README Header, Social Preview PNG, Upload Documentation, Admin Wordmark, Verification and Scope

## Assumptions Presented

### README Header

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Add `brandbook/examples/readme-header.svg` as the first visible README brand surface, with badges and existing product copy kept below it. | Likely | `README.md`; `brandbook/examples/readme-header.svg`; `brandbook/brand-book.md` |

### Social Preview PNG

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Export and commit only `brandbook/examples/og-card.png` from `brandbook/examples/og-card.svg` at 2400x1260 via the verified Playwright command, then verify dimensions and file size. | Confident | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`; `brandbook/examples/og-card.svg` |

### Upload Documentation

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Document GitHub social-preview upload steps in `brandbook/README.md`, including the v1.10 exception to its current "PNG exports are never committed" rule. | Confident | `brandbook/README.md`; `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`; `.planning/REQUIREMENTS.md` |

### Admin Wordmark

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Replace the old admin placeholder with the sealed-flap identity now, not defer it, but make the admin rendering theme-aware rather than copying the light-surface primary logo verbatim. | Likely | `mailglass_admin/priv/static/mailglass-logo.svg`; `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`; `mailglass_admin/lib/mailglass_admin/components.ex`; `mailglass_admin/lib/mailglass_admin/operator/shell.ex`; `mailglass_admin/assets/css/app.css`; `brandbook/assets/logo-primary.svg`; `brandbook/assets/logo-monochrome.svg` |

### Verification and Scope

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep HexDocs logo/favicon wiring and SVG width/height prep out of phase 92; verify phase 92 with README/SVG render checks, PNG dimension/size checks, and `mix verify.preview` if admin code/static changes. | Confident | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-CONTEXT.md`; `mailglass_admin/mix.exs` |

## Corrections Made

No corrections - all assumptions confirmed.
