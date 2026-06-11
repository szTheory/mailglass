# Phase 77: Motion and Microinteraction Polish - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 77-motion-and-microinteraction-polish
**Mode:** assumptions
**Areas analyzed:** Motion-reveal re-fire fix scope; Vocabulary conformance & layout-thrashing sweep; Verification approach

## Assumptions Presented

### Motion-reveal re-fire fix scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Surgical two-id fix: `id={"delivery-detail-#{@selected_delivery.id}"}` at `operator_live.ex:442` + parallel `id={"inbound-detail-#{@selected_record.id}"}` at `inbound_live.ex:341`; no CSS changes | Confident | `operator_live.ex:442` + `inbound_live.ex:341` are bare `<div class="motion-reveal space-y-4">`; pattern proven at `preview/tabs.ex:84`; `@selected_delivery`/`@selected_record` confirmed real with `.id` |

### Vocabulary conformance & layout-thrashing sweep (GAP-20, GAP-21)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| GAP-20 + thrash sweep are verification-only (no code changes); GAP-21 a11y already landed in Phases 75/76 | Confident (upgraded from Likely after de-risk grep) | Thrash grep across `lib/` returned zero banned terms; stagger cap-8 at `app.css:263-270`; `aria-current`/`aria-selected`/`role="dialog"`/`aria-modal` confirmed present in `shell.ex`, lists, both `replay_modal.ex` |

### Verification approach
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New dedicated `scripts/check_*.sh` motion grep gate + `e2e/operator.spec.js` reduced-motion test with `#delivery-detail-<id>` assertion + same-PR bundle rebuild | Likely | No motion grep exists (`ui-audit.sh` is CI-banned); Playwright harness present (`playwright.config.cjs`, `e2e/operator.spec.js`); bundle gate at `mix.exs` `verify.preview`; vendored `tailwind-macos-arm64` present |

## Corrections Made

No corrections — user selected "Yes, proceed". All three assumptions confirmed, including folding the `inbound_live.ex:341` twin fix into scope.

## De-Risk Performed (orchestrator)

Before presenting, ran a grep to confirm GAP-21 a11y status and motion-reveal site inventory:
- `aria-current`/`aria-selected`/`role="dialog"`/`aria-modal` confirmed present (Phases 75/76 work) → GAP-21 upgraded to out-of-scope/satisfied, Area 2 confidence Likely → Confident.
- Two un-id'd `motion-reveal` panes confirmed at `operator_live.ex:442` and `inbound_live.ex:341`. (Flash/toast `motion-reveal` at `components.ex:78`, `shell.ex:287/295` are correct action-triggered usage, no id needed.)

## External Research

None performed — frozen in-repo spec applied to in-repo code; no library/ecosystem gaps. The only ecosystem API used (`page.emulateMedia({ reducedMotion })`) is stable and well-documented.
