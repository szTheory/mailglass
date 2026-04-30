# Milestone v0.3 Requirements

## Active

### Resend
- [x] **RESEND-01**: Webhook plug verifies Svix HMAC-SHA256 signature using `svix-id`, `svix-timestamp`, and raw request body.
- [x] **RESEND-02**: Webhook maps Resend events (delivered, bounced, complained) to `mailglass` normalized taxonomy.

### Mailgun
- [x] **MAILGUN-01**: Webhook plug verifies HMAC-SHA256 signature using `timestamp`, `token`, and webhook signing key.
- [x] **MAILGUN-02**: Token caching mechanism prevents replay attacks for previously verified tokens.
- [x] **MAILGUN-03**: Webhook maps Mailgun events to `mailglass` normalized taxonomy.

### SES
- [ ] **SES-01**: Webhook plug parses SNS payloads arriving with `text/plain` Content-Type. _Reset 2026-04-29 by v0.3.0-MILESTONE-AUDIT — unit-level verification passed but E2E ingest blocked at `lib/mailglass/webhook/ingest.ex:122` (`:ses` missing from provider guard). Closes in Phase 19._
- [x] **SES-02**: System automatically performs HTTP GET to `SubscribeURL` upon receiving `SubscriptionConfirmation` events. _Implementation auto-confirms via TopicArn+Token per D-07 (functionally satisfies the requirement). Formal override block awaiting record in 16-VERIFICATION.md → Phase 21._
- [ ] **SES-03**: Webhook plug verifies RSA-SHA1/SHA256 signatures using X.509 certificates fetched from AWS. _Reset 2026-04-29 by v0.3.0-MILESTONE-AUDIT — unit-level verification passed but E2E ingest blocked. Closes in Phase 19._
- [ ] **SES-04**: X.509 certificates are fetched via `:httpc` and cached in `:ets` to avoid synchronous network I/O per webhook. _Reset 2026-04-29 by v0.3.0-MILESTONE-AUDIT — unit-level verification passed but E2E ingest blocked. Closes in Phase 19._
- [ ] **SES-05**: Webhook maps SES events inside the SNS `Message` envelope to `mailglass` normalized taxonomy. _Reset 2026-04-29 by v0.3.0-MILESTONE-AUDIT — unit-level verification passed but E2E ingest blocked. Closes in Phase 19._

## Future Requirements

*(None deferred)*

## Out of Scope

- **Inbound message processing** (Action Mailbox equivalent) - Deferred to v0.5+ sibling package.
- **Provider-specific sending implementations** - Mailglass is a transactional email framework over Swoosh. Swoosh adapters handle the actual sending. Mailglass only handles webhook ingest normalization.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| RESEND-01 | Phase 14 (implemented), Phase 17 (verification), Phase 18 (Plug-level integration test added in PR #20) | Complete |
| RESEND-02 | Phase 14 (implemented), Phase 17 (verification), Phase 18 (Plug-level integration test added in PR #20) | Complete |
| MAILGUN-01 | Phase 15 | Complete |
| MAILGUN-02 | Phase 15 | Complete |
| MAILGUN-03 | Phase 15 | Complete |
| SES-01 | Phase 16 (unit), Phase 19 (E2E ingest fix) | Pending |
| SES-02 | Phase 16 (implemented per D-07), Phase 21 (formal override paperwork) | Partial |
| SES-03 | Phase 16 (unit), Phase 19 (E2E ingest fix) | Pending |
| SES-04 | Phase 16 (unit), Phase 19 (E2E ingest fix) | Pending |
| SES-05 | Phase 16 (unit), Phase 19 (E2E ingest fix) | Pending |
| DELIV-04 | Phase 18 | Complete |
