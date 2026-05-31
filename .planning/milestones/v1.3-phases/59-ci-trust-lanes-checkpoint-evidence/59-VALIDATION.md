---
phase: 59
slug: ci-trust-lanes-checkpoint-evidence
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
last_audited: 2026-05-31
---

# Phase 59 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GitHub Actions workflow static lint, `shellcheck`, ExUnit contract tests, `scripts/check_trust_runner_checkpoint.sh`, `scripts/check_clean_baseline_hex_only.sh`, and `mix verify.reference_host.journey` |
| **Config file** | `.github/workflows/ci.yml`, `.github/workflows/gate-self-test.yml`, `scripts/setup_branch_protection.sh`, `test/scripts/required_checks_test.exs` |
| **Quick run command** | `actionlint .github/workflows/ci.yml .github/workflows/gate-self-test.yml && shellcheck scripts/check_clean_baseline_hex_only.sh scripts/setup_branch_protection.sh scripts/check_trust_runner_checkpoint.sh && MIX_ENV=test mix test test/scripts/required_checks_test.exs` |
| **Full suite command** | `MIX_ENV=test mix verify.reference_host.journey && MIX_ENV=test mix verify.reference_host.journey --host-root reference/host_app && bash scripts/check_trust_runner_checkpoint.sh && (cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh)` |
| **Estimated runtime** | <60s locally for focused checks; CI lane runtime depends on GitHub runner queue and dependency cache |

---

## Sampling Rate

- **After every task commit:** `actionlint` for changed workflows, `shellcheck` for changed scripts, and focused ExUnit tests for branch-protection contract drift.
- **After every plan wave:** Run the trust-runner journey and checkpoint validator locally; push to CI to confirm the trust lanes appear and upload checkpoint artifacts.
- **Before `/gsd:verify-work`:** Focused static checks, ExUnit contract tests, repo-head trust journey, clean-baseline trust journey, checkpoint validator, and Hex-first guard all pass.
- **Max feedback latency:** <60s for local focused checks; CI feedback depends on runner availability.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-01 Task 1 | 59-01 | 1 | EVID-02 precondition | T-59-B (path-dep leakage) | Hex-source guard exits 0 only when `reference/host_app/mix.lock` resolves all three siblings via `:hex`; exits 1 for missing or non-Hex entries | script unit | `(cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh)` | yes | green |
| 59-01 Task 2 | 59-01 | 1 | EVID-01 enforcement proof | T-59-A (workflow-bypass) | `gate-self-test.yml` accepts a `check_name` input and polls required checks through jq env binding rather than raw expression interpolation | static workflow lint | `actionlint .github/workflows/gate-self-test.yml` | yes | green |
| 59-01 Task 3 | 59-01 | 1 | EVID-01 drift proof | T-59-A (workflow-bypass) | `REQUIRED_CHECKS` array and `print_expected_text` bullets stay synchronized; clean-baseline lane remains out of branch protection by contract | ExUnit contract | `MIX_ENV=test mix test test/scripts/required_checks_test.exs` | yes | green |
| 59-02 Task 1 | 59-02 | 2 | EVID-01 | T-59-A (workflow-bypass) | Repo-head trust lane runs unconditionally, validates a checkpoint, and is registered in `REQUIRED_CHECKS` plus printed expected branch-protection text | static + local journey | `actionlint .github/workflows/ci.yml && MIX_ENV=test mix verify.reference_host.journey && bash scripts/check_trust_runner_checkpoint.sh` | yes | green |
| 59-02 Task 1 / Phase 60 follow-up | 59-02 / 60-02 | 2 | EVID-02 | T-59-B (path-dep leakage) | Clean-baseline trust lane now runs unconditionally, asserts Hex-first resolution, runs `mix verify.reference_host.journey --host-root reference/host_app`, and uploads checkpoint evidence | static + local journey | `actionlint .github/workflows/ci.yml && MIX_ENV=test mix verify.reference_host.journey --host-root reference/host_app && (cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh)` | yes | green |
| 59-02 Task 1 | 59-02 | 2 | EVID-04 | T-59-C (artifact integrity) | Trust lanes upload exact `checkpoint.json` files through pinned `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02`, with `if-no-files-found: error` and `retention-days: 90` | workflow static + checkpoint contract | `rg -n 'trust-runner-(repo-head|clean-baseline)-\\$\\{\\{ github.run_id \\}\\}|retention-days: 90|if-no-files-found: error' .github/workflows/ci.yml && bash scripts/check_trust_runner_checkpoint.sh` | yes | green |
| 59-02 Task 1 | 59-02 | 2 | EVID-01/EVID-02 publish gate | T-59-D (publish bypass) | Trust lanes are not listed in `publish-hex.yml` advisory lanes, so `gate-ci-green` treats failures as blocking by default | workflow static | `rg -n 'ADVISORY_LANES|Trust Lane' .github/workflows/publish-hex.yml .github/workflows/ci.yml` | yes | green |

*Status: pending / green / red / manual-only.*

---

## Wave 0 Requirements

- [x] `scripts/check_clean_baseline_hex_only.sh` - reusable Hex-source guard for `reference/host_app/mix.lock`.
- [x] `.github/workflows/gate-self-test.yml` - `check_name` `workflow_dispatch` input plumbed into the poll loop with jq env binding.
- [x] `test/scripts/required_checks_test.exs` - ExUnit contract test for `REQUIRED_CHECKS` vs `print_expected_text` drift, Phase 27 lock entries, and clean-baseline branch-protection exclusion.

---

## Generated Test Files

| File | Requirement | Coverage |
|------|-------------|----------|
| `test/scripts/required_checks_test.exs` | EVID-01 | Fails on `REQUIRED_CHECKS` / heredoc drift, fails if Phase 27 required checks are removed, and asserts the clean-baseline lane is not a branch-protection required check. |

No additional test files were generated during the 2026-05-31 audit because all current requirement surfaces already have automated coverage.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Branch protection on `main` actually requires the repo-head trust check after merge | EVID-01 | GitHub branch protection is external server-side state; in-repo config is the source of truth but live enforcement changes only when the setup script or drift workflow runs with admin credentials | After merge to `main`: run `GH_TOKEN=$BRANCH_PROTECTION_PAT ./scripts/setup_branch_protection.sh main` or trigger `branch-protection-drift.yml`; then assert `gh api repos/szTheory/mailglass/branches/main/protection \| jq '.required_status_checks.contexts'` includes `Trust Lane Repo Head (Elixir 1.18 / OTP 27)`. |
| End-to-end synthetic enforcement self-test | EVID-01 | Opens and closes a real synthetic-failure PR and requires workflow-dispatch permission | Run `gh workflow run gate-self-test.yml -f check_name='Trust Lane Repo Head ('`; expected summary result is `blocked`. |
| CI artifact download from GitHub run storage | EVID-04 | Requires a completed hosted CI run and authenticated artifact download | For a completed CI run, download `trust-runner-repo-head-${run_id}` and `trust-runner-clean-baseline-${run_id}` artifacts, then run `bash scripts/check_trust_runner_checkpoint.sh --checkpoint <downloaded-checkpoint.json>`. |

---

## Validation Audit 2026-05-31

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Existing automated surfaces verified | 7 |

Audit notes:

- The earlier EVID-02 deferral recorded in `59-02-SUMMARY.md` and `59-VERIFICATION.md` is no longer current for the repository: `.github/workflows/ci.yml` now contains `trust_lane_clean_baseline`, added by Phase 60 Plan 02.
- `test/scripts/required_checks_test.exs` now contains three tests, including the clean-baseline branch-protection exclusion contract.
- `nyquist_compliant: true` remains valid because the remaining live-branch-protection and artifact-download checks are external-state manual verifications, not missing automated repository tests.

---

## Validation Sign-Off

- [x] All tasks have automated verification or documented external-state manual checks.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all original missing references (`scripts/check_clean_baseline_hex_only.sh`, `gate-self-test.yml` extension, `test/scripts/required_checks_test.exs`).
- [x] No watch-mode flags in validation commands.
- [x] Feedback latency is acceptable for the focused local path.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** refreshed 2026-05-31 (Nyquist validation audit)
