---
phase: 178-preview-authoring-and-milestone-review
plan: "27"
subsystem: browser-tests
tags: [playwright, chromium, accessibility, recovery]

requires:
  - phase: "178-26"
    provides: "Hosted failure traces for the inbound quick-view End-key assertion"
provides:
  - "Test-only wait for native smooth-scroll completion before End"
  - "Locally reproduced and verified fix with original accessibility checks preserved"
affects: [178-28, UIQ-06]

actuals:
  tokens: 6200
  tasks: 3
  commits: 1
plan_head_before: de799da72b9ebbce45bd1f358f8527b0c894cbe1
plan_head_after: 8e501960bc975ed44b632ba5c74522e0c5d66f8c

tech-stack:
  added: []
  patterns: ["Wait for native scrollend between sequential smooth-scroll keyboard inputs"]

key-files:
  created: [.planning/debug/operator-inbound-scroll-178.md]
  modified: [mailglass_admin/e2e/flows.spec.js]

key-decisions:
  - "Wait for scrollend before End; preserve the exact bottom predicate and all focus/accessibility assertions."
  - "Keep this as a browser-test timing fix; no product behavior or dependency changed."
  - "Local evidence does not replace exact-SHA hosted verification."

patterns-established:
  - "When smooth native scrolling is part of a keyboard test, wait for its completion event before sending the next navigation gesture."

requirements-completed: []
coverage: []

duration: 95min
completed: 2026-11-02
status: complete
---

# Phase 178 Plan 27: Inbound Scroll Timing Fix

**The browser test now waits for native smooth-scroll completion before sending End; its accessibility and bottom-boundary assertions remain unchanged.**

## Accomplishments

- Isolated the hosted failure to Chromium sometimes ignoring End near the tail of a PageDown smooth-scroll animation. The same signature reproduced without the application.
- Added a one-shot `scrollend` wait in `mailglass_admin/e2e/flows.spec.js`; no product code, dependency, or lockfile changed.
- The inbound and delivery scroll tests passed three times each. The timing harness passed 12/12 with the fix; reverting the change restored failure in 3/12 runs.
- Independent review found no blocker. The original keyboard, focus, disabled-boundary, and exact-bottom assertions remain.

## Commit

| Task | Commit | Description |
|---|---|---|
| 178-27-02/03 | `8e501960bc975ed44b632ba5c74522e0c5d66f8c` | Wait for scroll completion before End; local target and mutation checks passed |

## Deviations

The diagnosis, implementation, verification, and source commit completed before this summary was written. This closeout records that completed work; it does not imply hosted acceptance.

## Hosted boundary and next action

The original candidate failed the same assertion on two hosted attempts. The new fix has not yet run in hosted CI. Plan 28 owns the new exact-SHA hosted cycle and conditional cost/preview checks. PR #317 remains open and draft; no merge, release, publication, or deployment is authorized.

## Self-Check: PASSED

The exact source commit exists, the debug record contains the root cause and verification evidence, and no product or dependency changes are included.
