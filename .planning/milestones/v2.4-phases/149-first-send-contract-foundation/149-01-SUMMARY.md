---
phase: 149-first-send-contract-foundation
plan: "01"
subsystem: outbound tenancy
tags: [elixir, ecto, swoosh, tenancy, preflight, outbound]
requires: []
provides:
  - "Resolver-aware outbound preflight that writes normalized tenant ownership before effects"
  - "SingleTenant default normalization and strict custom-tenancy rejection proofs"
affects: [149-02, 149-03, 149-04, outbound, tenancy]
tech-stack:
  added: []
  patterns:
    - "Pure resolver-aware preflight before rendering, persistence, queueing, or adapter dispatch"
    - "Custom tenancy uses strict process-local context while SingleTenant alone may normalize default"
key-files:
  created:
    - lib/mailglass/outbound/preflight.ex
  modified:
    - lib/mailglass/outbound.ex
    - test/mailglass/outbound/preflight_test.exs
    - test/mailglass/outbound/deliver_later_test.exs
    - test/mailglass/tenancy_test.exs
    - test/mailglass/boundary_test.exs
key-decisions:
  - "Only configured Mailglass.Tenancy.SingleTenant may resolve an unstamped outbound message to default."
  - "Custom tenancy resolves with tenant_id!/0 so missing, blank, and lost process context fail before effects."
patterns-established:
  - "Outbound stages receive a Message whose tenant_id has already been normalized by Preflight.run/1."
requirements-completed: [FIRST-01, FIRST-02]
coverage:
  - id: D1
    description: "An unstamped SingleTenant message normalizes to default through sync and durable-async outbound paths."
    requirement: FIRST-01
    verification:
      - kind: integration
        ref: "test/mailglass/outbound/preflight_test.exs and test/mailglass/outbound/deliver_later_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Custom tenancy rejects missing, blank, and lost context without Delivery or Fake-adapter side effects, while valid stamps own persisted delivery."
    requirement: FIRST-02
    verification:
      - kind: integration
        ref: "test/mailglass/outbound/preflight_test.exs#custom tenancy resolver-aware tenancy normalization"
        status: pass
      - kind: unit
        ref: "test/mailglass/tenancy_test.exs#custom tenancy remains fail-closed"
        status: pass
    human_judgment: false
metrics:
  duration: 19m
  completed: 2026-08-02
status: complete
---

# Phase 149 Plan 01: First-Send Contract Foundation Summary

**Resolver-aware outbound preflight normalizes unstamped SingleTenant messages to `"default"` while keeping every custom tenancy context fail-closed before outbound effects.**

## Performance

- **Duration:** 19m
- **Started:** 2026-08-02T17:22:02Z
- **Completed:** 2026-08-02T17:41:40Z
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added the internal pure `Mailglass.Outbound.Preflight` gate and made sync, async, and per-item batch paths normalize tenancy before downstream work.
- Proved unstamped `SingleTenant` sync and durable-async sends persist and dispatch with tenant `"default"`.
- Proved custom missing, blank, and async-restoration-loss context raises `%Mailglass.TenancyError{type: :unstamped}` without Delivery or Fake-adapter side effects; valid custom stamps flow into delivery ownership.

## Task Commits

1. **Task 1: Send one unstamped SingleTenant message end to end** - `0177a5cf`, `d310ef78` (test, feat)
2. **Task 2: Prove custom tenancy remains fail-closed** - `8156167b` (feat)
3. **Post-wave integration fix: Synchronize async Fake ownership** - `1ade874f` (fix)

## Files Created/Modified

- `lib/mailglass/outbound/preflight.ex` - Pure resolver-aware tenant and envelope/body gate.
- `lib/mailglass/outbound.ex` - Routes every outbound entry point through preflight before effects.
- `test/mailglass/outbound/preflight_test.exs` - Public sync-path tenancy and side-effect regression coverage.
- `test/mailglass/outbound/deliver_later_test.exs` - Default-tenant durable-async ownership coverage.
- `test/mailglass/tenancy_test.exs` - Strict custom context and restoration-loss coverage.
- `test/mailglass/boundary_test.exs` - Internal-child Boundary contract coverage.

## Decisions Made

- Only the configured `Mailglass.Tenancy.SingleTenant` resolver may turn missing process context into `"default"`.
- Custom resolvers use strict `tenant_id!/0`; empty stamps are rejected as `:unstamped` and no fallback crosses tenant boundaries.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The post-wave integration gate exposed an order-sensitive Task.Supervisor/Fake ownership race. Blind sleeps were replaced with monitored child completion; the exact 61-test wave gate then passed across the orchestrator run and six debugger seeds without ownership or sandbox-teardown warnings.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 149-02 can extend the shared preflight gate with the remaining recipient and body-shape matrix while retaining resolver-aware tenancy normalization.

## Self-Check: PASSED

- Confirmed task commits `0177a5cf`, `d310ef78`, `8156167b`, and post-wave fix `1ade874f` exist.
- Confirmed `lib/mailglass/outbound/preflight.ex` and focused tenancy/outbound tests exist.
