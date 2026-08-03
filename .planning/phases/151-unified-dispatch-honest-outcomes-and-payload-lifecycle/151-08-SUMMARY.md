---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
plan: "08"
subsystem: outbound dispatch and documentation contracts
tags: [oban, ecto, payload-lifecycle, privacy, docs-contract]
requires:
  - phase: 151-07
    provides: terminal dispatch outcomes and lifecycle documentation baseline
provides:
  - Every queued Delivery without a private Payload settles once as legacy_payload_missing.
  - Public Delivery metadata can never be reconstructed into adapter input.
  - Executable guidance requires operator recovery from an authoritative private source.
affects: [outbound worker, payload lifecycle, compatibility guidance, operator recovery]
tech-stack:
  added: []
  patterns: [payload-first fail-closed dispatch, atomic Delivery/Event terminal settlement, docs contract regressions]
key-files:
  created: []
  modified:
    - lib/mailglass/outbound.ex
    - lib/mailglass/outbound/dispatch_outcome.ex
    - lib/mailglass/outbound/worker.ex
    - test/mailglass/outbound/worker_test.exs
    - test/mailglass/docs_contract_test.exs
    - guides/jobs.md
    - guides/getting-started.md
    - guides/compatibility-and-deprecations.md
    - docs/api_stability.md
key-decisions:
  - "D-19 amendment and PRIV-04 require every absent private Payload to fail closed, regardless of historical metadata shape."
  - "legacy_days retains only actual private legacy Payload content and tombstones; it is never a metadata-dispatch grace window."
patterns-established:
  - "Missing payloads settle a bounded public outcome without reading Delivery.metadata."
requirements-completed: [DISP-02, PRIV-03, PRIV-04]
coverage:
  - id: D1
    description: "Historical and current queued no-Payload work atomically cancels as legacy_payload_missing with no adapter call or metadata disclosure."
    requirement: PRIV-04
    verification:
      - kind: integration
        ref: "test/mailglass/outbound/worker_test.exs#fails closed and settles a historical no-Payload job without exposing its private sentinel"
        status: pass
    human_judgment: false
  - id: D2
    description: "Adoption, compatibility, and API guidance reject the retired metadata dispatch promise and describe explicit operator recovery."
    requirement: PRIV-03
    verification:
      - kind: unit
        ref: "test/mailglass/docs_contract_test.exs#public guidance locks fail-closed no-Payload dispatch, privacy, and retention"
        status: pass
      - kind: other
        ref: "MIX_ENV=test mix verify.support_contract.core"
        status: pass
    human_judgment: false
duration: 20min
completed: 2026-08-03
status: complete
---

# Phase 151 Plan 08: Retire Legacy Metadata Dispatch Summary

**Payload-first durable dispatch now terminalizes every no-Payload row as `legacy_payload_missing`, with preserved public provenance and no metadata-to-adapter reconstruction.**

## Performance

- **Duration:** 20 min
- **Completed:** 2026-08-03
- **Tasks:** 2/2
- **Files modified:** 9

## Accomplishments

- Removed the legacy loader, rehydrator, recipient/header rebuilders, and legacy dispatch overload.
- Added an end-to-end private-sentinel worker oracle covering first/repeated execution, one Event, unchanged metadata, no Payload creation, and zero adapter calls.
- Updated executable docs to require re-authoring/re-enqueueing from an authoritative private source while retaining finite cleanup only for real legacy private content.

## Task Commits

1. **Task 1: Fail closed an actual historical no-Payload worker path** — `69488de4` (`feat`)
2. **Task 2: Retire the legacy dispatch promise from executable guidance** — `c43bd353` (`docs`)

## Verification

- `mix test test/mailglass/outbound/worker_test.exs test/mailglass/outbound/payload_lifecycle_test.exs test/mailglass/outbound/dispatch_outcome_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors` — pass (66 tests, 1 skipped)
- `MIX_ENV=test mix verify.support_contract.core` — pass (205 tests, 1 skipped)
- `MIX_ENV=test mix verify.no_optional_runtime` — pass
- `mix test --warnings-as-errors` — pass (pre-existing migration/runtime warnings only)

## Decisions Made

- The authoritative D-19 amendment and PRIV-04 supersede the former narrow legacy-reader promise: absence of the private Payload alone determines the terminal result.
- The Delivery/Event settlement shares one Ecto.Multi; repeated jobs observe the already-terminal bounded outcome instead of appending another Event.

## Deviations from Plan

None - plan executed as amended by D-19 / commit `dfd377c8`.

## Known Stubs

None.

## Next Phase Readiness

Phase 151's verification blocker `cc1a237f` is falsified by a real worker-path sentinel test. No follow-up work is required before the next phase.

## Self-Check: PASSED

- Runtime and documentation files exist and both task commits are present in git history.
