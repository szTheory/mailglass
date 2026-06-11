# Phase 79: Verification and Visual-Regression Hardening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 79-verification-and-visual-regression-hardening
**Mode:** assumptions
**Areas analyzed:** Audit-matrix re-run, Gap-register closeout, e2e extension, Conformance/bundle gates, Deep-link GAP-22 disposition, Release ceremony depth + version

## Assumptions Presented

### A. Audit-Matrix Re-Run + Comparison
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Manual / local LLM-critique before/after vs Phase-74 baseline; no pixel-diff, no committed PNGs, no CI promotion | Confident | ui-audit.sh:14-18 (gitignored, D-06/D-07); design-system.md:128-135; STATE.md:49 |
| VERIF-03 ritual = documented prose in design-system.md, no new tooling | Likely | design-system.md:123-139; agent-browser unversioned |

### B. Gap-Register Sev-4/5 Closeout
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Five sev-4 rows (GAP-01/03/05/06/13), zero sev-5; all resolved by Phases 76-78; Phase 79 records closure only | Confident | 74-GAP-REGISTER.md:117/119/121/122/155; 76-02/76-03/78-01 SUMMARYs |
| Closure recorded in separate 79-GAP-CLOSEOUT.md, not by editing frozen register | Likely | 74-GAP-REGISTER.md:13,226 (frozen); Phase 73 RELEASE-RECORD precedent |

### C. e2e Extension + Pre-Existing Replay Failure
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add structural tests for Operator Overview + inbound/preview orientation/new IA testids (currently untested) | Confident | operator.spec.js:13-30,101; 75-03-SUMMARY.md:114-121; VERIF-02 |
| Fix (not skip) the exact-replay-flow failure — likely seed-index drift post-Phase-78 | Likely | todo resolves_phase:79; operator.spec.js:104-131 positional nth; 78-01-SUMMARY.md:53,80 |

### D. Conformance + Bundle Gates
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Promote 5 inline greps into committed check-conformance.sh; run + bundle-clean gate | Likely | 76-06-SUMMARY.md:70-77; check_motion_conformance.sh precedent (STATE.md:120) |
| Encode text-base-content false-positive exclusion (Footgun-6) | Confident | 76-06-SUMMARY.md:73 |

### E. Deep-Link GAP-22 Disposition
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Re-confirm Phase-75 D-17 deferral as permanent v1.7 disposition; no code change; hold at sev 3 | Confident | 75-CONTEXT.md:57 (D-17); design-system.md:152-159; STATE.md:47 scope lock; VERIF-04 |

### F. Release Ceremony Depth + Version
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Prepare/acknowledge only; hands-free Release Please publishes on merge | Likely | CLAUDE.md release conventions; STATE.md:42 |
| Target 1.5.0 minor (linked mailglass+admin); inbound separate patch 1.1.6 | Likely | release-please-config.json linked group excludes inbound; manifest 1.4.5/1.4.5/1.1.5; D-24 |

## Corrections Made

No corrections to A–E — all confirmed "Proceed as written."

Three strategic forks confirmed via direct question (ship decisions, escalated per decision policy):
- **Release ceremony depth:** Prepare/acknowledge only — confirmed (matches assumption F).
- **Target version:** 1.5.0 minor — confirmed (matches assumption F).
- **Remaining assumptions A–E:** Proceed as written.

## Auto-Resolved

Not applicable — interactive confirmation, no --auto.

## External Research

None performed — all evidence present in the codebase (verification/closeout phase).
