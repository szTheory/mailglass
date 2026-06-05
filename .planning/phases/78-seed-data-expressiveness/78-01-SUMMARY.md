---
phase: 78-seed-data-expressiveness
plan: "01"
subsystem: reference/demo_app
tags: [seed-data, demo, admin-dashboard, inbound, outbound, support-cards]
dependency_graph:
  requires: []
  provides:
    - "demo_data.ex breadth seed: 9 missing event-type deliveries, 2 missing inbound outcomes, all support-card branches, truncation stress rows, empty-tenant constant"
  affects:
    - "reference/demo_app/lib/mailglass_demo/demo_data.ex"
    - "reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs"
tech_stack:
  added: []
  patterns:
    - "Direct InboundRecords API calls (not private builder) for explicit received_at control"
    - "Event.changeset/1 directly for orphan events (delivery_id: nil, needs_reconciliation: true)"
    - "WebhookEvent.changeset/1 directly for failed-ingest seed (status: :failed)"
key_files:
  created: []
  modified:
    - "reference/demo_app/lib/mailglass_demo/demo_data.ex"
    - "reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs"
decisions:
  - "[78-01-A] Committed reference/demo_app/mix.lock (swoosh 1.26.0 -> 1.26.1 patch bump) — this is the demo_app sub-project lock, not the root mix.lock; patch bump is required for the build to compile and test correctly in worktree"
  - "[78-01-B] Combined Task 1 and Task 2 into one commit — both tasks modify demo_data.ex and the test update reflects both tasks' count changes; can't stage partial changes to a single file without interactive patch mode"
metrics:
  duration_seconds: 489
  completed_date: "2026-06-04"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 3
---

# Phase 78 Plan 01: Northstar Breadth Seed Expansion Summary

Expanded `demo_data.ex` with a comprehensive breadth seed covering every admin dashboard screen state: 9 missing Anymail event-type deliveries, 2 missing inbound outcomes, all support-card Tier-1/Tier-2 branches, truncation stress rows, and an empty-tenant constant.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Expand seed_outbound! with 8 missing event-type deliveries + support-card branch seeds | 074b0cde | reference/demo_app/lib/mailglass_demo/demo_data.ex, reference/demo_app/mix.lock |
| 2 | Expand seed_inbound! with :ignore and :failed outcome rows + truncation stress inbound record | 074b0cde | reference/demo_app/lib/mailglass_demo/demo_data.ex, reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs |

## What Was Built

### Task 1: seed_outbound! Expansion

Added to `demo_data.ex`:

- `@empty_tenant "empty-tenant"` module attribute and `empty_tenant_id/0` public function (D-02 zero-state reachability — navigating with `?tenant_id=empty-tenant` reaches every empty/zero state without seeding any rows)
- **9 missing event-type deliveries** (GAP-16): `:queued`, `:rejected`, `:autoresponded`, `:opened`, `:clicked`, `:complained`, `:unsubscribed`, `:subscribed`, `:unknown` — all at `minutes_ago(132..148)` so they sort below existing rows
- **Truncation stress delivery** (D-08): recipient `aaa...@northstar-stress.example` with 82-char local-part
- **Replay-outcome events** (D-05 / GAP-13): 3 events on `receipt` and `usage_alert` covering all 3 branches: `outcome="replayed"`, `outcome="noop"`, and `:webhook_replay_failed`
- **Orphan events** (D-06 / GAP-13): Orphan A (`needs_reconciliation: true`, `delivery_id: nil`) linked by a `:reconciled` event; Orphan B unmatched — gives `reconcile_facts.reconciled_count > 0` AND `still_unmatched_count > 0`
- **Failed-ingest WebhookEvent** (GAP-13): `status: :failed` inserted via `WebhookEvent.changeset/1` directly — triggers the Tier-1 `failed_ingest` support card (`count > 0`)

### Task 2: seed_inbound! Expansion

- **`:ignore` inbound outcome** (D-04 / GAP-16): inserted via `InboundRecords.insert_inbound_record/1` directly (to control `received_at: minutes_ago(30)`), then `inbound_run!/6` with `outcome: :ignore, mailbox: "MailglassDemoWeb.Inbound.SpamMailbox"` — satisfies `validate_outcome_shape/1` (mailbox present, `failure: %{}`)
- **`:failed` inbound outcome + truncation stress subject** (D-04 / D-08 / GAP-16): record inserted directly with `received_at: minutes_ago(35)`, subject 209 chars (>= 150 required). Execution run inserted via `InboundRecords.insert_execution_run/1` with `execution_failure: %{"reason" => "parse_error", "provider" => "mailgun"}` — `normalize_execution_attrs/1` maps this to `outcome: :failed, failure: map_size > 0`
- All 6 inbound outcomes now seeded: `:no_match`, `:accept`, `:reject`, `:bounce`, `:ignore`, `:failed`

## Verification Results

1. `mix compile --warnings-as-errors` — exits 0, no warnings
2. `mix test test/mailglass_demo/` — 12 tests, 0 failures
3. `mix test test/mailglass_admin/operator_live_test.exs` — 22 tests, 0 failures (support-card Tier-1 branches render: orphan_backlog, failed_ingest, replay_outcomes; reconcile_facts shows both branches)
4. `mix verify.preview` — 189 tests, 0 failures (2 excluded); bundle bit-identical, no rebuild needed
5. `demo.spec.js` — UNCHANGED (minimum-count invariants; breadth additions never reduce row counts below 1)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated demo_data_reset_test.exs exact-count assertions**
- **Found during:** Task 1 execution (test run after seed changes)
- **Issue:** `demo_data_reset_test.exs` asserted exact counts (6 deliveries, 12 events, 4 inbound, etc.) and exact lists (`delivery_message_ids`, `inbound_provider_message_ids`, etc.) that no longer matched after adding 10 deliveries and 2 inbound records
- **Fix:** Updated all exact-count assertions to reflect new totals (16 deliveries, 35 events, 6 inbound, 6 evidence, 8 replay runs, 3 webhook events) and updated all exact-list assertions to include the new seed records' provider_message_ids and execution matrix entries
- **Files modified:** `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs`
- **Commit:** 074b0cde

**2. [Rule 3 - Blocking] mix deps.get required in worktree**
- **Found during:** Initial compile attempt
- **Issue:** Worktree did not have deps downloaded; `mix compile` failed immediately
- **Fix:** Ran `mix deps.get` in both `reference/demo_app` and `mailglass_admin` directories — standard worktree setup step
- **Impact:** `reference/demo_app/mix.lock` bumped `swoosh` from 1.26.0 to 1.26.1 (patch); committed as it is the demo_app sub-project lock (not root mix.lock)

### Structural Notes

- **Single commit for both tasks:** Tasks 1 and 2 both modify `demo_data.ex` and the test update covers both tasks' count changes. Staged as one coherent commit since `git add -p` (interactive partial staging) is not available in this execution context.

## Known Stubs

None — all seeded data is wired to real schema paths (Event, Delivery, WebhookEvent, InboundRecords) with no hardcoded empty values or placeholder text flowing to UI rendering.

## Threat Flags

None — this plan makes no changes to authentication, authorization, network endpoints, or trust boundaries. All added data is synthetic demo seed inserted into dev/reference app.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| `reference/demo_app/lib/mailglass_demo/demo_data.ex` exists | FOUND |
| `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs` exists | FOUND |
| `.planning/phases/78-seed-data-expressiveness/78-01-SUMMARY.md` exists | FOUND |
| Commit `074b0cde` exists in git log | FOUND |
