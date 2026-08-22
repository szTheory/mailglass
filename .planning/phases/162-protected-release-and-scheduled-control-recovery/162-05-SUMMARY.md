---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 05
subsystem: release reconciliation and scheduled control evidence
tags: [github-actions, release-policy, repository-hygiene, post-publish, hex, git, exunit]
requires:
  - phase: 162-01
    provides: append-only release evidence and disposition contract
  - phase: 162-02
    provides: proposal-only release control results
  - phase: 162-03
    provides: three-state repository-hygiene evidence
  - phase: 162-04
    provides: blocked scheduled post-publish resolution
provides:
  - final append-only release and run-provenance capture
  - explicit control, schedule, pending, and cannot-check dispositions
  - complete Phase 162 threat-closure contract and validated Wave 0 coverage
affects: [163-deterministic-release-path-timeout-repairs, 164-repository-truth-reconciliation-and-closeout]
tech-stack:
  added: []
  patterns: [append-only live evidence, control-schedule provenance separation, artifact-summary agreement, honest pending state]
key-files:
  created:
    - .planning/phases/162-protected-release-and-scheduled-control-recovery/162-05-SUMMARY.md
  modified:
    - .planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md
    - test/scripts/phase_162_release_reconciliation_test.exs
    - .planning/phases/162-protected-release-and-scheduled-control-recovery/162-VALIDATION.md
key-decisions:
  - "PR #222 remains retained only for the existing exact candidate-digest protected dispatch; its current head is distinct from the authorized ledger proposal."
  - "Manual control runs remain distinct from scheduled proof; post-change schedules are pending until the protected remote revision and named cron runs exist."
  - "The phase's evidence validation is complete, while the release disposition remains blocked rather than forcing publication or substituting an identity."
requirements-completed: [AUTO-01, AUTO-02, AUTO-03, AUTO-04, AUTO-05]
coverage:
  - id: D1
    description: Final immutable release reconciliation retains earlier evidence, resolves every scoped disposition, and preserves blocked authorization semantics.
    requirement: AUTO-01
    verification:
      - kind: unit
        ref: test/scripts/phase_162_release_reconciliation_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Control and scheduled evidence carries distinct event provenance, artifact agreement, explicit pending conditions, and full threat closure.
    requirement: AUTO-03
    verification:
      - kind: unit
        ref: mix test test/scripts/phase_162_release_reconciliation_test.exs test/scripts/release_trigger_recovery_test.exs test/mix/tasks/mailglass.repo.hygiene_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: The Phase 162 validation map has complete Wave 0 coverage and Nyquist compliance without treating pending schedules as success.
    requirement: AUTO-05
    verification:
      - kind: integration
        ref: mix test
        status: pass
    human_judgment: false
duration: 45min
completed: 2026-08-22
status: complete
---

# Phase 162 Plan 05: Final Release and Scheduled-Control Reconciliation Summary

**A final append-only evidence capture that keeps release controls proposal-only, proves artifact provenance where available, and records post-change schedule proof as pending rather than substituting a manual run or forcing publication.**

## Performance

- **Duration:** 45 min
- **Started:** 2026-08-22T19:13:00Z
- **Completed:** 2026-08-22T19:25:00Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Captured fresh PR #222, branch, tag, release, Hex, ledger, WT-03, preservation-ref, and canonical publish-summary identities without mutating release state.
- Added final-capture and exhaustive threat-closure contracts, then marked Wave 0 complete and the validation plan Nyquist-compliant only after the four focused contract files passed.
- Recorded distinct control and schedule rows with run IDs, workflow SHAs, artifact SHA-256 evidence, summary agreement, explicit cannot-check recovery commands, and exact pending cron observations.

## Task Commits

1. **Task 1 RED: Refresh immutable release facts and finalize every disposition** — `ae4408ab`
2. **Task 1 GREEN: Refresh immutable release facts and finalize every disposition** — `fb32b076`
3. **Task 2 RED: Record distinct control and scheduled evidence and enforce honest incompleteness** — `4b6f6749`
4. **Task 2 GREEN: Record distinct control and scheduled evidence and enforce honest incompleteness** — `5e958c2e`

## Files Created/Modified

- `.planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md` — final source, disposition, control/schedule, and threat-closure evidence.
- `test/scripts/phase_162_release_reconciliation_test.exs` — final capture, provenance, artifact, pending-cron, and threat-completeness contracts.
- `.planning/phases/162-protected-release-and-scheduled-control-recovery/162-VALIDATION.md` — completed Wave 0 and Nyquist validation evidence.

## Decisions Made

- Retain PR #222 and its proposal branch for the existing protected exact-candidate path only; current distinct head and ledger identities prohibit any ordinary merge or release action.
- Keep unavailable artifacts as `cannot-check` and post-change schedule observations as `pending`, each with a bounded recovery or observation command.
- Treat an authorized but unpublished ledger target as blocked evidence; published tags, prior manual proof, and release-event no-ops never substitute for it.

## Verification

- `mix test test/scripts/phase_162_release_reconciliation_test.exs` — passed, 8 tests.
- `mix test test/scripts/release_trigger_recovery_test.exs` — passed, 14 tests.
- `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs` — passed, 13 tests.
- `mix test test/mailglass/publish/post_publish_smoke_contract_test.exs` — passed, 10 tests.
- `mix test` — passed; existing test-load-filter, optional OTLP-exporter, and migration-order warnings remained non-failing.
- `mix format --check-formatted test/scripts/phase_162_release_reconciliation_test.exs` and `git diff --check` — passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Formatting] Formatted the expanded reconciliation contract**
- **Found during:** Task 1 verification
- **Issue:** `mix format --check-formatted` required line wrapping in the ExUnit contract.
- **Fix:** Applied the project formatter before the GREEN commit.
- **Files modified:** `test/scripts/phase_162_release_reconciliation_test.exs`
- **Verification:** Formatter and focused reconciliation test passed.
- **Committed in:** `fb32b076`

---

**Total deviations:** 1 auto-fixed (formatting).
**Impact on plan:** No behavior or scope change.

## Known Stubs

None.

## Issues Encountered

None. Remote artifacts unavailable for selected historical runs are explicitly represented as `cannot-check`, not as missing or successful evidence.

## Next Phase Readiness

- Phase 163 may address only its planned timeout-repair scope; no release authority was broadened here.
- Phase 164 receives a complete evidence record, with post-change scheduled observations still pending their named protected-remote cron runs.

## Self-Check: PASSED

- The reconciliation record, contract test, validation map, and this summary exist on disk.
- RED/GREEN commits `ae4408ab`, `fb32b076`, `4b6f6749`, and `5e958c2e` exist in Git history.
- No tracked release ledger, tag, branch, release, package publication, or retained WT-03 evidence was mutated.
