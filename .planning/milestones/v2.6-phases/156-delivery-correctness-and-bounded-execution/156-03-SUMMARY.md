---
phase: 156
plan: 03
subsystem: async-dispatch
tags: [task-supervisor, bounded-concurrency, error-contracts, inbound]
status: complete
requires: [156-02]
provides: [bounded-task-fallback, truthful-dispatch-admission]
affects: [outbound, inbound-execution, send-error]
tech-stack:
  added: []
  patterns: [held-child-barrier, result-bearing-dispatch, typed-admission-failure]
key-files:
  created: []
  modified:
    - lib/mailglass/application.ex
    - lib/mailglass/errors/send_error.ex
    - lib/mailglass/outbound.ex
    - lib/mailglass/outbound/async_adapter.ex
    - lib/mailglass/outbound/async_adapter/task_supervisor.ex
    - mailglass_inbound/lib/mailglass_inbound/application.ex
    - mailglass_inbound/lib/mailglass_inbound/execution.ex
decisions:
  - Task-supervisor fallback is capped at ten children in core and inbound.
  - Rejected admission is represented by the additive dispatch-unavailable SendError type and a finite reason class.
  - SendError retry_class is additive and deliberately excluded from the stable JSON representation.
metrics:
  tasks_completed: 2
  tests: 56
  completed: 2026-08-17
---

# Phase 156 Plan 03: Bounded and Truthful Task Fallback Summary

Core and inbound Task.Supervisor fallbacks now admit at most ten held children and report any refusal as a typed, persisted failure rather than a false queued acknowledgement.

## Completed Work

- Capped the core and inbound fallback supervisors at ten children and added deterministic held-child barrier coverage for the eleventh admission.
- Extended `Mailglass.SendError` additively with `:dispatch_unavailable` and `retry_class`, while retaining JSON fields exactly as `type`, `message`, and `context`.
- Updated the async adapter behaviour, implementation, and callers to carry explicit accepted and rejected dispatch results.
- Persisted core single and batch admission refusals through the existing failed-event path; accepted fallback work remains best effort and durable Oban routing remains unchanged.
- Normalized inbound fallback error, exit, and unavailable-supervisor outcomes to the same privacy-safe typed error.

## Verification

- `mix test test/mailglass/application_test.exs test/mailglass/error_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/deliver_many_test.exs --warnings-as-errors` — 51 tests, 0 failures (2 pre-existing skips).
- `cd mailglass_inbound && mix test test/mailglass_inbound/async_execution_test.exs --warnings-as-errors` — 5 tests, 0 failures.
- `mix format --check-formatted` — passed.

## TDD Gate Compliance

- RED: barrier and refusal-contract tests failed before the admission/error implementation.
- GREEN: `d18f36d2` and `281ac8f2` implement the core and inbound paths respectively.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- Confirmed all eight implementation modules and five focused test modules exist.
- Confirmed implementation commits `d18f36d2` and `281ac8f2` exist.
