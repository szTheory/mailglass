---
phase: 121-inbound-surface-redesign
plan: 01
subsystem: ui
tags: [phoenix-liveview, heex, inbound, empty-state-ia, data_state, exunit, brand-voice]

# Dependency graph
requires:
  - phase: 120-deliveries-surface-redesign
    provides: the shipped no-data/no-match/populated cond split (operator_live.ex:489-522), empty-pane-only orientation strip, dormant data_state primitive, the paired-test trap pattern
provides:
  - Inbound surface gated into three streamlined IA states (genuine no-data single calm pane; no-match toolbar+grid; populated toolbar+grid) driven by the existing empty_state_for/2 truth
  - orientation_strip surface={:inbound} is now empty-pane-only (removed from the populated-but-unselected detail column)
  - records_list.ex data_state wired from the LiveView so the error/permission_denied/stale branches are reachable (no longer dead code), gated so a loaded records list is never hijacked into the error pane
  - D-07 noun-discipline copy fix ("No InboundMessages have been recorded yet.")
  - corrected paired ExUnit + voice_test assertions matching the empty-pane-only IA
affects: [122-preview-surface-redesign, 123-cross-surface-coherence-ratchet]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Empty-state IA: wrap the render else-branch in a top-level cond driven by the existing empty_state_for/2 discriminator (no new flag); genuine no-data withholds every control that cannot act on an empty set (filters toolbar, CTA, health strip, master-detail grid)"
    - "data_state must never override a loaded records list: gate the escalation on records == [] so the table always renders its rows and a bad selection is surfaced by the detail-error band instead"
    - "Same-phase paired-test rule (Pitfall-2 / D-15): relocating an always-visible block on a green-only-forward floor requires updating every spec that asserts it, in the same phase"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/mailglass_admin/voice_test.exs

key-decisions:
  - "Genuine-no-data classification uses the verbatim guard @records == [] and not filters_active?(@filter_params) and @filter_errors == %{} — the @filter_errors guard keeps an in-flight invalid filter from being misclassified as no-data (T-121-02 mitigation)"
  - "data_state escalates to :error only when there are no rows to show; when the list loaded rows it stays nil (regression fix — the initial wiring hijacked the records list into the error pane)"
  - "Gateway-unavailable with no loadable records is genuine no-data → calm pane, health strip withheld; the degraded-path test was updated to assert the calm pane + no-leak rather than a zero-summary overview"
  - "LD-12 orientation-tip voice assertion relocated off the no-match mount to render_component(&Shell.orientation_strip/1, surface: :inbound) since the strip is now empty-pane-only"

patterns-established:
  - "Pattern 1: empty-pane-only orientation strip — the strip renders only in the genuine-no-data branch, never below a populated/no-match table (mirrors Deliveries D-05)"
  - "Pattern 2: detail-error band requires a populated tenant — a bad selection on a genuinely-empty tenant shows the calm pane, not the error band (shipped behavior of the mirrored cond)"

requirements-completed: [INB-01]

coverage:
  - id: D1
    description: "Inbound else-branch gated into no-data/no-match/populated cond; orientation strip empty-pane-only; inbound-empty-detail helper retained on populated-unselected"
    requirement: "INB-01"
    verification:
      - kind: unit
        ref: "test/mailglass_admin/inbound_live_test.exs#genuine no-data renders a single calm pane: truly-empty copy + orientation, toolbar withheld"
        status: pass
      - kind: unit
        ref: "test/mailglass_admin/inbound_live_test.exs#renders the no-selection prompt and masks recipients by default (V5)"
        status: pass
      - kind: other
        ref: "cd mailglass_admin && grep -c 'orientation_strip surface={:inbound}' lib/mailglass_admin/inbound_live.ex == 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "data_state wired from inbound_live.ex into RecordsList (error/permission_denied/stale reachable) without hijacking a loaded records list"
    requirement: "INB-01"
    verification:
      - kind: unit
        ref: "test/mailglass_admin/inbound_live_test.exs#a selected record outside active filters surfaces the detail-error band"
        status: pass
      - kind: unit
        ref: "test/mailglass_admin/inbound_live_test.exs#an unselectable foreign-tenant record id surfaces the detail-error band, not a leak"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-07 noun-discipline copy fix: truly-empty body uses the InboundMessage noun"
    requirement: "INB-01"
    verification:
      - kind: unit
        ref: "test/mailglass_admin/inbound_live_test.exs#genuine no-data renders a single calm pane: truly-empty copy + orientation, toolbar withheld"
        status: pass
      - kind: other
        ref: "cd mailglass_admin && grep -c 'No InboundMessages have been recorded yet.' lib/mailglass_admin/inbound/records_list.ex == 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "Same-phase paired ExUnit + voice_test updates so the empty-pane-only assertions stay green-only-forward (D-15)"
    requirement: "INB-01"
    verification:
      - kind: unit
        ref: "cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/voice_test.exs --seed 0 (79 tests, 0 failures, 1 excluded)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Token-parity / asset landmine avoided — render-condition-only changes, committed app.css byte-unchanged (D-18)"
    verification:
      - kind: other
        ref: "git diff --stat -- mailglass_admin/priv/static/app.css (empty / no change)"
        status: pass
    human_judgment: false

# Metrics
duration: 24min
completed: 2026-06-28
status: complete
---

# Phase 121 Plan 01: Inbound surface redesign (empty-pane-only IA port) Summary

**Ported Phase 120's no-data/no-match/populated cond split onto the Inbound LiveView — the orientation strip is now empty-pane-only, the filters toolbar/health strip/master-detail grid are withheld in genuine no-data, the dormant data_state is wired (and gated so it never hijacks a loaded list), and the D-07 InboundMessage noun fix landed with the paired ExUnit + voice_test assertions corrected in the same phase.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-06-28T16:46:46Z
- **Completed:** 2026-06-28T17:10:00Z
- **Tasks:** 3 (plus 1 in-scope regression fix)
- **Files modified:** 4

## Accomplishments
- Wrapped the inbound render else-branch in a top-level `cond` driven by the existing `empty_state_for/2` truth (no new flag): genuine no-data renders a single calm pane (`inbound-deliveries-empty-pane` + orientation strip) and withholds the filters toolbar, Open-record CTA, `Inbound.Overview` health strip, and the entire master-detail grid (D-01/D-02/D-05).
- Made the orientation strip empty-pane-only — removed it from the populated-but-unselected `is_nil(@detail)` detail column while keeping the `inbound-empty-detail` "Select an InboundMessage…" column-fill helper (D-04).
- Wired the dormant `data_state` from the LiveView into `RecordsList` so the error/permission_denied/stale branches are reachable (D-09), then gated it so a loaded records list is never forced into the error pane.
- Applied the D-07 noun-discipline copy fix ("No InboundMessages have been recorded yet.").
- Corrected the paired ExUnit + voice_test assertions (D-15) so the green-only-forward floor holds: 79 tests pass with `--seed 0`.

## Task Commits

1. **Task 1: Wrap the inbound else-branch in the no-data/no-match/populated cond + relocate the orientation strip** - `df3f69fc` (feat)
2. **Task 2 (copy fix): D-07 InboundMessage noun in records_list.ex** - `e32e2ac3` (fix)
3. **Task 2/Rule-1 regression fix: data_state must not hijack a loaded records list** - `9e6c822c` (fix)
4. **Task 3: Same-phase paired ExUnit + voice_test updates** - `8fc142ab` (test)

_Note: Task 2's two halves (data_state wiring + D-07 copy) landed across Task 1's commit (the `data_state={@data_state}` call-site + assign plumbing) and the `e32e2ac3` copy commit; the gating correctness fix is `9e6c822c`._

## Files Created/Modified
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - else-branch wrapped in a top-level cond; genuine-no-data single-calm-pane; orientation strip removed from the is_nil(@detail) column; `@data_state` assign added (mount/assign_inbound_state/clear_surface_state) and threaded into the populated list-card; `data_state_for/2` gated on records.
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` - `empty_body(:truly_empty)` noun fix (D-07).
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - V5 orientation refuted on populated; genuine-no-data truly-empty + toolbar-withheld; detail-error tests seed a same-tenant record; responsive-IA + tenant-scoped-search seed a same-tenant record; gateway-unavailable now asserts the calm pane + no-leak; V10 empty+no-selection split into no-data and populated mounts.
- `mailglass_admin/test/mailglass_admin/voice_test.exs` - LD-12 orientation tip asserted via `render_component(&Shell.orientation_strip/1, surface: :inbound)`; LD-16/LD-03 kept on the no-match mount.

## Decisions Made
- **Genuine-no-data guard kept verbatim** including the `@filter_errors == %{}` clause so an in-flight invalid filter is not misclassified as no-data (which would wrongly withhold the recovery toolbar — T-121-02 mitigation).
- **data_state escalation gated on `records == []`.** The initial wiring routed any detail-selection `:not_found` into the list `data_state`, forcing the records card into the error pane and hiding legitimately-loaded rows. The list must always render its rows; the bad selection is surfaced by the detail-error band. data_state only escalates to `:error` when there is nothing to show (the genuinely-reachable dead-branch path).
- **Gateway-unavailable with no records is genuine no-data.** The degraded path returns an empty record set → calm pane, health strip withheld. The legacy test asserting a zero-summary overview was updated to assert the calm pane + the no-leak guarantee, matching the new IA rather than weakening it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] data_state wiring hijacked the loaded records list**
- **Found during:** Task 3 (running the paired tests against the Task-1 implementation)
- **Issue:** Task 1 wired `data_state` from `detail_error_for/2` unconditionally. A provider-filtered no-match selection (a `:not_found` detail) drove `data_state=:error`, which short-circuited `RecordsList`'s cond and rendered the error pane instead of the matching rows — the records list (e.g. the visible `ses_record`) stopped rendering. This regressed `inbound_live_test.exs` "a selected record outside active filters surfaces the detail-error band".
- **Fix:** Re-shaped `data_state_for/2` to take `records` and stay `nil` whenever rows are present; only escalate to `:error` when `records == []`. The detail-error band continues to surface the bad selection in the detail column.
- **Files modified:** mailglass_admin/lib/mailglass_admin/inbound_live.ex
- **Verification:** `mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/voice_test.exs --seed 0` → 79 tests, 0 failures.
- **Committed in:** `9e6c822c`

**2. [Rule 3 - Blocking / D-15 paired-test] Extra inbound tests went RED under the new IA**
- **Found during:** Task 3
- **Issue:** Beyond the V5/truly-empty/voice tests the plan named, five further tests asserted now-changed behavior (filters toolbar / master-detail grid / overview present on what are now genuine-no-data mounts). D-15 explicitly requires scanning and updating any inbound ExUnit with these assumptions in the same phase.
- **Fix:** Seeded same-tenant records where the test needs the populated layout (responsive-IA hooks, tenant-scoped search, both detail-error tests, the V10 detail-load-error test); updated the gateway-unavailable test to the calm-pane + no-leak shape; split the V10 empty+no-selection test into a no-data mount and a populated mount. No masking/no-leak/banned-word assertion weakened.
- **Files modified:** mailglass_admin/test/mailglass_admin/inbound_live_test.exs
- **Verification:** full pair green with `--seed 0`.
- **Committed in:** `8fc142ab`

---

**Total deviations:** 2 auto-fixed (1 Rule-1 bug, 1 Rule-3/D-15 paired-test scope). Plus one out-of-scope item logged (below).
**Impact on plan:** Both auto-fixes were necessary for correctness and for the green-only-forward floor. No scope creep — all changes are render-condition + the paired tests the plan mandates. No new components, tokens, or Tailwind classes; `app.css` byte-unchanged.

## Issues Encountered
- **Pre-existing out-of-scope warning (deferred):** `mix compile --warnings-as-errors` fails on a shipped Phase 120 warning — `attribute "selected_delivery" … must be a :map, got: nil` at `operator_live.ex:505`. `operator_live.ex` is unmodified by this plan. The analogous inbound site was fixed by omitting the defaulted `selected_record={nil}` attr. Logged to `.planning/phases/121-inbound-surface-redesign/deferred-items.md`. Gated this plan on the inbound-scoped compile being clean (no warnings from `inbound_live.ex` / `records_list.ex`).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Inbound surface now matches the streamlined three-state IA shipped for Deliveries; ready for plans 121-02/03/04 (reveal a11y, replay-modal APG gaps, judgment-gate/persona-shoot) in this phase, then Phase 122 (Preview) inherits the cleaned-up pattern.
- The Phase 120 `operator_live.ex:505` `selected_delivery={nil}` warning remains for a future `--warnings-as-errors` clean-up (deferred-items.md).

## Self-Check: PASSED

All modified files exist; all 4 task/fix commits (`df3f69fc`, `e32e2ac3`, `9e6c822c`, `8fc142ab`) are present in git history. Targeted verification green: `mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/voice_test.exs --seed 0` → 79 tests, 0 failures, 1 excluded. `app.css` byte-unchanged.

---
*Phase: 121-inbound-surface-redesign*
*Completed: 2026-06-28*
