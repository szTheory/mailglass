---
phase: 150-private-envelope-and-atomic-durable-enqueue
plan: "06"
subsystem: outbound
tags: [elixir, swoosh, envelope, json, oban]
requires:
  - phase: 150-05
    provides: payload-first durable dispatch and private payload persistence
provides:
  - Complete lossless V1 envelope decoding with persisted adapter routing
  - Bounded JSON validation and durable attachment materialization
affects: [151-unified-dispatch, outbound-worker]
tech-stack:
  added: []
  patterns: [allowlisted versioned codec, ordered pair collections, bounded canonical JSON]
key-files:
  created: []
  modified: [lib/mailglass/outbound/envelope.ex, lib/mailglass/outbound/payload.ex, lib/mailglass/outbound.ex, test/mailglass/outbound/envelope_test.exs]
key-decisions:
  - "Payload-backed dispatch uses the envelope adapter_ref; a non-nil Delivery projection must agree."
  - "Headers and attachment headers use ordered string-pair wire arrays to preserve duplicates."
requirements-completed: [ENVL-02, ENVL-04]
coverage:
  - id: D1
    description: Complete V1 message, route, ordered headers, nil semantics, and materialized attachments round-trip.
    requirement: ENVL-02
    verification:
      - kind: unit
        ref: mix test test/mailglass/outbound/envelope_test.exs --only phase_150_task:t150_06_01 --warnings-as-errors
        status: pass
    human_judgment: false
  - id: D2
    description: Recursive JSON resource and unsafe-term rejection is enforced before persistence.
    requirement: ENVL-04
    verification:
      - kind: unit
        ref: mix test test/mailglass/outbound/envelope_test.exs --only phase_150_task:t150_06_02 --warnings-as-errors
        status: pass
    human_judgment: false
metrics:
  duration: 12min
  completed: 2026-08-02
status: complete
---

# Phase 150 Plan 06: Complete Private Envelope Fidelity Summary

**Lossless, bounded V1 durable envelope codec with immutable attachment bytes and persisted adapter-route dispatch.**

## Performance

- **Duration:** 12 min
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Reconstructed every supported envelope field, preserving nil/empty semantics and native recipient placement.
- Kept header and attachment-header ordering plus duplicate entries through persistence and load.
- Materialized attachment bytes once at dump time and enforced JSON depth, item, byte, key, UTF-8, and finite-float limits.

## Task Commits

1. **Task 1: Complete V1 fidelity and attachment materialization** - `c9fc8ed4` (test), `86ca995f` (feat)
2. **Task 2: Recursive JSON and envelope bounds** - `d8381613` (test), `86ca995f` (feat)

## Files Created/Modified

- `lib/mailglass/outbound/envelope.ex` - strict V1 codec, bounded JSON validation, and attachment materialization.
- `lib/mailglass/outbound/payload.ex` - digest-safe loader returning the full decoded envelope.
- `lib/mailglass/outbound.ex` - payload-first dispatch using validated persisted route with mismatch rejection.
- `test/mailglass/outbound/envelope_test.exs` - focused fidelity, TOCTOU, and hostile-input regression coverage.

## Decisions Made

- A nil legacy Delivery adapter projection does not conflict with a modern persisted payload route; any non-nil disagreement fails closed.
- BEAM rejects construction of IEEE NaN/infinity terms from external float bits, but the codec still identifies exponent-all-ones float representations before JSON encoding.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Compatibility] Retained legacy nil Delivery adapter projections during payload-first dispatch**
- **Found during:** Task 1
- **Issue:** Existing worker proof fixtures use a nil legacy Delivery projection while their modern envelope carries the default adapter route.
- **Fix:** Treat only a non-nil, unequal Delivery route as a mismatch; the envelope remains authoritative for payload-backed dispatch.
- **Files modified:** `lib/mailglass/outbound.ex`
- **Verification:** focused envelope and worker suite passed.
- **Committed in:** `86ca995f`

**Total deviations:** 1 auto-fixed (Rule 1)

## Issues Encountered

- The runtime cannot construct NaN/infinity from IEEE external float bits for a direct test fixture; finite-float bit inspection remains in the validator and ordinary hostile JSON coverage passes.

## Next Phase Readiness

Phase 151 can consume the complete decoded `message` plus immutable `adapter_ref` value without reselecting a route.

## Self-Check: PASSED

- Verified all four changed implementation/test files and commits `c9fc8ed4`, `d8381613`, and `86ca995f` exist.
