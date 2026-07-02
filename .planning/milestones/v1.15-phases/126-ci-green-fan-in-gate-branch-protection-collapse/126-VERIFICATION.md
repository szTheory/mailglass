---
phase: 126-ci-green-fan-in-gate-branch-protection-collapse
verified: 2026-07-01T15:31:00Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 126: CI Green Fan-in Gate + Branch-Protection Collapse Verification Report

**Phase Goal:** Collapse the 5 required leaf branch-protection contexts into a single `CI Green` aggregate job (plus `guard-release-trigger`), with release-SHA-safe `skipped` handling and a set-equality coverage meta-test so no required lane can silently drop out of `needs`.
**Verified:** 2026-07-01T15:31:00Z
**Status:** PASS
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `CI Green` aggregate job (`if: always()`, explicit `needs` of 5 required leaves) is the sole required branch-protection context alongside `guard-release-trigger`; docs-only PRs are mergeable (GATE-01) | VERIFIED | `ci_green:` job at ci.yml:1145 with `name: CI Green`, `if: always()`, `needs:` = 5 leaves; no `paths-ignore` anywhere in ci.yml; `changes` job at :23 emits boolean `code` output; all 5 leaves gate on `needs.changes.outputs.code == 'true'`; `setup_branch_protection.sh --print-expected-json` yields `contexts: ["CI Green", "Guard Release Trigger"]`, `strict: true` |
| 2 | On the release/publish path a required lane must be `success` — `skipped` required lane does NOT count as green (GATE-02) | VERIFIED | `publish-hex.yml:201-207` defines `REQUIRED_LANES` with all 5 leaf display names char-for-char; required-lane presence+success check at :249-261 blocks any non-success conclusion; old `latest.conclusion === 'success'` fast-path dropped; `blockingFailures` at :273 excludes `REQUIRED_LANES` (handled separately); `actionlint` passes |
| 3 | A coverage meta-test asserts set-equality between `setup_branch_protection.sh` `REQUIRED_CHECKS`, `ci-green.needs`, and the actual job set; fails if a required lane is dropped or permanently disabled (GATE-03) | VERIFIED | `mix test test/scripts/required_checks_test.exs`: 6 tests, 0 failures; test file contains set-equality assertion, permanently-disabled-if detector, anti-vacuity guards for all 4 parsers, reconciled `@v1_0_lock_entries` sub-test (asserts 3 lanes in `ci-green.needs`, not `REQUIRED_CHECKS`), strengthened D-04 sub-test (refutes clean-baseline in both sets) |
| 4 | `guard-release-trigger` is verified to always report; `gate-self-test.yml` stale default corrected to `CI Green` (GATE-04) | VERIFIED | `gate-self-test.yml:22` has `default: "CI Green"` (not `"Tests ("`); `mix test test/scripts/guard_release_trigger_test.exs`: 4 tests, 0 failures; `guard-release-trigger.yml` has no `paths:` or `paths-ignore:` filter confirmed by grep and by the passing test |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.github/workflows/ci.yml` | `ci_green` job, `changes` gate job, per-leaf `if:`, no `paths-ignore` | VERIFIED | `ci_green:` at :1145 (`name: CI Green`, `if: always()`, `needs:` = 5 leaves); `changes:` at :23 (hand-rolled `git diff`, reuses SHA-pinned checkout action); all 19 non-advisory jobs gated on `needs.changes.outputs.code == 'true'`; `workflow_dispatch` + anti-recursion comment preserved |
| `scripts/setup_branch_protection.sh` | `REQUIRED_CHECKS` = `{CI Green, Guard Release Trigger}`; heredoc bullets match | VERIFIED | `--print-expected-json` output confirmed: contexts exactly `["CI Green", "Guard Release Trigger"]`, `strict: true`, all non-context fields unchanged; `print_expected_text` heredoc bullets match char-for-char |
| `test/scripts/required_checks_test.exs` | Set-equality meta-test + reconciled sub-tests | VERIFIED | 6 tests present and passing: drift test, GATE-01 exact-set test, stability-lock sub-test (reconciled), D-04 sub-test (strengthened), GATE-03 set-equality test, permanently-disabled-if test; all 4 parsers have anti-vacuity guards |
| `.github/workflows/publish-hex.yml` | `REQUIRED_LANES` set of 5 leaf display names; required-lane-must-be-success check | VERIFIED | `REQUIRED_LANES` array at :201-207 with all 5 names; presence+success check at :249-261; brand-voice `Delivery blocked:` message at :260; `actionlint` passes |
| `.github/workflows/gate-self-test.yml` | `check_name` default `"CI Green"`; gate-agnostic copy | VERIFIED | `default: "CI Green"` at :22; header comment, job name, poll step name, PR title, summary block all updated to reference `CI Green` gate in brand voice; `actionlint` passes |
| `test/scripts/guard_release_trigger_test.exs` | New: no-path-filter + always-reporting-trigger invariant | VERIFIED | 4 tests: `pull_request` targets `main`, no `paths:` filter, no `paths-ignore:` filter, always-reporting `types` (opened/synchronize/reopened), job name exactly `Guard Release Trigger`; anti-vacuity guard present |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `ci_green.needs` (5 leaf keys) | `ci-green.needs` display names | `parse_ci_job_names` in meta-test maps key→name | WIRED | Test asserts every key resolves to a real defined job and the display-name set equals `@required_leaf_names` |
| `REQUIRED_LANES` in `publish-hex.yml` | 5 leaf `name:` fields in `ci.yml` | Copied char-for-char; comment notes the LD-10 seam | WIRED | All 5 display names confirmed identical (cross-file seam; Phase 128 MIXCI-03 deferred to hoist to shared source) |
| `gate-self-test.yml` poll | `CI Green` required context | `startswith(env.CHECK_NAME)` with `default: "CI Green"` | WIRED | Default corrected; poll mechanics unchanged; `"CI Green"` prefix-matches the aggregate required context |
| `guard-release-trigger.yml` job name | `REQUIRED_CHECKS` "Guard Release Trigger" in setup script | Exact string match | WIRED | Job `name: Guard Release Trigger` at yml:14 matches REQUIRED_CHECKS entry; invariant test asserts the exact match |

### Data-Flow Trace (Level 4)

Not applicable — all artifacts are CI configuration files and tests reading local files; no dynamic data rendering.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Meta-test is GREEN (GATE-03) | `mix test test/scripts/required_checks_test.exs` | 6 tests, 0 failures | PASS |
| Guard-release-trigger invariant is GREEN (GATE-04) | `mix test test/scripts/guard_release_trigger_test.exs` | 4 tests, 0 failures | PASS |
| `ci.yml` YAML is valid | `actionlint .github/workflows/ci.yml` | No output (clean) | PASS |
| `publish-hex.yml` YAML is valid | `actionlint .github/workflows/publish-hex.yml` | No output (clean) | PASS |
| `gate-self-test.yml` YAML is valid | `actionlint .github/workflows/gate-self-test.yml` | No output (clean) | PASS |
| `setup_branch_protection.sh --print-expected-json` contexts | `bash scripts/setup_branch_protection.sh --print-expected-json \| python3 -m json.tool` | `contexts: ["CI Green", "Guard Release Trigger"]`, `strict: true` | PASS |
| `paths-ignore` completely removed from `ci.yml` | `grep -n 'paths-ignore' ci.yml` | No output | PASS |
| Workflow `workflow_dispatch` preserved | `grep -q 'workflow_dispatch' ci.yml` | Match found at :8 | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| GATE-01 | 126-01-PLAN.md | `CI Green` aggregate job + branch-protection collapse; always-reports fix | SATISFIED | `ci_green` job at ci.yml:1145; `changes` gate at :23; `REQUIRED_CHECKS` = 2 contexts confirmed |
| GATE-02 | 126-02-PLAN.md | `skipped` required lane blocks publish; `REQUIRED_LANES` presence+success check | SATISFIED | `publish-hex.yml` `REQUIRED_LANES` + required-lane check; old fast-path removed |
| GATE-03 | 126-01-PLAN.md | Set-equality meta-test; no permanently-disabled lane; anti-vacuity | SATISFIED | `required_checks_test.exs` 6 tests passing; all parsers + assertions verified |
| GATE-04 | 126-02-PLAN.md | `gate-self-test` default `CI Green`; `guard-release-trigger` always-reports invariant | SATISFIED | `gate-self-test.yml` default corrected; `guard_release_trigger_test.exs` 4 tests passing |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | — | — | — |

No TBD/FIXME/XXX/placeholder debt markers in any modified file. No stub implementations. All test assertions are wired to live file content.

### Scope Fence (D-23)

`git diff --stat 8c15ce6b..HEAD -- ':!.planning'` confirms exactly 6 files changed:

```
.github/workflows/ci.yml                    | 142
.github/workflows/gate-self-test.yml        |  34
.github/workflows/publish-hex.yml           |  65
scripts/setup_branch_protection.sh          |  14
test/scripts/guard_release_trigger_test.exs | 155
test/scripts/required_checks_test.exs       | 209
```

No `lib/**`, no migrations, no routes. D-23 convergence holds.

### REQUIRED_LANES Drift Check (LD-10 seam)

Both copies of the required-lane set were verified to agree char-for-char:

**ci.yml `ci_green.needs` display names** (resolved via `parse_ci_job_names`):
- `Support Contract Core (Elixir 1.18 / OTP 27)`
- `Support Contract Admin (Elixir 1.18 / OTP 27)`
- `Compile No Optional Deps (Elixir 1.18 / OTP 27)`
- `Trust Lane Repo Head (Elixir 1.18 / OTP 27)`
- `Installer Host Smoke`

**publish-hex.yml `REQUIRED_LANES`**: identical 5 entries.

The cross-file seam is a known LD-10 accepted risk; Phase 128 MIXCI-03 is the planned single-source consolidation. Current state: no drift.

### Human Verification Required

None. All phase success criteria are mechanically verifiable from the codebase.

---

_Verified: 2026-07-01T15:31:00Z_
_Verifier: Claude (gsd-verifier)_
