---
phase: 24-tenant-safe-webhook-replay-with-audit-context
plan: 01
subsystem: operator
tags: [replay, webhook, tenancy, operator, read-model]
requires:
  - phase: 23-production-admin-mount-and-step-up-auth
    provides: operator auth-aware production surface for future destructive actions
provides:
  - durable webhook-to-ledger replay linkage on ingest
  - tenant-scoped replay target resolution for delivery detail flows
  - ambiguity-safe replay target outcomes for historical and SendGrid cases
affects: [phase-24-plan-02, phase-24-plan-03, operator-replay]
tech-stack:
  added: []
  patterns: [tenant-scoped replay target read model, ledger metadata back-link to webhook rows]
key-files:
  created: [lib/mailglass/operator/replay_targets.ex, test/mailglass/operator/replay_targets_test.exs]
  modified: [lib/mailglass/webhook/ingest.ex, test/mailglass/webhook/ingest_test.exs]
key-decisions:
  - "Replay identity is preserved on future ingest writes via webhook_event_id metadata on each appended ledger event."
  - "Historical deliveries without exact linkage degrade to explicit unavailable states instead of guessing from delivery-only context."
  - "SendGrid historical child events remain unavailable when they cannot safely imply one raw webhook row."
patterns-established:
  - "Replay target lookup starts from tenant_id + delivery_id, then resolves exact webhook rows from ledger metadata."
  - "Operator replay read models return explicit exact, ambiguous, and unavailable outcomes."
requirements-completed: [REPLAY-01, REPLAY-03]
duration: 23min
completed: 2026-05-01
---

# Phase 24: Plan 01 Summary

**Replay-safe delivery targeting now resolves exact webhook rows from tenant-scoped ledger linkage instead of guessing from delivery ids alone**

## Performance

- **Duration:** 23 min
- **Started:** 2026-05-01T14:35:00Z
- **Completed:** 2026-05-01T14:58:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added durable replay linkage during webhook ingest by stamping each appended event with its source `webhook_event_id`.
- Introduced `Mailglass.Operator.ReplayTargets` as the canonical tenant-scoped resolver for zero/one/many replay target outcomes.
- Locked the safety contract with coverage for exact matches, ambiguity, historical no-linkage, and SendGrid child-event fallback.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write durable replay-target linkage during webhook ingest** - `653ca5d` (feat)
2. **Task 2: Add the tenant-scoped replay-target resolver and ambiguity tests** - `60840d5` (feat)

## Files Created/Modified

- `lib/mailglass/webhook/ingest.ex` - stamps replay linkage metadata onto newly appended ledger events.
- `test/mailglass/webhook/ingest_test.exs` - proves replay linkage survives normal ingest, duplicate replay, and SendGrid batch ingest.
- `lib/mailglass/operator/replay_targets.ex` - resolves selected deliveries to exact replayable webhook candidates under tenant scope.
- `test/mailglass/operator/replay_targets_test.exs` - covers exact, ambiguous, unavailable, tenant-mismatch, and SendGrid historical cases.

## Decisions Made

- Used `webhook_event_id` as the canonical future-write replay pointer and preserved raw webhook `provider_event_id` separately for fallback display/query needs.
- Returned explicit `:exact`, `:ambiguous`, and `:unavailable` statuses so the UI can stay honest without inventing replay targets.
- Treated historical SendGrid child events without linkage as unavailable because they do not safely identify one raw webhook row.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The repository already contained unrelated in-progress changes, so execution stayed scoped to the plan-owned files and commits only.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 24 plan 02 can now build the canonical replay command and append-only replay audit history on top of exact webhook target resolution.
- Phase 24 plan 03 can consume the explicit resolver outcomes to drive modal preselection, ambiguity choice, and unavailable copy in the operator UI.

---
*Phase: 24-tenant-safe-webhook-replay-with-audit-context*
*Completed: 2026-05-01*
