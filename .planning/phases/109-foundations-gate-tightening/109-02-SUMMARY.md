---
phase: 109-foundations-gate-tightening
plan: "02"
subsystem: ui
tags: [tailwind, daisyui, phoenix-liveview, design-system, accessibility]
requires:
  - phase: 109-01
    provides: "PR #86 merged baseline for overlapping admin shell and preview files"
provides:
  - "Semantic z-index layer utilities for base, dropdown, overlay scrim, overlay panel, and toast"
  - "Semantic overlay scrim, focus-ring, inset focus-ring, and admin-root isolation utilities"
  - "Migrated modal, toast, shell, preview, sidebar, tab, gallery, and delivery-row consumers"
  - "Rebuilt committed admin CSS bundle"
affects: [phase-109, phase-110, mailglass_admin, admin-design-system]
tech-stack:
  added: []
  patterns:
    - "Semantic admin layer utilities in app.css"
    - "Reusable mg-focus-ring and mg-focus-ring-inset focus contract"
    - "Host-safe mg-admin-root isolation class"
key-files:
  created: []
  modified:
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
    - mailglass_admin/lib/mailglass_admin/preview/tabs.ex
    - mailglass_admin/priv/static/app.css
key-decisions:
  - "Overlay scrim color is derived from `--color-base-content` via `color-mix`, keeping color ownership in daisyUI semantic variables."
  - "Offset focus rings use `.mg-focus-ring`; delivery rows and tabs use `.mg-focus-ring-inset` where offset rings would clip."
  - "`h-[600px]` preview panes moved to standard 4px-grid `h-150` rather than a new token or arbitrary utility."
patterns-established:
  - "HEEx stacking contexts consume `.mg-layer-*` instead of literal numeric `z-*` classes."
  - "Admin mount roots use `.mg-admin-root` for isolated stacking contexts."
  - "Focus styling is centralized in CSS utilities before the hard FOCUS-RING gate is added."
requirements-completed: [FND-01, FND-02, FND-03, FND-04]
duration: 5 min
completed: 2026-06-18
status: complete
---

# Phase 109 Plan 02: Semantic Token/Class Consolidation Summary

**Admin z layers, overlay scrims, focus rings, and root isolation now use semantic utilities backed by the committed static CSS bundle.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-18T17:00:45Z
- **Completed:** 2026-06-18T17:05:59Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Added `--z-base`, `--z-overlay-scrim`, `--z-overlay-panel`, compatibility aliases, and `.mg-layer-*` utilities in the existing `app.css` token source.
- Added `.mg-overlay-scrim`, `.mg-focus-ring`, `.mg-focus-ring-inset`, and `.mg-admin-root` without new raw color literals or JS theme hooks.
- Migrated replay modal scrims/panels, flash toast, operator shell root, and preview shell root to semantic utility classes.
- Replaced copied focus-ring idioms across operator shell, delivery rows, gallery nav specimens, preview controls, sidebar controls, and preview tabs.
- Rebuilt and committed `mailglass_admin/priv/static/app.css`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add semantic layer, overlay, focus, and isolation utilities** - `23406908` (feat)
2. **Task 2: Migrate stacking contexts and admin roots to semantic utilities** - `b0652da0` (refactor)
3. **Task 3: Consolidate focus-ring consumers and rebuild the CSS bundle** - `221f14a2` (refactor)

**Plan metadata:** this summary commit

## Files Created/Modified

- `mailglass_admin/assets/css/app.css` - Defines z-layer, overlay, focus-ring, and admin-root semantic utilities.
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` - Uses scrim/panel semantic layers.
- `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` - Uses scrim/panel semantic layers.
- `mailglass_admin/lib/mailglass_admin/components.ex` - Flash toast uses the toast layer utility.
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` - Operator root uses admin isolation; nav links use semantic focus rings.
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` - Delivery row focus uses inset semantic focus utility.
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` - Copied nav specimens use semantic focus rings.
- `mailglass_admin/lib/mailglass_admin/preview_live.ex` - Preview root and controls use semantic utilities; raw `border-2` removed.
- `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` - Sidebar controls use semantic focus rings.
- `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` - Tabs use inset semantic focus rings; preview panes use `h-150`.
- `mailglass_admin/priv/static/app.css` - Rebuilt committed CSS bundle.

## Decisions Made

- `.mg-overlay-scrim` derives from `--color-base-content` with `color-mix`, preserving the "color only in daisyUI theme blocks" rule.
- `.mg-focus-ring-inset` is limited to row/tab controls where the existing implementation intentionally used inset rings to avoid clipping.
- Preview pane height uses `h-150`, which is the Tailwind v4 spacing grid equivalent of the prior 600px height without arbitrary bracket syntax.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** None.

## Issues Encountered

None. `mix verify.support_contract.admin` emitted expected optional Oban warnings only; all tests passed.

## User Setup Required

None - no external service configuration required.

## Verification

- `rg -n -- '--z-base|--z-overlay-scrim|--z-overlay-panel|\\.mg-layer-overlay-scrim|\\.mg-layer-overlay-panel|\\.mg-focus-ring|\\.mg-admin-root' mailglass_admin/assets/css/app.css` -> required tokens/classes found.
- `bash mailglass_admin/scripts/check-conformance.sh` -> `OK: design-system conformance clean.`
- `cd mailglass_admin && mix mailglass_admin.assets.build` -> success.
- `test "$(rg -n 'focus-visible:ring-2 focus-visible:ring-primary|focus:outline|focus:outline-2|focus:outline-primary' mailglass_admin/lib/mailglass_admin | wc -l | tr -d ' ')" = "0"` -> passed.
- `test "$(rg -n '\\bborder-(0|2|4|8|\\[[^]]+\\])\\b|\\b(?:w|h|min-w|max-w|min-h|max-h)-\\[[^]]+\\]' mailglass_admin/lib/mailglass_admin/preview_live.ex mailglass_admin/lib/mailglass_admin/preview/tabs.ex | wc -l | tr -d ' ')" = "0"` -> passed.
- `cd mailglass_admin && mix verify.support_contract.admin` -> 59 tests, 0 failures.
- `cd mailglass_admin && git diff --exit-code priv/static/` after rebuild -> passed.

## Self-Check: PASSED

All Plan 109-02 tasks completed, task commits are present, the semantic utilities are defined and consumed, raw focus-ring copies are gone, no JS theme hook or picker UI was introduced, and the static CSS bundle is rebuilt and committed.

## Next Phase Readiness

Ready for Plan 109-03 to add hard conformance gates and ratchet schema v3 on top of the now-clean codebase.

---
*Phase: 109-foundations-gate-tightening*
*Completed: 2026-06-18*
