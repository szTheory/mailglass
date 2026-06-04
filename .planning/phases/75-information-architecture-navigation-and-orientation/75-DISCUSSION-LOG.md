# Phase 75: Information Architecture, Navigation and Orientation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 75-information-architecture-navigation-and-orientation
**Mode:** assumptions
**Areas analyzed:** Orientation strip generalization, Preview empty-state co-existence, Operator Overview routing, Suppression count placement, IA vocabulary + e2e co-update, GAP-citation + a11y split, 390px acceptance

## Methodology

Codebase analyzed via `gsd-assumptions-analyzer` (15 tool uses, ~90k tokens) plus direct orchestrator verification of the router and `handle_params/3` reality. Calibration tier: minimal_decisive (project methodology = decisive-by-default). Phase 75 is heavily pre-specified by the frozen `74-UI-SPEC.md`, so analysis focused on HOW decisions and verifying the spec's file:line claims against the live code.

## Assumptions Presented

### Orientation Strip Generalization (IA-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extract `orientation_strip/0` defp → public `Shell.orientation_strip/1` after `flash_region/1`, single `attr :surface` discriminator with frozen copy table baked in; testids `{surface}-orientation` | Confident | `operator_live.ex:362` (defp), `shell.ex:102` (active discriminator precedent), UI-SPEC §Orientation Strip Contract (copy table locked), triggers at `operator_live.ex:254` / `inbound_live.ex:330` / `preview_live.ex:291` |

### Preview Empty-State Co-existence (IA-01, D-09)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Strip SUPPLEMENTS (not replaces) the existing `preview-empty-mailables` card; preserve testid + router-config hint | Likely | `preview_live.ex:291-323`, UI-SPEC:308 (defers co-existence to Phase 75) |

### Operator Overview Routing (IA-02) — the one genuine fork
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No router change possible (`:index`-only); params-based branch in `handle_params/3`; bare `/ops/mail/` → Overview, `?view=deliveries` → list; `tenant_id` orthogonal; nudge vs health branch on tenant presence | Likely | `router.ex:261`/`:270` (single `:index`, no `:overview`/`/deliveries`), `operator_live.ex:71` (handle_params), `:417` (`load_deliveries(tenant_id: "") -> []`), UI-SPEC §Route Mechanics + :292 |

### Suppression Count Placement (IA-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add `count_active_suppressions/1` to CORE `mailglass` (additive, mirrors active-entry filter); read via runtime seam, degrade to "—" | Confident | `suppressions.ex:18` (only `get_delivery_suppression_state/2`), `:26-28` (filter), `support_summary.ex:29-34` (no suppression field), `operator_live.ex:670` (indirection seam), UI-SPEC:436/218 |

### IA Vocabulary + Same-Commit e2e (IA-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Existing titles conformant; new Overview h1 "Operator overview"; root→Overview breaks heading assertions, updated same commit | Confident | `operator_live.ex:250`, `inbound_live.ex:271`, `operator.spec.js:19`, `demo.spec.js:27/41`, IA-03 mandate |

### GAP-citation Discipline + a11y Split (IA-04, GAP-21)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Cite only GAP-07/09/11/22; a11y limited to new Overview (`aria-current` + h1/h2); do not pull GAP-13 (P76) / GAP-19 (P77) despite line-193 mis-tag; defer GAP-22 to Phase 79 | Confident | GAP-REGISTER:175/177/185/193/199-201, `shell.ex` (aria-current present), `operator.spec.js:47` (aria-selected present) |

### 390px Acceptance (IA-03, GAP-07/09/11)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Verify via local screenshot→LLM-critique ritual + extended Playwright 390px structural test; no CI visual regression | Likely | GAP-REGISTER:132/139/146, `operator.spec.js:64-89`, VR-NEXT-01 (out of scope) |

## Corrections Made

No corrections — user selected "Yes, proceed"; all 7 assumptions confirmed and locked as D-01..D-18 in CONTEXT.md.

## Notable Discrepancy Surfaced

The UI-SPEC's "`:overview` action" language is not literally implementable: the operator router (`router.ex:261`) exposes only `live "/", OperatorLive, :index` (and `/inbound`), with no `:overview` live_action and no `/deliveries` route. A true Phoenix `live_action` would require a router-macro change, which the milestone forbids. Resolved decisively from code alone: the Overview is a **params-based state** inside the single `:index` `handle_params/3`, with `?view=deliveries` as the list discriminator and `tenant_id` kept orthogonal (D-07/D-08). No external research required.

## External Research

None performed — the frozen UI-SPEC, gap register, and existing repo patterns settled every gray area.
