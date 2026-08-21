---
phase: 155-restore-adopter-and-ci-truth
plan: 01
subsystem: database
tags: [ecto, mix-task, migrations, safety, inbound]
requires: []
provides:
  - Shared configured-repo migration generator for core and inbound packages
  - Immutable initial migration wrappers and additive offline upgrades
affects: [155-02, 155-03, 155-04, generated-host-certification]
tech-stack:
  added: []
  patterns: [configured-repo selection, exclusive migration writes, injectable generator clock]
key-files:
  created: [lib/mailglass/migration_generator.ex]
  modified:
    - lib/mix/tasks/mailglass.gen.migration.ex
    - mailglass_inbound/lib/mix/tasks/mailglass.inbound.gen.migration.ex
    - test/mix/tasks/mailglass_gen_migration_test.exs
    - mailglass_inbound/test/mix/tasks/mailglass_inbound_gen_migration_test.exs
key-decisions:
  - "CLI repo text is matched only to existing configured repo module strings; arbitrary input never creates an atom."
  - "Version zero is an absent anchor, not an upgrade source; callers receive initial-generation guidance."
  - "Inbound version one has no offline predecessor and therefore truthfully refuses every offline upgrade."
patterns-established:
  - "Migration wrappers delegate exclusively to public package facades and never embed package DDL."
  - "Initial wrappers remain byte-stable; upgrades are separate exclusive timestamped files."
requirements-completed: [ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-04]
coverage:
  - id: D1
    description: "Core and inbound Mix tasks generate real public-facade wrappers for a uniquely configured or explicitly selected repo."
    requirement: ADOPT-01
    verification:
      - kind: unit
        ref: "mix test test/mix/tasks/mailglass_gen_migration_test.exs --warnings-as-errors; cd mailglass_inbound && mix test test/mix/tasks/mailglass_inbound_gen_migration_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Offline core upgrades are fresh reversible wrappers and invalid inputs, absent anchors, and collisions leave history untouched."
    requirement: ADOPT-03
    verification:
      - kind: unit
        ref: "test/mix/tasks/mailglass_gen_migration_test.exs#adds a rollback-aware offline upgrade without modifying the install wrapper"
        status: pass
    human_judgment: false
status: complete
---

# Phase 155 Plan 01: Migration Generation Tracer Summary

**Configured Ecto repos now receive immutable core/inbound facade wrappers and collision-safe offline core upgrades with validated rollback versions.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-08-17T01:39:00Z
- **Completed:** 2026-08-17T01:44:00Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added the core-owned `Mailglass.MigrationGenerator`, used by both public Mix tasks without reversing the inbound dependency direction.
- Selected repos strictly from the host app's configured `:ecto_repos`, including explicit selection by an already-configured module string and ambiguity/no-write failures.
- Replaced core's toy DDL generator with stable public `up/0` and `down/0` wrapper source; inbound uses the identical contract.
- Added additive offline core upgrades, exact rollback literals, exclusive write collision detection, and clear invalid-version guidance.

## Task Commits

1. **Task 1: Generate fresh core and inbound wrappers for one real configured repo** - `2884994c` (`feat`)
2. **Task 2: Add collision-safe offline upgrade generation and the zero-version refusal** - `36d2c2b4` (`feat`)

## Files Created/Modified

- `lib/mailglass/migration_generator.ex` - Shared parsing, repo resolution, rendering, immutable initial write, and additive upgrade logic.
- `lib/mix/tasks/mailglass.gen.migration.ex` - Core package specification for the shared generator.
- `mailglass_inbound/lib/mix/tasks/mailglass.inbound.gen.migration.ex` - Inbound package specification using the core-owned helper.
- `test/mix/tasks/mailglass_gen_migration_test.exs` - Core CLI acceptance and deterministic collision coverage.
- `mailglass_inbound/test/mix/tasks/mailglass_inbound_gen_migration_test.exs` - Inbound parity acceptance coverage.

## Decisions Made

- Migration directories use `Ecto.Migrator.migrations_path/1`, so the selected repo determines the Ecto-standard host path and migration namespace.
- `--repair-legacy` is recognized but deliberately refuses until Plan 155-04; it never guesses at a legacy shape.
- The clock injection is internal to the shared generator, keeping public task syntax stable while testing timestamp-collision behavior deterministically.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the injectable clock default path**
- **Found during:** Task 2
- **Issue:** `Keyword.get_lazy/3` had already evaluated the default timestamp, so invoking it as a function failed on normal task execution.
- **Fix:** Used `Keyword.fetch/2` to call only an explicitly injected zero-arity clock and otherwise obtain `DateTime.utc_now/0`.
- **Files modified:** `lib/mailglass/migration_generator.ex`
- **Verification:** Focused core and inbound Mix-task suites pass with warnings treated as errors.
- **Committed in:** `36d2c2b4`

**Total deviations:** 1 auto-fixed (Rule 1)

## Known Stubs

None. The explicit `--repair-legacy` refusal is the planned safe boundary for Plan 155-04, not a placeholder path.

## Self-Check: PASSED

- Created generator and both acceptance test files exist.
- Task commits `2884994c` and `36d2c2b4` exist in git history.
- Final verification passed: core focused suite (6 tests), inbound focused suite (3 tests), and root format check.

## Next Phase Readiness

Plans 155-02 through 155-04 can extend the shared seam with live-version truth, selected-repo authority, and exact legacy repair without changing generated history.
