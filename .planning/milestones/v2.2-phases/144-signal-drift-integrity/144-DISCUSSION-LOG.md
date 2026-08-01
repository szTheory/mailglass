# Phase 144: Signal & Drift Integrity - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-31
**Phase:** 144-signal-drift-integrity
**Mode:** assumptions
**Areas analyzed:** Honest Verification Outcomes, Dynamic Asset and Release Fan-out Integrity, Release-trigger Recovery

## Assumptions Presented

### Honest Verification Outcomes

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Standardize all three unavailable-verification paths on explicit `always()` failure outcomes with precise remediation; retain Branch Protection Advisory as publish-gating. | Confident | `.github/workflows/branch-protection-drift.yml`; `.github/workflows/ci.yml`; `dev/mix/tasks/mailglass.repo.hygiene.ex`; Phase 141 context |
| Add recurring read-only comparison to the existing scheduled protection workflow and lock the job display-name/context relationship with a regression test. | Confident | `scripts/setup_branch_protection.sh`; `scripts/verify-branch-protection.sh`; `test/scripts/required_checks_test.exs`; `test/scripts/guard_release_trigger_test.exs` |

### Dynamic Asset and Release Fan-out Integrity

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Extend verification with a temporary dynamic-icon fixture proving every resolved `hero-*` value is compared against the vendored inventory. | Confident | `mailglass_admin/scripts/check-conformance.sh`; `mailglass_admin/lib/mailglass_admin/components.ex`; CONFORM-02 |
| Serialize the linked-release train with a release-independent key in both publish and smoke workflows while preserving already-published success. | Confident | `.github/workflows/publish-hex.yml`; `.github/workflows/post-publish-smoke.yml`; Phase 143 context |

### Release-trigger Recovery

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Treat the existing hourly, idempotent release-please self-heal as the TRUTH-04 fix and add durable contract evidence/documentation rather than replacing triggers. | Confident | `.github/workflows/release-please.yml`; `.github/workflows/publish-hex.yml` |

## Corrections Made

No corrections — all assumptions confirmed.

## Methodology Applied

- **Decisive-By-Default Research Posture:** Existing seams and the already-present release self-heal were
  selected without presenting routine topology alternatives.
- **Honest Surface Area:** The three no-verification paths, literal-only icon scan, and distinct
  publish/smoke concurrency groups were treated as truth-contract defects.
- **Recommendation-First Synthesis:** Each area received one bounded direction consistent with the
  maintenance-only and no-new-dependency constraints.
