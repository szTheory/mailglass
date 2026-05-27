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
- 🚧 **v1.3 Adopter Trust Proof** — Phases 52-56 (planned 2026-05-27)

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
<summary>🚧 v1.3 Adopter Trust Proof (Phases 52-56) — PLANNED 2026-05-27</summary>

**Goal:** Prove adoption confidence with one maintained Phoenix reference host app and deterministic trust evidence across local, CI, and published-version release checks.

**Scope lock:** trust-proof milestone only (no provider-matrix broadening, no `gen_smtp` expansion, no `SEED-003` auto-promotion).

**Requirements coverage:** 16/16 mapped from `.planning/REQUIREMENTS.md` (HOST/JOUR/EVID/DOCB/OPS categories).

- [x] Phase 52: Trust Scope Lock + Reference Host Baseline (0/3 plans) (completed 2026-05-27)
- [ ] Phase 53: Deterministic End-to-End Trust Journey (0/0 plans)
- [ ] Phase 54: CI Trust Lanes + Checkpoint Artifacts (0/0 plans)
- [ ] Phase 55: Docs Boundary + Contract Positioning (0/0 plans)
- [ ] Phase 56: Drift Prevention + Release-Gate Integration (0/0 plans)

### Phase Details

**Phase 52: Trust Scope Lock + Reference Host Baseline**  
Goal: establish one thin maintained reference host app with explicit proof-scope allowlist and non-goals.  
Requirements: HOST-01, HOST-02, HOST-03  
Success criteria:

1. Maintained reference host boots from clean checkout and documented setup.
2. Host integration boundary uses public Mailglass seams only.
3. Scope allowlist and non-goals are committed and enforced as review criteria.

**Phase 53: Deterministic End-to-End Trust Journey**  
Goal: make trust proof reproducible with one command and deterministic fixtures.  
Requirements: JOUR-01, JOUR-02, JOUR-03, JOUR-04  
Success criteria:

1. One runner command executes install -> preview -> send -> webhook ingest -> operator troubleshooting.
2. Fixtures and assertions are deterministic across repeated runs.
3. Webhook proof uses signed verify-first route path and includes one negative signature case.
4. Operator diagnosis flow includes one scripted non-happy-path scenario.

**Phase 54: CI Trust Lanes + Checkpoint Artifacts**  
Goal: block drift with required CI trust lanes and machine-readable evidence.  
Requirements: EVID-01, EVID-02, EVID-04  
Success criteria:

1. Repo-head trust lane is required and fails on missing checkpoints.
2. Clean-baseline lane enforces Hex-first resolution and fails on path-dependency leakage.
3. Trust lanes emit checkpoint artifacts used by release evidence.

**Phase 55: Docs Boundary + Contract Positioning**  
Goal: keep reference-app usage proof separate from API-contract truth.  
Requirements: DOCB-01, DOCB-02, DOCB-03  
Success criteria:

1. Reference docs explicitly state usage-proof-only boundary.
2. Canonical contract documents/tests are linked at every trust-journey touchpoint.
3. Docs contract checks enforce boundary language and prevent accidental API guarantees.

**Phase 56: Drift Prevention + Release-Gate Integration**  
Goal: operationalize trust-proof reliability and close active smoke-risk debt.  
Requirements: EVID-03, OPS-01, OPS-02  
Success criteria:

1. Post-publish/published-version trust journey runs before milestone trust claims are accepted.
2. Active hackney smoke failure is resolved with regression protection.
3. Release checklist and maintenance cadence require green trust evidence.

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
**Plans:** 0 plans

Plans:

- [ ] TBD (promote with $gsd-review-backlog when ready)

## Notes

**Release-cadence rule (added 2026-05-06):** Each milestone closes with a release ceremony (Phase X.5 by convention). Don't start the next milestone implementation while previous-milestone work is unreleased. The 4-milestone-deep gap between v0.3.2 and 1.0.0 is the failure mode this rule prevents.
