---
phase: 165-reconcile-terminal-proof-and-milestone-archive-ordering
plan: 04
subsystem: release-authority
tags: [installation, sha256, runtime-closure, rollback, fail-closed]
requires:
  - phase: 165-reconcile-terminal-proof-and-milestone-archive-ordering
    plan: 01
    provides: authenticated v2.7 milestone loader, proposal contract, and installed-boundary tests
provides:
  - exact-tuple-approved external v2.7 milestone finalizer installation
  - guarded create-disposition rollback proof and final byte/mode closure
  - installed-only readiness evidence without terminal report dispatch
affects: [165-05-audit-archive-runbook, v2.7-milestone-archive]
actuals:
  tokens: 5951
  tasks: 2
  commits: 0
plan_head_before: cbe9c45797c444b21dc7e6f51559f7b2f573fbf1
tech-stack:
  added: []
  patterns: [exact-installation-tuple, atomic-no-overwrite-publication, guarded-rollback, closed-runtime-path]
key-files:
  created:
    - /Users/jon/.local/bin/mailglass-finalize-milestone
    - .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-04-SUMMARY.md
  modified: []
key-decisions:
  - "The approved absent predecessor uses create disposition with no backup; rollback may remove only an installed regular file at mode 0500 whose digest matches the approved source."
  - "For an absent destination, same-filesystem hard-link publication preserves atomic visibility while refusing to overwrite a destination created after the final lstat."
  - "Readiness invokes only the installed-boundary alias and --version identity; the terminal v2.7 command remains uninvoked."
patterns-established:
  - "Every host-boundary mutation revalidates repository identity, source OID/blob/digest, destination predecessor, physical tool closure, versions, and tool digests immediately before publication."
requirements-completed: []
coverage:
  - id: D1
    description: "The installed milestone finalizer exactly matches the approved source bytes, destination, mode, predecessor disposition, and eight-tool runtime closure."
    verification:
      - kind: integration
        ref: "host installation proof at source cbe9c45797c444b21dc7e6f51559f7b2f573fbf1"
        status: pass
    human_judgment: false
  - id: D2
    description: "The installed-only readiness boundary and hostile byte-mismatch suite pass without terminal milestone reporting."
    verification:
      - kind: integration
        ref: "mix verify.phase_165.installed_boundary; mix verify.phase_165.repository"
        status: pass
    human_judgment: false
  - id: D3
    description: "The approved create rollback removes only the authenticated installed object and restores absence before the final reinstall."
    verification:
      - kind: other
        ref: "induced post-publication failure and guarded remove_created rollback proof"
        status: pass
    human_judgment: false
metrics:
  duration: 8m
  completed_date: 2026-09-13
duration: 8m
completed: 2026-09-13
status: complete
---

# Phase 165 Plan 04: Approved Milestone Finalizer Installation Summary

**The separately approved v2.7 milestone command is installed byte-for-byte at mode 0500, with its closed runtime authenticated, rollback exercised, and terminal reporting left untouched.**

## Performance

- **Duration:** 8m
- **Started:** 2026-09-13T19:06:50Z
- **Completed:** 2026-09-13T19:14:50Z
- **Tasks:** 2
- **Files modified:** 1 external executable plus this summary

## Accomplishments

- Revalidated and honored the approved installation tuple at source commit `cbe9c45797c444b21dc7e6f51559f7b2f573fbf1`, blob `8e463a420d69bf8affa1fac0784564f8f52cb296`, and SHA-256 `505707b19ab09366479243365ef2ce1b4c2a4030614eca69c40ea5f51174a6ce`.
- Installed `/Users/jon/.local/bin/mailglass-finalize-milestone` atomically with mode `0500`, no predecessor backup, and a proven guarded `remove_created` rollback before the identical final reinstall.
- Passed both the installed-only identity boundary and all repository hostile cases, including installed-byte mismatch rejection, without creating a terminal v2.7 report or invoking terminal mode.

## Approved Installation Tuple

- **Repository/origin:** `/Users/jon/projects/mailglass` / `https://github.com/szTheory/mailglass.git`
- **Source:** commit `cbe9c45797c444b21dc7e6f51559f7b2f573fbf1`; blob `8e463a420d69bf8affa1fac0784564f8f52cb296`; SHA-256 `505707b19ab09366479243365ef2ce1b4c2a4030614eca69c40ea5f51174a6ce`
- **Destination/mode:** `/Users/jon/.local/bin/mailglass-finalize-milestone`; `0500`
- **Predecessor/disposition:** absent / `create`; no backup
- **Rollback:** remove only the created destination after proving regular non-symlink type, mode `0500`, and approved digest
- **Runtime closure:** physical NODE, GIT, BASH, GH, JQ, MIX, ELIXIR, and ERL paths, versions, and SHA-256 digests exactly matched the approved values
- **Excluded authority:** `/Users/jon/.local/bin/mailglass-finalize-phase` remained SHA-256 `5cc800c1db20b65e8ad7ea90fde01a0180dc66c057166d8486ac9c321f564972`, mode `0500`

## Task Commits

No task commit was required: Task 1 was a blocking approval checkpoint and Task 2 changed only the approved external executable. The plan metadata commit records this summary and normal GSD state bookkeeping.

## Files Created/Modified

- `/Users/jon/.local/bin/mailglass-finalize-milestone` - Approved external mirror of the authenticated repository loader, mode `0500`.
- `.planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-04-SUMMARY.md` - Non-secret installation and readiness evidence.

## Decisions Made

- Retained the approved `create` disposition and created no predecessor backup because the destination was absent at proposal, pre-install, rollback-proof, and final-install boundaries.
- Published the staged file with an atomic same-filesystem no-overwrite hard link, then removed the staging name. This closes the race in which a plain rename could replace an object created after predecessor validation.
- Interpreted repository cleanliness against the orchestrator-owned baseline: `.planning/config.json` remained the sole dirty path and retained `_auto_chain_active: true` plus the temporary documented default-branch override; it was never staged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Security] Used atomic no-overwrite publication for the absent predecessor**

- **Found during:** Task 2 (Install the approved bytes atomically and prove the installed-only boundary)
- **Issue:** A normal rename atomically publishes bytes but can overwrite a destination created between the final absence check and publication, violating the approved `create` predecessor tuple.
- **Fix:** Staged beside the destination, verified SHA-256 and mode, fsynced the staged file, atomically linked it to the absent destination with no-overwrite semantics, removed the staging name, and attempted directory fsync.
- **Files modified:** `/Users/jon/.local/bin/mailglass-finalize-milestone`
- **Verification:** The induced post-publication failure executed the approved guarded rollback, restored absence, and the identical final reinstall passed byte/mode checks.
- **Committed in:** External-only task; recorded by plan metadata commit.

**2. [Rule 1 - Metadata regression] Corrected inconsistent SDK progress output**

- **Found during:** Plan closeout
- **Issue:** `state.update-progress` counted only three of four completed predecessor phases, rendered 60%, retained the prose completed-plan count at 70 despite detecting 71 summaries, and left frontmatter `current_plan` at 4 after advancing to Plan 5.
- **Fix:** Restored the evidence-backed four-of-five phase progress (80%), aligned completed-plan counters to 71/75, set `current_plan: 5`, and updated the last-activity description.
- **Files modified:** `.planning/STATE.md`
- **Verification:** ROADMAP reports Phase 165 at 4/5 and STATE reports Plan 5 of 5 with four completed predecessor phases and 71/75 completed summaries.
- **Committed in:** Plan metadata commit.

**Total deviations:** 2 auto-fixed (one Rule 1, one Rule 2). **Impact:** Stronger host-boundary security plus bounded bookkeeping consistency; no scope expansion.

## Issues Encountered

- The first version display used ambient `asdf` selection for Mix and stopped before mutation. Re-running under the loader's reconstructed physical `PATH` proved Mix 1.19.5, Elixir 1.19.5, and OTP 28 exactly; all tuple fields were then revalidated again in the same process immediately before installation.

## Test Evidence

- Exact tuple and all eight executable digests passed before mutation; the closed-path version probe reported Node 24.19.0, Git 2.41.0, Bash 5.2.37(1), gh 2.95.0, jq 1.7.1-apple, Mix 1.19.5, Elixir 1.19.5, and OTP 28.
- Guarded rollback proof returned `rolled_back`; final installation returned `installed` with SHA-256 `505707b19ab09366479243365ef2ce1b4c2a4030614eca69c40ea5f51174a6ce` and mode `0500`.
- `mix verify.phase_165.installed_boundary` passed 1 test with 0 failures and 12 exclusions.
- `mix verify.phase_165.repository` passed 12 tests with 0 failures and 1 exclusion, including installed-byte mismatch rejection.
- The terminal-report file set was unchanged; no `v2.7` terminal invocation occurred.
- Repository porcelain was unchanged from the authorized orchestrator baseline: only `.planning/config.json` was modified, and its bytes remained unchanged throughout installation and tests.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None. The external executable creation, predecessor rollback, installed-byte authentication, and runtime closure are the four surfaces explicitly covered by the plan threat register.

## User Setup Required

None - the approved external installation is complete.

## Next Phase Readiness

- Plan 165-05 may perform ordinary Phase 165 verification, canonical audit, archive preview/approval, archive completion, final tracked convergence, and later protected evidence ordering.
- The installed command is readiness-proven only. It must not be invoked with `v2.7` until the post-archive protected-main, CI, and natural-schedule gates are satisfied.

## Self-Check: PASSED

- The installed external file and summary both exist; the executable is a regular non-symlink at mode `0500` with the approved SHA-256.
- The persisted plan ledger base is `cbe9c45797c444b21dc7e6f51559f7b2f573fbf1`; no task commit is expected for the approval-only and external-only tasks.
- Coverage classification reports all three deliverables auto-covered with no schema errors.
- `.planning/config.json` is unstaged and remains the only pre-existing modified tracked path.

---
*Phase: 165-reconcile-terminal-proof-and-milestone-archive-ordering*
*Completed: 2026-09-13*
