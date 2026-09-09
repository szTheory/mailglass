---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 15
subsystem: repository-truth-finalization
tags: [git, bash, jq, exunit, evidence-integrity, temporal-validation]
requires:
  - phase: 164-14
    provides: exact protected-main pre-verification evidence and terminal lifecycle handoff
provides:
  - verifier-to-terminal binding through an explicit verified implementation SHA and per-commit first-parent allowlist
  - complete Plans 01-13 pre-verification prerequisites and token-owned hostile fixture teardown
  - two-sided scheduled timestamp validation at producer and independent finalizer seams
affects: [phase-verification, terminal-finalization, TRTH-01, TRTH-02, TRTH-03]
actuals:
  tokens: 8810
  tasks: 3
  commits: 7
tech-stack:
  added: []
  patterns: [first-parent per-commit history validation, exclusive token-owned test fixtures, closed-interval evidence freshness]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-15-SUMMARY.md
  modified:
    - scripts/finalize_phase_164.sh
    - scripts/scheduled_control_evidence.sh
    - scripts/validate_repository_truth.exs
    - test/scripts/phase_164_closeout_test.exs
    - test/scripts/scheduled_control_evidence_test.exs
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-VALIDATION.md
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv
key-decisions:
  - "Terminal authority inspects every commit after verified_implementation_sha relative to its first parent, preserving forbidden change-then-revert history without traversing unrelated second-parent history."
  - "Scheduled freshness is the closed interval from zero through each tracked registry maximum; malformed and negative ages have no clock-skew exception."
  - "Out-of-root hostile fixtures are recursively removed only while exclusive allocation, lstat identity, resolved parent, exact basename, and invocation token all remain valid."
patterns-established:
  - "Verification applicability is an explicit commit identity plus an exact per-commit metadata path allowlist."
  - "Destructive test teardown requires independently retained ownership evidence at cleanup time."
requirements-completed: [TRTH-01, TRTH-02, TRTH-03]
coverage:
  - id: D1
    description: "Terminal finalization accepts a passing verifier only when its exact implementation SHA is an ancestor and every later first-parent commit changes only four named completion-metadata paths."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_closeout_test.exs#terminal verifier authority and forbidden-history regressions"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pre-verification requires summaries through Plan 13 and hostile lexical-prefix fixtures cannot delete pre-existing, symlinked, or token-replaced paths."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_closeout_test.exs#complete-summary and owned-cleanup regressions"
        status: pass
    human_judgment: false
  - id: D3
    description: "Scheduled evidence rejects malformed, future, and stale timestamps independently at both producer and terminal raw-source validation boundaries."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "test/scripts/phase_164_closeout_test.exs and test/scripts/scheduled_control_evidence_test.exs#two-sided freshness regressions"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-09-09
status: complete
---

# Phase 164 Plan 15: Terminal Evidence Integrity Summary

**Terminal closeout is bound to the verified implementation history, complete repair prerequisites, ownership-safe hostile fixtures, and temporally possible scheduled evidence.**

## Performance

- **Duration:** 18 minutes
- **Started:** 2026-09-09T20:44:13Z
- **Completed:** 2026-09-09T21:02:02Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Required a single full lowercase `verified_implementation_sha`, proved it exists and is an ancestor, and inspected every intervening first-parent commit against the four exact completion-metadata paths.
- Extended pre-verification through `164-13-SUMMARY.md` and replaced unsafe sibling teardown with exclusive, token-bound ownership checks that fail visibly without deleting an unowned path.
- Enforced `0 <= now - updated_at <= max_age_seconds` at both scheduled-evidence boundaries without changing registry ages, provenance, workflow behavior, or release authority.
- Expanded `164-VALIDATION.md` through Plan 164-15 with commands, assets, observable failure directions, and T-164-53 through T-164-57 mappings.

## Task Commits

Each TDD task was committed through explicit RED and GREEN gates:

1. **Task 1: Trace a verified implementation SHA through terminal HEAD authorization** — `bd005650` (RED), `caec1c4f` (GREEN)
2. **Task 2: Require the complete repair summary set and contain hostile fixture cleanup** — `6f5eb7fc` (RED), `b8cb8c55` (GREEN)
3. **Task 3: Reject invalid and future timestamps at both scheduled-evidence boundaries** — `7490f338` (RED), `8e4ef450` (GREEN)
4. **Rule 2 ledger correction:** `6765b3ca` (fix)

## Files Created/Modified

- `scripts/finalize_phase_164.sh` — Hash-bound terminal history, complete pre-verification prerequisites, and independent closed-interval freshness.
- `scripts/scheduled_control_evidence.sh` — Fail-closed timestamp parsing and two-sided registry-bounded age enforcement.
- `test/scripts/phase_164_closeout_test.exs` — Isolated Git history, missing-summary, owned-cleanup, and finalizer timestamp regressions.
- `test/scripts/scheduled_control_evidence_test.exs` — Producer-boundary invalid, future, current, in-range, and stale timestamp fixtures.
- `scripts/validate_repository_truth.exs` and `164-TRUTH-DISPOSITION.tsv` — Canonical exact-one relationship for the durable Phase 164 validation artifact.
- `164-FINALIZATION.md` and `164-VALIDATION.md` — Matching lifecycle, command, asset, threat, and terminal-gate contracts.

## Decisions Made

- Used a per-first-parent-commit path inspection rather than an endpoint tree diff so a forbidden change followed by its revert remains terminally disqualifying.
- Kept merge evaluation bounded to the merge result relative to its first parent, avoiding rejection based only on unrelated second-parent ancestry.
- Applied no clock-skew allowance: future evidence is impossible under the established contract and fails closed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added the newly audited validation artifact to the exact-one repository-truth contract**
- **Found during:** Task 1 full verification
- **Issue:** Plan 164-15 made `164-VALIDATION.md` an audited modified artifact, but the authoritative ledger and canonical relationship map did not yet classify it, causing the production validator to report `missing_audited_subjects`.
- **Fix:** Added retained disposition `M-23` and its canonical relationship digest without weakening any inventory or enum check.
- **Files modified:** `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv`, `scripts/validate_repository_truth.exs`
- **Verification:** The authoritative CLI prints `repository truth ledger: valid`; the complete focused suite passes.
- **Committed in:** `6765b3ca`

**Total deviations:** 1 auto-fixed (1 missing critical functionality).
**Impact on plan:** The correction is required to keep TRTH-02's exact-one ledger truthful after adding the planned validation artifact; no inventory, release, workflow, or authority boundary was broadened.

## Issues Encountered

- `.tool-versions` selects unavailable Elixir/Erlang versions in this checkout. Verification used the already-installed Elixir `1.19.5-otp-28` and Erlang `28.4.1` through per-process ASDF variables; project version files were not changed.
- The focused suite retains one pre-existing historical skip and the existing optional OTLP-exporter warning. Neither was introduced by Plan 164-15 or supplies sole requirement coverage.

## TDD Gate Compliance

- Task 1 RED failed on absent/malformed verifier identities, forbidden post-verification history, and missing lifecycle documentation; GREEN passed 26 closeout tests.
- Task 2 RED failed when missing `164-13-SUMMARY.md` still allowed collection; GREEN passed 28 closeout tests with owned-teardown regressions.
- Task 3 RED failed because future timestamps passed both production seams; GREEN passed the combined 38-test closeout/scheduled suite.

## Verification

- Complete focused Phase 164 suite: 96 tests, 0 failures, 1 pre-existing skip (95 executed).
- Authoritative ledger CLI: `repository truth ledger: valid`.
- Changed Elixir test formatting: passed.
- Finalizer, scheduled-evidence, and tracked finalizer-shim Bash syntax: passed.
- `git diff --check`: passed.

## Known Stubs

None.

## Threat Flags

None — the changes tighten existing Git-history, test-filesystem, and scheduled-evidence trust boundaries without adding a network endpoint, authentication path, schema, workflow operation, or release authority.

## User Setup Required

None.

## Next Phase Readiness

- All planned Phase 164 implementation and regression gaps are closed with automated evidence.
- The ordinary verifier must record the exact evaluated implementation commit in `verified_implementation_sha`; after all tracked completion metadata reaches protected `main`, the separate `/finalize-phase 164` terminal capture remains required and permits no later tracked commit.

## Self-Check: PASSED

- All eight production, test, lifecycle, validation, and ledger files exist.
- All seven task/deviation commits are present in Git history.
- Every task verification and plan-level acceptance command passed in this execution session.
- No goal-blocking stub, new skipped test, unrun verification, or unplanned threat surface remains.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-09*
