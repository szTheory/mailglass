---
phase: 26-runtime-per-tenant-adapter-resolution
plan: "02"
subsystem: outbound
tags: [tenant, routing, outbound, async, worker]
requires: [26-01]
provides:
  - shared sync and async route-resolution precedence in Mailglass.Outbound
  - queue-time adapter_ref persistence for deliver_later and deliver_many
  - worker dispatch that honors persisted route intent instead of rerunning tenancy routing
affects: [outbound, worker, config, tests]
tech-stack:
  added: []
  patterns: [runtime route resolution, persisted adapter_ref dispatch, no-drift queued retries]
key-files:
  created:
    - test/support/outbound_route_test_support.ex
  modified:
    - lib/mailglass/config.ex
    - lib/mailglass/outbound.ex
    - test/support/generators.ex
    - test/mailglass/outbound_test.exs
    - test/mailglass/outbound/deliver_later_test.exs
    - test/mailglass/outbound/deliver_many_test.exs
    - test/mailglass/outbound/worker_test.exs
key-decisions:
  - "Sync resolution order is explicit: `opts[:adapter]` -> `opts[:adapter_ref]` -> tenancy callback -> global default."
  - "Queued paths persist only a durable adapter_ref; raw queued adapter overrides are rejected unless they map cleanly to the default or a named route."
  - "Worker dispatch rehydrates from `delivery.adapter_ref` and restamps the existing delivery id into the message before the adapter call."
patterns-established:
  - "Named route refs can be declared as atoms in config and still round-trip through persisted string adapter refs."
  - "Batch sends resolve adapter refs per message before insert so routing failures become visible delivery results instead of silent fallback."
requirements-completed: [TENANT-01, TENANT-02, TENANT-03]
duration: 14min
completed: 2026-05-01
---

# Phase 26 Plan 02: Outbound Routing Summary

**Tenant-aware runtime adapter resolution for sync sends, queue-time route snapshots for async sends, and no-drift worker dispatch**

## Performance

- **Duration:** 14 min
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Reworked `Mailglass.Outbound` so sync sends, `deliver_later/2`, and `deliver_many/2` all resolve tenant-aware routes through one explicit precedence chain.
- Persisted `adapter_ref` on queued deliveries and taught the worker to dispatch from that stored identity instead of recomputing tenant routing.
- Added focused route-recording support modules and regression tests for sync override precedence, async route persistence, batch route stamping, and worker no-drift behavior.

## Task Commits

Both plan tasks landed together in one commit because they share the same outbound and worker code paths:

1. **Task 1: Refactor the canonical outbound resolution path for sync, async, and batch sends** - `df827de`
2. **Task 2: Make queued dispatch honor persisted route intent and pin no-drift retry behavior** - `df827de`

## Verification

- `mix test test/mailglass/outbound_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/outbound/deliver_many_test.exs test/mailglass/outbound/worker_test.exs --warnings-as-errors`

## Issues Encountered

- Persisted adapter refs are stored as strings, while most runtime config examples use atom keys. `Mailglass.Config.resolve_adapter_ref/1` was updated to normalize both forms so queued dispatch can round-trip cleanly.

## Next Phase Readiness

- Public docs can now describe the actual shipped routing surface: named `adapter_ref` routes, tenancy callback selection, and queue-time persistence semantics.
- Operator-facing delivery rows now carry a durable route identity for future admin and audit surfaces.
