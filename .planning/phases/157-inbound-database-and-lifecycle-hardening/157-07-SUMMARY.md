---
phase: 157-inbound-database-and-lifecycle-hardening
plan: 07
subsystem: database
tags: [elixir, ecto, postgres, suppression, keyset-pagination, bulk-upsert]
requires:
  - phase: 157-06
    provides: positional bounded suppression-store bulk lookup capability
provides:
  - Stable `(occurred_at, id)` keyset-paged suppression resync
  - Cross-page candidate-key deduplication with bounded bulk existence reads and conflict-safe writes
  - Public Mix task proof of configured bounded pages without new CLI options
affects: [suppression, outbound, lifecycle-hardening]
tech-stack:
  added: []
  patterns: [stable keyset cursor, cross-page key deduplication, bounded result preview, bounded multi insert, fail-visible chunk writes]
key-files:
  created:
    - test/mailglass/suppression/resync_test.exs
  modified:
    - lib/mailglass/suppression/resync.ex
    - lib/mailglass/suppression_store/ecto.ex
    - test/mailglass/suppression_store/ecto_test.exs
    - test/mix/tasks/mailglass.suppressions.resync_test.exs
key-decisions:
  - "Page by `(occurred_at, id)` and keep only summary data plus candidate keys needed to retain cross-page totals."
  - "Keep bounded page sizing configurable through application configuration, not new Mix task flags."
requirements-completed: [DATA-05]
coverage:
  - id: D1
    description: Keyset-paged resync preserves equal-timestamp events, cross-page duplicate treatment, existing/missing totals, and visible write failures.
    requirement: DATA-05
    verification:
      - kind: integration
        ref: mix test test/mailglass/suppression/resync_test.exs --warnings-as-errors
        status: pass
    human_judgment: false
  - id: D2
    description: Public resync Mix task preserves its flags and output while routing work through configured bounded pages.
    requirement: DATA-05
    verification:
      - kind: integration
        ref: mix test test/mix/tasks/mailglass.suppressions.resync_test.exs --warnings-as-errors
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-08-17
status: complete
---

# Phase 157 Plan 07: Bounded Suppression Resync Summary

**Suppression-ledger rebuild now keyset-pages with bounded bulk lookup/upsert work while retaining dry-run and Mix task result semantics.**

## Accomplishments

- Replaced full-window event loading and per-candidate queries with `(occurred_at, id)` keyset pages, cross-page key deduplication, a 100-entry result preview, and Plan 06 positional bulk reads.
- Batched missing suppression rows into conflict-safe `insert_all` chunks; a real chunk write error stops the run without undoing earlier committed pages.
- Proved equal-timestamp cursor traversal, duplicate handling across page boundaries, existing/missing totals, dry-run behavior, and unmodified CLI output.

## Task Commits

1. **Task 1: Resync one multi-page ledger with bounded bulk work** — `f4ce2e47` (`feat`)
2. **Task 2: Preserve the public resync Mix task contract** — `eb5e4f8a` (`test`)

## Files Created/Modified

- `lib/mailglass/suppression/resync.ex` — bounded keyset scanner, positional bulk lookup, conflict-safe chunk writes, and configuration-based page bound.
- `test/mailglass/suppression/resync_test.exs` — equal-timestamp/duplicate pagination and write-failure coverage.
- `test/mix/tasks/mailglass.suppressions.resync_test.exs` — public task bounded-page contract coverage.
- `lib/mailglass/suppression_store/ecto.ex` — fixes nil-stream handling in the Plan 06 native bulk predicate.
- `test/mailglass/suppression_store/ecto_test.exs` — explicitly covers omitted and nil bulk lookup stream values.

## Decisions Made

- Kept page-size control internal to application configuration (`:suppression_resync_page_size`) so the public Mix task's accepted flags and output vocabulary do not change.
- Retained compact cross-page key state so page boundaries cannot alter dry-run versus apply totals, while capping returned candidate detail at 100 entries with additive truncation metadata.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Handle nil stream values in native Ecto bulk checks**
- **Found during:** Task 1
- **Issue:** Elixir treats `nil` as an atom, so the Plan 06 `is_atom(stream)` branch built an invalid `e.stream == nil` Ecto predicate for address-scoped resync candidates.
- **Fix:** Excluded `nil` from the stream-scoped predicate and added explicit omitted/nil-stream regression coverage.
- **Files modified:** `lib/mailglass/suppression_store/ecto.ex`, `test/mailglass/suppression_store/ecto_test.exs`
- **Verification:** Focused resync, Mix task, and Ecto store tests pass.
- **Committed in:** `f4ce2e47`, `eb5e4f8a`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Required for the bounded address-scoped flow; no public API or CLI scope expansion.

## Verification

- `mix test test/mailglass/suppression/resync_test.exs test/mix/tasks/mailglass.suppressions.resync_test.exs test/mailglass/suppression_store/ecto_test.exs --warnings-as-errors`
- `mix compile --warnings-as-errors`
- `mix format --check-formatted` for all modified implementation and test files
- `git diff --check`

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

Bounded suppression resync is available to later lifecycle/database work with no new admin or operator UI surface.

## Self-Check: PASSED

- All listed implementation and test files exist.
- Task commits `f4ce2e47` and `eb5e4f8a` exist in git history.
