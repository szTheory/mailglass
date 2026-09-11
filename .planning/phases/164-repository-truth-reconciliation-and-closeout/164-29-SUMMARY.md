---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 29
subsystem: installed-finalization-authority
tags: [elixir, exunit, installed-loader, ci-isolation, provenance]
requires:
  - phase: 164-27
    provides: approved mode-0500 installed loader and mode-0400 nineteen-field approval record
  - phase: 164-28
    provides: exact 01-28 terminal-history readiness contract
provides:
  - controlled-host proof of the real Plan 164-27 installed authority tuple and direct self-check
  - default exclusion of machine-specific proof from every root ExUnit process
  - exhaustive alias/workflow contract preserving repository-only attack coverage
affects: [phase-164-verification, terminal-finalization, TRTH-03]
tech-stack:
  added: []
  patterns: [data-only approval parsing, lstat-before-read, immutable Git blob authentication, default host-tag exclusion]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-29-SUMMARY.md
  modified:
    - test/scripts/phase_164_closeout_test.exs
    - test/test_helper.exs
    - test/scripts/ci_parity_drift_test.exs
    - test/scripts/scheduled_control_evidence_test.exs
key-decisions:
  - "Plan 164-27 remains the single installed authority tuple; approval bytes are parsed as data and matched field-for-field before installed execution."
  - "The controlled-host tag is excluded by test_helper on every schema axis and is re-enabled only by the exact named --only alias."
  - "Disposable loader attacks remain repository-only tests and discover Node through the active test environment rather than a version-specific launcher."
patterns-established:
  - "External authority proof validates lstat type/mode, exact schema, SHA-256, committed blob identity, ancestry, and direct self-check in that order."
  - "Root-suite safety is checked across recursively expanded Mix aliases and workflow commands, with negative controls for missing exclusion and synthetic --only collection."
requirements-completed: [TRTH-03]
coverage:
  - id: TRTH-03-installed
    description: "The controlled-host alias authenticates and executes the real installed Plan 164-27 authority."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix verify.phase_164.installed_boundary (5 selected, 0 failures)"
        status: pass
    human_judgment: false
  - id: TRTH-03-isolation
    description: "Repository and protected full suites cannot collect controlled-host proof while all five disposable attacks remain active."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "focused isolation suite (69 tests, 0 failures, 5 host tests excluded)"
        status: pass
      - kind: integration
        ref: "mix verify.ci_lane_contract (388 tests, 0 failures, 5 host tests excluded)"
        status: pass
    human_judgment: false
actuals:
  tokens: 4307
  tasks: 2
  commits: 5
duration: 15min
completed: 2026-09-10
status: complete
---

# Phase 164 Plan 29: Installed Authority and Full-Suite Isolation Summary

**The controlled-host lane now proves the real Plan 164-27 installation field-for-field, while every ordinary root suite excludes host state and retains all disposable hostile-loader coverage.**

## Performance

- **Duration:** 15 minutes
- **Started:** 2026-09-11T02:37:50Z
- **Completed:** 2026-09-11T02:53:00Z
- **Tasks:** 2
- **Files modified:** 4 production/test files

## Accomplishments

- Replaced fixture-labeled installed proof with five tests that lstat the actual external files, parse the exact nineteen-field approval schema without evaluation, authenticate installed and committed bytes, prove installation-OID ancestry, and execute the installed shebang's own self-check.
- Preserved all five disposable foreign-repository, moving-HEAD, missing-pair, retired-extension, and override attacks under repository-only selection.
- Added a base `:phase_164_installed_production_boundary` exclusion to every root ExUnit process while retaining the exact controlled-host `--only` alias.
- Added recursive Mix-alias and CI-workflow full-suite collection checks plus negative controls, and preserved the protected job's single repository-only alias call.
- Removed version-specific Node launch paths from disposable fixture helpers by resolving and checking the active Node executable.

## Task Commits

1. **Task 1 RED:** `55c7ebc8` — failing real installed-authority tracer.
2. **Task 1 GREEN:** `31f4f818` — exact approval, provenance, and installed self-check implementation.
3. **Task 1 deviation fix:** `b9066cce` — correct SHA-256 argument ordering.
4. **Task 2 RED:** `f26b54e9` — failing root-suite isolation and protected-call-site contracts.
5. **Task 2 GREEN:** `e6aec348` — default host exclusion and portable fixture Node resolution.

## Decisions Made

- Kept one exact Plan 164-27 authority rather than introducing alternate installed identities.
- Used direct executable invocation for production proof so the approved shebang participates; disposable repository attacks use a checked runtime-discovered Node path.
- Kept terminal finalization and canonical pre-verification out of this plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected SHA-256 pipeline argument ordering**
- **Found during:** Task 1 GREEN verification
- **Issue:** Piping bytes directly into `:crypto.hash/2` reversed its algorithm and data arguments.
- **Fix:** Bound the bytes explicitly as the second argument for both installed-file and Git-blob hashing.
- **Files modified:** `test/scripts/phase_164_closeout_test.exs`
- **Commit:** `b9066cce`

## Issues Encountered

- The installed self-check correctly rejects a dirty canonical repository. The orchestrator-owned pre-existing STATE bookkeeping diff was preserved outside the verification window and restored byte-for-byte immediately afterward; no terminal or pre-verification mode ran.

## Verification

- `mix verify.phase_164.installed_boundary`: 5 tests, 0 failures, 49 excluded.
- Focused Task 2 suite: 69 tests, 0 failures, 5 controlled-host tests excluded.
- `mix verify.ci_lane_contract`: 388 tests, 0 failures, 5 controlled-host tests excluded.
- `git diff --check`: passed.
- No ExUnit skips appeared in any plan verification.

## Known Stubs

None.

## Threat Flags

None. The changed surface narrows test collection and authenticates an already-approved external executable; it adds no endpoint, schema, package, or new authority.

## Next Phase Readiness

- The two TRTH-03 verifier gaps assigned to Plan 164-29 are closed and contribute to readiness for ordinary Phase 164 verification after the remaining gap plans execute.
- Plan 164-30 and later gap plans remain unexecuted.
- Terminal finalization remains pending under the established protected-main lifecycle.

## Self-Check: PASSED

- All four key files exist.
- All five task commits exist in history.
- Both task acceptance suites and the repository-only required lane passed non-vacuously.
- No stubs, skipped tests, unrun verification, or unplanned security surface remains.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-10*
