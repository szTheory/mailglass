# Phase 52: Trust Scope Lock + Reference Host Baseline - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `52-CONTEXT.md` — this log preserves assumption analysis.

**Date:** 2026-05-27
**Phase:** 52-trust-scope-lock-reference-host-baseline
**Mode:** assumptions
**Areas analyzed:** Reference host artifact, Public seam boundary, Baseline environment, Scope allowlist enforcement, Risk/dependency handling

## Assumptions Presented

### Reference host artifact
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 52 should create a dedicated maintained reference host app artifact separate from `test/example`. | Unclear | `.planning/ROADMAP.md`, `test/example/README.md` |

### Public seam boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reference host integration should use only stable public seams and avoid internal modules/provider internals. | Confident | `docs/api_stability.md`, `mailglass_admin/docs/api_stability.md`, `mailglass_inbound/docs/api_stability.md` |

### Baseline environment
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 52 baseline should be Ecto-capable for the full trust journey; no-ecto smoke remains separate. | Likely | `.planning/ROADMAP.md`, `.github/workflows/post-publish-smoke.yml`, `test/mailglass/install/install_first_preview_smoke_test.exs` |

### Scope allowlist enforcement
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Scope allowlist/non-goals must be both documented and machine-enforced. | Likely | `.planning/ROADMAP.md`, `.planning/METHODOLOGY.md`, `test/mailglass/docs_contract_test.exs`, `lib/mix/tasks/mailglass.docs.check.ex` |

### Risk/dependency handling
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Hackney smoke failure should remain tracked dependency risk and not be folded into Phase 52 core scope. | Likely | `.planning/REQUIREMENTS.md`, `.planning/todos/pending/2026-05-27-resolve-post-publish-smoke-hackney-dependency-failure.md` |

## Corrections Made

No corrections — all assumptions confirmed via user selection ("Yes, proceed").

