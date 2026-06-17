# Phase 95: Audit Apparatus + Quality-Ratchet v2 - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-13
**Phase:** 95-audit-apparatus-quality-ratchet-v2
**Mode:** assumptions
**Calibration:** minimal_decisive (vendor_philosophy `opinionated`)
**Areas analyzed:** GAP register, Score baseline + idempotency, Playwright + LLM harness, Pillar-rubric identity (fork)

## Methodology Lenses Applied

- **Decisive-By-Default Research Posture** + **Recommendation-First Synthesis** — favored one
  coherent default grounded in existing repo patterns over option menus. Escalated only the
  one genuinely strategic fork (pillar rubric — an expensive-to-rekey contract).
- **Honest Surface Area** — judged not directly applicable (internal dev/CI tooling, not
  adopter-facing surface).

## Assumptions Presented

### GAP register
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Fresh carried-forward register at `.planning/RATCHET-GAP-REGISTER.md`, GAP-NN from GAP-01; reuse v1.7 columns + add status/run_id/first_seen_run; do NOT migrate frozen v1.7 register | Likely | `74-GAP-REGISTER.md:5,17-22,26-36`; `79-GAP-CLOSEOUT.md:143-151` |

### Score baseline + idempotency
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `mailglass_admin/docs/ui-baseline-scores.json` keyed surface→pillar→theme; fail-closed ExUnit in `verify.support_contract.admin`; first run = establish-and-freeze (no regression check until Phase 103) | Likely | `94-CONTEXT.md` D-02; `ci.yml:643`; ROADMAP critical path 94→…→103 |

### Playwright + LLM harness
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New `e2e/structural.spec.js` on existing required `operator_browser_gate` lane; 6 facts map to existing assertion patterns; LLM scoring maintainer-run local (not CI), screenshots from `ui-audit.sh` (18 = 3 surfaces × 3 viewports × 2 themes), only JSON committed | Likely | `ci.yml:645-716`; `operator.spec.js:56-57,229`; `ui-audit.sh:7-18` |

### Pillar-rubric identity (escalated fork)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Two different 6-pillar sets exist (generic gsd-ui-review vs project design-system.md); baseline JSON keys depend on the choice → escalate | Unclear (pre-decision) | `ui-review.md:124-132`; `design-system.md:104-121`; `74-GAP-REGISTER.md:39-48` |

## Corrections Made

No corrections to the three Likely assumptions — owner selected "Yes, proceed."

### Pillar-rubric fork (escalated → owner-decided)
- **Original assumption (Claude's recommendation):** Pin the `design-system.md` 6 pillars
  (Spacing/Radius/Color/Type/Elevation/Motion+A11y) as canonical; treat "gsd-ui-review grade"
  as the ui-review *method* applied to the project pillars.
- **Owner decision:** **design-system.md pillars (Recommended)** — confirmed.
- **Reason:** RATCHET-04 machine-checkable facts map onto these; already used by v1.7 register,
  conformance scripts, Playwright gates; baseline keys are expensive to re-key later.

## External Research

None performed — the analyzer flagged no external-research gaps. The one flagged item (pillar
identity) was an internal decision fork resolved by the owner, not a web-research question.
</content>
