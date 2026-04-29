# Project Roadmap

## Phases

- [ ] **Phase 14: Resend Webhook Provider & Core Ingest** - System securely ingests and normalizes Resend webhooks through a new provider behavior
- [x] **Phase 15: Mailgun Webhook Provider** - System securely ingests and normalizes Mailgun webhooks while preventing replay attacks (completed 2026-04-29)
- [x] **Phase 16: SES Webhook Provider & SNS Cache** - System securely ingests and normalizes AWS SES (via SNS) webhooks with automatic subscription handling and certificate caching (completed 2026-04-29)
- [ ] **Phase 17: Unblock & Verify Resend** - Full test suite passes clean and Resend provider is confirmed production-ready
- [ ] **Phase 18: Ship v0.3.0** - v0.3.0 published to Hex.pm with complete CHANGELOG and updated provider guides

## Phase Details

### Phase 14: Resend Webhook Provider & Core Ingest
**Goal**: System securely ingests and normalizes Resend webhooks through a new provider behavior
**Depends on**: Phase 13
**Requirements**: RESEND-01, RESEND-02
**Success Criteria** (what must be TRUE):
  1. Valid Resend Svix webhook signatures are accepted by the webhook plug
  2. Invalid Resend Svix webhook signatures are rejected
  3. Resend events (delivered, bounced, complained) are mapped to the internal normalized taxonomy
  4. Raw body caching plug successfully preserves the body for Svix validation without breaking subsequent JSON parsers
**Plans**: 1 plan

Plans:
- [x] 14-01-PLAN.md — Implement Resend Provider and Tests

### Phase 15: Mailgun Webhook Provider
**Goal**: System securely ingests and normalizes Mailgun webhooks while preventing replay attacks
**Depends on**: Phase 14
**Requirements**: MAILGUN-01, MAILGUN-02, MAILGUN-03
**Success Criteria** (what must be TRUE):
  1. Valid Mailgun HMAC-SHA256 signatures are accepted
  2. Invalid or expired Mailgun signatures are rejected
  3. Replayed Mailgun tokens are rejected via token caching
  4. Mailgun events are correctly mapped to the internal normalized taxonomy
**Plans**: 4 plans

Plans:
- [x] 15-01-PLAN.md — Define the replay-aware Mailgun contract and ETS cache
- [x] 15-02-PLAN.md — Implement the Mailgun provider, fixtures, and provider tests
- [x] 15-03-PLAN.md — Wire Mailgun into plug, router, config, and runtime tests
- [x] 15-04-PLAN.md — Update installer snippets, webhook docs, and goldens for Mailgun opt-in

### Phase 16: SES Webhook Provider & SNS Cache
**Goal**: System securely ingests and normalizes AWS SES (via SNS) webhooks with automatic subscription handling and certificate caching
**Depends on**: Phase 15
**Requirements**: SES-01, SES-02, SES-03, SES-04, SES-05
**Success Criteria** (what must be TRUE):
  1. System successfully parses `text/plain` SES SNS payloads
  2. System automatically confirms SNS subscriptions by fetching the SubscribeURL
  3. Valid SES RSA signatures are accepted using X.509 certificates fetched from AWS
  4. X.509 certificates are cached in `:ets` preventing repeated network calls per webhook
  5. SES events wrapped inside the SNS message are mapped to the internal normalized taxonomy
**Plans**: 4 plans

Plans:
- [x] 16-01-PLAN.md — Wave 0: test scaffolding, JSON fixtures, WebhookFixtures RSA helpers
- [x] 16-02-PLAN.md — Wave 1: TrustPolicy SSRF guard + ETS CertCache OTP trio
- [x] 16-03-PLAN.md — Wave 2: SES provider verify!/3 + SNS control-plane handling
- [x] 16-04-PLAN.md — Wave 3: normalize/2 + plug/router/application wiring + webhooks guide

### Phase 17: Unblock & Verify Resend
**Goal**: Full test suite passes clean and Resend provider is confirmed production-ready
**Depends on**: Phase 16
**Requirements**: RESEND-01, RESEND-02
**Success Criteria** (what must be TRUE):
  1. `mix test` passes clean with no `--only` scoping or test exclusions
  2. Valid Resend Svix signatures are accepted by the webhook plug
  3. Invalid Resend Svix signatures are rejected with `Mailglass.SignatureError`
  4. Resend events (delivered, bounced, complained) map to the correct Anymail taxonomy atoms
  5. Phase 14 marked complete in ROADMAP.md
**Plans**: 2 plans

Plans:
- [ ] 17-01-PLAN.md — Plug wiring, test fix, and WebhookCase :resend infrastructure
- [ ] 17-02-PLAN.md — Resend plug integration tests, fixture, and Phase 14 completion

### Phase 18: Ship v0.3.0
**Goal**: v0.3.0 published to Hex.pm with complete CHANGELOG and updated provider guides
**Depends on**: Phase 17
**Requirements**: DELIV-04
**Success Criteria** (what must be TRUE):
  1. `https://hex.pm/packages/mailglass/0.3.0` is live and installable
  2. `https://hex.pm/packages/mailglass_admin/0.3.0` is live and installable
  3. webhooks.md documents Resend configuration including `CachingBodyReader` setup
  4. CHANGELOG.md has a complete v0.3 section covering Mailgun, SES, and Resend providers
  5. DELIV-04 marked complete in PROJECT.md
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 14. Resend Webhook Provider & Core Ingest | 1/1 | Verification blocked (implementation complete) | - |
| 15. Mailgun Webhook Provider | 4/4 | Complete    | 2026-04-29 |
| 16. SES Webhook Provider & SNS Cache | 4/4 | Complete    | 2026-04-29 |
| 17. Unblock & Verify Resend | 0/2 | Not started | - |
| 18. Ship v0.3.0 | 0/2 | Not started | - |
