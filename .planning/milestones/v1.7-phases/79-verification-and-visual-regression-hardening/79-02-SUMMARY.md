---
phase: 79-verification-and-visual-regression-hardening
plan: "02"
subsystem: testing
tags: [playwright, e2e, operator-overview, orientation-strip, replay-flow]

requires:
  - phase: 75-information-architecture-navigation-and-orientation
    provides: operator-overview landing, orientation-strip testids (operator-overview-health, operator-overview-nav, inbound-orientation, preview-orientation)
  - phase: 78-seed-data-expressiveness
    provides: browser scenario seed with inbound record and expanded delivery set
provides:
  - Playwright e2e coverage for operator-overview-health, operator-overview-nav, inbound-orientation, preview-orientation testids
  - Fixed "exact replay flow" test (was failing at timeline assertion since pre-Phase-77)
  - Fixed operator_fixtures.ex jsonb[] cast bug (was blocking server boot with inbound seed)
  - BrowserSessionController.preview_empty/2 route for preview empty-mailables state in e2e
affects: [phase-79-verify-work, VERIF-02]

tech-stack:
  added: []
  patterns:
    - "/ops/browser-preview-empty route pattern: sets mailables=[] in session before redirecting to /dev/mail/, enabling preview-orientation e2e assertion in a test server that has explicit mailables configured"
    - "status_badge text vs event_badge truthiness: event_badge/1 returns 'Replay audit' as a truthy sentinel; the rendered badge text is status_label(:webhook_replay_succeeded) = 'Replay succeeded'"

key-files:
  created: []
  modified:
    - mailglass_admin/e2e/operator.spec.js
    - mailglass_admin/test/support/operator_fixtures.ex
    - mailglass_admin/test/support/endpoint_case.ex

key-decisions:
  - "Keep deliveryRow(page, 3) for exact delivery: index 3 is browser-exact@example.com (confirmed by fixture insertion order with desc:inserted_at sort — noop=1, ambiguous=2, exact=3); do not change to index 1 as PATTERNS.md suggested (that analysis used ascending not descending insertion order)"
  - "Fix replay timeline assertion from 'Replay audit' to 'Webhook replay completed' + 'Replay succeeded': event_badge/1 returns 'Replay audit' as a truthy sentinel for whether to render the badge, but status_badge/1 renders status_label(:webhook_replay_succeeded) = 'Replay succeeded' as the visible text"
  - "Add /ops/browser-preview-empty test route: the preview-orientation testid only renders when @mailables == []; the test router is configured with explicit fixture mailables so a direct goto to /dev/mail/ shows the landing card. A dedicated controller action sets mailables=[] in the session before the redirect"

patterns-established:
  - "preview-empty test route pattern: when a LiveView component renders conditionally on session-controlled data, add a dedicated test browser route that sets the triggering session state before navigating to the surface URL"

requirements-completed:
  - VERIF-02

duration: 12min
completed: "2026-06-04"
---

# Phase 79 Plan 02: Extended E2E and Replay-Flow Fix Summary

**Playwright suite extended to 10 tests covering operator-overview-health, operator-overview-nav, inbound-orientation, and preview-orientation testids; pre-existing "exact replay flow" failure fixed by correcting the timeline badge text assertion**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-04T21:50:00Z
- **Completed:** 2026-06-04T22:03:56Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Fixed the pre-existing "exact replay flow" e2e failure (tracked since Phase 77): the assertion at line 128 expected "Replay audit" but `status_badge/1` renders "Replay succeeded" for `webhook_replay_succeeded`; added `{ timeout: 10000 }` on the primary timeline assertion
- Fixed operator_fixtures.ex `insert_inbound_record!`: `from`, `to`, `cc`, `bcc`, `reply_to`, and `attachments` columns are `jsonb[]` (not `jsonb`); removed `::jsonb` SQL cast and passed Elixir lists directly for native Postgrex handling — this was a Rule 1 bug blocking server boot entirely
- Added two new Playwright tests: "operator overview landing has health cards and navigation CTAs" and "inbound and preview surfaces render their orientation strips"; all 10 tests pass

## Task Commits

1. **Task 1: Fix the "exact replay flow" e2e test** - `629c91b0` (fix)
2. **Task 2: Add Operator Overview and orientation-strip structural tests** - `ab14422e` (feat)

## Files Created/Modified

- `mailglass_admin/e2e/operator.spec.js` - Fixed replay timeline assertion; added two new structural tests for Overview and orientation strips; 10 tests total
- `mailglass_admin/test/support/operator_fixtures.ex` - Fixed `insert_inbound_record!/1`: `from/to/cc/bcc/reply_to/attachments` are `jsonb[]` not `jsonb`; removed JSON encoding and SQL cast, pass Elixir lists directly
- `mailglass_admin/test/support/endpoint_case.ex` - Added `BrowserSessionController.preview_empty/2` action and `/ops/browser-preview-empty` route to enable preview-orientation testing in the test server (which has explicit fixture mailables configured)

## Decisions Made

- **Keep `deliveryRow(page, 3)` for exact delivery**: The PATTERNS.md fix suggestion ("change to index 1") was based on ascending insertion order analysis, but the sort is `desc: inserted_at`. With noop inserted last (most recent), the actual order is: index 0=selected, 1=noop, 2=ambiguous, 3=exact. The existing index 3 is correct; the test was failing at the timeline assertion, not the row selection.
- **Fix "Replay audit" → "Webhook replay completed" + "Replay succeeded"**: `event_badge(:webhook_replay_succeeded)` returns "Replay audit" as a truthy sentinel (controls whether the badge renders), but `status_badge/1` renders `status_label(:webhook_replay_succeeded)` = "Replay succeeded" as the visible badge text. The timeline row title is `replay_event_label(:webhook_replay_succeeded)` = "Webhook replay completed".
- **Add `/ops/browser-preview-empty` test infrastructure**: The preview-orientation testid only renders when `@mailables == []`. The test router is configured with `mailables: [HappyMailer, StubMailer, BrokenMailer]`, so navigating to `/dev/mail/` directly shows the landing card, not the orientation strip. Added a minimal controller action that sets `mailables=[]` in the HTTP session before redirecting to `/dev/mail/`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed operator_fixtures.ex jsonb[] cast error blocking server boot**
- **Found during:** Task 1 (running `npx playwright test -g "exact replay flow"`)
- **Issue:** `insert_inbound_record!/1` used `::jsonb` SQL cast and `Jason.encode!/1` for `from`, `to`, `cc`, `bcc`, `reply_to`, and `attachments` columns. These are `{:array, :map}` / `jsonb[]` in Postgres, not `jsonb`. The Postgrex `datatype_mismatch` error prevented the test server from booting at all.
- **Fix:** Removed `::jsonb` SQL casts from the VALUES clause and passed Elixir lists directly (Postgrex handles `{:array, :map}` natively — no `Jason.encode!` needed).
- **Files modified:** `mailglass_admin/test/support/operator_fixtures.ex`
- **Verification:** Test server booted successfully; fixture seeding completed without errors.
- **Committed in:** `629c91b0` (part of Task 1 commit)

**2. [Rule 1 - Bug] Fixed replay timeline assertion: "Replay audit" → correct badge text**
- **Found during:** Task 1 (running the test in isolation after server boot was fixed)
- **Issue:** The test asserted `toContainText("Replay audit")` at line 128. The `event_badge/1` function returns the string "Replay audit" as a truthy sentinel to control badge rendering, but the visible badge text is produced by `status_label(:webhook_replay_succeeded)` = "Replay succeeded". The timeline row title is "Webhook replay completed" (from `replay_event_label/1`). The assertion was wrong — "Replay audit" never appeared in the rendered DOM.
- **Fix:** Changed to `toContainText("Webhook replay completed", { timeout: 10000 })` (row title, primary timing-guarded assertion) and added `toContainText("Replay succeeded")` (badge text). The extended timeout handles async LiveView socket propagation.
- **Files modified:** `mailglass_admin/e2e/operator.spec.js`
- **Verification:** `npx playwright test -g "exact replay flow"` exits 0 (1 test passed).
- **Committed in:** `629c91b0` (part of Task 1 commit)

**3. [Rule 2 - Missing Critical] Added /ops/browser-preview-empty route for preview-orientation e2e**
- **Found during:** Task 2 (running the full suite; `preview-orientation` assertion failed because the test server has fixture mailables configured)
- **Issue:** The plan specified `await page.goto("/dev/mail/")` then assert `preview-orientation` visible. But `preview-orientation` only renders when `@mailables == []`. The test router is configured with `mailables: [HappyMailer, StubMailer, BrokenMailer]`, so the preview surface always shows the mailables landing card, not the orientation strip. No existing test infrastructure provided a way to reach the empty-mailables state.
- **Fix:** Added `BrowserSessionController.preview_empty/2` action that sets `"mailables" => []` in the HTTP session (which the `__preview_session__` callback reads before the explicit mailables opts) and redirects to `/dev/mail/`. Added `/ops/browser-preview-empty` route in the test adapter router. Updated the test to navigate via this route.
- **Files modified:** `mailglass_admin/test/support/endpoint_case.ex`, `mailglass_admin/e2e/operator.spec.js`
- **Verification:** `preview-orientation` testid visible; full suite exits 0 (10 tests passed).
- **Committed in:** `ab14422e` (part of Task 2 commit)

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 2 missing critical infrastructure)
**Impact on plan:** All three fixes were necessary for the plan's success criteria. The jsonb[] cast fix unblocked the server entirely. The timeline badge text fix resolved the pre-existing tracked failure. The browser-preview-empty route was essential for testing a conditional UI surface in a test server with explicit mailables. No scope creep.

## Issues Encountered

- The RESEARCH.md assumption table listed `browser-exact` at index 1 using ascending insertion order reasoning, but the actual sort is `desc: inserted_at`, making exact index 3 (which is what the original test already used correctly). The PATTERNS.md "fix" recommendation would have broken the test if applied.
- The "Replay audit" text in the todo and plan comments referred to the `event_badge/1` return value (a truthy check sentinel), not the rendered badge text. This distinction was not visible from the todo description alone — required running the test to diagnose from the actual DOM output.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- VERIF-02 satisfied: all 4 required testids (operator-overview-health, operator-overview-nav, inbound-orientation, preview-orientation) have structural e2e assertions; 10 tests pass
- Pre-existing "exact replay flow" failure resolved — no longer a tracked todo
- Phase 79 Plan 03 (audit-matrix re-run and gap-register closeout) can proceed

---
*Phase: 79-verification-and-visual-regression-hardening*
*Completed: 2026-06-04*
