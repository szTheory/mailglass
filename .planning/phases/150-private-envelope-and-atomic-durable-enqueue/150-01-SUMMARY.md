---
phase: 150-private-envelope-and-atomic-durable-enqueue
plan: "01"
subsystem: outbound persistence
tags: [elixir, ecto, postgres, outbound, envelope]
requires:
  - phase: 149-first-send-contract-foundation
    provides: prepared single-recipient outbound messages and adapter routing
provides:
  - Version-one private outbound envelope codec and SHA-256 integrity digest
  - Tenant-scoped payload schema and prefix-safe V06 DDL
affects: [151-unified-dispatch, outbound-worker]
tech-stack:
  added: []
  patterns: [versioned string-key private envelope, prefix-qualified migration DDL]
key-files:
  created: [lib/mailglass/outbound/envelope.ex, lib/mailglass/outbound/payload.ex, lib/mailglass/migrations/postgres/v06.ex, test/mailglass/outbound/envelope_test.exs]
  modified: [lib/mailglass/outbound.ex, lib/mailglass/migrations/postgres.ex, test/mailglass/migration_test.exs]
key-decisions:
  - "Payloads store an explicit envelope version and lowercase SHA-256 digest."
  - "The Oban enqueue multi writes its private payload between queued event and job."
requirements-completed: [ENVL-01, ENVL-02, ENVL-04, ENVL-05]
coverage:
  - id: D1
    description: Private envelope codec round-trips a prepared single-recipient message.
    requirement: ENVL-02
    verification:
      - kind: unit
        ref: mix test test/mailglass/outbound/envelope_test.exs --only phase_150_task:t150_01_01 --warnings-as-errors
        status: pass
    human_judgment: false
  - id: D2
    description: V06 is exposed by the Postgres migration dispatcher.
    requirement: ENVL-05
    verification:
      - kind: unit
        ref: mix test test/mailglass/migration_test.exs test/mailglass/schema_prefix_hardening_test.exs --only phase_150_task:t150_01_02 --warnings-as-errors
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-02
status: complete
---

# Phase 150 Plan 01: Private Envelope and Atomic Durable Enqueue Summary

**A versioned, integrity-checked private outbound envelope now persists before the canonical Oban job, backed by prefix-qualified V06 payload storage.**

## Performance

- **Duration:** 8 min
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Added the V1 string-key envelope codec, deterministic SHA-256 digest, and materialized attachment representation.
- Added tenant/delivery-scoped Payload persistence and placed it in the canonical enqueue transaction before the job operation.
- Added reversible V06 payload-table DDL and advanced the migration dispatcher to version 6.

## Task Commits

1. **Task 1: Round-trip one prepared envelope through private storage** — `bf42e6a0` (test), `17e1f197` (feat)
2. **Task 2: Prove reversible prefix-safe V06 migration behavior** — `35c00bc2` (test)

## Files Created/Modified

- `lib/mailglass/outbound/envelope.ex` — V1 codec, attachment materialization, and digest.
- `lib/mailglass/outbound/payload.ex` — private Ecto payload schema and scoped lookup.
- `lib/mailglass/outbound.ex` — payload insertion in the Oban multi.
- `lib/mailglass/migrations/postgres/v06.ex` — prefixed payload table and indexes.
- `lib/mailglass/migrations/postgres.ex` — V06 dispatcher registration.

## Decisions Made

- Persist a lowercase SHA-256 digest over the canonical JSON envelope.
- Keep envelope data private to the payload table; public Delivery fields remain projections only.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The full planned verification command passed: 17 tests, 0 failures.

## Next Phase Readiness

Phase 151 can consume the persisted private envelope through `Payload.fetch_for_delivery/2` while retaining the canonical job payload.

## Self-Check: PASSED

- Confirmed all four newly created source/test files exist.
- Confirmed task commits `bf42e6a0`, `17e1f197`, and `35c00bc2` exist in git history.
