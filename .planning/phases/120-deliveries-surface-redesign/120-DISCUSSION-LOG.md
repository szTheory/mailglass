# Phase 120: Deliveries surface redesign - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-26
**Phase:** 120-deliveries-surface-redesign
**Mode:** assumptions
**Calibration:** minimal_decisive (vendor_philosophy=opinionated; METHODOLOGY.md decisive-by-default)
**Areas analyzed:** Empty-state IA gating; Orientation-strip placement + label-tripling;
Cross-cutting matrix via existing capabilities + paired tests

## Assumptions Presented

### Empty-state IA — gate filters/open-CTA/orientation by no-data vs no-match vs populated
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Drive off existing `filters_active?/1` + `deliveries_list` no-data/no-match split; render filters+"Open delivery" only when populated OR no-match, withhold in genuine no-data, show single onboarding pane; preserve tenant-scope boundary | Confident | `operator_live.ex:489-526,519,684`; `deliveries_list.ex:68-99`; `FiltersForm.fields` `:510-516`; DEFECT-REGISTER security flag |

### Orientation-strip placement + label-tripling resolution
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Make `orientation_strip surface={:deliveries}` empty-pane-only; remove from `is_nil(@selected_delivery)` branch; keep "Select a delivery…" helper; copy byte-frozen; label-tripling resolves as side-effect | Confident | `operator_live.ex:581,582-594`; 119 D-07/D-10; `shell.ex:382-424`; DEFECT-REGISTER D-LABEL-TRIPLING |

### Cross-cutting matrix via existing capabilities + paired-test updates
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Route error/permission-denied/stale/disconnected through existing `data_state` + `@detail_error`; verify (not rebuild) responsive/null/long-value; MUST update `operator.spec.js:83-115/26-32`, `operator_live_test.exs:37`; add empty-pane-only judgment assertion; motion/copy/asset constraints locked from 119 | Confident | `deliveries_list.ex:37-67`; `operator_live.ex:568-579`; `operator.spec.js:83-115,382-395`; `operator_live_test.exs:37`; 119 D-11/D-12 |

## Corrections Made

No corrections — all three assumptions confirmed via "Yes, proceed".

## External Research

None performed — the analyzer flagged no research gaps. The DEFECT-REGISTER, Phase 119 locked
decisions, the existing no-data/no-match split, the existing `data_state` capability, and the
catalogued conflicting tests are jointly decisive for all three areas.
