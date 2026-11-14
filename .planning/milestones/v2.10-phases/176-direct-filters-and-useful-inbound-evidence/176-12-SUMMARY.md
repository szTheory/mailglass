---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "12"
subsystem: ui
tags: [a11y, wcag-2.5.3, label-in-name, copy-value, inbound, tdd]
status: complete
gap_closure: true

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "Plan 11 evidence-card gap closure (wave 1)"
provides:
  - "Components.copy_value/1 accessible name \"Copy <label>: <value>\" (value is part of the name)"
  - "Component test (hostile quote/angle-bracket value) and Inbound contact-list test over every contact copy button"
  - "15 browser role locators moved off the label-only exact name"
affects: [176-13, 176-14, 176-15, phase-176-verification]

plan_head_before: c049d0fdc1bb9a8e4b2ebf2d05cc99ebc098989e
plan_head_after: df8f35341110e7a2a006a5fbe5668fbcd80e9eb6
actuals:
  tokens: 4500
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "One accessible-name convention for copy controls: \"Copy <what>: <value>\" (timestamp and copy_value agree)"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/test/mailglass_admin/components_test.exs
    - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/e2e/inbound-layout.spec.js
    - mailglass_admin/e2e/phase169-journey.spec.js
    - mailglass_admin/e2e/phase175-inbound.spec.js
    - reference/demo_app/assets/e2e/cohort.spec.js

key-decisions:
  - "Fixed the shared component, not only the Inbound header: all 13 copy_value call sites show their value as the button text, so all had the same Label-in-Name defect"
  - "Format \"Copy <label>: <value>\" follows the existing timestamp copy control; visible text, data-copy-value and data-copy-toast are unchanged"
  - "Browser locators use the full exact name where the value is already in scope, an anchored regex (^Copy <label>: ) elsewhere"

requirements-completed: ["INUX-05"]

coverage:
  - id: D1
    description: "Every copy_value button's accessible name is \"Copy <label>: <value>\" and contains its visible text (WCAG 2.5.3)"
    requirement: "INUX-05"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/components_test.exs#clickable identifiers expose the exact value and shared copy feedback"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/components_test.exs#Phase 176 every contact copy button's accessible name contains its address"
        status: pass
    human_judgment: false
  - id: D2
    description: "A hostile value (quote, angle brackets) stays one escaped aria-label with no injected attribute (T-176-29)"
    requirement: "INUX-05"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/components_test.exs#a copy control's accessible name carries a hostile value as one escaped attribute"
        status: pass
    human_judgment: false
  - id: D3
    description: "Missing contacts render no copy button, so no accessible name with an empty value exists"
    requirement: "INUX-05"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/components_test.exs#Phase 176 missing contacts render no copy button"
        status: pass
    human_judgment: false
  - id: D4
    description: "Browser specs locate copy controls by the new value-bearing names and still pass"
    requirement: "INUX-05"
    verification:
      - kind: e2e
        ref: "playwright: flows, inbound-layout, phase169-journey, phase175-inbound (69 passed); demo cohort + quick-views (12 passed)"
        status: pass
    human_judgment: false
---

# Phase 176 Plan 12: Copy controls name their value Summary

**Every `Components.copy_value/1` button is now named "Copy <label>: <value>", so the visible address (or ID) is part of the accessible name (WCAG 2.5.3 Label in Name), and 15 browser locators were moved to the new names.**

Duration: about 10 minutes. Tasks: 2. Files: 8.

## Accomplishments

- Closed gap SC4 / INUX-05 (review WR-04). Complete Inbound contact addresses (From, Reply-To, To, Cc including those behind "Show N more", Delivered to) were exposed to assistive technology only as "Copy To address" because the `aria-label` replaced the visible text. The name is now "Copy To address: ada@example.com".
- Fixed the shared component, so the Record ID, Provider message ID, Delivery ID and Event ID copy controls in the inbound and operator views get the same correction. `data-copy-value`, `data-copy-toast`, `title` and the visible text are unchanged, so sighted behaviour does not move. `copy_button/1` and the timestamp control were not touched.
- `@doc` of `copy_value/1` now states that the accessible name contains the visible value.

## Task Commits

1. Task 1 RED: `68907e1f` test(176-12): add failing tests for copy-control accessible name carrying the value
2. Task 1 GREEN: `67394fb0` feat(176-12): copy_value accessible name includes the visible value
3. Task 2: `df8f3534` test(176-12): locate copy controls by their value-bearing accessible names

## TDD Evidence (red then green)

RED (`components_test.exs` + `inbound/components_test.exs`, `--seed 0`: 165 tests, 3 failures, each on the planned assertion):
- `clickable identifiers expose the exact value and shared copy feedback`: left `["Copy Delivery ID"]`, expected `["Copy Delivery ID: exact-record-id"]`.
- `a copy control's accessible name carries a hostile value as one escaped attribute`: left `["Copy To address"]`, expected the name with the exact value.
- `Phase 176 every contact copy button's accessible name contains its address`: left `"Copy From address"`, expected `"Copy From address: ada@example.com"`.
- `Phase 176 missing contacts render no copy button` passed already (guard test: no button, so no empty-value name; it keeps passing after the fix by design).

GREEN: components_test + inbound/components_test + phase176_prohibition_contract_test: 189 tests, 0 failures (P2 masking and P5 telemetry green). Full admin suite `mix test --seed 0`: 853 tests, 0 failures, 1 excluded.

The contact test asserts the copy-button count is at least 12 (1 From, 1 Reply-To, 3 To, 6 Cc, 1 envelope) before its per-button loop, so it cannot pass on an empty or truncated list; it also checks that the Unicode address `用户@例子.广告`, the sixth Cc (behind "Show 1 more") and the envelope each appear verbatim in a name.

## Locator Changes (file:line, new locator)

| File:line | New locator |
|---|---|
| flows.spec.js:976, 1055 | `` name: `Copy Delivery ID: ${expectedDeliveryId}`, exact: true `` |
| flows.spec.js:995, 1065 | `name: /^Copy Event ID: /` |
| flows.spec.js:1574 | `name: /^Copy Delivery ID: /` |
| flows.spec.js:1963 | `` name: `Copy Delivery ID: ${deliveryId}`, exact: true `` |
| flows.spec.js:2050 | `` name: `Copy Delivery ID: ${selected.deliveryId}`, exact: true `` |
| inbound-layout.spec.js:215, 228, 230 | `name: /^Copy Record ID: /` (value changes between assertions) |
| phase169-journey.spec.js:143 | `name: /^Copy Event ID: /` |
| phase169-journey.spec.js:420 | `name: /^Copy Delivery ID: /` |
| phase175-inbound.spec.js:204, 283 | `name: /^Copy Record ID: /` |
| reference/demo_app/assets/e2e/cohort.spec.js:127 | `name: /^Copy Provider message ID: /` |

Test titles, scope locators and following assertions are unchanged. `quick-views.spec.js:236` already used a non-exact name and was not touched. `git grep -E 'name: "Copy [A-Za-z ]+", exact: true'` over both e2e trees: no match (baseline 15).

## Advisory Browser Lane (D-29)

- Admin: `npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js inbound-layout.spec.js phase169-journey.spec.js phase175-inbound.spec.js`: 69 passed, 0 failed.
- Demo (external-server mode, throwaway database `mailglass_demo_176_12_tmp` on port 4716, dropped afterwards; `mailglass_demo_dev` untouched): `cohort.spec.js` + `quick-views.spec.js` 12 passed, 0 failed, `demo-e2e-exit=0`. The first attempt gave 8 passed / 4 failed: the four `cohort.spec.js` cases failed in their `beforeEach` because `POST /demo/evidence/reset` returned 403 (the server was started without `DEMO_EVIDENCE_RESET_TOKEN` / `DEMO_EVIDENCE_PROJECT_ID`, which `authorized_evidence_reset?/1` requires). That was an environment gap, not a locator defect. Restarting the throwaway server with a throwaway token and a project id matching the required pattern (`mailglass-evidence-1-1`), both set only for that process and the spec run, gave 12 of 12.
- Restore: `priv/static/app.css`, `reference/demo_app/mix.lock` and both tracked Phase 168/169 artifact directories were restored by path and match HEAD (`git status --porcelain` empty on them). Note: the plan's wrapper used an unquoted `$A` holding two paths; under zsh it is not word-split, so the wrapper's own `git checkout`/`git clean` did not restore the 169 PNGs. I restored them by hand with the two paths spelled out. Nothing from `priv/static/` or an artifact directory was staged. Plan 176-13/15/14 wrappers should spell the two paths explicitly (or run under bash).

## Deviations from Plan

None - plan executed exactly as written. The demo lane needed the reset-token environment described above; that is lane setup, not a plan deviation.

## Issues Encountered

- The `$A` word-splitting issue under zsh described above (restored manually; no committed impact).
- One attempted `pkill -f phx.server` during cleanup was blocked by the permission classifier as too broad; I then stopped only the server on port 4716 by its pid.

## Known Stubs

None.

## Threat Flags

None. T-176-29 mitigated: HEEx escapes attribute values, and the hostile-value test asserts one button, the exact decoded value, and no attribute beyond type, data-copy-value, data-copy-toast, aria-label, title and class. T-176-30 accepted as planned (the address is already the visible text on the same authorized page; DOM-only, no telemetry path, P5 green). No package installs (T-176-SC).

## Next Phase Readiness

Ready for 176-13 (wave 3). Plan 176-14 adds contract P10 with a recorded mutation for this prohibition. No blockers.

## Self-Check: PASSED

- `grep -c '"Copy " <> @label}'` in components.ex: 0 (baseline 1); `aria-label={"Copy #{@label}: #{@value}"}` present.
- Old exact-name locators: none remain in `mailglass_admin/e2e` and `reference/demo_app/assets/e2e`.
- Commits 68907e1f, 67394fb0, df8f3534 are ancestors of HEAD; `git rev-list --count` from the ledger base is 3.
