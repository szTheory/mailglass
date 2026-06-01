---
phase: 68-realistic-b2b-saas-fixtures
plan: "01"
subsystem: testing
tags: [demo-data, deterministic-fixtures, inbound-replay, quick-gate]
requires:
  - phase: 67-demo-app-foundation
    provides: deterministic demo app reset + seed wiring
provides:
  - deterministic six-outbound/four-inbound Northstar fixture corpus
  - named-scenario reset contract assertions
  - repo-root quick validation wrapper for demo fixture tests
affects: [phase-68-plan-02, phase-69, phase-70]
tech-stack:
  added: []
  patterns: [scenario-first fixture seeding, stored-truth replay lineage, root nested Mix gate]
key-files:
  created: [test/mailglass/demo_data_test.exs]
  modified:
    - reference/demo_app/lib/mailglass_demo/demo_data.ex
    - reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs
key-decisions:
  - "Keep reset flow as truncate -> seed_outbound! -> seed_inbound! with explicit seven-table truncate scope."
  - "Model inbound replay as execution-run lineage over one stored record/evidence pair per story."
patterns-established:
  - "Fixture identity is scenario-first via explicit scenario metadata and fixed provider IDs."
  - "Repo-root quick gate delegates into reference/demo_app with System.cmd and MIX_ENV=test."
requirements-completed: [DATA-01, DATA-02, DATA-03]
duration: 7min
completed: 2026-06-01
---

# Phase 68 Plan 01: Realistic B2B SaaS Fixtures Summary

**Deterministic Northstar fixture corpus now seeds six outbound and four inbound named stories with replay lineage plus a repo-root quick gate.**

## Performance

- **Duration:** 7 min
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Expanded `MailglassDemo.DemoData` with exactly the required outbound/inbound IDs, webhook IDs, suppression-linked incident story, and execution matrix.
- Strengthened `MailglassDemo.DemoDataResetTest` to assert deterministic named scenario contracts (counts, IDs, suppression tuple, execution matrix).
- Added repo-root `test/mailglass/demo_data_test.exs` wrapper that runs demo app `ecto.create`, `ecto.migrate`, and `mix test test/mailglass_demo/*.exs --warnings-as-errors`.

## Task Commits
1. **Task 1: Expand deterministic outbound/inbound corpus** - `71ef999` (feat)
2. **Task 2: Determinism assertions + root quick gate** - `ad4d0d8` (test)

## Files Created/Modified
- `reference/demo_app/lib/mailglass_demo/demo_data.ex` - scenario corpus, webhook/suppression/inbound execution lineage.
- `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs` - named fixture contract assertions.
- `test/mailglass/demo_data_test.exs` - repo-root nested Mix quick gate.

## Decisions Made
- Kept truncate list explicit and scoped to seven Mailglass demo tables.
- Preserved `InboundRecords.insert_*` write seam and avoided duplicate inbound-record inserts for replay.

## Verification Results
- `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/demo_data_reset_test.exs --warnings-as-errors` ✅
- `mix test test/mailglass/demo_data_test.exs` ✅
- `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/*.exs --warnings-as-errors` ✅
- `mix test` ✅ (1163 tests, 0 failures, 7 skipped)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated stale reset counts immediately after fixture expansion**
- **Found during:** Task 1 verification
- **Issue:** Existing deterministic test still asserted old 3/6/2/2/3 row counts, causing Task 1 verify failure.
- **Fix:** Updated baseline count assertions to new deterministic corpus values before continuing.
- **Files modified:** `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs`
- **Verification:** Task 1 demo-app verify command passed after patch.
- **Committed in:** `71ef999`

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** No scope creep; required to satisfy Task 1 verification gate after intended corpus growth.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
Phase 68-02 can build preview-scenario and message-contract assertions on a deterministic seeded corpus with an existing root quick gate.

## Self-Check: PASSED
