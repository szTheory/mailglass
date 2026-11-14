---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "01"
subsystem: ui
tags: [phoenix-liveview, filters, history, tenancy, playwright]

requires:
  - phase: 169-outbound-investigation-and-recovery
    provides: Deliveries filter history spec and the URL-backed filter contract
provides:
  - MailglassAdmin.Operator.FilterCommit pure history policy and canonical query helpers
  - Deliveries filters that commit on change and on Enter through one commit_filters/3 path
  - phx-auto-recover recover_filters event and replace-based tenant canonicalization
  - Accessible mobile Filters toggle that reports committed filters only
affects: [176-02, 176-04, 176-06, 176-07, 176-10]

actuals:
  tokens: 13600
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Every filter change is a commit: payload -> FilterCommit.commit_params -> normalize -> sorted canonical path -> push_patch(replace: history_kind)"
    - "pending_commit_kind is assigned only where push_patch is called; handle_params settles it into last_commit_kind, so non-commit patches end a search edit"
    - "same_location? canonicalizes both queries (window_hours=168 filled) so bare entry URLs and Clear compare equal to commit targets"

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/operator/filter_commit.ex
    - mailglass_admin/test/mailglass_admin/operator/filter_commit_test.exs
    - mailglass_admin/e2e/phase176-filters.spec.js
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/e2e/phase169-journey.spec.js

key-decisions:
  - "window_hours=168 stays in committed URLs (existing URL contract); only blanks and page=1 are dropped, keys sorted with Enum.sort/1"
  - "Operator support_state is carried through commits via an optional build_path_with_view/4 argument; other callers keep dropping it"
  - "Hidden filters_tenant_id input deleted: commits read the Account only from socket.assigns.selected_tenant_id"
  - "Clear with nothing applied compares both queries canonically, and on a no-op resets the draft to the URL-backed params"
  - "Canonicalize_tenant patches with replace: true and assigns no pending kind (it is a non-commit patch)"

patterns-established:
  - "assert_patch_kind(view, kind) reads the {ref, {:patch, topic, %{kind:, to:}}} message from view.proxy to prove push vs replace in ExUnit"
  - "Browser runs of the operator-browser script are wrapped: assert priv/static/app.css clean before, git checkout it after"

requirements-completed: ["FILTER-01", "FILTER-02", "FILTER-03"]

coverage:
  - id: D1
    description: "Deliveries select changes commit a canonical, sorted, Account-safe URL immediately; no Apply, submit or disable-with control"
    requirement: "FILTER-01"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 select change commits one sorted canonical push patch"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 the filter form has no Apply, submit, loading or tenant control"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 tracer: Deliveries select applies without Apply"
        status: pass
    human_judgment: false
  - id: D2
    description: "Enter commits through commit_filters/3 with kind :enter; search trimmed; a 500-character search round-trips; no filter control is disabled"
    requirement: "FILTER-02"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 Enter trims search and commits it to the URL"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 a 500-character search round-trips through the canonical URL"
        status: pass
    human_judgment: false
  - id: D3
    description: "One history policy decides push vs replace for every commit kind; replace for canonicalize and recover; Account never taken from the payload; page and selection dropped"
    requirement: "FILTER-03"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator/filter_commit_test.exs#history_kind/2 truth table (4 tests)"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 rapid select, search and Enter end at the last URL with push, push, replace"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 a foreign tenant_id never changes the Account on change or submit"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#history.length delta of exactly 1 for one select, Back and Forward restore state"
        status: pass
    human_judgment: false
  - id: D4
    description: "Deliveries mobile Filters toggle carries aria-controls and a toggled aria-expanded and labels committed filters only"
    requirement: "FILTER-03"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 mobile Filters toggle (4 tests)"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-10-28
plan_head_before: c96c8a4f38d61f5c72c373bb4b0bf6c1d8b983d0
plan_head_after: 2b787cfaaa770d44b54fcc5840d568ca5cc4c7bf
commits: 3
status: complete
---

# Phase 176 Plan 01: Deliveries Direct Filters Summary

**Deliveries filters now commit on change and on Enter through one unit-tested history policy (`FilterCommit`), with a server-held Account, a sorted canonical URL, one history entry per intent, and replace for canonicalization and reconnect recovery.**

## Performance

- **Duration:** about 12 min
- **Completed:** 2026-10-28
- **Tasks:** 3
- **Files modified:** 6 (3 created, 3 modified)

## Accomplishments

- A select change patches the canonical URL immediately. The Apply button, its disable-with loading state and the hidden tenant input are gone from the Deliveries form (D-01, D-05, D-09).
- `FilterCommit.history_kind/2` is the single truth table for push vs replace: search pushes first and replaces after, Enter replaces only when it finalizes an in-flight search edit, select/clear/page push, recover/canonicalize replace.
- `commit_filters/3` forces the server-held Account, trims search, drops page and selection keys, carries support state, and treats a same-location commit as a no-op. `pending_commit_kind` is assigned only in the push branch, so a no-op can never mislabel a later Back.
- `phx-auto-recover="recover_filters"` restores a valid, differing draft with replace; an invalid draft stays a draft; a foreign tenant is ignored.
- The mobile Filters toggle has `aria-controls`/`aria-expanded` and reads "Filters" or "Filters (N applied)" from committed params only.

## Task Commits

1. **Task 1: Deliveries select change commits end-to-end through FilterCommit (tracer)** - `fca72fc0` (feat)
2. **Task 2: History policy, search-edit tracking, replace for canonicalize/recover, Clear guard** - `0938c02b` (feat)
3. **Task 3: Deliveries mobile Filters toggle state** - `2b787cfa` (feat)

**Plan metadata:** committed separately (docs: complete plan)

## Verification

All commands run from `/Users/jon/projects/mailglass/mailglass_admin` with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`.

| Check | Result |
| --- | --- |
| Baseline `mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/bucket_a_coverage_test.exs --seed 0` before changes | 130 tests, 0 failures |
| Task 1 (same two files) after | 143 tests, 0 failures (13 new Phase 176 tests) |
| Final `mix test test/mailglass_admin/operator/filter_commit_test.exs test/mailglass_admin/operator_live_test.exs --seed 0` | 165 tests, 0 failures (`--only phase176`: 44 tests) |
| Quick lane `operator_live_test`, `inbound_live_test`, `inbound/components_test` `--seed 0` | 269 tests, 0 failures |
| Full admin suite `mix test --seed 0` | 725 tests, 0 failures, 1 excluded |
| `bash scripts/check-conformance.sh` | OK: design-system conformance clean. |
| `mix format --check-formatted` on the four touched Elixir files | clean |
| Playwright (Chromium, LV 1.2.13): tracer + "Phase 169 filter history restores committed URL state" + "routine filter patches retain the feedback node" | 3 passed, 0 skipped, 0 flaky; `app.css` verified clean before and restored after |
| `grep -c filters_tenant_id` / `phx-disable-with` in operator_live.ex | 0 / 0 (baselines 1 / 1) |
| `grep -c load_provider_options` | 4 (baseline 5) |
| `grep -c 'phx-auto-recover="recover_filters"'` / `replace: true` | 1 / 1 |

RED was confirmed before each GREEN: the 13 Task 1 tests failed (11 failures) against the old handlers, and the filter_commit unit file failed on the missing `history_kind/2`.

## Decisions Made

See `key-decisions` above. The plan's orchestrator decisions 1, 2 and 5 are implemented as written.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Clear with nothing applied would still have patched**
- **Found during:** Task 2
- **Issue:** `clear_filters` builds a target without `window_hours`, while the current-URI canonicalization fills `window_hours=168`, so `same_location?/2` would never match and Clear-with-nothing-applied would patch.
- **Fix:** `same_location?/2` canonicalizes both the current and the target query (idempotent for commit targets, which already carry `window_hours`). On a Clear no-op the draft is reset to the URL-backed params so an uncommitted draft does not linger.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`
- **Verification:** "Phase 176 Clear with nothing applied produces no patch and stays enabled"
- **Committed in:** `0938c02b`

**2. [Rule 3 - Blocking] Existing form test submitted the removed hidden tenant field**
- **Found during:** Task 1
- **Issue:** `form("#operator-filters", filters: %{"tenant_id" => ...})` fails once the hidden input is deleted.
- **Fix:** Dropped `tenant_id` from that `form/3` map; foreign-tenant coverage moved to new `render_hook` tests.
- **Files modified:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs`
- **Committed in:** `fca72fc0`

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking). **Impact:** both necessary for the plan's own acceptance rows; no scope change.

## Issues Encountered

- `mix credo --strict lib/mailglass_admin/operator_live.ex` reports one pre-existing refactoring opportunity (cyclomatic complexity 23 on `assign_delivery_state/5`, `operator_live.ex:1604`). The function is untouched by this plan (zero diff lines mention it), so it is out of scope.
- `mix format --check-formatted` across the whole admin package lists many unrelated, pre-existing unformatted files; only the files this plan touches were checked and formatted.

## Known Stubs

None.

## Threat Flags

None. The plan's threat register is mitigated: T-176-01 (forced server-held tenant on change, submit and recover, with foreign-tenant tests) and T-176-02 (page and selection keys dropped, asserted on the patched URL). No packages or lockfiles changed (T-176-SC).

## User Setup Required

None - no external service configuration required.

## Prohibition status

The plan-level prohibition (no Apply, submit or disable-with control in the Deliveries filter form) is proved here by "Phase 176 the filter form has no Apply, submit, loading or tenant control" and the connected tracer. Mutation proof in `phase176_prohibition_contract_test.exs` belongs to plan 176-10.

## Next Phase Readiness

- Plans 176-06 (debounced search and focus hook) and 176-07 (Inbound) can reuse `FilterCommit` and the `commit_filters/3` shape; Inbound still renders Apply until 176-07.
- `reference/persona_spec/quick_view_scenarios.json` still describes Deliveries as rendering Apply filters; refresh belongs with the persona/contract plan.

## Self-Check: PASSED

- Created files present: `filter_commit.ex`, `filter_commit_test.exs`, `phase176-filters.spec.js`.
- Commits `fca72fc0`, `0938c02b`, `2b787cfa` are ancestors of HEAD; `git rev-list --count c96c8a4f..HEAD` = 3 (matches `commits: 3`).
- No file deletions in any task commit; user WIP under `.planning/` and `prompt.txt` never staged; `priv/static/app.css` unchanged.

---
*Phase: 176-direct-filters-and-useful-inbound-evidence*
*Completed: 2026-10-28*
