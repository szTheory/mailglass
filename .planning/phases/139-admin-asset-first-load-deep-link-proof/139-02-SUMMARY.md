---
phase: 139-admin-asset-first-load-deep-link-proof
plan: 02
subsystem: testing
tags: [playwright, phoenix-liveview, admin-assets, fonts, computed-styles]

requires:
  - phase: 139-admin-asset-first-load-deep-link-proof
    provides: Test-only alternate admin macro mounts and first-HTML stylesheet href matrix from 139-01
provides:
  - Serialized Playwright hard-load proof for admin CSS/font network behavior
  - Computed-style proof that direct-loaded admin pages apply self-hosted Inter fonts and token-backed backgrounds
  - Default and alternate mount browser route matrix for preview, gallery, operator, and inbound surfaces
affects: [140-verification-docs-reconciliation-and-closeout, admin-assets, browser-hard-load-proof]

tech-stack:
  added: []
  patterns:
    - Direct page.goto per route case after auth setup, never in-app navigation
    - Playwright requestfailed plus response checks for stylesheet/font resources
    - Computed-style assertions over screenshots or pixel diffs

key-files:
  created:
    - mailglass_admin/e2e/admin-assets.spec.js
  modified:
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/test/mailglass_admin/token_parity_test.exs

key-decisions:
  - "Kept the browser proof in a focused Playwright spec under the existing serialized operator browser gate."
  - "Used /ops/browser-login with a non-CSS /ops/browser-ready return target before protected direct-load tests so the proof still attaches network listeners before page.goto(targetPath)."
  - "Left production asset routing, CSS, tokens, HEEx markup, package versions, and router macro APIs unchanged."

patterns-established:
  - "Admin asset browser proofs attach requestfailed and response listeners before direct navigation and assert status, content type, same-origin URL, and effective mount root."
  - "Admin computed-style proof waits for document.fonts.ready and verifies Inter/Inter Tight typography plus token-backed root background colors."

requirements-completed:
  - AAU-02
  - AAU-03
  - AAU-04
  - GATE-03

duration: 6 min
completed: 2026-07-08
status: complete
---

# Phase 139 Plan 02: Serialized Browser Asset Hard-Load Proof Summary

**Playwright hard-load proof that admin CSS/fonts resolve from default and alternate mount roots with applied Inter typography and token-backed computed styles.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-08T13:20:13Z
- **Completed:** 2026-07-08T13:26:13Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added `mailglass_admin/e2e/admin-assets.spec.js` with 12 independent `admin asset hard load:` tests covering preview, gallery, operator, inbound, query deep links, and alternate mount roots.
- Proved stylesheet and font requests are observed on direct hard loads, stay same-origin, return 200, expose `text/css` or `font/woff2`, and remain rooted under the effective mount path.
- Added computed-style assertions that wait for self-hosted fonts, verify Inter body and Inter Tight heading typography, assert dark query roots, and check token-backed root backgrounds.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add direct-load CSS and font network proof** - `cefa3434` (test)
2. **Task 2: Add token-backed computed-style assertions** - `341aa265` (test)

## Files Created/Modified

- `mailglass_admin/e2e/admin-assets.spec.js` - Focused Playwright spec for direct admin hard-load network and computed-style proof.

## Verification

- `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs test/mailglass_admin/mount_path_test.exs --warnings-as-errors` - PASS, 21 tests, 0 failures.
- `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset hard load"` - PASS, 12 Playwright tests, 0 failures.
- `rg -n "admin asset hard load|requestfailed|resourceType\\(\\)|content-type|font/woff2|text/css|/alt/dev/console|/secure/console|assertTokenBackedStyles|document\\.fonts\\.ready|document\\.fonts\\.check|getComputedStyle|fontFamily|backgroundColor|fontWeight" mailglass_admin/e2e/admin-assets.spec.js` - PASS.
- `rg -n "screenshot|toHaveScreenshot|pixel|pixelmatch" mailglass_admin/e2e/admin-assets.spec.js` - PASS, no screenshot or pixel-diff assertions.

## Decisions Made

- Kept all browser asset proof in a new focused spec so GATE-03 stays runnable with the existing `test:operator-browser` script and a narrow `--grep`.
- Authenticated operator and inbound cases through the existing `/ops/browser-reset` and `/ops/browser-login` support routes, then attached network listeners before the target `page.goto`.
- Preserved the existing `MountPathHook -> MountPath.base/1 -> Layouts.css_url/1` strategy and did not change production routing, assets, CSS, tokens, HEEx markup, or package versions.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The orchestrator reran `npm run test:operator-browser -- --grep "admin asset hard load"` after plan completion, which rebuilt `mailglass_admin/priv/static/app.css` and exposed that the committed bundle was stale for existing admin classes (`collapse*`, `inline-block`, `items-end`). The regenerated bundle also exposed a narrow `token_parity_test` parser assumption: the compiled dark token selector may be `[data-theme=dark],[data-theme=mailglass-dark]`. Post-wave commit `89558212` keeps the bundle current and updates the parser to recognize both dark selectors.
- Verification continues to emit the pre-existing Phoenix component warning at `mailglass_admin/lib/mailglass_admin/operator_live.ex:505`; the focused commands exit 0 and the warning is outside this plan's functional changes.

## Known Stubs

None.

## Authentication Gates

None.

## Next Phase Readiness

Ready for Phase 140: the fast first-HTML proof from 139-01 and the serialized browser proof from 139-02 now cover Phase 139's admin asset URL robustness requirements. Phase 140 can reconcile docs/backlog text and close the v2.1 verification loop.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-02-SUMMARY.md`.
- Created Playwright spec exists at `mailglass_admin/e2e/admin-assets.spec.js`.
- Task commit `cefa3434` exists.
- Task commit `341aa265` exists.
- Post-wave bundle-clean commit `89558212` exists.

---
*Phase: 139-admin-asset-first-load-deep-link-proof*
*Completed: 2026-07-08*
