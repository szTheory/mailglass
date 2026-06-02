---
phase: 68
slug: realistic-b2b-saas-fixtures
status: complete
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
| **Repo-root config file** | `mix.exs` |
| **Demo-app local config file** | `reference/demo_app/mix.exs` |
| **Canonical quick run command** | `mix test test/mailglass/demo_data_test.exs` (repo root, after Plan `68-01` Task 2 creates the wrapper) |
| **Bootstrap fallback command** | `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/demo_data_reset_test.exs --warnings-as-errors` (inside `reference/demo_app`, while implementing Plan `68-01` Task 1 before the wrapper exists) |
| **Demo-app targeted fallback** | `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/*.exs --warnings-as-errors` |
| **Full suite command** | `mix test` (repo root) |
| **Estimated runtime** | ~30-90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mailglass/demo_data_test.exs` from the repo root once the wrapper exists; while implementing Plan `68-01` Task 1 before that file exists, use the bootstrap fallback command above inside `reference/demo_app`.
- **After every plan wave:** Run `mix test` from the repo root.
- **Before `$gsd-verify-work`:** Full suite must be green from the repo root.
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 68-01-01 | 01 | 0 | Phase goal | T-68-01 | Fixture reset remains deterministic and scoped to demo data | integration | `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/demo_data_reset_test.exs --warnings-as-errors` | yes | covered |
| 68-01-02 | 01 | 1 | Phase goal | T-68-02 | Outbound/inbound/webhook/replay scenarios use sanctioned schema states only | integration | `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/demo_data_reset_test.exs --warnings-as-errors` | yes | covered |
| 68-01-03 | 01 | 1 | Phase goal | T-68-03 | Suppression scenarios model B2B SaaS risk without leaking real tenant/user data | integration | `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/demo_data_reset_test.exs --warnings-as-errors` | yes | covered |
| 68-01-04 | 01 | 2 | Phase goal | T-68-04 | Replay lineage preserves stored-truth evidence semantics | integration | `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/demo_data_reset_test.exs --warnings-as-errors` | yes | covered |
| 68-01-05 | 01 | 2 | Phase goal | T-68-05 | Demo reset remains callable through `mix demo.reset` and does not require new fixture infra | integration | `mix test test/mailglass/demo_data_test.exs` | yes | covered |

*Status: pending / green / red / flaky*

Rows `68-01-01` through `68-01-04` intentionally use the demo-app bootstrap lane because the repo-root wrapper is introduced by Plan `68-01` Task 2. After that file lands, `mix test test/mailglass/demo_data_test.exs` becomes the canonical quick command for all remaining Phase 68 work.

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

**Approval:** validated 2026-06-02
