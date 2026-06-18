# Phase 103: Verification + Idempotent Closeout - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 103-CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-16
**Phase:** 103-verification-idempotent-closeout
**Mode:** assumptions + research-driven recommendations (advisor)
**Areas analyzed:** Score-baseline persistence / meet-or-beat activation, GAP register reconciliation, Release prepare-only + milestone audit

## Assumptions Presented

### Prior-Baseline Source for Meet-or-Beat Activation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Read prior from `git show HEAD:.../ui-baseline-scores.json` vs in-tree current; activate `compare_baselines/2` | Likely | ratchet_baseline_test.exs:40,87-104; 95-CONTEXT D-05 |

### GAP Register Close Strategy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Verify-already-fixed-and-flip all open sev≥3 rows (GAP-01/06/07/08/09); GAP-04 sev-2 optional | Confident | operator_live.ex:409/419, deliveries_list.ex:18-43, support_cards.ex:56 |

### Release Prepare-Only + Milestone Audit
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Prepare-only = doc note + inbound pin check; pins == 1.6.2, no bump triggered; regen audit via gsd-audit-milestone | Likely | 79-04-SUMMARY.md; release-please-config.json; stale v1.11-MILESTONE-AUDIT.md |

## Corrections Made

User requested deep parallel-subagent research (pros/cons/tradeoffs, ecosystem idioms, lessons
from comparable libs/tools, DX) on all three areas before locking, and locked "fresh re-run +
re-score" for the matrix depth. Research produced two material corrections:

### Score-Baseline Persistence
- **Original assumption:** prior from `git show HEAD:` (Option A).
- **Corrected to:** single JSON with `{prior, current}` keyed blocks (Option C), `schema_version`→2,
  anti-vacuity `run_id` guard.
- **Reason:** `git show HEAD:` is unsafe — `docs/` ships in the Hex tarball but `.git` does not, so
  `mix test` from an unpacked package / shallow CI checkout reads empty → vacuous pass; also
  violates zero-process-dep test DNA. Committed-snapshot-as-source-of-truth is the ecosystem canon
  (Betterer, Rust `insta`, jest snapshots, type-coverage).

### Release Prepare-Only
- **Original assumption:** pins == 1.6.2, no core bump triggered, deliverable is just a doc note.
- **Corrected to:** a linked ~1.6.2→1.7.0 bump IS pending (v1.11 `feat:`/`fix:` commits on
  `mailglass_admin/` paths + linked-versions plugin); prepare-only still touches nothing RP owns
  now, records the inbound exact-pin re-pin as a deferred `fix(inbound):` step.
- **Reason:** advisor research found the linked-versions plugin will open a bump once armed; the
  inbound pin must re-pin to the RP-computed target version, which is unknowable pre-PR.

### GAP Register
- **Confirmed (no change):** verify-already-fixed-and-flip; research additionally verified GAP-04
  (sev-2) is also genuinely fixed (filters_form.ex uses text-label token) → flip all six, no
  downgrades; added the cite-the-line + bright-line honesty discipline.

## External Research

Three parallel `gsd-advisor-researcher` subagents:
- **Ratchet persistence** — Option C recommended; `git show HEAD:` rejected as tarball/shallow-clone
  unsafe. Sources: Betterer results-file docs, eslint-formatter-ratchet, ESLint baseline #13437.
- **GAP reconciliation** — Option A (verify-and-flip) decisive; per-row close-type table with
  proving citations; bright-line fixed-vs-downgrade rule.
- **Prepare-only release** — Interpretation A + deferred inbound re-pin; corrected the
  zero-version-change premise; do-NOT-touch list (manifest, CHANGELOG, version numbers, pin-now).
