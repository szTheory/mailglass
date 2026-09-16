---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 37
subsystem: repository-truth-closeout
tags: [protected-main, immutable-approval, physical-toolchain, runtime-probe, recoverable-install]
status: complete
requires:
  - phase: 164-36
    provides: exact protected-main source OID and successful attempt-one normal push CI identity
provides:
  - immutable physical-toolchain proposal bound to protected source, CI, predecessor, and rollback absence
  - byte-exact human approval authorizing only the displayed recoverable Plan 164-38 replacement
affects: [phase-164-38-installation, phase-164-39-final-reconciliation]
actuals:
  tokens: 4332
  tasks: 2
  commits: 3
plan_head_before: ae2e36ce5e2dc2d3485ea1414fe876c94364781d
tech-stack:
  added: []
  patterns:
    - approval is exact proposal bytes plus one terminal status line
    - authenticated runtime closure is proven by physical identities and exact-child execution output
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-37-SUMMARY.md
  modified:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md
key-decisions:
  - "Human approval is scoped only to proposal SHA-256 4d580f9f4a72ed6d25afa390f53369e1e08af3dc84c92b9e008d80895c13ddcf and its exact 27 ordered fields."
  - "Plan 164-37 publishes authority data only; installation, rollback creation, finalization, workflow operation, release, and completion metadata remain excluded."
patterns-established:
  - "Exact-copy approval: preserve proposal bytes and append exactly one approval_status=approved line."
  - "Double revalidation: verify all live identities before review and again immediately before atomic approval publication."
requirements-completed: [TRTH-03]
coverage:
  - id: D1
    description: "One immutable proposal binds protected source and CI to a physical, executable runtime closure and unchanged predecessor tuple."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix verify.phase_164.proposal_boundary"
        status: pass
      - kind: other
        ref: "live all-fields proposal revalidation against source OID 52c07a5051d269b307831a2210f53dec0dd1ff65 and CI run 34650810638"
        status: pass
    human_judgment: false
  - id: D2
    description: "The maintainer approved the displayed tuple and the approval is its byte-exact mode-0400 copy plus one status line."
    requirement: TRTH-03
    verification:
      - kind: manual_procedural
        ref: "blocking-human response: approved"
        status: pass
      - kind: other
        ref: "approval readback SHA-256 e3687bf5a2afc69a79b2677c69daa3d533549d4b6f730a30a04e32cc6d13b7cd"
        status: pass
    human_judgment: false
duration: 13m
completed: 2026-09-11
---

# Phase 164 Plan 37: Physical Toolchain Proposal and Approval Summary

**A protected-main loader and physically runnable BEAM toolchain are bound into one immutable proposal whose exact-copy approval authorizes only the next recoverable installation step.**

## Performance

- **Duration:** 13 minutes across the checkpoint continuation
- **Started:** 2026-09-11T23:30:08Z
- **Completed:** 2026-09-11T23:43:00Z
- **Tasks:** 2
- **Tracked files modified:** 2
- **External records created:** 2

## Accomplishments

- Published a regular non-symlink mode-0400 proposal binding exact protected source and CI, eight physical tool identities, exact-child runtime outputs, the active predecessor, destination, and absent rollback identity.
- Revalidated all 27 ordered fields and every live identity after the exact human response `approved`, then atomically published a 28-field exact-copy-plus-status approval.
- Preserved lifecycle separation: installed bytes, rollback bytes, protected controls, CI, finalization, release state, and completion metadata did not change.

## Approved Immutable Tuple

- **Proposal:** `/Users/jon/.local/share/mailglass/checkpoints/164-37-install-proposal.env`
- **Proposal SHA-256:** `4d580f9f4a72ed6d25afa390f53369e1e08af3dc84c92b9e008d80895c13ddcf`
- **Approval:** `/Users/jon/.local/share/mailglass/checkpoints/164-37-install-approval.env`
- **Approval SHA-256:** `e3687bf5a2afc69a79b2677c69daa3d533549d4b6f730a30a04e32cc6d13b7cd`
- **File contract:** both records are regular non-symlinks with mode `0400`; approval bytes equal proposal bytes followed by exactly `approval_status=approved\n`.

```text
record_version=2
proposal_schema=mailglass-finalize-phase-install-proposal-v2
phase_plan=164-37
installation_source_oid=52c07a5051d269b307831a2210f53dec0dd1ff65
source_sha256=394a47effebe04d7aaa4e098775bedd194b6f00ce6efa63eea078aa79bb9f746
protected_ci_run_id=34650810638
destination=/Users/jon/.local/bin/mailglass-finalize-phase
install_mode=0500
node_executable=/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node
git_executable=/opt/homebrew/Cellar/git/2.41.0/bin/git
bash_executable=/opt/homebrew/Cellar/bash/5.2.37/bin/bash
gh_executable=/opt/homebrew/Cellar/gh/2.95.0/bin/gh
jq_executable=/usr/bin/jq
mix_executable=/Users/jon/.asdf/installs/elixir/1.19.5-otp-28/bin/mix
elixir_executable=/Users/jon/.asdf/installs/elixir/1.19.5-otp-28/bin/elixir
erl_executable=/Users/jon/.asdf/installs/erlang/28.4.1/bin/erl
mix_version=Mix 1.19.5 (compiled with Erlang/OTP 28)
elixir_version=Elixir 1.19.5 (compiled with Erlang/OTP 28)
otp_release=28
runtime_probe_sha256=ca3c43bd04c4e21e223f39561f294885ceca2633db65a72fa29b780bcef3975d
prior_approval_sha256=f120bbda1a15478ea97179210215ee54e28ff59641644a35a643628265e9bf4b
prior_sha256=f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac
prior_mode=0500
prior_stat_identity=16777229:273869583:501:20
rollback_path=/Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac
rollback_status=absent
terminal_last_plan=39
approval_status=approved
```

## Task Commits

1. **Task 1: Publish the exact physical-toolchain replacement proposal** — `31f32902` (chore)
2. **Task 2: Approve exactly the displayed immutable proposal** — `17f50426` (chore)

The plan summary is committed separately after both task commits.

## Files Created/Modified

- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md` — records the proposal and approved lifecycle tuple while keeping every later stage pending.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-37-SUMMARY.md` — records exact approved fields, digests, verification, and scope.
- `/Users/jon/.local/share/mailglass/checkpoints/164-37-install-proposal.env` — external immutable proposal, mode `0400`.
- `/Users/jon/.local/share/mailglass/checkpoints/164-37-install-approval.env` — external exact-copy approval, mode `0400`.

## Decisions Made

- The response `approved` authorizes only the displayed tuple. Any field change requires a new proposal and another explicit approval.
- Plan 164-38 may preserve the installed predecessor at the digest-addressed rollback path and atomically replace the destination with the authenticated source blob, followed by installed-boundary verification. Plan 164-37 itself performs none of those mutations.
- Terminal finalization and tracked completion authority remain separately ordered after installation and Plan 164-39 reconciliation.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Two pre-publication verifier assertions were corrected before any approval bytes existed: one selected the Bash path where Git was intended, and one initially interpreted the final installed-stat component as link count instead of group ID. The complete revalidation then passed and publication occurred only once.

## Verification

- Proposal-boundary alias after approval: 4 selected tests, 0 failures, 60 excluded, 0 SuiteFloor violations.
- Exact proposal readback: 27 unique, nonempty fields in required order; SHA-256 `4d580f9f4a72ed6d25afa390f53369e1e08af3dc84c92b9e008d80895c13ddcf`; regular non-symlink mode `0400`.
- Protected source: remote `main` and protected branch API both reported `52c07a5051d269b307831a2210f53dec0dd1ff65`; the local Task 1/2 commits descend from that OID.
- Protected CI: run `34650810638` remained workflow `CI`, event `push`, attempt `1`, branch `main`, exact head SHA, status `completed`, conclusion `success`.
- Authenticated source blob: SHA-256 `394a47effebe04d7aaa4e098775bedd194b6f00ce6efa63eea078aa79bb9f746`, absolute physical Node shebang, terminal range `01-39`.
- Physical tools: Node, Git, Bash, gh, jq, Mix, Elixir, and Erlang were regular non-symlink physical paths with safe ownership and no group/world write bits.
- Exact-child runtime probe: `Mix 1.19.5 (compiled with Erlang/OTP 28)`, `Elixir 1.19.5 (compiled with Erlang/OTP 28)`, OTP `28`, digest `ca3c43bd04c4e21e223f39561f294885ceca2633db65a72fa29b780bcef3975d`.
- Active predecessor: approval digest `f120bbda1a15478ea97179210215ee54e28ff59641644a35a643628265e9bf4b`; installed digest `f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac`; mode `0500`; lstat identity `16777229:273869583:501:20`.
- Approval readback: proposal prefix byte-identical plus one terminal approved-status line; 28 unique, nonempty fields; SHA-256 `e3687bf5a2afc69a79b2677c69daa3d533549d4b6f730a30a04e32cc6d13b7cd`; mode `0400`.
- Protection API response digest was unchanged across publication: `b3d1ff17390b778c58c6cfc37030b4ef34aa390fbfa47cca18366878d824d2dc`.
- Installed predecessor identity and digest were unchanged after publication; the new rollback path remained absent.
- `git diff --check`: passed.

## Authentication Gates

None.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Plan 164-38 may consume only the exact approval SHA-256 and tuple recorded above for recoverable installation.
- Plan 164-39 tracked reconciliation, ordinary verification, completion-only metadata, protected-main terminal evidence, and terminal finalization remain pending.
- No release, publication, workflow dispatch/rerun, or terminal claim occurred.

## Self-Check: PASSED

- The tracked lifecycle record and this summary exist.
- Task commits `31f32902` and `17f50426` resolve to committed objects.
- The external proposal and approval read back with their recorded digests and exact-copy relationship.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-11*
