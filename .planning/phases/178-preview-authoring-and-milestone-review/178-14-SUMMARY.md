---
phase: 178-preview-authoring-and-milestone-review
plan: "14"
subsystem: testing
tags: [Playwright, accessibility, CI, evidence]

requires:
  - phase: 178-13
    provides: "Recorded-advisory input for measuring a known Operator Browser Gate failure"
provides:
  - "Hashed trace diagnosis and a recorded nondeterministic outcome for the PR-run Operator Browser Gate failure"
  - "Self-diagnosing focus checks immediately before PageDown and End"
affects: [178-15, 178-17]

actuals:
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Inline active-element polls report an element id or tag before each keyboard scroll boundary"
    - "Advisory reds are recorded on a title line with the measured repeat-log hash"

key-files:
  created: []
  modified:
    - mailglass_admin/e2e/flows.spec.js
    - .planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md

key-decisions:
  - "Classify the hosted End-key failure as nondeterministic: both traces preserve dialog focus and show scroll movement, but omit the dimensions and callback result needed to locate the false bottom predicate."
  - "Treat the failed local startup attempt as a separate harness race: readiness can precede fixture seeding. Exclude it from the repeat count and use a ready server for the valid 50-run measurement."

requirements-completed: []

coverage:
  - id: D1
    description: "The saved PR-run failure is compared with its retry trace and the passing dispatch run on the same tree."
    requirement: "UIQ-08"
    verification:
      - kind: other
        ref: "178-AUTOMATION.md: both trace hashes and event findings; candidate-to-main commit count is 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "The nondeterministic classification meets the required 50 consecutive target passes and full in-order file pass."
    requirement: "UIQ-08"
    verification:
      - kind: integration
        ref: "classification-repeat.log: 50 passed; local-flows-full-rerun.log: 46 passed, 0 failed"
        status: pass
    human_judgment: false
  - id: D3
    description: "Focus-loss recurrences identify the active element, and both shared helper cases remain stable."
    requirement: "UIQ-08"
    verification:
      - kind: integration
        ref: "precondition-red.log: expected inbound-quick-view, received BODY; local-target-30.log: 30 passed; local-delivery-10.log: 10 passed"
        status: pass
    human_judgment: false

duration: 13min
completed: 2026-11-01
status: complete
plan_base_sha: 5dc4b84202ba64b14094203c84e42157996d591c
plan_head_before: 5dc4b84202ba64b14094203c84e42157996d591c
plan_head_after: 00143b5a9fe91ba7d1532affe1699ab6c851759b
---

# Phase 178 Plan 14: PR-run Operator Browser Gate Diagnosis

**The PR-only End-key failure remains unexplained by the available traces, so it is recorded as nondeterministic after the required local runs; future focus loss now reports the active element at both scroll boundaries.**

## Accomplishments

- Analyzed both saved hosted traces. The dialog retained focus; PageDown advanced `scrollTop` to 625 and End advanced it to 630. Neither trace records `clientHeight`, `scrollHeight`, or the final poll value, and there is no frame navigation, dialog replacement, or captured LiveView WebSocket patch in the observed interval.
- Confirmed the PR merge tree equals the candidate tree. The dispatch run on that same tree passed the target test.
- Added one inline focus poll before each key press. Each reports `element?.id || element?.tagName`; the End poll identifies `BODY` when a temporary `dialog.blur()` mutation removes focus.
- Recorded the exact advisory title and SHA-256 for the valid `50/50` CI repeat log. The full in-order `flows.spec.js` rerun passed all 46 tests; final Inbound and shared-helper Delivery checks passed `30/30` and `10/10`.

## Verification

| Check | Result |
|---|---|
| Target, CI mode | 50/50 passed (`classification-repeat.log`); final 30/30 passed (`local-target-30.log`) |
| Full `flows.spec.js`, CI mode | 46 passed on the fresh in-order rerun (`local-flows-full-rerun.log`) |
| Delivery sibling, CI mode | 10/10 passed (`local-delivery-10.log`) |
| Deliberate focus loss | Expected red; `precondition-red.log` reports `Received: "BODY"` |
| Static acceptance | Passed: exactly two focus polls, original scroll predicate and key presses retained, skip/fixme counts unchanged, config and CSS clean |

The first full-file run had one unrelated Phase 168 Delivery Mailable wrapping setup failure (45 passed, 1 failed); the case passed in isolation, and the subsequent full-file rerun passed 46/46. An invalid repeat attempt also ended before the test started: `/ops/browser-ready` can respond before the browser server finishes fixture seeding, so its initial seed raced with Playwright's reset request on the shared SQL Sandbox connection. Those setup failures were excluded. For the valid repeat, the test server reached `fixtures_seeded` and `ready` before Playwright connected through a temporary local reuse config; that config was removed, and the tracked Playwright config/retry policy remained unchanged.

## Task Commits

1. **178-14-01: Save hosted trace diagnosis** — `f6c42043`
2. **178-14-02: Add self-diagnosing focus polls** — `5ee9a173`
3. **178-14-02: Record the PR-run outcome** — `00143b5a`

## Files Modified

- `mailglass_admin/e2e/flows.spec.js` — two inline focus assertions around PageDown and End.
- `178-AUTOMATION.md` — trace findings, local evidence, classification, and exact recorded advisory title.

## Next Plan

Plan 178-15 is next in gap-only dependency order. Plan 178-16 retains its owner checkpoint before any remote action.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-11-01*
