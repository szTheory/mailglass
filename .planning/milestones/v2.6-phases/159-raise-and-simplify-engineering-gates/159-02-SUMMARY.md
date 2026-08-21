---
phase: 159-raise-and-simplify-engineering-gates
plan: 02
subsystem: ci-formatting
tags: [format, ci, cache, locked-dependencies]
requires: []
provides:
  - root-owned core and inbound formatter scope
  - package-scoped locked Beam/Mix setup action
affects: [159-04, 159-05, 159-06, 159-07]
requirements-completed: [QUAL-01, QUAL-05, QUAL-10]
completed: 2026-08-17
---

# Phase 159 Plan 02: Formatter and Locked Setup Summary

## Accomplishments

- Root formatter scope explicitly includes inbound `config`, `lib`, and `test`
  trees; inbound was normalized mechanically without product/UI changes.
- Formatter scope contract has a mutation control for a removed inbound input.
- Added `setup-beam-mix` composite action with explicit package directory,
  lockfile, Mix environment, build path, cache namespace, strict toolchain,
  package-local cache identity, and `mix deps.get --check-locked`.
- `Format Check` retains its display identity and now uses the setup action.
- Setup action contract rejects wildcard lock hashing and proves the format job
  supplies root package identity.

## Commits

- `b2a519f1` — `style(159-02): establish root inbound format scope`
- `cf42a93d` — `ci(159-02): add locked package setup action`

## Verification

- `mix test test/scripts/format_scope_contract_test.exs test/scripts/setup_action_contract_test.exs --warnings-as-errors`
- `mix format --check-formatted`
- `cd mailglass_inbound && mix format --check-formatted`
- `actionlint .github/workflows/ci.yml`
- `git diff --check`

## Scope

No admin/operator UI behavior, release policy, publication, or roadmap/state
files were changed.
