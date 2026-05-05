# Roadmap: mailglass

**Granularity:** standard (config.json)
**Sibling package out of milestone:** `mailglass_inbound` (post-`v1.0`, not roadmapped here)

## Milestones

- ✅ **v0.1 Validation Release** — Phases 1-7 + 07.1 (shipped 2026-04-26) — see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** — Phases 8-13 (shipped 2026-04-28) — see [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** — Phases 14-21 (shipped 2026-04-30) — see [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Operator Confidence** — Phases 22-27 (shipped 2026-05-02) — see [milestones/v0.4-ROADMAP.md](milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 Adoption Hardening** — Phases 28-31 (shipped 2026-05-03)

## Current Milestone

### v0.6 Production Maturity

**Goal:** Make mailglass resilient and legible under real production support conditions.

**Why now:** v0.5 reduced integration friction. The next gap before `v1.0` is operational maturity during real incidents, support, and regression prevention.

**Progress:** 3/3 phases complete

| Phase | Status | Goal | Requirements |
|-------|--------|------|--------------|
| 32 | ✅ Complete | Operators can replay and reconcile delivery state safely, with clear audit trails and defensible authorization boundaries. | `MAT-01` |
| 33 | ✅ Complete | Operators can diagnose production delivery issues through documented telemetry and incident-response workflows. | `MAT-02` |
| 34 | ✅ Complete | Maintainers can trust automated verification to catch the most material support and regression gaps before `v1.0`. | `MAT-03` |

## Phase Details

### Phase 32: Replay & Reconcile Hardening
**Goal**: Operators can replay and reconcile webhook-driven delivery state safely, with explicit guardrails around authorization, ambiguity, and audit outcomes.
**Depends on**: Phase 31
**Requirements**: MAT-01
**Success Criteria**:
  1. Replay and reconcile actions require tenant-safe target resolution and recent authorization where appropriate.
  2. Operator-visible replay outcomes stay auditable and clearly distinguish new work, no-op outcomes, and failures.
  3. Regression coverage exists for the most failure-prone replay/reconcile operator paths.
**Plans**: 3 plans

Plans:
- [x] 32-01-PLAN.md — Action-time replay authorization and exact-target guardrails
- [x] 32-02-PLAN.md — Shared repair-state wording for replay availability, outcome, and effect
- [x] 32-03-PLAN.md — Reconcile fallback contract, docs, and regression coverage

### Phase 33: Observability & Incident Support
**Goal**: Operators can diagnose production delivery issues through documented telemetry, backlog signals, and incident-response workflows.
**Depends on**: Phase 32
**Requirements**: MAT-02
**Success Criteria**:
  1. Delivery, webhook ingest, orphan reconciliation, and replay/reconcile signals are documented in one operator-facing support surface.
  2. Incident-response guidance explains how to diagnose the highest-value production failure modes without exposing PII.
  3. Support workflows are consistent with the actual telemetry and admin capabilities shipped in the codebase.
**Plans**: 3 plans

Plans:
- [x] 33-01-PLAN.md — Canonical incident guide, telemetry contract correction, and docs-alignment tests
- [x] 33-02-PLAN.md — Tenant-scoped support-summary read model backed by durable webhook and ledger facts
- [x] 33-03-PLAN.md — Operator support cards, privacy-minimized overview cues, and LiveView regression coverage

### Phase 34: Verification & Regression Closure
**Goal**: Maintainers can trust automated verification to catch the most material support and regression gaps before `v1.0`.
**Depends on**: Phase 33
**Requirements**: MAT-03
**Success Criteria**:
  1. The highest-risk deferred verification seams have explicit automated coverage or a documented enforced gate.
  2. CI/support validation reflects the actual production-maturity contract being promised for `v0.6`.
  3. The milestone can close without carrying forward material support-critical regressions as undocumented debt.
**Plans**: 3 plans

Plans:
- [x] 34-01-PLAN.md — Root support-contract authority and bootstrap honesty
- [x] 34-02-PLAN.md — Admin support-contract authority and bootstrap honesty
- [x] 34-03-PLAN.md — Honest orchestrator, explicit CI contract, and advisory/docs alignment

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
