---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "13"
subsystem: ui
tags: [filters, deliveries, liveview, js-commands, a11y, d-16, tdd]
status: complete
gap_closure: true

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "Plan 12 copy-control accessible name (wave 2)"
provides:
  - "Deliveries filters_active?/1 and applied_filter_count/1 decide the window through one helper, non_default_window?/1"
  - "Class-based mobile Filters toggle (JS.toggle_class mg-inbound-filters-open) chained with the aria-expanded flip"
  - "PubSub refresh that leaves the polite status region text unchanged (WR-07, D-16)"
  - "Quiet normalization of a present-but-blank window_hours (IN-07), aligned with Inbound"
affects: [176-14, 176-15, phase-176-verification]

plan_head_before: b53d4ceed6850bf8ab495480ddaec432a49ca721
plan_head_after: 29afeff68fd744b6e79f2a37251616c2a7f7ce20
actuals:
  tokens: 9000
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "A non-default time window is a filter on both collections (Deliveries now matches Inbound)"
    - "Mobile filter panels toggle a class that ships in the committed bundle, never an inline display style"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/e2e/phase176-filters.spec.js

key-decisions:
  - "Window counts as a filter exactly as Inbound counts it; the default 168 h (written out or implied) is not a filter"
  - "Toggle reuses mg-inbound-filters-open (already in priv/static/app.css, count 1) instead of adding CSS, avoiding an app.css rebuild and the TokenParity landmine"
  - "PubSub refresh keeps the previous results_status_text; Retry and commit reads still announce"
  - "Blank window_hours reads as absent (default 168, no error, no Custom period); non-blank invalid windows keep the D-13 error"

requirements-completed: ["FILTER-01"]

coverage:
  - id: D1
    description: "An empty narrower window keeps #operator-filters, the chosen window, the filtered-empty pane and Clear filters; never the genuine no-data pane"
    requirement: "FILTER-01"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 gap: an empty narrower window keeps the toolbar and a way back"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 gap: a direct URL with an empty narrower window keeps the toolbar"
        status: pass
    human_judgment: false
  - id: D2
    description: "The default window written out explicitly is not a filter; the toggle count agrees with the empty-state branch"
    requirement: "FILTER-01"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 gap: the default window written out explicitly is not a filter"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 gap: the toggle count and the empty-state branch agree on the window"
        status: pass
    human_judgment: false
  - id: D3
    description: "The Deliveries mobile toggle emits toggle_class then toggle_attr, no bare toggle op, and the panel class stays hidden md:block; the panel is visible at 1280px after a 360px close"
    requirement: "FILTER-01"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 gap: the mobile Filters toggle switches a class, never an inline display"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 gap: deliveries filter panel is visible at desktop width after a mobile close"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 gap: inbound filter panel is visible at desktop width after a mobile close"
        status: pass
    human_judgment: false
  - id: D4
    description: "A PubSub refresh updates rows but leaves the status region text; the next commit resynchronizes it"
    requirement: "FILTER-01"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 gap: a PubSub refresh does not rewrite the status region"
        status: pass
    human_judgment: false
  - id: D5
    description: "A blank window normalizes quietly to 168 with no Custom period; a non-numeric window keeps the D-13 error"
    requirement: "FILTER-01"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 gap: a blank window normalizes quietly without a Custom period option"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#retains custom positive window links, rejects unsafe window drafts and normalizes a blank window quietly"
        status: pass
    human_judgment: false
---

# Phase 176 Plan 13: Deliveries window, toggle and status-region gap closure Summary

**Deliveries now treats a non-default time window as a filter (toolbar and a way back survive an empty window), toggles its mobile panel by class so it survives a close at desktop width, keeps the polite status region quiet on PubSub refreshes, and reads a blank window as the default.**

## Performance

- **Duration:** about 25 min
- **Tasks:** 3 (tracer, auto, auto)
- **Commits:** 4 (one RED test commit covering all three tasks, then one fix commit per task)

## Accomplishments

- WR-02: `filters_active?/1` and `applied_filter_count/1` both call the private `non_default_window?/1`, so an empty narrower window renders the toolbar with the chosen window selected, the filtered-empty pane and Clear filters instead of the genuine no-data pane. Window 168 stays a non-filter, so the single calm pane for a genuinely empty Account is untouched.
- Mobile toggle: `JS.toggle_class("mg-inbound-filters-open", to: "#operator-filter-panel")` chained with the existing aria-expanded flip. No CSS was added or rebuilt; `priv/static/app.css` already carries the rule.
- WR-07 / D-16: `refresh_visible_state/1` (deliveries) restores `results_status_text` after the background re-read.
- IN-07: `normalize_window_filter/2` reads a blank value as the default whether or not the key is present; `filter_draft_params/2` no longer copies a blank value into the draft.

## Task Commits

1. RED tests for all three tasks: `dfed337c` (`test(176-13)`)
2. Task 1, non-default window is a filter: `26156bdb` (`fix(176-13)`)
3. Task 2, class-based toggle plus browser case: `42b33757` (`fix(176-13)`)
4. Task 3, status text and blank window: `29afeff6` (`fix(176-13)`)

## Red-then-green

| Test | Red (pre-fix) | Green |
|------|---------------|-------|
| Phase 176 gap: an empty narrower window keeps the toolbar and a way back | fail: `[data-testid='operator-filters']` absent | pass after `26156bdb` |
| Phase 176 gap: a direct URL with an empty narrower window keeps the toolbar | fail: `#operator-filters` absent | pass after `26156bdb` |
| Phase 176 gap: the default window written out explicitly is not a filter | pass (adjacency guard, passes before and after) | pass |
| Phase 176 gap: the toggle count and the empty-state branch agree on the window | pass (count already used the window; guard against drift) | pass |
| Phase 176 gap: the mobile Filters toggle switches a class, never an inline display | fail: `"toggle"` op present | pass after `42b33757` |
| Phase 176 gap: a PubSub refresh does not rewrite the status region | fail: status read "2 deliveries match" | pass after `29afeff6` |
| Phase 176 gap: a blank window normalizes quietly without a Custom period option | fail: "Custom period" rendered | pass after `29afeff6` |
| retains custom positive window links, rejects unsafe window drafts and normalizes a blank window quietly | not observed red: the test is outside the phase176 tag, so the RED run (--only phase176) did not include it; the blank gap test above covers the same behavior and was red | pass after `29afeff6` |
| Browser: Phase 176 gap: deliveries filter panel is visible at desktop width after a mobile close | fail with the toggle temporarily reverted to `JS.toggle(to:)` (panel not visible at 1280px) | pass |
| Browser: Phase 176 gap: inbound filter panel is visible at desktop width after a mobile close (control) | pass in the same reverted run | pass |

## Verification

- `mix test test/mailglass_admin/operator_live_test.exs --only phase176 --seed 0`: 0 failures.
- `mix test test/mailglass_admin/operator_live_test.exs --seed 0`: 172 tests, 0 failures.
- `mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/phase176_prohibition_contract_test.exs --only phase176 --seed 0`: 148 tests, 0 failures, 84 excluded (includes "Phase 176 Inbound a blank window normalizes quietly without a Custom period option").
- `cd mailglass_admin && mix test --seed 0`: 860 tests, 0 failures, 1 excluded.
- Browser lane (advisory, D-29), wrapper run under bash with app.css and the Phase 168/169 artifact dirs clean before and restored after: **4 passed** (2 new "Phase 176 gap" tests, one per collection; existing "mobile Filters toggle reaches 44px"; structural "Operator: filter toggle and detail back controls meet touch target floor"). RC=0, app.css and artifact dirs clean afterwards.
- Acceptance greps: `JS.toggle(to:` count 0 in `operator_live.ex`; `mg-inbound-filters-open` count 1 in `priv/static/app.css`; no diff under `mailglass_admin/priv/static` or `mailglass_admin/assets/css`.
- `mix format --check-formatted` lists only files this plan did not touch (pre-existing format drift in other admin files); `operator_live.ex` and `operator_live_test.exs` are formatted.

## Reversed assertion and tradeoff

**Reversed test (bounded D-13 reading).** The existing test "retains custom positive window links and rejects unsafe or empty window drafts" asserted that a blank window draft is rejected with "Time window was not applied" and keeps an empty selection. This plan reverses that one step: a blank window now normalizes quietly to 168 (no error, no Custom period option, "168" selected), and the test is renamed "retains custom positive window links, rejects unsafe window drafts and normalizes a blank window quietly". The reversal rests on the bounded reading of locked D-13: a present-but-blank `window_hours` is read as absent, not invalid, matching what Phase 176 already ships on Inbound (`inbound_live.ex` `normalize_window_filter/2`, test "Phase 176 Inbound a blank window normalizes quietly without a Custom period option"). Non-blank invalid windows keep the D-13 error and the D-12 draft retention: the 39-digit draft assertion is unchanged and the new blank-window gap test pins `window_hours=abc` still rendering "Time window was not applied". CONTEXT.md was not edited. Verify-work should read the rename as intended, not as a weakened test.

**D-16 tradeoff.** After a `{:delivery_updated, ...}` PubSub refresh, the visible rows can change while the polite status region keeps the count from the last committed read. Example from the WR-07 test: one delivery is open and the region reads "1 delivery matches"; a second and then a third delivery arrive over PubSub, all three rows render, and the region still reads "1 delivery matches". This is accepted under D-16: the region speaks after a commit or a Retry, never on another operator's background activity. The next commit (the test changes the event filter) resynchronizes it to "3 deliveries match".

## Deviations from Plan

None in behavior. One process note: the plan orders tests per task; because all three tasks edit the same test file, the failing tests for all three were written and committed together as a single RED commit (`dfed337c`), followed by one fix commit per task. The browser-lane red proof for the Deliveries case was done by temporarily reverting the toggle line to `JS.toggle(to: ...)` (restored byte-for-byte from a saved copy before committing).

## Known Stubs

None.

## Threat Flags

None. T-176-31 (blank-value branch) mitigated: only blank values changed behavior; the positive-integer parse and `@max_window_hours` bound stay and the oversized-draft assertion still expects the error. T-176-32 mitigated: other actors' PubSub activity no longer reaches the polite status region.

## Self-Check: PASSED

- Files modified exist: operator_live.ex, operator_live_test.exs, phase176-filters.spec.js.
- Commits dfed337c, 26156bdb, 42b33757, 29afeff6 are ancestors of HEAD.
- No user WIP (`.planning/config.json`, state.json, research, seeds, HANDOFF.json, prompt.txt) staged in any commit.
