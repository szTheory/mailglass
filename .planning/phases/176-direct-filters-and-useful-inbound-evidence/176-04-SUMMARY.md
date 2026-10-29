---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "04"
subsystem: ui
tags: [phoenix-liveview, filters, read-state, accessibility, playwright]

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: commit_filters/3 draft branch and handle_params URL normalization (plan 01)
provides:
  - One-shot `deliveries` read fault seam for ExUnit and the browser
  - Deliveries error panel with a history-free Retry; count hidden unless the read is :ready
  - MailglassAdmin.Operator.ResultsStatus (settled-state text for both collections, stale title)
  - Persistent sr-only role=status region and stale panel with load time
  - Draft-pending and URL-invalid notes with the reworded event error
affects: [176-09, 176-10]

actuals:
  tokens: 10900
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "A read's load time is stamped only by a successful read and carried through a failed one, so the stale panel names the rows actually on screen"
    - "The announcement region's text is a pure function of how a read settled (ResultsStatus.text/1); drafts never reach it"
    - "filter_error_source (nil | :draft | :url) separates an uncommitted invalid draft from an invalid value the URL carried"

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/operator/results_status.ex
    - mailglass_admin/test/mailglass_admin/operator/results_status_test.exs
  modified:
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/support/operator_fixtures.ex
    - mailglass_admin/e2e/phase176-filters.spec.js

key-decisions:
  - "Stale count is hidden (D-15); the stale title carries the HH:MM UTC load time and a Components.timestamp line renders beneath it (orchestrator decision 3)"
  - "The status region sits outside the list cond, inside the Deliveries (non-overview) branch, so it exists for both the genuine-empty pane and the list"
  - "The Full-detail exact-read-failure test now refutes the empty-state testids instead of the phrase, because the sr-only region may truthfully state the settled list read"
  - "Window-invalid note reads 'Showing results for the default time window instead.' since the window falls back rather than disappearing"

patterns-established:
  - "Browser runs of the operator-browser script stay wrapped: assert priv/static/app.css clean before, git checkout it after"

requirements-completed: ["FILTER-04"]

coverage:
  - id: D1
    description: "A failed new-query Deliveries read renders the error panel with Retry and no rows, count or empty copy; Retry adds no history"
    requirement: "FILTER-04"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 Deliveries new-query read failure shows a truthful error, no count and no empty copy"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 Deliveries Retry adds no history and re-reads the committed filters"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/phase176-filters.spec.js#Phase 176 Deliveries failed read shows error and Retry"
        status: pass
    human_judgment: false
  - id: D2
    description: "A same-query failed read keeps rows under the stale panel with the load time; the count is hidden unless the read is ready"
    requirement: "FILTER-04"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 a same-query failed read keeps rows under the stale panel with the load time"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator/results_status_test.exs#stale_title/1"
        status: pass
    human_judgment: false
  - id: D3
    description: "One persistent role=status region present at first render; text changes only when a read settles and never on invalid drafts or identical re-reads"
    requirement: "FILTER-04"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 results status region exists at first render and announces the settled count"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 results status text ignores invalid drafts and identical re-reads"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator/results_status_test.exs#text/1 (Deliveries and Inbound tables)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Invalid draft and invalid URL value are labelled with distinct notes, aria wiring and reworded event error; a later valid commit clears both"
    requirement: "FILTER-04"
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 an invalid draft stays a draft with a pending note outside the filter panel"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/operator_live_test.exs#Phase 176 an invalid URL value is labelled as excluded, never an unlabelled fallback"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-10-28
plan_head_before: aa88eb0e55ab9eba89a7b013214a1640837fe075
plan_head_after: 5977d8e1cdada70b3e653a8bf76a48e9f2032ffb
commits: 3
status: complete
---

# Phase 176 Plan 04: Deliveries Truthful Read States Summary

**Deliveries never lies about results: a failed new-query read shows an error with a history-free Retry, a same-query failure keeps rows under a stale panel naming the load time, invalid drafts and URL values are labelled, and one quiet role=status region announces each settled read once.**

## Performance

- **Duration:** about 10 min
- **Completed:** 2026-10-28
- **Tasks:** 3
- **Files modified:** 7 (2 created, 5 modified)

## Accomplishments

- `deliveries` joins the one-shot `arm_reader_fault!/3` whitelist, so the same fault arms in ExUnit and through `/ops/browser-mutate`.
- `DeliveriesList` hides the count unless the read is `nil` or `:ready`; the `:error` panel reads "Couldn't load deliveries for these filters" with a `operator-retry-deliveries` Retry beneath it (D-14, D-15). `retry_deliveries` was already patch-free; tests now prove it (`refute_patch`, and `history.length` unchanged in Chromium).
- `Operator.ResultsStatus.text/1` and `stale_title/1` give the six settled-state strings for Deliveries and Inbound (Inbound reuse lands in plan 09). `OperatorLive` stamps `deliveries_loaded_at` only on a successful read and assigns `results_status_text` after every settle.
- The stale panel is titled "Showing results from HH:MM UTC; refresh failed" (or "Showing earlier results; refresh failed" with no known time), with body "Mailglass couldn't re-read these results. Retry to check for updates.", a `Components.timestamp` line, and Retry.
- `#operator-results-status` (role=status, aria-live=polite, aria-atomic, sr-only) renders from first render; invalid drafts and identical re-reads leave its text unchanged.
- `filter_error_source` drives two notes outside `#operator-filter-panel`: `filters-draft-pending-note` for an uncommitted invalid draft and `filters-url-invalid-note` with one sentence per invalid URL field. The event error now reads "Latest recorded event was not applied. Choose a listed event."

## Task Commits

1. **Task 1: A failed new-query Deliveries read shows a truthful error with Retry (tracer)** - `0ad7983e` (feat)
2. **Task 2: Stale retention with load time and the persistent results status region** - `b5b3bf87` (feat)
3. **Task 3: Invalid draft and invalid URL value notes with the reworded event error** - `5977d8e1` (feat)

**Plan metadata:** committed separately (docs: complete plan)

## Verification

All Elixir commands run from `/Users/jon/projects/mailglass/mailglass_admin` with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`.

| Check | Result |
| --- | --- |
| Task 1 tracer: `mix test test/mailglass_admin/operator_live_test.exs --seed 0` | 156 tests, 0 failures |
| Task 1 browser: `phase176-filters.spec.js --grep "Phase 176 Deliveries failed read"` (wrapped, app.css clean before and restored after) | 1 passed |
| Task 2: `results_status_test.exs`, `operator_live_test.exs`, `voice_test.exs` `--seed 0` | 182 tests, 0 failures |
| Task 2: `--only phase176 --trace` | 164 tests, 0 failures; stale/status test names present |
| Task 3: `operator_live_test.exs --seed 0` | 162 tests, 0 failures; `--only phase176` trace lists the "invalid" tests |
| Full admin suite `mix test --seed 0` | 773 tests, 0 failures, 1 excluded |
| `bash mailglass_admin/scripts/check-conformance.sh` | OK: design-system conformance clean. |
| `mix credo --strict` (repo root) | no issues |
| `mix format --check-formatted` on every touched Elixir file | clean |
| Playwright `phase176-filters.spec.js` + `phase169-journey.spec.js` | 10 passed, 1 failed (pre-existing, see Deferred Issues) |
| `grep -c "Couldn't load deliveries for these filters"` deliveries_list.ex | 1 (baseline 0) |
| `grep -c 'role="status"'` operator_live.ex | 1 (baseline 0) |
| `grep -c "Latest recorded event was not applied"` operator_live.ex | 1 (baseline 0) |
| `grep -c "Status was not applied"` operator_live_test.exs | 0 (baseline 3) |
| `git status --porcelain mailglass_admin/priv/static` | clean (bundle never rebuilt or staged) |

## Decisions Made

See `key-decisions`. No new utilities were introduced: `sr-only`, `mt-sm`, `text-label`, `text-secondary`, `mx-auto`, `min-h-11` were grepped in `priv/static/app.css` before use.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Coupled assertion refuted text the new sr-only region legitimately carries**
- **Found during:** Task 2
- **Issue:** "an unavailable exact read retains the requested ID" refuted the phrase "No deliveries in this time window" in the full document; the new status region states that settled result for an Account with no deliveries.
- **Fix:** Refute the visible empty-state testids (`operator-empty-truly`, `data-state-empty`) instead, with a comment.
- **Files modified:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs`
- **Commit:** `b5b3bf87`

**2. [Rule 3 - Blocking] Three coupled assertions of the old event error copy, not two**
- **Found during:** Task 3
- **Issue:** The plan named `:297` and `:318-334`; a third, the Phase 176 recover test, asserted the same string.
- **Fix:** All three updated to "Latest recorded event was not applied. Choose a listed event."
- **Commit:** `5977d8e1`

**3. [Rule 3 - Blocking] `mix format` rewrote `deliveries_list.ex` wholesale**
- **Found during:** Task 1
- **Issue:** The file had never been formatted, so formatting it (in scope, per the dispatch instruction) produced a 405-line whitespace-heavy diff in commit `0ad7983e`.
- **Fix:** Kept deliberately; behavior is unchanged and later plans inherit a formatted file.

**Total deviations:** 3 auto-fixed (1 Rule 1, 2 Rule 3). **Impact:** none on scope or behavior.

## Deferred Issues

- `e2e/phase169-journey.spec.js:459` ("Phase 169 rendered route matrix stays readable across widths and missing media") fails because it expects replay-review copy "does not resend outbound mail or prove provider receipt", while `operator/replay_modal.ex:35` has said "It does not resend mail or prove provider receipt." since Phase 175 (`a9670252`). This plan did not touch the replay modal; the failure is stale spec copy. Logged in `deferred-items.md` in this phase directory. It is not covered by any plan 176 task.

## Known Stubs

None.

## Threat Flags

None. Failure panels render fixed copy only; the tests refute the synthetic failure detail (T-176-11), `:error` renders no rows, count or empty copy and `:stale` carries the load time (T-176-12), and URL normalization is unchanged, with invalid values now labelled and excluded (T-176-13). No installs or lockfile changes (T-176-SC).

## Next Phase Readiness

`ResultsStatus.text/1` already accepts `collection: :inbound` for plan 09. Plan 10 still owes the gallery literal and `structural.spec.js:2283`/`:2330` rewording to match the new event error copy and the prohibition contract tests for the two plan-04 prohibitions.

## Self-Check: PASSED

Created files exist (`results_status.ex`, `results_status_test.exs`); commits `0ad7983e`, `b5b3bf87`, `5977d8e1` are ancestors of HEAD.
