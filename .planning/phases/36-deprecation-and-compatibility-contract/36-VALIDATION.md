---
phase: 36
slug: deprecation-and-compatibility-contract
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 36 — Validation Strategy

> Per-phase validation contract for the canonical `1.x` compatibility promise, the canonical latest-`0.x` to `1.0` guide, and the lightweight proof inventory that keeps both honest.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix tasks + ExDoc builds |
| **Config file** | `config/test.exs`, `mailglass_admin/config/test.exs`, `mix.exs`, `mailglass_admin/mix.exs` |
| **Quick run command** | `mix docs --warnings-as-errors && mix test test/mailglass/docs_contract_test.exs test/mailglass/docs_migration_smoke_test.exs test/mailglass/compatibility_contract_test.exs --warnings-as-errors && mix mailglass.docs.check && mix verify.support_contract.core && cd mailglass_admin && mix docs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors && cd mailglass_admin && mix test --warnings-as-errors` |
| **Estimated runtime** | ~120s quick / ~240s full phase scope |

---

## Sampling Rate

- **After every task commit:** run the smallest task-local command for the files just changed
- **After every plan wave:** rerun the quick phase commands, including both docs builds
- **Before `$gsd-verify-work`:** rerun the full suite commands in both projects
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 36-01-01 | 01 | 1 | COMPAT-01, COMPAT-02 | T-36-01 | canonical compatibility guide defines stable lane, compatibility lane, support matrix rows, and exception posture from repo truth only | docs contract | `rg -n "stable lane|compatibility lane|patch releases|minor releases|major releases|warnings-as-errors|Elixir \`~> 1\\.18\`|OTP \`27\\+\`|Phoenix \`~> 1\\.8\`|LiveView \`~> 1\\.1\`|Ecto / Ecto SQL \`~> 3\\.13\`|Postgres 14\\+|mailglass_inbound" guides/compatibility-and-deprecations.md` | ✅ Task creates file | ⬜ pending |
| 36-01-02 | 01 | 1 | COMPAT-01, COMPAT-02 | T-36-02, T-36-03 | root docs, admin docs, and both ExDoc nav surfaces point to one canonical policy without forcing cross-package file ownership | docs build / docs contract | `mix docs --warnings-as-errors && cd mailglass_admin && mix docs --warnings-as-errors && rg -n "compatibility-and-deprecations|compatibility" README.md mailglass_admin/README.md MAINTAINING.md docs/api_stability.md mailglass_admin/docs/api_stability.md mix.exs mailglass_admin/mix.exs mailglass_admin/docs/compatibility-and-deprecations.md` | ✅ Task creates file | ⬜ pending |
| 36-02-01 | 02 | 2 | COMPAT-03, COMPAT-04 | T-36-04 | the canonical `0.x -> 1.0` guide is the only upgrade authority and every retained path has replacement, warning channel, strict-CI impact, support horizon, and proof artifact | docs contract / smoke | `mix test test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors && rg -n "surface|replacement|warning channel|--warnings-as-errors impact|support-until version|proof artifact|Mailglass\\.Message\\.new/2|Mailglass\\.Outbound\\.send/2|Mailglass\\.deliver/2|mix mailglass\\.upgrade\\.v0_2|verify\\.phase_" guides/upgrading-to-v1_0.md` | ✅ Task updates file | ⬜ pending |
| 36-02-02 | 02 | 2 | COMPAT-03, COMPAT-04 | T-36-05, T-36-06 | source-adjacent docs classify `Message.new/2`, `send/2`, and the codemod consistently with the compatibility lane | source-doc regression | `rg -n "@deprecated|native Mailglass\\.Message setters|legacy compatibility bridge|canonical public verb|upgrading-to-v1_0|transitional" lib/mailglass/message.ex lib/mailglass/outbound.ex lib/mix/tasks/mailglass.upgrade.v0_2.ex` | ✅ | ⬜ pending |
| 36-03-01 | 03 | 3 | COMPAT-04 | T-36-07 | explicit deprecated-path inventory is mechanically verified and every retained path stays documented through `v2.0` or later | ExUnit contract | `mix test test/mailglass/compatibility_contract_test.exs --warnings-as-errors` | ✅ Task creates file | ⬜ pending |
| 36-03-02 | 03 | 3 | COMPAT-01, COMPAT-02, COMPAT-03, COMPAT-04 | T-36-08, T-36-09 | lightweight repo-native checks catch compatibility-guide drift and keep the proof inside existing verification aliases | alias / docs contract | `mix test test/mailglass/docs_contract_test.exs test/mailglass/docs_migration_smoke_test.exs test/mailglass/compatibility_contract_test.exs --warnings-as-errors && mix mailglass.docs.check && mix verify.support_contract.core` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All Phase 36 behaviors are expected to have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verification or existing infrastructure support
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05
