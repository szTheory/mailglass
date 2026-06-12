# Differentiation Brief — brandbook-fable (BRIEF-02)

The locked contract for Phases 86-90. Downstream phases work from this brief,
the brand strategy seeds (`prompts/mailglass-brand-book.md`), and the v1.9
research (`.planning/research/v1.9-brandbook-fable/SUMMARY.md` and its four
inputs) — and never re-open any `brandbook/` file. Every codex fact a
downstream phase needs is carried here or in the Phase 85 audit
(`85-codex-audit.md`), cited by `CDX-` row ID.

Locked essence (must not be contradicted anywhere downstream): **mail you can
see through**, the thoughtful-maintainer voice (clear, exact, confident not
cocky, warm not cute), and glass as metaphor — never gimmick.

## Differentiators

Twelve locked differentiators. Every candidate from the approved draft list
survived audit validation; two were added from audit-discovered defect rows
(CDX-11, CDX-18). Each Evidence cell cites the audit defect row(s) the
differentiator exploits or the strength row it must beat. No entry restates a
claim from the audit's Killed Differentiator Candidates section.

| ID | Differentiator | Why it earns its bytes | Evidence |
|----|----------------|------------------------|----------|
| DIF-01 | Outlined, font-independent logo assets | The mark and wordmark render identically on every OS and inside GitHub's font-less `<img>` sandbox — codex's primary asset degrades for nearly every viewer. | CDX-01, CDX-09, CDX-12 |
| DIF-02 | Purpose-drawn wordmark (integer grid, optical-correction pass, outlined paths) | A drawn letterform system with measured stems and overshoot beats typed text in a font the audience doesn't have. | CDX-01 |
| DIF-03 | Demonstrated dark mode: page-level toggle re-skins every specimen, with complete dark role coverage | Dark tokens that no page can reach are a claim, not a feature; the toggle plus full role reassignment makes dark mode verifiable on sight. | CDX-04, CDX-05, CDX-06; beats CDX-S-03 |
| DIF-04 | Live HTML component gallery with real hover/focus/disabled states plus forced-state rows | "Buildable UI, not mood boards" is provable only with real elements driven by the shipped tokens — codex promises it and ships static pictures. | CDX-13 |
| DIF-05 | Computed WCAG contrast matrix, rendered in-page and recomputed on theme toggle | Every text/surface pair carries a ratio and AA/AAA verdict that cannot drift from the tokens — codex defers contrast to a validation that never ran. | CDX-07; beats CDX-S-02 |
| DIF-06 | Zero process leakage: reader-facing folder, reader-facing language, nothing else | The brand folder contains only the brand system; tournament exhaust, audits, and phase vocabulary stay in `.planning/`. | CDX-03, CDX-08 |
| DIF-07 | Landing-page blueprint (`examples/landing-page.html`), deployable with find-and-replace | The highest-leverage launch surface ships as working, self-contained HTML instead of not existing. | CDX-16 |
| DIF-08 | Branded transactional email specimen (`examples/email-template.html`), client-safe | An email framework's brand book must brand an actual email — table layout, inline styles, dark-mode survival — codex ships none. | CDX-17 |
| DIF-09 | Per-surface copy library plus seven-noun microcopy | Paste-ready copy for GitHub/Hex/HexDocs/landing/launch and UX strings keyed to all seven domain nouns — breadth codex's four microcopy strings don't approach. | CDX-19; beats CDX-S-08 |
| DIF-10 | Worked diagram-language spec (node shapes, stroke weights, arrowheads, pane motif) | Diagrams are a named core component with zero specification — the spec makes every future architecture drawing on-brand by recipe. | CDX-20 |
| DIF-11 | Small-size-true favicon: redrawn ≤3-shape artifact, legible at 16px | The favicon is where adopters meet the mark daily; a redrawn small-size artifact beats codex's full mark scaled down to detail soup. | CDX-11 |
| DIF-12 | Social-card template (1200×630 source SVG) with documented PNG export path | Link previews are the first brand impression most people get; codex has no card at all, and the export note prevents the SVG-og:image trap. | CDX-18 |

## Non-Negotiables

The loudly-repeated single rules. Stated here once, restated in every phase
plan they touch, enforced by the Phase 90 gate:

1. **Outlined paths only — zero `font-family` and zero `<text>` in any asset SVG.** The wordmark is the one place type never falls back.
2. **Zero planning-process vocabulary in any shipped artifact** — no phase names, requirement IDs, tournament/option references, or editor metadata anywhere under `brandbook-fable/`.
3. **Dark mode is demonstrated live on every specimen** — the toggle re-skins the whole book; a dark token that no specimen renders does not exist.
4. **Every contrast claim is computed, never asserted** — ratios and pass/fail verdicts ship in the book; no "validate later" language survives.
5. **Zero network requests in any HTML** — every page opens from `file://` complete; no fetch, no modules, no webfonts, no external URLs in `src`/`href`/`url()`.
6. **No rectangular background plate behind any mark** — the single documented exception is the inherently square social avatar.
7. **Text artifacts only** — SVG, MD, JSON, CSS, HTML; no binaries, no font files, no committed rasters.

## Banned Motif Families

Named explicitly so no tournament option or specimen drifts into them
(pitfall IDs from `.planning/research/v1.9-brandbook-fable/PITFALLS-PORTABILITY.md`):

- **Rounded-rect badge plate behind the mark** (P-21) — the #1 AI-logo tell.
- **Gradient meshes / multi-stop gradients as the identity** (P-22) — every mark must pass a single-color test; this is also codex's shipped mistake (CDX-02).
- **Nodes-and-connections, circuit traces, hexagons, isometric cubes, brains, orbit rings** (P-23) — says "tech," not "mail you can see through."
- **Blue-purple SaaS gradient drift** (P-24) — any violet movement off the teal/ink palette is a regression.
- **Fake glassmorphism** (P-25) — frosted blur, transparency stacks, `backdrop-filter`, lens flares; doubly tempting given the name, banned by the brand seed.
- **Envelope-with-swoosh** — the envelope is on-domain; the swoosh treatment is the cliché.
- **Linear-slats, Glassdoor, or Gmail resemblance** — adjacent marks the lens/pane space collides with; every option is checked against them.
- **Paper plane, mailbox, chat bubble, send arrow, mascot** — brand-seed bans, restated.
- **Literal broken glass** — glass is a metaphor for clarity, never damage.

## Compositional Stance

Left-aligned, documentation-like composition throughout. The brand book, the
landing blueprint, and every specimen read like well-made docs: ragged-right
text blocks, asymmetric layouts, content anchored to a left rail or column.
The centered-hero, symmetric, three-icon-column formula is the AI-era default
(P-27) and reads as marketing; the thoughtful-maintainer voice reads better as
a well-lit workbench.

Density is calm but real: generous whitespace around exact content, not
emptiness around slogans. Every section terminates in something operable — a
table, a CSS block, a rendered specimen — per the engineer-operable
design-system genre rule in `.planning/research/v1.9-brandbook-fable/BRAND-SYSTEMS.md`.

## Ownable Axis

The ownable visual axis is **Ink/Glass/Ice plus transparency-as-meaning**:
teal-cyan accents on near-navy ink, with translucency used only where it
expresses layered visibility — panes, preview surfaces, inspection layers.
Supabase's lesson is that owning one color treatment, repeated with
discipline, builds recognition faster than variety; mailglass owns the
glass-teal-on-ink pairing and the pane motif the way Supabase owns its green.

Transparency always carries meaning (a layer you can see through to something
real beneath) and is never atmosphere. Flat color first, translucency as
vocabulary, gradients nowhere near the identity.

## Brand-Book Section Outline

Phase 88 implements this order verbatim in `brandbook-fable/index.html` and
mirrors it in `brand-book.md`. Foundations before applications; sticky header
carries the wordmark, anchor rail, and theme toggle.

1. **Orientation & Essence** — what mailglass is, "mail you can see through," the non-negotiables stated loudly up front.
2. **Voice** — thoughtful-maintainer principles with paired say/don't-say examples in real product language.
3. **Color & Tokens** — raw palette with named jobs, semantic role table (light and dark values visible side by side), terminating in the complete copy-pasteable `:root` / `[data-theme="dark"]` CSS block.
4. **Typography** — display/UI/mono stacks with the honest system-ui fallback statement, scale table, usage rules.
5. **Contrast Matrix** — runtime-computed WCAG table of every text-role/surface-role pair, ratio plus AA/AAA badge, recomputed on toggle (DIF-05).
6. **Component Gallery** — live buttons, inputs, badges, alerts, tabs, code blocks built from tokens with real `:hover`/`:focus-visible`/`:disabled` plus forced-state rows (DIF-04).
7. **Logo System** — asset manifest table, each lockup tier rendered on Paper/Mist/Ink/Glass chips at light/dark/32px/16px/mono, minimum-size and clear-space diagrams, do/don't list.
8. **Specimens & Applications** — per-surface collateral: README header, docs page, landing blueprint, email specimen (isolated in `<iframe srcdoc>`), social card, diagram language.
9. **Usage & Export Policy** — what to commit, what to generate locally (PNG export path for the social card), what never ships.

## Kill-List

Artifacts deliberately NOT shipped, each with its reason:

- **Personas** — the audience is one sentence (senior Phoenix/Elixir teams); a persona deck is filler.
- **Mission statements** — the essence line does the work; corporate mission prose dilutes it.
- **Mood boards** — the book ships operable tokens and specimens, not vibes.
- **Print/stationery specs** — no print surface exists for an OSS library; pure byte waste.
- **Icon libraries** — out of scope per REQUIREMENTS.md; the admin UI owns its own icon mechanics.
- **Motion videos** — motion is a few duration/easing tokens, not a video deliverable.
- **Tournament/options galleries inside the brand folder** — the codex mistake (CDX-08); all selection evidence lives in `.planning/`, the brand folder ships only winners.
- **Generated screenshot sets** — no concrete release purpose; regenerate locally when needed.
- **PNG or any binary assets** — text-artifacts-only scope lock; the social card documents a local export path instead.
- **Webfont files / `@font-face`** — banned by scope lock; the type section states the system-fallback truth instead of embedding fonts.
- **A second admin UI framework** — `mailglass_admin/docs/design-system.md` remains the product UI source of truth; the book maps to it deliberately or not at all.

## File Manifest

The planned `brandbook-fable/` tree: 21 files. Hard budgets, verbatim:
**folder <= 500 KB, index.html <= 150 KB, no single file > 100 KB.**
Per-file ceilings below sum to 489 KB, so the folder budget holds even if
every file hits its ceiling.

| File | Purpose | Budget | Authored by |
|------|---------|--------|-------------|
| `index.html` | Self-contained brand book: toggle, live gallery, contrast matrix, logo system | 150 KB | Phase 88 |
| `brand-book.md` | Parallel source-of-truth document, LLM/human scannable | 30 KB | Phase 88 |
| `README.md` | Orientation, usage, export policy | 6 KB | Phase 88 |
| `tokens.json` | DTCG-2025.10 tokens: palette + semantic roles, light and dark | 10 KB | Phase 86 |
| `tokens.css` | `--mg-*` custom properties, `:root` + `[data-theme="dark"]` + media-query block | 10 KB | Phase 86 |
| `assets/logo-primary.svg` | Primary lockup, outlined paths, explicit hex fills | 16 KB | Phase 87 |
| `assets/logo-typemark.svg` | Standalone wordmark, outlined | 12 KB | Phase 87 |
| `assets/logo-mark.svg` | Standalone mark | 8 KB | Phase 87 |
| `assets/logo-mark-mono.svg` | Monochrome/currentColor mark with explicit fallback color | 8 KB | Phase 87 |
| `assets/logo-with-tagline.svg` | The only lockup carrying a subtitle | 16 KB | Phase 87 |
| `assets/favicon.svg` | Redrawn ≤3-shape 16px artifact (DIF-11) | 3 KB | Phase 87 |
| `assets/social-avatar-light.svg` | Square avatar, light surface | 6 KB | Phase 87 |
| `assets/social-avatar-dark.svg` | Square avatar, dark surface | 6 KB | Phase 87 |
| `examples/landing-page.html` | Self-contained landing blueprint (DIF-07) | 50 KB | Phase 89 |
| `examples/email-template.html` | Client-safe branded transactional email (DIF-08) | 50 KB | Phase 89 |
| `examples/readme-header.svg` | GitHub README header specimen, outlined wordmark | 20 KB | Phase 89 |
| `examples/docs-page.svg` | Docs-page framing specimen | 24 KB | Phase 89 |
| `examples/og-card.svg` | 1200×630 social-card source template with export note (DIF-12) | 20 KB | Phase 89 |
| `examples/diagram-language.svg` | Worked diagram-language spec (DIF-10) | 24 KB | Phase 89 |
| `copy/copy-blocks.md` | Paste-ready per-surface copy library (DIF-09) | 10 KB | Phase 89 |
| `copy/microcopy.md` | Seven-noun UX strings across error/empty/success/warning | 10 KB | Phase 89 |

Token format, contrast fix values, font stacks, dark ramp, and GitHub SVG
rules are already settled by research — consume them from
`.planning/research/v1.9-brandbook-fable/SUMMARY.md` ("Decisions Already
Settled by Research"); do not re-decide them in any phase.

## Pitfall Mapping

The 28-pitfall register is NOT duplicated here. Each downstream phase clears
the pitfall IDs below, with warning signs and prevention specified in
`.planning/research/v1.9-brandbook-fable/PITFALLS-PORTABILITY.md`:

| Phase | Must clear |
|-------|-----------|
| 86 (foundations/tokens) | P-09, P-11 (token structure), P-15, P-16 |
| 87 (logo tournament) | P-01, P-02, P-03, P-05, P-06, P-07, P-15, P-21, P-22, P-23, P-24, P-25, P-26 |
| 88 (book assembly) | P-04, P-09, P-10, P-11, P-12, P-13, P-14, P-15, P-25 |
| 89 (collateral/copy) | P-01, P-02, P-03, P-05, P-06, P-07, P-13, P-15, P-17, P-18, P-19, P-20, P-25, P-27, P-28 |
| 90 (quality gate) | Gates all 28 (grep/parse/render checks per the register's enforce lines) |

P-15 (planning-language leakage) applies to every authoring phase from the
first draft — reader-facing language is written, not retrofitted.
