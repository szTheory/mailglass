---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 26
subsystem: immutable-finalization-authority
tags: [git, toolchain, path-hardening, provenance, repository-truth]
requires:
  - phase: 164-25
    provides: hermetic required-CI boundary and controlled-host production checks
provides:
  - canonical physical repository and normalized origin authentication before dependency enumeration
  - validated absolute executable identities and an allowlisted child environment
  - installation-OID ancestry proof and exact terminal history through Plan 28
affects: [finalize-phase, phase-164-closeout, TRTH-03, installed-loader]
actuals:
  tokens: 10655
  tasks: 2
  commits: 6
tech-stack:
  added: []
  patterns: [loader-owned authority constants, physical executable validation, allowlisted subprocess environment, generated test-only loader configuration]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-26-SUMMARY.md
  modified:
    - scripts/mailglass_finalize_phase_loader.mjs
    - scripts/finalize_phase_164.sh
    - test/scripts/phase_164_closeout_test.exs
key-decisions:
  - "Production finalization always selects /Users/jon/projects/mailglass and szTheory/mailglass; disposable acceptance fixtures use a generated test-only loader copy rather than runtime overrides."
  - "The loader validates absolute Node, Git, Bash, gh, jq, Mix, and Elixir identities before repository authentication and passes only an allowlisted environment with a reconstructed PATH."
  - "Phase 164 terminal history is exactly one PLAN and SUMMARY pair for every number 01 through 28."
requirements-completed: [TRTH-03]
duration: 10min
completed: 2026-09-10
status: complete
---

# Phase 164 Plan 26: Canonical Repository and Trusted Toolchain Summary

**Finalization now begins from one compiled physical repository identity and one validated absolute toolchain, with caller cwd/PATH excluded from authority and installation provenance bound by Git ancestry.**

## Performance

- **Duration:** 10 minutes
- **Started:** 2026-09-11T00:01:38Z
- **Completed:** 2026-09-11T00:11:45Z
- **Tasks:** 2
- **Files modified:** 3 implementation/contract files

## Accomplishments

- Pinned production dispatch to the physical `/Users/jon/projects/mailglass` checkout and normalized `szTheory/mailglass` origin before commit capture, tree enumeration, or repository byte reads.
- Replaced ambient Node/Git/Bash/tool resolution with validated absolute identities and an allowlisted environment whose PATH is reconstructed from trusted tool directories.
- Added a separate ancestry gate to self-check, preserving both installation/current byte equality checks while rejecting byte-identical loader blobs from unrelated history.
- Advanced the mechanically shared loader/shell terminal contract to the exact 01–28 PLAN/SUMMARY pair set with member-specific shell errors.
- Added non-vacuous hostile PATH coverage proving forged `git`, `bash`, `gh`, `jq`, `mix`, `node`, and `elixir` programs never execute.

## Task Commits

1. **Task 1 RED: canonical loader contracts** — `56d6753a`
2. **Task 1 GREEN: canonical repository and exact 01–28 history** — `7889a2fd`
3. **Task 2 RED: trusted-toolchain and ancestry contracts** — `c48b4d9b`
4. **Task 2 GREEN: validated toolchain, sanitized environment, ancestry gate** — `90e801a9`
5. **Task 2 fix: production-boundary canonical-history evidence** — `aec837fc`
6. **Task 2 test: seven-tool caller-PATH attack** — `c8d4f645`

## Verification

- `phase_164_canonical_loader`: 1 selected, 0 failures.
- `phase_164_loader_shell_terminal_contract`: 1 selected, 0 failures.
- `phase_164_trusted_toolchain`: 3 selected, 0 failures.
- `phase_164_installed_production_boundary`: 5 selected, 0 failures.
- Node syntax, Bash syntax across the finalizer chain, and `git diff --check`: passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reworked the moving-HEAD fixture after trusted Git bypassed its PATH shim**
- **Found during:** Task 2 regression run
- **Issue:** The old fixture mutated HEAD by shadowing `git` on caller PATH, which correctly stopped working once Git became an absolute trusted identity.
- **Fix:** Converted the fixture into a non-vacuous forged-Git negative control and retained the separate moving-HEAD guard in production code.
- **Files modified:** `test/scripts/phase_164_closeout_test.exs`
- **Commits:** `90e801a9`, `c8d4f645`

**2. [Rule 1 - Bug] Preserved fixture marker variables without widening production environment authority**
- **Found during:** Task 2 immutable-loader regression run
- **Issue:** The new allowlist correctly removed fixture-only marker variables, causing the authenticated fixture shell to abort under `set -u`.
- **Fix:** Added an empty production `TEST_ENV_KEYS` seam that generated test-only loader copies replace explicitly; direct production invocation retains no marker variables.
- **Files modified:** `scripts/mailglass_finalize_phase_loader.mjs`, `test/scripts/phase_164_closeout_test.exs`
- **Commit:** `90e801a9`

## TDD Gate Compliance

- RED commit `56d6753a` failed on missing canonical identities and the old terminal range.
- GREEN commit `7889a2fd` passed both Task 1 tagged contracts.
- RED commit `c48b4d9b` failed on ambient startup/tool resolution and missing ancestry rejection.
- GREEN commit `90e801a9` passed Task 2, with follow-up regression commits preserving the same behavior.

## Known Stubs

None. The empty production `TEST_ENV_KEYS` list is an intentional closed test-configuration seam and does not flow to runtime output.

## Issues Encountered

The broader closeout test file still exposes a pre-existing Plan 164-25 ledger derivation mismatch for `mix.exs` and `test/scripts/ci_parity_drift_test.exs`; the plan-scoped acceptance suites are green and this plan did not alter that ledger surface.

## User Setup Required

None. Updating the separately installed external command remains governed by its existing approval/install workflow and was not performed by this plan.

## Next Phase Readiness

- Canonical repository selection, trusted executable lookup, ancestry validation, and exact 01–28 history are implemented and regression-tested.
- Plans 164-27 and 164-28 can perform protected-main integration and terminal closeout without caller cwd or PATH participating in authority.

## Self-Check: PASSED

- All three implementation/contract files exist.
- Task commits `56d6753a`, `7889a2fd`, `c48b4d9b`, `90e801a9`, `aec837fc`, and `c8d4f645` exist in Git history.
- Every plan-scoped verification command passed after the final commits.
- No goal-blocking stubs, skipped tests, unrun plan verification, or unplanned threat surface remains.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-10*
