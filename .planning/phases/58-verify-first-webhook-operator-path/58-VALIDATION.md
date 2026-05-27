---
phase: 58
slug: verify-first-webhook-operator-path
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
validated: 2026-05-27
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
| 58-01-01 | 01 | 1 | JOUR-03 | T-58-01 | Signed Postmark webhook enters `MailglassReferenceHostWeb.Router` and `MailglassInbound.Ingress.Plug`, not provider internals | integration/route | `MIX_ENV=test mix test test/reference_host/webhook_operator_path_test.exs --warnings-as-errors` | Yes - `test/reference_host/webhook_operator_path_test.exs` | covered |
| 58-01-02 | 01 | 1 | JOUR-03 | T-58-02 | Forged Postmark webhook returns `401` rejected before tenant resolution, persistence, or mailbox execution | integration/route | `MIX_ENV=test mix test test/reference_host/webhook_operator_path_test.exs --warnings-as-errors` | Yes - `test/reference_host/webhook_operator_path_test.exs` | covered |
| 58-02-01 | 02 | 1 | JOUR-04 | T-58-03 | Scripted `:no_match` operator scenario emits deterministic, PII-safe diagnosis evidence under `operator_troubleshooting` | integration/unit | `MIX_ENV=test mix test test/reference_host/webhook_operator_path_test.exs --warnings-as-errors` plus `MIX_ENV=test mix cmd --cd mailglass_admin mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | Yes - `test/reference_host/webhook_operator_path_test.exs`, `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` | covered |
| 58-02-02 | 02 | 1 | JOUR-03/JOUR-04 | T-58-04 | Checkpoint preserves `trust_runner.v1` and existing stage order while validating Phase 58 evidence fields separately from row hash | contract/smoke | `MIX_ENV=test mix verify.reference_host.journey && ./scripts/check_trust_runner_checkpoint.sh` | Yes - `test/reference_host/trust_runner_checkpoint_contract_test.exs`, `scripts/check_trust_runner_checkpoint.sh` | covered |

---

## Wave 0 Requirements

- [x] `test/reference_host/webhook_operator_path_test.exs` - route-level positive/negative Postmark proof and operator evidence checkpoint coverage.
- [x] `test/reference_host/trust_runner_command_contract_test.exs` - completed Phase 58 claim-boundary expectations replace deferred-language assertions.
- [x] `test/reference_host/trust_runner_checkpoint_contract_test.exs` - additive evidence for `webhook_ingest` and `operator_troubleshooting` is asserted while preserving stage order and `trust_runner.v1`.
- [x] `scripts/check_trust_runner_checkpoint.sh` - completed Phase 58 semantics are validated in checkpoint JSON.

---

## Validation Audit 2026-05-27

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Phase 58 was audited after execution. Existing automated coverage satisfies all mapped requirements:

- `JOUR-03` is covered by route-level signed and forged Postmark tests through `MailglassReferenceHostWeb.Router.call/2`.
- `JOUR-04` is covered by deterministic `:no_match` operator diagnosis proof and admin inbound LiveView harness coverage.
- Checkpoint semantics are covered by root contract tests and `scripts/check_trust_runner_checkpoint.sh`, with row-hash identity kept to ordered `stage|status|fixture_id` rows.

Audit verification command:

```bash
MIX_ENV=test mix verify.reference_host.journey && ./scripts/check_trust_runner_checkpoint.sh && MIX_ENV=test mix test test/reference_host/webhook_operator_path_test.exs test/reference_host/trust_runner_command_contract_test.exs test/reference_host/trust_runner_checkpoint_contract_test.exs --warnings-as-errors && MIX_ENV=test mix cmd --cd mailglass_admin mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors
```

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
