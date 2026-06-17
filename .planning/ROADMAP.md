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
- 🚧 **v1.12 Adopter Onboarding & Day-2 Confidence** - Phases 104-108 (planned 2026-06-16) - see below

## Active Milestone — v1.12 Adopter Onboarding & Day-2 Confidence

**Status:** 🚧 PLANNED · **Phases:** 104–108 · **Requirements:** 13 (see `.planning/REQUIREMENTS.md`)

**Core outcome:** A Phoenix dev goes from `mix mailglass.install` to a correctly-wired,
production-ready integration without a silent webhook failure, a broken copy-paste example, or a
missing day-2 runbook — and the accumulated v1.7–v1.12 polish finally ships to Hex. Friction-removal
+ publish, not feature growth (D-23 convergence posture). Release posture: **actually cut** (not
prepare-only).

### Phase 104: Installer Fail-Closed + Webhook-Wiring Doctor

**Goal**: Make `mix mailglass.install` fail closed with an actionable error (+ `--force` escape
hatch) when it can't safely wire the webhook body_reader — routing the already-detected
`Plug.Parsers` conflict (`installer/apply.ex:47-76`) through the `Mix.raise` path the task already
uses (`mailglass.install.ex:108-112`), so silent production webhook 401s become impossible. Add a
verifiable post-install webhook-wiring check (`mix mail.doctor` endpoint lane or `mix
mailglass.doctor`). Tests-first, following the `install_idempotency_test.exs` fixture pattern.
**Depends on**: Nothing (critical-path root)
**Requirements**: INSTALL-01, INSTALL-02, INSTALL-03, INSTALL-04
**Success criteria**: install aborts with an actionable error on an unmanaged-parser conflict;
`--force` proceeds and wires the managed parser; the doctor check exits non-zero when
CachingBodyReader is absent; fail-closed/force/doctor paths are tested and green.

### Phase 105: Onboarding Docs — Quickstart Fix + Learning Arc

**Goal**: Make the first hour frictionless — fix the broken README quickstart (config-first so
`Mailglass.deliver()` can't `ConfigError`), end `getting-started.md` with a "Next steps" arc, add a
discoverable learning-path/index over the existing guides, and reopen `migration-from-swoosh.md`
with the "Swoosh = transport; mailglass = the framework layer" value pitch. All gated by
`docs_contract_test.exs`.
**Depends on**: Phase 104 (docs reference the new fail-closed behavior + doctor)
**Requirements**: DOCS-01, DOCS-02, DOCS-03, DOCS-04
**Success criteria**: README example parses via the docs-contract gate; getting-started has a
Next-steps section; the learning path is discoverable; the swoosh "why" opener is present;
docs-contract suite green.

### Phase 106: Day-2 Guides — Go-Live Checklist + Error/Troubleshooting Map

**Goal**: Give adopters the day-2 runbooks they expect — a `production-go-live-checklist.md`
(surfaces `mix mail.doctor` + the 104 webhook-wiring check, webhook secret rotation, Oban queue
sizing, per-tenant routing, suppression strategy, telemetry/alerting) and a unified
`errors-and-troubleshooting.md` mapping every `Mailglass.Error` struct → cause → fix. Both
registered in `mix.exs` docs and docs-contract gated.
**Depends on**: Phase 105 (shares `mix.exs` docs `extras:`/`groups_for_extras:` +
`docs_contract_test.exs`; serialized to avoid collisions)
**Requirements**: OPS-01, OPS-02
**Success criteria**: both new guides exist, are registered in both docs lists, and the
docs-contract suite (including new section/error-coverage assertions) is green.

### Phase 107: Inbound Replay-Modal A11y Parity (WR-03)

**Goal**: Bring the admin inbound replay modal to operator-modal accessibility parity — focus trap
+ Escape-to-close — with a structural Playwright assertion and a clean committed CSS bundle.
**Depends on**: Nothing (admin-UI; runs in parallel with 104–106)
**Requirements**: A11Y-01
**Success criteria**: modal traps focus, Escape closes it, Playwright structural assertion passes,
`git diff --exit-code priv/static/` clean.

### Phase 108: Release Cut + Milestone Closeout

**Goal**: Cut the real linked-version Hex release for the accumulated v1.7–v1.12 work (CHANGELOG,
admin-minor drags matched core+inbound, Release Please PR merges + publishes), perform the D-13
inbound exact-pin re-pin after merge, verify Hex resolution + post-publish smoke, and run the
milestone audit.
**Depends on**: Phases 104, 105, 106, 107
**Requirements**: REL-01, REL-02
**Success criteria**: all three packages published to Hex; inbound re-pinned to the new core
version; `mix deps.get` resolves from Hex; post-publish smoke green; milestone audit passed.

**Critical path:** 104 → 105 → 106 → 108, with 107 in parallel and 108 gated on all.

## Phases

All milestones through v1.11 are shipped and archived. Per-milestone phase detail,
success criteria, and plan breakdowns live in `.planning/milestones/vX.Y-ROADMAP.md`.

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

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 94. Token Re-Baseline onto Canonical Brand | v1.11 | 3/3 | Complete | 2026-06-13 |
| 95. Audit Apparatus + Quality-Ratchet v2 | v1.11 | 4/4 | Complete | 2026-06-14 |
| 96. Research Dossier | v1.11 | 6/6 | Complete | 2026-06-14 |
| 97. Cross-Surface Component Layer | v1.11 | 8/8 | Complete | 2026-06-14 |
| 98. Operator / Deliveries Surface | v1.11 | 4/4 | Complete | 2026-06-14 |
| 99. Inbound Surface | v1.11 | 5/5 | Complete | 2026-06-15 |
| 100. Preview Surface | v1.11 | 3/3 | Complete | 2026-06-15 |
| 101. Microcopy Pass | v1.11 | 2/2 | Complete | 2026-06-16 |
| 102. Motion + Micro-interaction Pass | v1.11 | 3/3 | Complete | 2026-06-16 |
| 103. Verification + Idempotent Closeout | v1.11 | 4/4 | Complete | 2026-06-16 |
| 104. Installer Fail-Closed + Webhook-Wiring Doctor | v1.12 | 0/? | Planned | — |
| 105. Onboarding Docs: Quickstart Fix + Learning Arc | v1.12 | 0/? | Planned | — |
| 106. Day-2 Guides: Go-Live Checklist + Error/Troubleshooting Map | v1.12 | 0/? | Planned | — |
| 107. Inbound Replay-Modal A11y Parity (WR-03) | v1.12 | 0/? | Planned | — |
| 108. Release Cut + Milestone Closeout | v1.12 | 0/? | Planned | — |

## Backlog

### Phase 999.1: Human-Readable Code Comments + GSD Artifact Cleanup

Retained from previous milestones. Promote separately when worth the maintenance
pass.

### Phase 999.2: Shift-Left Email Screenshot + Responsive Preview Workflow

Retained from previous milestones. Do not fold into brandbook milestones; the
brandbooks avoid committing generated screenshot sets by design.
