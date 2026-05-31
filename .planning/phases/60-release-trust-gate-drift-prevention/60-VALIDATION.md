---
phase: 60
slug: release-trust-gate-drift-prevention
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
validated: 2026-05-31
---

# Phase 60 - Validation Strategy

> Retroactive Nyquist audit completed on 2026-05-31.
> The audit found one drift regression: `trust_lane_clean_baseline` was present
> in the Phase 60 summary commit but missing from the current `ci.yml`. The job
> has been restored and locked with an ExUnit workflow contract test.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18+ / OTP 27), shell guards, GitHub Actions workflow contracts |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/scripts/required_checks_test.exs test/mailglass/install/install_first_preview_smoke_test.exs` |
| **Workflow parse command** | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml')); yaml.safe_load(open('.github/workflows/post-publish-smoke.yml')); print('OK')"` |
| **Workflow lint command** | `actionlint .github/workflows/ci.yml .github/workflows/post-publish-smoke.yml` |
| **Full suite command** | `MIX_ENV=test mix test` |
| **Estimated runtime** | < 5 seconds for scoped ExUnit contracts; CI-only trust journeys run in GitHub Actions |

## Sampling Rate

- **After every workflow edit:** Run the scoped ExUnit workflow contracts, YAML parse command, and `actionlint`.
- **After every docs/branch-protection edit:** Run `test/mailglass/publish/maintaining_release_gate_contract_test.exs` and `test/scripts/required_checks_test.exs`.
- **Before milestone trust claim / v1.3 closeout:** Confirm one green `post-publish-smoke` run with `consumer-install` and `published-trust-journey` successful and a `trust-runner-published-*` artifact.
- **Max local feedback latency:** < 5 seconds for deterministic contract coverage.

## Per-Requirement Verification Map

| Requirement | Behavior | Test Type | Automated Command / Check | Where it runs | File Exists | Status |
|-------------|----------|-----------|----------------------------|---------------|-------------|--------|
| EVID-02 | Clean-baseline lane enforces Hex-first resolution, blocks path leakage | Workflow contract + shell exit-code | `mix test test/mailglass/publish/ci_trust_lane_contract_test.exs`; CI step runs `cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh` | local + CI | yes | covered |
| EVID-02 | Clean-baseline lane stays OUT of `REQUIRED_CHECKS` (D-04) | ExUnit | `mix test test/scripts/required_checks_test.exs`; asserts clean-baseline name absent from parsed checks | local + CI | yes | covered |
| EVID-02/03 | Checkpoint contract holds | shell exit-code + workflow contract | `bash scripts/check_trust_runner_checkpoint.sh` in both trust lanes; workflow tests assert the step remains wired | CI + local contract | yes | covered |
| EVID-03 | Published-version journey runs post-publish before trust claims | Workflow contract + CI job green | `mix test test/mailglass/publish/post_publish_smoke_contract_test.exs`; `published-trust-journey` job uploads `trust-runner-published-*` | local + CI-only runtime | yes | covered |
| OPS-01 | Installer sets `config :swoosh, :api_client, false` (root-cause) | ExUnit | `mix test test/mailglass/install/install_first_preview_smoke_test.exs` | local + CI | yes | covered |
| OPS-01 | No hackney/finch reintroduced on a fresh PUBLISHED host | Workflow contract + CI grep exit-code | `mix test test/mailglass/publish/post_publish_smoke_contract_test.exs`; `consumer-install` guard checks `runtime.exs` and `mix.lock` | local + CI-only runtime | yes | covered |
| OPS-02 | `MAINTAINING.md` requires green trust evidence; no stale approval gate | ExUnit doc contract | `mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs` | local + CI | yes | covered |

## Wave 0 Requirements

- [x] `.github/workflows/ci.yml` `trust_lane_clean_baseline` job covers EVID-02 and is restored in the current tree.
- [x] `.github/workflows/post-publish-smoke.yml` `published-trust-journey` job covers EVID-03.
- [x] `.github/workflows/post-publish-smoke.yml` `consumer-install` hackney/api_client guard covers OPS-01 live signal.
- [x] `test/mailglass/publish/maintaining_release_gate_contract_test.exs` covers OPS-02 doc drift.
- [x] `test/scripts/required_checks_test.exs` refutes clean-baseline membership in `REQUIRED_CHECKS`.
- [x] `test/mailglass/publish/ci_trust_lane_contract_test.exs` locks the clean-baseline lane shape.
- [x] `test/mailglass/publish/post_publish_smoke_contract_test.exs` locks the published journey, live OPS-01 guard, and success-only tracker closeout.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real post-publish run is green | EVID-03 / OPS-01 | Requires a live published version and GitHub Actions runtime | Observe one green `post-publish-smoke` run after publish/cron/`workflow_dispatch`; confirm `consumer-install`, `published-trust-journey`, and `retracted-check` are green and `trust-runner-published-*` was uploaded |
| Closeout evidence for issue #32 | OPS-01 | Issue closeout is owned by GitHub Actions success job | Confirm `close-publish-smoke-tracker-on-success` comments with run/artifact evidence and closes the tracker only after the same green run |

## Validation Audit 2026-05-31

| Metric | Count |
|--------|-------|
| Gaps found | 4 |
| Resolved | 4 |
| Escalated | 0 |

### Gaps Resolved

- Restored missing `trust_lane_clean_baseline` in `.github/workflows/ci.yml`.
- Added `test/mailglass/publish/ci_trust_lane_contract_test.exs` to prevent clean-baseline lane drift.
- Extended `test/mailglass/publish/post_publish_smoke_contract_test.exs` to cover the published trust journey and OPS-01 live guard, not only tracker closeout.
- Updated this validation file from pending Wave 0 status to audited coverage.

### Verification Evidence

- `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/scripts/required_checks_test.exs test/mailglass/install/install_first_preview_smoke_test.exs` -> 9 tests, 0 failures.
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml')); yaml.safe_load(open('.github/workflows/post-publish-smoke.yml')); print('OK')"` -> OK.
- `actionlint .github/workflows/ci.yml .github/workflows/post-publish-smoke.yml` -> exit 0.

## Validation Sign-Off

- [x] All tasks have automated verification or CI-only runtime coverage with local workflow contracts.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all previously missing references.
- [x] No watch-mode flags.
- [x] Feedback latency < 5s for local deterministic contracts.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** audited and filled on 2026-05-31
