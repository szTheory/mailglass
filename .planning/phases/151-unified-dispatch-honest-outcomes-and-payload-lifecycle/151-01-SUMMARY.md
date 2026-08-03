---
phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
plan: "01"
subsystem: outbound dispatch
tags: [oban, outbound, envelope, provider-adapter, integration-testing]
requires:
  - phase: 150-08
    provides: immutable V2 payload decode and real public-Oban job proof
provides:
  - One provider-input handoff for sync, Task.Supervisor, and durable Oban dispatch
  - Actual-job wire-equivalence regression coverage for supported outbound input
affects: [dispatch-outcomes, payload-lifecycle, generated-host-proof]
tech-stack:
  added: []
  patterns: [in-memory envelope normalization before sync adapter I/O, captured adapter-input oracle]
key-files:
  created:
    - test/mailglass/outbound/wire_equivalence_test.exs
  modified:
    - lib/mailglass/outbound.ex
key-decisions:
  - "Sync uses the bounded Envelope codec in memory so it normalizes exactly as durable payload dispatch without writing a Payload."
  - "The persisted adapter route is resolved before durable dispatch reaches the shared provider handoff."
patterns-established:
  - "Wire-equivalence tests must perform the job inserted by public deliver_later/2 and compare captured adapter input field-for-field."
requirements-completed: [ENVL-03]
coverage:
  - id: D1
    description: "Sync and actual queued-job dispatch hand the adapter equal normalized recipient, headers, attachments, content, metadata, tags, and provider options."
    requirement: ENVL-03
    verification:
      - kind: integration
        ref: "mix test test/mailglass/outbound/wire_equivalence_test.exs --only phase_151_task:t151_01_01 --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 46min
completed: 2026-08-03
status: complete
---

# Phase 151 Plan 01: Unified Prepared Dispatch Summary

**Sync and real queued Oban delivery now send the same envelope-normalized provider input through one canonical adapter handoff.**

## Performance

- **Duration:** 46 min
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Added an integration oracle that captures sync and actual ID-only Oban-job adapter input for a fully featured, one-recipient message.
- Normalized sync input through the bounded envelope codec in memory, preserving the no-sync-Payload contract.
- Unified sync, Task.Supervisor, and payload-backed delivery at `dispatch_prepared/3`, while retaining the persisted async adapter route as authority.

## Task Commits

1. **Task 1: Prove one sync/Oban provider-input path** — `7202e5b7` (RED test), `50e9c92d` (GREEN implementation), `624da02f` (support-contract follow-up)

## Files Created/Modified

- `lib/mailglass/outbound.ex` — canonical prepared-message dispatch handoff and in-memory sync normalization.
- `test/mailglass/outbound/wire_equivalence_test.exs` — deep captured adapter-input and public-surface regression oracle.

## Decisions Made

- Sync normalizes through `Envelope.dump/2` and `Envelope.load/1` in memory rather than persisting private content just to reuse the durable path.
- The test preserves the existing documented public-safe metadata projection while asserting all non-metadata private sentinels stay off Delivery/Event/job surfaces.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored failed-projection persistence for payload-load errors**
- **Found during:** Task 1
- **Issue:** Initial seam extraction bypassed the existing `dispatch_by_id/1` failure persistence branch.
- **Fix:** Wrapped the shared dispatch result so exception-shaped payload/load failures still call `persist_failed_by_id/2`.
- **Files modified:** `lib/mailglass/outbound.ex`
- **Verification:** `mix test test/mailglass/outbound/wire_equivalence_test.exs test/mailglass/outbound/worker_test.exs --warnings-as-errors`
- **Commit:** `50e9c92d`

**Total deviations:** 1 auto-fixed (Rule 1)

### Follow-up Support-Contract Fix

- Preserved direct sync adapter input for map-backed headers and nonpersistable explicit adapter overrides, while retaining envelope normalization for ordered durable-header input.
- Added focused regressions for the explicit adapter precedence and bulk `List-Unsubscribe` header access contracts.
- Verified with focused wire-equivalence/worker tests and the full outbound directory suite.

## Issues Encountered

- Equal sync and async fixtures intentionally collide on the durable idempotency key. The test releases only the first fixture key after capturing its adapter input so it can execute an equivalent real queued job.
- The existing public-safe `Delivery.metadata` compatibility projection is intentionally retained; its value is still checked at the adapter boundary but is not treated as a private-content sentinel.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Outcome classification and payload lifecycle work can rely on one verified adapter-input seam.
- No Payload is created for synchronous sends, and durable jobs continue to use their stored adapter route.

## Self-Check: PASSED

- Found `lib/mailglass/outbound.ex`, `test/mailglass/outbound/wire_equivalence_test.exs`, and task commits `7202e5b7`, `50e9c92d`, and `624da02f`.
