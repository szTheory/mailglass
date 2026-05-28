# Roadmap: mailglass

**Granularity:** standard (config.json)

## Milestones

- ✅ **v0.1 Validation Release** — Phases 1-7 + 07.1 (shipped 2026-04-26) — see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** — Phases 8-13 (shipped 2026-04-28) — see [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** — Phases 14-21 (shipped 2026-04-30) — see [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Operator Confidence** — Phases 22-27 (shipped 2026-05-02) — see [milestones/v0.4-ROADMAP.md](milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 Adoption Hardening** — Phases 28-31 (shipped 2026-05-03) — see [milestones/v0.5-ROADMAP.md](milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 Production Maturity** — Phases 32-34 (shipped 2026-05-05) — see [milestones/v0.6-ROADMAP.md](milestones/v0.6-ROADMAP.md)
- ✅ **v1.0 Stability Lock** — Phases 35-38 (shipped 2026-05-06) — see [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Inbound Core Slice** — Phases 39-44 (shipped 2026-05-06) — see [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Inbound Production Confidence** — Phases 44.5, 45-50, 50.5, 50.7, 51 (shipped 2026-05-26) — see [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- 🚧 **v1.3 Adopter Trust Proof** — Phases 52, 57-61 (planned 2026-05-27)

## Phases

<details>
<summary>✅ v1.1 Inbound Core Slice (Phases 39-44) — SHIPPED 2026-05-06</summary>

- [x] Phase 39: Inbound Package Foundation (3/3 plans) — completed 2026-05-06
- [x] Phase 40: Postmark Ingress And Replayable Persistence (3/3 plans) — completed 2026-05-06
- [x] Phase 41: SendGrid Ingress And Mailbox Routing (3/3 plans) — completed 2026-05-06
- [x] Phase 42: Async Execution And Adopter Proof (3/3 plans) — completed 2026-05-06
- [x] Phase 43: Execution Verification Recovery (3/3 plans) — completed 2026-05-06
- [x] Phase 44: Async Adoption Closeout Reconciliation (2/2 plans) — completed 2026-05-06

Audit re-passed 2026-05-07 after Phase 43 + 44 closeout. Full archive at [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md).

</details>

<details>
<summary>✅ v1.2 Inbound Production Confidence (Phases 44.5, 45-50, 50.5, 50.7, 51) — SHIPPED 2026-05-26</summary>

- [x] Phase 44.5: v1.0/1.1 Release Ceremony (5/5 plans) — completed 2026-05-07
- [x] Phase 45: Inbound Telemetry + Idempotency Foundation (12/12 plans) — completed 2026-05-23
- [x] Phase 46: Mailgun + SES Inbound Ingress (3/3 plans) — completed 2026-05-23
- [x] Phase 47: Inbound Test Helpers + Generators (4/4 plans) — completed 2026-05-24
- [x] Phase 48: Inbound Admin LiveView (3/3 plans) — completed 2026-05-24
- [x] Phase 49: Inbound Runtime Operator Tooling (3/3 plans) — completed 2026-05-25
- [x] Phase 50: Inbound Documentation Pass (3/3 plans) — completed 2026-05-25
- [x] Phase 50.5: v1.2 Release Ceremony (3/3 plans) — completed 2026-05-26
- [x] Phase 50.7: v1.2 Repo Hygiene Pass (1/1 plan) — completed 2026-05-26
- [x] Phase 51: Stability Closeout (4/4 plans) — completed 2026-05-26

Audit passed 2026-05-26 after Phase 51 closeout. Full archive at [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md).

</details>

<details>
<summary>🚧 v1.3 Adopter Trust Proof (Phases 52, 57-61) — PLANNED 2026-05-27</summary>

**Goal:** Prove adoption confidence with one maintained Phoenix reference host app and deterministic trust evidence across local, CI, and published-version release checks.

**Scope lock:** trust-proof milestone only (no provider-matrix broadening, no `gen_smtp` expansion, no `SEED-003` auto-promotion).

**Requirements coverage:** 16/16 mapped from `.planning/REQUIREMENTS.md` (HOST/JOUR/EVID/DOCB/OPS categories).

- [x] Phase 52: Trust Scope Lock + Reference Host Baseline (0/3 plans) (completed 2026-05-27)
- [x] Phase 57: Deterministic Trust Runner + Fixtures (0/0 plans) (completed 2026-05-27)
- [x] Phase 58: Verify-First Webhook + Operator Path (2/2 plans) (completed 2026-05-27)
- [ ] Phase 59: CI Trust Lanes + Checkpoint Evidence (0/2 plans)
- [ ] Phase 60: Release Trust Gate + Drift Prevention (0/0 plans)
- [ ] Phase 61: Docs Contract Boundary Enforcement (0/0 plans)

### Phase Details

**Phase 52: Trust Scope Lock + Reference Host Baseline**  
Goal: establish one thin maintained reference host app with explicit proof-scope allowlist and non-goals.  
Requirements: HOST-01, HOST-02, HOST-03  
Success criteria:

1. Maintained reference host boots from clean checkout and documented setup.
2. Host integration boundary uses public Mailglass seams only.
3. Scope allowlist and non-goals are committed and enforced as review criteria.

**Phase 57: Deterministic Trust Runner + Fixtures**  
Goal: establish a deterministic trust-runner command and stable fixture/checkpoint harness for reproducible trust assertions.  
Requirements: JOUR-01, JOUR-02  
Success criteria:

1. One runner command executes install -> preview -> send -> webhook ingest -> operator troubleshooting.
2. Fixtures and IDs are deterministic across local reruns and CI.
3. Runner output emits stable checkpoints consumed by downstream trust lanes.

**Phase 58: Verify-First Webhook + Operator Path**  
Goal: complete trust journey proof for signed webhook verification and one deterministic non-happy-path diagnosis scenario.  
Requirements: JOUR-03, JOUR-04  
Plans:

- [x] 58-01-PLAN.md — Route-level Postmark verify-first proof and webhook_ingest runner evidence
- [x] 58-02-PLAN.md — Deterministic no-match operator evidence and checkpoint validator semantics

Success criteria:

1. Webhook proof executes the real verify-first signed payload route path.
2. Negative signature assertion is included and must fail deterministically.
3. Operator troubleshooting scenario is scripted with deterministic diagnosis evidence.
4. Runner and operator paths align on shared trust checkpoint semantics.

**Phase 59: CI Trust Lanes + Checkpoint Evidence**  
Goal: enforce trust proof in required CI lanes and publish machine-readable checkpoint evidence artifacts.  
Requirements: EVID-01, EVID-02, EVID-04  
Plans:

- [x] 59-01-PLAN.md — Wave 0 preconditions: reusable Hex-first guard script, parameterize gate-self-test, REQUIRED_CHECKS array/heredoc drift contract test
- [ ] 59-02-PLAN.md — Add repo-head + clean-baseline trust lanes to ci.yml, register repo-head in REQUIRED_CHECKS atomically, post-merge branch-protection re-assertion

Success criteria:

1. Repo-head trust lane is required and fails on missing trust checkpoints.
2. Clean-baseline trust lane enforces Hex-first dependency resolution and blocks path-dependency leakage.
3. CI emits machine-readable trust checkpoint artifacts for release evidence ingestion.

**Phase 60: Release Trust Gate + Drift Prevention**  
Goal: gate release trust claims on published-version trust evidence and close the active smoke-risk reliability gap.  
Requirements: EVID-03, OPS-01, OPS-02  
Success criteria:

1. Post-publish/published-version trust journey runs before milestone trust claims are accepted.
2. Active hackney smoke failure is resolved with regression protection.
3. Release checklist and maintenance cadence require green trust evidence.

**Phase 61: Docs Contract Boundary Enforcement**  
Goal: enforce reference-host docs as usage proof while directing contract guarantees to canonical API stability artifacts.  
Requirements: DOCB-01, DOCB-02, DOCB-03  
Success criteria:

1. Reference docs explicitly state usage-proof-only boundary.
2. Canonical stability contract documents and tests are linked at each trust-journey surface.
3. Docs contract verification blocks language that implies reference internals are public API guarantees.

</details>

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
**Plans:** 3/3 plans complete

Plans:

- [ ] TBD (promote with $gsd-review-backlog when ready)

## Notes

**Release-cadence rule (added 2026-05-06):** Each milestone closes with a release ceremony (Phase X.5 by convention). Don't start the next milestone implementation while previous-milestone work is unreleased. The 4-milestone-deep gap between v0.3.2 and 1.0.0 is the failure mode this rule prevents.
