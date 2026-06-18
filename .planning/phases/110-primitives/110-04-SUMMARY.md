---
phase: 110-primitives
plan: "04"
subsystem: ui
tags: [phoenix-liveview, playwright, conformance, accessibility, heroicons]

# Dependency graph
requires:
  - phase: 110-03
    provides: Primitive public components, gallery state coverage, canonical stat_card/theme_picker specimens, and rebuilt static CSS.
provides:
  - PRIMITIVE-DRIFT-GATE for copied primitive/helper drift.
  - STATCARD-GATE for page-local stat helpers and non-canonical KPI markup.
  - ICON-EXISTS-GATE comparing admin hero-* use against the vendored inline Heroicons inventory.
  - Compiled-bundle Playwright proof for primitive states, themes, target sizes, contrast, focus, disabled distinction, icon meaning, and stat-card overflow.
affects: [110-primitives, 111-forms, 112-app-shell, 113-data-display, 116-ratchet]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - BASH_SOURCE-anchored conformance gates scan admin source from any cwd.
    - Primitive gallery structural proof uses compiled CSS and computed style assertions, not screenshots or pixel diffs.
    - Gallery repeated native controls receive specimen-scoped names so browser semantics remain real.

key-files:
  created:
    - .planning/phases/110-primitives/110-04-SUMMARY.md
  modified:
    - mailglass_admin/scripts/check-conformance.sh
    - mailglass_admin/assets/vendor/heroicons-inline.js
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs

key-decisions:
  - "Conformance gates own primitive drift, stat-card canonicalization, and icon inventory checks in one zero-Node shell lane."
  - "Missing vendored icons are fixed in heroicons-inline.js rather than weakening the gallery or icon-exists gate."
  - "Primitive proof stays structural: computed styles, DOM semantics, and local overflow checks replace screenshots, pixel diffs, axe, storage, and matchMedia additions."
  - "Repeated gallery theme_picker specimens use unique native radio group names so checked state remains independently testable."
  - "Preview URL assertion now matches the existing canonical width/theme ordering produced by PreviewLive."

patterns-established:
  - "ICON-EXISTS-GATE: derive required hero-* names from admin .ex files and compare them with the vendored plugin inventory via comm."
  - "Primitive gallery wrappers: each component/state/theme specimen is addressable by stable data-testid selectors across 320, 768, and 1280 viewports."
  - "Native grouped controls in repeated gallery cells must use specimen-scoped names to avoid cross-cell form-state collapse."

requirements-completed: [PRIM-01, PRIM-02, PRIM-03, PRIM-04, PRIM-05, PRIM-06, PRIM-07]

# Metrics
duration: 45min
completed: 2026-06-18
status: complete
---

# Phase 110 Plan 04: Primitive Proof Summary

**Fail-closed primitive gates and compiled-browser structural proof now prevent primitive copy drift, stat-card bypasses, missing inline icons, weak targets, broken native theme-picker semantics, and stat-card overflow regressions.**

## Performance

- **Duration:** 45min
- **Started:** 2026-06-18T22:34:00Z
- **Completed:** 2026-06-18T23:19:05Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `PRIMITIVE-DRIFT-GATE`, `STATCARD-GATE`, and `ICON-EXISTS-GATE` to `check-conformance.sh`, with cwd-independent pathing and zero Node/package additions.
- Extended `structural.spec.js` with Phase 110 primitive-gallery assertions across `nav_link`, `nav_pill`, `tenant_chip`, `theme_picker`, and `stat_card` in light, dark, and system wrappers at 320px, 768px, and 1280px.
- Proved native three-radio theme-picker semantics, 44px target floors, focus/non-text/text contrast, disabled distinction, icon meaning, stat-card no-wrap/tabular behavior, and local overflow handling against the compiled bundle.

## Task Commits

Each implementation task was committed atomically:

1. **Task 1: Add primitive drift, stat-card, and icon-exists gates** - `13d29d75` (`test`)
2. **Task 2: Add compiled-bundle structural proof for primitive states** - `595b8c37` (`test`)
3. **Task 3: Run final Phase 110 proof and source-scope audit** - `ff128dfb` (`test`, blocking verification assertion fix)

## Files Created/Modified

- `mailglass_admin/scripts/check-conformance.sh` - Adds primitive drift, stat-card canonicalization, and Heroicons inventory gates.
- `mailglass_admin/assets/vendor/heroicons-inline.js` - Adds the missing `chart-bar` and `eye` outline icons required by existing gallery usage.
- `mailglass_admin/priv/static/app.css` - Rebuilt committed CSS bundle after the vendored icon plugin changed.
- `mailglass_admin/e2e/structural.spec.js` - Adds Phase 110 primitive structural proof, computed-style parsing helpers, viewport matrix, and per-primitive state assertions.
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` - Gives each repeated theme-picker specimen a unique native radio group name.
- `mailglass_admin/test/mailglass_admin/preview_live_test.exs` - Aligns one URL-state assertion with PreviewLive's existing canonical `width` then `theme` ordering.

## Decisions Made

- Conformance remains a shell gate so Phase 110 does not add Node asset/tooling dependencies.
- Icon inventory failures are correctness failures: the vendored plugin must contain every admin `hero-*` name in use.
- Primitive structural proof avoids screenshots, pixel diffs, `@axe-core/playwright`, storage APIs, `matchMedia`, theme hooks, tenant listing, tenant switching, and brandbook scope.
- `system` theme proof remains absence-based: system wrappers emit no explicit `data-theme`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Added missing vendored icons required by ICON-EXISTS-GATE**
- **Found during:** Task 1 (Add primitive drift, stat-card, and icon-exists gates)
- **Issue:** Existing admin/gallery usage referenced `hero-chart-bar` and `hero-eye`, but `heroicons-inline.js` did not include those SVGs, so the new icon-exists gate correctly failed.
- **Fix:** Vendored the missing outline SVGs into `heroicons-inline.js` and rebuilt `priv/static/app.css`.
- **Files modified:** `mailglass_admin/assets/vendor/heroicons-inline.js`, `mailglass_admin/priv/static/app.css`
- **Verification:** `bash mailglass_admin/scripts/check-conformance.sh`; `cd mailglass_admin && bash scripts/check-conformance.sh`
- **Committed in:** `13d29d75`

**2. [Rule 1 - Bug] Fixed repeated gallery theme-picker radio-group collapse**
- **Found during:** Task 2 (Add compiled-bundle structural proof for primitive states)
- **Issue:** Multiple gallery theme-picker specimens shared the same native radio `name`, so only one checked radio could survive per page and per-cell native semantics were not independently true.
- **Fix:** Threaded a specimen id through `GalleryLive.render_specimen/2` and used it to scope each theme-picker group name.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex`
- **Verification:** `cd mailglass_admin && npm run test:operator-browser -- --grep "gallery|touch targets|theme_picker|stat_card"`
- **Committed in:** `595b8c37`

**3. [Rule 3 - Blocking verification issue] Corrected pre-existing PreviewLive URL assertion**
- **Found during:** Task 3 (Run final Phase 110 proof and source-scope audit)
- **Issue:** `mix verify.preview` failed because one test expected `?theme=dark&width=375`, while `PreviewLive` already canonicalized capture URLs as `?width=375&theme=dark`.
- **Fix:** Updated the assertion to match the existing canonical ordering.
- **Files modified:** `mailglass_admin/test/mailglass_admin/preview_live_test.exs`
- **Verification:** `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs:273 --warnings-as-errors`; `cd mailglass_admin && mix verify.preview`
- **Committed in:** `ff128dfb`

---

**Total deviations:** 3 auto-fixed (Rule 1: 1, Rule 2: 1, Rule 3: 1)
**Impact on plan:** All fixes were necessary for the plan's fail-closed proof. No package installs, screenshot/pixel tooling, storage hooks, tenant behavior, or brandbook scope were added.

## Issues Encountered

- The initial focused browser run exposed test-helper mechanics and the repeated radio-group bug; both were resolved before the full browser gate.
- `mix verify.preview` exposed the pre-existing query-order assertion mismatch described above; the test-only fix unblocked the required final gate.
- Expected Oban-unavailable warnings appeared during Mix and browser runs; they are existing local-test warnings and did not affect results.

## Verification

- `bash mailglass_admin/scripts/check-conformance.sh` - passed (`OK: design-system conformance clean.`)
- `cd mailglass_admin && bash scripts/check-conformance.sh` - passed
- `cd mailglass_admin && mix compile --warnings-as-errors` - passed
- `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs --warnings-as-errors` - passed (`83 tests, 0 failures`)
- `cd mailglass_admin && mix verify.support_contract.admin` - passed (`59 tests, 0 failures`)
- `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs:273 --warnings-as-errors` - passed (`1 test, 0 failures`)
- `cd mailglass_admin && mix verify.preview` - passed (`298 tests, 0 failures, 1 excluded`)
- `cd mailglass_admin && npm run test:operator-browser -- --grep "gallery|touch targets|theme_picker|stat_card"` - passed (`15 passed`)
- `cd mailglass_admin && npm run test:operator-browser` - passed (`63 passed`)
- `cd mailglass_admin && git diff --exit-code priv/static/ package.json package-lock.json` - passed
- `! rg -n '@axe-core/playwright|toHaveScreenshot|screenshot|localStorage|sessionStorage|matchMedia|phx-hook=.*theme|theme hook|tenant listing|auto-select|brandbook/' mailglass_admin/lib mailglass_admin/e2e mailglass_admin/package.json mailglass_admin/package-lock.json` - passed

## Known Stubs

None. The stub-pattern scan only found comments describing intentional test/gallery states, not hardcoded placeholder data flowing to UI rendering.

## Threat Flags

None. This plan added test/conformance coverage and vendored SVG inventory only; it introduced no new network endpoints, auth paths, file-access trust boundaries, or schema changes.

## User Setup Required

None.

## Self-Check: PASSED

- Created/modified files exist: `mailglass_admin/scripts/check-conformance.sh`, `mailglass_admin/assets/vendor/heroicons-inline.js`, `mailglass_admin/priv/static/app.css`, `mailglass_admin/e2e/structural.spec.js`, `mailglass_admin/lib/mailglass_admin/gallery_live.ex`, `mailglass_admin/test/mailglass_admin/preview_live_test.exs`, `.planning/phases/110-primitives/110-04-SUMMARY.md`.
- Task commits exist: `13d29d75`, `595b8c37`, `ff128dfb`.
