---
phase: 178-preview-authoring-and-milestone-review
plan: "30"
subsystem: preview-delivery
tags: [git-worktree, diagnostics, offline-test]
requires:
  - phase: "178-29"
    provides: "Cookie-persistent login-first route probing"
provides:
  - "Visible Git worktree creation errors from the preview launcher"
  - "Offline regression coverage proving Git diagnostics are preserved"
affects: [UIQ-08]
tech-stack:
  added: []
  patterns: ["Capture failing subprocess output and include it in the fail-closed error"]
key-files:
  modified:
    - scripts/check_phase178_candidate.sh
    - scripts/test_check_phase178_candidate.sh
key-decisions:
  - "Cycle 05 remains stopped and consumed; no launcher or worktree retry is part of this plan."
  - "Any later preview must run from the primary execution context, with a fresh Cycle 06 one-attempt approval."
requirements-completed: []
requirements-open: [UIQ-08]
status: complete
actuals:
  tasks: 2
  commits: 1
---

# Phase 178 Plan 30: Preserve Worktree Failure Diagnostics

Cycle 05 stopped before Compose because the launcher could not create the detached candidate worktree. The launcher had redirected Git's stderr, so the exact error was lost. Plan 30 makes a future failure actionable without repeating the consumed attempt.

## Changes

- Added `add_candidate_worktree`, which keeps successful output quiet and includes Git's captured diagnostic in the fail-closed error when worktree creation fails.
- Added an offline test using a stub Git command. It checks the launcher context and distinctive Git error are both returned, and confirms no candidate worktree path is created.
- No candidate source, dependencies, Docker state, GitHub state, or Cycle 05 history changed.

## Verification

- `bash -n scripts/check_phase178_candidate.sh` — passed.
- `bash -n scripts/test_check_phase178_candidate.sh` — passed.
- `bash scripts/test_check_phase178_candidate.sh` — all 13 checks passed.
- `git diff --check` — passed.
- Independent read-only review — no blocking findings.
- No preview launcher, Git worktree creation, Docker, network, or GitHub command was used by this plan.

## Next step

Cycle 05 remains consumed and stopped. The delegated executor was later denied `.git/index.lock` with `Operation not permitted`, which suggests its read-only Git metadata boundary caused the earlier worktree failure; the exact original Git error is still unknown. The prepared Cycle 06 checkpoint binds the unchanged candidate to the updated launcher hash and authorizes no run until the user approves it. If approved, the primary execution context will run one attempt and preserve any Git error in output.
