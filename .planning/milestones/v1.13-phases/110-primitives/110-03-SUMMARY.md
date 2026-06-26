---
phase: 110-primitives
plan: "03"
subsystem: ui
tags: [phoenix-liveview, phoenix-component, gallery, primitives, theme-picker, stat-card]

requires:
  - phase: 110-primitives
    provides: "Plans 110-01 and 110-02 public primitive API plus shell/stat-card consumer migrations"
provides:
  - "GalleryLive primitive specimens rendered through public MailglassAdmin.Components calls"
  - "Light, dark, and inherited-theme specimen wrappers for every gallery cell"
  - "Expanded primitive state rows for nav_link, nav_pill, tenant_chip, theme_picker, and stat_card"
  - "Clean rebuilt admin CSS bundle with no priv/static delta"
affects: [phase-110, phase-116, mailglass_admin, admin-design-system]

tech-stack:
  added: []
  patterns:
    - "Gallery primitive specimens call public Phoenix components rather than copied HEEx"
    - "System-theme gallery coverage is represented by absence of data-theme on a stable wrapper"
    - "Non-applicable primitive states are recorded adjacent to the specimen matrix"

key-files:
  created:
    - .planning/phases/110-primitives/110-03-SUMMARY.md
  modified:
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex

key-decisions:
  - "GalleryLive now renders nav_link, nav_pill, tenant_chip, theme_picker, and stat_card through MailglassAdmin.Components dispatchers."
  - "Every gallery specimen cell keeps the stable gallery-{component}-{state} anchor and adds a gallery-{component}-{state}-system wrapper without data-theme."
  - "Loading remains explicit: stat_card has a loading specimen, while navigation, tenant_chip, and theme_picker record loading as not applicable in the matrix."
  - "The CSS bundle was rebuilt and stayed bit-clean; no priv/static/app.css commit was needed for Plan 110-03."

patterns-established:
  - "Gallery public-component proof precedes Plan 110-04 structural drift and target-size gates."
  - "State rows are added without renaming existing non-obsolete gallery anchors."
  - "Token-scope gate-sensitive wording avoids slash-separated light/dark/system comments in admin lib sources."

requirements-completed: [PRIM-01, PRIM-02, PRIM-03, PRIM-04, PRIM-05]

duration: 8 min
completed: 2026-06-18
status: complete
---

# Phase 110 Plan 03: Primitive Gallery Summary

**The dev gallery now certifies real public primitive components across expanded state rows and light, dark, and inherited-theme wrappers.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-18T20:30:02Z
- **Completed:** 2026-06-18T20:38:19Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Replaced copied gallery HEEx for `nav_link`, `nav_pill`, `tenant_chip`, and the old binary `theme_toggle` with direct public `MailglassAdmin.Components` calls.
- Renamed the gallery primitive identity to `theme_picker` and added a `stat_card` gallery dispatcher.
- Added an inherited-theme wrapper for every specimen cell with stable `gallery-{component}-{state}-system` test ids and no explicit `data-theme`.
- Expanded primitive rows for hover-ready, focus-visible, disabled, selected, long-content, empty, loading, unavailable, and severity states as applicable.
- Rebuilt the admin CSS bundle and verified `priv/static/` stayed clean.

## Task Commits

Each task was committed atomically:

1. **Task 1: Render public primitives in light, dark, and system gallery wrappers** - `5587de19` (feat)
2. **Task 2: Add primitive state specimens and rebuild bundle** - `8f2a2a00` (feat)

**Plan metadata:** this summary commit

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` - Public primitive dispatchers, inherited-theme specimen wrapper, renamed `theme_picker` rows, stat-card dispatcher, and expanded primitive state matrix.
- `.planning/phases/110-primitives/110-03-SUMMARY.md` - Plan completion record.

## Decisions Made

- The gallery uses the public primitive API as the certification surface; no gallery-only API or copied primitive HEEx remains for the named atoms.
- The inherited-theme wrapper is the system specimen proof: stable test id, same public component call, and no explicit `data-theme`.
- Non-applicable loading/interaction states stay adjacent to the source matrix so Plan 110-04 gates can distinguish intentional non-applicability from missing coverage.
- No static CSS bundle delta was committed because the asset build was bit-clean after the gallery class changes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Avoided token-scope conformance false positive**

- **Found during:** Plan-level verification after Task 2.
- **Issue:** A module-doc sentence used slash-separated theme wording that matched the Phase 109 token-scope grep gate even though runtime behavior was correct.
- **Fix:** Reworded the comment to avoid the forbidden pattern while preserving the inherited-theme wrapper behavior.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex`
- **Verification:** `bash mailglass_admin/scripts/check-conformance.sh` returned `OK: design-system conformance clean.`
- **Committed in:** `8f2a2a00`

---

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** The fix kept the existing conformance gate green without changing runtime behavior or expanding scope.

## Issues Encountered

- `mix compile` and `mix mailglass_admin.assets.build` briefly waited on the shared build lock during parallel verification commands, then completed successfully.
- The focused Playwright gallery lane emitted existing Oban-absent warnings from the test server; the gallery tests still passed 5/5.

## User Setup Required

None - no external service configuration required.

## Verification

- `rg -n 'Components\.(nav_link|nav_pill|tenant_chip|theme_picker|stat_card)' mailglass_admin/lib/mailglass_admin/gallery_live.ex` -> all five public primitive dispatchers found.
- `rg -n 'theme_toggle|defp render_specimen\(%\{component: :theme_toggle\}' mailglass_admin/lib/mailglass_admin/gallery_live.ex || true` -> no matches.
- `rg -n 'nav_link.*hover-ready|nav_link.*focus-visible|nav_pill.*hover-ready|nav_pill.*focus-visible|theme_picker.*focus-visible|stat_card.*loading|loading.*not applicable' mailglass_admin/lib/mailglass_admin/gallery_live.ex` -> planned state rows and loading notes found.
- `rg -n 'nav_link.*disabled|nav_pill.*disabled|tenant_chip.*long-tenant|theme_picker.*system-selected|theme_picker.*dark-selected|stat_card.*long-value|stat_card.*unavailable' mailglass_admin/lib/mailglass_admin/gallery_live.ex` -> planned disabled, selected, long, and unavailable rows found.
- `cd mailglass_admin && mix compile --warnings-as-errors` -> success.
- `cd mailglass_admin && mix mailglass_admin.assets.build` -> success.
- `cd mailglass_admin && git diff --exit-code priv/static/` -> success.
- `cd mailglass_admin && npm run test:operator-browser -- --grep "gallery"` -> 5 tests passed.
- `bash mailglass_admin/scripts/check-conformance.sh` -> `OK: design-system conformance clean.`

## Known Stubs

None.

## Self-Check: PASSED

- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` exists.
- `.planning/phases/110-primitives/110-03-SUMMARY.md` exists.
- Commit `5587de19` exists.
- Commit `8f2a2a00` exists.
- No tracked files were deleted by task commits.
- No package manifest, recipient-facing email template, or brandbook token files changed.

## Next Phase Readiness

Ready for Plan 110-04 to add the PRIMITIVE-DRIFT, STATCARD, ICON-EXISTS, target-size, system-wrapper, and overflow structural gates against the widened real-component gallery.

---
*Phase: 110-primitives*
*Completed: 2026-06-18*
