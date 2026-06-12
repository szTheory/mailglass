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
- 🚧 **v1.9 Brand Book Fable — A/B Brand System** - Phases 85-90 (in progress)

## Current Milestone: v1.9 Brand Book Fable — A/B Brand System

**Goal:** A second, fully self-contained brand book at `brandbook-fable/` that
the maintainer can A/B against the frozen codex `brandbook/` baseline (commit
`09a84dd4`) — and that beats it on craft, buildability, accessibility proof,
and standalone polish.

**Scope locks (apply to every phase):**

- Only `brandbook-fable/` is written. `brandbook/` is the frozen A/B baseline;
  `mailglass_admin`, `guides/`, and the root README are untouched.
- Text artifacts only: SVG, MD, JSON, CSS, HTML. No Node toolchain, no
  binaries, no embedded fonts, no external network requests in any HTML.
- Tournament galleries, audits, and decision records live in `.planning/`,
  never inside `brandbook-fable/`.
- Locked essence: "mail you can see through", thoughtful-maintainer voice,
  glass-as-metaphor-not-gimmick. Palette/typography/logo open to justified
  evolution.

**Critical path:** 85 → 86 → 87 → 88 → 89 → 90 (strictly linear: 87 needs 86's
locked palette/type; 88 needs 87's promoted assets; 89 slots into 88's shell;
90 gates everything.)

## Phases

<details>
<summary>✅ v1.8 Brand System and Repo-Ready Brandbook (Phases 80-84) — CLOSED SUPERSEDED 2026-06-11</summary>

- [x] Phase 80: Brand Audit and Gap Register (1/1 plans) — completed 2026-06-06
- [x] Phase 81: Brandbook Source and Token System (1/1 plans) — completed 2026-06-06
- [x] Phase 82: Logo and SVG Asset System (3/3 plans) — completed 2026-06-10; plans 02/03 resolved out-of-band, maintainer selected `concept-07r-no-idot-02-tighter-gap`, frozen at commit `09a84dd4`
- [~] Phase 83: Visual Specimens and Copy Blocks — superseded 2026-06-10 (intent substantially satisfied out-of-band; residual gaps inherited by v1.9)
- [~] Phase 84: Quality Gate and Repo Hygiene — superseded 2026-06-10 (partial out-of-band coverage; contrast validation never ran; residual gaps inherited by v1.9)

Full details: [milestones/v1.8-ROADMAP.md](milestones/v1.8-ROADMAP.md)

</details>

- [x] **Phase 85: Research and Differentiation Brief** - Forensic codex-brandbook audit + differentiation brief (≤12 differentiators, book outline, kill-list); planning artifacts only (completed 2026-06-11)
- [x] **Phase 86: Foundations — Palette, Type, Voice, Tokens** - Evolve-vs-keep records, DTCG tokens.json/tokens.css (light+dark, interaction+feedback states), computed WCAG contrast matrix (completed 2026-06-11)
- [x] **Phase 87: Logo Tournament** - 8 pre-screened options across 4 axes, rendered-evidence gallery, maintainer hard pause, ≤2 refinement rounds, winner promoted to outlined-path assets (completed 2026-06-12)
- [x] **Phase 88: Brand Book Assembly** - Self-contained index.html (light/dark toggle, live component gallery, contrast matrix, logo section), brand-book.md, README.md (completed 2026-06-12)
- [x] **Phase 89: Collateral, Specimens, and Copy Library** - landing-page/email-template HTML, README/docs/OG/diagram SVG specimens, copy-blocks.md, microcopy.md (completed 2026-06-12)
- [x] **Phase 90: Quality Gate and Maintainer UAT** - Scripted gate (parse/link/grep/size/render checks), browser evidence, A/B walkthrough sign-off (completed 2026-06-12)

## Phase Details

### Phase 85: Research and Differentiation Brief
**Goal**: The maintainer has a verified, row-addressable account of exactly where the codex brandbook falls short and a locked brief that defines what "beating it" means — before any fable artifact is authored
**Depends on**: Nothing (first phase of v1.9; consumes frozen `brandbook/` at `09a84dd4` and `.planning/research/v1.9-brandbook-fable/`)
**Requirements**: BRIEF-01, BRIEF-02
**Success Criteria** (what must be TRUE):
  1. A forensic audit of the codex `brandbook/` exists as a row-addressable defect/gap register, with every claimed weakness verified against actual file contents (file-and-line evidence, not assertions)
  2. The differentiation brief locks at most 12 differentiators, each with a one-line "why it earns its bytes"
  3. The brief contains the brand-book section outline and an explicit kill-list of artifacts deliberately not shipped
  4. Nothing exists under `brandbook-fable/` yet — all Phase 85 artifacts live in `.planning/`
**Plans**: 1 plan

Plans:
- [x] 85-01-PLAN.md — Forensic codex audit register (BRIEF-01) + locked differentiation brief (BRIEF-02)

### Phase 86: Foundations — Palette, Type, Voice, Tokens
**Goal**: The fable brand has a complete, contrast-proven token foundation for light and dark themes that every later artifact consumes
**Depends on**: Phase 85 (differentiation brief + section outline lock the foundation scope)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04
**Success Criteria** (what must be TRUE):
  1. Every seed palette/typography decision has an explicit evolve-vs-keep record with contrast math justifying any deviation — including the four research-identified contrast failures fixed with the computed values (light: `glass-deep #1D637A`, `glass-deepest #174E61`, `amber-deep #96520E`, `slate-soft #74909F`; dark: `crimson-bright #E29089`, `slate-bright #62809A`) and the codex dark ramp adopted
  2. `brandbook-fable/tokens.json` (DTCG-2025.10 style, two tiers) and `tokens.css` define raw palette → semantic roles → interaction states (default/hover/active/focus/disabled/selected) → feedback states (success/warning/error/info), plus type scale, space, radius, and focus tokens — for light AND dark themes
  3. A computed WCAG contrast matrix covers every text-role/surface-role pair in both themes with AA/AAA pass-fail and a usage rule per pair (Glass #277B96 stays AA-valid on white at 4.82:1; text-accent on tinted surfaces routes through `glass-deep`)
  4. No token name or description references planning, phases, milestones, the old brandbook, or any process vocabulary
**Plans**: 1 plan
**UI hint**: yes

Plans:
- [x] 86-01-PLAN.md — Token foundation: tokens.json + tokens.css (light+dark, full parity), computed WCAG matrix + foundations decision record, in-phase hygiene gate

### Phase 87: Logo Tournament
**Goal**: The maintainer selects the fable logo from a constraint-screened, evidence-rendered field, and the winner ships as a complete outlined-path asset system
**Depends on**: Phase 86 (locked palette and type foundations; options render against final tokens)
**Requirements**: LOGO-05, LOGO-06, LOGO-07, LOGO-08
**Success Criteria** (what must be TRUE):
  1. Round 1 presents exactly 8 logo options — 2 per axis (integrated custom typemark / mark + tight wordmark lockup / monogram-glyph / negative-space) — each pre-screened against the constraint checklist before being shown
  2. Every presented option passes the hard constraints: no rectangular background plate, visible boundary-break, tight mark-to-wordmark proximity, no subtitle in the main lockup, legible at 16px and 32px, works in mono/currentColor and on dark, no i-dot manipulation, no glassmorphism/paper-plane/mailbox/send-arrow/mascot tropes
  3. The maintainer explicitly selects from a rendered-evidence gallery (light/dark/32px/16px/mono/in-context per option) in `.planning/phases/87-*/tournament/` at a hard pause, and the selection plus rationale are recorded
  4. At most 2 refinement rounds (parameter-named variants) run on the pick(s) before promotion
  5. Canonical assets ship in `brandbook-fable/assets/`: primary lockup, standalone typemark, mark, monochrome/currentColor mark, with-tagline variant (the only one carrying a subtitle), favicon, light/dark social avatars — all logotype glyphs outlined to paths, zero `font-family` in any asset SVG, each with accessible title/desc and unique IDs
**Plans**: 2 plans
**UI hint**: yes

Plans:
- [x] 87-01-PLAN.md — Author 8 options (2 per axis), pre-flight screen, evidence gallery, browser audit; ends at the hard pause (87-01-CHECKPOINT.md)
- [x] 87-02-PLAN.md — Refinement rounds (<=2) on the pick(s), winner promotion to brandbook-fable/assets/ (8 outlined-path assets), decision record

**Checkpoint**: maintainer selection — **hard pause** at round 1. This phase BLOCKS on the maintainer picking from the rendered-evidence gallery by design; no auto-advance past selection. **Circuit breaker:** two consecutive full-set rejections halt the tournament and escalate (re-brief before generating more options).

### Phase 88: Brand Book Assembly
**Goal**: A reader can open `brandbook-fable/index.html` from disk and experience the complete brand system live — both themes, real component states, computed contrast proof, and the logo system — with parallel Markdown sources of truth
**Depends on**: Phase 87 (promoted logo assets) and Phase 86 (tokens)
**Requirements**: BOOK-04, BOOK-05, BOOK-06, BOOK-07
**Success Criteria** (what must be TRUE):
  1. `brandbook-fable/index.html` opens from disk with zero network requests and renders correctly in light and dark via a manual toggle plus `prefers-color-scheme` default
  2. The book includes a live HTML component gallery (buttons, inputs, badges, alerts, tabs, code blocks) built from tokens.css with working hover/focus/disabled states — not static pictures of components
  3. The book renders the computed contrast matrix and shows the logo system at light/dark/16px/32px/mono scales
  4. `brandbook-fable/brand-book.md` is a parallel source-of-truth document structured for human and LLM scanning (consistent heading grammar, exact hex/px values inline, tables), and `brandbook-fable/README.md` documents orientation, usage, and export policy
**Plans**: 1 plan
**UI hint**: yes

Plans:
- [x] 88-01-PLAN.md — Self-contained index.html (9 verbatim brief sections, theme toggle, live component gallery, runtime getComputedStyle contrast matrix, logo system per usage rules) + brand-book.md/README.md + Playwright visual audit loop with in-phase gates

### Phase 89: Collateral, Specimens, and Copy Library
**Goal**: Every real launch surface — landing page, transactional email, README, docs, social card, diagrams, and per-surface copy — has a deployable, brand-true specimen in the fable system
**Depends on**: Phase 88 (book shell, finalized tokens, and logo section the specimens slot into)
**Requirements**: COLL-01, COLL-02, COLL-03, COPY-01, COPY-02
**Success Criteria** (what must be TRUE):
  1. `examples/landing-page.html` is a full self-contained landing blueprint (hero, install snippet, feature grid, code block, comparison row, footer) deployable with a find-and-replace
  2. `examples/email-template.html` is an email-client-safe branded transactional specimen (table-based layout, inline styles, both color-scheme metas)
  3. SVG specimens cover README header, docs-page framing, a 1200×630 social-card template with documented local PNG export policy, and a worked diagram-language spec (node shapes, stroke weights, arrowheads, pane motif)
  4. `copy/copy-blocks.md` ships paste-ready copy for GitHub About (within char limit), Hex.pm description, HexDocs intro, landing hero + feature blurbs, social/launch posts, and a release-note voice template — no placeholders, no lorem
  5. `copy/microcopy.md` ships UX strings keyed to the seven domain nouns across error/empty/success/warning states, consistent with the Anymail event taxonomy
**Plans**: TBD
**UI hint**: yes

### Phase 90: Quality Gate and Maintainer UAT
**Goal**: The fable brand book is mechanically proven clean, portable, and budget-compliant, and the maintainer signs off the A/B comparison against the codex baseline
**Depends on**: Phase 89 (complete artifact set under `brandbook-fable/`)
**Requirements**: GATE-01, GATE-02, GATE-03
**Success Criteria** (what must be TRUE):
  1. A scripted gate passes: all SVGs XML-parse (xmllint), tokens.json JSON-parses, every href/src resolves locally, zero external URLs, zero planning-process vocabulary in the folder, zero `font-family` in `assets/*.svg`, no background plate behind any mark (documented square social-avatar exception), size budgets hold (folder ≤ 500 KB, index.html ≤ 150 KB, no file > 100 KB)
  2. Browser-rendered evidence (screenshots to an ignored tmp dir) confirms light/dark rendering and 16px favicon legibility, and nothing outside `brandbook-fable/` and `.planning/` changed
  3. The maintainer completes an A/B walkthrough (`brandbook/index.html` vs `brandbook-fable/index.html`) and signs off the milestone
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 85. Research and Differentiation Brief | 1/1 | Complete    | 2026-06-11 |
| 86. Foundations — Palette, Type, Voice, Tokens | 1/1 | Complete    | 2026-06-11 |
| 87. Logo Tournament | 2/2 | Complete    | 2026-06-12 |
| 88. Brand Book Assembly | 1/1 | Complete    | 2026-06-12 |
| 89. Collateral, Specimens, and Copy Library | 1/1 | Complete    | 2026-06-12 |
| 90. Quality Gate and Maintainer UAT | 1/1 | Complete    | 2026-06-12 |

## Backlog

### Phase 999.1: Human-Readable Code Comments + GSD Artifact Cleanup

Retained from previous milestones. Promote separately when worth the maintenance
pass.

### Phase 999.2: Shift-Left Email Screenshot + Responsive Preview Workflow

Retained from previous milestones. Do not fold into brandbook milestones; the
brandbooks avoid committing generated screenshot sets by design.
