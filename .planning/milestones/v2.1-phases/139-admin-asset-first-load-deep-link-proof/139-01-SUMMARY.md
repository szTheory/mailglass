---
phase: 139-admin-asset-first-load-deep-link-proof
plan: 01
subsystem: testing
tags: [phoenix-liveview, assets, router, floki, conn-test]

requires:
  - phase: 138-schema-prefix-no-search-path-hardening
    provides: v2.1 sequencing baseline; no code dependency for admin asset proof
provides:
  - Test-only alternate admin macro mounts at /alt/dev/console and /secure/console
  - First-HTML stylesheet href route matrix for preview, gallery, operator, inbound, query, error, and alternate mount roots
  - Fast Conn/LiveView proof that stylesheet hrefs are root-relative and rooted at the effective admin mount path
affects: [139-admin-asset-first-load-deep-link-proof, admin-assets, browser-hard-load-proof]

tech-stack:
  added: []
  patterns:
    - Existing router macros reused for alternate test mounts
    - Floki parses full first HTML to inspect the root-layout stylesheet link
    - MountPathHook -> MountPath.base/1 -> Layouts.css_url/1 preserved

key-files:
  created:
    - mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs
  modified:
    - mailglass_admin/test/support/endpoint_case.ex

key-decisions:
  - "Preserved the existing MountPathHook -> MountPath.base/1 -> Layouts.css_url/1 strategy; no production hardening was required."
  - "Proved alternate mount roots through test-only reuse of mailglass_admin_routes/2 and mailglass_operator_routes/2 with unique live_session_name values."

patterns-established:
  - "First-HTML asset URL proof parses the root layout stylesheet link with Floki and asserts exact mount-rooted hrefs."
  - "Alternate admin mount proof lives in the synthetic test router, not in public router macro options."

requirements-completed:
  - AAU-01
  - AAU-03
  - GATE-03

duration: 5 min
completed: 2026-07-08
status: complete
---

# Phase 139 Plan 01: Fast First-HTML Stylesheet Href Proof Summary

**Mount-rooted admin stylesheet href proof across preview, gallery, operator, inbound, query, render-error, and alternate macro-mounted first HTML routes.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-08T13:09:01Z
- **Completed:** 2026-07-08T13:14:15Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added test-only alternate preview and operator/inbound roots using the existing public router macros at `/alt/dev/console` and `/secure/console`.
- Added `MailglassAdmin.AdminAssetUrlTest`, a focused first-HTML route matrix that parses the root-layout stylesheet link from direct `get/2` responses.
- Confirmed the current mount-aware implementation already satisfies the fast proof, so `MailglassAdmin.MountPath.base/1` and `MailglassAdmin.Layouts.css_url/1` stayed unchanged.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add test-only alternate macro mounts** - `2a155dfa` (test)
2. **Task 2: Add first-HTML stylesheet href route matrix** - `7e13ad55` (test)

## Files Created/Modified

- `mailglass_admin/test/support/endpoint_case.ex` - Added alternate test-only preview and operator/inbound macro mounts with unique live session names.
- `mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs` - Added full first-HTML stylesheet href route matrix and assertion helpers.

## Verification

- `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs test/mailglass_admin/mount_path_test.exs --warnings-as-errors` - PASS, 21 tests, 0 failures.
- `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/router_test.exs --warnings-as-errors` - PASS, 15 tests, 0 failures.
- `rg -n "AdminAssetUrlTest|stylesheet_href!|operator_conn|/alt/dev/console|/secure/console|css-" mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs mailglass_admin/test/support/endpoint_case.ex` - PASS.

## Decisions Made

- Preserved the existing mount-aware asset path strategy and avoided production code changes because the new matrix passed as written.
- Kept alternate mount proof in the synthetic test router and reused the current macro options instead of adding router API surface or fallback asset routes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Kept router macro options as literal lists**
- **Found during:** Task 1 (Add test-only alternate macro mounts)
- **Issue:** A small cleanup attempted to share macro options through module attributes, but `mailglass_admin_routes/2` validates options before those attributes expand.
- **Fix:** Restored literal `mailables` and `session` option lists at each test-router macro call, matching the existing pattern.
- **Files modified:** `mailglass_admin/test/support/endpoint_case.ex`
- **Verification:** `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/router_test.exs --warnings-as-errors`
- **Committed in:** `2a155dfa`

---

**Total deviations:** 1 auto-fixed (1 blocking issue)
**Impact on plan:** No scope change. The fix kept the test router aligned with the existing macro validation pattern.

## Issues Encountered

No blocking issues. Verification emitted an existing Phoenix component attribute warning from `mailglass_admin/lib/mailglass_admin/operator_live.ex:505`; the focused commands exited 0 and the warning is outside this plan's touched files.

## Known Stubs

None.

## Authentication Gates

None.

## Next Phase Readiness

Ready for `139-02`: the browser hard-load proof can consume the default and alternate mount routes added here and verify stylesheet/font network responses plus computed styles.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-01-SUMMARY.md`.
- Created test file exists at `mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs`.
- Task commit `2a155dfa` exists.
- Task commit `7e13ad55` exists.

---
*Phase: 139-admin-asset-first-load-deep-link-proof*
*Completed: 2026-07-08*
