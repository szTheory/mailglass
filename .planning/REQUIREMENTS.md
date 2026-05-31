# Requirements: mailglass

**Defined:** 2026-05-27  
**Core Value:** Email you can see, audit, and trust before it ships.

## v1.3 Requirements

Requirements for the Adopter Trust Proof milestone. Scope is intentionally narrow: prove one end-to-end adopter journey without expanding product breadth.

### Reference Host Baseline

- [ ] **HOST-01**: Adopter can boot one maintained Phoenix reference host app from a clean checkout using documented setup and published package constraints.
- [ ] **HOST-02**: Reference host app integrates through documented public Mailglass seams only, with no copied provider internals.
- [ ] **HOST-03**: Reference host app includes an explicit proof-scope allowlist and non-goals so it does not become a second product.

### Deterministic Trust Journey

- [ ] **JOUR-01**: One deterministic trust runner command proves install -> preview -> send -> webhook ingest -> operator troubleshooting.
- [ ] **JOUR-02**: Trust fixtures use stable IDs/payloads so local and CI assertions are reproducible.
- [x] **JOUR-03**: Webhook proof executes the real verify-first route path with signed payloads plus one failing-signature assertion.
- [x] **JOUR-04**: Operator troubleshooting includes one scripted non-happy-path flow with deterministic evidence and diagnosis.

### CI and Release Trust Evidence

- [ ] **EVID-01**: CI has a required repo-head trust lane that fails on missing journey checkpoints.
- [x] **EVID-02**: CI has a clean-baseline trust lane that enforces Hex-first dependency resolution and blocks path-dependency leakage.
- [ ] **EVID-03**: Release/post-publish workflow executes a published-version trust journey before milestone trust claims are accepted.
- [ ] **EVID-04**: Trust lanes emit machine-readable checkpoint artifacts used as release evidence.

### Docs and Contract Boundary

- [ ] **DOCB-01**: Reference-app docs clearly state they are usage proof artifacts, not API-contract truth.
- [ ] **DOCB-02**: Reference journey docs link to canonical stability contract documents and tests for guarantee semantics.
- [ ] **DOCB-03**: Docs contract verification enforces boundary language so reference internals are not presented as public API.

### Operational Risk and Drift Prevention

- [ ] **OPS-01**: Active post-publish smoke hackney dependency failure is resolved and regression-protected as part of trust-proof reliability.
- [x] **OPS-02**: Release checklist and maintenance cadence require green trust evidence before v1.3 closeout.

## Future Requirements

Deferred after v1.3 trust proof and inbound stability lock:

### Deferred Breadth

- **FUTR-01**: Multi-provider trust matrix in reference host app.
- **FUTR-02**: Ecosystem integrations from `SEED-003-ecosystem-integrations`.
- **FUTR-03**: Cloudflare forwarding recipes or additional ecosystem transport wedges.
- **FUTR-04**: `gen_smtp` listener/relay transport-class expansion.

## Out of Scope

Explicit v1.3 exclusions to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Provider-matrix broadening in v1.3 | Trust-proof milestone validates one representative journey, not breadth across all providers. |
| `SEED-003-ecosystem-integrations` promotion | Deferred until trust-proof and inbound stability-lock priorities are complete. |
| `gen_smtp` listener expansion | Different transport class with separate threat model and ops burden; not part of v1.3 trust claim. |
| New product features in reference app | Reference app is a proof host, not a second app surface. |

## Traceability

Each v1.3 requirement maps to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| HOST-01 | Phase 52 | Pending |
| HOST-02 | Phase 52 | Pending |
| HOST-03 | Phase 52 | Pending |
| JOUR-01 | Phase 57 | Pending |
| JOUR-02 | Phase 57 | Pending |
| JOUR-03 | Phase 58 | Complete |
| JOUR-04 | Phase 58 | Complete |
| EVID-01 | Phase 59 | Pending |
| EVID-02 | Phase 59 | Complete |
| EVID-04 | Phase 59 | Pending |
| DOCB-01 | Phase 61 | Pending |
| DOCB-02 | Phase 61 | Pending |
| DOCB-03 | Phase 61 | Pending |
| EVID-03 | Phase 60 | Pending |
| OPS-01 | Phase 60 | Pending |
| OPS-02 | Phase 60 | Complete |

**Coverage:**

- v1.3 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 after v1.3 milestone gap-closure phase planning*
