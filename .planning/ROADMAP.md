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

**Progress:** 1/6 phases complete

| Phase | Status | Goal | Requirements |
|-------|--------|------|--------------|
| 22 | Complete | Establish the read-only operator data foundation for deliveries, timelines, and suppression visibility. | `ADMIN-02`, `ADMIN-03`, `ADMIN-04` |
| 23 | Pending | Make the operator surface production-mountable and enforce step-up auth on destructive actions. | `ADMIN-01`, `ADMIN-05` |
| 24 | Pending | Add tenant-safe webhook replay with durable audit context. | `REPLAY-01`, `REPLAY-02`, `REPLAY-03` |
| 25 | Pending | Ship `mix mail.doctor` with actionable DNS deliverability diagnostics. | `DOCTOR-01`, `DOCTOR-02`, `DOCTOR-03` |
| 26 | Pending | Add runtime per-tenant outbound adapter resolution without breaking single-tenant defaults. | `TENANT-01`, `TENANT-02`, `TENANT-03` |
| 27 | Pending | Close the known install and post-publish smoke gaps before milestone ship. | `REL-17`, `REL-18` |

**Next up:** `$gsd-plan-phase 23`

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
