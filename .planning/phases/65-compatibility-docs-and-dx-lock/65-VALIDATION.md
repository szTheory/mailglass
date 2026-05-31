---
phase: 65
slug: compatibility-docs-and-dx-lock
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-31
---

# Phase 65 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Elixir/Mix |
| **Config file** | `mailglass_inbound/test/test_helper.exs` and root Mix aliases |
| **Quick run command** | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` |
| **Full suite command** | `mix verify.stability_contract` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`.
- **After every plan wave:** Run `mix mailglass.docs.check`.
- **Before `$gsd-verify-work`:** `mix verify.stability_contract` must be green.
- **Max feedback latency:** 60 seconds for focused docs-contract checks, 180 seconds for aggregate stability verification.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 65-W0-01 | TBD | 0 | DX-01 | T-65-01 | Canonical adoption path cannot drift across README/install/provider/operator docs. | contract-doc | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | yes | pending |
| 65-W0-02 | TBD | 0 | DX-02 | T-65-02, T-65-03 | Operator docs keep doctor/replay/prune tenant guards, exit semantics, replay-over-stored-truth wording, and destructive confirmations explicit. | contract-doc | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | yes | pending |
| 65-W0-03 | TBD | 0 | DX-03 | T-65-04 | Testing docs preserve process-local capture and one-assertion-per-drive semantics. | contract-doc | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | yes | pending |
| 65-W0-04 | TBD | 0 | DX-04 | T-65-05, T-65-06 | Admin/operator trust docs avoid fresh-receive replay, silent-reroute, public replay API, and stable UI/DOM/component guarantees. | contract-doc + tier1 | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors && cd .. && mix mailglass.docs.check` | yes | pending |

*Status: pending | green | red | flaky*

---

## Wave 0 Requirements

- [ ] Add or confirm docs-contract assertions for README canonical adoption path tokens and subordinate guide parity.
- [ ] Add or confirm docs-contract assertions for stable-vs-internal/deferred compatibility language and deprecation bridge wording.
- [ ] Add or confirm docs-contract assertions for doctor/replay/prune command semantics, exit behavior, tenant guards, and destructive confirmation language.
- [ ] Add or confirm docs-contract assertions for `MailboxCase`, `Test.Ingress`, process-local assertions, and one-assertion-per-drive examples.
- [ ] Add or confirm Tier-1 docs checks for admin/operator trust anti-overclaim wording.

---

## Manual-Only Verifications

All phase behaviors should have automated verification through the docs-contract and stability-contract lanes. Manual review is limited to judging prose clarity after automated required/forbidden phrase checks pass.

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target recorded.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending execution
