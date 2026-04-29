# Feature Landscape

**Domain:** Transactional Email Framework Webhooks (Mailgun, SES, Resend)
**Researched:** 2026-05-XX
**Overall confidence:** HIGH

## Table Stakes

Features users expect. Missing = product feels incomplete or insecure.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Mailgun Signature Verification** | Security. Mailgun webhooks use HMAC-SHA256 of `timestamp` + `token`. | Low | Requires specific "Webhook Signing Key" (not API key). |
| **Resend/Svix Signature Verification** | Security. Resend uses Svix for webhooks, requiring `svix-id`, `svix-timestamp`, and `svix-signature` header validation. | Medium | **Critical constraint:** Verification requires the exact raw HTTP request body string. Any JSON parsing before verification will break the signature. |
| **SES SNS Subscription Auto-Confirmation** | Usability. SES pushes events via Amazon SNS, which requires a one-time HTTP `GET` to a `SubscribeURL` when an endpoint is first added. | Medium | If not handled automatically by the webhook plug, developers must manually parse logs and `curl` the URL, which is a terrible DX. |
| **SES SNS Signature Verification** | Security. SNS payload includes a `Signature` and `SigningCertURL` that must be validated to trust the event. | High | Requires fetching the certificate from AWS, parsing x509, and verifying the RSA signature. |
| **SES Envelope Unwrapping** | Usability. The actual SES event (Bounce, Delivery, Complaint) is sent as a stringified JSON string inside the SNS `Message` property. | Low | Must unwrap the SNS envelope and `Jason.decode!` the `Message` string before passing to the Anymail normalizer. |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Raw Body Caching Plug** | Essential for Resend. Native Phoenix `Plug.Parsers` consumes the body. A custom `CachingBodyReader` allows JSON parsing while preserving the raw string for Svix validation. | Medium | Mailglass likely already has a `CachingBodyReader` from the v0.1 Postmark/SendGrid work. It needs to be leveraged for Resend. |
| **Mailgun Replay Attack Prevention** | Mailgun sends a unique `token`. Caching this token (e.g., via ETS or Cachex) for 24 hours prevents attackers from replaying intercepted webhook payloads. | Medium | Requires a lightweight transient storage mechanism. Can fall back to simple timestamp staleness check if stateful cache is avoided. |
| **Seamless SNS Abstraction** | The user shouldn't know or care that AWS wraps SES in SNS. The framework should handle the SNS handshake silently. | Low | The Anymail mapper for SES should only receive the unwrapped SES payload. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Manual SNS Confirmation UI** | Building admin UI to paste `SubscribeURL`s is wasted effort. | The webhook ingestion endpoint should detect `Type: SubscriptionConfirmation` and execute a side-effect HTTP GET to the URL immediately, returning 200 OK. |
| **Storing Raw Webhook Payloads** | Wastes database space and potentially violates privacy if payloads contain PII. | Parse, verify, map to the internal `Event` struct, and discard the raw JSON/body. |
| **Bringing in a full Svix dependency** | Pulling in a large external Elixir Svix SDK just for webhook verification adds bloat. | Implement the HMAC-SHA256 verification manually based on Svix specs (it's just base64 decoding the signature and comparing it to `HMAC-SHA256(msg_id + timestamp + raw_body)`). |

## Feature Dependencies

```text
CachingBodyReader → Resend Webhook Verification (Requires raw body)
HTTP Client (Req/Finch) → SES Subscription Confirmation (Requires making an outbound GET request to the SubscribeURL)
X509 / `:public_key` → SES Signature Verification (Requires cert parsing and RSA verification)
```

## MVP Recommendation

Prioritize:
1. **Raw Body Caching** (confirm existing v0.1 `CachingBodyReader` handles Resend's needs).
2. **Mailgun HMAC-SHA256 Verification** (simplest to implement).
3. **Resend Svix Verification** (manual implementation of the Svix signature algorithm to avoid dependencies).
4. **SES SNS Unwrapping & Auto-Confirmation** (highest DX value for AWS users).
5. **SES Signature Validation** (most complex due to certificate fetching, but mandatory for security).

## Sources

- Mailgun Webhook Security Docs (HMAC-SHA256 standard)
- Resend Webhook Docs (Svix standard, raw body requirement)
- Amazon SES / SNS Webhook Documentation (SubscriptionConfirmation, Notification envelope)
