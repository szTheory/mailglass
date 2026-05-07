# Roadmap: mailglass

**Granularity:** standard (config.json)
**Active sibling package milestone:** `mailglass_inbound` core slice (`v1.1`)

## Milestones

- ✅ **v0.1 Validation Release** — Phases 1-7 + 07.1 (shipped 2026-04-26) — see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** — Phases 8-13 (shipped 2026-04-28) — see [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** — Phases 14-21 (shipped 2026-04-30) — see [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Operator Confidence** — Phases 22-27 (shipped 2026-05-02) — see [milestones/v0.4-ROADMAP.md](milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 Adoption Hardening** — Phases 28-31 (shipped 2026-05-03) — see [milestones/v0.5-ROADMAP.md](milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 Production Maturity** — Phases 32-34 (shipped 2026-05-05) — see [milestones/v0.6-ROADMAP.md](milestones/v0.6-ROADMAP.md)
- ✅ **v1.0 Stability Lock** — Phases 35-38 (shipped 2026-05-06) — see [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)
- 🚧 **v1.1 Inbound Core Slice** — Phases 39-44 (active; audit gap closure phases added 2026-05-06)

## Current Milestone

### v1.1 Inbound Core Slice

**Status:** Active. Product implementation phases 39-42 are complete; audit gap closure phases 43-44 are next.
**Phases:** 39-44
**Total Plans:** 12

## Overview

v1.1 is the first deliberate expansion beyond the locked outbound/admin core.
The milestone opens `mailglass_inbound` as a sibling package, but keeps the
scope narrow enough to ship honestly: one canonical inbound model, one routing
surface, first-party Postmark and SendGrid ingress, durable storage for
normalized plus raw source data, and async mailbox execution that prefers Oban
without requiring it.

The milestone does **not** include the remaining live `v1.0` publish closeout,
Conductor UI, SMTP relay ingress, or long-tail provider parity.

## Phases

### Phase 39: Inbound Package Foundation

**Goal**: Define the canonical `mailglass_inbound` package contract, including the normalized inbound model, routing DSL, mailbox behaviour, and tenant-safe storage foundation.
**Depends on**: Phase 38
**Plans**: 3 plans
**Status:** Complete (2026-05-06)

Plans:

- [x] 39-01: Define the canonical `InboundMessage` struct plus router and mailbox behaviour contract
- [x] 39-02: Establish tenant-safe persistence for normalized inbound records plus raw source evidence
- [x] 39-03: Wire sibling package scaffolding, optional-dependency seams, and baseline docs/tests

### Phase 40: Postmark Ingress And Replayable Persistence

**Goal**: Accept authentic Postmark inbound payloads, normalize them, persist replayable evidence, and hand them into the package routing contract.
**Depends on**: Phase 39
**Plans**: 3 plans
**Status:** Complete (2026-05-06)

Plans:

- [x] 40-01: Implement Postmark inbound verification and normalization into the canonical `InboundMessage`
- [x] 40-02: Persist normalized plus raw provider source data with replay-oriented storage semantics
- [x] 40-03: Add Postmark ingress docs and contract proof for parse, storage, and rejection paths

### Phase 41: SendGrid Ingress And Mailbox Routing

**Goal**: Extend the package to a second provider shape and prove the routing/mailbox contract against real inbound execution paths.
**Depends on**: Phase 40
**Plans**: 3 plans
**Status:** Complete (2026-05-06)

Plans:

- [x] 41-01: Implement SendGrid inbound parse verification and normalization into the canonical `InboundMessage`
- [x] 41-02: Route matched inbound messages through mailbox execution with explicit accept/reject/ignore/bounce outcomes
- [x] 41-03: Extend replay, persistence, and second-provider contract proof without re-receive ambiguity

### Phase 42: Async Execution And Adopter Proof

**Goal**: Make the first inbound slice operationally credible with Oban-backed execution, bounded fallback semantics, and honest install/test/operator docs.
**Depends on**: Phase 41
**Plans**: 3 plans
**Status:** Complete (2026-05-06)

Plans:

- [x] 42-01: Add Oban-backed inbound execution plus a supported non-Oban fallback path
- [x] 42-02: Publish canonical install, testing, and operator-trust docs for the core inbound slice
- [x] 42-03: Extend sibling-package release and root verification proof to cover `mailglass_inbound`

### Phase 43: Execution Verification Recovery

**Goal**: Restore execution-level verification evidence for the inbound implementation phases so milestone requirements can be satisfied under the three-source audit check.
**Depends on**: Phase 42
**Requirements**: MODEL-01, ROUTE-01, MAILBOX-01, INGRESS-01, STORE-01, INGRESS-02, STORE-02
**Gap Closure:** Closes execution verification and validation gaps identified by the `v1.1` milestone audit.
**Plans**: 0 plans
**Status:** Pending

Plans:

- [ ] TBD (`$gsd-plan-phase 43`)

### Phase 44: Async Adoption Closeout Reconciliation

**Goal**: Complete async/adopter verification evidence and reconcile milestone bookkeeping so closeout records no longer contradict the audit.
**Depends on**: Phase 43
**Requirements**: EXEC-01, EXEC-02, ADOPT-01
**Gap Closure:** Closes closeout-readiness integration gaps and the remaining milestone verification chain gaps from the `v1.1` audit.
**Plans**: 2 plans
**Status:** Pending

Plans:

**Wave 1**
- [x] 44-01-PLAN.md — Recover Phase 42 execution verification report (42-VERIFICATION.md) from re-run proof lanes

**Wave 2** *(blocked on Wave 1 completion)*
- [ ] 44-02-PLAN.md — Reconcile REQUIREMENTS.md, STATE.md, ROADMAP.md and produce v1.1-MILESTONE-AUDIT-CLOSEOUT.md

---

## Milestone Summary

**Decimal Phases:**

- None planned.

**Key Decisions:**

- Keep the first inbound milestone narrow: Postmark and SendGrid only, not full provider parity.
- Store both normalized inbound records and raw provider source material so replay/debug truth is first-class from day one.
- Preserve Mailglass's optional-Oban philosophy rather than making inbound execution Oban-only.

**Deferred From This Milestone:**

- Live `v1.0` publish closeout and external branch-protection proof
- Conductor-style dev UI
- Mailgun, SES, and `gen_smtp` relay ingress
- Adjacent deliverability workflow bets unrelated to the inbound package contract

## Backlog

### Phase 999.1: Human-Readable Code Comments + GSD Artifact Cleanup (BACKLOG)
**Goal:** Reduce distracting internal planning references such as `D-20`, phase-plan IDs, and similar GSD artifacting in source comments so the code reads cleanly for humans while preserving the intent behind important architectural notes
**Requirements:** TBD
**Plans:** 3/3 plans complete

Plans:
- [ ] TBD (promote with $gsd-review-backlog when ready)

### Phase 999.2: Shift-Left Email Screenshot + Responsive Preview Workflow (BACKLOG)
**Goal:** Make it easy at any time to see realistic rendered example emails across themes and mobile/responsive layouts, ideally through an idiomatic low-friction workflow such as a mix task, preview pipeline, or CI-generated screenshots
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with $gsd-review-backlog when ready)
