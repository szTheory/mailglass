---
phase: 24-tenant-safe-webhook-replay-with-audit-context
plan: "01"
subsystem: operator
tags: [replay, webhook, tenancy, audit, sendgrid]
requires:
  - phase: 22-operator-data-foundation
    provides: tenant-scoped delivery and timeline read models for the operator surface
  - phase: 04-webhook-ingest
    provides: verified webhook ingest path and raw webhook persistence
provides:
  - durable replay linkage on newly appended ledger events
  - tenant-scoped delivery replay target resolver with exact and ambiguous outcomes
  - tests for zero/one/many replay target resolution and SendGrid historical safety
affects: [phase-24-replay-ui, operator-liveview, replay-audit]
tech-stack:
  added: []
  patterns: [durable replay linkage in event metadata, schema-less tenant-scoped raw webhook lookup]
key-files:
  created: [lib/mailglass/operator/replay_targets.ex, test/mailglass/operator/replay_targets_test.exs]
  modified: [lib/mailglass/webhook/ingest.ex, test/mailglass/webhook/ingest_test.exs]
key-decisions:
  - "Replay identity is written during ingest inside the existing append path via webhook_event_id and webhook_provider_event_id metadata."
  - "The operator resolver only trusts durable replay linkage and rejects tenant mismatches before any raw webhook lookup."
  - "Historical SendGrid child events without durable linkage degrade to explicit unavailable state instead of implying a raw webhook row."
patterns-established:
  - "Replay linkage metadata belongs on normalized ledger events, not as post-write mutation."
  - "Operator read models may query raw webhook storage schema-less to preserve boundary discipline while staying tenant-scoped."
requirements-completed: [REPLAY-01, REPLAY-03]
duration: 24min
completed: 2026-05-01
---

# Phase 24: Tenant-Safe Webhook Replay with Audit Context Summary

**Durable replay linkage now flows from webhook ingest into ledger metadata, and delivery detail flows can resolve tenant-safe raw webhook replay targets without guessing**

## Performance

- **Duration:** 24 min
- **Started:** 2026-05-01T18:33:00Z
- **Completed:** 2026-05-01T18:57:28Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Webhook ingest now stamps each appended normalized event with `webhook_event_id` and `webhook_provider_event_id` metadata inside the existing transaction path.
- Added `Mailglass.Operator.ReplayTargets.list_delivery_targets/1` to return explicit `:exact`, `:ambiguous`, and `:unavailable` outcomes under tenant scope.
- Added coverage for replay linkage persistence, duplicate convergence, zero/one/many replay-target outcomes, tenant mismatch rejection, and historical SendGrid safety.

## Task Commits

Each task was committed atomically:

1. **Task 24-01-01: Write durable replay-target linkage during webhook ingest** - `653ca5d` (feat)
2. **Task 24-01-02: Add the tenant-scoped replay-target resolver and ambiguity tests** - `60840d5` (feat)

## Files Created/Modified
- `lib/mailglass/webhook/ingest.ex` - writes replay linkage metadata during event append
- `test/mailglass/webhook/ingest_test.exs` - proves replay linkage exists and duplicate ingest still converges
- `lib/mailglass/operator/replay_targets.ex` - resolves delivery-scoped replay candidates under tenant scope
- `test/mailglass/operator/replay_targets_test.exs` - covers exact, ambiguous, unavailable, tenant, and SendGrid historical cases
- `.planning/phases/24-tenant-safe-webhook-replay-with-audit-context/24-01-SUMMARY.md` - execution summary for plan 24-01

## Decisions Made
- Preferred durable future-write linkage from ingest rather than trying to infer replay identity from normalized child events.
- Used schema-less `mailglass_webhook_events` queries in the operator read model to avoid boundary warnings while keeping tenant scope explicit.
- Returned `:historical_sendgrid_batch` for old SendGrid rows without linkage so the UI can explain why replay is unavailable instead of guessing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Blocking] Removed an operator boundary violation in raw webhook lookup**
- **Found during:** Task 24-01-02 (tenant-scoped replay target resolver)
- **Issue:** Directly referencing `Mailglass.Webhook.WebhookEvent` from the operator layer raised boundary warnings and broke the `--warnings-as-errors` lane.
- **Fix:** Switched the resolver to a schema-less `mailglass_webhook_events` query with explicit tenant scope and type normalization.
- **Files modified:** `lib/mailglass/operator/replay_targets.ex`
- **Verification:** `mix test test/mailglass/operator/replay_targets_test.exs --warnings-as-errors`
- **Committed in:** `60840d5`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope creep. The change preserved the planned resolver behavior while making the verification lane pass.

## Issues Encountered
- Duplicate ingest returns a transient conflict struct that does not reliably expose the persisted raw webhook row id, so the ingest test was tightened to assert durable stored linkage instead of the duplicate call's transient return struct.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Delivery detail flows now have a canonical tenant-safe replay target resolver and durable future-write linkage to exact raw webhook rows.
- Phase 24 replay UI and audit command work can build on `list_delivery_targets/1` without inventing a delivery-id-based replay path.

---
*Phase: 24-tenant-safe-webhook-replay-with-audit-context*
*Completed: 2026-05-01*
