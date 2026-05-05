# Phase 14: Resend Webhook Provider & Core Ingest - Research

**Researched:** 2026-04-28
**Domain:** Webhook Processing, Cryptography, Elixir Behaviours
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Svix Signature Implementation
- **D-01:** Implement native HMAC-SHA256 verification using `:crypto` to avoid a third-party dependency, maintain control over the `Plug.Conn` body reading, and raise domain-specific `Mailglass.SignatureError`s.

### Timestamp Drift Tolerance
- **D-02:** Make timestamp drift tolerance configurable via a keyword argument (falling back to application config), but secure-by-default to 300 seconds (5 minutes) to match the Svix/Stripe industry standard while providing an escape hatch for local testing and CI.

### Unmapped Events Handling
- **D-03:** Faithfully map Resend's intermediate events to specific taxonomy atoms (`email.sent` → `:sent`, `email.delivery_delayed` → `:deferred`) rather than swallowing them into `:unknown`. `:unknown` is strictly reserved for genuinely unrecognized event types.

### the agent's Discretion
- The exact name of the configuration keys and function signatures for the tolerance override.
- Internal test assertions setup for HMAC signatures (fixture generation).

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RESEND-01 | Webhook plug verifies Svix HMAC-SHA256 signature using `svix-id`, `svix-timestamp`, and raw request body. | Confirmed Svix algorithm uses `msg_id.timestamp.body` layout, verified via `:crypto.mac/4` and constant-time compare. |
| RESEND-02 | Webhook maps Resend events (delivered, bounced, complained) to `mailglass` normalized taxonomy. | Established provider normalization behaviour mapped directly to `Anymail` standard taxonomy. |
</phase_requirements>

## Summary

This phase implements Resend webhook integration using the existing `Mailglass.Webhook.Provider` behaviour. The system must verify cryptographic signatures using the Svix protocol (HMAC-SHA256) and correctly map Resend's event taxonomy into the internal `Anymail` standard used by Mailglass. 

Crucially, the raw body of the request must be cached during verification before being parsed by standard JSON decoders. The core deliverable is `Mailglass.Webhook.Providers.Resend` combined with tests to ensure correct taxonomy mapping and rejection of spoofed requests via timestamp or signature failure.

**Primary recommendation:** Implement `Mailglass.Webhook.Providers.Resend` strictly adhering to the `svix_id.svix_timestamp.raw_body` signature generation strategy, using `Plug.Crypto.secure_compare/2` to verify the resulting HMAC without exposing timing vulnerabilities.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Webhook Header Extraction | API / Backend | — | Identifying `svix-id`, `svix-timestamp`, `svix-signature` is HTTP-layer responsibility (Plug context). |
| Signature Cryptography | API / Backend | — | HMAC-SHA256 generation + constant-time comparison belong entirely in domain logic (Provider context). |
| Event Taxonomy Mapping | API / Backend | — | Converting `email.bounced` -> `:bounced` is an adapter-level translation responsibility. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:crypto` | Erlang OTP | HMAC Generation | Included in Erlang standard library; avoids pulling external Svix SDK or crypto dependencies. |
| `Plug.Crypto` | Core Dep | Verification | Provides `secure_compare/2` for timing-attack resistance. |

## Architecture Patterns

### System Architecture Diagram
```mermaid
graph TD
    A[Resend Webhook Request] --> B[Plug.Parsers (Raw Body Cache)]
    B --> C[Mailglass Webhook Plug]
    C --> D{Verify Signature}
    D -- Invalid --> E[Raise Mailglass.SignatureError]
    D -- Valid --> F[Mailglass.Webhook.Providers.Resend.normalize/2]
    F --> G[Map Resend Type to Taxonomy]
    G --> H[Return Event Structs]
```

### Pattern 1: Svix Signature Construction
**What:** Creating the string that Svix expects to be signed.
**When to use:** In `verify!/3`.
**Example:**
```elixir
# In Mailglass.Webhook.Providers.Resend
signed_content = "#{svix_id}.#{svix_timestamp}.#{raw_body}"
```

### Pattern 2: Multi-Version Signature Comparison
**What:** The `svix-signature` header can contain multiple space-separated signatures (e.g., `v1,sig1 v1,sig2`), allowing zero-downtime secret rotation.
**When to use:** Always, when comparing the generated hash.
**Example:**
```elixir
defp match_signature?(header_val, expected_sig) do
  header_val
  |> String.split(" ")
  |> Enum.any?(fn
    "v1," <> sig -> Plug.Crypto.secure_compare(sig, expected_sig)
    _ -> false
  end)
end
```

### Anti-Patterns to Avoid
- **Comparing strings using `==`:** Can lead to timing attacks. Always use `Plug.Crypto.secure_compare/2`.
- **Parsing the body before verification:** JSON parsers reorder keys and strip whitespace, destroying the signature's integrity. Must use the exact raw bytes.
- **Ignoring the timestamp:** Failing to verify `svix-timestamp` opens the system to replay attacks. Must check if `abs(now - timestamp) <= tolerance`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Constant Time Comparison | Custom bitwise check | `Plug.Crypto.secure_compare/2` | Already available via Plug dependency and thoroughly audited for timing attack vectors. |
| JSON Body Parsing | Custom parser logic | `Jason.decode!/1` | Once signature is verified, standard JSON parsing safely navigates the structured payload. |

## Runtime State Inventory
Step 2.5: SKIPPED (Greenfield phase for this specific provider, no runtime state to migrate)

## Common Pitfalls

### Pitfall 1: Base64 Decoding the Secret
**What goes wrong:** Attempting to hash using the raw string `"whsec_..."`.
**Why it happens:** Svix prefixes their secrets with `whsec_` and base64 encodes the remainder. The raw bytes must be extracted first.
**How to avoid:**
```elixir
"whsec_" <> encoded_secret = config_secret
{:ok, secret_bytes} = Base.decode64(encoded_secret)
```

### Pitfall 2: Replay Attacks via Stale Timestamps
**What goes wrong:** An attacker intercepts a valid webhook and resends it later. The signature is mathematically correct.
**Why it happens:** The timestamp is part of the signature but isn't checked against the current clock.
**How to avoid:** Fail verification if `System.system_time(:second) - String.to_integer(svix_timestamp) > tolerance` (default 300s).

### Pitfall 3: Dropping "provider_event_id" Identity
**What goes wrong:** Webhooks fail to insert idempotently.
**Why it happens:** Resend payloads embed their ID in the `id` JSON field. If this isn't mapped to the event's `metadata["provider_event_id"]`, the append-only uniqueness constraint fails to protect against duplicate processing.

## Code Examples

### Constructing and Verifying the Signature
```elixir
def verify!(raw_body, headers, config) do
  svix_id = fetch_header!(headers, "svix-id")
  svix_timestamp = fetch_header!(headers, "svix-timestamp")
  svix_signature = fetch_header!(headers, "svix-signature")
  
  verify_timestamp!(svix_timestamp, config)
  
  secret = fetch_secret!(config)
  signed_content = "#{svix_id}.#{svix_timestamp}.#{raw_body}"
  
  expected_sig = 
    :crypto.mac(:hmac, :sha256, secret, signed_content) 
    |> Base.encode64()

  unless match_signatures?(svix_signature, expected_sig) do
    raise Mailglass.SignatureError.new(:bad_signature, provider: :resend)
  end
  
  :ok
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Third-party Svix Library | Native `:crypto` evaluation | Project D-01 | Removes heavy transitive dependencies while retaining Svix compatibility natively. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Resend event types match `email.sent`, `email.delivery_delayed`, `email.delivered`, `email.bounced`, `email.complained`. | Constraints | Normalizer will miscategorize events into `:unknown`. Tests will fail if we misidentify Resend's real production strings. |

## Open Questions (RESOLVED)

1. **Test Fixtures** (RESOLVED)
   - What we know: We must generate our own test fixtures since we are avoiding the Svix library.
   - What's unclear: Best placement for the fixture generator (in `test/support` vs inline module).
   - Recommendation: Place the HMAC fixture generator in `test/support/mailglass/webhook_fixtures.ex` so it can be cleanly reused without bloating the test file itself.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `:crypto` | HMAC verification | ✓ | N/A | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/mailglass/webhook/providers/resend_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RESEND-01 | Valid signatures accepted | unit | `mix test test/mailglass/webhook/providers/resend_test.exs` | ❌ Wave 0 |
| RESEND-01 | Rejects stale timestamps | unit | `mix test test/mailglass/webhook/providers/resend_test.exs` | ❌ Wave 0 |
| RESEND-01 | Rejects invalid signature | unit | `mix test test/mailglass/webhook/providers/resend_test.exs` | ❌ Wave 0 |
| RESEND-02 | Correctly maps events | unit | `mix test test/mailglass/webhook/providers/resend_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/mailglass/webhook/providers/resend_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/mailglass/webhook/providers/resend_test.exs` — covers RESEND-01, RESEND-02

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | HMAC-SHA256 + Svix signature header pattern |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | strict header checking and payload parsing post-verification |
| V6 Cryptography | yes | `:crypto.mac/4` and `Plug.Crypto.secure_compare/2` |

### Known Threat Patterns for Elixir/Plug

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Signature Timing Attack | Information Disclosure | `Plug.Crypto.secure_compare/2` (constant-time verification) |
| Replay Attack | Spoofing | Enforcing 5-minute maximum tolerance on `svix-timestamp` |
| JSON parsing DoS | Denial of Service | Validating webhook signature strictly *before* executing JSON decoder |

## Sources

### Primary (HIGH confidence)
- Svix API Documentation - Webhook verification standard (`svix_id.svix_timestamp.raw_body`)
- `.planning/phases/14-resend-webhook-provider-core-ingest/14-CONTEXT.md` - Locked Decisions
- `lib/mailglass/webhook/providers/postmark.ex` - Elixir standard provider implementation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - `Plug.Crypto` and `:crypto` are robust built-ins.
- Architecture: HIGH - Dictated directly by Project Guidelines & `Provider` behaviour context.
- Pitfalls: HIGH - Svix timestamp and base64 issues are universally documented traps.

**Research date:** 2026-04-28
**Valid until:** 2026-05-28
