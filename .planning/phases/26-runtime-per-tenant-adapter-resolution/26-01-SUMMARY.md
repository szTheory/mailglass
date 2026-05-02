---
phase: 26-runtime-per-tenant-adapter-resolution
plan: "01"
subsystem: outbound
tags: [tenant, routing, config, persistence, delivery]
requires: []
provides:
  - optional outbound adapter-ref tenancy callback with explicit default fallback
  - validated named adapter registry in Mailglass.Config
  - durable delivery adapter_ref field plus V04 migration bump
affects: [tenancy, config, outbound, migrations]
tech-stack:
  added: []
  patterns: [optional tenancy callback, additive config registry, durable route-ref persistence]
key-files:
  created:
    - lib/mailglass/migrations/postgres/v04.ex
    - priv/repo/migrations/00000000000005_mailglass_v04.exs
  modified:
    - lib/mailglass/tenancy.ex
    - lib/mailglass/tenancy/single_tenant.ex
    - lib/mailglass/config.ex
    - lib/mailglass/outbound/delivery.ex
    - lib/mailglass/migrations/postgres.ex
    - test/mailglass/tenancy_test.exs
    - test/mailglass/config_test.exs
    - test/mailglass/outbound/delivery_test.exs
    - test/mailglass/migration_test.exs
key-decisions:
  - "Keep outbound route choice on the existing Mailglass.Tenancy seam with a narrow `resolve_outbound_adapter_ref/1` callback that defaults cleanly to :default."
  - "Validate both the global adapter and the additive `config :mailglass, adapters:` registry inside Mailglass.Config so later outbound code does not need ad hoc env reads."
  - "Persist queue-time route identity on a dedicated `mailglass_deliveries.adapter_ref` column and reserve `\"__default__\"` as the global-default sentinel."
patterns-established:
  - "Named adapter refs normalize to the same `{module, opts}` transport shape as the existing global adapter."
  - "Single-tenant installs stay zero-config because the outbound tenancy callback falls back to `:default`."
requirements-completed: [TENANT-01, TENANT-03]
duration: 8min
completed: 2026-05-01
---

# Phase 26 Plan 01: Contract Foundation Summary

**Outbound adapter-ref contract, validated adapter registry, and durable delivery route identity for queued sends**

## Performance

- **Duration:** 8 min
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added `Mailglass.Tenancy.resolve_outbound_adapter_ref/1` as the new optional outbound-routing seam and kept `Mailglass.Tenancy.SingleTenant` on the default path.
- Extended `Mailglass.Config` with an additive `adapters:` registry plus normalization/accessors for the global adapter and named refs.
- Added `Delivery.adapter_ref`, a reserved default sentinel, and the V04 migration layer so queued route intent has an explicit persisted contract.

## Task Commits

1. **Task 1: Add the tenancy callback and additive adapter-ref registry contract** - `445abfb`
2. **Task 2: Add the dedicated delivery route-ref field and migration version bump** - `2c02d19`

## Verification

- `mix test test/mailglass/tenancy_test.exs test/mailglass/config_test.exs test/mailglass/outbound/delivery_test.exs test/mailglass/migration_test.exs --warnings-as-errors`

## Issues Encountered

- `migration_test.exs` emits module redefinition warnings when Ecto recompiles migration wrappers during the rollback round-trip. The targeted suite still passed with `0` failures and no compile-time warnings.

## Next Phase Readiness

- Outbound runtime code can now resolve named adapter refs through `Mailglass.Config` without adding new raw `Application.get_env/3` lookups.
- Async enqueue/dispatch work in Plan 26-02 can persist and later honor `delivery.adapter_ref` for both named and default routes.
