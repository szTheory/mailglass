---
phase: 112-app-shell-navigation-tenant-seam
plan: 03
subsystem: admin-shell
tags: [theme, phoenix-liveview, cookies, root-layout, url-state]

requires:
  - phase: 112-02
    provides: tenant-preserving shell URL state and operator/inbound surface paths
provides:
  - Host-scoped `mailglass_admin_theme` cookie persistence for explicit light/dark admin chrome
  - First-response root layout theme resolution from URL first, then explicit cookie
  - Mounted `/theme/:theme` persistence seam with same-mount return URL sanitization
  - Shell theme paths that preserve tenant, filters, selected ids, and current surface
affects: [phase-112, admin-shell, theme-picker, root-layout]

tech-stack:
  added: []
  patterns:
    - Explicit theme cookie values are allowlisted to light/dark; system is cookie absence.
    - Theme picker LiveView events redirect through an HTTP controller so cookies can be set before redirecting back.
    - Return paths are relative and constrained to the current mounted admin path.

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/controllers/theme_controller.ex
    - .planning/phases/112-app-shell-navigation-tenant-seam/112-03-SUMMARY.md
  modified:
    - mailglass_admin/lib/mailglass_admin/mount_path_hook.ex
    - mailglass_admin/lib/mailglass_admin/layouts.ex
    - mailglass_admin/lib/mailglass_admin/router.ex
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
    - mailglass_admin/test/mailglass_admin/router_test.exs

key-decisions:
  - "Use `mailglass_admin_theme` as the namespaced explicit-theme cookie."
  - "Store only `light` and `dark`; `system` deletes the cookie and never emits `data-theme=\"system\"`."
  - "Theme picker events use a mounted HTTP seam because LiveView patches cannot set response cookies."

patterns-established:
  - "Root theme resolution order is URL theme param, explicit cookie, then nil/system."
  - "Theme persistence paths keep URL state in a sanitized `return_to` value with the stale `theme` key removed."

requirements-completed: [SHELL-03, SHELL-04]

duration: 12min
completed: 2026-06-19
status: complete
---

# Phase 112 Plan 03: Theme Persistence Summary

**Tri-state admin theme picker now persists explicit light/dark choices in a host-scoped cookie and renders first-paint root theme without treating system as a concrete theme.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-19T20:56:00Z
- **Completed:** 2026-06-19T21:01:00Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added RED tests for cookie-driven first paint, system/no-root-theme behavior, invalid cookie fallback, URL precedence, mounted route coverage, and theme path URL-state preservation.
- Added `MailglassAdmin.Controllers.ThemeController` and mounted `/theme/:theme` routes for preview/operator admin mounts.
- Threaded the explicit theme cookie through router session callbacks, `MountPathHook`, and `Layouts.root_theme/1`.
- Updated shell theme helpers and LiveView theme events to use the HTTP persistence seam while preserving tenant/filter/surface URL state.

## Task Commits

1. **Task 1: Add no-FOUC theme persistence tests** - `3df2723c` (test)
2. **Task 2: Implement namespaced theme cookie root seam** - `d5418f21` (feat)
3. **Task 3: Wire shell theme paths to persistence while preserving URL state** - `f4337ef3` (feat)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/controllers/theme_controller.ex` - Sets/deletes the namespaced explicit-theme cookie and sanitizes mounted return paths.
- `mailglass_admin/lib/mailglass_admin/mount_path_hook.ex` - Resolves root theme from URL first, then explicit cookie, then nil/system.
- `mailglass_admin/lib/mailglass_admin/layouts.ex` - Reads request cookie on disconnected first render.
- `mailglass_admin/lib/mailglass_admin/router.ex` - Mounts theme persistence routes and whitelists the theme cookie into LiveView session data.
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` - Builds mounted persistence paths with `return_to` preserving URL state.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - Redirects theme picker events through the persistence seam.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - Redirects theme picker events through the persistence seam.
- `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` - Covers shell theme persistence paths and mounted path derivation.
- `mailglass_admin/test/mailglass_admin/router_test.exs` - Covers cookie set/delete, root first paint, query precedence, invalid cookie fallback, and return URL rejection.

## Decisions Made

- `mailglass_admin_theme` is host-scoped by omission of a `domain` cookie option and path-scoped to the current admin mount.
- `system` is absence of explicit state: the controller deletes the cookie, helper paths strip stale `theme`, and the root layout emits no `data-theme`.
- Theme picker events use full LiveView redirects to a controller route because response cookies cannot be set by a `push_patch`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated session whitelist tests for the new explicit cookie key**
- **Found during:** Task 2
- **Issue:** Existing router session tests asserted an exact key list that predated the planned theme cookie session key.
- **Fix:** Updated expectations to include `admin_chrome_theme_cookie` while still rejecting adopter session pass-through.
- **Files modified:** `mailglass_admin/test/mailglass_admin/router_test.exs`
- **Verification:** Package-local focused suite passed.
- **Committed in:** `d5418f21`

**2. [Rule 3 - Blocking] Redirected LiveView theme events through the HTTP seam**
- **Found during:** Task 3
- **Issue:** The shell helper now returns a controller route; leaving `push_patch` in the LiveViews would route a LiveView patch to a non-LiveView endpoint.
- **Fix:** Switched operator and inbound `set_theme`/`toggle_theme` events to `redirect/2`.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound_live.ex`
- **Verification:** Operator and inbound LiveView suites passed.
- **Committed in:** `f4337ef3`

**Total deviations:** 2 auto-fixed (Rule 1: 1, Rule 3: 1)
**Impact on plan:** Both fixes were required for the planned persistence seam to work without widening auth, storage, or theme scope.

## Issues Encountered

- The plan's literal root command still fails before assertions because root Mix does not load `mailglass_admin/test/support/*` modules (`MailglassAdmin.LiveViewCase`, `MailglassAdmin.EndpointCase`). This is the same package-local verification constraint documented in 112-02.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. Stub-pattern scan only found existing test assigns, nil assertions, and comments; no new placeholder UI data was introduced.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: redirect-return-path | `mailglass_admin/lib/mailglass_admin/controllers/theme_controller.ex` | Added a theme-setting HTTP seam that redirects back to the current admin surface; return paths are restricted to relative same-mount paths and external/protocol-relative URLs fall back to the mount root. |
| threat_flag: preference-cookie | `mailglass_admin/lib/mailglass_admin/controllers/theme_controller.ex` | Added a non-auth visual preference cookie; values are allowlisted to `light`/`dark`, invalid values are ignored, and `system` deletes the cookie. |

## Verification

- RED: `cd mailglass_admin && mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/router_test.exs --warnings-as-errors` failed with missing `/theme/:theme` route, absent cookie first-paint behavior, and old shell theme paths.
- GREEN: `cd mailglass_admin && mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/router_test.exs --warnings-as-errors` passed: 35 tests, 0 failures.
- Supporting: `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` passed: 88 tests, 0 failures.
- Literal root command attempted: `mix test mailglass_admin/test/mailglass_admin/operator/shell_test.exs mailglass_admin/test/mailglass_admin/router_test.exs --warnings-as-errors` failed before assertions because admin test support modules are not loaded in the root Mix context.

## Next Phase Readiness

SHELL-04 is complete for explicit theme persistence and first-paint root rendering. Later Phase 112 plans can continue strengthening navigation and pagination without changing the Phase 110 primitive API or introducing a concrete system theme.

## Self-Check: PASSED

- Created/modified files exist on disk.
- Task commits `3df2723c`, `d5418f21`, and `f4337ef3` exist in git history.
- Package-local focused and affected LiveView verification passed.

---
*Phase: 112-app-shell-navigation-tenant-seam*
*Completed: 2026-06-19*
