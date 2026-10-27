---
phase: 174-faithful-storybook-and-quiet-quick-views
plan: "02"
subsystem: ui
tags: [phoenix-live-view, quick-view, storybook, playwright, elixir, inbound, operator]

requires:
  - phase: 174-01
    provides: Delivery production story, scenario manifest/builder, Storybook mount correction
provides:
  - Quiet Inbound quick-view arrows with retained production-component variations
  - Connected Inbound keyboard/focus return to the selected row on its originating surface
  - Scoped Delivery and Inbound pure-to-persisted projection evidence
affects: [174-03, 174-04, inbound-quick-view, storybook-projections]

actuals:
  tokens: 14175.5
  tasks: 2
  commits: 4
plan_head_before: c409e654bc37c92ed6efb649b5a91af71cc880f0
plan_head_after: 87d18cb73c7633ad60fbd339a91440f60954331f

tech-stack:
  added: []
  patterns:
    - Production list read boundaries feed the same quick-view components used by the pure scenario builder.
    - Scenario receipts distinguish persisted projection agreement, rendering-only states, and connected route-only empty states.

key-files:
  created:
    - reference/demo_app/storybook/quick_views/inbound.story.exs
    - mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - reference/persona_spec/quick_view_scenarios.ex
    - reference/persona_spec/quick_view_scenarios.json
    - reference/demo_app/assets/e2e/quick-views.spec.js
    - mailglass_admin/test/support/operator_fixtures.ex
    - mailglass_admin/test/support/inbound_fixtures.ex

key-decisions:
  - "Keep Inbound native disabled buttons and compare the raw persisted :accept outcome at the production component boundary."
  - "Normalize only generated selected IDs and documented timestamp precision/anchors; preserve recipient, subject, provider, outcome, Account, mailbox, provider ID, and mailable exactly."
  - "Keep unavailable and empty states within their real proof boundaries instead of fabricating persisted selections."

patterns-established:
  - "Projection tests read through the exact tenant-scoped production list gateway and render the real quick-view component."
  - "Scenario evidence names persisted, Storybook-render-only, and connected-real-route-only states separately."

requirements-completed: [UXF-11, STORY-03]
coverage:
  - id: D1
    description: "Inbound quick-view navigation is visually quiet, retains disabled boundaries, and returns focus to the selected row."
    requirement: UXF-11
    verification:
      - kind: e2e
        ref: "npm --prefix reference/demo_app/assets run test:e2e -- quick-views.spec.js --grep \"Phase174 inbound\" (3 passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Representative Delivery and Inbound scenario facts agree with scoped production projections and production component output."
    requirement: STORY-03
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs (4 tests)"
        status: pass
      - kind: other
        ref: "Scenario manifest inventory check (9 rendered stories; 18 unique selected scenario/theme cases)"
        status: pass
    human_judgment: false

duration: 26m
completed: 2026-10-27
status: complete
---

# Phase 174 Plan 02: Quiet Inbound Quick View Summary

**The retained Inbound quick view now uses quiet navigation, returns focus to its selected list row, and has scoped projection evidence beside its production-component stories.**

## Performance

- **Duration:** 26 minutes
- **Started:** 2026-10-27T02:22:15Z
- **Completed:** 2026-10-27T02:47:59Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Removed the idle border from the Inbound ghost navigation controls while retaining native disabled buttons, accessible labels, focus/hover states, and 44px targets.
- Added five retained Inbound production-component states and six manifest scenarios, with exactly nine rendered quick-view stories and 18 selected light/dark axe cases across Delivery and Inbound.
- Added connected checks for Account/filter URL preservation, first/last/single/normal selection, keyboard movement, disabled boundaries, close behavior, and exact focus return on desktop and mobile.
- Added projection agreement coverage for `qv-delivery-single-unicode`, `qv-inbound-normal`, and `qv-inbound-single-unicode`, plus Helios absence, a foreign Account exclusion, and the unavailable Inbound rendering state.

## Task Commits

1. **Task 1: RED —** `014acc97` — add failing Inbound quick-view browser checks.
2. **Task 1: GREEN —** `9e5496b9` — retain the quiet Inbound quick view and connected focus return.
3. **Task 2: RED —** `ecbfc71a` — add failing projection agreement coverage.
4. **Task 2: GREEN —** `87d18cb7` — prove scoped production projection agreement and record scenario evidence.

## Files Created/Modified

- `reference/demo_app/storybook/quick_views/inbound.story.exs` — retained normal, boundary, single-Unicode, and unavailable variations using the production component.
- `reference/persona_spec/quick_view_scenarios.ex` and `.json` — Inbound builder facts, raw `:accept` outcome, axe selections, projection receipts, and rendering/route-only evidence limits.
- `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex` — quiet idle arrows while preserving native disabled semantics.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` and `inbound/records_list.ex` — remember the validated desktop/mobile source and restore focus to the matching selected row.
- `reference/demo_app/assets/e2e/quick-views.spec.js` — connected and retained-story acceptance checks.
- `mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs` — scoped Delivery/Inbound projection and rendering agreement, position, foreign-tenant, empty, null, and unavailable checks.
- `mailglass_admin/test/support/operator_fixtures.ex` and `inbound_fixtures.ex` — supply the canonical Fjordline subject and scenario mailbox to the existing persona materializers.

## Verification Results

- `mix test test/mailglass_admin/quick_view_projection_test.exs` — 4 tests, 0 failures.
- `npm --prefix reference/demo_app/assets run test:e2e -- quick-views.spec.js --grep "Phase174 inbound"` — 3 passed.
- `mix format --check-formatted` on the modified Elixir files — passed.
- Manifest parse/count check — 9 rendered stories, 18 unique selected state/theme cases, and three persisted scenario receipts.
- RED evidence: Task 1 first exposed outlined Inbound controls, a missing Storybook iframe, and incomplete selected story coverage. Task 2 first exposed a missing canonical Delivery subject and a pure `:matched` value where the production Inbound read model returns `:accept`.

## Decisions Made

- Compare Delivery reads through `Mailglass.Operator.Deliveries.list_recent_deliveries_page/2` and Inbound reads through `MailglassAdmin.OptionalDeps.MailglassInbound.list_records_page/2`.
- Compare raw persisted fields before rendering the production components. The Inbound normal case uses six bounded fixture rows so its 3-of-6 position is independently reproduced.
- Normalize generated IDs only when comparing scenario and persisted presentation, and compare Inbound timestamps at second precision for the database's subsecond precision. Delivery fixture and Storybook time anchors remain independently generated and are validated as `DateTime` values.
- The persisted `reject_reason: nil` fact is recorded as source-only because neither the Delivery list projection nor the quick-view component consumes it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restore focus to the correct Inbound row after closing the quick view**
- **Found during:** Task 1
- **Issue:** Keyboard movement and close did not return focus to the exact selected row, as required by the acceptance contract.
- **Fix:** Added a validated desktop/mobile source marker and a focus-return target derived only from the selected row in the current collection.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/inbound_live.ex`, `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex`.
- **Verification:** Focused Inbound Playwright suite passed at the production route.
- **Committed in:** `9e5496b9`.

**2. [Rule 3 - Blocking issue] Align existing fixture materializers with the scenario facts needed for an exact projection comparison**
- **Found during:** Task 2
- **Issue:** The Fjordline admin fixture omitted its canonical subject, the Inbound fixture hardcoded its mailbox, and the normal pure scenario encoded `:matched` while the production read model returns `:accept`.
- **Fix:** Seed the canonical subject in the existing persona helper, allow the existing Inbound helper to receive its matched mailbox, and preserve the raw production `:accept` value in the scenario builder.
- **Files modified:** `mailglass_admin/test/support/operator_fixtures.ex`, `mailglass_admin/test/support/inbound_fixtures.ex`, `reference/persona_spec/quick_view_scenarios.ex`, `reference/persona_spec/quick_view_scenarios.json`.
- **Verification:** Projection agreement suite passed with exact subject, mailbox, outcome, Account, and position assertions.
- **Committed in:** `87d18cb7`.

**Total deviations:** 2 auto-fixed (one Rule 1, one Rule 3).
**Impact on plan:** Both changes were required by the focus-return acceptance contract or by the existing fixture/read-model boundary; no new public API, persisted schema, or dependency was added.

## Issues Encountered

- The sandboxed Chromium launch failed with macOS permission errors; the focused Playwright run succeeded with the authorized escalated execution path.
- The initial progress update found that `STATE.md` lacked the template's `Progress:` body line. The canonical line was restored and the CLI then recalculated the current overall progress as 0% while Phase 174 remains incomplete.
- No authentication gates occurred.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 03 should preserve the Inbound `phx-value-surface` marker and selected-row focus return behavior in `InboundLive`/`RecordsList`. Projection evidence identifies which Storybook states are rendering-only and which empty states are connected-route-only. The phase remains in progress with four plans outstanding.

---
*Phase: 174-faithful-storybook-and-quiet-quick-views*
*Completed: 2026-10-27*

## Self-Check: PASSED

- Summary and all ten plan files exist.
- All four task commits are ancestors of the current plan head.
