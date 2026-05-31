---
phase: 61
slug: docs-contract-boundary-enforcement
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
validated: 2026-05-31
---

# Phase 61 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir test stack) |
| **Config file** | `mix.exs` aliases plus `test/` suites |
| **Quick run command** | `mix mailglass.docs.check` |
| **Full suite command** | `mix verify.stability_contract` |
| **Estimated runtime** | ~60-180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix mailglass.docs.check`
- **After every plan wave:** Run `mix test test/mailglass/docs_contract_test.exs test/reference_host/trust_runner_command_contract_test.exs test/reference_host/trust_runner_checkpoint_contract_test.exs --warnings-as-errors`
- **Before `$gsd-verify-work`:** `mix verify.stability_contract` must be green
- **Max feedback latency:** 180 seconds for quick feedback, full-suite latency accepted at phase gate

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 61-01-01 | 01 | 1 | DOCB-01,DOCB-02 | T-61-01/T-61-02/T-61-03 | Reference-host docs state usage-proof-only boundary, route guarantees to canonical stability inventories, and reject contract-truth / fixture-seed overreach | contract | `MIX_ENV=test mix test test/reference_host/trust_runner_command_contract_test.exs --warnings-as-errors` | Yes | green |
| 61-01-02 | 01 | 1 | DOCB-01,DOCB-02 | T-61-01/T-61-02/T-61-03 | Existing reference-host command contract pins README/SCOPE Phase 61 boundary tokens and forbidden overreach phrases | contract | `MIX_ENV=test mix test test/reference_host/trust_runner_command_contract_test.exs --warnings-as-errors` | Yes | green |
| 61-02-01 | 02 | 1 | DOCB-01,DOCB-02 | T-61-01/T-61-02/T-61-03 | Maintainer, webhook, and troubleshooting trust docs route guarantees to canonical stability inventories and executable contract checks | contract/lint | `MIX_ENV=test mix test test/mailglass/docs_contract_test.exs --warnings-as-errors && mix mailglass.docs.check` | Yes | green |
| 61-02-02 | 02 | 1 | DOCB-02 | T-61-01/T-61-02 | Operator-trust docs preserve semantic seams while marking internal names as implementation detail | contract/lint | `MIX_ENV=test mix test test/mailglass/docs_contract_test.exs --warnings-as-errors && mix mailglass.docs.check` | Yes | green |
| 61-03-01 | 03 | 2 | DOCB-02,DOCB-03 | T-61-01/T-61-02/T-61-03 | Docs checker scans all Phase 61 trust-entry docs and fails on internals-as-public-contract overreach without non-contract framing | lint/mutation | `MIX_ENV=test mix test test/mailglass/docs_check_task_test.exs --warnings-as-errors && mix mailglass.docs.check` | Yes | green |
| 61-03-02 | 03 | 2 | DOCB-02,DOCB-03 | T-61-02/T-61-03 | ExUnit docs-contract assertions pin canonical links, `mix verify.stability_contract`, and non-contract phrasing across trust-entry docs | contract/integration | `MIX_ENV=test mix test test/mailglass/docs_contract_test.exs --warnings-as-errors && mix verify.stability_contract` | Yes | green |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [x] `lib/mix/tasks/mailglass.docs.check.ex` - extend deterministic trust-doc surface rules for Phase 61 boundary coverage.
- [x] `test/mailglass/docs_contract_test.exs` - add focused canonical-link and boundary assertions for trust-entry docs.
- [x] `test/reference_host/trust_runner_command_contract_test.exs` - pin reference-host usage-proof-only claim language.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | DOCB-01,DOCB-02,DOCB-03 | All phase behaviors must be enforced by deterministic docs checker and ExUnit contract tests. | N/A |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency target documented
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-31

---

## Validation Audit 2026-05-31

| Metric | Count |
|--------|-------|
| Requirements audited | 3 |
| Automated rows audited | 6 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Manual-only | 0 |

### Requirement Coverage

| Requirement | Status | Automated Evidence |
|-------------|--------|--------------------|
| DOCB-01 | COVERED | `test/reference_host/trust_runner_command_contract_test.exs` asserts reference-host usage-proof-only and non-contract truth wording. |
| DOCB-02 | COVERED | `test/mailglass/docs_contract_test.exs`, `test/reference_host/trust_runner_command_contract_test.exs`, and `mix mailglass.docs.check` pin canonical stability routing. |
| DOCB-03 | COVERED | `test/mailglass/docs_check_task_test.exs` mutation coverage and `mix mailglass.docs.check` enforce internals-as-guarantee overreach failures. |

### Commands Run

| Command | Result |
|---------|--------|
| `MIX_ENV=test mix test test/reference_host/trust_runner_command_contract_test.exs test/mailglass/docs_check_task_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors` | PASS - 31 tests, 0 failures, 1 skipped |
| `mix mailglass.docs.check` | PASS - Tier 1 docs match the stability contract |
| `mix verify.stability_contract` | PASS - 1 property, 123 tests, 0 failures, 1 skipped across the stability-contract alias |
