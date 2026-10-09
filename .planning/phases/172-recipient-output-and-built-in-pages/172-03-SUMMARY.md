---
phase: 172-recipient-output-and-built-in-pages
plan: 03
subsystem: compliance
tags: [unsubscribe, phoenix, heex, playwright]

# Dependency graph
requires:
  - phase: 172-01
    provides: Existing demo browser evidence route and Playwright lane.
provides:
  - Truthful, read-only valid unsubscribe GET page with escaped recipient display.
  - Distinct private invalid and expired recovery pages retaining 404 and 410.
  - Fixed-state demo evidence route and narrow viewport geometry checks.
affects: [unsubscribe, compliance, reference-demo, adopter-guides]

# Actuals (#2632), measured from the realized diff (17,833 characters / 4).
actuals:
  tokens: 4458
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Fixed state atoms select truthful copy in one shared embedded HEEx document.
    - Demo evidence renders the actual embedded template with fixed synthetic input.

key-files:
  created:
    - lib/mailglass/compliance/unsubscribe_html/state.html.heex
  modified:
    - lib/mailglass/compliance/unsubscribe_controller.ex
    - test/mailglass/compliance/unsubscribe_controller_test.exs
    - guides/unsubscribe.md
    - reference/demo_app/lib/mailglass_demo_web/router.ex
    - reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex
    - reference/demo_app/assets/e2e/demo.spec.js
  deleted:
    - lib/mailglass/compliance/unsubscribe_html/confirm.html.heex

key-decisions:
  - "Valid GET remains informational and does not change subscription state."
  - "Only fixed state atoms render recovery copy; invalid and expired pages receive no recipient or token assigns."
  - "POST remains the only built-in unsubscribe mutation path; configured redirect applies to GET only."

requirements-completed: [MAILUX-04]
coverage:
  - id: D1
    description: "Valid GET truthfully explains its read-only result and supported next steps, with escaped recipient text."
    requirement: MAILUX-04
    verification:
      - kind: integration
        ref: "test/mailglass/compliance/unsubscribe_controller_test.exs — valid GET copy, escaping, no mutation, redirect, and POST regression"
        status: pass
    human_judgment: false
  - id: D2
    description: "Invalid and expired GET responses retain distinct private recovery pages and status codes."
    requirement: MAILUX-04
    verification:
      - kind: integration
        ref: "test/mailglass/compliance/unsubscribe_controller_test.exs — invalid and expired GET cases"
        status: pass
    human_judgment: false
  - id: D3
    description: "Actual embedded unsubscribe pages remain readable without horizontal overflow at 320px and 160px."
    requirement: MAILUX-04
    verification:
      - kind: e2e
        ref: "bash scripts/run_demo_browser_evidence.sh — unsubscribe state test passed at both viewport sizes"
        status: pass
    human_judgment: false

# Metrics
duration: 9min
completed: 2026-10-09
status: complete
commits: 3
plan_head_before: b02b3c80dbb1dacbb5c96f1edfbe7e7674a9e3ff
plan_head_after: 03c5689834b7faa41b5e57ac1f01f75e138c42b5
---

# Phase 172 Plan 03: Built-in Unsubscribe Pages Summary

**Built-in unsubscribe GET now reports truthful state and recovery guidance, while controller and browser evidence preserve the existing POST protocol.**

## Performance

- **Duration:** 9 minutes
- **Started:** 2026-10-09T22:08:15Z
- **Completed:** 2026-10-09T22:17:17Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Replaced the misleading valid GET confirmation with an informational, escaped, responsive state page; tests prove GET adds no unsubscribe event or suppression.
- Rendered distinct, private invalid and expired pages with recovery guidance while retaining 404 and 410, configured GET redirects, and POST event/idempotency behavior.
- Added a fixed-state `/dev/unsubscribe/:state` route that renders the embedded template and Playwright checks for copy and overflow at 320px and 160px.
- Updated adopter guidance to describe GET as read-only and POST as the mutation path.

## Task Commits

Each task was committed atomically:

1. **Task 1: Show a truthful informational valid GET page** — `a0adfb58` (`feat`)
2. **Task 2: Render distinct private error states and lock the POST protocol** — `bc9741bc` (`fix`)
3. **Task 3: Verify the actual unsubscribe page at narrow width and browser zoom** — `03c56898` (`test`)

## Files Created/Modified

- `lib/mailglass/compliance/unsubscribe_controller.ex` — Routes valid GET and fixed recovery states through shared HEEx rendering without changing POST.
- `lib/mailglass/compliance/unsubscribe_html/state.html.heex` — Shared semantic page shell and state-specific copy, with narrow-width wrapping.
- `lib/mailglass/compliance/unsubscribe_html/confirm.html.heex` — Removed the old misleading confirmation template.
- `test/mailglass/compliance/unsubscribe_controller_test.exs` — Covers status, copy, privacy, escaping, GET no-mutation, configured redirect, and POST replay semantics.
- `guides/unsubscribe.md` — Documents GET and POST behavior and adopter rollout checks.
- `reference/demo_app/lib/mailglass_demo_web/router.ex` and `page_controller.ex` — Adds the fixed synthetic state evidence route under `/dev`.
- `reference/demo_app/assets/e2e/demo.spec.js` — Verifies state copy and no overflow at both required viewport sizes.
- `test/mailglass/docs/unsubscribe_guide_test.exs` — Updated the guide contract after review so it pins the informational GET and current POST/replay behavior.

## Decisions Made

- Keep valid GET informational and read-only; show the recipient only on the valid page through normal HEEx escaping.
- Use fixed state atoms and no recipient/token assigns for invalid and expired pages.
- Keep configured redirect GET-only and preserve POST's empty 200 response and idempotent event behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Wrapped the page heading at the 160px zoom-equivalent viewport**
- **Found during:** Task 3
- **Issue:** The single-word valid heading exceeded the available content width and created horizontal page overflow at 160px.
- **Fix:** Added word wrapping to the shared page heading.
- **Files modified:** `lib/mailglass/compliance/unsubscribe_html/state.html.heex`
- **Verification:** The unsubscribe Playwright case passed for all three states at both 320px and 160px.
- **Committed in:** `03c56898` (part of Task 3 commit)

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** The fix closes the specified zoom-equivalent layout requirement without changing page semantics or adding scope.

## Verification

- Focused controller suite: 10 tests, 0 failures.
- Unsubscribe guide contract suite after review follow-up: 5 tests, 0 failures.
- Required regression gate: core 78 tests passed; Admin 593 passed with 1 excluded; Inbound 480 tests and 3 properties passed with 3 excluded; connected operator browser suite 30 passed.
- Demo browser evidence: the new unsubscribe test passed at 320px and 160px. The existing advisory lane had 72 passing tests and two unrelated failures: the Helios empty-state heading and inbound detail header. A preview test failed once and passed on retry. These pre-existing surfaces were left unchanged.

## Issues Encountered

- **Review follow-up:** Code review found the unsubscribe guide contract test still asserted the retired confirmation-page wording and manual UAT labels. Updated the test to assert the current read-only GET, configured redirect, empty POST response, and replay event contract. The focused guide suite passes; disposition is recorded in `172-REVIEW-DISPOSITION.md`.

- The demo evidence script updated `reference/demo_app/mix.lock` during dependency resolution. That file was clean before the run and outside this plan, so the generated lockfile drift was restored.
- The first regression-gate attempt could not launch host Chromium under the workspace sandbox. The reviewed retry completed the connected browser suite successfully with 30 passing tests.

## User Setup Required

None.

## Next Phase Readiness

MAILUX-04 is implemented with controller and browser evidence. The two unrelated advisory browser failures remain outside this plan's scope.

## Self-Check: PASSED

- Summary file exists.
- Task commits `a0adfb58`, `bc9741bc`, and `03c56898` are ancestors of the current HEAD.

---
*Phase: 172-recipient-output-and-built-in-pages*
*Completed: 2026-10-09*
