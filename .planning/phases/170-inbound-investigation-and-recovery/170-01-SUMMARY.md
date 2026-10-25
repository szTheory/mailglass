---
phase: 170-inbound-investigation-and-recovery
plan: 01
subsystem: inbound-operator-ui
tags: [elixir, phoenix-liveview, inbound, read-state, tenancy]

# Dependency graph
requires:
  - phase: 169-account-scoped-operator-evidence
    provides: Tenant-scoped inbound read models and URL-driven operator context
provides:
  - Exact Account-scoped selection and return navigation across list filters and pages
  - Cause-specific empty, out-of-range, optional-package, and read-failure states
  - Narrow, dependency-free gateway error classification
affects: [170-04, 170-05, 170-08, inbound-operator-ui]

# Actuals (#2632)
actuals:
  tokens: 15319
  tasks: 2
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Classify only explicit error tuples and DBConnection.ConnectionError at the Admin read boundary."
    - "Keep list, summary, detail, and timeline read outcomes independent."

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/inbound/read_result.ex
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs

key-decisions:
  - "Exact selected records resolve independently of current page and filters; Back preserves the committed result context."
  - "Missing optional support, unavailable reads, successful empty results, filter no-match, and out-of-range pages remain distinguishable."
  - "Only explicit gateway error results and DBConnection.ConnectionError become sanitized unavailable states; other exceptions propagate."
  - "The page-one recovery link omits the default page parameter while retaining active filters."

patterns-established:
  - "ReadResult.fetch/1 gives Admin gateway reads one narrow, testable error boundary without adding a dependency."
  - "An unavailable panel does not overwrite successful data from another panel."

requirements-completed: [INUX-01]
coverage:
  - id: D1
    description: "An exact same-Account record opens outside the current page or filter and returns to its original result context; missing and foreign IDs disclose no ownership information."
    requirement: INUX-01
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#exact selected record opens outside the current result page and returns to its context"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#an unselectable foreign-tenant record id surfaces the detail-error band, not a leak"
        status: pass
    human_judgment: false
  - id: D2
    description: "Successful empty data, filter no-match, out-of-range pages, missing optional support, and operational read failures have distinct truthful UI states; independent successful detail remains visible when timeline history is unavailable."
    requirement: INUX-01
    verification:
      - kind: integration
        ref: "ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/optional_deps/mailglass_inbound_test.exs --seed 1 (74 tests, 0 failures)"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#gateway result classification is narrow and sanitizes explicit failures"
        status: pass
      - kind: other
        ref: "ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix compile --no-optional-deps --warnings-as-errors"
        status: pass
    human_judgment: false

# Metrics
duration: 16 min
completed: 2026-10-09
status: complete
---

# Phase 170 Plan 01: Exact inbound selection with truthful read states

**Exact Account-scoped inbound selection now survives page and filter boundaries, with honest empty, unavailable, and out-of-range states.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-10-09T01:05:43Z
- **Completed:** 2026-10-09T01:21:10Z
- **Tasks:** 2
- **Files modified:** 5 implementation and test files

## Accomplishments

- Selected same-Account records resolve by exact tenant-scoped ID in Quick view and Full detail, independent of the loaded list slice; Back restores the Account, filters, and page.
- Table/card record controls remain native and keyboard operable; foreign or missing IDs keep the same non-disclosing unavailable copy.
- Read outcomes now distinguish optional package absence, operational failures, successful empty results, filter no-match, and out-of-range pages. Summary and timeline failures no longer fabricate zero counts or empty history.
- Connection failures are sanitized at a small Admin boundary while unrelated exceptions remain visible to maintainers.

## Task Commits

1. **Task 1: Open one exact inbound record and return to its result context** — `4312abee` (RED), `03ec82c3` (GREEN)
2. **Task 2: Show collection and read states from their actual source** — `ed13705e` (RED), `14ced523` (GREEN)

## Files Created/Modified

- `mailglass_admin/lib/mailglass_admin/inbound/read_result.ex` — Narrow classification for explicit gateway errors and database connection failures.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` — Independent typed read outcomes and cause-specific rendering.
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` — Honest unavailable and out-of-range collection states.
- `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex` — Distinct unavailable-read copy without changing missing/foreign-ID copy.
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` — Connected navigation, empty-state, paging, connection-failure, timeline-independence, and error-boundary coverage.

## Decisions Made

- Added `ReadResult.fetch/1` as a dependency-free internal seam so the narrow exception boundary is independently tested.
- Preserved each successful panel when another panel’s read fails; a failed timeline is never rendered as an empty timeline.
- A first-page recovery path omits the default `page=1` query parameter, preserving the existing canonical URL shape.

## Deviations from Plan

- Added `mailglass_admin/lib/mailglass_admin/inbound/read_result.ex` and recorded it in this PLAN’s `files_modified` and task file lists. The plan’s multiple read sites needed one reusable, directly testable boundary to ensure only the approved failures are classified.

**Total deviations:** 1 scope clarification; no dependency added.

## TDD Gate Compliance

- **Task 1 RED:** The exact-selection connected LiveView test failed because Quick view discarded the ID outside the loaded list page. GREEN passed in the focused suite.
- **Task 2 RED:** The gateway-unavailable connected LiveView test failed because the page presented the package as a successful empty Account. The original JUnit report and evidence record are retained under `artifacts/tdd-red/`; the classifier returned `RED_EVIDENCE_OK`. GREEN passed in the focused suite.

## Issues Encountered

- The first out-of-range link assertion expected a literal `page=1`; the existing path builder canonicalizes page one by omitting that default. The assertion now verifies that stale `page=99` is removed while the active provider filter remains. No unresolved issue remains.

## User Setup Required

None.

## Next Plan Readiness

Plan 170-01 is complete and its automated focused suite passes. Plan 170-02 and Plan 170-03 are the remaining independent plans in Wave 1.

---
*Phase: 170-inbound-investigation-and-recovery*
*Completed: 2026-10-09*
