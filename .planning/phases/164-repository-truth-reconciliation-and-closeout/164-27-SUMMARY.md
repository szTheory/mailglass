---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 27
subsystem: immutable-finalization-authority
tags: [git, installed-loader, immutable-approval, rollback, hostile-boundary]
requires:
  - phase: 164-26
    provides: canonical repository, trusted toolchain, installation ancestry, and exact 01-28 terminal-history contracts
provides:
  - immutable human-approved Plan 164-27 replacement tuple persisted outside the repository
  - mode-0500 installed loader byte-identical to the approved hardened Git blob
  - digest-addressed mode-0400 rollback copy of the superseded loader
  - passing installed-boundary proof against foreign-repository, forged-PATH, history, and moving-HEAD attacks
affects: [phase-164-terminal-proof, finalize-phase, TRTH-03, plan-164-28]
actuals:
  tokens: 10164
  tasks: 3
  commits: 4
tech-stack:
  added: []
  patterns: [source-bound approval tuple, private rollback-before-replace, same-directory atomic installation, post-install adversarial verification]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-27-SUMMARY.md
    - /Users/jon/.local/share/mailglass/checkpoints/164-27-install-proposal.env
    - /Users/jon/.local/share/mailglass/checkpoints/164-27-install-approval.env
    - /Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9
  modified:
    - test/scripts/phase_164_closeout_test.exs
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md
    - /Users/jon/.local/bin/mailglass-finalize-phase
key-decisions:
  - "Human approval authorized only source OID 2c7cf25c4ac004df3f960a5e8cb37cf8aef68c97 and its complete source-bound replacement tuple; every repository, tool, prior-object, and rollback field was revalidated before mutation."
  - "The superseded ca760f78 loader remains recoverable as a private digest-addressed mode-0400 object, while the operational command is now the approved 0dbcc034 hardened loader."
  - "Installation readiness was proven without invoking canonical pre-verification or terminal finalization; protected lifecycle ordering remains unchanged."
patterns-established:
  - "Reinstallation approval binds immutable Git bytes, trusted executable paths, the exact installed inode identity, and an absent rollback target before replacement."
  - "A prior executable is published and verified in private rollback storage before an atomic destination rename, with automatic restoration reserved for failed post-install checks."
requirements-completed: [TRTH-03]
coverage:
  - id: D1
    description: "The tracked reinstall contract identifies the hardened source, immutable prior provenance, and unchanged lifecycle boundary."
    requirement: TRTH-03
    verification:
      - kind: unit
        ref: "test/scripts/phase_164_closeout_test.exs#phase_164_reinstall_contract (3 selected, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The exact human-approved replacement tuple is persisted in regular non-symlink mode-0400 proposal and approval records."
    requirement: TRTH-03
    verification:
      - kind: other
        ref: "Plan 164-27 Task 2 schema, proposal parity, source/tool/prior-object, and approval-status checks"
        status: pass
    human_judgment: false
  - id: D3
    description: "The installed command is the approved hardened blob, the prior loader is recoverable, and controlled-host attacks fail closed."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix verify.phase_164.installed_boundary (5 selected, 0 failures)"
        status: pass
      - kind: other
        ref: "/Users/jon/.local/bin/mailglass-finalize-phase --self-check --repo /Users/jon/projects/mailglass --expected-source-oid 2c7cf25c4ac004df3f960a5e8cb37cf8aef68c97"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-09-10
status: complete
---

# Phase 164 Plan 27: Hardened Installed Loader Reinstallation Summary

**The approved Plan 164-26 loader now serves as the external mode-0500 finalization authority, with exact prior bytes preserved for rollback and five hostile installed-boundary cases passing.**

## Performance

- **Duration:** 4 minutes
- **Started:** 2026-09-11T01:04:47Z
- **Completed:** 2026-09-11T01:08:30Z
- **Tasks:** 3
- **Files modified:** 7 tracked and external artifacts

## Accomplishments

- Added and passed a non-vacuous reinstall-readiness contract covering the hardened loader's canonical repository, trusted tools, sanitized environment, ancestry gate, and exact 01-28 range.
- Persisted the explicitly approved source/tool/destination/prior-object/rollback tuple as mode-0400 proposal and approval records after rechecking clean exact HEAD and every bound identity.
- Preserved the superseded loader byte-for-byte at the private rollback path, atomically installed the approved Git blob at mode 0500, and passed version, ancestry-aware self-check, and five controlled-host attacks.
- Kept canonical pre-verification and terminal finalization unrun; older ignored reports retained pre-plan timestamps and were not rewritten.

## Approved Replacement Evidence

```text
installation_source_oid=2c7cf25c4ac004df3f960a5e8cb37cf8aef68c97
source_sha256=0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e
destination=/Users/jon/.local/bin/mailglass-finalize-phase
install_mode=0500
prior_approval_sha256=c9750e8becddd7b08ce27b2c6267b5172c1f25954d0d1b5ef9e39f04a909c862
prior_sha256=ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9
prior_mode=0500
prior_stat_identity=16777229:267228421:501:20
rollback_path=/Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9
proposal_sha256=e01aa2ffaa59ace2ceb53adccc008601ea169d37ad2f993e487cd150eba7bb5e
approval_sha256=e3acaa0081593713daaedf891c5129561bb3c645d2067ea4e835fee92a54eac9
```

The approval also records the source-bound absolute Node, Git, Bash, gh, jq, Mix, and Elixir executable paths. The approval is exactly the proposal plus one `approval_status=approved` field.

## Task Commits

1. **Task 1 RED: Trace hardened source to a reinstall-readiness contract** — `032510e8`
2. **Task 1 GREEN: Define hardened loader reinstall readiness** — `2c7cf25c`
3. **Task 2: Approve the exact hardened-loader replacement tuple** — external proposal/approval state; no tracked-file delta
4. **Task 3: Atomically replace, self-check, and attack the installed authority** — external installation/rollback state; no tracked-file delta

Task 2 and Task 3 intentionally produce external operational state rather than repository changes; their durable tracked evidence is this summary.

## Files Created/Modified

- `test/scripts/phase_164_closeout_test.exs` — tagged readiness and immutable-prior-provenance contract.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md` — Plan 164-27 reinstall prerequisite and unchanged terminal ordering.
- `/Users/jon/.local/share/mailglass/checkpoints/164-27-install-proposal.env` — regular non-symlink mode-0400 approved proposal source.
- `/Users/jon/.local/share/mailglass/checkpoints/164-27-install-approval.env` — regular non-symlink mode-0400 proposal copy plus explicit approval.
- `/Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9` — mode-0400 exact superseded loader bytes.
- `/Users/jon/.local/bin/mailglass-finalize-phase` — mode-0500 hardened loader installed from the approved commit blob.

## Decisions Made

- Applied the human response only to the approved immutable source-bound tuple after every state-bearing field still matched current state.
- Preserved the prior loader before replacement and retained the rollback object after successful verification for explicit recoverability.
- Treated installed-boundary verification as readiness proof only; it does not substitute for the later ordinary verifier, protected completion metadata, or exact-main terminal capture.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The continuation began before the Plan 164-27 proposal and approval records had been published. Their approved fields still matched exactly, so the proposal and exact-copy approval were atomically persisted before any destination mutation, as required by Task 2.

## Verification

- `phase_164_reinstall_contract`: 3 selected, 0 failures.
- Proposal/approval schema, non-symlink type, mode 0400, exact-copy parity, and explicit approval: passed.
- Installed SHA-256 `0dbcc034...`, regular-file type, and mode 0500: passed.
- Rollback SHA-256 `ca760f78...`, regular-file type, and mode 0400: passed.
- Version probe returned `mailglass-finalize-phase-loader 1`.
- Ancestry-aware self-check returned matching installation/current OID `2c7cf25c...`, matching loader digest, mode 0500, and terminal range 01-28.
- `mix verify.phase_164.installed_boundary`: 5 selected, 0 failures, 44 excluded.
- Node syntax and `git diff --check`: passed.
- No canonical pre-verification or terminal finalization command ran during installation.

## Known Stubs

None.

## User Setup Required

None. The explicit Plan 164-27 installation approval was completed and consumed.

## Next Phase Readiness

- The supported installed command now contains the canonical-repository, trusted-toolchain, ancestry, and exact-history repairs needed by Plan 164-28.
- Terminal finalization remains pending behind ordinary verification and protected completion-metadata integration.

## Self-Check: PASSED

- Task commits `032510e8` and `2c7cf25c` exist and are ancestors of the approved installation source OID.
- All tracked and external key files exist with the documented types, modes, and digests.
- Every plan acceptance and plan-level verification command passed after installation.
- No stubs, skipped tests, unrun verification, or unplanned threat surface remains.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-10*
