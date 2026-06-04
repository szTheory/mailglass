---
phase: 78-seed-data-expressiveness
plan: "02"
subsystem: mailglass_admin
tags:
  - seed-data
  - e2e
  - inbound
  - playwright
  - operator-fixtures
dependency_graph:
  requires:
    - 77-01 (inbound_live.ex id={"inbound-detail-#{@detail.record.id}"} attribute)
  provides:
    - browser scenario has navigable inbound row (GAP-13 resolved)
    - MOTION-02 e2e gate active (no longer skipped)
  affects:
    - mailglass_admin/test/support/operator_fixtures.ex
    - mailglass_admin/e2e/operator.spec.js
tech_stack:
  added: []
  patterns:
    - raw SQL INSERT via Ecto.Adapters.SQL.query! with positional params (extends existing pattern from insert_webhook_event!)
    - Jason.encode! for jsonb array columns in raw SQL inserts
key_files:
  created: []
  modified:
    - mailglass_admin/test/support/operator_fixtures.ex
    - mailglass_admin/e2e/operator.spec.js
decisions:
  - "Used Jason.encode! + $N::jsonb cast for array columns (from/to/cc/bcc/reply_to/attachments) — postgrex does not auto-encode {:array, :map} as jsonb in raw SQL; explicit cast required"
  - "received_at: hours_ago(10) chosen for inbound record — older than hours_ago(6) browser-other delivery (D-07 row-index stability)"
  - "source: 'fresh' used for replay run (not 'replay') — inbound execution runs seeded as live executions, not replays"
  - "raw_mime_fingerprint column excluded from evidence INSERT — it is a GENERATED ALWAYS AS STORED column, cannot be set explicitly"
metrics:
  duration: "~6 minutes"
  completed: "2026-06-04"
  tasks_completed: 1
  files_modified: 2
---

# Phase 78 Plan 02: Inbound Seed + MOTION-02 Un-skip Summary

One-liner: Seeded one inbound record + evidence + execution run in the browser scenario via raw SQL helpers, then removed the test.skip wrapper from the MOTION-02 Playwright gate and implemented the 4-step inbound detail pane id-presence assertion.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add inbound seed to operator_fixtures.ex + un-skip operator.spec.js:254 | 7ee88ba9 | mailglass_admin/test/support/operator_fixtures.ex, mailglass_admin/e2e/operator.spec.js |

## What Was Built

**operator_fixtures.ex changes (PART A):**

1. `reset!/0` extended: TRUNCATE now includes `mailglass_inbound_replay_runs, mailglass_inbound_evidence, mailglass_inbound_records` before the existing outbound tables. `RESTART IDENTITY CASCADE` handles FK order automatically — no orphan rows on re-run.

2. Three new private helpers using raw SQL via `Ecto.Adapters.SQL.query!` (same pattern as `insert_webhook_event!/1`):
   - `insert_inbound_record!/1`: inserts into `mailglass_inbound_records` with all NOT NULL columns including `suppression_flagged: false`. Array columns (`from`, `to`, `cc`, `bcc`, `reply_to`, `attachments`) use `Jason.encode!` + `$N::jsonb` cast.
   - `insert_inbound_evidence!/1`: inserts into `mailglass_inbound_evidence`; `raw_mime_fingerprint` is a GENERATED column and is excluded from the INSERT.
   - `insert_inbound_run!/2`: inserts into `mailglass_inbound_replay_runs` with `source: 'fresh'`, `outcome: 'accept'`, `replay_id: nil`, `mailbox: 'Mailglass.Example.BrowserMailbox'`.

3. `seed_browser_scenario!/0` extended: inserts one inbound record at `received_at: hours_ago(10)` — older than the oldest delivery row (`hours_ago(6)`) so D-07 delivery row indices 0–3 are unaffected (separate table, separate sort).

**operator.spec.js changes (PART B):**

- Removed `test.skip` wrapper and `[SKIP: requires inbound seed in browser scenario]` suffix from test name.
- Replaced Phase 78 gate comment with MOTION-02 regression gate citation comment (matching style of MOTION-01 delivery detail test above it).
- Implemented 4-step assertion: navigate to `/ops/mail/inbound?tenant_id=browser-tenant`, click `getByTestId("inbound-record-row").nth(0)`, await URL containing `inbound_id=`, assert `#inbound-detail-${inboundId}` is visible.
- Used `"inbound-record-row"` testid — matches actual DOM `data-testid` in `records_list.ex:36` (the skip block used `"operator-inbound-row"` which does not exist in the DOM).

## Verification Results

- `mix test test/mailglass_admin/operator_live_test.exs`: 22 tests, 0 failures
- `mix verify.preview`: 189 tests, 0 failures (2 excluded pre-existing), exit 0
- `grep -c 'test\.skip' operator.spec.js`: 0
- `grep "inbound-record-row" operator.spec.js`: 1 match

## Deviations from Plan

None — plan executed exactly as written. The one verification note: the skip block's `"operator-inbound-row"` testid was already flagged in the plan as a discrepancy to fix (plan action item 5, PART B); replaced with `"inbound-record-row"` per plan direction.

## Known Stubs

None. The inbound record is fully seeded with real-looking data — no placeholder values that would cause empty-state rendering.

## Threat Flags

None. All changes are to test support files and a Playwright spec. No production code paths, authentication, or trust boundaries modified.

## Self-Check: PASSED

- `mailglass_admin/test/support/operator_fixtures.ex`: modified (inbound helpers + seed call + reset! extension)
- `mailglass_admin/e2e/operator.spec.js`: modified (test.skip removed, 4-step assertion implemented)
- Commit 7ee88ba9 exists in git log
- `mix test test/mailglass_admin/operator_live_test.exs`: 22 tests, 0 failures
- `mix verify.preview`: exit 0
