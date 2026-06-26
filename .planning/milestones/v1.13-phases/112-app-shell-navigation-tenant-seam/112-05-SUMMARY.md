---
phase: 112-app-shell-navigation-tenant-seam
plan: 05
subsystem: read-models
tags: [pagination, tenant-scope, ecto, mailglass-inbound, mailglass-admin]

requires:
  - phase: 112-04
    provides: shell navigation cues ready for downstream pagination chrome
provides:
  - Tenant-scoped outbound delivery page metadata
  - Tenant-scoped inbound record page metadata
  - Optional inbound gateway for paginated record reads
affects: [phase-112, pagination-ui, mailglass-admin, mailglass-inbound]

tech-stack:
  added: []
  patterns:
    - Count queries reuse the same tenant/filter base query before limit and offset.
    - Existing list APIs delegate to page APIs and return entries for compatibility.
    - Page and per-page params are normalized as positive integers and capped at existing max limits.

key-files:
  created:
    - .planning/phases/112-app-shell-navigation-tenant-seam/112-05-SUMMARY.md
  modified:
    - lib/mailglass/operator/deliveries.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex
    - mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex
    - test/mailglass/operator/deliveries_test.exs
    - mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs

key-decisions:
  - "Read-model page APIs return maps with entries, total_count, page, per_page, total_pages, has_previous?, and has_next?."
  - "Inbound counts use Repo.one(select(count(id))) because the inbound host-repo facade does not expose aggregate/3."
  - "Blank inbound tenant preserves the existing no-crash contract by returning an empty page result."

patterns-established:
  - "Pagination metadata is computed by counting the scoped base query before applying entry limit/offset."
  - "Optional inbound access continues through runtime apply/3, now including list_records_page/2."

requirements-completed: [SHELL-06]

duration: 18min
completed: 2026-06-19
status: complete
---

# Phase 112 Plan 05: Read-Model Pagination Metadata Summary

**Outbound deliveries and inbound records now expose honest tenant-scoped page metadata for future pagination controls.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-19T20:52:00Z
- **Completed:** 2026-06-19T21:10:46Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added TDD coverage for page metadata totals, first/last page boundaries, and tenant/filter-scoped counts.
- Added `Mailglass.Operator.Deliveries.list_recent_deliveries_page/2`.
- Added `MailglassInbound.Internal.Operator.Records.list_records_page/2`.
- Preserved old `list_recent_deliveries/2` and `list_records/2` entry-list return shapes.
- Added `MailglassAdmin.OptionalDeps.MailglassInbound.list_records_page/2` through the existing optional runtime gateway.

## Task Commits

1. **Task 1: Add read-model pagination metadata tests** - `f89259a6` (test)
2. **Task 2: Implement page metadata APIs and optional gateway** - `4c78d23f` (feat)

## Files Created/Modified

- `lib/mailglass/operator/deliveries.ex` - Adds delivery page API, scoped count, normalized page/per-page params, and compatible list delegation.
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` - Adds inbound page API, scoped count through the repo facade, normalized params, and compatible list delegation.
- `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex` - Exposes inbound page metadata through runtime `apply/3`.
- `test/mailglass/operator/deliveries_test.exs` - Covers outbound page metadata, total counts, first/last boundaries, and tenant/filter scoping.
- `mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs` - Covers inbound page metadata, total counts, first/last boundaries, and tenant/filter scoping.

## Decisions Made

- Page APIs return a plain metadata map instead of changing existing list APIs, keeping current callers compatible.
- Count queries are built from the scoped base query before order/limit/offset/projection so totals cannot be inferred from truncated entries.
- Inbound blank or missing tenant returns `%{entries: [], total_count: 0, total_pages: 0, ...}` instead of raising, preserving the established inbound admin contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Avoided unsupported inbound repo aggregate call**
- **Found during:** Task 2
- **Issue:** `MailglassInbound.Repo` is a host-repo facade and does not expose `aggregate/3`; admin package compilation warned on `Repo.aggregate/3`.
- **Fix:** Changed inbound count to `select(count(record.id)) |> Repo.one()` using the same scoped base query.
- **Files modified:** `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`
- **Verification:** `cd mailglass_admin && mix compile --warnings-as-errors` passed.
- **Committed in:** `4c78d23f`

**Total deviations:** 1 auto-fixed (Rule 3: 1)
**Impact on plan:** The fix stayed within the planned read-model implementation and preserved the existing inbound repo facade.

## Issues Encountered

- The literal root plan command compiles/runs the outbound file but cannot execute `mailglass_inbound/test/...` from the root harness because `MailglassInbound.TestRepo` is unavailable there. This matches the package-boundary verification issue documented in prior Phase 112 summaries.
- The package-local inbound test command is blocked before compilation by a pre-existing dependency mismatch: `premailex` requires `~> 1.0` but the package lock reports `0.3.20`.

## Verification

- RED: `mix test test/mailglass/operator/deliveries_test.exs mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs --warnings-as-errors` failed with missing `Mailglass.Operator.Deliveries.list_recent_deliveries_page/2`; the same root command also hit the known inbound root-harness issue.
- Package-local inbound RED attempt: `cd mailglass_inbound && mix test test/mailglass_inbound/internal/operator/records_test.exs --warnings-as-errors` failed before compilation on the pre-existing `premailex` lock mismatch.
- GREEN: `mix test test/mailglass/operator/deliveries_test.exs --warnings-as-errors` passed: 5 tests, 0 failures.
- Supporting compile: `cd mailglass_admin && mix compile --warnings-as-errors` passed, compiling the inbound read model and optional gateway.
- Literal root command after implementation: `mix test test/mailglass/operator/deliveries_test.exs mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs --warnings-as-errors` passed outbound tests and failed only on unavailable inbound root test support.

## Known Stubs

None. Stub-pattern scan found only existing blank/nil guard logic and test assertions; no placeholder UI or mock data was introduced.

## Threat Flags

None beyond the plan threat model. The new count metadata stays behind the existing tenant/filter read-model boundaries and applies the same scope as entries.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 112-06 can wire UI pagination controls to real metadata without deriving totals or page boundaries from capped entry lists.

## Self-Check: PASSED

- Created/modified files exist on disk.
- Task commits `f89259a6` and `4c78d23f` exist in git history.
- Final executable focused checks passed where this workspace supports them.

---
*Phase: 112-app-shell-navigation-tenant-seam*
*Completed: 2026-06-19*
