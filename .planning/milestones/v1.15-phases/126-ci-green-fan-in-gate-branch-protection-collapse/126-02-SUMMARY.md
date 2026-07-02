---
phase: 126-ci-green-fan-in-gate-branch-protection-collapse
plan: "02"
subsystem: ci-pipeline
tags: [ci, release-gate, branch-protection, gate-02, gate-04]
status: complete

dependency_graph:
  requires: [126-01]
  provides: [GATE-02, GATE-04]
  affects: [.github/workflows/publish-hex.yml, .github/workflows/gate-self-test.yml, test/scripts/guard_release_trigger_test.exs]

tech_stack:
  added: []
  patterns:
    - Explicit REQUIRED_LANES presence+success check on the publish path (replaces skip-tolerant blockingFailures)
    - Brand-voice Delivery blocked message naming offending lane(s) with conclusion
    - Anti-vacuity guard in ExUnit invariant test

key_files:
  modified:
    - .github/workflows/publish-hex.yml
    - .github/workflows/gate-self-test.yml
  created:
    - test/scripts/guard_release_trigger_test.exs

decisions:
  - "Removed the early latest.conclusion === 'success' fast-path entirely; the publish path always runs the required-lane presence+success check (GATE-02)"
  - "Non-required, non-advisory failures still block via a separate blockingFailures pass after the required-lane check"
  - "Parser in guard_release_trigger_test uses 4+-space-indent child-line collection rather than brittle full-YAML parse (no yaml_elixir dep in this repo)"

metrics:
  duration_seconds: 227
  completed_date: "2026-07-01"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 2
---

# Phase 126 Plan 02: Release-gate GATE-02/GATE-04 hardening Summary

Explicit required-lane-must-be-success check in `publish-hex.yml`, corrected `gate-self-test.yml` default to `CI Green`, and an executable invariant locking the `guard-release-trigger` always-reports property.

## What Was Built

### Task 1 — Enforce required-lane-must-be-success on the publish path (GATE-02)

**File:** `.github/workflows/publish-hex.yml` `gate-ci-green` job, "Verify CI is green on tagged SHA" step.

**REQUIRED_LANES set as-built:**

```
Support Contract Core (Elixir 1.18 / OTP 27)
Support Contract Admin (Elixir 1.18 / OTP 27)
Compile No Optional Deps (Elixir 1.18 / OTP 27)
Trust Lane Repo Head (Elixir 1.18 / OTP 27)
Installer Host Smoke
```

Copied char-for-char from `ci.yml` job `name:` fields. A comment in the step body notes this set must stay identical to `ci_green.needs` (the LD-10 shared `ci_lanes` seam; Phase 128 MIXCI-03 will hoist to one source).

**Required-lane verdict change:**

The old code had a two-stage approach: first an early-return fast-path (`if (latest.conclusion === 'success') { return; }`), then a `blockingFailures` filter with `j.conclusion !== 'success' && j.conclusion !== 'skipped'` that let skipped lanes pass. Both are replaced:

- **Fast-path: DROPPED.** A run where a required lane path-skipped can still report overall `success` — so early-returning on overall `success` would bless a skipped required lane. The step now always fetches jobs and runs the required-lane check.
- **Required-lane check (new):** For each lane in `REQUIRED_LANES`, find the matching job by exact display name. If the job is missing OR `conclusion !== 'success'` (covers `skipped`, `failure`, `cancelled`, `null`), collect as `requiredBlocking`. If any blocking entry exists, `core.setFailed` with a brand-voice message: `Delivery blocked: required CI lane(s) did not pass on SHA <sha>: <list of lane (conclusion|missing)>`.

**Advisory lanes: UNCHANGED.** `ADVISORY_LANES` array (`Operator Browser Gate`, `Demo Browser Evidence`) and `isAdvisory()` (prefix + `/ Advisory \(/` regex) stay intact. Advisory lanes keep skip-tolerance via a separate `blockingFailures` pass (after the required-lane check passes) and a `core.warning` for advisory failures.

### Task 2 — gate-self-test stale default + guard-release-trigger always-reports invariant (GATE-04)

**gate-self-test.yml changes:**

| Location | Before | After |
|---|---|---|
| Header comment | "proves the Tests gate blocks failing PRs" | "proves the required CI Green gate blocks failing PRs" |
| `check_name` input description | example "Tests (" | references CI Green aggregate and Trust Lane leaf example |
| `check_name` input default | `"Tests ("` | `"CI Green"` |
| Job `name:` | `Verify Tests gate blocks failing PRs` | `Verify CI Green gate blocks failing PRs` |
| Poll step `name:` | `Poll for Tests check completion` | `Poll for CI Green check completion` |
| PR title in open step | `[gate-self-test] verify Tests gate blocks failing PRs` | `[gate-self-test] verify CI Green gate blocks failing PRs` |
| Summary heading | `## Gate Self-Test Result` | `## CI Green Gate Self-Test Result` |
| Summary block message | "Gate did NOT block ... — REL-10 has regressed." | "Delivery blocked: CI Green gate did NOT block the failing PR — the gate has regressed." |

Poll mechanics (`gh pr checks --required` + `startswith(env.CHECK_NAME)`) are unchanged — `"CI Green"` matches the aggregate required context by prefix.

**New: `test/scripts/guard_release_trigger_test.exs`** (`Mailglass.Scripts.GuardReleaseTriggerTest`, `async: true`):

Four assertions (all pass against current unweakened `guard-release-trigger.yml`):

1. **pull_request trigger targets main** — the `  pull_request:` block contains `main`.
2. **No `paths:` filter** — the trigger block has no `paths:` key (a path filter would let some PRs skip the workflow, leaving the required context unreported → stuck "Expected").
3. **No `paths-ignore:` filter** — same green-but-BLOCKED risk.
4. **Always-reporting `types:`** — `opened`, `synchronize`, and `reopened` are all present (guarantees a fresh status on every PR update to main).
5. **Job display name** — exactly `Guard Release Trigger` (the string registered as the required branch-protection context; a mismatch would mean the context silently never reports).

**Anti-vacuity guard:** `parse_workflow/0` returns `nil` for the trigger block if the `  pull_request:` line is absent; the tests `refute pr_trigger_block == nil` / `assert pr_trigger_block != nil` to fail loudly on a format change rather than vacuously passing.

## Verification Results

| Command | Result |
|---|---|
| `actionlint .github/workflows/publish-hex.yml` | PASS |
| `grep -q 'REQUIRED_LANES' publish-hex.yml` | PASS |
| `grep -q 'Installer Host Smoke' publish-hex.yml` | PASS |
| `grep -q 'Trust Lane Repo Head (Elixir 1.18 / OTP 27)' publish-hex.yml` | PASS |
| `grep -q 'Delivery blocked' publish-hex.yml` | PASS |
| `actionlint .github/workflows/gate-self-test.yml` | PASS |
| `grep -q 'default: "CI Green"' gate-self-test.yml` | PASS |
| `! grep -q 'default: "Tests ("' gate-self-test.yml` | PASS |
| `! grep -q 'paths-ignore' guard-release-trigger.yml` | PASS |
| `! grep -qE '^\s*paths:' guard-release-trigger.yml` | PASS |
| `mix test test/scripts/guard_release_trigger_test.exs` | PASS (4 tests, 0 failures) |

## Commits

| Task | Commit | Description |
|---|---|---|
| Task 1 | `767ae897` | `ci(126-02): enforce required-lane-must-be-success on publish path (GATE-02)` |
| Task 2 | `2ac92c98` | `ci(126-02): fix gate-self-test stale default + add guard-release-trigger invariant (GATE-04)` |

## Deviations from Plan

None — plan executed exactly as written. The `parse_workflow/0` helper in the invariant test uses a 4+-space-indent-collection approach (rather than a full YAML parser) because `yaml_elixir` is not a project dependency. This is within the plan's "otherwise a scoped text parse of the `on:`/`pull_request:` block is acceptable" allowance.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. All changes are workflow YAML and a test file reading local files.

## Self-Check: PASSED

- `.github/workflows/publish-hex.yml` — FOUND (modified)
- `.github/workflows/gate-self-test.yml` — FOUND (modified)
- `test/scripts/guard_release_trigger_test.exs` — FOUND (created)
- Commit `767ae897` — FOUND
- Commit `2ac92c98` — FOUND
