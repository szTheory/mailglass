# Phase 62: close-gap-evid-02-evid-03-current-release-trust-proof - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-31T16:23:23Z
**Phase:** 62-close-gap-evid-02-evid-03-current-release-trust-proof
**Mode:** assumptions
**Areas analyzed:** current-release dependency drift, folded EVID-02 todo, clean-baseline guard, audit residuals

## Assumptions Presented

### Current-Release Dependency Drift

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Current-release dependency drift is the whole implementation scope: bump `reference/host_app/mix.exs` to `~> 1.3` / `~> 1.3` / `~> 0.3`, refresh lock to `1.3.0` / `1.3.0` / `0.3.0`, and do not redesign the existing clean-baseline or published-trust workflow jobs. | Confident | `.planning/v1.3-MILESTONE-AUDIT.md`; `reference/host_app/mix.exs`; `reference/host_app/mix.lock`; `.github/workflows/ci.yml`; `.github/workflows/post-publish-smoke.yml`; `.planning/phases/60-release-trust-gate-drift-prevention/60-05-PLAN.md` |

### Folded EVID-02 Todo

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Fold the pending EVID-02 todo into Phase 62, but treat Phase 60 decisions as superseding its stale "run from `reference/host_app`" wording. | Confident | `.planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md`; `.planning/phases/60-release-trust-gate-drift-prevention/60-CONTEXT.md` |

### Clean-Baseline Guard

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Make `scripts/check_clean_baseline_hex_only.sh` version-specific, not just source-specific. It should fail unless the three sibling Hex entries match the intended current release line. | Confident | `.planning/phases/60-release-trust-gate-drift-prevention/60-VERIFICATION.md`; `.planning/phases/60-release-trust-gate-drift-prevention/60-05-PLAN.md`; `scripts/check_clean_baseline_hex_only.sh` |

### Audit Residuals

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Treat live GitHub branch-protection proof for EVID-01 and live post-publish green-run evidence as residual/manual audit items, not Phase 62 local implementation scope. | Likely | `.planning/v1.3-MILESTONE-AUDIT.md`; `.planning/ROADMAP.md`; `.planning/STATE.md` |

## Corrections Made

No corrections — all assumptions confirmed.
