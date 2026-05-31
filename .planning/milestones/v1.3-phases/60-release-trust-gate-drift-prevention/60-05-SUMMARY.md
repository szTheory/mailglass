---
phase: 60-release-trust-gate-drift-prevention
plan: "05"
subsystem: reference-host
tags: [gap-closure, hex, trust-baseline, version-guard]
dependency_graph:
  requires: [60-VERIFICATION]
  provides: [current-release clean-baseline proof]
  affects: [Phase 59, Phase 60, Phase 62]
key_files:
  modified:
    - reference/host_app/mix.exs
    - reference/host_app/mix.lock
    - scripts/check_clean_baseline_hex_only.sh
    - test/mailglass/publish/ci_trust_lane_contract_test.exs
metrics:
  completed: "2026-05-31"
  tasks_completed: 3
  tasks_total: 3
---

# Phase 60 Plan 05: Reference Host Version Drift Closure Summary

## One-Liner

Closed the clean-baseline/published trust blocker by aligning the reference host to the current published release line and making the Hex-first guard version-specific.

## What Was Built

- `reference/host_app/mix.exs` pins the sibling packages to `~> 1.3`, `~> 1.3`, and `~> 0.3`.
- `reference/host_app/mix.lock` resolves `mailglass` 1.3.0, `mailglass_admin` 1.3.0, and `mailglass_inbound` 0.3.0 from Hex.
- `scripts/check_clean_baseline_hex_only.sh` now rejects both path deps and stale Hex-sourced sibling versions.
- `test/mailglass/publish/ci_trust_lane_contract_test.exs` covers stale-version, malformed-lock, non-evaluating parse, and invalid-entry cases.

## Verification Passed

- `(cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh)` — pass.
- `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/scripts/required_checks_test.exs test/mailglass/install/install_first_preview_smoke_test.exs` — 13 tests, 0 failures.
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml')); yaml.safe_load(open('.github/workflows/post-publish-smoke.yml')); print('OK')"` — pass.
- `actionlint .github/workflows/ci.yml .github/workflows/post-publish-smoke.yml` — pass.
- `MIX_ENV=test mix verify.reference_host.journey --host-root reference/host_app && bash scripts/check_trust_runner_checkpoint.sh` — pass.

## Deviations

None. The closure matches the `60-05-PLAN.md` must-haves.

## Residuals

Live post-publish observation remains normal release evidence, but it is no longer a local milestone blocker: the workflow path is wired, the reference host resolves the current release line, and local contract checks guard against drift.
