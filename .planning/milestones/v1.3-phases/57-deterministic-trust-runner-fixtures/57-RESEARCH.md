---
phase: 57
slug: deterministic-trust-runner-fixtures
researched: 2026-05-27
status: complete
confidence: high
posture: deterministic runner contract + stable fixture/checkpoint schema
---

# Phase 57 Research: Deterministic Trust Runner + Fixtures

**Researched:** 2026-05-27  
**Domain:** trust-journey orchestration, deterministic fixtures, machine-readable checkpoints  
**Confidence:** HIGH

## Summary

Phase 57 should ship a single deterministic trust-runner command and fixture/checkpoint contract that becomes the source of truth for local and CI trust assertions.

The decisive recommendation is:

1. Define one canonical command for the journey (`install -> preview -> send -> webhook ingest -> operator troubleshooting`) and reuse it across local and CI entrypoints.
2. Make fixture identity deterministic (stable IDs, ordering, and payload fingerprints) with no ad hoc randomness in required assertions.
3. Emit machine-readable checkpoint artifacts with explicit schema version and bounded trust language so downstream required lanes can fail closed on drift.

## User Constraints (from `57-CONTEXT.md`)

### Locked Decisions

- **D-01/D-02:** one canonical trust-runner entrypoint; CI and release wrappers must call the same entrypoint.
- **D-03/D-04:** reuse existing deterministic artifact patterns; fixture IDs/order remain stable across reruns and CI.
- **D-05/D-06:** checkpoint output is machine-readable with explicit schema and executable verification, not narrative-only docs.
- **D-07:** Phase 57 scope is only runner + deterministic fixture/checkpoint foundation (`JOUR-01`, `JOUR-02`).
- **D-08:** target `reference/host_app` with published constraints and public seams only.

### Claude's Discretion

- Final command/module naming for the runner.
- Artifact layout and file naming under a deterministic checkpoint directory.
- Internal decomposition (helpers vs scripts vs tests) as long as external single-entrypoint contract remains intact.

### Deferred (Out of Scope for Phase 57)

- Signed verify-first negative webhook assertion (`JOUR-03`) -> Phase 58.
- Deterministic non-happy-path operator diagnosis scenario (`JOUR-04`) -> Phase 58.
- Required CI trust lanes and evidence gate wiring (`EVID-01`, `EVID-02`, `EVID-04`) -> Phase 59.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `JOUR-01` | One deterministic trust runner command proves install -> preview -> send -> webhook ingest -> operator troubleshooting. | Add one canonical verify alias/task (single command), backed by deterministic scenario execution against `reference/host_app` and explicit checkpoint stages. |
| `JOUR-02` | Trust fixtures use stable IDs/payloads so local and CI assertions are reproducible. | Introduce fixture contract module/files with fixed IDs, stable ordering, and deterministic checkpoint serialization plus contract tests. |

## Project Constraints

- Keep trust claims bounded: usage-proof confidence, not broad cross-client or cross-topology guarantees.
- Reuse proven deterministic artifact contract patterns (`schema_version`, `claim_boundary`, sorted rows, hash checkpoints).
- Avoid provider-matrix expansion and internal module coupling.
- Keep runner non-interactive and CI-safe (single command, deterministic output directory, scriptable verification).

## Existing Pattern Reuse

1. **Deterministic artifact schema**
   - `mailglass_admin/lib/mailglass_admin/preview/capture_manifest.ex`
   - uses explicit `schema_version`, `claim_boundary`, sorted entries, and stable `matrix_sha256`.
2. **Executable checkpoint validator shell gate**
   - `scripts/check_preview_capture_checkpoint.sh`
   - validates files, schema, boundary language, matrix cardinality, and deterministic dimensions.
3. **Reference-host contract posture**
   - `test/reference_host/*_contract_test.exs`
   - enforces README/scope/public-seam claims with deterministic token checks.
4. **Single-command verify entrypoint style**
   - `mix.exs` verify aliases (`verify.*`) are already canonical CI/local command surfaces.

## Recommended Architecture

### Canonical Runner Surface

- Add one canonical runner command under root project verify namespace (recommended shape: `mix verify.reference_host.journey`).
- Command executes deterministic stages and writes checkpoint artifact(s) under a stable path (for example `tmp/mailglass_trust_runner`).

### Deterministic Fixture Contract

- Add fixture source with stable IDs and payload fixtures used by runner/tests.
- Normalize ordering before assertions/artifact writes.
- Include explicit phase-57 fixture vocabulary so Phase 58 can extend without breaking base checkpoint semantics.

### Checkpoint Contract

- Introduce trust checkpoint schema (versioned) with:
  - schema version
  - bounded claim text
  - ordered checkpoints with stage status
  - deterministic scenario IDs
  - aggregate hash/fingerprint for drift detection
- Add executable checker script or ExUnit contract test that fails closed when schema/boundary/order drift occurs.

## Recommended Plan Split

### Plan 57-01: Canonical trust-runner command and stage orchestration (`JOUR-01`)

- Create one command entrypoint and deterministic stage execution contract.
- Wire install/preview/send/webhook/operator checkpoints with stable stage keys.
- Ensure same command can run locally and in CI non-interactively.

### Plan 57-02: Deterministic fixture and checkpoint schema contract (`JOUR-02`)

- Add stable fixture IDs/payload references and deterministic ordering.
- Add trust checkpoint encoder with schema + claim boundary + stable hash.
- Add contract tests validating deterministic reruns and schema shape.

### Plan 57-03: Verification harness and docs-facing runner contract (`JOUR-01`, `JOUR-02`)

- Add checker command/script + focused docs/runbook references to canonical command.
- Add integration tests that run the runner twice and assert identical checkpoint semantics.
- Keep explicit boundary text that verify-first negative and non-happy-path proof are deferred to Phase 58.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Multiple trust entrypoints emerge | local/CI/release drift | enforce one canonical command and route wrappers through it only |
| Fixture non-determinism | flaky trust assertions | stable IDs/order; deterministic serialization and hash checks |
| Scope bleed into Phase 58 concerns | delayed closure of JOUR-01/02 | explicit defer tokens for signed-negative and non-happy-path scenarios |
| Over-claiming trust boundary | contract confusion | include bounded claim language in checkpoint schema and docs |
| Runner too coupled to internals | brittle future maintenance | keep runner on reference-host + public seams; avoid internal module calls |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit contract/integration tests + deterministic checkpoint check script |
| Quick run | `mix test test/reference_host/trust_runner_checkpoint_contract_test.exs --warnings-as-errors` |
| Full suite | `mix verify.reference_host.journey` plus deterministic checkpoint validator |

### Requirement Mapping

| Req ID | Verification focus | Concrete command(s) |
|--------|--------------------|---------------------|
| `JOUR-01` | one command executes full stage chain with stable stage names | `mix verify.reference_host.journey` |
| `JOUR-02` | fixture IDs/payloads and checkpoint output stay deterministic across reruns | run runner twice; compare normalized checkpoint outputs and schema assertions |

### Phase Gate

- Canonical trust-runner command exists and is callable as one command.
- Deterministic fixture/checkpoint contract tests are green with warnings-as-errors.
- Checkpoint artifact has explicit schema version + bounded trust language.

## Assumptions Log

| # | Assumption | Risk if wrong | Handling |
|---|------------|---------------|----------|
| A1 | Verify alias namespace is acceptable for the canonical runner command. | low | fallback to dedicated `mix mailglass.trust.run` task while preserving single-entrypoint rule |
| A2 | Existing preview-capture manifest/checkpoint pattern is acceptable as trust-checkpoint template. | low | retain same shape with trust-specific schema version |
| A3 | Phase 57 can prove webhook/operator happy-path checkpoint semantics without Phase 58 negative-path completeness. | medium | enforce explicit defer token in plans and docs |
| A4 | Reference-host baseline from Phase 52 is stable enough to anchor deterministic runner fixtures. | low | add contract preflight in runner to fail fast with actionable drift output |

## Sources

### Primary

- `.planning/phases/57-deterministic-trust-runner-fixtures/57-CONTEXT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/v1.3-MILESTONE-AUDIT.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`

### Secondary

- `mailglass_admin/lib/mailglass_admin/preview/capture_manifest.ex`
- `scripts/check_preview_capture_checkpoint.sh`
- `test/reference_host/boot_contract_test.exs`
- `test/reference_host/public_seams_contract_test.exs`
- `test/reference_host/scope_lock_contract_test.exs`
- `mix.exs`

## RESEARCH COMPLETE
