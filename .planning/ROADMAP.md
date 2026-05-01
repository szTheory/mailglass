# Roadmap: mailglass

**Granularity:** standard (config.json)
**Sibling package out of milestone:** `mailglass_inbound` (v0.5+, not roadmapped here)

## Milestones

- ✅ **v0.1 Validation Release** — Phases 1-7 + 07.1 (shipped 2026-04-26) — see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** — Phases 8-13 (shipped 2026-04-28) — see [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** — Phases 14-21 (shipped 2026-04-30) — see [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)

## Current Milestone

### v0.4 Operator Confidence

**Goal:** Make mailglass credible for production operators, not just library authors.

**Why now:** Provider coverage is complete. The next missing layer is operator trust: mounting the admin safely, inspecting deliveries and timelines, replaying safely, validating deliverability posture, and closing fresh-host shipping gaps.

**Progress:** 2/6 phases complete

| Phase | Status | Goal | Requirements |
|-------|--------|------|--------------|
| 22 | Complete | Establish the read-only operator data foundation for deliveries, timelines, and suppression visibility. | `ADMIN-02`, `ADMIN-03`, `ADMIN-04` |
| 23 | Complete | Make the operator surface production-mountable and enforce step-up auth on destructive actions. | `ADMIN-01`, `ADMIN-05` |
| 24 | Pending | Add tenant-safe webhook replay with durable audit context. | `REPLAY-01`, `REPLAY-02`, `REPLAY-03` |
| 25 | Pending | Ship `mix mail.doctor` with actionable DNS deliverability diagnostics. | `DOCTOR-01`, `DOCTOR-02`, `DOCTOR-03` |
| 26 | Pending | Add runtime per-tenant outbound adapter resolution without breaking single-tenant defaults. | `TENANT-01`, `TENANT-02`, `TENANT-03` |
| 27 | Pending | Close the known install and post-publish smoke gaps before milestone ship. | `REL-17`, `REL-18` |

#### Phase 23 Plan Set

**Plans:** 3 plans

Plans:
- [x] `23-01-PLAN.md` — Split preview/operator router products, `live_session`s, and session whitelists; add operator-only production mount path.
- [x] `23-02-PLAN.md` — Add the adopter-owned recent-auth behavior/helper seam and wire operator mount/live assigns for future destructive checks.
- [x] `23-03-PLAN.md` — Lock the contract with router/auth/operator tests and update README + roadmap docs for preview versus production mounting.

**Next up:** `$gsd-plan-phase 24`

## Phase Details

### Phase 22: Operator Data Foundation
**Goal**: Establish the read-only operator data foundation for deliveries, timelines, and suppression visibility.
**Depends on**: Phase 21
**Requirements**: ADMIN-02, ADMIN-03, ADMIN-04
**Plans**: 3/3 complete

Plans:
- [x] `22-01-PLAN.md` — Add tenant-scoped operator delivery, timeline, and suppression read-model seams in core mailglass.
- [x] `22-02-PLAN.md` — Build the read-only operator LiveView on top of the new delivery/timeline/suppression data seams.
- [x] `22-03-PLAN.md` — Lock the operator UI contract with LiveView tests, responsive checks, and verification evidence.

### Phase 23: Production Admin Mount and Step-Up Auth
**Goal**: Make the operator surface production-mountable and enforce step-up auth on destructive actions.
**Depends on**: Phase 22
**Requirements**: ADMIN-01, ADMIN-05
**Plans**: 3/3 complete

Plans:
- [x] `23-01-PLAN.md` — Split preview/operator router products, `live_session`s, and session whitelists; add operator-only production mount path.
- [x] `23-02-PLAN.md` — Add the adopter-owned recent-auth behavior/helper seam and wire operator mount/live assigns for future destructive checks.
- [x] `23-03-PLAN.md` — Lock the contract with router/auth/operator tests and update README + roadmap docs for preview versus production mounting.

### Phase 24: Tenant-Safe Webhook Replay with Audit Context
**Goal**: Add tenant-safe webhook replay with durable audit context.
**Depends on**: Phase 23
**Requirements**: REPLAY-01, REPLAY-02, REPLAY-03
**Plans**: 0/0 complete

Plans:
- [ ] TBD — plan with `$gsd-plan-phase 24`

### Phase 25: Deliverability Doctor
**Goal**: Ship `mix mail.doctor` with actionable DNS deliverability diagnostics.
**Depends on**: Phase 24
**Requirements**: DOCTOR-01, DOCTOR-02, DOCTOR-03
**Plans**: 0/4 complete

Plans:
- [ ] `25-01-PLAN.md` — Define the shared deliverability result contract, resolver seam, and one-domain runtime entrypoint.
- [ ] `25-02-PLAN.md` — Implement the SPF, DKIM, and DMARC analyzers with explicit uncertainty semantics and test coverage.
- [ ] `25-03-PLAN.md` — Implement the MX and BIMI analyzers plus shared human/JSON formatting.
- [ ] `25-04-PLAN.md` — Ship the strict `mix mail.doctor` CLI wrapper, contract tests, and README usage/docs.

### Phase 26: Runtime Per-Tenant Adapter Resolution
**Goal**: Add runtime per-tenant outbound adapter resolution without breaking single-tenant defaults.
**Depends on**: Phase 25
**Requirements**: TENANT-01, TENANT-02, TENANT-03
**Plans**: 0/0 complete

Plans:
- [ ] TBD — plan with `$gsd-plan-phase 26`

### Phase 27: Release / Install Closure
**Goal**: Close the known install and post-publish smoke gaps before milestone ship.
**Depends on**: Phase 26
**Requirements**: REL-17, REL-18
**Plans**: 0/0 complete

Plans:
- [ ] TBD — plan with `$gsd-plan-phase 27`

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
