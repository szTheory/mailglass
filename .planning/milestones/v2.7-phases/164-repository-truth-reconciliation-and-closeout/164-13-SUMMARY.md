---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 13
subsystem: repository-truth-testing
tags: [elixir, exunit, repository-truth, closeout, adversarial-testing]
requires:
  - phase: 164-12
    provides: non-circular pre-verification evidence and corrected CI provenance validation
provides:
  - tagged exact-one ledger mutation matrix against the production validator
  - tagged canonical-identity, output-boundary, and late-dirt closeout process matrix
affects: [164-14, phase-verification, TRTH-02, TRTH-03]
actuals:
  tokens: 3494
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [production-seam mutation fixtures, process-level preflight markers, write-boundary dirt injection]
key-files:
  created: []
  modified:
    - test/scripts/phase_164_repository_truth_test.exs
    - test/scripts/phase_164_closeout_test.exs
key-decisions:
  - "Production behavior from Plans 164-08 through 164-11 remains unchanged; Plan 164-13 locks it through named hostile fixtures rather than adding another parser or closeout seam."
  - "Late-dirt regressions inject observable untracked files at exact stable-porcelain call boundaries so a clean preflight can never stand in for post-write state."
patterns-established:
  - "Gap-closure suites use the phase_164_gap_closure tag and prove non-vacuous selection through focused commands."
  - "Preflight rejection tests pair nonzero status with an untouched collection marker or external sentinel."
requirements-completed: [TRTH-02, TRTH-03]
coverage:
  - id: D1
    description: "The production ledger validator rejects forged enums, stale retain rows, vacuous or incomplete inventories, and duplicate subjects while preserving set-based ordering semantics."
    requirement: TRTH-02
    verification:
      - kind: integration
        ref: "mix test test/scripts/phase_164_repository_truth_test.exs --only phase_164_gap_closure --warnings-as-errors --no-deps-check"
        status: pass
    human_judgment: false
  - id: D2
    description: "The closeout process rejects alternate identities and hostile destinations before collection, and late component/report dirt always forces a blocked verdict."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix test test/scripts/phase_164_closeout_test.exs --only phase_164_gap_closure --warnings-as-errors --no-deps-check"
        status: pass
      - kind: other
        ref: "bash -n scripts/closeout_repository_truth.sh scripts/finalize_phase_164.sh"
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-09-08
status: complete
---

# Phase 164 Plan 13: Repository Truth Adversarial Regression Summary

**Named production-seam regressions now lock exact-one ledger semantics, canonical closeout identity, ignored output containment, and post-write cleanliness precedence.**

## Performance

- **Duration:** 6 minutes
- **Started:** 2026-09-08T19:44:19Z
- **Completed:** 2026-09-08T19:50:04Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added four tagged production-validator tests covering exact currentness membership, stale disposition semantics, every audited inventory class, adjacent/separated duplicates, and deterministic row reordering.
- Added four tagged process tests covering disposable and forged repository identities, copied and semantically invalid ledgers, lexical/output/symlink escapes, and pre-collection marker safety.
- Added deterministic component-write and first-report-write dirt injection that persists an untracked sentinel and proves `post_write_porcelain_dirty` has non-pass precedence.

## Task Commits

Each task was committed atomically:

1. **Task 1: Trace forged and incomplete ledger bytes through the production validator** — `695f0d0b` (`test`)
2. **Task 2: Exercise canonical identity and post-write cleanliness through the closeout process** — `177f1fd2` (`test`)

## Files Created/Modified

- `test/scripts/phase_164_repository_truth_test.exs` — Tagged exact enum, completeness, duplicate, and order-invariance regression matrix.
- `test/scripts/phase_164_closeout_test.exs` — Tagged hostile identity, ledger, destination, symlink, and late-dirt process matrix.

## Decisions Made

- Kept the already-correct production validator and closeout scripts unchanged; every new assertion executes those production seams directly.
- Treated copied-complete ledger bytes separately from semantic corruption: the validator accepts equivalent valid bytes, while closeout still rejects the non-authoritative path identity before collection.
- Used stateful command stubs only to control observation timing; the closeout process still creates its real report/components and persists a real untracked dirt sentinel.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The user-owned `.tool-versions` edit currently selects no installed Elixir version. Verification used installed Elixir `1.19.5-otp-28` with Erlang `28.4.1` through per-command ASDF environment variables; `.tool-versions` remained untouched and unstaged.
- The focused suite retained one pre-existing skipped test and emitted the existing optional OTLP-exporter warning; neither was introduced by this plan or affected the 89 executed passing tests.

## TDD Gate Compliance

- The initial tagged commands selected zero tests, establishing the missing non-vacuous regression path.
- Both tasks were test-only gap-closure work against production behavior already implemented by Plans 164-08 through 164-11, so no production `feat` commit was necessary or fabricated.

## Verification

- Tagged ledger group: 4 tests, 0 failures.
- Tagged closeout group: 4 tests, 0 failures; Bash syntax passed.
- Complete focused Phase 164 suite: 90 tests, 0 failures, 1 pre-existing skip (89 executed).
- `mix format --check-formatted` passed for the production validator and both changed contracts.
- Authoritative production ledger CLI printed `repository truth ledger: valid`.
- `git diff --check` passed.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 164-14 can rerun the full contract and closeout proof with every verifier attack now represented by a named executable fixture. No blocker remains from this plan.

## Self-Check: PASSED

- Both modified test files exist and contain non-vacuously selected `phase_164_gap_closure` groups.
- Task commits `695f0d0b` and `177f1fd2` exist in Git history.
- All task, acceptance, and plan-level verification commands passed in this execution session.
- No goal-blocking stub, new skipped test, unrun verification, production threat surface, or unrelated file change was introduced.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-08*
