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
- 🚧 **v2.3 B2C First-Adopter Readiness** — Phases 145-148 (active)

## Active Milestone: v2.3 B2C First-Adopter Readiness

**Goal:** Make the safe single-tenant consumer launch path opinionated, automated, and observable while preserving ownership boundaries across the package family.

- [x] **Phase 145: B2C Safety Profile** — Publish the stream, suppression, single-tenant, cold-domain, MPP, package-boundary, launch-gate, and Crosswake decisions.
- [x] **Phase 146: Provider-Feedback Contract** — Add the stable PII-free post-commit feedback event with replay convergence.
- [x] **Phase 147: Live Solo-Operator Admin** — Refresh tenant-scoped delivery and evidence state from existing PubSub signals without reloads.
- [ ] **Phase 148: Release and Adoption Proof** — Run suppression/docs/browser proofs, cut linked core/admin 2.4.0, and smoke the published consumer path without bumping inbound unnecessarily.

**Execution order:** 145 → 146 → 147 → 148. Phase 148 release publication remains gated by all Mailglass tests and the external B2C launch checklist in `REQUIREMENTS.md`.

### Phase 148: Release and Adoption Proof

**Goal**: Prove the locked suppression, documentation, and live-operator behaviors; release linked `mailglass` and `mailglass_admin` 2.4.0 without republishing `mailglass_inbound`; and validate a clean consumer install from the published packages.
**Depends on**: Phase 145 (B2C safety and package-boundary decisions), Phase 146 (provider-feedback contract), and Phase 147 (live solo-operator admin proof)
**Requirements**: PROOF-02, PROOF-03, REL-01
**Success Criteria** (what must be TRUE):

  1. Focused suppression evidence proves stream unsubscribe remains stream-scoped while complaint and hard-bounce suppression remains address-wide and blocks transactional delivery.
  2. B2C documentation-contract evidence proves every published guide example parses against current APIs and `guides/b2c-first-adopter.md` remains in the HexDocs/package surface.
  3. The release-proof bundle includes the tenant-scoped LiveView refresh and foreign-tenant rejection evidence delivered by Phase 147.
  4. Release Please and protected Hex publication produce linked `mailglass` and `mailglass_admin` 2.4.0 releases while `mailglass_inbound` remains at 2.1.1 and is neither republished nor required for the core/admin publish fan-out to complete.
  5. `scripts/consumer_install_smoke.sh` passes both the shift-left local-path proof and the post-publication Hex-mode proof from a clean consumer using the versions adopters actually install.

**Plans**: 1/5 plans executed

Plans:
**Wave 1**

- [x] 148-01-PLAN.md — Prove the protected core/admin release path and establish the evidence ledger.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 148-02-PLAN.md — Isolate Release Please sync and upload sanitized prepublish proof.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 148-03-PLAN.md — Capture commit-bound behavioral, consumer, and release preflight evidence.

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 148-04-PLAN.md — Pause for go/no-go and run the protected one-way release ceremony.

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 148-05-PLAN.md — Verify Hex versions and finalize the published-consumer proof.
