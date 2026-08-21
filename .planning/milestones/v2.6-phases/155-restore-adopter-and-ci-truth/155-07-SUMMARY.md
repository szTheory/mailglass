---
phase: 155-restore-adopter-and-ci-truth
plan: 07
subsystem: database
tags: [postgres, ecto, migrations, schema-isolation, generated-host]
requires:
  - phase: 155-05
    provides: Generated Phoenix/Ecto Host.Repo proof and public migration wrappers
  - phase: 155-06
    provides: Stable protected CI truth for the generated-host proof lane
provides:
  - Symmetric RESTRICT-only rollback behavior for core and inbound shared schemas
  - Isolated regression coverage for core-first, inbound-first, and host-owned schema objects
  - Two fresh generated Host.Repo migration and rollback journeys
affects: [ADOPT-01, generated-host-proof, postgres-schema-lifecycle]
tech-stack:
  added: []
  patterns: [postgres-do-exception-guard, shared-schema-restrict-teardown, parameterized-generated-host-journeys]
key-files:
  created: []
  modified:
    - lib/mailglass/migrations/postgres.ex
    - mailglass_inbound/lib/mailglass_inbound/migrations/postgres.ex
    - mailglass_inbound/test/mailglass_inbound/migrations_test.exs
    - scripts/generated_ecto_host_proof.sh
    - test/scripts/generated_ecto_host_proof_test.exs
key-decisions:
  - "Schema deletion remains DROP SCHEMA IF EXISTS ... RESTRICT; only PostgreSQL's dependent_objects_still_exist exception is converted to a no-op."
  - "The generated proof uses separate derived databases and hosts for inbound-first and core-first rollbacks."
patterns-established:
  - "Shared package schemas rely on RESTRICT as the ownership boundary, never relation enumeration or CASCADE."
requirements-completed: [ADOPT-01]
coverage:
  - id: D1
    description: Core and inbound rollbacks preserve sibling and host-owned objects until a package-managed schema is empty.
    requirement: ADOPT-01
    verification:
      - kind: integration
        ref: "mailglass_inbound/test/mailglass_inbound/migrations_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Fresh generated Phoenix/Ecto hosts execute both opposing public-wrapper rollback orders through Host.Repo.
    requirement: ADOPT-01
    verification:
      - kind: integration
        ref: "MAILGLASS_PATH=$PWD bash scripts/generated_ecto_host_proof.sh"
        status: pass
      - kind: unit
        ref: "test/scripts/generated_ecto_host_proof_test.exs"
        status: pass
    human_judgment: false
duration: 33min
completed: 2026-08-17
status: complete
---

# Phase 155 Plan 07: Shared-Schema Rollback Summary

**Core and inbound now roll back safely from one non-public schema: each removes only its own relations, RESTRICT preserves sibling and host objects, and a final empty schema is removed.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-08-17T02:32:00Z
- **Completed:** 2026-08-17T03:05:10Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Replaced unconditional shared-schema teardown failure with a PostgreSQL-local `dependent_objects_still_exist` exception guard around the existing `DROP SCHEMA ... RESTRICT` operation in both package runners.
- Added real Ecto migration-runner coverage for core-first, inbound-first, and host-sentinel rollback behavior, asserting every package relation set and final schema state.
- Parameterized the generated Phoenix/Ecto proof into two fresh hosts and derived scratch databases, including core and inbound persistence/reload plus intermediate and final rollback assertions.

## Task Commits

1. **Task 1: Roll core and inbound down independently without claiming shared schema ownership** — `ad462f72`
2. **Task 2: Make both authoritative generated Host.Repo rollback orders pass** — `d069199b`, `20e37159`

## Files Created/Modified

- `lib/mailglass/migrations/postgres.ex` — guards only PostgreSQL's RESTRICT dependent-object refusal.
- `mailglass_inbound/lib/mailglass_inbound/migrations/postgres.ex` — applies the identical inbound lifecycle policy.
- `mailglass_inbound/test/mailglass_inbound/migrations_test.exs` — exercises both package orders and a host-owned sentinel.
- `scripts/generated_ecto_host_proof.sh` — executes separate core-first and inbound-first generated-host journeys.
- `test/scripts/generated_ecto_host_proof_test.exs` — mutation-backed contract checks for both proof journeys.

## Decisions Made

- Schema ownership is decided only by PostgreSQL `RESTRICT`; package code neither enumerates unknown objects nor deletes sibling or host-owned relations.
- `to_regnamespace` is cast to text in the generated host because Postgrex does not decode the native `regnamespace` type.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Kept the expected RESTRICT refusal inside PostgreSQL's transaction-safe exception block.**
- **Found during:** Task 1
- **Issue:** Rescuing `%Postgrex.Error{}` after `query!` left Ecto's encompassing migration transaction aborted.
- **Fix:** Used a `DO` block that catches only `dependent_objects_still_exist` (SQLSTATE 2BP01); all other errors continue to abort.
- **Files modified:** Core and inbound Postgres runners.
- **Verification:** Isolated three-case shared-schema integration suite.
- **Committed in:** `ad462f72`

**2. [Rule 1 - Bug] Made generated-host namespace assertions driver-compatible.**
- **Found during:** Task 2
- **Issue:** Postgrex cannot decode native `regnamespace` values.
- **Fix:** Cast `to_regnamespace($1)` to text while retaining non-null and null assertions.
- **Files modified:** `scripts/generated_ecto_host_proof.sh`
- **Verification:** Fresh generated core-first and inbound-first proof run.
- **Committed in:** `d069199b`

**3. [Rule 1 - Bug] Restored the proof script executable mode.**
- **Found during:** Task 2
- **Issue:** Recreating the script changed its tracked mode from executable to non-executable.
- **Fix:** Restored mode `100755`.
- **Files modified:** `scripts/generated_ecto_host_proof.sh`
- **Verification:** Fresh shell syntax and generated-host proof run.
- **Committed in:** `20e37159`

**Total deviations:** 3 auto-fixed Rule 1 issues. All were required for the rollback proof to execute correctly; no scope expanded beyond the plan.

## Verification

- `cd mailglass_inbound && mix test test/mailglass_inbound/migrations_test.exs --warnings-as-errors` — 17 tests, 0 failures.
- `mix test test/scripts/generated_ecto_host_proof_test.exs --warnings-as-errors` — 5 tests, 0 failures.
- `mix format --check-formatted`, `bash -n scripts/generated_ecto_host_proof.sh`, `actionlint .github/workflows/ci.yml`, and `git diff --check` — passed.
- `MAILGLASS_PATH="$PWD" DATABASE_URL=ecto://postgres:postgres@localhost/mailglass_generated_ecto_host_gap155 bash scripts/generated_ecto_host_proof.sh` — passed two fresh journeys: `inbound_first` and `core_first`.

## Known Stubs

None.

## Issues Encountered

`state.advance-plan` could not parse the pre-existing `Plan: —` marker in `STATE.md`; progress, metrics, decisions, session, and roadmap counts were updated through their independent handlers.

## Next Phase Readiness

ADOPT-01's shared-schema rollback path is now proven through isolated real migrations and generated Host.Repo journeys. No admin UI changes were made.

## Self-Check: PASSED

- Confirmed all five implementation artifacts and task commits `ad462f72`, `d069199b`, and `20e37159` exist.
