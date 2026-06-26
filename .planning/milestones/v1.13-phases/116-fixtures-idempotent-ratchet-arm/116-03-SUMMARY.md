---
phase: 116-fixtures-idempotent-ratchet-arm
plan: 03
subsystem: mailglass_admin
status: complete
tags: [ratchet, interaction-pillar, playwright, accessibility, e2e, binary-gates]
requires:
  - "mailglass_admin/e2e/structural.spec.js (assertPanelAboveScrim seam)"
  - "Phase 116-01 persona cohort (DemoData.reset! / browser harness fixtures)"
provides:
  - "Four binary interaction-invariant Playwright gates (RATCHET-03 interaction half)"
  - "Theme-axis open helpers (openOperatorReplayModalThemed / openInboundReplayModalThemed / openPreviewPanelThemed)"
  - "assertCentroidHitsPanel generalization of the centroid hit-test"
affects:
  - "Plan 116-05 (A21 CLS + A22 skeleton Bucket-A guards cross-cite this pillar)"
  - "Plan 116-06 (full-matrix run references these --grep labels)"
tech-stack:
  added: []
  patterns:
    - "Binary pass/fail Playwright gates (not LLM-scored) — failing test name is the diagnosis (D-01)"
    - "elementFromPoint / scrollY / activeElement / getBoundingClientRect — screenshot-free, no pixel-diff"
    - "Theme axis: light=?theme=light, dark=?theme=dark, system=no theme param + emulateMedia({colorScheme:'dark'})"
key-files:
  created: []
  modified:
    - "mailglass_admin/e2e/structural.spec.js"
decisions:
  - "CLS threshold = 4px (well under the <=8px UI-SPEC ceiling, headroom for Chromium sub-pixel rounding); 0px floor for the synchronous inbound mount"
  - "focus-restore trigger id = replay-open-btn (operator-replay-open testid -> id=replay-open-btn, JS.focus return target per STATE.md [Phase ?])"
  - "preview 'panel' = device-frame preview-pane (non-scrim); centroid clamped to the visible viewport intersection because the tall pane extends past the fold"
metrics:
  duration: "~18 min"
  completed: 2026-06-20
  tasks: 2
  files: 1
---

# Phase 116 Plan 03: Interaction Pillar (RATCHET-03) Summary

Added the idempotent ratchet's interaction pillar — four BINARY pass/fail Playwright
gates (panel-above-scrim, scroll-chaining, focus-restore, layout-jump/CLS) parameterized
across deliveries/inbound/preview x light/dark/system — extending the existing
`assertPanelAboveScrim` seam in `structural.spec.js`, screenshot-free and no pixel-diff.

## What Was Built

All four invariants are true/false runtime DOM properties an LLM scoring a static PNG
cannot observe and a 1-4 aesthetic rubric cannot trade away. The failing test name IS the
diagnosis (D-01).

### Task 1 — Invariant 1 (panel-above-scrim) + Invariant 2 (scroll-chaining)

- **Panel-above-scrim** (9 gates): centroid `document.elementFromPoint` hit-test asserts
  `hit === el || el.contains(hit)` for deliveries replay dialog, inbound modal, and preview
  panel, each x light/dark/system. Reuses `assertPanelAboveScrim` for the two scrim-backed
  dialogs and a generalized `assertCentroidHitsPanel` for the non-scrim preview pane.
- **Scroll-chaining / overscroll-contain** (6 gates): with the overlay open, scroll its
  `.mg-overscroll-contain` container to `scrollTop = scrollHeight` and assert the background
  `window.scrollY` is unchanged; assert at most one element in the overlay subtree owns a
  vertical scrollbar (`scrollableSubtreeCount`). Deliveries + inbound x light/dark/system.

### Task 2 — Invariant 3 (focus-restore) + Invariant 4 (layout-jump/CLS)

- **Focus-restore** (3 gates): open the replay modal on deliveries, close via the in-modal
  Close button (routes to `close_replay`; the `:if` span's `phx-remove` fires
  `JS.focus(to:"#replay-open-btn")`), assert `document.activeElement.id === "replay-open-btn"`.
  x light/dark/system. The trigger id is asserted (`operator-replay-open` testid -> `replay-open-btn`).
- **Layout-jump/CLS** (6 gates): capture a content region's `getBoundingClientRect().height`
  in the loading state and the settled state (`waitForLoadState('networkidle')` + animation
  settle so intentional reveal motion does not trip the gate — Motion Contract), assert
  `|loaded - loading| <= 4px` on the deliveries list region. The synchronous inbound mount
  asserts the 0px floor AND zero `.mg-skeleton` (A22 cross-cite). x light/dark/system.

## Key Decisions

| Decision | Value | Rationale |
|----------|-------|-----------|
| CLS threshold | **4px** | Under the UI-SPEC `<=8px` "meaningful" ceiling; headroom for Chromium sub-pixel layout rounding |
| CLS synchronous floor | **0px** | Inbound mount is synchronous (A22) — no skeleton, no jump |
| Focus-restore trigger id | **`replay-open-btn`** | `operator-replay-open` testid resolves to `id=replay-open-btn`, the `JS.focus(to:)` return target (operator_live.ex:604) |
| Preview "panel" | **preview-pane** (device frame) | The Invariant-1 third surface; non-scrim, so the centroid hit-test proves the pane is the top element at its (viewport-clamped) center |
| Theme axis for system | no `?theme=` + `emulateMedia({colorScheme:'dark'})` | Mirrors the A16-system precedent so the media-query branch is genuinely exercised, not a no-op light render |

## --grep Labels (for plan 116-05 A21/A22 + plan 116-06 full-matrix)

These exact label fragments select the interaction pillar (all under
`test.describe("structural assertions — 6 D-01 pillar facts")`):

```
panel above scrim|scroll-chaining|overscroll|focus.restore|layout.jump|CLS
```

Individual gate name fragments:
- `panel above scrim — deliveries replay dialog (<theme>)`
- `panel above scrim — inbound modal (<theme>)`
- `panel above scrim — preview panel (<theme>)`
- `scroll-chaining contained — deliveries replay dialog (<theme>)`
- `scroll-chaining contained — inbound modal (<theme>)`
- `focus restore to trigger — deliveries replay modal (<theme>)`
- `layout-jump/CLS within threshold — deliveries list region (<theme>)`
- `layout-jump/CLS 0px on synchronous inbound mount (<theme>)`

(`<theme>` ∈ light / dark / system)

## Verification

```
cd mailglass_admin && npm run test:operator-browser -- \
  --grep "panel above scrim|scroll-chaining|focus.restore|layout.jump|CLS"
```

**Result: 28 passed** (24 net-new interaction-pillar gates in `structural.spec.js` +
4 pre-existing `flows.spec.js` overlay-subset tests matched by the same grep). Per-task:
panel-above-scrim+scroll-chaining 19 passed; focus-restore+CLS 9 passed.

Bundle clean: `mailglass_admin/priv/static/` unchanged after `mix mailglass_admin.assets.build`
(the test:operator-browser prebuild produced a bit-identical bundle — no commit needed).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preview-pane centroid hit-test returned `hit=null`**
- **Found during:** Task 1 (panel-above-scrim, preview panel, all three themes)
- **Issue:** The preview device-frame pane is taller than the viewport, so its raw
  geometric centroid falls below the fold; `document.elementFromPoint` returns `null`
  for off-screen coordinates, failing the hit-test.
- **Fix:** `assertCentroidHitsPanel` now `scrollIntoViewIfNeeded()`s the pane and computes
  the centroid of the panel's **visible viewport intersection** (clamping left/top/right/
  bottom to `[0, innerWidth/innerHeight]`). Still a true centroid hit-test — no screenshot,
  no pixel-diff. The two scrim-backed dialogs (deliveries/inbound) fit the viewport and
  continue to use the unchanged `assertPanelAboveScrim`.
- **Files modified:** `mailglass_admin/e2e/structural.spec.js`
- **Commit:** fc053e51

## Threat Surface

No new network endpoints, auth paths, file access, or schema changes — test-only additions
to an existing spec file. T-116-06 (overlay focus trap / scroll lock) and T-116-07 (LLM
score-trading) mitigations from the plan's threat register are now enforced by binary gates:
focus restores to the trigger, background scroll is not chained, and the four invariants sit
outside the 1-4 aesthetic rubric so a panel-behind-scrim or focus-loss defect cannot be
scored away.

## Known Stubs

None. All four invariants are wired against live admin surfaces with real persona-cohort data.

## Self-Check: PASSED
- `mailglass_admin/e2e/structural.spec.js` — FOUND (modified, +357 lines)
- Commit fc053e51 — FOUND in git log
- 28/28 interaction-pillar gates green via the plan's verification grep
