# Phase 98: Operator / Deliveries Surface - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-14
**Phase:** 98-operator-deliveries-surface
**Mode:** assumptions
**Areas analyzed:** Overview/master-detail IA reconciliation, Seed/fixture strategy, CR-01/02/03 nil-guard fixes, 390px disclosure + group spacing + e2e tagging

## Assumptions Presented

### Seed/Fixture Strategy (FLOW-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend the single `OperatorFixtures.seed_browser_scenario!/0` to cover unseeded states; reach every state by URL params against ONE dataset; no new seed entry points | Confident | `operator_browser_server.ex:30`, `endpoint_case.ex:87`, `operator_fixtures.ex:10,131-133,156-159`; `detail_error_for/2` `operator_live.ex:550-552`; URL-param nav in `operator.spec.js`/`structural.spec.js` |

### CR Nil-Guard Fixes (CR-01/02/03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| CR-01 catch-all `body_copy(_)` fallback; CR-02 nil-safe `selected_delivery.id` read (not a happy-path branch); CR-03 add `:suppressed` to `status_badge` attr `values:` (one line, fallback already renders correctly) | Confident | `suppression_card.ex:51,55-57,59`; `operator_live.ex:33,153,241`; `components.ex:158-183`; STATE-LD-05 phantom-atom lock; 76-REVIEW.md §58/76/105 |

### 390px Disclosure + Group Spacing + e2e Tagging
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 390px filter disclosure via `JS.toggle` (no socket assign); group spacing on existing `gap-lg/md/sm` token rhythm; group containers tagged `data-testid="operator-{group}"` kebab | Likely | IA-LD-02 (permits JS.toggle or assign); `operator_live.ex:31,281,285,396-397,414,467-468`; `shell.ex:181`; `structural.spec.js` getByTestId; `mix.exs:183-188` |

## Corrections Made

No corrections — all 3 assumptions confirmed ("Yes, proceed").

## Open Fork Resolved (user decision)

### Overview / master-detail IA reconciliation
- **Context:** The operator surface has a separate `:overview` view (`operator_live.ex:280-363` —
  Health stat cards + Navigate cards) that the locked IA-LD decisions never mention; they only
  specify the deliveries master-detail. PAGE-01 requires orienting both first-time and advanced
  operators on landing.
- **Options presented:** (1) Keep both, bring both to spec [recommended]; (2) Fold overview into a
  single deliveries page (top tier above master-detail); (3) Let planner decide.
- **User chose:** **Keep both, bring both to spec.** Overview = first-time orientation landing
  (PAGE-01); deliveries = advanced master-detail; both brought into full IA-LD conformance. → D-01.

## Conformance Gaps Noted During Analysis (folded into decisions)

- Master-detail grid `lg:grid-cols-[minmax(22rem,28rem)_1fr]` (`operator_live.ex:396`) does not match
  locked IA-LD-03 (40/60 @768, 33/67 @1440; wrong breakpoint) → D-02.
- Deliveries-list `h2` still uses banned arbitrary `tracking-[0.08em]` (`operator_live.ex:~409`),
  violating IA-LD-04 + the tightened RATCHET-03 grep gate → D-03.

## External Research

None performed — IA/state/dark/motion/copy fully locked in SUMMARY.md; seed/e2e/CR patterns all
established in-repo.
