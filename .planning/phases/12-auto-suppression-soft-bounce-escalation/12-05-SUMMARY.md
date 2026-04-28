---
phase: 12-auto-suppression-soft-bounce-escalation
plan: 05
subsystem: api
tags: [suppression, telemetry, errors, webhook, preflight]
requires:
  - phase: 12-01
    provides: webhook-driven suppression projection and auto-suppress wiring
provides:
  - enriched SuppressedError context for pre-send blocks
  - explicit suppression telemetry for pre-send-blocked and auto-added paths
affects: [phase-12, suppression, outbound, webhook]
tech-stack:
  added: []
  patterns: [structured error enrichment, whitelist-safe telemetry metadata]
key-files:
  created: []
  modified:
    - lib/mailglass/suppression.ex
    - lib/mailglass/errors/suppressed_error.ex
    - lib/mailglass/suppression/auto_suppress.ex
    - test/mailglass/suppression_test.exs
    - test/mailglass/outbound/preflight_test.exs
key-decisions:
  - "Kept `{:error, %Mailglass.SuppressedError{}}` as the only public pre-send suppression failure shape and enriched its context instead of inventing a parent error struct."
  - "Emitted suppression telemetry only with tenant, scope, reason, source, and expiry-presence metadata to preserve the CORE-03 no-PII contract."
patterns-established:
  - "Suppression callers receive non-PII detail through error context, not through ad hoc result tuples."
  - "Suppression telemetry is emitted at the decision point that blocks or inserts state, with boolean expiry signaling instead of raw recipient data."
requirements-completed: [SUPP-04]
duration: 4min
completed: 2026-04-28
---

# Phase 12 Plan 05: Suppression Surface Summary

**Structured suppression preflight errors with reason/source/expiry context plus explicit non-PII telemetry for blocked sends and webhook auto-adds**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-28T12:31:25Z
- **Completed:** 2026-04-28T12:34:20Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Enriched `%Mailglass.SuppressedError{}` context with `reason`, `source`, and `expires_at` while keeping the public error hierarchy unchanged.
- Added `[:mailglass, :suppression, :pre_send_blocked, :stop]` telemetry for fail-closed pre-send suppression hits.
- Added `[:mailglass, :suppression, :auto_added, :stop]` telemetry at the webhook auto-suppression insert point with whitelist-safe metadata only.

## Task Commits

Each task was committed atomically:

1. **Task 1: Enrich suppression-hit errors without changing the repo's public hierarchy** - `f041edd` (`test`), `3ae375c` (`feat`)
2. **Task 2: Emit suppression telemetry for auto-add and pre-send-blocked paths** - `c9c1704` (`test`), `6463b4c` (`feat`)

## Files Created/Modified
- `lib/mailglass/suppression.ex` - Added structured suppression error context assembly and `pre_send_blocked` telemetry emission.
- `lib/mailglass/errors/suppressed_error.ex` - Documented and typed the richer non-PII suppression context contract.
- `lib/mailglass/suppression/auto_suppress.ex` - Emitted `auto_added` telemetry from the webhook suppression insert helper.
- `test/mailglass/suppression_test.exs` - Added regression coverage for enriched context and both suppression telemetry signals.
- `test/mailglass/outbound/preflight_test.exs` - Verified preflight still returns a structured suppression error and inserts no delivery row.

## Decisions Made
- Kept the repo-native suppression failure shape exactly as `{:error, %Mailglass.SuppressedError{}}`; callers get extra detail through `context`, not through a new wrapper struct.
- Represented expiry in telemetry as `expires_at?` instead of the raw timestamp to stay inside the plan's whitelist-safe metadata boundary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Emitted auto-add telemetry from `Mailglass.Suppression.AutoSuppress` instead of `Mailglass.Webhook.Ingest`**
- **Found during:** Task 2
- **Issue:** The plan required an `auto_added` event in either the ingest pipeline or the suppression helper, but the insert decision and successful row shape only exist in the helper.
- **Fix:** Added telemetry at the successful insert point in `Mailglass.Suppression.AutoSuppress`, which keeps the event aligned with the actual suppression write.
- **Files modified:** `lib/mailglass/suppression/auto_suppress.ex`
- **Verification:** `mix test test/mailglass/suppression_test.exs`
- **Committed in:** `6463b4c`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope creep. The deviation kept the implementation smaller and attached telemetry to the exact write boundary the plan required.

## Issues Encountered

- `gsd-sdk query state.advance-plan` reported `last_plan` against the current pre-dirty planning state, and `roadmap.update-plan-progress` found no matching checkbox.
- `gsd-sdk query requirements.mark-complete SUPP-04` rewrote adjacent requirement text incorrectly, so that helper-generated change was reverted instead of being committed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Suppression callers now receive consistent, actionable non-PII detail for blocked sends.
- Phase 12 can build on explicit suppression telemetry without revisiting the public error contract.

## Self-Check

PASSED

- Found summary file at `.planning/phases/12-auto-suppression-soft-bounce-escalation/12-05-SUMMARY.md`
- Verified task commits `f041edd`, `3ae375c`, `c9c1704`, and `6463b4c` exist in git history

---
*Phase: 12-auto-suppression-soft-bounce-escalation*
*Completed: 2026-04-28*
