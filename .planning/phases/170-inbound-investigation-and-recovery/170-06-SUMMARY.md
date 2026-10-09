---
phase: 170-inbound-investigation-and-recovery
plan: "06"
subsystem: inbound-replay
tags: [elixir, phoenix-liveview, ecto, tenant-scope, accessibility]

# Dependency graph
requires:
  - phase: 170-01
    provides: Account-scoped inbound detail and selected-record context
  - phase: 170-02
    provides: Explicit inbound execution outcomes
  - phase: 170-04
    provides: Tenant-scoped historical execution reads
  - phase: 170-05
    provides: Admin detail and timeline presentation
provides:
  - Tenant-scoped replay eligibility from stored evidence and execution history
  - Exact-record replay review with action-time revalidation before host authorization
affects: [170-07, 170-08, inbound-operator-workflows]

# Actuals (#2632)
actuals:
  tokens: 4100
  tasks: 2
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Runtime optional-dependency gateway for eligibility reads
    - Revalidate exact tenant/record/eligibility immediately before action authorization

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex
  modified:
    - mailglass_inbound/lib/mailglass_inbound/internal/replay.ex
    - mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/mailglass_admin/inbound/replay_modal_test.exs

key-decisions:
  - "Eligibility is a tenant-scoped projection of durable evidence/history and never rematches current router rules."
  - "The reviewed Account, record ID and Mailbox eligibility are re-read before host authorization; authorization remains directly before replay."
  - "Replay consequence copy names the recorded Mailbox with currently deployed code against stored data and rules out provider redelivery/current-router matching."

patterns-established:
  - "A disabled replay confirmation announces its typed eligibility reason in a polite status region."
  - "Foreign and missing record IDs share a non-disclosing result; stale review is rejected before host authorization."

requirements-completed: [INUX-04]

coverage:
  - id: D1
    description: "Eligibility reports the safely resolvable recorded Mailbox or a typed, tenant-scoped reason."
    requirement: INUX-04
    verification:
      - kind: unit
        ref: "mailglass_inbound/test/mailglass_inbound/replay_test.exs#eligibility/2"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/optional_deps/mailglass_inbound_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "The operator reviews the exact Account, record and recorded Mailbox before a fresh authorized replay."
    requirement: INUX-04
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#replay confirm flow (IADM-03)"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/replay_modal_test.exs"
        status: pass
    human_judgment: true
    rationale: "The LiveView tests assert modal focus-trap wiring and keyboard affordances; connected keyboard focus behavior is scheduled for the Phase 170 browser journey in Plan 08."

# Metrics
duration: 15min
completed: 2026-10-08
status: complete
---

# Phase 170 Plan 06: Durable Replay Eligibility and Exact-Target Confirmation Summary

**Tenant-scoped replay eligibility and exact-target revalidation now gate inbound replay before the existing host authorization seam.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-10-08T23:04:51-04:00
- **Completed:** 2026-10-08T23:19:55-04:00
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added a narrow internal eligibility read that distinguishes stored no-match, missing execution history, unsafe legacy binding, missing evidence, and an unavailable Mailbox without exposing raw evidence.
- Added the optional Admin gateway and verified the absent-inbound compile lane.
- Replaced the inbound replay dialog with an exact Account/record/Mailbox review, cause-specific disabled copy, Escape and visible Close/Cancel controls, and focus containment/return wiring.
- Confirmation re-reads the exact tenant-scoped record and eligibility, rejects changed reviews before host authorization, then authorizes the fresh record immediately before replay.

## Task Commits

1. **Task 1: Read scoped replay eligibility from durable inbound evidence** - `79f15a2c` (RED), `d614bb72` (GREEN)
2. **Task 2: Confirm the exact reviewed Mailbox target through action-time authorization** - `632c222c` (RED), `52fa06b2` (GREEN)

**Plan metadata:** pending.

## Files Created/Modified

- `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` - Tenant-scoped eligibility from stored binding, evidence and history.
- `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex` - Optional runtime eligibility gateway.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - Review snapshot, action-time reread and authorization order.
- `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` - Exact-target modal and eligibility reasons.
- `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex` - Corrected replay description to match stored-binding behavior.
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - Stale target, Account switch, duplicate event, denial and eligibility cases.
- `mailglass_admin/test/mailglass_admin/inbound/replay_modal_test.exs` - Dialog copy, identity and disabled-state checks.
- `mailglass_admin/test/support/endpoint_case.ex` - Test-only host authorization call tracking.
- `mailglass_admin/test/mailglass_admin/optional_deps/mailglass_inbound_test.exs` - Optional gateway coverage.
- `mailglass_admin/mix.exs` - Optional gateway warning configuration for the no-optional-dependency compile lane.

## Decisions Made

- Eligibility uses stored route binding and scoped history; it does not simulate current routing.
- The modal review is a snapshot, not authorization. Confirmation revalidates its tenant, record and eligibility before host authorization.
- The existing `:replay_inbound` Auth contract and tenant-scoped replay seam remain unchanged.

## Deviations from Plan

- Updated the detail header's stale “re-runs mailbox routing” description because it contradicted the corrected consequence shown in the modal.
- Fixed a nil-module guard in Mailbox discovery found while validating unavailable Mailbox behavior; in Elixir, `nil` is an atom and must be excluded explicitly.
- Added the optional gateway module to the existing no-warning configuration after the clean optional-dependency compile surfaced a warnings-as-errors failure.

**Total deviations:** 3 auto-fixed.
**Impact on plan:** Each change was needed to keep the replay contract accurate or preserve the existing optional-dependency build lane.

## Issues Encountered

- An isolated alternate build directory hit a pre-existing `premailex` build-path artifact issue. The repository's configured optional-dependency lane was then cleaned and rebuilt; it passed with warnings as errors and without the optional gateway beam.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 07 can add single-submit feedback and independently refreshed timestamped history on top of the exact-review contract.
- Plan 08 can verify actual keyboard focus behavior and the connected journey.

---
*Phase: 170-inbound-investigation-and-recovery*
*Completed: 2026-10-08*
