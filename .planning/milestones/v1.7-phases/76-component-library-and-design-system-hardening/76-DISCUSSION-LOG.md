# Phase 76: Component-Library and Design-System Hardening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 76-component-library-and-design-system-hardening
**Mode:** assumptions
**Areas analyzed:** Badge Consolidation Scope, status_badge Component Shape, Support-Card Restructure, Token-Migration Blast Radius, Regression Test + Bundle, Cross-Phase

## Assumptions Presented

### Badge Consolidation Scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Delete all FIVE badge_class/1 copies, not three (ROADMAP/DS-01 "three" is stale; GAP-05/06 latent dups) | Confident | deliveries_list.ex:80-84, timeline.ex:130-135, records_list.ex:97-101, operator/detail_header.ex:81-85, inbound/detail_header.ex:142-146; GAP-REGISTER GAP-05/06 |
| Inbound singular→past-tense normalization in admin call-site adapter, never in mailglass_inbound | Confident | execution_run.ex:17, replay_run.ex:17 (@outcomes singular = locked 1.0); UI-SPEC Conflict 2 |

### status_badge Component Shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| status_badge/1 is a sibling to existing badge/1; not a replacement | Confident | components.ex:91-114 (badge/1 = Preview :warning/:stub atom) |
| Render label-only per UI-SPEC sketch (DS-01 "icon+label" satisfied by label) | Likely | UI-SPEC:171,223; all call sites label-only; no status badge uses a Heroicon |
| status_class/label (+icon) return only literal strings, attr+values allow-lists | Confident | Pitfall 1 (UI-SPEC:171,516); house style components.ex:91, alert_class/1:86-89 |

### Support-Card Restructure
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Restructure support_cards.ex in place to Tier1/Tier2, same summarize_tenant/1 data, no new plumbing | Confident | support_cards.ex:29; support_summary.ex:21-35; suppression count from separate @suppression_count assign |
| Restructure-first then tokenize; counts as text-display font-bold + Health Count Colors | Confident | UI-SPEC:229,519; GAP-13/14; reuse operator_live.ex:287-294 |

### Token-Migration Blast Radius
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Admin-wide HEEx: ~274 text-(sm/base/xs)/22 files, ~45 gap-3/4/6/15 files, 0 font-medium/semibold, 0 z-[, 1 benign #ffffff | Confident | per-file grep counts; preview/tabs.ex:113 inline style hex; tracking-[0.08em] not gated |
| Phase 75 Overview/orientation markup already token-clean — excluded | Confident | operator_live.ex:279-362 uses gap-lg/md/sm, text-display/heading/body/label |

### Regression Test + Bundle
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New components_test.exs, render_component, assert exact class per atom across all 4 tables | Confident | inbound/components_test.exs:26, shell_test.exs:12; Pitfall 5 (UI-SPEC:520) |
| mix mailglass_admin.assets.build → commit priv/static/app.css; git diff --exit-code gate | Confident | mailglass_admin.assets.build.ex:28; BundleTest; CLAUDE.md #6 |

### Cross-Phase
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 75 did not touch badge atoms — clean consolidation surface | Confident | singular atoms + phantom :suppressed confirmed present post-75; Phase 75 inbound work was shell.ex orientation only |

## Corrections Made

### status_badge Component Shape
- **Original assumption:** Render label-only (`<span>{status_label}</span>`), no icon — per the
  frozen UI-SPEC sketch; treat DS-01 "icon + label" as satisfied by the label alone.
- **User correction:** **Icon + label.** Render a per-atom Heroicon before the label, honoring the
  literal REQUIREMENTS DS-01 contract over the UI-SPEC label-only sketch.
- **Consequence captured in CONTEXT D-04:** This phase now owns a per-atom `status_icon/1` Heroicon
  mapping (extending the frozen taxonomy with an icon column, ~24 atoms), outline-style decorative
  (`aria-hidden`) icons, and a 390px overflow re-check (GAP-10). Recorded as a deliberate amendment
  to the frozen UI-SPEC. Icon names must be literal strings (Pitfall 1) and present in the JIT bundle.

All other assumptions confirmed without correction.

## External Research

None performed — self-contained internal admin refactor against a frozen, fully-specified Phase 74
contract. daisyUI 5 class names and the asset toolchain are already verified in-repo (UI-SPEC Pitfall 3).
