---
phase: "33"
plan: "02"
subsystem: "operator"
tags: ["observability", "incident-support", "operator", "read-model"]
requires: ["MAT-02"]
provides: ["tenant-support-summary-read-model", "support-summary-query-contract"]
affects:
  - "lib/mailglass/operator/support_summary.ex"
  - "test/mailglass/operator/support_summary_test.exs"
tech_stack:
  added: []
  patterns:
    - "tenant-scoped read model"
    - "append-only ledger facts"
    - "webhook row + ledger fact aggregation"
    - "tdd"
key_files:
  created:
    - "lib/mailglass/operator/support_summary.ex"
    - "test/mailglass/operator/support_summary_test.exs"
  modified:
    - "lib/mailglass/operator/support_summary.ex"
    - "test/mailglass/operator/support_summary_test.exs"
decisions:
  - "Summarize support posture from webhook rows plus ledger facts instead of introducing mutable incident state."
  - "Keep failed_ingest, orphan_backlog, replay_outcomes, and reconcile_facts as separate buckets with drillable exemplars."
  - "Treat current orphan backlog as unresolved orphan events minus durable :reconciled linkage facts."
metrics:
  completed_at: "2026-05-05T18:10:19Z"
  duration: "about 4 minutes"
  tasks_completed: 2
  files_touched: 3
---

# Phase 33 Plan 02: Support Summary Summary

Tenant-scoped support summary read model backed by durable webhook rows and append-only ledger facts.

## Tasks Completed

### Task 1

- Added `Mailglass.Operator.SupportSummary.summarize_tenant/1`.
- Queried failed ingest from `mailglass_webhook_events` rows and orphan / replay / reconcile cues from `mailglass_events`.
- Returned four explicit buckets with counts and exemplars: `failed_ingest`, `orphan_backlog`, `replay_outcomes`, and `reconcile_facts`.
- Commits: `e9e9740`, `79f134f`

### Task 2

- Expanded the dedicated support-summary tests to pin failed/dead webhook semantics, unresolved orphan backlog behavior, oldest backlog age, and replay-vs-reconcile separation.
- Added `oldest_age_seconds` to the orphan backlog bucket so the read model reports current unresolved pressure without mutating orphan rows.
- Commits: `889990a`, `1b57136`

## Verification

- `mix test test/mailglass/operator/support_summary_test.exs --warnings-as-errors`
- `mix test test/mailglass/operator/support_summary_test.exs test/mailglass/webhook/replay_test.exs test/mailglass/webhook/reconciler_test.exs --warnings-as-errors`
- `rg -n "failed_ingest|orphan_backlog|replay_outcomes|reconcile_facts|summarize_tenant" lib/mailglass/operator/support_summary.ex test/mailglass/operator/support_summary_test.exs`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test fixture bug] Corrected invalid delivery fixture statuses in the RED test setup**
- **Found during:** Task 1 RED verification
- **Issue:** The first failing run stopped on invalid fixture status values instead of the missing support-summary module.
- **Fix:** Changed the delivery fixtures in `support_summary_test.exs` from `:delivered` to the valid persisted status `:sent`.
- **Files modified:** `test/mailglass/operator/support_summary_test.exs`
- **Commit:** `e9e9740`

**2. [Rule 2 - Missing critical functionality] Added explicit oldest backlog age to the orphan summary**
- **Found during:** Task 2 RED verification
- **Issue:** The read model exposed the oldest unresolved orphan exemplar but not the explicit age the plan called for.
- **Fix:** Added `oldest_age_seconds` derived from the unresolved orphan exemplar while keeping the source of truth in durable orphan facts.
- **Files modified:** `lib/mailglass/operator/support_summary.ex`, `test/mailglass/operator/support_summary_test.exs`
- **Commit:** `1b57136`

## Known Stubs

None.

## Self-Check: PASSED

- Verified `lib/mailglass/operator/support_summary.ex`, `test/mailglass/operator/support_summary_test.exs`, and `.planning/phases/33-observability-incident-support/33-02-SUMMARY.md` exist on disk.
- Verified commits `e9e9740`, `79f134f`, `889990a`, and `1b57136` exist in git history.
