---
phase: 157-inbound-database-and-lifecycle-hardening
plan: 09
subsystem: database
tags: [postgres, ecto, migrations, generated-host, expand-contract]
requires:
  - phase: 157-inbound-database-and-lifecycle-hardening-05
    provides: inbound V02 additive schema and resumable SHA-256 backfill
  - phase: 157-inbound-database-and-lifecycle-hardening-08
    provides: core V06 additive raw-body and retention schema
provides:
  - generated nontransactional upgrade wrappers with guarded concurrent DDL
  - populated V05/V01 upgrade, backfill, recovery, and rollback certification
  - immutable shipped-migration hashes and an executable forward migration policy
affects: [adopter-migrations, release-certification, generated-host-testing]
tech-stack:
  added: []
  patterns: [transactional fresh install, nontransactional populated upgrade, invalid-index recovery, generated-host anti-vacuity]
key-files:
  created: [docs/migration-policy.md, .planning/phases/157-inbound-database-and-lifecycle-hardening/157-09-SUMMARY.md]
  modified: [scripts/generated_ecto_host_proof.sh, lib/mailglass/migration_generator.ex, lib/mailglass/migrations/postgres/v06.ex, lib/mailglass/migration.ex, mailglass_inbound/lib/mailglass_inbound/migration.ex]
key-decisions:
  - "Initial wrappers remain transactional; only populated-host upgrade wrappers disable the Ecto transaction and migration lock."
  - "Both public migration facades reject a nontransactional upgrade flag when the configured repo reports an active transaction."
  - "Fixed package-owned index names are dropped and rebuilt concurrently to recover interrupted CREATE INDEX CONCURRENTLY attempts."
patterns-established:
  - "Generated upgrade wrapper: require both Ecto disable attributes plus an explicit non_transactional_wrapper flag."
  - "Populated migration proof: exercise the public generators and real package code in both package orders, with anti-vacuity assertions."
requirements-completed: [DATA-08]
coverage:
  - id: D1
    description: A populated generated Phoenix/Ecto/Postgres host upgrades core V05 and inbound V01 through generated wrappers, resumes its backfill, recovers invalid indexes, and rolls back only additive versions.
    requirement: DATA-08
    verification:
      - kind: e2e
        ref: DATABASE_URL=postgres://postgres:postgres@localhost/mailglass_generated_ecto_host_local MAILGLASS_PATH=$PWD bash scripts/generated_ecto_host_proof.sh
        status: pass
      - kind: integration
        ref: test/scripts/generated_ecto_host_proof_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Core V01-V05 and inbound V01 bytes are frozen while the documented forward policy preserves package independence and excludes admin/operator scope.
    requirement: DATA-08
    verification:
      - kind: unit
        ref: test/mailglass/shipped_migration_divergence_test.exs
        status: pass
      - kind: unit
        ref: test/mailglass/docs_migration_smoke_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Both public migration facades fail closed when concurrent migration policy is requested from inside a transaction.
    requirement: DATA-08
    verification:
      - kind: unit
        ref: test/mailglass/migration_facade_test.exs
        status: pass
      - kind: unit
        ref: mailglass_inbound/test/mailglass_inbound/migration_facade_test.exs
        status: pass
    human_judgment: false
duration: 1h
completed: 2026-08-17
status: complete
---

# Phase 157 Plan 09: Generated-Host Migration Certification Summary

**Public generators now produce guarded nontransactional upgrade wrappers, and a real populated generated host certifies both packages' forward migrations, resumable data work, index recovery, and additive rollback.**

## Performance

- **Duration:** 1h
- **Started:** 2026-08-17T05:13:15-04:00
- **Completed:** 2026-08-17T06:13:20-04:00
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Kept fresh-install wrappers transactional while emitting the exact transaction, migration-lock, and explicit nontransactional policy required for core V06 and inbound V02 populated upgrades.
- Expanded the real generated-host proof to cover both package orders, populated legacy data, exact signed bytes, mixed-row dedupe, interrupted/resumed cursor backfill, valid usable indexes, invalid-index recovery, idempotent reruns, and rollback to V05/V01.
- Froze byte hashes for core V01-V05 and inbound V01 and documented the additive expand/backfill/index/contract policy without involving admin or operator storage/UI.
- Made both public migration facades fail closed when a caller requests concurrent DDL while the repo is already inside a transaction.

## Task Commits

1. **Task 1: Upgrade a populated generated host through inbound V02 and core V06** — `5ba67506`, `9bad8fe9`, `0c010337`, `58b91ece`, `36aacb45`
2. **Task 2: Freeze shipped migrations and codify the forward policy** — `ad67f47f`

## Files Created/Modified

- `scripts/generated_ecto_host_proof.sh` - Creates and exercises a disposable generated Phoenix/Ecto host against populated prior-version schemas.
- `test/scripts/generated_ecto_host_proof_test.exs` - Prevents the real generator, migration, data, index, recovery, and rollback journey from becoming vacuous.
- `lib/mailglass/migration_generator.ex` - Emits safe upgrade-wrapper attributes and the explicit nontransactional facade flag.
- `lib/mailglass/migrations/postgres.ex` - Selects concurrent V06 index execution only for explicitly nontransactional upgrades.
- `lib/mailglass/migrations/postgres/v06.ex` - Supports transactional fresh installs and recoverable concurrent populated upgrades.
- `lib/mailglass/migration.ex` - Rejects nontransactional policy when the adopter repo reports an active transaction.
- `mailglass_inbound/lib/mailglass_inbound/migration.ex` - Applies the same fail-closed transaction guard to inbound migrations.
- `test/mailglass/migration_facade_test.exs` - Covers the core transaction misuse guard.
- `mailglass_inbound/test/mailglass_inbound/migration_facade_test.exs` - Covers the inbound transaction misuse guard.
- `test/mailglass/shipped_migration_divergence_test.exs` - Pins pre-phase shipped migration bytes and catalogs forward versions separately.
- `docs/migration-policy.md` - Defines adopter sequencing, timeout, recovery, rerun, rollback, and package-boundary policy.
- `test/mailglass/docs_migration_smoke_test.exs` - Keeps the migration policy and its safety clauses discoverable.
- `test/mix/tasks/mailglass_gen_migration_test.exs` and `mailglass_inbound/test/mix/tasks/mailglass_inbound_gen_migration_test.exs` - Verify generated initial and upgrade wrapper contracts.

## Decisions Made

- Initial installation does not need concurrent index machinery, so its generated wrapper retains Ecto's normal transaction behavior. Only upgrades from a populated prior version opt into the nontransactional path.
- The explicit wrapper flag is a safety contract, not merely metadata: both facades resolve the repo and refuse to execute it from an active transaction.
- Interrupted `CREATE INDEX CONCURRENTLY` operations can leave invalid artifacts. The upgrade owns fixed package-specific names, removes invalid remnants concurrently, and recreates them so the same generated wrapper is safely resumable.

## Deviations from Plan

### Auto-fixed Issues

**1. Added runtime transaction misuse guards to both package facades**

- **Found during:** Task 1 review
- **Issue:** Wrapper attributes expressed the intended execution mode but direct facade callers could still request concurrent DDL inside a transaction.
- **Fix:** Resolve the configured repo, query `in_transaction?/0`, and raise before executing up or down when the nontransactional flag is incompatible with the current context.
- **Verification:** Core and inbound facade suites plus both generator suites pass.
- **Committed in:** `36aacb45`

**2. Adapted the proof to the cursor-based backfill result contract**

- **Found during:** Task 1 real-host execution
- **Issue:** The generated-host harness expected an older scalar return shape and could not prove interrupted/resumed progress.
- **Fix:** Persist and reuse the returned cursor/result map across bounded batches, then assert exhaustion.
- **Verification:** Both `core_first` and `inbound_first` generated-host journeys pass.
- **Committed in:** `58b91ece`

---

**Total deviations:** 2 auto-fixed correctness gaps
**Impact on plan:** Both changes strengthen the planned execution proof without adding admin/operator scope or changing historical migrations.

## Verification

- `mix test test/scripts/generated_ecto_host_proof_test.exs test/mailglass/shipped_migration_divergence_test.exs test/mailglass/docs_migration_smoke_test.exs test/mailglass/migration_facade_test.exs test/mix/tasks/mailglass_gen_migration_test.exs --warnings-as-errors` — 25 tests, 0 failures
- `mix test test/mailglass/migration_test.exs --warnings-as-errors` — 21 tests, 0 failures
- `cd mailglass_inbound && mix test test/mailglass_inbound/migrations_test.exs test/mailglass_inbound/migration_facade_test.exs test/mix/tasks/mailglass_inbound_gen_migration_test.exs --warnings-as-errors` — 23 tests, 0 failures
- `DATABASE_URL="postgres://postgres:postgres@localhost/mailglass_generated_ecto_host_local" MAILGLASS_PATH="$PWD" bash scripts/generated_ecto_host_proof.sh` — passed for `core_first` and `inbound_first`
- Root and inbound `mix compile --no-optional-deps --warnings-as-errors` — passed
- Root `mix format --check-formatted`, scoped inbound formatting, `bash -n scripts/generated_ecto_host_proof.sh`, and `git diff --check` — passed

## Issues Encountered

The generated-host harness initially captured compile output with the migration path and used shell-sensitive SQL quoting; `--no-compile` path discovery and dollar-quoted SQL literals resolved those harness-only failures. The repository-wide inbound formatter still reports pre-existing/unowned Phase 157 files from other plans; every Plan 157-09 inbound file passes a scoped format check.

## User Setup Required

None. The proof uses the existing allowlisted disposable PostgreSQL test URL contract.

## Next Phase Readiness

DATA-08 is complete and adopter-facing migrations are certified for populated SaaS integration. The remaining phase-wide cleanup is to format the unrelated inbound files owned by other Plan 157 work before declaring the entire repository green.

## Self-Check: PASSED

All task commits, public wrapper contracts, immutable migration hashes, migration policy, and real generated-host evidence are present.

---
*Phase: 157-inbound-database-and-lifecycle-hardening*
*Completed: 2026-08-17*
