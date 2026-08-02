# Feature Research

**Domain:** Outbound first-adopter correctness for a Phoenix transactional-email framework
**Project:** mailglass v2.4
**Researched:** 2026-08-02
**Confidence:** HIGH

## Feature Landscape

This is a launch-contract repair milestone, not a product-surface expansion. The adopter must be able to use the documented one-brand, one-recipient path without knowing Mailglass internals: construct a message, choose sync or durable async, accept an unsubscribe, and verify production readiness. A result is only complete when it is observable from a generated Phoenix/Postgres host without test-only configuration.

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes / testable acceptance expectation |
|---------|--------------|------------|-----------------------------------------|
| **Zero-config single-tenant first send** | A single-brand app should not need a process-local tenant stamp merely to send its first email. | MEDIUM | With no custom tenancy module and no `put_current/1`, sync and async sends persist/use tenant `"default"`; verified feedback and unsubscribe resolve to that same tenant. A configured custom resolver remains fail-closed when its context is absent or invalid. |
| **Explicit body and renderer contract** | An adopter must know whether HTML, generated plaintext, and text-only mail will be sent before depending on the guide. | MEDIUM | `text_body/2` produces text-only mail without requiring HTML; explicit plaintext wins over generated text; HTML-only behavior follows the documented renderer setting; published CSS-inliner choices have the same observable result in both modes. Unsupported renderer input fails before any send/job is created. |
| **Exactly one envelope recipient per delivery** | Transactional mail must not leak recipients or silently turn one logical send into multi-recipient semantics. | HIGH | Reject or split unsupported recipient shapes before persistence; every successful `deliver/2` or `deliver_later/2` has one envelope recipient, one delivery row, one suppression decision, and one provider dispatch. The v2.4 contract is one recipient, not a `deliver_many/2` redesign. |
| **Sync/async wire fidelity** | Choosing `deliver_later/2` must change timing/durability, not message meaning. | HIGH | Given a supported one-recipient message, sync and durable async deliver equivalent provider-ready From/To/subject/headers/HTML/text/attachments and the persisted selected adapter reference. Render once before the async boundary; do not serialize executable HEEx/functions or raw adapter secrets. |
| **Fail-closed durable async enqueueing** | Production callers reasonably interpret a queued result as recoverable durable work. | HIGH | `{:ok, delivery}` with `:queued` means the delivery record, queued event, complete internal payload, and Oban job commit atomically. If Oban is unavailable/miswired or payload persistence/enqueue fails, return an error and create no sendable partial work. Task-supervisor dispatch is expressly non-production/non-durable. |
| **Honest retry and terminal outcome semantics** | Operators must not mistake permanent rejects or post-dispatch ambiguity for safe automatic retries. | MEDIUM | Only genuinely retryable dispatch failures are returned to Oban; rendering, serialization, suppression, configuration, and malformed payload failures settle as non-retryable with an honest final delivery/error record. Retries retain the already selected route and never claim exactly-once provider acceptance. |
| **Built-in one-click suppression convergence** | RFC 8058 one-click must actually stop subsequent eligible sends, including POST replay. | HIGH | A valid POST returns empty `200`; first click atomically writes the originating address+stream suppression and durable unsubscribe event; replays return the same `200` without duplicate rows/events. A later same-stream send is preflight-blocked; transactional mail is not blocked by an operational/bulk stream unsubscribe. |
| **Bounded private queued payload lifecycle** | Queued content can contain PII or sensitive business text, but async delivery needs it until dispatch succeeds. | HIGH | Store a private, internal delivery artifact separate from adopter `Delivery.metadata`; retain only what dispatch/retry needs; scrub it transactionally after successful dispatch; expire/scrub terminal undeliverable payloads on a documented bounded schedule. It is not operator-visible sent-mail retention. |
| **Production preflight and clean-host release proof** | Copy-paste docs are not sufficient evidence for a framework that owns migrations, queueing, webhooks, and compliance. | HIGH | A generated Phoenix/Postgres host installs published packages, runs migrations, configures Oban and real runtime settings, performs sync and async send, ingests feedback, proves one-click enforcement, mounts production operations, and runs `mail.doctor`/`mailglass.doctor`. This path blocks release when snippets, migrations, queue names, or contracts drift. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **One-recipient parity as a documented compatibility promise** | Most email abstractions make async behavior an implementation detail; Mailglass can give Phoenix adopters a concrete, testable equivalence guarantee. | HIGH | Differentiate through correctness and evidence, not more provider features. The guarantee applies only to the supported single-recipient contract. |
| **Privacy-bounded queued artifact rather than casual job serialization** | Lets teams use durable delivery without treating Oban args or delivery metadata as a long-lived mail archive. | HIGH | The artifact is an internal transport aid with deletion rules; it creates no sent-body browsing feature. |
| **Compliance that converges into send preflight** | The built-in RFC 8058 endpoint provides a safe baseline whose effect is visible on the next send. | HIGH | Keep category preferences with Chimeway/host; Mailglass owns stream-level suppression and delivery evidence. |
| **Generated-host proof as a release gate** | An adopter can trust the published install journey, not only the repository test harness. | HIGH | This is release-confidence infrastructure, not a demo app or a UI redesign. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Multi-recipient / CC / BCC support in the v2.4 async repair** | It sounds like ordinary email functionality. | It changes privacy, suppression, idempotency, delivery-row, and envelope semantics while the milestone must make one recipient correct. | Enforce the one-envelope-recipient contract; plan recipient fan-out only with its own data model and privacy work. |
| **Task.Supervisor fallback presented as production async** | It reduces setup friction where Oban is absent. | Process-local work is lost on restart and cannot satisfy a durable queued-success promise. | Require Oban and its queue/schema for production; retain the fallback only as clearly non-durable development/test behavior. |
| **Sent-email snapshots or admin body viewer** | Operators want to see the exact email after send. | It turns short-lived private queue data into a retention, encryption, authorization, redaction, and deletion product. | Scrub transient async payloads; defer opt-in sent snapshots to SEED-004 with a dedicated privacy design. |
| **Native HEEx assigns/API redesign** | It would make dynamic template authoring more ergonomic. | It changes stable renderer and preview semantics, expanding a correctness milestone into compatibility work. | Keep documented renderer/body semantics honest; defer to SEED-005. |
| **Category preferences, quiet hours, caps, digests, or scheduling** | A B2C adopter wants richer preference controls. | These are notification-policy decisions and would violate the locked Chimeway/host ownership boundary. | Mailglass provides stream-level suppression; Chimeway/host consumes one-click intent and owns category policy. |
| **Provider breadth, ecosystem integrations, or admin polish** | Each improves the product in isolation. | None proves the first documented send path correct and all increase the release matrix. | Defer until actual adopter pull; preserve current provider and UI boundaries. |
| **Exactly-once provider delivery claim** | It sounds stronger than retryable delivery. | Network/provider acknowledgement can be ambiguous after handoff; retries can be at-least-once at the provider boundary. | Promise idempotent local enqueue/ledger handling and honest attempt/status semantics, not impossible provider exactly-once delivery. |

## Feature Dependencies

```text
Zero-config single tenancy ─┐
Explicit renderer/body truth ├──> one-recipient normalized artifact ──> sync/async wire-fidelity proof
One-envelope-recipient rule ─┘                         │
                                                        ├──> atomic durable Oban enqueue
                                                        ├──> retry classification and route persistence
                                                        └──> private-payload scrub/expiry lifecycle

One-click POST replay convergence ──> stream-scoped suppression ──> later-send preflight enforcement

All launch contracts ──> generated Phoenix/Postgres proof ──> release gate

Sent snapshot viewer ──conflicts with── transient private queued-payload lifecycle
Category notification preferences ──owned by── Chimeway/host (outside Mailglass scope)
```

### Dependency Notes

- **One-recipient normalized artifact requires renderer/body truth:** async fidelity cannot be proved until the supported provider-ready form of HTML, text-only, explicit text, headers, and attachments is defined.
- **Durable enqueue requires the artifact and selected adapter reference:** the database transaction must persist everything a later worker needs, while excluding host secrets and executable render state.
- **Retry semantics require durable enqueue:** Oban can only make a retry decision after it can load a complete artifact and distinguish permanent pre-dispatch errors from retryable adapter failures.
- **Suppression enforcement requires one-click convergence:** a `200` is insufficient unless the committed suppression is consulted by the next matching send before provider handoff.
- **Generated-host proof comes last:** it should exercise the integrated contract rather than masking seams with inline adapters, test tenancy stamps, or hand-built migrations.

## MVP Definition

### Launch With (v2.4)

- [ ] **Real single-tenant sync and async first send** — default `"default"` behavior works with no caller stamp; custom tenancy does not silently downgrade its safety checks.
- [ ] **Supported one-recipient message contract** — explicit HTML/plaintext/text-only semantics and a single envelope recipient are validated before persistence and are identical at the provider boundary for sync and async.
- [ ] **Atomic Oban-backed async path** — queued success is durable and fail-closed, has a full private dispatch artifact, preserves route identity, and classifies retries honestly.
- [ ] **Idempotent stream-scoped RFC 8058 POST** — first and replayed POSTs converge, and future same-stream sends are blocked before dispatch.
- [ ] **Bounded async privacy lifecycle** — internal queued content is separated from adopter metadata, scrubbed on success, and bounded for non-success terminal states.
- [ ] **Generated production-shaped host release proof** — clean install through production preflight, sync/async send, feedback, unsubscribe enforcement, and operations mounting passes without test-helper shortcuts.

### Add After Validation (v2.x)

- [ ] **Sent-message snapshot retention** — add only when exact body reproduction has an approved encryption, authorization, redaction, retention, and deletion policy (SEED-004).
- [ ] **Native HEEx assigns rendering** — add only through a compatibility-aware renderer/preview design (SEED-005).
- [ ] **Recipient fan-out model** — add only after real adopter demand justifies per-recipient delivery, suppression, idempotency, and audit semantics.

### Future Consideration (post-v2.4)

- [ ] **Provider expansion and ecosystem integrations** — defer until repeated adopter pull justifies the support matrix.
- [ ] **Admin visual polish and message-content viewer** — defer; neither proves outbound correctness, and content viewing first requires the sent-snapshot privacy product.
- [ ] **Notification policy and preference orchestration** — keep with Chimeway/host; Mailglass remains transport, evidence, and stream suppression.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Single-tenant and renderer/body contract truth | HIGH | MEDIUM | P1 |
| One-recipient sync/async wire fidelity | HIGH | HIGH | P1 |
| Atomic durable Oban enqueue and honest retries | HIGH | HIGH | P1 |
| One-click suppression convergence | HIGH | HIGH | P1 |
| Private queued-payload scrub/retention | HIGH | HIGH | P1 |
| Generated-host preflight/release proof | HIGH | HIGH | P1 |
| Sent snapshots, HEEx assigns, fan-out, providers, UI polish | MEDIUM | HIGH | P3 |

## Sources

- `.planning/PROJECT.md` — v2.4 goal, active requirements, locked ownership boundaries, and explicit deferrals.
- `.planning/milestones/v2.3-REQUIREMENTS.md` — shipped B2C contract and promotion triggers.
- `guides/b2c-first-adopter.md` — single-tenant profile, stream behavior, and external-owner boundaries.
- `guides/getting-started.md`, `guides/authoring-mailables.md`, `guides/production-go-live-checklist.md` — published first-send and production expectations.
- `guides/unsubscribe.md`, `guides/multi-tenancy.md`, `guides/errors-and-troubleshooting.md`, `guides/testing.md` — current one-click, tenancy, retry, and test/Oban behavior.
- `.planning/seeds/SEED-004-sent-email-snapshot-retention.md`, `.planning/seeds/SEED-005-native-heex-assigns-rendering.md` — explicitly deferred scope.
- `lib/mailglass/outbound.ex`, `lib/mailglass/outbound/delivery.ex`, `lib/mailglass/config.ex` — current contract seams audited for roadmap implications.

---
*Feature research for: mailglass v2.4 Outbound First-Adopter Correctness*
*Researched: 2026-08-02*
