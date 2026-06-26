# Roadmap: mailglass

**Granularity:** standard (config.json)

## Milestones

- ✅ **v0.1 Validation Release** - Phases 1-7 + 07.1 (shipped 2026-04-26) - see [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- ✅ **v0.2 Production-Credible Core** - Phases 8-13 (shipped 2026-04-28) - see [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)
- ✅ **v0.3 Webhook Coverage Complete** - Phases 14-21 (shipped 2026-04-30) - see [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Operator Confidence** - Phases 22-27 (shipped 2026-05-02) - see [milestones/v0.4-ROADMAP.md](milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 Adoption Hardening** - Phases 28-31 (shipped 2026-05-03) - see [milestones/v0.5-ROADMAP.md](milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 Production Maturity** - Phases 32-34 (shipped 2026-05-05) - see [milestones/v0.6-ROADMAP.md](milestones/v0.6-ROADMAP.md)
- ✅ **v1.0 Stability Lock** - Phases 35-38 (shipped 2026-05-06) - see [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Inbound Core Slice** - Phases 39-44 (shipped 2026-05-06) - see [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Inbound Production Confidence** - Phases 44.5, 45-50, 50.5, 50.7, 51 (shipped 2026-05-26) - see [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Adopter Trust Proof** - Phases 52, 57-62 (shipped 2026-05-31) - see [milestones/v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 Inbound Stability Lock** - Phases 63-66 (shipped 2026-06-01) - see [milestones/v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 Demo Evidence and Click-Around Confidence** - Phases 67-70 (shipped 2026-06-02) - see [milestones/v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 Inbound 1.0 Release and Truth Lock** - Phases 71-73 (shipped 2026-06-02) - see [milestones/v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 Admin UI - IA & Design-System Polish v2** - Phases 74-79 (shipped 2026-06-05) - see [milestones/v1.7-ROADMAP.md](milestones/v1.7-ROADMAP.md)
- ✅ **v1.8 Brand System and Repo-Ready Brandbook** - Phases 80-84 (closed superseded 2026-06-11; audit verdict gaps_found, accepted) - see [milestones/v1.8-ROADMAP.md](milestones/v1.8-ROADMAP.md) and [milestones/v1.8-MILESTONE-AUDIT.md](milestones/v1.8-MILESTONE-AUDIT.md)
- ✅ **v1.9 Brand Book Fable — A/B Brand System** - Phases 85-90 (shipped 2026-06-12) - see [milestones/v1.9-ROADMAP.md](milestones/v1.9-ROADMAP.md)
- ✅ **v1.10 Brand Adoption** - Phases 91-93 (shipped 2026-06-13) - see [milestones/v1.10-ROADMAP.md](milestones/v1.10-ROADMAP.md) and [milestones/v1.10-MILESTONE-AUDIT.md](milestones/v1.10-MILESTONE-AUDIT.md)
- ✅ **v1.11 mailglass_admin Design-System Uplift** - Phases 94-103 (shipped 2026-06-16) - see [milestones/v1.11-ROADMAP.md](milestones/v1.11-ROADMAP.md) and [milestones/v1.11-MILESTONE-AUDIT.md](milestones/v1.11-MILESTONE-AUDIT.md)
- ✅ **v1.12 Adopter Onboarding & Day-2 Confidence** - Phases 104-108 (shipped 2026-06-17) - see [milestones/v1.12-ROADMAP.md](milestones/v1.12-ROADMAP.md) and [milestones/v1.12-MILESTONE-AUDIT.md](milestones/v1.12-MILESTONE-AUDIT.md)
- ✅ **v1.13 Admin Design-System Stress Test & UX Uplift (v3)** - Phases 109-117 (shipped 2026-06-21) - see [milestones/v1.13-ROADMAP.md](milestones/v1.13-ROADMAP.md) and [milestones/v1.13-MILESTONE-AUDIT.md](milestones/v1.13-MILESTONE-AUDIT.md)

## Phases (Shipped — Archived)

All milestones through v1.13 are shipped and archived. Per-milestone phase detail,
success criteria, and plan breakdowns live in `.planning/milestones/vX.Y-ROADMAP.md`.

<details>
<summary>✅ v1.13 Admin Design-System Stress Test & UX Uplift (Phases 109-117) — SHIPPED 2026-06-21</summary>

Bottom-up fractal admin design-system uplift (foundations → primitives → forms → app-shell →
data-display → composed groups → motion → WCAG 2.2 AA ratchet), then a linked-version MINOR
release → **mailglass 1.8.0 / mailglass_admin 1.8.0 / mailglass_inbound 1.5.0 live on Hex**.
Audit status: passed — 41/41 requirements, 9/9 phases. Inbound re-pinned {:mailglass, "== 1.8.0"}.
Full detail: [milestones/v1.13-ROADMAP.md](milestones/v1.13-ROADMAP.md).

</details>
<details>
<summary>✅ v1.12 Adopter Onboarding & Day-2 Confidence (Phases 104-108) — SHIPPED 2026-06-17</summary>

Friction-removal + the first real linked-version Hex release since 1.6.2 → **mailglass 1.7.0 /
mailglass_admin 1.7.0 / mailglass_inbound 1.4.0 live on Hex**. Installer fail-closed + webhook
doctor (104), onboarding docs + learning arc (105), day-2 guides (106), inbound replay-modal a11y
parity (107), release cut + closeout (108). Audit `status: passed` — 13/13 requirements, 5/5
phases. Full detail: [milestones/v1.12-ROADMAP.md](milestones/v1.12-ROADMAP.md).

</details>

<details>
<summary>✅ v1.11 mailglass_admin Design-System Uplift (Phases 94-103) — SHIPPED 2026-06-16</summary>

Re-baseline the admin UI onto the canonical fable brand tokens, then fractally
audit-and-uplift every component, component-group, and page across the Operator,
Inbound, and Preview surfaces — enforced by an idempotent, research-grounded quality
ratchet. Admin UI only (3 surfaces). Release posture: prepare-only (no Hex release cut).
Audit `status: passed` — 34/34 requirements, 10/10 phases, 16/16 integration, 7/7 flows.
Full detail: [milestones/v1.11-ROADMAP.md](milestones/v1.11-ROADMAP.md).

- [x] Phase 94: Token Re-Baseline onto Canonical Brand (3/3 plans) — completed 2026-06-13
- [x] Phase 95: Audit Apparatus + Quality-Ratchet v2 (4/4 plans) — completed 2026-06-14
- [x] Phase 96: Research Dossier (6/6 plans) — completed 2026-06-14
- [x] Phase 97: Cross-Surface Component Layer (8/8 plans) — completed 2026-06-14
- [x] Phase 98: Operator / Deliveries Surface (4/4 plans) — completed 2026-06-14
- [x] Phase 99: Inbound Surface (5/5 plans) — completed 2026-06-15
- [x] Phase 100: Preview Surface (3/3 plans) — completed 2026-06-15
- [x] Phase 101: Microcopy Pass (2/2 plans) — completed 2026-06-16
- [x] Phase 102: Motion + Micro-interaction Pass (3/3 plans) — completed 2026-06-16
- [x] Phase 103: Verification + Idempotent Closeout (4/4 plans) — completed 2026-06-16

**Critical path:** 94 → 95 → 96 → 97 → {98, 99, 100 parallel} → {101, 102 parallel} → 103

</details>

## Backlog

### Phase 999.1: Human-Readable Code Comments + GSD Artifact Cleanup

Retained from previous milestones. Promote separately when worth the maintenance
pass.

### Phase 999.2: Shift-Left Email Screenshot + Responsive Preview Workflow

Retained from previous milestones. Do not fold into brandbook milestones; the
brandbooks avoid committing generated screenshot sets by design.
