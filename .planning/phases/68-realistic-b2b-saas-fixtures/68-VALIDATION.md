---
phase: 68
slug: realistic-b2b-saas-fixtures
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-01
---

# Phase 68 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Mix |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/mailglass/demo_data_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30-90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mailglass/demo_data_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 68-01-01 | 01 | 0 | Phase goal | T-68-01 | Fixture reset remains deterministic and scoped to demo data | integration | `mix test test/mailglass/demo_data_test.exs` | yes | pending |
| 68-01-02 | 01 | 1 | Phase goal | T-68-02 | Outbound/inbound/webhook/replay scenarios use sanctioned schema states only | integration | `mix test test/mailglass/demo_data_test.exs` | yes | pending |
| 68-01-03 | 01 | 1 | Phase goal | T-68-03 | Suppression scenarios model B2B SaaS risk without leaking real tenant/user data | integration | `mix test test/mailglass/demo_data_test.exs` | yes | pending |
| 68-01-04 | 01 | 2 | Phase goal | T-68-04 | Replay lineage preserves stored-truth evidence semantics | integration | `mix test test/mailglass/demo_data_test.exs` | yes | pending |
| 68-01-05 | 01 | 2 | Phase goal | T-68-05 | Demo reset remains callable through `mix demo.reset` and does not require new fixture infra | integration | `mix test test/mailglass/demo_data_test.exs` | yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
