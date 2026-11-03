# Phase 178: Preview Authoring and Milestone Review - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-29
**Phase:** 178-preview-authoring-and-milestone-review
**Mode:** assumptions (calibration: minimal_decisive)
**Areas analyzed:** Restore/guidance, Scenario selector, Final reconciliation, Cost & candidate

## Assumptions Presented

### Restore action and sample-value guidance
| Assumption | Confidence | Evidence |
|---|---|---|
| "Restore defaults" bordered secondary action, handler unchanged | Confident | assigns_form.ex:62-66, preview_live.ex:262-280, evidence_card.ex:84 |
| Drop generic type helpers; one read-only note; fix describedby | Likely | assigns_form.ex:304-331, preview_live.ex:1038-1042 |

### Scenario selector
| Assumption | Confidence | Evidence |
|---|---|---|
| Humanized primary label, module secondary, visible exact identity, raw-atom URLs | Confident | sidebar.ex:129-132,216,263-276,419; preview_live_test ~508-520 |
| Pure whole-set disambiguation builder; scenario-level collision fixture | Likely | sidebar.ex:369-374; mailables.ex:26; 173-REMOTE-CI.md |

### Final reconciliation
| Assumption | Confidence | Evidence |
|---|---|---|
| UIQ-04 = correction pass on ledger (3 stale 176 rows, partial fidelity row) | Confident | quick_view_scenarios.json; phase174-review.md:85,94 |
| Replace stale phase-bound ledger assertion with merge-blocking ExUnit rule | Confident | quick-views.spec.js:300-303; quick_view_projection_test.exs:20 |
| Preview authoring story set; connected-only/pure-only accounting | Likely | preview_chrome.story.exs; discovery.ex |
| Real zoom via existing extension; fill 174/177/178 gaps; CSS zoom relabel | Confident | e2e/support/browser-zoom-extension; phase176-filters.spec.js:599-652 |

### Cost & candidate
| Assumption | Confidence | Evidence |
|---|---|---|
| Reconcile hosted pilot + measure Operator Browser Gate growth | Likely | ci.yml:954,1062; 174-COST-DISPOSITION.json |
| Draft never-merged PR on gsd/v2.10-ui-repairs-storybook; isolated Compose preview; one approval stop | Likely | guard-release-trigger.yml:3-12; check_phase173_candidate.sh; 173-DELIVERY.md |

## Corrections Made

No corrections — all assumptions confirmed.
