---
phase: 168-shared-workspace-and-usable-baseline
plan: 09
subsystem: ui
tags: [phoenix-liveview, accessibility, playwright, browser-zoom]

# Dependency graph
requires:
  - phase: 168-08
    provides: Shared operator workspace and phase-wide acceptance baseline
provides:
  - Real Chromium 200% zoom assertions for shared controls and full Delivery detail/timeline values
  - Accessible pending status during delayed Account scope changes
  - Automated proof that committed Account identity and displayed data remain paired during switching
affects: [operator-workspace, accessibility, phase-168-verification]

# Actuals (#2632)
actuals:
  tokens: 66528
  tasks: 3
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns: [assert browser tab zoom directly, pair pending Account feedback with committed scope, verify text reachability through rendered DOM geometry]

key-files:
  created:
    - .planning/phases/168-shared-workspace-and-usable-baseline/168-09-task3-red-evidence.json
  modified:
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/priv/static/app.css

key-decisions:
  - "Use the existing Chromium zoom extension and Playwright fixtures to prove actual 200% browser zoom and rendered geometry."
  - "Announce a pending Account switch with a polite atomic status while server-backed patching keeps the old Account committed."
  - "Keep the browser lane advisory and out of CI Green; its recurring value is already provided by the existing operator_browser_gate."
  - "Apply D-52: deterministic acceptance is covered by automation, with no owner UAT for these criteria."

patterns-established:
  - "For browser-zoom acceptance, set and read the real tab zoom and assert control/value/document geometry rather than relying on screenshots."
  - "During asynchronous scope changes, communicate pending state separately from the committed identity and data."

requirements-completed: [UXF-03, UXF-04, UXF-08]

coverage:
  - id: D1
    description: Shared Account and Appearance controls remain visible and unclipped at actual 200% Chromium zoom.
    requirement: UXF-04
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js#Phase 168 Delivery Mailable wrapping; exact tab zoom and control/document geometry"
        status: pass
    human_judgment: false
  - id: D2
    description: Complete Delivery detail and timeline values remain rendered, readable, and reachable at actual 200% Chromium zoom.
    requirement: UXF-03
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js#Phase 168 Delivery Mailable wrapping; value and final-character geometry"
        status: pass
    human_judgment: false
  - id: D3
    description: A delayed Account switch announces pending work and preserves the old committed identity/data pair until the new scope commits.
    requirement: UXF-08
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js#Phase 168 Account scope; held LiveView patch"
        status: pass
    human_judgment: false

# Metrics
duration: 189min
completed: 2026-10-08
status: complete
---

# Phase 168 Plan 09: Verify zoom accessibility and pending Account feedback

Actual browser zoom and delayed scope switching now have deterministic Playwright coverage. Account changes expose an accessible pending announcement while the server-backed patch retains the previously committed scope.

## Performance

- **Duration:** 189 min
- **Started:** 2026-10-08T19:40:04Z
- **Completed:** 2026-10-08T22:48:38Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Extended the existing operator-browser test to set and read actual Chromium tab zoom at exactly 2, then verify shared controls, full Delivery values, and layout geometry without relying on screenshot comparison.
- Added a delayed real-control Account switch assertion for visible `role=status`, polite atomic announcement, old-scope retention, and new-scope completion.
- Implemented the pending announcement in the shared shell. The existing responsive CSS already met the expanded zoom assertions, so no source CSS change or additional dependency was needed; the existing asset build updated generated CSS.
- Applied the durable D-52 rule: these observable criteria are automated, and no owner UAT is needed for them.

## Task Commits

1. **Tasks 1–3: Add browser regressions and Task 3 RED evidence** - `f574f838` (test)
2. **Task 3: Announce pending Account switches** - `5fa6a380` (feat)

**Plan metadata:** `ef2c3dd3` (docs: add focused gap-closure plan)

## Automated evidence

- Focused Phase 168 operator-browser checks: 2 passed, 0 failed, including exact 200% tab zoom and delayed Account switching.
- Task 3 RED evidence records the intended missing-status failure before implementation and was accepted by the GSD RED-evidence classifier.
- `make ci-fast` passed with the pinned Elixir/OTP versions; formatting/compile checks passed and Credo reported no issues across 559 files and 81 checks.
- Full operator-browser suite: 196 passed, 2 failed, 1 guarded skip. One Phase 169 copy-status case passed on isolated rerun. The Phase 169 suppression-refresh case remains reproducibly failing in isolation; it is outside this plan and the Phase 168 tests passed. The existing browser gate remains advisory and outside CI Green.

## Decisions and deviations

The new 200% geometry assertions passed without source CSS changes, so the plan's conditional CSS adjustment was unnecessary. The pending status reuses the existing server-backed patch and styling conventions. No package, CI requirement, or branch-protection setting changed.

The broad browser run exposed an unrelated Phase 169 suppression-refresh failure, apparently in the existing fault-injection path. It is recorded for phase-level review and was not modified as part of this Phase 168 closure.

## Next Phase Readiness

The three identified UX requirements now have passing machine coverage; phase-wide security, code review, UI review, validation, regression, and verifier gates remain to be recorded before Phase 168 can be marked complete. No owner UAT is required for the deterministic criteria covered by this plan.

## Self-Check: PASSED

- The pending Account status test failed on the intended assertion before the implementation and passed afterward.
- The actual-tab-zoom checks prove the browser zoom value and rendered geometry.
- No human verification, dependency, or new CI lane was added for these acceptance criteria.

---
*Phase: 168-shared-workspace-and-usable-baseline, Plan 09*
*Completed: 2026-10-08*
