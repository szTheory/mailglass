---
phase: 16-ses-webhook-provider-sns-cache
plan: "01"
subsystem: webhook-test-scaffolding
tags: [ses, sns, webhook, test, fixtures, rsa, cert-cache]
dependency_graph:
  requires: []
  provides:
    - test/support/fixtures/webhooks/ses/ (16 JSON fixture files)
    - test/support/webhook_fixtures.ex (generate_sns_keypair/0, sign_sns_canonical_string/3, load_ses_fixture/1)
    - test/support/webhook_case.ex (stub_ses_fixture/1, :ses conn clause)
    - test/mailglass/webhook/providers/ses_test.exs (RED state, 20 tests)
    - test/mailglass/webhook/providers/ses/cert_cache_test.exs (RED state, 7 tests)
  affects:
    - 16-02-PLAN.md (CertCache implementation uses CertCacheTest as spec)
    - 16-03-PLAN.md (SES provider implementation uses SESTest as spec)
tech_stack:
  added: []
  patterns:
    - RSA keypair generation via :public_key.generate_key/1 at test runtime (no baked keys)
    - SNS canonical string building (byte-sorted field/value pairs)
    - CertCache ETS stub pattern (put public key directly, bypass :httpc)
    - Payload-only fixtures with PLACEHOLDER_REPLACED_AT_TEST_RUNTIME signature
key_files:
  created:
    - test/support/fixtures/webhooks/ses/notification_bounce_permanent.json
    - test/support/fixtures/webhooks/ses/notification_bounce_transient.json
    - test/support/fixtures/webhooks/ses/notification_complaint.json
    - test/support/fixtures/webhooks/ses/notification_delivery.json
    - test/support/fixtures/webhooks/ses/event_send.json
    - test/support/fixtures/webhooks/ses/event_delivered.json
    - test/support/fixtures/webhooks/ses/event_bounced_permanent.json
    - test/support/fixtures/webhooks/ses/event_bounced_transient.json
    - test/support/fixtures/webhooks/ses/event_complained.json
    - test/support/fixtures/webhooks/ses/event_rejected.json
    - test/support/fixtures/webhooks/ses/event_opened.json
    - test/support/fixtures/webhooks/ses/event_clicked.json
    - test/support/fixtures/webhooks/ses/event_failed.json
    - test/support/fixtures/webhooks/ses/event_delivery_delay.json
    - test/support/fixtures/webhooks/ses/subscription_confirmation.json
    - test/support/fixtures/webhooks/ses/unsubscribe_confirmation.json
    - test/mailglass/webhook/providers/ses_test.exs
    - test/mailglass/webhook/providers/ses/cert_cache_test.exs
  modified:
    - test/support/webhook_fixtures.ex
    - test/support/webhook_case.ex
decisions:
  - RSA keypair generates {public_key_term, private_key_record} rather than PEM bytes — tests stub CertCache.put/3 directly, bypassing :httpc entirely
  - SNS Notification fixtures use JSON-encoded Message string (double-encoded) matching real AWS wire format
  - Control-plane fixtures (SubscriptionConfirmation, UnsubscribeConfirmation) have flat structure with no inner Message JSON
  - test/mailglass/webhook/providers/ses/cert_cache_test.exs uses ExUnit.Case (not WebhookCase) to keep ETS tests focused
metrics:
  duration: ~15 minutes
  completed_date: "2026-04-28"
  tasks_completed: 2
  files_created: 20
  files_modified: 2
---

# Phase 16 Plan 01: SES Test Scaffold (Wave 0) Summary

RSA-signed SNS test scaffold with 16 JSON fixture files and RED-state test stubs for the SES webhook provider and CertCache.

## What Was Built

**Task 1: 16 JSON SNS/SES fixture files** in `test/support/fixtures/webhooks/ses/`:

- 4 classic SNS Notification fixtures (bounce permanent/transient, complaint, delivery) — `notificationType` field
- 10 SES event publishing fixtures (send, delivery, bounce permanent/transient, complaint, reject, open, click, rendering failure, delivery delay) — `eventType` field
- 2 SNS control-plane fixtures (SubscriptionConfirmation, UnsubscribeConfirmation) — flat envelope, no inner SES JSON

All Notification fixtures follow the SNS wire format: `"Message"` field is a JSON-encoded string (double-encoded), not a nested object. Control-plane fixtures have `"Type"` = `"SubscriptionConfirmation"` or `"UnsubscribeConfirmation"`. All signatures use `"PLACEHOLDER_REPLACED_AT_TEST_RUNTIME"`.

**Task 2: Test helpers and RED-state test stubs**

`WebhookFixtures` additions:
- `generate_sns_keypair/0` — returns `{public_key_term, private_key_record}` for CertCache stub pattern
- `sign_sns_canonical_string/3` — RSA-SHA1 (default) or RSA-SHA256 (`:digest` opt) signer for canonical strings
- `load_ses_fixture/1` — loads `test/support/fixtures/webhooks/ses/*.json` by name

`WebhookCase` additions:
- `stub_ses_fixture/1` — delegates to `WebhookFixtures.load_ses_fixture/1`
- `mailglass_webhook_conn(:ses, ...)` clause — builds POST conn to `/webhooks/ses` with `x-amz-sns-message-type: Notification` header
- `prior_ses` env snapshot + `restore_env(:ses, prior_ses)` in `on_exit`

`ses_test.exs`: 20 tests across 5 describe blocks:
1. `verify!/3 SNS signature verification` — valid, tampered, bad cert URL (SSRF), malformed JSON
2. `verify!/3 SNS control-plane` — subscription confirmation, unsubscribe confirmation
3. `normalize/2 classic feedback` — Bounce Permanent/Transient, Complaint, Delivery
4. `normalize/2 event publishing` — 10 event type mappings
5. `normalize/2 metadata requirements` — string keys, provider_event_id pattern

`cert_cache_test.exs`: 7 tests across 3 describe blocks:
1. `fetch_public_key/1` — miss on empty, hit within TTL, miss on expired, ETS eviction on expiry, independent URLs
2. `reset/0` — clears all entries
3. `table/0` — returns `:mailglass_webhook_ses_cert_cache`

## Deviations from Plan

None — plan executed exactly as written.

The plan offered alternative approaches for `generate_sns_keypair/0` (PEM-based certificate vs. raw RSA key with CertCache stub). The plan's "Definitive implementation" section specified `{public_key_term, private_key_record}` as the return shape, which was followed verbatim.

## Known Stubs

All 20 tests in `ses_test.exs` and all 7 tests in `cert_cache_test.exs` are intentional RED-state stubs. They reference `Mailglass.Webhook.Providers.SES` and `Mailglass.Webhook.Providers.SES.CertCache` which do not exist yet. These stubs will turn GREEN in Plans 02 (CertCache) and 03 (SES provider).

## Threat Flags

None — test fixtures use synthetic emails (bounce@example.com, spam@example.com) and generate RSA keys at runtime. No private keys are baked into fixtures or source files.

## Self-Check: PASSED

Files exist:
- `test/support/fixtures/webhooks/ses/` — 16 files confirmed (count verified: 16)
- `test/mailglass/webhook/providers/ses_test.exs` — exists
- `test/mailglass/webhook/providers/ses/cert_cache_test.exs` — exists
- `test/support/webhook_fixtures.ex` — contains `generate_sns_keypair` (4 occurrences)
- `test/support/webhook_case.ex` — contains `stub_ses_fixture: 1`

Commits exist:
- `372127e` — test(16-01): add 16 SNS/SES JSON fixture files
- `a076f20` — test(16-01): add SES test scaffolding and helpers (RED state)

Compile: `mix compile --warnings-as-errors` exits 0 (no output = no errors)
Tests: 29/29 fail in RED state referencing `Mailglass.Webhook.Providers.SES` — confirmed.
