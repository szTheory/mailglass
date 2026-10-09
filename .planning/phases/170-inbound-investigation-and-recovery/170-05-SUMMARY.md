---
phase: 170-inbound-investigation-and-recovery
plan: "05"
subsystem: inbound-operator-ui
tags: [elixir, phoenix-liveview, inbound, execution-history, outcomes]

# Dependency graph
requires:
  - phase: 170-01
    provides: Tenant-scoped inbound selection and read-state contracts
  - phase: 170-02
    provides: Persisted explicit Mailbox :no_change outcome
  - phase: 170-04
    provides: Latest-fresh list/detail projection and chronological timeline data
provides:
  - Consistent collection, detail, filter, and timeline vocabulary for stored outcomes
  - Explicit display states for missing history, no match, and failed execution
  - Timeline outcome labels without free-form failure/exception details
affects: [inbound-investigation, INUX-02, INUX-04]

# Actuals
duration: 13min
tasks: 2
commits: 4
files: 15

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Render :no_change as a distinct neutral result while keeping :ignore labeled Ignored."
    - "Map nil latest-fresh outcome to a display-only missing-history state; reserve No match for :no_match."
    - "Render only allowlisted timeline outcome vocabulary and omit free-form outcome_reason/failure detail."

key-decisions:
  - "A missing ExecutionRun is labeled No history and No execution recorded; it is not a no-match result."
  - "An absent mailbox on a failed execution is Unavailable; only :no_match produces No match."
  - "Timeline labels are explicit for accept, ignore, no_change, no_match, reject, bounce, and failed."
  - "Free-form outcome_reason and failure metadata are not rendered in the operator timeline."
  - "No dependency or lockfile changes were needed."

requirements-completed: [INUX-02, INUX-04]

# Coverage metadata
coverage:
  - id: D1
    description: "Inbound collection distinguishes the latest-fresh no_match, accept, ignore, no_change, reject, bounce, failed, and missing-history states; explicit no-change filtering remains separate from ignore."
    requirement: INUX-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#filters an explicit no-change run without including an ignored run"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/components_test.exs#RecordsList.records_list/1 renders an explicit no-change outcome separately from other outcomes"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/components_test.exs#RecordsList.records_list/1 renders no history when the record has no execution run yet"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/components_test.exs#RecordsList.records_list/1 does not label a failed execution as no match"
        status: pass
    human_judgment: false
  - id: D2
    description: "Detail and timeline preserve mailbox result, source, run ID, exact timestamp, and chronological order while distinguishing no-change from ignore and withholding raw failure reasons."
    requirement: INUX-04
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/components_test.exs#DetailHeader.detail_header/1 shows missing history separately from no match"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/components_test.exs#Timeline.timeline/1 labels no-change separately from ignore and preserves chronological run identity"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/components_test.exs#Timeline.timeline/1 never renders raw execution failure reasons"
        status: pass
    human_judgment: false

# Commits
task_commits:
  - "0db58cdc test(170-05): add failing tests for explicit no-change outcomes"
  - "71d3681c feat(170-05): display explicit no-change and history states"
  - "9035e57e test(170-05): add failing tests for detail and timeline vocabulary"
  - "0e95c436 feat(170-05): clarify detail and timeline outcomes"

# Files
files_created: []
files_modified:
  - .planning/phases/170-inbound-investigation-and-recovery/170-05-PLAN.md
  - .planning/phases/170-inbound-investigation-and-recovery/artifacts/tdd-red/170-05-task1-junit.xml
  - .planning/phases/170-inbound-investigation-and-recovery/artifacts/tdd-red/170-05-task1-red.json
  - .planning/phases/170-inbound-investigation-and-recovery/artifacts/tdd-red/170-05-task2-junit.xml
  - .planning/phases/170-inbound-investigation-and-recovery/artifacts/tdd-red/170-05-task2-red.json
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound/timeline.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/test/mailglass_admin/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
  - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
  - mailglass_admin/test/support/inbound_fixtures.ex

# Plan 05: Stored outcome and history presentation

**The Admin UI now shows explicit no-change, missing-history, failed, and chronological outcome states without inventing provider-delivery claims or exposing raw failure details.**

## Performance

- **Duration:** 13 min.
- **Started:** 2026-10-09T02:44:00Z.
- **Completed:** 2026-10-09T02:57:00Z.
- **Tasks:** 2.
- **Files changed:** 15.

## Accomplishments

- Added `:no_change` to the closed LiveView outcome filter set and neutral badge vocabulary; `:ignore` remains Ignored.
- Made `:no_match`, failed execution without a mailbox, and absent execution history render as distinct facts. Nil latest-fresh outcome maps to the display-only No history state, and missing mailboxes no longer imply No match.
- Kept long and non-ASCII list values available in row/card markup and titles while preserving recipient masking.
- Aligned detail and timeline outcome labels, retained fresh/replay source, run IDs, exact timestamps, and input chronological order, and removed free-form outcome reason rendering.
- Updated filter help to identify the latest fresh mailbox outcome, including explicit no-change.

## Task Commits

1. **Task 1 RED / GREEN:** `0db58cdc` and `71d3681c`. RED evidence classified `RED_EVIDENCE_OK`; seven planned assertions failed. GREEN passed the 203-test focused suite.
2. **Task 2 RED / GREEN:** `9035e57e` and `0e95c436`. RED evidence classified `RED_EVIDENCE_OK`; five planned assertions failed. GREEN passed all 28 focused component tests.

The complete reports and semantic assessments are preserved under `artifacts/tdd-red/`.

## Automated Verification

- Combined Plan 05 suite: 207 tests, 0 failures (`inbound_live_test.exs`, inbound `components_test.exs`, shared `components_test.exs`).
- Task 2 component suite: 28 tests, 0 failures.
- Formatter check and `git diff --check` passed.
- The suite emitted the existing Boundary reference warning and local Oban-unavailable warnings; no warning or dependency was changed as part of this plan.

## Deviations and Issues

- Updated existing LiveView routing/evidence assertions to match Plan 03's shipped safe copy and redaction behavior; this keeps the planned focused suite valid without undoing that work.
- The local `mailglass_inbound` source already declares `:no_change`, while the cached test build initially had the older enum. Rebuilt only that local dependency in `MIX_ENV=test`; no dependency declaration or lockfile changed.
- Focused runs use the pinned Erlang/Elixir toolchain and `--no-deps-check` because the existing Dialyxir checkout differs from the lockfile, as documented by earlier plans.

## User Setup Required

None. Plan 08 owns the connected and rendered inbound acceptance checks; this plan has automated coverage for its component and LiveView contracts.

## Next Plan Readiness

- Plan 170-06 is Wave 4 and depends on Plans 01, 02, 04, and 05; those plans are complete.
- INUX-02 and INUX-04 remain shared across later Plan 08 coverage and are not globally marked complete until the requirements readiness gate allows it.

## Self-Check: PASSED

- Both RED reports are current, complete JUnit documents and were classified `RED_EVIDENCE_OK` before GREEN.
- Both TDD gate pairs are in history and the final combined Plan 05 suite passes.
- No runtime UAT or human verification is required by this plan.

---
*Phase: 170-inbound-investigation-and-recovery*
*Completed: 2026-10-09*
