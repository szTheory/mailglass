---
phase: 157-inbound-database-and-lifecycle-hardening
plan: 08
subsystem: database
tags: [postgres, ecto, webhook, retention]
requires:
  - phase: 156-delivery-correctness-and-bounded-execution
    provides: bounded lifecycle patterns
provides:
  - bounded serialized core webhook pruning
  - V06 signed-body and retention-index schema expansion
  - bulk webhook delivery-state lookup
affects: [157-09-generated-host-migration-proof]
tech-stack:
  added: []
  patterns: [session advisory lock, SKIP LOCKED batch deletion, batch delivery map]
key-files:
  created: [lib/mailglass/migrations/postgres/v06.ex]
  modified: [lib/mailglass/webhook/pruner.ex, lib/mailglass/webhook/ingest.ex]
key-decisions:
  - "Core retention pins its advisory lock to one checked-out repo session."
  - "Webhook batches deduplicate provider message ids before one scoped delivery query."
requirements-completed: [DATA-06, DATA-07]
coverage:
  - id: D1
    description: Bounded core webhook retention is serialized and uses SKIP LOCKED batches.
    requirement: DATA-06
    verification:
      - kind: integration
        ref: test/mailglass/webhook/pruner_test.exs
        status: pass
      - kind: integration
        ref: mailglass_inbound/test/mailglass_inbound/internal/prune_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Webhook evidence retains exact signed request bytes and resolves delivery state in bulk.
    requirement: DATA-07
    verification:
      - kind: integration
        ref: test/mailglass/webhook/ingest_test.exs
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-17
status: complete
---

# Phase 157 Plan 08: Inbound Database and Lifecycle Hardening Summary

**Core webhook retention now deletes finite locked batches under a session advisory lock, while webhook evidence stores exact signed bytes and batch delivery matching uses one scoped query.**

## Accomplishments

- Added additive V06 support for `raw_signed_body` plus retention candidate indexes.
- Replaced unbounded core deletes with independently committed `FOR UPDATE SKIP LOCKED` batches under a package-specific advisory lock.
- Persisted byte-exact signed webhook bodies and replaced per-event delivery reads with one deduplicated provider-batch lookup.
- Advanced the stable Postgres migration dispatcher to V06.

## Task Commits

1. Task 1 — `38eff2f4` `feat(157-08): batch and serialize webhook retention`
2. Task 2 — `2501b5d8` `feat(157-08): retain signed bytes and bulk-load deliveries`
3. Task 3 — `bb6a0928` `feat(157-08): expose V06 through migration dispatcher`

## Verification

- `mix test test/mailglass/webhook/pruner_test.exs --warnings-as-errors` — passed
- `mix test test/mailglass/webhook/ingest_test.exs --warnings-as-errors` — passed
- `cd mailglass_inbound && mix test test/mailglass_inbound/internal/prune_test.exs --warnings-as-errors` — passed
- `mix format --check-formatted ...` and `git diff --check` — passed

## Deviations from Plan

### Deferred Issue

The requested generated-wrapper `CREATE INDEX CONCURRENTLY` contract has no existing implementation seam in the files assigned to this plan. V06 uses transactional additive indexes with bounded transactional DDL settings; Phase 157-09 owns generated-host wrapper proof and should supply the out-of-transaction wrapper policy.

## Issues Encountered

The full `test/mailglass/migration_test.exs` run has an unrelated shared-schema rollback failure: V01 cannot drop `mailglass_deliveries` because `mailglass_outbound_payloads_delivery_id_fkey` exists. The focused V06 dispatcher assertion passed.

## Self-Check: PASSED

All three task commits and V06 source file exist.
