# Requirements: mailglass v1.5 Demo Evidence and Click-Around Confidence

**Defined:** 2026-06-01
**Core Value:** Email you can see, audit, and trust before it ships.

## v1.5 Requirements

### Demo App

- [x] **DEMO-01**: Maintainer can run a separate B2B SaaS Ops demo app without changing the existing narrow reference host.
- [x] **DEMO-02**: Maintainer can switch the demo between local path dependencies and published Hex package constraints.
- [ ] **DEMO-03**: Demo app exposes a click-around dashboard that links to Mailglass preview, outbound operator, and inbound operator surfaces.

### Demo Data

- [ ] **DATA-01**: Maintainer can reset deterministic demo data with one command.
- [ ] **DATA-02**: Demo data includes realistic outbound deliveries, timeline events, suppressions, and replayable webhook targets.
- [ ] **DATA-03**: Demo data includes realistic inbound records, evidence, routing outcomes, replay lineage, and no-match cases.
- [ ] **DATA-04**: Demo mailables provide realistic preview scenarios for invite/auth, receipt, and operational alert use cases.

### Developer Experience

- [x] **DX-01**: Maintainer can start Postgres plus the demo app through Docker Compose.
- [x] **DX-02**: Docker/Compose setup preserves Mix deps, build artifacts, npm deps, and browser caches across style or code iterations.
- [ ] **DX-03**: Demo docs start with a short quickstart and explain the persona, JTBD, seeded data, and what to click.

### Evidence

- [ ] **EVID-01**: Browser evidence drives the demo preview journey and verifies realistic mailables render.
- [ ] **EVID-02**: Browser evidence drives outbound operator list/detail/timeline/suppression/replay journeys.
- [ ] **EVID-03**: Browser evidence drives inbound operator list/detail/evidence/routing-trace/replay journeys.
- [ ] **EVID-04**: CI or local evidence writes deterministic checkpoints/screenshots without treating DOM shape as stable public API.

## Future Requirements

- **FUTR-01**: Published-Hex-only demo gate after the `mailglass_inbound` `1.0.0` live release exists.
- **FUTR-02**: Provider-matrix demo breadth beyond the representative seeded Postmark/SendGrid/Mailgun/SES stories.
- **FUTR-03**: Ecosystem integrations from `SEED-003` after a concrete adopter pull signal exists.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Turning `reference/host_app` into the rich demo | It remains a narrow trust-proof artifact and usage-proof contract. |
| New stable Mailglass public APIs | This milestone proves adoption confidence through a demo app, not library surface expansion. |
| Hosted demo service | Mailglass remains mountable Phoenix infrastructure, not a hosted SaaS. |
| Production auth or account management in the demo | Demo-only operator login/session glue is sufficient for click-around evidence. |
| Provider-matrix broadening | The milestone optimizes journey confidence, not provider breadth. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEMO-01 | Phase 67 | Complete |
| DEMO-02 | Phase 67 | Complete |
| DEMO-03 | Phase 69 | Pending |
| DATA-01 | Phase 68 | Pending |
| DATA-02 | Phase 68 | Pending |
| DATA-03 | Phase 68 | Pending |
| DATA-04 | Phase 68 | Pending |
| DX-01 | Phase 67 | Complete |
| DX-02 | Phase 67 | Complete |
| DX-03 | Phase 69 | Pending |
| EVID-01 | Phase 70 | Pending |
| EVID-02 | Phase 70 | Pending |
| EVID-03 | Phase 70 | Pending |
| EVID-04 | Phase 70 | Pending |
| FUTR-01 | Future | Deferred |
| FUTR-02 | Future | Deferred |
| FUTR-03 | Future | Deferred |

**Coverage:**
- v1.5 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0

---
*Requirements defined: 2026-06-01*
*Last updated: 2026-06-01 after Phase 67 completion*
