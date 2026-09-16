---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 43
subsystem: maintainer-lifecycle-truth
tags: [maintaining, lifecycle-authority, provenance, documentation-contract, tdd]
status: complete
requires:
  - phase: 164-37
    provides: immutable active approval proposal and checkpoint
  - phase: 164-38
    provides: recoverable installation of the approved loader as the active external authority
provides:
  - current maintainer guidance bound to Plan 164-37 approval and Plan 164-38 installation
  - bounded historical provenance for the superseded Plan 164-23 loader generation
  - region-scoped executable enforcement of current versus historical authority
affects: [phase-164-verification, terminal-finalization, maintainer-runbook]
actuals:
  tokens: 1261
  tasks: 2
  commits: 4
plan_head_before: 33374bd581f4ee859fd4c7203593908981234ead
tech-stack:
  added: []
  patterns:
    - current lifecycle authority and superseded provenance live in separately extracted documentation regions
    - executable documentation contracts reject stale authority tokens from current guidance
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-43-SUMMARY.md
  modified:
    - MAINTAINING.md
    - test/mailglass/publish/maintaining_release_gate_contract_test.exs
key-decisions:
  - "Plan 164-37 is the sole current approval authority and Plan 164-38 is the sole current installed-loader authority."
  - "Plan 164-23 remains discoverable only as superseded earlier-generation installation provenance inside the historical boundary."
  - "Approval and installation readiness remain distinct from ordinary verification and terminal finalization."
patterns-established:
  - "Lifecycle region contract: independently extract current and historical sections, then assert positive ownership and negative stale-owner constraints within each region."
requirements-completed: [TRTH-01, TRTH-03]
coverage:
  - id: D1
    description: "Current Phase 164 maintainer guidance names Plan 164-37 approval, Plan 164-38 installation, the repository loader source, and the external installed path while excluding Plan 164-23."
    requirement: TRTH-01
    verification:
      - kind: integration
        ref: "test/mailglass/publish/maintaining_release_gate_contract_test.exs#current finalization guidance binds the active approval and installation authorities"
        status: pass
    human_judgment: false
  - id: D2
    description: "The historical boundary retains Plan 164-23 as superseded provenance and names Plans 164-37/164-38 as the exclusive current replacement pair."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "test/mailglass/publish/maintaining_release_gate_contract_test.exs#historical release procedures retain provenance without becoming current guidance"
        status: pass
    human_judgment: false
duration: 4m
completed: 2026-09-12
---

# Phase 164 Plan 43: Maintainer Lifecycle Authority Reconciliation Summary

**Current maintainer guidance now binds immutable approval to Plan 164-37 and installed-loader authority to Plan 164-38, while Plan 164-23 survives only as executable, bounded history.**

## Performance

- **Duration:** 4 minutes
- **Started:** 2026-09-12T03:23:12Z
- **Completed:** 2026-09-12T03:27:40Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced stale current Plan 164-23 ownership with the active Plan 164-37 approval and Plan 164-38 installation authorities, including the repository source and external mode-0500 executable relationship.
- Preserved Plan 164-23 as explicitly superseded earlier-generation installation provenance inside the existing historical boundary.
- Made current-versus-history ownership executable through separately scoped positive and negative assertions.

## Task Commits

Each TDD gate was committed atomically:

1. **Task 1 RED: Require active current finalization authorities** — `a5c443b5` (test)
2. **Task 1 GREEN: Bind active approval and installation authorities** — `52a78a5a` (feat)
3. **Task 2 RED: Require bounded superseded loader provenance** — `588610a7` (test)
4. **Task 2 GREEN: Preserve Plan 164-23 as history** — `c3953146` (feat)

The plan metadata is committed separately after state synchronization.

## TDD Gate Compliance

- **Task 1 RED:** The targeted current-finalization test failed on the missing `Plan 164-37` assertion while the section still named Plan 164-23. The persisted evidence returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Task 1 GREEN:** The current section named Plans 164-37/164-38, the repository source, and external installed path; the focused suite passed 5 tests with 0 failures.
- **Tracer feedback gate:** The automated-only verification was rerun after Task 1 and passed 5 tests with 0 failures before expansion.
- **Task 2 RED:** The targeted historical-boundary test failed because Plan 164-23 was absent from that region. The persisted evidence returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Task 2 GREEN:** The bounded historical region retained Plan 164-23 with supersession semantics and the focused suite passed 5 tests with 0 failures.
- **REFACTOR:** No separate refactor was needed; the final contract and `git diff --check` remained green.

## Files Created/Modified

- `MAINTAINING.md` — binds the active approval/install pair and preserves the prior loader generation as bounded history.
- `test/mailglass/publish/maintaining_release_gate_contract_test.exs` — extracts lifecycle regions and enforces positive current/history ownership plus negative stale-current ownership.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-43-SUMMARY.md` — records execution, TDD, and verification evidence.

## Decisions Made

- The current operational pair is exactly Plan 164-37 approval followed by Plan 164-38 installation; neither repository tests nor installed readiness establish terminal proof.
- Plan 164-23 remains durable evidence of a formerly authoritative loader generation, but cannot authorize current lifecycle actions.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- A supplemental acceptance-check command initially selected an unavailable Ruby executable. The plan's ExUnit verification had already passed; the same region checks were rerun with the available Perl runtime and passed. No production or contract change was required.

## Authentication Gates

None.

## Known Stubs

None.

## User Setup Required

None.

## Verification

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs --warnings-as-errors --no-deps-check` — 5 tests, 0 failures, 0 SuiteFloor violations.
- Region-scoped acceptance script — current and historical ownership boundaries passed.
- `git diff --check` — passed.

## Next Phase Readiness

- The stale maintainer-authority gap from ordinary verification is closed and ready for Phase 164 re-verification.
- Other gap-closure plans and the separately ordered terminal lifecycle remain outside this plan; no completion-only or terminal evidence was advanced.

## Self-Check: PASSED

- Both modified contract files and this summary exist.
- Task commits `a5c443b5`, `52a78a5a`, `588610a7`, and `c3953146` resolve to committed objects.
- The focused contract passes after all tracked task changes.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-12*
