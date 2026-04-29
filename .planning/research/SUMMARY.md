# Project Research Summary

**Project:** mailglass
**Domain:** Transactional Email Framework Webhooks (Mailgun, SES, Resend)
**Researched:** 2024-05
**Confidence:** HIGH

## Executive Summary

`mailglass` is a transactional email framework in Elixir, and this project introduces support for securely ingesting webhooks from Mailgun, Amazon SES, and Resend. Expert implementations in the Elixir ecosystem prioritize security and an ultra-lightweight footprint. True to the library's DNA, this integration will rely entirely on built-in Erlang modules (`:crypto`, `:public_key`, `:httpc`) and Phoenix standard libraries (`Plug`), ensuring robust signature validation without introducing new external dependencies like `req`, `httpoison`, or heavy vendor SDKs.

The recommended approach delegates provider-specific logic to individual provider modules orchestrated by a central `Mailglass.Webhook.Plug`. Mailgun and Resend signatures utilize fast HMAC-SHA256 calculations, while SES demands more complex X.509 certificate parsing and RSA verification over a custom SNS payload wrapper. An essential component of this architecture is an ETS-backed cache to handle the asynchronous network fetching of SES certificates without blocking the plug pipeline.

Key risks center around provider-specific idiosyncrasies that break default Phoenix configurations. Foremost is Resend's strict reliance on the unparsed raw HTTP body for Svix signature verification, which will silently fail if standard `Plug.Parsers` consumes the stream too early. Similarly, SES sends JSON payloads masked as `text/plain` and requires an out-of-band `SubscriptionConfirmation` HTTP GET request. Mitigation strategies include utilizing a custom `CachingBodyReader`, aggressively caching external certificates, and incorporating specialized parsing clauses for SNS quirks.

## Key Findings

### Recommended Stack

No new external dependencies should be added. The system relies entirely on standard Erlang built-ins and existing Phoenix capabilities to handle cryptography and network requests securely.

**Core technologies:**
- **Erlang `:crypto`**: Mailgun & Resend HMAC — Built-in, performant implementation for standard HMAC-SHA256 signatures.
- **Erlang `:public_key`**: SES Signature Verification — Natively decodes PEM certificates and verifies RSA signatures without external bloat.
- **Erlang `:httpc`**: SES Cert Fetching & Sub Confirmation — Avoids forcing a specific HTTP client (`Req` or `Finch`) on the adopter.
- **`Plug.Crypto`**: Constant-time comparison — `secure_compare/2` is critical for preventing timing attacks during signature validation.
- **Erlang ETS**: SES Cert Caching — Provides fast, in-memory caching of downloaded SNS certificates to prevent external API calls on every request.

### Expected Features

**Must have (table stakes):**
- **Mailgun Signature Verification** — Validates incoming HMAC-SHA256 payloads.
- **Resend/Svix Signature Verification** — Validates Svix-standard headers against the unmodified raw request body.
- **SES SNS Signature Verification** — Fetches and parses AWS certificates for RSA validation.
- **SES SNS Subscription Auto-Confirmation** — Automatically triggers HTTP GET to `SubscribeURL` upon topic connection.
- **SES Envelope Unwrapping** — Extracts the actual SES event from the nested stringified JSON within the SNS `Message` envelope.

**Should have (competitive):**
- **Raw Body Caching Plug** — A `CachingBodyReader` to ensure Svix validation succeeds while maintaining standard JSON parameters for subsequent routes.
- **Mailgun Replay Attack Prevention** — Timestamp drift validation (`< 5 mins`) to reject old payloads.
- **Seamless SNS Abstraction** — Normalizers that completely hide the underlying AWS SNS complexities from the end user.

**Defer (v2+):**
- **Full Stateful Replay Attack Prevention** — Persisting tokens to a database/Redis to track uniquely consumed events can be deferred; simple timestamp staleness is sufficient for MVP.

### Architecture Approach

The architecture relies on a central Plug router delegating to behavior-driven provider implementations, with isolated network dependencies restricted solely to the SES pipeline.

**Major components:**
1. **`Mailglass.Webhook.Plug`** — Orchestrator. Dispatches the incoming connection to the correct provider based on route configuration and extracts necessary headers.
2. **`Providers.[Resend/Mailgun/SES]`** — Implements `Mailglass.Webhook.Provider` behavior, enforcing `verify!/3` and `normalize/2` standards per vendor.
3. **`SNSCertificateCache`** — A `GenServer` backed by `:ets` that safely downloads (via `:httpc`) and caches AWS X.509 certificates to isolate network I/O from the hot path.

### Critical Pitfalls

1. **Consumed Raw Body before HMAC Verification (Resend)** — Avoid by using a `CachingBodyReader`. `Plug.Parsers` consumes the body to parse JSON, altering formatting and destroying the cryptographic hash required for Svix.
2. **SNS Webhook `text/plain` Content-Type Mismatch (SES)** — Avoid by adding a specific parsing handler. SES sends valid JSON but flags it as `text/plain`, causing standard Phoenix parsers to ignore the body entirely.
3. **SNS Subscription Confirmation Neglect (SES)** — Avoid by explicitly checking for `Type: SubscriptionConfirmation` and auto-fetching the `SubscribeURL`. Ignoring this traps the endpoint in "PendingConfirmation" status.

## Implications for Roadmap

Based on research, suggested phase structure focusing on incremental complexity:

### Phase 1: Resend Provider Integration
**Rationale:** Simplest implementation utilizing standard HTTP headers and HMAC-SHA256. Proves out the `Mailglass.Webhook.Provider` behavior and `Plug` orchestration.
**Delivers:** Resend Svix signature validation and event normalization.
**Addresses:** Resend/Svix Signature Verification, Raw Body Caching Plug.
**Avoids:** Consumed Raw Body before HMAC Verification pitfall.

### Phase 2: Mailgun Provider Integration
**Rationale:** Medium complexity. Still isolated to HMAC-SHA256, but requires JSON decoding *before* signature validation to extract the signature tokens, introducing payload processing into the security layer.
**Delivers:** Mailgun signature validation and event normalization.
**Uses:** `Erlang :crypto`, `Plug.Crypto`.
**Implements:** `Providers.Mailgun`, Mailgun Replay Attack Prevention (timestamp validation).

### Phase 3: SES Provider & SNS Cache
**Rationale:** Most complex integration. Introduces async external network I/O, public key cryptography, ETS caching, and stateful setup handshakes. Built last to ensure core webhook abstractions are solid.
**Delivers:** Complete SES auto-confirmation, SNS unwrapping, and RSA verification.
**Uses:** `Erlang :public_key`, `Erlang :httpc`, `ETS`.
**Implements:** `Providers.SES`, `SNSCertificateCache`.
**Avoids:** SNS Webhook `text/plain` Content-Type Mismatch, SNS Subscription Confirmation Neglect.

### Phase Ordering Rationale

- **Dependency Flow:** Build from zero-state/header-only (Resend) to payload-dependent (Mailgun) to stateful-network-dependent (SES).
- **Architecture Validation:** Phase 1 cements the base `Plug` router and Provider behavior patterns before introducing the complex GenServer ETS caching layer needed in Phase 3.

### Research Flags

Phases likely needing deeper research during planning:
- **None.** All phases have standard, well-documented implementation patterns in the Elixir ecosystem.

Phases with standard patterns (skip research-phase):
- **Phase 1-3:** Well-documented algorithms and security specifications across all three providers.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Native Erlang `:crypto`, `:public_key`, and `Plug.Crypto` are the indisputable standards for this use case. |
| Features | HIGH | Vendor docs clearly outline required security primitives (HMAC vs RSA) and connection steps. |
| Architecture | HIGH | The Provider behavior + caching GenServer is the proven pattern for Elixir API integrations. |
| Pitfalls | HIGH | Common issues like Resend's raw body parsing and SES `text/plain` bugs are widely recognized in Elixir forums. |

**Overall confidence:** HIGH

### Gaps to Address

- **Verification Sandbox:** How to effectively mock the SES `SubscriptionConfirmation` lifecycle and RSA signatures in unit testing without hitting AWS during CI runs.

## Sources

### Primary (HIGH confidence)
- Mailgun Webhook Security Docs — HMAC-SHA256 standardization & timestamp checks.
- Resend Webhook Docs — Svix standard, raw body requirements, `whsec_` prefix format.
- Amazon SES / SNS Webhook Documentation — Signature verification, Subscription confirmation, and x509 cert validation rules.
- Elixir/Phoenix ecosystem standards — Standard practices for lightweight library construction, avoiding HTTP clients like `req` for pure libraries.

---
*Research completed: 2024-05*
*Ready for roadmap: yes*
