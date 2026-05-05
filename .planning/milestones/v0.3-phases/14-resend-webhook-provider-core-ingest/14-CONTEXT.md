# Phase 14: Resend Webhook Provider & Core Ingest - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

System securely ingests and normalizes Resend webhooks through a new provider behavior.

</domain>

<decisions>
## Implementation Decisions

### Svix Signature Implementation
- **D-01:** Implement native HMAC-SHA256 verification using `:crypto` to avoid a third-party dependency, maintain control over the `Plug.Conn` body reading, and raise domain-specific `Mailglass.SignatureError`s.

### Timestamp Drift Tolerance
- **D-02:** Make timestamp drift tolerance configurable via a keyword argument (falling back to application config), but secure-by-default to 300 seconds (5 minutes) to match the Svix/Stripe industry standard while providing an escape hatch for local testing and CI.

### Unmapped Events Handling
- **D-03:** Faithfully map Resend's intermediate events to specific taxonomy atoms (`email.sent` → `:sent`, `email.delivery_delayed` → `:deferred`) rather than swallowing them into `:unknown`. `:unknown` is strictly reserved for genuinely unrecognized event types.

### Claude's Discretion
- The exact name of the configuration keys and function signatures for the tolerance override.
- Internal test assertions setup for HMAC signatures (fixture generation).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Implementation Reference
- `lib/mailglass/webhook/provider.ex` — Webhook provider behaviour.
- `lib/mailglass/webhook/providers/postmark.ex` — Example of existing provider verifying signatures and mapping events.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Plug.Crypto.secure_compare/2` is available and must be used for timing-attack-safe comparison of HMAC signatures (already used in Postmark provider).

### Established Patterns
- Provider behavior uses `verify!(raw_body, headers, config)` and `normalize(raw_body, headers)` without pulling `%Plug.Conn{}` into the verify path.
- Provider identifier mapping sets `"provider" => "resend"`, `"provider_event_id" => ...`, `"record_type" => ...`, and `"message_id" => ...` inside the Event's `metadata` using STRING keys (for JSONB roundtrip safety).
</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 14-resend-webhook-provider-core-ingest*
*Context gathered: 2026-04-28*
