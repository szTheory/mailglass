---
phase: 17
slug: unblock-verify-resend
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-29
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir stdlib) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mailglass/webhook/providers/resend_webhook_plug_test.exs test/mailglass/webhook/plug_test.exs test/mailglass/tracking/endpoint_resolution_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mailglass/webhook/ test/mailglass/tracking/endpoint_resolution_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 17-01-01 | 01 | 1 | — | — | N/A | manual | `grep "async: false" test/mailglass/tracking/endpoint_resolution_test.exs` | ✅ exists | ⬜ pending |
| 17-01-02 | 01 | 1 | RESEND-01 | — | :resend in @valid_providers | unit | `mix test test/mailglass/webhook/plug_test.exs` | ✅ exists | ⬜ pending |
| 17-01-03 | 01 | 1 | RESEND-01 | — | resolve_config!/2 reads :resend env | unit | `mix test test/mailglass/webhook/plug_test.exs` | ✅ exists | ⬜ pending |
| 17-02-01 | 02 | 1 | RESEND-01 | T-17-01 | valid sig accepted → 200 | integration | `mix test test/mailglass/webhook/providers/resend_webhook_plug_test.exs` | ❌ W0 | ⬜ pending |
| 17-02-02 | 02 | 1 | RESEND-01 | T-17-01 | invalid sig rejected → 401 + SignatureError | integration | `mix test test/mailglass/webhook/providers/resend_webhook_plug_test.exs` | ❌ W0 | ⬜ pending |
| 17-02-03 | 02 | 1 | RESEND-01 | T-17-02 | stale timestamp → 401 | integration | `mix test test/mailglass/webhook/providers/resend_webhook_plug_test.exs` | ❌ W0 | ⬜ pending |
| 17-02-04 | 02 | 1 | RESEND-01 | — | missing svix-id → 401 | integration | `mix test test/mailglass/webhook/providers/resend_webhook_plug_test.exs` | ❌ W0 | ⬜ pending |
| 17-02-05 | 02 | 2 | RESEND-02 | — | events map to correct Anymail atoms | unit | `mix test test/mailglass/webhook/providers/resend_test.exs` | ✅ exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass/webhook/providers/resend_webhook_plug_test.exs` — stub file covering RESEND-01 (valid/invalid/stale/missing header scenarios)
- [ ] `test/support/fixtures/webhooks/resend/delivered.json` — JSON fixture needed by plug test

*These must be created before executing plans that reference them.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Phase 14 marked complete in ROADMAP.md | — | Doc update, no automated check | `grep "Status: Complete" .planning/ROADMAP.md` for Phase 14 row |

---

## Threat Model

| ID | Threat | STRIDE | Mitigation | ASVS |
|----|--------|--------|------------|------|
| T-17-01 | Forged webhook (signature bypass) | Spoofing | HMAC-SHA256 via `:crypto.mac` + `Plug.Crypto.secure_compare/2` — already in `verify!/3` | V6 |
| T-17-02 | Replay attack | Repudiation | 300-second timestamp tolerance window — already in `verify_timestamp/2` | V6 |
| T-17-03 | Timing oracle on signature comparison | Information Disclosure | `Plug.Crypto.secure_compare/2` constant-time — already used | V6 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
