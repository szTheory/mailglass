---
phase: 97-cross-surface-component-layer
plan: 03
subsystem: ui
tags: [phoenix, liveview, accessibility, wcag, aria, heex, operator]

# Dependency graph
requires:
  - phase: 97-cross-surface-component-layer
    provides: "97-PATTERNS.md replay_modal a11y pattern and 97-UI-SPEC accessibility contract"
provides:
  - "WCAG 2.1 Level AA compliant replay_modal dialog with aria-labelledby, keyboard dismiss, focus trap"
  - "JS focus management (focus_first on open, focus return on close) via Phoenix.LiveView.JS in operator_live"
  - "COPY-LD-13 sub-copy applied to replay modal"
  - "text-heading token replacing banned text-lg on replay modal h2"
affects:
  - "97-04 and later plans that uplift other operator components"
  - "Phase 98 operator surface uplift"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "phx-mounted=JS.focus_first + phx-remove=JS.focus on :if conditional span for assign-based modal focus trap"
    - "id on trigger button (replay-open-btn) as focus return target"
    - "phx-key=Escape + phx-window-keydown for keyboard modal dismiss"
    - "aria-labelledby linking role=dialog to h2 id"

key-files:
  created: []
  modified:
    - "mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex"
    - "mailglass_admin/lib/mailglass_admin/operator_live.ex"
    - "mailglass_admin/lib/mailglass_admin/operator/detail_header.ex"

key-decisions:
  - "Focus trap for assign-based (not JS.show) modal uses phx-mounted/phx-remove on a :if conditional span element in operator_live.ex render template"
  - "id=replay-open-btn added to detail_header trigger button as JS.focus return target"
  - "Phoenix.LiveView.JS aliased in operator_live.ex for focus commands"

patterns-established:
  - "Assign-based modal focus trap: :if conditional span with phx-mounted=JS.focus_first + phx-remove=JS.focus in parent LiveView template"

requirements-completed:
  - COMP-02

# Metrics
duration: 4min
completed: 2026-06-14
---

# Phase 97 Plan 03: Replay Modal WCAG A11y Summary

**WCAG 2.1 Level AA modal compliance: aria-labelledby + Escape keyboard dismiss + JS focus trap wired in operator_live, COPY-LD-13 sub-copy applied**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-06-14T16:03:26Z
- **Completed:** 2026-06-14T16:07:12Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `aria-labelledby="replay-modal-title"`, `phx-key="Escape"`, `phx-window-keydown="close_replay"` to `role="dialog"` div
- Added `id="replay-modal-title"` to h2 and replaced banned `text-lg` with `text-heading` token
- Replaced sub-copy with COPY-LD-13 string ("Re-dispatches the stored webhook request through Mailbox routing...")
- Wired JS focus trap in `operator_live.ex` via `:if` conditional span using `phx-mounted=JS.focus_first` and `phx-remove=JS.focus`
- Added `id="replay-open-btn"` to the replay trigger button in `detail_header.ex` as focus return target

## Task Commits

Each task was committed atomically:

1. **Task 1: Add aria-labelledby, Escape dismiss, h2 id + typography, COPY-LD-13** - `060c7a7b` (feat)
2. **Task 2: Wire JS.focus_first / JS.focus focus-trap in parent LiveView** - `f7bcf2f2` (feat)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` - Added WCAG aria attrs, keyboard dismiss, text-heading token, COPY-LD-13 copy
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - Aliased Phoenix.LiveView.JS; added :if span with phx-mounted/phx-remove focus commands
- `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` - Added id="replay-open-btn" to replay trigger button

## Decisions Made

- **Focus trap pattern for assign-controlled modal:** Since the modal is controlled by a server-side socket assign (not `JS.show/hide`), the focus trap is wired via a `:if` conditional `<span>` in `operator_live.ex`'s render template. `phx-mounted` fires `JS.focus_first(to: "#operator-replay-modal")` when the span mounts (modal opens); `phx-remove` fires `JS.focus(to: "#replay-open-btn")` when the span is removed (modal closes). This is the idiomatic LiveView.JS pattern for assign-based conditional rendering — no client JS hook needed.
- **Trigger button id:** Added `id="replay-open-btn"` to the replay open button in `detail_header.ex` so the `JS.focus` return target resolves. The `data-testid="operator-replay-open"` is preserved alongside the new id.

## Deviations from Plan

None — plan executed exactly as written. The plan anticipated assign-based control and provided the correct LiveView.JS fallback pattern. The `phx-mounted`/`phx-remove` approach on a `:if` span in the parent LiveView template was chosen as the no-hook implementation.

## Issues Encountered

None. `mix compile --warnings-as-errors` clean on first attempt.

## Threat Surface Scan

No new security surface introduced. T-97-03-01 verified: `close_replay` handle_event (operator_live.ex:177-178) only calls `close_replay_modal/1` which sets assigns — it does not call the replay dispatch function. The replay dispatch is exclusively in `confirm_replay` handler.

## Known Stubs

None — all changes are complete implementations with no placeholder values.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- replay_modal is now WCAG 2.1 Level AA compliant (COMP-02 satisfied)
- Focus trap and keyboard dismiss are both wired and compile-clean
- Ready for Phase 97 Plan 04+ to continue other component uplifts

---
*Phase: 97-cross-surface-component-layer*
*Completed: 2026-06-14*
