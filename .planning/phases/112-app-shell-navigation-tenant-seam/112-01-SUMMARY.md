---
phase: 112-app-shell-navigation-tenant-seam
plan: 01
subsystem: admin-shell
tags: [tenant-scope, read-model, phoenix, ecto, mailglass-admin]

requires:
  - phase: 110-primitives
    provides: public shell primitives for later selector UI consumption
  - phase: 111-forms
    provides: completed form primitive foundation before shell behavior work
provides:
  - Scoped core outbound tenant selector projection
  - Admin tenant selector seam combining outbound and optional inbound tenant ids
  - Runtime-gated inbound tenant projection gateway
affects: [phase-112, shell-tenant-selector, mailglass-admin, mailglass-inbound]

tech-stack:
  added: []
  patterns:
    - Core read model applies Mailglass.Tenancy.scope/2 before selector projection
    - Admin package consumes tenant ids through a seam, not raw Repo access
    - Optional inbound access remains runtime apply/3-gated

key-files:
  created:
    - lib/mailglass/operator/tenants.ex
    - mailglass_admin/lib/mailglass_admin/operator/tenants.ex
    - test/mailglass/operator/tenants_test.exs
    - mailglass_admin/test/mailglass_admin/operator/tenants_test.exs
    - mailglass_admin/test/mailglass_admin/optional_deps/mailglass_inbound_test.exs
  modified:
    - lib/mailglass.ex
    - mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex

key-decisions:
  - "Use a distinct tenant projection over outbound deliveries for core shell discovery."
  - "Use the admin selector seam as the only shell-facing tenant list API."
  - "Keep inbound tenant ids behind the existing optional dependency gateway."

patterns-established:
  - "Selector rows are plain maps with string id and label fields."
  - "Tenant selector unions de-duplicate and sort ids before rendering-facing output."

requirements-completed: [SHELL-01, SHELL-02]

duration: 35min
completed: 2026-06-19
status: complete
---

# Phase 112 Plan 01: Core Tenant Selector Seam Summary

**Scoped outbound tenant discovery plus an admin selector seam that can include optional inbound-only tenant ids.**

## Performance

- **Duration:** 35 min
- **Started:** 2026-06-19T20:09:00Z
- **Completed:** 2026-06-19T20:43:59Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `Mailglass.Operator.Tenants.list_tenants/2`, a scoped distinct projection over outbound deliveries.
- Added `MailglassAdmin.Operator.Tenants.list_tenants/2`, the shell-facing seam that unions outbound and optional inbound tenant ids.
- Extended the inbound optional dependency gateway and inbound read model with tenant selector projection support.
- Added regression tests for sorting, de-duplication, blank filtering, tenancy scoping, admin union behavior, and optional gateway behavior.

## Task Commits

1. **Task 1: Add scoped core tenant projection tests** - `e02147c5` (test)
2. **Task 2: Implement Mailglass.Operator.Tenants.list_tenants/2** - `d74b47bb` (feat)

## Files Created/Modified

- `lib/mailglass/operator/tenants.ex` - Core scoped outbound tenant selector projection.
- `mailglass_admin/lib/mailglass_admin/operator/tenants.ex` - Admin shell selector seam.
- `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex` - Runtime-gated inbound tenant projection wrapper.
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` - Inbound tenant projection read-model function.
- `lib/mailglass.ex` - Boundary export for the new core read model.
- `test/mailglass/operator/tenants_test.exs` - Core selector tests.
- `mailglass_admin/test/mailglass_admin/operator/tenants_test.exs` - Admin selector seam tests.
- `mailglass_admin/test/mailglass_admin/optional_deps/mailglass_inbound_test.exs` - Optional gateway tests.

## Decisions Made

- The core selector uses existing outbound delivery rows instead of a dedicated tenant table, matching Phase 112 research and avoiding migrations.
- Inbound-only tenant ids require a narrow inbound internal read-model function so admin code never reaches into inbound storage directly.
- Tests for admin package modules include root-package compatibility requires because the plan-level root `mix test` command does not compile `mailglass_admin/lib` paths by default.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Exported the new core read model through the core Boundary**
- **Found during:** Task 2
- **Issue:** `mailglass_admin` compile rejected `Mailglass.Operator.Tenants` because the module was not exported by the `Mailglass` boundary.
- **Fix:** Added `Operator.Tenants` to `lib/mailglass.ex` exports.
- **Files modified:** `lib/mailglass.ex`
- **Verification:** `mix compile --warnings-as-errors` from `mailglass_admin/` succeeded.
- **Committed in:** `d74b47bb`

**2. [Rule 2 - Missing Critical] Added inbound internal tenant projection**
- **Found during:** Task 2
- **Issue:** The optional admin gateway needed a real inbound read-model function to source inbound-only tenant ids without admin Repo access.
- **Fix:** Added `MailglassInbound.Internal.Operator.Records.list_tenants/2` with `Tenancy.scope/2`, blank filtering, distinct grouping, and sorted selector rows.
- **Files modified:** `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`
- **Verification:** Targeted root test command passed, including optional gateway tests.
- **Committed in:** `d74b47bb`

**Total deviations:** 2 auto-fixed (Rule 2: 1, Rule 3: 1)
**Impact on plan:** Both changes were required for correctness and package-boundary compliance. No migrations, new dependencies, tenant CRUD, or admin Repo access were added.

## Issues Encountered

- Standalone `mailglass_inbound` compile in its package directory is blocked by a pre-existing dependency mismatch: `premailex` requirement `~> 1.0` but lock/source reports `0.3.20`. The root targeted verification exercised the inbound code path successfully.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: tenant-read-model | `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` | Added an inbound tenant selector projection at a tenant/data trust boundary; it applies `Mailglass.Tenancy.scope/2`, excludes blank ids, and returns only plain string selector fields. |

## Verification

- `mix test test/mailglass/operator/tenants_test.exs mailglass_admin/test/mailglass_admin/operator/tenants_test.exs mailglass_admin/test/mailglass_admin/optional_deps/mailglass_inbound_test.exs --warnings-as-errors` failed in RED before implementation with missing planned APIs.
- `mix test test/mailglass/operator/tenants_test.exs test/mailglass/operator/deliveries_test.exs mailglass_admin/test/mailglass_admin/operator/tenants_test.exs mailglass_admin/test/mailglass_admin/optional_deps/mailglass_inbound_test.exs --warnings-as-errors` passed: 9 tests, 0 failures.
- `mix compile --warnings-as-errors` from `mailglass_admin/` passed after the boundary export.

## Next Phase Readiness

Later Phase 112 plans can consume `MailglassAdmin.Operator.Tenants.list_tenants/2` through the existing `operator_actor` assign and build the sole-tenant auto-select and multi-tenant switcher behavior without adding admin storage reads.

## Self-Check: PASSED

- Created files exist on disk.
- Task commits `e02147c5` and `d74b47bb` exist in git history.
- Plan-level targeted verification passed.

---
*Phase: 112-app-shell-navigation-tenant-seam*
*Completed: 2026-06-19*
