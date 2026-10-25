---
phase: 170-inbound-investigation-and-recovery
plan: "07"
subsystem: admin-ui
tags: [inbound, replay, liveview, timeline]
requires:
  - phase: 170-03
    provides: Explicit inbound no-change outcome and persisted run projection
  - phase: 170-06
    provides: Exact replay review eligibility and revalidation before host authorization
provides:
  - Single-use local replay review confirmation with result-specific feedback
  - Independent command feedback and scoped timeline snapshot refresh
affects: [170-08]
tech-stack:
  added: []
  patterns: [consumed-review-guard, scoped-timeline-snapshot]
key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/mailglass_admin/inbound/replay_modal_test.exs
decisions:
  - Replay review identifiers are consumed server side; busy wording describes only local in-flight work.
  - Replay outcome feedback is derived from the returned structured result and remains separate from later timeline reads.
  - Selected history is labeled through its last successful scoped read and refreshed through an explicit native control.
metrics:
  duration: 6m
  completed_date: 2026-10-09
  tasks: 2
  files: 3
  commits: 3
plan_head_before: 9fd872f8fd66a13c48b131e5767342eece6a90cd
plan_head_after: bb729798abda76cb00ba72969f1ee722b9cb8ac6
status: complete
actuals:
  tokens: 5415
  tasks: 2
  commits: 3
---

# Phase 170 Plan 07: Truthful Replay Feedback and History Summary

Inbound replay now consumes one server-side review identifier per confirmation and reports the structured command result independently from the selected record’s later history read.

## Completed Tasks

| Task | Name | Commit | Files |
| --- | --- | --- | --- |
| 1 | Guard one local confirmation and report the command's actual result | `47c0e7fd` | `inbound_live.ex`, `inbound_live_test.exs` |
| 2 | Show scoped terminal history only when its refresh succeeds | `bb729798` | `inbound_live.ex`, `inbound_live_test.exs` |

The RED test contract was committed first as `04021312`.

## Implementation

- A reviewed confirmation receives a unique local identifier. Confirmation consumes it before revalidation, authorization, and replay; repeated events cannot call replay again. The existing `phx-disable-with` remains immediate local feedback and no distributed lock or retry claim is introduced.
- A returned run is described separately from its Mailbox outcome, including explicit `No change` and recorded execution failure. A pre-run error says no run was recorded, and requested/queued wording is emitted only for an explicit runtime status.
- Replay status uses an always-rendered polite live region with error styling. Existing modal close, cancel, focus containment, and focus return remain in place.
- A successful tenant-scoped timeline read is timestamped as a snapshot. A native refresh reads only the selected record’s scoped timeline; an unavailable refresh preserves the command result, marks history unavailable, and retains the last successful snapshot timestamp.

## Verification

- RED: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/replay_modal_test.exs --seed 1` failed on the new result copy, absent feedback region, and missing snapshot/refresh behavior.
- Task 1 focused run: the same command passed with 80 tests and 0 failures.
- Task 2 focused run: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_admin/inbound_live_test.exs --seed 1` passed with 79 tests and 0 failures.
- Final focused run: the same two-file command passed with 82 tests and 0 failures.
- Existing unrelated warnings remain: a forbidden-reference warning in `test/support/operator_fixtures.ex` and optional Oban fallback notices.
- No human-only verification was required for this plan. Plan 08 owns browser verification of visible busy/status/focus behavior.

## Deviations from Plan

None. No dependencies were added. Plan 06’s exact eligibility revalidation remains before host authorization.

## Auth Gates

None.

## Known Stubs

None found in the Plan 07 changed implementation and tests.

## Threat Surface Scan

No new network endpoint, authorization path, file access pattern, or trust-boundary schema was introduced. Timeline refresh continues through the existing tenant-scoped gateway.

## User Setup Required

None.

## Next Phase Readiness

Plan 07 is complete. Plan 08 can verify the visible confirmation feedback and focus behavior in a browser.

## Self-Check: PASSED

- Summary and all declared source artifacts exist.
- Task commits `04021312`, `47c0e7fd`, and `bb729798` exist and are ancestors of the current checkout.
- Measured commit count is 3 from `plan_head_before` through `plan_head_after`.
