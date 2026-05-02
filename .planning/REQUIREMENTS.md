# Requirements: mailglass

**Defined:** 2026-05-02
**Core Value:** Email you can see, audit, and trust before it ships.

## v0.5 Requirements

### Scaffolding
- [ ] **SCAFFOLD-01**: User can generate a new mailable scaffold and matching HEEx template with `mix mailglass.gen.mailable`.

### Testing
- [x] **TEST-01
**: User has richer test assertion helpers for outbound delivery verification.
- [ ] **TEST-02**: User has richer test assertion helpers for webhook payload and idempotency verification.

### Rate Limiting
- [ ] **RATE-01**: Operator can configure per-domain rate limiting for outbound dispatch.
- [ ] **RATE-02**: Rate limiting applies adoption-facing sensible defaults and documentation out of the box.

### Documentation & Reliability
- [ ] **DOCS-01**: Adopters can access a dedicated first-party webhook troubleshooting guide.
- [ ] **DOCS-02**: Adopters can consult refined upgrade documentation and operator guides addressing real integration friction.
- [ ] **REL-19**: Install and post-publish smoke test contracts are tightened to eliminate known brittleness.

## Future Requirements

### Production Maturity (v0.6)
- **MAT-01**: Operator has hardened replay / reconcile / incident-response workflows.
- **MAT-02**: Operator-facing observability and support docs cover real production failure modes.
- **MAT-03**: Deferred verification and regression gaps are closed where material.

### Post-v1.0 Inbound
- **INBOUND-01**: Adopter can route inbound mail through a separate `mailglass_inbound` package once the outbound/operator core is stable.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Inbound mail routing in `v0.5` | Explicitly deferred until after the pre-`v1.0` operator/adoption/stability arc |
| Marketing / campaign tooling | Different product category and compliance surface |
| Large new conceptual surface area | Goal is adoption hardening of the current core, not expansion |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCAFFOLD-01 | Phase 28 | Pending |
| TEST-01 | Phase 29 | Pending |
| TEST-02 | Phase 29 | Pending |
| RATE-01 | Phase 30 | Pending |
| RATE-02 | Phase 30 | Pending |
| DOCS-01 | Phase 31 | Pending |
| DOCS-02 | Phase 31 | Pending |
| REL-19 | Phase 31 | Pending |

**Coverage:**
- v0.5 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0

---
*Requirements defined: 2026-05-02*
*Last updated: 2026-05-02*
