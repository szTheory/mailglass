---
phase: 175-delivery-investigation-and-safe-replay
plan: "01"
subsystem: operator-ui
tags: [delivery, replay, phoenix-liveview, playwright, storybook]
requires: []
provides:
  - Connected, Account-scoped Delivery investigation and permitted replay with refreshed evidence, accessible result toast, and retained context.
  - Exact replay review from Quick view and Full detail using the same server-selected Delivery and ReplayAction presentation.
  - A retained production-component Storybook page for the Delivery investigation job.
affects: [Phase 175 follow-on replay states, Delivery quick view, Delivery full detail]
actuals:
  tokens: 6531.75
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 8331d8f5db50de185fceb4811e604bbd49dd0bb4
plan_head_after: 54266c4bd2344edd936284f67ed267a2f7f2c1db
tech-stack:
  added: []
  patterns:
    - Both Delivery surfaces reuse ReplayAction; origin is the only browser-supplied replay-entry value.
    - Selected replay candidates and confirm-time identity continue to come from scoped server reads.
key-files:
  created:
    - reference/demo_app/storybook/delivery_investigation.story.exs
    - .planning/phases/175-delivery-investigation-and-safe-replay/175-01-red-evidence.json
    - .planning/phases/175-delivery-investigation-and-safe-replay/175-01-red.tap
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_action.ex
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/mailglass_admin/components_test.exs
key-decisions:
  - "Replay target identity remains server-owned; browser events supply only the validated entry origin."
  - "Quick view and Full detail share ReplayAction, with review entry shown only for exact or explicitly ambiguous target sets."
requirements-completed: [UXF-12, REPLAY-04, REPLAY-05, REPLAY-06, REPLAY-07]
coverage:
  - id: D1
    description: Full Delivery investigation shows technical evidence before disclosure, refreshes scoped suppression, and returns with Account, filters, and exact selection intact.
    requirement: UXF-12
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js#Phase 175 Delivery tracer (1 passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: Quick view and Full detail review the same exact eligible webhook target; lookalike labels still require an explicit UUID choice.
    requirement: REPLAY-04
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 175 Delivery entry exposes replay from the selected quick and full detail"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 175 Delivery entry keeps same-looking ambiguous requests separate"
        status: pass
    human_judgment: false
  - id: D3
    description: Missing exact targets explain unavailability and expose no replay action; forged foreign-Account identity is ignored.
    requirement: REPLAY-05
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 175 Delivery entry explains unavailable replay and rejects forged identities"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/components_test.exs#Phase 175 Delivery entry component leaves unavailable replay explanatory and non-actionable"
        status: pass
    human_judgment: false
  - id: D4
    description: Stored-request review has a named Close control and preserves the existing exact review, selection, and focus safeguards.
    requirement: REPLAY-06
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js#Phase 175 Delivery tracer (named Close control asserted)"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 175 Delivery entry discards a review after the selected delivery changes"
        status: pass
    human_judgment: false
  - id: D5
    description: Permitted replay closes review, displays accessible success feedback, and refreshes persisted evidence for the actual outcome.
    requirement: REPLAY-07
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js#Phase 175 Delivery tracer (1 passed; result screenshot retained)"
        status: pass
    human_judgment: false
  - id: D6
    description: The retained Delivery investigation page composes bounded synthetic facts through the production components and does not simulate commands.
    verification:
      - kind: integration
        ref: "reference/demo_app GET /dev/storybook/delivery_investigation via Plug.Test Endpoint.call (status 200; page title and stored request ID present)"
        status: pass
    human_judgment: false
duration: 23min
completed: 2026-10-27
status: complete
---

# Phase 175 Plan 01: Delivery Investigation and Safe Replay Summary

**Scoped Delivery replay now works from Quick view and Full detail with exact server-owned targets, truthful availability, refreshed evidence, and retained review/result screenshots.**

## Performance

- **Duration:** 23 min
- **Started:** 2026-10-27T14:47:02Z
- **Completed:** 2026-10-27T15:10:13Z
- **Tasks:** 2
- **Files modified:** 11 (9 planned source, test, and story files plus 2 committed RED evidence files)

## Accomplishments

- Completed a permitted scoped Delivery investigation: visible technical details, Account-local suppression refresh, exact stored webhook review, actual replay result, accessible toast, and return context.
- Added exact replay entry to Quick view using the production `ReplayAction`; Full detail uses the same component. Unavailable targets show their reason without an enabled review action.
- Added tagged cases for exact and ambiguous target identity, same-looking labels, forged cross-Account values, missing linkage, and stale selection. The selected record and frozen candidate set remain server-owned.
- Retained `Storybook.DeliveryInvestigation` at `/dev/storybook/delivery_investigation`, composed from production components and bounded synthetic facts.
- Retained browser captures at `mailglass_admin/test-results/baseline-layout/delivery-175-replay-review.png` and `mailglass_admin/test-results/baseline-layout/delivery-175-replay-result.png`. The images were visually inspected; they are non-empty generated artifacts ignored by Git.

## Verification

- Browser tracer: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- flows.spec.js --grep "Phase 175 Delivery tracer"` — **1 passed**. It asserts the exact stored request UUID, scoped refresh, accessible Close and toast, actual replay evidence, and retained Account/filter/selection URLs.
- Tagged server and component cases: `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/components_test.exs --only phase175 --trace` — **6 Phase 175 tests executed, 0 failures** (ExUnit reports 228 discovered, 222 excluded).
- Named passing cases: `Phase 175 Delivery entry component carries quick-view origin with exact identity`; `Phase 175 Delivery entry component leaves unavailable replay explanatory and non-actionable`; `Phase 175 Delivery entry exposes replay from the selected quick and full detail`; `Phase 175 Delivery entry keeps same-looking ambiguous requests separate`; `Phase 175 Delivery entry explains unavailable replay and rejects forged identities`; `Phase 175 Delivery entry discards a review after the selected delivery changes`.
- Story route: an in-process `GET /dev/storybook/delivery_investigation` through `MailglassDemoWeb.Endpoint.call/2` returned **200**, with the page title and synthetic stored request UUID present.
- Formatting: Elixir `mix format` succeeded for the changed Elixir source and test files. Demo app compilation succeeded after compiling the lazy Storybook module.

## Task Commits

1. **Task 1: Complete one scoped Delivery investigation and permitted replay** — `1e4aae4c` (`feat`)
2. **Task 2 RED: Add failing exact-entry and availability cases** — `fca6fa14` (`test`)
3. **Task 2 GREEN: Expose exact replay in Delivery quick view** — `88969b23` (`feat`)
4. **Task 1 evidence correction: Retain connected Delivery screenshots** — `54266c4b` (`fix`)

The Summary/STATE/ROADMAP metadata commit is created during closeout after state updates.

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — Validates the replay origin, loads selected Delivery target availability on both surfaces, preserves the entry surface/focus return, and retains quick-view feedback.
- `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` — Keeps Full detail technical evidence visible after primary facts.
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` — Uses concise scoped-impact copy, an accessible X Close control, and semantic primary styling.
- `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex` and `mailglass_admin/lib/mailglass_admin/operator/replay_action.ex` — Reuse eligibility, reason copy, and origin-only review entry in Quick view and Full detail.
- `mailglass_admin/e2e/flows.spec.js` — Adds the connected tracer and validated review/result screenshots.
- `reference/demo_app/storybook/delivery_investigation.story.exs` — Retains the normal Delivery job composition without simulating commands.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` and `mailglass_admin/test/mailglass_admin/components_test.exs` — Add six tagged Phase 175 cases.
- `.planning/phases/175-delivery-investigation-and-safe-replay/175-01-red-evidence.json` and `.planning/phases/175-delivery-investigation-and-safe-replay/175-01-red.tap` — Preserve the machine-checkable RED run and its complete TAP report.

## Decisions Made

- Replay request IDs and candidate selection remain server-derived; browser events contribute only the expected entry origin.
- Both surfaces reuse `ReplayAction`; exact targets can open review, ambiguous targets require explicit selection, and unavailable states have no review primary action.

## TDD Gate Compliance

- **RED:** The target `Phase 175 Delivery entry exposes replay from the selected quick and full detail` failed on its planned assertion that the Quick view replay entry exists. Six Phase 175 cases executed (five failed on the missing entry/availability behavior and one stale-selection guard passed). `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check tdd-red-evidence .planning/phases/175-delivery-investigation-and-safe-replay/175-01-red-evidence.json --raw` returned `RED_EVIDENCE_OK` for the actual failing assertion. RED commit: `fca6fa14`.
- **GREEN:** The required tagged command passed all six Phase 175 cases with zero failures. GREEN commit: `88969b23`.
- **REFACTOR:** None needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added retained screenshots to the connected tracer**
- **Found during:** Final acceptance review
- **Issue:** The tracer asserted visible facts but did not retain the screenshots required by D-52 for agent review.
- **Fix:** Captured and size-checked the exact-request review dialog and completed result page in the existing browser artifact directory.
- **Files modified:** `mailglass_admin/e2e/flows.spec.js`
- **Verification:** The named browser tracer passed (1 case); both screenshot files were confirmed non-empty and visually inspected.
- **Committed in:** `54266c4b`

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** Added the missing review evidence; no domain command, storage, provider, or authorization contract changed.

## Issues Encountered

- The webhook fixture schema enforces unique `(provider, provider_event_id)`. The ambiguous case now uses distinct stored provider-event IDs, which render identical “POSTMARK webhook target” labels, and verifies deliberate UUID selection.
- The RED classifier does not accept raw ExUnit console output. A temporary TAP formatter captured the same test execution in a supported report format; the persisted report was accepted as `RED_EVIDENCE_OK`. The required ExUnit verification command was then run unchanged and passed.
- The demo Storybook module is lazily compiled. After a forced demo-app compile, the in-process route check returned 200 with its expected content; no application change was needed.
- The initial restricted browser launch could not create Chromium’s macOS process port. The named test was rerun with the available escalated browser permission and passed; no authentication gate occurred.

## User Setup Required

None - no external service configuration is required.

## Known Stubs

None. The Storybook page uses explicitly bounded synthetic facts and has no command simulation; the connected browser test verifies the real command and evidence.

## Threat Flags

None. The origin value is validated against the current surface. Delivery/target identity, fresh eligibility, authorization, and command effects remain behind the existing scoped server reads.

## Next Phase Readiness

The first complete Delivery investigation path is ready for the dependent Phase 175 plans to cover additional adverse and recovery states. No external setup or owner UAT checkpoint remains for this plan. `requirements.ready-ids` returned no ready IDs because all five declared requirements are also claimed by unfinished sibling plans; REQUIREMENTS.md remains pending until the final sibling summary.

---
*Phase: 175-delivery-investigation-and-safe-replay*
*Completed: 2026-10-27*

## Self-Check: PASSED

- Summary, Storybook page, and persisted RED evidence files exist.
- All four production/test commits are ancestors of the current HEAD; no plan commit deleted a tracked file.
- Both retained screenshots exist and are non-empty.
- Coverage classifier validated all six deliverables as automatically covered with no errors.
