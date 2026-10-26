---
phase: 169-outbound-investigation-and-recovery
plan: "03"
subsystem: operator-ui
tags: [elixir, phoenix-liveview, timeline, suppression, accessibility, browser-tests]

# Dependency graph
requires:
  - phase: 169-02
    provides: Account-scoped support evidence and shared operator investigation surfaces
provides:
  - Bounded Delivery event chronology with exact Account+Delivery+Event drill-in
  - Accessible copying that keeps exact event IDs and UTC timestamps visible
  - Current Mailglass suppression context separated from history and Account totals
affects: [169-04, 169-05, operator-support, outbound-investigation]

# Measured from the realized diff (chars / 4) and the persisted plan base.
actuals:
  tokens: 20481
  tasks: 3
  commits: 4
commits: 4
plan_head_before: 3c7b39b6e3be6ae6e357c2e1d88e1990fa38201d
plan_head_after: 18901af338ca53eebf5e54271e852a087f8e2f82

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Exact child-resource reads require the selected Account and Delivery scopes.
    - Read failures preserve retained evidence and expose scoped retry feedback.
key-files:
  created: []
  modified:
    - lib/mailglass/operator/timeline.ex
    - lib/mailglass/operator/suppressions.ex
    - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
    - mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/controllers/assets.ex
    - mailglass_admin/e2e/phase169-journey.spec.js
    - mailglass_admin/e2e/operator.spec.js
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - mailglass_admin/test/mailglass_admin/components_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/support/operator_fixtures.ex
    - mailglass_admin/test/support/endpoint_case.ex
    - test/mailglass/operator/timeline_test.exs
    - test/mailglass/operator/suppressions_test.exs
key-decisions:
  - "Show at most 100 chronological Events, detect overflow with row 101, and resolve selected Events independently by Account, Delivery, and Event."
  - "Keep exact recorded UTC values visible and make local time a separately labeled supplement."
  - "Present one current Mailglass suppression match separately from historical Events and Account-wide active-record totals."
requirements-completed: [OUTUX-03, OUTUX-04]
coverage:
  - id: D1
    description: Bounded Delivery chronology, overflow disclosure, and exact off-slice event selection.
    requirement: OUTUX-03
    verification:
      - kind: unit
        ref: test/mailglass/operator/timeline_test.exs
        status: pass
      - kind: automated_ui
        ref: Playwright Phase 169 timeline overflow and exact selection, port 4102
        status: pass
    human_judgment: false
  - id: D2
    description: Exact event and timestamp copy controls preserve visible UTC values and announce copy results.
    requirement: OUTUX-03
    verification:
      - kind: unit
        ref: mailglass_admin/test/mailglass_admin/components_test.exs (101 passed)
        status: pass
      - kind: automated_ui
        ref: Playwright Phase 169 exact copy and timestamp scenarios, port 4102 (2 passed)
        status: pass
    human_judgment: false
  - id: D3
    description: Current suppression match, public removal policy, unavailable refresh, historical events, and active totals remain distinct.
    requirement: OUTUX-04
    verification:
      - kind: unit
        ref: test/mailglass/operator/suppressions_test.exs (10 passed)
        status: pass
      - kind: integration
        ref: mailglass_admin/test/mailglass_admin/operator_live_test.exs (94 passed)
        status: pass
      - kind: automated_ui
        ref: Playwright Phase 169 current suppression scenario, port 4102 (1 passed)
        status: pass
    human_judgment: false

# Metrics
duration: 21min
completed: 2026-10-07
status: complete
---

# Phase 169 Plan 03: Bounded Event History and Current Suppression Summary

**Operators can inspect exact Delivery history and one current Mailglass suppression match without confusing either with aggregate counts or delivery outcomes.**

## Performance

- **Duration:** 21 minutes
- **Started:** 2026-10-08T01:02:31Z
- **Completed:** 2026-10-08T01:23:25Z
- **Tasks:** 3
- **Files modified:** 16

## Accomplishments

- Added the first-100 chronological timeline with a row-101 overflow sentinel and exact Account+Delivery+Event lookup for selected evidence outside the visible slice.
- Preserved exact stored UTC values and event IDs while adding semantic copy controls with accessible success and failure feedback.
- Added accurate current suppression reason, scope, source, expiry, and public removal guidance, plus retained-record retry feedback and a clear distinction from historical Events and active-record totals.
- Corrected the Health active-suppression destination copy so its Account-wide count is not mistaken for the historical suppressed-Event result set.

## Task Commits

Each task was committed atomically:

1. **Task 1: Present 100 chronological events and retain exact selected evidence outside the slice** — `9473873f` (TDD red evidence), `b13a8ca3` (implementation).
2. **Task 2: Copy exact event identity and UTC time without replacing their visible values** — `5feeb480` (feat).
3. **Task 3: Explain one current matching suppression separately from ledger history and Account totals** — `18901af3` (fix).

**Summary commit:** `e29d07ce` (docs; the final execution metadata commit also captures the state updates and this self-check).

## Files Created/Modified

- No source files created.
- Modified the 16 source, test, fixture, and browser files listed in `key-files.modified`.

## Decisions Made

- The 101st Event is used only to establish that additional history exists; the UI does not imply an exact total.
- A selected Event is resolved with Account, Delivery, and Event identity even when it falls outside the visible timeline slice.
- A successful empty suppression read describes only the current Mailglass reader; configured-store and provider restrictions remain outside its claim.
- Complaint and unsubscribe removal are blocked by the public removal command; policy records are described as supported for removal.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Blocking test fixture correction] Made persisted timeline browser fixtures satisfy storage and identifier constraints**
- **Found during:** Task 1 browser verification
- **Issue:** The browser scenario used an invalid webhook UUID and an Event timestamp that the database requires to be present; UTC precision also needed to remain stable in the fixture.
- **Fix:** Used a valid UUID and fixed UTC timestamps at the schema's supported precision, and retained the stored timestamp availability case in unit coverage.
- **Files modified:** `mailglass_admin/test/support/operator_fixtures.ex`, `mailglass_admin/e2e/phase169-journey.spec.js`
- **Verification:** The Phase 169 timeline browser scenario passed on port 4102.
- **Committed in:** `5feeb480`

**2. [Rule 2 - Missing critical distinction] Clarified the Health active-suppression count's historical Event destination**
- **Found during:** Task 3 integration review
- **Issue:** The Health count represented Account-wide current records while its link opened historical suppressed Delivery Events, without enough copy to distinguish those populations.
- **Fix:** Added an explicit accessible destination label and hint describing the separate historical population; added route and rendered-copy assertions.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs`, `mailglass_admin/e2e/phase169-journey.spec.js`
- **Verification:** Admin LiveView tests and the current-suppression browser scenario passed.
- **Committed in:** `18901af3`

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 2)
**Impact on plan:** Both corrections were necessary to satisfy the plan's persistence constraints and keep separate evidence populations truthful.

## Issues Encountered

- Chromium's macOS bootstrap IPC was denied in the default sandbox during an early retry. The authorized browser run completed after using the approved escalated execution path.
- The first Health link assertion ran on the Delivery detail route, where that overview metric is not rendered. The scenario now navigates to the overview to verify the destination, then returns to the exact Delivery detail.
- Browser asset builds generated a tracked `app.css` change; it was restored before the Task 3 commit.

## Verification

- `mix test test/mailglass/operator/timeline_test.exs --seed 1` — 6 passed.
- `mix test test/mailglass/operator/suppressions_test.exs --seed 1` — 10 passed.
- `mix test test/mailglass_admin/components_test.exs --seed 1` (from `mailglass_admin`) — 101 passed.
- Admin LiveView command, run from `mailglass_admin` — 94 passed:

  ```sh
  mix test test/mailglass_admin/operator_live_test.exs
  ```
- Playwright named timeline overflow/exact-selection scenario — 1 passed on port 4102.
- Playwright exact-copy and timestamp scenarios — 2 passed on port 4102.
- Playwright current-suppression/history/totals/unavailable-refresh scenario — 1 passed on port 4102.

## User Setup Required

None — no external service configuration required.

## Next Plan Readiness

The bounded timeline, exact selected-event read, copy behavior, and current suppression context are ready for Plan 04. No later plan was executed.

---
*Phase: 169-outbound-investigation-and-recovery*
*Completed: 2026-10-07*

## Self-Check: PASSED

- SUMMARY.md exists at the expected phase path.
- Task commits `9473873f`, `b13a8ca3`, `5feeb480`, and `18901af3`, plus summary commit `e29d07ce`, are present in the current history.

## Orchestrator Post-Wave Integration Gate

Admin compilation passed. The complete suite caught a gallery-load crash when an older timeline projection omitted optional `provider_occurred_at`. The timeline now checks this optional key with `Map.get/2`, preserving existing gallery projections and omitting unavailable provider time. Existing gallery asset-load coverage exercises this regression.

Rerun from `mailglass_admin`: `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 HEX_HOME=/private/tmp/mailglass-169-hex MIX_ENV=test mix test --seed 1` — 529 passed, 0 failed, 1 excluded. Schema and UI gates report `block:false`; codebase-drift abstains with `no-structure-md`.
