---
phase: 178-preview-authoring-and-milestone-review
plan: "33"
subsystem: testing
tags: [elixir, ecto, mailglass-clock, deterministic-tests, inbound]
requires:
  - phase: 178
    provides: Cycle 07 stop and fixed-date persisted Inbound scenarios
provides:
  - Inbound page/provider time windows derive their cutoffs from Mailglass.Clock.
  - Fixed-date persisted Inbound projections run deterministically under the existing 168-hour filter.
  - Direct coverage that the records page window filters both returned entries and total_count.
affects: [178-23, 178-24, UIQ-08]
actuals:
  tokens: 3501
  tasks: 3
  commits: 1
commits: 1
plan_head_before: c5172ca6ea87c4cae6add0dd3c250a6c5462c9c8
plan_head_after: 8f2afc92
tech-stack:
  added: []
  patterns:
    - Use the shared process-local Mailglass.Clock freeze for stable query-window tests.
key-files:
  created:
    - .planning/phases/178-preview-authoring-and-milestone-review/178-33-SUMMARY.md
  modified:
    - mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex
    - mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs
    - mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs
    - .planning/STATE.md
    - .planning/ROADMAP.md
key-decisions:
  - Keep the production default at 168 hours and preserve explicit positive-window and invalid-filter behavior.
  - Keep scenario timestamps and dependency locks unchanged; freeze test time at scenario time plus 24 hours.
  - Cycle 07 remains stopped; no new hosted or preview authority is implied by local validation.
requirements-completed: [UIQ-04, STORY-07]
coverage:
  - id: D1
    description: Inbound records page applies its time window to entries and total_count.
    requirement: UIQ-04
    verification:
      - kind: unit
        ref: mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs#time window excludes old rows from both entries and total_count
        status: pass
    human_judgment: false
  - id: D2
    description: Persisted fixed-date Inbound projection scenarios remain within the 168-hour filter under a frozen clock.
    requirement: STORY-07
    verification:
      - kind: integration
        ref: mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs#normal Inbound facts match the scoped production projection at position 3 of 6
        status: pass
      - kind: integration
        ref: mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs#Unicode Inbound facts stay exact and foreign Account rows remain excluded
        status: pass
    human_judgment: false
duration: about 10min
completed: 2026-11-02
status: complete
---

# Phase 178 Plan 33: Deterministic Inbound Projection Summary

**Inbound records now use the shared application clock for window cutoffs, keeping fixed-date projections stable and proving filtered page counts.**

## Performance

- **Duration:** About 10 minutes; the runtime did not capture the exact start timestamp.
- **Completed:** 2026-11-02T16:49:29Z.
- **Tasks:** 3/3 implementation and validation tasks completed locally.
- **Files modified:** 3 scoped source/test files; this summary and plan tracking are separate local commits.

## Accomplishments

- Changed the default and explicit positive inbound record window cutoffs to use `Mailglass.Clock.utc_now/0`, matching the Delivery read-model convention. The 168-hour default, positive-window semantics, invalid-filter behavior, tenant scope, and query shape remain unchanged.
- Froze the two persisted Inbound projection tests at 24 hours after each scenario's fixed `received_at`, retaining their existing 168-hour production filter and source scenario facts.
- Added a direct `Records.list_records_page/2` test with a record 6 hours old and one 48 hours old under a 24-hour window. It proves both the entries and `total_count` exclude the old row.
- The source scenario JSON and both dependency lockfiles are unchanged. No hosted, Docker, preview, PR, dispatch, retry, rerun, merge, release, or deployment action occurred.

## Verification

Commands ran from each package directory with the installed Elixir 1.18.4 / OTP 27 runtime selected explicitly (`ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.13`):

- `mix test test/mailglass_inbound/internal/operator/records_test.exs` — **41 tests, 0 failures**.
- `mix test test/mailglass_admin/quick_view_projection_test.exs` — **25 tests, 0 failures**.
- `mix test --warnings-as-errors` in `mailglass_admin` — **1,205 tests, 0 failures, 1 excluded**.
- `git diff --check` on all three source/test files — passed.
- Confirmed `records.ex` contains both `Mailglass.Clock.utc_now/0` cutoffs and no direct `DateTime.utc_now/0`; scenario JSON and lockfiles have no diff.

The full suite emitted existing deprecation warnings from `mix_config_test.exs` and logged expected synthetic LiveView failure-path errors; the command exited successfully with warnings-as-errors enabled.

## Task Commits

1. **Task 33-01/02: Shared clock and deterministic window tests** — `8f2afc92` (`fix(inbound): use shared clock for operator windows`).

The commit is on local branch `gsd/phase178-cycle08-local`; no remote ref changed. The candidate SHA for a new hosted cycle is not frozen yet because the next cycle's updated recovery plans and exact-SHA packet still need to be committed and prepared.

## Decisions Made

- Keep the existing production window durations and invalid-window behavior intact; control only the clock source.
- Preserve the fixed scenario facts and make the test clock relative to each scenario timestamp.
- Keep the Cycle 07 stop intact. A later hosted candidate requires a fresh exact-SHA approval packet.

## Deviations from Plan

Per parent direction, the source/test implementation was committed after moving from protected `main` to a local feature branch. The plan summary and tracking metadata are recorded separately; no new hosted candidate SHA has been authorized or frozen.

## Issues Encountered

The package directories do not select the repository-root asdf pin automatically. The installed `1.18.4-otp-27` runtime was selected explicitly; no runtime or dependency installation was needed. All required local validation passed.

## User Setup Required

None.

## Next Phase Readiness

The local regression is fixed and the required Admin suite passes. Source commit `8f2afc92` is local on `gsd/phase178-cycle08-local`; Cycle 07 is still stopped, and any later hosted or preview action needs a new exact-SHA packet and approval.

## Self-Check: PASSED

All six scoped paths exist, implementation/test changes pass whitespace checks, and the source commit is recorded. The exact candidate SHA for a future hosted cycle remains to be frozen after the next-cycle plans are updated.

---
*Phase: 178-preview-authoring-and-milestone-review*
*Completed: 2026-11-02*
