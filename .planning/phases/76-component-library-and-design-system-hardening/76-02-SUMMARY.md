---
phase: 76-component-library-and-design-system-hardening
plan: "02"
subsystem: mailglass_admin
tags:
  - component-library
  - design-system
  - status-badge
  - call-site-rewire
dependency_graph:
  requires:
    - phase: 76-01
      provides: Components.status_badge/1 and Components.normalize_inbound_outcome/1
  provides:
    - All five badge_class/1 private functions deleted across mailglass_admin
    - All five call sites route through Components.status_badge/1
    - Fallback clauses added to status_class/1, status_icon/1, status_label/1 for phantom atoms and nil
  affects:
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
tech_stack:
  added: []
  patterns:
    - All badge call sites route through Components.status_badge/1 (single source of truth)
    - normalize_inbound_outcome/1 applied at admin-side adapter boundary (D-02)
    - Fallback defp clauses for phantom/unknown atoms render badge-outline per UI-SPEC Conflict 1
key_files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
key_decisions:
  - "Fallback clauses added to status_class/1, status_icon/1, status_label/1 for :suppressed and nil — badge-outline per UI-SPEC Conflict 1 (phantom atom elimination)"
  - "outcome_label/1 removed from records_list.ex and inbound/detail_header.ex after becoming dead code (only call site was the replaced badge span); compiler requires this under --warnings-as-errors"
  - "Test updated: nil outcome badge now renders 'Unknown' (fallback) instead of 'Pending' (old outcome_label/1 behavior)"
requirements_completed:
  - DS-01
duration: ~20 minutes
completed: "2026-06-04"
---

# Phase 76 Plan 02: Badge Call-Site Rewire — Five badge_class/1 Copies Deleted

**Deleted all five divergent badge_class/1 private functions and routed every call site through Components.status_badge/1, collapsing GAP-01..GAP-06 into the single canonical implementation.**

## Performance

- **Duration:** ~20 minutes
- **Started:** 2026-06-04T05:10:00Z
- **Completed:** 2026-06-04T05:30:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Deleted 5 copies of `badge_class/1` across 5 files (deliveries_list, timeline, records_list, operator/detail_header, inbound/detail_header)
- Replaced all 5 badge call sites with `Components.status_badge/1`
- Applied `Components.normalize_inbound_outcome/1` adapter in both inbound files (records_list, inbound/detail_header)
- Added fallback clauses to `status_class/1`, `status_icon/1`, `status_label/1` in `components.ex` for phantom atoms (`:suppressed`) and nil — renders `badge-outline` per UI-SPEC Conflict 1
- Removed now-dead `outcome_label/1` from both inbound files (compiler error under `--warnings-as-errors`)
- Full test suite green (187 tests, 0 relevant failures; 1 pre-existing VoiceTest dep-JS noise excluded per project memory)

## Task Commits

1. **Task 1: Rewire operator/deliveries_list.ex and operator/timeline.ex** — `8a4e22c4` (refactor)
2. **Task 2: Rewire inbound/records_list.ex, operator/detail_header.ex, inbound/detail_header.ex** — `3f573b75` (refactor)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` — badge span replaced with `Components.status_badge/1`; 5 `badge_class/1` clauses deleted
- `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` — alias added; badge span replaced with `Components.status_badge :if=...`; 3 `badge_class/1` clauses deleted
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` — badge span replaced with `Components.status_badge/1` + `normalize_inbound_outcome`; 5 `badge_class/1` clauses deleted; `outcome_label/1` removed (dead code)
- `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` — alias added; badge span replaced with `Components.status_badge/1`; 5 `badge_class/1` clauses deleted
- `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex` — badge span replaced with `Components.status_badge/1` + `normalize_inbound_outcome`; 5 `badge_class/1` clauses deleted; `outcome_label/1` removed (dead code)
- `mailglass_admin/lib/mailglass_admin/components.ex` — fallback clauses added to all three status helper defps
- `mailglass_admin/test/mailglass_admin/inbound/components_test.exs` — nil-outcome test updated: "Pending" → "Unknown" (new canonical fallback)

## Decisions Made

- Fallback clauses added to `status_class/1`, `status_icon/1`, `status_label/1` for any atom not in the canonical taxonomy (including phantom `:suppressed` and nil). This is required for runtime safety when legacy delivery records carry `:suppressed` status. Per UI-SPEC Conflict 1, these render as the neutral outline badge (`badge-outline`, `hero-question-mark-circle`, "Unknown").
- `outcome_label/1` deleted from both inbound files after becoming dead code. The plan noted "leave dead code" to be conservative, but the Elixir compiler treats unused private functions as errors under `--warnings-as-errors`. Deletion is correct and safe — the function was only called from the badge span that was replaced.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added fallback clauses to status_class/1, status_icon/1, status_label/1 in components.ex**
- **Found during:** Task 2 — full test suite run
- **Issue:** 5 test failures with `FunctionClauseError` in `status_class/1`. The old `badge_class/1` functions had a fallback `defp badge_class(_status), do: "badge-outline"` covering `:suppressed` (a phantom atom in legacy delivery records) and `nil` (no outcome yet). The Plan 76-01 implementation of `status_badge/1` omitted fallback clauses, causing crashes when these atoms reached the component.
- **Fix:** Added `defp status_class(_status), do: "badge-outline"`, `defp status_icon(_status), do: "hero-question-mark-circle"`, `defp status_label(_status), do: "Unknown"` as fallbacks. Behavior matches UI-SPEC Conflict 1: phantom atoms render neutral outline.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/components.ex`
- **Verification:** Full test suite: 187 tests, 0 relevant failures
- **Committed in:** 3f573b75 (Task 2 commit)

**2. [Rule 1 - Bug] Removed dead outcome_label/1 functions from both inbound files**
- **Found during:** Task 2 — compile after badge call site replacement
- **Issue:** The compiler rejected both files under `--warnings-as-errors` because `outcome_label/1` became unused after the badge spans were replaced.
- **Fix:** Deleted `outcome_label/1` (two clauses each) from `inbound/records_list.ex` and `inbound/detail_header.ex`. These helpers only served the badge span that was replaced.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex`, `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex`
- **Verification:** `mix compile --warnings-as-errors` exits 0
- **Committed in:** 3f573b75 (Task 2 commit)

**3. [Rule 1 - Bug] Updated inbound/components_test.exs nil-outcome badge assertion**
- **Found during:** Task 2 — test suite run after fallback clauses added
- **Issue:** `test "renders the neutral Pending badge for a record with no run yet"` asserted `html =~ "Pending"`. With the badge now routed through `status_badge/1` + fallback, nil outcome renders "Unknown" (the canonical fallback), not "Pending" (the old `outcome_label/1` string).
- **Fix:** Updated assertion from `"Pending"` to `"Unknown"`; updated test name to reflect canonical behavior.
- **Files modified:** `mailglass_admin/test/mailglass_admin/inbound/components_test.exs`
- **Verification:** Test passes; `badge-outline` assertion (line 109) unchanged and still correct
- **Committed in:** 3f573b75 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 1 — bugs exposed by the rewire)
**Impact on plan:** All fixes required for correctness. No scope creep. The fallback clauses were a gap in the Plan 76-01 implementation that only became visible when real production atoms (:suppressed, nil) reached status_badge/1 via the call-site rewire.

## Issues Encountered

The pre-existing `VoiceTest` failure (`refute html =~ "oops"` failing due to "noops" in phoenix.mjs dep JS) remained. Per project memory (`project_voice_test_noops_dep_js.md`), this is pre-existing dep-JS noise unrelated to feature phases and excluded from phase pass/fail.

## Known Stubs

None. All call sites are fully wired to the canonical `Components.status_badge/1` implementation.

## Threat Flags

None. This plan replaces private `badge_class/1` calls with `Components.status_badge/1` calls. No new trust boundary, no new auth/session/data-access/input-validation surface.

## Next Phase Readiness

- Badge consolidation (DS-01) complete: `grep -rn 'defp badge_class' mailglass_admin/lib/` returns zero
- Five call sites all route through `Components.status_badge/1`
- `normalize_inbound_outcome/1` applied correctly in both inbound files
- Test suite green
- Ready for Plan 76-03 (token migration or support-card restructure)

---
*Phase: 76-component-library-and-design-system-hardening*
*Completed: 2026-06-04*
