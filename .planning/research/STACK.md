# Technology Stack

**Project:** mailglass
**Researched:** 2024-05
**Mode:** Project Research — Stack for Mailgun, SES, and Resend webhooks.

## Recommended Stack

No new external dependencies should be added for this milestone. `mailglass`'s design philosophy mandates minimal dependency surface, and all three webhook providers can be securely verified using Erlang's standard library and Phoenix's existing `Plug` primitives.

### Core Framework & Built-ins
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Erlang `:crypto` | built-in | Mailgun & Resend HMAC | Both providers use HMAC-SHA256 for signatures. Erlang's native `:crypto.mac/4` is performant and standard. |
| Erlang `:public_key` | built-in | SES Signature Verification | AWS SNS uses X.509 certs and RSA-SHA1/SHA256. `:public_key` natively decodes PEM and verifies RSA signatures without bloat. |
| Erlang `:httpc` | built-in | SES Cert Fetching & Sub Confirmation | SES requires fetching a `.pem` certificate and calling a `SubscribeURL`. `:httpc` is built-in, avoiding forcing a specific HTTP client (`Req`/`Finch`) on the adopter. |
| `Plug.Crypto` | `~> 1.0` | Constant-time string comparison | Included with `plug`. `Plug.Crypto.secure_compare/2` is essential to prevent timing attacks when comparing computed HMACs against provided signatures. |
| ETS (Erlang Term Storage) | built-in | SES Cert Caching | AWS SNS certificates are long-lived. ETS can cache the PEM certificates by URL to prevent latency spikes and external HTTP calls on every incoming SES webhook. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| **SES Verification** | Erlang `:public_key` | `ex_aws_sns` | `ex_aws_sns` pulls in `ex_aws`, which requires global application config and forces a specific HTTP client (like `hackney`). This is too heavy and prescriptive just for verifying incoming webhooks in a library context. |
| **Resend Verification** | Erlang `:crypto` (Manual Svix) | `resend` / `svix` Hex packages | Resend uses Svix. The Svix signature verification is a simple HMAC-SHA256 string interpolation (`svix-id.svix-timestamp.raw_body`). Pulling in a full SDK for a single pure function violates mailglass's minimal-dependency DNA. |
| **HTTP Client** | Erlang `:httpc` | `req` / `finch` / `httpoison` | While `req` is standard for apps, adding an HTTP client dependency to a library *just* to fetch a PEM file and hit a `SubscribeURL` once per endpoint lifecycle is unnecessary weight. |

## Integration Points & Pre-requisites

### 1. Raw Request Body (Resend)
Resend (Svix) signatures are computed against the **exact raw request body**. Any JSON re-encoding (e.g. `Jason.encode!`) will fail due to whitespace/ordering differences. 
- **Existing Asset:** `mailglass` already implements `CachingBodyReader` (from v0.1 Postmark/SendGrid work). This MUST be used for Resend webhooks.

### 2. Canonical String Signing (AWS SES)
AWS SNS does *not* use the raw body for signatures. Instead, it signs a canonical string built from specific JSON fields (`Message`, `MessageId`, `Subject`, `Timestamp`, `TopicArn`, `Type`). 
- **Security Check:** The `SigningCertURL` MUST be validated to match `^https://sns\.[a-z0-9\-]+\.amazonaws\.com/.*\.pem$` to prevent SSRF vulnerabilities.

### 3. Timestamp Validation (Mailgun & Resend)
Both Mailgun (`timestamp`) and Resend (`svix-timestamp`) include timestamps in their payloads to prevent replay attacks.
- **Integration:** The webhook plugs must enforce a strict drift tolerance (e.g., rejecting events older than 5 minutes) using `System.system_time(:second)`.

## Installation

No additions required in `mix.exs`. 

```elixir
# No new dependencies needed!
```

## Sources

- **AWS SNS Signature Verification:** https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message.html (HIGH confidence)
- **Resend Webhook Signatures (Svix):** https://docs.svix.com/receiving/verifying-payloads/how (HIGH confidence)
- **Mailgun Webhook Security:** https://documentation.mailgun.com/en/latest/user_manual.html#webhooks (HIGH confidence)
