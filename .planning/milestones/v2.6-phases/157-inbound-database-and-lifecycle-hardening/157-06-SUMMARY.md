---
phase: 157-inbound-database-and-lifecycle-hardening
plan: 06
subsystem: database
tags: [elixir, ecto, ets, suppression, batch-delivery, postgres]
requires:
  - phase: 156-delivery-correctness-and-bounded-execution
    provides: durable ordered batch delivery semantics
provides:
  - Optional positional suppression bulk capability with compatible legacy fallback
  - Bounded, deduplicated batch suppression preflight
  - Bare-column Ecto suppression predicates suitable for indexed lookup
affects: [suppression, outbound, batch-delivery, resync]
tech-stack:
  added: []
  patterns: [optional behaviour capability probe, bounded positional bulk result validation]
key-files:
  modified:
    - lib/mailglass/suppression_store.ex
    - lib/mailglass/suppression_store/ecto.ex
    - lib/mailglass/suppression_store/ets.ex
    - lib/mailglass/suppression.ex
    - lib/mailglass/outbound.ex
key-decisions:
  - "Chunk every native and legacy bulk invocation at a hard maximum of 100 keys."
  - "Treat an optional store returning the wrong positional result count as a fail-closed preflight rejection."
requirements-completed: [DATA-03, DATA-04]
coverage:
  - id: D1
    description: Positional native and legacy suppression bulk lookup contract
    requirement: DATA-03
    verification:
      - kind: unit
        ref: mix test test/mailglass/suppression_store/ecto_test.exs test/mailglass/suppression_store/ets_test.exs --warnings-as-errors
        status: pass
    human_judgment: false
  - id: D2
    description: Bounded deduplicated batch preflight with ordered results and fail-closed malformed-store handling
    requirement: DATA-04
    verification:
      - kind: integration
        ref: mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_many_test.exs --warnings-as-errors
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-08-17
status: complete
---

# Phase 157 Plan 06: Bounded Suppression Preflight Summary

**Positional, bounded suppression bulk checks across Ecto, ETS, legacy stores, and ordered async delivery batches.**

## Accomplishments

- Added optional `check_many/2` support with a hard-bounded, positional `check/2` fallback for existing custom stores.
- Implemented deduplicated native Ecto and ETS lookup paths while preserving tenant, stream, expiry, and input-order semantics.
- Removed indexed-column text casts from Ecto suppression predicates and made `deliver_many/2` restore result order after preflight failures.
- Added native chunk-count, malformed callback, mixed-result, duplicate, and legacy compatibility coverage.

## Task Commits

1. **Task 1: Resolve one mixed suppression batch positionally** — `fb883b94` (RED), `c6e49a9b` (GREEN), `ba70925a` (format), `a9fa7da1` (legacy fallback coverage)
2. **Task 2: Bound delivery preflight queries without changing outcomes** — `eff99240` (RED), `0c45ec39` (GREEN)

## Files Modified

- `lib/mailglass/suppression_store.ex` — optional capability probe, bounded chunking, and result-count validation.
- `lib/mailglass/suppression_store/ecto.ex` — direct bare-column predicates and positional native bulk reconstruction.
- `lib/mailglass/suppression_store/ets.ex` — deduplicated positional bulk lookup.
- `lib/mailglass/suppression.ex` — shared batch-to-preflight result/telemetry translation.
- `lib/mailglass/outbound.ex` — deduplicated suppression preflight and ordered batch result restoration.
- `test/mailglass/suppression_store/{ecto,ets}_test.exs` and `test/mailglass/outbound/deliver_many_test.exs` — conformance and bounded-work coverage.

## Decisions Made

- Applied the same hard 100-key maximum to native and legacy callbacks so a custom batch-size setting cannot create an unbounded Ecto query.
- A bulk callback that returns a result list of the wrong length becomes a non-dispatchable preflight error rather than silently misaligning recipients.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fail closed on malformed optional bulk-store results**
- **Found during:** Task 2
- **Issue:** A callback returning fewer positional results could mis-map recipients and then crash failed-delivery serialization.
- **Fix:** Validated callback result count, returned a typed fail-closed error for every affected key, and translated it to a safe preflight rejection.
- **Files modified:** `lib/mailglass/suppression_store.ex`, `lib/mailglass/suppression.ex`, `test/mailglass/outbound/deliver_many_test.exs`
- **Verification:** Focused store and outbound test suite passes.
- **Committed in:** `0c45ec39`

**2. [Rule 2 - Missing Critical Functionality] Bound native callback cardinality**
- **Found during:** Task 2 review
- **Issue:** Native Ecto callbacks initially received the full input, allowing a user-sized OR query.
- **Fix:** Moved chunking ahead of capability dispatch and clamped configured chunk sizes to 100 keys.
- **Files modified:** `lib/mailglass/suppression_store.ex`
- **Verification:** Native chunk-count integration test passes.
- **Committed in:** `0c45ec39`

## Verification

- `mix test test/mailglass/suppression_store/ecto_test.exs test/mailglass/suppression_store/ets_test.exs test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_many_test.exs --warnings-as-errors`
- `mix compile --no-optional-deps --warnings-as-errors`
- `mix format --check-formatted` for all plan files

## Self-Check: PASSED

- All listed implementation and test files exist.
- Task commits `fb883b94`, `c6e49a9b`, `eff99240`, `0c45ec39`, and `a9fa7da1` exist in git history.
