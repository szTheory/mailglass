---
phase: 109-foundations-gate-tightening
plan: "04"
subsystem: ui
tags: [playwright, accessibility, wcag, daisyui, design-system]
requires:
  - phase: 109-03
    provides: "Hard conformance gates and ratchet schema v3 system cells"
provides:
  - "Structural system-theme proof for default/system root and preview shell behavior"
  - "WCAG-style structural assertions for focus appearance, focus not obscured, non-text contrast, and 44px target-size coverage"
  - "Replay modal panel-above-scrim hit-test coverage for operator and inbound modals"
  - "Final Phase 109 validation proof with package, bundle, scope-creep, ExUnit, and browser gates green"
affects: [phase-109, phase-110, phase-116, mailglass_admin, admin-design-system]
tech-stack:
  added: []
  patterns:
    - "System/default theme is proved by no explicit data-theme plus Playwright colorScheme emulation"
    - "Overlay stacking is proved with document.elementFromPoint rather than screenshots"
    - "Target-size and focus appearance checks remain structural/computed-style based"
key-files:
  created:
    - .planning/phases/109-foundations-gate-tightening/109-04-SUMMARY.md
  modified:
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/priv/static/app.css
key-decisions:
  - "System theme remains absence of explicit data-theme; tests emulate OS light/dark before navigation instead of adding JS theme resolution."
  - "Replay modal stacking is asserted with elementFromPoint at the panel centroid so scrim/panel z-layer regressions fail structurally."
  - "Preview icon theme controls use min-w-11 as well as min-h-11 so square icon buttons meet the 44px target floor."
patterns-established:
  - "Browser structural tests can lock WCAG 2.2 interaction facts without axe, screenshots, or pixel baselines."
  - "Icon-only controls must carry both height and width floors when the target-size floor applies."
requirements-completed: [REL-01, FND-01, FND-02, FND-04, FND-05]
duration: 9 min
completed: 2026-06-18
status: complete
---

# Phase 109 Plan 04: Structural WCAG/System Proof Summary

**System-theme, overlay stacking, focus appearance, and target-size behavior are now locked by structural Playwright assertions with the full Phase 109 validation battery green.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-06-18T17:13:30Z
- **Completed:** 2026-06-18T17:22:46Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added Playwright helpers for 44px target-size checks, focus appearance plus Focus Not Obscured, system/default `data-theme` absence, and `elementFromPoint` modal hit-testing.
- Added system/default preview assertions that call `page.emulateMedia({ colorScheme: "light" })` and `page.emulateMedia({ colorScheme: "dark" })` before navigation, proving root HTML and preview shell emit no explicit `data-theme`.
- Extended explicit light/dark preview assertions to cover both root HTML and preview shell values.
- Added operator/inbound replay modal centroid hit-tests proving modal panels are above their scrims.
- Extended focus checks to require a visible >=2px indicator, non-text contrast >=3:1, and no center-point obstruction.
- Extended target-size coverage across operator nav, replay modal actions, preview theme/frame buttons, and preview sidebar summary controls.
- Ran and recorded the final Phase 109 proof battery.

## Task Commits

1. **Task 1: Extend structural Playwright assertions for system theme and WCAG 2.2** - `4a0f2ab6` (test)
2. **Task 2: Run final proof and scope-creep audit** - verification-only; evidence recorded in this summary

**Plan metadata:** this summary commit

## Files Created/Modified

- `mailglass_admin/e2e/structural.spec.js` - Adds system/default theme, focus appearance, target-size, and modal hit-test assertions.
- `mailglass_admin/lib/mailglass_admin/preview_live.ex` - Adds `min-w-11` to preview admin/frame icon buttons so they meet the target-size floor.
- `mailglass_admin/priv/static/app.css` - Rebuilt committed CSS bundle with the generated `min-w-11` utility.

## Decisions Made

- System mode remains root/CSS behavior only: no JS hook, storage, picker UI, or explicit `data-theme="system"` was added.
- Modal stacking proof uses `document.elementFromPoint` at panel centroids, which catches panel/scrim z-layer regressions without screenshot infrastructure.
- Target-size checks round bounding boxes to rendered pixels because Chromium may report a 44px CSS floor as a 43.89px subpixel measurement.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed preview theme/frame icon buttons below the 44px width floor**

- **Found during:** Task 1 focused Playwright run.
- **Issue:** The new target-size assertion showed the preview admin and frame icon buttons were 32px wide because they had `min-h-11` but no matching width floor.
- **Fix:** Added `min-w-11` to both preview icon buttons and rebuilt `mailglass_admin/priv/static/app.css`.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/preview_live.ex`, `mailglass_admin/priv/static/app.css`
- **Verification:** `npm run test:operator-browser -- --grep "system|replay modal|focus|touch targets"` passed 11 tests after the fix.
- **Committed in:** `4a0f2ab6`

---

**Total deviations:** 1 auto-fixed (blocking target-size defect).
**Impact on plan:** The source fix was required for the planned WCAG target-size assertion to prove green on current code; no scope creep or dependency changes.

## Issues Encountered

Expected optional Oban warnings appeared in Mix and browser-server runs. `mix verify.preview` also emitted existing Elixir eval deprecation warnings from `mix_config_test.exs`; all tests passed.

## User Setup Required

None - no external service configuration required.

## Verification

- `gh pr view 86 --json state,mergedAt --jq '.state == "MERGED" and (.mergedAt != null)'` -> `true`.
- `bash mailglass_admin/scripts/check-conformance.sh` -> `OK: design-system conformance clean.`
- `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` -> 4 tests, 0 failures.
- `cd mailglass_admin && mix verify.support_contract.admin` -> 59 tests, 0 failures.
- `cd mailglass_admin && mix verify.preview` -> 256 tests, 0 failures, 1 excluded.
- `cd mailglass_admin && npm run test:operator-browser` -> 58 tests, 0 failures.
- `cd mailglass_admin && git diff --exit-code priv/static/` -> passed.
- `git diff --exit-code -- mailglass_admin/package.json mailglass_admin/package-lock.json` -> passed.
- `test "$(rg -n '@axe-core/playwright|toHaveScreenshot|\bscreenshot\b|phx-hook=.*theme|localStorage|sessionStorage|mailglass_admin:theme|script[^>]*theme|theme-picker|theme_picker' mailglass_admin/e2e/structural.spec.js mailglass_admin/package.json mailglass_admin/package-lock.json mailglass_admin/lib/mailglass_admin | wc -l | tr -d ' ')" = "0"` -> passed.

## Self-Check: PASSED

All four Phase 109 plans now have summaries, the final validation battery is green, package manifests are unchanged, the CSS bundle is clean after rebuild, no axe dependency or screenshot baseline was added, no theme hook/storage/picker UI landed, and no pillar re-score artifact was introduced.

## Next Phase Readiness

Phase 109 is complete. Phase 110 can build primitives on a tightened foundation with z-layer, focus, system-theme, ratchet schema, structural WCAG, and scope-creep guards already armed.

---
*Phase: 109-foundations-gate-tightening*
*Completed: 2026-06-18*
