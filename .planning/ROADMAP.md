# Roadmap: mailglass

**Granularity:** standard (config.json)
**Sibling package out of milestone:** `mailglass_inbound` (post-`v1.0`, not roadmapped here)

## Milestones

- ✅ **v0.1 Validation Release** — Phases 1-7 + 07.1 (shipped 2026-04-26) — see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** — Phases 8-13 (shipped 2026-04-28) — see [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** — Phases 14-21 (shipped 2026-04-30) — see [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Operator Confidence** — Phases 22-27 (shipped 2026-05-02) — see [milestones/v0.4-ROADMAP.md](milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 Adoption Hardening** — Phases 28-31 (shipped 2026-05-03) — see [milestones/v0.5-ROADMAP.md](milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 Production Maturity** — Phases 32-34 (shipped 2026-05-05) — see [milestones/v0.6-ROADMAP.md](milestones/v0.6-ROADMAP.md)

## Current Milestone

### v1.0 Stability Lock

**Goal:** Declare the transactional and admin core stable for long-lived production adoption without expanding the product boundary.

**Why now:** Production maturity is complete. The remaining `v1.0` work is to lock the real public contract, make compatibility promises explicit, prove the contract with targeted enforcement, and rehearse the release with evidence instead of maintainer memory.

## Phases

- [ ] **Phase 35: Stability Contract Audit** - Lock the exact stable `v1.x` surface across `mailglass` and `mailglass_admin`.
- [ ] **Phase 36: Deprecation and Compatibility Contract** - Publish the canonical `1.x` policy, support matrix, and `0.x -> 1.0` upgrade path.
- [ ] **Phase 37: Contract Enforcement and Trust Docs** - Enforce the documented contract and ship trust docs for testing and admin semantics.
- [ ] **Phase 38: Release Rehearsal and Proof Artifacts** - Rehearse install, upgrade, artifact verification, and release cutover for `v1.0`.

## Phase Details

### Phase 35: Stability Contract Audit
**Goal**: Adopters and maintainers can identify the exact stable `v1.x` contract across `mailglass` and `mailglass_admin`, including what remains internal.
**Depends on**: Phase 34
**Requirements**: LOCK-01, LOCK-02, LOCK-03, LOCK-04
**Success Criteria** (what must be TRUE):
  1. Adopter can find one canonical inventory of stable `mailglass` modules, behaviours, mix tasks, telemetry names, structs, and documented fields promised for `v1.x`.
  2. Adopter can find one canonical inventory of stable `mailglass_admin` router, auth, and operator-service seams, with UI implementation details explicitly marked as internal.
  3. Maintainer can classify exported-but-unsupported surfaces as internal or sibling-package-only without expanding the accidental public contract.
  4. Generated docs show `@since` and deprecation metadata on stable public APIs so the contract is visible at the point of use.
**Plans**: TBD

Plans:
- [ ] TBD

### Phase 36: Deprecation and Compatibility Contract
**Goal**: Adopters can upgrade within `1.x` and from the latest `0.x` path using one narrow, explicit compatibility promise.
**Depends on**: Phase 35
**Requirements**: COMPAT-01, COMPAT-02, COMPAT-03, COMPAT-04
**Success Criteria** (what must be TRUE):
  1. Adopter can read one canonical versioning and deprecation policy covering patch, minor, major, and security/correctness exception behavior.
  2. Adopter can read one support matrix covering runtime floors, Phoenix/Postgres scope, sibling-package expectations, and optional-dependency lanes.
  3. Adopter can follow one canonical `0.x -> 1.0` upgrade guide that identifies legacy entrypoints, required code changes, and expected warning behavior.
  4. Maintainer can verify every still-supported deprecated path has a documented replacement and no planned removal before `v2.0`.
**Plans**: TBD

Plans:
- [ ] TBD

### Phase 37: Contract Enforcement and Trust Docs
**Goal**: Maintainers can prove the documented contract stays honest, and adopters can rely on stable testing and admin semantics without depending on internals.
**Depends on**: Phase 36
**Requirements**: PROOF-01, PROOF-02, PROOF-03, PROOF-04
**Success Criteria** (what must be TRUE):
  1. Maintainer can run one stability verification workflow that detects drift between the documented public surface and the shipped `mailglass` and `mailglass_admin` surface.
  2. Maintainer can detect leaked internal modules, docs, types, mix tasks, or sibling-package contract violations before release.
  3. Adopter can rely on one documented testing contract covering inline, async, Oban, and cross-process delivery workflows.
  4. Adopter can rely on admin mount, auth, and operator-action docs that describe stable semantics without freezing DOM, component, or LiveView internals.
**Plans**: TBD

Plans:
- [ ] TBD

### Phase 38: Release Rehearsal and Proof Artifacts
**Goal**: Maintainers have fresh proof artifacts showing the documented install, upgrade, docs, and sibling-package release flow are trustworthy enough for `v1.0`.
**Depends on**: Phase 37
**Requirements**: RELS-01, RELS-02, RELS-03, RELS-04
**Success Criteria** (what must be TRUE):
  1. Maintainer can prove a clean Phoenix app can install released `mailglass` and `mailglass_admin` packages from Hex, mount admin, and complete the documented first-send workflow.
  2. Maintainer can prove an app on the latest `0.x` upgrade path can reach `v1.0` using the documented migration steps and smoke checks.
  3. Maintainer can verify tarball contents, HexDocs inputs, and sibling-package version pins before publish so release artifacts match the documented contract.
  4. Maintainer can execute a release checklist that includes the required CI buckets and any remaining manual external checks needed for a trustworthy `v1.0` cut.
**Plans**: TBD

Plans:
- [ ] TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 35. Stability Contract Audit | 0/TBD | Not started | - |
| 36. Deprecation and Compatibility Contract | 0/TBD | Not started | - |
| 37. Contract Enforcement and Trust Docs | 0/TBD | Not started | - |
| 38. Release Rehearsal and Proof Artifacts | 0/TBD | Not started | - |

## Backlog

### Phase 999.1: Human-Readable Code Comments + GSD Artifact Cleanup (BACKLOG)
**Goal:** Reduce distracting internal planning references such as `D-20`, phase-plan IDs, and similar GSD artifacting in source comments so the code reads cleanly for humans while preserving the intent behind important architectural notes
**Requirements:** TBD
**Plans:** 5/5 plans complete

Plans:
- [ ] TBD (promote with $gsd-review-backlog when ready)

### Phase 999.2: Shift-Left Email Screenshot + Responsive Preview Workflow (BACKLOG)
**Goal:** Make it easy at any time to see realistic rendered example emails across themes and mobile/responsive layouts, ideally through an idiomatic low-friction workflow such as a mix task, preview pipeline, or CI-generated screenshots
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with $gsd-review-backlog when ready)
