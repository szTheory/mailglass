---
phase: 113-data-display
plan: "04"
subsystem: ui
tags: [playwright, structural-testing, tailwind, daisyui, gallery, conformance, data-state, responsive]

# Dependency graph
requires:
  - phase: 113-01
    provides: "Components.data_state/1 with four kinds + heroicons (inbox, lock-closed, clock)"
  - phase: 113-02
    provides: "deliveries_list dual presentation (operator-deliveries-table/-cards) + data_state wiring"
  - phase: 113-03
    provides: "records_list dual presentation (inbound-records-table/-cards) + data_state wiring"
provides:
  - "Gallery specimens for data_state (4 kinds), deliveries_list table+cards+long-value, records_list table+cards+long-value"
  - "Playwright structural proof for DATA-01 (responsive), DATA-04 (badges+aria), DATA-05 (overflow)"
  - "STATUS-BADGE-GATE and DATA-STATE-GATE in check-conformance.sh"
  - "Bit-clean rebuilt priv/static/app.css with Phase 113 class coverage"
affects: ["future-gallery-additions", "ci-conformance-pipeline", "data-display-regression-prevention"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Gallery specimens: render_specimen/1 clause + @specimens tuple auto-inherits light/dark/system harness"
    - "Overflow containment: overflow-x-auto on table div wrapper (not on table itself) to contain fixed-width columns within aside"
    - "Responsive Playwright pattern: setViewportSize + toBeVisible/toBeHidden on testid pairs"
    - "Cross-presentation click: scope to operator-deliveries-cards/inbound-records-cards at 390px, operator-delivery-row/inbound-record-row work in both"
    - "noMatchRow visibility filter: filter({visible: true}) to get visible row regardless of responsive breakpoint"

key-files:
  created:
    - ".planning/phases/113-data-display/113-04-SUMMARY.md"
  modified:
    - "mailglass_admin/lib/mailglass_admin/gallery_live.ex"
    - "mailglass_admin/e2e/structural.spec.js"
    - "mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex"
    - "mailglass_admin/lib/mailglass_admin/inbound/records_list.ex"
    - "mailglass_admin/scripts/check-conformance.sh"
    - "mailglass_admin/priv/static/app.css"
    - "mailglass_admin/test/mailglass_admin/inbound/components_test.exs"
    - "mailglass_admin/test/mailglass_admin/voice_test.exs"

key-decisions:
  - "Body overflow at 320/768px: scoped DATA-05 assertion to list container offsetWidth vs aside width, not scrollWidth — avoids false-positive from overflow-x-auto internal scroll"
  - "Gallery overflow test: omit gallery-cell-level overflow assertion at 320px (gallery flex-wrap forces narrow cells; live page at 320px is the meaningful check)"
  - "noMatchRow() visibility filter: add filter({visible: true}) so it works at both 390px (cards visible) and 1280px (table visible) without separate viewport-conditional paths"
  - "Pre-existing preview theme toggle failure: confirmed pre-existing before Phase 113 (git stash test); excluded from Phase 113 pass criteria"

patterns-established:
  - "Conformance gate shape: STATUS-BADGE-GATE = positive grep (module must call canonical primitive) + negative grep (no defp badge helper)"
  - "DATA-STATE-GATE: assert each of four data-state-* string literals present in components.ex; confirm single public def"
  - "ExUnit copy assertions must be updated in sync with UI-SPEC copy changes (voice_test + components_test)"

requirements-completed: [DATA-01, DATA-02, DATA-03, DATA-04, DATA-05]

# Metrics
duration: 24min
completed: 2026-06-19
status: complete
---

# Phase 113 Plan 04: Data-Display Certification and Gate Arming Summary

**Gallery specimens (10 cells: 4 data-state kinds, 3 deliveries_list, 3 records_list), Playwright structural proof (responsive/overflow/badge/aria-selected), STATUS-BADGE-GATE + DATA-STATE-GATE in check-conformance.sh, bit-clean priv/static/app.css rebuild — DATA-01..05 closed.**

## Performance

- **Duration:** ~24 min
- **Started:** 2026-06-19T21:47:46Z
- **Completed:** 2026-06-19T22:12:00Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Added 10 gallery specimen entries (data_state × 4 kinds, deliveries_list × 3, records_list × 3) with auto-inherited light/dark/system theme wrapping (no matchMedia/localStorage added)
- Extended structural.spec.js with 9 new Phase 113 tests proving DATA-01 (responsive breakpoints), DATA-04 (status/outcome badges visible in both presentations, aria-selected in both), DATA-05 (overflow containment), DATA-03 (four distinct data-state kinds), and D-06 (synchronous invariant)
- Migrated all legacy `operator-deliveries-list`/`noMatchRow` consumers to survive the dual-presentation refactor without orphaned selectors
- Armed STATUS-BADGE-GATE (routes badge rendering through Components.status_badge/1) and DATA-STATE-GATE (four distinct testid literals required) in check-conformance.sh
- Rebuilt priv/static/app.css bit-clean (two consecutive builds produce identical MD5; `git diff --exit-code -- priv/static/app.css` exits 0)

## Task Commits

Each task was committed atomically:

1. **Task 1: Gallery specimens for data_state, deliveries_list, records_list, long-value stress** - `9a70caac` (feat)
2. **Task 2: Extend structural spec with responsive/overflow/status/data-state proof; migrate legacy consumers** - `c5f7d03b` (feat)
3. **Task 3: Extend conformance gates, rebuild bit-clean CSS bundle, update stale copy assertions** - `ee01e6a8` (feat)

## Files Created/Modified
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` - Added render_specimen/1 clauses for data_state + records_list; extended deliveries_list dispatcher; added 10 @specimens entries
- `mailglass_admin/e2e/structural.spec.js` - 9 new Phase 113 tests; fixed openOperator/noMatchRow/master-detail legacy consumers; updated inbound copy assertions
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` - Added overflow-x-auto to table wrapper (Rule 2 auto-fix)
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` - Added overflow-x-auto to table wrapper (Rule 2 auto-fix)
- `mailglass_admin/scripts/check-conformance.sh` - Added STATUS-BADGE-GATE and DATA-STATE-GATE
- `mailglass_admin/priv/static/app.css` - Rebuilt bit-clean (Phase 113 class coverage included)
- `mailglass_admin/test/mailglass_admin/inbound/components_test.exs` - Updated empty-state copy assertion to UI-SPEC strings
- `mailglass_admin/test/mailglass_admin/voice_test.exs` - Updated LD-03 assertion to Phase 113 UI-SPEC copy

## Decisions Made
- Scoped DATA-05 overflow assertion to `element.offsetWidth <= aside.width + 1` rather than `scrollWidth - clientWidth <= 1`: with `overflow-x-auto` on the table wrapper, the table's internal scroll is contained but the wrapper's `scrollWidth` is still large. The user-visible contract (no page-level horizontal scroll) is proven by the aside containment check.
- Omitted gallery overflow assertions at 320px: gallery cells in a three-theme flex-wrap row are each ~100px wide at 320px total; the component INSIDE (operator-deliveries-cards) proved by the live-page DATA-05 test which uses full-width viewport.
- Updated voice_test LD-03 from "No InboundMessages match these filters" to "No records match the current filters." — the UI-SPEC deliberately replaced the domain-noun formulation with a simpler "No records" title pattern per Plan 03 design decision.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Table wrapper overflow-x-auto missing in deliveries_list.ex and records_list.ex**
- **Found during:** Task 2 (structural spec overflow test)
- **Issue:** `table-fixed` with 6 fixed-width columns (total ~640px min) in a 40%-of-768px (~307px) column caused `offsetWidth` to exceed the aside container width, creating page-level horizontal scroll at 768px
- **Fix:** Added `overflow-x-auto` to `<div class="hidden md:block">` wrapper in both deliveries_list.ex and records_list.ex
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`
- **Verification:** `assertNoElementHorizontalOverflow` test passes at both 320px and 768px
- **Committed in:** `c5f7d03b` (Task 2 commit)

**2. [Rule 1 - Bug] Legacy operator state coverage test used hidden stub testids**
- **Found during:** Task 2 (test run discovered hidden stub div toBeVisible fails)
- **Issue:** `getByTestId("operator-empty-filtered").toBeVisible()` targets the `<div style="display:none">` stub, not the visible `<section data-testid="data-state-empty">` rendered by Components.data_state/1
- **Fix:** Changed to `page.getByTestId("operator-deliveries-list-card").getByTestId("data-state-empty")` and use `operator-empty-reset` for the clear-filters button assertion
- **Files modified:** `mailglass_admin/e2e/structural.spec.js`
- **Verification:** `Operator: per-state delivery cells are reachable by URL` passes
- **Committed in:** `c5f7d03b` (Task 2 commit)

**3. [Rule 1 - Bug] `noMatchRow()` and master-detail 390px click used hidden table rows**
- **Found during:** Task 2 (test timeouts at 390px viewport)
- **Issue:** At 390px, `inbound-record-row` matches `<tr>` elements inside the `hidden md:block` table (display:none at mobile). Playwright's `.first()` returns the first DOM match which is the hidden tr.
- **Fix:** Added `filter({visible: true})` to `noMatchRow()`. At 390px master-detail click, scoped to `operator-deliveries-cards`/`inbound-records-cards` wrapper.
- **Files modified:** `mailglass_admin/e2e/structural.spec.js`
- **Verification:** Both master-detail grid tests pass at 390px
- **Committed in:** `c5f7d03b` (Task 2 commit)

**4. [Rule 1 - Bug] Stale ExUnit copy assertions for UI-SPEC strings changed in Plan 03**
- **Found during:** Task 3 (mix verify.preview exposed 2 ExUnit failures)
- **Issue:** `inbound/components_test.exs` checked `"No InboundMessages match these filters"` and `voice_test.exs` checked same — both strings were replaced in Plan 03 with "No records match the current filters."
- **Fix:** Updated both test assertions to UI-SPEC copy; removed outdated body copy check from components_test
- **Files modified:** `mailglass_admin/test/mailglass_admin/inbound/components_test.exs`, `mailglass_admin/test/mailglass_admin/voice_test.exs`
- **Verification:** `mix verify.preview` exits 0 (384 tests, 0 failures)
- **Committed in:** `ee01e6a8` (Task 3 commit)

---

**Total deviations:** 4 auto-fixed (2 Rule 1 bugs, 1 Rule 2 missing critical, 1 Rule 1 stale test)
**Impact on plan:** All auto-fixes necessary for correctness. The overflow-x-auto fix and testid migration were direct enablers of the DATA-05 and operator state coverage proof. No scope creep.

## Issues Encountered
- Pre-existing `Preview: admin chrome and preview frame toggles are independent` test failure (line 1150 in structural.spec.js): confirmed failing before Phase 113 via git stash test. Grep `"responsive"` in the parent describe block name causes it to be picked up by the Phase 113 test filter. Not fixed as it is out of scope; noted in SUMMARY.
- Gallery long-value overflow assertion at 320px was not viable: gallery flex-wrap cells are ~100px each at 320px — the inner component has no room. Proven via the live-page overflow test instead.

## Known Stubs
None - all specimens render real component outputs. Gallery long-value stress uses realistic long UUIDs and IDs. No placeholder text or empty data sources.

## Threat Flags
None - plan-04 adds only test infrastructure, gallery specimens, conformance gates, and CSS bundle. No new network endpoints, auth paths, or schema changes.

## Self-Check

### Files verified:
- `./scripts/check-conformance.sh` exits 0: CONFIRMED
- `mix verify.preview` 384 tests, 0 failures: CONFIRMED
- `npm run test:operator-browser --grep "responsive|stat_card|status|overflow|data.state|Data"` 28 passed, 1 pre-existing failure: CONFIRMED
- `git diff --exit-code -- priv/static/app.css` exits 0 (bit-clean): CONFIRMED

### Commits verified:
- `9a70caac`: feat(113-04): gallery specimens — FOUND
- `c5f7d03b`: feat(113-04): structural spec extension — FOUND
- `ee01e6a8`: feat(113-04): conformance gates + CSS rebuild — FOUND

## Self-Check: PASSED

## Next Phase Readiness
- Phase 113 is COMPLETE: DATA-01..05 closed with structural proof, conformance gates armed, CSS bundle bit-clean
- `check-conformance.sh` STATUS-BADGE-GATE and DATA-STATE-GATE are armed; CI will catch badge drift and data-state regressions
- Gallery lab has table/cards/data-state specimens with full light/dark/system coverage for future regression testing
- No blockers for subsequent phases

---
*Phase: 113-data-display*
*Plan: 04*
*Completed: 2026-06-19*
