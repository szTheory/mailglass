---
phase: 150-private-envelope-and-atomic-durable-enqueue
plan: "05"
subsystem: outbound documentation contract
tags: [elixir, oban, outbound, durability, privacy, documentation]
requires:
  - phase: 150-private-envelope-and-atomic-durable-enqueue
    provides: fail-closed Oban readiness, payload-first worker recovery, and production readiness
provides:
  - Active source and adopter documentation synchronized with fail-closed durable Oban selection
  - Focused non-vacuous source contract for adapter fallback and canonical queue drift
affects: [151-unified-dispatch, 153-generated-host-proof, api-stability]
tech-stack:
  added: []
  patterns: [enumerated documentation seam contract, mutation-backed source assertions]
key-files:
  created: []
  modified:
    - lib/mailglass/optional_deps.ex
    - lib/mailglass/optional_deps/oban.ex
    - lib/mailglass/outbound.ex
    - lib/mailglass/application.ex
    - lib/mailglass/config.ex
    - docs/api_stability.md
    - guides/getting-started.md
    - guides/jobs.md
    - test/mailglass/docs_contract_test.exs
key-decisions:
  - "Availability detection, canonical readiness, and transactional insertion remain distinct OptionalDeps.Oban gateway concerns."
  - "Selected Oban is durable and fail-closed; TaskSupervisor is explicitly selected non-durable behavior only."
patterns-established:
  - "Source/adopter contract tests enumerate active regions and use mutation fixtures instead of broad historical negative greps."
requirements-completed: [ENVL-01, ENVL-06, ENVL-07, ENVL-08]
coverage:
  - id: D1
    description: "All active outbound source, stability, and adopter seams state the durable fail-closed Oban and explicit non-durable TaskSupervisor contract."
    requirement: ENVL-06
    verification:
      - kind: unit
        ref: "mix test test/mailglass/docs_contract_test.exs --only phase_150_task:t150_05_01 --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Canonical mailglass_outbound queue and private ID-only transport boundary are protected from active documentation drift."
    requirement: ENVL-08
    verification:
      - kind: integration
        ref: "mix test test/mailglass/outbound/envelope_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/deliver_many_test.exs test/mailglass/outbound/worker_test.exs test/mailglass/migration_test.exs test/mailglass/schema_prefix_hardening_test.exs test/mailglass/application_test.exs test/mailglass/config_test.exs test/mailglass/docs_contract_test.exs test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-08-02
status: complete
---

# Phase 150 Plan 05: Outbound Contract Lock Summary

**Durable Oban, explicit non-durable TaskSupervisor, canonical queue, and private transport-state claims now agree across all active outbound source and adopter seams.**

## Performance

- **Duration:** 14 min
- **Tasks:** 1/1
- **Files modified:** 9

## Accomplishments

- Replaced active automatic-fallback claims with the fail-closed selected-Oban contract, while preserving inbound, historical, and webhook-maintenance exclusions.
- Documented `available?/0`, `ready?/1`, and `insert/4` as distinct gateway responsibilities and aligned application/configuration messaging.
- Added a tagged, mutation-backed documentation contract that enumerates the six source/stability seams and two adopter guides.

## Task Commits

1. **Task 1: Clean and lock every active outbound fallback claim** — `e2f164f8` (RED), `a4528df6` (GREEN), `5a12c733` (verification fix)

## Files Created/Modified

- `lib/mailglass/optional_deps.ex` and `lib/mailglass/optional_deps/oban.ex` — truthful gateway, readiness, insertion, and canonical queue documentation.
- `lib/mailglass/outbound.ex`, `lib/mailglass/application.ex`, and `lib/mailglass/config.ex` — explicit selected-adapter claims with no automatic downgrade.
- `docs/api_stability.md`, `guides/getting-started.md`, and `guides/jobs.md` — private transport, ID-only job, readiness, and non-durability guidance.
- `test/mailglass/docs_contract_test.exs` — active-seam manifest plus fallback and queue-drift mutation fixtures.

## Decisions Made

- Keep private Payload discussion limited to internal recoverable transport state; it creates no archive, admin viewer, or public API promise.
- Tie every active outbound queue example to `Mailglass.Outbound.Worker.queue/0`'s `mailglass_outbound` token.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed a generated-doc warning from the new gateway documentation**
- **Found during:** Task 1 phase verification.
- **Issue:** A new `Oban.insert/4` documentation link targeted a hidden external API and made `mix docs` warn.
- **Fix:** Reworded the sentence as the four-argument Oban Multi variant without changing the gateway contract.
- **Files modified:** `lib/mailglass/optional_deps/oban.ex`.
- **Verification:** `mix docs` completed without that warning; focused contract test passed.
- **Committed in:** `5a12c733`.

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** Documentation verification correctness only; no runtime behavior or public API scope expanded.

## Issues Encountered

The full suite emitted pre-existing optional OTLP, migration-order, test-fixture, and supervised-test-process warnings, but completed successfully with `--warnings-as-errors`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 151 can rely on a single documented durable enqueue boundary without a stale fallback or payload-archive claim.

## Self-Check: PASSED

- Confirmed all nine task files exist and commits `e2f164f8`, `a4528df6`, and `5a12c733` exist in git history.
- Focused contract, wave verification, no-optional-deps compile, documentation generation, and full test suite passed.
