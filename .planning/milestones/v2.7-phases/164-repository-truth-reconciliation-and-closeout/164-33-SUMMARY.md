---
phase: 164-repository-truth-reconciliation-and-closeout
plan: 33
subsystem: immutable-finalization-authority
tags: [git, installed-loader, rollback, controlled-host, exact-history, tdd]
requires:
  - phase: 164-32
    provides: immutable human-approved 01-34 source, tool, prior-object, destination, and rollback tuple
provides:
  - approved mode-0500 01-34 loader installed from one authenticated Git blob
  - exact Plan 164-27 bytes preserved at the approved private mode-0400 rollback path
  - active controlled-host proof plus hermetic repository-only attack coverage
  - non-terminal installation-readiness evidence with later lifecycle work still pending
affects: [phase-164-terminal-proof, plan-164-34, TRTH-03, finalize-phase]
actuals:
  tokens: 5735
  tasks: 2
  commits: 3
plan_head_before: a81caea0a04dc53298f4982dd70396c89b92493a
tech-stack:
  added: []
  patterns: [rollback-before-replace, exact approval consumption, controlled-host authority split, atomic same-directory install]
key-files:
  created:
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-33-SUMMARY.md
    - /Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e
  modified:
    - test/scripts/phase_164_closeout_test.exs
    - .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md
    - /Users/jon/.local/bin/mailglass-finalize-phase
key-decisions:
  - "The active installed authority is only the exact Plan 164-32 approval tuple: source OID 1cfee7802de808f690fe5413b22a57e7ab802488, digest f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac, and mode 0500."
  - "Plan 164-27 remains immutable prior provenance through its exact mode-0400 digest-addressed rollback; it is recoverable but is not a second active authority."
  - "Plan 164-33 establishes installation readiness only; requirement completion, phase completion, protected-main evidence, and terminal finalization remain pending."
patterns-established:
  - "External replacement revalidates proposal/approval parity, repository source, trusted tools, prior inode tuple, and rollback absence before any mutation."
  - "The prior object is atomically published and digest-verified before same-directory destination rename, with automatic restoration armed for every post-install failure."
requirements-completed: []
coverage:
  - id: D1
    description: "The exact approved 01-34 Git blob is the active regular non-symlink mode-0500 command, with the exact Plan 164-27 bytes preserved as a private mode-0400 rollback."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "Plan 164-33 Task 1 exact approval/rollback/install verification plus direct --version and --self-check"
        status: pass
    human_judgment: false
  - id: D2
    description: "Controlled-host proof authenticates the real Plan 164-32 approval and installed object while retaining exact Plan 164-27 approval and rollback provenance."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix verify.phase_164.installed_boundary (7 selected, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Disposable repository attacks remain hermetic and lifecycle evidence records readiness without claiming terminal or completion state."
    requirement: TRTH-03
    verification:
      - kind: integration
        ref: "mix verify.ci_lane_contract (396 selected, 0 failures; 7 controlled-host tests excluded)"
        status: pass
      - kind: other
        ref: "git diff --check"
        status: pass
    human_judgment: false
duration: 17min
completed: 2026-09-11
status: complete
---

# Phase 164 Plan 33: Approved 01-34 Loader Installation Summary

**The exact Plan 164-32 loader now serves as the active mode-0500 external authority, with Plan 164-27 bytes preserved at the approved private rollback and both controlled-host and repository-only proof green.**

## Performance

- **Duration:** 17 minutes
- **Started:** 2026-09-11T04:19:22Z
- **Completed:** 2026-09-11T04:36:28Z
- **Tasks:** 2
- **Files modified:** 5 tracked and external artifacts

## Accomplishments

- Revalidated the exact persisted Plan 164-32 proposal/approval parity, authenticated source blob, trusted tool identities, clean committed source, precise Plan 164-27 inode/digest/mode identity, and rollback absence before mutation.
- Published the exact prior bytes at the approved regular non-symlink mode-0400 rollback path, then privately materialized and atomically installed the approved mode-0500 blob with automatic restoration armed for post-install failure.
- Bound the controlled-host suite to the real Plan 164-32 approval and installed object while preserving Plan 164-27 as exact prior provenance; 7 installed-host tests passed.
- Retained all disposable foreign-repository, moving-HEAD, missing-pair, hostile-extension, and override attacks in the repository-only lane; 396 tests passed with the 7 host-controlled tests excluded.
- Recorded installation readiness only. No phase argument, pre-verification, terminal finalization, CI dispatch/rerun, release, publication, requirement completion, or phase completion occurred.

## Installed Authority Evidence

```text
installation_source_oid=1cfee7802de808f690fe5413b22a57e7ab802488
source_sha256=f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac
destination=/Users/jon/.local/bin/mailglass-finalize-phase
install_mode=0500
installed_stat_identity=16777229:273869583:501:20
prior_approval_sha256=e3acaa0081593713daaedf891c5129561bb3c645d2067ea4e835fee92a54eac9
prior_sha256=0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e
rollback_path=/Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e
rollback_mode=0400
rollback_stat_identity=16777229:273869587:501:20
version=mailglass-finalize-phase-loader 1
terminal_range=01-34
```

## Task Commits

1. **Task 1: Atomically replace the exact Plan 164-27 object with approved committed bytes** — external installation/rollback state; no tracked-file delta
2. **Task 2 RED: Add failing active installation proof** — `60f3063d`
3. **Task 2 GREEN: Record installed authority readiness** — `14959c2e`
4. **Task 2 verification repair: Advance repository fixtures to 01-34** — `abae31ad`

Task 1 intentionally mutates only the approved external destination and rollback objects. Its durable tracked evidence is the Task 2 lifecycle record and this summary.

## Files Created/Modified

- `test/scripts/phase_164_closeout_test.exs` — active Plan 164-32 tuple proof, immutable Plan 164-27 rollback provenance, and exact 01-34 repository-only fixtures.
- `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZATION.md` — observed non-terminal installation readiness and preserved lifecycle order.
- `/Users/jon/.local/share/mailglass/rollback/mailglass-finalize-phase.0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e` — exact prior loader bytes, regular non-symlink mode 0400.
- `/Users/jon/.local/bin/mailglass-finalize-phase` — approved 01-34 loader blob, regular non-symlink mode 0500.

## Decisions Made

- Consumed approval as a complete immutable tuple, not as general authority over a path, future source, readiness/finalization mode, or lifecycle action.
- Preserved the prior bytes before destination replacement and retained the rollback after success so the superseded installation stays exactly recoverable.
- Kept host-controlled assertions in the single named installed-boundary alias and all disposable repository attacks in the repository-only lane.
- Left `TRTH-03`, Phase 164 completion, protected-main integration, and terminal evidence pending for their separately authorized later boundaries.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Advanced stale repository-only fixtures from 01-28 to 01-34**
- **Found during:** Task 2 full verification
- **Issue:** Twelve repository-only assertions and fixture histories still modeled the superseded 01-28 range, so the newly active approved 01-34 command correctly rejected them before their intended attack assertions.
- **Fix:** Advanced expected diagnostics, terminal fixture histories, missing-terminal cases, and unexpected-number cases to the exact 01-34 authority while preserving every disposable attack and the installed-host exclusion.
- **Files modified:** `test/scripts/phase_164_closeout_test.exs`
- **Verification:** `mix verify.ci_lane_contract` passed 396 tests with 7 controlled-host tests excluded.
- **Committed in:** `abae31ad`

---

**Total deviations:** 1 auto-fixed (1 blocking issue). **Impact on plan:** The correction was required to retain the planned repository-only attacks under the newly active range; no authority or scope was weakened.

## TDD Gate Compliance

- RED commit `60f3063d` added the active/prior authority and lifecycle-readiness contract. The focused lifecycle test failed on its intended missing Plan 164-33 heading, and `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- GREEN commit `14959c2e` added the observed installation-readiness record; the focused lifecycle test passed before commit.
- Verification commit `abae31ad` corrected the stale repository-only fixtures exposed by the full lane. No separate refactor was needed.

## Issues Encountered

- The first broad RED run also reached the active self-check while the test file was intentionally dirty. The RED gate was rerun against the exact lifecycle test location, producing one real assertion failure and no fixture/load or unrelated failure before GREEN authorization.
- The recurring missing `opentelemetry_exporter` test-environment warning remained non-failing and pre-existing; both required aliases completed with zero failures.

## Verification

- Exact Task 1 installed/rollback type, mode, digest, direct `--version`, and ancestry-aware `--self-check`: passed.
- `mix verify.phase_164.installed_boundary`: 7 selected, 0 failures, 54 excluded.
- `mix verify.ci_lane_contract`: 396 selected, 0 failures, 7 controlled-host tests excluded.
- `git diff --check`: passed.
- Direct self-check reported installation OID `1cfee7802de808f690fe5413b22a57e7ab802488`, current OID `abae31add29a983e2b03376447b62c0998de6294`, approved digest, external executable path, mode 0500, and terminal range 01-34.
- No finalization mode or lifecycle mutation outside the approved install/rollback tuple ran.

## Known Stubs

None.

## Threat Flags

None. The external approval, prior-destination, rollback, installed-command, and trusted-tool boundaries are the planned T-164-125 through T-164-128 and T-164-SC surfaces; no additional endpoint, schema, package, or file-access authority was introduced.

## User Setup Required

None. The exact persisted Plan 164-32 approval was consumed successfully.

## Next Phase Readiness

- Plan 164-34 may reconcile validation, security, lifecycle, and ledger records to this verified active installation.
- Ordinary verification, completion-only metadata, protected-main integration, exact attempt-one protected evidence, and terminal ignored capture remain pending and separately governed.

## Self-Check: PASSED

- Task commits `60f3063d`, `14959c2e`, and `abae31ad` exist after the persisted Plan 164-33 ledger base.
- Both tracked implementation files, this summary, the approved active destination, and the exact rollback object exist.
- The final controlled-host and repository-only aliases passed from the committed implementation state, and no stubs, skipped tests, unrun verification, unexpected deletion, or unplanned threat surface remains.

---
*Phase: 164-repository-truth-reconciliation-and-closeout*
*Completed: 2026-09-11*
