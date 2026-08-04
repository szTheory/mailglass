---
phase: 150-private-envelope-and-atomic-durable-enqueue
plan: "08"
subsystem: outbound durability testing
tags: [oban, worker, payload, immutable-retry, tenancy]
requires:
  - phase: 150-06
    provides: decoded V1 payload messages with their persisted adapter reference
provides:
  - Real public-Oban enqueue and stored-job retry proof for immutable rendered content and route selection
  - Fail-closed proof that a Delivery adapter_ref projection mismatch cannot reach either adapter
affects: [151-unified-dispatch, generated-host-proof, outbound-worker]
tech-stack:
  added: []
  patterns: [disabled-mode real Oban job retrieval, mutable callback negative controls]
key-files:
  created: []
  modified:
    - test/mailglass/outbound/worker_test.exs
key-decisions:
  - "The retry proof executes the job inserted by public deliver_later/2 rather than constructing Worker args."
  - "Stateful render and tenancy controls count enqueue callbacks, then prove Worker.perform/1 does not call them after live state changes."
patterns-established:
  - "Durable retry tests must mutate live rendering and routing state after enqueue and observe the actual adapter input."
requirements-completed: [ENVL-04]
coverage:
  - id: D1
    description: "A real ID-only Oban job delivers original rendered bytes, attachment bytes, and route-A input after live render and route state change."
    requirement: ENVL-04
    verification:
      - kind: integration
        ref: "mix test test/mailglass/outbound/worker_test.exs --only phase_150_task:t150_08_01 --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Tampered public adapter_ref projection fails closed before either route adapter is called."
    requirement: ENVL-04
    verification:
      - kind: integration
        ref: "test/mailglass/outbound/worker_test.exs#fails closed before adapter delivery when the public route projection disagrees with the envelope"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-08-03
status: complete
---

# Phase 150 Plan 08: Queued Immutable Retry Proof Summary

**A real disabled-mode Oban job now proves retries send the private V1 payload and its original route after mutable rendering and tenancy state change.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-08-03T01:31:00Z
- **Completed:** 2026-08-03T01:35:15Z
- **Tasks:** 1/1
- **Files modified:** 1

## Accomplishments

- Enqueued through `Outbound.deliver_later/2`, fetched the actual `oban_jobs` row, and performed it through `Worker.perform/1`.
- Proved the stored original subject, rendered body, attachment bytes, and persisted route-A adapter reach the adapter after changing both live controls to route B/new content.
- Proved render and tenancy callbacks remain at their enqueue-only counts, and a Delivery `adapter_ref` mismatch fails before either adapter call.

## Task Commits

1. **Task 1: Prove a queued worker retry ignores changed live render and route state** — `f3883819`, `a434c01b`, `795c6c11`

## Files Created/Modified

- `test/mailglass/outbound/worker_test.exs` — real disabled-mode Oban integration proof, stateful render/route negative controls, projection-tamper check, and complete global-config restoration.

## Decisions Made

- Used a test-local stateful adapter and tenancy resolver so the test observes adapter input and callback counters without changing production routing code.
- Kept `lib/mailglass/outbound.ex` unchanged: its payload-decoded adapter reference already matched Plan 06's required authoritative behavior.

## Deviations from Plan

None - the plan executed exactly as written; no production wiring correction was exposed.

## Issues Encountered

- The renderer escapes the callback-produced HTML before persistence, so the assertion pins the stored escaped payload rather than the pre-render callback string.
- The proof uses a real data-backed `Swoosh.Attachment` marker because public Message metadata is intentionally not preserved in the dispatch envelope.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 151 can rely on a real queued-worker proof that V1 payload content and route are immutable across retry boundaries.
- No Phase 151 outcome classification or payload lifecycle behavior was added.

## Self-Check: PASSED

- Found `test/mailglass/outbound/worker_test.exs` and all three task commits (`f3883819`, `a434c01b`, `795c6c11`).

---
*Phase: 150-private-envelope-and-atomic-durable-enqueue*
*Completed: 2026-08-03*
