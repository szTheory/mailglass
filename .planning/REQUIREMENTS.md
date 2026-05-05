# Requirements: mailglass

**Defined:** 2026-05-05
**Core Value:** Email you can see, audit, and trust before it ships.

## v1.0 Requirements

Requirements for the `v1.0 Stability Lock` milestone. Each maps to exactly one roadmap phase.

### Stability Contract

- [ ] **LOCK-01**: Adopter can identify the exact `mailglass` core modules, behaviours, mix tasks, telemetry names, structs, and documented fields that are stable for `v1.x`.
- [ ] **LOCK-02**: Adopter can identify the exact `mailglass_admin` router, auth, and operator-service seams that are stable for `v1.x`, and which admin UI details remain internal.
- [ ] **LOCK-03**: Maintainer can classify exported but non-contract surfaces as internal or sibling-package-only so accidental public surface does not expand during `v1.x`.
- [ ] **LOCK-04**: Stable public APIs carry complete `@since` and deprecation metadata so the contract is visible in generated docs, not only in planning notes.

### Compatibility And Upgrade Contract

- [ ] **COMPAT-01**: Adopter can read one canonical `1.x` versioning and deprecation policy that explains patch, minor, and major guarantees plus security/correctness exceptions.
- [ ] **COMPAT-02**: Adopter can read one canonical support matrix covering runtime floors, Phoenix/Postgres scope, sibling-package expectations, and optional-dependency support lanes.
- [ ] **COMPAT-03**: Adopter can follow a canonical `0.x -> 1.0` upgrade guide that covers remaining legacy entrypoints, required code changes, and expected warning behavior.
- [ ] **COMPAT-04**: Maintainer can verify that any still-supported deprecated path has a documented replacement, warning behavior where possible, and no planned removal before `v2.0`.

### Contract Enforcement And Trust Docs

- [ ] **PROOF-01**: Maintainer can run one stability verification workflow that detects drift in the documented public surface for both `mailglass` and `mailglass_admin`.
- [ ] **PROOF-02**: Maintainer can detect leaked internal modules, docs, types, tasks, or sibling-package contract violations before a release is cut.
- [ ] **PROOF-03**: Adopter can rely on a documented testing contract for inline, async, Oban, and cross-process delivery workflows without guessing which helpers or modes are stable.
- [ ] **PROOF-04**: Adopter can rely on stable admin mount, auth, and operator-action docs without depending on DOM, component, or LiveView implementation details.

### Release Rehearsal And Proof Artifacts

- [ ] **RELS-01**: Maintainer can prove a clean Phoenix app can install released `mailglass` and `mailglass_admin` packages from Hex, mount admin, and execute the documented first-send workflow.
- [ ] **RELS-02**: Maintainer can prove an app on the latest `0.x` upgrade path can reach `v1.0` with the documented migration steps and passing smoke checks.
- [ ] **RELS-03**: Maintainer can verify tarball contents, HexDocs inputs, and sibling-package version pins before publish so the released artifacts match the documented contract.
- [ ] **RELS-04**: Maintainer can execute a rehearsed release checklist that includes required CI buckets and any manual external checks still needed for a trustworthy `v1.0` cut.

## v2 Requirements

Deferred until after the `v1.0` stability promise is shipped and proven.

### Post-v1.0 Expansion

- **INBOUND-01**: Adopter can receive and route inbound email through a first-party `mailglass_inbound` sibling package.
- **DELIV-01**: Maintainer can explore adjacent deliverability workflow bets such as warmup, BIMI tooling expansion, or other post-`v1.0` support surfaces without weakening the core contract.
- **COMPAT-05**: Maintainer can evaluate heavier compatibility tooling or broader support-matrix expansion only after the narrow `v1.x` contract is stable in practice.

## Out of Scope

Explicitly excluded from the `v1.0 Stability Lock` milestone.

| Feature | Reason |
|---------|--------|
| `mailglass_inbound` implementation | Post-`v1.0` future bet; it expands the product boundary instead of locking the existing core. |
| New providers, transports, or major runtime abstractions | Stability milestone should reduce variables, not create new ones. |
| Marketing, campaigns, automation, or preference-center work | Outside the transactional/operator core and already a permanent project boundary. |
| Broad compatibility-matrix expansion | A one-maintainer project should keep the support promise narrow and honest at `v1.0`. |
| Heavy ABI/manifest compatibility infrastructure | Targeted contract checks are enough for this milestone and cheaper to maintain. |
| Admin UI DOM/component freeze | Only route, auth, and operator-action semantics are part of the intended stable contract. |

## Traceability

Which phases cover which requirements. Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| LOCK-01 | Phase 35 | Pending |
| LOCK-02 | Phase 35 | Pending |
| LOCK-03 | Phase 35 | Pending |
| LOCK-04 | Phase 35 | Pending |
| COMPAT-01 | Phase 36 | Pending |
| COMPAT-02 | Phase 36 | Pending |
| COMPAT-03 | Phase 36 | Pending |
| COMPAT-04 | Phase 36 | Pending |
| PROOF-01 | Phase 37 | Pending |
| PROOF-02 | Phase 37 | Pending |
| PROOF-03 | Phase 37 | Pending |
| PROOF-04 | Phase 37 | Pending |
| RELS-01 | Phase 38 | Pending |
| RELS-02 | Phase 38 | Pending |
| RELS-03 | Phase 38 | Pending |
| RELS-04 | Phase 38 | Pending |

**Coverage:**
- v1.0 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-05-05*
*Last updated: 2026-05-05 after milestone research synthesis for v1.0 Stability Lock*
