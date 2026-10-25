---
phase: 168-shared-workspace-and-usable-baseline
plan: 01
subsystem: ui
tags: [phoenix-liveview, heex, tailwind, playwright, operator]
requires: []
provides:
  - Shared Account identity and bounded switching in operator chrome across Health, Deliveries, and Inbound.
  - Account-scoped filter forms without duplicate Account selectors.
  - Preserved-workspace and rendered before/after baseline evidence.
affects: [phase-168, operator, inbound, shared-navigation]
actuals:
  tokens: 71351
  tasks: 3
  commits: 3
  plan_head_before: 9db9f0141d0d29fcc6e008d53104c3a917bb9b0d
  plan_head_after: 1ef528b6b61b13e41631c74926a207af6fc60271
tech-stack:
  added: []
  patterns: [shared LiveView Account context, hidden tenant scope in filter submissions, bounded native details switcher]
key-files:
  created:
    - .planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md
    - .planning/phases/168-shared-workspace-and-usable-baseline/deferred-items.md
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
    - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
    - mailglass_admin/lib/mailglass_admin/surface_nav.ex
    - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/test/support/endpoint_case.ex
    - mailglass_admin/priv/static/app.css
key-decisions:
  - "Keep tenant_id as the stable URL scope; carry it in hidden filter fields after removing duplicate Account selectors."
  - "Use the shared operator shell for selected Account context and scope-preserving switch links; keep Preview outside production Account scope."
  - "Retain existing server-side host authorization and route handling; Account options are navigation aids, not authorization grants."
patterns-established:
  - "Operator pages pass selected Account ID, host label/options, and current URI into shared chrome."
  - "Cross-surface navigation preserves tenant_id and clears stale surface-specific record selections."
requirements-completed: [UXF-01, UXF-02, UXF-06, UXF-07]
coverage:
  - id: D1
    description: Reproducible preserved-workspace disposition and source-identified before/after route inventory.
    requirement: UXF-01
    verification:
      - kind: other
        ref: Python evidence-prefix gate plus six before and six after rendered captures in 168-BASELINE.md
        status: pass
    human_judgment: true
    rationale: A maintainer must judge the visual specimens and the recorded tooltip overflow finding.
  - id: D2
    description: Account switch changes the URL and server-scoped result while clearing the prior delivery selection.
    requirement: UXF-02
    verification:
      - kind: e2e
        ref: npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 168 Account scope"
        status: pass
    human_judgment: false
  - id: D3
    description: Both operator filter forms retain tenant scope without a second Account selector.
    requirement: UXF-06
    verification:
      - kind: unit
        ref: mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --seed 1 (172 passed, 2 pre-existing failures)
        status: fail
      - kind: automated_ui
        ref: Direct rendered DOM review of Deliveries and Inbound at localhost:4015
        status: pass
    human_judgment: true
    rationale: The focused test command retains two unrelated invalid-filter assertions that match the embedded Phoenix client bundle; rendered scope behavior passed direct review.
  - id: D4
    description: Configured navigation keeps the committed route cue, scope, and optional Inbound filtering.
    requirement: UXF-07
    verification:
      - kind: unit
        ref: mix test test/mailglass_admin/admin_shell_test.exs test/mailglass_admin/operator/shell_test.exs --seed 1
        status: pass
      - kind: automated_ui
        ref: AtlasDesk browser review at 320, 390, 768, and 1440 CSS px; details recorded in 168-BASELINE.md
        status: pass
    human_judgment: true
    rationale: Responsive page overflow from a pre-existing Health stat-card tooltip remains deferred outside this task's source scope.
duration: 48min
completed: 2026-10-07
status: complete
---

# Phase 168 Plan 01: Shared Account Context and Usable Baseline Summary

**Shared operator Account context and URL-scoped switching with a preserved workspace archive, built assets, and rendered baseline evidence.**

## Performance

- **Duration:** 48 minutes
- **Started:** 2026-10-07T18:20:39Z
- **Completed:** 2026-10-07T19:08:32Z
- **Tasks:** 3
- **Files modified:** 26 across the three task commits (including rendered specimens)

## Accomplishments

- Reconciled the authoritative cleanup squash while preserving the local planning lineage and existing unrelated workspace changes; archived the original dirt and recorded the exact merge evidence.
- Added a shared Account label, full stable `tenant_id`, and bounded keyboard/touch-operable switcher to operator Health, Deliveries, and Inbound. The Playwright switch path confirmed URL scope, cleared the previous delivery ID, and loaded the selected Account's scoped result.
- Removed duplicate Account filter selectors, retained `tenant_id` in hidden form fields, aligned the chooser copy with the UI contract, and verified the source-built stylesheet against the served response.
- Confirmed configured navigation, committed-route active cues, scope-preserving links, optional Inbound filtering, Preview's separate scope, and keyboard focus behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Reconcile, capture before, and switch one Account through the served operator shell** - `8473783c` (`feat`)
2. **Task 2: Carry Account context through Inbound and remove duplicate page-filter selection** - `5885521f` (`feat`)
3. **Task 3: Finish section navigation semantics and compact shell reflow** - `1ef528b6` (`test`)

The final GSD metadata commit records this summary and the state/roadmap updates.

## Files Created/Modified

- `.planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md` - archive identity, exact dispositions, before/after screenshots, served CSS hashes, filter/switch/navigation checks, and known responsive issue.
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` - shared Account context, native switcher, and exact chooser copy.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` and `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - shared shell assignments and hidden `filters[tenant_id]` fields.
- `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex` and `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex` - removed duplicate Account selectors.
- `mailglass_admin/e2e/flows.spec.js` and `mailglass_admin/test/support/endpoint_case.ex` - browser switch scenario and test-only account fixture setup.
- `mailglass_admin/lib/mailglass_admin/surface_nav.ex`, `mailglass_admin/lib/mailglass_admin/admin_shell.ex`, and shell tests - preserved configured navigation and asserted absent optional Inbound behavior.
- `mailglass_admin/priv/static/app.css` - rebuilt bundle matching the HEEx classes and served response.

## Decisions Made

- Keep `tenant_id` as the URL and filter-submission scope; do not create a second Account filter control.
- Preserve host-owned tenant resolution and authorization. Account option links are not authorization grants.
- Keep Preview as a separate development surface without production Account context.

## Deviations from Plan

- Long, duplicate, and mixed-script Account labels/IDs were reviewed by substituting text in the live rendered switcher DOM at 320px and 390px; the AtlasDesk fixture itself has only two distinct normal-length labels. The substituted text preserved the component markup/styles and tested wrapping, row sizing, and root overflow.
- A fully offline navigation attempt produced Chromium's native `ERR_INTERNET_DISCONNECTED` page because section navigation is a full-document route change. The application recovers after network restoration, but no in-app recovery message can render when the browser has no document connection.

## Verification and Deferred Issues

- Passed: Python evidence-prefix integrity/source gate.
- Passed: focused Playwright account-scope flow, 1 test.
- Passed: `mix test test/mailglass_admin/admin_shell_test.exs test/mailglass_admin/operator/shell_test.exs --seed 1`, 27 tests.
- Partial: Task 2 focused LiveView batch ran 174 tests; 172 passed. Two pre-existing `refute html =~ "not-real"` assertions fail because the term also appears in the embedded Phoenix JavaScript. Both are in `deferred-items.md`.
- Deferred: required document-level review found the existing invisible `.mg-stat-card-tooltip` extends 1px beyond the viewport at 320px and 164px at 768px on Health. It is outside this plan's source ownership and is recorded as open in `.planning/WINDOWS.md` entry 37.

## Issues Encountered

- The GSD SDK advanced the plan counter, recorded metrics/decisions/session, and marked the four plan requirements complete. `state.update-progress` skipped because `STATE.md` has no writable body `Progress:` line. `roadmap.update-plan-progress 168 01 complete` also skipped with `missing_phase_details`: its active-milestone write gate scans after the final archived `<details>` block, but the v2.9 phase sections precede that archived block. ROADMAP.md was left unchanged; no manual edit was made.

No new endpoint, authorization path, schema change, or security boundary was introduced. No stubs were added.

## Self-Check: PASSED

- Summary and baseline files exist.
- Rebuilt `mailglass_admin/priv/static/app.css` exists.
- Task commits `8473783c`, `5885521f`, and `1ef528b6` are ancestors of HEAD.

---
*Phase: 168-shared-workspace-and-usable-baseline*
*Completed: 2026-10-07*

## Orchestrator follow-up

The roadmap tracking issue was resolved after this plan returned: moved the unchanged archived milestone block before the active milestone, then `roadmap.update-plan-progress 168 01 complete` succeeded (1/4, In Progress). Strict state validation passed. Wave-post schema/UI gates passed; codebase drift was skipped because no STRUCTURE.md exists. Health tooltip overflow is carried into Plan 168-02 readability work.
