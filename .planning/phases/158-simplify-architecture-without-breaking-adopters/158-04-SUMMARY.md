---
phase: 158-simplify-architecture-without-breaking-adopters
plan: 04
subsystem: outbound-delivery
tags: [architecture, outbound, persistence, routing, preflight]
requires:
  - phase: 158-02
    provides: runtime-backed configuration accessors
  - phase: 158-03
    provides: narrow core integration ports
provides:
  - stable Outbound facade over explicit preflight, routing, persistence, and dispatch owners
  - shared idempotency and delivery persistence policy for sync, async, batch, and replay paths
  - stability contract proving collaborator modules remain internal
affects: [158-06, 159-engineering-gates, outbound]
tech-stack:
  added: []
  patterns: [thin stable facade, responsibility-owned collaborators, external I/O between transactions]
key-files:
  created:
    - lib/mailglass/outbound/preflight.ex
    - lib/mailglass/outbound/routes.ex
    - lib/mailglass/outbound/persistence.ex
    - lib/mailglass/outbound/dispatch.ex
  modified:
    - lib/mailglass/outbound.ex
    - test/mailglass/outbound/preflight_test.exs
    - test/mailglass/stability_contract_test.exs
key-decisions:
  - "Outbound retains public coercion, telemetry envelopes, async admission, and result presentation while internal collaborators own delivery policy."
  - "Persistence owns queued/dispatched Multi composition plus shared idempotency and delivery attributes; adapter I/O remains outside transactions."
  - "Collaborators use hidden module documentation so extraction does not expand the promised adopter API."
patterns-established:
  - "Delivery modes share Preflight, Routes, Persistence, and Dispatch collaborators without changing stable public verbs."
requirements-completed: [ARCH-04]
coverage:
  - id: D1
    description: "Synchronous delivery preserves preflight, routing, persistence, adapter, event, and return behavior behind explicit collaborators."
    requirement: ARCH-04
    verification:
      - kind: integration
        ref: "mix test test/mailglass/outbound_test.exs test/mailglass/outbound/preflight_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Async, batch, and replay behavior shares routing, dispatch, idempotency, and persistence policy without expanding public API."
    requirement: ARCH-04
    verification:
      - kind: integration
        ref: "mix test test/mailglass/outbound_test.exs test/mailglass/outbound test/mailglass/stability_contract_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D3
    description: "Outbound architecture remains optional-dependency-safe, cycle-free, formatted, and inside declared boundaries."
    requirement: ARCH-04
    verification:
      - kind: integration
        ref: "mix compile --no-optional-deps --warnings-as-errors; mix test test/scripts/architecture_boundary_test.exs --warnings-as-errors; mix xref graph --format cycles --label compile-connected; mix format --check-formatted"
        status: pass
    human_judgment: false
duration: 7m
completed: 2026-08-17
status: complete
---

# Phase 158 Plan 04: Outbound Responsibility Seams Summary

`Mailglass.Outbound` now preserves its stable delivery surface while cohesive internal modules own preflight, route selection, persistence policy, and provider dispatch.

## Performance

- **Duration:** 7 min
- **Completed:** 2026-08-17
- **Tasks:** 2
- **Files created:** 4
- **Files modified:** 3

## Accomplishments

- Extracted the ordered tenant, tracking, suppression, rate-limit, stream, render, compliance, and tracking-rewrite pipeline into `Mailglass.Outbound.Preflight`.
- Centralized named/default/tenant/persisted adapter selection in `Routes`, provider telemetry and calls in `Dispatch`, and queued/dispatched persistence plus shared idempotency/attributes in `Persistence`.
- Routed synchronous, asynchronous, batch, and replay flows through those owners while retaining public return shapes, optional Oban/Task behavior, retry handling, post-commit broadcasts, and provider I/O outside transactions.
- Locked the public verb inventory and hidden collaborator status into the stability contract.

## Task Commits

1. **RED: Characterize collaborator seams** - `6f0d52d5` (test)
2. **Task 1: Extract outbound responsibility seams** - `1f03ce77` (refactor)
3. **Task 2: Unify outbound persistence policy** - `96e38278` (refactor)

## Verification

- Passed synchronous outbound/preflight suite: 21 tests, 0 failures.
- Passed outbound and stability suite: 1 property plus 111 tests, 0 failures.
- Passed root no-optional-dependency compile and architecture boundary suite: 4 tests, 0 failures.
- Passed compile-connected xref with no cycles, formatter, and `git diff --check`.
- Expected Fake-adapter owner warnings occurred in Task.Supervisor fallback tests; all assertions passed.

## Deviations from Plan

None - the extraction preserved the public contract and stayed within outbound core code; admin/operator UI was untouched.

## User Setup Required

None.

## Next Phase Readiness

Outbound is ready for the cross-cutting architecture/security verification in Plan 06. No blockers remain.

## Self-Check: PASSED

- All four collaborator modules exist and are hidden from adopter documentation.
- Public Outbound verb arities are explicitly covered by the stability contract.
- Task commits `6f0d52d5`, `1f03ce77`, and `96e38278` are present.
- All required verification commands passed.

---
*Phase: 158-simplify-architecture-without-breaking-adopters*
*Completed: 2026-08-17*
