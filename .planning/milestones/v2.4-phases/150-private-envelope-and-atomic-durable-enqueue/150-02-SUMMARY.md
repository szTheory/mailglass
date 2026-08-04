---
phase: 150-private-envelope-and-atomic-durable-enqueue
plan: "02"
subsystem: outbound persistence
tags: [elixir, ecto, oban, postgres, outbound]
requires:
  - phase: 150-private-envelope-and-atomic-durable-enqueue
    provides: private envelope codec and payload storage
provides:
  - Prefix-aware four-part durable Oban enqueue transaction
  - Per-envelope batch persistence with ordered replay-safe results
affects: [outbound-worker, unified-dispatch, production-readiness]
tech-stack:
  added: []
  patterns: [atomic Ecto.Multi enqueue, ID-only Oban args, private payload boundary]
key-files:
  created: []
  modified: [lib/mailglass/outbound.ex, lib/mailglass/optional_deps/oban.ex, test/mailglass/outbound/deliver_later_test.exs, test/mailglass/outbound/deliver_many_test.exs]
key-decisions:
  - "Oban job insertion receives the configured schema prefix inside the same Multi as Mailglass records."
  - "Batch messages use independent transactions and return results in their original input order."
requirements-completed: [ENVL-01, ENVL-02, ENVL-04, ENVL-05]
coverage:
  - id: D1
    description: Durable single sends commit Delivery, queued Event, Payload, and canonical Oban job together without public private-content leakage.
    requirement: ENVL-04
    verification:
      - kind: integration
        ref: mix test test/mailglass/outbound/deliver_later_test.exs --only phase_150_task:t150_02_01 --warnings-as-errors
        status: pass
    human_judgment: false
  - id: D2
    description: Each eligible batch item uses the same per-envelope durable boundary while retaining ordered replay-safe results.
    requirement: ENVL-05
    verification:
      - kind: integration
        ref: mix test test/mailglass/outbound/deliver_many_test.exs --only phase_150_task:t150_02_02 --warnings-as-errors
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-08-02
status: complete
---

# Phase 150 Plan 02: Atomic Durable Enqueue Summary

**Single and batch Oban sends now commit a private immutable payload, public delivery and event facts, and the canonical queued job as one prefix-aware transaction.**

## Performance

- **Duration:** 12 min
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Routed Oban `Ecto.Multi` job insertion through prefix-aware options and require all four named results before reporting queued.
- Removed rendered content and internal delivery transport state from public Delivery metadata; the explicit Task.Supervisor branch retains prepared input only in memory.
- Replaced batch bulk/post-commit enqueue with independent per-message boundaries, preserving input order and idempotency replays.
- Added focused integration tests for four-fact success, public-surface privacy, and payload/job rollback.

## Task Commits

1. **Task 1: Commit one durable request as four inseparable facts** — `9c02ff2d` (RED), `9734c08c` (GREEN), `385cf2ad` (format), `62136c76` (rollback hardening)
2. **Task 2: Reuse per-envelope atomicity for deliver_many** — `762a31bf` (RED), `5951923f` (GREEN)

## Files Created/Modified

- `lib/mailglass/outbound.ex` — central four-part durable transaction, safe public projection, per-envelope batch orchestration, and bounded persistence error mapping.
- `lib/mailglass/optional_deps/oban.ex` — prefix-aware `Oban.insert/4` gateway.
- `test/mailglass/outbound/deliver_later_test.exs` — focused private boundary and rollback integration coverage.
- `test/mailglass/outbound/deliver_many_test.exs` — focused independent batch-envelope coverage and updated privacy expectations.

## Decisions Made

- Oban job insertion receives `Repo.multi_opts()` inside the active transaction rather than relying on ambient schema configuration.
- Existing batch idempotency rows are returned before a new enqueue is attempted; a failed new item becomes its own typed result instead of affecting other positions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalized database constraint failures from the durable Multi**
- **Found during:** Task 1 rollback probes.
- **Issue:** A database-level Payload CHECK violation escaped as `Ecto.ConstraintError` instead of returning the public bounded `SendError` shape.
- **Fix:** Rescued transaction constraint/database failures at the durable boundary and mapped them to `:adapter_failure` with a bounded `:persistence_failed` reason class.
- **Files modified:** `lib/mailglass/outbound.ex`, `test/mailglass/outbound/deliver_later_test.exs`.
- **Verification:** Payload and canonical-job temporary constraint probes both leave all four durable stores unchanged.
- **Commit:** `62136c76`.

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** Required for the plan's typed rollback-failure contract; no public feature scope expanded.

## Issues Encountered

The batch module's legacy Task.Supervisor tests emit known Fake-adapter owner warnings while still passing; the focused durable Oban paths complete without warnings or failures.

## Next Phase Readiness

Phase 150 Plan 03 can load the private Payload in the worker and tighten Oban readiness/fail-closed behavior. The public durable write boundary and identifier-only job args are ready.

## Self-Check: PASSED

- Confirmed all four modified source/test files and this summary exist.
- Confirmed commits `9c02ff2d`, `9734c08c`, `385cf2ad`, `762a31bf`, `5951923f`, and `62136c76` exist in git history.
