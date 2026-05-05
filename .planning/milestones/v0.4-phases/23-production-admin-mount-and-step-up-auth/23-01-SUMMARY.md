---
phase: 23-production-admin-mount-and-step-up-auth
plan: "01"
subsystem: auth
tags: [phoenix, liveview, router, session, operator, preview]
requires:
  - phase: 22-operator-data-foundation
    provides: read-only operator liveview foundation
provides:
  - separate preview and operator router macros
  - distinct preview and operator live_session boundaries
  - explicit operator session whitelist callback
affects: [phase-23-auth-seam, mailglass_admin, operator-routing]
tech-stack:
  added: []
  patterns: [separate live_session surfaces, explicit session whitelists]
key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/router.ex
    - mailglass_admin/test/mailglass_admin/router_test.exs
    - mailglass_admin/test/support/endpoint_case.ex
key-decisions:
  - "Phase 23 adds a new public `mailglass_operator_routes/2` surface instead of reusing the preview macro for production operator mounting."
  - "Operator session data stays explicit via named session-key mappings rather than raw adopter session passthrough."
patterns-established:
  - "Pattern 1: preview and operator mounts get different `live_session` names and callbacks whenever their trust boundaries differ."
  - "Pattern 2: router macros may accept tuple-form LiveView hooks, but only through a narrow validated hook schema."
requirements-completed: [ADMIN-01, ADMIN-05]
duration: 25min
completed: 2026-05-01
---

# Phase 23 Plan 01: Router Boundary Summary

**Separate preview and production operator router products with explicit session whitelists and distinct LiveView auth boundaries**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-01T16:23:00Z
- **Completed:** 2026-05-01T16:48:33Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added `mailglass_operator_routes/2` so adopters can mount the operator surface without preview routes.
- Split preview and operator `live_session` callbacks into `__preview_session__/2` and `__operator_session__/2`.
- Expanded router coverage to pin the new route split and the operator session whitelist contract.

## Task Commits

No task-specific commits were created in this run. The repository already had unrelated dirty-tree changes, so the phase was executed without creating mixed-scope commits.

## Files Created/Modified
- `mailglass_admin/lib/mailglass_admin/router.ex` - added the operator macro, operator option schema, and explicit preview/operator session callbacks.
- `mailglass_admin/test/mailglass_admin/router_test.exs` - added route-split, session-whitelist, and operator opt-validation coverage.
- `mailglass_admin/test/support/endpoint_case.ex` - mounted the new `/ops/mail` test route with tuple-form auth hooks.

## Decisions Made
- Preserved `mailglass_admin_routes/2` as the preview-compatible mount and introduced `mailglass_operator_routes/2` for the production-safe operator surface.
- Required operator callers to declare a narrow `session:` mapping so only approved auth metadata crosses from `Plug.Conn` into LiveView session state.

## Deviations from Plan

None. The router split, whitelist callbacks, and tuple-form hook support landed as planned.

## Issues Encountered

Macro option validation initially rejected alias ASTs for `auth:` and tuple-form hooks. The macro now expands aliases before `NimbleOptions` validation so real adopter module references work at compile time.

## User Setup Required

Production operator adopters must now supply `auth:` and `session:` options when mounting `mailglass_operator_routes/2`.

## Next Phase Readiness

- Plan 23-02 can build directly on the operator mount hook and session whitelist already wired into the router.
- Preview routing remains isolated, so later operator auth changes do not need to revisit `/dev/mail`.

## Self-Check

PASSED

- Verified `mailglass_operator_routes/2`, `__preview_session__/2`, and `__operator_session__/2` exist.
- Verified router tests pass with the preview/operator route split.

---
*Phase: 23-production-admin-mount-and-step-up-auth*
*Completed: 2026-05-01*
