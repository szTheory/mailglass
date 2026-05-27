---
phase: 58
slug: verify-first-webhook-operator-path
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-27
---

# Phase 58 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `config/test.exs`, `mailglass_inbound/config/test.exs`, `mailglass_admin/config/test.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/reference_host --warnings-as-errors` |
| **Full suite command** | `MIX_ENV=test mix verify.reference_host.journey && ./scripts/check_trust_runner_checkpoint.sh && MIX_ENV=test mix test --warnings-as-errors --exclude flaky` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test test/reference_host --warnings-as-errors`
- **After every plan wave:** Run `MIX_ENV=test mix verify.reference_host.journey && ./scripts/check_trust_runner_checkpoint.sh`
- **Before `$gsd-verify-work`:** Run `MIX_ENV=test mix test --warnings-as-errors --exclude flaky`
- **Max feedback latency:** 120 seconds for quick feedback, full suite at wave/phase gates

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 58-01-01 | 01 | 1 | JOUR-03 | T-58-01 | Signed Postmark webhook enters `MailglassReferenceHostWeb.Router` and `MailglassInbound.Ingress.Plug`, not provider internals | integration/route | `MIX_ENV=test mix test test/reference_host/webhook_operator_path_test.exs --warnings-as-errors` | No - W0 | pending |
| 58-01-02 | 01 | 1 | JOUR-03 | T-58-02 | Forged Postmark webhook returns `401` rejected before tenant resolution, persistence, or mailbox execution | integration/route | `MIX_ENV=test mix test test/reference_host/webhook_operator_path_test.exs --warnings-as-errors` | No - W0 | pending |
| 58-02-01 | 02 | 1 | JOUR-04 | T-58-03 | Scripted `:no_match` operator scenario emits deterministic, PII-safe diagnosis evidence under `operator_troubleshooting` | integration/unit | `MIX_ENV=test mix test test/reference_host/webhook_operator_path_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | Partial - W0 | pending |
| 58-02-02 | 02 | 1 | JOUR-03/JOUR-04 | T-58-04 | Checkpoint preserves `trust_runner.v1` and existing stage order while validating Phase 58 evidence fields separately from row hash | contract/smoke | `MIX_ENV=test mix verify.reference_host.journey && ./scripts/check_trust_runner_checkpoint.sh` | Partial - W0 | pending |

---

## Wave 0 Requirements

- [ ] `test/reference_host/webhook_operator_path_test.exs` - add route-level positive/negative Postmark proof and operator evidence checkpoint coverage.
- [ ] `test/reference_host/trust_runner_command_contract_test.exs` - replace Phase 58 deferred-language assertions with completed Phase 58 claim-boundary expectations.
- [ ] `test/reference_host/trust_runner_checkpoint_contract_test.exs` - assert additive evidence for `webhook_ingest` and `operator_troubleshooting` while preserving stage order and `trust_runner.v1`.
- [ ] `scripts/check_trust_runner_checkpoint.sh` - validate completed Phase 58 semantics in checkpoint JSON.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | JOUR-03/JOUR-04 | All phase behaviors have automated route, contract, and smoke verification. | N/A |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency target recorded
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-27
