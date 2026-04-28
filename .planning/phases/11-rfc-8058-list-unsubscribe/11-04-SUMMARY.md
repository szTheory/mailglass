---
phase: 11-rfc-8058-list-unsubscribe
plan: 04
subsystem: api
tags: [phoenix, router, unsubscribe, rfc-8058, testing]
requires:
  - phase: 11-01
    provides: unsubscribe config accessors and URL builder
  - phase: 11-03
    provides: unsubscribe controller endpoints mounted by the router macro
provides:
  - Mailglass.Router macro for unsubscribe route mounting
  - compile-time GET/POST collision detection against :phoenix_routes
  - route-reflection tests for helper naming and URL-path consistency
affects: [phase-11-05, phase-11-06, unsubscribe-guides, adopter-router-integration]
tech-stack:
  added: []
  patterns: [phoenix-router-macro, nimble-options-validation, compile-time-route-collision-check]
key-files:
  created: [lib/mailglass/router.ex, test/mailglass/router/unsubscribe_router_test.exs]
  modified: [lib/mailglass/router.ex, test/mailglass/router/unsubscribe_router_test.exs]
key-decisions:
  - "Expose unsubscribe mounting through Mailglass.Router with a default helper prefix of :mailglass_unsubscribe."
  - "Read the default mount path through Mailglass.Config.compliance_mount_path/0 and fail compilation when the mounted public path diverges."
  - "Detect collisions by checking the caller module's accumulated :phoenix_routes before injecting GET and POST unsubscribe routes."
patterns-established:
  - "Router macros use NimbleOptions validation and quote bind_quoted for public mount contracts."
  - "Compile-string router tests should verify both __routes__/0 reflection and compile-time failure messaging."
requirements-completed: [UNSUB-04]
duration: 7 min
completed: 2026-04-28
---

# Phase 11 Plan 04: Unsubscribe Router Summary

**Mailglass.Router now mounts deterministic unsubscribe GET and POST routes with compile-time collision protection and route-reflection coverage.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-28T09:35:00Z
- **Completed:** 2026-04-28T09:41:54Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `mailglass_router_routes/2` as the core unsubscribe router macro with option validation and config-path alignment.
- Made route shadowing load-bearing by raising when earlier GET or POST routes already occupy the unsubscribe path.
- Expanded the router test suite to lock helper naming, `:phoenix_routes`-backed failure behavior, and `Unsubscribe.unsubscribe_url/2` path consistency.

## Task Commits

1. **Task 1 RED: failing unsubscribe router contract tests** - `528bb2b` (`test`)
2. **Task 1 GREEN: unsubscribe router macro implementation** - `5eb3461` (`feat`)
3. **Task 2: expanded route-reflection coverage** - `0ae3d07` (`test`)

## Files Created/Modified
- `lib/mailglass/router.ex` - Public unsubscribe router macro with NimbleOptions validation and compile-time collision checks.
- `test/mailglass/router/unsubscribe_router_test.exs` - Macro-contract, helper-prefix, collision, and URL-path consistency tests.

## Decisions Made
- Used `Mailglass.Router.__ensure_route_available__/3` inside the quoted router body so collision checks read the caller module's live `:phoenix_routes` attribute at mount time.
- Kept the public contract strict: the default mount must match `Mailglass.Config.compliance_mount_path/0`, while `:mount_path` remains an explicit test-only override.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `11-05`: the core router contract is now stable enough for generator output and adopter mount instructions to target `import Mailglass.Router` plus `mailglass_router_routes "/mailglass"`.

## Self-Check

PASSED
