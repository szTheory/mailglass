---
phase: 59
slug: ci-trust-lanes-checkpoint-evidence
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 59 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | (a) GitHub Actions workflow self-execution on a feature branch; (b) `actionlint` + `shellcheck` for static lint; (c) `scripts/check_trust_runner_checkpoint.sh` for checkpoint contract; (d) `scripts/check_clean_baseline_hex_only.sh` (Wave 0) for Hex-source enforcement; (e) `mix verify.reference_host.journey` for end-to-end runner check |
| **Config file** | `.github/workflows/ci.yml`, `scripts/setup_branch_protection.sh`, `scripts/check_clean_baseline_hex_only.sh` (new) |
| **Quick run command** | `actionlint .github/workflows/ci.yml && shellcheck scripts/check_clean_baseline_hex_only.sh scripts/setup_branch_protection.sh` |
| **Full suite command** | `MIX_ENV=test mix verify.reference_host.journey && bash scripts/check_trust_runner_checkpoint.sh && (cd reference/host_app && mix deps.get && bash ../../scripts/check_clean_baseline_hex_only.sh)` |
| **Estimated runtime** | <60s locally; ~3–5 min per CI lane |

---

## Sampling Rate

- **After every task commit:** `actionlint .github/workflows/ci.yml` (if workflow changed) + `shellcheck` on modified `scripts/*.sh` + local `MIX_ENV=test mix verify.reference_host.journey && bash scripts/check_trust_runner_checkpoint.sh`.
- **After every plan wave:** Push to a feature branch; observe CI run; confirm both new lanes appear with the expected names; download both artifacts via `gh run download` and re-validate with `scripts/check_trust_runner_checkpoint.sh`.
- **Before `/gsd:verify-work`:** Full suite green AND post-merge `./scripts/setup_branch_protection.sh main` (or `workflow_dispatch` on `branch-protection-drift.yml`) confirms the new required check is registered on `main` protection. `publish-hex.yml` dry-run (`gh workflow run publish-hex.yml -f dry_run=true`) acknowledges the new lanes in `gate-ci-green`.
- **Max feedback latency:** ~60s for the quick path; ~5 min for the full-CI path.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-XX-XX | TBD by planner | 1 | EVID-01 | T-59-A (workflow-bypass) | New required job present in `REQUIRED_CHECKS`; lane exits non-zero on missing checkpoint | static + CI smoke | `grep -Fq 'Reference Host Trust Journey (Elixir 1.18 / OTP 27)' scripts/setup_branch_protection.sh && (rm -f tmp/mailglass_trust_runner/checkpoint.json && bash scripts/check_trust_runner_checkpoint.sh; test $? -eq 1)` | ✅ (script exists) | ⬜ pending |
| 59-XX-XX | TBD by planner | 1 | EVID-02 | T-59-B (path-dep leakage) | Clean-baseline lane fails when any sibling resolves via `:path` source in `reference/host_app/mix.lock` | script unit | `(cd reference/host_app && mix deps.get && bash ../../scripts/check_clean_baseline_hex_only.sh)` exits 0; with synthetic `path:` override in throwaway copy of `reference/host_app/mix.exs`, exits 1 | ❌ W0 (new script) | ⬜ pending |
| 59-XX-XX | TBD by planner | 1 | EVID-04 | T-59-C (artifact integrity) | Both lanes upload `trust_runner.v1` checkpoint JSON via `actions/upload-artifact@<pinned-v4-SHA>` with `if-no-files-found: error`, `retention-days: 90`, stable `${{ github.run_id }}`-suffixed names | CI smoke + download verify | After CI run on Phase 59 PR: `gh run download <id> -n trust-runner-repo-head-<id> && bash scripts/check_trust_runner_checkpoint.sh --checkpoint checkpoint.json` exits 0; same for clean-baseline artifact | Will exist after Wave 1 first run | ⬜ pending |
| 59-XX-XX | TBD by planner | 1 | EVID-01 (enforcement proof) | T-59-A | `gate-self-test.yml` synthetic-failure run reports the new required check in FAILURE status, not just SKIPPED | extended self-test | `gh workflow run gate-self-test.yml -f check_name='Reference Host Trust Journey (Elixir 1.18 / OTP 27)'` observes FAILURE on the synthetic-failing PR | ❌ W0 (gate-self-test extension) | ⬜ pending |
| 59-XX-XX | TBD by planner | 1 | EVID-01/EVID-02 (publish gate) | T-59-D (publish bypass) | Neither new lane in `ADVISORY_LANES`; `publish-hex.yml::gate-ci-green` enumerates them as blocking on a synthetic-red CI run | publish-gate smoke | `gh workflow run publish-hex.yml -f tag=<existing> -f dry_run=true -f package=mailglass` on a SHA where one trust lane is red → `gate-ci-green` setFailed lists the trust lane | ✅ (workflow exists) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Note: Task IDs will be assigned by the planner. This table maps requirements to verification surfaces; the planner will bind each row to a specific PLAN task.*

---

## Wave 0 Requirements

- [ ] `scripts/check_clean_baseline_hex_only.sh` — reusable Hex-source guard (loads `mix.lock`, asserts `:mailglass`/`:mailglass_admin`/`:mailglass_inbound` entries have `:hex` source). 6-line bash wrapper + ~10-line `elixir -e` inline; extracted so Phase 60 release ceremony can run it locally.
- [ ] `.github/workflows/gate-self-test.yml` — extend to accept a `check_name` `workflow_dispatch` input (defaulting to "Tests"); use the input as the polled check-name in the synthetic-failure assertion step. Proves EVID-01's "required" enforcement is observable, not just declared.
- [ ] `test/scripts/required_checks_test.exs` (or equivalent shell-bats test) — asserts `REQUIRED_CHECKS` array contains the expected lane names. Tracks the lane list as a contract regression surface, not a one-time edit.

*If none after planner finalizes: "Existing test infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Branch protection on `main` actually requires the new check after merge | EVID-01 | GitHub branch protection is *external state*; the in-repo `REQUIRED_CHECKS` array is the source of truth, but live enforcement only updates when `./scripts/setup_branch_protection.sh main` runs or `branch-protection-drift.yml` re-asserts | After merge to `main`: (1) run `./scripts/setup_branch_protection.sh main` or trigger `workflow_dispatch` on `branch-protection-drift.yml`; (2) `gh api repos/szTheory/mailglass/branches/main/protection \| jq '.required_status_checks.contexts'` — assert the new lane name is present |
| Phase 60 release-evidence ingest path works | EVID-04 (forward-compat) | Phase 60 isn't built yet; this is a forward-compat check, not a Phase 59 regression surface | After Phase 59 ships: confirm `actions/download-artifact@v4` with `pattern: 'trust-runner-*'` (or exact `${{ github.run_id }}`-suffixed name) returns a valid `trust_runner.v1` JSON — defers to Phase 60 plan |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (`scripts/check_clean_baseline_hex_only.sh`, `gate-self-test.yml` extension, `test/scripts/required_checks_test.exs`)
- [ ] No watch-mode flags (CI lanes are one-shot per push; no `--watch`)
- [ ] Feedback latency < 60s (quick path) / 5 min (full CI path)
- [ ] `nyquist_compliant: true` set in frontmatter after plan binds task IDs

**Approval:** pending
