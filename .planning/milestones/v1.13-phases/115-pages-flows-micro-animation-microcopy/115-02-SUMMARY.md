---
phase: 115-pages-flows-micro-animation-microcopy
plan: 02
subsystem: mailglass_admin
tags: [motion, css, overlay, accessibility, responsive]
requires:
  - "115-01 (microcopy + 320px patches; same surfaces)"
provides:
  - ".motion-overlay transform-origin: var(--mg-origin, center) — origin-aware overlays (D-07)"
  - ".mg-state-layer state-layer-only color transition at fast token (D-08 inverted default)"
  - ".mg-overscroll-contain modal scroll-chaining guard at 320px (D-04)"
  - "rebuilt committed priv/static CSS bundle"
affects:
  - "operator/inbound replay modals (overscroll-contain; centered origin)"
tech-stack:
  added: []
  patterns:
    - "CSS custom property var(--mg-origin, center) re-parameterizes existing keyframe — zero JS, no new animated property"
    - "Inverted theme-transition default: bulk theme color transitions OFF; only state layers opt in"
key-files:
  created: []
  modified:
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
key-decisions:
  - "Task 3 is a deliberate no-op: the only .motion-overlay surfaces rendered by operator_live.ex and inbound_live.ex are the centered replay modals, which correctly OMIT --mg-origin (center default per D-07). No header-anchored overlays or toasts exist to anchor."
  - ".mg-state-layer uses raw `transition: color/background-color/border-color` (not the Tailwind `transition-colors` class) so the D-09 negative grep (no `transition-colors` on data-theme chrome) stays clean."
  - "Inbound modal converted to be its own scroll container (max-h-[90vh] overflow-y-auto) since its scrim is flex-centered with no scroll; operator scrim already had overflow-y-auto."
requirements-completed: [FLOW-02, FLOW-03]
duration: 18 min
completed: 2026-06-20
---

# Phase 115 Plan 02: Micro-Animation Pass (Origin-Aware Overlays + Theme-Switch Suppression) Summary

Landed the FLOW-03 micro-animation pass within the MOTION-LD locks: origin-aware overlay
scaling via a single CSS custom property (`var(--mg-origin, center)`), theme-switch color-flash
suppression via an inverted-default state-layer transition utility, and a 320px scroll-chaining
guard on both replay modals — zero JS, zero hooks, no new animated property.

- **Duration:** ~18 min (start 2026-06-20T14:05Z → end 2026-06-20T14:23Z)
- **Tasks:** 3/3 (Task 3 a confirmed no-op)
- **Files changed:** 4 (2 source CSS+bundle, 2 modal components)

## What Changed

### Task 1 — app.css (+ rebuilt bundle)
- `.motion-overlay` now declares `transform-origin: var(--mg-origin, center)` — re-parameterizes
  the existing `mg-overlay` `scale(0.98→1)` keyframe so overlays scale from an author-declared
  origin (default `center`). No new keyframe, no new animated property (MOTION-LD-04/10).
- Added `.mg-state-layer` utility: `transition: color/background-color/border-color
  var(--duration-instant) var(--ease-out)` (90ms ≤ 100ms fast token, MOTION-LD-06). This is the
  D-08 inverted default — bulk theme-driven color transitions stay OFF so a server-side theme
  re-render never animates a color change; only interactive state layers opt in.
- Added `.mg-overscroll-contain` utility (`overscroll-behavior: contain`) for the modal
  scroll-chaining guard (D-04).
- No reduced-motion rule added for the origin var — the existing
  `@media (prefers-reduced-motion: reduce)` block already neutralizes it.
- Rebuilt the committed `priv/static/app.css` bundle (`mix mailglass_admin.assets.build`); all
  three rules are present in the bundle and `git diff --exit-code priv/static` is clean.

### Task 2 — replay modals
- **operator/replay_modal.ex:** added `mg-overscroll-contain` to the `overflow-y-auto` scrim
  (the scroll container). Panel stays center; no `--mg-origin` added.
- **inbound/replay_modal.ex:** the scrim is flex-centered with no scroll, so the panel itself
  was made the scroll container (`max-h-[90vh] overflow-y-auto mg-overscroll-contain`) and
  `mx-auto` added for 320px horizontal centering. Panel stays center; no `--mg-origin` added.
- Existing testids (`operator-replay-modal`, `inbound-replay-modal`, the confirm testids) and the
  `phx-window-keydown="close_replay"` Escape wiring are unchanged.

### Task 3 — inline --mg-origin on live-view overlay triggers
- **No-op (intentional, per D-07).** Audited `operator_live.ex` and `inbound_live.ex`: the only
  `.motion-overlay` surfaces they render are the two centered replay modals (via the modal
  components). Both are `mx-auto max-w-2xl` centered confirm modals that MUST keep the default
  `center` origin and therefore OMIT the var. There are no header-anchored overlays, popovers, or
  toasts in these surfaces to anchor. The centered-modal default is the correct intentional origin
  — no `--mg-origin` keyword was added, and none should be (a new overlay would have been invented
  otherwise, which the plan forbids).

## Verification

| Check | Command | Result |
|---|---|---|
| origin var in .motion-overlay | `grep -E "transform-origin:\s*var\(--mg-origin, center\)" assets/css/app.css` | PASS |
| overscroll-contain present | `grep -F "overscroll-behavior: contain" assets/css/app.css` | PASS |
| state-layer fast-token transition | `grep "mg-state-layer" + var(--duration-instant)` | PASS |
| no transition-colors on chrome | `grep -n "transition-colors" assets/css/app.css` | PASS (only in comment text, no declaration) |
| modals omit --mg-origin | `! grep -- "--mg-origin" both replay_modal.ex` | PASS |
| modals carry overscroll-contain | `grep -c "mg-overscroll-contain"` (1 each) | PASS |
| compile | `mix compile --warnings-as-errors` | PASS |
| bundle committed/clean | `git diff --exit-code priv/static/` | PASS |
| voice test (regression guard) | `mix test test/mailglass_admin/voice_test.exs` | PASS (16 tests, 0 failures, 1 excluded) |

## Deviations from Plan

None — plan executed exactly as written. Task 3 was a planned no-op (the plan's acceptance
criteria explicitly cover the "surfaces render only centered modals → make NO change and record
it in the SUMMARY" branch).

**Total deviations:** 0. **Impact:** none.

## Deferred / Out-of-Scope Issues

Three PRE-EXISTING test failures observed in `operator_live_test.exs:911`,
`inbound_live_test.exs:46`, and `inbound_live_test.exs:89` — all assert the tenant-selector
sub-copy `"Choose a tenant to inspect its deliveries and inbound routing"` (lowercase
"deliveries"). The UI-SPEC locks this string with capital-D `"Deliveries"` (FLOW-04 microcopy),
so the templates emit the new capitalized copy while these tests still expect the old string.
Verified by stashing the four Plan-02 files and re-running: **all three fail identically at
baseline**, confirming they are NOT caused by this plan. This is FLOW-04 tenant-selector
microcopy, which lives in `shell.ex` / Plan 01's scope — out of scope for 115-02 (a
micro-animation pass touching app.css + replay modals). Logged here per the scope-boundary rule;
not fixed. The Plan-01 / orchestrator pass should reconcile these tenant-selector test
expectations against the locked capital-D copy.

## Self-Check: PASSED

- `mailglass_admin/assets/css/app.css` — exists, modified (3 rules added)
- `mailglass_admin/priv/static/app.css` — exists, modified (bundle rebuilt, all 3 rules present)
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` — exists, modified
- `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` — exists, modified
- Commit `7c934b4d` (feat 115-02: app.css + bundle) — present in `git log`
- Commit `a6e7d48c` (feat 115-02: replay modals) — present in `git log`
