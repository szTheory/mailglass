# Webhook Troubleshooting

## 1) Introduction

This guide helps you diagnose and fix common issues with Mailglass webhook ingestion. Mailglass uses a "verify-first, tenant-second" architecture, which means most failures happen at the signature verification layer before your application code is even reached.

## 2) Signature Verification Failures

Most webhook issues stem from failed signature verification. This is usually caused by a configuration gap in your Phoenix `Endpoint` or missing environment variables.

### CachingBodyReader placement

Mailglass requires the raw request body to verify signatures. Because `Plug.Parsers` consumes the request stream, you must use `Mailglass.Webhook.CachingBodyReader` to capture the bytes before they are decoded into JSON.

**Checklist:**
- Ensure `body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []}` is present in your `plug Plug.Parsers` configuration in `lib/my_app_web/endpoint.ex`.
- Confirm that no other `Plug.Parsers` (like those for `multipart` or `urlencoded`) appear **before** the one containing the `CachingBodyReader` for your webhook routes.

### Signing Secrets

Each provider uses a different signing method. Ensure your secrets are correctly configured in `config/runtime.exs`.

- **Postmark:** Uses Basic Auth. Verify `POSTMARK_WEBHOOK_USER` and `POSTMARK_WEBHOOK_PASS`.
- **SendGrid:** Uses ECDSA P-256. The `public_key` must be the base64-encoded **SPKI DER** string from the SendGrid portal (not PEM).
- **Mailgun:** Uses HMAC-SHA256. Ensure `MAILGUN_WEBHOOK_SIGNING_KEY` is correct.
- **Resend:** Uses Svix-style HMAC. Ensure `RESEND_WEBHOOK_SECRET` starts with `whsec_`.

## 3) Provider-Specific Setup

### Amazon SES (via SNS)

SES webhooks are delivered through SNS.
- **Handshake:** Mailglass automatically confirms SNS subscriptions. If a subscription remains "Pending", ensure your endpoint is publicly reachable and returns 200 to the `SubscriptionConfirmation` POST.
- **Certificates:** Mailglass fetches and caches Amazon's X.509 certificates. Ensure your server can make outbound HTTPS requests to `sns.amazonaws.com`.

### SendGrid Batches

SendGrid can send up to 128 events in a single POST.
- **Length Limit:** Ensure your `Plug.Parsers` has `length: 10_000_000` (10MB) to accommodate these large payloads.

## 4) Ingest Latency and Backlog

Mailglass processes webhooks synchronously by default to ensure ledger integrity.

### Database Load

If your database is slow, webhook ingest may time out. Mailglass enforces a **2-second statement timeout** on ingest.
- Check `[:mailglass, :webhook, :ingest, :stop]` telemetry for elevated latency.
- Monitor your database for lock contention on the `mailglass_webhook_events` table.

### Orphaned Events

If a webhook arrives before the `Delivery` record is committed, it becomes an "orphan" (`delivery_id: nil`).
- **Background-first contract:** If Oban is installed, ensure `Mailglass.Webhook.Reconciler` is scheduled via Oban cron. If Oban is absent, schedule `mix mailglass.reconcile` from system cron or another job runner.
- **Truthful outcome check:** `mix mailglass.reconcile` reports `linked` when a sweep appended new `:reconciled` audit events and `still unmatched` for scanned orphans that remain unresolved after the run.
- **Orphan Age:** Check the `[:mailglass, :webhook, :orphan, :stop]` telemetry to see if orphans are failing to reconcile after the expected window.

## 5) Webhook Replay

The Mailglass Admin UI provides a "Replay" feature for webhook events.
- If you fix a configuration issue (e.g., a missing secret), you can replay failed events from the Admin UI.
- Replayed events use the same idempotency logic as the original ingest, preventing duplicate ledger entries.

## 6) Testing Locally

Webhooks require a public URL. Use a tool like **ngrok** or **localtunnel** to expose your local Phoenix server.

1. Start ngrok: `ngrok http 4000`
2. Update your provider's webhook URL to the ngrok URL (e.g., `https://random-id.ngrok.io/webhooks/postmark`).
3. Send a test webhook from the provider's dashboard.

## 7) Troubleshooting

### Symptom: Provider reports 401 Unauthorized

- **Check:** Verify the signing secret/key in `config/runtime.exs` matches the provider's dashboard.
- **Check:** Ensure `CachingBodyReader` is configured in `endpoint.ex`.
- **Check:** (Postmark) If using `ip_allowlist`, ensure `remote_ip` is correctly forwarded by your proxy (use `Plug.RewriteOn`).

### Symptom: Provider reports 413 Payload Too Large

- **Check:** Increase the `length` limit in `Plug.Parsers` to `10_000_000`.

### Symptom: Webhook received but no Delivery matched

- **Check:** Confirm the `message_id` or `provider_id` in the webhook matches a `Delivery` record in the database.
- **Check:** Ensure the reconcile sweep is running through Oban cron or `mix mailglass.reconcile`.
- **Check:** If a manual sweep finishes with `still unmatched > 0`, inspect whether the orphan event metadata is missing the provider/message identifiers needed for a safe match.

### Symptom: 500 Internal Server Error

- **Check:** Look at the server logs. A `500` usually indicates a configuration error (e.g., a missing required config key) or a database timeout.
- **Check:** Verify the provider is enabled in `config :mailglass, :provider_name, enabled: true`.

---

*Last updated: 2026-05-03 (Phase 31 ships at v0.1).*
