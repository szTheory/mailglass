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
- 🔄 **v1.8 Brand System and Repo-Ready Brandbook** - Phases 80-84 (active)

## v1.8 Brand System and Repo-Ready Brandbook

**Goal:** Pressure-test the existing Mailglass brand book and turn it into a
self-contained, source-control-friendly brand system for OSS docs, README
presentation, landing pages, design tokens, SVG logos, visual specimens, and
maintainer-safe marketing copy.

**Scope locks:**

- Preserve the current brand center; do not redesign for novelty.
- Keep all new collateral under `brandbook/`.
- Commit only durable text assets: Markdown, HTML, JSON, CSS, and SVG.
- Do not add font binaries, PDFs, Figma files, generated screenshot sets, or
  large raster exports.
- Keep the artifact set lean: all killer, no filler.

## Phases

### Phase 80: Brand Audit and Gap Register

**Status:** Complete — 2026-06-06
**Requirements:** BRAND-01, BRAND-02

**Goal:** Produce a critical pressure test that decides what to keep, tighten,
rework, add, or remove before generating assets.

**Plans:** 1/1 plans complete

Plans:
- [x] 80-01-PLAN.md — Convert `brandbook/brand-audit.md` into a row-addressable brand audit and gap register.

**Success criteria:**

1. `brandbook/brand-audit.md` gives a candid executive judgment.
2. Audit includes DNA extraction, scorecard, surface stress tests, gaps/risks,
   artifact plan, prioritized actions, and final quality gate.
3. Recommendations preserve the strong existing brand and avoid churn.

### Phase 81: Brandbook Source and Token System

**Status:** Complete — 2026-06-06
**Requirements:** BOOK-01, BOOK-02, BOOK-03, TOKEN-01, TOKEN-02, TOKEN-03

**Goal:** Create the source brandbook and implementation tokens that designers,
engineers, and future agents can use without reopening prompt history.

**Plans:** 1/1 plans complete

Plans:
- [x] 81-01-PLAN.md — Revise the source brandbook and token system to remove
  overclaims, preserve the brand center, clarify semantic token usage, and keep
  the admin UI boundary explicit.

**Success criteria:**

1. `brandbook/index.html` opens directly from disk.
2. `brandbook/brand-book.md` captures the source-of-truth brand guidance.
3. `brandbook/tokens.json` and `brandbook/tokens.css` define raw, semantic,
   state, callout, code, type, space, radius, border, shadow, focus, and motion
   tokens.
4. Token language aligns with `mailglass_admin/docs/design-system.md`.

### Phase 82: Logo and SVG Asset System

**Status:** Planned
**Requirements:** LOGO-01, LOGO-02, LOGO-03, LOGO-04

**Goal:** Add a simple, editable, source-control-friendly logo system.

**Plans:** 1/3 plans executed

Plans:

**Wave 1**

- [x] 82-01-PLAN.md — Create source-native logo option evidence and comparison.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 82-02-PLAN.md — Run maintainer logo-direction review checkpoint. Fresh G-R first-principles options pending selection.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 82-03-PLAN.md — Finalize approved SVG assets and logo guidance.

**Success criteria:**

1. Primary logo, mark, monochrome mark, favicon, and social avatar SVGs exist.
2. Maintainer reviews multiple credible logo directions before selecting or
   refining the final system.
3. Assets include accessible title/description metadata.
4. Assets avoid raster images, embedded fonts, glossy effects, paper-plane
   metaphors, mascot logic, and unnecessary path complexity.

### Phase 83: Visual Specimens and Copy Blocks

**Status:** Planned
**Requirements:** EXAMPLE-01, EXAMPLE-02, VOICE-01

**Goal:** Add high-signal examples and copy that make the brand buildable for
README, docs, Hex.pm, landing, and launch surfaces.

**Success criteria:**

1. SVG specimens cover palette, typography, UI primitives, README framing, and
   docs-page framing.

2. The audit/brandbook include concrete copy blocks for package descriptions,
   README intro, landing hero, feature blurbs, errors, empty states, success,
   warnings, and release notes.

3. Examples do not pretend to be product screenshots.

### Phase 84: Quality Gate and Repo Hygiene

**Status:** Planned
**Requirements:** REPO-01, REPO-02, REPO-03

**Goal:** Ensure the brand system is source-control-ready, self-contained, and
safe to maintain.

**Success criteria:**

1. All artifacts live under `brandbook/`.
2. The folder documents commit/generate/avoid rules.
3. Validation checks cover JSON parsing, SVG parsing, local HTML references,
   file sizes, and git cleanliness.

## Progress

| Phase | Name | Status |
|---:|---|---|
| 80 | Brand Audit and Gap Register | Complete — 2026-06-06 |
| 81 | Brandbook Source and Token System | Complete — 2026-06-06 |
| 82 | Logo and SVG Asset System | Planned |
| 83 | Visual Specimens and Copy Blocks | Planned |
| 84 | Quality Gate and Repo Hygiene | Planned |

## Backlog

### Phase 999.1: Human-Readable Code Comments + GSD Artifact Cleanup

Retained from previous milestones. Promote separately when worth the maintenance
pass.

### Phase 999.2: Shift-Left Email Screenshot + Responsive Preview Workflow

Retained from previous milestones. Do not fold into v1.8; this brandbook avoids
committing generated screenshot sets by design.

## Notes

**v1.8 artifact rule:** Brand collateral belongs in `brandbook/`. Product code
should import or copy from that system only when a real surface needs it.

**Correction note:** Commit `572f3eb2` created a useful draft brandbook artifact
set, but it did not complete v1.8 because the normal GSD phase lifecycle did not
run. Treat those files as draft inputs to Phase 80+, not approved milestone
closeout.
