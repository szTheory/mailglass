# Roadmap: mailglass

**Granularity:** standard (config.json)

## Milestones

- ✅ **v0.1 Validation Release** — Phases 1-7 + 07.1 (shipped 2026-04-26) — [archive](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** — Phases 8-13 (shipped 2026-04-28) — [archive](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** — Phases 14-21 (shipped 2026-04-30) — [archive](milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Operator Confidence** — Phases 22-27 (shipped 2026-05-02) — [archive](milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 Adoption Hardening** — Phases 28-31 (shipped 2026-05-03) — [archive](milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 Production Maturity** — Phases 32-34 (shipped 2026-05-05) — [archive](milestones/v0.6-ROADMAP.md)
- ✅ **v1.0 Stability Lock** — Phases 35-38 (shipped 2026-05-06) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Inbound Core Slice** — Phases 39-44 (shipped 2026-05-06) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Inbound Production Confidence** — Phases 44.5, 45-50, 50.5, 50.7, 51 (shipped 2026-05-26) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Adopter Trust Proof** — Phases 52, 57-62 (shipped 2026-05-31) — [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 Inbound Stability Lock** — Phases 63-66 (shipped 2026-06-01) — [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 Demo Evidence and Click-Around Confidence** — Phases 67-70 (shipped 2026-06-02) — [archive](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 Inbound 1.0 Release and Truth Lock** — Phases 71-73 (shipped 2026-06-02) — [archive](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 Admin UI — IA & Design-System Polish v2** — Phases 74-79 (shipped 2026-06-05) — [archive](milestones/v1.7-ROADMAP.md)
- ✅ **v1.8 Brand System and Repo-Ready Brandbook** — Phases 80-84 (closed superseded 2026-06-11) — [archive](milestones/v1.8-ROADMAP.md)
- ✅ **v1.9 Brand Book Fable — A/B Brand System** — Phases 85-90 (shipped 2026-06-12) — [archive](milestones/v1.9-ROADMAP.md)
- ✅ **v1.10 Brand Adoption** — Phases 91-93 (shipped 2026-06-13) — [archive](milestones/v1.10-ROADMAP.md)
- ✅ **v1.11 mailglass_admin Design-System Uplift** — Phases 94-103 (shipped 2026-06-16) — [archive](milestones/v1.11-ROADMAP.md)
- ✅ **v1.12 Adopter Onboarding & Day-2 Confidence** — Phases 104-108 (shipped 2026-06-17) — [archive](milestones/v1.12-ROADMAP.md)
- ✅ **v1.13 Admin Design-System Stress Test & UX Uplift (v3)** — Phases 109-117 (shipped 2026-06-21) — [archive](milestones/v1.13-ROADMAP.md)
- ✅ **v1.14 Operator IA & Lived-Experience Redesign** — Phases 118-124 (shipped 2026-06-30) — [archive](milestones/v1.14-ROADMAP.md)
- ✅ **v1.15 Release-Pipeline Efficiency & Contributor DX** — Phases 125-131 (shipped 2026-07-02) — [archive](milestones/v1.15-ROADMAP.md)
- ✅ **v2.0 Postgres Schema Isolation** — Phases 132-137 (shipped 2026-07-04) — [archive](milestones/v2.0-ROADMAP.md)
- ✅ **v2.1 Postgres + Admin URL Hardening** — Phases 138-140 (shipped 2026-07-08) — [archive](milestones/v2.1-ROADMAP.md)
- ✅ **v2.2 CI Signal Integrity & Supply-Chain Hygiene** — Phases 141-144 (shipped 2026-07-31) — [archive](milestones/v2.2-ROADMAP.md)
- ✅ **v2.3 B2C First-Adopter Readiness** — Phases 145-148 (shipped 2026-08-02) — [archive](milestones/v2.3-ROADMAP.md)
- ✅ **v2.4 Outbound First-Adopter Correctness** — Phases 149-153 (shipped 2026-08-04) — [archive](milestones/v2.4-ROADMAP.md)
- ◆ **v2.5 B2C Alpha Adoption Certification** — Phase 154 (in progress)

## Phases

- [ ] **Phase 154: Executable Alpha Certification**
  - **Goal:** Produce fresh, reproducible evidence that the released v2.4.1 package family is safe to integrate, or isolate a proven defect without expanding scope.
  - **Requirements:** CERT-01, CERT-02, CERT-03, SAFE-01, SAFE-02, SAFE-03
  - **Success criteria:**
    1. Package-shaped local and exact-Hex generated-host journeys pass every documented stage with bounded checkpoint evidence.
    2. First-send, durable outbound, payload privacy/lifecycle, feedback, and one-click suppression contracts pass against the release baseline.
    3. Provider/webhook, schema, optional-runtime, docs, and safety-only operator checks either pass or have a precisely classified, reproducible failure.
    4. A final go/no-go report separates library readiness from adopter-owned deployment prerequisites and does not claim an unsupported production guarantee.
    5. Any proven library defect is fixed with regression coverage and recertified; no release occurs if no source defect exists.

<details>
<summary>✅ v2.4 Outbound First-Adopter Correctness (Phases 149-153) — SHIPPED 2026-08-04</summary>

- [x] Phase 149: First-Send Contract Foundation (4/4 plans) — completed 2026-08-02
- [x] Phase 150: Private Envelope and Atomic Durable Enqueue (9/9 plans) — completed 2026-08-02
- [x] Phase 151: Unified Dispatch, Honest Outcomes, and Payload Lifecycle (8/8 plans) — completed 2026-08-03
- [x] Phase 152: Atomic One-Click Suppression Convergence (3/3 plans) — completed 2026-08-03
- [x] Phase 153: Generated-Host Proof, Docs, and Release Gate (8/8 plans) — completed 2026-08-04

</details>

No active milestone. Start the next milestone with `$gsd-new-milestone`.
