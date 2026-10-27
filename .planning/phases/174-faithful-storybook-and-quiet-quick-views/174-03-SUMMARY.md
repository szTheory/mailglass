---
phase: 174-faithful-storybook-and-quiet-quick-views
plan: "03"
subsystem: ui
tags: [phoenix-live-view, phoenix-storybook, playwright, focus-management]
requires:
  - phase: 174-01
    provides: Retained production Delivery quick view and root-mounted Storybook routes
  - phase: 174-02
    provides: Inbound quick-view scenarios and connected focus-return behavior
provides:
  - One canonical production hook asset shared by Admin and Demo Storybook
  - A hashed, development-only Storybook hook endpoint that does not create a socket
  - Connected lifecycle evidence for Storybook, Demo Delivery/Inbound, and Admin Delivery/Inbound
affects: [174-04, 174-05, 174-06, 175, 176, 177, 178]
actuals:
  tokens: 14171.75
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 149510c4dfd1d9586803a9c162338fcf99eb1244
plan_head_after: de06c706a25c73f6ecb9399d6c6d14db4f0ddd1c
tech-stack:
  added: []
  patterns:
    - "Compile-time embedded hook bytes are shared by the Admin bundle and a Demo-only hashed asset response."
    - "PhoenixStorybook receives production hook definitions through window.storybook.Hooks while retaining its own iframe LiveView owner."
    - "Browser lifecycle evidence counts sockets per browsing document and focusin listener installation/removal separately."
key-files:
  created:
    - mailglass_admin/priv/static/hooks.js
    - reference/demo_app/assets/e2e/storybook-hooks.spec.js
    - .planning/174-03-task-1-red-evidence.json
  modified:
    - mailglass_admin/lib/mailglass_admin/controllers/assets.ex
    - reference/demo_app/lib/mailglass_demo_web/router.ex
    - reference/demo_app/dev/mailglass_demo_web/storybook.ex
    - mailglass_admin/test/mailglass_admin/assets_test.exs
    - mailglass_admin/e2e/flows.spec.js
key-decisions:
  - "Keep one canonical window.MailglassAdminHooks implementation; the Storybook response only assigns it to window.storybook.Hooks and never constructs a LiveSocket."
  - "Keep each Admin, Demo, Storybook explorer, and isolated preview document under its existing socket owner; account for the explorer and iframe transports independently."
  - "Keep the existing LiveView and PhoenixStorybook package locks unchanged and verify each resolved client in its own browser host."
requirements-completed: [STORY-06]
coverage:
  - id: D1
    description: "Admin and Storybook use byte-identical production hook definitions, and the Storybook hook asset does not include an Admin socket bootstrap."
    requirement: STORY-06
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/assets_test.exs — shared hook JavaScript contract"
        status: pass
      - kind: e2e
        ref: "reference/demo_app/assets/e2e/storybook-hooks.spec.js — Phase174 hooks"
        status: pass
    human_judgment: false
  - id: D2
    description: "Connected Storybook and both locked application clients retain focus traps through patches, reconnects, close, focus return, and Storybook preview removal/remount."
    requirement: STORY-06
    verification:
      - kind: e2e
        ref: "reference/demo_app/assets/e2e/storybook-hooks.spec.js — Phase174 hooks"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js — Phase174 client hooks"
        status: pass
    human_judgment: false
duration: 31min
completed: 2026-10-27
status: complete
---

# Phase 174 Plan 03: Shared Hook Lifecycle Summary

**Admin and PhoenixStorybook now share one production focus-hook asset, with connected lifecycle checks on the pinned Demo and Admin clients.**

## Performance

- **Duration:** 31 min
- **Started:** 2026-10-27T02:54:04Z
- **Completed:** 2026-10-27T03:24:46Z
- **Tasks:** 2
- **Files modified:** 7 implementation and browser-test files, plus the retained TDD RED-evidence record

## Accomplishments

- Extracted `ModalFocusTrap`, `PreviewTabs`, and `PreviewPanelScroll` into `mailglass_admin/priv/static/hooks.js`. Admin embeds the same bytes once and retains its own socket bootstrap; Storybook receives those definitions through a guarded Demo-only hash URL and `window.storybook.Hooks` registration.
- Verified six successful hook asset responses with the source MD5 `a2feb8413071062448465a247096b88e`; each response registered the Storybook hooks and contained no socket constructor. The Storybook explorer and its isolated preview each had one socket; the iframe joined its expected channels without loading the Admin bootstrap.
- Exercised connected Storybook mount, native Playground assign patches, focus wrap, preview removal, and remount. Demo LiveView 1.1.33 and Admin LiveView 1.2.13 each passed repeated Delivery and Inbound open/update/close cycles under reduced motion. Admin also passed a controlled disconnect/reconnect with one open transport afterward.
- Verified Delivery focus returns to its opener after close. Inbound focus returns to the row matching the newly selected record after navigation. Hook listener additions and removals balanced on the real Demo/Admin route dialogs.
- Kept PhoenixStorybook 1.2.0 and the locked Playwright versions (Demo 1.60.0, Admin 1.59.1) unchanged. The runtime receipt is at `reference/demo_app/tmp/demo_browser_evidence/phase174/hooks.json` (ignored runtime evidence).

## Verification

- `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/assets_test.exs` — **7 tests passed**.
- `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix reference/demo_app/assets run test:e2e -- storybook-hooks.spec.js --grep "Phase174 hooks"` — **1 passed**.
- `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep "Phase174 client hooks"` — **1 passed**.
- The test-first evidence records the expected RED failure against the shared-hook assertions before implementation; the focused ExUnit suite passed after the implementation.

The browser receipt distinguishes the Storybook explorer from its isolated iframe: each document owned one socket, with one explorer channel join and two iframe channel joins. It observed nine WebSocket connections over the full browser lifecycle, including navigations and route cycles; that count is not a concurrent-owner count. The Admin test separately asserted one open LiveView transport after reconnect.

## Task Commits

1. **Task 1: RED — shared hook asset contract coverage** — `b807d06e` (`test`)
2. **Task 1: GREEN — share production hooks with Storybook** — `ea9fe736` (`feat`)
3. **Task 1: refactor — format shared hook assertions** — `ec76f3d5` (`style`)
4. **Task 2: verify hook lifecycle across clients** — `de06c706` (`test`)

The separate plan metadata commit records this summary and the sequential GSD tracking updates.

## Files Created/Modified

- `mailglass_admin/priv/static/hooks.js` — canonical production hook definitions without socket creation.
- `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` — compile-time shared bytes, content hash, Admin embedding, and hook-only Plug response.
- `reference/demo_app/lib/mailglass_demo_web/router.ex` — guarded development-only hash route for Storybook hook registration.
- `reference/demo_app/dev/mailglass_demo_web/storybook.ex` — points Storybook at the Demo-only hook response.
- `mailglass_admin/test/mailglass_admin/assets_test.exs` — verifies hook bytes, hash, content type, and absence of socket bootstrap.
- `reference/demo_app/assets/e2e/storybook-hooks.spec.js` — Storybook ownership and connected Demo lifecycle evidence.
- `mailglass_admin/e2e/flows.spec.js` — Admin Delivery/Inbound patch, reconnect, close, and focus-return coverage.
- `.planning/174-03-task-1-red-evidence.json` — retained expected RED-run evidence.

## Decisions Made

- The shared JavaScript asset contains hook definitions only. The Demo response adds the Storybook registration wrapper; it does not bundle Phoenix/LiveView or create another authenticated connection.
- Socket counts are interpreted per browsing document because the Storybook explorer and its intentionally isolated preview iframe each own a legitimate transport.
- Tests use the existing pinned clients instead of introducing a dependency upgrade or a new build system.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Kept the hook-only endpoint outside the CSRF browser pipeline**
- **Found during:** Task 1
- **Issue:** The browser pipeline's CSRF check rejected the same-origin GET used to load the hook script.
- **Fix:** Served the guarded hook route through the secure-browser-headers pipeline, retaining browser security headers without the CSRF check that blocks this script GET.
- **Files modified:** `reference/demo_app/lib/mailglass_demo_web/router.ex`
- **Verification:** The focused asset contract passed and the browser observed the hashed hook URL returning 200 with Storybook registration and no socket constructor.
- **Committed in:** `ea9fe736`

**Total deviations:** 1 auto-fixed bug.
**Impact on plan:** The route remains inside the development-only Storybook boundary; no published Admin router or package behavior was added.

## Evidence Limits

- The reused local Demo host had seeded records, but `DEMO_EVIDENCE_RESET_TOKEN` and `DEMO_EVIDENCE_PROJECT_ID` were not configured. The destructive reset was therefore skipped; the connected tests passed against that existing seed. A fresh seeded reset run was not established in this execution.
- Storybook removal was proven by detaching the preview browsing context and remounting a new one with one listener. Its `pagehide` snapshots showed zero and one focusin listeners in the contexts at teardown; listener add/remove balance is directly asserted on the real Demo and Admin quick-view routes.

## Issues Encountered

- The best-effort `gsd_run windows append` could not write the deviation rows because `.planning/WINDOWS.md` already has a rendered-table/fenced-JSON mismatch for row 48. No edits were made to that cross-phase ledger. This pre-existing planning issue is recorded in `deferred-items.md` for later repair.

## User Setup Required

None. The reset credentials were unavailable for this local run, but no new external configuration is required by the implementation.

## Next Phase Readiness

Plan 174-04 can build on the canonical hook asset and lifecycle coverage. The Demo browser suite should be run with its authorized reset token and project ID when a deterministic reseed is required.

---
*Phase: 174-faithful-storybook-and-quiet-quick-views*
*Completed: 2026-10-27*

## Self-Check: PASSED

- All listed created files exist.
- All four task commits are reachable from HEAD.
