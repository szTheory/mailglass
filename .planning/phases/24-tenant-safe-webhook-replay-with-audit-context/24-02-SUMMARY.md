---
phase: 24-tenant-safe-webhook-replay-with-audit-context
plan: 02
subsystem: webhook
tags: [replay, audit, ledger, webhook, operator]
requires:
  - phase: 24-tenant-safe-webhook-replay-with-audit-context
    provides: exact webhook replay target resolution for selected deliveries
provides:
  - closed replay audit event types in the ledger contract
  - canonical tenant-scoped webhook replay command
  - delivery-scoped replay history read model
affects: [phase-24-plan-03, operator-replay, operator-timeline]
tech-stack:
  added: []
  patterns: [append-only replay requested/succeeded/failed audit facts, explicit replayed vs noop command outcomes]
key-files:
  created: [lib/mailglass/webhook/replay.ex, lib/mailglass/operator/replay_history.ex, test/mailglass/webhook/replay_test.exs]
  modified: [lib/mailglass/events/event.ex, docs/api_stability.md, test/mailglass/operator/timeline_test.exs]
key-decisions:
  - "Replay reuses provider normalization and ledger/projector paths without attempting to insert a second raw webhook row."
  - "Replay audit facts are first-class internal ledger event types rather than mutable webhook-row summaries."
  - "The replay command remains tenant-explicit all the way through delivery resolution and projector lookup."
patterns-established:
  - "Replay commands append requested audit facts before execution and succeeded/failed facts after outcome resolution."
  - "Operator replay history queries stay delivery-scoped and source their actor/target metadata from ledger rows."
requirements-completed: [REPLAY-02, REPLAY-03]
duration: 33min
completed: 2026-05-01
---

# Phase 24: Plan 02 Summary

**Webhook replay is now a tenant-scoped command with durable requested, succeeded, and failed audit facts backed by a delivery-level replay history read model**

## Performance

- **Duration:** 33 min
- **Started:** 2026-05-01T14:58:00Z
- **Completed:** 2026-05-01T15:08:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Extended the ledger event contract to include replay audit fact types and documented the closed event set.
- Added `Mailglass.Operator.ReplayHistory` so operator code can query replay audit rows chronologically for one delivery.
- Implemented `Mailglass.Webhook.Replay.execute/1` with explicit `:replayed` vs `:noop` outcomes plus durable failure auditing.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend the ledger contract for replay audit facts and history reads** - `2ca7cfb` (feat)
2. **Task 2: Implement the canonical replay command with explicit no-op and failure outcomes** - `6350cc8` (feat)

## Files Created/Modified

- `lib/mailglass/events/event.ex` - adds closed internal replay audit event types.
- `docs/api_stability.md` - documents the expanded closed event type contract.
- `lib/mailglass/operator/replay_history.ex` - exposes chronological delivery-scoped replay audit history.
- `test/mailglass/operator/timeline_test.exs` - proves replay history is tenant-scoped and ordered.
- `lib/mailglass/webhook/replay.ex` - executes tenant-scoped replay, writes requested/succeeded/failed audits, and returns honest outcomes.
- `test/mailglass/webhook/replay_test.exs` - covers replayed work, noop convergence, tenant mismatch rejection, and failed audit persistence.

## Decisions Made

- Reused provider normalization and existing projector/auto-suppression flows instead of attempting to replay by inserting a second raw webhook row.
- Classified replay success as either `:replayed` or `:noop` based on whether new ledger rows were actually inserted.
- Linked failed audits back to the already-written requested audit row whenever the failure happens after the request audit is durable.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The first replay command draft still relied on ambient tenant context for some delivery lookups; that was corrected so replay stays explicitly tenant-scoped even outside webhook-ingest process context.
- Initial tests overfit on total `mailglass_events` counts. The final assertions verify replay semantics by event type and target metadata instead.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 24 plan 03 can now drive its modal, action-time auth, and inline result rendering from `ReplayTargets`, `Replay.execute/1`, and `ReplayHistory.list_delivery_replay_history/1`.
- Replay outcomes now expose enough durable operator-visible context for the LiveView to distinguish replayed work, noop convergence, and failures honestly.

---
*Phase: 24-tenant-safe-webhook-replay-with-audit-context*
*Completed: 2026-05-01*
