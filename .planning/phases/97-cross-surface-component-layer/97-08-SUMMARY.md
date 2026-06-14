---
phase: "97"
plan: "08"
subsystem: mailglass_admin/e2e
tags: [playwright, structural-ratchet, gallery, data-testid, twin-theme, gap-close]
dependency_graph:
  requires:
    - phase: 97-06
      provides: GalleryLive with gallery-{component}-{state} testids
    - phase: 97-07
      provides: CSS bundle rebuilt with gallery Tailwind classes
  provides:
    - GALLERY-02: structural.spec.js gallery block un-skipped with 5 real assertions
    - GAP-05-fixed: RATCHET-GAP-REGISTER.md GAP-05 flipped to fixed
  affects:
    - structural.spec.js (gallery describe block now runs in CI)
    - RATCHET-GAP-REGISTER.md (GAP-05 closed)
tech_stack:
  added: []
  patterns:
    - "openGallery(page) helper: page.goto + getByRole heading assertion (mirrors openPreview)"
    - "getByTestId('gallery-{component}-{state}') visibility assertions"
    - "twin data-theme locator: cell.locator('[data-theme=\"mailglass-light\"]') toBeVisible"
key_files:
  created: []
  modified:
    - mailglass_admin/e2e/structural.spec.js
    - .planning/RATCHET-GAP-REGISTER.md
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
decisions:
  - "Flash testids use exact gallery state names: gallery-flash-error-kind and gallery-flash-success-kind (not gallery-flash-error) — matched real specimens from gallery_live.ex"
  - "gallery_live.ex NaiveDateTime specimens fixed to UTC DateTime to match format_datetime/1 clause"
  - "gallery_live.ex timeline occurred_at field added to all event specimens to match timeline.ex access pattern"
  - "gallery_live.ex sidebar scenario keys fixed from strings to atoms to match Atom.to_string/1 call in sidebar.ex"
metrics:
  duration_seconds: 420
  completed_date: "2026-06-14"
  tasks_completed: 2
  files_modified: 3
---

# Phase 97 Plan 08: E2E Structural Assertions for Gallery Surface Summary

**One-liner:** Un-skipped gallery describe block in structural.spec.js with openGallery helper and 5 real getByTestId + twin-theme assertions; GAP-05 flipped to fixed; 3 gallery_live.ex specimen data bugs fixed for Playwright green (5/5 pass).

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Un-skip gallery describe block and add real structural assertions | 94b6e647 | structural.spec.js |
| 2 | Flip GAP-05 to fixed in RATCHET-GAP-REGISTER.md | 553ca21f | RATCHET-GAP-REGISTER.md |
| Deviation | Fix gallery_live.ex specimen data bugs for Playwright green | 2a5219ca | gallery_live.ex |

## What Was Built

### structural.spec.js

- Added `openGallery(page)` helper function after `openPreview` (lines 45-48): navigates to `/dev/mail/gallery` and asserts the `h1` heading "Component Gallery" is visible.
- Replaced the entire `test.describe.skip("gallery surface — deferred to Phase 97", ...)` block (previously lines 421-428) with a real `test.describe("gallery surface — Phase 97", ...)` containing 5 tests:
  1. **status_badge badge groups** — asserts `gallery-status_badge-delivered` (success), `gallery-status_badge-dispatched` (primary), `gallery-status_badge-bounced` (error), `gallery-status_badge-deferred` (warning), `gallery-status_badge-autoresponded` (outline)
  2. **nav_link states** — asserts `gallery-nav_link-active` and `gallery-nav_link-inactive`
  3. **flash states** — asserts `gallery-flash-error-kind` and `gallery-flash-success-kind` (exact gallery state strings from gallery_live.ex, not plain "error"/"success")
  4. **twin-theme wrappers** — asserts `cell.locator('[data-theme="mailglass-light"]')` and `cell.locator('[data-theme="mailglass-dark"]')` visible on the `gallery-status_badge-delivered` cell
  5. **inbound specimens** — asserts `gallery-routing_trace-empty` and `gallery-evidence_card-redacted`

### RATCHET-GAP-REGISTER.md

- GAP-05 row updated: `status: open` → `status: fixed`
- Fix sketch updated to: "Phase 97 plan 08: gallery route created in router.ex; structural.spec.js gallery block un-skipped with 5 real assertions"
- GAP-01 through GAP-04 remain open (Phase 98/99/100 scope — not touched)

## Verification Results

| Check | Command | Expected | Actual | Status |
|-------|---------|----------|--------|--------|
| No skip blocks | `grep -c "test.describe.skip" structural.spec.js` | 0 | 0 | PASS |
| openGallery count | `grep -c "openGallery" structural.spec.js` | ≥6 | 6 | PASS |
| testid coverage | `grep -c "gallery-status_badge-delivered\|gallery-nav_link-active\|gallery-flash-error"` | ≥3 | 4 | PASS |
| twin-theme assertions | `grep -c 'data-theme="mailglass-light"\|data-theme="mailglass-dark"'` | ≥2 | 2 | PASS |
| GAP-05 fixed | `grep "GAP-05" RATCHET-GAP-REGISTER.md \| grep -c "fixed"` | 1 | 1 | PASS |
| GAP-01..04 unchanged | `grep "GAP-04\|GAP-03\|GAP-02\|GAP-01" \| grep -c "fixed"` | 0 | 0 | PASS |
| Playwright gallery tests | `npx playwright test --grep "gallery"` | 5 passed | 5 passed | PASS |
| Admin ExUnit suite | `mix test --seed 0` | 202 pass | 202 pass | PASS |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] NaiveDateTime in deliveries_list and detail_header specimens**
- **Found during:** Task 1 Playwright run
- **Issue:** `format_datetime/1` in `deliveries_list.ex` has clauses for `%DateTime{}` and `nil` only. Gallery specimens used `~N[...]` (NaiveDateTime) for `last_event_at` fields, producing `FunctionClauseError` at runtime.
- **Fix:** Replaced all `~N[2026-06-14 12:00:00]` and `~N[2026-06-14 11:45:00]` with `~U[2026-06-14 12:00:00Z]` and `~U[2026-06-14 11:45:00Z]` (UTC DateTime) in gallery_live.ex deliveries_list and detail_header specimens.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex`
- **Commit:** 2a5219ca

**2. [Rule 1 - Bug] Missing :occurred_at field in timeline event specimens**
- **Found during:** Task 1 Playwright run (second error after datetime fix)
- **Issue:** `timeline.ex` accesses `event.occurred_at` when rendering each event row. The gallery `@specimens` timeline entries had `id`, `type`, `metadata`, `reject_reason` but no `occurred_at` — producing `KeyError: key :occurred_at not found` at runtime.
- **Fix:** Added `occurred_at: ~U[2026-06-14 11:59:00Z]` and `occurred_at: ~U[2026-06-14 12:00:00Z]` to all timeline event maps in both `"populated"` and `"highlighted-event"` specimens.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex`
- **Commit:** 2a5219ca

**3. [Rule 1 - Bug] String scenario keys in sidebar specimens crash Atom.to_string/1**
- **Found during:** Task 1 Playwright run (third error after previous fixes)
- **Issue:** `sidebar.ex` iterates `{scenario_name, _defaults}` tuples from the reflection list and calls `Atom.to_string(scenario_name)` — expects atom keys. Gallery sidebar specimens used string keys (`{"default", %{}}`, `{"reset", %{}}`, `{"with-name", %{name: "Ada"}}`), producing `ArgumentError: not an atom` at `:erlang.atom_to_binary("default")`.
- **Fix:** Changed all sidebar specimen scenario keys to atoms: `{:default, %{}}`, `{:reset, %{}}`, `{:"with-name", %{name: "Ada"}}`, `current_scenario: :"with-name"`.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex`
- **Commit:** 2a5219ca

**Note on flash testid naming:** The plan specified asserting `gallery-flash-error` and `gallery-flash-success`, but the actual gallery_live.ex specimen state labels are `"error-kind"` and `"success-kind"` — so the real testids are `gallery-flash-error-kind` and `gallery-flash-success-kind`. The assertions in structural.spec.js use the correct exact strings. The grep gate `grep -c "gallery-flash-error"` still passes because `gallery-flash-error-kind` contains the substring `gallery-flash-error`.

## Known Stubs

None — all assertions target real rendered data from GalleryLive specimens.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The gallery route was already added in Phase 97-06; this plan only adds e2e structural assertions against it.

## Self-Check

- `/Users/jon/projects/mailglass/mailglass_admin/e2e/structural.spec.js` — FOUND (modified)
- `/Users/jon/projects/mailglass/.planning/RATCHET-GAP-REGISTER.md` — FOUND (modified)
- `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/gallery_live.ex` — FOUND (modified)
- Commit 94b6e647 — FOUND (Task 1: structural.spec.js)
- Commit 553ca21f — FOUND (Task 2: RATCHET-GAP-REGISTER.md)
- Commit 2a5219ca — FOUND (Deviation: gallery_live.ex bug fixes)

## Self-Check: PASSED

---
*Phase: 97-cross-surface-component-layer*
*Completed: 2026-06-14*
