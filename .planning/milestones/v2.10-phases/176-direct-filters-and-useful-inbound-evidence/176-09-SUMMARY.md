---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "09"
subsystem: ui
tags: [phoenix-liveview, inbound, filters, read-state, accessibility]

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "Plan 04 ResultsStatus and the Deliveries read-state pattern; plan 07 Inbound commit_filters/3 draft branch"
provides:
  - Inbound failed new-query read renders an error panel with a history-free Retry (retry_inbound)
  - Same-query failed read keeps rows under a stale panel above the list, with the load time
  - Persistent role=status region #inbound-results-status driven by ResultsStatus.text/1
  - Draft-pending and URL-invalid notes on Inbound, outside the collapsible filter panel
affects: [176-10]

actuals:
  tokens: 11000
  tasks: 3
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Inbound mirrors Deliveries: a read's load time and query key are stamped only by a successful read, so a failure of the same key becomes :stale and any other key becomes an error"
    - "RecordsList renders the :stale panel as a sibling above the row cond, never inside it (Pitfall 7)"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/e2e/phase170-journey.spec.js

key-decisions:
  - "retry_inbound derives the selected record id from the page URI (inbound_id), not from selected_record, so Retry after a failed detail read still preserves the URL selection"
  - "A :package_unavailable list read maps to the :error status text; only :ok is :ready and only a same-query :read_unavailable is :stale"
  - "Status region renders in the non-tenant-selector branch before the list cond, mirroring the Deliveries placement"

patterns-established:
  - "Stale rows are rebuilt from records_page_meta plus the retained records, so no second copy of the page is stored"

requirements-completed: ["FILTER-04"]

coverage:
  - id: D1
    description: "A failed new-query Inbound read renders the error panel with Retry and no rows, count or empty copy; Retry adds no history"
    requirement: "FILTER-04"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound new-query read failure shows a truthful error, no count and no empty copy"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound Retry adds no history and re-reads the committed filters"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/phase170-journey.spec.js#database connection failures render as sanitized unavailable data"
        status: pass
    human_judgment: false
  - id: D2
    description: "A same-query failed read keeps rows under the stale panel (above the list) with the load time; count hidden"
    requirement: "FILTER-04"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 a same-query failed read keeps rows under the stale panel with the load time"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 RecordsList renders retained rows beneath the stale panel"
        status: pass
    human_judgment: false
  - id: D3
    description: "One persistent role=status region present at first render; text unchanged by invalid drafts, changes when a read settles"
    requirement: "FILTER-04"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound status region exists at first render and ignores invalid drafts"
        status: pass
    human_judgment: false
  - id: D4
    description: "Invalid draft and invalid URL outcome/window are labelled by distinct notes outside #inbound-filter-panel; a valid commit clears them"
    requirement: "FILTER-04"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound an invalid draft stays a draft with a pending note outside the filter panel"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound an invalid URL value is labelled as excluded, never an unlabelled fallback"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-10-28
plan_head_before: 9d0f87de12127fb079712b8f2450eca3a03d3a14
plan_head_after: cdd047030c60ab4b8b76a803a1d99f4384c7cd03
commits: 1
status: complete
---

# Phase 176 Plan 09: Inbound Truthful Read States Summary

**Inbound now matches Deliveries: a failed new-query read is an error with a history-free Retry, a same-query failure keeps its rows under a stale panel naming the load time, invalid drafts and URL values are labelled, and one quiet role=status region announces each settled read.**

## Accomplishments

- `RecordsList` `:read_unavailable` panel (testid `inbound-read-unavailable` kept) now reads "Couldn't load inbound messages for these filters" / "The read failed. Your filters are unchanged. Retry, or change a filter." with a `Retry messages` button (`inbound-retry-messages`, `phx-click={@retry_event}`, default `retry_inbound`).
- `RecordsList` `:stale` moved out of the row `cond` to a sibling above it (Pitfall 7 fix): `inbound-stale-results` panel with `ResultsStatus.stale_title/1`, the stale body, a `Components.timestamp` line (`inbound-stale-loaded-at`, only when the load time is known) and Retry. Rows still render beneath. The count stays guarded by `is_nil(@data_state)`.
- `InboundLive`: `retry_inbound` re-runs `assign_inbound_state/4` with the committed filters, current selection (from the URL) and `full_detail?`, never patching. `assign_inbound_state` computes a query key from tenant/provider/outcome/search/window/page and records `inbound_loaded_for`/`inbound_loaded_at` only on `:ok`; a `:read_unavailable` read with the same key and existing rows is retained as `:stale`, any other key is an error with no rows.
- `#inbound-results-status` (role=status, aria-live=polite, aria-atomic, sr-only) renders from first render; `results_status_text` is assigned after each read settles via `ResultsStatus.text/1` (`collection: :inbound`).
- `filter_error_source` (`:url` in `handle_params`, `:draft` in the `commit_filters/3` error branch, `nil` otherwise) drives `filters-draft-pending-note` and `filters-url-invalid-note` (one sentence per invalid field: Mailbox outcome / default time window) placed after `#inbound-filter-panel`.

## Task Commits

All three tasks share `assign_inbound_state/4`, `RecordsList` and the same test file, so they landed in one commit (see Deviations).

1. **Tasks 1-3 (tracer error + Retry, stale/status region, notes)** - `cdd04703` (feat)

## Verification

All Elixir commands run from `/Users/jon/projects/mailglass/mailglass_admin` with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`.

| Check | Result |
| --- | --- |
| `mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/voice_test.exs --seed 0` | 141 tests, 0 failures, 1 excluded (:skip) |
| `mix test test/mailglass_admin/inbound_live_test.exs --only phase176 --trace` | 36 phase176 tests listed, 0 failures; "Phase 176 Inbound ..." stale/status/note names present |
| Browser: `phase170-journey.spec.js --grep "database connection failures render as sanitized unavailable data"` (wrapped; app.css clean before, restored after) | 1 passed |
| Full admin suite `mix test --seed 0` | 818 tests, 0 failures, 1 excluded |
| `mix format --check-formatted` on touched files | clean |
| `mix credo --strict` | no findings in touched files (4 findings are pre-existing in other files) |
| `bash scripts/check-conformance.sh` | OK: design-system conformance clean |

Acceptance greps: `retry_inbound` in inbound_live.ex = 1 (baseline 0); "Showing results without the Mailbox outcome filter." = 1 (baseline 0); `grep -c 'id="inbound-results-status"'` = 2 because the pattern is also a substring of `data-testid="inbound-results-status"` (the id attribute appears once; Deliveries has the same shape).

## Deviations from Plan

### Process

**1. [Process] Three tasks committed as one**
- **Found during:** Task 1-3 execution
- **Issue:** the tracer, stale/status and notes tasks all edit `assign_inbound_state/4`, `RecordsList` and one test file, and `RecordsList` moves the stale panel in the same edit as the error copy; clean per-task hunks were not separable without interactive staging.
- **Fix:** implemented in one pass and committed once (`cdd04703`). Every task's verify commands were still run against the final state.
- **Task 2/3 `tdd="true"`:** tests were written after the implementation in this pass rather than RED first; each test was run and passes against the final code, and the deliberate copy updates (existing stale component test at the old `:2009-2010` location, connection-failure copy, browser spec literal) were made as the plan specified.

### Auto-fixed Issues

None - no bugs beyond the plan's scope were found.

**Total deviations:** 1 process deviation. **Impact:** none on behavior; granularity of git history only.

## Known Stubs

None.

## Threat Flags

None. T-176-19: failed-read copy is fixed; tests keep `refute html =~ "synthetic inbound connection failure"`; `ReadResult` is unchanged. T-176-20: `:stale` only for the same query key and always labelled; a new-query failure shows no rows, count or empty copy.

## Issues Encountered

None. `deferred-items.md` browser reds (flows/operator/phase169 specs) are owned by plan 176-10 and were not touched.

## Next Phase Readiness

Ready for 176-10: the Inbound surface now exposes `inbound-results-status`, `inbound-retry-messages`, `inbound-stale-results`, `inbound-stale-loaded-at`, `filters-draft-pending-note` and `filters-url-invalid-note` for the prohibition contract test and browser specs.

## Self-Check: PASSED

- Modified files exist; commit `cdd04703` is an ancestor of HEAD.
- All task acceptance criteria and plan-level verification commands re-run green (see table).
