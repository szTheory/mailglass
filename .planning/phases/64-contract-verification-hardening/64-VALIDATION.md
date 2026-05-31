---
phase: 64
slug: contract-verification-hardening
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-31
---

# Phase 64 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Elixir/Mix |
| **Config file** | `mailglass_inbound/test/test_helper.exs` and root `test/test_helper.exs` |
| **Quick run command** | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` |
| **Full suite command** | `mix verify.stability_contract` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` when docs-contract surfaces changed; run the focused new inbound stability test once it exists.
- **After every plan wave:** Run `mix verify.stability_contract`.
- **Before `$gsd-verify-work`:** `mix verify.stability_contract` must be green.
- **Max feedback latency:** 60 seconds for focused checks, 180 seconds for aggregate stability verification.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 64-01-01 | 01 | 1 | PROOF-01 | T-64-01 | Stable inbound modules/functions/macros/callbacks carry compiled-doc `since` metadata | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/stability_contract_test.exs --warnings-as-errors` | Missing W0 | pending |
| 64-01-02 | 01 | 1 | PROOF-02 | T-64-02 | Closed structured-error `:type` docs exactly match `__types__/0` | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | Exists, extend | pending |
| 64-01-03 | 01 | 1 | PROOF-03 | T-64-03 | Adoption/stability docs reject over-claims and stale release-line/install-pin drift | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | Exists, extend | pending |
| 64-01-04 | 01 | 1 | PROOF-01 | T-64-04 | Root stability lane delegates to package-owned inbound support-contract alias | integration | `mix verify.stability_contract` | Exists, update | pending |

*Status: pending | green | red | flaky*

---

## Wave 0 Requirements

- [ ] `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs` - new compiled-doc metadata proof for inbound stable and adopter-facing testing surfaces.
- [ ] `mailglass_inbound/docs/api_stability.md` - add explicit `Closed :type set` bullets for `MailglassInbound.MIMEError`.
- [ ] `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` - extend docs-contract assertions for closed type sets, over-claims, and stale release/install claims.
- [ ] `mailglass_inbound/mix.exs` - add `verify.support_contract.inbound` and preferred env wiring.
- [ ] `mix.exs` and `test/mailglass/stability_contract_test.exs` - root aggregate wiring delegates to the inbound package lane.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target recorded.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-31
