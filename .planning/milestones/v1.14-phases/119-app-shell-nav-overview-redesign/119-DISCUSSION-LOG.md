# Phase 119: App-shell + Nav + Overview redesign - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-26
**Phase:** 119-app-shell-nav-overview-redesign
**Mode:** assumptions
**Areas analyzed:** Nav active-state + Overview nav identity; Overview-as-triage (drill-through health + empty-pane orientation); Microcopy/motion/paired-test mechanics

## Assumptions Presented

### Nav active-state + Overview nav identity (SHELL-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add `:overview` to `active` enum + always-shown "Overview" nav link; replace literal `active={:deliveries}` with `active={@view}`; shell untouched; Overview link is real `nav_link` so `aria-current` renders | Confident | `shell.ex:201,235`; `operator_live.ex:349,356-363`; `components.ex:230`; `judgment.spec.js` nav-active gate |

### Overview → real triage destination (SHELL-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Delete `operator-overview-nav` block + signpost subtitle; health counts become click-throughs (failures→`status=failed`, suppressions→`status=suppressed`, orphans→existing support_cards focus); wrap stat_card in a link (don't mutate primitive); orientation strip empty-pane-only; all-clear collapses to calm summary | Likely | `operator_live.ex:416-448,34`; `support_cards.ex` orphan focus drilldown; `DEFECT-REGISTER` D-NAV-DUP/D-OVERVIEW-SIGNPOST/D-ORIENT-REDUNDANT |

### Microcopy / motion / paired-test mechanics (SHELL-03 + matrix)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Same-phase: rewrite `operator.spec.js:352-368` (VERIF-02), flip both `judgment.spec.js` gates test.fixme→test; rewrite signpost subtitle (Oops banned), keep orientation copy byte-frozen; reuse existing motion tokens (no new keyframes); `mix assets.build`+commit on class change, watch TokenParityTest landmine | Confident | `DEFECT-REGISTER` Pitfall-2 §66-71/§299-302; `judgment.spec.js:14-18`; existing `nav_link` motion tokens; milestone-seed TokenParityTest constraint |

## Corrections Made

No corrections — user selected "Yes, proceed"; all three areas confirmed as presented.

## Codebase-Resolved Fork (during discuss)

- **Orphan-backlog drill-through target** (analyzer flagged as an open product/IA fork): resolved by
  the codebase, not escalated. `support_cards.ex` already ships an orphan-backlog focus drilldown
  (`phx-value-focus="orphan_backlog"`), and no Deliveries `status=` filter maps to orphans. Decision:
  reuse the existing drilldown; failures/suppressions use Deliveries filter links. Recorded as D-05.

## External Research

Not performed in discuss. Two topics carried to `/gsd-plan-phase` research (see CONTEXT deferred):
- Overview-as-triage IA pattern (GOV.UK / Apple-deliberate; all-clear vs attention-state layout) —
  the ROADMAP already flagged this for plan-phase research.
- Health-row vs `support_cards` dedup — a planning refinement.
