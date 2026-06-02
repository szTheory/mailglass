# Phase 71: Inbound Release Truth Preflight - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution
> agents. Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-02T06:41:19Z
**Phase:** 71-inbound-release-truth-preflight
**Mode:** assumptions
**Areas analyzed:** Source And Package Truth, Preflight Check Shape, Required
Versus Advisory Boundary, Stale Claim Handling, Release Topology

## Assumptions Presented

### Source And Package Truth

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 71 should reconcile existing inbound `1.0.0` source/package truth, not decide the release position again. | Confident | `.release-please-manifest.json`, `mailglass_inbound/mix.exs`, `mailglass_inbound/CHANGELOG.md`, `.planning/publish/mailglass_inbound-publish-summary.json`, `.planning/milestones/v1.4-phases/66-release-position-decision/66-CONTEXT.md` |

### Preflight Check Shape

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Use the existing `mix mailglass.publish.check --package mailglass_inbound` lane as the core Phase 71 preflight, and add/adjust contract checks only for stale source/package truth that it does not already pin. | Likely | `lib/mix/tasks/mailglass.publish.check.ex`, `.planning/publish/mailglass_inbound-files.expected`, `.planning/publish/mailglass_inbound-publish-summary.json` |

### Required Versus Advisory Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Required proof should remain deterministic repo/package evidence; provider-live checks and ecosystem canaries should stay advisory unless a specific release claim depends on them. | Confident | `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `MAINTAINING.md`, `.github/workflows/publish-hex.yml` |

### Stale Claim Handling

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 71 should identify stale claims and package-version contradictions, but leave broad public wording rewrites and executable stale-claim guards to Phase 72 unless they directly affect REL-01 or PROOF-01 preflight truth. | Likely | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `README.md`, `reference/host_app/mix.exs`, `reference/demo_app/mix.exs`, `MAINTAINING.md` |

### Release Topology

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep inbound release topology independent from the linked core/admin version group: core/admin stay at `1.3.0`, inbound is `1.0.0`, and `MIX_PUBLISH=true` inbound pins `mailglass == 1.3.0`. | Likely | `release-please-config.json`, `mailglass_inbound/mix.exs`, `.planning/publish/mailglass_inbound-publish-summary.json`, `.github/workflows/release-please.yml` |

## Corrections Made

No corrections - all assumptions confirmed.
