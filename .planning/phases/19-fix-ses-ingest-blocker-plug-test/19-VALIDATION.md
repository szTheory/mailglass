---
phase: 19
slug: fix-ses-ingest-blocker-plug-test
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-30
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir, OTP 27) |
| **Config file** | `test/test_helper.exs` (existing — Wave 0 not required) |
| **Quick run command** | `mix test test/mailglass/webhook/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30s quick / ~3 min full |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mailglass/webhook/`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green with no `--only` scoping or test exclusions (success criterion #4)
- **Max feedback latency:** 30 seconds (quick run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 19-01-01 | 01 | 1 | SES-01 | — | `:ses` accepted by `ingest_multi/3` guard at `lib/mailglass/webhook/ingest.ex:122` | unit | `mix test test/mailglass/webhook/ingest_test.exs` (or grep guard) | ✅ | ⬜ pending |
| 19-01-02 | 01 | 1 | SES-03 | — | `derive_webhook_provider_event_id(:ses, _, [first \| _])` clause delegates to `extract_event_provider_id/1` | unit | `grep -nE 'defp derive_webhook_provider_event_id\(:ses, _raw_body, \[first \| _\]\)' lib/mailglass/webhook/ingest.ex && mix compile --warnings-as-errors` (behavioral coverage: Wave 2 via 19-02-01) | ✅ | ⬜ pending |
| 19-02-01 | 02 | 2 | SES-04 | T-19-01 (SNS signature bypass leak) | Signed SES Notification flows through `Mailglass.Webhook.Plug` and persists a `WebhookEvent` row | integration (Plug-level) | `mix test test/mailglass/webhook/plug_ses_test.exs` | ❌ W0 (new file) | ⬜ pending |
| 19-02-02 | 02 | 2 | SES-04 | — | Sandbox + `with_tenant/2` ownership matches Mailgun analog | integration | included in plug_ses_test.exs | ❌ W0 | ⬜ pending |
| 19-03-01 | 03 | 3 | SES-05 | — | `mix test` exits 0 with no scoping; `mix credo --strict` clean | suite | `mix test && mix credo --strict` | ✅ | ⬜ pending |
| 19-03-02 | 03 | 3 | SES-05 | — | Conventional Commits `fix:` triggers Release Please v0.3.3 | manual + CI | `gh release view v0.3.3` (post-merge) | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass/webhook/plug_ses_test.exs` — new Plug-level integration test (~120 lines, mirrors `plug_mailgun_test.exs`)

*All other test infrastructure ships from Phase 16: `WebhookCase`, `generate_sns_keypair/0`, `sign_sns_canonical_string/3`, `mailglass_webhook_conn(:ses, _)`, `CertCache.put/3`, and 16 SES fixtures already exist.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| v0.3.3 published to Hex.pm via Release Please | SES-05 | Release Please runs in CI on merge to main; verification is observational | After PR merge: `gh release view v0.3.3` and `mix hex.info mailglass` should report 0.3.3 |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (only `plug_ses_test.exs`)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
