---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "06"
subsystem: ui
tags: [phoenix-liveview, filters, search, debounce, hooks, history, playwright]

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "commit_filters/3, FilterCommit.history_kind/2 and the Phase 176 admin spec (plan 01)"
provides:
  - Debounced (300 ms), URL-backed Deliveries Search that is one history entry per edit
  - FilterSearchSync hook that restores the committed search into a focused input on Back/Forward
  - FiltersForm committed_search attr and data-committed contract (reused by plan 176-07)
  - Browser spike on LiveView 1.2.13 (admin) and 1.1.33 (demo) with the shipped sync path recorded
affects: [176-07, 176-10]

actuals:
  tokens: 9800
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Search field attrs (phx-debounce, phx-hook, data-committed, autocomplete, enterkeyhint) are passed through filter_field's :global rest on the Search field only; selects carry none"
    - "FilterSearchSync: popstate arms a pending flag, updated() applies data-committed to the focused input only while armed, disarmed on updated/input/1500 ms"
    - "Hooks.js body changes require re-pinning the demo Storybook review-JS md5 in reference/demo_app/dev/mailglass_demo_web/storybook.ex"

key-files:
  created:
    - reference/demo_app/assets/e2e/phase176-filters.spec.js
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/priv/static/hooks.js
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/e2e/phase176-filters.spec.js
    - reference/demo_app/dev/mailglass_demo_web/storybook.ex

key-decisions:
  - "The updated() hook path ships (demo LV 1.1.33 spike: 2 passed); the push_event fallback was not needed and operator_live.ex has no handle_params change"
  - "Back/Forward spike uses a select between two search edits so the second edit is a fresh push; a replace-only sequence would otherwise Back past the search"
  - "The demo lane was run against a fresh throwaway database (PGDATABASE override) served on port 4017 via DEMO_BASE_URL, then dropped"

patterns-established:
  - "Mutation check for a hook spike: remove phx-hook, run the spike, expect red (value stayed abcd), restore by cp and prove with cmp"

requirements-completed: []
# FILTER-02 and FILTER-03 are also declared by plans 176-07 and 176-10, so requirements.ready-ids holds them back until the last declaring plan finishes.

coverage:
  - id: D1
    description: "Deliveries Search is debounced 300 ms with data-committed, autocomplete=off, enterkeyhint=search; selects have no debounce; the input is never disabled or readonly"
    requirement: "FILTER-02"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 Search is debounced and carries the search-field attributes only on Search"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 data-committed follows the committed search while a draft differs"
        status: pass
    human_judgment: false
  - id: D2
    description: "The filter form has exactly one implicit-submission text field and no submit control, so Enter commits through phx-submit"
    requirement: "FILTER-02"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 the filter form has exactly one implicit-submission text field"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 search: one history entry per search edit and Enter commits immediately"
        status: pass
    human_judgment: false
  - id: D3
    description: "One search edit is one history entry (delta 1), debounced commits keep focus, Enter commits under 250 ms"
    requirement: "FILTER-02"
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 search: one history entry per search edit and Enter commits immediately"
        status: pass
    human_judgment: false
  - id: D4
    description: "Back/Forward with focus in Search restores the committed text on LV 1.2.13 and 1.1.33; typing after a Back that changed nothing is kept"
    requirement: "FILTER-03"
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 spike: focused search restores on Back (LV 1.2.13)"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 spike: typing after an empty Back is kept (LV 1.2.13)"
        status: pass
      - kind: e2e
        ref: "reference/demo_app/assets/e2e/phase176-filters.spec.js#Phase 176 spike (LV 1.1.33), 2 cases"
        status: pass
    human_judgment: false

duration: 16min
completed: 2026-10-28
plan_head_before: 3055905c01ee17299d8b55d48d337ce7d2647bbc
plan_head_after: 1be3fc99da69c041bc42551e122424e76d98e84c
commits: 2
status: complete
---

# Phase 176 Plan 06: Debounced Search and Back/Forward Sync Summary

**Deliveries Search now debounces into one history entry per edit, Enter commits immediately, and a `FilterSearchSync` hook restores the committed text into a focused Search on Back/Forward, proven on LiveView 1.2.13 and 1.1.33.**

## Performance

- **Duration:** about 16 min (including the demo lane boot and a fresh demo database)
- **Completed:** 2026-10-28
- **Tasks:** 2
- **Files modified:** 7 (1 created, 6 modified)

## Accomplishments

- The Search field renders `phx-debounce="300"`, `autocomplete="off"`, `enterkeyhint="search"`, `data-committed={committed search}` and `phx-hook="FilterSearchSync"`; the selects carry no debounce and nothing on the form is disabled, readonly or re-keyed (D-02, D-05).
- ExUnit proves the DOM contract, that exactly one text-like input exists in `#operator-filters` with no submit control (D-03), and that `data-committed` keeps the committed value while an invalid draft differs.
- Chromium on LV 1.2.13 proves `history.length` delta 1 for one search edit, focus retained across debounced commits, and Enter committing inside 250 ms.
- `FilterSearchSync` ships in the hand-maintained `hooks.js`; a mutation run without the hook turns the Back spike red (`Expected "abc", Received "abcd"`), so the spike measures the hook and not default LiveView behavior.

## Task Commits

1. **Task 1: Deliveries Search debounces into one history entry per edit and Enter commits immediately (tracer)** - `225f8640` (feat)
2. **Task 2: FilterSearchSync hook, spiked on LV 1.2.13 and 1.1.33** - `1be3fc99` (feat)

Tracer gate: Task 1's `<verify>` (ExUnit plus the browser case) was re-run green before Task 2 started, so expansion proceeded.

## Spike Outcome and Shipped Sync Path

| Client | Command | Result |
| --- | --- | --- |
| Admin, LV 1.2.13 (task-blocking) | `npm --prefix mailglass_admin run test:operator-browser -- phase176-filters.spec.js --grep "Phase 176 (spike\|search)"` | 3 passed, 0 skipped, 0 flaky |
| Demo, LV 1.1.33 (advisory, D-29) | `DEMO_BASE_URL=http://127.0.0.1:4017 npm --prefix reference/demo_app/assets run test:e2e -- phase176-filters.spec.js --grep "Phase 176 spike"` | 2 passed, demo-spike-exit=0 |

**Shipped path: the `updated()` hook path.** The demo spike was green on the hook path, so the server `push_event("mailglass:filter-search-sync")` fallback was not built and `operator_live.ex` has no `handle_params` change. Plan 176-07 can reuse the same hook and the `data-committed` contract.

## Verification

All Elixir commands from `/Users/jon/projects/mailglass/mailglass_admin` with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`.

| Check | Result |
| --- | --- |
| `mix test test/mailglass_admin/operator_live_test.exs --seed 0` after Task 1 | 165 tests, 0 failures (3 new) |
| `mix test operator_live_test.exs assets_test.exs token_parity_test.exs --seed 0` after Task 2 | 177 tests, 0 failures |
| Quick lane `operator_live_test`, `inbound_live_test`, `inbound/components_test` `--seed 0` | 298 tests, 0 failures |
| `bash scripts/check-conformance.sh` | OK: design-system conformance clean |
| `mix format --check-formatted` on touched Elixir files; `mix credo --strict lib/.../filters_form.ex` | clean; no issues |
| `grep -c 'phx-debounce="300"'` / `grep -c FilterSearchSync hooks.js` / `grep -c 'phx-hook="FilterSearchSync"'` | 1 / 1 or more / 1 |
| `git diff --quiet -- reference/demo_app/mix.lock` and `-- mailglass_admin/priv/static/app.css` | both clean (app.css restored after each browser run, never staged) |

The existing Phase 169 journey case at `phase169-journey.spec.js:459` (replay-modal copy) remains the known pre-existing red in `deferred-items.md`; it is not part of this plan's runs.

## Decisions Made

See `key-decisions`. The orchestrator decision 7 rule resolved to the hook path, with no human checkpoint.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Demo Storybook pins an md5 of hooks.js**
- **Found during:** Task 2, first demo run
- **Issue:** `reference/demo_app/dev/mailglass_demo_web/storybook.ex` hashes `MailglassAdmin.Controllers.Assets.hooks_body()` at compile time and raises `Update the Storybook review JS path hash to d7201408...` when it differs. Changing `hooks.js` therefore broke the demo compile, which surfaced as `MailglassDemoWeb.Router is not available` on `/demo/login`.
- **Fix:** Updated `@configured_review_js_hash` and the `js_path` literal from `571f26622aab3f8464962fb22bda3296` to `d7201408b8ccd6015cc463b47b90d8b1`. The router and `storybook-hooks.spec.js` read the hash dynamically, so no other file needs it.
- **Files modified:** `reference/demo_app/dev/mailglass_demo_web/storybook.ex`
- **Verification:** demo compile succeeds, demo spike 2 passed.
- **Committed in:** `1be3fc99`

**2. [Rule 3 - Blocking] Local demo dev database was stale**
- **Found during:** Task 2, demo run
- **Issue:** `mix ecto.setup` failed on the existing `mailglass_demo_dev` database (`schema "mailglass" does not exist`), and a second run timed out waiting for the webServer URL.
- **Fix:** No repo change. I served the demo from a fresh throwaway database (`PGDATABASE=mailglass_demo_phase176_06`, port 4017) and pointed Playwright at it with `DEMO_BASE_URL`, then stopped the server and dropped the database. The existing `mailglass_demo_dev` database was not touched.
- **Verification:** demo spike 2 passed; `reference/demo_app/mix.lock` byte-identical afterwards.

**Total deviations:** 2 auto-fixed (both Rule 3). **Impact:** deviation 1 is a real cross-package coupling that plan 176-07 must repeat if it edits `hooks.js` again; neither changes scope.

## Issues Encountered

- Any later change to the `hooks.js` body must re-pin the md5 in the demo `storybook.ex` in the same commit, or the demo no longer compiles.
- The default demo lane command (`test:e2e` with its own webServer) does not start on this machine because the local `mailglass_demo_dev` database is stale; use a fresh `PGDATABASE` plus `DEMO_BASE_URL` as above.
- IME composition (assumption A6) is not automatable and stays unverified; focused values are never patched by LiveView, so residual risk is low.

## Known Stubs

None.

## Threat Flags

None. T-176-04 is mitigated (the flag disarms on `updated()`, on `input` and after 1500 ms, with the "typing after an empty Back is kept" case green on both clients). No packages or lockfiles changed (T-176-SC).

## User Setup Required

None.

## Prohibition status

The prohibition that the Search field must never be disabled, readonly or show a loading state is asserted by the DOM-contract ExUnit test and the Playwright `toBeEnabled`/`toBeFocused` checks; the mutation-proven contract test belongs to plan 176-10.

## Next Phase Readiness

- Plan 176-07 (Inbound) can reuse `FilterSearchSync` and the `data-committed` contract without a server fallback. If it edits `hooks.js`, it must re-pin the demo Storybook hash.

## Self-Check: PASSED

- Created file present: `reference/demo_app/assets/e2e/phase176-filters.spec.js`.
- Commits `225f8640` and `1be3fc99` are ancestors of HEAD; `git rev-list --count 3055905c..HEAD` = 2 (matches `commits: 2`).
- No file deletions in either commit; user WIP under `.planning/` and `prompt.txt` never staged; `priv/static/app.css` and `reference/demo_app/mix.lock` unchanged.

---
*Phase: 176-direct-filters-and-useful-inbound-evidence*
*Completed: 2026-10-28*
