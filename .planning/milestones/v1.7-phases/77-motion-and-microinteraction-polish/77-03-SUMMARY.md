---
phase: 77-motion-and-microinteraction-polish
plan: "03"
subsystem: mailglass_admin/e2e
tags:
  - playwright
  - e2e
  - motion
  - regression-gate
  - reduced-motion
dependency_graph:
  requires:
    - 77-01  # id={"delivery-detail-#{@selected_delivery.id}"} added in Plan 01
    - 77-02  # scripts/check_motion_conformance.sh added in Plan 02
  provides:
    - MOTION-01 e2e regression gate (delivery id-presence + element-replace)
    - MOTION-02 e2e regression gate (reduced-motion suppression)
    - Documented seed dependency gate for Phase 78 inbound id-presence
  affects: []
tech_stack:
  added: []
  patterns:
    - Playwright DOM id-presence assertion via page.locator('#delivery-detail-<uuid>')
    - page.emulateMedia({ reducedMotion: 'reduce' }) before page.goto ordering
    - test.skip with Phase-N seed dependency comment pattern
key_files:
  created: []
  modified:
    - mailglass_admin/e2e/operator.spec.js
decisions:
  - inbound test skipped (not failed) because seed_browser_scenario!() seeds zero inbound records; Phase 78 is the enablement gate
  - emulateMedia placed before setViewportSize and openOperator to ensure media query active on initial page load
  - element-replace assertion uses toHaveCount(0) on old id to confirm LiveView performed a full element replace, not in-place patch
metrics:
  duration: ~13 minutes
  completed: "2026-06-04T16:19:09Z"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 1
---

# Phase 77 Plan 03: Motion E2E Regression Tests Summary

Playwright DOM-layer regression tests for MOTION-01 (delivery id-presence + element-replace) and MOTION-02 (reduced-motion suppression), plus a documented-skip inbound assertion gated on Phase 78 seed expansion.

## What Was Built

Three new test blocks appended inside the existing `test.describe("operator browser gate", ...)` in `mailglass_admin/e2e/operator.spec.js`:

**Test 1 — delivery id-presence + element-replace (MOTION-01 regression gate)**
Clicks delivery row 0, reads `delivery_id` from URL, asserts `#delivery-detail-<uuid>` is visible. Clicks row 1, confirms `delivery_id2 != deliveryId`, asserts `#delivery-detail-<deliveryId2>` visible and `#delivery-detail-<deliveryId>` has count 0 (element replaced, not patched). This is the Nyquist gate: ExUnit substring tests cannot detect a missing or static `id` attribute — only Playwright DOM inspection can.

**Test 2 — reduced-motion suppression (MOTION-02 regression gate)**
Calls `page.emulateMedia({ reducedMotion: "reduce" })` before `setViewportSize` and `openOperator` (emulateMedia must precede `page.goto` to be active on page load). Clicks row 0, asserts `#delivery-detail-<uuid>` is visible — confirming the element is not stuck at `opacity: 0` under the `animation-duration: 0.01ms !important` reduced-motion rule.

**Test 3 — inbound id-presence SKIPPED**
`test.skip(...)` with comment explaining: `seed_browser_scenario!()` seeds zero inbound records; the `id={"inbound-detail-#{@detail.record.id}"}` HEEx fix ships in Plan 01 but its e2e assertion requires a navigable inbound row. Phase 78 seed expansion is the enablement gate.

## Verification Status

All acceptance-criteria grep checks pass:
- `grep -c "delivery detail pane carries record-keyed id"` → 1
- `grep -c "motion-reveal is suppressed under prefers-reduced-motion"` → 1
- `grep -c "inbound detail pane carries record-keyed id"` → 1
- `grep -c "emulateMedia"` → 1 (in reduced-motion test, before openOperator)
- `grep -c "delivery-detail-"` → 5 (multiple id-presence assertions)
- `grep -c "test.skip"` → 1 (inbound skip only)

**npm run test:operator-browser: authored-but-not-executed.** The Playwright suite requires a running seeded Phoenix test server (`OperatorBrowserServer`) which is not available in this worktree (no Postgres/MIX_ENV=test server running). Per the plan's explicit disposition and the `project_specific_note`, this is expected and documented here. The structural correctness of all three tests was validated via grep checks above. The pre-existing tests and the two new live tests will be executed as part of the Phase 79 verification wave where the full server + seed environment is available.

## Deviations from Plan

None — plan executed exactly as written. The authored-but-not-executed disposition for `npm run test:operator-browser` is explicitly anticipated by the plan ("if the suite requires a seeded running server you cannot start, document that the test was authored-but-not-executed").

## Known Stubs

None. The skipped inbound test (`test.skip`) is intentionally incomplete with a documented Phase 78 gate, not a stub — it carries a full implementation body that becomes live once the seed is extended.

## Threat Flags

No new security-relevant surface introduced. This plan adds test-only code to an existing Playwright suite. Threat register items T-77-03-01 and T-77-03-02 both have `accept` disposition (UUID in URL is test-only synthetic data; explicit skip is documented).

## Self-Check: PASSED

- File exists: `mailglass_admin/e2e/operator.spec.js` — confirmed modified
- Commit 7c5ed6cf exists — confirmed via `git log`
- All acceptance criteria grep checks pass (results above)
- No file deletions in commit
