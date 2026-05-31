---
phase: 60-release-trust-gate-drift-prevention
plan: "02"
subsystem: ci
tags: [ci, trust-lane, evid-02, hex-first, clean-baseline, gate-ci-green]
dependency_graph:
  requires: [60-01]
  provides: [trust_lane_clean_baseline job in ci.yml]
  affects: [.github/workflows/ci.yml, publish gate via gate-ci-green]
tech_stack:
  added: []
  patterns: [mirror-repo-head-job, sha-pinned-actions, unconditional-ci-job]
key_files:
  created: []
  modified:
    - .github/workflows/ci.yml
decisions:
  - "D-04: trust_lane_clean_baseline is publish-gate-only (NOT in REQUIRED_CHECKS) — PR merges do not depend on a Hex-baseline reference-host build. Reversible by adding one line to setup_branch_protection.sh."
  - "Two-delta mirror pattern: repo-head job copied verbatim; only the Hex-first guard step and artifact name differ."
metrics:
  duration: "~8 minutes"
  completed: "2026-05-29"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 1
  files_created: 0
---

# Phase 60 Plan 02: Trust Lane Clean Baseline (ci.yml) Summary

## One-Liner

Added unconditional `trust_lane_clean_baseline` CI job that builds the Hex-sourced reference host, asserts `:hex` resolution for all three siblings via `check_clean_baseline_hex_only.sh`, runs the full trust journey from repo root with `--host-root`, and uploads the checkpoint artifact — auto-gating publish via `gate-ci-green` without being added to REQUIRED_CHECKS.

## What Was Built

Added `trust_lane_clean_baseline` job to `.github/workflows/ci.yml`, placed between `trust_lane_repo_head` and `branch_protection_advisory`. The job is a verbatim mirror of `trust_lane_repo_head` with exactly two deltas:

**Delta 1 — Hex-first guard step** (inserted after the reference-host build, before the journey):
```yaml
- name: Assert clean Hex-first baseline
  working-directory: reference/host_app
  run: bash ../../scripts/check_clean_baseline_hex_only.sh
```
CWD is `reference/host_app` so the script reads that directory's `mix.lock` (not the root lock, which has path-dep siblings).

**Delta 2 — journey step + artifact rename:**
- Journey: `run: mix verify.reference_host.journey --host-root reference/host_app` (from repo root; no `working-directory` on this step)
- Artifact name: `trust-runner-clean-baseline-${{ github.run_id }}` (was `trust-runner-repo-head-*`)

Unchanged from the template: postgres service block, env vars, checkout/setup-beam/cache/install-deps/wait-for-postgres steps, reference-host build step, checkpoint validator, print-SHA step, and upload block (`if-no-files-found: error`, `retention-days: 90`, exact `path: tmp/mailglass_trust_runner/checkpoint.json`).

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add trust_lane_clean_baseline job to ci.yml | a64e802 | .github/workflows/ci.yml (+81 lines) |

## Verification Passed

All automated checks from the plan's `<verify>` block:
- `grep -q '^  trust_lane_clean_baseline:'` — passes
- `grep -q 'verify.reference_host.journey --host-root reference/host_app'` — passes
- `grep -q 'trust-runner-clean-baseline-'` — passes
- `grep -q 'check_clean_baseline_hex_only.sh'` — passes
- `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/ci.yml'))"` — exits 0 (YAML valid)
- No `if:` or `needs:` at job level in the new block
- Journey step has no `working-directory:` (runs from repo root)
- `scripts/setup_branch_protection.sh` unchanged (lane absent from REQUIRED_CHECKS)
- `publish-hex.yml` unchanged
- Only `ci.yml` modified (confirmed via `git diff --name-only`)

## Deviations from Plan

None — plan executed exactly as written. All action `uses:` lines reuse the exact SHA-pinned forms already present in `ci.yml` (Pitfall 5). The job is unconditional with no `if:` or `needs:` (Pitfall 1 avoided).

## Known Stubs

None. The job wires existing scripts that are fully implemented.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes introduced. The CI job runs only first-party scripts with existing SHA-pinned third-party actions.

## Self-Check: PASSED

- `.github/workflows/ci.yml` exists and contains `trust_lane_clean_baseline:` — FOUND
- Commit `a64e802` exists in git log — FOUND
- `publish-hex.yml` unmodified — CONFIRMED
- `release-please.yml` unmodified — CONFIRMED
- `release-please-config.json` unmodified — CONFIRMED
- `.release-please-manifest.json` unmodified — CONFIRMED
- `scripts/setup_branch_protection.sh` unmodified — CONFIRMED
