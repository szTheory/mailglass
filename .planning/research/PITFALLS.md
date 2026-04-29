# Pitfalls Research

**Domain:** Transactional Email Framework Webhooks (Mailgun, SES, Resend)
**Researched:** 2026-05-01
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: SNS Webhook `text/plain` Content-Type Mismatch (SES)

**What goes wrong:**
Amazon SES/SNS sends webhook events with valid JSON payloads, but incorrectly sets the `Content-Type` header to `text/plain`. The Phoenix application receives an empty `conn.params` because `Plug.Parsers` ignores the body, causing the webhook handler to crash or fail silently.

**Why it happens:**
Developers assume a JSON payload will arrive with `application/json`. `Plug.Parsers` is strictly configured to only parse `application/json` via `Phoenix.json_library()`.

**How to avoid:**
Add a custom parsing clause for the SNS webhook route that explicitly decodes `text/plain` as JSON, or use a custom `body_reader` that handles the SNS quirk before it reaches the standard parsers.

**Warning signs:**
Webhook logs show `200 OK` or `500 Server Error` but `conn.body_params` is `%{}`, despite the request containing a full JSON body.

**Phase to address:**
Phase addressing SES Webhook integration (v0.3 / DELIV-04).

---

### Pitfall 2: Consumed Raw Body before HMAC Verification (Resend/Svix)

**What goes wrong:**
Resend (via Svix) signature verification fails consistently, even with the correct secret key.

**Why it happens:**
Svix HMAC signatures require the exact, unparsed raw HTTP body. If `Plug.Parsers` consumes the body to parse it into an Elixir map, developers often try to reconstruct the JSON string (e.g., `Jason.encode!(params)`). This alters whitespace and key ordering, breaking the cryptographic hash.

**How to avoid:**
Ensure the existing `CachingBodyReader` (built in v0.1 for Postmark/SendGrid) is properly configured in the endpoint for the Resend webhook route, and validate the signature against `conn.assigns[:raw_body]`.

**Warning signs:**
Signature validation succeeds in unit tests (where mock bodies are perfectly formatted) but fails 100% of the time in production/staging.

**Phase to address:**
Phase addressing Resend Webhook integration (v0.3 / DELIV-04).

---

### Pitfall 3: SNS Subscription Confirmation Neglect (SES)

**What goes wrong:**
No delivery, bounce, or complaint events are ever received in production for SES, despite the AWS Console showing the SNS topic is configured.

**Why it happens:**
When you add an HTTPS endpoint to an SNS topic, AWS sends a `SubscriptionConfirmation` event. If your webhook endpoint doesn't actively parse this event and make a GET request to the provided `SubscribeURL`, the endpoint remains in "PendingConfirmation" status and receives zero traffic.

**How to avoid:**
Implement specific handling in the SES plug to detect `Type == "SubscriptionConfirmation"`, extract the `SubscribeURL`, and perform an HTTP GET to auto-confirm the subscription.

**Warning signs:**
The SNS topic console shows "Pending confirmation" for the HTTP endpoint.

**Phase to address:**
Phase addressing SES Webhook integration (v0.3 / DELIV-04).

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| **Timing Attacks in HMAC Verification** | Attackers can forge signatures by measuring response times character-by-character. | Never use `==` for signature comparison. Always use `Plug.Crypto.secure_compare/2`. (Applies to Mailgun, SES, Resend). |
| **Mailgun Replay Attacks** | Attackers intercept a valid webhook and resend it repeatedly to spam the system or manipulate suppression lists. | Mailgun provides a `timestamp` and `token`. Ensure `abs(current_time - timestamp) < 5_minutes` AND cache the `token` (e.g., in Redis or ETS) to reject seen tokens. |
| **Blindly Trusting `SigningCertURL` (SES)** | Attackers send fake webhooks with a valid signature generated from their own rogue certificate hosted on their servers. | Validate that the `SigningCertURL` matches `^https://sns\.[a-zA-Z0-9-]+\.amazonaws\.com/`. Reject all other domains before downloading the cert. |

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| **SES (SNS)** | Treating the `Message` field as a parsed map. | The SNS payload contains a `Message` key which is a *stringified JSON object*. You must `Jason.decode!` the `Message` string a second time to access the actual SES bounce/complaint data. |
| **Mailgun** | Assuming the payload is always JSON. | Depending on the webhook configuration in Mailgun, payloads might arrive as `multipart/form-data` instead of JSON. Ensure `Plug.Parsers` handles both, or explicitly configure the Mailgun dashboard for JSON. |
| **Resend (Svix)** | Using the raw secret key directly in the HMAC function. | Resend secrets typically start with `whsec_` followed by base64. You must strip the `whsec_` prefix and `Base.decode64!()` the remainder before using it as the HMAC key. |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| **Synchronous Cert Downloading (SES)** | Webhook times out and AWS retries, creating a backlog. | Cache the downloaded PEM certificate using ETS or persistent cache based on the `SigningCertURL`. Do not download it on every request. | Moderate scale (10+ events/sec) or when AWS cert servers are slow. |
| **Sync Database Updates in Hook** | High latency on the webhook endpoint causes providers to drop the connection and mark the webhook as failed. | Delegate webhook processing to a background worker (e.g., `Oban`) or use asynchronous processes after validating the signature. *Note: mailglass handles this via Ecto.Multi and appending to `mailglass_events` which is fast.* | Large burst traffic (newsletter sends). |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Mailgun:** Often missing replay attack prevention — verify token cache and timestamp checks.
- [ ] **SES:** Often missing auto-confirmation — verify `SubscriptionConfirmation` is handled automatically.
- [ ] **SES:** Often missing cert validation — verify `SigningCertURL` regex strictly limits to `amazonaws.com`.
- [ ] **Resend:** Often missing `whsec_` decoding — verify secret is base64 decoded before HMAC.

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| **Missed SNS Confirmation** | LOW | Manually click the confirmation link in AWS Console, or trigger a re-send of the confirmation event. |
| **Dropped Webhooks due to body_reader misconfig** | HIGH | Providers usually retry for up to 3 days. Deploy the fix quickly; providers will re-deliver the backlog. Once they stop retrying, data is permanently lost. |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| SES `text/plain` & `Message` parsing | v0.3 / DELIV-04 (SES Integration) | Sandbox tests simulate SNS JSON disguised as `text/plain`. |
| SES Subscription Auto-Confirm | v0.3 / DELIV-04 (SES Integration) | Unit test verifying GET request is made when `Type` is `SubscriptionConfirmation`. |
| SES `SigningCertURL` Validation | v0.3 / DELIV-04 (SES Integration) | Security unit test injecting rogue `malicious.com` cert URL. |
| Mailgun Replay Attack Prevention | v0.3 / DELIV-04 (Mailgun Integration) | Unit test reusing a token and verifying rejection. |
| Resend/Svix Raw Body Parsing | v0.3 / DELIV-04 (Resend Integration) | Integration test verifying the signature against a mocked raw payload. |
| Timing Attacks (`==` vs `secure_compare`) | v0.3 / DELIV-04 (All Providers) | Code review + custom Credo check ensuring `secure_compare/2` is used in webhook validators. |

## Sources

- Amazon SNS Webhook Documentation (Subscription confirmation & cert validation)
- Svix / Resend Webhook Documentation (Raw body HMAC & `whsec_` base64 rules)
- Mailgun Webhook Security Documentation (Replay attack timestamping)
- Elixir/Phoenix Community Gotchas (`text/plain` JSON & `secure_compare/2`)
- mailglass DNA (`CachingBodyReader` context)

---
*Pitfalls research for: Transactional Email Framework Webhooks*
*Researched: 2026-05-01*
