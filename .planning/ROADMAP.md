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
- 🚧 **v1.10 Brand Adoption** - Phases 91-93 (in progress)

## v1.10 Scope Locks (apply to every phase)

- **No Hex release is cut by this milestone's commits.** Brand/docs commits use
  non-release-triggering types (`docs:`, `chore:`, `test:`); the HexDocs wiring
  ships with the next natural release. Research-verified: release-please
  defaults make `docs:`/`chore:` non-bumping (ADOPTION-MECHANICS.md §2).

- **Sealed-flap usage rules and constraints C-15/C-16 are binding** on every
  propagated surface
  (`.planning/milestones/v1.9-phases/87-logo-tournament/87-decision-record.md`).

- **Binary additions limited to the single og-card PNG export.**
- **Planning archives (`.planning/milestones/`) are never edited.**

## Phases

<details>
<summary>✅ v1.9 Brand Book Fable — A/B Brand System (Phases 85-90) — SHIPPED 2026-06-12</summary>

- [x] Phase 85: Research and Differentiation Brief (1/1 plans) — completed 2026-06-11
- [x] Phase 86: Foundations — Palette, Type, Voice, Tokens (1/1 plans) — completed 2026-06-11
- [x] Phase 87: Logo Tournament (2/2 plans) — completed 2026-06-11; winner 4D "the sealed flap" via 4-round tournament
- [x] Phase 88: Brand Book Assembly (1/1 plans) — completed 2026-06-11
- [x] Phase 89: Collateral, Specimens, and Copy Library (1/1 plans) — completed 2026-06-11
- [x] Phase 90: Quality Gate and Maintainer UAT (1/1 plans) — completed 2026-06-12; gate 9/9 first run, maintainer A/B sign-off

Full details: [milestones/v1.9-ROADMAP.md](milestones/v1.9-ROADMAP.md)

</details>

### v1.10 Brand Adoption (Phases 91-93)

- [x] **Phase 91: Folder Adoption and Reference Reconciliation** - the fable book becomes canonical `brandbook/` via git mv, codex book removed, all tracked pointers reconciled, quality gate re-passes on the new path (completed 2026-06-13)
- [ ] **Phase 92: Surface Propagation** - Root README adopts the brand header, og-card PNG exported and committed with upload steps documented, admin wordmark explicitly dispositioned
- [ ] **Phase 93: HexDocs Wiring and Release Hardening** - ex_doc logo/favicon config for all three packages verified with local `mix docs`, release-please hardened against brand/planning-only commits, 1.6.x aftermath reconciled

## Phase Details

### Phase 91: Folder Adoption and Reference Reconciliation

**Goal**: The fable brand book is the project's one canonical `brandbook/` — the old codex book exists only in history, every tracked reference points at the new location, and the v1.9 quality gate proves nothing broke in the move
**Depends on**: Nothing (first phase of v1.10; v1.9 shipped)
**Requirements**: FOLD-01, FOLD-02, FOLD-03
**Success Criteria** (what must be TRUE):

  1. `brandbook/` at the repo root contains the fable book (moved via `git mv` with the codex files removed in the same commit; history preserves the codex baseline at `09a84dd4`), and the former fable staging folder no longer exists
  2. No active tracked file outside provenance archives references the former fable staging path; the CLAUDE.md Brand & Voice source-of-truth pointer and `mailglass_admin/docs/design-system.md:5` both point at `brandbook/brand-book.md` (the v1.9 sweep proved these are the only tracked consumers)
  3. The v1.9 quality gate (`gate.sh`, re-pathed) passes on the folder at its new location
  4. Every commit in the phase uses a non-release-triggering type (`chore:`/`docs:`) and no release-please PR is created

**Plans**: 4 plans
Plans:
**Wave 0**

- [x] 91-01-PLAN.md - Create the phase-local adoption gate and evidence contract

**Wave 1** *(blocked on Wave 0 completion)*

- [x] 91-02-PLAN.md - Replace the active brandbook folder via Git

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 91-03-PLAN.md - Reconcile active source-of-truth pointers and live planning memory

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 91-04-PLAN.md - Run the re-pathed gate and record release-safety evidence

### Phase 92: Surface Propagation

**Goal**: Anyone who encounters the repo — README, link unfurl, or the running admin dashboard — sees the sealed-flap identity (or a recorded reason why a surface was deferred)
**Depends on**: Phase 91 (all asset paths reference the post-rename `brandbook/`)
**Requirements**: SURF-01, SURF-02, SURF-03
**Success Criteria** (what must be TRUE):

  1. The root README displays `brandbook/examples/readme-header.svg` and renders correctly on both GitHub light and dark themes (C-15/C-16 binding; SVG rules pre-settled in v1.9)
  2. `brandbook/examples/og-card.png` (2400×1260 export via the verified Playwright command, under GitHub's 1 MB limit) is committed — the milestone's only binary addition — with the Settings-UI-only social-preview upload steps documented (no write API exists)
  3. The shipped admin wordmark (`mailglass_admin/priv/static/mailglass-logo.svg`) is explicitly dispositioned: replaced with the sealed-flap identity (with rebuilt committed bundle passing the `verify.preview` bundle-clean gate) or deferred with a recorded reason — not silently dropped

**Plans**: 2 plans
Plans:
**Wave 1**

- [ ] 92-01-PLAN.md - Propagate the sealed-flap identity to README and GitHub social-preview surfaces
- [ ] 92-02-PLAN.md - Replace the admin wordmark placeholder with a theme-safe sealed-flap logo

Cross-cutting constraints:

- Keep HexDocs logo/favicon wiring, ex_doc SVG width/height preparation, and release hardening out of Phase 92; Phase 93 owns HEXD-01, HEXD-02, RELH-01, and RELH-02.

### Phase 93: HexDocs Wiring and Release Hardening

**Goal**: All three packages are wired to ship the brand on HexDocs with the next natural release, and the release pipeline can never again cut a release from brand/planning-only commits
**Depends on**: Phase 92 (Phase 91 transitively — wiring references post-rename `brandbook/` asset paths; 92 settles asset disposition first)
**Requirements**: HEXD-01, HEXD-02, RELH-01, RELH-02
**Success Criteria** (what must be TRUE):

  1. The referenced SVGs (`logo-mark.svg`, `favicon.svg`) carry explicit `width`/`height` attributes (ex_doc 0.40.x requirement — current assets are viewBox-only) and all three packages' `docs:` config gains `logo:` (and `favicon:` where supported) pointing at the canonical `brandbook/` assets via relative paths
  2. `mix docs` renders locally for all three packages with the logo/favicon visible and no new warnings; the mix.exs changes land as non-release-triggering commit types and ride the next natural release
  3. release-please can no longer cut a release from commits touching only brand/planning paths — either the root `"."` package path stops claiming `brandbook/` + `.planning/` (mechanism verified against the manifest schema) or an enforced CI commit-type lint covers those paths
  4. The 1.6.x release aftermath is reconciled: unpublished stale tags dispositioned (deleted or documented), the inbound exact-pin bumped to the released core version via the established `fix(inbound)` dance, and `.planning` release-state memory/docs reflect the final version truth

**Plans**: TBD

> **External dependency note (RELH-02):** reconciliation depends on the in-flight
> release train settling first — if it has not settled when Phase 93 executes,
> RELH-02 is blocked-on-external and the phase records the blocker rather than
> guessing at final version truth.

## Progress

**Execution Order:** 91 → 92 → 93 (strictly linear — 92 and 93 reference the post-rename `brandbook/` paths)

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 91. Folder Adoption and Reference Reconciliation | 4/4 | Complete   | 2026-06-13 |
| 92. Surface Propagation | 0/2 | Ready to execute | - |
| 93. HexDocs Wiring and Release Hardening | 0/? | Not started | - |

## Backlog

### Phase 999.1: Human-Readable Code Comments + GSD Artifact Cleanup

Retained from previous milestones. Promote separately when worth the maintenance
pass.

### Phase 999.2: Shift-Left Email Screenshot + Responsive Preview Workflow

Retained from previous milestones. Do not fold into brandbook milestones; the
brandbooks avoid committing generated screenshot sets by design.
