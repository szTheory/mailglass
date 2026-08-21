---
phase: 156
plan: 02
subsystem: outbound-durable-dispatch
tags: [oban, ecto-multi, idempotency, postgres]
status: complete
requires: [156-01]
provides: [atomic-durable-batch-enqueue, deterministic-batch-replay]
affects: [outbound, oban-gateway, task-supervisor-fallback]
tech-stack:
  added: []
  patterns: [single-repo-multi-boundary, named-oban-multi-step, post-commit-input-projection]
key-files:
  created: []
  modified:
    - lib/mailglass/optional_deps/oban.ex
    - lib/mailglass/outbound.ex
    - test/mailglass/outbound/deliver_many_test.exs
decisions:
  - Durable Oban batch jobs are inserted through the same host Repo.multi boundary as delivery rows and queued events.
  - The optional gateway fails the named Multi step when Oban is unavailable instead of acknowledging a non-durable queue.
  - Batch responses are reconstructed from input idempotency keys after commit, preserving mixed replay correspondence.
metrics:
  tasks_completed: 2
  tests: 28
  completed: 2026-08-17
---

# Phase 156 Plan 02: Atomic Durable Batch Dispatch Summary

Durable batch delivery now commits delivery projections, rendered metadata, queued events, and Oban jobs as one transaction, with replay results returned in caller input order.

## Completed Work

- Added an optional-dependency-safe `Ecto.Multi` form of the Oban `insert_all` gateway; absent Oban fails the named transaction step rather than producing a false durable acknowledgement.
- Made the durable `deliver_many/2` branch select Oban before persistence and add jobs from only the rows returned by `insert_all(..., returning: true)`.
- Preserved the Task.Supervisor fallback as a distinct non-durable route for Plan 156-03 while removing the post-commit Oban batch enqueue path.
- Added PostgreSQL/Oban proof for full commit, job-step rollback, replay no-op counts, and mixed-replay input correspondence.

## Verification

- `mix test test/mailglass/outbound/deliver_many_test.exs --warnings-as-errors` — 13 tests, 0 failures.
- `mix test test/mailglass/outbound/deliver_many_test.exs test/mailglass/outbound/delivery_idempotency_key_test.exs --warnings-as-errors` — 28 tests, 0 failures.
- `mix compile --no-optional-deps --warnings-as-errors` — passed.
- `mix format --check-formatted` — passed.

## TDD Gate Compliance

- RED: `0fa3632b` established atomicity/rollback coverage and `8f782bfa` established replay-order coverage; both failed before implementation.
- GREEN: `7b58e10a` added the atomic Multi path and `7df818ac` restored deterministic replay ordering.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Rebuilt batch responses by input idempotency key after commit.
- **Found during:** Task 2 RED coverage.
- **Issue:** the replay SELECT had no ordering contract, so a reordered mixed replay returned rows in storage order rather than input correspondence.
- **Fix:** mapped the complete post-commit projection by idempotency key and rebuilt it from the original input rows.
- **Files modified:** `lib/mailglass/outbound.ex`, `test/mailglass/outbound/deliver_many_test.exs`.
- **Commit:** `7df818ac`.

2. [Rule 3 - Blocking issue] Corrected an invalid local-function guard in the optional Oban gateway.
- **Found during:** Task 1 compilation.
- **Issue:** `available?/0` cannot be invoked in an Elixir guard.
- **Fix:** evaluated availability in the normal `nil` branch while retaining the same fail-closed behavior.
- **Files modified:** `lib/mailglass/optional_deps/oban.ex`.
- **Commit:** `7b58e10a`.

## Self-Check: PASSED

- Confirmed all three plan artifacts exist.
- Confirmed implementation commits `0fa3632b`, `7b58e10a`, `8f782bfa`, and `7df818ac` exist.
