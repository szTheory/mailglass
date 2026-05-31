# Requirements: mailglass v1.4 Inbound Stability Lock

**Defined:** 2026-05-31
**Core Value:** Email you can see, audit, and trust before it ships.

## v1.4 Requirements

Requirements for the inbound stability-lock milestone. Each requirement maps to exactly one roadmap phase.

### Contract Lock

- [x] **LOCK-01**: Adopter can identify every stable inbound runtime, testing, and operator seam from one canonical inventory.
- [x] **LOCK-02**: Adopter can distinguish stable semantics from reachable/internal modules.
- [x] **LOCK-03**: Deferred inbound capabilities are explicitly named so later sessions do not promote them accidentally.

### Verification Proof

- [ ] **PROOF-01**: `mix verify.stability_contract` proves inbound contract docs and compiled-doc metadata.
- [ ] **PROOF-02**: Inbound closed atom/type sets stay locked to docs.
- [ ] **PROOF-03**: Docs checks block over-claims and stale release-line claims.

### Adopter DX

- [ ] **DX-01**: Adopter can follow one canonical install/adoption path without contradictory docs.
- [ ] **DX-02**: Operator can understand doctor/replay/prune commands, exit semantics, tenant guards, and destructive confirmations.
- [ ] **DX-03**: Testing docs clearly explain process-local assertions and one-assertion-per-drive behavior.
- [ ] **DX-04**: Admin/operator trust wording does not confuse replay, reroute, fresh receipt, or UI guarantees.

### Release Position

- [ ] **REL-01**: Maintainer can make an explicit inbound `1.0.0` vs final `0.x` release decision from committed evidence.
- [ ] **REL-02**: Release notes explain the contract posture without hype or ambiguity.
- [ ] **REL-03**: No broad feature-growth milestone opens before the release-position decision.

## Future Requirements

Deferred until there is clear adopter pull and a separately scoped milestone.

### Inbound Expansion

- **FUT-IN-01**: Adopter can use additional inbound matchers such as body, attachment, raw MIME, predicate combinators, or multi-match fan-out.
- **FUT-IN-02**: Adopter can use mailbox lifecycle callbacks beyond `process/1`.
- **FUT-IN-03**: Adopter can use a public replay API distinct from operator CLI semantics.
- **FUT-IN-04**: Adopter can implement a public provider extension behaviour for custom inbound providers.
- **FUT-IN-05**: Adopter can use a synthetic inbound development UI with strict dev-only, tenant-safe, provenance-stamped behavior.
- **FUT-IN-06**: Adopter can use a first-party `gen_smtp` listener ingress after a separate transport threat model and ops review.
- **FUT-IN-07**: Adopter can use Cloudflare forwarding or ecosystem integration recipes when there is pull-driven need.

## Out of Scope

Explicitly excluded from v1.4 to keep this a stability-lock milestone.

| Feature | Reason |
|---------|--------|
| New inbound providers | Provider breadth is feature growth; v1.4 locks existing shipped provider posture. |
| Matcher expansion | Expands routing semantics and support surface; defer until after contract lock. |
| Mailbox lifecycle callbacks | Adds a new public extension model; not needed to decide 1.0 posture. |
| Public replay API | Replay remains operator/storage-truth semantics, not a general public runtime API. |
| Public worker/queue contracts | Oban jobs, queue names, worker args, and retry tuning remain internal implementation details. |
| Provider extension API | First-party provider modules remain verify/normalize internals behind `Ingress.Plug`. |
| Synthetic inbound dev UI | Useful DX, but not required for contract stability and risks widening the milestone. |
| `gen_smtp` listener | Separate transport class with separate threat and ops burden. |
| Ecosystem integrations / `SEED-003` | Pull-driven strategic work only after inbound stability lock and release-position decision. |
| Admin DOM/component guarantees | Admin UI semantics may be stable; DOM, LiveView modules, components, and CSS remain internal. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| LOCK-01 | Phase 63 | Complete |
| LOCK-02 | Phase 63 | Complete |
| LOCK-03 | Phase 63 | Complete |
| PROOF-01 | Phase 64 | Pending |
| PROOF-02 | Phase 64 | Pending |
| PROOF-03 | Phase 64 | Pending |
| DX-01 | Phase 65 | Pending |
| DX-02 | Phase 65 | Pending |
| DX-03 | Phase 65 | Pending |
| DX-04 | Phase 65 | Pending |
| REL-01 | Phase 66 | Pending |
| REL-02 | Phase 66 | Pending |
| REL-03 | Phase 66 | Pending |

**Coverage:**
- v1.4 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-05-31*
*Last updated: 2026-05-31 after v1.4 milestone definition*
