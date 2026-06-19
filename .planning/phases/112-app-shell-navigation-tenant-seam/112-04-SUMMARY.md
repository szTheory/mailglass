---
phase: 112-app-shell-navigation-tenant-seam
plan: 04
subsystem: admin-shell
tags: [navigation, accessibility, phoenix-liveview, tailwind, mailglass-admin]

requires:
  - phase: 112-03
    provides: theme-persistent shell paths and shared shell chrome wiring
provides:
  - Shared desktop and mobile active nav cues with aria-current and structural borders
  - Component tests preventing color-only active nav regressions
  - Shell tests proving desktop nav_link and mobile nav_pill current cues render through shared primitives
affects: [phase-112, admin-shell, navigation-primitives, final-browser-proof]

tech-stack:
  added: []
  patterns:
    - Active nav state combines aria-current, bold text, and tokenized border geometry.
    - Mobile nav pills reserve transparent border geometry for inactive/disabled states to avoid layout shift.

key-files:
  created:
    - .planning/phases/112-app-shell-navigation-tenant-seam/112-04-SUMMARY.md
  modified:
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/test/mailglass_admin/components_test.exs
    - mailglass_admin/test/mailglass_admin/operator/shell_test.exs

key-decisions:
  - "Use `border-b-2 border-primary` as the mobile nav_pill structural active cue, matching desktop nav_link's existing border-left pattern."
  - "Do not commit a rebuilt CSS bundle because the required border utilities were already present in `priv/static/app.css`; the transient rebuild diff came from unrelated dirty-tree source."

patterns-established:
  - "Component active-nav tests must assert structural border tokens, not only color/background or aria-current."
  - "Shell current-nav tests inspect aria-current nodes for both desktop and mobile primitive class contracts."

requirements-completed: [SHELL-05]

duration: 12min
completed: 2026-06-19
status: complete
---

# Phase 112 Plan 04: Active Navigation Cue Summary

**Shared desktop and mobile nav primitives now expose active state through aria-current, bold text, and visible border geometry rather than color alone.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-19T20:53:00Z
- **Completed:** 2026-06-19T21:05:02Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added failing component and shell tests for structural active-nav cues.
- Updated `Components.nav_pill/1` so active mobile nav uses `border-b-2 border-primary` plus bold text and `aria-current="page"`.
- Preserved `min-h-11`, `mg-focus-ring`, disabled inert semantics, and shared primitive ownership.
- Rebuilt the CSS bundle to check generated output, then restored it because the required utilities were already present in the committed bundle.

## Task Commits

1. **Task 1: Add active nav non-color cue tests** - `5b5e9755` (test)
2. **Task 2: Update shared nav primitives and compiled CSS** - `08b25b64` (feat)

## Files Created/Modified

- `mailglass_admin/test/mailglass_admin/components_test.exs` - Requires active nav primitives to expose structural border cues and prevents inactive items from carrying active tokens.
- `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` - Verifies shell-rendered current nav items include desktop border-left and mobile border-bottom cues from shared primitives.
- `mailglass_admin/lib/mailglass_admin/components.ex` - Adds mobile nav pill border geometry and active/inactive border token classes.

## Decisions Made

- Mobile active nav uses a bottom border, not a local marker element, keeping the cue inside `Components.nav_pill/1`.
- Inactive and disabled nav pills keep transparent border geometry so the active border does not resize the header.
- No `priv/static/app.css` commit was needed: `border-b-2`, `border-primary`, and `border-transparent` were already present. The transient rebuild introduced an unrelated `hover:border-primary` utility from the current dirty worktree, so it was not committed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The literal root command from the plan still fails before assertions because root Mix does not load `mailglass_admin/test/support` modules (`MailglassAdmin.LiveViewCase`). This matches the package-local verification constraint documented in 112-02 and 112-03. The package-local equivalent passed.
- `mix mailglass_admin.assets.build` produced a transient `priv/static/app.css` diff unrelated to this plan's class additions; it was restored after confirming the required utilities already exist in the committed bundle.

## Verification

- RED: `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs --warnings-as-errors` failed with 2 expected failures for missing mobile `border-b-2`.
- GREEN: `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs --warnings-as-errors` passed: 96 tests, 0 failures.
- CSS build check: `cd mailglass_admin && mix mailglass_admin.assets.build` completed successfully.
- Final gate: `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs --warnings-as-errors && ./scripts/check-conformance.sh && git diff --exit-code priv/static/app.css` passed.
- Literal root command attempted: `mix test mailglass_admin/test/mailglass_admin/components_test.exs mailglass_admin/test/mailglass_admin/operator/shell_test.exs --warnings-as-errors` failed before assertions due missing `MailglassAdmin.LiveViewCase` in root test support.

## Known Stubs

None. Stub-pattern scan found only existing form empty-option handling, `nil` assertions, and placeholder as an allowed HTML attribute name; no new placeholder UI data was introduced.

## Threat Flags

None. This plan changed visual/ARIA nav state only and introduced no new network endpoints, auth paths, file access, schema changes, or trust-boundary data flow.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

SHELL-05 is satisfied at component and shell-test levels. Plan 112-06 can perform the planned browser-level structural geometry proof using the same shared primitive cues.

## Self-Check: PASSED

- Created/modified files exist on disk: `.planning/phases/112-app-shell-navigation-tenant-seam/112-04-SUMMARY.md`, `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/test/mailglass_admin/components_test.exs`, `mailglass_admin/test/mailglass_admin/operator/shell_test.exs`.
- Task commits exist in git history: `5b5e9755`, `08b25b64`.
- Final package-local verification and conformance gates passed.

---
*Phase: 112-app-shell-navigation-tenant-seam*
*Completed: 2026-06-19*
