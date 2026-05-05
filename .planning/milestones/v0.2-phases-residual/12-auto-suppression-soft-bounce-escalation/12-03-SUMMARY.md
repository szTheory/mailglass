---
phase: 12-auto-suppression-soft-bounce-escalation
plan: 03
subsystem: suppression
tags: [oban, suppression, migrations, deliverability]
requires:
  - phase: 12-auto-suppression-soft-bounce-escalation
    provides: matched webhook suppression projection
provides:
  - async soft-bounce escalation worker and evaluation helper
  - optional-dependency-gated enqueue path for deferred escalation jobs
  - V03 storage boundary with deferred-event scan index and complaint-permanence DDL
affects: [suppression, webhook-ingest, migrations, oban, phase-12]
tech-stack:
  added: []
  patterns: [conditional Oban worker, explicit tenant-scoped event window query, versioned migration slot]
key-files:
  created:
    - lib/mailglass/suppression/escalation.ex
    - lib/mailglass/migrations/postgres/v03.ex
    - test/mailglass/suppression/escalation_test.exs
  modified:
    - lib/mailglass/migrations/postgres.ex
key-decisions:
  - "Keep soft-bounce escalation fully async behind a conditionally compiled Oban worker and never evaluate inside the webhook request path."
  - "Use explicit tenant plus recipient filtering over deferred events in a seven-day sliding window, with a default threshold of five."
  - "Ship the complaint-permanence CHECK constraint in V03 now because the storage release boundary is shared with later Phase 12 permanence API work."
requirements-completed: [SUPP-02]
duration: 5min
completed: 2026-04-28
---

# Phase 12 Plan 03: Soft-Bounce Escalation Summary

**Soft-bounce escalation now has an Oban-backed worker, a direct evaluation helper, and the V03 storage slot needed for its event-window query**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-28T12:16:00Z
- **Completed:** 2026-04-28T12:20:47Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Mailglass.Suppression.Escalation` as a conditionally compiled Oban worker with a public `evaluate/2` helper and an enqueue path routed through `Mailglass.OptionalDeps.Oban`.
- Enforced the locked default escalation rule of five `:deferred` events in seven days and wrote distinguishable suppression provenance via `source: "webhook:soft_bounce_escalation"` plus metadata.
- Added `Mailglass.Migrations.Postgres.V03`, bumped the internal migration dispatcher to version `3`, and included both the deferred-event scan index and the complaint-permanence CHECK scaffold for the shared storage release boundary.

## Task Commits

1. **Task 1 RED: lock the worker contract** - `d38de75` (`test`)
2. **Task 1 GREEN: implement the worker and helper** - `4398df0` (`feat`)
3. **Task 2: add V03 migration and version bump** - `91a5695` (`feat`)

## Files Created/Modified

- `lib/mailglass/suppression/escalation.ex` - Conditionally compiled Oban worker, enqueue helper, threshold evaluation query, and distinguishable suppression insert path.
- `test/mailglass/suppression/escalation_test.exs` - Covers compile gating, enqueue gateway usage, below-threshold behavior, and threshold-triggered suppression provenance.
- `lib/mailglass/migrations/postgres.ex` - Bumps `@current_version` from `2` to `3`.
- `lib/mailglass/migrations/postgres/v03.ex` - Adds the deferred-event query index and complaint-permanence CHECK constraint.

## Decisions Made

- Kept the worker inside the top-level `if Code.ensure_loaded?(Oban.Worker)` guard so `mix compile --no-optional-deps --warnings-as-errors` stays clean.
- Counted deferred evidence through `mailglass_events` joined to `mailglass_deliveries`, scoped by both tenant and recipient, instead of relying on payload metadata.
- Chose `mailglass_events_deferred_window_idx` as a narrow partial index on deferred rows with non-null `delivery_id` because that is the exact event subset the worker scans.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Next Phase Readiness

- Plan `12-05` can call the new enqueue/evaluation seam instead of inventing a second escalation path.
- Plan `12-06` can build on the already-shipped complaint-permanence DDL and focus on API-level permanence/removal behavior.

## Self-Check

PASSED
