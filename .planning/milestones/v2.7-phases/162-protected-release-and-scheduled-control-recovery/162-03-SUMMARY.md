---
phase: 162-protected-release-and-scheduled-control-recovery
plan: 03
subsystem: repository hygiene control reporting
tags: [elixir, mix-task, github-actions, json, exunit, repository-hygiene]
requires:
  - phase: 162-protected-release-and-scheduled-control-recovery
    provides: protected release reconciliation evidence from Plan 01
provides:
  - explicit pass, blocked, and cannot-check repository-hygiene results
  - one JSON result map used by CLI, workflow summary, and uploaded artifact
  - fail-closed nonzero exit behavior for both non-pass states
affects: [162-05, repository-hygiene, scheduled-control-evidence]
tech-stack:
  added: []
  patterns: [three-state aggregate precedence, boundary-only status serialization, artifact-first workflow summary]
key-files:
  created: []
  modified:
    - dev/mix/tasks/mailglass.repo.hygiene.ex
    - test/mix/tasks/mailglass.repo.hygiene_test.exs
    - .github/workflows/repo-hygiene.yml
key-decisions:
  - "Evidence-unavailable checks take aggregate precedence over confirmed policy blocks so an incomplete observation never becomes a complete policy verdict."
  - "The Mix task owns the status and reason; Actions only renders and uploads its JSON output."
patterns-established:
  - "Keep :cannot_check internal and serialize it as cannot-check only at text and JSON boundaries."
  - "Use a persisted result artifact as the sole input for workflow summaries, including expected non-pass runs."
requirements-completed: []
coverage:
  - id: D1
    description: "Repository hygiene classifies complete checks as pass, policy failures as blocked, and unavailable evidence as cannot-check with fail-closed precedence and exits."
    requirement: AUTO-04
    verification:
      - kind: unit
        ref: mix test test/mix/tasks/mailglass.repo.hygiene_test.exs
        status: pass
      - kind: integration
        ref: mix test
        status: pass
    human_judgment: false
  - id: D2
    description: "The GitHub Actions summary and artifact render the identical JSON result without recomputing a verdict."
    requirement: AUTO-04
    verification:
      - kind: unit
        ref: test/mix/tasks/mailglass.repo.hygiene_test.exs#workflow summary reads aggregate result and checks from the audit JSON artifact
        status: pass
    human_judgment: false
metrics:
  duration: 4m
  completed: 2026-08-22
  tasks_completed: 2
  files_modified: 3
status: complete
---

# Phase 162 Plan 03: Repository Hygiene Three-State Reporting Summary

**Repository hygiene now preserves pass, blocked, and cannot-check evidence through its Mix CLI, Actions summary, and retained JSON artifact without expanding workflow authority.**

## Accomplishments

- Replaced ambiguous `:unknown` check outcomes with `:cannot_check`, with explicit aggregate precedence over blocked and pass.
- Kept confirmed `DRIFT:` branch-protection evidence blocked while missing credentials, tools, verifiers, upstreams, and remote access remain cannot-check.
- Added a top-level reason to the Mix result map; Actions reads its status, reason, and each check exclusively from `$RUNNER_TEMP/repo-hygiene.json`.
- Preserved nonzero exits for both honest non-pass statuses and all existing workflow triggers, permissions, topology, concurrency, and pinned actions.

## Task Commits

1. **Task 1 RED: Make the repo-hygiene CLI three-state and fail closed** — `8286c3b3` (failing contract tests)
2. **Task 1 GREEN: Make the repo-hygiene CLI three-state and fail closed** — `52f2fe35` (three-state classification and serialization)
3. **Task 2: Render and retain exactly the Mix task result in Actions** — `ac00bd24` (artifact-first summary contract)

## Verification

- `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs` — passed, 13 tests.
- `mix test` — passed; pre-existing test-load-filter and optional OTLP-exporter warnings remained non-failing.
- `git diff --check` — passed before both task commits.

## Decisions Made

- Aggregate cannot-check outranks blocked: unavailable evidence prevents a complete policy verdict even if another established check blocks.
- The result map supplies the summary’s status and reason, preventing a shell-derived summary from disagreeing with the uploaded artifact.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Next Phase Readiness

Plan 05 can cite the same artifact-first contract when it records separate control and scheduled evidence. AUTO-04 remains pending until that plan captures or honestly records the applicable scheduled observation.

## Self-Check: PASSED

- All three implementation and test files exist on disk.
- RED and GREEN commits `8286c3b3` and `52f2fe35`, plus workflow commit `ac00bd24`, exist in Git history.
- No stubs, skipped tests, unrun verification, or new trust surface was introduced.
