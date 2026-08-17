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
  - immutable exact signed-body and retention-index schema expansion
  - bulk webhook delivery-state lookup and parse-once request flow
affects: [157-09-generated-host-migration-proof]
tech-stack:
  added: []
patterns: [session advisory lock, SKIP LOCKED batch deletion, batch delivery map, explicit verified request]
key-files:
  created: [lib/mailglass/migrations/postgres/v06.ex]
  modified: [lib/mailglass/webhook/pruner.ex, lib/mailglass/webhook/ingest.ex]
key-decisions:
  - "Core retention pins its advisory lock to one checked-out repo session."
  - "Webhook batches deduplicate provider message ids before one scoped delivery query."
  - "Raw signed bytes and one decoded outer JSON result travel together without process state."
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
- Persisted immutable byte-exact signed webhook bodies and replaced per-event delivery reads with one deduplicated provider-batch lookup.
- Added an explicit verified-request value so verification, tenant extraction, normalization, and persistence reuse one decoded outer JSON result while SES alone decodes its nested message.
- Advanced the stable Postgres migration dispatcher to V06.

## Task Commits

1. Task 1 — `38eff2f4` `feat(157-08): batch and serialize webhook retention`
2. Task 2 — `2501b5d8` `feat(157-08): retain signed bytes and bulk-load deliveries`
3. Task 3 — `bb6a0928` `feat(157-08): expose V06 through migration dispatcher`
4. Review fixes — `21e2c279`, `3876b73c`, `1c7bf3e5`, `1b2edcd2` (lockout semantics, projection reuse, prune contract, signed-body immutability)
5. Parse-once integration — `25971507`, `01fbb2f9` (explicit decoded request plus adopter-compatible tenancy context)

## Verification

- `mix test test/mailglass/webhook/pruner_test.exs --warnings-as-errors` — passed
- `mix test test/mailglass/webhook/plug_test.exs test/mailglass/webhook/ingest_test.exs test/mailglass/webhook/providers --warnings-as-errors` — 161 passed
- `cd mailglass_inbound && mix test test/mailglass_inbound/internal/prune_test.exs --warnings-as-errors` — passed
- `mix format --check-formatted ...` and `git diff --check` — passed

## Deviations from Plan

### Deferred to Plan 157-09

Generated upgrade wrappers and populated-table `CREATE INDEX CONCURRENTLY` execution remain owned by Plan 157-09. V06 exposes both transactional fresh-install and nontransactional populated-upgrade paths for that proof.

## Issues Encountered

The earlier rollback failure was traced to an empty orphan table in the disposable local `mailglass_test` database, not repository migration code. After removing that exact test-only residue, `mix test test/mailglass/migration_test.exs --warnings-as-errors` passed 21 tests.

## Self-Check: PASSED

All three task commits and V06 source file exist.
