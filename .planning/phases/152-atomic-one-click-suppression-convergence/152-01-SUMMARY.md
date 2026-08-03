---
phase: 152-atomic-one-click-suppression-convergence
plan: 01
subsystem: compliance
tags: [elixir, ecto, postgres, phoenix, suppression, unsubscribe]
requires:
  - phase: 149-first-send-contract-foundation
    provides: prefix-aware repository operations and stream-scoped suppression schema
  - phase: 151-unified-dispatch-honest-outcomes-and-payload-lifecycle
    provides: trusted persisted Delivery records and opaque one-click route contract
provides:
  - atomic event-and-suppression one-click convergence service
  - explicit empty-500 rollback behavior for genuine convergence failures
affects: [152-02 post-commit effects, 152-03 compatibility documentation]
tech-stack:
  added: []
  patterns: [flat Ecto.Multi convergence, explicit prefix callback refetches, inserted_at conflict sentinel]
key-files:
  created: [lib/mailglass/compliance/unsubscribe_convergence.ex]
  modified: [lib/mailglass/compliance/unsubscribe_controller.ex, test/mailglass/compliance/unsubscribe_controller_test.exs]
key-decisions:
  - "One-click suppression metadata is bounded to delivery_id, event_id, and event_type with source compliance:one_click."
  - "The DB-defaulted inserted_at field is the conflict sentinel for both client-generated UUID records."
patterns-established:
  - "Trusted Delivery data enters the tenant context before all convergence writes."
  - "Either durable fact inserted makes a repaired legacy pair created; only a fully pre-existing pair is already_converged."
requirements-completed: [UNSUB-07, UNSUB-08, UNSUB-11]
coverage:
  - id: D1
    description: "Valid one-click POST atomically converges one canonical unsubscribe event and immutable address-stream suppression."
    requirement: UNSUB-07
    verification:
      - kind: integration
        ref: "mix test test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Replay and legacy half-state repairs return canonical convergence results without duplicate durable rows."
    requirement: UNSUB-08
    verification:
      - kind: integration
        ref: "test/mailglass/compliance/unsubscribe_controller_test.exs#POST one-click convergence cases"
        status: pass
    human_judgment: false
  - id: D3
    description: "Named failures after either insert roll back the complete pair and map to an empty 500."
    requirement: UNSUB-11
    verification:
      - kind: integration
        ref: "test/mailglass/compliance/unsubscribe_controller_test.exs#rollback cases"
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-08-03
status: complete
---

# Phase 152 Plan 01: Atomic One-Click Suppression Convergence Summary

**One-click POSTs now atomically converge a delivery-keyed unsubscribe event with an immutable, stream-scoped suppression while preserving exact privacy no-ops.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-08-03T14:27:00Z
- **Completed:** 2026-08-03T14:32:11Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Added a flat, prefix-explicit `UnsubscribeConvergence` transaction that canonicalizes event and suppression conflicts by refetching persisted rows.
- Derived suppression scope only from the trusted Delivery, with exact `compliance:one_click` source and bounded metadata.
- Proved legacy half-state repair, full-pair replay classification, privacy no-ops, and deterministic all-or-nothing empty-500 rollback paths.

## Task Commits

1. **Task 1: Prove and implement the flat atomic convergence path** — `20bf7fc1` (RED), `d91c926a` (GREEN)
2. **Task 2: Close conflict, incomplete-pair, and rollback branches** — `7d7c6525`, `a6d6983e` (RED), `065e11c5` (GREEN), `a4400ebd` (status coverage)

## Files Created/Modified

- `lib/mailglass/compliance/unsubscribe_convergence.ex` — Transactional event/suppression convergence and canonical result classification.
- `lib/mailglass/compliance/unsubscribe_controller.ex` — Tenant-restored controller wiring with stable empty 200/500 responses.
- `test/mailglass/compliance/unsubscribe_controller_test.exs` — Public POST, conflict, repair, metadata, and rollback evidence.

## Decisions Made

- Used the DB-defaulted `inserted_at` result as the adapter-pinned `ON CONFLICT DO NOTHING` sentinel, since IDs are client-generated.
- Kept lifecycle and broadcast effects out of this transaction; Plan 02 owns created-only post-commit effects.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored tenant context before convergence**
- **Found during:** Task 2
- **Issue:** The initial controller refactor called the convergence service without restoring the Delivery tenant context.
- **Fix:** Wrapped `UnsubscribeConvergence.run/1` in `Tenancy.with_tenant/2` before the prefix-explicit transaction.
- **Files modified:** `lib/mailglass/compliance/unsubscribe_controller.ex`
- **Verification:** Focused controller test suite passed.
- **Committed in:** `065e11c5`

**Total deviations:** 1 auto-fixed (Rule 1)

## Issues Encountered

- `mix format --check-formatted` reports a pre-existing formatting difference in `lib/mailglass/optional_deps/oban.ex`, outside this plan's file ownership. It was not modified.

## User Setup Required

None.

## Next Phase Readiness

Plan 02 can add created-only post-commit lifecycle and broadcast effects on top of the committed convergence result.

## Self-Check: PASSED

- Confirmed all three owned implementation/test files exist.
- Confirmed all six task commits exist in git history.
