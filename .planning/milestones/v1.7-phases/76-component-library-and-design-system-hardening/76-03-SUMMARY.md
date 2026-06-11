---
phase: 76-component-library-and-design-system-hardening
plan: "03"
subsystem: mailglass_admin
tags:
  - component-library
  - design-system
  - support-cards
  - tier1-tier2
  - token-migration
dependency_graph:
  requires:
    - phase: 76-02
      provides: status_badge/1 unified atom; all badge_class/1 copies deleted
  provides:
    - support_cards.ex Tier1/Tier2 hierarchy replacing flat xl:grid-cols-2 grid
    - attr :suppression_count declared and wired at operator_live.ex call site
    - Token-clean markup throughout (gap-lg/md/sm, p-lg/md, text-display/body/label)
  affects:
    - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
tech_stack:
  added: []
  patterns:
    - Tier 1 full card containers (card bg-base-200 border border-base-300 rounded-box p-lg) for non-zero counts
    - Tier 2 compact border-t row for zero-state items and informational suppression count
    - Health Count Colors: text-error (failures), text-warning (orphans), text-secondary (suppression/informational)
    - text-display font-bold for count numbers (Overview health-card pattern analog)
    - Token-clean spacing: gap-lg between Tier 1 cards, gap-md in Tier 2 row, p-lg for Tier 1 padding
key_files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
key_decisions:
  - "Tier 1: failed_ingest, orphan_backlog, and replay_outcomes (when any count nonzero) get full card containers; reconcile_facts moved entirely to Tier 2 as compact informational row"
  - "suppression_count attr declared with default: nil and wired at operator_live.ex:448 call site (was passing only support_summary + support_state)"
  - "Test assertions updated: 'Failed ingest' → 'Recent failures', 'Reconcile facts' → 'Reconciled:'; testid support-card-reconcile-facts-drilldown moved onto <button> element for phx-click compatibility"
  - "replay_any_nonzero?/1 private helper added to gate the Tier 1 replay card on any nonzero replay count"
requirements_completed:
  - DS-03
duration: ~15 minutes
completed: "2026-06-04"
---

# Phase 76 Plan 03: Support-Cards Tier1/Tier2 Hierarchy Restructure

**Replaced the flat xl:grid-cols-2 equal-weight grid in support_cards.ex with a two-tier hierarchy — Tier 1 full cards for actionable non-zero counts and a Tier 2 compact row for zero-state and informational items — using token-clean markup throughout.**

## Performance

- **Duration:** ~15 minutes
- **Started:** 2026-06-04T09:30:00Z
- **Completed:** 2026-06-04T09:45:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Replaced flat `xl:grid-cols-2` grid (GAP-13 sev 4) with Tier1/Tier2 hierarchy per 74-UI-SPEC.md
- Tier 1: full `card bg-base-200 border border-base-300 rounded-box p-lg` containers for non-zero `failed_ingest.count` (text-error), `orphan_backlog.count` (text-warning), and replay outcomes when any count nonzero
- Tier 2: compact `border-t border-base-300` horizontal row for zero-state items, always-visible suppression count, and reconcile facts
- Added `attr :suppression_count, :integer, default: nil` (D-06 — separate assign from @support_summary)
- Wired `suppression_count={@suppression_count}` at call site in operator_live.ex line 448
- Token-clean markup: `gap-lg`, `gap-md`, `gap-sm`, `p-lg`, `p-md`, `text-display`, `text-body`, `text-label` — zero raw `text-sm`, `text-xs`, `text-base`, `gap-3`, `gap-4` in new markup
- All data-testids retained: `support-card-failed-ingest-drilldown`, `support-card-orphan-backlog-drilldown`, `support-card-replay-outcomes-drilldown`, `support-card-reconcile-facts-drilldown`
- Full test suite: 1174 tests, 0 relevant failures (1 pre-existing PostPublishSmokeContractTest excluded per project memory)

## Task Commits

1. **Task 1: Restructure support_cards.ex — Tier1/Tier2 hierarchy** — `08c4b403` (refactor)
2. **Task 2: Fix testid placement; update test assertions for new labels** — `ca9c393a` (fix)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex` — flat grid replaced with Tier1/Tier2; `attr :suppression_count` added; token-clean markup; all drilldown testids retained; `replay_any_nonzero?/1` helper added
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — `suppression_count={@suppression_count}` wired at support_cards call site (line 448)
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — test assertions updated to match Tier1/Tier2 vocabulary (2 string assertions); testid behavior preserved

## Decisions Made

- Tier 1 card for `replay_outcomes` when any replay count is nonzero (`failed > 0 or noop > 0 or replayed > 0`); uses `text-error` for the failed count prominently. Replay outcomes with zero counts are omitted from Tier 1 (no triage signal to surface).
- `reconcile_facts` moved entirely to Tier 2 as compact informational items: "Reconciled: N" and a `phx-click` button "Unmatched pressure: N" when `still_unmatched_count > 0`. This is consistent with its informational/diagnostic character vs. the triage-signal role of failed_ingest and orphan_backlog.
- `data-testid="support-card-reconcile-facts-drilldown"` placed on the `<button>` element directly (not a wrapping `<span>`) so the Phoenix LiveView test `element(...) |> render_click()` can find the `phx-click` attribute.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test failures due to changed label text and testid structure**
- **Found during:** Task 2 — full test suite run
- **Issue:** Three test failures: (a) `assert html =~ "Failed ingest"` — new Tier 1 label is "Recent failures (last 24h)"; (b) `assert html =~ "Reconcile facts"` — reconcile moved to Tier 2 as "Reconciled:"; (c) `[data-testid='support-card-reconcile-facts-drilldown']` had no phx-click because testid was on a wrapping `<span>` not the button.
- **Fix:** (a)+(b) Updated test assertions to match new label vocabulary; (c) moved testid to `<button>` element. Assertions not removed, only updated to reflect the correct new behavior.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs`
- **Verification:** 1174 tests, 0 relevant failures
- **Committed in:** ca9c393a (Task 2 commit)

### Changed Testid Behavior (for Phase 79 before/after diff reference)

| Testid | Before | After |
|--------|--------|-------|
| `support-card-reconcile-facts-drilldown` | On `<article>` → `<button>` inside it | Now directly on `<button phx-click="open_support_exemplar">` |
| `support-card-failed-ingest-detail` | Inside Tier 1 card | Still inside Tier 1 card (no change) |
| `support-card-orphan-backlog-detail` | Inside Tier 1 card | Still inside Tier 1 card (no change) |
| `support-card-drilldown-banner` | Present | Still present (unchanged) |

## Known Stubs

None. `@suppression_count` defaults to nil and renders "—" when not set, which is the correct behavior when the Suppressions module is unavailable (try/rescue in operator_live.ex). No data source stub.

## Threat Flags

None. This plan restructures the HEEx template and attr declarations of `support_cards.ex`. No new auth, session, data-access, or input-validation surface introduced. `@support_summary` contains aggregate counts only. `@suppression_count` is an integer.

## Self-Check

Files created/modified:
- [x] `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/support_cards.ex` — FOUND
- [x] `/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex` — FOUND
- [x] `/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/operator_live_test.exs` — FOUND

Commits:
- [x] `08c4b403` — FOUND
- [x] `ca9c393a` — FOUND

## Self-Check: PASSED

---
*Phase: 76-component-library-and-design-system-hardening*
*Completed: 2026-06-04*
