# Architecture Research

**Domain:** Transactional Email Webhooks (Mailgun, SES, Resend)
**Researched:** 2026-05-15
**Confidence:** HIGH

## Standard Architecture

### System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                 [Plug Pipeline / Router]                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │               Mailglass.Webhook.Plug                │    │
│  └────┬──────────────────────┬──────────────────────┬──┘    │
│       │                      │                      │       │
├───────┼──────────────────────┼──────────────────────┼───────┤
│       │               [Providers]                   │       │
│  ┌────▼────┐            ┌────▼────┐            ┌────▼────┐  │
│  │ Resend  │            │ Mailgun │            │   SES   │  │
│  └────┬────┘            └────┬────┘            └────┬────┘  │
│       │                      │                      │       │
├───────┼──────────────────────┼──────────────────────┼───────┤
│       │                      │                 ┌────▼────┐  │
│       │                      │                 │ SNS Cert│  │
│       │                      │                 │  Cache  │  │
│       │                      │                 └────┬────┘  │
│       │                      │                      │       │
├───────┴──────────────────────┴──────────────────────┴───────┤
│                     [Ingest Multi]                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │           Mailglass.Webhook.Ingest.multi            │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `Mailglass.Webhook.Plug` | Orchestrator. Dispatches to provider based on route config | Existing Plug. Add `:mailgun`, `:ses`, `:resend` to `@valid_providers`. |
| `Providers.Resend` | Verify Svix signatures, map Resend events | `Mailglass.Webhook.Provider` behaviour impl. Reads `svix-*` headers. |
| `Providers.Mailgun` | Verify Mailgun signatures, map Mailgun events | `Mailglass.Webhook.Provider` behaviour impl. Decodes JSON to get token/timestamp. |
| `Providers.SES` | Verify SNS RSA signatures, handle `SubscriptionConfirmation`, map SES events | `Mailglass.Webhook.Provider` behaviour impl. Decodes base64 certs. |
| `SNSCertificateCache` | Cache downloaded AWS X.509 certs to prevent network I/O blocking | `GenServer` backed by `:ets`. Downloads via OTP `:httpc`. |

## Recommended Project Structure

```text
lib/mailglass/webhook/
├── providers/
│   ├── mailgun.ex       # Implements Provider.verify!/3 and normalize/2
│   ├── resend.ex        # Implements Provider.verify!/3 and normalize/2
│   ├── ses.ex           # Implements Provider.verify!/3 and normalize/2
│   └── ses/
│       └── cert_cache.ex # Downloads and caches SNS X.509 certificates
```

### Structure Rationale

- **providers/:** Colocates the webhook implementations behind the `Mailglass.Webhook.Provider` behaviour.
- **providers/ses/:** SES is unique in requiring side-effecting network calls (SNS certificate downloading). The `cert_cache.ex` is sequestered here because no other provider requires an ETS cache.

## Architectural Patterns

### Pattern 1: Svix Header Verification (Resend)

**What:** Resend uses standard Svix webhook signing. The signature, timestamp, and message ID are passed in headers.
**When to use:** In `Providers.Resend.verify!/3`.
**Trade-offs:** Fast, zero-allocation verification. The body does not need to be decoded to verify.

**Example:**
```elixir
def verify!(raw_body, headers, config) do
  secret = config[:webhook_secret] || raise ConfigError
  timestamp = get_header(headers, "svix-timestamp")
  msg_id = get_header(headers, "svix-id")
  
  to_sign = "#{msg_id}.#{timestamp}.#{raw_body}"
  expected_sig = :crypto.mac(:hmac, :sha256, secret, to_sign) |> Base.encode64()
  
  # Compare against svix-signature header
end
```

### Pattern 2: JSON Payload Verification (Mailgun)

**What:** Mailgun places its verification tokens (`timestamp`, `token`, `signature`) inside the JSON body payload.
**When to use:** In `Providers.Mailgun.verify!/3`.
**Trade-offs:** Requires `Jason.decode!(raw_body)` inside the `verify!/3` function, meaning JSON decode runs BEFORE verification. If the payload is massive or malicious, it consumes memory before rejection. However, Plug limiters mitigate this.

**Example:**
```elixir
def verify!(raw_body, _headers, config) do
  secret = config[:signing_key] || raise ConfigError
  payload = Jason.decode!(raw_body)
  sig_data = payload["signature"]
  
  to_sign = "#{sig_data["timestamp"]}#{sig_data["token"]}"
  expected = :crypto.mac(:hmac, :sha256, secret, to_sign) |> Base.encode16(case: :lower)
  
  if Plug.Crypto.secure_compare(expected, sig_data["signature"]), do: :ok, else: raise SignatureError
end
```

### Pattern 3: SNS Certificate Verification & Auto-Confirm (SES)

**What:** AWS SES sends webhooks via SNS. Webhooks are signed with an asymmetric RSA key. The URL to the public certificate is provided in the payload. Also, when a webhook is first setup, SNS sends a `Type: SubscriptionConfirmation` which must be visited.
**When to use:** In `Providers.SES.verify!/3`.
**Trade-offs:** Highly complex. Network I/O inside `verify!/3` is a denial-of-service vector if not cached. `SubscriptionConfirmation` makes the webhook stateful.

## Data Flow

### Request Flow (SES)

```text
[AWS SNS Webhook]
    ↓ (JSON payload with Type, Message, Signature)
[Webhook.Plug] → [Providers.SES.verify!/3] 
    ↓                   ↓ (If cert not cached)
    │             [SNSCertCache (ETS + httpc)] ← [AWS S3]
    ↓                   ↓ (If Type == SubscriptionConfirmation)
    │             [:httpc.request (GET)] → [SubscribeURL]
    ↓
[Providers.SES.normalize/2]
    ↓ (If SubscriptionConfirmation, return [])
    ↓ (If Notification, parse inner Message JSON)
[%Event{}, ...] → [Ingest.multi] → [Database]
```

## Anti-Patterns

### Anti-Pattern 1: Network I/O in the Webhook Hot Path

**What people do:** Call `HTTPoison.get(SigningCertURL)` inside SES `verify!/3` synchronously on every request.
**Why it's wrong:** Exhausts the Phoenix connection pool during a webhook spike because each request pauses for external I/O.
**Do this instead:** Validate that `SigningCertURL` matches `^https://sns\.[a-z0-9\-]+\.amazonaws\.com/` and use a `GenServer` with an ETS cache to only download each certificate once.

### Anti-Pattern 2: Adding a Dependency for One Request

**What people do:** Add `:req` or `:httpoison` just to download the SNS certificate and hit the `SubscribeURL`.
**Why it's wrong:** Bloats the dependency tree for a library that strictly enforces minimalism.
**Do this instead:** Use OTP's built-in `:httpc` and `:public_key` modules.

## Integration Points

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `Plug` ↔ `Providers` | `@callback verify!/3` and `normalize/2` | `Mailglass.Webhook.Plug` must add `:resend`, `:mailgun`, `:ses` to its valid list. |
| `Providers.SES` ↔ `Cache` | Function call to `get_cert/1` | Must fall back gracefully. The cache acts as an isolation boundary. |

## Build Order

Based on the architectural complexity, the components should be built in this sequence:

1. **Phase A: Resend Provider.** Simplest implementation. HTTP header-based Svix HMAC verification.
2. **Phase B: Mailgun Provider.** Medium implementation. JSON body decoding required before verification, but no external network requests.
3. **Phase C: SES Provider & Cache.** Most complex. Requires `SNSCertCache`, regex validation of AWS domains, `:public_key` RSA signature validation, and `:httpc` handling for `SubscriptionConfirmation`. 

---
*Architecture research for: Transactional Email Webhooks (Mailgun, SES, Resend)*
*Researched: 2026-05-15*