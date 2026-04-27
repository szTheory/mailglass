---
phase: 08-release-engineering-hardening
plan: "04"
subsystem: ci/workflows
tags: [ci, workflows, dependabot, sha-pins, tests, installer]
dependency_graph:
  requires: ["08-01", "08-02", "08-03"]
  provides: ["REL-06", "REL-07", "REL-08", "REL-09"]
  affects: [".github/workflows/", "test/mailglass/install/", "mix.lock"]
tech_stack:
  added: []
  patterns:
    - "GitHub Actions SHA pinning with trailing tag comments (CLAUDE.md)"
    - "ensure_block partial-marker drift detection (installer)"
key_files:
  created: []
  modified:
    - ".github/workflows/advisory-matrix.yml"
    - ".github/workflows/ci.yml"
    - ".github/workflows/publish-hex.yml"
    - ".github/workflows/post-publish-smoke.yml"
    - ".github/workflows/release-please.yml"
    - ".github/workflows/dependency-review.yml"
    - ".github/workflows/actionlint.yml"
    - ".github/workflows/pr-title.yml"
    - ".github/workflows/provider-live.yml"
    - "mix.lock"
    - "test/mailglass/install/install_idempotency_test.exs"
decisions:
  - "Drop Elixir 1.17 from advisory-matrix: mix.exs requires ~> 1.18; 1.17 was never supported"
  - "ensure_snippet drift detection deferred: requires installer source changes (non-trivial manifest schema); test-only constraint held"
  - "Dependabot branches deleted: PRs superseded by direct Task 3 SHA updates to main"
  - "googleapis/release-please-action pinned at v4.4.1 per D-08-26 (Phase 13 upgrade)"
metrics:
  duration: "~35 minutes"
  completed: "2026-04-27"
  tasks_completed: 4
  tasks_at_checkpoint: 0
---

# Phase 8 Plan 04: Workflow Debt + Dependabot Re-batch Summary

**One-liner:** Advisory-matrix Postgres fix + 1.17 row dropped; managed-block drift detection tests added; all 9 workflow files refreshed to 2026-Q2 SHAs; sigra/db_connection bumped via mix deps.update.

## Tasks Completed

| Task | Description | Commit | Status |
|------|-------------|--------|--------|
| 1 | Fix advisory-matrix.yml: add wait-for-postgres step, drop unsupported 1.17 row (REL-06) | d870d17 | Complete |
| 2 | Add managed-block drift detection tests, update skip TODOs (REL-07) | 2bbda39 | Complete (partial) |
| 3 | Refresh all third-party GitHub Actions SHA pins for 2026-Q2 (REL-09) | 5691ba0 | Complete |
| 4-preflight | Update sigra 0.2.0→0.2.5, db_connection 2.9.0→2.10.0 via mix deps.update | 076ca07 | Complete |
| 4 | Re-batch + merge the 6 closed Dependabot PRs (REL-08) | 076ca07 + comments on PRs #1-#6 | Complete |

## Task 1: Advisory Matrix Fix (REL-06)

### Problem
Two failures in advisory-matrix.yml:
- Elixir 1.18 job: missing "Wait for postgres + create test DB" step before `mix test`
- Elixir 1.17 job: compile failure (mix.exs requires `elixir: "~> 1.18"`)

### Fix Applied
- **Removed 1.17 matrix row** (Path 1 from the TODO recommendation) — mix.exs declares `elixir: "~> 1.18"` and 1.17 was never a supported target. Added explanatory comment for future reference.
- **Added "Wait for postgres + create test DB" step** between Compile and "Run advisory tests" — mirrors the identical step in ci.yml.
- **provider-live.yml**: already had complete postgres setup; no changes needed.

### 1.17 Compat Guards
No guards added — the correct fix was dropping the unsupported matrix row. The 1.17 compile failure was caused by `mix.exs` correctly rejecting a mismatched Elixir version, not a specific stdlib call that needed guarding.

## Task 2: Install Idempotency Tests (REL-07)

### Status: Partial — ensure_snippet drift deferred

The 2 existing `@tag :skip` tests verify `ensure_snippet` drift detection behavior that IS NOT YET IMPLEMENTED in the installer. They were correctly skipped at v0.1. The plan constraint "DO NOT modify the installer source itself" prevents implementing this.

### What Was Done
Added a new `describe "managed-snippet drift detection"` block with 2 tests that verify `ensure_block` partial-marker drift detection (which IS implemented):

1. **Test: partial managed-block markers trigger conflict sidecar** — removes `end_marker` from installed `config/runtime.exs`, reruns install, asserts file unchanged and `.mailglass_conflict_runtime*` sidecar written with drift reason.
2. **Test: --force resolves partial-marker drift without leaving sidecar** — same setup, but runs with `--force`, asserts both markers restored and no sidecar.

Both new tests pass 5 consecutive random-seed runs.

### Known Gap: ensure_snippet Drift (Deferred)
The 2 original `@tag :skip` tests test `ensure_snippet` drift (router snippet). They cannot pass without adding snippet-hash tracking to the manifest schema. TODOs updated from `v0.1.1` to `Phase 8 / v0.1.2 REL-07` with pointer to `apply_ensure_snippet/3`.

## Task 3: GitHub Actions SHA Pin Refresh (REL-09)

All 9 workflow files refreshed to 2026-Q2 SHAs. `actionlint` passes all files.

### SHA Refresh Table

| Action | Before SHA (version) | After SHA (version) |
|--------|---------------------|---------------------|
| actions/checkout | `11bd719` (v4.2.2) | `de0fac2` (v6.0.2) |
| erlef/setup-beam | `5304e04` (v1.22.x) | `fc68ffb` (v1.24.0) |
| actions/cache | `d4323d4` (v4.2.2) | `27d5ce7` (v5.0.5) |
| actions/github-script | `60a0d83` (v7.0.1) | `3a2844b` (v9.0.0) |
| actions/dependency-review-action | `da24556` (v4.x) | `2031cfc` (v4.9.0) |
| amannn/action-semantic-pull-request | `0723387` (v5.x) | `48f256` (v6.1.1) |
| rhysd/actionlint | `e7d448e` (v1.7.x) | `914e7df` (v1.7.12) |
| googleapis/release-please-action | `5c625bf` (v4.4.1) | **UNCHANGED** (v4.4.1) |

**release-please-action pinned at v4.4.1** per D-08-26. Added `# DO NOT bump to v5 until Phase 13 release ceremony` comment above the `uses:` line.

### No Breaking Changes
No `with:` blocks modified. SHA refresh only. All input parameters unchanged.

## Task 4: Dependabot PR Re-batch (REL-08) — Complete

### Resolution
All 6 closed Dependabot PRs cannot be reopened (head branches deleted). Their content was applied directly to main:

- **GitHub Actions PRs (#1 setup-beam, #2 dependency-review, #3 checkout, #5 cache, #6 actionlint)**: Superseded by Task 3's SHA pin refresh (commit `5691ba0`).
- **Sigra PR (#4)**: Applied via `mix deps.update sigra` — sigra 0.2.0 → 0.2.5, db_connection 2.9.0 → 2.10.0 (commit `076ca07`).

### PR Closure (REL-08 cleanup)
All 6 PRs received "superseded" comments via `gh pr comment` referencing the integrating commits:
- PRs #1, #2, #3, #5, #6 → reference `5691ba0`
- PR #4 → references `076ca07`

REL-08 closed: the dependency updates are on main; the closed PRs are documented as superseded.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed 1.17 matrix row instead of adding compat guards**
- **Found during:** Task 1
- **Issue:** mix.exs declares `elixir: "~> 1.18"` — 1.17 is not and was never a supported target. The plan described adding guards but the TODO recommended dropping the row (Path 1).
- **Fix:** Removed 1.17 matrix entry; added explanatory comment. provider-live.yml already had correct setup.
- **Files modified:** `.github/workflows/advisory-matrix.yml`
- **Commit:** d870d17

**2. [Rule 2 - Missing Critical] Added ensure_block drift detection tests instead of unskipping broken ensure_snippet tests**
- **Found during:** Task 2
- **Issue:** The 2 skipped tests assert `ensure_snippet` drift behavior that doesn't exist. Unskipping them would cause test failures. The plan constraint "DO NOT modify the installer source itself" prevents implementing the feature.
- **Fix:** Added new `describe "managed-snippet drift detection"` block testing `ensure_block` drift detection (which IS implemented). Original 2 skipped tests remain with updated TODO comments.
- **Files modified:** `test/mailglass/install/install_idempotency_test.exs`
- **Commit:** 2bbda39

**3. [Rule 3 - Blocking] Dependabot branch deletion prevents PR reopen**
- **Found during:** Task 4 pre-flight
- **Issue:** The 6 Dependabot PR branches were deleted when PRs were closed. `gh pr reopen` fails. The plan assumed branches would still exist.
- **Fix:** Applied the hex dep changes directly via `mix deps.update sigra`. GitHub Actions SHA changes were already in main from Task 3. Documented for user action.
- **Files modified:** `mix.lock`
- **Commit:** 076ca07

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

Files exist:
- `.github/workflows/advisory-matrix.yml` ✓
- `.github/workflows/ci.yml` ✓
- `test/mailglass/install/install_idempotency_test.exs` ✓
- `mix.lock` ✓

Commits exist:
- `d870d17` ✓ (fix(08-04): advisory-matrix fix)
- `2bbda39` ✓ (test(08-04): drift detection tests)
- `5691ba0` ✓ (chore(08-04): SHA refresh)
- `076ca07` ✓ (chore(08-04): sigra bump)

Actionlint: all 9 workflow files pass ✓

release-please-action SHA `5c625bfb5d1ff62eadeeb3772007f7f66fdcf071` unchanged ✓
