---
phase: 63
slug: inbound-contract-inventory-reconciliation
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
---

# Phase 63 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` aliases plus `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` |
| **Quick run command** | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` |
| **Full suite command** | `mix verify.stability_contract` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`
- **After every plan wave:** Run `mix verify.stability_contract`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 63-01-01 | 01 | 1 | LOCK-01 | T-63-01 | Stable runtime, testing, operator, telemetry, and error-contract seams remain explicit. | contract-doc | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | yes | green |
| 63-01-02 | 01 | 1 | LOCK-02 | T-63-02 | Provider, replay, worker, queue, route, and operator internals remain classified as internal implementation support. | contract-doc | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | yes | green |
| 63-01-03 | 01 | 1 | LOCK-03 | T-63-03 | Deferred matcher, lifecycle, fan-out, synthetic UI, `gen_smtp`, and ecosystem integration capabilities remain explicitly out of v1.4 scope. | contract-doc | `mix verify.stability_contract` | yes | green |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification through the docs contract lane.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency <= 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated validation audit passed on 2026-05-31

---

## Validation Audit 2026-05-31

| Metric | Count |
|--------|-------|
| Requirements audited | 3 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

| Requirement | Evidence | Status |
|-------------|----------|--------|
| LOCK-01 | `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` pins stable runtime, testing, operator, telemetry, and error-contract tokens from `mailglass_inbound/docs/api_stability.md`. | COVERED |
| LOCK-02 | The same docs-contract suite asserts internal provider/replay/worker/queue/route tokens and refutes promotion into the stable section. | COVERED |
| LOCK-03 | The docs-contract suite asserts the deferred capability list, including matcher expansion, lifecycle callbacks, fan-out, synthetic UI, `gen_smtp`, and ecosystem integrations. | COVERED |

Verification evidence:

- `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` - 14 tests, 0 failures
- `mix verify.stability_contract` - docs checks passed; final inbound docs-contract lane 14 tests, 0 failures
