# Phase 16: SES Webhook Provider & SNS Cache - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

System securely ingests and normalizes AWS SES webhooks delivered through Amazon SNS. Scope includes parsing SNS `text/plain` JSON payloads, verifying SNS RSA signatures with cached X.509 certificates, automatically confirming SNS subscriptions, unwrapping SES events from SNS envelopes, and mapping SES events into mailglass's existing normalized webhook taxonomy.

</domain>

<decisions>
## Implementation Decisions

### SNS control-plane handling
- **D-01:** Handle SNS `SubscriptionConfirmation`, `Notification`, and `UnsubscribeConfirmation` on the same SES webhook endpoint. Do not introduce a separate route, controller, or setup UI just for SNS handshake traffic.
- **D-02:** Treat SNS control-plane messages as an explicit success path in the provider/plug flow, not as fake normalized `%Event{}` records and not as hidden side effects inside generic ingest. Control messages should short-circuit before `normalize/2` + ingest persistence.
- **D-03:** `SubscriptionConfirmation` must auto-confirm by default after successful SNS signature verification and trust-policy validation. Return HTTP `200` on success and persist no webhook event rows for the confirmation itself.
- **D-04:** `UnsubscribeConfirmation` should verify successfully, emit logging/telemetry, and return HTTP `200` as a no-op. Do not silently re-confirm subscriptions because that violates least surprise.

### AWS trust policy and network boundaries
- **D-05:** Verify SNS authenticity before any control-plane side effect. Signature verification applies to `Notification`, `SubscriptionConfirmation`, and `UnsubscribeConfirmation`, per AWS guidance.
- **D-06:** Validate `SigningCertURL` and `SubscribeURL` with a provider-local trust helper before any network I/O: `https` only, no userinfo, no fragment, exact SNS host derived from the signed `TopicArn` region/partition, and expected certificate/query shape. Do not use a broad `*.amazonaws.com` allowlist.
- **D-07:** After verification, do not treat `SubscribeURL` as an authority to follow. Confirm SNS subscriptions using a mailglass-constructed `ConfirmSubscription` request derived from the signed `TopicArn` and `Token`, with redirects disabled. `SubscribeURL` is validated for consistency, not used as the trusted source of truth.
- **D-08:** Support SNS partitions explicitly in trust validation and request construction: commercial AWS (`amazonaws.com`), GovCloud (`amazonaws.com`), and China (`amazonaws.com.cn`).
- **D-09:** URL trust-policy failures are authenticity failures, not adopter config errors. Malformed or forged SNS URLs must fail closed on the verification path.

### Certificate caching and hot-path behavior
- **D-10:** Keep the SES certificate fetch/cache layer ETS-backed and supervised, matching the existing OTP style already used for Mailgun replay caching and suppression ETS ownership.
- **D-11:** Certificate fetches should use native Erlang/OTP facilities (`:httpc`, `:public_key`, ETS) rather than adding an AWS SDK or third-party HTTP client dependency. mailglass should stay batteries-included without forcing adopter dependency choices.
- **D-12:** Cache X.509 certificates by trusted cert URL with expiration-aware refresh behavior so normal webhook verification does not incur repeated network calls. Network I/O is allowed only at the SES boundary and should stay tightly scoped.

### SES normalization breadth
- **D-13:** Use a broad but conservative normalized core. Support both classic SNS feedback payloads (`notificationType`) and SES event-publishing payloads (`eventType`) while mapping only clear SES semantics into the existing mailglass/Anymail taxonomy.
- **D-14:** Normalize clear SES events into existing atoms only: `:sent`, `:delivered`, `:bounced`, `:complained`, `:rejected`, `:opened`, `:clicked`, `:failed`, and `:deferred`. Do not create SES-specific public event atoms or public structs.
- **D-15:** Preserve AWS-specific nuance in metadata with string keys rather than widening the public normalized contract. This includes SNS envelope identifiers, SES subtype/reason fields, and any raw delivery/bounce/complaint detail needed for audit/debugging.

### Recipient fan-out and suppression safety
- **D-16:** When SES supplies recipient arrays, fan out one normalized `%Event{}` per recipient rather than emitting one ledger event for a whole recipient batch. Derive stable per-recipient `provider_event_id` values from the SNS message id plus recipient identity or index so webhook idempotency stays durable.
- **D-17:** Suppression-driving mappings must stay conservative. Terminal hard-bounce semantics map to `%Event{type: :bounced, reject_reason: :bounced}`. Complaint semantics map to `:complained`. Transient and delay-style outcomes map to `:deferred`, not `:bounced`. Policy/account/suppression-list style SES outcomes map to `:rejected` with provider detail preserved.
- **D-18:** Document duplicate-source behavior explicitly. SES feedback notifications and SES event publishing can overlap on bounce/complaint/delivery semantics; adopters should not point overlapping sources at the same endpoint/topic unless they intentionally want duplicate upstream signals.

### Developer-experience defaults
- **D-19:** Planning and implementation should prefer agent-led research, tradeoff synthesis, and recommended defaults by default for provider/webhook phases. Escalate decisions back to the user only when they are likely to materially affect public API, project shape, long-term maintainer burden, or a product-level behavior the user is likely to care about directly.

### the agent's Discretion
- Exact callback/tuple shape used to represent the SES control-plane success path, as long as it is explicit in the provider/plug boundary and does not masquerade as a normal normalized event.
- Exact ETS table ownership module names and cache invalidation details for the SNS certificate cache.
- Exact metadata field names for preserved SES/SNS detail beyond the required `"provider"`, `"provider_event_id"`, `"record_type"`, and `"message_id"` keys.
- Exact timeout values, retry posture, and telemetry field names for certificate fetch and subscription confirmation, as long as they remain tight, explicit, and fail closed.

</decisions>

<specifics>
## Specific Ideas

- The SES provider should feel like Mailgun and Resend in public shape: small provider module, explicit verification path, native crypto/OTP primitives, and predictable route/config behavior.
- Hide SNS ceremony from adopters. Users should experience SES support as "mount the webhook, configure the topic, and it works," not "read logs and manually click confirmation URLs."
- Do the boring secure thing by default. Narrow trust boundaries, explicit verification, and no magic re-subscribe behavior are more important than copying AWS convenience flows literally.
- Future GSD discussion/planning passes should bias toward researching options, recommending the coherent default, and only surfacing a user choice when the decision is truly high-impact.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Internal code and project contracts
- `.planning/PROJECT.md` — Project-level design DNA: minimal dependencies, provider-local verification, Anymail taxonomy, and maintainer ergonomics.
- `.planning/ROADMAP.md` — Phase 16 scope, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — Locked SES requirement IDs `SES-01..SES-05`.
- `.planning/STATE.md` — Carries forward `D-23`: SES certificate fetching should use ETS caching behind a supervised process.
- `.planning/phases/14-resend-webhook-provider-core-ingest/14-CONTEXT.md` — Recent provider-extension baseline: native verification, JSONB-safe metadata, and provider behavior expectations.
- `.planning/phases/15-mailgun-webhook-provider/15-CONTEXT.md` — Recent replay/cache/provider-route decisions and the explicit preference for agent-led recommendations.
- `lib/mailglass/webhook/provider.ex` — Current provider contract and verify/normalize split.
- `lib/mailglass/webhook/plug.ex` — Response matrix and the place where SES control-plane short-circuit behavior must remain explicit.
- `lib/mailglass/webhook/router.ex` — Route surface contract and explicit provider mounting style.
- `lib/mailglass/webhook/webhook_event.ex` — Current webhook idempotency/audit schema and `provider_event_id` expectations.
- `lib/mailglass/webhook/providers/mailgun.ex` — Current example of broader conservative provider normalization and replay-aware verification.
- `lib/mailglass/webhook/providers/resend.ex` — Current example of native crypto verification and small provider style.
- `lib/mailglass/application.ex` — Existing supervision tree patterns that the SES certificate cache should match.
- `lib/mailglass/suppression/auto_suppress.ex` — Current suppression semantics that SES bounce/complaint mappings must not accidentally violate.
- `guides/webhooks.md` — Public adopter contract for webhook mounting and provider configuration.

### AWS SNS / SES primary references
- `https://docs.aws.amazon.com/sns/latest/dg/sns-message-and-json-formats.html` — SNS message types and HTTP(S) envelope expectations.
- `https://docs.aws.amazon.com/sns/latest/dg/http-notification-json.html` — SNS `Notification` body shape, `Content-Type: text/plain`, and signature fields.
- `https://docs.aws.amazon.com/sns/latest/dg/http-subscription-confirmation-json.html` — SNS `SubscriptionConfirmation` body shape and `Token`/`SubscribeURL` fields.
- `https://docs.aws.amazon.com/sns/latest/dg/http-unsubscribe-confirmation-json.html` — SNS `UnsubscribeConfirmation` body shape and recovery semantics.
- `https://docs.aws.amazon.com/sns/latest/dg/SendMessageToHttp.prepare.html` — AWS handling guidance for `x-amz-sns-message-type`, parsing `text/plain` JSON, confirmation flow, and response timing expectations.
- `https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message.html` — Signature-verification best practices and trust-chain guidance.
- `https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message-verify-message-signature.html` — Exact signing fields/order, trusted-domain guidance, and signature-version behavior.
- `https://docs.aws.amazon.com/sns/latest/api/API_ConfirmSubscription.html` — `ConfirmSubscription` API shape used for the safest auto-confirm path.
- `https://docs.aws.amazon.com/ses/latest/dg/notification-contents.html` — Classic SES feedback notification schema and bounce/complaint/delivery semantics.
- `https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-contents.html` — SES event-publishing schema and supported `eventType` breadth.
- `https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-examples.html` — Canonical SES event examples for fixtures and mapper tests.

### Adjacent ecosystem references
- `https://anymail.dev/en/latest/esps/amazon_ses/` — Popular mature library showing auto-confirm-by-default DX and broad normalized SES tracking/event support.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Webhook.Provider` already gives the right seam for SES-specific verification and normalization logic without leaking `%Plug.Conn{}` into provider code.
- `Mailglass.Webhook.Plug` already owns provider dispatch and response shaping; it is the right place for an explicit SES control-plane short-circuit branch.
- `Mailglass.Webhook.WebhookEvent` already provides durable idempotency and audit storage keyed by `provider` + `provider_event_id`.
- `Mailglass.Webhook.CachingBodyReader` already establishes the raw-body-preservation pattern used by recent webhook providers.
- `Mailglass.Webhook.Providers.MailgunReplayCache.*` provides the closest in-repo pattern for a supervised ETS-backed transient cache.
- `Mailglass.Clock` should be used anywhere certificate expiry or timeout-sensitive logic needs testable time behavior.

### Established Patterns
- Provider modules are expected to stay small, native, and dependency-light.
- Verification and normalization are deliberately split; control-plane SES behavior should preserve that explicitness rather than smearing network side effects across hidden seams.
- Event metadata uses string keys for JSONB round-trip safety.
- Route surfaces are explicit and stable; new provider support should feel additive, not magical.
- Auto-suppression logic already assumes bounce/complaint semantics have been normalized conservatively before projection.

### Integration Points
- `Mailglass.Webhook.Plug` will need an SES-specific handled-control outcome that returns `200` without calling ingest.
- `Mailglass.Application` will need to supervise the SNS certificate cache alongside other optional runtime support processes.
- SES provider tests should mirror recent Mailgun/Resend fixture-driven suites while adding certificate/trust-policy/confirmation-path coverage.
- Public docs and installer/config snippets will need SES-specific setup guidance, including explicit provider opt-in if router defaults remain unchanged.

</code_context>

<deferred>
## Deferred Ideas

- Rich SES-specific public event projections or structs — out of scope; preserve nuance in metadata instead.
- Distributed/shared certificate caches across nodes — local ETS cache is sufficient for this phase unless scale evidence later proves otherwise.
- Admin UI or operator console for manual SNS confirmation recovery — out of scope; default path should be automatic.
- Global GSD preference plumbing beyond this phase context — captured here for downstream agents now, but broader workflow-level persistence can be handled separately if needed.

</deferred>

---

*Phase: 16-ses-webhook-provider-sns-cache*
*Context gathered: 2026-04-28*
