---
phase: 178-preview-authoring-and-milestone-review
plan: "06"
subsystem: testing
tags: [playwright, chromium, real-zoom, wcag, operator-browser-gate, mailglass_admin]

requires:
  - phase: 178-preview-authoring-and-milestone-review
    provides: "178-04 Restore defaults and the readable scenario selector (technical identity line) that the Phase 171 case now covers under real zoom"
provides:
  - "mailglass_admin/e2e/support/real-zoom.cjs: launchRealZoomContext, applyRealZoom, measureEffective, recordReceipt, undersizedTargets"
  - "mailglass_admin/e2e/phase178-real-zoom.spec.js: five serial Phase 178 real zoom cases with real-zoom annotations, one browser context"
  - "Phase 171 actual-zoom case asserts Restore defaults and the technical identity line"
  - "Phase 176 style.zoom cases and the Storybook receipt limit no longer claim real zoom"
affects: [178-07, 178-08, 178-09, 178-11]

phase_base_sha: 61e90275f01f9927d2f8ab3bbfd3ba7f9099dffc
plan_head_before: f3747e4a049dbf05f7ddc60c717dd6a66e050055
plan_head_after: e9bcfba9c184c3590cefcecbc9d25af20ab14da0

actuals:
  tokens: 7500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "One persistent Chromium context per serial describe: tab zoom is per origin and survives same-origin navigation, so the extension loads and zoom applies once in beforeAll"
    - "Every case re-measures its own receipt (documentWidth depends on the route) and records it as a real-zoom test annotation"
    - "Target scan reports data-testid, width and height of every sub-44px interactive element, with an optional exempt selector for the 24px field-help trigger"

key-files:
  created:
    - mailglass_admin/e2e/support/real-zoom.cjs
    - mailglass_admin/e2e/phase178-real-zoom.spec.js
  modified:
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/e2e/phase176-filters.spec.js
    - reference/demo_app/assets/e2e/storybook-fidelity.spec.js

key-decisions:
  - "Phase 176 CSS-zoom cases are relabelled (CSS zoom 2x), not migrated; the real-zoom filter proof is added once in the new spec for both collections in one context"
  - "At 320 CSS px the Delivery and Inbound cards are themselves the opener buttons (ids operator-delivery-mobile-* and inbound-record-open-mobile-*), so the cases open and assert focus return on those ids"
  - "Receipt asserts DPR ratio 2, innerWidth 320 and documentWidth <= 320 in recordReceipt, so a case that did not really zoom cannot pass"
  - "Commit trailer is Co-Authored-By: Claude Sonnet 5.5, following the runtime attribution reminder instead of the plan text's Claude Opus 5.5"

requirements-completed: ["UIQ-06"]

coverage:
  - id: D1
    description: "Delivery and Inbound quick views keep the position counter, arrows (including the natively disabled Inbound boundary) and Close usable at 320 CSS px under actual 200% tab zoom; every target is 44x44, arrows navigate, Close returns focus to the opener"
    requirement: "UIQ-06"
    verification:
      - kind: automated_ui
        ref: "mailglass_admin/e2e/phase178-real-zoom.spec.js#Phase 178 real zoom: Delivery quick view keeps position, arrows and Close usable at 320 CSS px"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/phase178-real-zoom.spec.js#Phase 178 real zoom: Inbound quick view keeps position, arrows and Close usable at 320 CSS px"
        status: pass
    human_judgment: false
  - id: D2
    description: "Health overview (verdict, issue rows, Refresh) and the Account control (keyboard open, option list) are readable and operable at 320 CSS px under actual 200% zoom, with reduced motion, Tab reach and visible focus"
    requirement: "UIQ-06"
    verification:
      - kind: automated_ui
        ref: "mailglass_admin/e2e/phase178-real-zoom.spec.js#Phase 178 real zoom: Health overview keeps the verdict, issue rows and Refresh readable at 320 CSS px"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/phase178-real-zoom.spec.js#Phase 178 real zoom: Account control opens and lists Accounts at 320 CSS px"
        status: pass
    human_judgment: false
  - id: D3
    description: "Phase 176 filters on Deliveries and Inbound apply without overflow under actual 200% zoom: the Filters toggle and every control are 44px and inside 320 CSS px, a select applies to the URL, and the 500-character query overflows nothing"
    requirement: "UIQ-06"
    verification:
      - kind: automated_ui
        ref: "mailglass_admin/e2e/phase178-real-zoom.spec.js#Phase 178 real zoom: filters on Deliveries and Inbound apply without overflow at 320 CSS px"
        status: pass
    human_judgment: false
  - id: D4
    description: "The Phase 171 actual-zoom case also asserts Restore defaults is visible, 44x44 and inside 320 CSS px, and the technical identity line wraps; its title is unchanged"
    requirement: "UIQ-06"
    verification:
      - kind: automated_ui
        ref: "mailglass_admin/e2e/structural.spec.js#Phase 171 rendered: actual 200% zoom retains preview controls and long identity at 320 CSS px"
        status: pass
    human_judgment: false
  - id: D5
    description: "No test or assertion message calls CSS zoom real zoom: the two Phase 176 style.zoom cases say CSS zoom 2x, and the Storybook receipt limit points to the connected real-zoom spec and states it applies no browser zoom while still matching /Phase 178/i"
    requirement: "UIQ-06"
    verification:
      - kind: automated_ui
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 connected: a 500-character query overflows nothing at 360px and under CSS zoom 2x"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 connected: the mobile Filters toggle reaches 44px and does not clip under CSS zoom 2x"
        status: pass
      - kind: unit
        ref: "scripts/check_phase174_evidence.test.cjs (checker bundle: 42 pass, 0 fail)"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-10-29
status: complete
---

# Phase 178 Plan 06: Real browser zoom reconciliation Summary

**Every area the milestone deferred to Phase 178 now has an actual-200%-zoom receipt at 320 CSS px (Chromium tab zoom through the repository's zoom extension: Delivery and Inbound quick views, Health, Account, Deliveries and Inbound filters, Preview Restore defaults and technical identity), and no test or evidence limit presents CSS zoom as real zoom.**

## Performance

- **Duration:** 10 min (13:48Z to 13:59Z)
- **Tasks:** 3 (1 tracer, 2 auto)
- **Files:** 2 created, 3 modified

## Accomplishments

- `real-zoom.cjs` lifts the phase175/phase170 recipe into one helper. `applyRealZoom` sets tab zoom 2, asserts `getZoom` is 2, polls `innerWidth` to half, resizes the window to reach 320 CSS px and returns the receipt. A named `RealZoomError` is thrown when the service worker or the active tab is unavailable.
- `phase178-real-zoom.spec.js` runs five cases in one persistent context (one launch, zoom applied once in `beforeAll`). `recordReceipt` asserts tab zoom 2, effective DPR exactly twice the initial, `innerWidth` 320 and `documentWidth <= 320`, then pushes a `real-zoom` annotation.
- Health and Account run under `reducedMotion: reduce`, reach their control with Tab and assert a visible focus outline or shadow. The Account list is opened from the keyboard and every option is 44px and inside 320 CSS px.
- The Phase 171 case keeps its title and now also asserts Restore defaults (visible, 44x44, inside 320) and that every rendered `preview-email-menu-active-technical` line has `scrollWidth <= clientWidth + 1`. No new browser context was added.
- The Phase 176 titles and assertion messages say CSS zoom; the `style.zoom` bodies and their 360px checks are unchanged. The Storybook receipt limit now names `mailglass_admin/e2e/phase178-real-zoom.spec.js` and states it applies no browser zoom. `scripts/check_phase174_evidence.cjs` and its case-id set are untouched.

## Receipts

Every real-zoom case reports tab zoom 2, initial `{devicePixelRatio: 2, innerWidth: 1440}` and effective `{devicePixelRatio: 4, innerWidth: 320}`. Effective `documentWidth` is measured per route and asserted `<= 320` (the Delivery quick view route measured 320). The annotations are in the JSON reporter output (`annotations[].type == "real-zoom"`).

| Case | Result |
| --- | --- |
| Delivery quick view | pass (0.5-0.7s) |
| Inbound quick view | pass (0.7-0.8s) |
| Health overview | pass (0.4-0.5s) |
| Account control | pass (0.2s) |
| Filters, Deliveries and Inbound | pass (0.8-1.1s) |
| Phase 171 actual 200% zoom (extended) | pass (0.8s) |
| Phase 176 CSS zoom 2x (2 cases) | pass (0.9s, 1.4s) |

Target-scan teeth were checked by mutation: raising the threshold from 43.5 to 60 in `undersizedTargets` made the Delivery quick view case fail naming `operator-quick-view-next`, `operator-detail-back`, `operator-quick-view-full` and the copy buttons. The helper was restored before commit.

## Verification

- `phase178-real-zoom.spec.js` alone: 5 passed (6.7s of test time; the spec adds one Chromium launch to the Operator Browser Gate, input for UIQ-07).
- Task 2 verify (`phase178-real-zoom.spec.js` plus the Phase 171 case): 6 passed, `.planning/milestones/v2.9-phases/16{8,9}-*/artifacts` and `mailglass_admin/priv/static` clean afterward.
- Task 3 verify: checker bundle (`check_phase174_evidence.test.cjs`, `check_phase175_evidence.test.cjs`, `phase174-review-claims.test.cjs`, `storybook-axe.test.cjs`) 42 pass, 0 fail; `git diff --quiet -- scripts/check_phase174_evidence.cjs` exits 0; `phase176-filters.spec.js --grep "CSS zoom 2x"` 2 passed.
- Acceptance greps: `chrome.tabs.setZoom` count 1 in the helper; `style.zoom` count 0 in the new spec and helper and 2 in `phase176-filters.spec.js`; `Phase 178 real zoom:` count 5; Phase 171 title count 1; 200%-zoom test titles in `phase176-filters.spec.js` 0; `phase178-real-zoom.spec.js` in the Storybook spec 1.
- `npx playwright test --config=playwright.config.cjs --list | tail -1`: **Total: 311 tests in 18 files** (research baseline 300 in 17; this plan adds 5 tests and 1 file, the rest is 178-04/05 work).

## Task Commits

1. **Task 1 (tracer): real zoom on the Delivery quick view through the helper** - `8fc91ae9`
2. **Task 2: Inbound quick view, Health, Account, filters and the Phase 171 extension** - `4924e64b`
3. **Task 3: honest zoom labels** - `e9bcfba9`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Mobile opener selector**
- **Found during:** Task 1
- **Issue:** The plan's recipe (`operator-delivery-row` then a button named "Open delivery") finds nothing at 320 CSS px, where the card list is shown and each card is itself the opener button.
- **Fix:** Select `button[id^="operator-delivery-mobile-"]` and `button[id^="inbound-record-open-mobile-"]` filtered to visible, and assert focus returns to that id.
- **Files modified:** `mailglass_admin/e2e/phase178-real-zoom.spec.js`
- **Commit:** `8fc91ae9`, `4924e64b`

**2. [Rule 1 - Bug] Disabled boundary assertion in the new Inbound case**
- **Found during:** Task 2
- **Issue:** After navigating off the boundary the previous arrow is a link, so `toBeEnabled()` on the old button locator never resolves.
- **Fix:** Assert the disabled button count is 0 once off the boundary.
- **Commit:** `4924e64b`

### Plan-text drift (no behavior change)

- The Phase 171 case sits at `structural.spec.js:1840`, not `:1790`; located by its unchanged title.
- Commits use `Co-Authored-By: Claude Sonnet 5.5` per the runtime attribution reminder, not the plan's `Claude Opus 5.5`.
- `undersizedTargets` gained an optional third argument (`{ exempt }`) so Health can hold the field-help trigger to 24x24 as `phase177-health.spec.js` does, instead of failing it at 44.
- `measureEffective` and `recordReceipt` were added to the helper's exports beyond the three named in the plan; the new spec needs a per-route measurement.

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug), plus plan-text drift. **Impact:** none on scope or the proof.

## Authentication Gates

None.

## Known Stubs

None.

## Issues Encountered

None. The plan verify blocks rely on `cd ... && ... ; rc=$?` forms that need bash (`PIPESTATUS`); they were run under `bash` as required.

## Threat Flags

None. The only new surface is the repository's existing two-file test extension (T-178-17, accepted); no package installs or lockfile changes (T-178-SC).

## Next Phase Readiness

- UIQ-06 is declared by 178-01, 178-04, 178-07, 178-08 and 178-10 as well, so `REQUIREMENTS.md` stays unticked until the last declaring plan finishes.
- 178-11 can scan test sources for rule P7 (no `style.zoom` or DPR override under a real-zoom, actual 200% or 200% zoom label); the new files contain no `style.zoom`.
- The new spec runs in the existing Operator Browser Gate (`npm run test:operator-browser`); no CI lane registration is needed.

## Self-Check: PASSED

- Created files exist: `mailglass_admin/e2e/support/real-zoom.cjs`, `mailglass_admin/e2e/phase178-real-zoom.spec.js`.
- Commits exist on `main`: `8fc91ae9`, `4924e64b`, `e9bcfba9`.
