# Roadmap: mailglass

**Granularity:** standard (config.json)
**Sibling package out of milestone:** `mailglass_inbound` (v0.6+, not roadmapped here)

## Milestones

- ✅ **v0.1 Validation Release** — Phases 1-7 + 07.1 (shipped 2026-04-26) — see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** — Phases 8-13 (shipped 2026-04-28) — see [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** — Phases 14-21 (shipped 2026-04-30) — see [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Operator Confidence** — Phases 22-27 (shipped 2026-05-02) — see [milestones/v0.4-ROADMAP.md](milestones/v0.4-ROADMAP.md)

## Current Milestone

### v0.5 Adoption Hardening

**Goal:** Reduce adopter friction and close the “serious SaaS team” integration gaps.

**Why now:** Once the operator story is real, the next leverage comes from making setup, scaffolding, testing, and troubleshooting feel unusually smooth.

**Progress:** 0/4 phases complete

| Phase | Status | Goal | Requirements |
|-------|--------|------|--------------|
| 28 | Not started | Developers can scaffold mailables instantly without looking up boilerplate. | `SCAFFOLD-01` |
| 29 | Not started | Developers can confidently write tests for their mailables and webhooks using dedicated assertion helpers. | `TEST-01`, `TEST-02` |
| 30 | Not started | Operators can protect domain reputation through configurable per-domain rate limiting. | `RATE-01`, `RATE-02` |
| 31 | Not started | Adopters experience zero friction during install and have clear troubleshooting runbooks for operational edge cases. | `DOCS-01`, `DOCS-02`, `REL-19` |

## Phase Details

### Phase 28: Mailable Scaffolding
**Goal**: Developers can scaffold mailables instantly without looking up boilerplate.
**Depends on**: Phase 27
**Requirements**: SCAFFOLD-01
**Success Criteria**:
  1. `mix mailglass.gen.mailable` generates a module and HEEx template.
  2. Generated mailables compile and work out of the box.
**Plans**: 1/1 complete

Plans:
- [ ] 28-01-PLAN.md — Mailable Code Generator

### Phase 29: Test Assertion Helpers
**Goal**: Developers can confidently write tests for their mailables and webhooks using dedicated assertion helpers.
**Depends on**: Phase 28
**Requirements**: TEST-01, TEST-02
**Success Criteria**:
  1. User can assert a mailable was dispatched with specific assigns.
  2. User can simulate and assert webhook handling easily in tests.
**Plans**: 0/0 complete

Plans:
- [ ] TBD — plan with `$gsd-plan-phase 29`

### Phase 30: Per-Domain Rate Limiting
**Goal**: Operators can protect domain reputation through configurable per-domain rate limiting.
**Depends on**: Phase 29
**Requirements**: RATE-01, RATE-02
**Success Criteria**:
  1. The system throttles outbound dispatch per-domain based on configuration.
  2. Rate limiting includes sensible defaults that prevent unintentional bursts.
**Plans**: 0/0 complete

Plans:
- [ ] TBD — plan with `$gsd-plan-phase 30`

### Phase 31: Documentation & Reliability Tightening
**Goal**: Adopters experience zero friction during install and have clear troubleshooting runbooks for operational edge cases.
**Depends on**: Phase 30
**Requirements**: DOCS-01, DOCS-02, REL-19
**Success Criteria**:
  1. New users can install and smoke test without hitting known brittle edge cases.
  2. Operators can resolve webhook delivery issues using the troubleshooting guide.
  3. Upgrades are straightforward due to clear and actionable migration docs.
**Plans**: 0/0 complete

Plans:
- [ ] TBD — plan with `$gsd-plan-phase 31`

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