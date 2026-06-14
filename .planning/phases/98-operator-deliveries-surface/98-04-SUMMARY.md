---
phase: 98-operator-deliveries-surface
plan: 04
subsystem: ui
tags: [operator, playwright, responsive, accessibility, static-assets]

requires:
  - phase: 98-operator-deliveries-surface
    provides: Operator IA, copy cleanup, state testids, and tracking-clean component surface
provides:
  - Single browser seed reaches the suppressed delivery state without shifting existing index-pinned rows
  - Browser coverage for operator state reachability, failed-row audit flow, responsive grid, one-h1, and touch targets
  - Rebuilt operator CSS bundle with mounted asset loading fixed for /ops/mail
affects: [operator, deliveries, browser-gate, phase-99-gate-flip]

tech-stack:
  added: []
  patterns:
    - Operator browser specs drive all state variants from one seeded dataset and URL params
    - Root layout computes mounted CSS asset URLs from request path for root and nested admin mounts
    - Replay modal uses overlay-owned scrolling so long target lists remain reachable

key-files:
  created:
    - .planning/phases/98-operator-deliveries-surface/98-04-SUMMARY.md
  modified:
    - mailglass_admin/test/support/operator_fixtures.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/e2e/operator.spec.js
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/lib/mailglass_admin/controllers/assets.ex
    - mailglass_admin/lib/mailglass_admin/layouts.ex
    - mailglass_admin/lib/mailglass_admin/layouts/root.html.heex
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/priv/static/app.css

key-decisions:
  - "The suppressed browser row is timed at hours_ago(8), preserving existing operator.spec.js row indices 0-4."
  - "Filtered-empty browser coverage uses status=queued because OperatorLive intentionally allowlists delivery statuses and rejects bounced as a delivery status."
  - "The /ops/mail root page must emit an absolute mounted CSS URL; bare relative css-* hrefs resolve to /ops/css-* and leave the operator surface unstyled."
  - "Ambiguous replay selection is asserted through keyboard interaction with the accessible radio, matching the sr-only radio contract."

patterns-established:
  - "Responsive grid browser assertions parse computed grid-template-columns and compare column ratios at 768 and 1440."
  - "Operator empty-state testids live on the visible empty-state container, not on hidden placeholders."
  - "Tailwind important utilities are used only where daisyUI component or breakpoint cascade otherwise overrides the required operator contract."

requirements-completed: [FLOW-01, FLOW-02, PAGE-02, RESP-01, A11Y-01]

duration: 23 min
completed: 2026-06-14
---

# Phase 98 Plan 04: Operator Browser Reachability Summary

**Single-seed operator browser coverage now validates suppressed, empty, error, failed-audit, responsive-grid, touch-target, and asset-bundle contracts**

## Performance

- **Duration:** 23 min
- **Started:** 2026-06-14T21:08:00Z
- **Completed:** 2026-06-14T21:31:02Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Added a `:suppressed` browser delivery row timed with `hours_ago(8)` plus an ExUnit ordering snapshot that locks `browser-selected` first and `browser-suppressed` last.
- Added Playwright coverage for operator detail error, filtered-empty, truly-empty, suppressed badge fallback, failed SendGrid row inspection, one h1, mobile list/detail behavior, touch targets, and 768/1440 grid ratios.
- Rebuilt and committed `priv/static/app.css`, then verified the bundle-clean gate.
- Fixed mounted CSS URL generation so `/ops/mail` and nested admin routes load the compiled stylesheet from their route mount.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend seed + ExUnit ordering snapshot** - `1d88cb9e` (test)
2. **Task 2: Playwright state matrix + responsive/a11y coverage** - `d8663ca0` (test)
3. **Task 3: Rebuild static CSS bundle** - `61e06e5d` (build)

**Plan metadata:** pending in this commit.

## Files Created/Modified

- `mailglass_admin/test/support/operator_fixtures.ex` - Adds the append-last suppressed browser delivery row.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - Adds the browser seed ordering snapshot.
- `mailglass_admin/e2e/operator.spec.js` - Adds mobile orientation/list assertions, failed-row FLOW-02 inspection, and keyboard radio selection for ambiguous replay.
- `mailglass_admin/e2e/structural.spec.js` - Adds state-reachability, h1, touch-target, and responsive-grid structural assertions.
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` - Moves filtered/truly-empty testids onto the visible empty-state container.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - Adds mobile touch target height, mobile detail ordering, and important 1440 grid override.
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` - Makes replay modal overflow scroll at the overlay level.
- `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` - Embeds source `priv/static/app.css` so asset rebuilds recompile against the current bundle.
- `mailglass_admin/lib/mailglass_admin/layouts.ex` and `layouts/root.html.heex` - Emit mounted CSS URLs for root and nested admin routes.
- `mailglass_admin/priv/static/app.css` - Rebuilt Tailwind bundle.

## Decisions Made

- Used `status=queued` for filtered-empty URL coverage because `bounced` is an event value, not an allowed delivery status.
- Kept the browser harness single-seed; no per-state fixture endpoint was added.
- Used keyboard selection for ambiguous replay because the radio is intentionally sr-only but accessible by role/name.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Empty-state testids needed to be on visible DOM**
- **Found during:** Task 2 (per-state structural coverage)
- **Issue:** The structural test needed visible filtered/truly-empty state anchors; the prior true-empty testid was hidden and the filtered testid was on the reset button.
- **Fix:** Moved `operator-empty-filtered` and `operator-empty-truly` to the visible empty-state container and renamed the reset button testid to `operator-empty-reset`.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`
- **Verification:** `e2e/structural.spec.js` state coverage passed.
- **Committed in:** `d8663ca0`

**2. [Rule 3 - Blocking] Operator root route loaded CSS from the wrong relative URL**
- **Found during:** Task 2 (browser responsive/touch verification)
- **Issue:** `/ops/mail` emitted `href="css-..."`, which resolved to `/ops/css-*` instead of `/ops/mail/css-*`; the page had correct classes but no Tailwind utilities applied.
- **Fix:** Root layout now computes mounted CSS URLs from `@conn.request_path`, and the asset controller embeds source `priv/static/app.css` so rebuilds are reflected after compile.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/layouts.ex`, `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex`, `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`
- **Verification:** Direct Playwright probe confirmed `/ops/mail/css-...` and full browser gate passed.
- **Committed in:** `d8663ca0`

**3. [Rule 3 - Blocking] Styled replay modal made long target lists hard to reach**
- **Found during:** Task 2 (operator replay browser verification)
- **Issue:** Once CSS loaded correctly, replay modal content could extend beyond the viewport and Playwright/user clicks on lower controls were intercepted by the overlay.
- **Fix:** Moved scrolling to the fixed overlay and kept the dialog as a normal centered block.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex`
- **Verification:** `e2e/operator.spec.js` passed all 11 operator browser tests.
- **Committed in:** `d8663ca0`

**4. [Rule 3 - Blocking] CSS cascade overrode required touch and 1440 grid contracts**
- **Found during:** Task 2 (touch target and responsive-grid assertions)
- **Issue:** daisyUI `.btn` height overrode ordinary `h-11`, and the generated `md:` grid rule overrode the 1440 arbitrary breakpoint rule.
- **Fix:** Used `!h-11` for the mobile filter/back controls and `min-[1440px]:!grid-cols-[33%_67%]` for the wide grid.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`
- **Verification:** `e2e/structural.spec.js` passed touch-target and responsive-grid checks.
- **Committed in:** `d8663ca0`

---

**Total deviations:** 4 auto-fixed (1 missing critical, 3 blocking).
**Impact on plan:** All fixes were required to make the planned browser assertions test the real styled operator surface. No new dataset, baseline cell, or package dependency was added.

## Issues Encountered

- Playwright reset/seed is not concurrency-safe across these two files, so the browser verification was run with `--workers=1`.
- `mix verify.preview` was not run in full; the plan explicitly allowed scoping to `mix mailglass_admin.assets.build && git diff --exit-code priv/static/` if unrelated suite noise appeared. The scoped bundle-clean gate passed.

## User Setup Required

None - no external service configuration required.

## Verification

- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` — 30 tests, 0 failures.
- `cd mailglass_admin && mix test test/mailglass_admin/assets_test.exs test/mailglass_admin/router_test.exs --warnings-as-errors` — 11 tests, 0 failures.
- `cd mailglass_admin && mix mailglass_admin.assets.build && mix compile --force --warnings-as-errors && npx playwright test --config=playwright.config.cjs --workers=1 e2e/operator.spec.js e2e/structural.spec.js` — 38 tests, 0 failures.
- `cd mailglass_admin && git diff --quiet docs/ui-baseline-scores.json test/mailglass_admin/ratchet_baseline_test.exs && echo baseline-ok` — `baseline-ok`.
- `cd mailglass_admin && mix mailglass_admin.assets.build && git diff --exit-code priv/static/ && echo bundle-clean-ok` — `bundle-clean-ok`.

## Next Phase Readiness

All Phase 98 planned operator delivery state coverage is in place, the frozen 36-cell UI baseline remains untouched, and the operator browser surface is ready for phase-level review/verification.

---
*Phase: 98-operator-deliveries-surface*
*Completed: 2026-06-14*
