# Phase 74: Systematic Audit and UI-SPEC - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-03
**Phase:** 74-systematic-audit-and-ui-spec
**Mode:** assumptions
**Calibration:** minimal_decisive (vendor philosophy: opinionated)
**Areas analyzed:** Artifact format/location/freeze mechanics; Severity rubric & pillar dimension; Before-baseline capture & reconciliation; Open-question disposition (record vs resolve); Three-way badge taxonomy construction

## Assumptions Presented

### Artifact Format, Location & Freeze Mechanics
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Gap register / UI-SPEC / assertion inventory as committed Markdown in phase dir; UI-SPEC as `74-UI-SPEC.md` with `status: approved` frontmatter | Confident | `22-UI-SPEC.md`, `65-UI-SPEC.md` precedent; `components.ex:105` cites a UI-SPEC section |
| Stable `GAP-NN` row IDs make the anti-churn citation gate enforceable | Confident | ROADMAP anti-churn contract (severity ≥ 3 citation) |

### Severity Rubric & Pillar Dimension
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Self-contained 1-5 rubric; pillar maps to the 6 pillars in `design-system.md:104-121`; sev-4/5 = blocks Phase 79 | Likely | `design-system.md:104-121`; ROADMAP Phase 79 closeout bar; no standalone rubric file |

### Before-Baseline Capture & Reconciliation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Committed = text inventory + PNG path refs; PNG binaries gitignored in `tmp/ui-audit/`; capture via extended `ui-audit.sh` across 390/768/1440 × light/dark × 3 surfaces | Confident | `ui-audit.sh` `OUT` default; `.gitignore` `/tmp/`; ROADMAP criterion 3; SUMMARY "never add PNGs to CI" |

### Open Technical Questions → RECORD, Don't Resolve
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 74 records, never resolves (zero-code) | Confident | ROADMAP criterion 5 "zero build-phase code" |
| (a) Preview empty state already exists | Confident | `preview_live.ex:291`, testid `preview-empty-mailables` |
| (b) `count_active_suppressions/1` absent → add in Phase 75 | Confident | `Suppressions` exposes only `get_delivery_suppression_state/2`; grep finds no count fn |
| (c) Deep-link bug filed with recommended deferral to Phase 79 | Confident | `design-system.md:142-150`; IA-04 / VERIF-04 ownership |

### Three-Way Badge Taxonomy Table Construction
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Table compares all 3 copies side-by-side; surfaces 3 conflicts (phantom `:suppressed`; singular vs past-tense inbound atoms; base-class string divergence) | Confident | `deliveries_list.ex:80-84`, `records_list.ex:97-101`, `timeline.ex:130-135`; FEATURES canonical table |

## Corrections Made

No corrections — user selected "Yes, proceed"; all assumptions confirmed as locked decisions.

## External Research

None performed. The gsd-assumptions-analyzer reported "Needs External Research: None" — the v1.7 research files (SUMMARY/FEATURES/ARCHITECTURE/PITFALLS/STACK) plus direct source reads fully settle every gray area for this evidence-only phase.

## Methodology Lenses Applied

- **Decisive-By-Default Research Posture:** Each open question resolved to a single recommendation by reading actual source; collapsed 2 of 3 "open questions" (preview empty state, suppression count) from open → settled-by-evidence.
- **Honest Surface Area:** Flagged the three-way badge conflict is larger than the headline `:suppressed` framing (two additional latent conflicts); surfaced the real committed-vs-gitignored baseline tension rather than papering over it.
- **Recommendation-First Synthesis:** Every assumption leads with the decision, matching the owner's minimal_decisive / opinionated philosophy. No decision escalated — all reversible or settled by strong in-repo precedent.
