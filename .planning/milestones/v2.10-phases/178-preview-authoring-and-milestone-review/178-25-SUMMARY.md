---
phase: 178-preview-authoring-and-milestone-review
plan: "25"
subsystem: ci
tags: [github-actions, inotify, preview-capture, recovery]
dependency_graph:
  requires:
    - "178-22: preserved the stopped hosted run and missing-watcher evidence"
  provides:
    - "Preview Capture Advisory installs the Linux watcher before Phoenix starts"
    - "A separate, authority-free local candidate record for the corrected workflow"
  affects: [UIQ-06, UIQ-07, UIQ-08, "178-23", "178-24"]
tech_stack:
  added: []
  patterns: ["job-scoped OS package setup", "dependency-free workflow contract test", "separate SHA-bound recovery cycle"]
key_files:
  created:
    - scripts/check_preview_capture_advisory_setup.test.cjs
    - .planning/phases/178-preview-authoring-and-milestone-review/178-RECOVERY-CYCLE-02.json
  modified:
    - .github/workflows/ci.yml
key_decisions:
  - "Install the documented Linux file watcher only in the optional Preview Capture Advisory job; do not change the Elixir or npm dependency graphs."
  - "Freeze the corrected source at a new local SHA while keeping hosted, preview, and cost authority unset."
requirements-completed: []
duration: not-recorded
completed: 2026-11-02
status: complete
---

# Phase 178 Plan 25: Advisory Watcher Setup Recovery Summary

**The advisory preview job now installs its required Linux file watcher, and the fix is frozen as a new local candidate without carrying forward the prior hosted approval.**

## Accomplishments

- Added `inotify-tools` installation to `preview_capture_advisory`, after Playwright's OS dependency setup and before the deterministic preview server starts. The existing Elixir/npm dependency graph, app configuration, required checks, and advisory placement are unchanged.
- Added a dependency-free Node contract test that checks the watcher install is unique, remains in the advisory job, precedes server startup, and is covered by the Demo Browser Evidence contract-test command.
- Froze candidate `a0a7450cc68afe84e25e69276c654d9e63422499` on local `main`, with source hashes and local-check receipts in [178-RECOVERY-CYCLE-02.json](178-RECOVERY-CYCLE-02.json).
- Confirmed the prior recovery record and Plan 22 stop record remain unchanged. The previous candidate's hosted approval is not inherited.

## Verification

- `node --test scripts/check_preview_capture_advisory_setup.test.cjs` — passed (2 tests).
- `actionlint .github/workflows/ci.yml` — passed.
- `git diff --check -- .github/workflows/ci.yml scripts/check_preview_capture_advisory_setup.test.cjs` — passed.
- The source files in candidate `a0a7450c` match their recorded SHA-256 values and the working files. The previous `178-RECOVERY.json` SHA-256 remains `334cd4a7407677c80f536a38758ea648ef7033cb95b4b4f480418b2ffa259003`.

These local checks establish the workflow syntax and setup contract. They do not establish that the watcher starts on a hosted Ubuntu runner; that still needs a new, separately approved hosted cycle.

## Task Commits

1. **Task 1: Scope the Linux watcher setup and lock the contract** — `a0a7450c` (`fix(178-25): install advisory file watcher`).
2. **Task 2: Validate, review, and commit the local workflow correction** — validation completed after Task 1; no source changes remained to commit.
3. **Task 3: Freeze a separate candidate cycle** — the cycle record and this summary are committed together in the final Plan 25 documentation commit.

## Decisions and Boundaries

- The Linux package is scoped to one advisory CI job; no application or package-manifest dependency was added.
- Plan 22 remains halted, Plans 178-23 and 178-24 remain blocked, hosted cost remains unmeasured, and UIQ-06/07/08 remain open.
- No push, GitHub edit, workflow dispatch, preview launch, release, deployment, or publication occurred. Any hosted operation requires fresh approval for the exact new candidate and operation list.
- `.planning/STATE.md`, `.planning/ROADMAP.md`, and unrelated dirty files were left untouched under the assigned file scope.

## Deviations from Plan

Task 2 produced no separate source commit because the tracer task had already committed the exact source changes; its checks and review passed against those committed bytes. No other deviations.

## Self-Check: PASSED

- The candidate source commit and both source files are present and hash-matched.
- All three required local receipts are nonempty, contain a passing exit marker, and match the cycle-record hashes.
- The prior recovery record hash matches the saved value; hosted and preview authority remain unset and hosted cost remains unmeasured.
- The checkout remains on `main`; no hosted or preview action was performed.
