---
phase: 57-deterministic-trust-runner-fixtures
plan: "01"
subsystem: testing
tags: [reference-host, trust-runner, deterministic]
requires:
  - phase: 52-trust-scope-lock-reference-host-baseline
    provides: maintained reference host baseline and public seam contract
provides:
  - canonical deterministic trust-runner command entrypoint
  - fail-closed contract test coverage for JOUR-01 command semantics
  - explicit Phase 58 deferred-scope documentation and assertions
affects: [57-02, 58-verify-first-webhook-operator-path, 59-ci-trust-lanes]
tech-stack:
  added: []
  patterns:
    - verify alias as single trust-runner orchestration surface
    - deterministic stage pipeline with fail-closed stage-signal validation
key-files:
  created:
    - lib/mix/tasks/mailglass.trust.run.ex
    - test/reference_host/trust_runner_command_contract_test.exs
  modified:
    - mix.exs
    - reference/host_app/README.md
key-decisions:
  - "Canonical trust orchestration uses mix verify.reference_host.journey with preferred env :test."
  - "Runner stage order is hard-coded and validated as install -> preview -> send -> webhook_ingest -> operator_troubleshooting."
  - "Phase boundary text explicitly defers JOUR-03/JOUR-04 signed-negative and non-happy-path proof to Phase 58."
patterns-established:
  - "Contract test token lock: runner command and deferred-scope language are fail-closed via deterministic token checks."
requirements-completed: [JOUR-01]
duration: 5 min
completed: 2026-05-27
---

# Phase 57 Plan 01: Canonical Trust Runner Command and Deterministic Stage Flow Summary

**Shipped one canonical `mix verify.reference_host.journey` entrypoint backed by a deterministic stage runner and fail-closed contract tests that preserve the Phase 57/58 trust boundary.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-27T13:22:00Z
- **Completed:** 2026-05-27T13:27:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added canonical trust-runner alias and preferred env mapping in `mix.exs`.
- Implemented `Mix.Tasks.Mailglass.Trust.Run` with deterministic five-stage flow and required option parsing (`--checkpoint-out`, `--host-root`, `--dry-run`).
- Added `test/reference_host/trust_runner_command_contract_test.exs` to lock JOUR-01 stage semantics and explicit Phase 58 deferred-scope claims.
- Updated `reference/host_app/README.md` with canonical command usage and explicit deferred wording for `JOUR-03` and `JOUR-04`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add one canonical trust-runner command entrypoint and deterministic stage pipeline** - `293cd74` (feat)
2. **Task 2: Add fail-closed command contract tests and explicit deferred-scope guardrails** - `9d995e2` (test)

## Files Created/Modified
- `mix.exs` - Added `verify.reference_host.journey` alias and `:test` preferred env mapping.
- `lib/mix/tasks/mailglass.trust.run.ex` - Implemented deterministic trust-runner task contract and option parsing.
- `test/reference_host/trust_runner_command_contract_test.exs` - Added fail-closed token assertions for runner stages and Phase 58 defer guardrails.
- `reference/host_app/README.md` - Added canonical trust-runner command section and explicit defer language.

## Verification Results
- `rg -n "verify.reference_host.journey" mix.exs` -> PASS
- `rg -n "defmodule Mix\\.Tasks\\.Mailglass\\.Trust\\.Run|install|preview|send|webhook_ingest|operator_troubleshooting|checkpoint_out|host_root|dry_run" lib/mix/tasks/mailglass.trust.run.ex` -> PASS
- `mix help mailglass.trust.run` -> PASS
- `mix verify.reference_host.journey --dry-run` -> PASS (all five stage keys emitted)
- `mix test test/reference_host/trust_runner_command_contract_test.exs --warnings-as-errors` -> PASS (2 tests, 0 failures)
- `rg -n "install|preview|send|webhook_ingest|operator_troubleshooting|JOUR-03|JOUR-04|Phase 58" test/reference_host/trust_runner_command_contract_test.exs` -> PASS
- `rg -n "mix verify.reference_host.journey|Phase 58|signed|non-happy-path" reference/host_app/README.md` -> PASS

## Decisions Made
- Chose one canonical verify alias (`verify.reference_host.journey`) as the only trust-runner orchestration surface.
- Kept stage outputs deterministic via hard-coded stage keys and explicit status values.
- Guarded Phase 57 scope by enforcing explicit defer language for signed-negative webhook and non-happy-path diagnosis.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed (0 blocking, 0 missing critical, 0 bugs)  
**Impact on plan:** None.

## Issues Encountered
None. `mix test` emitted a non-blocking OTLP exporter warning from existing environment settings; tests still passed with warnings-as-errors.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plan 01 contract is complete and ready for Phase 57 Plan 02 deterministic fixture/checkpoint schema work.
- Canonical runner command and deferred-scope boundaries are now explicit and test-enforced.

## Self-Check: PASSED

---
*Phase: 57-deterministic-trust-runner-fixtures*  
*Completed: 2026-05-27*
