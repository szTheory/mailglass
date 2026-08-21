---
phase: 155-restore-adopter-and-ci-truth
plan: 03
subsystem: database
tags: [ecto, migrations, postgres, mix-tasks, upgrade-safety]
requires:
  - phase: 155-01
    provides: configured-repo migration wrapper generation and offline upgrade validation
  - phase: 155-02
    provides: typed, fail-closed migration metadata readers
provides:
  - live upgrade inspection against the selected host repository
  - explicit-repo-first core and inbound migration facades
  - no-write failure coverage for invalid live metadata
affects: [generated-host-adoption, migration-upgrades]
tech-stack:
  added: []
  patterns: [Ecto.Migrator.with_repo selected-repo inspection, explicit repo facade dispatch]
key-files:
  created: []
  modified:
    - lib/mailglass/migration_generator.ex
    - lib/mailglass/migration.ex
    - mailglass_inbound/lib/mailglass_inbound/migration.ex
    - test/mix/tasks/mailglass_gen_migration_test.exs
    - mailglass_inbound/test/mix/tasks/mailglass_inbound_gen_migration_test.exs
key-decisions:
  - "Live --upgrade starts and queries only the selected configured repo; package-global repo config is fallback-only."
  - "Live and offline invalid upgrade states remain distinct, actionable no-write failures."
patterns-established:
  - "Migration facades resolve an explicit :repo before application configuration for adapter selection and catalog reads."
requirements-completed: [ADOPT-03, ADOPT-04, ADOPT-06]
coverage:
  - id: D1
    description: "Core live upgrades derive rollback version from the selected repo and reject unsafe live outcomes without writing files."
    requirement: ADOPT-03
    verification:
      - kind: unit
        ref: "test/mix/tasks/mailglass_gen_migration_test.exs#selected repo live upgrade and failure matrix"
        status: pass
    human_judgment: false
  - id: D2
    description: "Inbound live inspection uses its independent anchor and the selected repo, while its current initial version refuses an upgrade."
    requirement: ADOPT-04
    verification:
      - kind: unit
        ref: "mailglass_inbound/test/mix/tasks/mailglass_inbound_gen_migration_test.exs#selected repo live inspection"
        status: pass
    human_judgment: false
  - id: D3
    description: "Startup, catalog, malformed, impossible, and timestamp-collision conditions preserve migration history."
    requirement: ADOPT-06
    verification:
      - kind: unit
        ref: "mix test focused core and inbound generator suites --warnings-as-errors"
        status: pass
    human_judgment: false
metrics:
  duration: 4min
  completed: 2026-08-17
status: complete
---

# Phase 155 Plan 03: Live Upgrade Resolution Summary

**Core and inbound live upgrades now inspect only the selected Ecto repository, validate the actual applied version, and leave migration history unchanged for every unsafe outcome.**

## Accomplishments

- Connected `--upgrade` without `--from` to `Ecto.Migrator.with_repo/3` and the selected repo's typed catalog reader.
- Made both public migration facades choose adapters and query repositories from explicit `:repo` options before application defaults.
- Added conflicting-config and no-write acceptance coverage for core and inbound live upgrade paths.

## Verification

- `mix test test/mix/tasks/mailglass_gen_migration_test.exs --warnings-as-errors` — 8 tests, 0 failures.
- `cd mailglass_inbound && mix test test/mix/tasks/mailglass_inbound_gen_migration_test.exs --warnings-as-errors` — 4 tests, 0 failures.
- `mix format --check-formatted` and `git diff --check` — passed.

## Task Commits

1. **Task 1: Drive a live core upgrade from the selected repo's applied version**
   - `a1888deb` `test(155-03): add failing live core upgrade test`
   - `fabb99e7` `feat(155-03): generate live core upgrades from selected repo`
2. **Task 2: Give inbound the identical live-upgrade contract**
   - `8ce10d5d` `feat(155-03): align inbound live upgrade resolution`

## Files Modified

- `lib/mailglass/migration_generator.ex` — resolves and validates live prior versions through the selected repo.
- `lib/mailglass/migration.ex` — honors explicit repositories for core adapter dispatch and catalog queries.
- `mailglass_inbound/lib/mailglass_inbound/migration.ex` — provides the same explicit-repo authority for inbound.
- `test/mix/tasks/mailglass_gen_migration_test.exs` — covers conflicting repo configuration plus live failure no-write behavior.
- `mailglass_inbound/test/mix/tasks/mailglass_inbound_gen_migration_test.exs` — covers inbound selected-repo and current-version refusal behavior.

## Decisions Made

- Selected `--repo` is authoritative for startup, adapter selection, and catalog reads; configured package repos remain compatible fallbacks when no explicit repo is provided.
- Live failures retain distinct messages from offline `--from` validation and never produce a migration file.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Formatting] Formatted the live resolver after the formatter identified multiline layout violations.**
- **Found during:** Task 1
- **Fix:** Applied the repository formatter before verification.
- **Verification:** `mix format --check-formatted`

**Total deviations:** 1 auto-fixed.

## Known Stubs

None.

## Next Phase Readiness

Live core and inbound migration generation is ready for generated-host proof work. The intentionally empty inbound upgrade range remains honest until a future inbound schema version exists.

## Self-Check: PASSED

- All modified source and test files exist.
- Task commits `a1888deb`, `fabb99e7`, and `8ce10d5d` exist in git history.
