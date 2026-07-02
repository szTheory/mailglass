---
phase: 126-ci-green-fan-in-gate-branch-protection-collapse
plan: "01"
subsystem: ci-pipeline
tags: [ci, github-actions, branch-protection, gate, test]
status: complete

dependency_graph:
  requires: [phase-125]
  provides: [ci_green-aggregate-job, changes-detection-gate, collapsed-required-checks, set-equality-meta-test]
  affects: [.github/workflows/ci.yml, scripts/setup_branch_protection.sh, test/scripts/required_checks_test.exs]

tech_stack:
  added: []
  patterns:
    - "changes detection gate job (hand-rolled git diff, no new SHA-pinned actions)"
    - "CI Green fan-in aggregate (if: always(), tolerates skipped, fails on failure/cancelled)"
    - "set-equality meta-test with text-based ci.yml parsing"

key_files:
  modified:
    - .github/workflows/ci.yml
    - scripts/setup_branch_protection.sh
    - test/scripts/required_checks_test.exs

decisions:
  - "Hand-rolled git diff gate (not dorny/paths-filter): avoids a new SHA-pinned action dep per CLAUDE.md; handles pull_request/push/workflow_dispatch event variants"
  - "ci_green verdict uses hardcoded needs.<job>.result checks (not toJSON(needs)) because the step body list is validated by the GATE-03 meta-test's set-equality assertion"
  - "trust_lane_clean_baseline gated on changes (was previously unconditional) so docs-only PRs don't trigger it; its 'publish-gate-only' comment updated accordingly"

metrics:
  duration_minutes: 8
  completed_date: "2026-07-01"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 3
  tests_added: 5
---

# Phase 126 Plan 01: CI Green Fan-in Gate + Branch-Protection Collapse Summary

One-liner: Single `CI Green` aggregate job (fan-in over 5 required leaves with `if: always()`) replaces the 5-entry `REQUIRED_CHECKS`, with a `changes` gate fixing the `paths-ignore` stuck-pending trap and a set-equality meta-test guarding against silent lane drop-out.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Add `changes` detection gate + `CI Green` aggregate job; drop workflow-level paths-ignore | db876152 |
| 2 | Collapse `REQUIRED_CHECKS` to `{CI Green, Guard Release Trigger}` | 9512319f |
| 3 | Extend `required_checks_test.exs` to set-equality coverage meta-test + reconciled sub-tests | ce037eda |

## What Was Built

### Task 1: ci.yml restructure

**`changes` job** (new first job, key `changes`, display "Detect Non-Doc Changes"):
- Reuses the already-SHA-pinned `actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0`
- Hand-rolled `git diff --name-only` with three event branches:
  - `workflow_dispatch`: always `code=true` (release dispatches must run the full matrix)
  - `pull_request`: diff `github.event.pull_request.base.sha...HEAD`; `code=false` when all changed paths are under `.planning/` or `prompts/`
  - `push`: diff `github.event.before...github.sha`; handles the zero-SHA first-push edge case
- Exposes `code` boolean via `GITHUB_OUTPUT` and `outputs:` map

**Leaf gating**: All 19 non-advisory jobs now have `needs: [changes]` and `if: needs.changes.outputs.code == 'true'`. `branch_protection_advisory` is intentionally not gated (harmless to always run).

**`ci_green` job** (new last job, after `branch_protection_advisory`):
- `name: CI Green`
- `if: always()` — runs regardless of whether leaves ran or were skipped
- `needs: [compile_no_optional_deps, installer_host_smoke, support_contract_core, support_contract_admin, trust_lane_repo_head]` — exactly the 5 required leaves
- Single step evaluates each `needs.<job>.result`: fails with `exit 1` and brand-voice "Delivery blocked: required CI lane(s) did not pass: …" message on any `failure` or `cancelled` result; treats `skipped` and `success` as OK
- `workflow_dispatch` trigger and anti-recursion comment preserved (publish-hex gate still finds ci.yml runs on dispatched refs)

**GATE-01 proof — docs-only PR is mergeable:**
1. A PR touching only `.planning/**` or `prompts/**` paths triggers ci.yml (no workflow-level `paths-ignore` anymore)
2. The `changes` job runs and emits `code=false`
3. All 19 gated leaves have `if: needs.changes.outputs.code == 'true'` → all skip
4. `ci_green` has `if: always()` → runs, sees 5 `skipped` results, none are `failure`/`cancelled` → exits 0 → posts `success` to GitHub
5. PR is mergeable; never stuck "Expected — waiting on status"

**GATE-01 proof — red leaf reds CI Green:**
1. A PR touching `lib/**` emits `code=true`
2. Leaves run; a failing leaf (e.g. `support_contract_core` returns `failure`)
3. `ci_green` runs (`if: always()`), detects `failure` → `exit 1` → posts `failure`
4. Branch protection blocks the merge

### Task 2: setup_branch_protection.sh collapse

`REQUIRED_CHECKS` array (was 5 entries):
```
"CI Green"
"Guard Release Trigger"
```

`print_expected_text` heredoc bullets updated to match exactly:
```
  - CI Green
  - Guard Release Trigger
```

`Guard Release Trigger` is newly added as a required context (it was not previously in `REQUIRED_CHECKS`). `strict: true` and all non-context fields in `expected_json` are unchanged.

### Task 3: required_checks_test.exs meta-test

**New parsers added:**
- `parse_ci_green_needs/1`: text-scans ci.yml for the `ci_green:` job block and returns its `needs:` list as a `MapSet` of job keys
- `parse_ci_job_names/1`: returns a `%{job_key => display_name}` map for all defined ci.yml jobs
- `parse_ci_job_ifs/1`: returns a `%{job_key => if_expression}` map for jobs that have an `if:` clause

**New / rewritten tests (6 total, up from 3):**

1. **"REQUIRED_CHECKS array and print_expected_text bullets stay in sync"** — existing drift test; now naturally validates the 2-context set
2. **"REQUIRED_CHECKS contains exactly {CI Green, Guard Release Trigger} (GATE-01)"** — asserts set-equality of the collapsed context array
3. **"Phase 27 stability-lock entries are in ci_green.needs (not REQUIRED_CHECKS)"** — reconciled `@v1_0_lock_entries` sub-test: asserts the 3 stability-lock lanes are in `ci_green.needs` display names, NOT in `REQUIRED_CHECKS`
4. **"clean-baseline lane is NOT a required branch-protection check AND NOT in ci_green.needs (D-04)"** — strengthened D-04 sub-test: refutes membership in both `REQUIRED_CHECKS` and `ci_green.needs`
5. **"ci_green.needs set-equality: every key resolves to a defined job and display names match required leaf set (GATE-03)"** — core set-equality test: (i) every needs key is a real defined job; (ii) needs_display set-equals `@required_leaf_names`; anti-vacuity guards for both new parsers
6. **"no required CI leaf is permanently if:-disabled (GATE-03)"** — rejects constant-false `if:` expressions on any `ci_green.needs` leaf; path-conditional `if:` (like `needs.changes.outputs.code == 'true'`) is explicitly allowed

## Verification Results

| Command | Result |
|---------|--------|
| `actionlint .github/workflows/ci.yml` | PASS (no output) |
| `grep -qE '^  ci_green:' ci.yml` | PASS |
| `grep -q 'name: CI Green' ci.yml` | PASS |
| `grep -q 'if: always()' ci.yml` | PASS |
| `grep -qE '^  changes:' ci.yml` | PASS |
| `! grep -q 'paths-ignore' ci.yml` | PASS |
| `grep -q 'needs.changes.outputs' ci.yml` | PASS |
| `grep -q 'workflow_dispatch' ci.yml` | PASS |
| `jq -e '.required_status_checks.contexts == ["CI Green", "Guard Release Trigger"] and .required_status_checks.strict == true and .enforce_admins == false'` | PASS |
| `grep -q '  - CI Green'` (--print-expected) | PASS |
| `grep -q '  - Guard Release Trigger'` (--print-expected) | PASS |
| `! grep -q 'Support Contract Core'` (--print-expected) | PASS |
| `mix test test/scripts/required_checks_test.exs` | PASS (6 tests, 0 failures) |

## Deviations from Plan

**1. [Rule 1 - Cleanup] Removed redundant `parse_ci_green_needs` implementation**
- **Found during:** Task 3 implementation
- **Issue:** Initial draft had a two-function approach (`parse_ci_green_needs` calling `do_parse_ci_green_needs`), where the outer function discarded its own result. This was overcomplicated.
- **Fix:** Collapsed to a single clean function using `Enum.reduce_while` with inline logic.
- **Files modified:** `test/scripts/required_checks_test.exs`
- **Commit:** ce037eda (same task commit)

**2. [Rule 2 - Missing functionality] Removed redundant duplicate test**
- **Found during:** Task 3 review
- **Issue:** Had two tests both asserting REQUIRED_CHECKS is exactly {CI Green, Guard Release Trigger} — the standalone "(iii)" test duplicated the "contains exactly" test.
- **Fix:** Removed the duplicate; coverage remains complete.
- **Files modified:** `test/scripts/required_checks_test.exs`
- **Commit:** ce037eda (same task commit)

## Known Stubs

None. All assertions are wired to live file content.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Changes are confined to `.github/workflows/ci.yml`, `scripts/setup_branch_protection.sh`, and `test/scripts/required_checks_test.exs` — all within the D-23 scope fence.

## Self-Check: PASSED

- FOUND: `.github/workflows/ci.yml`
- FOUND: `scripts/setup_branch_protection.sh`
- FOUND: `test/scripts/required_checks_test.exs`
- FOUND: commit db876152 (Task 1)
- FOUND: commit 9512319f (Task 2)
- FOUND: commit ce037eda (Task 3)
