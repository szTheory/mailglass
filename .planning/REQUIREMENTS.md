# Milestone v0.3 Requirements

## Active

### Resend
- [ ] **RESEND-01**: Webhook plug verifies Svix HMAC-SHA256 signature using `svix-id`, `svix-timestamp`, and raw request body.
- [ ] **RESEND-02**: Webhook maps Resend events (delivered, bounced, complained) to `mailglass` normalized taxonomy.

### Mailgun
- [ ] **MAILGUN-01**: Webhook plug verifies HMAC-SHA256 signature using `timestamp`, `token`, and webhook signing key.
- [ ] **MAILGUN-02**: Token caching mechanism prevents replay attacks for previously verified tokens.
- [ ] **MAILGUN-03**: Webhook maps Mailgun events to `mailglass` normalized taxonomy.

### SES
- [ ] **SES-01**: Webhook plug parses SNS payloads arriving with `text/plain` Content-Type.
- [ ] **SES-02**: System automatically performs HTTP GET to `SubscribeURL` upon receiving `SubscriptionConfirmation` events.
- [ ] **SES-03**: Webhook plug verifies RSA-SHA1/SHA256 signatures using X.509 certificates fetched from AWS.
- [ ] **SES-04**: X.509 certificates are fetched via `:httpc` and cached in `:ets` to avoid synchronous network I/O per webhook.
- [ ] **SES-05**: Webhook maps SES events inside the SNS `Message` envelope to `mailglass` normalized taxonomy.

## Future Requirements

*(None deferred)*

## Out of Scope

- **Inbound message processing** (Action Mailbox equivalent) - Deferred to v0.5+ sibling package.
- **Provider-specific sending implementations** - Mailglass is a transactional email framework over Swoosh. Swoosh adapters handle the actual sending. Mailglass only handles webhook ingest normalization.

## Traceability

*(Will be filled by the roadmapper)*