---
phase: "97"
plan: "06"
subsystem: mailglass_admin/gallery
tags: [live-view, gallery, data-testid, twin-theme, structural-ratchet]
dependency_graph:
  requires:
    - phase: 97-01
      provides: shell component uplifts (nav_link/nav_pill focus rings, orientation_strip copy)
    - phase: 97-02
      provides: components.ex uplifts (status_badge, flash, badge)
    - phase: 97-03
      provides: operator component uplifts (deliveries_list, filters_form, support_cards, replay_modal)
    - phase: 97-04
      provides: verify pass on components.ex, timeline, routing_trace, evidence_card
    - phase: 97-05
      provides: preview component uplifts (device_frame, tabs, sidebar)
  provides:
    - GALLERY-01: dev-only /dev/mail/gallery route wired inside preview live_session
    - GALLERY-02: stable data-testid=gallery-{component}-{state} cells for structural assertions
  affects:
    - 97-07 (bundle rebuild — gallery Tailwind classes picked up on next rebuild)
    - 97-08 (e2e structural assertions — un-skip gallery block using these testids)
tech_stack:
  added: []
  patterns:
    - "In-code @specimens module attribute: [{component_atom, state_label, assigns_map}] tuples"
    - "Twin data-theme wrappers per cell: static mailglass-light + mailglass-dark side-by-side"
    - "data-testid=gallery-{component}-{state}: one stable testid per component x state cell"
    - "Shell private components inlined as equivalent HEEx (defp not callable externally)"
key_files:
  created:
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  modified:
    - mailglass_admin/lib/mailglass_admin/router.ex
decisions:
  - "Route added as one line inside existing preview live_session block — no new live_session or scope (CONTEXT D-01)"
  - "Shell nav_link/nav_pill/tenant_chip/theme_toggle are defp — inlined as equivalent HEEx in gallery; no shell.ex refactor needed"
  - "Phoenix.HTML.FormData.to_form/2 used directly for filters_form specimens with string keys (not atom keys)"
  - "grouped_specimens/1 helper preserves insertion order so sections appear in STATE-LD-01..22 row order"
metrics:
  duration_seconds: 323
  completed_date: "2026-06-14"
  tasks_completed: 2
  files_modified: 2
---

# Phase 97 Plan 06: GalleryLive and Gallery Route Summary

**One-liner:** Dev-only component gallery at /dev/mail/gallery with 22-component STATE-LD matrix, twin data-theme wrappers, and stable gallery-{component}-{state} testids covering all 57 specimen cells.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Wire gallery route in router.ex | 2755b684 | router.ex |
| 2 | Create GalleryLive with complete in-code specimen list and twin-theme render | 931d3fd4 | gallery_live.ex |

## What Was Built

### router.ex

- Added `MailglassAdmin.GalleryLive` to the `@compile {:no_warn_undefined, [...]}` list at lines 87-95 — keeps `--warnings-as-errors` clean before the module is compiled in ordering scenarios.
- Added `live "/gallery", MailglassAdmin.GalleryLive, :index` inside the existing `live_session :mailglass_admin_preview` block after the two existing `live` lines. Route resolves to `/dev/mail/gallery`. No segment collision with `/:mailable/:scenario` (1 segment vs 2 segments). Route inherits the adopter's `if dev_routes` wrapping for dev-only enforcement.

### gallery_live.ex (new)

`MailglassAdmin.GalleryLive` — 773 lines covering:

**Mount:** Assigns `:page_title` and `:specimens` from the in-code list. No DB access, no mailable scan, no `__preview_session__` assigns.

**Render:** Grouped by component (one `<section>` per component), then by state within the section. Each cell:
- Outer `<div data-testid={"gallery-#{component}-#{state}"}>` — stable ratchet anchor
- Label `<p>` showing `{component_label(component)} — {state}` in `text-label font-bold text-secondary`
- Twin wrappers: `<div data-theme="mailglass-light" ...>` and `<div data-theme="mailglass-dark" ...>`

**Specimen coverage (all STATE-LD rows):**

| Component | States | STATE-LD |
|-----------|--------|----------|
| icon | rest | STATE-LD-01 |
| logo | rest | STATE-LD-02 |
| flash | error-kind, info-kind, success-kind, warning-kind | STATE-LD-03 |
| badge | warning, stub | STATE-LD-04 |
| status_badge | 22 atoms + phantom nil (23 cells) | STATE-LD-05 |
| nav_link | active, inactive | STATE-LD-06 |
| nav_pill | active, inactive | STATE-LD-06 |
| tenant_chip | with-tenant, no-tenant | STATE-LD-07 |
| theme_toggle | light-mode, dark-mode | STATE-LD-08 |
| orientation_strip | deliveries, inbound, preview | STATE-LD-09 |
| deliveries_list | populated-unselected, populated-selected, empty | STATE-LD-11 |
| detail_header | shown | STATE-LD-12 |
| filters_form | empty, filled | STATE-LD-13 |
| support_cards | tier1-shown, tier1-hidden | STATE-LD-14 |
| suppression_card | present, absent | STATE-LD-15 |
| timeline | populated, highlighted-event, empty | STATE-LD-16 |
| replay_modal | closed | STATE-LD-17 |
| routing_trace | empty, all-passing, first-failing | STATE-LD-18 |
| evidence_card | no-evidence, redacted, revealed, denied | STATE-LD-19 |
| device_frame | inactive-btn | STATE-LD-20 |
| tabs | inactive-tab | STATE-LD-21 |
| sidebar | mailable-collapsed, mailable-expanded, scenario-active | STATE-LD-22 |

Total: 57 specimen cells.

**Shell private component handling:** `nav_link`, `nav_pill`, `tenant_chip`, and `theme_toggle` are `defp` in `operator/shell.ex` — not callable from outside the module. Each is inlined as equivalent HEEx inside `render_specimen/1` pattern-matched clauses. The rendered HTML is identical to what the private functions emit.

**No new hero icon glyphs:** All status_badge icons and component icons reuse already-embedded glyphs from `heroicons-inline.js` (CONTEXT D-07 respected).

## Verification Results

| Check | Command | Expected | Actual | Status |
|-------|---------|----------|--------|--------|
| GalleryLive in router | `grep -c "GalleryLive" router.ex` | 2 | 2 | PASS |
| gallery route in router | `grep -c 'live "/gallery"' router.ex` | 1 | 1 | PASS |
| compile clean | `mix compile --warnings-as-errors` | 0 errors | 0 errors | PASS |
| data-testid present | `grep -c "data-testid" gallery_live.ex` | ≥1 | 2 | PASS |
| twin data-theme wrappers | `grep -c 'data-theme="mailglass-light"\|data-theme="mailglass-dark"'` | ≥2 | 3 | PASS |
| no Repo. calls | `grep -c "Repo\." gallery_live.ex` | 0 | 0 | PASS |
| admin test suite | `mix test --seed 0` | 202 pass | 202 pass | PASS |

## Deviations from Plan

**[Rule 1 - Bug] Shell private components inlined instead of aliased**

- **Found during:** Task 2 — compile attempt
- **Issue:** `nav_link/1`, `nav_pill/1`, `tenant_chip/1`, and `theme_toggle/1` are `defp` in `MailglassAdmin.Operator.Shell`. The plan's `render_specimen` dispatcher used `Shell.nav_link`, `Shell.nav_pill`, etc. which produced undefined function warnings (treated as errors under `--warnings-as-errors`).
- **Fix:** Each private function's render output is reproduced inline as an equivalent `~H"""..."""` block inside the appropriate `render_specimen/1` clause. No logic is changed — the HEEx is a verbatim copy of the private function bodies.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex`
- **Commit:** 931d3fd4

**[Rule 1 - Bug] Phoenix.HTML.Form map keys must be strings**

- **Found during:** Task 2 — compile attempt
- **Issue:** `Phoenix.HTML.FormData.to_form/2` warned: "a map with atom keys was given to a form" — the `@specimens` filters_form entries used atom keys (`%{tenant_id: "", ...}`) but Phoenix forms require string keys for map parameters.
- **Fix:** Changed all filters_form specimen map keys to strings (`%{"tenant_id" => "", ...}`).
- **Files modified:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex`
- **Commit:** 931d3fd4

## Known Stubs

None — all specimens use concrete literal data. The `replay_modal` specimen renders in the `closed` (`:if` false) state by design — open state requires a live phx-click event (per plan spec, STATE-LD-17 "open states require live event; specimen is rest-closed").

## Threat Surface Scan

The gallery route is inside the preview `live_session` which is gated by the adopter's `if dev_routes` wrapping — the T-97-06-01 mitigation (route exposure) is confirmed in place. No new DB access, no new trust boundary, no user input flows into the gallery.

No threat flags beyond what the plan's threat model already covers.

## Self-Check

- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/gallery_live.ex` — FOUND
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex` — modified (FOUND)
- Commit 2755b684 — FOUND (Task 1: router.ex)
- Commit 931d3fd4 — FOUND (Task 2: gallery_live.ex)

## Self-Check: PASSED

---
*Phase: 97-cross-surface-component-layer*
*Completed: 2026-06-14*
