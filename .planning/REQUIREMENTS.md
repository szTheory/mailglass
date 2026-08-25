# Requirements: Mailglass v2.7 Repository Stewardship & Operational Hygiene

**Defined:** 2026-08-21
**Core Value:** Email you can see, audit, and trust before it ships.

## v2.7 Requirements

### Workspace Integrity and Evidence Preservation

- [x] **WSPC-01**: A maintainer can inspect a recorded inventory of every linked worktree, stash, relevant local/remote branch, divergent commit range, and release leftover before any cleanup mutates it.
- [x] **WSPC-02**: A maintainer has one documented canonical `main` checkout whose upstream and ahead/behind state are explained and whose working tree contains no unexplained changes.
- [x] **WSPC-03**: Every inventoried workspace or Git object has an explicit retain, handoff, merge, archive, or remove disposition backed by unique-work and reachability evidence.
- [x] **WSPC-04**: Approved cleanup uses normal Git-managed operations and preserves any unique or uncertain work on a recoverable ref or documented handoff before removal.

### Automation and Release Truth

- [ ] **AUTO-01**: A maintainer can reconcile PR #222, its head/base commits and checks, tags, published Hex versions, and `.planning/release-target.json` to one evidence-backed release-state narrative.
- [ ] **AUTO-02**: PR #222 and each stale release branch/check are merged only through the protected path, retired with a recorded reason, or retained with a named recovery condition; no auto-merge or check remains in unexplained limbo.
- [x] **AUTO-03**: Release-please produces a truthful proposal-only result through its current control and scheduled entry points without gaining merge, tag, publish, or protected-dispatch authority.
- [x] **AUTO-04**: Repository-hygiene automation reports an inspectable pass, policy block, or cannot-check result whose logs and JSON artifact agree, with both a control run and an observed scheduled run when scheduling is applicable.
- [ ] **AUTO-05**: Post-publish automation validates the exact immutable published target through its existing recovery path, or records an evidence-backed inapplicable/blocked disposition without substituting `main` or forcing a release.

### Deterministic Release-Path Gates

- [ ] **DTRM-01**: A maintainer can reproduce and repair the observed PostgreSQL SQLSTATE 57014 property-test failure at its narrow fixture, session, isolation, or query boundary while retaining the invariant and 1,000 successful property executions.
- [ ] **DTRM-02**: Focused repeated property proof and the canonical protected CI path pass without seed-pinning, skipping the property, changing product schemas/APIs, or loosening global database or job timeouts.
- [ ] **DTRM-03**: A maintainer can reproduce and repair the observed gallery-matrix timeout at its narrow readiness, test, or Playwright configuration boundary while retaining discovered-specimen, viewport, theme, stress, and overflow coverage.
- [ ] **DTRM-04**: Focused repeated browser proof and the relevant operator-browser gate pass without changing the admin UI, removing matrix cells, adding broad retries, or replacing bounded execution with an unlimited/global timeout.

### Repository Truth and Closeout

- [ ] **TRTH-01**: Maintainer, version, release, recovery, and package guidance agrees with the settled protected-release workflow, published package state, and actual supported commands.
- [ ] **TRTH-02**: Every changed tracked/generated artifact and ignore rule has an evidence-backed classification; only demonstrable junk or stale output is removed, and planning/release proof remains tracked and discoverable.
- [ ] **TRTH-03**: A maintainer can reproduce final closeout evidence showing the canonical workspace clean, protected main CI green, scheduled/recovery outcomes explained, and every audited item dispositioned.

## Future Requirements

No future capabilities are promoted by this milestone. New needs discovered during execution return to backlog review rather than expanding v2.7 implicitly.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Product, API, schema, provider, or admin UI changes | v2.7 is repository stewardship; adopter-facing behavior remains on the v2.6 baseline. |
| Dependency, action, Beam, Node, browser, or database upgrades | Research found the existing pinned stack sufficient; version churn adds unrelated risk. |
| CI efficiency or topology redesign | The milestone repairs truthful outcomes, not runtime or workflow architecture. |
| Broad timeout increases, retries, skipped tests, reduced property counts, or reduced browser matrices | These can manufacture green checks while hiding the observed deterministic failures. |
| Automatic bulk deletion, force removal, history rewriting, reset, or force-push cleanup | Cleanup must preserve evidence and uncertain work through recoverability-first dispositions. |
| Generic worktree tooling, automation dashboards, or new maintenance services | Existing Git, GitHub Actions, Mix tasks, and release scripts already provide the needed control plane. |
| Broad ignore rules for `.planning/`, release, publish, or generated-host evidence | These paths contain contractual and forensic proof, not disposable cache by default. |
| Cosmetic reorganization or formatting churn | Changes require a demonstrated truth, safety, or maintenance benefit. |
| A new Hex release performed only to close the milestone | Publication occurs only if a genuine adopter-facing correction requires it and the protected release path authorizes it. |
| SEED-006 CI efficiency overhaul | The archived pull-gated seed is performance redesign, outside this bounded stewardship milestone. |

## Traceability

Every v2.7 requirement is assigned to exactly one planned phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| WSPC-01 | Phase 161 | Complete |
| WSPC-02 | Phase 161 | Complete |
| WSPC-03 | Phase 161 | Complete |
| WSPC-04 | Phase 161 | Complete |
| AUTO-01 | Phase 162 | Gaps Found |
| AUTO-02 | Phase 162 | Gaps Found |
| AUTO-03 | Phase 162 | Gaps Found |
| AUTO-04 | Phase 162 | Gaps Found |
| AUTO-05 | Phase 162 | Gaps Found |
| DTRM-01 | Phase 163 | Pending |
| DTRM-02 | Phase 163 | Pending |
| DTRM-03 | Phase 163 | Pending |
| DTRM-04 | Phase 163 | Pending |
| TRTH-01 | Phase 164 | Pending |
| TRTH-02 | Phase 164 | Pending |
| TRTH-03 | Phase 164 | Pending |

**Coverage:**

- v2.7 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-08-21*
*Last updated: 2026-08-22 after Phase 161 verification*
