# Phase 109: Foundations + Gate-Tightening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-18
**Phase:** 109-foundations-gate-tightening
**Mode:** assumptions
**Areas analyzed:** Token-Layer Structure, Gate-Tightening Mechanics, System-Theme Plumbing, REL-01/PR #86 Sequencing

## Assumptions Presented

### Token-Layer Structure (FND-01/02/03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Tokens already exist (`@theme` + `:root`); net-new tokens extend existing blocks, not a parallel source | Confident | `app.css:107-144` (`@theme`), `app.css:192-223` (`:root`) |
| z-index tokens already exist but are UNCONSUMED (research claim "no z-tokens" is stale); fix = consume + split scrim/panel + isolation | Confident | `app.css:216-223` (`--z-sticky..toast`); literal `z-40` at `operator/replay_modal.ex:20`, `inbound/replay_modal.ex:24`; `z-50` toast `components.ex:104`; panel has no explicit z |
| Focus-ring is an un-tokenized string copy-pasted ~14× + a divergent idiom; consolidate before the gate | Confident | 14× `focus-visible:ring-2 focus-visible:ring-primary`; `preview_live.ex:385` uses `focus:outline` |

### Gate-Tightening Mechanics (FND-05)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New gates = grep blocks in existing `check-conformance.sh` (6-gate pattern, `BASH_SOURCE`-scoped); TYPE-GATE extended | Confident | `check-conformance.sh:22,30-115,45` |
| Ratchet → schema v3: add `system` theme, bump `==2`→`==3`, seed system cells in both prior+current by COPY (no re-score) | Likely (mechanism Confident; system-as-3rd-theme vs viewport-structural is ARCHITECTURE §3a's open Q — FND-05 text decides for theme axis) | `ratchet_baseline_test.exs:26-29,41,46,60,78,80,100-102`; `docs/ui-baseline-scores.json:5,34` |
| WCAG 2.2 SC extend the structural matrix (elementFromPoint hit-test net-new; target-size/contrast extend existing) | Confident | `structural.spec.js:222,232,286-363,780`; no `elementFromPoint`/`isolation`/`2.4.11` found |

### System-Theme Plumbing (FND-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| CSS-layer system-theme is already correct (`data-theme={nil}`=system via `prefersdark`); Phase 109 proves+locks, doesn't rebuild | Confident | `root.html.heex:2`; `layouts.ex:82-97`; `app.css:60-64` |
| Operator surface still 2-state `dark_chrome?`; the 3-way picker UI is Phase 110/112, NOT 109 | Likely (CSS seam Confident; the 109-vs-112 scope line is a judgment to hold) | `operator/shell.ex:50-99,119,258-269`; `operator_live.ex:64-768` |

### REL-01 / PR #86 Sequencing
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| REL-01 = one-time admin-override merge of #86 before any 109 code; block is review-required only, not CI/conflict | Confident | `gh pr view 86`: OPEN, MERGEABLE, BLOCKED, `reviewDecision:""`, 24 checks SUCCESS; branch `fix/admin-preview-mount-aware-urls` |

## Corrections Made

No corrections — user selected "Yes, proceed." All assumptions confirmed and locked as decisions
D-01..D-12 in CONTEXT.md.

## User Decisions

- **PR #86 merge handling:** "Capture as planned precondition" — record the admin-override merge
  (`gh pr merge 86 --admin`) as the first step of phase *execution*; do NOT merge during the
  discussion. (Captured as D-12.)

## External Research

None performed — the v1.13 research dossiers are HIGH-confidence and the codebase grounding
confirmed/corrected them directly. Notable internal correction surfaced to the planner: the
research's "no z-index tokens in app.css" claim is stale — tokens exist at `app.css:216-223` but
are unconsumed by HEEx (folded into D-03).
