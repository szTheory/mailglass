---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "15"
subsystem: ui
tags: [filters, deliveries, inbound, liveview, d-12, d-13, wr-05, wr-06, tdd]
status: complete
gap_closure: true

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "Plan 11 live tracer and UI-SPEC rows; plan 13 filters_active?/1, blank-window normalization and filter_draft_params/2"
provides:
  - "filter_url_invalid assign on both LiveViews, written only in handle_params/3; the URL note follows the committed URL"
  - "URL note and draft note co-occur whenever both apply; neither replaces the other"
  - "enum_options/2 on the event and outcome selects: a rejected value stays selected as an enabled 'Not applied: <value>' option"
  - "UI-SPEC rows 111 and 112 clarified (co-occurring notes, Not applied option, window note copy reconciled)"
affects: [176-14, phase-176-verification]

plan_head_before: 12f358510cc0ac89562aa5eeed6c2a7696812f1b
plan_head_after: 5054cdc74ae11ce087cee16dc83befc51736d1fc
actuals:
  tokens: 8700
  tasks: 2
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Provenance labels follow the committed URL (a snapshot assigned only in handle_params), not the draft's error source"
    - "A select that holds a rejected value renders it as an enabled option, never a disabled one (disabled options drop out of submission)"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
    - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/e2e/phase176-filters.spec.js
    - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-UI-SPEC.md

key-decisions:
  - "Draft note unchanged (D-12 as written): commit_filters/3 still assigns :filter_error_source to :draft for every invalid change event, including a re-post of the URL's own invalid value. It co-occurs with the URL note; no bounded reading of D-12 is recorded because none is needed."
  - "URL note keyed on a separate filter_url_invalid snapshot (the URL normalization error map), not inferred from filter_errors, which mixes URL and draft origins after a change event."
  - "WR-05 fixed in the product, not deferred: deferring would have weakened D-12's locked 'select never contradicts its error'. Label shape 'Not applied: <value>' mirrors the window select's custom option."
  - "The Not applied option is enabled so the next change event re-posts the raw value instead of silently clearing the filter."

requirements-completed: ["FILTER-04"]

coverage:
  - id: D1
    description: "URL-invalid note stays on screen, naming only the URL's invalid fields, after a Search edit, another select change and a reconnect, beside the draft note, on both collections; a valid commit clears both"
    requirement: "FILTER-04"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 gap: a URL-invalid filter stays labelled as excluded after a later edit or a reconnect"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound gap: a URL-invalid filter stays labelled as excluded after a later edit or a reconnect"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 URL-invalid labelling (deliveries, inbound)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A rejected enum value (event, outcome) is a selected, enabled 'Not applied: <value>' option directly after the prompt; encoding is escaped with no injected element; blank selects the prompt with no Not applied option"
    requirement: "FILTER-04"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 gap: a rejected event stays selected as a Not applied option"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound gap: a rejected outcome stays selected as a Not applied option"
        status: pass
    human_judgment: false
  - id: D3
    description: "UI-SPEC rows 111 and 112 state the co-occurring note rules, the Not applied option and the shipped window note copy"
    requirement: "FILTER-04"
    verification:
      - kind: command
        ref: "grep -c 'Clarified by 176-15' 176-UI-SPEC.md == 2; grep -q 'Showing results for the default time window instead.'"
        status: pass
    human_judgment: false
---

# Phase 176 Plan 15: URL-invalid labelling and Not applied options Summary

On both Deliveries and Inbound, the excluded-filter note now follows the committed URL through later edits and reconnects (WR-06, D-13) and sits beside the unchanged D-12 draft note, while a rejected enum value stays selected in its select as an enabled "Not applied: <value>" option (WR-05, D-12).

## What changed

- `operator_live.ex`, `inbound_live.ex`: new `:filter_url_invalid` assign, `%{}` at mount, set from the URL normalization error map only in `handle_params/3`. The URL note's `:if` is now `map_size(@filter_url_invalid) > 0` and lists `url_invalid_notes(@filter_url_invalid)`. `commit_filters/3`, `clear_filters`, the refresh paths and the draft note are untouched. The comment above the notes states the co-occurrence rule.
- `operator/filters_form.ex`, `inbound/filters_form.ex`: `enum_options/2` prepends `{"Not applied: " <> value, value}` when the trimmed current value is non-blank and unlisted. Enabled on purpose (comment added).
- `176-UI-SPEC.md` rows 111 and 112 clarified (two "Clarified by 176-15" notes); row 112's visible-result cell reconciled to the shipped window copy. No code change for that reconciliation.
- Tests and one browser describe, listed under Coverage above.

## TDD evidence

RED/GREEN commits: `5b4faf52` test -> `13969c2d` fix (Task 1); `732b13f6` browser spec; `5a034b40` test -> `489e800a` fix (Task 2); `5054cdc7` docs.

Task 1 red lines (pre-fix source, `--seed 0`), asserting the planned behavior (URL note absent after the Search edit):
- `Phase 176 gap: a URL-invalid filter stays labelled as excluded after a later edit or a reconnect` (operator_live_test.exs:3953): `code: assert Floki.text(url_note.(view)) =~ "Showing results for the default time window instead."`, `left: ""`.
- `Phase 176 Inbound gap: a URL-invalid filter stays labelled as excluded after a later edit or a reconnect` (inbound_live_test.exs:3556): same assertion, `left: ""`.
Both fail after the first-render assertions pass, so the target is the post-edit absence. The reconnect and second-field cases sit behind that assertion in the same test; they ran green after the fix.

Task 2 red lines (6 failures, all on the planned assertion, option absent / `selected_filter_value` nil): the two new tests (`assert selected_filter_value(html, "#filters_event") == "bogus"`, `... "#filters_outcome") == "not-real"`) and the four flipped tests. After the fix the same run is 0 failures.

Absent-option assertions before the flip: `grep -n "option\[value=" ...` at plan start printed 5 lines (operator_live_test.exs:304; inbound_live_test.exs:775, :779, :807, :3043; lines had shifted by 3 in inbound after earlier gap plans). Four were absence assertions on a rejected enum value and were flipped (titles unchanged): `operator_live_test.exs` "invalid URL-backed filters render recovery copy without narrowing tenant reads"; `inbound_live_test.exs` "invalid URL-backed filters render recovery copy without widening tenant reads", "invalid submitted filters render recovery copy and do not push a patch", "Phase 176 Inbound invalid URL values stay in the draft next to their errors". The fifth (:779, window `bogus` option present) is unchanged. Post-flip the absence-regex count is 0.

## Verification

- `mix test` for operator_live, inbound_live, components, inbound/components and phase176_prohibition_contract (incl. P8): 489 tests, 0 failures (`--seed 0`).
- Full admin suite `mix test --seed 0`: 864 tests, 0 failures, 1 excluded. `mix compile --warnings-as-errors` clean.
- grep checks: `filter_url_invalid` count 4 and 4 (>= 3); `:if={@filter_error_source == :url}` count 0 and 0; `Not applied: ` count 1 and 1; absent-option regex count 0; `Clarified by 176-15` 2; window copy present in UI-SPEC.
- Browser lane (advisory, D-29), command wrapped with the app.css / artifact-dir clean-check and by-path restore: 8 passed (2 new URL-invalid, one per collection; 4 axe invalid-state across 2 themes and 2 collections; 2 reconnect-recovery). Tree clean afterward. One earlier attempt failed before any test ran (the browser server hit a DB sandbox checkout timeout while seeding); an immediate rerun passed with no code change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test assumption] Blank-select assertion adjusted**
- **Found during:** Task 2 RED run
- **Issue:** The behavior list says a blank enum draft "selects the prompt", but the prompt option carries no `selected` attribute (`selected_filter_value` returns nil, not `""`).
- **Fix:** Blank/baseline assertions use `in [nil, ""]` with a comment; the rejected-value assertions remain strict.
- **Files modified:** operator_live_test.exs, inbound_live_test.exs
- **Commit:** 5a034b40

**2. [Environment] npm drops quoting in `--grep`**
- The plan's browser verify passes a regex with spaces through `npm run`, which re-splits it. The same 8 cases were selected with a space-free regex (`.` for spaces). No plan content changed.

**Total deviations:** 1 test-assumption adjustment, 1 invocation workaround. **Impact:** none on shipped behavior.

## Known Stubs

None.

## Threat Flags

None. T-176-35 mitigated (encoding test: one extra option, exact decoded value, no child elements); T-176-36 mitigated (`filter_url_invalid` written only in `handle_params/3`).

## Self-Check: PASSED

- All eight modified files exist; six commits (`5b4faf52`, `13969c2d`, `732b13f6`, `5a034b40`, `489e800a`, `5054cdc7`) are ancestors of HEAD.
- No user WIP files staged in any commit.
