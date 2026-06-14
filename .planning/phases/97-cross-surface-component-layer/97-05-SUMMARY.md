---
phase: "97"
plan: "05"
subsystem: mailglass_admin/preview
tags: [accessibility, aria, focus-rings, touch-targets, preview-surface]
dependency_graph:
  requires: []
  provides: [COMP-01, COMP-02]
  affects: [mailglass_admin/preview/device_frame.ex, mailglass_admin/preview/tabs.ex, mailglass_admin/preview/sidebar.ex]
tech_stack:
  added: []
  patterns: [focus-visible ring, aria-controls tabpanel contract, border-l-2 conformance]
key_files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/preview/device_frame.ex
    - mailglass_admin/lib/mailglass_admin/preview/tabs.ex
    - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
decisions:
  - btn-sm retained alongside min-h-11 on device_frame buttons (btn-sm uses --size CSS var, min-h-11 sets min-height — different CSS properties; STATE.md decision confirmed effective 44px touch target)
  - ring-inset used on tab buttons (not ring-offset) matching deliveries_list row pattern — inset ring stays within the element boundary for inline-sibling buttons
  - border-l-2 replaces border-l-[3px] in both scenario_classes clauses — 2px is nearest Tailwind scale value and aligns with nav_link border-l-2 (shell.ex:207); arbitrary value banned by conformance gate
metrics:
  duration_seconds: 420
  completed_date: "2026-06-14"
  tasks_completed: 3
  files_modified: 3
---

# Phase 97 Plan 05: Preview Surface Component Uplift Summary

**One-liner:** ARIA tab panel contract (aria-controls + tabpanel + aria-labelledby), 44px touch targets, focus rings, and border-l-2 conformance on all three Preview surface components.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | device_frame: add min-h-11 to all three segmented control buttons | 1020e625 | device_frame.ex |
| 2 | tabs: add ARIA tab contract, focus rings, min-h-11, empty HTML placeholder | 665ff72a | tabs.ex |
| 3 | sidebar: add focus rings to summary and link; border-l-[3px] → border-l-2 | e52408ae | sidebar.ex |

## What Was Built

### device_frame.ex

All three segmented control buttons (375/768/1024) now carry `min-h-11` alongside `btn-sm`. The `btn-sm` class uses the daisyUI `--size` CSS variable for button sizing; `min-h-11` sets `min-height: 2.75rem` (44px) as an independent property. Both coexist without conflict — confirmed from compiled app.css where `btn-sm` rule is `{--size:calc(var(--size-field,.25rem)*8)}` with no `min-height` declaration. `aria-pressed` not regressed.

### tabs.ex

Full ARIA tab panel contract implemented:
- All four tab buttons (HTML, Text, Raw, Headers) now have `id="tab-btn-{tab}"` and `aria-controls="tab-panel-{tab}"`
- All four tab buttons get `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-inset` (ring-inset chosen as for inset context — buttons are inline inside the tablist, no outer boundary available)
- `min-h-10` upgraded to `min-h-11` on all four buttons (44px touch target floor per UI-SPEC Global Rules)
- Content div renamed from `id="preview-tab-{tab}"` to `id="tab-panel-{tab}"` to match aria-controls targets
- Content div gains `role="tabpanel"` and `aria-labelledby="tab-btn-{active_tab}"`
- Empty HTML body placeholder: "No HTML body — this Mailable's template returned empty content." rendered when `@html_body == ""`
- `motion-tab-swap` class preserved (MOTION-LD-05 not regressed)

### sidebar.ex

- `<summary>` element gets `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1` appended to its class string
- Scenario `<.link>` element gets the same focus ring on its static class string
- Both `scenario_classes/4` clauses: `border-l-[3px]` replaced with `border-l-2` (arbitrary value removed from both active and inactive branches)

## Verification Results

| Check | Command | Expected | Actual | Status |
|-------|---------|----------|--------|--------|
| device_frame min-h-11 | `grep -c "min-h-11" device_frame.ex` | 3 | 3 | PASS |
| device_frame aria-pressed | `grep -c "aria-pressed" device_frame.ex` | ≥3 | 4 | PASS |
| tabs aria-controls | `grep -c "aria-controls" tabs.ex` | ≥4 | 4 | PASS |
| tabs role=tabpanel | `grep -c 'role="tabpanel"' tabs.ex` | ≥1 | 1 | PASS |
| tabs focus ring | `grep -c "focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-inset" tabs.ex` | ≥4 | 4 | PASS |
| tabs No HTML body | `grep -c "No HTML body" tabs.ex` | 1 | 1 | PASS |
| tabs motion-tab-swap | `grep -c "motion-tab-swap" tabs.ex` | ≥1 | 1 | PASS |
| sidebar focus ring | `grep -c "focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1" sidebar.ex` | ≥2 | 2 | PASS |
| sidebar border-l-[3px] removed | `grep -v "^#" sidebar.ex \| grep -c "border-l-\[3px\]"` | 0 | 0 | PASS |
| sidebar border-l-2 | `grep -c "border-l-2" sidebar.ex` | ≥2 | 2 | PASS |
| sidebar details/summary | `grep -c "<details\|<summary" sidebar.ex` | ≥2 | 3 | PASS |
| compile clean | `cd mailglass_admin && mix compile --warnings-as-errors` | exit 0 | exit 0 | PASS |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all changes are complete implementations. No placeholder data or empty state stubs that prevent the plan's goal from being achieved.

## Threat Surface Scan

No new trust boundaries introduced. Changes are purely class-string additions and one conditional render (`if @html_body == ""`) in the existing tabs iframe wrapper. The `@html_body == ""` check is a purely static comparison — no user input flows into the conditional or the placeholder message. The `Atom.to_string(@active_tab)` value flowing into `id` and `aria-labelledby` attributes is from a controlled atom set (`[:html, :text, :raw, :headers]`), not user input (T-97-05-01 accepted per plan threat register).

## Self-Check: PASSED

- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/preview/device_frame.ex` — FOUND
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/preview/tabs.ex` — FOUND
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` — FOUND
- Commit 1020e625 — FOUND
- Commit 665ff72a — FOUND
- Commit e52408ae — FOUND
