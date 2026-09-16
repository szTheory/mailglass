---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 21
subsystem: immutable-finalization-authority
tags: [git, finalization, immutable-loader, tdd, repository-truth]
requires:
  - phase: 164-20
    provides: reconciled finalization lifecycle and current validation map
provides:
  - externally installable loader that binds all repository authority reads to one full commit OID
  - exact authenticated Phase 164 PLAN/SUMMARY history for plans 01 through 24
  - fixed shell terminal gate that cannot shrink with surviving files
affects: [finalize-phase, repository-truth-ledger, TRTH-03, phase-164-closeout]
actuals:
  tokens: 8250
  tasks: 2
  commits: 7
tech-stack:
  added: []
  patterns: [captured-OID Git authority, private mode-0500 materialization, exact numbered-set authentication]
key-files:
  created:
    - scripts/mailglass_finalize_phase_loader.mjs
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-21-SUMMARY.md
  modified:
    - scripts/finalize_phase_164.sh
    - scripts/validate_repository_truth.exs
    - test/scripts/phase_164_closeout_test.exs
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv
key-decisions:
  - "The standalone loader captures one full HEAD commit OID, uses it for every tree/blob authority operation, rechecks HEAD immediately before dispatch, and executes only privately materialized authenticated bytes."
  - "Phase 164 terminal history is the explicit 48-path PLAN/SUMMARY set for 01 through 24; later plans must deliberately update both loader and shell constants."
  - "Repository-truth inventory considers completed plan declarations, preventing unexecuted future plans and their external installation paths from becoming premature ledger requirements."
patterns-established:
  - "Mutable checkout code never establishes or replaces finalization authority."
  - "Numbered history validation rejects missing, singleton, malformed, duplicate, and unexpected identities before Bash runs."
requirements-completed: []
coverage:
  - id: D1
    description: "One immutable authority OID controls all authenticated reads and moving HEAD stops before Bash."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "phase_164_immutable_loader focused suite — 7 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exact PLAN/SUMMARY pairs 01 through 24 cannot shrink or accept numbered-looking malformed paths."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "Phase 164 closeout and repository-truth suites — 68 tests, 0 failures"
        status: pass
      - kind: other
        ref: "repository truth ledger validator — valid"
        status: pass
    human_judgment: false
duration: 22min
completed: 2026-09-10
status: complete
---

# Phase 164 Plan 21: Immutable Finalization Authority Summary

**A standalone captured-OID loader now authenticates and privately materializes the complete fixed Phase 164 history before any finalization shell code can execute.**

## Performance

- **Duration:** 22 minutes
- **Started:** 2026-09-10T20:29:54Z
- **Completed:** 2026-09-10T20:51:58Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added an import-safe Node loader with bounded CLI behavior, full-OID authority capture, exact stage-zero authentication, private `0400`/`0500` materialization, moving-HEAD refusal, and non-dispatching installation self-check.
- Replaced discovery-derived terminal history with explicit PLAN/SUMMARY identities for every Phase 164 plan from 01 through 24 in both loader and shell gates.
- Added production-seam regressions for moving HEAD, hostile checkout mutation, source self-check, missing middle/baseline/current pairs, singleton identities, malformed suffixes, and unexpected numbered paths.
- Registered the loader as a canonical tracked repository-truth subject while keeping future unexecuted plan declarations out of the current audited inventory.

## Task Commits

1. **Task 1 RED: Immutable loader contracts** — `4fd71c7f` (test)
2. **Task 1 GREEN: Immutable finalization loader** — `9946474c` (feat)
3. **Task 2 RED: Fixed numbered-history contracts** — `df8f7139` (test)
4. **Task 2 GREEN: Fixed terminal history and ledger integration** — `c479741a` (feat)
5. **Acceptance-gap RED: Malformed history contract** — `ab0c162c` (test)
6. **Acceptance-gap GREEN: Numbered-looking path rejection** — `d10af0a4` (fix)
7. **Regression formatting** — `1f3c799f` (style)

## Files Created/Modified

- `scripts/mailglass_finalize_phase_loader.mjs` — Standalone immutable authority loader and installation self-check.
- `scripts/finalize_phase_164.sh` — Explicit 01–24 terminal PLAN/SUMMARY gate.
- `test/scripts/phase_164_closeout_test.exs` — Captured-OID, materialization, self-check, and exact-history regressions.
- `scripts/validate_repository_truth.exs` — Canonical loader relationship plus completed-plan inventory boundary.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` — Evidence-backed tracked loader disposition.

## Decisions Made

- Kept the loader standalone and dependency-free so the installed command can establish authority before project code runs.
- Materialized every authenticated dependency from the captured commit into a private temporary root instead of executing mutable checkout bytes.
- Treated the 01–24 range as a coordinated constant shared by loader, shell, and contract tests; no later numbered plan is implicit.
- Scoped plan-derived ledger inventory to completed plans because future plan declarations can name not-yet-created repository and external installation artifacts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rejected numbered-looking malformed paths**
- **Found during:** Task 2 acceptance review
- **Issue:** Exact-path filtering rejected missing and unexpected well-formed pairs but ignored a path such as `164-10-PLAN.md.backup`.
- **Fix:** Added a broader numbered-looking classifier and adversarial singleton, malformed, and unexpected-path regressions.
- **Files modified:** `scripts/mailglass_finalize_phase_loader.mjs`, `test/scripts/phase_164_closeout_test.exs`
- **Commits:** `ab0c162c`, `d10af0a4`, `1f3c799f`

**2. [Rule 3 - Blocking] Prevented future plan declarations from invalidating the current ledger**
- **Found during:** Task 2 canonical ledger verification
- **Issue:** The validator treated files named by unexecuted Plans 22–24, including external installation paths, as already-required audited subjects.
- **Fix:** Plan-derived inventory now includes completed plans only, while the tracked loader is explicitly audited and canonically hashed.
- **Files modified:** `scripts/validate_repository_truth.exs`
- **Commit:** `c479741a`

## Issues Encountered

- The repository's checked-in `.tool-versions` entries are unavailable locally. Verification used the installed compatible pair Elixir `1.19.5-otp-28` and Erlang `28.4.1`.
- Focused tests emit the existing optional OTLP-exporter warning; it did not affect compilation or outcomes.

## TDD Gate Compliance

- RED commits `4fd71c7f`, `df8f7139`, and `ab0c162c` demonstrated missing loader, shrinking shell history, and malformed-suffix acceptance failures respectively.
- GREEN commits `9946474c`, `c479741a`, and `d10af0a4` followed their corresponding RED gates and passed the production-seam suite.

## Verification

- Focused immutable-loader suite: 7 selected, 37 excluded, 0 failures.
- Combined closeout and repository-truth suites: 68 tests, 0 failures.
- `mix format --check-formatted` for changed Elixir sources: passed.
- `bash -n scripts/finalize_phase_164.sh`: passed.
- `node --check scripts/mailglass_finalize_phase_loader.mjs`: passed.
- Loader version probe: `mailglass-finalize-phase-loader 1`.
- Canonical repository-truth validator: `repository truth ledger: valid`.
- `git diff --check`: passed.

## Known Stubs

None.

## User Setup Required

None for this plan. External installation and approval remain assigned to Plan 164-23.

## Next Phase Readiness

- Plan 164-22 can bind the extension command and maintainer guidance to the external loader contract.
- Plan 164-23 remains the explicit human-approved installation boundary; this plan did not mutate external installation state.
- TRTH-03 remains open until the remaining gap-closure plans and terminal evidence complete.

## Self-Check: PASSED

- All five implementation and contract files exist.
- All seven task and deviation commits are present in Git history.
- Focused and combined regression suites passed against the final committed implementation.
- No goal-blocking stub, skipped test, unrun plan verification, or unplanned threat surface remains.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-10*
