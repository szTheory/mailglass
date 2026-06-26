---
phase: 119-app-shell-nav-overview-redesign
plan: "01"
subsystem: mailglass_admin
tags: [shell, nav, overview, livev, ux, triage]
status: complete

dependency_graph:
  requires: []
  provides:
    - shell.ex active enum [:overview, :deliveries, :inbound]
    - shell.ex overview_path attr (bare operator root)
    - shell.ex surface_paths/4 :overview key
    - shell.ex Overview nav_link (hero-chart-bar, always-visible)
    - shell.ex Overview nav_pill (always-visible)
    - operator_live.ex active={@view} (replaces literal :deliveries)
    - operator_live.ex overview_path threaded into shell render
    - operator_live.ex drill-through links for failures + suppressions
    - operator_live.ex null-safe orientation strip gate (all-clear only)
    - operator_live.ex triage subtitle cond
    - operator.spec.js Wave-0 drill-through + orientation assertions
  affects:
    - inbound_live.ex (overview_path added to shell render — Rule 2 auto-fix)

tech_stack:
  added: []
  patterns:
    - TDD RED/GREEN per task
    - In-file clone pattern for nav items (no invention)
    - Null-safe guard @support_summary && all_clear?(@support_summary) for orientation gate
    - build_path/4 with Map.put chaining for drill-through links (existing pattern)
    - Wrapper div with data-testid around byte-frozen orientation_strip (D-10)

key_files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/e2e/operator.spec.js

decisions:
  - Used hero-chart-bar (already embedded in heroicons-inline.js) for Overview nav — avoids rebuild + TokenParityTest landmine
  - hover:border-primary verified present in compiled CSS (as .hover\:border-primary:hover); no rebuild needed
  - Orientation strip testid placed on outer wrapper div in operator_live.ex (not shell.ex) per D-10 byte-freeze constraint
  - all-clear calm paragraph uses same null-safe predicate as orientation strip gate (DRY, null-safe)
  - attention-state test uses failed webhook_event insert (not delivery) — all_clear? checks failed_ingest (webhook_events), not deliveries

metrics:
  duration: "~9 minutes"
  completed: "2026-06-26"
  tasks_completed: 4
  files_modified: 6
---

# Phase 119 Plan 01: App-shell Nav + Overview Redesign (Core Changes) Summary

Surgical SHELL-01/02/03 code changes landing the keystone Overview/shell/nav redesign: Overview nav item, active-state fix, deleted Navigate block, drill-through health stat cards, empty-pane-only orientation strip, and triage microcopy.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 0 | Scaffold Wave-0 e2e assertions | 307111b8 | operator.spec.js |
| 1 (RED) | SHELL-01 failing tests | ba31e371 | shell_test.exs |
| 1 (GREEN) | SHELL-01 nav identity + active fix | 7461b24c | shell.ex, operator_live.ex |
| 2 (RED) | SHELL-02 failing tests | ec4b7646 | operator_live_test.exs |
| 2 (GREEN) | SHELL-02 Navigate block + drill-through + orientation | f3e4d357 | operator_live.ex, operator_live_test.exs |
| 3 (RED) | SHELL-03 failing tests | 058a9cdd | operator_live_test.exs |
| 3 (GREEN) | SHELL-03 triage subtitle + calm copy | 105a749d | operator_live.ex, inbound_live.ex |

## What Was Built

**SHELL-01 (Nav active-state fix + Overview nav identity):**
- `shell.ex` active attr enum extended to `[:overview, :deliveries, :inbound]`
- `shell.ex` `attr(:overview_path, :string, required: true)` added
- `shell.ex` `surface_paths/4` returns `:overview` key (bare operator root, no `?view=`)
- `shell.ex` Overview `nav_link` (icon: `hero-chart-bar`) inserted as first sidebar nav child — always-visible, no `:if` gate
- `shell.ex` Overview `nav_pill` inserted as first mobile nav child — always-visible, no `:if` gate
- `operator_live.ex` `active={@view}` replaces literal `active={:deliveries}` — fixes false-active bug for all surfaces
- `operator_live.ex` `overview_path={@overview_path}` threaded through shell render
- `operator_live.ex` `overview_path` assigned from `paths.overview` in both render-time assigns and `assign_overview_state`

**SHELL-02 (Delete Navigate block + drill-through health + orientation gate):**
- `operator-overview-nav` block (Navigate section with View Deliveries/View Inbound cards) deleted entirely
- "Recent failures" stat card wrapped in `<.link patch={build_path(...)}>` with `status=failed`, `data-testid="operator-overview-health-failures-link"`, `aria-label`, `mg-focus-ring`/`hover:border-primary`/`transition-colors`
- "Active suppressions" stat card wrapped same way with `status=suppressed`, `data-testid="operator-overview-health-suppressions-link"`
- "Orphan backlog" unwrapped (support_cards.ex `phx-click` drilldown preserved)
- "Overall status" unwrapped (summary readout, not actionable)
- Orientation strip gated on null-safe predicate: `@support_summary && all_clear?(@support_summary) && @suppression_count in [0, nil]`
- Wrapper `<div data-testid="operator-overview-orientation">` added in `operator_live.ex` (testid cannot go in byte-frozen `shell.ex`)

**SHELL-03 (Triage microcopy + motion confirmation):**
- Overview subtitle rewritten from signpost copy to state-driven `cond`: all-clear → "Your delivery system is healthy." / attention → "Your delivery system needs attention." (banned phrases "Oops" and "Navigate to" never appear)
- Deliveries surface subtitle unchanged: "Prove what happened to a message…"
- All-clear calm paragraph `<p class="text-body text-secondary">Your delivery system is healthy — nothing needs your attention right now.</p>` renders above orientation strip only in all-clear state
- No new `@keyframes` added to `assets/css/app.css` (verified via git show comparison)

**Wave-0 e2e scaffolds (Task 0):**
- `operator.spec.js` drill-through link assertions: `status=failed` and `status=suppressed` href substring matches
- `operator.spec.js` orientation-strip attention-state assertion: `toHaveCount(0)` when seed tenant has data
- Line-367 `operator-overview-nav` assertion preserved (119-02 deletes both block and assertion)

## Test Results

```
184 tests, 0 failures (mix test shell_test.exs components_test.exs operator_live_test.exs token_parity_test.exs --warnings-as-errors)
```

TDD gate sequence:
- Task 1: RED (3 failures) → GREEN (0 failures) ✓
- Task 2: RED (3 failures) → GREEN (0 failures) ✓
- Task 3: RED (2 failures) → GREEN (0 failures) ✓

TokenParityTest: green (bundle undisturbed; hover:border-primary was already compiled, no rebuild needed)
Motion lock: no new @keyframes (verified)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] inbound_live.ex missing overview_path**
- **Found during:** Task 3 verification (compiler warning: missing required attribute `overview_path` for `Shell.shell/1` in `inbound_live.ex:362`)
- **Issue:** Adding `attr(:overview_path, :string, required: true)` to shell.ex made the inbound_live.ex render call invalid — it didn't pass the new required attr
- **Fix:** Added `overview_path: paths.overview` to `inbound_live.ex` assign block and `overview_path={@overview_path}` to the shell render call
- **Files modified:** `mailglass_admin/lib/mailglass_admin/inbound_live.ex`
- **Commit:** 105a749d

**2. [Rule 1 - Test fix] nil support_summary test assumption wrong**
- **Found during:** Task 2 GREEN run
- **Issue:** Test expected `support_summary=nil` in test env (assumed module unavailable), but SupportSummary IS loaded in the admin test suite → returns all-zeros summary → all_clear?==true → orientation strip shows
- **Fix:** Redesigned tests to match actual behavior: all-clear state shows strip, attention state (failed webhook_event insert) suppresses strip
- **Files modified:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs`
- **Commit:** f3e4d357

## Known Stubs

None. All changes produce real wired behavior; no placeholder text or empty data sources.

## Threat Surface Scan

No new endpoints, auth paths, file access patterns, or schema changes introduced. The drill-through links use the existing `build_path/4` helper with closed-set `@status_values` — T-119-01 mitigation verified (tenant_id preserved via `@filter_params`). No new threat surface.

## Self-Check: PASSED

Files exist:
- FOUND: mailglass_admin/lib/mailglass_admin/operator/shell.ex
- FOUND: mailglass_admin/lib/mailglass_admin/operator_live.ex
- FOUND: mailglass_admin/lib/mailglass_admin/inbound_live.ex
- FOUND: mailglass_admin/e2e/operator.spec.js

Commits exist:
- 307111b8 — Wave-0 e2e scaffolds
- ba31e371 — SHELL-01 RED tests
- 7461b24c — SHELL-01 GREEN implementation
- ec4b7646 — SHELL-02 RED tests
- f3e4d357 — SHELL-02 GREEN implementation
- 058a9cdd — SHELL-03 RED tests
- 105a749d — SHELL-03 GREEN implementation + inbound_live.ex fix
