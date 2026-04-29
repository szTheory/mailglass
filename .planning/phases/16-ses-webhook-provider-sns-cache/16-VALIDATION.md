---
phase: 16
slug: ses-webhook-provider-sns-cache
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-28
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (OTP-native) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mailglass/webhook/providers/ses_test.exs test/mailglass/webhook/providers/ses/cert_cache_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mailglass/webhook/providers/ses_test.exs test/mailglass/webhook/providers/ses/cert_cache_test.exs`
- **After every plan wave:** Run `mix test test/mailglass/webhook/`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 0 | SES-01..05 | T-16-01 | Test stubs fail before impl | unit | `mix test test/mailglass/webhook/providers/ses_test.exs` | ❌ W0 | ⬜ pending |
| 16-01-02 | 01 | 0 | SES-04 | T-16-02 | Cert cache test stubs | unit | `mix test test/mailglass/webhook/providers/ses/cert_cache_test.exs` | ❌ W0 | ⬜ pending |
| 16-01-03 | 01 | 1 | SES-01 | — | text/plain JSON parsed correctly | unit | `mix test test/mailglass/webhook/providers/ses_test.exs` | ✅ W0 | ⬜ pending |
| 16-02-01 | 02 | 1 | SES-03 | T-16-01 | Valid RSA sigs accepted; tampered rejected | unit | `mix test test/mailglass/webhook/providers/ses_test.exs` | ✅ W0 | ⬜ pending |
| 16-02-02 | 02 | 1 | SES-04 | T-16-02 | ETS hit served from cache; miss fetches | unit | `mix test test/mailglass/webhook/providers/ses/cert_cache_test.exs` | ✅ W0 | ⬜ pending |
| 16-03-01 | 03 | 2 | SES-02 | T-16-03 | SubscriptionConfirmation auto-confirms | unit | `mix test test/mailglass/webhook/providers/ses_test.exs` | ✅ W0 | ⬜ pending |
| 16-04-01 | 04 | 2 | SES-05 | — | SES events map to normalized taxonomy | unit | `mix test test/mailglass/webhook/providers/ses_test.exs` | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass/webhook/providers/ses_test.exs` — stubs for SES-01, SES-02, SES-03, SES-05
- [ ] `test/mailglass/webhook/providers/ses/cert_cache_test.exs` — stubs for SES-04
- [ ] `test/support/fixtures/webhooks/ses/` — fixture directory with JSON fixture files (notification, subscription_confirmation, unsubscribe_confirmation, bounce, complaint, delivery, open, click)
- [ ] Test RSA keypair generation helper — `test/support/fixtures/webhooks/ses_fixture_helper.ex` with `generate_test_cert/0` using `:public_key.generate_key({:rsa, 2048, 65537})` and `:public_key.pkix_sign/2`
- [ ] `:httpc` stub/interceptor for subscription confirmation calls in tests

*SNS subscription confirmation :httpc calls require test-time stubbing via Mox or :httpc interceptor*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| SNS SubscribeURL trust validation against live SNS endpoint | SES-02 | Requires live AWS SNS topic and valid subscription | Configure real SNS topic, mount endpoint, verify auto-confirmation in AWS console |
| X.509 cert fetch from real amazonaws.com host | SES-03/04 | Requires network I/O to AWS | Integration test in daily cron CI lane only, not PR gate |

---

## Security Validation Map

| ASVS Category | Control | Automated Check |
|---------------|---------|-----------------|
| V2 Authentication | SNS RSA signature verification via :public_key | unit test: tampered signature rejected |
| V4 Access Control | Trust-policy validation before network I/O | unit test: forged SigningCertURL rejected |
| V5 Input Validation | URI.parse + regex on SigningCertURL | unit test: non-SNS host rejected |
| V6 Cryptography | :public_key RSA verify — never hand-roll | code review gate |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SSRF via SigningCertURL | Spoofing | `^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$` host validation + https-only |
| Replay attack via forged SNS message | Tampering | RSA signature covers all canonical fields; idempotency key in DB |
| Subscription hijack | Elevation | TopicArn + Token used for ConfirmSubscription; SubscribeURL never followed |
| Forged SubscribeURL from attacker bucket | Spoofing | Host regex on SubscribeURL before any I/O; construct request from TopicArn + Token |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
