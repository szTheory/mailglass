---
phase: 169-outbound-investigation-and-recovery
plan: "01"
subsystem: outbound-operator
tags: [elixir, phoenix-liveview, ecto, playwright, replay]

requires: []
provides:
  - Account-scoped exact Delivery selection and an authorized exact-request replay path.
  - Truthful URL-backed filter drafts, collection states, and exact detail navigation.
  - A pre-edit rendered baseline with source and served asset provenance.
affects: [169-02, outbound-operator, delivery-investigation]

actuals:
  tokens: 78072
  tasks: 3
  commits: 4
commits: 4
plan_head_before: 987ae8c854a9056b6d34fe279bb74f043dc1f68e
plan_head_after: 2e870aa7c8262ffa8295a32765dd064502844e3d

tech-stack:
  added: []
  patterns:
    - Exact tenant-scoped lookup stays independent of bounded list membership.
    - Destructive replay rechecks the reviewed target immediately before execution.
    - Filter drafts remain separate from committed URL query state.
key-files:
  created:
    - .planning/phases/169-outbound-investigation-and-recovery/169-BASELINE.md
    - .planning/phases/169-outbound-investigation-and-recovery/artifacts/before/
    - mailglass_admin/e2e/phase169-journey.spec.js
  modified:
    - lib/mailglass/operator/deliveries.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - test/mailglass/operator/deliveries_test.exs
key-decisions:
  - "Keep exact Delivery selection independent of the current page and time window."
  - "Retain compatible filters across Account switches while clearing page and object evidence IDs."
  - "Use content-column width for the table-to-card breakpoint."
patterns-established:
  - "Exact reads are Account-scoped and disclose the same result for missing and foreign IDs."
  - "Replay confirmation reloads current target membership and reuses the reviewed exact request ID."
requirements-completed: [OUTUX-02, OUTUX-05]
coverage:
  - id: D1
    description: "An operator can open an exact off-page Delivery, review and replay the stored webhook request through host authorization, then return to the same list context."
    requirement: OUTUX-02
    verification:
      - kind: unit
        ref: "test/mailglass/operator/deliveries_test.exs; mailglass_admin/test/mailglass_admin/operator_live_test.exs"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/phase169-journey.spec.js — Phase 169 exact replay tracer"
        status: pass
    human_judgment: false
  - id: D2
    description: "Custom filter drafts, committed results, Account switches, and browser history preserve truthful URL-backed context."
    requirement: OUTUX-05
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs; mailglass_admin/test/mailglass_admin/operator/shell_test.exs"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/phase169-journey.spec.js — URL Back/Forward filter history"
        status: pass
    human_judgment: false
  - id: D3
    description: "Collection and exact detail views distinguish empty, filtered, invalid, foreign, out-of-range, and known unavailable states across responsive widths."
    requirement: OUTUX-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs; mailglass_admin/test/mailglass_admin/operator/replay_modal_test.exs"
        status: pass
      - kind: automated_ui
        ref: "mailglass_admin/e2e/operator.spec.js; mailglass_admin/e2e/flows.spec.js"
        status: pass
    human_judgment: false

duration: 24min
completed: 2026-10-08
status: complete
---

# Phase 169 Plan 01: Exact Delivery Investigation and Recovery Summary

**Account-scoped exact Delivery review and replay now preserve the stored request, truthful filters, and list context.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-10-08T00:09:31Z
- **Completed:** 2026-10-08T00:33:14Z
- **Tasks:** 3
- **Files modified:** 31 (including baseline captures)

## Accomplishments

- Added a sibling-only exact Delivery lookup constrained by Account and tenant scope; exact selection remains available outside the current page and time window.
- Connected the first browser replay path through current target revalidation, host destructive-action authorization, and the persisted command result.
- Made custom filter input, Account changes, history navigation, empty/error states, and responsive collection/detail layouts preserve truthful context.
- Recorded the pre-edit baseline with ten viewport captures plus source and served CSS hashes.

## Task Commits

Each task was committed atomically:

1. **Task 1: Exact outbound delivery replay tracer** - `8a14b550` (feat)
2. **Task 2: Preserve truthful account filter drafts** - `19583943` (fix)
3. **Task 3: Harden collection and exact selection states** - `fafb5692` (feat)
4. **Task 3 follow-up: Sync responsive delivery asset** - `2e870aa7` (style)

The measured plan commit count is four. The plan range is `987ae8c854a9056b6d34fe279bb74f043dc1f68e..2e870aa7c8262ffa8295a32765dd064502844e3d`.

## Verification

- Core exact lookup: 8 tests passed.
- Focused Admin LiveView, shell, replay modal, and persona cohort suite: 120 tests passed.
- Playwright operator browser run on port 4102: 8 tests passed, including exact replay, malformed detail, filtered-empty, responsive cards/table, full detail return, and URL Back/Forward.
- `git diff --check` passed before the final task commit.
- Pre-edit baseline provenance matched the built and served stylesheet.

## Files Created/Modified

- `.planning/phases/169-outbound-investigation-and-recovery/169-BASELINE.md` and `artifacts/before/` - pre-edit baseline record and captures.
- `lib/mailglass/operator/deliveries.ex` - exact Account-scoped Delivery read.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` and operator components - URL-backed filters, exact selection, recovery states, and review/return behavior.
- `mailglass_admin/e2e/phase169-journey.spec.js` - connected exact replay and navigation tracer.
- `mailglass_admin/test/support/` and Admin/core tests - named scenario reset, exact fixture, fault handling, and regression coverage.
- `mailglass_admin/assets/css/app.css` and `mailglass_admin/priv/static/app.css` - responsive content-width layout styling.

## Decisions Made

- Exact selection uses the requested Delivery ID independently of list membership, while the query remains Account and tenant scoped.
- Replay confirmation re-reads the currently eligible target and authorizes the same reviewed ID immediately before execution.
- Compatible filters remain when changing Account; page and selected object/evidence IDs are cleared.
- The comparison table appears only when the content column reaches 768px; narrower layouts use ordered cards.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Full-detail return reopened Quick view**
- **Found during:** Task 1 (exact replay tracer)
- **Issue:** The Back action retained the selected Delivery ID, so returning to the list reopened Quick view.
- **Fix:** Made explicit Back to deliveries clear the selected object while preserving Account and filter/page context.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/e2e/phase169-journey.spec.js`
- **Verification:** Playwright exact replay tracer and return path passed.
- **Committed in:** `8a14b550`

**2. [Rule 1 - Bug] Exact read call used the wrong arity**
- **Found during:** Task 1 (browser integration)
- **Issue:** The LiveView initially called `get_delivery/1` although the core API requires Account and Delivery ID.
- **Fix:** Routed reads through `get_delivery/2` with the selected Account.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`
- **Verification:** Core lookup tests and exact-detail browser tracer passed.
- **Committed in:** `8a14b550`

**3. [Rule 1 - Bug] Selection and read failures needed distinct recovery states**
- **Found during:** Tasks 2–3
- **Issue:** Invalid requested IDs could resemble an empty Account, and stale rows or detail failures could misrepresent the committed query.
- **Fix:** Distinguished invalid from missing/foreign IDs, retained known transient read errors with scoped retry, and added explicit filtered-empty and out-of-range states.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`, `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex`, related tests.
- **Verification:** Focused LiveView suite and 8 Playwright browser tests passed.
- **Committed in:** `fafb5692`

**Total deviations:** 3 auto-fixed (Rule 1). All were needed for correctness; no unresolved issues remain.

## Issues Encountered

The final task's generated stylesheet was omitted from its first staging attempt and was committed in a dedicated follow-up after syncing the source and served assets. No test failures or unrun verification remain.

## Known Stubs

None.

## Threat Flags

None. The exact lookup and replay path implement the plan's tenant disclosure and action-time authorization mitigations; no additional trust boundary was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 can build on the exact selection, filter-state, read-error, and browser reset patterns. The current tracer and regression suite pass; no blockers remain.

---
*Phase: 169-outbound-investigation-and-recovery*
*Completed: 2026-10-08*

## Self-Check: PASSED

- Summary file exists at the required path.
- All four task commits are ancestors of the current HEAD.
