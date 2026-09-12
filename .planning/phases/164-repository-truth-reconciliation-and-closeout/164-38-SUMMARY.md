---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 38
subsystem: repository-truth-closeout
tags: [authenticated-install, rollback, controlled-host, physical-beam, tdd]
status: complete
requires:
  - phase: 164-37
    provides: exact human-approved protected loader, CI, physical-toolchain, predecessor, and rollback tuple
provides:
  - exact approved 01-39 loader installed as the active mode-0500 external authority
  - verified mode-0400 digest-addressed rollback preserving the superseded Plan 164-32 object
  - non-vacuous controlled-host and hermetic repository-lane proof with terminal lifecycle still pending
affects: [phase-164-39-reconciliation, ordinary-phase-verification, terminal-finalization]
actuals:
  tokens: 5272
  tasks: 2
  commits: 3
plan_head_before: 8200c9d6fab7ebbeebbde8a9319693ad4652f68e
tech-stack:
  added: []
  patterns:
    - rollback-first same-directory atomic installation from an authenticated Git blob
    - installed proof binds physical Mix, Elixir, and Erlang identities plus normalized child output
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-38-SUMMARY.md
  modified:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md
    - test/scripts/phase_164_closeout_test.exs
key-decisions:
  - "Only Plan 164-37 approval SHA-256 e3687bf5a2afc69a79b2677c69daa3d533549d4b6f730a30a04e32cc6d13b7cd authorized installation; mutable checkout bytes were never the install source."
  - "Plan 164-32 remains bounded prior provenance through its approval and the verified mode-0400 rollback, never as a second active authority."
  - "Plan 164-38 establishes installation readiness only; Plan 164-39, ordinary verification, completion metadata, protected exact-main evidence, and T-164-109 remain pending."
patterns-established:
  - "Authenticated replacement: materialize the approved commit blob privately, verify digest/shebang/mode, then atomically rename within the destination directory."
  - "Lane separation: the explicit host alias reads real external authority while repository CI excludes both approval and installed-host tags."
requirements-completed: [TRTH-03]
coverage:
  - id: D1
    description: "The exact approved loader is active at mode 0500 after verified predecessor publication at a mode-0400 rollback identity."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "direct installed --version and ancestry-aware --self-check against source OID 52c07a5051d269b307831a2210f53dec0dd1ff65"
        status: pass
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix verify.phase_164.installed_boundary"
        status: pass
    human_judgment: false
  - id: D2
    description: "Controlled-host and repository-only authorities are non-vacuous, disjoint, and remain explicitly non-terminal."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix verify.phase_164.installed_boundary — 7 tests, 0 failures, 57 excluded"
        status: pass
      - kind: integration
        ref: "mix verify.ci_lane_contract — 397 tests, 0 failures, 11 excluded"
        status: pass
    human_judgment: false
duration: 21m
completed: 2026-09-11
---

# Phase 164 Plan 38: Approved 01-39 Loader Installation Summary

**The protected 01-39 loader blob is recoverably installed with a verified predecessor rollback and a real physical BEAM runtime proof, while every terminal lifecycle gate remains pending.**

## Performance

- **Duration:** 21 minutes
- **Started:** 2026-09-11T23:46:56Z
- **Completed:** 2026-09-12T00:07:24Z
- **Tasks:** 2
- **Tracked files modified:** 3
- **External objects created/replaced:** 2

## Accomplishments

- Revalidated the persisted Plan 164-37 proposal and approval byte-for-byte, protected source/CI facts, all physical tools and runtime outputs, and the exact predecessor tuple immediately before mutation.
- Preserved the predecessor as a verified digest-addressed mode-0400 rollback, then atomically installed only the authenticated Git blob as the active regular mode-0500 executable.
- Proved the actual external command through direct version/self-check and 7 controlled-host tests, while the separate hermetic repository lane passed 397 tests with host-only groups excluded.

## Installed and Rollback Evidence

- **Approval:** `/Users/jon/.local/share/mailglass/checkpoints/164-37-install-approval.env`
- **Approval SHA-256:** `e3687bf5a2afc69a79b2677c69daa3d533549d4b6f730a30a04e32cc6d13b7cd`
- **Approved protected source OID:** `52c07a5051d269b307831a2210f53dec0dd1ff65`
- **Approved attempt-one push CI run:** `34650810638`
- **Installed path:** `/Users/jon/.local/bin/mailglass-finalize-phase`
- **Installed SHA-256 / mode / lstat:** `394a47effebe04d7aaa4e098775bedd194b6f00ce6efa63eea078aa79bb9f746` / `0500` / `16777229:288282024:501:20`
- **Rollback path:** `/Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac`
- **Rollback SHA-256 / mode / lstat:** `f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac` / `0400` / `16777229:288282021:501:20`
- **Prior Plan 164-32 approval SHA-256:** `f120bbda1a15478ea97179210215ee54e28ff59641644a35a643628265e9bf4b`

Direct `--version` returned `mailglass-finalize-phase-loader 1`. Direct `--self-check` reported the approved installation OID, the installed digest/path/mode, terminal range `01-39`, `Mix 1.19.5 (compiled with Erlang/OTP 28)`, `Elixir 1.19.5 (compiled with Erlang/OTP 28)`, OTP `28`, and runtime probe SHA-256 `ca3c43bd04c4e21e223f39561f294885ceca2633db65a72fa29b780bcef3975d`.

## Task Commits

1. **TDD RED: Bind installed proof to the approved authority** — `03cb5bab` (test)
2. **Task 1: Preserve predecessor and install approved source bytes** — `9532baa2` (chore)
3. **Task 2 GREEN: Record installed authority readiness and lane separation** — `6059398c` (feat)

The plan summary is committed separately after all task verification.

## TDD Gate Compliance

- **RED:** `03cb5bab` added the Plan 164-37 tuple and 01-39 lifecycle contract. The targeted lifecycle test failed on its expected assertion because the Plan 164-38 readiness section did not exist. The persisted record returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **GREEN:** `6059398c` added the observed installed authority, rollback, runtime, lane, and pending-order record. The targeted lifecycle test passed before the GREEN commit.
- **REFACTOR:** No separate refactor was needed; the final full installed and repository lanes remained green.

## Files Created/Modified

- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md` — records the active installation, rollback, physical runtime closure, disjoint lanes, and pending terminal order.
- `test/scripts/phase_164_closeout_test.exs` — advances the controlled-host contract from the obsolete Plan 164-32 tuple to the exact Plan 164-37 approval and physical runtime fields.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-38-SUMMARY.md` — records Plan 164-38 execution and verification evidence.

## Decisions Made

- Persisted approval bytes, not prompt text or checkout state, were the installation authority.
- The verified rollback remains recoverable prior provenance; the installed Plan 164-37 blob is the only active authority.
- Installation readiness cannot complete TRTH-03 or authorize either finalization mode; Plan 164-39 and all later lifecycle gates retain ownership.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Advanced the installed-boundary test authority from Plan 164-32 to Plan 164-37**

- **Found during:** Task 1 pre-mutation verification
- **Issue:** The plan declared only `164-FINALIZATION.md` as modified, but the real controlled-host alias still parsed the superseded Plan 164-32 approval and expected terminal range 01-34. Installing the approved 01-39 blob without updating that contract would make the mandated real alias reject the correct installation.
- **Fix:** Updated the existing public test boundary to parse all 28 Plan 164-37 approval fields, prove physical Mix/Elixir/Erlang output and probe digest, preserve Plan 164-32 as rollback provenance, and require 01-39 lifecycle text.
- **Files modified:** `test/scripts/phase_164_closeout_test.exs`
- **Verification:** RED evidence returned `RED_EVIDENCE_OK`; final installed alias passed 7 tests with 0 failures.
- **Committed in:** `03cb5bab` and `6059398c`

---

**Total deviations:** 1 auto-fixed (1 Rule 2 missing-critical contract update)
**Impact on plan:** The deviation is required for the plan's named controlled-host proof to authenticate the newly approved authority instead of stale prior state; it adds no lifecycle authority.

## Issues Encountered

- An initial pre-mutation shell validation attempt exited before creating rollback or changing the destination. The validation was rerun with explicit fail-closed diagnostics; every authority check passed before the single successful mutation sequence.
- The installed self-check intentionally rejects a dirty repository. Task evidence was therefore committed before the final full controlled-host alias, preserving the production cleanliness invariant instead of weakening or bypassing it.

## Evidence

- Approval/proposal: exact proposal-copy-plus-status form, 27/28 unique ordered nonempty fields, modes `0400`, expected digests.
- Protected authority: remote and branch API both reported source OID `52c07a5051d269b307831a2210f53dec0dd1ff65`; CI run `34650810638` remained workflow `CI`, event `push`, attempt `1`, branch `main`, exact head SHA, completed, successful.
- Installed direct proof: version and ancestry-aware self-check passed with terminal range `01-39` and the approved physical runtime closure.
- Controlled host: `mix verify.phase_164.installed_boundary` — 7 tests, 0 failures, 57 excluded.
- Repository-only: `mix verify.ci_lane_contract` — 397 tests, 0 failures, 11 excluded.
- `git diff --check`: passed.

## Authentication Gates

None.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Plan 164-39 may reconcile validation, security, lifecycle, and ledger evidence against this installed tuple.
- Ordinary verification, completion-only metadata, protected-main integration, exact remote CI/natural schedules, terminal capture, and T-164-109 remain pending.
- No phase argument, pre-verification mode, terminal mode, workflow dispatch/rerun, release, publication, or protected-control mutation occurred.

## Self-Check: PASSED

- The tracked lifecycle record, test contract, and this summary exist.
- Task commits `03cb5bab`, `9532baa2`, and `6059398c` resolve to committed objects.
- The installed and rollback objects read back with their recorded modes, digests, and lstat identities.
- Both disjoint verification lanes passed after the final tracked task change.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-11*
