---
phase: 122-preview-surface-redesign
plan: 01
subsystem: mailglass_admin / preview
tags: [a11y, theme-picker, preview, liveview, wcag, d-05]
requires:
  - "Components.theme_picker (shipped 1.8.0)"
  - "preview_theme_path/2 + put_frame_query frame carry-through (D-05)"
provides:
  - "Preview admin chrome theme via canonical tri-state theme_picker (set_theme event)"
  - "Hardened email-backdrop toggle (aria-pressed + visible 'Email backdrop' label + aria-live announce)"
  - "preview-backdrop-status aria-live region (testid)"
affects:
  - "mailglass_admin/lib/mailglass_admin/preview_live.ex"
  - "mailglass_admin/e2e/flows.spec.js"
  - "mailglass_admin/e2e/structural.spec.js"
  - "mailglass_admin/test/mailglass_admin/preview_live_test.exs"
tech-stack:
  added: []
  patterns:
    - "theme_picker adoption mirrors operator surfaces (tri-state light/dark/system)"
    - "aria-live role=status sr-only announce region (mirrors evidence_card.ex, 121 D-11)"
    - "closed-set theme_segment guard before /theme/<seg> interpolation (T-122-01 mitigation)"
key-files:
  created: []
  modified:
    - "mailglass_admin/lib/mailglass_admin/preview_live.ex"
    - "mailglass_admin/e2e/flows.spec.js"
    - "mailglass_admin/e2e/structural.spec.js"
    - "mailglass_admin/test/mailglass_admin/preview_live_test.exs"
decisions:
  - "set_theme routes through Preview's own frame-aware preview_theme_path/2, never the operator shell builder (D-05 load-bearing invariant)"
  - "preview_theme_path/2 generalized from binary currently_dark? to a closed tri-state segment string; theme_segment/1 collapses any non-{dark,light} value to system"
  - "admin_chrome_theme nil maps to theme_picker :system (no explicit override)"
  - "set_theme redirect asserts frame=dark carry-through — confirmed correct via the live preview_live_test suite (not the original frame-less assertion)"
metrics:
  duration: "~7 min"
  completed: "2026-06-28"
  tasks: 3
  files_changed: 4
status: complete
---

# Phase 122 Plan 01: Preview Surface Redesign — theme_picker adoption + backdrop a11y Summary

Swapped Preview's bespoke binary admin-theme button for the canonical tri-state
`Components.theme_picker` (routed through the frame-aware `preview_theme_path/2`
so the email backdrop survives the chrome remount, D-05), and hardened the
email-backdrop button into a correct toggle with `aria-pressed`, a visible
"Email backdrop" label, and an `aria-live` announce region (WCAG 1.4.1).

## What Was Built

- **Task 1 (`83256c78`)** — `preview_live.ex` header now renders
  `<Components.theme_picker selected={admin_chrome_selected(@admin_chrome_theme)}
  event="set_theme" />` under an "App theme" caption, replacing the bespoke
  `preview-admin-theme-toggle` button. New `handle_event("set_theme", ...)` clause
  redirects through `preview_theme_path/2`, which was generalized to a closed
  tri-state segment (keeping the `append_query_without_theme |> put_frame_query`
  return_to verbatim). New helpers: `admin_chrome_selected/1` (maps `:dark|:light|nil`
  → picker `:system|:light|:dark`) and `theme_segment/1` (closed-set guard).
- **Task 2 (`5e593892`)** — Email-backdrop button hardened: added
  `aria-pressed={@preview_frame_dark_chrome}`, renamed label "Email" → "Email
  backdrop", kept testid + phx-click verbatim. Added a
  `role="status" aria-live="polite" sr-only` region (`data-testid="preview-backdrop-status"`)
  carrying `backdrop_status_text/1` → "Email backdrop: dark|light".
- **Task 3 (`b6ed8a50`)** — `flows.spec.js` gained two new a11y tests (tri-state
  theme_picker present + system reachable + bespoke button gone; backdrop
  aria-pressed flip + aria-live announce). The two-theme independence lock
  (`flows.spec.js:454-458`) is preserved unweakened.

## Load-Bearing Invariant (D-05) — Verified

The new `set_theme` handler calls `preview_theme_path/2` exclusively — `grep`
confirms `Shell.set_theme_path`/`set_theme_path` is NOT referenced from
`preview_live.ex`. The `put_frame_query(socket.assigns.preview_frame_dark_chrome)`
call is retained in the return_to construction. The live LiveView test
(`preview_live_test.exs` "admin chrome toggle ...") proves the redirect carries
`frame=dark` when the backdrop is dark, so the email backdrop survives the full
controller remount.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Pre-existing tests bound to the removed bespoke theme button**
- **Found during:** Task 1 (removal of `preview-admin-theme-toggle` / `toggle_theme`)
- **Issue:** `preview_live_test.exs` (lines 155-156, 274, 314) and
  `structural.spec.js` (lines 903, 1395, 1532) asserted on the now-removed
  `preview-admin-theme-toggle` testid and `toggle_theme` event — these would fail
  against the theme_picker swap.
- **Fix:** Migrated `preview_live_test.exs` assertions to `set_theme` + theme_picker
  + hardened-backdrop expectations (including the corrected `frame=dark` carry-through
  redirect, verified green). Retargeted the three `structural.spec.js` spots to the
  theme_picker radio segments (touch-target, focus indicator, independence click).
- **Files modified:** `test/mailglass_admin/preview_live_test.exs`,
  `e2e/structural.spec.js`
- **Commit:** `b6ed8a50`

## Deferred Issues

- **[Out of scope] `operator_live.ex:505` warnings-as-errors failure** —
  pre-existing `selected_delivery={nil}` map-attr warning (introduced phase 120,
  commit `e59a6e5f`); fails `mix compile --warnings-as-errors` repo-wide but is
  NOT caused by this plan. `preview_live.ex` itself compiles warning-clean. Logged
  to `deferred-items.md`. Per scope boundary, not fixed here.

## Verification

- All Task 1/2/3 `grep` gates pass (theme_picker adopted, set_theme frame-aware,
  put_frame_query kept, bespoke button gone, shell path not called, backdrop
  aria-pressed + aria-live present).
- `preview_live.ex` compiles warning-clean (only the unrelated pre-existing
  `operator_live.ex` warning trips the repo-wide `--warnings-as-errors` lane).
- `mix test test/mailglass_admin/preview_live_test.exs --seed 0` → 23 tests, 0 failures.
- `node --check e2e/flows.spec.js` and `e2e/structural.spec.js` parse.
- D-13: committed `mailglass_admin/priv/static/app.css` is UNTOUCHED (no new
  Tailwind class introduced — `sr-only`, `text-label`, `min-h-11`, `mg-focus-ring`
  all already ship).

## Threat Surface

No new threat surface beyond the plan's `<threat_model>`. The `set_theme` path
interpolates only the closed `theme_segment/1` value into `/theme/<seg>`
(T-122-01 mitigation applied); the aria-live region announces only on/off state,
no PII (T-122-02 accepted). No new route, auth path, or data flow. Surface remains
dev-only.

## Self-Check: PASSED

- SUMMARY.md present
- Commits 83256c78, 5e593892, b6ed8a50 exist
- preview_live.ex present
