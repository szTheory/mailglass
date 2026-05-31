---
phase: 61
slug: docs-contract-boundary-enforcement
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-31
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
| 61-01-01 | 01 | 0 | DOCB-03 | T-61-01 | Docs checker fails wording that presents reference internals as public API guarantees | contract/lint | `mix mailglass.docs.check` | Yes | pending |
| 61-01-02 | 01 | 1 | DOCB-01 | T-61-02 | Reference host docs state usage-proof-only boundary and do not claim API-contract truth | contract | `mix test test/reference_host/trust_runner_command_contract_test.exs --warnings-as-errors` | Yes | pending |
| 61-01-03 | 01 | 1 | DOCB-02 | T-61-03 | Trust-journey docs route guarantee semantics to canonical stability docs and executable contract tests | contract/lint | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors && mix mailglass.docs.check` | Yes | pending |
| 61-01-04 | 01 | 2 | DOCB-01,DOCB-02,DOCB-03 | T-61-01/T-61-02/T-61-03 | Full stability-contract lane proves docs boundary enforcement is release-gated | integration | `mix verify.stability_contract` | Yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `lib/mix/tasks/mailglass.docs.check.ex` - extend deterministic trust-doc surface rules for Phase 61 boundary coverage.
- [ ] `test/mailglass/docs_contract_test.exs` - add focused canonical-link and boundary assertions for trust-entry docs.
- [ ] `test/reference_host/trust_runner_command_contract_test.exs` and/or `test/reference_host/trust_runner_checkpoint_contract_test.exs` - pin reference-host usage-proof-only claim language.

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
