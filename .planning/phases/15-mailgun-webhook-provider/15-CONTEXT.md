# Phase 15: Mailgun Webhook Provider - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

System securely ingests and normalizes Mailgun webhooks while preventing replay attacks. Scope is limited to Mailgun verification, replay handling, route/config integration, and normalized event mapping through the existing webhook ingest pipeline.

</domain>

<decisions>
## Implementation Decisions

### Signature and Replay Strategy
- **D-01:** Implement Mailgun verification natively with `:crypto` HMAC-SHA256 over `timestamp <> token`, using the signing fields embedded in the JSON body. Do not add a third-party Mailgun webhook dependency.
- **D-02:** Replay protection should use a supervised local ETS cache as the primary guard inside `verify!/3`, with Mailgun `token` as the replay key. This matches mailglass's existing OTP/ETS style and keeps replay rejection off the DB hot path.
- **D-03:** Mailgun `token` should also become the durable `provider_event_id` written into `mailglass_webhook_events`, so the existing UNIQUE `(provider, provider_event_id)` constraint remains a secondary backstop for restarts and cross-node duplicates.
- **D-04:** Timestamp validation is required, but it is a sanity/expiry guard rather than the primary replay defense. Do not transplant Stripe/Svix-style aggressive 300-second recency as the default because Mailgun does not document the same retry-signing semantics. Default to a configurable, generous expiration window that is compatible with Mailgun retries, while keeping a strict future-skew check.
- **D-05:** Detected Mailgun replay must NOT be modeled as a normal `SignatureError` that becomes HTTP `401`. Mailgun retries non-`200`/non-`406` responses for hours, so replay handling must short-circuit with a non-retrying outcome. Prefer `200` as an idempotent no-op, aligned with the existing duplicate-ingest behavior.

### Route and Config Surface
- **D-06:** Keep `mailglass_webhook_routes "/webhooks"` behavior stable. Mailgun support should be opt-in via an explicit `providers: [...]` list rather than silently expanding the zero-arg default mount set.
- **D-07:** Installer/docs should do the thinking for adopters: when Mailgun is selected, emit the explicit provider list and config snippet, rather than asking adopters to infer the required router changes themselves.

### Event Mapping Breadth
- **D-08:** Use a broader but conservative normalized core, not a minimal three-event mapping. Mailgun should contribute stable lifecycle signal where semantics are clear, while preserving raw provider fields for anything ambiguous.
- **D-09:** Map stable Mailgun lifecycle states into the existing normalized taxonomy:
  - `accepted` -> `:queued`
  - `delivered` -> `:delivered`
  - `failed` with `severity: "temporary"` -> `:deferred`
  - `failed` with `severity: "permanent"` and recipient/MTA terminal failures -> `:bounced`
  - `failed` with `severity: "permanent"` and suppression/policy-style reasons -> `:rejected`
  - `opened` -> `:opened`
  - `clicked` -> `:clicked`
  - `complained` -> `:complained`
  - `unsubscribed` -> `:unsubscribed`
- **D-10:** Do not overfit every Mailgun nuance into a fake cross-provider abstraction. When reason mapping is genuinely ambiguous, preserve the raw Mailgun reason/details in metadata and fall back conservatively instead of inventing precise normalized meanings.

### Developer Experience Defaults
- **D-11:** Downstream agents should bias toward agent-led research and recommended defaults, not bounce gray-area analysis back to the user unless a decision is likely to materially affect public API, product shape, or long-term project direction.

### the agent's Discretion
- Exact module names and supervision shape for the Mailgun replay cache.
- Exact config key names for signing key and replay/timestamp tolerances.
- Exact internal representation of ambiguous Mailgun failure reasons in metadata.
- Final choice of replay short-circuit plumbing (`:ok` sentinel vs dedicated replay outcome type) so long as it avoids retry amplification and preserves clear telemetry/logging.

</decisions>

<specifics>
## Specific Ideas

- Favor the existing mailglass design language: small provider modules, native crypto, low dependency count, explicit config, and predictable Phoenix router behavior.
- Bias for principle of least surprise over magic. New provider support should feel additive for teams who opt in, not behaviorally different for teams who do nothing.
- User preference for this phase and similar future gray areas: have GSD do the research, synthesize tradeoffs, and recommend the default path unless a decision is truly high impact.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Internal code and project contracts
- `lib/mailglass/webhook/provider.ex` — Provider contract; verify/normalize split and Conn-free design.
- `lib/mailglass/webhook/plug.ex` — Current response matrix and failure handling; replay handling must not accidentally flow through the 401 signature-failure path.
- `lib/mailglass/webhook/router.ex` — Current default provider mount behavior; Mailgun should extend via explicit opt-in.
- `lib/mailglass/webhook/webhook_event.ex` — Existing UNIQUE `(provider, provider_event_id)` backstop and webhook audit model.
- `lib/mailglass/webhook/providers/postmark.ex` — Existing single-event provider pattern and metadata conventions.
- `lib/mailglass/webhook/providers/sendgrid.ex` — Existing richer lifecycle mapping and timestamp-skew pattern.
- `lib/mailglass/webhook/providers/resend.ex` — Existing recent provider extension pattern and native HMAC verification style.
- `guides/webhooks.md` — Public adopter contract for webhook mounting and configuration.

### External provider and ecosystem references
- `https://documentation.mailgun.com/docs/mailgun/user-manual/webhooks/securing-webhooks` — Mailgun signature format, token replay guidance, and timestamp caveats.
- `https://documentation.mailgun.com/docs/mailgun/user-manual/webhooks/webhook-payloads` — Current Mailgun webhook event payloads and lifecycle fields.
- `https://documentation.mailgun.com/docs/mailgun/user-manual/webhooks/webhook-retries` — Retry behavior; crucial for replay-response semantics.
- `https://anymail.dev/en/v14.0/esps/mailgun/` — Mature Mailgun normalization/reference implementation; notably uses Mailgun webhook token as normalized event id.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Webhook.Provider` already isolates provider-specific auth and normalization cleanly from `Plug.Conn`.
- `Mailglass.Webhook.WebhookEvent` already provides a durable uniqueness and audit backstop keyed by `provider_event_id`.
- Existing ETS ownership patterns in `lib/mailglass/suppression_store/ets/` provide a house style for supervised local caches.
- `Mailglass.Clock` exists and should be used for any timestamp checks that need test-time control.

### Established Patterns
- Provider metadata is stored with STRING keys for JSONB roundtrip safety.
- Existing providers use native crypto and avoid unnecessary external dependencies.
- The webhook router and docs currently treat public route surfaces as explicit and stable; changing the default zero-arg mount set would be a surprising API shift.
- Existing duplicate ingest converges to `200`, so replay handling should feel consistent with mailglass's idempotent webhook posture.

### Integration Points
- `Mailglass.Webhook.Plug` will need a replay-aware success path that does not route through the generic `SignatureError` -> `401` rescue branch.
- `Mailglass.Webhook.Router` will need `:mailgun` validation support without changing the zero-arg default provider list.
- Provider config/documentation will need a Mailgun signing-key subtree and clear opt-in examples.
- Tests should mirror existing provider suites plus replay-specific coverage for ETS behavior, timestamp expiry, and non-retrying duplicate responses.

</code_context>

<deferred>
## Deferred Ideas

- Cluster-wide replay rejection before ingest (for example via Redis or another distributed cache) — out of scope for Phase 15 unless needed to satisfy a later milestone.
- Additional helper APIs for "all configured providers" route mounting — avoid new macro surface unless later UX evidence justifies it.
- Provider-specific analytics or richer Mailgun-only event projections beyond the stable normalized core.

</deferred>

---

*Phase: 15-mailgun-webhook-provider*
*Context gathered: 2026-04-28*
