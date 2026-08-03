---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
plan: "04"
subsystem: outbound delivery
tags: [elixir, ecto, oban, payload-lifecycle, dispatch-outcomes, privacy]
requires:
  - phase: 151-01
    provides: shared prepared provider-input seam
  - phase: 151-02
    provides: closed dispatch outcome contract
  - phase: 151-03
    provides: V07 payload lifecycle schema
provides:
  - tenant-scoped durable payload claims before provider I/O
  - atomic durable success settlement with a scrubbed payload tombstone
  - structural worker cancellation for terminal and uncertain payload outcomes
affects: [payload-retention, generated-host-proof, outbound-worker]
tech-stack:
  added: []
  patterns: [CAS payload claims, provider I/O outside transactions, atomic delivery-event-payload settlement]
key-files:
  created: [test/mailglass/outbound/payload_lifecycle_test.exs]
  modified: [lib/mailglass/outbound.ex, lib/mailglass/outbound/payload.ex, lib/mailglass/outbound/worker.ex, lib/mailglass/outbound/dispatch_outcome.ex, test/mailglass/outbound/worker_test.exs]
key-decisions:
  - "Only a recoverable tenant-scoped Payload can be claimed for provider dispatch."
  - "Payload-backed success scrubs in the Delivery/Event settlement Multi; in-memory paths never receive a Payload argument."
patterns-established:
  - "Worker retry/cancel behavior derives from DispatchOutcome class rather than provider error text."
requirements-completed: [DISP-02, DISP-03, PRIV-01, PRIV-03, PRIV-04]
coverage:
  - id: D1
    description: "Recoverable payloads are atomically claimed once before provider dispatch."
    requirement: PRIV-01
    verification:
      - kind: integration
        ref: "mix test test/mailglass/outbound/payload_lifecycle_test.exs --only phase_151_task:t151_04_01 --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Worker cancels modern missing payloads rather than reconstructing or retrying them."
    requirement: PRIV-04
    verification:
      - kind: integration
        ref: "mix test test/mailglass/outbound/worker_test.exs test/mailglass/outbound/payload_lifecycle_test.exs --only phase_151_task:t151_04_02 --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-08-02
status: complete
---

# Phase 151 Plan 04: Race-Safe Payload Settlement Summary

**Durable outbound dispatch now claims private payloads before external I/O, atomically tombstones accepted payloads, and maps closed outcome classes to safe worker behavior.**

## Performance

- **Duration:** 12 min
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added tenant-scoped recoverable-to-dispatching CAS claims and contentless success tombstones.
- Kept provider calls outside Repo transactions while durable success settles Delivery, Event, and Payload in one Multi.
- Added structural retryable/terminal/uncertain worker mapping and fail-closed modern missing-payload cancellation.

## Task Commits

1. **Task 1: Claim once, call outside transactions, and atomically scrub success** — `6e269699` (RED test), `8e71750e` (implementation)
2. **Task 2: Persist terminal and uncertain outcomes and map Oban exhaustively** — `d73c6886` (test), `d9c1d662` (implementation)

## Files Created/Modified

- `lib/mailglass/outbound/payload.ex` — lifecycle schema fields, scoped claim, loading, and settlement changesets.
- `lib/mailglass/outbound.ex` — durable claim/dispatch/settlement orchestration.
- `lib/mailglass/outbound/worker.ex` — closed outcome-to-Oban result mapping.
- `lib/mailglass/outbound/dispatch_outcome.ex` — explicit modern payload reason classes.
- `test/mailglass/outbound/payload_lifecycle_test.exs` — claim race regression proof.
- `test/mailglass/outbound/worker_test.exs` — missing-payload cancellation regression.

## Decisions Made

- Existing legacy rows retain their narrow compatibility reader; modern missing Payload rows are terminal and never reconstructed.
- Lifecycle-originated payload facts cancel automatic worker resend, while compatibility-visible non-lifecycle adapter errors retain their established return shape.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Compatibility] Preserved the narrow legacy queued-row reader.**
- **Found during:** Task 2
- **Issue:** Claim-first dispatch initially treated all absent payloads as modern missing content, breaking existing legacy queued-row coverage.
- **Fix:** Routed only absent payload rows through the established complete legacy reader; modern lifecycle facts still fail closed.
- **Files modified:** `lib/mailglass/outbound.ex`
- **Verification:** `mix test test/mailglass/outbound/worker_test.exs test/mailglass/outbound/envelope_test.exs --warnings-as-errors`
- **Committed in:** `d9c1d662`

**Total deviations:** 1 auto-fixed (Rule 1)

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all listed source and test files exist.
- Confirmed task commits `6e269699`, `8e71750e`, `d73c6886`, and `d9c1d662` exist.
