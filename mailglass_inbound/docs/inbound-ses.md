# SES Inbound

This guide assumes you have completed the [inbound-install.md](inbound-install.md) setup.
It covers the full pipeline for receiving mail through Amazon SES: SNS topic, IAM policy,
SES receipt rules, optional dep install, production config, and the behavioral guarantees
the package provides once the pipeline is wired.

## Overview

Amazon SES inbound works through a two-leg pipeline:

```
SES Receipt Rules → S3 (raw MIME body) + SNS topic (notification) → your endpoint
```

When SES receives a message matching your receipt rule:

1. SES stores the raw MIME body in your S3 bucket (the S3 action).
2. SES publishes a notification to your SNS topic (the SNS action).
3. SNS delivers the notification to your HTTPS endpoint via subscription.
4. The ingress plug verifies the SNS X.509 signature, reads the S3 object key from the
   notification, fetches the raw MIME bytes from S3, and processes the message.

This is distinct from SES **sending-event webhooks** (delivery/bounce/complaint
notifications) — those flow through a different AWS pipeline and are handled by the core
`mailglass` package's SES webhook adapter.

## Mount Path

Mount the ingress plug on a dedicated SES route in your Phoenix router:

```elixir
forward "/inbound/:tenant_id/ses",
  MailglassInbound.Ingress.Plug,
  provider: :ses,
  router: MyApp.MailglassInboundRouter
```

The ingress plug is verify-first:

1. read the exact request bytes from `conn.private[:raw_body]`
2. verify the SNS X.509 signature
3. dispatch on SNS message type (Notification, SubscriptionConfirmation, UnsubscribeConfirmation)
4. for Notifications: fetch raw MIME from S3
5. resolve tenant scope
6. normalize into `%MailglassInbound.InboundMessage{}`
7. persist one canonical row plus one raw evidence row
8. dispatch mailbox execution only for newly inserted records

## Plug.Parsers Wiring

Your endpoint must include the caching body reader from the install guide:

```elixir
plug Plug.Parsers,
  parsers: [:json],
  pass: ["*/*"],
  json_decoder: Jason,
  body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}
```

Without this `body_reader`, SNS signature verification fails — the raw bytes that SNS signs
are not available for X.509 verification.

## SNS Topic Setup

1. Open the **SNS console** and create a new topic.
   - Type: **Standard** (not FIFO — SNS HTTP subscriptions are not supported on FIFO topics).
   - Name: e.g. `mailglass-inbound-ses`.
   - Note the **Topic ARN** — you will need it when configuring the SES receipt rule.

2. Create an **HTTPS subscription** to your endpoint:
   - Protocol: `HTTPS`
   - Endpoint: `https://your-app.example.com/inbound/YOUR_TENANT_ID/ses`
   - Click **Create subscription**.

3. **Confirm the subscription manually.** After SNS delivers a
   `SubscriptionConfirmation` POST to your endpoint, the ingress plug validates
   the `SubscribeURL` host against the hardcoded SNS trust policy (SSRF guard)
   and returns `200 OK`, but it does **not** follow the URL. SNS requires an
   HTTP GET to the `SubscribeURL` to complete confirmation.

   Visit the SNS console → your subscription → **Request confirmation** (or
   retrieve the `SubscribeURL` from the SNS delivery attempt logs and curl it):

   ```bash
   curl "https://sns.us-east-1.amazonaws.com/?Action=ConfirmSubscription&..."
   ```

   The subscription status changes from `PendingConfirmation` to `Confirmed`
   once SNS receives your GET. Until confirmed, no `Notification` messages are
   delivered. See [SubscribeURL Trust Policy](#subscribeurl-trust-policy) for
   details on the host validation that guards against SSRF.

## IAM Policy

The SES receipt rule needs permission to write the raw message body to your S3 bucket. Your
application (or the environment where it runs) needs permission to read from that bucket.

### SES Delivery Role

Attach a policy to the IAM role used by your SES receipt rule action that allows `s3:PutObject`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject"],
      "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/inbound/*"
    }
  ]
}
```

Replace `YOUR-BUCKET-NAME` with your actual bucket name and `inbound/` with the key prefix
you configured in the receipt rule S3 action.

### Application Read Policy

Attach a policy to your application's IAM role (or instance profile / pod identity) that
allows reading from the bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
    }
  ]
}
```

Replace `YOUR-BUCKET-NAME` with your actual bucket name. The `/*` suffix is required because
the object key is the SES message ID, which varies per message.

## SES Receipt Rule Setup

1. Open the **SES console → Email Receiving → Rule Sets**.
2. Select an existing rule set or create a new one and activate it.
3. Create a new rule:
   - **Recipient conditions:** add the address or domain patterns you want to receive mail for
     (e.g. `support@mg.example.com` or `@mg.example.com` for all addresses on the domain).
   - **Action 1: S3** — store to `YOUR-BUCKET-NAME` with key prefix `inbound/`.
     SES stores the raw MIME body at `s3://YOUR-BUCKET-NAME/inbound/{messageId}`.
   - **Action 2: SNS** — publish notification to your SNS topic ARN.
     The SNS notification includes the S3 bucket name and object key, which the ingress plug
     uses to fetch the raw MIME body.
4. Save the rule.

> **Order matters:** The S3 action must come before the SNS action. SNS can deliver the
> notification before S3 write-after-read consistency is guaranteed. The plug retries the
> S3 fetch to handle this — see [S3 Consistency](#s3-consistency).

## Optional Deps Install

SES inbound requires three optional packages plus an HTTP client. Add them to your
`mix.exs` dependencies:

```elixir
defp deps do
  [
    # existing deps ...
    {:ex_aws, "~> 2.7"},
    {:ex_aws_s3, "~> 2.5"},
    {:sweet_xml, "~> 0.7"},
    # Choose one HTTP client that ex_aws supports:
    {:hackney, "~> 1.20"}
    # {:req, "~> 0.5"}
    # {:finch, "~> 0.19"}
  ]
end
```

`ex_aws` and `ex_aws_s3` are the AWS SDK; `sweet_xml` is required by `ex_aws_s3` for
XML response parsing; the HTTP client is required by `ex_aws` for making AWS API requests.
Any HTTP client that `ex_aws` supports will work — `hackney` is the most commonly used.

### AWS Credentials

`ex_aws` resolves credentials from the standard AWS chain: environment variables
(`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`), ECS task roles, EC2 instance
profiles, or EKS pod identity. No mailglass-specific credential configuration is needed.

## Configuration

> **Warning:** The default `s3_fetcher` is the Fake adapter, which is **test-only** and
> performs no real S3 fetch. You must explicitly configure the production fetcher or your
> application will silently process no inbound mail in production.

Configure the SES inbound provider in your runtime config:

```elixir
# config/runtime.exs
config :mailglass_inbound, :ses,
  s3_fetcher: MailglassInbound.S3Fetcher.ExAwsS3
```

`MailglassInbound.S3Fetcher.ExAwsS3` is the real adapter that calls `ExAws.S3.get_object/2`
to fetch the message body. It is gated behind the optional deps above — the config key is
`nil` (and therefore resolves to the Fake adapter) unless you set it explicitly.

### Optional Tuning Knobs

```elixir
config :mailglass_inbound, :ses,
  s3_fetcher: MailglassInbound.S3Fetcher.ExAwsS3,
  # How long X.509 signing certificates are cached (default: 3600 seconds / 1 hour)
  cert_cache_ttl_seconds: 3600,
  # S3 retry configuration (default: 3 attempts, 250ms/1000ms/2000ms backoff)
  s3_retry_opts: [max_attempts: 3, backoff_ms: [250, 1_000, 2_000]]
```

## SubscribeURL Trust Policy

When SNS sends a `SubscriptionConfirmation` message to your endpoint, the notification
includes a `SubscribeURL` that SNS uses to verify the subscription. The ingress plug
validates this URL against a hardcoded trust policy before taking any action.

The trust policy enforces that the `SubscribeURL` host matches:

```
^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$
```

URLs that do not match this pattern are rejected immediately — the plug returns `401`
without following the URL. This prevents an attacker from injecting a forged
`SubscriptionConfirmation` that points to an internal service (an SSRF attack).

**No adopter-configurable allowlist is needed or provided.** A dynamic allowlist would be
exploitable — if an adopter misconfigured it to include a broader pattern, a forged
subscription confirmation could be used to make your server issue arbitrary HTTPS requests.
The hardcoded AWS SNS host pattern is the correct security boundary.

## S3 Consistency

S3 provides read-after-write consistency for new objects, but SNS can deliver the
notification in the brief window before the S3 write is fully visible to all readers. If the
S3 `GetObject` call returns a "not found" or transient error, the plug retries:

- Up to 3 attempts total.
- Backoff: 250ms after the first attempt, 1000ms after the second, 2000ms after the third.
- After 3 failed attempts, the plug returns a structured `S3FetchError` and the request
  returns `500` so SNS can retry later.

The retry behavior is configurable via `s3_retry_opts` if your workload has different
latency characteristics.

## KMS Limitation

If you enable **client-side KMS encryption** on your S3 bucket — where the object is
encrypted by the SES client using a KMS key before upload — the raw bytes returned by
`GetObject` will be KMS ciphertext. The ingress plug does not hold or use any KMS keys and
cannot decrypt this ciphertext.

The result is a **degraded record**: the MIME parser processes the ciphertext bytes and
produces a record with empty normalized fields (`text_body`, `html_body`, `from`, `to`,
etc.). The raw ciphertext bytes are preserved in the evidence row. No crash occurs.

**Use bucket-level server-side encryption (SSE) instead:**

- **SSE-S3** (`AES256`): S3 manages the keys transparently. No changes needed on the
  read path — `GetObject` returns plaintext bytes.
- **SSE-KMS** with a bucket policy: S3 decrypts using the specified KMS key on `GetObject`.
  Ensure your application's IAM role has `kms:Decrypt` permission on the key.

Client-side KMS encryption (where encryption happens before upload using the AWS SDK's
`S3EncryptionClient`) is not supported and produces unusable records. Use SSE.

## Testing in Development

In the test and development environments, the `s3_fetcher` key defaults to the Fake adapter
(`MailglassInbound.S3Fetcher.Fake`), which returns a pre-configured raw MIME body without
making any real S3 calls. You do not need AWS credentials to run the test suite.

Use the built-in fixture helper to construct test payloads:

```elixir
# Keyword list — map is not accepted here
payload = MailglassInbound.Fixtures.build_ses_sns_payload(subject: "SES inbound test")

# To test with a custom body:
payload = MailglassInbound.Fixtures.build_ses_sns_payload(
  subject: "SES inbound test",
  text_body: "Custom body content"
)
```

> **Note:** `:bucket` and `:key` are fixture-internal constants and cannot be
> overridden via options. To control the message content, use the supported options
> above (`:subject`, `:text_body`, `:html_body`, `:from`, `:to`).

The Fake adapter is wired by default when no `s3_fetcher` is configured in the test
environment. In production, the `s3_fetcher` must be set explicitly to
`MailglassInbound.S3Fetcher.ExAwsS3`.

## Persistence Semantics

A verified SES notification writes two records before mailbox execution:

- one canonical normalized row in `mailglass_inbound_records`
- one linked raw evidence row in `mailglass_inbound_evidence`

The evidence row carries the SNS payload JSON, selected request headers, verification
facts, parse warnings, and attachment blobs. The raw MIME bytes fetched from S3 are stored
in the evidence `raw_mime` column.

Duplicate requests (same `tenant_id`, `provider`, and `provider_message_id`) collapse on
the canonical row — no second record is created and no second mailbox execution is
dispatched.

`SubscriptionConfirmation` and `UnsubscribeConfirmation` messages from SNS are handled
as control-plane messages: they return `200 OK` immediately and create no records.

Mailbox execution is dispatched after persistence commits. The Oban-backed path is the
durable route. Without Oban, `Task.Supervisor` fallback is bounded best-effort only —
no automatic retry on execution failure.
