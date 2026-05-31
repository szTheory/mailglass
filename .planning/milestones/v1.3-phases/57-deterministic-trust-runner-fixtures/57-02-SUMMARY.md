---
phase: 57-deterministic-trust-runner-fixtures
plan: "02"
subsystem: testing
tags: [reference-host, trust-runner, checkpoint-contract]
requires:
  - phase: 57-01
    provides: canonical trust-runner command and deterministic stage pipeline
provides:
  - deterministic fixture catalog with stable IDs and fixed stage ordering
  - schema-versioned trust checkpoint encoder with deterministic hash output
  - executable checkpoint validator and repeatability contract tests
affects: [58-verify-first-webhook-operator-path, 59-ci-trust-lanes, 60-release-trust-gate]
tech-stack:
  added: []
  patterns:
    - schema_version + claim_boundary + deterministic hash contract for checkpoint evidence
    - fail-closed checkpoint validation script with explicit stage-set enforcement
key-files:
  created:
    - test/support/reference_host/trust_runner_fixtures.ex
    - lib/mailglass/reference_host/trust_checkpoint.ex
    - scripts/check_trust_runner_checkpoint.sh
    - test/reference_host/trust_runner_fixture_contract_test.exs
    - test/reference_host/trust_runner_checkpoint_contract_test.exs
  modified:
    - lib/mix/tasks/mailglass.trust.run.ex
    - MAINTAINING.md
key-decisions:
  - "Trust checkpoint schema is fixed at trust_runner.v1 with bounded claim text that explicitly defers signed-negative and non-happy-path semantics to Phase 58."
  - "Checkpoint rows are normalized and sorted deterministically before checkpoint_sha256 calculation."
  - "Canonical runner now emits checkpoint artifacts at tmp/mailglass_trust_runner/checkpoint.json by default so downstream lanes consume one stable path."
patterns-established:
  - "Repeatability contract: two dry-run executions must produce equal normalized checkpoint payloads and matching checkpoint_sha256 values."
requirements-completed: [JOUR-02, JOUR-01]
duration: 5 min
completed: 2026-05-27
---

# Phase 57 Plan 02: Deterministic Fixtures and Trust Checkpoint Contract Summary

**Delivered deterministic fixture/checkpoint evidence for the trust runner, including `trust_runner.v1` schema output, stable ordering/hash semantics, and fail-closed checkpoint validation for downstream trust lanes.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-27T13:25:00Z
- **Completed:** 2026-05-27T13:30:05Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- Added `Mailglass.ReferenceHost.TrustRunnerFixtures` with stable fixture IDs and fixed stage ordering for install/preview/send/webhook/operator stages.
- Added `Mailglass.ReferenceHost.TrustCheckpoint` with `trust_runner.v1`, bounded `claim_boundary`, deterministic row sorting, and `checkpoint_sha256`.
- Added `scripts/check_trust_runner_checkpoint.sh` to fail closed on missing keys, stage set/order drift, and hash mismatches.
- Added fixture and checkpoint contract tests proving deterministic IDs/order and two-run checkpoint payload/hash repeatability.
- Documented trust-runner checkpoint handoff contract in `MAINTAINING.md` with canonical command, artifact path, required keys, and explicit Phase 58 extension boundary.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement deterministic fixture catalog and schema-versioned trust checkpoint encoder** - `8ed47eb` (feat)
2. **Task 2: Add executable checkpoint validator and deterministic repeatability contract tests** - `7030022` (feat)
3. **Task 3: Document downstream checkpoint handoff contract for future trust lanes** - `662938f` (docs)

## Files Created/Modified
- `test/support/reference_host/trust_runner_fixtures.ex` - Stable fixture IDs/order contract for trust stages.
- `lib/mailglass/reference_host/trust_checkpoint.ex` - Deterministic `trust_runner.v1` encoder with ordered `checkpoints` hash output.
- `lib/mix/tasks/mailglass.trust.run.ex` - Emits trust checkpoint schema payloads to default artifact path.
- `scripts/check_trust_runner_checkpoint.sh` - Machine-readable checkpoint validator for schema/boundary/order/hash assertions.
- `test/reference_host/trust_runner_fixture_contract_test.exs` - Verifies deterministic fixture IDs and stage ordering.
- `test/reference_host/trust_runner_checkpoint_contract_test.exs` - Verifies two-run payload equality and `checkpoint_sha256` stability.
- `MAINTAINING.md` - Added trust runner checkpoint handoff contract section.

## Verification Results
- `rg -n "defmodule Mailglass\\.ReferenceHost\\.TrustRunnerFixtures|install|preview|send|webhook_ingest|operator_troubleshooting" test/support/reference_host/trust_runner_fixtures.ex` -> PASS
- `rg -n "defmodule Mailglass\\.ReferenceHost\\.TrustCheckpoint|trust_runner\\.v1|claim_boundary|checkpoint_sha256|checkpoint_count|checkpoints" lib/mailglass/reference_host/trust_checkpoint.ex` -> PASS
- `rg -n "deferred to Phase 58|signed-negative webhook|non-happy-path" lib/mailglass/reference_host/trust_checkpoint.ex` -> PASS
- `bash scripts/check_trust_runner_checkpoint.sh --help` -> PASS
- `mix test test/reference_host/trust_runner_fixture_contract_test.exs --warnings-as-errors` -> PASS (1 test, 0 failures)
- `mix test test/reference_host/trust_runner_checkpoint_contract_test.exs --warnings-as-errors` -> PASS (1 test, 0 failures)
- `bash scripts/check_trust_runner_checkpoint.sh --checkpoint tmp/mailglass_trust_runner/checkpoint.json` -> PASS (after regenerating default checkpoint via `mix verify.reference_host.journey --dry-run`)
- `rg -n "schema_version|claim_boundary|checkpoint_count|checkpoint_sha256|webhook_ingest|operator_troubleshooting" scripts/check_trust_runner_checkpoint.sh` -> PASS
- `rg -n "Trust runner checkpoint handoff|mix verify.reference_host.journey|tmp/mailglass_trust_runner/checkpoint.json|schema_version|claim_boundary|checkpoint_count|checkpoint_sha256|Phase 58" MAINTAINING.md` -> PASS
- `rg -n "trust_runner.v1|claim_boundary|checkpoint_sha256" lib/mailglass/reference_host/trust_checkpoint.ex` -> PASS
- `rg -n "mix verify.reference_host.journey|checkpoint_sha256|Phase 58" MAINTAINING.md` -> PASS

## Decisions Made
- Reused the established deterministic checkpoint contract shape (`schema_version`, `claim_boundary`, ordered rows, aggregate SHA) for trust artifacts.
- Kept stage semantics explicitly bounded to Phase 57 and documented Phase 58 as an extension layer.
- Standardized on a default trust checkpoint output path so script and downstream lanes can consume a single artifact location.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed (0 blocking, 0 missing critical, 0 bugs)  
**Impact on plan:** None.

## Issues Encountered
`mix test` emitted existing non-blocking OTLP exporter warnings and transient Postgrex `too_many_connections` log noise; both targeted contract test runs still completed successfully with 0 failures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 57 Plan 02 contract is complete and provides deterministic fixture/checkpoint semantics for Phase 58 extensions.
- Downstream CI/release trust lanes can consume the stable checkpoint schema and validator without inferring deferred Phase 58 guarantees.

## Self-Check: PASSED

---
*Phase: 57-deterministic-trust-runner-fixtures*  
*Completed: 2026-05-27*
