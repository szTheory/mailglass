# Requirements: mailglass

**Defined:** 2026-08-04
**Core Value:** Email you can see, audit, and trust before it ships.

## v2.5 Requirements

### Certification Evidence

- [ ] **CERT-01**: Maintainer can reproduce every generated-host certification stage from package-shaped local artifacts and record bounded, non-PII checkpoint evidence.
- [ ] **CERT-02**: Maintainer can reproduce the complete generated-host journey from the exact public `mailglass` 2.4.1, `mailglass_admin` 2.4.1, and `mailglass_inbound` 2.1.2 package versions with no path or git dependency.
- [ ] **CERT-03**: Maintainer can verify the documented first-adopter contracts for single-recipient send, durable async delivery, immutable payload lifecycle, provider feedback, and one-click suppression against the released package family.

### Integration Safety

- [ ] **SAFE-01**: Maintainer can verify provider/webhook signature controls, schema isolation, optional-dependency isolation, and public documentation contracts without a false-green or unclassified failure.
- [ ] **SAFE-02**: Maintainer can verify safety-only operator behavior: authenticated access, anonymous denial, preflight/readiness reporting, and delivery/suppression evidence visibility without requiring UI polish.
- [ ] **SAFE-03**: Maintainer receives a go/no-go report that classifies each result as a library defect, evidence/test defect, or adopter-owned prerequisite and names the required owner.

## Future Requirements

- **ALPHA-01**: First-adopter SaaS host proves its own real provider, DNS, auth, preference, alerting, and deployment configuration before live traffic.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New Mailglass product capabilities, providers, or integrations | Certification must test the released contract rather than expand it. |
| Admin/operator visual polish or workflow redesign | Verify safety and access only; UX cleanup is a later dedicated effort. |
| Automatic Hex release | Publish only if certification exposes and fixes a real library defect. |
| SaaS-host DNS, credentials, auth, preference policy, paging, and deployment | These must be proven in the adopter's environment and remain host-owned. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CERT-01 | Phase 154 | Pending |
| CERT-02 | Phase 154 | Pending |
| CERT-03 | Phase 154 | Pending |
| SAFE-01 | Phase 154 | Pending |
| SAFE-02 | Phase 154 | Pending |
| SAFE-03 | Phase 154 | Pending |

**Coverage:**
- v2.5 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0 ✓

---
*Requirements defined: 2026-08-04*
*Last updated: 2026-08-04 after v2.5 milestone definition*
