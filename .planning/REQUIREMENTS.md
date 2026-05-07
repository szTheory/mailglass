# Requirements: mailglass v1.2 — Inbound Production Confidence

**Defined:** 2026-05-06
**Core Value:** Email you can see, audit, and trust before it ships. Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure.

**Milestone goal:** Bring `mailglass_inbound` to the operator/dev/admin maturity outbound reached across v0.4–v0.6, so adopters on the major providers can install, debug from the dashboard, write tests, and operate inbound with the same confidence they already get on outbound.

> Research synthesis: `.planning/research/milestone-candidates/SYNTHESIS.md` (5 parallel agents, strong convergence). Strategic alternatives investigated and rejected at `.planning/research/milestone-candidates/05-strategic-alternatives.md`.

---

## v1.2 Requirements

### Telemetry Foundation (TELE)

Currently `mailglass_inbound/lib/` contains **zero** `:telemetry` calls. This is the biggest single observability gap and a blocker for `MailglassAdmin.PubSub.Topics` live-update wiring.

- [ ] **TELE-01**: Inbound emits `[:mailglass_inbound, :ingress, :request, :start | :stop | :exception]` spans on every ingress request, with PII-free metadata (provider, tenant_id, status, latency, byte size — never recipient, sender, body, headers)
- [ ] **TELE-02**: Inbound emits `[:mailglass_inbound, :route, :match, :start | :stop | :exception]` spans during router matching, with metadata for matched mailbox / no-match outcome / candidate count
- [ ] **TELE-03**: Inbound emits `[:mailglass_inbound, :execution, :run, :start | :stop | :exception]` spans wrapping mailbox execution (both Oban worker path and Task.Supervisor fallback path), with mailbox module / outcome (`:accept | :reject | :ignore | {:bounce, reason}`) / source (`:fresh | :replay`) metadata
- [ ] **TELE-04**: Inbound emits `[:mailglass_inbound, :persist, :record, :start | :stop | :exception]` spans during persistence, with operation (insert/update/dedup_skip) / record_type metadata
- [ ] **TELE-05**: A telemetry handler raising during inbound processing does not break business logic (mirrors outbound contract)
- [ ] **TELE-06**: All telemetry metadata passes the existing `NoPIIInTelemetry` Credo check; the check is extended to cover `mailglass_inbound/`
- [ ] **TELE-07**: Inbound telemetry events are surfaced through `MailglassAdmin.PubSub.Topics` so the v1.2 admin LiveView can subscribe for live updates

### Idempotency Convergence Proof (TELE — continued)

- [ ] **TELE-08**: A StreamData property test proves 1000-replay convergence on inbound ingest (same provider payload N times → exactly one `InboundRecord` + one `ExecutionRun`), mirroring the outbound v0.1 webhook ingest proof

### Shared MIME Module (MIME)

- [ ] **MIME-01**: `MailglassInbound.MIME` module parses canonical RFC 5322 message bodies into a stable internal representation (headers, parts, attachments, inline content)
- [ ] **MIME-02**: MIME backend is gated through `Mailglass.OptionalDeps.GenSmtp` (existing) for nested-multipart parsing; degraded fallback path documented
- [ ] **MIME-03**: `mailglass.inbound.doctor` reports MIME backend availability and which optional dep is in use
- [ ] **MIME-04**: MIME parsing handles malformed payloads without raising; returns structured `Mailglass.Error{type: :inbound_mime_invalid}` matching the project's error contract

### Mailgun Inbound Ingress (MGUN)

- [ ] **MGUN-01**: `MailglassInbound.Ingress.Providers.Mailgun` plug verifies HMAC-SHA256 timestamp+token signature and rejects forged requests by raising `MailglassInbound.SignatureError` (no recovery path, mirroring outbound D-22)
- [ ] **MGUN-02**: Mailgun ingress reuses the existing `Mailglass.Webhook.Providers.MailgunReplayCache` ETS table (or aliases its supervisor/owner pattern) to prevent timestamp-replay attacks
- [ ] **MGUN-03**: Mailgun ingress normalizes the multipart payload into the canonical `%MailglassInbound.InboundMessage{}` shape and persists raw provider source to `inbound_evidence` for replay truth
- [ ] **MGUN-04**: `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` allowlist is extended to recognize the Mailgun provider key
- [ ] **MGUN-05**: Mailgun setup guide at `docs/inbound-mailgun.md` covers HTTP route URL, API key configuration, signing key rotation, and verification

### SES Inbound Ingress (SESI)

- [ ] **SESI-01**: `MailglassInbound.Ingress.Providers.SES` plug verifies SNS X.509 message signatures using the existing `Mailglass.Webhook.Providers.SES.CertCache` and `TrustPolicy` modules (URL allowlist for SubscriptionConfirmation prevents hijacking attacks)
- [ ] **SESI-02**: SES ingress auto-confirms `SubscriptionConfirmation` notifications when the SubscribeURL passes TrustPolicy validation (mirrors outbound webhook behavior)
- [ ] **SESI-03**: `MailglassInbound.S3Fetcher` behaviour defines the contract for fetching MIME body from S3 when SES delivers `Action: S3` notifications
- [ ] **SESI-04**: A `MailglassInbound.S3Fetcher.Fake` test implementation ships in core; a real `MailglassInbound.S3Fetcher.ExAwsS3` adapter ships behind `Mailglass.OptionalDeps.ExAwsS3` (new optional-dep gateway, mirroring `OptionalDeps.GenSmtp`)
- [ ] **SESI-05**: SES ingress handles the message-id race (SNS notification arriving before S3 object is consistent) with bounded retry + structured error
- [ ] **SESI-06**: SES setup guide at `docs/inbound-ses.md` covers SNS topic configuration, IAM policy template, S3 bucket setup, optional-dep installation, and the SubscribeURL allowlist

### Inbound Test Helpers (ITEST)

API mirrors outbound `Mailglass.TestAssertions` (`lib/mailglass/test_assertions.ex`).

- [ ] **ITEST-01**: `MailglassInbound.TestAssertions` provides 4 matcher styles for `assert_inbound_received/1` (no-arg / keyword filter / function predicate / pattern match), mirroring the outbound `assert_delivered` family
- [ ] **ITEST-02**: Outcome-specific assertions: `assert_inbound_accepted/1`, `assert_inbound_rejected/1`, `assert_inbound_ignored/1`, `assert_inbound_bounced/1` keyed off the locked mailbox outcome atoms
- [ ] **ITEST-03**: Routing assertions: `assert_inbound_routed_to/2` (mailbox module match) and `assert_inbound_no_match/1` (no route matched)
- [ ] **ITEST-04**: Negative assertion `assert_no_inbound_received/0` (no inbound message received in the test process scope)
- [ ] **ITEST-05**: `MailglassInbound.MailboxCase` ExUnit case template sets up sandbox + pub_sub subscription + per-test fixtures, including the HI-01 snapshot/restore pattern for `:async_execution_impl` config (mirrors `Mailglass.MailerCase`)
- [ ] **ITEST-06**: `MailglassInbound.Test.Ingress` drives the real persist+route+execute write path with a single fake-provider seam (analogous to `Mailglass.Adapters.Fake.trigger_event/3` for outbound)
- [ ] **ITEST-07**: `MailglassInbound.Fixtures` builds canonical `%InboundMessage{}` and raw provider payloads (Postmark JSON, SendGrid form-encoded, Mailgun multipart, SES SNS) entirely from code — no `.eml` files on disk (avoids real-PII commits)

### Inbound Generators (IGEN)

All Igniter-based, mirroring `mix mailglass.gen.mailable`.

- [ ] **IGEN-01**: `mix mailglass.gen.mailbox <ModuleName>` scaffolds a mailbox module with the behaviour, a default callback, a route stub in the configured router, and an ExUnit test stub using `MailboxCase`
- [ ] **IGEN-02**: `mix mailglass.gen.inbound_router <ModuleName>` scaffolds a new inbound router module with the macro DSL and a sample route
- [ ] **IGEN-03**: `mix mailglass.gen.inbound_route <pattern> <MailboxModule>` adds a route to an existing inbound router with idempotent code modification
- [ ] **IGEN-04**: All generators support `--dry-run` (preview changes without applying), matching `mix mailglass.install` v0.5 hardening

### Inbound Admin LiveView (IADM)

Architecturally clones `mailglass_admin/lib/mailglass_admin/operator_live.ex` patterns.

- [ ] **IADM-01**: `MailglassAdmin.InboundLive` master/detail layout lists inbound records with URL-param filters (provider, mailbox outcome, time window, search), tenant-required gate (empty list when no tenant scope, never cross-tenant leak)
- [ ] **IADM-02**: Inbound detail view shows canonical `%InboundMessage{}`, the raw provider source from `InboundEvidence` (with PII handling), the matched mailbox + execution result, and a timeline of replay runs
- [ ] **IADM-03**: Replay modal (cloned from `operator/replay_modal.ex`) with destructive-action confirmation, tenant-bound by `operator/destructive_action.ex` pattern, no ambiguous-multi case (inbound replay target is the record itself, simpler than outbound)
- [ ] **IADM-04**: Routing trace card answers "why didn't this message match this mailbox?" by rendering a matcher diff against `__mailglass_inbound_routes__/0` reflection
- [ ] **IADM-05**: InboundLive subscribes to `MailglassAdmin.PubSub.Topics` for live updates from TELE-07 events
- [ ] **IADM-06**: Inbound admin honors the brand voice: error messages composed and specific (e.g., "Replay blocked: mailbox module not found"), no "Oops!" or generic copy
- [ ] **IADM-07**: Inbound surface is reachable from the admin nav, gated by the existing `MailglassAdmin.Auth` plug (no new auth surface required)

### Inbound Operator Runtime Tooling (IOPS)

- [ ] **IOPS-01**: `mix mailglass.inbound.doctor` runs DNS-free checks: routes compile and don't conflict, mailbox modules exist and implement the behaviour, provider signing keys are configured, MIME backend is available. Exit-coded for CI use. Mirrors `mix mail.doctor` pattern.
- [ ] **IOPS-02**: `mix mailglass.inbound.replay --record-id <id>` and `--since <iso8601>` and `--tenant <id>` provide CLI surface over `MailglassInbound.Internal.Replay.replay/2`, with destructive-action confirmation prompt unless `--yes`
- [ ] **IOPS-03**: `mix mailglass.inbound.prune` retains records 90d / evidence 30d / execution_runs 90d / replay_runs 30d (configurable), Oban-optional with mix-task fallback (mirrors `Mailglass.Webhook.Pruner`)
- [ ] **IOPS-04**: Ingress-stage post-verify rate limiter with three buckets (tenant, sender_domain, recipient), no `:transactional` bypass; configured via `Mailglass.Config`; emits telemetry on rate-trip without auto-suppressing
- [ ] **IOPS-05**: Suppression flag-only on inbound: messages from suppressed senders persist normally with a `:suppression_flagged` boolean on `InboundRecord`, surfaced in IADM-02; mailbox callbacks receive the flag in `%InboundMessage{}.metadata.suppression_flagged`. No auto-bounce. Documented rationale: preserves diagnostic signal for forwarders, complaint replies, and false-positive recovery.

### Inbound Documentation (IDOC)

- [ ] **IDOC-01**: Inbound install guide: `docs/inbound-install.md` covers `mix.exs` deps, repo configuration, router macro setup, first mailbox, first ingress, sandboxed test
- [ ] **IDOC-02**: Inbound testing guide: `docs/inbound-testing.md` covers `MailboxCase`, `TestAssertions`, `Test.Ingress`, fixtures, and idempotency property-test patterns
- [ ] **IDOC-03**: Inbound operator guide: `docs/inbound-operator.md` covers `inbound.doctor`, `inbound.replay`, `inbound.prune`, rate-limit configuration, suppression flag interpretation
- [ ] **IDOC-04**: Mailgun setup guide (MGUN-05) and SES setup guide (SESI-06) are complete, end-to-end walkthroughs with example payloads
- [ ] **IDOC-05**: Routing debug guide: `docs/inbound-routing-debug.md` covers the InboundLive routing-trace card workflow, common matcher failure modes, and CLI inspection patterns
- [ ] **IDOC-06**: All v1.2 inbound docs pass the existing doc-contract test (`mix mailglass.docs.check`) without warnings

### v1.0 Carry-Forward Debt Closeout (CLOSE)

Bundled into v1.2 Phase 51 rather than slipping further. None of these are adopter-facing, but RETROSPECTIVE.md's standing lesson is that compounding debt across milestones is the failure mode.

- [ ] **CLOSE-01**: Phase 35 Nyquist bookkeeping `wave_0_complete: false` is corrected; verification audit re-runs cleanly
- [ ] **CLOSE-02**: GitHub branch-protection automation: either repo-as-code via `gh api` script in `scripts/` with documented invocation, or explicit owner-runbook in `MAINTAINING.md` accepting the manual boundary
- [ ] **CLOSE-03**: Bare `mix test` citext-OID-cache race is fixed (likely a `Postgrex.Types` reload + sandbox checkout reorder) so `mix test` is green from a clean clone
- [ ] **CLOSE-04**: Non-blocking boundary warnings in support-summary and admin probe verification paths are resolved (no warnings on `mix boundary --no-checkout`)
- [ ] **CLOSE-05**: Phase 4 standard-depth review WR-01..WR-06 items are addressed or formally closed-no-action with rationale in `.planning/milestones/v1.0-MILESTONE-AUDIT.md`
- [ ] **CLOSE-06**: v1.0 live Hex publish closeout is coordinated (tarball published, branch-protection rule confirmed externally, MILESTONES.md updated)

---

## v1.3 Requirements (Deferred)

Tracked but deliberately deferred from v1.2 to keep the milestone supportable for a one-person maintainer (per D-22).

### Inbound Provider Expansion II

- **CFR-01..NN**: Cloudflare Email Routing inbound — pending stable first-party webhook contract
- **SMTP-01..NN**: `gen_smtp` SMTP listener inbound — different transport class than HTTP webhook; belongs in own milestone or `mailglass_relay` sibling package

### Inbound Conductor / Synthetic-Inbound Dev UI

- **CDUI-01..NN**: Conductor-style "create a fake inbound message in dev" LiveView surface; deferred to v1.2.1 to allow explicit security design pass (dev-only enforcement, never-in-prod gate, tenant-scoped synthetic stamps, raw payload safety)

### Auto-Suppression on Inbound Flooders

- **AUTO-01..NN**: Auto-add to suppression list when a sender exceeds inbound rate limits or matches abuse patterns; flag-only in v1.2 to preserve diagnostic signal until adopter behaviour data is available

### Inbound MX Reachability + HTTPS Reachability Probes in Doctor

- **MXC-01..NN**: `mailglass.inbound.doctor` extension to probe ingress endpoint HTTPS reachability + (when relay mode lands) MX records; deferred until `gen_smtp` listener exists

---

## Out of Scope (Permanent)

Inheriting all PROJECT.md Out-of-Scope items. v1.2-specific permanent exclusions added below.

| Feature | Reason |
|---------|--------|
| Synthetic-inbound compose form in v1.2 | Security design pass deferred to v1.2.1 — dev-only enforcement, tenant-scoped stamps, never-in-prod gate need explicit design before code |
| Cloudflare Email Routing in v1.2 | No first-party stable webhook contract; would invent a provider abstraction without a real provider behind it |
| `gen_smtp` SMTP listener in v1.2 | Different transport class entirely (TLS-terminated SMTP listener vs HTTP webhook plug); conflating would harm both surfaces |
| Auto-suppression on inbound senders | Destroys diagnostic signal (forwarders, complaint replies); flag-only is correct policy until adopter behaviour data exists. Matches ActionMailbox + Anymail |
| `:transactional` bypass on inbound rate limits | Inbound has no transactional/bulk/operational stream semantics; bypass would invert protection |
| `.eml` fixture files on disk | Invites real-PII commits; code-built fixtures (ITEST-07) achieve the same testing power |
| Inbound webhooks for providers without real adopter pull | We added the providers we know adopters use (Mailgun, SES, plus already-shipped Postmark + SendGrid). Other providers wait for adopter signal |

---

## Traceability

Populated by `gsd-roadmapper` agent on 2026-05-07 against `.planning/ROADMAP.md` (Phases 45-51). Every v1.2 REQ-ID maps to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TELE-01 | Phase 45 | Pending |
| TELE-02 | Phase 45 | Pending |
| TELE-03 | Phase 45 | Pending |
| TELE-04 | Phase 45 | Pending |
| TELE-05 | Phase 45 | Pending |
| TELE-06 | Phase 45 | Pending |
| TELE-07 | Phase 45 | Pending |
| TELE-08 | Phase 45 | Pending |
| MIME-01 | Phase 45 | Pending |
| MIME-02 | Phase 45 | Pending |
| MIME-03 | Phase 49 | Pending |
| MIME-04 | Phase 45 | Pending |
| MGUN-01 | Phase 46 | Pending |
| MGUN-02 | Phase 46 | Pending |
| MGUN-03 | Phase 46 | Pending |
| MGUN-04 | Phase 46 | Pending |
| MGUN-05 | Phase 50 | Pending |
| SESI-01 | Phase 46 | Pending |
| SESI-02 | Phase 46 | Pending |
| SESI-03 | Phase 46 | Pending |
| SESI-04 | Phase 46 | Pending |
| SESI-05 | Phase 46 | Pending |
| SESI-06 | Phase 50 | Pending |
| ITEST-01 | Phase 47 | Pending |
| ITEST-02 | Phase 47 | Pending |
| ITEST-03 | Phase 47 | Pending |
| ITEST-04 | Phase 47 | Pending |
| ITEST-05 | Phase 47 | Pending |
| ITEST-06 | Phase 47 | Pending |
| ITEST-07 | Phase 47 | Pending |
| IGEN-01 | Phase 47 | Pending |
| IGEN-02 | Phase 47 | Pending |
| IGEN-03 | Phase 47 | Pending |
| IGEN-04 | Phase 47 | Pending |
| IADM-01 | Phase 48 | Pending |
| IADM-02 | Phase 48 | Pending |
| IADM-03 | Phase 48 | Pending |
| IADM-04 | Phase 48 | Pending |
| IADM-05 | Phase 48 | Pending |
| IADM-06 | Phase 48 | Pending |
| IADM-07 | Phase 48 | Pending |
| IOPS-01 | Phase 49 | Pending |
| IOPS-02 | Phase 49 | Pending |
| IOPS-03 | Phase 49 | Pending |
| IOPS-04 | Phase 49 | Pending |
| IOPS-05 | Phase 49 | Pending |
| IDOC-01 | Phase 50 | Pending |
| IDOC-02 | Phase 50 | Pending |
| IDOC-03 | Phase 50 | Pending |
| IDOC-04 | Phase 50 | Pending |
| IDOC-05 | Phase 50 | Pending |
| IDOC-06 | Phase 50 | Pending |
| CLOSE-01 | Phase 51 | Pending |
| CLOSE-02 | Phase 51 | Pending |
| CLOSE-03 | Phase 51 | Pending |
| CLOSE-04 | Phase 51 | Pending |
| CLOSE-05 | Phase 51 | Pending |
| CLOSE-06 | Phase 51 | Pending |

**Coverage:**
- v1.2 requirements: **58 total** (TELE×8 + MIME×4 + MGUN×5 + SESI×6 + ITEST×7 + IGEN×4 + IADM×7 + IOPS×5 + IDOC×6 + CLOSE×6 = 58). Note: an earlier draft of this file stated "53 total" — that was a counting error in the source doc; actual checkbox count is 58.
- Mapped to phases: **58** ✓
- Unmapped: **0** ✓

**Per-phase distribution:**

| Phase | REQ-IDs | Count |
|-------|---------|-------|
| Phase 45: Inbound Telemetry + Idempotency Foundation | TELE-01..08, MIME-01, MIME-02, MIME-04 | 11 |
| Phase 46: Mailgun + SES Inbound Ingress | MGUN-01..04, SESI-01..05 | 9 |
| Phase 47: Inbound Test Helpers + Generators | ITEST-01..07, IGEN-01..04 | 11 |
| Phase 48: Inbound Admin LiveView | IADM-01..07 | 7 |
| Phase 49: Inbound Runtime Operator Tooling | IOPS-01..05, MIME-03 | 6 |
| Phase 50: Inbound Documentation Pass | IDOC-01..06, MGUN-05, SESI-06 | 8 |
| Phase 51: Stability Closeout | CLOSE-01..06 | 6 |
| **Total** | | **58** |

---

*Requirements defined: 2026-05-06*
*Last updated: 2026-05-07 — `gsd-roadmapper` populated traceability table for Phases 45-51; corrected category count from "53 total" to actual 58 total*
