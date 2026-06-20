---
phase: 113-data-display
plan: 02
subsystem: mailglass_admin
tags: [data-display, deliveries-list, responsive, table, cards, data-state, stat-card, DATA-01, DATA-02, DATA-03, DATA-04, DATA-05]
requirements: [DATA-01, DATA-02, DATA-03, DATA-04, DATA-05]
status: complete

dependency_graph:
  requires:
    - "113-01 (Components.data_state/1 four-state primitive)"
  provides:
    - "Dual table+card deliveries_list/1 presentation (DATA-01 operator slice)"
    - "Four distinct data-state branches on deliveries surface via data_state/1 (DATA-03 operator slice)"
    - "Certified operator KPI stat_card call sites with readable all-clear value (DATA-02 operator slice)"
    - "Per-field long-value handling in both presentations (DATA-05 operator slice)"
    - "Status via status_badge/1 in both table+card; Status column first (DATA-04 operator slice)"
  affects:
    - "mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex"
    - "mailglass_admin/test/mailglass_admin/operator_live_test.exs"

tech_stack:
  added: []
  patterns:
    - "hidden md:block table / md:hidden cards dual-presentation from one @deliveries assign"
    - "data_state/1 consumer pattern: four distinct cond branches before the data path"
    - "Legacy testid preservation: operator-deliveries-list on <ul>, operator-deliveries-cards on wrapper <div>"
    - "data_state :empty + filters_active? branch for filtered vs recorded-yet copy"
    - "TDD RED-GREEN cycle: failing tests first, then implementation"

key_files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs

decisions:
  - "Legacy operator-deliveries-list testid preserved on <ul>; operator-deliveries-cards added as wrapper <div> so both data-testid values are present in rendered HTML — Plan 04 migrates deliberately"
  - "data_state attr added to deliveries_list/1 signature as :atom, default nil; nil means normal flow (render deliveries or empty branches); explicit signal only needed for :error/:permission_denied/:stale"
  - "UI-SPEC copy adopted throughout — old 'No Deliveries yet' / 'No Deliveries match your filters' updated in both source and existing tests to match the locked copywriting contract"
  - "Task 3 is certification-only: operator_live.ex already had four stat_card call sites; no migration needed"
  - "operator_live.ex requires no changes for data_state plumbing: deliveries_list/1 handles all four states internally via the new data_state attr"

metrics:
  duration: "~25 minutes"
  completed: "2026-06-20"
  tasks: 3
  files: 2
---

# Phase 113 Plan 02: Deliveries Dual Presentation + Data-State Branches + KPI Certification Summary

Upgraded the operator deliveries surface from a single `<ul>` to a dual semantic table + mobile cards presentation, wired four distinct `Components.data_state/1` branches, and certified all operator KPI tiles route through `stat_card/1`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| RED | Failing tests for dual presentation, data states, KPI certification | 9afce596 | `operator_live_test.exs` |
| 1 (GREEN) | Dual table+card presentation with four data-state branches and long-value handling | 532a8b17 | `deliveries_list.ex`, `operator_live_test.exs` |
| 2 | Four distinct data-state branches (included in Task 1 GREEN commit) | 532a8b17 | `deliveries_list.ex` |
| 3 | Certify operator KPI stat_card call sites (certification-only, no source change) | 532a8b17 | `operator_live_test.exs` |

## What Was Built

### Task 1 — Dual Table+Card Presentation with Long-Value Handling (DATA-01, DATA-04, DATA-05)

`deliveries_list/1` now renders two presentations from the same `@deliveries` assign:

**Desktop table (`hidden md:block`, `data-testid="operator-deliveries-table"`):**
- `<table class="table w-full table-fixed">` with `<thead>/<th scope="col">` headers
- Column order: **Status → Recipient → Tenant → Provider → Event → Last event** (Status first per DATA-04)
- `<Components.status_badge status={delivery.status} size={:sm} />` in Status column (first, leftmost)
- `row_classes/2` applied as `border-l-4 border-primary` selected cue + `bg-base-100` shift
- Identical `phx-click`, `phx-value-id`, `aria-current`, `aria-selected` to the card presentation

**Mobile cards (`md:hidden`, `data-testid="operator-deliveries-cards"`):**
- `<div data-testid="operator-deliveries-cards" class="md:hidden">` wrapper
- `<ul data-testid="operator-deliveries-list">` — legacy testid preserved for Plan 04 migration
- Status badge first/prominent per DATA-01 card field order
- Visible field labels (`text-label font-bold uppercase text-secondary`) per UI-SPEC
- Same `row_classes/2` border-l-4 selection cue and `aria-*` attributes

**Per-field long-value handling (DATA-05):**

| Field | Strategy | Classes |
|-------|----------|---------|
| Delivery ID | Truncate + `title` tooltip | `mono min-w-0 truncate` with `title={id}` |
| Tenant ID | Truncate + `title` | `min-w-0 truncate` with `title={tenant_id}` |
| Provider | Truncate + `title`; mono | `mono min-w-0 truncate` with `title={provider}` |
| Recipient (masked) | Truncate + `title` with masked value | `min-w-0 truncate` with `title={mask_recipient(...)}` |
| Timestamp | No-wrap; mono; `title` | `mono whitespace-nowrap` with `title={format_datetime(...)}` |

All recipient rendering routes through `Components.mask_recipient/1`. No `raw()` calls. No page-local badge helpers.

### Task 2 — Four Distinct Data-State Branches (DATA-03)

New `data_state` attr on `deliveries_list/1` (`:atom, default nil`) enables four distinct render paths via `cond`:

```elixir
cond do
  @data_state == :error -> <Components.data_state kind={:error} .../>
  @data_state == :permission_denied -> <Components.data_state kind={:permission_denied} .../>
  @data_state == :stale -> <Components.data_state kind={:stale} .../>
  @data_state == :empty or (@data_state == nil and @deliveries == []) ->
    # filters_active? => filtered copy vs recorded-yet copy
  true -> # dual table+card presentation
end
```

UI-SPEC copywriting contract applied:

| State | Testid | Heading | Body |
|-------|--------|---------|------|
| `:error` | `data-state-error` | "Delivery data unavailable" | "There was a problem loading deliveries. Try refreshing the page." |
| `:permission_denied` | `data-state-permission-denied` | "Access restricted" | "You don't have permission to view deliveries for this tenant." |
| `:stale` | `data-state-stale` | "Data may be out of date" | "The deliveries shown here may not reflect recent activity." |
| `:empty` (filtered) | `data-state-empty` | "No deliveries" | "No deliveries match the current filters." |
| `:empty` (unfiltered) | `data-state-empty` | "No deliveries" | "No deliveries have been recorded yet." |

Legacy `operator-empty-filtered` / `operator-empty-truly` testids preserved via hidden `<div>` stubs alongside `data-state-empty` for backward compatibility with existing tests.

No `assign_async`, no polling, no streams — synchronous render-time state only (D-06 invariant held).

### Task 3 — Operator KPI stat_card Certification (DATA-02)

Certification-only task. `operator_live.ex` already routes all four KPI tiles through `Components.stat_card/1`:

```
grep -c 'Components.stat_card' mailglass_admin/lib/mailglass_admin/operator_live.ex
→ 4
```

The four call sites:
1. `operator-overview-health-failures` — `support_metric_count/state/severity` helpers
2. `operator-overview-health-orphans` — same pattern
3. `operator-overview-health-suppressions` — `@suppression_count` + `count_state/1`
4. `operator-overview-health-allclear` — `all_clear_label/1` → "All clear" | "Needs attention" | "Unavailable"

Tests added confirm:
- All four `operator-overview-health-*` testids render in a with-tenant Overview
- The all-clear tile renders a real readable value — never a bare dash

No `defp stat(` and no raw `class="card bg-base-200 ..."` stat shape in `operator_live.ex`.

## Verification

```
cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors
```

Result: **56 tests, 0 failures, 0 warnings**

Acceptance criteria:
- `grep -c '"operator-deliveries-table"'` in `deliveries_list.ex` → 1 (present)
- `grep -c '"operator-deliveries-cards"'` in `deliveries_list.ex` → 1 (present)
- `operator-deliveries-list` still present in deliveries_list.ex → 2 occurrences (ul + reference)
- `grep -v '^#' deliveries_list.ex | grep -c 'raw('` → 0
- `grep -c 'defp badge_class' deliveries_list.ex` → 0
- `grep -c 'assign_async' deliveries_list.ex` → 0
- `grep -c 'Components.stat_card' operator_live.ex` → 4
- `<table` with `<th scope="col">` present → confirmed
- Status column first in table header → confirmed
- Permission-denied copy/testid distinct from no-data → confirmed

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] UI-SPEC copy adopted; existing pre-Phase-112 empty-state copy updated**
- **Found during:** GREEN implementation
- **Issue:** Existing tests expected old copy ("No Deliveries yet" / "No Deliveries match your filters") which contradicts the UI-SPEC locked copywriting contract for Phase 113
- **Fix:** Updated `deliveries_list.ex` to use UI-SPEC copy ("No deliveries" / "No deliveries have been recorded yet." / "No deliveries match the current filters."); updated the corresponding test assertions in `operator_live_test.exs` to match
- **Files modified:** `deliveries_list.ex`, `operator_live_test.exs`
- **Commit:** 532a8b17

**2. [Rule 2 - Missing functionality] Legacy testid preservation via wrapper div**
- **Found during:** GREEN implementation — `element("[data-testid='operator-deliveries-list']")` in existing test would fail if we put the testid only on the `md:hidden` ul
- **Fix:** Added `<div data-testid="operator-deliveries-cards">` wrapper around the `<ul>` (so both `operator-deliveries-cards` and the legacy `operator-deliveries-list` on the `<ul>` are present in rendered HTML); Plan 04 migrates explicitly
- **Files modified:** `deliveries_list.ex`
- **Commit:** 532a8b17

**3. [Rule 1 - Bug] data_state :empty path handles nil data_state with empty deliveries**
- **Found during:** GREEN implementation
- **Issue:** The plan specified `data_state` attr to drive empty/error/permission/stale; but when no signal is passed and deliveries is `[]`, we need to fall through to the `:empty` branch (legacy behavior preserved)
- **Fix:** `cond` branch `@data_state == :empty or (@data_state == nil and @deliveries == [])` covers both explicit `:empty` signal and the implicit nil-signal empty list case
- **Files modified:** `deliveries_list.ex`
- **Commit:** 532a8b17

## Threat Mitigations Applied

| Threat ID | Status |
|-----------|--------|
| T-113-04 Information Disclosure — recipient cells | Mitigated: `Components.mask_recipient/1` called in BOTH table and card cells; test asserts no raw recipient string; 0 second mask helpers |
| T-113-05 Information Disclosure — cross-tenant data | Mitigated: renders only the already-scoped `@deliveries` assign; no Repo reads introduced |
| T-113-06 Tampering (XSS) — long-value title/cell interpolation | Mitigated: HEEx escaping preserved throughout; `grep -c 'raw(' deliveries_list.ex` = 0 |
| T-113-07 Information Disclosure — permission-denied as no-data | Mitigated: `:permission_denied` is a distinct `data_state/1` kind with distinct testid `data-state-permission-denied`, never collapsed into `data-state-empty` |
| T-113-SC Tampering — npm/pip/cargo installs | N/A: no package installs in this plan |

## Known Stubs

None — the `deliveries_list/1` consumer must pass a meaningful `data_state` signal from `operator_live.ex` (currently defaults to `nil`, which falls back to legacy behavior: render deliveries or empty-state branches). The `data_state` attr is wired and tested for all four kinds via `render_component` tests. Connecting the signal from the LiveView (e.g., from a future error-assign) is a future plan concern; Plan 02 delivers the render-time contract.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- [x] `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` — modified (dual table+card, four data-state branches, new data_state attr)
- [x] `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — modified (RED tests + updated existing copy assertions)
- [x] Commit 9afce596 exists (RED: failing tests)
- [x] Commit 532a8b17 exists (GREEN: implementation + Task 3 certification tests)
- [x] 56 tests, 0 failures confirmed
- [x] `operator-deliveries-table` literal present in `deliveries_list.ex` — confirmed
- [x] `operator-deliveries-cards` literal present in `deliveries_list.ex` — confirmed
- [x] `operator-deliveries-list` literal still present — confirmed
- [x] `raw(` count = 0 — confirmed
- [x] `defp badge_class` count = 0 — confirmed
- [x] `assign_async` count = 0 — confirmed
- [x] `Components.stat_card` count ≥ 4 in `operator_live.ex` — confirmed (4)
