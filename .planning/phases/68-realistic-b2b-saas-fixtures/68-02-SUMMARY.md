---
phase: 68-realistic-b2b-saas-fixtures
plan: "02"
subsystem: demo-mailers
tags: [demo-data, preview-scenarios, message-contracts]
requires:
  - phase: 68-realistic-b2b-saas-fixtures
    plan: "01"
    provides: deterministic fixture corpus and repo-root quick gate
provides:
  - deterministic B2B SaaS preview props for account, billing, and operations scenarios
  - public-message-field contract tests for six preview scenarios
affects: [phase-69, phase-70]
tech-stack:
  added: []
  patterns: [public-message-seam assertions, deterministic scenario key-order pinning]
key-files:
  created:
    - reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs
  modified:
    - reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex
    - reference/demo_app/lib/mailglass_demo_web/mailers/billing_mailer.ex
    - reference/demo_app/lib/mailglass_demo_web/mailers/operations_mailer.ex
key-decisions:
  - Keep assertions at `preview_props/0` plus public `Mailglass.Message` fields only.
  - Lock exact scenario subjects and deterministic tokens in source and tests for browser-evidence traceability.
requirements-completed: [DATA-04]
duration: 4 min
completed: 2026-06-01
---

# Phase 68 Plan 02: Realistic B2B SaaS Fixtures Summary

**Preview mailers now expose deterministic, realistic scenario props and copy, and six scenario contracts are pinned at the public `Mailglass.Message` seam.**

## Performance

- **Duration:** 4 min
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Enriched `AccountMailer`, `BillingMailer`, and `OperationsMailer` preview props with required deterministic fields and kept exact scenario order.
- Updated scenario HTML/text bodies to include scenario-identifying tokens required for later browser evidence.
- Locked all six required subject lines as exact literals in source.
- Added `reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs` with focused tests for scenario key order, deterministic values, `mailable_function`, and public Swoosh message fields.

## Task Commits
1. **Task 1: Deepen deterministic preview scenarios** - `73721f8` (feat)
2. **Task 2: Add preview scenario message contract coverage** - `3c9cc5b` (test)

## Verification Results
- `mix test test/mailglass/demo_data_test.exs` ✅ (passes after Task 1 and Task 2)
- `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/*.exs --warnings-as-errors` ✅ (10 tests, 0 failures)
- `mix test` ⚠️ fails in repo-wide suite due pre-existing DB timeout/cancel failures outside Plan 68-02 files (`Mailglass.Events.*` and `Mailglass.Install.FirstSendSmokeTest` seen in output)

## Deviations from Plan

None - plan tasks executed as written.

## Deferred Issues

- Repo-wide `mix test` wave gate is currently red from pre-existing database timeout/cancel failures not introduced by this plan’s changed files.

## Self-Check: PASSED
- Found summary file: `.planning/phases/68-realistic-b2b-saas-fixtures/68-02-SUMMARY.md`
- Found task commit: `73721f8`
- Found task commit: `3c9cc5b`
