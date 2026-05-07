---
phase: 37
slug: contract-enforcement-and-trust-docs
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 37 — Validation Strategy

> Per-phase validation contract for the semantic repo-root stability workflow, the canonical testing contract, and the canonical admin trust contract.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix aliases + docs generation |
| **Config file** | `config/test.exs`, `mailglass_admin/config/test.exs`, `mix.exs`, `mailglass_admin/mix.exs` |
| **Quick run command** | `mix test test/mailglass/docs/testing_guide_test.exs test/mailglass/test_assertions_test.exs test/mailglass/mailer_case_test.exs test/mailglass/test_assertions_pubsub_test.exs --warnings-as-errors && cd mailglass_admin && mix test test/mailglass_admin/operator_trust_doc_test.exs test/mailglass_admin/router_test.exs test/mailglass_admin/auth_test.exs test/mailglass_admin/operator_live_test.exs --warnings-as-errors && mix docs --warnings-as-errors` |
| **Full suite command** | `bash scripts/verify_support_contract.sh && mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors && cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs test/mailglass_admin/operator_trust_doc_test.exs --warnings-as-errors && mix docs --warnings-as-errors` |
| **Estimated runtime** | ~90s quick / ~180s full phase scope |

---

## Sampling Rate

- **After every task commit:** run the smallest task-local lane that covers the changed docs or test seam.
- **After every plan wave:** rerun the quick phase commands and the relevant docs build.
- **Before `$gsd-verify-work`:** rerun the full phase commands including the repo-root stability workflow.
- **Max feedback latency:** 180 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-01-01 | 01 | 1 | PROOF-03 | T-37-01 | Canonical testing guide describes the stable default and explicit exception lanes truthfully. | docs contract | `mix test test/mailglass/docs/testing_guide_test.exs test/mailglass/test_assertions_test.exs test/mailglass/mailer_case_test.exs test/mailglass/test_assertions_pubsub_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 37-02-01 | 02 | 2 | PROOF-04 | T-37-02 | Canonical admin trust doc describes stable router/auth/session/replay semantics without freezing UI internals. | docs + semantic admin tests | `cd mailglass_admin && mix test test/mailglass_admin/operator_trust_doc_test.exs test/mailglass_admin/router_test.exs test/mailglass_admin/auth_test.exs test/mailglass_admin/operator_live_test.exs --warnings-as-errors && mix docs --warnings-as-errors` | ✅ | ✅ green |
| 37-03-01 | 03 | 3 | PROOF-01, PROOF-02 | T-37-03 | One semantic repo-root proof entrypoint verifies core/admin contract truth and catches docs-surface drift. | mix alias + compiled-doc tests | `bash scripts/verify_support_contract.sh && mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors && cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs test/mailglass_admin/operator_trust_doc_test.exs --warnings-as-errors` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All Phase 37 behaviors are expected to have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verification or existing infrastructure support
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-06
