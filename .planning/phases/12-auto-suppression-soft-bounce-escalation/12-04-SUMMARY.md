---
phase: 12-auto-suppression-soft-bounce-escalation
plan: 04
subsystem: api
tags: [suppression, resync, mix-task, tenancy, ecto]
requires:
  - phase: 12-01
    provides: centralized webhook suppression translation via Mailglass.Suppression.AutoSuppress
provides:
  - tenant-scoped suppression resync service with a shared dry-run/apply candidate path
  - strict mix task wrapper requiring --tenant-id for operator-led repair runs
  - replay-safe projection coverage for bounded resync windows
affects: [phase-12, suppression-repair, operator-tooling]
tech-stack:
  added: []
  patterns: [tenant-scoped batch repair, shared dry-run/apply projection path, conflict-ignore replay safety]
key-files:
  created:
    - lib/mailglass/suppression/resync.ex
    - lib/mix/tasks/mailglass.suppressions.resync.ex
    - test/mix/tasks/mailglass.suppressions.resync_test.exs
  modified: []
key-decisions:
  - "Reused Mailglass.Suppression.AutoSuppress.build_attrs/2 so resync matches live webhook projection semantics."
  - "Kept default operator output count-only and moved candidate detail behind --verbose."
patterns-established:
  - "Batch repair flows should query under explicit tenant scope and never rely on ambient tenancy for candidate selection."
  - "Dry-run and apply modes should diverge only after candidate selection so reported counts stay trustworthy."
requirements-completed: [SUPP-03]
duration: 5min
completed: 2026-04-28
---

# Phase 12 Plan 04: Suppression Resync Summary

**Tenant-scoped suppression rebuild via a shared resync service and strict `mix mailglass.suppressions.resync` contract**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-28T12:23:00Z
- **Completed:** 2026-04-28T12:28:08Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `Mailglass.Suppression.Resync` to project `mailglass_events` back into `mailglass_suppressions` using the existing auto-suppression translation layer.
- Added `Mix.Tasks.Mailglass.Suppressions.Resync` with mandatory `--tenant-id`, bounded window support, dry-run/apply parity, and optional verbose candidate output.
- Added targeted tests covering 90-day default windowing, tenant isolation, write-free dry runs, and idempotent repeated apply runs.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build one tenant-scoped resync service for dry-run and apply**
   - `7fa1e07` (`test`) RED
   - `78cfdc3` (`feat`) GREEN
2. **Task 2: Add the strict Mix task contract**
   - `67b9203` (`test`) RED
   - `02a2e55` (`feat`) GREEN
   - `834ffa0` (`style`) formatter follow-up

## Files Created/Modified

- `lib/mailglass/suppression/resync.ex` - Shared tenant-scoped ledger scan and projection service with dry-run/apply split at the write step.
- `lib/mix/tasks/mailglass.suppressions.resync.ex` - Strict operator-facing Mix task wrapper for the resync service.
- `test/mix/tasks/mailglass.suppressions.resync_test.exs` - Service and CLI coverage for tenant scoping, bounded windows, dry-run parity, and idempotent apply behavior.

## Decisions Made

- Reused `Mailglass.Suppression.AutoSuppress.build_attrs/2` instead of introducing a second event-to-suppression translator, keeping runtime and repair behavior aligned.
- Returned candidate summaries from the service so the Mix task can stay count-only by default while still supporting `--verbose` without re-querying.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Tenant-scoped suppression repair is available for operator-led rebuilds and replay-safe verification.
- No blockers surfaced within the files owned for this plan.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/12-auto-suppression-soft-bounce-escalation/12-04-SUMMARY.md`.
- Task commits present: `7fa1e07`, `78cfdc3`, `67b9203`, `02a2e55`, `834ffa0`.

---
*Phase: 12-auto-suppression-soft-bounce-escalation*
*Completed: 2026-04-28*
