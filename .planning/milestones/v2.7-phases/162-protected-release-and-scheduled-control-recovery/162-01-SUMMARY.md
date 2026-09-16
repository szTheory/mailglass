---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 01
subsystem: release evidence and verification
tags: [github-actions, release-policy, hex, git, exunit, reconciliation]
requires:
  - phase: 161-canonical-workspace-and-evidence-preservation
    provides: immutable worktree, preservation-ref, and WT-03 release evidence
provides:
  - append-only protected-release reconciliation record
  - deterministic ExUnit contract for evidence and disposition matrices
  - explicit PR, tag, Hex, publish-summary, and retained-worktree identities
affects: [162-02, 162-03, 162-04, 162-05, 164-repository-truth-reconciliation-and-closeout]
tech-stack:
  added: []
  patterns: [append-only timestamped evidence ledger, cannot-check acquisition result, stable category and identity ordering]
key-files:
  created:
    - .planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md
    - test/scripts/phase_162_release_reconciliation_test.exs
  modified:
    - .planning/phases/162-protected-release-and-scheduled-control-recovery/162-VALIDATION.md
key-decisions:
  - "PR #222 is retained only for a future exact candidate-digest protected dispatch because its fresh head SHA differs from the ledger proposal SHA."
  - "Authorized plus publication:not_started is blocked evidence, never merge, tag, or publish authority."
  - "Unavailable remote branch observations are cannot-check and remain retained pending a fresh authenticated read."
patterns-established:
  - "Each evidence identity records source, capture time, immutable identity, observation, and one safe disposition or recovery condition."
  - "Equal tag or ref OIDs remain independent rows, sorted by category then immutable identity."
requirements-completed: [AUTO-01, AUTO-02]
coverage:
  - id: D1
    description: "Append-only reconciliation ledger records PR, candidate, publication, worktree, and preservation evidence with explicit safe outcomes."
    requirement: AUTO-01
    verification:
      - kind: unit
        ref: test/scripts/phase_162_release_reconciliation_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: "Scoped release identities retain distinct outcomes, cannot-check handling, explicit empty rows, and bytewise stable ordering."
    requirement: AUTO-02
    verification:
      - kind: unit
        ref: test/scripts/phase_162_release_reconciliation_test.exs
        status: pass
      - kind: unit
        ref: mix test test/scripts/release_policy_test.exs test/scripts/release_policy_contract_test.exs
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-08-22
status: complete
---

# Phase 162 Plan 01: Protected Release Reconciliation Summary

**A tested, append-only reconciliation ledger that distinguishes PR #222, the authorized-but-unpublished candidate, published tags and Hex releases, preserved refs, and WT-03 evidence without extending release authority.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-08-22T18:42:59Z
- **Completed:** 2026-08-22T18:48:35Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Captured fresh, read-only GitHub PR/check, tag/release, Hex, Git-ref, publish-summary, and WT-03 evidence with immutable SHA, digest, version, and checksum identities.
- Added deterministic ExUnit coverage for the tracer, canonical-source coverage, singular dispositions, explicit `NONE-*` rows, and stable matrix ordering.
- Recorded the safe PR #222 disposition: retain only for the existing exact candidate-digest protected dispatch, because its current head differs from the ledger proposal.

## Task Commits

1. **Task 1: Prove one PR-to-disposition release-state path end to end** — `b76189fb` (RED test), `fec73dda` (GREEN tracer ledger)
2. **Task 2: Expand reconciliation across every scoped identity** — `e14dede8` (RED test), `1c6f0977` (GREEN expanded ledger)

## Files Created/Modified

- `.planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md` — append-only timestamped source, evidence, and disposition matrices.
- `test/scripts/phase_162_release_reconciliation_test.exs` — parser-backed contract for required evidence and ordering.
- `.planning/phases/162-protected-release-and-scheduled-control-recovery/162-VALIDATION.md` — confirms Plan 01 ownership and keeps the Wave 0 completion gate with Plan 05.

## Decisions Made

- Preserve PR #222 rather than merge or retire it: its live head is distinct from the authorized ledger candidate, so only a future exact protected dispatch may evaluate it.
- Keep failed branch lookups as `cannot-check`; a 404 does not establish absence or authorize retirement.
- Treat equal tag/ref OIDs as distinct identities and preserve all of them independently.

## Verification

- `mix test test/scripts/phase_162_release_reconciliation_test.exs` — passed after each GREEN stage.
- `mix test test/scripts/phase_162_release_reconciliation_test.exs test/scripts/release_policy_test.exs test/scripts/release_policy_contract_test.exs` — passed.
- `mix test` — passed; existing fixture-pattern and optional OTLP-exporter warnings remained non-failing.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Issues Encountered

None. The RED tests failed as intended before their corresponding ledger coverage existed.

## Next Phase Readiness

Plans 02–04 can consume the reconciled evidence while keeping ordinary triggers proposal-only. `wave_0_complete` remains `false`; Plan 05 Task 1 is the first allowed completion gate after all remaining contract cases pass.

## Self-Check: PASSED

- The reconciliation ledger, contract test, and validation map exist on disk.
- All four RED/GREEN commits are present in Git history.
- No stubs, skipped tests, unrun verifications, or new threat surfaces were found.
