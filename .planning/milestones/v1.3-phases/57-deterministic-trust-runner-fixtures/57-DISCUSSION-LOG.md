# Phase 57: deterministic-trust-runner-fixtures - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 57-deterministic-trust-runner-fixtures
**Mode:** assumptions
**Areas analyzed:** Trust runner entrypoint, deterministic fixtures, checkpoint evidence contract, phase sequencing, reference host boundary

## Assumptions Presented

### Trust runner entrypoint
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| One canonical runner command should be the sole trust-journey orchestration surface, reused by local/CI/release paths. | Likely | `lib/mix/tasks/mailglass.publish.check.ex`, `.github/workflows/post-publish-smoke.yml`, `test/mailglass/install/install_first_preview_smoke_test.exs` |

### Deterministic fixtures
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Deterministic fixture behavior should extend existing deterministic capture + maintained host patterns instead of creating a second fixture framework. | Confident | `mailglass_admin/lib/mix/tasks/mailglass_admin.preview.capture.ex`, `mailglass_admin/lib/mailglass_admin/preview/capture_manifest.ex`, `reference/host_app/README.md`, `test/reference_host/boot_contract_test.exs` |

### Checkpoint evidence contract
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Trust-runner outputs should be machine-readable checkpoint artifacts with schema and bounded-claim language, validated by executable checks. | Likely | `scripts/check_preview_capture_checkpoint.sh`, `.github/workflows/ci.yml`, `mailglass_admin/lib/mailglass_admin/preview/capture_manifest.ex` |

### Phase sequencing
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 57 should lock runner/fixtures/checkpoints only, while webhook-negative and operator non-happy-path proofs remain in Phase 58. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/v1.3-MILESTONE-AUDIT.md` |

### Reference host boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Runner execution should target `reference/host_app` with published constraints and public seams only. | Confident | `reference/host_app/SCOPE.md`, `test/reference_host/public_seams_contract_test.exs`, `test/reference_host/scope_lock_contract_test.exs` |

## Corrections Made

No corrections — all assumptions confirmed.
