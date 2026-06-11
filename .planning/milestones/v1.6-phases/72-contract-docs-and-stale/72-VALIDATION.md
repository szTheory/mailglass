---
phase: 72
slug: contract-docs-and-stale
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-02
---

# Phase 72 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` |
| **Full suite command** | `mix test --seed 0` (root); `cd mailglass_inbound && mix test --seed 0` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command above
- **After every plan wave:** Run full suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 72-01-01 | 01 | 1 | DOC-01/DOC-02/DOC-03 | — | N/A | docs check | `mix mailglass.docs.check` | ✅ | ⬜ pending |
| 72-01-02 | 01 | 1 | DOC-01 | — | N/A | unit | `mix test test/mailglass/docs_contract_test.exs` | ✅ | ⬜ pending |
| 72-01-03 | 01 | 1 | PROOF-02 | — | N/A | unit | `mix test test/mailglass/stability_contract_test.exs` | ✅ | ⬜ pending |
| 72-02-01 | 02 | 1 | DOC-01/DOC-02 | — | N/A | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs` | ✅ | ⬜ pending |
| 72-03-01 | 03 | 2 | PROOF-02 | — | N/A | unit | `mix test test/mailglass/stability_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
