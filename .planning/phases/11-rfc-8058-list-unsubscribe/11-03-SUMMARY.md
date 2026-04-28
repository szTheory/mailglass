---
phase: 11-rfc-8058-list-unsubscribe
plan: 03
subsystem: api
tags: [phoenix, controller, rfc8058, unsubscribe, ecto-multi, lifecycle]
requires:
  - phase: 11-rfc-8058-list-unsubscribe
    provides: unsubscribe token verification and compliance config accessors
provides:
  - core unsubscribe GET confirmation controller flow
  - idempotent unsubscribe POST event transaction with lifecycle composition
  - layout-free built-in confirmation page and controller contract tests
affects: [router-macro, generator, suppressions]
tech-stack:
  added: []
  patterns: [library-owned phoenix controller, lifecycle-before-commit multi composition, post-commit broadcast]
key-files:
  created:
    - lib/mailglass/compliance/unsubscribe_controller.ex
    - lib/mailglass/compliance/unsubscribe_html.ex
    - lib/mailglass/compliance/unsubscribe_html/confirm.html.heex
  modified:
    - lib/mailglass/compliance.ex
    - test/mailglass/compliance/unsubscribe_controller_test.exs
key-decisions:
  - "GET renders a library-owned HTML confirmation page unless `compliance.redirect` is configured."
  - "POST canonicalizes replayed `:unsubscribed` rows inside the transaction before lifecycle and broadcast handling."
  - "Lifecycle hooks compose on the in-flight `Ecto.Multi`; PubSub fan-out stays strictly post-commit."
patterns-established:
  - "Controllers that write events should use deterministic idempotency keys plus a follow-up Multi step to resolve replayed rows."
  - "Core Phoenix controllers should render their own layout-free HTML when adopter layout coupling would be unsafe."
requirements-completed: [UNSUB-03]
duration: 9min
completed: 2026-04-28
---

# Phase 11 Plan 03: Runtime Unsubscribe Controller Summary

**Core RFC 8058 unsubscribe controller with standalone GET confirmation, replay-safe POST event append, and lifecycle-aware transaction composition**

## Performance

- **Duration:** 9 min
- **Started:** 2026-04-28T09:24:00Z
- **Completed:** 2026-04-28T09:33:02Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Added `Mailglass.Compliance.UnsubscribeController` with a safe GET confirmation flow and redirect escape hatch.
- Implemented append-only, replay-safe POST unsubscribe handling with `Events.append_multi/3`, lifecycle composition, and post-commit broadcast.
- Locked the controller contract down with focused GET/POST tests covering replay, invalid/tampered/expired tokens, and the RFC 8058 no-redirect POST rule.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement GET confirmation page and redirect escape hatch** - `165cc31` (test), `d329287` (feat)
2. **Task 2: Implement idempotent POST event append with lifecycle integration** - `6ba6b61` (test), `73013b8` (feat)
3. **Task 3: Cover controller failure and replay paths** - `5a9325c` (test)

## Files Created/Modified
- `lib/mailglass/compliance/unsubscribe_controller.ex` - Core GET/POST unsubscribe controller with transaction orchestration.
- `lib/mailglass/compliance/unsubscribe_html.ex` - Template module for the built-in confirmation page.
- `lib/mailglass/compliance/unsubscribe_html/confirm.html.heex` - Library-owned standalone confirmation markup.
- `lib/mailglass/compliance.ex` - Added a small lifecycle accessor used by the controller transaction path.
- `test/mailglass/compliance/unsubscribe_controller_test.exs` - End-to-end controller contract coverage for GET, POST, replay, redirect, and failure cases.

## Decisions Made
- Used a library-owned HTML module plus HEEx template instead of adopter layouts so GET rendering stays safe in any host app.
- Resolved replayed unsubscribe inserts to the canonical stored event row inside the Multi before broadcasting, so post-commit fan-out has stable event metadata.
- Returned HTTP 200 with no redirect for POST token failures as well as success paths to match the RFC 8058 one-click contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added a minimal adjacent accessor in `Mailglass.Compliance`**
- **Found during:** Task 2 (POST transaction implementation)
- **Issue:** The controller needed the configured lifecycle module through the existing compliance seam without adding fresh config lookup patterns in the transaction code.
- **Fix:** Added `Mailglass.Compliance.configured_lifecycle/0` and used it from the controller.
- **Files modified:** `lib/mailglass/compliance.ex`, `lib/mailglass/compliance/unsubscribe_controller.ex`
- **Verification:** `mix test test/mailglass/compliance/unsubscribe_controller_test.exs`
- **Committed in:** `73013b8`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Minimal adjacent scope expansion only. No behavior drift from the plan.

## Issues Encountered

- The synthetic Phoenix test endpoint needed explicit endpoint config and ConnTest macro wiring before the RED phase pointed at controller behavior instead of harness errors.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The runtime controller contract is in place for router macro and generator work.
- Suppression/projector follow-up phases can now mount this controller without re-proving replay or lifecycle semantics.

## Self-Check: PASSED

---
*Phase: 11-rfc-8058-list-unsubscribe*
*Completed: 2026-04-28*
