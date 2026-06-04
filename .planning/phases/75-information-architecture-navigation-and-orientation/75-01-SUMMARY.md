---
phase: 75-information-architecture-navigation-and-orientation
plan: "01"
subsystem: core/operator
tags:
  - suppressions
  - read-model
  - test-stubs
  - wave-0
dependency_graph:
  requires: []
  provides:
    - count_active_suppressions/1 in Mailglass.Operator.Suppressions
    - Wave 0 test stubs for shell_test.exs and operator_live_test.exs
  affects:
    - lib/mailglass/operator/suppressions.ex
    - lib/mailglass/repo.ex
    - test/mailglass/operator/suppressions_test.exs
    - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
tech_stack:
  added: []
  patterns:
    - Ecto.Query aggregate via Repo facade
    - TDD RED/GREEN cycle with ExUnit describe blocks
    - "@tag :skip" Wave 0 structural stubs (CI-safe placeholders)
key_files:
  created:
    - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
  modified:
    - lib/mailglass/operator/suppressions.ex
    - lib/mailglass/repo.ex
    - test/mailglass/operator/suppressions_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
decisions:
  - Repo.aggregate/3 added to Repo facade (Rule 2) — count_active_suppressions/1 required
    aggregate query but Repo facade only exposed what was previously needed; extending
    the thin facade is the correct pattern per repo.ex design (re-export only what
    mailglass itself uses)
  - Wave 0 stubs use @tag :skip (not flunk/1) — test_helper.exs has exclude: [:skip]
    so skipped tests are never counted as failures; structural slot established without
    breaking CI
metrics:
  duration_minutes: 15
  completed_date: "2026-06-04"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
  files_created: 1
---

# Phase 75 Plan 01: Add count_active_suppressions/1 and Wave 0 Test Stubs Summary

**One-liner:** Tenant-scoped active suppression count via `Repo.aggregate(:count, :id)` + Wave 0 `@tag :skip` test structure for Plans 75-02 and 75-03.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add count_active_suppressions/1 to core suppressions.ex (TDD) | 6b0929a3 | suppressions.ex, repo.ex, suppressions_test.exs |
| 2 | Create Wave 0 test stubs for shell_test.exs and operator_live_test.exs | 75522cc0 | operator/shell_test.exs (new), operator_live_test.exs |

## What Was Built

**Task 1 — `count_active_suppressions/1`:**
- Added `@spec count_active_suppressions(String.t()) :: non_neg_integer()` to `Mailglass.Operator.Suppressions`
- Guard: `when is_binary(tenant_id) and tenant_id != ""` — mirrors existing pattern
- Body: `Entry |> where(tenant_id) |> where(active entries: nil or future expires_at) |> Tenancy.scope(tenant_id) |> Repo.aggregate(:count, :id)`
- All required aliases (`Clock`, `Entry`, `Repo`, `Tenancy`) already present — no new imports
- 5 test cases: empty tenant (0), N nil-expires active entries, expired exclusion, cross-tenant isolation, future-expiry inclusion

**Task 2 — Wave 0 stubs:**
- Created `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` with `describe "orientation_strip/1"` (4 stubs) and `describe "aria-current nav resolution"` (1 stub)
- Extended `operator_live_test.exs` with `describe "Operator Overview branch"` (5 stubs): no-tenant nudge, health counts, suppression degradation, em-dash degradation, `?view=deliveries` routing
- All stubs use `@tag :skip` — excluded by `ExUnit.start(exclude: [:skip])` in test_helper.exs; CI stays green

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Added Repo.aggregate/3 to the Repo facade**
- **Found during:** Task 1 GREEN phase
- **Issue:** `Mailglass.Repo` is a thin facade that re-exports only what mailglass uses. `aggregate/3` was not previously needed, so it was not exposed. Calling `Repo.aggregate/3` in the new function raised `UndefinedFunctionError`.
- **Fix:** Added `def aggregate(queryable, aggregate, field), do: repo().aggregate(queryable, aggregate, field)` to `lib/mailglass/repo.ex`. This is the correct pattern (see existing `one/2`, `all/2`, `delete_all/2` delegators).
- **Files modified:** `lib/mailglass/repo.ex`
- **Commit:** 6b0929a3

## Verification Results

All plan verification checks pass:

- `mix test test/mailglass/operator/suppressions_test.exs --seed 0` → 9 tests, 0 failures
- `grep -c "def count_active_suppressions" lib/mailglass/operator/suppressions.ex` → 1
- `grep -c "describe.*count_active_suppressions" test/mailglass/operator/suppressions_test.exs` → 1
- `ls mailglass_admin/test/mailglass_admin/operator/shell_test.exs` → EXISTS
- `grep -c "describe.*Operator Overview branch" mailglass_admin/test/mailglass_admin/operator_live_test.exs` → 1
- Admin test run (both files, seed 0) → 16 tests, 0 failures (10 excluded via @tag :skip)

## Known Stubs

The following are intentional stubs created by this plan — structural placeholders for Plans 75-02 and 75-03:

| File | Stub | Reason |
|------|------|--------|
| `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` | 4 @tag :skip in "orientation_strip/1" | Plan 75-02 implements the component |
| `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` | 1 @tag :skip in "aria-current nav resolution" | Plan 75-03 implements the Overview branch |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | 5 @tag :skip in "Operator Overview branch" | Plan 75-03 implements the Overview branch |

These stubs are the intended output of this plan per `<output>` spec. They do not prevent the plan's goal — the goal IS to establish these structural slots and implement `count_active_suppressions/1`.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. `count_active_suppressions/1` returns an aggregate integer — no PII exposed (CLAUDE.md telemetry rule satisfied). T-75-02 mitigation (tenant guard + Tenancy.scope) applied as specified in the plan's threat register.

## Self-Check: PASSED

- `lib/mailglass/operator/suppressions.ex` — contains `def count_active_suppressions` (verified)
- `lib/mailglass/repo.ex` — contains `def aggregate` (verified)
- `test/mailglass/operator/suppressions_test.exs` — contains `describe "count_active_suppressions/1"` with 5 tests (verified)
- `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` — file exists with 2 describe blocks (verified)
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — contains `describe "Operator Overview branch"` with 5 stubs (verified)
- Commits `6b0929a3` and `75522cc0` exist in git log (verified)
