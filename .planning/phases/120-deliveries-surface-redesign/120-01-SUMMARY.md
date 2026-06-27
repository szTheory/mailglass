---
phase: 120-deliveries-surface-redesign
plan: 01
subsystem: mailglass_admin operator UI (Deliveries surface)
tags: [ui, ia, render-gating, liveview, exunit, empty-state]
status: complete
requires:
  - "Phase 119 empty-pane-only IA pattern (orientation_strip surface={:deliveries}, operator-empty-truly)"
provides:
  - "Three-state Deliveries IA (genuine no-data / no-match / populated) driven off existing truth"
  - "Single-calm-pane genuine-no-data render contract (operator-empty-truly + deliveries-orientation only)"
  - "Paired ExUnit lock for the no-data / populated-unselected / no-match render conditions"
affects:
  - "mailglass_admin/lib/mailglass_admin/operator_live.ex (Deliveries render branch)"
  - "mailglass_admin/test/mailglass_admin/operator_live_test.exs"
tech-stack:
  added: []
  patterns:
    - "Render-condition gating via cond over {@deliveries == [], filters_active?/1} — no new assign"
    - "Empty-pane-only orientation strip (inherited from Phase 119)"
key-files:
  created: []
  modified:
    - "mailglass_admin/lib/mailglass_admin/operator_live.ex"
    - "mailglass_admin/test/mailglass_admin/operator_live_test.exs"
decisions:
  - "Genuine-no-data predicate extended with @filter_errors == %{} so an in-progress invalid filter submission keeps the toolbar (recovery copy) — deviation from the literal {@deliveries, filters_active?} pair the plan specified."
metrics:
  duration: "~12m"
  completed: 2026-06-26
  tasks: 2
  files_changed: 2
  commits: 2
requirements: [DELIV-01]
---

# Phase 120 Plan 01: Deliveries Surface Redesign — Single Calm Pane Summary

Gated the Deliveries branch of `operator_live.ex` to a single calm pane (`operator-empty-truly` + orientation strip) in genuine no-data — withholding the filters toolbar, Open-delivery CTA, and the entire master-detail grid (and its nested "Select a delivery…" helper) — while keeping the toolbar + grid in no-match/populated and removing the always-on orientation strip from the populated-unselected detail column; the co-located ExUnit suite was updated in the same plan to assert the corrected three-state render conditions.

## What Was Built

### Task 1 — Render-condition gating (`operator_live.ex`) — `e59a6e5f`
Restructured the Deliveries `<% else %>` branch as a `cond` over the existing truth (no new assign/flag):
- **Genuine no-data** (`@deliveries == [] and not filters_active?(@filter_params) and @filter_errors == %{}`): renders ONLY a calm pane — `deliveries_list` with an empty set (the sole source of the `operator-empty-truly` testid) wrapped in an `operator-deliveries-empty-pane` card — immediately followed by `Shell.orientation_strip surface={:deliveries}`. The `operator-filters` section, the "Open delivery" CTA, the `operator-master-detail` grid (and therefore the nested `operator-empty-detail` "Select a delivery…" helper) and the ReplayModal are all withheld.
- **No-match / populated** (the `<% true -> %>` arm): renders the existing FILTERS section + master-detail grid + ReplayModal unchanged in structure.
- Deleted the `orientation_strip surface={:deliveries}` line from the `is_nil(@selected_delivery)` detail-column clause (it previously fired on every populated-but-unselected view); the "Select a delivery…" helper that follows it is retained there (D-06).

### Task 2 — Paired ExUnit update (`operator_live_test.exs`) — `695a0c38`
- **Populated-unselected** test: flipped the `deliveries-orientation` assertion to a `refute` (strip is empty-pane-only now); KEPT the "Select a delivery…" assertion as the positive D-06 proof the helper still renders.
- **Genuine-no-data** test: renamed to "renders a single calm pane … in genuine no-data (no rows, no active filters)"; removed the now-false "Select a delivery…" assertion; added `assert operator-empty-truly`, `assert deliveries-orientation`, `refute operator-filters`, `refute operator-master-detail`.
- **No-match** test (new): a sent delivery + `status=failed` URL filter → zero rows with active filters; asserts `operator-filters` present + `operator-empty-filtered` present + `deliveries-orientation` absent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Genuine-no-data predicate must also exclude active filter errors**
- **Found during:** Task 1 (surfaced by the pre-existing `operator_live_test.exs:156` "invalid submitted filters render recovery copy" test going RED).
- **Issue:** On an invalid `apply_filters` submission with an empty delivery set, the `apply_filters` handler does NOT update `@filter_params` (it leaves it at defaults, so `filters_active?/1` is false) and only updates `@filter_form` + `@filter_errors`. With the literal plan predicate `{@deliveries == [], filters_active?/1}`, that state fell into the genuine-no-data arm, which withholds the filters toolbar — swallowing the filter-error recovery copy ("Status was not applied. Choose a listed status." etc.) and breaking a tested contract.
- **Fix:** Extended the genuine-no-data predicate with `and @filter_errors == %{}`. An in-progress invalid filter submission is no longer treated as genuine no-data, so the toolbar (with recovery copy + Clear-filters) stays. This reuses the existing `@filter_errors` assign — still no new assign/flag introduced for the discriminator.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`
- **Commit:** `e59a6e5f`
- **Security note:** This does not widen scope — `@filter_errors` reflects only status/event/window normalization failures; `FiltersForm.fields` exposes no tenant control (T-120-01 mitigation intact: the no-data calm pane still exposes zero scope-widening vectors).

## Verification Results

| Check | Result |
|-------|--------|
| `mix test test/mailglass_admin/operator_live_test.exs` | **69 tests, 0 failures** |
| `git diff --exit-code priv/static/app.css` | clean (BUNDLE-CLEAN-OK) — no `mix assets.build` run, byte-identical to HEAD |
| `git diff --exit-code lib/mailglass_admin/operator/shell.ex` | clean (SHELL-FROZEN-OK) — orientation copy byte-frozen |
| No new assign for discriminator | confirmed — diff contains no `assign(:...)` additions; reuses `filters_active?/1`, `@deliveries`, `@filter_errors` |

Intermediate signal (Task 1 before Task 2): the suite showed exactly the two expected paired-update failures (`operator_live_test.exs:37` and `:51`) plus the one regression caught above — after the predicate fix only the two paired-update assertions remained RED, then went green once Task 2 corrected them.

## Constraints Honored

- No new Tailwind classes, tokens, or keyframes. The new `operator-deliveries-empty-pane` card reuses utility classes already present on the existing list-card aside (`card min-w-0 rounded-box border border-base-300 bg-base-200 p-0`).
- `priv/static/app.css` byte-identical to HEAD; `mix assets.build` never run.
- `shell.ex` orientation strip copy unmodified.
- Only the two named files (+ this SUMMARY) staged; `mix.lock` and unrelated `.planning` files left untouched.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes. The only render-condition change at the operator→OperatorLive boundary (withholding the toolbar in no-data) tightens, not widens, the scope surface (T-120-01 mitigation positively asserted by the new `refute operator-filters` no-data assertion).

## Self-Check: PASSED

- FOUND: mailglass_admin/lib/mailglass_admin/operator_live.ex (modified)
- FOUND: mailglass_admin/test/mailglass_admin/operator_live_test.exs (modified)
- FOUND commit: e59a6e5f
- FOUND commit: 695a0c38
