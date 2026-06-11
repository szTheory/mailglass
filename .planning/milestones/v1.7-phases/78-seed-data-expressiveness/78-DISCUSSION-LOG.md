# Phase 78: Seed-Data Expressiveness - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 78-seed-data-expressiveness
**Mode:** assumptions
**Areas analyzed:** Surface Division of Labor; Status Taxonomy & Badge Coverage; Row-Index Stability & Truncation

## Assumptions Presented

### Surface Division of Labor
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Two seed surfaces keep non-overlapping jobs: `operator_fixtures.ex` owns replay depth + inbound un-skip + empty tenant; `demo_data.ex` owns breadth | Confident | `operator.spec.js:9,108,139,167` (deliveryRow 0..3), `operator.spec.js:248` (skipped inbound gate), `operator_fixtures.ex:46-130`, `demo.spec.js:30-48` |
| Empty-result state via a second zero-row tenant (`"empty-tenant"`), no data removal | Confident | `deliveries.ex:24` tenant filter, `operator_live.ex:359,427`, `deliveries_list.ex:15`, `SupportSummary.summarize_tenant` tenant-scoped |

### Status Taxonomy & Badge Coverage
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| "14 outbound statuses" = event-timeline badges on `event.type` (not delivery.status, which is 5 atoms); seed all 14 Anymail types + internal webhook_replay_*/reconciled | Confident | `delivery.ex:35,56`, `event.ex:40-53`, `deliveries_list.ex:49`, `components.ex:131-156` |
| Inbound badges via `normalize_inbound_outcome/1`; seed each inbound outcome | Confident | `records_list.ex:55`, `components.ex:126-129`, execution_run `@outcomes` |
| Replay outcomes from Event rows (`webhook_replay_succeeded` + metadata["outcome"]; `webhook_replay_failed`); reconciled+unmatched both branches from orphan + `:reconciled` events | Confident | `support_summary.ex:97-117,190-210`, `support_cards.ex:180-207`, `event.ex:56` |

### Row-Index Stability & Truncation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Insert breadth rows at older timestamps to preserve operator.spec.js indices 0-3; do not switch to testid selectors this phase | Confident | `deliveries.ex:29-33`, `records.ex:50-52`, `operator_fixtures.ex:15-130`, `operator.spec.js:9,108,139,167` |
| Truncation is Tailwind `truncate`; ~80-char recipient / ~150-char subject overflows; no schema cap | Likely | `deliveries_list.ex:44,50`, `records_list.ex:50`, `components.ex:268` (mask preserves length) |

## Corrections Made

No corrections — all assumptions confirmed ("Yes, proceed").

## Reviewed Todos

- `preexisting-replay-flow-e2e-failure.md` (score 0.6, `resolves_phase: 79`) — reviewed, NOT
  folded; captured as constraint D-10 in CONTEXT.md. It is Phase 79 verification debt
  (operator.spec.js:104 timeline assertion, confirmed pre-existing against the pre-77 baseline),
  not Phase 78 scope.

## Methodology

`.planning/METHODOLOGY.md` lenses applied: Decisive-By-Default Research Posture (single decisive
recommendation per item, no menus), Honest Surface Area (flagged the pre-existing failure and the
loose-atom-name reconciliation rather than papering over them), Recommendation-First Synthesis.
Nothing flagged for escalation — all gray areas resolved from codebase evidence.

## External Research

None performed — codebase fully determined the seed shapes, badge taxonomy, query ordering,
support-card branch conditions, and spec coupling.
