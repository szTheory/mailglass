---
phase: 51-stability-closeout
plan: "02"
status: complete
completed_at: 2026-05-26T13:40:08Z
requirements: [CLOSE-02]
key_files:
  created:
    - scripts/verify-branch-protection.sh
  modified:
    - scripts/setup_branch_protection.sh
    - .github/workflows/branch-protection-drift.yml
    - .github/workflows/ci.yml
    - MAINTAINING.md
commits:
  - c6c71cf
  - b99930e
---

# Phase 51 Plan 02 Summary

## Outcome

Branch protection is back to repo-owned truth instead of stale script strings.
The repo now has one owner-apply path, one read-only verifier, an advisory CI
job, and live `main` protection aligned to the current support-contract buckets.

## What Changed

- Replaced the stale required-check list in `scripts/setup_branch_protection.sh`
  with the exact current contexts:
  `Support Contract Core`, `Support Contract Admin`, and
  `Compile No Optional Deps` (all `Elixir 1.18 / OTP 27`).
- Added `scripts/verify-branch-protection.sh` as a read-only `gh api` verifier
  with `--print-expected` and `--print-expected-json` modes plus normalized
  live-state comparison.
- Updated `MAINTAINING.md` to document the exact required contexts and the split
  between owner-applied mutation and read-only verification.
- Split workflow responsibilities:
  `.github/workflows/branch-protection-drift.yml` now only re-applies desired
  state with owner credentials, while `.github/workflows/ci.yml` runs a
  non-blocking `Branch Protection Advisory` verifier.
- Applied the desired ruleset to the live GitHub branch-protection endpoint and
  re-verified it successfully.

## Verification

- `bash -n scripts/setup_branch_protection.sh scripts/verify-branch-protection.sh`
- `bash scripts/verify-branch-protection.sh --print-expected-json | jq -e '.required_status_checks.contexts == ["Support Contract Core (Elixir 1.18 / OTP 27)","Support Contract Admin (Elixir 1.18 / OTP 27)","Compile No Optional Deps (Elixir 1.18 / OTP 27)"] and .required_status_checks.strict == true and .enforce_admins == false and .required_pull_request_reviews == null and .restrictions == null and .allow_force_pushes == false and .allow_deletions == false and .block_creations == false and .required_conversation_resolution == false and .lock_branch == false and .allow_fork_syncing == false'`
- `actionlint .github/workflows/branch-protection-drift.yml .github/workflows/ci.yml`
- `bash scripts/verify-branch-protection.sh main`

## Deviations from Plan

### 1. [Rule 1 - Live API truth] `allow_fork_syncing` cannot stay true without a locked branch

The original plan assumptions expected `allow_fork_syncing: true` while also
keeping `lock_branch: false`. A live `gh api` apply+verify run showed GitHub
returns `allow_fork_syncing: false` in that configuration, so the repo-owned
expected JSON now matches the actual platform behavior instead of encoding a
false desired state.

## Self-Check: PASSED
