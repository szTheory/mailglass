# Roadmap: mailglass

**Granularity:** standard (config.json)

## Milestones

- ✅ **v0.1 Validation Release** — Phases 1-7 + 07.1 (shipped 2026-04-26) — [archive](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** — Phases 8-13 (shipped 2026-04-28) — [archive](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** — Phases 14-21 (shipped 2026-04-30) — [archive](milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Operator Confidence** — Phases 22-27 (shipped 2026-05-02) — [archive](milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 Adoption Hardening** — Phases 28-31 (shipped 2026-05-03) — [archive](milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 Production Maturity** — Phases 32-34 (shipped 2026-05-05) — [archive](milestones/v0.6-ROADMAP.md)
- ✅ **v1.0 Stability Lock** — Phases 35-38 (shipped 2026-05-06) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Inbound Core Slice** — Phases 39-44 (shipped 2026-05-06) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Inbound Production Confidence** — Phases 44.5, 45-50, 50.5, 50.7, 51 (shipped 2026-05-26) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Adopter Trust Proof** — Phases 52, 57-62 (shipped 2026-05-31) — [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 Inbound Stability Lock** — Phases 63-66 (shipped 2026-06-01) — [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 Demo Evidence and Click-Around Confidence** — Phases 67-70 (shipped 2026-06-02) — [archive](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 Inbound 1.0 Release and Truth Lock** — Phases 71-73 (shipped 2026-06-02) — [archive](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 Admin UI — IA & Design-System Polish v2** — Phases 74-79 (shipped 2026-06-05) — [archive](milestones/v1.7-ROADMAP.md)
- ✅ **v1.8 Brand System and Repo-Ready Brandbook** — Phases 80-84 (closed superseded 2026-06-11) — [archive](milestones/v1.8-ROADMAP.md)
- ✅ **v1.9 Brand Book Fable — A/B Brand System** — Phases 85-90 (shipped 2026-06-12) — [archive](milestones/v1.9-ROADMAP.md)
- ✅ **v1.10 Brand Adoption** — Phases 91-93 (shipped 2026-06-13) — [archive](milestones/v1.10-ROADMAP.md)
- ✅ **v1.11 mailglass_admin Design-System Uplift** — Phases 94-103 (shipped 2026-06-16) — [archive](milestones/v1.11-ROADMAP.md)
- ✅ **v1.12 Adopter Onboarding & Day-2 Confidence** — Phases 104-108 (shipped 2026-06-17) — [archive](milestones/v1.12-ROADMAP.md)
- ✅ **v1.13 Admin Design-System Stress Test & UX Uplift (v3)** — Phases 109-117 (shipped 2026-06-21) — [archive](milestones/v1.13-ROADMAP.md)
- ✅ **v1.14 Operator IA & Lived-Experience Redesign** — Phases 118-124 (shipped 2026-06-30) — [archive](milestones/v1.14-ROADMAP.md)
- ✅ **v1.15 Release-Pipeline Efficiency & Contributor DX** — Phases 125-131 (shipped 2026-07-02) — [archive](milestones/v1.15-ROADMAP.md)
- ✅ **v2.0 Postgres Schema Isolation** — Phases 132-137 (shipped 2026-07-04) — [archive](milestones/v2.0-ROADMAP.md)
- ✅ **v2.1 Postgres + Admin URL Hardening** — Phases 138-140 (shipped 2026-07-08) — [archive](milestones/v2.1-ROADMAP.md)
- ✅ **v2.2 CI Signal Integrity & Supply-Chain Hygiene** — Phases 141-144 (shipped 2026-07-31) — [archive](milestones/v2.2-ROADMAP.md)
- ✅ **v2.3 B2C First-Adopter Readiness** — Phases 145-148 (shipped 2026-08-02) — [archive](milestones/v2.3-ROADMAP.md)
- 📋 **v2.4 Outbound First-Adopter Correctness** — Phases 149-153 (planned)

## Phases

- [ ] **Phase 149: First-Send Contract Foundation** - Make the documented no-stamp, one-recipient rendering contract true before any work is persisted or sent.
- [ ] **Phase 150: Private Envelope and Atomic Durable Enqueue** - Persist the complete supported async message privately and atomically with durable queue work.
- [ ] **Phase 151: Unified Dispatch, Honest Outcomes, and Payload Lifecycle** - Dispatch the same prepared envelope honestly and bound private content for its full lifecycle.
- [ ] **Phase 152: Atomic One-Click Suppression Convergence** - Make RFC 8058 POSTs atomically and immediately enforce stream-scoped suppression.
- [ ] **Phase 153: Generated-Host Proof, Docs, and Release Gate** - Prove the published contract in a clean production-shaped host before releasing changed packages.

## Phase Details

### Phase 149: First-Send Contract Foundation

**Goal**: A clean default-tenant adopter can send one valid, correctly rendered message while invalid tenancy, recipient, and body shapes fail before side effects.
**Depends on**: Nothing (first phase)
**Requirements**: FIRST-01, FIRST-02, FIRST-03, FIRST-04, FIRST-05, FIRST-06, FIRST-07
**Success Criteria** (what must be TRUE):

  1. A `SingleTenant` adopter can send one supported message synchronously or select durable async delivery without setting a process-local tenant stamp, and that delivery is owned by tenant `"default"`.
  2. An adopter using custom tenancy receives a typed, actionable failure rather than a send or queue success when required tenant context is absent, invalid, or unavailable to an async worker.
  3. A delivery with zero recipients or more than one total recipient across `to`, `cc`, and `bcc` is rejected with a typed preflight error before rendering, rate limiting, persistence, job insertion, or provider dispatch.
  4. Explicit plaintext, text-only mail, and HTML mail retain the documented body semantics, and the `renderer.plaintext` and `renderer.css_inliner` settings have the same observable effect in rendering, sync send, async send, and preview.
  5. Unsupported envelope or body content fails explicitly before a delivery row or job exists; Mailglass never silently drops a recipient or message content.

**Plans**: 1/4 plans executed

Plans:
**Wave 1**

- [x] 149-01-PLAN.md — Prove the resolver-aware first-send tracer and fail-closed custom tenancy.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 149-02-PLAN.md — Enforce exact recipient/body preflight before every side effect.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 149-03-PLAN.md — Implement renderer body precedence and cross-consumer configuration parity.

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 149-04-PLAN.md — Reconcile stable API and adopter documentation with the shipped contract.

### Phase 150: Private Envelope and Atomic Durable Enqueue

**Goal**: A durable async request either creates one private, complete, recoverable outbound envelope and its queue work atomically or reports no queued work at all.
**Depends on**: Phase 149
**Requirements**: ENVL-01, ENVL-02, ENVL-04, ENVL-05, ENVL-06, ENVL-07, ENVL-08
**Success Criteria** (what must be TRUE):

  1. A durable send stores a versioned Mailglass-private envelope while public `Delivery.metadata` and Oban arguments contain no rendered content or provider payload; the job carries only stable identifiers and tenant context.
  2. The private envelope round-trips every documented async-supported field—including the sole recipient, sender, reply-to, subject, headers, HTML, plaintext, stream/tags/metadata, selected adapter reference, attachments, and supported JSON-safe provider options—without silent loss; unsupported attachment or option forms fail explicitly before queueing.
  3. A prepared async request renders content and selects its adapter route before enqueue, so retries use the immutable stored envelope rather than changed templates, process state, or routing configuration.
  4. Under the configured Mailglass schema prefix, the delivery projection, queued ledger event, private payload, and real `mailglass_outbound` Oban job commit together or none commit; legacy queued payloads have a prefix-safe forward-compatible reader/migration path.
  5. Selecting `async_adapter: :oban` returns a typed readiness failure if Oban is absent, unusable, or cannot insert the canonical-queue job, with no `Task.Supervisor` fallback; explicit `:task_supervisor` is documented and checked as non-durable development/test-only behavior.

**Plans**: TBD

### Phase 151: Unified Dispatch, Honest Outcomes, and Payload Lifecycle

**Goal**: Sync and durable async delivery use the same prepared provider input, report outcomes honestly, and retain private queue content only as long as operationally necessary.
**Depends on**: Phase 150
**Requirements**: ENVL-03, DISP-01, DISP-02, DISP-03, DISP-04, PRIV-01, PRIV-02, PRIV-03, PRIV-04
**Success Criteria** (what must be TRUE):

  1. For the same supported one-recipient message, synchronous and Oban-backed asynchronous paths supply wire-equivalent provider input, except for timing and provider-generated values.
  2. Provider outcomes are structurally classified: retryable transport failures retry through Oban, malformed/configuration/suppression/missing-payload and confirmed permanent failures settle without retry, and uncertain provider acceptance is recorded for repair/reconciliation rather than blindly resent.
  3. Published guidance accurately describes the at-least-once provider boundary and how provider idempotency or correlation can reduce duplicate risk without claiming impossible exactly-once delivery.
  4. A successful dispatch atomically records success and scrubs its private payload while retaining the non-sensitive delivery projection and ledger; terminal, discarded, abandoned, and legacy queued payloads follow a configurable bounded-retention prune/recovery policy.
  5. Missing, corrupt, expired, unsupported-version, or already-scrubbed payloads fail closed with an operator-actionable state and are never rebuilt from incomplete public metadata; new async sends keep bodies, subjects, headers, tokens, attachments, and provider options out of public metadata.

**Plans**: TBD

### Phase 152: Atomic One-Click Suppression Convergence

**Goal**: A valid RFC 8058 one-click POST reliably converges into one tenant-safe, stream-scoped suppression that immediately prevents future matching sends.
**Depends on**: Phase 149
**Requirements**: UNSUB-07, UNSUB-08, UNSUB-09, UNSUB-10, UNSUB-11
**Success Criteria** (what must be TRUE):

  1. A valid built-in one-click POST atomically creates or reuses exactly one canonical unsubscribe event and one `address_stream` suppression for the token's tenant, address, and originating stream.
  2. Concurrent or replayed valid POSTs return the required empty success response and converge without duplicate durable records or external side effects.
  3. Once the transaction commits, the next send to the same address and stream is preflight-blocked, while transactional mail and unrelated streams remain sendable.
  4. Database mutation completes before callbacks or broadcasts run, so failed transactions produce neither a success response nor a partial event/suppression pair.
  5. The behavior stays tenant-safe and schema-prefix-safe under hostile `search_path` conditions.

**Plans**: TBD

### Phase 153: Generated-Host Proof, Docs, and Release Gate

**Goal**: A clean, production-shaped Phoenix host proves the published first-adopter journey end to end and prevents release on contract or configuration drift.
**Depends on**: Phase 151, Phase 152
**Requirements**: ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-04, ADOPT-05, ADOPT-06, REL-17
**Success Criteria** (what must be TRUE):

  1. An unassisted generated Phoenix/Ecto/Postgres host installs the published-package-shaped Mailglass family, generates and runs schema-isolated migrations, boots through public APIs, and runs a real `mailglass_outbound` Oban queue.
  2. In that host, an unstamped default-tenant sync send and an Oban-backed async send produce equivalent captured provider input without `MailerCase`, repo-local `TestRepo`, hidden tenant stamps, inline workers, or fixture-only configuration.
  3. Negative-control host runs fail loudly before false queued or sent success when Oban is missing, the `mailglass_outbound` queue is missing or wrong, migrations/schema drift, or recipient/payload shapes are unsupported.
  4. The host proves signed provider feedback reaches the durable event/ledger contract and a replayed one-click POST prevents a later same-stream send.
  5. Production preflight, the production-available operator mount, and executable README/getting-started/authoring/rate-limit/production/multi-tenancy/compatibility/admin-packaging guidance match shipped behavior; only changed packages are released after this published-package journey passes.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 149. First-Send Contract Foundation | 1/4 | In Progress|  |
| 150. Private Envelope and Atomic Durable Enqueue | 0/TBD | Not started | - |
| 151. Unified Dispatch, Honest Outcomes, and Payload Lifecycle | 0/TBD | Not started | - |
| 152. Atomic One-Click Suppression Convergence | 0/TBD | Not started | - |
| 153. Generated-Host Proof, Docs, and Release Gate | 0/TBD | Not started | - |
