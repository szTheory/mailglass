# Requirements: mailglass — v2.4 Outbound First-Adopter Correctness

**Defined:** 2026-08-02  
**Core Value:** Email you can see, audit, and trust before it ships.  
**Goal:** Make Mailglass's documented single-recipient sync/async B2C path correct, durable, privacy-bounded, and proven from a clean Phoenix host before Alpha adopts it.

## v2.4 Requirements

### First-send contract

- [ ] **FIRST-01:** A default `Mailglass.Tenancy.SingleTenant` caller can send synchronously and durably asynchronously as tenant `"default"` without setting a process-local tenant stamp.
- [ ] **FIRST-02:** A configured custom tenancy implementation remains fail-closed when required tenant context is absent, invalid, or cannot be restored in an async worker.
- [ ] **FIRST-03:** Mailglass accepts exactly one envelope recipient total across `to`, `cc`, and `bcc` for a delivery and returns a typed, actionable preflight error for every zero- or multi-recipient shape.
- [ ] **FIRST-04:** Recipient-cardinality rejection occurs before rendering side effects, rate-limit consumption, delivery/event/payload persistence, job insertion, or provider dispatch.
- [ ] **FIRST-05:** An adopter-authored plaintext body is preserved, a text-only message remains non-empty and sendable, and automatic plaintext is generated only when the published renderer contract calls for it.
- [ ] **FIRST-06:** The documented `renderer.plaintext` and `renderer.css_inliner` settings change observable rendering behavior consistently in direct render, synchronous send, async send, and preview paths.
- [ ] **FIRST-07:** Invalid or unsupported body/envelope shapes return typed errors before any delivery row or job is created; no path silently drops content or recipients.

### Durable outbound envelope

- [ ] **ENVL-01:** Durable async delivery stores a versioned Mailglass-private outbound payload separate from public `Delivery.metadata` and Oban job arguments contain only stable identifiers and tenant context.
- [ ] **ENVL-02:** The private envelope round-trips every documented async-supported field, including sender, sole recipient, reply-to, subject, headers, HTML, plaintext, Mailglass stream/tags/metadata, attachments, selected adapter reference, and supported JSON-safe provider options.
- [ ] **ENVL-03:** Synchronous and Oban-backed asynchronous delivery produce wire-equivalent provider input for the same supported message, except for timing and provider-generated values.
- [ ] **ENVL-04:** A message is rendered and its adapter route selected before the async boundary; retries use the immutable stored envelope and never re-render executable template state or read a newly changed route.
- [ ] **ENVL-05:** Delivery projection, queued ledger event, private payload, and `mailglass_outbound` Oban job commit atomically, or none of them commit.
- [ ] **ENVL-06:** Selecting `async_adapter: :oban` fails closed with a typed readiness error when Oban is unavailable, its integration is unusable, or insertion fails; it never silently falls back to `Task.Supervisor`.
- [ ] **ENVL-07:** Explicit `async_adapter: :task_supervisor` remains available only as a clearly documented non-durable development/test choice and never satisfies production readiness checks.
- [ ] **ENVL-08:** Production configuration, generated examples, and executable contract checks use the worker's canonical `mailglass_outbound` queue name and fail on queue-name drift.

### Dispatch outcomes and payload lifecycle

- [ ] **DISP-01:** Worker outcomes distinguish retryable transport failures, terminal pre-dispatch/permanent failures, and uncertain provider-acceptance outcomes using structured classifications rather than error-message matching.
- [ ] **DISP-02:** Only retryable failures are returned to Oban for automatic retry; malformed/configuration/suppression/missing-payload and confirmed permanent provider failures settle without retry.
- [ ] **DISP-03:** An uncertain provider-acceptance outcome is recorded as repair/reconciliation required and is not automatically resent as though the provider definitely rejected it.
- [ ] **DISP-04:** Public documentation states the honest at-least-once provider boundary and describes when provider idempotency/correlation can reduce duplicate risk without claiming impossible exactly-once delivery.
- [ ] **PRIV-01:** Successful dispatch scrubs the private outbound payload as part of the persisted success transition without deleting the non-sensitive delivery projection or ledger history.
- [ ] **PRIV-02:** Terminal, discarded, abandoned, and legacy queued payloads follow a configurable, documented bounded-retention policy with a safe prune/recovery path.
- [ ] **PRIV-03:** New async sends never store rendered bodies, subjects, headers, tokens, attachments, or provider options in public `Delivery.metadata`; legacy content has an explicit forward migration and cleanup strategy.
- [ ] **PRIV-04:** Missing, corrupt, unsupported-version, expired, or already-scrubbed payloads fail closed with an operator-actionable state and are never reconstructed from incomplete public metadata.

### One-click unsubscribe convergence

- [ ] **UNSUB-07:** A valid built-in RFC 8058 POST atomically creates or reuses both the canonical unsubscribe event and an `address_stream` suppression for the token's tenant, address, and originating stream.
- [ ] **UNSUB-08:** Concurrent and replayed valid POSTs return the required empty success response while converging to one durable event and one suppression without duplicate side effects.
- [ ] **UNSUB-09:** After commit, the next send to the same address and stream is blocked in preflight, while a stream unsubscribe does not block transactional mail or unrelated streams.
- [ ] **UNSUB-10:** Database changes complete before lifecycle callbacks or broadcasts; external/host side effects run post-commit and cannot make the Mailglass event/suppression pair partially durable.
- [ ] **UNSUB-11:** One-click convergence remains tenant-safe and schema-prefix-safe under a hostile `search_path`, and a failed transaction returns no success response or partial mutation.

### Production adopter proof and release

- [ ] **ADOPT-01:** A disposable stock Phoenix/Ecto/Postgres host can install the published-package-shaped Mailglass family, generate and run schema-isolated migrations, and boot using only public adopter APIs.
- [ ] **ADOPT-02:** The generated host proves an unstamped single-tenant synchronous send and Oban-backed async send produce equivalent captured provider input without `MailerCase`, repo-local `TestRepo`, hidden stamps, inline workers, or fixture-only configuration.
- [ ] **ADOPT-03:** Negative-control host runs prove missing Oban, missing/wrong `mailglass_outbound` queue, migration/schema drift, and unsupported recipient or payload shapes fail loudly before a false queued/sent success.
- [ ] **ADOPT-04:** The generated host proves signed provider feedback reaches the durable ledger/event contract and a replayed one-click POST blocks a later same-stream send.
- [ ] **ADOPT-05:** Production preflight covers repo/schema access, selected adapter shape, webhook verification config, Oban queue/maintenance scheduling, and a production-available operator mount without requiring admin visual changes.
- [ ] **ADOPT-06:** README, getting-started, authoring, rate-limit, production, multi-tenancy, compatibility, and admin packaging guidance are executable against the shipped behavior and consistently describe the current 2.x contract.
- [ ] **REL-17:** Release the changed package set without mechanically republishing unchanged siblings, then pass the clean published-package adopter journey against the versions users actually install.

## Future Requirements

### Native authoring

- **HEEX-01:** Message assigns propagate through native function-component rendering with preview/production parity and a compatibility-aware `Mailable.render/3` contract.

### Retained evidence

- **SNAP-01:** An adopter can opt into provider-independent sent-message snapshots only after encryption, authorization, redaction, attachment, retention, and deletion policy are explicitly designed.

### Recipient expansion

- **RCPT-01:** Mailglass can fan out a logical message into independently correlated per-recipient deliveries if repeated adopter demand justifies the data-model and privacy expansion.

## Out of Scope

| Feature | Reason |
|---|---|
| Admin visual/UI polish | The current operator surface is serviceable; this milestone fixes production availability and correctness only. |
| Alpha notification categories, quiet hours, caps, digests, scheduling, and fallback | Chimeway/host owns notification policy. |
| Alpha auth-token, billing, support, paging, and mobile behavior | Sigra, Accrue, Cairnloop, Parapet, Crosswake, and the host retain their locked ownership. |
| Native HEEx assigns in v2.4 | SEED-005 is valuable but compatibility-sensitive and has a working pre-render path; keep this convergence milestone focused. |
| Sent-message snapshot/body viewer | Transient async payloads must be scrubbed, not promoted into an operator retention product; SEED-004 remains deferred. |
| Multi-recipient fan-out | The approved v2.4 contract is exactly one envelope recipient per delivery. |
| New providers, transport classes, ecosystem adapters, or `crosswake_mailglass` | No adopter evidence justifies expanding the support matrix or ownership boundary. |
| CI/CD efficiency work | SEED-006 does not advance Alpha runtime correctness. |

## Traceability

Populated during roadmap creation. Every v2.4 requirement must map to exactly one phase.

| Requirement | Phase | Status |
|---|---|---|
| FIRST-01 | Phase 149 | Pending |
| FIRST-02 | Phase 149 | Pending |
| FIRST-03 | Phase 149 | Pending |
| FIRST-04 | Phase 149 | Pending |
| FIRST-05 | Phase 149 | Pending |
| FIRST-06 | Phase 149 | Pending |
| FIRST-07 | Phase 149 | Pending |
| ENVL-01 | Phase 150 | Pending |
| ENVL-02 | Phase 150 | Pending |
| ENVL-04 | Phase 150 | Pending |
| ENVL-05 | Phase 150 | Pending |
| ENVL-06 | Phase 150 | Pending |
| ENVL-07 | Phase 150 | Pending |
| ENVL-08 | Phase 150 | Pending |
| ENVL-03 | Phase 151 | Pending |
| DISP-01 | Phase 151 | Pending |
| DISP-02 | Phase 151 | Pending |
| DISP-03 | Phase 151 | Pending |
| DISP-04 | Phase 151 | Pending |
| PRIV-01 | Phase 151 | Pending |
| PRIV-02 | Phase 151 | Pending |
| PRIV-03 | Phase 151 | Pending |
| PRIV-04 | Phase 151 | Pending |
| UNSUB-07 | Phase 152 | Pending |
| UNSUB-08 | Phase 152 | Pending |
| UNSUB-09 | Phase 152 | Pending |
| UNSUB-10 | Phase 152 | Pending |
| UNSUB-11 | Phase 152 | Pending |
| ADOPT-01 | Phase 153 | Pending |
| ADOPT-02 | Phase 153 | Pending |
| ADOPT-03 | Phase 153 | Pending |
| ADOPT-04 | Phase 153 | Pending |
| ADOPT-05 | Phase 153 | Pending |
| ADOPT-06 | Phase 153 | Pending |
| REL-17 | Phase 153 | Pending |

**Coverage:**
- v2.4 requirements: 35 total
- Mapped to phases: 35
- Unmapped: 0

---
*Requirements defined: 2026-08-02*
*Last updated: 2026-08-02 after research-backed v2.4 definition*
