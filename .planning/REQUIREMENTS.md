# Requirements: mailglass v1.6 Inbound 1.0 Release and Truth Lock

**Defined:** 2026-06-02
**Core Value:** Email you can see, audit, and trust before it ships.

## v1.6 Requirements

### Release Truth

- [x] **REL-01**: Maintainer can prove `mailglass_inbound` `1.0.0` source truth across `.release-please-manifest.json`, `mailglass_inbound/mix.exs`, `mailglass_inbound/CHANGELOG.md`, README install pins, `MIX_PUBLISH=true` core dependency pin, package allowlist, and `.planning/publish/mailglass_inbound-publish-summary.json`.
- [x] **REL-02**: Maintainer can execute or prepare the inbound-only publish path from the reviewed tag/ref without forcing a `mailglass` or `mailglass_admin` release.
- [x] **REL-03**: Maintainer can record inbound release evidence including tag/ref, release or dispatch path, publish workflow URL, fallback usage, Hex index URL, HexDocs URL, smoke/install proof, and the 60-minute revert/retire decision.

### Contract Documentation

- [x] **DOC-01**: Adopter-facing docs describe `mailglass_inbound` as its own stable `1.0` package contract routed through `mailglass_inbound/docs/api_stability.md`, not as `v0.5+`, `0.3`, or outside stability truth.
- [x] **DOC-02**: Compatibility docs preserve the matched `mailglass` / `mailglass_admin` `1.x` sibling line while explaining that inbound has a separate `1.0` contract and does not widen core/admin compatibility promises.

### Release Proof

- [x] **PROOF-01**: Release docs and checks clearly distinguish deterministic required release proof from advisory provider/live checks.
- [x] **PROOF-02**: Executable docs-contract or release-contract checks pin the highest-risk stale claims: inbound install version, package table status, maintainer runbook smoke dependencies, and inbound-only release wording.

## Future Requirements

Deferred to future milestones only with concrete adopter pull or a contract gap.

### Inbound Feature Growth

- **FUT-IN-01**: Synthetic inbound development UI can be considered with strict dev-only tenant/provenance safety.
- **FUT-IN-02**: Cloudflare forwarding recipe docs can be considered as narrow adopter-pull documentation.
- **FUT-IN-03**: Ecosystem integrations can be reconsidered only after a concrete integration need outranks release/maintenance work.
- **FUT-IN-04**: `gen_smtp` listener support requires a separate threat and operations model.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Matcher expansion, lifecycle callbacks, public replay API, provider extension API | Would widen the just-locked inbound contract and invalidate the release-governance focus. |
| Synthetic inbound UI | Useful later, but not needed to publish or prove the selected `1.0.0` candidate. |
| `gen_smtp` listener, Cloudflare recipes, ecosystem integrations | Separate transport/integration work; pull-driven only. |
| Demo app enhancements or screenshot workflow expansion | v1.5 already closed demo evidence; this milestone is release truth. |
| Planning-directory cleanup or broad source hygiene | Real maintenance, but not release-critical unless it directly blocks v1.6 proof. |
| Full core/admin/inbound matched release line | Inbound is an independent `1.0` package contract; core/admin remain the matched sibling line. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 71 | Complete |
| REL-02 | Phase 73 | Complete |
| REL-03 | Phase 73 | Complete |
| DOC-01 | Phase 72 | Complete |
| DOC-02 | Phase 72 | Complete |
| PROOF-01 | Phase 71 | Complete |
| PROOF-02 | Phase 72 | Complete |

**Coverage:**
- v1.6 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0

---
*Requirements defined: 2026-06-02*
*Last updated: 2026-06-02 after roadmap creation*
