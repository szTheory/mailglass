# Requirements: mailglass

**Defined:** 2026-05-06
**Core Value:** Email you can see, audit, and trust before it ships.

## v1.1 Requirements

### Core Model And Routing

- [ ] **MODEL-01**: Adopter can depend on one canonical `%InboundMessage{}` struct for the first-party inbound package, with stable fields for routing, tenancy, and provider provenance.
- [ ] **ROUTE-01**: Adopter can route inbound mail to mailboxes using one DSL that matches on recipient, subject, and headers.
- [ ] **MAILBOX-01**: Adopter can implement mailbox handlers with explicit `:accept`, `:reject`, `:ignore`, and `{:bounce, reason}` outcomes.

### Provider Ingress

- [ ] **INGRESS-01**: Maintainer can verify and normalize Postmark inbound payloads into the canonical inbound model through a first-party ingress plug.
- [ ] **INGRESS-02**: Maintainer can verify and normalize SendGrid inbound payloads into the canonical inbound model through a first-party ingress plug.

### Storage And Replay

- [ ] **STORE-01**: Operator can persist each inbound message as both normalized canonical data and raw provider source material sufficient for replay and debugging.
- [ ] **STORE-02**: Operator can replay a stored inbound message through routing and mailbox processing without pretending it is a newly received provider event.

### Execution And Adoption

- [ ] **EXEC-01**: Adopter can execute inbound routing asynchronously through Oban when Oban is installed and configured.
- [ ] **EXEC-02**: Adopter can execute the same logical mailbox contract through a supported bounded fallback when Oban is absent.
- [ ] **ADOPT-01**: Adopter can install, configure, test, and support the core inbound slice through honest first-party docs and verification lanes.

## Future Requirements

### Later Inbound Expansion

- **CONDUCTOR-01**: Developer can synthesize and replay inbound messages through a Conductor-style LiveView UI.
- **INGRESS-03**: Maintainer can verify and normalize Mailgun inbound into the canonical model.
- **INGRESS-04**: Maintainer can verify and normalize SES inbound into the canonical model.
- **SMTP-01**: Adopter can receive inbound mail through a `gen_smtp` relay ingress for self-hosted scenarios.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Live `v1.0` publish closeout | Explicit external precondition; not part of the inbound milestone scope |
| Conductor-style dev UI | Core routing/ingress/storage slice ships first so the first expansion stays narrow |
| Mailgun / SES inbound in `v1.1` | First milestone proves the package on Postmark + SendGrid before broad provider parity |
| `gen_smtp` relay ingress in `v1.1` | Webhook-based provider ingress is the initial scope; SMTP relay remains later follow-on work |
| Marketing / workflow automation | Different product category and compliance surface |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| MODEL-01 | Phase 43 | Satisfied |
| ROUTE-01 | Phase 43 | Satisfied |
| MAILBOX-01 | Phase 43 | Satisfied |
| INGRESS-01 | Phase 43 | Satisfied |
| STORE-01 | Phase 43 | Satisfied |
| INGRESS-02 | Phase 43 | Satisfied |
| STORE-02 | Phase 43 | Satisfied |
| EXEC-01 | Phase 44 | Pending |
| EXEC-02 | Phase 44 | Pending |
| ADOPT-01 | Phase 44 | Pending |

Phase 43 reconciles bookkeeping only: these seven requirements were implemented in Phases 39 to 41 and recovered under Phase 43 by restoring execution verification artifacts.

**Coverage:**
- v1.1 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

---
*Requirements defined: 2026-05-06*
*Last updated: 2026-05-06 after recovering Phase 39-41 execution verification artifacts under Phase 43*
