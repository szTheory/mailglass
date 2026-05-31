---
phase: 60-release-trust-gate-drift-prevention
status: passed
verification_mode: automated
manual_uat: not_required
updated: 2026-05-31T17:09:00Z
gaps: []
---

# Phase 60 Verification

## Automated Evidence

| Check | Command / CI lane | Result |
|-------|-------------------|--------|
| Clean-baseline CI job is present and wired to the Hex-first guard, trust journey, checkpoint validation, and clean-baseline artifact upload | `rg -n 'trust_lane_clean_baseline|check_clean_baseline_hex_only|verify.reference_host.journey --host-root reference/host_app|trust-runner-clean-baseline' .github/workflows/ci.yml test/mailglass/publish/ci_trust_lane_contract_test.exs` | pass |
| Published trust journey, OPS-01 guard, failure tracking, and success-only tracker closeout are present | `rg -n 'published-trust-journey|close-publish-smoke-tracker-on-success|trust-runner-published|check_clean_baseline_hex_only|verify.reference_host.journey --host-root reference/host_app' .github/workflows/post-publish-smoke.yml test/mailglass/publish/post_publish_smoke_contract_test.exs` | pass |
| Phase 60 workflow/doc/branch-protection contract suite passes | `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/scripts/required_checks_test.exs test/mailglass/install/install_first_preview_smoke_test.exs` | pass: 13 tests, 0 failures |
| CI and post-publish workflow YAML parse | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml')); yaml.safe_load(open('.github/workflows/post-publish-smoke.yml')); print('OK')"` | pass |
| CI and post-publish workflow actionlint | `actionlint .github/workflows/ci.yml .github/workflows/post-publish-smoke.yml` | pass |
| Reference host siblings resolve from Hex at the current release line | `(cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh)` | pass: `mailglass` 1.3.0, `mailglass_admin` 1.3.0, and `mailglass_inbound` 0.3.0 all resolve via `:hex` |
| Published-host trust journey emits a valid checkpoint locally | `MIX_ENV=test mix verify.reference_host.journey --host-root reference/host_app && bash scripts/check_trust_runner_checkpoint.sh` | pass: schema `trust_runner.v1`, five stages |

## Gap Closure

The previous blocker was stale reference-host release-line truth: `reference/host_app` was still pinned and locked to `mailglass` 1.2.0, `mailglass_admin` 1.2.0, and `mailglass_inbound` 0.2.0. That drift is closed:

- `reference/host_app/mix.exs` now pins `mailglass` and `mailglass_admin` to `~> 1.3`, and `mailglass_inbound` to `~> 0.3`.
- `reference/host_app/mix.lock` resolves those siblings from Hex at 1.3.0, 1.3.0, and 0.3.0.
- `scripts/check_clean_baseline_hex_only.sh` is version-specific, so Hex-source success cannot hide stale published-version drift.
- The clean-baseline and published-version trust lanes both run the guard before trust-journey proof.

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| EVID-02 | satisfied | Clean-baseline lane and guard prove current-release Hex resolution and block path-dependency leakage. |
| EVID-03 | satisfied | `post-publish-smoke.yml` contains the `published-trust-journey` job, runs the version-guarded reference-host journey, validates the checkpoint, and uploads `trust-runner-published-${{ github.run_id }}`. |
| OPS-01 | satisfied | Published install guard detects the hackney/api_client regression before compile and is covered by contract tests. |
| OPS-02 | satisfied | Release docs and workflow checks require green trust evidence before closeout. |

## Residuals

No Phase 60 verification gaps remain. The next live post-publish run should still be observed as normal release evidence, but the local milestone-blocking drift has been closed and regression-guarded.
