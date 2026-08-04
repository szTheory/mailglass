---
phase: 153
plan: 01
subsystem: generated-host-proof
tags: [phoenix, ecto, postgres, hex, migration, proof]
requires: []
provides: [package-shaped generated-host migration tracer, bounded proof checkpoint]
affects: [153-02, release-gate]
tech-stack:
  added: [Phoenix host generator, Hex package unpacking, JSON checkpoint validator]
  patterns: [public migration facade, schema-qualified catalog proof, allowlisted hashed evidence]
key-files:
  created:
    - scripts/generated_host_proof.sh
    - scripts/check_generated_host_proof.sh
    - dev/mailglass/generated_host/journey.ex
    - dev/mailglass/generated_host/host_template.ex
    - dev/mailglass/generated_host/checkpoint.ex
  modified:
    - lib/mix/tasks/mailglass.gen.migration.ex
    - test/mailglass/shipped_migration_divergence_test.exs
    - test/generated_host/journey_contract_test.exs
decisions:
  - Generated migration wrappers call only Mailglass.Migration.up/0 and down/0.
  - Local adoption proof builds and unpacks each package before dependency injection.
metrics:
  tasks_completed: 2
status: complete
---

# Phase 153 Plan 01: Generated Host Migration Tracer Summary

Stock Phoenix/Ecto hosts now install unpacked package artifacts, migrate the complete Mailglass schema into a unique non-public schema, and validate a bounded proof manifest before success.

## Tasks Completed

1. Public migration wrapper and package-shaped generated-host tracer.
2. Deterministic checkpoint schema and fail-closed privacy validator.

## Verification

- `mix test test/mailglass/shipped_migration_divergence_test.exs test/generated_host/journey_contract_test.exs --warnings-as-errors` — passed.
- The local package-artifact host was generated, resolved extracted artifacts, created the wrapper, migrated schema version 7, and proved the five current Mailglass tables are absent from `public`.
- `mix test test/generated_host/journey_contract_test.exs --warnings-as-errors` — passed after checkpoint implementation.

## Commits

- `78550d09` — RED migration-tracer contract.
- `a9ede0a7` — package-shaped generated-host migration tracer.
- `f11aa013` — RED checkpoint contract.
- `5c803fae` — bounded proof manifest enforcement.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected generated-host dependency insertion and Repo lifecycle.
- The runner initially emitted literal newline escapes and queried before the host Repo started.
- It now inserts valid dependency entries, uses no-start setup, and explicitly starts the configured Repo for catalog proof.

2. [Rule 1 - Bug] Corrected the table inventory to the actual V01–V07 schema.
- The current chain creates five tables; V03–V05/V07 alter existing tables.

## Self-Check: PASSED
