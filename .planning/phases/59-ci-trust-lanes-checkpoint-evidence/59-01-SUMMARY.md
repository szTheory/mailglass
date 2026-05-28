---
phase: 59-ci-trust-lanes-checkpoint-evidence
plan: "01"
subsystem: ci
tags:
  - ci
  - trust-evidence
  - hex-first
  - branch-protection
  - scripts
  - exunit
dependency_graph:
  requires: []
  provides:
    - scripts/check_clean_baseline_hex_only.sh
    - .github/workflows/gate-self-test.yml (check_name input)
    - test/scripts/required_checks_test.exs
  affects:
    - Plan 02 (wires check_clean_baseline_hex_only.sh into ci.yml clean-baseline lane)
    - Plan 02 (uses gate-self-test.yml check_name to verify trust-lane gate)
tech_stack:
  added: []
  patterns:
    - bash + inline elixir -e for mix.lock term evaluation (D-08 pattern)
    - GitHub Actions workflow_dispatch string input parameterization
    - ExUnit async contract test with MapSet symmetric-difference drift detection
key_files:
  created:
    - scripts/check_clean_baseline_hex_only.sh
    - test/scripts/required_checks_test.exs
  modified:
    - .github/workflows/gate-self-test.yml
decisions:
  - Used String.to_atom/1 for mix.lock map key lookup because Code.eval_string on mix.lock returns atom-keyed map (quoted keywords become atoms in Elixir)
  - Used MapSet symmetric-difference for drift detection rather than simple list equality to produce descriptive failure messages naming which side the drift is on
metrics:
  duration: "4m"
  completed: "2026-05-28T11:22:57Z"
  tasks_completed: 3
  tasks_total: 3
  files_created: 2
  files_modified: 1
---

# Phase 59 Plan 01: Wave 0 Preconditions Summary

Shipped the three Wave 0 preconditions that Plan 02 depends on: the reusable Hex-source guard script, a parameterizable gate-self-test workflow, and an ExUnit drift-detection contract test for REQUIRED_CHECKS array-vs-heredoc consistency.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create scripts/check_clean_baseline_hex_only.sh | 584541a | scripts/check_clean_baseline_hex_only.sh |
| 2 | Parameterize gate-self-test.yml with check_name input | 6a0aa79 | .github/workflows/gate-self-test.yml |
| 3 | Create test/scripts/required_checks_test.exs | 680d27b | test/scripts/required_checks_test.exs |

## Verification Results

- `shellcheck scripts/check_clean_baseline_hex_only.sh`: PASS
- `(cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh)`: PASS — all 3 siblings resolve via :hex
- `actionlint .github/workflows/gate-self-test.yml`: PASS
- `MIX_ENV=test mix test test/scripts/required_checks_test.exs`: 2 tests, 0 failures
- Stale `startswith("Tests (")` literal: 0 occurrences remaining
- Drift-detection sad path: test 1 fails with descriptive message naming "Synthetic Drift Check" as missing from heredoc
- Phase-27-lock-protection sad path: test 2 fails naming "Compile No Optional Deps" as missing lock entry

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed map key type mismatch in check_clean_baseline_hex_only.sh**
- **Found during:** Task 1 verification (happy-path run exit=1, "Hex-first violation: mailglass missing from mix.lock")
- **Issue:** The plan's RESEARCH.md template uses `Map.get(lock, name)` where `name` is a string like `"mailglass"`. However, Elixir's `Code.eval_string/1` on the `mix.lock` file returns a map with atom keys — the quoted string keywords in mix.lock syntax (`"mailglass": ...`) become atoms (`:mailglass`) when evaluated. `Map.get(lock, "mailglass")` always returns nil.
- **Fix:** Changed `Map.get(lock, name)` to `Map.get(lock, String.to_atom(name))` in the elixir -e block.
- **Files modified:** `scripts/check_clean_baseline_hex_only.sh`
- **Commit:** 584541a

## Known Stubs

None. All three files are fully functional with no stubs or placeholder data.

## Threat Surface Scan

No new security-relevant surface beyond what the plan's threat model covers. All three files:
- `check_clean_baseline_hex_only.sh`: reads lockfile via `File.read!/1` only; no exec of path argument
- `gate-self-test.yml`: `check_name` input lands inside double-quoted jq string; limited blast radius (poll watches wrong name → timeout)
- `required_checks_test.exs`: pure `File.read!/1` of script source; no eval of file content

## Self-Check: PASSED

Files exist:
- scripts/check_clean_baseline_hex_only.sh: FOUND
- .github/workflows/gate-self-test.yml: FOUND (modified)
- test/scripts/required_checks_test.exs: FOUND

Commits exist:
- 584541a: FOUND (feat(59-01): add check_clean_baseline_hex_only.sh)
- 6a0aa79: FOUND (feat(59-01): parameterize gate-self-test.yml)
- 680d27b: FOUND (test(59-01): add required_checks_test.exs)
