---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 32
subsystem: immutable-finalization-authority
tags: [git, installed-loader, immutable-approval, exact-history, tdd]
requires:
  - phase: 164-31
    provides: exact 01-34 tracked loader authority and explicit superseded-pending installed state
provides:
  - immutable human-approved Plan 164-32 replacement tuple persisted outside the repository
  - exact-copy-plus-status mode-0400 approval record bound to source, tools, prior object, and rollback absence
  - verified non-mutation boundary preserving the Plan 164-27 installed command for Plan 164-33
affects: [phase-164-terminal-proof, plan-164-33, plan-164-34, TRTH-03]
actuals:
  tokens: 1881
  tasks: 2
  commits: 2
plan_head_before: 9c279f413510b750a2e0da41d13151520e9f93d9
tech-stack:
  added: []
  patterns: [source-bound approval tuple, fail-closed drift revalidation, atomic no-clobber approval publication]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-32-SUMMARY.md
    - /Users/jon/.local/share/mailglass/checkpoints/164-32-install-proposal.env
    - /Users/jon/.local/share/mailglass/checkpoints/164-32-install-approval.env
  modified:
    - test/scripts/phase_164_closeout_test.exs
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md
key-decisions:
  - "Human approval authorizes only source OID 1cfee7802de808f690fe5413b22a57e7ab802488 and the complete persisted Plan 164-32 tuple; every proposal, source, tool, prior-object, and rollback field was revalidated immediately before and after approval publication."
  - "Plan 164-32 records approval only: the Plan 164-27 installed loader remains byte- and identity-unchanged, rollback remains absent, and Plan 164-33 alone owns replacement and installed-boundary proof."
patterns-established:
  - "Approval publication uses a same-directory private temporary file and an atomic no-clobber link after exact proposal parity is proven."
  - "A blocking approval is consumed only after clean exact HEAD, immutable Git blob, trusted tools, prior approval, destination lstat, and rollback absence all agree."
requirements-completed: [TRTH-03]
coverage:
  - id: D1
    description: "The tracked contract and lifecycle record define the complete non-mutating 01-34 replacement proposal boundary."
    requirement: TRTH-03
    verification:
      - kind: unit
        ref: "test/scripts/phase_164_closeout_test.exs#phase_164_gap_install_proposal (4 selected, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The exact approved tuple is persisted as a regular non-symlink mode-0400 proposal copy plus one approval_status=approved line."
    requirement: TRTH-03
    verification:
      - kind: other
        ref: "Plan 164-32 Task 2 proposal/approval parity and pre/post identity revalidation"
        status: pass
    human_judgment: false
  - id: D3
    description: "Approval caused no installed-command or rollback mutation and invoked no readiness, finalization, CI, rerun, release, or publication action."
    requirement: TRTH-03
    verification:
      - kind: other
        ref: "Installed digest/lstat identity and rollback-absence checks after approval publication"
        status: pass
    human_judgment: false
duration: 34min
completed: 2026-09-11
status: complete
---

# Phase 164 Plan 32: Exact 01-34 Replacement Approval Summary

**The changed 01-34 loader is bound to one immutable approved replacement tuple while the installed Plan 164-27 command and absent rollback target remain untouched for Plan 164-33.**

## Performance

- **Duration:** 34 minutes
- **Started:** 2026-09-11T03:37:46Z
- **Completed:** 2026-09-11T04:11:36Z
- **Tasks:** 2
- **Files modified:** 5 tracked and external artifacts

## Accomplishments

- Added a four-test contract for the exact 01-34 source authority, complete 18-field proposal schema, immutable Plan 164-27 prior-object provenance, and non-mutating lifecycle boundary.
- Persisted proposal SHA-256 `0480fd8bffede44942290c91ca7b8afbbc35ced3cbbbb4bf2c6f273cf892b990` for source OID `1cfee7802de808f690fe5413b22a57e7ab802488` and loader SHA-256 `f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac`.
- Applied the exact human response only after the full tuple revalidated, producing approval SHA-256 `f120bbda1a15478ea97179210215ee54e28ff59641644a35a643628265e9bf4b` as the proposal plus one approval line.
- Revalidated that the installed destination still has digest `0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e`, mode 0500, and lstat identity `16777229:269505365:501:20`, while the approved rollback path remains absent.

## Approved Replacement Evidence

```text
record_version=1
phase_plan=164-32
installation_source_oid=1cfee7802de808f690fe5413b22a57e7ab802488
source_sha256=f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac
destination=/Users/jon/.local/bin/mailglass-finalize-phase
install_mode=0500
node_executable=/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node
git_executable=/opt/homebrew/Cellar/git/2.41.0/bin/git
bash_executable=/opt/homebrew/Cellar/bash/5.2.37/bin/bash
gh_executable=/opt/homebrew/Cellar/gh/2.95.0/bin/gh
jq_executable=/usr/bin/jq
mix_executable=/Users/jon/.asdf/shims/mix
elixir_executable=/Users/jon/.asdf/shims/elixir
prior_approval_sha256=e3acaa0081593713daaedf891c5129561bb3c645d2067ea4e835fee92a54eac9
prior_sha256=0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e
prior_mode=0500
prior_stat_identity=16777229:269505365:501:20
rollback_path=/Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e
approval_status=approved
proposal_sha256=0480fd8bffede44942290c91ca7b8afbbc35ced3cbbbb4bf2c6f273cf892b990
approval_sha256=f120bbda1a15478ea97179210215ee54e28ff59641644a35a643628265e9bf4b
```

## Task Commits

1. **Task 1 RED: Add failing replacement-proposal contract** — `b25c1789`
2. **Task 1 GREEN: Define the non-mutating replacement-proposal boundary** — `1cfee780`
3. **Task 2: Approve only the persisted Plan 164-32 tuple** — external approval state; no tracked-file delta

Task 2 intentionally creates external operational evidence rather than a repository change. Its durable tracked evidence is this summary.

## Files Created/Modified

- `test/scripts/phase_164_closeout_test.exs` — exact 01-34 source, prior-object, proposal-schema, and lifecycle contract.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md` — pending Plan 164-32 tuple and unchanged terminal ordering.
- `/Users/jon/.local/share/mailglass/checkpoints/164-32-install-proposal.env` — regular non-symlink mode-0400 immutable proposal.
- `/Users/jon/.local/share/mailglass/checkpoints/164-32-install-approval.env` — regular non-symlink mode-0400 exact proposal copy plus approval status.

## Decisions Made

- Scoped the user's `approved` response to the exact persisted tuple and refused any interpretation as general path, future-source, installation, or finalization authority.
- Kept installation and rollback creation exclusively in Plan 164-33; approval itself changes neither object and establishes no installed-readiness claim.
- Preserved ordinary verification, completion-only metadata, protected-main integration, natural protected evidence, and terminal capture in their existing order.

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

- Task 1 RED commit `b25c1789` introduced the failing replacement-proposal contract before implementation.
- Task 1 GREEN commit `1cfee780` added the lifecycle boundary and published the exact non-mutating proposal; the focused tag then passed with 4 selected tests and 0 failures.
- Task 2 was the planned blocking-human approval checkpoint and added no source behavior.

## Issues Encountered

- Two approval-gate shell attempts stopped before creating any artifact: the first corrected the macOS `realpath` location from `/usr/bin` to `/bin`, and the second added braces around a zsh parameter adjacent to the Git `:<path>` suffix. The successful attempt reran the complete tuple validation from the beginning before publication.

## Verification

- `phase_164_gap_install_proposal`: 4 selected, 0 failures, 55 excluded, 0 skipped.
- Proposal and approval are regular non-symlink mode-0400 files; approval is exactly the proposal plus one `approval_status=approved` line.
- Clean exact HEAD, source blob digest and shebang, canonical origin, and all seven safe absolute executable identities revalidated before and after approval publication.
- Plan 164-27 approval digest, installed destination digest/mode/lstat identity, and rollback absence revalidated before and after publication.
- Node syntax and `git diff --check` passed.
- The installed command was not invoked or modified; no pre-verification, terminal finalization, CI dispatch, rerun, release, or publication action ran.

## Known Stubs

None.

## Threat Flags

None. The source, human-approval, prior-object, and parity trust boundaries are the planned T-164-121 through T-164-124 and T-164-SC surface; no additional endpoint, schema, package, or file-access authority was introduced.

## User Setup Required

None. The explicit Plan 164-32 approval was completed and persisted.

## Next Phase Readiness

- Plan 164-33 may consume only this exact approval tuple after revalidating every bound field again.
- Installation, controlled-host proof, ordinary verification, protected completion, and terminal evidence all remain pending.

## Self-Check: PASSED

- Task commits `b25c1789` and `1cfee780` exist after the persisted Plan 164-32 ledger base.
- Both tracked implementation files, this summary, and the two external mode-0400 checkpoint records exist.
- The focused four-test contract, exact approval parity, source/tool/prior-object checks, and post-publication non-mutation checks passed from the final Plan 164-32 state.
- No stubs, skipped tests, unrun verification, unexpected deletion, or unplanned threat surface remains.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-11*
