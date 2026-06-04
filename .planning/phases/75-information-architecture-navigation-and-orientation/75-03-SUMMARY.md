---
phase: 75-information-architecture-navigation-and-orientation
plan: "03"
subsystem: mailglass_admin/operator
tags:
  - operator-overview
  - handle-params-branch
  - tdd
  - same-commit-mandate
  - e2e
  - wave-3
dependency_graph:
  requires:
    - 75-01 (count_active_suppressions/1 in core suppressions.ex)
    - 75-02 (Shell.orientation_strip/1 extracted and wired)
  provides:
    - Operator Overview branch in handle_params/3 (params-based, no router change)
    - assign_overview_state/2 with health counts + suppression indirection
    - suppression_count_module/0 runtime indirection seam
    - Overview render: h1, orientation strip, health-count cards, navigation cards
    - Updated e2e openOperator helper (asserts "Operator overview" on landing)
    - 390px orientation strip acceptance assertion (GAP-07)
    - GAP-22 disposition recorded in docs/design-system.md (IA-04)
  affects:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/e2e/operator.spec.js
    - reference/demo_app/assets/e2e/demo.spec.js
    - mailglass_admin/docs/design-system.md
tech_stack:
  added: []
  patterns:
    - params-based view branching in handle_params/3 (no live_action change)
    - runtime-module-indirection seam + try/rescue degradation (suppression count)
    - TDD RED/GREEN cycle — 5 Overview branch stubs un-skipped and implemented
    - Same-commit mandate (IA-03): LiveView + both e2e specs in single commit
    - Token-clean Overview render (text-display/heading/body/label, gap-sm/md/lg)
key_files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/e2e/operator.spec.js
    - reference/demo_app/assets/e2e/demo.spec.js
    - mailglass_admin/docs/design-system.md
decisions:
  - "View Deliveries CTA uses Map.put(@filter_params, 'view', 'deliveries') into
    build_path/4 rather than string concatenation — ensures URI.encode_query
    alphabetical ordering matches assert_patch expectations in tests"
  - "apply_filters handler preserves view=deliveries via build_path_with_view/3
    so filter submissions from the Deliveries surface do not bounce to Overview"
  - "assign_overview_state/2 wraps summarize_tenant in try/rescue (tenant-guard
    first) because an empty tenant_id raises ArgumentError in fetch_tenant_id!;
    suppression count wrapped separately with the same pattern"
  - "Existing 'operator surface' tests updated to use view=deliveries where they
    test the Deliveries surface — correct behavior: bare /ops/mail/ is now Overview"
  - "GAP-22 deferred to Phase 79 (VERIF-04) at severity 3 per D-17 rationale"
metrics:
  duration_minutes: 25
  completed_date: "2026-06-04"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 5
  files_created: 0
---

# Phase 75 Plan 03: Operator Overview Branch, e2e Updates, GAP-22 Disposition Summary

**One-liner:** Params-based Operator Overview landing at bare `/ops/mail/` with 4 health-count cards, try/rescue suppression indirection, same-commit e2e heading updates, 390px GAP-07 assertion, and GAP-22 deferral recorded.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 (RED) | Add failing tests for Operator Overview branch (TDD RED) | 324c197b | operator_live_test.exs |
| 1+2 (GREEN + IA-03 same-commit) | Implement Overview branch + e2e updates + GAP-22 | f6df4de3 | operator_live.ex, operator_live_test.exs, operator.spec.js, demo.spec.js, design-system.md |

## What Was Built

**Task 1 — Overview branch in `handle_params/3` (TDD RED/GREEN):**

RED phase:
- Un-skipped 5 `@tag :skip` stubs in `operator_live_test.exs` "Operator Overview branch" describe block
- Implemented assertions: bare `/ops/mail/` Overview heading, no-tenant nudge copy, with-tenant health cards, suppression count degradation, `?view=deliveries` routing
- Confirmed 5 failures (RED) — Overview branch did not exist yet

GREEN phase (combined with Task 2 in IA-03 same-commit):

**`handle_params/3` extension:**
- Extracts `view = params["view"]` and `delivery_id = blank_to_nil(params["delivery_id"])`
- Branch condition: `if view == "deliveries" or not is_nil(delivery_id)` → `assign_delivery_state/3`; otherwise → `assign_overview_state/2`
- `live_action` stays `:index` — no router change

**`assign_overview_state/2`:**
- Guards `tenant_id` with `blank_to_nil/1` before calling `summarize_tenant` (avoids `ArgumentError` on empty tenant_id)
- Wraps `summarize_tenant` in `try/rescue` — degrades to `nil` on error
- Wraps `count_active_suppressions` call in `try/rescue` — degrades to `nil` (renders "—")
- Assigns `nil`/empty for all delivery-specific assigns so Overview render never crashes
- Computes `inbound_path` via `surface_paths/3` for the "View Inbound" CTA

**`suppression_count_module/0`:**
- Added adjacent to `support_summary_module/0` (line 670 area)
- Body: `:"Elixir.Mailglass.Operator.Suppressions"` — runtime indirection seam

**`assign_delivery_state/3` updated:**
- Added `assign(:view, :deliveries)` so the Deliveries render branch can check `@view == :overview`

**Overview render in `render/1`:**
- `<%= if @view == :overview do %>` branch renders `data-testid="operator-overview"`
- h1 "Operator overview" (`text-heading font-bold text-base-content`) — single h1 per page (GAP-21)
- `Shell.orientation_strip surface={:deliveries}` — always-visible in Overview
- No-tenant branch: shows nudge copy "Select a tenant to see health at a glance."
- With-tenant branch:
  - h2 "Health" + 4 compact health-count cards with `data-testid="operator-overview-health"`
  - Recent failures: `text-error` if > 0, else `text-success`
  - Orphan backlog: `text-warning` if > 0, else `text-success`
  - Active suppressions: `text-secondary`; "—" if `@suppression_count` is nil
  - All-clear: `text-success` if both zero, else `text-secondary`
  - h2 "Navigate" + 2 nav cards with `data-testid="operator-overview-nav"`
  - "View Deliveries" CTA: `btn btn-primary btn-sm min-h-11` with `build_path` + `view=deliveries`
  - "View Inbound" CTA: `btn btn-primary btn-sm min-h-11` via `@inbound_path`
- Shell: `active={:deliveries}` (not `:overview` — anti-pattern avoided per PATTERNS.md)
- Token-clean: `text-display/heading/body/label`, `gap-sm/md/lg`, `p-md`, `card bg-base-200 border border-base-300 rounded-box` throughout

**`apply_filters` handler updated:**
- When `@view == :deliveries`, uses `build_path_with_view/3` to preserve `view=deliveries` in patch URL
- `build_path_with_view/3` puts `"view" => "deliveries"` into filter_params before calling `build_path` — ensures alphabetical URI encoding matches test expectations

**Existing tests updated (Rule 1 — correct behavior):**
- `"renders the default detail prompt when no delivery is selected"` — add `"view" => "deliveries"` to navigate to Deliveries view
- `"renders the recent deliveries empty state"` — same fix
- `"applies filters through URL-backed state"` — start at Deliveries view; update `assert_patch` to include `view=deliveries`
- `"selects a delivery..."` — start at Deliveries view
- `"shows the replay CTA..."` — start at Deliveries view

**Task 2 — Same-commit e2e updates + GAP-22 (IA-03 mandate honored):**

**`operator.spec.js` changes:**
- `openOperator` helper: assert "Operator overview" heading on landing, then `page.goto` to `?view=deliveries`, then assert "Deliveries" heading and `operator-deliveries-list` testid — all 5 tests remain green
- 390px test extended: after detail section order assertions, navigate to `?view=deliveries` and assert `deliveries-orientation` testid visible (GAP-07 acceptance criterion, D-18)

**`demo.spec.js` changes:**
- "outbound operator opens with seeded delivery evidence" test: updated "Deliveries" heading assertion to "Operator overview", navigate to `?view=deliveries` before asserting list
- "Inbound records" assertion (line 41) left unchanged — InboundLive surface, unaffected

**`docs/design-system.md` change:**
- GAP-22 disposition added to "Known limitations" section near lines 141-150
- Records: deferred to Phase 79 (VERIF-04), severity 3, rationale (stable asset-serving seam, hard-refresh only), Phase 79 owns closure

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] assign_overview_state guard for blank tenant_id**
- **Found during:** GREEN phase — `summarize_tenant/1` raises `ArgumentError: tenant_id is required` when tenant_id is empty string
- **Fix:** Added `blank_to_nil/1` guard on tenant_id before calling `summarize_tenant`; wrapped entire call in `try/rescue` for defense in depth
- **Files modified:** `operator_live.ex`
- **Commit:** f6df4de3

**2. [Rule 1 - Bug] apply_filters handler lost view=deliveries on filter submission**
- **Found during:** GREEN phase — submitting the filter form from Deliveries view `push_patch`ed to a URL without `view=deliveries`, causing the view to switch to Overview
- **Fix:** Added `build_path_with_view/3` helper; `apply_filters` uses it when `@view == :deliveries`
- **Files modified:** `operator_live.ex`
- **Commit:** f6df4de3

**3. [Rule 1 - Correct Behavior] Updated existing "operator surface" tests to use view=deliveries**
- **Found during:** GREEN phase — existing tests that navigate to `operator_path(%{"tenant_id" => ...})` without `view=deliveries` now see the Overview, not the Deliveries list. This is correct new behavior.
- **Fix:** Added `"view" => "deliveries"` to tests that test the Deliveries surface; updated `assert_patch` to expect the `view=deliveries` param in the patched URL
- **Files modified:** `operator_live_test.exs`
- **Commit:** f6df4de3

## Verification Results

All plan verification checks pass:

- `mix test mailglass_admin/test/mailglass_admin/operator_live_test.exs --seed 0` → 21 tests, 0 failures
- `mix test test/mailglass/operator/suppressions_test.exs --seed 0` → 9 tests, 0 failures
- Full admin suite → 152 tests, 1 excluded failure (voice_test pre-existing phoenix.mjs dep-JS noise per project memory)
- `grep -c "assign_overview_state" operator_live.ex` → 2
- `grep -c "suppression_count_module" operator_live.ex` → 2
- `grep -c "Operator overview" operator_live.ex` → 1
- `grep -c "overview" router.ex` → 0
- `grep -c "Operator overview" operator.spec.js` → 1
- `grep -c "deliveries-orientation" operator.spec.js` → 2
- `grep -c "Operator overview" demo.spec.js` → 1
- `grep -c "GAP-22" docs/design-system.md` → 3
- `git diff --exit-code mailglass_admin/priv/static/` → exit 0 (bundle unchanged — no new classes added that weren't already in JIT scan)
- `grep -c "text-sm"` on non-comment lines of shell.ex → 0 (token-clean)
- No router.ex change confirmed

## Gap Register Coverage

| Gap | Description | Status |
|-----|-------------|--------|
| GAP-07 | Deliveries 390px orientation readability | CLOSED — 390px Playwright test asserts deliveries-orientation visible |
| GAP-21 | a11y h1/h2 hierarchy on Overview | CLOSED — single h1 "Operator overview", h2 for Health and Navigate sections |
| GAP-22 | Deep-link unstyled CSS disposition | RECORDED — deferred to Phase 79 (VERIF-04) at severity 3 (IA-04 satisfied) |

## Requirements Satisfied

- IA-02: Cold operator at /ops/mail/ reaches a task-oriented Overview with health counts and navigation CTAs
- IA-03: Same-commit e2e heading-assertion updates; all 5 operator.spec.js tests green; demo.spec.js tests green
- IA-04: GAP-22 deferral decision recorded in docs/design-system.md near lines 141-150

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes. `params["view"]` is pattern-matched (T-75-03-01 mitigated: any non-"deliveries" value falls through to the safe Overview default, no DB delivery query). Health count render uses only aggregate integers — no per-delivery PII fields (T-75-03-02 mitigated). `suppression_count_module/0` try/rescue degrades to nil without crashing LiveView (T-75-03-03 mitigated).

## TDD Gate Compliance

- RED gate: commit `324c197b` — `test(75-03): add failing tests for Operator Overview branch (TDD RED)` — 5 test failures confirmed
- GREEN gate: commit `f6df4de3` — `feat(75-03): implement Operator Overview branch...` — 21 tests, 0 failures

Both gates met. IA-03 same-commit mandate honored: operator_live.ex + operator.spec.js + demo.spec.js in single commit (f6df4de3).

## Self-Check: PASSED

- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — contains `assign_overview_state`, `suppression_count_module`, "Operator overview" render copy, view branch (verified)
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — Overview branch describe block with 5 passing tests (verified)
- `mailglass_admin/e2e/operator.spec.js` — "Operator overview" in openOperator helper, "deliveries-orientation" in 390px test (verified)
- `reference/demo_app/assets/e2e/demo.spec.js` — "Operator overview" in outbound operator test (verified)
- `mailglass_admin/docs/design-system.md` — "GAP-22" appears 3 times (verified)
- Commits `324c197b` (RED) and `f6df4de3` (GREEN+IA-03) exist in git log (verified)
- `mailglass_admin/priv/static/` — no diff (bundle gate passes, verified)
- No router.ex change (overview appears 0 times in router.ex, verified)
