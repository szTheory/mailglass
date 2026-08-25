---
phase: 155-restore-adopter-and-ci-truth
plan: 04
subsystem: database
tags: [ecto, postgres, migrations, fail-closed, legacy-repair]
requires:
  - phase: 155-02
    provides: typed fail-closed migration metadata
  - phase: 155-03
    provides: selected-repository migration generation
provides:
  - byte-exact legacy toy migration recognition
  - reversible additive core repair migration
  - destructive-operation refusal matrix
affects: [generated-host-adoption, migration-upgrades]
tech-stack:
  added: []
  patterns: [independent source-and-catalog preflight, fully-qualified restrictive repair DDL]
key-files:
  created: [lib/mailglass/migrations/legacy_toy.ex, test/mix/tasks/mailglass_legacy_repair_test.exs]
  modified:
    - lib/mailglass/migration.ex
    - lib/mailglass/migration_generator.ex
    - mailglass_inbound/lib/mix/tasks/mailglass.inbound.gen.migration.ex
key-decisions:
  - "Only the byte-exact historical core toy source is repairable; AST-equivalent or hand-edited sources are ambiguous."
  - "Repair always preserves the legacy file and generates a new timestamped reversible wrapper."
  - "Inbound has no approved legacy signature and rejects --repair-legacy before generator delegation."
patterns-established:
  - "Destructive migration repair requires independent source, catalog, and zero-row proofs before wrapper creation."
requirements-completed: [ADOPT-05, ADOPT-06]
coverage:
  - id: D1
    description: "An exact empty core toy migration upgrades to the current package schema and rolls back to the empty toy table."
    requirement: ADOPT-05
    verification:
      - kind: integration
        ref: "test/mix/tasks/mailglass_legacy_repair_test.exs#repairs one exact empty historical toy and rolls it back"
        status: pass
    human_judgment: false
  - id: D2
    description: "Altered, multiple, missing, catalog-mutated, populated, and inbound repair attempts preserve files and data."
    requirement: ADOPT-06
    verification:
      - kind: integration
        ref: "mix test test/mix/tasks/mailglass_legacy_repair_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
metrics:
  duration: 31min
  completed: 2026-08-16
status: complete
---

# Phase 155 Plan 04: Exact Legacy Toy Repair Summary

**Core now repairs only the byte-exact empty pre-155 toy migration through a new reversible wrapper, while every ambiguous, populated, unavailable, or inbound case fails closed.**

## Accomplishments

- Added `Mailglass.Migrations.LegacyToy` to compare the historical source bytes, inspect the complete Postgres table signature, and require zero rows before any repair file is written.
- Generated repair wrappers preserve the legacy migration and use fully qualified `RESTRICT` operations to replace only the proven toy table with the current package schema; rollback reconstructs the toy table.
- Added isolated real-Postgres proof for the success path plus altered source, duplicate/missing source, catalog mutation, sentinel-row, and inbound rejection controls.

## Verification

- `mix test test/mix/tasks/mailglass_gen_migration_test.exs --warnings-as-errors` — 8 tests passed.
- `mix test test/mix/tasks/mailglass_legacy_repair_test.exs --warnings-as-errors` — 5 tests passed.
- `mix format --check-formatted` and `git diff --check` — passed before the final task commit.

## Task Commits

1. Task 1: exact empty toy repair and rollback — `0a52ed40`
2. Task 1 corrective fixture isolation — `1d0b1289`
3. Task 2: unsafe-state refusal matrix and inbound rejection — `a5afa44b`

## Decisions Made

- The literal output from the pre-155 generator is the sole recognized source signature, including module name, whitespace, and trailing newline.
- Repair keeps the original migration untouched and writes only a separate timestamped wrapper after all preflight checks pass.
- Inbound cannot infer or reuse the core signature; it always refuses `--repair-legacy`.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Test isolation] Corrected the repair test fixture’s migration path.
   - Found during: Task 1 verification.
   - Issue: the fixture initially resolved to the package’s tracked migration path.
   - Fix: added a test-only injectable migration-path seam and moved all fixture writes to `tmp/mailglass_legacy_repair_test/migrations`.
   - Files modified: `lib/mailglass/migration_generator.ex`, `test/mix/tasks/mailglass_legacy_repair_test.exs`.
   - Verification: focused legacy-repair and existing migration-generator suites pass without tracked migration changes.
   - Commit: `1d0b1289`.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed `lib/mailglass/migrations/legacy_toy.ex` and `test/mix/tasks/mailglass_legacy_repair_test.exs` exist.
- Confirmed task commits `0a52ed40`, `1d0b1289`, and `a5afa44b` exist in git history.

