---
phase: 15
slug: mailgun-webhook-provider
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mailglass/webhook/providers/mailgun_test.exs test/mailglass/webhook/plug_mailgun_test.exs test/mailglass/webhook/router_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mailglass/webhook/providers/mailgun_test.exs test/mailglass/webhook/plug_mailgun_test.exs test/mailglass/webhook/router_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | MAILGUN-01, MAILGUN-02 | T-15-01 | Wave 0 Mailgun provider and plug test targets exist before later verification commands reference them. | unit | `test -f test/mailglass/webhook/providers/mailgun_test.exs && test -f test/mailglass/webhook/plug_mailgun_test.exs` | ✅ after 15-01 Task 1 | ⬜ pending |
| 15-01-02 | 01 | 1 | MAILGUN-02 | T-15-02 | The provider contract explicitly allows replay-aware success without widening the abstraction beyond `verify!/3`. | unit | `rg -n '@callback verify!\\(.*:: :ok \\| \\{:ok, :replay\\}' lib/mailglass/webhook/provider.ex && rg -n '@callback normalize\\(' lib/mailglass/webhook/provider.ex` | ✅ existing file | ⬜ pending |
| 15-01-03 | 01 | 1 | MAILGUN-02 | T-15-02 | Replay cache infrastructure is supervised and available before provider verification consumes it. | unit | `rg -n 'def check_and_put\\(|def reset|def table' lib/mailglass/webhook/providers/mailgun_replay_cache.ex && rg -n ':mailglass_webhook_mailgun_replay_cache' lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex && rg -n 'MailgunReplayCache\\.Supervisor' lib/mailglass/application.ex` | ✅ existing files | ⬜ pending |
| 15-02-01 | 02 | 2 | MAILGUN-03 | T-15-03 | Stable Mailgun fixture payloads exist before provider tests and normalization assertions consume them. | unit | `test -f test/support/fixtures/webhooks/mailgun/accepted.json && test -f test/support/fixtures/webhooks/mailgun/delivered.json && test -f test/support/fixtures/webhooks/mailgun/failed_temporary.json && test -f test/support/fixtures/webhooks/mailgun/failed_permanent_bounce.json && test -f test/support/fixtures/webhooks/mailgun/failed_permanent_rejected.json && test -f test/support/fixtures/webhooks/mailgun/opened.json && test -f test/support/fixtures/webhooks/mailgun/clicked.json && test -f test/support/fixtures/webhooks/mailgun/complained.json && test -f test/support/fixtures/webhooks/mailgun/unsubscribed.json` | ✅ after 15-02 Task 1 | ⬜ pending |
| 15-02-02 | 02 | 2 | MAILGUN-01, MAILGUN-02, MAILGUN-03 | T-15-04 | The Mailgun provider implementation contains the verify, replay, and normalization hooks required for the later provider suite to exercise real behavior. | unit | `rg -n 'def verify!|def normalize|MailgunReplayCache\\.check_and_put|\\{:ok, :replay\\}|\"provider\" => \"mailgun\"|\"provider_event_id\" => token' lib/mailglass/webhook/providers/mailgun.ex` | ✅ after 15-02 Task 2 | ⬜ pending |
| 15-02-03 | 02 | 2 | MAILGUN-01, MAILGUN-02, MAILGUN-03 | T-15-04 | Fixture helpers and provider tests fully exercise valid signatures, replay, malformed payloads, and the D-09 mapping set. | unit | `mix test test/mailglass/webhook/providers/mailgun_test.exs --warnings-as-errors` | ✅ after 15-01 Task 1 | ⬜ pending |
| 15-03-01 | 03 | 3 | MAILGUN-01, MAILGUN-02 | T-15-07 | Mailgun plug test target and harness exist before runtime wiring verification references them. | integration | `test -f test/mailglass/webhook/plug_mailgun_test.exs && rg -n 'mailglass_webhook_conn\\(:mailgun|signing_key|replay_cache_ttl_seconds|describe ' test/support/webhook_case.ex test/mailglass/webhook/plug_mailgun_test.exs` | ✅ after 15-03 Task 1 | ⬜ pending |
| 15-03-02 | 03 | 3 | MAILGUN-01 | T-15-08 | Mailgun runtime wiring exists in plug, router, and config before the finalized regression suites enforce behavior-level replay and route semantics. | unit | `rg -n '@valid_providers .*:mailgun|provider_module\\(:mailgun\\)|status: :replay|resolve_config!\\(:mailgun' lib/mailglass/webhook/plug.ex && rg -n '@default_providers @valid_providers|@valid_providers .*:mailgun' lib/mailglass/webhook/router.ex && rg -n 'mailgun:|signing_key|timestamp_tolerance_seconds|future_skew_seconds|replay_cache_ttl_seconds' lib/mailglass/config.ex` | ✅ after 15-03 Task 2 | ⬜ pending |
| 15-03-03 | 03 | 3 | MAILGUN-01, MAILGUN-02 | T-15-07, T-15-08, T-15-09 | The finalized plug, router, and config suites prove replay `200`, bad-signature `401`, explicit Mailgun route mounting, and Mailgun config validation. | integration | `mix test test/mailglass/webhook/plug_mailgun_test.exs test/mailglass/webhook/router_test.exs test/mailglass/config_test.exs --warnings-as-errors` | ✅ after 15-03 Task 1 | ⬜ pending |
| 15-04-01 | 04 | 4 | MAILGUN-01, MAILGUN-02 | T-15-07, T-15-08 | Installer snippets and docs publish the explicit Mailgun route and replay `200` contract. | docs | `mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors` | ✅ existing suite | ⬜ pending |
| 15-04-02 | 04 | 4 | MAILGUN-01, MAILGUN-02 | T-15-07, T-15-08 | Golden snapshots and guide text stay synchronized with the explicit Mailgun setup story. | docs | `mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors && rg -n 'providers: \\[:postmark, :sendgrid, :mailgun\\]|MAILGUN_WEBHOOK_SIGNING_KEY|replay.*200' lib/mailglass/installer/templates.ex guides/webhooks.md test/example/README.md` | ✅ existing suite | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass/webhook/providers/mailgun_test.exs` — provider verification, replay, and normalization coverage
- [ ] `test/mailglass/webhook/plug_mailgun_test.exs` — replay-response and ingest-path integration coverage
- [ ] `test/mailglass/webhook/router_test.exs` — explicit provider list and default-mount contract coverage
- [ ] `test/support/fixtures/webhooks/mailgun/*.json` — payload-only webhook fixtures for accepted, delivered, failed, complained, unsubscribed, and replay scenarios

Wave 0 plan binding:
- `15-01` Task 1 creates `test/mailglass/webhook/providers/mailgun_test.exs` and `test/mailglass/webhook/plug_mailgun_test.exs`.
- `15-02` Task 1 creates `test/support/fixtures/webhooks/mailgun/*.json` before provider test verification depends on them.

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
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
