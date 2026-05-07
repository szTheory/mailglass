---
phase: 34
slug: verification-regression-closure
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 34 — Validation Strategy

> Per-phase validation contract for verification-entrypoint honesty, CI contract clarity, and support-regression retention.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest + GitHub Actions YAML validation |
| **Config file** | `config/test.exs`, `mailglass_admin/config/test.exs`, `.github/workflows/*.yml` |
| **Quick run command** | `mix verify.support_contract.core`, `cd mailglass_admin && mix verify.support_contract.admin`, `mix compile --no-optional-deps --warnings-as-errors`, and `actionlint .github/workflows/ci.yml .github/workflows/advisory-matrix.yml` |
| **Full suite command** | `mix test --warnings-as-errors` and `cd mailglass_admin && mix test --warnings-as-errors` |
| **Estimated runtime** | ~180s quick / ~300s full phase scope |

---

## Sampling Rate

- **After every task commit:** run the smallest task-local command plus `actionlint` for workflow edits
- **After every plan wave:** rerun the quick phase commands for both packages and workflow files
- **Before `$gsd-verify-work`:** full suites must be green in both packages after the required contract passes
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | MAT-03 | T-34-02 | root support-contract and provider-compatibility bundles are explicit and non-vacuous | alias / integration | `mix verify.support_contract.core && mix verify.provider_compatibility` | ✅ | ✅ green |
| 34-01-02 | 01 | 1 | MAT-03 | T-34-01, T-34-03 | root citext probe raises on exhausted retries instead of returning a false green | unit | `mix test test/mailglass/test_support/citext_probe_test.exs --warnings-as-errors && mix verify.support_contract.core` | ✅ Task creates file | ✅ green |
| 34-02-01 | 02 | 1 | MAT-03 | T-34-05 | admin support-contract bundle is explicit and non-vacuous | alias / integration | `cd mailglass_admin && mix verify.support_contract.admin` | ✅ | ✅ green |
| 34-02-02 | 02 | 1 | MAT-03 | T-34-04, T-34-06 | admin citext probe raises on exhausted retries instead of returning a false green | unit | `cd mailglass_admin && mix test test/mailglass_admin/test_support/citext_probe_test.exs --warnings-as-errors && mix verify.support_contract.admin` | ✅ Task creates file | ✅ green |
| 34-03-01 | 03 | 2 | MAT-03 | T-34-07, T-34-08, T-34-09 | repo-root script and CI workflows expose three explicit required buckets while keeping advisory lanes non-required | workflow / shell | `bash scripts/verify_support_contract.sh && actionlint .github/workflows/ci.yml .github/workflows/advisory-matrix.yml && rg -n "Support Contract Core|Support Contract Admin|Core Full Suite Advisory|Provider Compatibility Advisory" .github/workflows/ci.yml .github/workflows/advisory-matrix.yml scripts/verify_support_contract.sh && ! rg -n --fixed-strings "mix test --warnings-as-errors --exclude provider_live" .github/workflows/advisory-matrix.yml` | ✅ Task creates file | ✅ green |
| 34-03-02 | 03 | 2 | MAT-03 | T-34-08 | maintainer docs lock the required-versus-advisory verification contract exactly | docs contract | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub branch protection requires only the three new Phase 34 truth jobs and does not require `Tests (Elixir 1.18 / OTP 27)` or `Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)` | MAT-03 | Branch-protection configuration is not stored in the repo | In GitHub branch protection, require `Compile No Optional Deps (Elixir 1.18 / OTP 27)`, `Support Contract Core (Elixir 1.18 / OTP 27)`, and `Support Contract Admin (Elixir 1.18 / OTP 27)`; remove any required reference to `Tests (Elixir 1.18 / OTP 27)` and `Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)` if present. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing infrastructure support
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05

**Completion Evidence:** Re-verified 2026-05-05 with `mix verify.support_contract.core`, `mix verify.provider_compatibility`, `cd mailglass_admin && mix verify.support_contract.admin`, `mix test test/mailglass/test_support/citext_probe_test.exs --warnings-as-errors`, `cd mailglass_admin && mix test test/mailglass_admin/test_support/citext_probe_test.exs --warnings-as-errors`, `bash scripts/verify_support_contract.sh`, `actionlint .github/workflows/ci.yml .github/workflows/advisory-matrix.yml`, and `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors`.
