---
phase: 92-surface-propagation
plan: 02
subsystem: admin-ui
tags: [brand, svg, phoenix, liveview, tailwind]

requires:
  - phase: 91-folder-adoption-and-reference-reconciliation
    provides: canonical brandbook assets at brandbook/
provides:
  - Theme-aware sealed-flap admin logo rendering
  - Font-free admin static logo asset at the stable logo.svg route
  - Regression coverage for the admin logo outline contract
affects: [phase-93-hexd-logos, admin-preview-bundle]

tech-stack:
  added: []
  patterns:
    - Inline currentColor SVG for theme-aware admin chrome
    - Existing mix verify.preview gate as bundle-clean proof

key-files:
  created:
    - .planning/phases/92-surface-propagation/92-02-SUMMARY.md
  modified:
    - mailglass_admin/priv/static/mailglass-logo.svg
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/test/mailglass_admin/bundle_test.exs
    - mailglass_admin/priv/static/app.css

key-decisions:
  - "Admin logo rendering uses inline currentColor SVG while the stable logo.svg asset route remains available."
  - "The rebuilt admin CSS bundle is committed because mix verify.preview requires priv/static/ to be clean after asset build."

patterns-established:
  - "Admin brand lockups use outlined paths and currentColor instead of live text or font-dependent SVG."
  - "Logo source assertions live beside the existing mailglass_admin bundle size budget."

requirements-completed: [SURF-03]

duration: 38min
completed: 2026-06-13
---

# Phase 92 Plan 02: Admin Wordmark Surface Summary

**Theme-aware sealed-flap admin logo with font-free static asset, inline currentColor rendering, and preview-bundle regression proof**

## Performance

- **Duration:** 38 min
- **Started:** 2026-06-13T05:11:30Z
- **Completed:** 2026-06-13T05:49:30Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Replaced the shipped v0.1 admin wordmark placeholder with the sealed-flap lockup as outlined SVG paths.
- Updated `Components.logo/1` to render the same lockup inline with `currentColor`, preserving caller-supplied classes and accessible naming.
- Added regression coverage banning live text and font dependencies in the admin logo asset.
- Rebuilt and committed the admin static bundle so `mix verify.preview` passes its bundle-clean gate.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace the admin static logo with sealed-flap paths** - `6746e009` (chore)
2. **Task 2: Make the rendered admin logo theme-aware** - `0d01759f` (chore)
3. **Task 3: Extend logo regression tests and run admin verification** - `bc7d4f66` (test)

## Files Created/Modified

- `mailglass_admin/priv/static/mailglass-logo.svg` - Stable served logo asset replaced with outlined currentColor sealed-flap paths and deterministic intrinsic size.
- `mailglass_admin/lib/mailglass_admin/components.ex` - `logo/1` now renders the sealed-flap lockup inline for light/dark theme inheritance.
- `mailglass_admin/test/mailglass_admin/bundle_test.exs` - Added no-`<text>`, no-`font-family`, and no-`letter-spacing` logo assertions.
- `mailglass_admin/priv/static/app.css` - Rebuilt generated admin bundle required by `mix verify.preview`.

## Decisions Made

- Used the monochrome/currentColor brand asset strategy rather than copying the light-surface primary lockup into dark admin chrome.
- Kept the public `<mount>/logo.svg` route unchanged; the inline component is only for theme-safe UI rendering.
- Committed the generated CSS bundle after `mailglass_admin.assets.build` changed it, because the admin verification gate requires `priv/static/` to be clean.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Committed rebuilt admin CSS bundle**
- **Found during:** Task 3 (Extend logo regression tests and run admin verification)
- **Issue:** The first `mix verify.preview` run passed compile/tests/assets but failed at `cmd git diff --exit-code priv/static/` because `mailglass_admin.assets.build` rewrote `priv/static/app.css`.
- **Fix:** Staged the rebuilt `mailglass_admin/priv/static/app.css` artifact and reran `mix verify.preview` from the package directory.
- **Files modified:** `mailglass_admin/priv/static/app.css`
- **Verification:** `cd mailglass_admin && mix verify.preview` exited 0 with 192 tests passing and the bundle-clean gate green.
- **Committed in:** `bc7d4f66`

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Required for the existing verification gate; no extra product surface or Phase 93 work was added.

## Issues Encountered

- `mix format mailglass_admin/lib/mailglass_admin/components.ex` converted existing `attr` declarations to call syntax, which would have broken the plan's exact `attr :class, :any, default: nil` source assertion. The component file was reset to the task baseline and the scoped logo edit was reapplied without formatter churn.
- A staging command was accidentally run from `mailglass_admin/` using a repo-root path; Git rejected it and no files changed. The command was rerun from the repo root.

## User Setup Required

None - no external service configuration required.

## Verification

- `rg -n '<text|font-family|letter-spacing|url\(|href=' mailglass_admin/priv/static/mailglass-logo.svg` printed no lines.
- `rg '<svg|currentColor|aria-label="mailglass"' mailglass_admin/lib/mailglass_admin/components.ex` exited 0.
- `rg '<text|font-family|letter-spacing' mailglass_admin/test/mailglass_admin/bundle_test.exs` exited 0.
- `cd mailglass_admin && mix verify.preview` exited 0.

## Known Stubs

None.

## Next Phase Readiness

SURF-03 is complete. Phase 93 can proceed with HexDocs logo/favicon wiring and release hardening without inheriting an admin wordmark deferral.

## Self-Check: PASSED

- Files exist: `mailglass_admin/priv/static/mailglass-logo.svg`, `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/test/mailglass_admin/bundle_test.exs`, `mailglass_admin/priv/static/app.css`.
- Commits found: `6746e009`, `0d01759f`, `bc7d4f66`.
- Working tree was clean before summary creation.

---
*Phase: 92-surface-propagation*
*Completed: 2026-06-13*
