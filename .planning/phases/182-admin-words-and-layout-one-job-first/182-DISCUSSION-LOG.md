# Phase 182: Admin Words and Layout, One Job First - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md; this log preserves the analysis.

**Date:** 2026-11-15
**Phase:** 182-admin-words-and-layout-one-job-first
**Mode:** assumptions (four-agent fan-out per the owner's fan-out boilerplate)
**Areas analyzed:** verdict model and microcopy; projection hand-off and release impact; time zones and status marks; words rollout; layout; verification and review gate; plan split

## Agents

| Agent | Scope | Key output |
|---|---|---|
| gsd-assumptions-analyzer | codebase evidence for BRADM-01..07 | sizing of every string/time/status site, plan split, 4 external-research flags |
| UX/prior-art researcher | verdict, time, marks, tooltip, layout, renaming | 5-verdict model with draft strings; reuse `field_help`; found brand-book copy conflicts with stop line |
| verification researcher | contract tests, journey lanes, reviewer protocol | 3-layer time/status test, cause test, two-judge gate with calibration, found JS localizer drops zone |
| core projection researcher | additive projection fields and release mechanics | five fields, isolated `feat(core)` commit, admin must tolerate missing keys |

## Conflicts resolved against the code

| Conflict | Resolution |
|---|---|
| Analyzer: "no JS reads `data-local-time`, times are UTC-only". UX and verification researchers: a browser localizer drops the zone. | Code says the localizer is live (`controllers/assets.ex:105-135`, pinned by e2e `operator.spec.js:713-720`). Analyzer was wrong (it searched `hooks.js`). Keep the localizer, add `timeZoneName: "short"` and fixed `en-US` (D-08). |
| Roadmap hand-off: add `bounced_at` and `terminal`. Analyzer: four fields. Core researcher: five. | Five (adds `delivered_at` for parity with `%Delivery{}`); `complained_at`/`suppressed_at` are required to avoid a false Failed on a complaint (D-05). |
| Analyzer: Needs attention is a count, not a filter. UX researcher: a "N emails need attention" list section. | Count plus row marks, no new core filter (D-07); filter deferred. Owner-vetoable default. |
| Commit scope `feat(operator)` (analyzer) vs `feat(core)` (core researcher). | `feat(core)` unless the PR-title check says otherwise; planner verifies (Claude's discretion). |
| Brand book (`brand.json` 256/263/649/720/725) says "will retry", "will not be retried", "Next try at 2:12 PM UTC". | Verified in the file. Stop line wins; `Copy` takes status words only (D-03). |

## Assumptions Presented

### Verdict and cause
| Assumption | Confidence | Evidence |
|---|---|---|
| Five verdicts by delivery class; "Sent is not delivered" on every Sent verdict | Confident | `status_map.ex`, `timeline.ex:163-165`, `brand.json` values |
| Cause only when reason exists; fixed fallback otherwise; fix `outcome_help` tooltips | Confident | `components.ex:1433-1442`, `suppression_card.ex:69-72` |
| Queued reads Sent-class with qualifier | Likely | 179 D-03, `copy.ex:21-23` |

### Projection and release
| Assumption | Confidence | Evidence |
|---|---|---|
| Add five fields to both reads; isolated commit | Confident / Likely | `deliveries.ex:70-134`, `projector.ex:48,126-132`, `guard_release_trigger.sh:42-75` |
| Admin tolerates missing keys | Confident | `mailglass_admin/mix.exs:150-155` |
| Needs attention = count + row marks | Likely | `operator_live.ex:997-1026,2738-2773` |

### Time and marks
| Assumption | Confidence | Evidence |
|---|---|---|
| Fix localizer zone; route offenders through `timestamp/1` | Confident | `assets.ex:105-135`, `timeline.ex:170,222`, `support_cards.ex:385,388` |
| New pane-mark component with pinned provenance record | Likely | `status_badge` `components.ex:1363-1369`; marks only inline in the zip's book HTML |

### Words
| Assumption | Confidence | Evidence |
|---|---|---|
| Screen-text-only rename; flip `Copy.vocabulary` to wired | Confident | `copy.ex:89-93`, `copy_contract_test.exs:679-693` |
| Reuse `field_help`/`module_identity` for the mailer tooltip | Confident | `components.ex:656-673` |

### Verification and plan split
| Assumption | Confidence | Evidence |
|---|---|---|
| After-catalog captured last; two-judge gate with calibration | Likely | `capture-before-catalog.cjs`, `before_catalog_manifest_test.exs` |
| 5 plans: core, one job, time/status, words, review | Likely | 179 D-26, 180 D-04, 181 D-20 |

## Corrections Made

No owner corrections were requested: project Decision Policy says research, decide and escalate only strategic forks. Vetoable defaults are listed in the CONTEXT.md summary (D-03 book-sentence override, D-05 core change, D-07 no filter).

## External Research

- WCAG 1.4.1, 1.4.11, 1.4.13, 2.5.3; APG tooltip; Cloudscape timestamps; Postmark/SendGrid/Resend delay and delivered semantics; LLM-as-judge bias (arXiv 2306.05685, abstract only).
- Claims about Linear, GitHub Actions and Sentry timelines were from memory and are uncited; nothing depends on them.
