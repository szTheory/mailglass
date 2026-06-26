---
phase: 112-app-shell-navigation-tenant-seam
plan: 02
subsystem: admin-shell
tags: [tenant-scope, phoenix-liveview, url-state, mailglass-admin]

requires:
  - phase: 112-01
    provides: admin tenant selector seam backed by scoped core and optional inbound projections
provides:
  - Sole-tenant URL canonicalization for operator and inbound LiveViews
  - Multi-tenant selector/switcher state with UI-SPEC copy
  - Tenant-preserving clear, back, surface navigation, and tenant switch paths
affects: [phase-112, shell-tenant-selector, mailglass-admin]

tech-stack:
  added: []
  patterns:
    - LiveViews resolve tenant options before loading surface data
    - Sole-tenant canonicalization is scheduled after connected mount
    - Tenant switch paths allowlist compatible query params and drop selected record ids

key-files:
  created:
    - .planning/phases/112-app-shell-navigation-tenant-seam/112-02-SUMMARY.md
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/test/mailglass_admin/operator/shell_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs

key-decisions:
  - "Sole-tenant canonicalization runs after the connected LiveView mount so tests and first render do not terminate as disconnected redirects."
  - "Explicit blank tenant_id is treated as an unselected selector state, while absent tenant_id is eligible for sole-tenant auto-select."
  - "Tenant switch URLs preserve compatible filters/theme through an allowlist and drop delivery_id/inbound_id."

patterns-established:
  - "Shell tenant selector composition lives in MailglassAdmin.Operator.Shell and is consumed by both operator and inbound LiveViews."
  - "Tenant state assigns use :none, :auto_select, :select_required, and :selected to gate surface reads."

requirements-completed: [SHELL-01, SHELL-02, SHELL-03]

duration: 55min
completed: 2026-06-19
status: complete
---

# Phase 112 Plan 02: Tenant Shell State Summary

**Admin operator and inbound surfaces now canonicalize sole-tenant URLs, render a scoped tenant selector for multi-tenant access, and preserve tenant scope through normal navigation.**

## Performance

- **Duration:** 55 min
- **Started:** 2026-06-19T19:59:00Z
- **Completed:** 2026-06-19T20:54:01Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added RED LiveView and shell-path regression coverage for sole-tenant canonicalization, multi-tenant selector copy, clear/back persistence, and tenant switch URL behavior.
- Added `Shell.tenant_switch_path/2` and `Shell.tenant_selector/1`.
- Wired both LiveViews to call `MailglassAdmin.Operator.Tenants.list_tenants/2` before loading surface data.
- Suppressed list/detail reads for no-tenant and multi-tenant-unselected states.
- Preserved `tenant_id` through clear filters and record back actions.

## Task Commits

1. **Task 1: Add tenant-state LiveView regression tests** - `bae53011` (test)
2. **Task 2: Implement admin tenant auto-select and switcher state** - `3342ba20` (feat)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` - Tenant switch URL builder and selector component.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - Operator tenant-state resolution, canonicalization, selector rendering, and clear-filter persistence.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - Inbound tenant-state resolution, canonicalization, selector rendering, and clear-filter persistence.
- `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` - Tenant switch URL regression coverage.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` - Operator tenant-state regression coverage and updated no-tenant expectations.
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - Inbound tenant-state regression coverage and updated blank-tenant expectations.

## Decisions Made

- Sole-tenant auto-select is scheduled via `:canonicalize_tenant` after connected mount; direct disconnected `push_patch` returned `{:live_redirect, ...}` in tests.
- Explicit `tenant_id=` remains a selector-required state instead of silently auto-selecting, so forged/blank URL state does not mutate into a tenant choice.
- Switch paths use a query allowlist to retain compatible filters and theme while dropping selected ids.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed stale no-tenant tests after replacing the dead-end state**
- **Found during:** Task 2
- **Issue:** Existing tests asserted old no-tenant copy and overview rendering that the plan explicitly replaces with no-tenant/selector shell states.
- **Fix:** Updated expectations to `No tenants available` and tenant selector copy.
- **Files modified:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs`, `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`
- **Verification:** Package-local focused suite passed.
- **Committed in:** `3342ba20`

**Total deviations:** 1 auto-fixed (Rule 1: 1)
**Impact on plan:** The adjustment aligned old tests with the planned SHELL-01/SHELL-02 behavior. No scope expansion.

## Issues Encountered

- The exact root-level command from the plan fails before assertions because root `mix test` does not load `mailglass_admin/test/support/live_view_case.ex`. The package-local equivalent passed and is the executable verification for these admin LiveView tests.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Verification

- RED: `cd mailglass_admin && mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` failed with missing tenant switch helper, missing canonicalization, missing selector copy, and clear-filter tenant loss.
- GREEN: `cd mailglass_admin && mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` passed: 107 tests, 0 failures.
- Root command attempted: `mix test mailglass_admin/test/mailglass_admin/operator/shell_test.exs mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` failed before assertions due missing `MailglassAdmin.LiveViewCase` in root test support.

## Next Phase Readiness

SHELL-01 through SHELL-03 are ready for Phase 112 plans 03-06. Theme persistence, nav cue strengthening, and pagination remain downstream Phase 112 scope.

## Self-Check: PASSED

- Summary file exists on disk.
- Task commits `bae53011` and `3342ba20` exist in git history.
- Package-local focused verification passed.

---
*Phase: 112-app-shell-navigation-tenant-seam*
*Completed: 2026-06-19*
