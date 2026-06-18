---
phase: 107-inbound-replay-modal-a11y-parity-wr-03
plan: "01"
subsystem: ui
tags: [liveview, accessibility, playwright, inbound, focus-management, a11y]

requires:
  - phase: 106-inbound-replay-modal-parity
    provides: "inbound replay modal component (MailglassAdmin.Inbound.ReplayModal) and close_replay handler in inbound_live.ex"

provides:
  - "Escape-to-close wiring on inbound replay modal via phx-key/phx-window-keydown"
  - "Real id attributes on inbound dialog div (#inbound-replay-modal) and trigger button (#inbound-replay-open-btn)"
  - "Focus-management sibling span in inbound_live.ex (phx-mounted focus-on-open, phx-remove return-focus-on-close)"
  - "Structural Playwright assertion proving role/aria + Escape attributes and Escape-closes behavior"
  - "Verified-clean priv/static/ admin CSS bundle (attributes-only change, no new Tailwind classes)"

affects:
  - "any future inbound modal work touching replay_modal.ex or inbound_live.ex"
  - "future a11y / keyboard navigation phases on the admin LiveView"

tech-stack:
  added: []
  patterns:
    - "Focus-management parity pattern: sibling <span> with :if conditional + phx-mounted/phx-remove JS commands mirrors operator_live.ex"
    - "Escape-to-close via phx-key + phx-window-keydown routes to existing event handler, no new server event"
    - "Structural Playwright assertion using getAttribute to validate LiveView binding attributes at runtime"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/e2e/structural.spec.js

key-decisions:
  - "Added real id= on inbound dialog div (intentional divergence from operator modal which has the D-04 latent bug) so focus-first selector resolves correctly"
  - "Focus span uses phx-mounted/phx-remove — pure LiveView JS, no phx-hook, no Tab-cycle focus trap per D-06 posture"
  - "Test framed as focus-management parity (not WCAG conformance) per D-07; no WCAG or focus-trap language in code or test"

patterns-established:
  - "Parity port pattern: add real id to fix D-04 latent bug on inbound without touching operator (D-05)"
  - "Playwright attribute assertion idiom: getAttribute on phx-* bindings verifies LiveView wiring at runtime"

requirements-completed: [A11Y-01]

duration: 2min
completed: 2026-06-17
---

# Phase 107 Plan 01: Inbound Replay Modal Focus-Management Parity Summary

**Escape-to-close + focus-on-open/return-focus-on-close ported to the inbound replay modal using pure LiveView JS commands (phx-key, phx-window-keydown, focus span), with real id attributes on dialog and trigger, and a structural Playwright assertion proving the contract.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-17T17:28:11Z
- **Completed:** 2026-06-17T17:30:48Z
- **Tasks:** 3 of 3
- **Files modified:** 4

## Accomplishments

- Added `id="inbound-replay-modal"`, `phx-key="Escape"`, and `phx-window-keydown="close_replay"` to the inbound dialog div — Escape now routes to the existing `close_replay` handler
- Added `id="inbound-replay-open-btn"` to the replay trigger button in `detail_header.ex` so the focus-return selector resolves
- Inserted focus-management sibling span immediately before `ReplayModal.replay_modal` in `inbound_live.ex` — `phx-mounted` focuses the modal on open; `phx-remove` returns focus to the trigger on close
- Structural Playwright assertion added inside the inbound describe block, proving role/aria attributes, phx-window-keydown, phx-key, and Escape-closes behavior using getAttribute/keyboard idioms (not pixel snapshots)
- Admin CSS bundle verified clean after `mix mailglass_admin.assets.build` — attributes-only change introduced no new Tailwind classes

## Task Commits

1. **Task 1: Wire Escape-to-close + real ids** - `8feb0b1d` (feat)
2. **Task 2: Add focus-management sibling span to inbound_live.ex** - `b9bfbfd5` (feat)
3. **Task 3: Structural Playwright assertion + bundle-clean verify** - `9006edad` (test)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` — Added id, phx-key, phx-window-keydown to dialog div
- `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex` — Added id to replay trigger button
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` — Inserted focus-management sibling span before ReplayModal call
- `mailglass_admin/e2e/structural.spec.js` — New structural test inside inbound describe block

## Decisions Made

- Added a real `id="inbound-replay-modal"` on the inbound dialog div. The operator modal has the D-04 latent bug (no id, so its focus-first selector is a no-op). The inbound port intentionally does NOT reproduce that bug — the id is required for focus-first to resolve. The operator modal is left untouched (D-05).
- Focus management uses pure LiveView JS (`phx-mounted` + `phx-remove` on a conditional `<span>`) with no phx-hook and no Tab-cycle focus trap. This matches the operator_live.ex pattern exactly and respects D-06.
- Test description and code comments use "focus-management parity" language throughout, never "WCAG conformance" or "focus trap/containment" (D-07).

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- A11Y-01 is satisfied. Phase 107 has only one plan; phase is complete.
- The operator modal D-04 latent bug (no id on operator dialog div, making its focus-first a no-op) is explicitly deferred per D-04/D-05 and tracked in the plan context. A future phase could fix it with a single `id="operator-replay-modal"` attribute addition.

## Self-Check

- `[ -f mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex ]` — FOUND
- `[ -f mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex ]` — FOUND
- `[ -f mailglass_admin/lib/mailglass_admin/inbound_live.ex ]` — FOUND
- `[ -f mailglass_admin/e2e/structural.spec.js ]` — FOUND
- `git log --oneline | grep 8feb0b1d` — FOUND (Task 1 commit)
- `git log --oneline | grep b9bfbfd5` — FOUND (Task 2 commit)
- `git log --oneline | grep 9006edad` — FOUND (Task 3 commit)

## Self-Check: PASSED

---
*Phase: 107-inbound-replay-modal-a11y-parity-wr-03*
*Completed: 2026-06-17*
