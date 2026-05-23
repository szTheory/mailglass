# Roadmap: mailglass

**Granularity:** standard (config.json)

## Milestones

- ✅ **v0.1 Validation Release** — Phases 1-7 + 07.1 (shipped 2026-04-26) — see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** — Phases 8-13 (shipped 2026-04-28) — see [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** — Phases 14-21 (shipped 2026-04-30) — see [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Operator Confidence** — Phases 22-27 (shipped 2026-05-02) — see [milestones/v0.4-ROADMAP.md](milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 Adoption Hardening** — Phases 28-31 (shipped 2026-05-03) — see [milestones/v0.5-ROADMAP.md](milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 Production Maturity** — Phases 32-34 (shipped 2026-05-05) — see [milestones/v0.6-ROADMAP.md](milestones/v0.6-ROADMAP.md)
- ✅ **v1.0 Stability Lock** — Phases 35-38 (shipped 2026-05-06) — see [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Inbound Core Slice** — Phases 39-44 (shipped 2026-05-06) — see [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)
- 🚧 **v1.2 Inbound Production Confidence** — Phases 44.5, 45-50, 50.5, 51 (in progress, opened 2026-05-06; Phases 44.5 + 45 complete, **Phase 46 next**; v1.0 release ceremony bracketing v1.2 implementation)

## Phases

<details>
<summary>✅ v1.1 Inbound Core Slice (Phases 39-44) — SHIPPED 2026-05-06</summary>

- [x] Phase 39: Inbound Package Foundation (3/3 plans) — completed 2026-05-06
- [x] Phase 40: Postmark Ingress And Replayable Persistence (3/3 plans) — completed 2026-05-06
- [x] Phase 41: SendGrid Ingress And Mailbox Routing (3/3 plans) — completed 2026-05-06
- [x] Phase 42: Async Execution And Adopter Proof (3/3 plans) — completed 2026-05-06
- [x] Phase 43: Execution Verification Recovery (3/3 plans) — completed 2026-05-06
- [x] Phase 44: Async Adoption Closeout Reconciliation (2/2 plans) — completed 2026-05-06

Audit re-passed 2026-05-07 after Phase 43 + 44 closeout. Full archive at [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md).

</details>

### v1.2 Inbound Production Confidence

- [x] **Phase 44.5: v1.0/1.1 Release Ceremony** — Single linked-version cut: `mailglass` 0.3.2 → **1.0.0**, `mailglass_admin` 0.3.2 → **1.0.0**, `mailglass_inbound` first Hex publish at **0.1.0**. Bundles 4 unreleased milestones (v0.5/v0.6/v1.0/v1.1, 169 commits since v0.3.0 tag). Resolves CLOSE-06. — completed 2026-05-07
- [x] **Phase 45: Inbound Telemetry + Idempotency Foundation** — 4-level telemetry spans across all inbound stages, shared MIME module, and 1000-replay convergence proof (12 plans: 4 functional + 8 gap-closure across 2 rounds) — completed 2026-05-23
- [ ] **Phase 46: Mailgun + SES Inbound Ingress** — Lift outbound verifiers into inbound; ship Mailgun (HMAC) and SES (SNS X.509 + S3 fetch) provider plugs (3 plans, 2 waves)
- [ ] **Phase 47: Inbound Test Helpers + Generators** — `TestAssertions`, `MailboxCase`, `Test.Ingress`, code-built fixtures, and 3 Igniter generators
- [ ] **Phase 48: Inbound Admin LiveView** — `InboundLive` master/detail with evidence/timeline cards, replay modal, routing-trace card
- [ ] **Phase 49: Inbound Runtime Operator Tooling** — `mix mailglass.inbound.{doctor,replay,prune}`, ingress rate limit, suppression flag-only
- [ ] **Phase 50: Inbound Documentation Pass** — Install / testing / operator / Mailgun + SES setup / routing-debug guides
- [ ] **Phase 50.5: v1.2 Release Ceremony** — Linked-version cut: `mailglass` 1.0.0 → **1.2.0**, `mailglass_admin` 1.0.0 → **1.2.0**, `mailglass_inbound` 0.1.0 → **0.2.0** (inbound stays on 0.x version line until Conductor + relay providers land). Ships all v1.2 inbound work to adopters.
- [ ] **Phase 51: Stability Closeout** — v1.0 carry-forward debt: Phase 35 Nyquist (CLOSE-01), branch-protection automation (CLOSE-02), citext race (CLOSE-03), boundary warnings (CLOSE-04), WR-01..06 (CLOSE-05). CLOSE-06 resolved by Phase 44.5.

## Phase Details

### Phase 44.5: v1.0/1.1 Release Ceremony

**Goal**: Ship four milestones of unreleased work to Hex.pm before starting v1.2 implementation, so adopters get the v0.5 + v0.6 + v1.0 + v1.1 value (`TestAssertions`, generators, `RateLimiter`, replay/reconcile, support summary, stability lock, compatibility promise, `mailglass_inbound` foundation) and v1.2 implementation lands against a fresh release base instead of compounding the gap further.
**Depends on**: Phase 44 (v1.1 Inbound Core Slice complete)
**Requirements**: CLOSE-06 (pulled forward from Phase 51)
**Success Criteria** (what must be TRUE):

  1. `mailglass` and `mailglass_admin` are published to Hex.pm at **1.0.0** via Release Please linked-versions PR; `mailglass_inbound` is published at **0.1.0** as its first Hex appearance.
  2. CHANGELOG entries for all three packages document the bundled v0.5 + v0.6 + v1.0 + v1.1 milestone work with REQ-ID references; the upgrade path doc (`docs/upgrade-from-0.x.md`) is verified end-to-end against a sandbox app.
  3. The `v1.0.0` git tag is pushed; the existing release-rehearsal artifacts from v1.0 milestone (Phase 38) are converted from rehearsal to live; the protected GitHub Environment publish flow is exercised for real (HEX_API_KEY + reviewer approval).
  4. `mix hex.info mailglass`, `mix hex.info mailglass_admin`, and `mix hex.info mailglass_inbound` all return 1.0.0 / 1.0.0 / 0.1.0 respectively; PROJECT.md "Current State" is updated to reflect the live publish; `MILESTONES.md` v1.0 entry adds the live-publish date.
  5. GitHub branch-protection rule is verified externally (closes the v1.0 carry-forward "manual GitHub branch-protection verification" item, partially fulfilling CLOSE-02 — the automation work in Phase 51 supplements this with a `gh api` script).

**Plans**: TBD
**UI hint**: no

**Hardest sub-tasks:**

- Release Please linked-versions config currently lock-steps `mailglass` + `mailglass_admin` at the same version (0.3.2). Adding `mailglass_inbound` at a separate 0.1.0 version line requires confirming the linked-versions plugin allows mixed major-version sibling packages — read `release-please-config.json` carefully and validate via `release-please --dry-run` before tagging.
- The `mailglass_admin/mix.exs` "literal pin" pattern (the `{:mailglass, "== 0.1.0"}` literal that comments warn is not `@version`-driven) needs to be bumped manually to `"== 1.0.0"` and verified the linked-versions plugin's sed step handles it correctly. This is the load-bearing constraint that v0.1's release engineering surfaced.
- The first-time `mailglass_inbound` Hex publish requires a separate `HEX_PACKAGE` registration step (or transitively via `--organization`) and an explicit `description` + `links` block in `mailglass_inbound/mix.exs`. Don't assume it inherits from the parent.

### Phase 45: Inbound Telemetry + Idempotency Foundation

**Goal**: Inbound emits 4-level `:telemetry` spans across every stage (ingress, route, execute, persist), the shared MIME parser is in place, and a StreamData property proves 1000-replay convergence — making the rest of v1.2 observable, debuggable, and idempotent by construction.
**Depends on**: Phase 44 (v1.1 inbound foundation)
**Requirements**: TELE-01, TELE-02, TELE-03, TELE-04, TELE-05, TELE-06, TELE-07, TELE-08, MIME-01, MIME-02, MIME-04
**Success Criteria** (what must be TRUE):

  1. Operator attaches a `:telemetry` handler at `[:mailglass_inbound, :ingress, :request, :stop]` and observes start/stop/exception spans on every ingress request, with PII-free metadata (provider, tenant_id, status, latency, byte_size — never recipient/sender/body/headers).
  2. Operator attaches handlers at `[:mailglass_inbound, :route, :match, *]`, `[:execution, :run, *]`, and `[:persist, :record, *]` and observes coherent span coverage across the entire inbound pipeline; a deliberately-raising handler does not break business logic.
  3. `mix credo` passes the `NoPIIInTelemetry` check across both `mailglass/` and `mailglass_inbound/` (check extended to cover the inbound package).
  4. Admin LiveView (Phase 48) can subscribe to inbound updates via `MailglassAdmin.PubSub.Topics` because TELE-07 surfaces telemetry events into the existing topic registry.
  5. StreamData property test replays an arbitrary inbound payload 1000× through the real persist+route+execute path and asserts exactly one `InboundRecord` + one fresh `ExecutionRun`, mirroring the outbound v0.1 webhook ingest convergence proof.
  6. `MailglassInbound.MIME` parses canonical RFC 5322 bodies into a stable internal representation; malformed payloads return structured `Mailglass.Error{type: :inbound_mime_invalid}` and never raise; backend gating goes through `Mailglass.OptionalDeps.GenSmtp` with a documented degraded fallback.

**Plans**: TBD
**UI hint**: no

**Hardest sub-tasks:**

- TELE-08 1000-replay convergence property must drive the *real* persist+route+execute write path (not a mock) without breaking the post-commit-execution invariant. Mirror the outbound `Mailglass.WebhookIngestion.Convergence` proof structurally.
- TELE-07 PubSub topic wiring must add exactly one new topic (`inbound_record_inserted/1`, per-tenant) — no topic explosion. Existing `MailglassAdmin.PubSub.Topics` shape is the contract.
- Extending `NoPIIInTelemetry` Credo check to `mailglass_inbound/` requires verifying the boundary check correctly cross-package classifies inbound modules.

### Phase 46: Mailgun + SES Inbound Ingress

**Goal**: Adopters running Mailgun or SES inbound webhooks can install Mailglass and have authentic provider payloads verified, normalized into the canonical `%InboundMessage{}`, and persisted with raw evidence — without Mailglass inventing new cryptography (everything lifts from the outbound webhook verifiers shipped at `lib/mailglass/webhook/providers/{mailgun,ses}.ex`).
**Depends on**: Phase 45 (telemetry spans + MIME module)
**Requirements**: MGUN-01, MGUN-02, MGUN-03, MGUN-04, SESI-01, SESI-02, SESI-03, SESI-04, SESI-05
**Success Criteria** (what must be TRUE):

  1. POSTing an authentic Mailgun multipart payload to `/inbound/mailgun` verifies HMAC-SHA256 over `timestamp+token`, normalizes into `%InboundMessage{}`, persists raw provider source to `inbound_evidence`, and dispatches the matched mailbox; a forged payload raises `MailglassInbound.SignatureError` with no recovery.
  2. Replayed Mailgun payloads (same `signature.token`) are dropped at the existing `Mailglass.Webhook.Providers.MailgunReplayCache` ETS table — no second `InboundRecord` is created, and the existing replay-cache GenServer is reused (not duplicated).
  3. POSTing an authentic SES SNS notification to `/inbound/ses` verifies the X.509 signature via `Mailglass.Webhook.Providers.SES.{CertCache, TrustPolicy}` (URL allowlist enforced); `SubscriptionConfirmation` notifications auto-confirm only when SubscribeURL passes `TrustPolicy`; forged or hijacked URLs are rejected.
  4. SES `Action: S3` notifications fetch the MIME body via the `MailglassInbound.S3Fetcher` behaviour; `MailglassInbound.S3Fetcher.Fake` ships in core (test default), and `MailglassInbound.S3Fetcher.ExAwsS3` ships behind the new `Mailglass.OptionalDeps.ExAwsS3` gateway; SNS-arriving-before-S3-consistency races recover with bounded retry + structured error.
  5. `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` allowlist accepts `:mailgun` and `:ses` alongside the existing `:postmark` and `:sendgrid`; verifier dispatch is one switch, not two parallel pipelines.

**Plans**: 3 plans (2 waves)

- [x] 46-01-PLAN.md — Shared foundation: net-new SignatureError + S3FetchError, S3Fetcher behaviour, widened Provider callback, widened Plug (4-provider allowlist + 3-variant result case + dual rescue), core SES verify_envelope!/2 seam (MGUN-04, SESI-03)
- [ ] 46-02-PLAN.md — Mailgun provider: flat-field HMAC + replay no-op + multipart normalize + Message-Id/fingerprint dedupe + fingerprint migration (MGUN-01, MGUN-02, MGUN-03)
- [ ] 46-03-PLAN.md — SES provider + S3: SNS X.509 via core seam + control-plane no-op + S3Fetcher Fake/ExAwsS3 + OptionalDeps.ExAwsS3 gateway + bounded retry (SESI-01, SESI-02, SESI-04, SESI-05)

**UI hint**: no

**Hardest sub-tasks:**

- SES S3 fetcher race: SNS can deliver the notification before the S3 PutObject is read-after-write consistent. Bounded retry (3 attempts, exponential backoff) + return `Mailglass.Error{type: :inbound_s3_consistency_lag}` rather than crashing the ingress plug.
- Reusing `MailglassWebhook.Providers.SES.CertCache` from `mailglass` core inside `mailglass_inbound` requires confirming the cross-package `alias` works under the boundary check (CLAUDE.md "Things Not To Do" #8 — check we are not registering a second singleton).
- New `Mailglass.OptionalDeps.ExAwsS3` gateway must mirror the existing `Mailglass.OptionalDeps.GenSmtp` shape exactly (`@compile {:no_warn_undefined, ...}` + `available?/0` + degraded fallback) so the optional-deps audit passes.

### Phase 47: Inbound Test Helpers + Generators

**Goal**: An adopter writing their first mailbox can `use MailglassInbound.MailboxCase`, call `assert_inbound_accepted/1` (or one of 4 matcher styles), drive the real persist+route+execute path with `MailglassInbound.Test.Ingress`, build provider payloads in code (no `.eml` files on disk), and scaffold the mailbox/router/route via Igniter generators — with full DX parity to outbound's `Mailglass.MailerCase` + `Mailglass.TestAssertions` + `mix mailglass.gen.mailable`.
**Depends on**: Phase 45 (telemetry + MIME)
**Requirements**: ITEST-01, ITEST-02, ITEST-03, ITEST-04, ITEST-05, ITEST-06, ITEST-07, IGEN-01, IGEN-02, IGEN-03, IGEN-04
**Success Criteria** (what must be TRUE):

  1. Adopter writes `assert_inbound_received(to: "support@example.test")` (or the no-arg / function-predicate / pattern-match variants) and the assertion fires correctly against inbound messages dispatched in the test process scope; `assert_no_inbound_received/0` refutes correctly.
  2. Outcome-specific assertions `assert_inbound_{accepted,rejected,ignored,bounced}/1` key off the locked mailbox outcome atoms from `mailbox.ex:22`; routing assertions `assert_inbound_routed_to/2` and `assert_inbound_no_match/1` work against `__mailglass_inbound_routes__/0` reflection.
  3. `use MailglassInbound.MailboxCase` sets up sandbox + PubSub subscription + frozen clock + per-test fixtures and includes the HI-01 snapshot/restore pattern for `:async_execution_impl` config (lifted from outbound `MailerCase` lines 120-204) — the `set_mailglass_inbound_global` race is structurally prevented.
  4. `MailglassInbound.Test.Ingress.receive_inbound/2` and `receive_provider_payload/3` drive the production write path end-to-end (a single fake-provider seam, mirroring outbound `Adapters.Fake.trigger_event/3`); `MailglassInbound.Fixtures` builds canonical Postmark JSON / SendGrid form / Mailgun multipart / SES SNS payloads entirely from code (no `.eml` files in `test/fixtures/`).
  5. `mix mailglass.gen.mailbox MyApp.Inbound.Support` scaffolds the mailbox module, a route stub in the configured router, and an ExUnit test stub using `MailboxCase`; `mix mailglass.gen.inbound_router` and `mix mailglass.gen.inbound_route` scaffold/extend routers idempotently; all three support `--dry-run` matching `mix mailglass.install` v0.5 hardening.

**Plans**: TBD
**UI hint**: no

**Hardest sub-tasks:**

- HI-01 snapshot/restore for `:async_execution_impl`: the outbound bug pattern (mailer_case.ex:120-204) is the predictable failure mode if we copy without snapshotting. Tests that flip async impl mid-run leak between cases otherwise.
- `mix mailglass.gen.inbound_route` adds a route to an existing router via Igniter source-edit (not regeneration). Idempotent code modification with multi-clause matchers is the trickiest of the three generators.
- `MailglassInbound.Fixtures.build_ses_sns_payload/1` must produce a valid X.509-signed SNS notification, which means generating a self-signed cert in the test fixture path that `SES.CertCache.Fake` accepts. Without this, ITEST-07 SES coverage is shallow.

### Phase 48: Inbound Admin LiveView

**Goal**: An operator opens `/admin/inbound` in `mailglass_admin` and gets the same observability they already have for outbound: a tenant-scoped master/detail of inbound records with provider/mailbox/outcome filters, an evidence card showing canonical message + raw provider source, a timeline of execution runs (fresh + replay), a routing-trace card answering "why didn't this match?", a confirmation-gated replay modal, and live updates via PubSub.
**Depends on**: Phase 45 (telemetry + PubSub topics)
**Requirements**: IADM-01, IADM-02, IADM-03, IADM-04, IADM-05, IADM-06, IADM-07
**Success Criteria** (what must be TRUE):

  1. Operator visits `/admin/inbound` (existing `MailglassAdmin.Auth` plug gates access — no new auth surface), selects a tenant, and sees a paginated list of inbound records filterable by provider, mailbox, outcome, time window, and search; an empty/missing tenant returns `[]` (mirroring `OperatorLive.load_deliveries/1` line 338 — never cross-tenant leak).
  2. Selecting a record shows the canonical `%InboundMessage{}`, the raw provider source from `InboundEvidence` (PII-redacted by default with `:reveal_raw` capability gate), the matched mailbox + execution outcome, and a timeline of all `ExecutionRun` rows (fresh + replay) for the record.
  3. Operator clicks "Replay" → a confirmation modal (cloned from `operator/replay_modal.ex`) tenant-bound by `operator/destructive_action.ex` enforces the `:replay_inbound` capability; on confirm, a new `ExecutionRun` row appears with `source: :replay` (no UPDATE; append-only is preserved).
  4. For a `:no_match` execution row, the routing-trace card renders a matcher diff against `__mailglass_inbound_routes__/0` showing every route that was tried and which clause failed — answering "why didn't this match `SupportMailbox`?" without `iex` archaeology.
  5. New inbound records appear in the list card without manual refresh because `InboundLive` subscribes to `MailglassAdmin.PubSub.Topics.inbound_record_inserted/1` (per-tenant); error messages are composed and specific (no "Oops!"), honoring the brand voice.

**Plans**: TBD
**UI hint**: yes

**Hardest sub-tasks:**

- Routing-trace card matcher diff: rendering `__mailglass_inbound_routes__/0` reflection against the actual `InboundMessage` and showing per-clause pass/fail is the most novel UI work — no direct outbound analog. Reuse `Router.Matcher` internals carefully so the diff matches actual matcher behaviour.
- `:reveal_raw` capability gate must hook into the existing `MailglassAdmin.Auth.authorize/3` adapter seam without inventing new auth surface; the new capability is configured by the adopter (D-17-shaped — convention not magic).
- Tenant-required-or-empty contract (mirroring outbound line 338) is a structural correctness invariant; adding a Credo check that no `MailglassAdmin.Inbound*` module queries inbound tables without `Mailglass.Tenancy.scope/2` would prevent regressions.

### Phase 49: Inbound Runtime Operator Tooling

**Goal**: An operator running mailglass in production has the same operational toolbox for inbound that they have for outbound: `mix mailglass.inbound.doctor` validates configuration before deploy, `mix mailglass.inbound.replay` re-runs failed/no-match records from CLI with destructive-action confirmation, `mix mailglass.inbound.prune` enforces retention policy, ingress rate limiting deflects DoS at three buckets (tenant, sender_domain, recipient), and suppressed senders are flagged-not-bounced to preserve diagnostic signal.
**Depends on**: Phase 45 (telemetry hooks for rate-limit/prune events), Phase 46 (provider verifiers for doctor's signature-config check)
**Requirements**: IOPS-01, IOPS-02, IOPS-03, IOPS-04, IOPS-05, MIME-03
**Success Criteria** (what must be TRUE):

  1. `mix mailglass.inbound.doctor` runs DNS-free, exits 0 when routes compile + don't conflict + mailboxes exist + provider signing keys are configured + MIME backend is available (MIME-03), exits non-zero with structured human + JSON output otherwise; usable in CI as a pre-deploy gate.
  2. `mix mailglass.inbound.replay --record-id <uuid>` (or `--since <iso8601>` or `--tenant <id>`) wraps `MailglassInbound.Internal.Replay.replay/2` with destructive-action confirmation prompt unless `--yes`; replay rows append to `execution_runs` with `source: :replay` (no UPDATE).
  3. `mix mailglass.inbound.prune` enforces retention defaults (records 90d, evidence 30d, execution_runs 90d, replay_runs 30d, all configurable, batched LIMIT 1000), Oban-cron-when-available with mix-task fallback, mirroring `Mailglass.Webhook.Pruner` exactly.
  4. Inbound ingress under load trips the post-verify rate limiter at three buckets (tenant 1000/min, sender_domain 200/min, recipient 500/min — defaults configurable via `Mailglass.Config`); over-limit responses are HTTP 429 with `Retry-After`; rate-trip emits `[:mailglass_inbound, :rate_limit, :stop]` telemetry; no `:transactional` bypass (inbound has no stream semantics); no auto-suppression on rate-trip.
  5. A message from a suppressed sender persists normally with `:suppression_flagged: true` on the `InboundRecord`, surfaces in IADM-02, and reaches mailbox callbacks through `%InboundMessage{}.metadata.suppression_flagged` — adopter's mailbox decides whether to `:reject` or process; no auto-bounce (preserves diagnostic signal for forwarders, complaint replies, false-positive recovery).

**Plans**: TBD
**UI hint**: no

**Hardest sub-tasks:**

- `mix mailglass.inbound.doctor` route-conflict check uses `Router.Matcher` internals to detect overlapping route patterns (e.g., two routes that would both match `support@example.com`); reporting which routes conflict with line numbers requires reflection, not just compile.
- Three-bucket rate limiting must extend `Mailglass.RateLimiter`'s multi-bucket pattern without leaking PII into bucket keys (sender_domain is OK; full sender address is NOT — see `rate_limiter.ex:43` PII rule).
- `mix mailglass.inbound.prune` cascade-deletes `inbound_evidence` when `inbound_records` go away; batching by `LIMIT 1000` with explicit advisory locks prevents replication lag spikes (mirroring `Webhook.Pruner` exactly is the safest path).

### Phase 50: Inbound Documentation Pass

**Goal**: An adopter coming to `mailglass_inbound` for the first time can read one canonical install guide → one testing guide → one operator guide → one provider setup guide (Mailgun or SES) → one routing-debug guide and have the inbound package running in production with confidence — closing the documentation gap that gates "use it confidently in their app."
**Depends on**: Phase 46 (Mailgun + SES code in place to document), Phase 47 (test helpers/generators to document), Phase 48 (admin LiveView to reference in routing-debug guide), Phase 49 (operator tooling to document)
**Requirements**: IDOC-01, IDOC-02, IDOC-03, IDOC-04, IDOC-05, IDOC-06, MGUN-05, SESI-06
**Success Criteria** (what must be TRUE):

  1. `docs/inbound-install.md` walks an adopter from `{:mailglass_inbound, "~> 1.2"}` through repo configuration, router macro setup, first mailbox, first ingress endpoint, and a sandboxed test that proves end-to-end wiring.
  2. `docs/inbound-testing.md` covers `MailglassInbound.MailboxCase`, all 4 `TestAssertions` matcher styles + outcome + routing assertions, `Test.Ingress` usage, `Fixtures` patterns (no `.eml` on disk), and the StreamData idempotency property pattern from TELE-08.
  3. `docs/inbound-operator.md` covers `mix mailglass.inbound.{doctor,replay,prune}`, retention policy, rate-limit configuration (3 buckets), and suppression-flag interpretation (why flag-only, not auto-bounce).
  4. `docs/inbound-mailgun.md` (MGUN-05) and `docs/inbound-ses.md` (SESI-06) are end-to-end provider walkthroughs with example payloads — Mailgun covers HTTP route URL / API key / signing-key rotation / verification; SES covers SNS topic / IAM template / S3 bucket / `:ex_aws_s3` install / SubscribeURL allowlist.
  5. `docs/inbound-routing-debug.md` covers the InboundLive routing-trace card workflow, common matcher failure modes (header AND-semantics, regex vs exact, recipient envelope vs To:), and CLI inspection patterns; all v1.2 inbound docs pass `mix mailglass.docs.check` with zero warnings (IDOC-06).

**Plans**: TBD
**UI hint**: no

**Hardest sub-tasks:**

- SES setup guide (SESI-06) is the longest and highest-stakes — the IAM policy template, the SubscribeURL allowlist explanation, and the optional `:ex_aws_s3` installation steps need to be copy-pasteable but also accurate against AWS console drift. Test the guide against a real AWS account before merge.
- Routing-debug guide (IDOC-05) requires a worked example of a real "why didn't this match?" debugging session — needs to ship with at least one fully-narrated trace from initial confusion to root cause.
- Doc-contract test (IDOC-06 via `mix mailglass.docs.check`) is strict; every docref + module link must resolve. Schedule the docs-check pass after all other code lands so churn is minimized.

### Phase 50.5: v1.2 Release Ceremony

**Goal**: Ship v1.2 inbound production confidence work to Hex.pm so adopters can `{:mailglass, "~> 1.2"}` and pick up Mailgun + SES inbound, admin LiveView for inbound, test helpers, and operator tooling — closing the v1.2 milestone with a published release rather than a planning label.
**Depends on**: Phase 50 (docs done) — code from Phases 45-49 is in place; this phase only ships it.
**Requirements**: (no new REQ-IDs — release-engineering ceremony, not feature work)
**Success Criteria** (what must be TRUE):

  1. `mailglass` 1.0.0 → **1.2.0**, `mailglass_admin` 1.0.0 → **1.2.0**, `mailglass_inbound` 0.1.0 → **0.2.0** all published to Hex.pm via Release Please linked-versions PR.
  2. CHANGELOG entries document v1.2 work by REQ-ID category (TELE, MIME, MGUN, SESI, ITEST, IGEN, IADM, IOPS, IDOC) with adopter-facing notes for breaking-or-additive changes.
  3. `mailglass_inbound` 0.2.0 release notes explicitly call out: still 0.x because Conductor-style dev UI + Mailgun/SES inbound + relay providers are the pre-1.0 expansion target; semver shape is documented in upgrade guide.
  4. `mix hex.info` confirms all three packages live; `v1.2.0` git tag pushed; release-engineering verification (the live publish flow exercised in Phase 44.5) used again — no new ceremony surface.
  5. PROJECT.md "Current State" updated; MILESTONES.md v1.2 entry adds live-publish date.

**Plans**: TBD
**UI hint**: no

**Hardest sub-tasks:**

- Coordinating `mailglass_inbound` 0.x version line with `mailglass` 1.x line through the linked-versions plugin (already exercised in Phase 44.5 — should be a repeat, not a discovery).
- CHANGELOG hygiene across 9 v1.2 REQ categories — keep adopter-facing notes scoped to behavioural changes, not internal refactors.

### Phase 51: Stability Closeout

**Goal**: Every v1.0 carry-forward debt item is closed (or formally accepted with rationale) so the v1.2 milestone audit has zero compounding-debt findings — honoring RETROSPECTIVE.md's standing lesson that compounding debt across milestones is the failure mode. CLOSE-06 (v1.0 publish closeout) is resolved by Phase 44.5; CLOSE-02 partial branch-protection verification also resolved by Phase 44.5, with the `gh api` automation work landing here.
**Depends on**: None (parallel-safe with all v1.2 inbound phases — no overlap with `mailglass_inbound/`)
**Requirements**: CLOSE-01, CLOSE-02, CLOSE-03, CLOSE-04, CLOSE-05
**Success Criteria** (what must be TRUE):

  1. `mailglass_admin/priv/audit/phases/35.json` records `wave_0_complete: true` after Phase 35 verification re-runs cleanly (CLOSE-01); verification audit is rerun and committed.
  2. `mix test` runs green from a clean clone — the bare `mix test` citext-OID-cache race is fixed (likely a `Postgrex.Types` reload + sandbox checkout reorder); CI has a smoke job proving green-from-clean (CLOSE-03).
  3. `mix boundary --no-checkout` reports zero warnings; the support-summary and admin probe boundary warnings are resolved by either correcting boundary classifications or formally accepting them with documented rationale (CLOSE-04).
  4. `scripts/verify-branch-protection.sh` (using `gh api`) reports pass against the live repo and runs in CI as a non-blocking advisory job (CLOSE-02 automation supplements the external verification done in Phase 44.5); Phase 4 standard-depth review WR-01..WR-06 items are individually addressed or formally closed-no-action with rationale appended to `.planning/milestones/v1.0-MILESTONE-AUDIT.md` (CLOSE-05).

**Plans**: TBD
**UI hint**: no

**Hardest sub-tasks:**

- CLOSE-03 citext-OID-cache race: requires reproducing the race deterministically before fixing it. The `Postgrex.Types` reload + sandbox checkout reorder is a hypothesis, not a confirmed fix; first plan should be diagnostic.
- CLOSE-02 `gh api` repo-as-code script needs to assert against the actual ruleset (required checks, required reviewers, dismissal policy) — keep it idempotent so it can run as a CI job without false alarms.

## Backlog

### Phase 999.1: Human-Readable Code Comments + GSD Artifact Cleanup (BACKLOG)

**Goal:** Reduce distracting internal planning references such as `D-20`, phase-plan IDs, and similar GSD artifacting in source comments so the code reads cleanly for humans while preserving the intent behind important architectural notes
**Requirements:** TBD
**Plans:** 1/3 plans executed

Plans:

- [ ] TBD (promote with $gsd-review-backlog when ready)

### Phase 999.2: Shift-Left Email Screenshot + Responsive Preview Workflow (BACKLOG)

**Goal:** Make it easy at any time to see realistic rendered example emails across themes and mobile/responsive layouts, ideally through an idiomatic low-friction workflow such as a mix task, preview pipeline, or CI-generated screenshots
**Requirements:** TBD
**Plans:** 0 plans

Plans:

- [ ] TBD (promote with $gsd-review-backlog when ready)

## Progress (v1.2 Inbound Production Confidence)

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| **44.5. v1.0/1.1 Release Ceremony** | 5/5 | ✅ Complete | 2026-05-07 |
| 45. Inbound Telemetry + Idempotency Foundation | 12/12 | ✅ Complete | 2026-05-23 |
| 46. Mailgun + SES Inbound Ingress | 1/3 | In Progress|  |
| 47. Inbound Test Helpers + Generators | 0/TBD | Not started | — |
| 48. Inbound Admin LiveView | 0/TBD | Not started | — |
| 49. Inbound Runtime Operator Tooling | 0/TBD | Not started | — |
| 50. Inbound Documentation Pass | 0/TBD | Not started | — |
| **50.5. v1.2 Release Ceremony** | 0/TBD | Not started | — |
| 51. Stability Closeout | 0/TBD | Not started | — |

**Estimated total plans:** ~20-24 (SYNTHESIS.md ~18-22 inbound + 2 release ceremonies). Plan counts will be set during `/gsd-plan-phase <N>` for each phase.

**Release-cadence rule (added 2026-05-06):** Each milestone closes with a release ceremony (Phase X.5 by convention). Don't start the next milestone implementation while previous-milestone work is unreleased. The 4-milestone-deep gap between v0.3.2 and 1.0.0 is the failure mode this rule prevents.
