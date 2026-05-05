---
phase: "34"
plan: "02"
subsystem: "testing"
tags: ["mailglass-admin", "support-contract", "citext-probe", "bootstrap"]
requires: ["MAT-03"]
provides:
  - "admin-support-contract-alias"
  - "honest-admin-citext-probe-failure"
  - "admin-probe-regression-tests"
affects:
  - "mailglass_admin/mix.exs"
  - "mailglass_admin/test/support/citext_probe.ex"
  - "mailglass_admin/test/mailglass_admin/test_support/citext_probe_test.exs"
tech_stack:
  added: []
  patterns:
    - "package-local support-contract alias"
    - "pool-size-based bounded probe retries"
    - "schema-backed probe writes for admin bootstrap"
key_files:
  created:
    - "mailglass_admin/test/mailglass_admin/test_support/citext_probe_test.exs"
  modified:
    - "mailglass_admin/mix.exs"
    - "mailglass_admin/test/support/citext_probe.ex"
decisions:
  - "Keep admin support verification package-local via its own explicit alias."
  - "Mirror the root probe's bounded retry budget from the repo pool size instead of hard-coding 5 attempts."
  - "Use schema-backed suppression writes so the admin probe exercises a valid insert path."
metrics:
  completed_at: "2026-05-05T19:46:54Z"
  duration: "during Phase 34 execution"
  tasks_completed: 2
  files_touched: 3
---

# Phase 34 Plan 02: Admin Verification Closure Summary

`mailglass_admin` now has an explicit support-contract command and an honest bootstrap probe with deterministic regression coverage.

## Tasks Completed

### Task 1

- Added `verify.support_contract.admin` to `mailglass_admin/mix.exs` for the exact two-file admin/operator support bundle.
- Added a `cli/0` `preferred_envs` entry so the alias runs under `MIX_ENV=test` like the rest of the admin verification surface.

### Task 2

- Refactored `MailglassAdmin.TestSupport.CitextProbe` to raise `citext probe exhausted for MailglassAdmin.TestRepo after N attempts`.
- Extracted the probe body behind `probe_fun` injection and aligned retry budgeting with `pool_size + 1`.
- Added `mailglass_admin/test/mailglass_admin/test_support/citext_probe_test.exs` with success and exhausted-retry assertions.

## Verification

- `cd mailglass_admin && mix test test/mailglass_admin/test_support/citext_probe_test.exs --warnings-as-errors`
- `cd mailglass_admin && mix verify.support_contract.admin`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Hidden bootstrap defect] Replaced the admin probe's invalid raw SQL insert**
- **Found during:** Wave 1 verification
- **Issue:** The previous admin probe retried a deterministic `ERROR 23502` because its raw insert omitted the non-null suppression `id` column, so the bootstrap never had a chance to recover from stale OIDs.
- **Fix:** Switched the admin probe to the same schema-backed insert/delete flow as the root package while preserving package-local ownership and the admin-specific failure message.
- **Files modified:** `mailglass_admin/test/support/citext_probe.ex`

## Issues Encountered

- `mailglass_admin` still emits Boundary warnings because its package-local probe reaches `Mailglass.Suppression.*` modules; the Phase 34 target commands passed, so that warning remains tracked but did not block completion of this plan.

## Self-Check: PASSED

- Verified the admin support alias runs successfully.
- Verified the admin probe tests cover both success and exhausted-retry behavior.

