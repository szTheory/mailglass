---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "07"
subsystem: ui
tags: [phoenix-liveview, filters, inbound, search, debounce, history, draft-retention, playwright]

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "FilterCommit history policy and commit_filters/3 shape (plan 01); FilterSearchSync hook, search attributes and data-committed contract (plan 06)"
provides:
  - Inbound filters that commit select changes and Enter straight to a sorted canonical URL, with no Apply control
  - Debounced Inbound Search sharing the Deliveries hook, one history entry per edit
  - Inbound raw-draft retention with a Custom period window option
  - Mobile Filters toggle on Inbound that reports committed filters only
affects: [176-09, 176-10]

actuals:
  tokens: 12500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Inbound mirrors Operator: payload -> FilterCommit.commit_params -> normalize -> sorted canonical path -> push_patch(replace: history_kind)"
    - "pending_commit_kind is assigned only in push_commit/3; handle_params settles it, so a no-op or invalid commit never mislabels a later Back"
    - "Draft retention keeps the raw value only for a field that carries an error, so a blank or padded value normalizes quietly"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/e2e/phase176-filters.spec.js
    - mailglass_admin/e2e/phase175-inbound.spec.js
    - mailglass_admin/e2e/inbound-layout.spec.js
    - reference/persona_spec/quick_view_scenarios.json

key-decisions:
  - "Inbound same_location? canonicalizes both queries with FilterCommit.canonical_current_query/1, so a bare entry URL and an unchanged commit target are the same location; committed Inbound URLs keep window_hours=168"
  - "Inbound hooks.js is unchanged, so the demo Storybook md5 pin did not move"
  - "filter_draft_params/3 takes the error map and retains a raw outcome or window only when it is in error (Operator's version retains whenever the key is present)"
  - "The shared build_path now ends in FilterCommit.encode_query/1, so every Inbound link (selection, detail, pagination) is key-sorted"

patterns-established:
  - "Inbound test helpers inbound_change/2, assert_patch_kind/2, refute_patch/1, selected_filter_value/2 mirror the Operator ones"

requirements-completed: []
# FILTER-01..04 are also declared by plans 176-09 and 176-10, so they are not marked here.

coverage:
  - id: D1
    description: "Inbound select change commits one sorted canonical push patch; no Apply, submit, loading or tenant control; foreign tenant, inbound_id, full and page never reach the URL"
    requirement: "FILTER-01"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound select change commits one sorted canonical push patch"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound the filter form has no Apply, submit, loading or tenant control"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound a foreign tenant_id never changes the Account on change, submit or recover"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 Inbound select applies without Apply"
        status: pass
    human_judgment: false
  - id: D2
    description: "Inbound Search is debounced 300 ms with FilterSearchSync, data-committed, autocomplete=off, enterkeyhint=search; selects have no debounce; one text input; first commit pushes, next replaces, settled Enter is a no-op; one history entry per edit; Back restores focused text"
    requirement: "FILTER-02"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound Search is debounced and carries the search-field attributes only on Search"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound search history: first commit pushes, next replaces, settled Enter is a no-op"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 Inbound search: one history entry per edit and Enter commits"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 Inbound search restores on Back with focus"
        status: pass
    human_judgment: false
  - id: D3
    description: "Inbound history policy: canonicalize and recover replace, Clear with nothing applied and bare-entry-URL unchanged commits produce no patch, page resets on commit, pagination links keep committed filters, Back restores earlier filters, no-op does not leak a pending kind"
    requirement: "FILTER-03"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound an unchanged commit from a bare entry URL is a no-op, a changing one pushes"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound pagination links preserve the committed filters"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound a select commit from page 2 patches to a path without page and renders page 1"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound mobile Filters toggle counts committed filters only"
        status: pass
    human_judgment: false
  - id: D4
    description: "A rejected outcome or window stays in the draft from the URL and from form events; the window select shows Custom period (N hours) selected next to its error; a blank window normalizes quietly"
    requirement: "FILTER-04"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound invalid URL values stay in the draft next to their errors"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound an invalid form window stays in the draft without a patch"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound a blank window normalizes quietly without a Custom period option"
        status: pass
    human_judgment: false

duration: 40min
completed: 2026-10-28
plan_head_before: b4d8d2a991a80c7bc31c6da446bffe5ca81233d6
plan_head_after: 4a99f7c24173db90024a665900816e4de05af7f1
commits: 3
status: complete
---

# Phase 176 Plan 07: Inbound Direct Filters Summary

**Inbound now filters like Deliveries: selects and Enter commit a sorted, Account-safe URL through `FilterCommit`, Search debounces into one history entry per edit with focused Back/Forward restore, and a rejected outcome or window stays in the draft instead of being silently replaced.**

## Performance

- **Duration:** about 40 min
- **Completed:** 2026-10-28
- **Tasks:** 3
- **Files modified:** 7 (0 created, 7 modified), plus `deferred-items.md`

## Accomplishments

- The Apply button, its disable-with state and the hidden tenant input are gone from `#inbound-filters`. `validate_filters`, `apply_filters` and the new `recover_filters` all call a private `commit_filters/3` that forces the server-held Account, trims search, drops page and selection keys, and treats a same-location commit as a no-op (D-01, D-06..D-09, D-11).
- The change handler no longer reloads provider options; `handle_params` alone does (D-04). `:canonicalize_tenant` patches with `replace: true`; `phx-auto-recover="recover_filters"` restores a valid differing draft with replace and leaves an invalid one as a draft.
- `Inbound.FiltersForm` passes the five search attributes to the existing Search `filter_field` (no raw markup) and takes `committed_search`; the shared `FilterSearchSync` hook from plan 06 needed no change.
- The mobile Filters toggle reads "Filters" or "Filters (N applied)" from committed params, counting search, outcome, provider and a non-default window.
- `filter_draft_params/3` plus a ported `window_options/2` keep a rejected outcome or window in the draft, so the select shows "Custom period (bogus hours)" next to its error (D-12, orchestrator decision 6).

## Task Commits

1. **Task 1: Inbound select change commits end-to-end through FilterCommit (tracer)** - `07813da2` (feat)
2. **Task 2: Debounced Search, Enter, focus hook and toggle state** - `42aee54d` (feat)
3. **Task 3: Raw-draft retention** - `4a99f7c2` (feat)

Tracer gate: Task 1's `<verify>` (full `inbound_live_test.exs` plus the three named browser cases) was green before Task 2 started.

## Coupled-spec edits

| File | Edit |
| --- | --- |
| `inbound_live_test.exs` IA-hooks test | `phx-disable-with` assertion became a refute scoped to `#inbound-filters` (the string still appears elsewhere on the page) |
| `inbound_live_test.exs` five `form("#inbound-filters", filters: ...)` calls | dropped the removed `tenant_id` field |
| `inbound_live_test.exs` invalid-submit test | sends the invalid payload through `validate_filters` with `_target`; the no-patch assertion is kept |
| `inbound_live_test.exs` URL-invalid test | `value="168" selected` became "Custom period (bogus hours)" present and selected; the outcome assertion is unchanged |
| `phase175-inbound.spec.js` | dropped the Apply click (the following `toHaveURL` assertions prove auto-apply) |
| `inbound-layout.spec.js` | dropped three Apply clicks; waits for `outcome=accept`, `window_hours=24`, `search=no-matching-message-7f2a` in the URL |
| `reference/persona_spec/quick_view_scenarios.json` | `fb-auto-apply-filters` disposition no longer says both lists render Apply |

## Verification

All Elixir commands from `/Users/jon/projects/mailglass/mailglass_admin` with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`.

| Check | Result |
| --- | --- |
| RED before Task 1 (`--only phase176`) | 13 failures against the old handlers |
| Task 1 `inbound_live_test.exs --seed 0` | 106 tests, 0 failures |
| Task 2 `--only phase176 --trace` | 112 tests, 0 failures, 84 excluded; named Inbound search/DOM/toggle tests present in the trace |
| Task 3 `inbound_live_test.exs components_test.exs --seed 0` | 235 tests, 0 failures |
| Full admin suite `mix test --seed 0` | 810 tests, 0 failures, 1 excluded |
| `bash scripts/check-conformance.sh` | OK: design-system conformance clean |
| `mix format --check-formatted` on the three touched Elixir files; `mix credo --strict` on `inbound_live.ex` and `inbound/filters_form.ex` | clean; no issues |
| Playwright Task 1 (`Phase 176 Inbound select`, `Phase 175 Inbound quick`, `outcome filters hide`) | 3 passed |
| Playwright Task 2 (`Phase 176 Inbound search`) | 2 passed |
| `grep -c phx-disable-with` / `phx-auto-recover="recover_filters"` / `replace: true` in `inbound_live.ex` | 0 / 1 / 1 (baselines 1 / 0 / 0) |
| `grep -c 'phx-debounce="300"'` / `grep -c "window_options(@window_options"` in `inbound/filters_form.ex` | 1 / 1 (baselines 0 / 0) |

`priv/static/app.css` was verified clean before every browser run and restored afterwards; it was never staged. `hooks.js` is unchanged, so the demo Storybook hash pin is untouched.

## Decisions Made

See `key-decisions`. Orchestrator decisions 1 (keep `window_hours=168` in committed URLs) and 6 (port draft retention to `handle_params`) are implemented as written.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Blank `window_hours` would have become a "Custom period" option**
- **Found during:** Task 3
- **Issue:** Porting Operator's `filter_draft_params` verbatim retains the raw value whenever the key is present. `?window_hours=` normalizes to 168 with no error, so the draft would have carried `""` and the select would have gained a "Custom period ( hours)" option with no error to explain it.
- **Fix:** `filter_draft_params/3` takes the error map and retains the raw value only for a field that is in error. Added a test for the blank case.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/inbound_live.ex`, `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`
- **Committed in:** `4a99f7c2`

**2. [Rule 3 - Blocking] Coupled tests the plan did not name**
- **Found during:** Task 1
- **Issue:** Five existing `form("#inbound-filters", ...)` calls submitted the removed hidden `tenant_id` field, and the IA-hooks `refute` of `phx-disable-with` matched unrelated markup elsewhere on the page.
- **Fix:** Dropped the `tenant_id` key from those form maps and scoped the refute to the form element.
- **Committed in:** `07813da2`

**3. [Rule 3 - Blocking] `render_patch` after a commit resets the search edit**
- **Found during:** Task 2
- **Issue:** My first history test followed each commit with `render_patch`, which is a non-commit patch and correctly ends the in-flight edit, so the second commit pushed instead of replaced. LiveViewTest already applies `push_patch` to the server.
- **Fix:** Removed the extra `render_patch` calls from the test; production code unchanged.
- **Committed in:** `42aee54d`

**Total deviations:** 3 auto-fixed (1 bug, 2 blocking). **Impact:** none change scope; deviation 1 differs deliberately from Operator's retention rule, and Operator's own blank-window behavior was left alone as out of scope.

## Issues Encountered

- A wider browser run (`flows.spec.js`, `operator.spec.js`) reported red cases on the Deliveries and Inbound evidence surfaces. With this plan's two Inbound source files swapped back to their pre-plan versions, `flows.spec.js:747` and `operator.spec.js:80` still failed, so they are not caused by this plan. They and the other reds from that run are logged in `deferred-items.md`; the first two files restored byte-identically (`cmp`) and `git status --porcelain mailglass_admin/lib` was clean afterwards.
- The known `phase169-journey.spec.js:459` replay-copy red was not part of this plan's runs.
- IME composition (assumption A6) stays unverified, as in plan 06.

## Known Stubs

None.

## Threat Flags

None. T-176-14 is mitigated (tenant forced from `selected_tenant_id`, hidden input removed, a foreign tenant sent through change, submit and recover in one test), T-176-15 (`inbound_id`, `full` and `page` asserted absent from the patched URL), T-176-16 (raw values only reach HEEx-escaped option text; commits still use allow-list normalization). No packages or lockfiles changed (T-176-SC).

## User Setup Required

None.

## Prohibition status

"MUST NOT render a visible Apply control, a type=submit control, or a disable-with attribute in the Inbound filter form" is proved by "Phase 176 Inbound the filter form has no Apply, submit, loading or tenant control", the exactly-one-text-field test and the Playwright `toHaveCount(0)` checks. The mutation-proven contract test belongs to plan 176-10.

## Next Phase Readiness

- Plan 176-09 (FILTER-04 notes and read states) can build on `filter_draft_params/3`; Inbound has no `filter_error_source` assign yet.
- Plan 176-10 owns the mutation-proven prohibition contract and the bundle-clean assertion.

## Self-Check: PASSED

- Modified files present; commits `07813da2`, `42aee54d`, `4a99f7c2` are ancestors of HEAD; `git rev-list --count b4d8d2a9..HEAD` = 3 (matches `commits: 3`).
- No file deletions in any task commit; user WIP under `.planning/` and `prompt.txt` never staged; `priv/static/app.css`, `hooks.js` and `mix.lock` unchanged.

---
*Phase: 176-direct-filters-and-useful-inbound-evidence*
*Completed: 2026-10-28*
