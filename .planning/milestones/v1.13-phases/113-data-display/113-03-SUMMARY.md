---
phase: 113-data-display
plan: 03
subsystem: mailglass_admin
tags: [data-display, inbound-records, responsive, table, cards, data-state, stat-card, DATA-01, DATA-02, DATA-03, DATA-04, DATA-05]
requirements: [DATA-01, DATA-02, DATA-03, DATA-04, DATA-05]
status: complete

dependency_graph:
  requires:
    - "113-01 (Components.data_state/1 four-state primitive)"
    - "113-02 (DeliveriesList sibling pattern)"
  provides:
    - "Dual table+card records_list/1 presentation (DATA-01 inbound slice)"
    - "Four distinct data-state branches on inbound surface via data_state/1 (DATA-03 inbound slice)"
    - "Certified inbound KPI stat_card call sites with meaningful values (DATA-02 inbound slice)"
    - "Per-field long-value handling in both presentations (DATA-05 inbound slice)"
    - "Outcome via status_badge/1+normalize_inbound_outcome/1 in both table+card; Outcome column first (DATA-04 inbound slice)"
  affects:
    - "mailglass_admin/lib/mailglass_admin/inbound/records_list.ex"
    - "mailglass_admin/test/mailglass_admin/inbound_live_test.exs"

tech_stack:
  added: []
  patterns:
    - "hidden md:block table / md:hidden cards dual-presentation from one @records assign"
    - "data_state/1 consumer pattern: four distinct cond branches before the data path"
    - "Legacy testid preservation: inbound-records-list on <ul>, inbound-records-cards as <div> wrapper"
    - "data_state :empty + empty_state atom sub-flavors for no_tenant/truly_empty/filtered copy distinctions"
    - "TDD RED-GREEN cycle: failing tests committed first, then implementation"

key_files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs

decisions:
  - "Added Recipient column (masked) to inbound table after Outcome — makes recipient visible in BOTH presentations (plan behavior test 5 requires mask_recipient/1 in both); column order is Outcome→Recipient→Mailbox→Tenant→Provider→Received"
  - "Legacy inbound-records-list testid preserved on <ul>; inbound-records-cards as wrapper <div> so both testid values render — Plan 04 migrates deliberately (mirrors Plan 02 decision)"
  - "data_state attr added to records_list/1 signature as :atom, default nil; nil means normal flow (render records or empty-state branches)"
  - "UI-SPEC copy adopted: 'No records' / 'No records have been recorded yet.' / 'No records match the current filters.' (replacing 'No InboundMessages yet' / 'InboundMessages appear here...' / 'No InboundMessages match these filters')"
  - "Task 3 is certification-only: inbound/overview.ex already had four stat_card call sites — no migration needed"
  - "Empty sub-state :no_tenant keeps original copy 'Select a tenant' / 'Choose a tenant...' routed through data_state :empty — preserves UI semantics without creating a fifth data-state kind"

metrics:
  duration: "~8 minutes"
  completed: "2026-06-20"
  tasks: 3
  files: 2
---

# Phase 113 Plan 03: Inbound Records Dual Presentation + Data-State Branches + KPI Certification Summary

Upgraded the inbound records surface from a single `<ul>` to a dual semantic table + mobile cards presentation, wired four distinct `Components.data_state/1` branches, and certified all inbound KPI tiles route through `stat_card/1`. Exact mirror of Plan 02 (deliveries) with inbound nouns.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| RED | Failing tests for dual presentation, data states, KPI certification | 98da28bc | `inbound_live_test.exs` |
| 1+2+3 (GREEN) | Dual table+card, four data-state branches, KPI cert | ef049c48 | `records_list.ex`, `inbound_live_test.exs` |

## What Was Built

### Task 1 — Dual Table+Card Presentation with Long-Value Handling (DATA-01, DATA-04, DATA-05)

`records_list/1` now renders two presentations from the same `@records` assign:

**Desktop table (`hidden md:block`, `data-testid="inbound-records-table"`):**
- `<table class="table w-full table-fixed">` with `<thead>/<th scope="col">` headers
- Column order: **Outcome → Recipient (masked) → Mailbox → Tenant → Provider → Received** (Outcome first per DATA-04)
- `<Components.status_badge status={Components.normalize_inbound_outcome(record_outcome(record))} size={:sm} />` wrapped in `<span data-testid={"inbound-outcome-#{record_outcome(record)}"}>` in Outcome column (first, leftmost)
- `row_classes/2` applied as `border-l-4 border-primary` selected cue + `bg-base-100` shift
- Identical `phx-click`, `phx-value-id`, `aria-current`, `aria-selected` to the card presentation

**Mobile cards (`md:hidden`, `data-testid="inbound-records-cards"`):**
- `<div data-testid="inbound-records-cards" class="md:hidden">` wrapper
- `<ul data-testid="inbound-records-list">` — legacy testid preserved for Plan 04 migration
- Outcome badge first/prominent per DATA-01 card field order
- Visible field labels (`text-label font-bold uppercase text-secondary`) per UI-SPEC
- Same `row_classes/2` border-l-4 selection cue and `aria-*` attributes

**Per-field long-value handling (DATA-05):**

| Field | Strategy | Classes |
|-------|----------|---------|
| Record ID | Truncate + `title` tooltip | `mono min-w-0 truncate` with `title={record.id}` |
| Tenant ID | Truncate + `title` | `min-w-0 truncate` with `title={tenant_id}` |
| Provider | Truncate + `title`; mono | `mono min-w-0 truncate` with `title={provider}` |
| Mailbox | Truncate + `title` | `min-w-0 truncate` with `title={matched_mailbox_label(record)}` |
| Recipient (masked) | Truncate + `title` with masked value | `min-w-0 truncate` with `title={mask_recipient(...)}` |
| Timestamp (received_at) | No-wrap; mono; `title` | `mono whitespace-nowrap` with `title={format_datetime(...)}` |

All recipient rendering routes through `Components.mask_recipient/1`. No `raw()` calls. No page-local badge helpers.

### Task 2 — Four Distinct Data-State Branches (DATA-03)

New `data_state` attr on `records_list/1` (`:atom, default nil`) enables four distinct render paths via `cond`:

```elixir
cond do
  @data_state == :error -> <Components.data_state kind={:error} .../>
  @data_state == :permission_denied -> <Components.data_state kind={:permission_denied} .../>
  @data_state == :stale -> <Components.data_state kind={:stale} .../>
  @data_state == :empty or (@data_state == nil and @records == []) ->
    # :no_tenant → data_state :empty with "Select a tenant" copy
    # :truly_empty → data_state :empty with "No records have been recorded yet."
    # :filtered → data_state :empty with "No records match the current filters."
  true -> # dual table+card presentation
end
```

UI-SPEC copywriting contract applied:

| State | Testid | Heading | Body |
|-------|--------|---------|------|
| `:error` | `data-state-error` | "Record data unavailable" | "There was a problem loading records. Try refreshing the page." |
| `:permission_denied` | `data-state-permission-denied` | "Access restricted" | "You don't have permission to view records for this tenant." |
| `:stale` | `data-state-stale` | "Data may be out of date" | "The records shown here may not reflect recent activity." |
| `:empty` (no_tenant) | `data-state-empty` | "Select a tenant" | "Choose a tenant to inspect its deliveries and inbound routing..." |
| `:empty` (truly_empty) | `data-state-empty` | "No records" | "No records have been recorded yet." |
| `:empty` (filtered) | `data-state-empty` | "No records" | "No records match the current filters." |

Hidden `<div>` stubs for backward compatibility with legacy `inbound-empty-filtered`/`inbound-empty-truly`/`inbound-empty-no-tenant` testids alongside `data-state-empty`.

No `assign_async`, no polling, no streams — synchronous render-time state only (D-06 invariant held).

### Task 3 — Inbound KPI stat_card Certification (DATA-02)

Certification-only task. `inbound/overview.ex` already routes all four KPI tiles through `Components.stat_card/1`:

```
grep -c 'Components.stat_card' mailglass_admin/lib/mailglass_admin/inbound/overview.ex
→ 4
```

The four call sites:
1. `inbound-overview-total` — `InboundMessages` total count
2. `inbound-overview-no-match` — `No match` count with `attention_severity`
3. `inbound-overview-accepted` — `Accepted` count with `accepted_severity`
4. `inbound-overview-no-match-rate` — `No-match rate` percentage with `rate_severity`

Tests added confirm all four `inbound-overview-*` testids render with meaningful non-dash values.

## Verification

```
cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors
```

Result: **63 tests, 0 failures, 0 warnings**

Acceptance criteria:
- `grep -c '"inbound-records-table"'` in `records_list.ex` → 1 (present)
- `grep -c '"inbound-records-cards"'` in `records_list.ex` → 1 (present)
- `inbound-records-list` still present in records_list.ex → 1 occurrence (ul)
- `inbound-record-row` still present → 2 occurrences (table tr + card button)
- `grep -v '^#' records_list.ex | grep -c 'raw('` → 0
- `grep -c 'defp badge_class' records_list.ex` → 0
- `grep -E 'assign_async|inbound-loading|Loading InboundMessages' inbound_live.ex` → 0 (clean)
- `grep -c 'Components.stat_card' inbound/overview.ex` → 4
- `<table` with `<th scope="col">` present → confirmed
- Outcome column first in table header → confirmed
- Permission-denied copy/testid distinct from no-data → confirmed

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added Recipient column to table — plan behavior test 5 requires mask_recipient in BOTH presentations**
- **Found during:** GREEN implementation
- **Issue:** Plan task 1 column order says `Outcome → Mailbox → Tenant → Provider → Received` (5 columns) but behavior test 5 says "envelope recipient renders via `mask_recipient/1` in both presentations." Without a Recipient column in the table, the table would not satisfy the recipient masking requirement.
- **Fix:** Added a Recipient (masked) column as column 2 after Outcome in the desktop table. Final column order: Outcome→Recipient→Mailbox→Tenant→Provider→Received. The card already had recipient. The acceptance criteria says "recipients use `mask_recipient/1`" which now holds in both presentations.
- **Files modified:** `records_list.ex`
- **Commit:** ef049c48

**2. [Rule 1 - Bug] UI-SPEC copy adopted; existing pre-Phase-113 empty-state copy updated**
- **Found during:** GREEN implementation
- **Issue:** Existing tests expected old copy ("No InboundMessages yet" / "InboundMessages appear here..." / "No InboundMessages match these filters") which contradicts the UI-SPEC locked copywriting contract for Phase 113
- **Fix:** Updated `records_list.ex` to use UI-SPEC copy; updated corresponding test assertions in `inbound_live_test.exs` to match
- **Files modified:** `records_list.ex`, `inbound_live_test.exs`
- **Commit:** ef049c48

**3. [Rule 2 - Missing functionality] Legacy testid preservation via wrapper div**
- **Found during:** GREEN implementation — mirrors Plan 02 decision
- **Issue:** `element("[data-testid='inbound-records-list']")` in existing tests would fail if we put the testid only on the `md:hidden` cards wrapper
- **Fix:** Added `<div data-testid="inbound-records-cards">` wrapper around the `<ul>` (so both `inbound-records-cards` and the legacy `inbound-records-list` on the `<ul>` are present in rendered HTML); Plan 04 migrates explicitly
- **Files modified:** `records_list.ex`
- **Commit:** ef049c48

**4. [Rule 1 - Bug] data_state :empty path handles nil data_state with empty records**
- **Found during:** GREEN implementation — mirrors Plan 02 decision
- **Issue:** The plan specified `data_state` attr to drive empty/error/permission/stale; but when no signal is passed and records is `[]`, we need to fall through to the `:empty` branch (legacy behavior preserved)
- **Fix:** `cond` branch `@data_state == :empty or (@data_state == nil and @records == [])` covers both explicit `:empty` signal and the implicit nil-signal empty list case
- **Files modified:** `records_list.ex`
- **Commit:** ef049c48

## Threat Mitigations Applied

| Threat ID | Status |
|-----------|--------|
| T-113-08 Information Disclosure — recipient cells | Mitigated: `Components.mask_recipient/1` called in BOTH table Recipient column and card; test asserts no raw recipient string; 0 second mask helpers |
| T-113-09 Information Disclosure — cross-tenant inbound data | Mitigated: renders only the already-scoped `@records` assign; no Repo reads introduced |
| T-113-10 Information Disclosure — permission-denied as no-data | Mitigated: `:permission_denied` is a distinct `data_state/1` kind with distinct testid `data-state-permission-denied`, never collapsed into `data-state-empty` |
| T-113-11 Tampering (XSS) — long-value title/cell interpolation | Mitigated: HEEx escaping preserved throughout; `grep -c 'raw(' records_list.ex` = 0 |
| T-113-12 Denial of Service — stale-data implementation | Mitigated: render-time only; no `assign_async`/polling/streams; synchronous invariant intact |
| T-113-SC Tampering — npm/pip/cargo installs | N/A: no package installs in this plan |

## Known Stubs

None — the `records_list/1` consumer must pass a meaningful `data_state` signal from `inbound_live.ex` (currently defaults to `nil`, which falls back to legacy behavior: render records or empty-state branches). The `data_state` attr is wired and tested for all four kinds via `render_component` tests. Connecting the signal from the LiveView (e.g., from a future error-assign) is a future plan concern; Plan 03 delivers the render-time contract identical to Plan 02.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- [x] `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` — modified (dual table+card, four data-state branches, new data_state attr)
- [x] `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` — modified (RED tests + GREEN implementation tests + updated existing copy assertions)
- [x] Commit 98da28bc exists (RED: failing tests)
- [x] Commit ef049c48 exists (GREEN: implementation)
- [x] 63 tests, 0 failures confirmed
- [x] `inbound-records-table` literal present in `records_list.ex` — confirmed (1 occurrence)
- [x] `inbound-records-cards` literal present in `records_list.ex` — confirmed (1 occurrence)
- [x] `inbound-records-list` literal still present — confirmed (1 occurrence)
- [x] `inbound-record-row` literal still present — confirmed (2 occurrences)
- [x] `raw(` count = 0 — confirmed
- [x] `defp badge_class` count = 0 — confirmed
- [x] `assign_async` count = 0 in `inbound_live.ex` — confirmed
- [x] `Components.stat_card` count ≥ 4 in `overview.ex` — confirmed (4)
