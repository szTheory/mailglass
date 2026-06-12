# Requirements: mailglass v1.9 — Brand Book Fable (A/B Brand System)

**Defined:** 2026-06-11
**Core outcome:** A second, fully self-contained brand book at `brandbook-fable/`
that a maintainer can A/B against the frozen codex `brandbook/` baseline
(commit `09a84dd4`) — and that beats it on craft, buildability, accessibility
proof, and standalone polish.

**Scope locks (apply to every requirement):**

- Only `brandbook-fable/` is written. `brandbook/` (frozen), `mailglass_admin`,
  `guides/`, and the root README are untouched.
- Text artifacts only: SVG, MD, JSON, CSS, HTML. No Node toolchain, no
  binaries, no embedded fonts, no external network requests in any HTML.
- Tournament galleries, audits, and decision records live in `.planning/`,
  never inside `brandbook-fable/`.
- Locked brand essence: "mail you can see through", thoughtful-maintainer
  voice, calm/exact/confident/warm, glass-as-metaphor-not-gimmick. Palette,
  typography, and logo are open to justified evolution.

## v1.9 Requirements

### BRIEF — Research and Differentiation

- [x] **BRIEF-01**: A forensic audit of the codex `brandbook/` exists as a
  row-addressable defect/gap register, with every claimed weakness verified
  against actual file contents.
- [x] **BRIEF-02**: A differentiation brief locks ≤12 differentiators (each
  with a one-line "why it earns its bytes"), the brand-book section outline,
  and an explicit kill-list of artifacts deliberately not shipped.

### FOUND — Foundations and Tokens

- [x] **FOUND-01**: Every seed palette/typography decision has an explicit
  evolve-vs-keep record with contrast math justifying any deviation.
- [x] **FOUND-02**: `brandbook-fable/tokens.json` and `tokens.css` define raw
  palette → semantic roles → interaction states (default/hover/active/focus/
  disabled/selected) → feedback states (success/warning/error/info), plus
  type scale, space, radius, and focus tokens — for light AND dark themes.
- [x] **FOUND-03**: A computed WCAG contrast matrix covers every text-role/
  surface-role pair in both themes with AA/AAA pass-fail and a usage rule per
  pair.
- [x] **FOUND-04**: No token name or description references planning, phases,
  milestones, the old brandbook, or any process vocabulary.

### LOGO — Logo Tournament and Asset System

- [x] **LOGO-05**: Round 1 presents exactly 8 logo options, 2 per axis (pure
  custom typemark with motif worked into letterforms / mark + tight wordmark
  lockup / monogram-glyph / negative-space), each pre-screened against the
  constraint checklist before being shown.
- [x] **LOGO-06**: Every presented option passes: no rectangular background
  plate, visible boundary-break, tight mark-to-wordmark proximity, no subtitle
  in the main lockup, legible at 16px and 32px, works in mono/currentColor and
  on dark, no i-dot manipulation, no glassmorphism/paper-plane/mailbox/
  send-arrow/mascot tropes.
- [x] **LOGO-07**: The maintainer explicitly selects from a rendered-evidence
  gallery (light/dark/32px/16px/mono/in-context per option) at a hard pause;
  refinement rounds (≤2, parameter-named variants) run on the pick(s) before
  promotion. The selection and rationale are recorded.
- [x] **LOGO-08**: Canonical assets ship in `brandbook-fable/assets/`:
  primary lockup, standalone typemark, mark, monochrome/currentColor mark,
  with-tagline variant (the only one carrying a subtitle), favicon, and
  light/dark social avatars — all logotype glyphs outlined to paths, zero
  `font-family` in any asset SVG, each with accessible title/desc and unique
  IDs.

### BOOK — Standalone HTML Brand Book

- [x] **BOOK-04**: `brandbook-fable/index.html` opens from disk with zero
  network requests and renders correctly in light and dark via a manual toggle
  plus `prefers-color-scheme` default.
- [x] **BOOK-05**: The book includes a live HTML component gallery (buttons,
  inputs, badges, alerts, tabs, code blocks) built from tokens.css with
  working hover/focus/disabled states — not static pictures of components.
- [x] **BOOK-06**: The book renders the computed contrast matrix and shows
  the logo system at light/dark/16px/32px/mono scales.
- [x] **BOOK-07**: `brandbook-fable/brand-book.md` is a parallel
  source-of-truth document structured for human and LLM scanning (consistent
  heading grammar, exact hex/px values inline, tables), and
  `brandbook-fable/README.md` documents orientation, usage, and export policy.

### COLL — Collateral and Specimens

- [ ] **COLL-01**: `examples/landing-page.html` is a full self-contained
  landing blueprint (hero, install snippet, feature grid, code block,
  comparison row, footer) deployable with a find-and-replace.
- [ ] **COLL-02**: `examples/email-template.html` is an email-client-safe
  branded transactional email specimen (table-based layout, inline styles).
- [ ] **COLL-03**: SVG specimens cover README header, docs-page framing, a
  1200×630 social-card template (with documented local PNG export policy),
  and a worked diagram-language spec (node shapes, stroke weights, arrowheads,
  pane motif).

### COPY — Voice and Copy Library

- [ ] **COPY-01**: `copy/copy-blocks.md` ships paste-ready copy for GitHub
  About (within char limit), Hex.pm description, HexDocs intro, landing hero +
  feature blurbs, social/launch posts, and a release-note voice template — no
  placeholders, no lorem.
- [ ] **COPY-02**: `copy/microcopy.md` ships UX strings keyed to the seven
  domain nouns (Mailable, Message, Delivery, Event, InboundMessage, Mailbox,
  Suppression) across error/empty/success/warning states, consistent with the
  Anymail event taxonomy.

### GATE — Quality Gate and A/B Readiness

- [ ] **GATE-01**: A scripted gate passes: all SVGs XML-parse, tokens.json
  JSON-parses, every href/src resolves locally, zero external URLs, zero
  planning-process vocabulary in the folder, zero `font-family` in
  `assets/*.svg`, no background plate behind any mark (documented square
  social-avatar exception), size budgets hold (folder ≤ 500 KB, index.html
  ≤ 150 KB, no file > 100 KB).
- [ ] **GATE-02**: Browser-rendered evidence (screenshots to an ignored tmp
  dir) confirms light/dark rendering and 16px favicon legibility; nothing
  outside `brandbook-fable/` and `.planning/` changed.
- [ ] **GATE-03**: The maintainer completes an A/B walkthrough
  (`brandbook/index.html` vs `brandbook-fable/index.html`) and signs off the
  milestone.

## Future Requirements

- Adopting the winning brand book as the canonical `brandbook/` (post-A/B
  decision; includes deleting the loser).
- Propagating the winning identity to the root README, HexDocs assets, and
  repo social preview (coordinated change, separate milestone).
- PNG/raster export pipeline for launch surfaces that require it.

## Out of Scope

- Any change to `brandbook/` — it is the frozen A/B baseline.
- Admin UI restyling or `mailglass_admin/docs/design-system.md` changes — the
  product design system remains its own source of truth.
- Marketing-email features or visuals (permanently out of scope per
  PROJECT.md).
- Webfont embedding, icon libraries, mascots, mood boards, persona docs,
  print/stationery specs, motion videos — killed as filler.
- Pushing tags/releases — repo-artifact milestone only.

## Traceability

Mapped: 22/22 v1.9 requirements → Phases 85-90 (roadmapped 2026-06-11).

| REQ-ID | Phase | Status |
|--------|-------|--------|
| BRIEF-01 | Phase 85 | Complete |
| BRIEF-02 | Phase 85 | Complete |
| FOUND-01 | Phase 86 | Complete |
| FOUND-02 | Phase 86 | Complete |
| FOUND-03 | Phase 86 | Complete |
| FOUND-04 | Phase 86 | Complete |
| LOGO-05 | Phase 87 | Complete |
| LOGO-06 | Phase 87 | Complete |
| LOGO-07 | Phase 87 | Complete |
| LOGO-08 | Phase 87 | Complete |
| BOOK-04 | Phase 88 | Complete |
| BOOK-05 | Phase 88 | Complete |
| BOOK-06 | Phase 88 | Complete |
| BOOK-07 | Phase 88 | Complete |
| COLL-01 | Phase 89 | Pending |
| COLL-02 | Phase 89 | Pending |
| COLL-03 | Phase 89 | Pending |
| COPY-01 | Phase 89 | Pending |
| COPY-02 | Phase 89 | Pending |
| GATE-01 | Phase 90 | Pending |
| GATE-02 | Phase 90 | Pending |
| GATE-03 | Phase 90 | Pending |

*REQ-ID numbering continues from v1.8 (LOGO-01..04 and BOOK-01..03 were v1.8
IDs, archived in `.planning/milestones/v1.8-REQUIREMENTS.md`).*
