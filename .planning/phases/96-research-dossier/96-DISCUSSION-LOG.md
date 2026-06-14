# Phase 96: Research Dossier - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-14
**Phase:** 96-research-dossier
**Mode:** assumptions
**Areas analyzed:** Dossier inventory & file layout, LOCKED DECISION block schema, Research
execution model, Per-dossier scope boundaries, Grounding in real surfaces & GAPs

## Assumptions Presented

### Dossier inventory & file layout
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Five dossiers (MOTION/IA/COMPONENT-STATES/DARK-MODE/MICROCOPY) + SUMMARY.md under `.planning/research/v1.11/`, ALLCAPS naming | Confident | prior research dirs `v1.9-brandbook-fable/`, `v1.7-admin-ui-polish/`; ROADMAP:112; REQUIREMENTS RESEARCH-01..05 |
| LOCKED DECISION block at end of each dossier; SUMMARY.md hoists all five; downstream reads only SUMMARY | Confident | ROADMAP success-criterion 4; `v1.10-brand-adoption/ADOPTION-MECHANICS.md` precedent |

### LOCKED DECISION block schema
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| ID-stamped decision table, per-dossier prefixes (MOTION-LD/IA-LD/STATE-LD/DARK-LD/COPY-LD), cols `LD-ID \| Decision \| Applies-to \| Constraint-binding \| Closes-GAP`, literal values | Likely | `RATCHET-GAP-REGISTER.md` GAP-NN machinery; STATE.md decision-ID idiom; design-system.md value tables |
| Every row carries Constraint-binding cell; can't lock anything CI gates would reject | Confident | STATE.md hard-constraints block; Phase 102 SC + Phase 94 motion gate |

### Research execution model
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 5 subagents parallel, then per-dossier adversarial critic-then-lock pass | Likely | config.json parallelization:true; ROADMAP "parallel-subagent"; CLAUDE.md decision policy |
| Web research enabled (gsd-phase-researcher has WebSearch/WebFetch/firecrawl/exa); external-led MOTION/IA/MICROCOPY, codebase-led COMPONENT-STATES/DARK-MODE | Likely | REQUIREMENTS RESEARCH-01/02 external sources; RESEARCH-03/04 over project archetypes/tokens |

### Per-dossier scope boundaries & grounding
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Axis-ownership: states (component-state) / transitions (motion) / dark render (dark-mode); cross-ref by LD-ID | Likely | design-system.md orthogonal axes; conflict-avoidance |
| COMPONENT-STATES covers real archetype inventory from code | Confident | components.ex, shell.ex, inbound/routing_trace.ex, evidence_card.ex; COMP-01/Phase 99 |
| Each dossier maps decisions to open GAP rows (dark→GAP-03, motion→GAP-02, type→GAP-04, gallery→GAP-05) | Likely | RATCHET-GAP-REGISTER seed rows; anti-churn sev≥3 gate |
| MICROCOPY maps voice to per-surface JTBD using locked domain nouns, never "Oops" | Confident | REQUIREMENTS RESEARCH-05; CLAUDE.md Brand & Voice + Domain Language; Phase 101 SC |

## Corrections Made

No corrections — all assumptions confirmed via single "Yes, proceed" gate.

## External Research

None performed during discussion. The substantive external research (Emil Kowalski, gov.uk,
Nielsen, platform HIG) IS the phase deliverable and is deferred to execution. One meta-note
surfaced and resolved: the `config.json` MCP-search flags are false, but `gsd-phase-researcher`
agents carry web tools independently, so web-grounded research remains available (D-06).
</content>
