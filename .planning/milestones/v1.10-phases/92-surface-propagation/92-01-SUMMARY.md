---
phase: 92-surface-propagation
plan: 01
subsystem: docs
tags: [brandbook, readme, github-social-preview, playwright, png-export]

# Dependency graph
requires:
  - phase: 91-folder-adoption-and-reference-reconciliation
    provides: canonical brandbook path and fable brand assets under brandbook/
provides:
  - Root README header reference to the canonical readme-header SVG
  - 2400x1260 GitHub social-preview PNG generated from the canonical SVG
  - Brandbook export policy documenting the single v1.10 PNG exception and manual GitHub upload
affects: [phase-92, phase-93, brandbook, github-social-preview]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - SVG-first brand propagation with a single documented raster exception
    - Playwright viewport screenshot export for social-preview PNGs

key-files:
  created:
    - brandbook/examples/og-card.png
  modified:
    - README.md
    - brandbook/README.md

key-decisions:
  - "Root README uses brandbook/examples/readme-header.svg directly as the first visible brand surface."
  - "brandbook/examples/og-card.png is the only committed v1.10 binary exception for GitHub social preview upload."
  - "GitHub social-preview upload remains manual because no documented write API exists."

patterns-established:
  - "README brand surfaces should reference canonical brandbook SVG assets directly instead of recomposing or rasterizing them."
  - "Generated social-preview PNGs must be validated by dimensions and size before commit."

requirements-completed: [SURF-01, SURF-02]

# Metrics
duration: 10 min
completed: 2026-06-13
---

# Phase 92 Plan 01: README and Social Preview Surfaces Summary

**Root README brand header plus a validated 2400x1260 GitHub social-preview PNG with durable export and upload policy**

## Performance

- **Duration:** 10 min
- **Started:** 2026-06-13T05:30:00Z
- **Completed:** 2026-06-13T05:40:26Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added the canonical `brandbook/examples/readme-header.svg` at the top of the root README before the H1 and badges.
- Exported `brandbook/examples/og-card.png` from `brandbook/examples/og-card.svg` with the planned Playwright command.
- Updated `brandbook/README.md` so the SVG-first export policy records `og-card.png` as the single v1.10 committed PNG exception and documents GitHub Settings upload.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the canonical README header** - `eb3477b4` (`docs`)
2. **Task 2: Export the social-preview PNG** - `1914d1e7` (`docs`)
3. **Task 3: Document export policy and GitHub upload steps** - `7282d64f` (`docs`)

## Files Created/Modified

- `README.md` - Adds the centered canonical README header image block above the existing H1.
- `brandbook/examples/og-card.png` - Committed 2400x1260 PNG export for GitHub social preview upload.
- `brandbook/README.md` - Documents the single PNG exception, exact export command, validation requirements, and manual GitHub Settings upload path.

## Decisions Made

- Used the canonical SVG directly in the README, preserving the existing README product and installation structure.
- Committed only `brandbook/examples/og-card.png` as the plan's binary artifact; no avatars, alternate social sizes, favicons, screenshots, or other rasters were added.
- Kept social-preview upload as a documented maintainer action because GitHub provides no documented write API for setting this surface.

## Verification

- `rg 'brandbook/examples/readme-header.svg' README.md` passed.
- `rg 'width="580"' README.md` passed.
- `rg -n '<text|font-family|url\\(|href=' brandbook/examples/readme-header.svg` returned no matches.
- `npx playwright screenshot --viewport-size=2400,1260 "file://$PWD/brandbook/examples/og-card.svg" brandbook/examples/og-card.png` exited 0.
- `identify -format '%wx%h' brandbook/examples/og-card.png` printed `2400x1260`.
- `stat -f%z brandbook/examples/og-card.png` printed `59562`, below 1 MB.
- `rg 'brandbook/examples/og-card\\.png|Social preview|Upload an image|2400x1260' brandbook/README.md` passed.
- `git diff --name-only --diff-filter=A HEAD~3..HEAD | rg '\\.(png|jpg|jpeg|gif|webp|avif|ico)$'` returned only `brandbook/examples/og-card.png`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

An extra README ordering assertion initially used `ruby`, but the repo has no Ruby version configured for that command. The assertion was rerun with shell tools and passed. This did not change implementation scope.

## Known Stubs

None.

## User Setup Required

Manual GitHub configuration remains required: open repository Settings, find Social preview, choose Edit, choose Upload an image, and select `brandbook/examples/og-card.png`.

## Next Phase Readiness

Plan 92-02 can proceed to the admin wordmark surface. Phase 93 remains untouched; HexDocs wiring, ex_doc SVG sizing, and release hardening are still out of scope for this plan.

## Self-Check: PASSED

- Found `.planning/phases/92-surface-propagation/92-01-SUMMARY.md`.
- Found task commits `eb3477b4`, `1914d1e7`, and `7282d64f`.
- Verified no newly added raster artifact in the plan diff except `brandbook/examples/og-card.png`.

---
*Phase: 92-surface-propagation*
*Completed: 2026-06-13*
