---
phase: 23-production-admin-mount-and-step-up-auth
plan: "02"
subsystem: auth
tags: [liveview, auth, operator, recent-auth, phoenix]
requires:
  - phase: 23-production-admin-mount-and-step-up-auth
    provides: operator route and session boundary
provides:
  - generic MailglassAdmin auth behaviour
  - operator on_mount authorization seam
  - auth-aware operator liveview assigns
affects: [phase-24-replay, operator-liveview, recent-auth]
tech-stack:
  added: []
  patterns: [stack-agnostic auth adapter, mount-time operator authorization]
key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/auth.ex
    - mailglass_admin/lib/mailglass_admin/operator/mount.ex
    - mailglass_admin/test/mailglass_admin/auth_test.exs
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/test/support/endpoint_case.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
key-decisions:
  - "Authorization stays adopter-owned through a behaviour module passed to the router instead of a hard dependency on any auth stack."
  - "Operator mount denial uses redirect-based halting so unauthorized access fails predictably before the LiveView renders."
patterns-established:
  - "Pattern 1: normalize actor metadata once in `MailglassAdmin.Auth` so later destructive handlers call one server-side contract."
  - "Pattern 2: assign operator auth context at mount time and keep later LiveView actions read-only until mutation phases land."
requirements-completed: [ADMIN-01, ADMIN-05]
duration: 28min
completed: 2026-05-01
---

# Phase 23 Plan 02: Auth Seam Summary

**Adopter-owned operator authorization contract with normalized actor metadata and a dedicated operator mount hook**

## Performance

- **Duration:** 28 min
- **Started:** 2026-05-01T16:28:00Z
- **Completed:** 2026-05-01T16:48:33Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added `MailglassAdmin.Auth` as the stack-agnostic authorization behaviour and normalization layer.
- Added `MailglassAdmin.Operator.Mount` to enforce operator access before the LiveView renders.
- Wired `OperatorLive` and the shared test router to carry actor and recent-auth context without adding destructive controls.

## Task Commits

No task-specific commits were created in this run. The repository already had unrelated dirty-tree changes, so the phase was executed without creating mixed-scope commits.

## Files Created/Modified
- `mailglass_admin/lib/mailglass_admin/auth.ex` - behavior and normalization helpers for `:operator_access` and future `:destructive_action` checks.
- `mailglass_admin/lib/mailglass_admin/operator/mount.ex` - internal on-mount authorization gate with redirect-based denial handling.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - stable auth-related assigns for future operator actions.
- `mailglass_admin/test/mailglass_admin/auth_test.exs` - contract tests for authorized, unauthorized, and stale-auth outcomes.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - authorized and unauthorized operator mount coverage on the new `/ops/mail` route.
- `mailglass_admin/test/support/endpoint_case.ex` - test auth adapter and hook wiring for the synthetic adopter router.

## Decisions Made
- Kept the auth seam behavior-based and runtime-passed through `auth:` so the library stays decoupled from `Sigra`, `phx.gen.auth`, and app-specific modules.
- Normalized `recent_auth_at` inside the library so later mutation handlers can rely on `DateTime` values instead of app-specific serialization.

## Deviations from Plan

None. The plan called for an auth seam, operator mount hook, and read-only non-regression wiring, and all three landed directly.

## Issues Encountered

`function_exported?/3` alone was not enough for test-only auth modules compiled onto the code path but not yet loaded. `MailglassAdmin.Auth.authorize/3` now uses `Code.ensure_loaded?/1` before checking `authorize/2`.

## User Setup Required

Adopters mounting the production operator surface must provide a module that implements `MailglassAdmin.Auth.authorize/2`.

## Next Phase Readiness

- Phase 24 can call the same auth seam for replay and suppression-removal authorization instead of inventing per-action checks.
- The operator LiveView already carries normalized actor and recent-auth state for audit-aware mutations.

## Self-Check

PASSED

- Verified auth contract tests pass for `:unauthorized` and `:stale_auth`.
- Verified unauthorized operator mounts redirect before the LiveView renders.

---
*Phase: 23-production-admin-mount-and-step-up-auth*
*Completed: 2026-05-01*
