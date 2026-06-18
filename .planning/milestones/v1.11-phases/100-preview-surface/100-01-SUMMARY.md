---
phase: 100-preview-surface
plan: 01
subsystem: ui
tags: [phoenix-liveview, preview, theme, accessibility]
requires:
  - phase: 97-cross-surface-component-layer
    provides: settled Preview Sidebar, DeviceFrame, and Tabs components
provides:
  - URL-owned Preview admin chrome theme state
  - Independent preview-frame theme state and DOM marker
  - Root layout theme helper that only honors explicit theme query params
affects: [preview-surface, phase-100, PAGE-03]
tech-stack:
  added: []
  patterns: [explicit URL theme parsing, separate admin/frame theme assigns]
key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/lib/mailglass_admin/layouts.ex
    - mailglass_admin/lib/mailglass_admin/layouts/root.html.heex
    - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
    - mailglass_admin/lib/mailglass_admin/preview/tabs.ex
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs
key-decisions:
  - "Preview admin chrome theme is explicit URL state and absent theme remains nil."
  - "Preview-frame dark chrome is local pane state and does not patch the URL."
patterns-established:
  - "Preview links append theme only when admin_chrome_theme is explicitly :dark or :light."
requirements-completed: [PAGE-03]
duration: 11 min
completed: 2026-06-15
---

# Phase 100 Plan 01: Preview Theme Ownership Summary

**Preview admin chrome now follows explicit URL theme state while the previewed Message frame has a separate local theme marker.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-06-15T21:06:42Z
- **Completed:** 2026-06-15T21:15:24Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Split Preview theme ownership into `admin_chrome_theme` URL state and `preview_frame_dark_chrome` pane state.
- Updated the root layout to omit `data-theme` unless the request has an explicit supported `theme` query param.
- Added focused LiveView regressions for explicit dark/light routes, absent-theme behavior, independent frame toggling, and sidebar theme-link preservation.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Theme ownership coverage** - `e87b0815` (test)
2. **Task 1 GREEN: Explicit admin chrome theme** - `e13d4897` (feat)
3. **Task 2: Theme independence regressions** - `f8694024` (test)

**Plan metadata:** committed separately with this summary.

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/preview_live.ex` - Owns Preview shell theme, URL parsing, admin theme toggle, and preview-frame toggle.
- `mailglass_admin/lib/mailglass_admin/layouts.ex` - Adds `root_theme/1` for explicit query-param theme handling.
- `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` - Uses `root_theme(assigns)` instead of a forced light/dark fallback.
- `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` - Preserves explicit admin chrome theme in scenario links without inventing `theme=light`.
- `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` - Emits `data-preview-frame-theme` on the active pane wrapper.
- `mailglass_admin/test/mailglass_admin/preview_live_test.exs` - Covers the split theme contract.

## Decisions Made

- Invalid or absent Preview theme params map to `nil`, not light, so daisyUI/root preference is not overridden.
- The admin chrome toggle reuses `MailglassAdmin.Operator.Shell.toggle_theme_path/2`; query param ordering follows that shared helper.
- Sidebar keeps its legacy `dark_chrome` attr for compatibility but Preview route links are now driven by explicit `admin_chrome_theme`.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** None.

## Issues Encountered

- Existing tests expected invalid theme params to force light and expected a specific query-param ordering. Updated those assertions to match the new explicit-theme contract and shared toggle helper behavior.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 100-02 responsive Preview shell composition. The shell now exposes stable `preview-shell` and split theme state needed for page-level IA and browser proof.

---
*Phase: 100-preview-surface*
*Completed: 2026-06-15*
