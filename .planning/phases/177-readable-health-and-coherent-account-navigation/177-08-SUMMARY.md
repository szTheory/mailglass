---
phase: 177-readable-health-and-coherent-account-navigation
plan: "08"
subsystem: testing
tags: [playwright, e2e, axe, health, container-query, measurement]
status: complete

requires:
  - phase: 177-04
    provides: "Candidate A, the 42rem Health reading column the comparison measures"
  - phase: 177-07
    provides: "e2e/support/account.cjs (visible-only Account/scope-nav locators)"
provides:
  - "Browser scenario phase177-health-all (all eight Health categories, counts 1..8)"
  - "177-HEALTH-COMPARISON.md: 252-measurement A vs B record, Winner: A"
  - "e2e/phase177-health.spec.js: eight retained Health gates (geometry, axe, link landing, focus, real width, long counts, help tier)"
affects: [177-11]

plan_head_before: 661a343bb0a8e8880254a3398ec1b447ff5f3fc0
plan_head_after: 809993d6bee397136c61e143aea586bc43ef288f

actuals:
  tokens: 41000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Real-route spike for composition comparisons: candidate B injected as a style element on the production markup, throwaway spec deleted before commit"
    - "Axe incomplete findings are annotated beside the violation count and resolved by a computed contrast check, never reported as a pass"

key-files:
  created:
    - mailglass_admin/e2e/phase177-health.spec.js
    - .planning/phases/177-readable-health-and-coherent-account-navigation/177-HEALTH-COMPARISON.md
  modified:
    - mailglass_admin/test/support/endpoint_case.ex

key-decisions:
  - "Winner A: both candidates pass G1-G7 in all 126 measurements each; tie-breakers 1-3 tie exactly; tie-breaker 4 (layout rules plus breakpoints, 3 vs 8) decides. Production unchanged."
  - "Unavailable state is produced by arming a one-shot failed_ingest fault on Deliveries and reopening Health from the scope nav (a full page load consumes the fault in the dead render; a window patch was not reachable from the UI)."
  - "Empty state uses the helios-void persona (zero Deliveries) rather than phase169-support-empty; it yields the exact verdict with no setup."

requirements-completed: ["OUTUX-06"]

coverage:
  - id: D1
    description: "Health composition decided by a bounded, recorded A vs B measurement; only the winner remains in production"
    requirement: OUTUX-06
    verification:
      - kind: command
        ref: "177-HEALTH-COMPARISON.md Winner line, 126 dark rows, per-pair >= 7 dark rows, Method versus D-15, Axe incomplete triage; throwaway spec absent from tree and git history; 0 layout/composition attrs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Health geometry gates G1-G4/G6 hold at 320/375/390/768/1024/1280/1440 across all-eight, default, partial, stale and armed-fault states"
    requirement: OUTUX-06
    verification:
      - kind: e2e
        ref: "playwright:phase177-health.spec.js Phase 177 Health gates hold at every width"
        status: pass
    human_judgment: false
  - id: D3
    description: "Axe reports 0 violations in operator-overview-health (light, dark, armed fault) with a non-vacuous include and a triaged incomplete finding"
    requirement: OUTUX-06
    verification:
      - kind: e2e
        ref: "playwright:phase177-health.spec.js Phase 177 Health axe"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every issue deep link lands on a view whose count equals the row count; Refresh keeps focus and width; 768 container width is captured; long counts widen only their cell; per-issue help stays subordinate"
    requirement: OUTUX-06
    verification:
      - kind: e2e
        ref: "playwright:phase177-health.spec.js (link landing, Refresh focus, real-width parity, long counts, help tier)"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-10-28
---

# Phase 177 Plan 08: Measured Health Composition Summary

**Candidate A (the single 42rem Health column) won a 252-measurement bounded comparison against the container-query grid B, decided by the layout-rule count (3 vs 8) after both passed every gate and tied tie-breakers 1-3; eight retained browser tests now hold the winner.**

## What was built

- Task 1 (tracer, `6d481176`): `phase177-health-all` clause in the browser-reset dispatcher (`endpoint_case.ex`) calling `OperatorFixtures.seed_phase177_health_all!()`; new `e2e/phase177-health.spec.js` with the tracer (eight rows, no overflow and 44px targets at 320 and 1440, Failed deliveries link lands on one failed row).
- Task 2 (`a05ea130`): a throwaway real-route spike measured A and B over 9 scenarios x 7 viewports x light/dark (252 records, each with an AxeBuilder scan). `177-HEALTH-COMPARISON.md` holds the protocol, method versus D-15, measured container widths, both gate tables, G5 fingerprint detail, axe incomplete triage, tie-breakers, `Winner: A`, the reason and the raw JSON lines. The spike spec and a second throwaway triage spec were deleted before commit and never entered git history.
- Task 3 (`809993d6`): the retained suite, eight tests (the tracer plus seven), `healthGates(page)` completed with G2, G3, G4 and G6.

## Decisive numbers

- Measured Health container widths: 288 / 343 / 358 / 480 / 736 / 992 / 1152 px at 320 / 375 / 390 / 768 / 1024 / 1280 / 1440. **768 viewport: 480 px** (measured, recorded in the comparison and attached to the real-width test).
- Gates: A 0 failures in 126 measurements, B 0 in 126. Axe: 0 violations in 252 scans, include matched >= 1 in every scan.
- Tie-breakers: scan path equal in 126 of 126 pairs; row slack equal in 84 of 84 pairs with rows; activity subordination satisfied by both in every pair; layout rules plus breakpoints A = 3, B = 8, so **A wins on tie-breaker 4**. The owner-visual-tie branch did not apply and no owner hand-off was needed.

## Verification evidence

- `mix test health_population_test + phase177_return_navigation_test --seed 0 --warnings-as-errors`: 35 tests, 0 failures (Task 1).
- `mix test health_population + health_overview + token_parity + assets --seed 0`: 42 tests, 0 failures; bundle byte-identical (`git diff --quiet priv/static/app.css`).
- Plan gate `health_population + health_overview + operator_live + inbound_live --seed 0`: 330 tests, 0 failures. `mailglass_admin/scripts/check-conformance.sh`: "OK: design-system conformance clean". `git status --short mailglass_admin/priv/static`: empty.
- `phase177-health.spec.js --grep "Phase 177"`: 8 passed, 0 skipped, 0 flaky.
- Axe annotations (include-match / violations / incomplete): all-eight light 1 / 0 / 1, all-eight dark 1 / 0 / 1, armed failed_ingest fault 1 / 0 / 1.
- Non-vacuity: temporarily shrinking the first issue link to `min-h-4` made both the tracer and "gates hold at every width" fail naming `operator-health-deliveries-failed-link`; production and bundle were restored (`git status` clean for both).

## Axe incomplete triage

Every scan reports exactly one incomplete item, `color-contrast`, on the visible "Refresh health" label ("Element's background color could not be determined due to a background image"): daisyUI's `btn` pseudo background stack defeats axe; computed `background-image` is "none, none" over a transparent colour. It is resolved by a computed contrast check, repeated inside the retained axe test on every scan: **5.26:1 light, 10.30:1 dark** (AA needs 4.5:1). Resolved, not counted as an axe pass. No other rule produced an incomplete result.

## Deviations from Plan

None - plan executed as written. Judgment calls inside the plan's latitude:
- `unavailable` is produced by arming the one-shot `failed_ingest` fault on Deliveries and reopening Health from the scope nav; a full page load consumed the fault during the dead render and a synthetic window patch never fired. The state is the real first-read-failed notice (`operator-health-unavailable-failed_ingest`); the verdict stays "Needs attention" from the panels that loaded.
- `empty` uses the `helios-void` persona (zero Deliveries, exact verdict "No mail activity in this period") instead of `phase169-support-empty`; recorded in the comparison.
- One extra retained test beyond the six listed ("long counts widen only their own cell") so the plan's large-count truth is held by a test; titles are stable.
- The plan's `scripts/check-conformance.sh` lives at `mailglass_admin/scripts/check-conformance.sh`; it was run from `mailglass_admin/`.

## Known Stubs

None.

## Threat Flags

None. Test-only browser scenario and specs; the reset route remains in the test endpoint only. No package installs or lockfile changes.

## Self-Check: PASSED

- FOUND: mailglass_admin/e2e/phase177-health.spec.js
- FOUND: .planning/phases/177-readable-health-and-coherent-account-navigation/177-HEALTH-COMPARISON.md
- FOUND commits: 6d481176 (Task 1), a05ea130 (Task 2), 809993d6 (Task 3)
- ABSENT as required: mailglass_admin/e2e/phase177-health-comparison.spec.js (tree and history), phase177-health-triage.spec.js
