# Phase 110: Primitives - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-18
**Phase:** 110-primitives
**Mode:** assumptions
**Areas analyzed:** Public Primitive Ownership, Theme Picker Boundary, Stat And Icon Gates, Target-Size Interpretation

## Assumptions Presented

### Public Primitive Ownership
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Promote `nav_link`, `nav_pill`, `tenant_chip`, the theme picker, and `stat_card` into `MailglassAdmin.Components`; shell and gallery render those public primitives instead of private/inlined HEEx. | Confident | `mailglass_admin/lib/mailglass_admin/components.ex`; `mailglass_admin/lib/mailglass_admin/operator/shell.ex:223-295`; `mailglass_admin/lib/mailglass_admin/gallery_live.ex:161-243`; `.planning/ROADMAP.md` Phase 110 |

### Theme Picker Boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The 3-way picker models `:system \| :light \| :dark`, with `:system` represented as no explicit theme value; Phase 110 provides the primitive while Phase 112 owns persistence/no-FOUC wiring. | Confident | `.planning/phases/109-foundations-gate-tightening/109-CONTEXT.md`; `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex`; `mailglass_admin/lib/mailglass_admin/layouts.ex`; `mailglass_admin/assets/css/app.css`; `mailglass_admin/lib/mailglass_admin/preview_live.ex` |
| The picker should use radio-group semantics visually styled as a segmented control, not three independent `aria-pressed` toggle buttons. | Confident after external research | WAI-ARIA APG Radio Group Pattern; WAI-ARIA APG Button Pattern |

### Stat And Icon Gates
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `stat_card` becomes the canonical KPI primitive in `MailglassAdmin.Components`, and Phase 110 gates should enforce both stat usage/shape and icon existence against the vendored inline Heroicons set. | Confident | `mailglass_admin/lib/mailglass_admin/operator_live.ex:291-326`; `mailglass_admin/lib/mailglass_admin/inbound/overview.ex:45-54`; `.planning/ROADMAP.md` Phase 110; `mailglass_admin/lib/mailglass_admin/components.ex`; `mailglass_admin/assets/vendor/heroicons-inline.js` |

### Target-Size Interpretation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| WCAG 2.2 AA gating is 24x24 CSS px minimum or documented SC 2.5.8 exception; the roadmap's stricter 44x44 floor remains default for ordinary primitives, with dense 24px exceptions explicitly recorded. | Confident after external research | WCAG 2.2 SC 2.5.8; Understanding Target Size Minimum; `.planning/ROADMAP.md` Phase 110 |

## Corrections Made

No corrections — user selected "Yes, proceed" (`1`). All assumptions were confirmed and locked as
decisions D-01..D-13 in CONTEXT.md.

## Auto-Resolved

Not applicable — this run was not `--auto`.

## External Research

- **Theme picker APG semantics:** Use a radio group, visually styled as segmented control. Native
  radios in `fieldset`/`legend` are preferred; custom markup should use `role="radiogroup"`,
  child `role="radio"`, and `aria-checked`. Three `aria-pressed` toggle buttons are the wrong
  semantic model for one-of-three selection. Source: WAI-ARIA APG Radio Group Pattern
  (`https://www.w3.org/WAI/ARIA/apg/patterns/radio/`) and Button Pattern
  (`https://www.w3.org/WAI/ARIA/apg/patterns/button/`).
- **WCAG 2.2 target size:** SC 2.5.8 AA requires 24x24 CSS px pointer targets or a documented
  exception; dense controls do not receive a blanket exception. Exact 24px targets can pass AA,
  while 44x44 remains a stricter comfort/enhanced requirement when the roadmap demands it. Source:
  WCAG 2.2 Target Size Minimum
  (`https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html`) and WCAG 2.2 normative
  text (`https://www.w3.org/TR/WCAG22/`).
