# Requirements: mailglass

**Defined:** 2026-05-05
**Core Value:** Email you can see, audit, and trust before it ships.

## v0.6 Requirements

### Replay & Reconcile
- [ ] **MAT-01**: Operator can replay or reconcile webhook-driven delivery state with explicit tenant-safe authorization, auditable outcomes, and clear failure handling.

### Observability & Support
- [ ] **MAT-02**: Operator-facing observability and incident-response/support docs cover delivery, webhook ingest, and reconciliation failure modes without exposing PII.

### Verification & Regression Closure
- [ ] **MAT-03**: Maintainer has automated verification for the highest-risk deferred regression and production-support gaps before `v1.0`.

## Future Requirements

### Stability Lock (v1.0)
- **STAB-01**: Adopter can rely on a documented stability and deprecation contract for the transactional/admin core.
- **STAB-02**: Maintainer has proof artifacts demonstrating the core surface is stable enough for long-lived production adoption.

### Post-v1.0 Inbound
- **INBOUND-01**: Adopter can route inbound mail through a separate `mailglass_inbound` package once the outbound/operator core is stable.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Inbound mail routing in `v0.6` | Explicitly deferred until after the pre-`v1.0` stability arc |
| Marketing / campaign tooling | Different product category and compliance surface |
| Major pre-`v1.0` abstraction pivots | Goal is production maturity of the current core, not expansion |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| MAT-01 | Phase 32 | Pending |
| MAT-02 | Phase 33 | Pending |
| MAT-03 | Phase 34 | Pending |

**Coverage:**
- v0.6 requirements: 3 total
- Mapped to phases: 3
- Unmapped: 0

---
*Requirements defined: 2026-05-05*
*Last updated: 2026-05-05*
