# Project Research Summary

**Project:** mailglass
**Domain:** Phoenix/Postgres transactional-email framework — v2.4 outbound first-adopter correctness
**Researched:** 2026-08-02
**Confidence:** HIGH for present-state facts and scope; MEDIUM for adapter-specific outcome handling

## Executive Summary

Mailglass v2.4 is one convergence milestone, not product-surface expansion. It must make the documented B2C first-send path true in a clean Phoenix/Postgres host: a zero-config single-tenant app can send a supported one-recipient message synchronously or durably through Oban; RFC 8058 one-click POSTs atomically create a stream-scoped suppression; and production operations work from the published packages. Keep Phoenix, Ecto/Postgres, Swoosh, and optional Oban. The corrective architectural move is to replace the partial message snapshot in public delivery metadata with a private, versioned, one-recipient outbound envelope.

Build from the contract inward: resolve tenant and reject a multi-recipient envelope before rendering or persistence; make body semantics truthful; then persist a prepared wire-equivalent envelope with the delivery, queued event, and host-owned mailglass_outbound Oban job in one transaction. Oban is the documented durable mode and must fail closed when unavailable or miswired—never silently downgrade to Task.Supervisor. The worker must distinguish retryable, terminal, and ambiguous provider outcomes; enqueue atomicity is achievable, provider exactly-once delivery is not.

The material risks are privacy leakage from retaining queue content in Delivery.metadata, duplicate sends after uncertain provider acceptance, non-atomic unsubscribe convergence, schema-prefix migration mistakes, and a false-green host smoke that never starts Oban. Mitigate with a private payload lifecycle (success scrub plus bounded terminal retention), an uncertain/repair state instead of blind resend, one Ecto.Multi for unsubscribe event plus suppression, hostile-search-path migration coverage, and a generated Phoenix/Postgres release gate that executes published configuration exactly.

## Key Findings

### Recommended Stack

Keep the established stack; no new queue, broker, renderer, or web framework is warranted. The new internal payload boundary is a Mailglass schema/module, not a service.

**Core technologies:**

- **Elixir ~> 1.18; Phoenix ~> 1.8 (lock 1.8.9):** retain the existing router/controller for signed RFC 8058 POST; fix transaction correctness, not web routing.
- **Ecto/Ecto SQL ~> 3.13 (lock 3.14.0), Postgrex ~> 0.22 (lock 0.22.3), PostgreSQL 14+:** use Ecto.Multi with explicit Mailglass schema-prefix options for local atomic facts.
- **Oban optional ~> 2.21 (lock 2.23.0):** the adopter host owns its Repo, migrations, and queues: [mailglass_outbound: concurrency]; selecting async_adapter: :oban without a usable integration returns an error and creates no sendable partial work.
- **Swoosh ~> 1.25 (lock 1.26.3):** canonical provider-ready representation; private envelope codec preserves the supported one-recipient field surface rather than partial reconstruction.
- **Premailex ~> 1.0 and Floki ~> 0.38:** retain existing HTML inlining/plaintext pipeline, but honor explicit text, text-only messages, and documented automatic-plaintext configuration.

Do not serialize Mailglass.Message into Oban arguments, add a broker/retry library, configure obsolete queue :mailglass, or present Task.Supervisor as durable. Oban provides durable job execution, not atomic provider acceptance.

### Expected Features

**Must have (v2.4 launch contract):**

- No-stamp default tenant "default" for sync, durable async, feedback, and unsubscribe; custom tenancy stays fail-closed without valid context.
- Published renderer/body truth: text-only remains text-only, explicit plaintext wins, HTML transformation is independent, and invalid shapes fail before send/enqueue.
- Exactly **one envelope recipient total** per delivery. Reject extra to, cc, or bcc before a delivery row, idempotency key, payload, or job exists; do not silently select the first address and do not introduce fan-out.
- Wire-equivalent sync and async dispatch for the supported envelope, immutable before the async boundary, with selected adapter reference but no host secrets.
- Atomic durable queueing: delivery projection, queued event, private payload, and Oban job either commit together or none do.
- Honest outcomes: transient failures retry; malformed/configuration/suppression/missing-payload failures settle terminally; uncertain provider acceptance is repair-required, not an automatic resend.
- Idempotent one-click POST atomically commits its canonical unsubscribe event and originating address+stream suppression; later eligible sends are preflight-blocked while transactional behavior remains unchanged.
- Private queued-payload lifecycle: queue content is never public metadata, scrubs after success, and is bounded/expired for terminal or abandoned work.
- Generated published-package Phoenix/Postgres host proves migrations, queue wiring, sync/async, feedback, unsubscribe, operations mount, and doctor/preflight before release.

**Differentiators:** a testable one-recipient parity promise, privacy-bounded durable content rather than casual job serialization, compliance that immediately converges into preflight, and generated-host proof as a release gate.

**Deferred by scope lock:** native HEEx assigns; recipient fan-out; sent-snapshot/body-viewer UI; provider breadth; ecosystem integrations; admin visual polish; and Chimeway/host-owned Alpha business policy (categories, quiet hours, caps, digests, scheduling). No new convergence milestone is recommended.

### Architecture Approach

Preserve Message -> Renderer -> Outbound -> Delivery/Event -> Adapter, but establish OutboundEnvelope as the durable boundary. Outbound preflight resolves tenant, validates a single envelope recipient, checks stream suppression, and produces a final rendered message. Envelope.build serializes only supported JSON-safe wire data to private Outbound.Payload; Envelope.to_message is used by both sync and worker dispatch. Public Delivery stays a non-secret operator projection and never reconstructs a wire message.

**Major components:**

1. **Tenancy / outbound preflight** — accepts "default" only for SingleTenant; requires stamps for custom resolvers and propagates the resolved tenant through the job.
2. **Renderer + Outbound.Envelope** — fixes body truth, validates the one-recipient subset, canonicalizes it, and round-trips the supported Swoosh input.
3. **Outbound.Payload + atomic enqueue** — privately persists versioned envelope data with delivery/event/job in one prefix-aware Ecto.Multi, including transitional handling for pre-v2.4 queued rows.
4. **Outbound.Worker + Outbound.Retry** — reloads only private envelope, classifies success/retry/cancel/uncertain, and never re-renders or treats scrubbed payload as recoverable.
5. **Unsubscribe controller + suppression store** — writes/reuses canonical event and address-stream suppression atomically; webhook AutoSuppress remains separate.
6. **Generated host/journey runner** — invokes public APIs and exact runtime config; proof infrastructure, not a second app or UI initiative.

### Critical Pitfalls

1. **Default tenancy contradicted by assert_stamped!:** resolve effective tenancy at outbound boundary and test clean-process sync, worker, and webhook paths; custom tenancy must still raise when unstamped.
2. **One stored recipient but multi-recipient Swoosh envelope:** validate/reject multi-to, cc, and bcc before persistence; never silently select the first recipient.
3. **Partial async snapshot and public-metadata privacy leak:** use a versioned private allowlist codec; migrate/read legacy queued metadata only temporarily, scrub legacy keys, and forbid content in delivery/admin/telemetry/event projections.
4. **Blind retry after ambiguous provider result:** document at-least-once provider behavior, mark uncertainty, and use reconciliation/operator recovery rather than another provider send.
5. **One-click 200 without enforceable suppression:** put event reuse and stream suppression in the same prefix-aware Ecto.Multi; prove concurrent/replayed POST plus immediate future send.
6. **Production proof that runs only a dev route:** use generated host with Postgres migrations, running mailglass_outbound, default tenant, and published docs; prove missing/miswired Oban fails closed.

## Implications for Roadmap

Suggested dependency-ordered phases continue at **149**. They are the v2.4 convergence milestone; do not open a polish, provider, business-policy, or ecosystem track.

### Phase 149: First-Send Contract Foundation

**Rationale:** Envelope durability and equivalence cannot be designed until tenant, recipient cardinality, and rendered-body truth are explicit and enforced at the outbound boundary.

**Delivers:** Effective tenant resolution permitting implicit "default" only under SingleTenant; custom-resolver fail-closed behavior; renderer semantics for explicit plaintext, text-only, HTML-only, and documented automatic plaintext; structured rejection of all multi-recipient to/cc/bcc shapes before persistence. Behavioral contract: one delivery, one envelope recipient, one suppression decision, one provider dispatch.

**Addresses:** zero-config first send, explicit body truth, exactly-one-recipient contract.

**Avoids:** process-stamp contradiction; silent first-recipient attribution; renderer drift. Include clean-process and adapter-capture tests, including duplicate/case-normalized and empty-address cases.

### Phase 150: Private Envelope and Atomic Durable Enqueue

**Rationale:** The foundation defines immutable supported input. Atomic queue success must mean all recoverable work exists, not merely a delivery projection.

**Delivers:** Versioned private Outbound.Payload, allowlisted JSON-safe envelope codec/round-trip tests, schema-prefixed migration/backfill compatibility for legacy queued rows, and one Ecto.Multi that commits Delivery + queued Event + Payload + mailglass_outbound Oban job. New code reads payload first; no new work reconstructs from Delivery.metadata. If :oban is selected but unavailable, unready, or insertion fails, return an error and do not report queued.

**Addresses:** wire-fidelity substrate, fail-closed durable enqueue, private queue-content boundary.

**Avoids:** partial snapshot loss, stranded jobs, metadata PII retention, queue-name drift, and prefix leakage. Reject attachments at enqueue unless a safe serialized/reference representation is explicitly supported; never drop them.

### Phase 151: Unified Dispatch, Honest Outcomes, and Payload Lifecycle

**Rationale:** Once durable envelope exists, both dispatch modes can use the same reconstructed provider input and enforce lifecycle truth without re-rendering against changed code/configuration.

**Delivers:** Shared sync/worker dispatch; Retry classification into retryable, terminal, and uncertain outcomes; state that does not call uncertain provider acceptance a safe failure; success scrub coupled to outcome persistence; bounded terminal/abandoned retention and pruner; fail-closed handling for expired, corrupt, or scrubbed queued payloads.

**Addresses:** one-recipient sync/async parity, honest retry, bounded private payload lifecycle.

**Avoids:** retry-all behavior, duplicate sends after timeout-after-accept, indefinite payload retention, and accidental sent-snapshot feature. Keep adapter calls outside local database transactions.

### Phase 152: Atomic One-Click Suppression Convergence

**Rationale:** It depends on the tenant/prefix contract, and follows preflight stabilization so its immediate send-blocking assertion targets final behavior.

**Delivers:** Prefix-aware controller Ecto.Multi that creates/reuses unsubscribe event and correct address+stream suppression atomically, runs only safe post-commit side effects, preserves empty-200 replay behavior, and proves future same-stream preflight blocking without broadening transactional suppression or notification policy.

**Addresses:** RFC 8058 replay convergence and stream-scoped enforcement.

**Avoids:** eventual webhook-only projection gaps, duplicate side effects, cross-tenant mutation, and search_path-masked bugs. Prove concurrent POST/send and replay under hostile schema paths.

### Phase 153: Generated-Host Proof, Docs, and Release Gate

**Rationale:** Host proof consumes final public contracts, migration shape, queue name, and privacy/outcome behavior; building it last makes it integration evidence rather than a test-helper workaround.

**Delivers:** Disposable Phoenix/Ecto/Postgres host using published packages and public APIs; migrations and running mailglass_outbound; default no-stamp tenancy; sync/async provider-capture parity; feedback; replayed one-click plus later suppression; operations mount and doctor/preflight; intentional missing-Oban and docs/queue-drift failures; release-gating automation and corrected guides.

**Addresses:** unassisted adopter journey and release proof.

**Avoids:** non-production --no-ecto smoke, stale snippets, inline adapters, and hidden schema/Oban misconfiguration.

### Phase Ordering Rationale

- Phase 149 freezes the supported one-recipient input; phase 150 can serialize it without compatibility ambiguity.
- Phase 150 makes queue success atomic and supplies phase 151’s replay/retry/privacy object.
- Phase 152 is local but follows preflight stabilization so its post-click send-blocking proof is reliable; it stays in the one convergence milestone.
- Phase 153 integrates settled public behavior and catches host Repo/Oban ownership, queue names, migrations, signing, prefixes, and docs.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 150:** inspect pinned Oban transaction APIs and migration conventions; settle exact legacy-payload compatibility and attachment rejection surface.
- **Phase 151:** validate each supported adapter’s timeout, correlation, permanent/transient, and idempotency evidence; uncertain acceptance needs concrete repair/reconciliation policy.
- **Phase 153:** validate generated-host toolchain/version matrix and published-package test mechanism near execution because release tooling and Hex are external-state sensitive.

Phases with standard patterns (normally skip research-phase):

- **Phase 149:** repository seams and contract tests are specific and already inventoried.
- **Phase 152:** RFC 8058 plus existing event/suppression conflict targets give a bounded established transaction pattern; inspect prefix/lifecycle-hook seams but no broad discovery is needed.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Official Oban, Swoosh, Ecto, and RFC sources support the approach; exact pinned-version behavior and host configuration need planning verification. |
| Features | HIGH | Grounded in PROJECT.md, active requirements, guide paths, and explicit scope locks. |
| Architecture | HIGH | Repository inventory identifies concrete seams and additive boundaries. |
| Pitfalls | HIGH | Repository/test/guide evidence confirms first-send, queue, metadata, one-click, and host-smoke risks; provider outcome taxonomy remains adapter-specific. |

**Overall confidence:** HIGH for phase structure and scope; MEDIUM for retry repair details and migration rollout mechanics.

### Gaps to Address

- **Adapter evidence:** define concrete supported-adapter error/correlation mappings and any idempotency/reconciliation lookup. Do not infer from error strings.
- **Attachment surface:** default recommendation is reject attachments at enqueue unless a JSON-safe, retention-bounded reference contract already exists.
- **Legacy migration:** establish age/count of pre-v2.4 queued rows, reader cutoff, indexes, lock budget, and rollback/forward recovery under mailglass prefix.
- **Lifecycle hook:** verify whether unsubscribe lifecycle work is DB-only/idempotent; external side effects run after commit.
- **Retention:** set explicit bounded terminal/abandoned duration and backup/access policy. Payload is private transport data, never a sent-message archive or operator viewer.
- **Compatibility wording:** publish exactly-one-recipient plus explicit durable field subset; make any previously accepted conflicting shape a clear rejection/migration rather than silent change.

## Sources

### Primary (HIGH confidence)

- [Project scope and active requirements](../PROJECT.md) — v2.4 goal, package ownership, required behavior, and deferrals.
- [Stack research](STACK.md), [feature research](FEATURES.md), [architecture research](ARCHITECTURE.md), and [pitfall research](PITFALLS.md) — repository-grounded synthesis inputs.
- [RFC 8058 — One-Click Unsubscribe](https://www.rfc-editor.org/rfc/rfc8058.html) — HTTPS POST and opaque recipient/list identifier requirements.

### Secondary (MEDIUM confidence)

- [Oban Worker documentation](https://oban.hexdocs.pm/Oban.Worker.html) — job construction, queue options, transaction insertion.
- [Oban error handling](https://oban.hexdocs.pm/error_handling.html) — retry/backoff and worker-result semantics.
- [Ecto.Multi documentation](https://hexdocs.pm/ecto/Ecto.Multi.html) — transaction composition.
- [Swoosh.Email documentation](https://swoosh.hexdocs.pm/Swoosh.Email.html) — canonical email field surface.

---
*Research completed: 2026-08-02*
*Ready for roadmap: yes — phases 149–153, one convergence milestone*
