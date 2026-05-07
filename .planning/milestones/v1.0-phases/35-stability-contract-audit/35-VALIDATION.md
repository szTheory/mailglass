---
phase: 35
slug: stability-contract-audit
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-05
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `config/test.exs`, `mailglass_admin/config/test.exs` |
| **Quick run command** | `mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors && cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs --warnings-as-errors && mix docs --warnings-as-errors >/tmp/mailglass-admin-phase35-docs.log && rg -n "api_stability|Stability|Contract" doc/**/*.html doc/dist/search_data-*.js` |
| **Full suite command** | `mix test --warnings-as-errors && cd mailglass_admin && mix test --warnings-as-errors && mix docs --warnings-as-errors` |
| **Estimated runtime** | ~25 seconds quick / ~90 seconds full |

---

## Sampling Rate

- **After every task commit:** Run the quick run command above.
- **After every plan wave:** Run `mix test --warnings-as-errors && cd mailglass_admin && mix test --warnings-as-errors && mix docs --warnings-as-errors`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 25 seconds quick / 90 seconds wave-end.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 1 | LOCK-01, LOCK-03 | T-35-01 / T-35-02 | Core stability inventory classifies stable vs internal vs sibling-only surfaces honestly. | docs-contract | `mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors` | ⚠️ Wave 0 | ⬜ pending |
| 35-01-02 | 01 | 1 | LOCK-01, LOCK-03 | T-35-02 / T-35-03 | README and `Mailglass` moduledoc point at the canonical core contract and do not overclaim package scope. | docs-contract | `mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors` | ⚠️ Wave 0 | ⬜ pending |
| 35-02-01 | 02 | 2 | LOCK-02, LOCK-03 | T-35-04 / T-35-05 | `mailglass_admin` package docs expose the stable admin seam and mark UI internals as internal. | docs-contract | `cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs --warnings-as-errors` | ⚠️ Wave 0 | ⬜ pending |
| 35-02-02 | 02 | 2 | LOCK-02, LOCK-03 | T-35-05 / T-35-06 | Router/auth/operator source docs match the package-local admin contract. | docs-contract | `cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs --warnings-as-errors` | ⚠️ Wave 0 | ⬜ pending |
| 35-03-01 | 03 | 3 | LOCK-04 | T-35-07 / T-35-09 | Stable public task surfaces expose truthful `:since` / deprecation metadata in compiled docs. | unit | `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors && cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs --warnings-as-errors` | ⚠️ Wave 0 | ⬜ pending |
| 35-03-02 | 03 | 3 | LOCK-01, LOCK-02, LOCK-03, LOCK-04 | T-35-07 / T-35-08 / T-35-09 | Contract docs, compiled-doc tests, and generated docs remain aligned without pulling Phase 37 enforcement forward. | docs-build | `mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors && cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs --warnings-as-errors && cd .. && mix docs --warnings-as-errors` | ⚠️ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ Wave 0 dependency*

---

## Wave 0 Requirements

- [ ] `test/mailglass/stability_contract_test.exs` — compiled-doc inventory and metadata audit for the core package
- [ ] `mailglass_admin/test/mailglass_admin/stability_contract_test.exs` — compiled-doc inventory and metadata audit for admin stable seams
- [ ] `mailglass_admin/docs/api_stability.md` — package-local admin contract artifact surfaced via ExDoc
- [ ] `mailglass_admin/mix.exs` docs config update — package-local extras/module grouping for the admin contract

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Package-version-history wording stays honest across milestone docs vs package manifests | LOCK-04 | Requires maintainer judgment when updating narrative docs around release history | Compare `mix.exs`, `mailglass_admin/mix.exs`, README snippets, and contract docs before phase verification; ensure package-version wording reflects manifest truth rather than milestone labels. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing verification references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
