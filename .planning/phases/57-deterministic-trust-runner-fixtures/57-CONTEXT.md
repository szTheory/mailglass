# Phase 57: deterministic-trust-runner-fixtures - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish one deterministic trust-runner command plus stable fixture and checkpoint artifacts for reproducible trust assertions across local reruns and CI.

This phase locks the runner/fixture/checkpoint foundation for `JOUR-01` and `JOUR-02`. Signed webhook proof, failing-signature assertions, and deterministic operator non-happy-path diagnosis remain in the next phase (`58`) per roadmap mapping.

</domain>

<decisions>
## Implementation Decisions

### Trust runner entrypoint
- **D-01:** Ship one canonical runner entrypoint command and treat it as the only supported trust-journey orchestrator surface for local and automation use.
- **D-02:** CI and release workflows must call the same runner entrypoint rather than duplicating trust-journey step orchestration in separate scripts.

### Deterministic fixtures
- **D-03:** Reuse existing deterministic preview-capture and reference-host contract infrastructure as fixture foundations; do not introduce a parallel fixture framework.
- **D-04:** Fixture IDs, scenario ordering, matrix dimensions, and output ordering must remain stable across reruns so assertions are reproducible.

### Checkpoint evidence contract
- **D-05:** Emit machine-readable checkpoint artifacts with explicit schema and bounded-claim language so downstream CI/release lanes can consume deterministic evidence directly.
- **D-06:** Checkpoint verification must be executable by repository scripts/CI checks, not narrative-only documentation.

### Phase sequencing and scope lock
- **D-07:** Phase 57 delivers runner + deterministic fixtures/checkpoints only (`JOUR-01`, `JOUR-02`); webhook verify-first negative path and operator non-happy-path diagnosis stay in Phase 58 (`JOUR-03`, `JOUR-04`).

### Reference host trust boundary
- **D-08:** Trust-runner execution targets the maintained `reference/host_app` baseline with published package constraints and documented public seams only; no internal-module or path-dependency coupling is allowed.

### Claude's Discretion
- Exact command name and mix-task module naming for the runner entrypoint.
- Exact fixture/checkpoint file naming and artifact directory layout, provided schema stability and deterministic ordering are preserved.
- Exact internal decomposition (task modules/helpers/scripts) as long as the external runner contract remains single-entrypoint and deterministic.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase intent and locked scope
- `.planning/ROADMAP.md` - Phase 57 goal, requirement mapping (`JOUR-01`, `JOUR-02`), and phase boundaries.
- `.planning/REQUIREMENTS.md` - v1.3 deterministic trust journey requirements and traceability mapping.
- `.planning/PROJECT.md` - v1.3 trust-proof preflight locks and non-goal policy.
- `.planning/STATE.md` - current milestone status and sequencing context.
- `.planning/METHODOLOGY.md` - decisive recommendation-first and honest-surface methodology lenses.

### Prior locked context
- `.planning/phases/52-trust-scope-lock-reference-host-baseline/52-CONTEXT.md` - maintained reference-host and public-seam lock decisions.
- `.planning/phases/999.2-shift-left-email-screenshot-responsive-preview-workflow-backlog/999.2-CONTEXT.md` - deterministic manifest/checkpoint precedent and bounded-claim posture.

### Reference host contract surfaces
- `reference/host_app/README.md` - clean-checkout bootstrap contract and stable seam declarations.
- `reference/host_app/SCOPE.md` - explicit in-scope/non-goal/deferred lock for trust-proof host behavior.
- `test/reference_host/boot_contract_test.exs` - executable host bootstrap contract.
- `test/reference_host/public_seams_contract_test.exs` - executable public-seam-only contract.
- `test/reference_host/compile_smoke_test.exs` - warnings-as-errors compile contract for maintained host baseline.
- `test/reference_host/scope_lock_contract_test.exs` - executable scope lock token enforcement.

### Deterministic artifact contract precedent
- `mailglass_admin/lib/mix/tasks/mailglass_admin.preview.capture.ex` - deterministic matrix capture command pattern.
- `mailglass_admin/lib/mailglass_admin/preview/capture_manifest.ex` - manifest/checkpoint schema contract (`preview_capture.v1`) and deterministic hashing/sorting approach.
- `scripts/check_preview_capture_checkpoint.sh` - executable checkpoint schema/boundary/dimension verification pattern.
- `mailglass_admin/test/mix/tasks/mailglass_admin.preview.capture_test.exs` - deterministic dry-run/task contract tests.

### CI and release integration surfaces
- `.github/workflows/ci.yml` - advisory preview-capture lane and checkpoint validation wiring.
- `.github/workflows/post-publish-smoke.yml` - canonical release-window smoke orchestration and published-version dependency constraints.
- `test/mailglass/install/install_first_preview_smoke_test.exs` - repo-local mirror of release-day smoke contract.
- `lib/mix/tasks/mailglass.publish.check.ex` - pre-publish evidence/check discipline and machine-readable proof summary posture.
- `MAINTAINING.md` - release runbook and trust-proof/release gate discipline.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `reference/host_app/*`: maintained host app baseline with published dependency pins and public seam wiring.
- `mailglass_admin.preview.capture` task + `CaptureManifest`: deterministic matrix enumeration and manifest/checkpoint generation patterns.
- `scripts/check_preview_capture_checkpoint.sh`: deterministic artifact verification script pattern reusable for trust checkpoint validation.
- Existing host contract tests under `test/reference_host/`: executable invariants for bootstrap/public seams/scope lock.

### Established Patterns
- Deterministic artifact contracts use explicit schema versions, bounded claim language, and sorted output ordering.
- Trust assertions are expected to be executable via tests/scripts/CI checks, not doc-only claims.
- Reference host remains a thin maintained baseline and must not drift into internal coupling or second-product behavior.

### Integration Points
- Phase 57 runner should integrate with `reference/host_app` setup flow and existing smoke-trust surfaces.
- Checkpoint outputs should be shaped for direct consumption by later CI trust lanes (Phase 59) and release trust gates (Phase 60).
- Runner and fixture contracts must preserve the phase boundary so webhook-negative and operator non-happy-path proofs can layer in Phase 58 without rework.

</code_context>

<specifics>
## Specific Ideas

- Keep one canonical trust-runner entrypoint for local + CI usage to avoid drift.
- Preserve bounded trust language in generated evidence ("confidence in this pipeline" rather than broad cross-client guarantees).
- Favor deterministic ordering and explicit schema fields over implicit conventions.

</specifics>

<deferred>
## Deferred Ideas

- Signed webhook verify-first negative assertion flow (`JOUR-03`) is deferred to Phase 58.
- Deterministic operator non-happy-path diagnosis script (`JOUR-04`) is deferred to Phase 58.
- CI required trust-lane gating and checkpoint artifact enforcement (`EVID-01`, `EVID-02`, `EVID-04`) are deferred to Phase 59.

</deferred>

---

*Phase: 57-deterministic-trust-runner-fixtures*
*Context gathered: 2026-05-27*
