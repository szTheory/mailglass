---
phase: 33-observability-incident-support
plan: 03
subsystem: ui
tags: [liveview, operator, observability, privacy, replay, reconcile]
requires:
  - phase: 33-01
    provides: canonical support vocabulary for provider, replay, and reconcile facts
  - phase: 33-02
    provides: tenant-scoped support summary read model and exemplars
provides:
  - delivery-centric support cards inside the existing operator detail view
  - masked overview recipient cues with exact selected-detail identity preserved
  - exemplar drilldowns that highlight replay and reconcile facts or reveal concrete webhook rows
affects: [mailglass_admin operator surface, operator incident support, replay audit wording]
tech-stack:
  added: []
  patterns: [tenant-scoped support cards, URL-backed support drilldowns, masked overview identity]
key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
    - mailglass_admin/lib/mailglass_admin/operator/repair_state.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
key-decisions:
  - "Support cues stay inside the selected-delivery column and load through URL-backed state instead of a separate dashboard surface."
  - "Overview rows mask recipient-like identifiers by default while the selected detail header keeps exact support context."
  - "Replay audit and reconcile facts use separate labels, badges, and drilldown banners so operator copy does not flatten them together."
patterns-established:
  - "Support drilldowns patch LiveView params to reveal a concrete webhook row or highlight a durable timeline fact."
  - "Support cards remain read-only and tenant-scoped, with exemplar details rendered inline rather than broad fleet summaries."
requirements-completed: [MAT-02]
duration: 8 min
completed: 2026-05-05
---

# Phase 33 Plan 03: Operator support cards with masked overview identity and exemplar drilldowns

**Delivery-centric support cards now sit in the existing operator detail view, with masked overview rows, distinct replay/reconcile fact labeling, and URL-backed exemplar drilldowns into webhook and timeline evidence.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-05T18:13:00Z
- **Completed:** 2026-05-05T18:20:46Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added a read-only `SupportCards` component between the detail header and timeline, backed by the Phase 33 support summary seam.
- Masked recipient-like identifiers in overview rows while preserving exact selected-delivery identity for authorized support work.
- Added exemplar drilldowns that reveal failed-ingest and orphan facts inline and highlight replay or reconcile facts in the timeline with visible context.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add read-only support cards and privacy-minimized overview cues to the operator surface**
   - `7644f99` `test(33-03): add failing operator support card regression`
   - `1fd4bc3` `feat(33-03): add operator support card surface`
2. **Task 2: Expand LiveView regression coverage for support cards, wording, and privacy posture**
   - `350705c` `test(33-03): add failing support drilldown regression`
   - `8aa247c` `feat(33-03): add support exemplar drilldowns`

## Files Created/Modified
- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex` - renders the four read-only support cards and visible drilldown context.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - loads tenant support summaries for selected deliveries and preserves drilldown state in params.
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` - masks recipient-like identifiers in the overview list.
- `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` - adds replay/reconcile badges, durable event IDs, and highlighted drilldown rows.
- `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex` - centralizes replay/reconcile event badge and summary wording.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - locks support-card rendering, privacy posture, and exemplar drilldown behavior.

## Decisions Made
- Kept support cues read-only and delivery-centric inside the existing master-detail LiveView rather than branching into a new operator dashboard.
- Used URL params for support drilldowns so the selected fact survives refresh and copied links the same way delivery selection already does.
- Put exact webhook row details only behind selected-detail support cards while keeping the broader list view masked.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The plan-level verification command `mix test test/mailglass/operator/support_summary_test.exs test/mailglass/operator/timeline_test.exs --warnings-as-errors` failed in `test/mailglass/operator/timeline_test.exs` on the pre-existing chronological ordering assertion for `Mailglass.Operator.Timeline.list_delivery_events/2`. That file is outside this plan's ownership and already dirty in the current working tree, so it was left unchanged.
- `lib/mailglass/operator/support_summary.ex` emits a pre-existing boundary warning for `Mailglass.Webhook.WebhookEvent` during compilation. This plan did not modify that core read model.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The operator surface now has tenant-scoped support cues and exemplar drilldowns that later plans can extend without widening scope into a dashboard product.
- The remaining blocker outside this plan is the existing core timeline test failure noted above if the orchestrator requires a fully clean cross-project verification run.

## Self-Check: PASSED

- Found `.planning/phases/33-observability-incident-support/33-03-SUMMARY.md`
- Found commits `7644f99`, `1fd4bc3`, `350705c`, and `8aa247c`
