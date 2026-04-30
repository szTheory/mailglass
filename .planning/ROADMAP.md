# Project Roadmap

## Phases

- [ ] **Phase 14: Resend Webhook Provider & Core Ingest** - System securely ingests and normalizes Resend webhooks through a new provider behavior
- [x] **Phase 15: Mailgun Webhook Provider** - System securely ingests and normalizes Mailgun webhooks while preventing replay attacks (completed 2026-04-29)
- [x] **Phase 16: SES Webhook Provider & SNS Cache** - System securely ingests and normalizes AWS SES (via SNS) webhooks with automatic subscription handling and certificate caching (completed 2026-04-29)
- [ ] **Phase 17: Unblock & Verify Resend** - Full test suite passes clean and Resend provider is confirmed production-ready
- [ ] **Phase 18: Ship v0.3.0** - v0.3.0 published to Hex.pm with complete CHANGELOG and updated provider guides
- [ ] **Phase 19: Fix SES Ingest BLOCKER + Plug-level Integration Test** - SES Notification flow ingests end-to-end through the core webhook seam, ships as v0.3.3 patch
- [ ] **Phase 20: Config Schema & Installer Surface for SES + Resend** - Adopter typos in `:ses` / `:resend` config fail at boot, installer template surfaces both providers, publish-check guards installer-golden drift
- [ ] **Phase 21: SES-02 D-07 Override + SUMMARY Frontmatter Backfill** - SES-02 verification status closes from `human_needed` to `passed` with formal D-07 override, missing `requirements-completed` frontmatter backfilled

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
- [x] 17-01-PLAN.md — Plug wiring, test fix, and WebhookCase :resend infrastructure
- [ ] 17-02-PLAN.md — Resend plug integration tests, fixture, and Phase 14 completion

### Phase 18: Ship v0.3.x
**Goal**: v0.3.x published to Hex.pm with complete CHANGELOG and updated provider guides
**Depends on**: Phase 17
**Requirements**: DELIV-04 (Complete)
**Success Criteria** (what must be TRUE):
  1. `https://hex.pm/packages/mailglass/0.3.x` is live and installable — ✓ (shipped as 0.3.2 after gate-ci-green required 0.3.0 → 0.3.1 → 0.3.2 patch recovery via Conventional Commits / Release Please; orphan tags 0.3.0 and 0.3.1 remain on GitHub but never on Hex; see 18-02-PUBLISH-EVIDENCE.md)
  2. `https://hex.pm/packages/mailglass_admin/0.3.x` is live and installable — ✓ (shipped as 0.3.2 alongside core via linked-versions plugin)
  3. webhooks.md documents Resend configuration including `CachingBodyReader` setup — ✓ (locked in `mix mailglass.docs.check`)
  4. CHANGELOG.md has a complete v0.3 section covering Mailgun, SES, and Resend providers — ✓ (curated 0.3.0 narrative + auto-generated 0.3.1 / 0.3.2 patch entries)
  5. DELIV-04 marked complete in PROJECT.md — ✓
**Plans**: 2 plans

Plans:
- [x] 18-01-PLAN.md — Refresh release surface (changelogs, webhooks guide, README, runbook, workflow comments)
- [x] 18-02-PLAN.md — Real publish ceremony, evidence capture, milestone closure

### Phase 19: Fix SES Ingest BLOCKER + Plug-level Integration Test
**Goal**: SES Notification flow ingests end-to-end through the core webhook seam, ships as v0.3.3 patch
**Depends on**: Phase 18
**Requirements**: SES-01, SES-03, SES-04, SES-05 (gap closure for v0.3.0-MILESTONE-AUDIT BLOCKER)
**Gap Closure**: Closes `gaps.integration` BLOCKER (`ingest_multi/3` provider guard rejects `:ses`) and the `gaps.flows` "SES Notification → mailglass_events" entry from v0.3.0-MILESTONE-AUDIT.md.
**Success Criteria** (what must be TRUE):
  1. `Mailglass.Webhook.Ingest.ingest_multi/3` accepts `:ses` (guard at `lib/mailglass/webhook/ingest.ex:122` updated)
  2. `derive_webhook_provider_event_id(:ses, raw_body, [first | _])` clause exists and delegates to `extract_event_provider_id(first)` mirroring the Mailgun/Resend pattern
  3. New `test/mailglass/webhook/providers/ses_plug_test.exs` exercises a real signed SES Notification through `Mailglass.Webhook.Plug` end-to-end and asserts a `WebhookEvent` row is persisted
  4. `mix test` passes clean with no `--only` scoping or test exclusions
  5. v0.3.3 published to Hex.pm via Release Please (Conventional Commits `fix:`)
**Plans**: 3 plans

Plans:
- [ ] 19-01-PLAN.md — Fix `ingest_multi/3` guard + `derive_webhook_provider_event_id(:ses, ...)` clause (closes SES-01, SES-03)
- [ ] 19-02-PLAN.md — Add `test/mailglass/webhook/plug_ses_test.exs` Plug-level integration test (closes SES-04)
- [ ] 19-03-PLAN.md — Full-suite gate + Conventional Commits ceremony + Release Please observation flow (closes SES-05)

### Phase 20: Config Schema & Installer Surface for SES + Resend
**Goal**: Adopter typos in `:ses` / `:resend` config fail at boot, installer template surfaces both providers, publish-check guards installer-golden drift
**Depends on**: Phase 19
**Requirements**: Defensive — affects SES-01..SES-05, RESEND-01, RESEND-02 (no requirement reset; these are warnings not unsatisfied)
**Gap Closure**: Closes `gaps.integration` Warning #2 (`Mailglass.Config @schema` lacks `:ses`/`:resend` subtrees) and Warning #3 (installer template provider list omits `:ses`/`:resend`) from v0.3.0-MILESTONE-AUDIT.md. Also absorbs todo `2026-04-26-add-installer-goldens-to-publish-check.md` (release-engineering hygiene that fits naturally because Phase 20 already regenerates the installer golden).
**Success Criteria** (what must be TRUE):
  1. `Mailglass.Config.@schema` has `:ses` and `:resend` subtrees so `validate_at_boot!` no longer silently drops adopter config under those keys
  2. `lib/mailglass/installer/templates.ex` example providers list includes `:ses` and `:resend`
  3. `test/mailglass/install/install_golden_test.exs` regenerated to match the new template output (clean diff after `MIX_INSTALLER_ACCEPT_GOLDEN=1`)
  4. `mix mailglass.publish.check` runs the installer golden test in dry-run mode (gated on `MIX_PUBLISH=true`) and fails fast with `%Mailglass.Error{type: :publish_blocked_golden_drift}` pointing at the regen command
  5. `mix test` passes; pre-publish gate exits 0 for both packages
**Plans**: TBD via `/gsd-plan-phase 20`

### Phase 21: SES-02 D-07 Override + SUMMARY Frontmatter Backfill
**Goal**: SES-02 verification status closes from `human_needed` to `passed` with formal D-07 override, missing `requirements-completed` frontmatter backfilled
**Depends on**: Phase 20
**Requirements**: SES-02 (paperwork closure — code already correct per D-07)
**Gap Closure**: Closes the SES-02 `partial` row in `gaps.requirements`, the INFO-severity status-doc divergence, and the Phase 16 tech-debt items from v0.3.0-MILESTONE-AUDIT.md. Pure planning artifacts — no code, no Hex publish.
**Success Criteria** (what must be TRUE):
  1. `.planning/phases/16-ses-webhook-provider-sns-cache/16-VERIFICATION.md` carries a formal override block recording the D-07 deviation (auto-confirm via TopicArn+Token instead of raw SubscribeURL) and flips `status: passed`
  2. `16-02-SUMMARY.md` and `16-04-SUMMARY.md` carry `requirements-completed` frontmatter listing SES-04 and SES-05 respectively
  3. `gsd-sdk query audit-uat --raw` returns `summary.total_items: 0`
  4. Re-running `/gsd-audit-milestone v0.3.0` returns `status: passing` with the SES-02 row showing `satisfied`
**Plans**: TBD via `/gsd-plan-phase 21`

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 14. Resend Webhook Provider & Core Ingest | 1/1 | Complete (verified in Phase 17 + 18) | 2026-04-29 |
| 15. Mailgun Webhook Provider | 4/4 | Complete    | 2026-04-29 |
| 16. SES Webhook Provider & SNS Cache | 4/4 | Complete (E2E gap closed in Phase 19) | 2026-04-29 |
| 17. Unblock & Verify Resend | 2/2 | Complete    | 2026-04-29 |
| 18. Ship v0.3.x (shipped as v0.3.2 — see EVIDENCE) | 2/2 | Complete    | 2026-04-29 |
| 19. Fix SES Ingest BLOCKER + Plug-level Integration Test | 0/0 | Pending (gap closure) | — |
| 20. Config Schema & Installer Surface for SES + Resend | 0/0 | Pending (gap closure) | — |
| 21. SES-02 D-07 Override + SUMMARY Frontmatter Backfill | 0/0 | Pending (gap closure) | — |
