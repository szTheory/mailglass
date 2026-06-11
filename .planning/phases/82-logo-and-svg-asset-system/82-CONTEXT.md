# Phase 82: Logo and SVG Asset System - Context

**Gathered:** 2026-06-06 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 82 creates the approved logo and SVG asset system for the v1.8 brandbook.

In scope:

- multiple credible logo-direction review before final approval
- editable SVG assets for primary lockup, icon-only mark, monochrome mark,
  favicon, and social avatar
- logo-specific updates to `brandbook/` source artifacts where needed
- SVG accessibility metadata, small-size disposition, monochrome/reversed use,
  and live-text versus path-only distribution decisions

This phase must satisfy LOGO-01, LOGO-02, LOGO-03, and LOGO-04. It must consume
the Phase 80 audit rows `BRAND-GAP-04`, `BRAND-GAP-05`, and `BRAND-GAP-06`, and
it must preserve the Phase 81 source-brandbook posture that current SVGs are
draft evidence until this phase completes.

Out of scope: README, Hex.pm, HexDocs, landing, launch, or social copy blocks;
visual specimens; validation scripts; package allowlist proof; product UI code;
public API changes; release workflow changes; raster exports; font binaries;
PDFs; vendor design files; broad trademark/legal/name strategy. Those belong to
Phases 83-84 or future launch-specific work.
</domain>

<decisions>
## Implementation Decisions

### Phase Boundary

- **D-01:** Phase 82 should update the logo/SVG brandbook surface, not package
  code or admin UI code.
- **D-02:** Phase 82 may add a durable logo-option review artifact under
  `brandbook/` and may update logo-specific wording in `brandbook/index.html`,
  `brandbook/brand-book.md`, `brandbook/README.md`, or logo SVG files as needed.
- **D-03:** Do not touch root README copy, Hex package copy, HexDocs copy,
  product/admin implementation code, public APIs, release workflow, package
  allowlists, validation scripts, or specimen/copy artifacts in this phase.

### Logo Direction

- **D-04:** Treat the current pane/message-fold mark and all A-F option assets
  as rejected draft evidence, not final approval.
- **D-05:** Phase 82 must compare the active G-R first-principles option set
  before selecting or refining the final system. The maintainer-selected
  priority family is email source, with infrastructure and inspection-tool
  outliers included to avoid another narrow variant round.
- **D-06:** The final posture should stay wordmark-first and refine toward the
  simplest small-size-safe source-native mark that still supports the approved
  "Mailglass makes email visible" brand center.
- **D-07:** The mark may suggest source headers, message lifecycle, inspection
  boundaries, routing, normalization, or visible-email structure, but must avoid
  paper planes, mailbox-on-post imagery, chat bubbles, send arrows, glossy
  app-icon treatment, mascot logic, pane/card/document geometry, and unnecessary
  path complexity.

### SVG Accessibility And Distribution

- **D-08:** Final SVGs must keep `role="img"`, `title`, `desc`, `viewBox`, and
  accessible labeling.
- **D-09:** Final SVGs must avoid raster images, embedded fonts, scripts,
  `foreignObject`, data/base64 payloads, and external references.
- **D-10:** Replace repeated `id="title"` and `id="desc"` with unique IDs per
  asset, or explicitly document a non-inline distribution rule if unique IDs are
  deliberately not used. The recommended default is unique IDs.
- **D-11:** Keep the primary lockup editable with live SVG text for source use.
  Keep favicon, icon mark, monochrome mark, and avatar path-only or shape-only
  where practical.
- **D-12:** Defer outlined wordmark exports unless a real launch, package-docs,
  or distribution surface needs pixel-exact typography. Do not introduce font
  binaries to solve logo distribution.

### Small-Size, Monochrome, And Dark Use

- **D-13:** Phase 82 must explicitly review favicon and mark behavior at small
  sizes, especially 16px and 32px.
- **D-14:** If the triangular fold reads like a document corner, envelope, or
  send arrow at small sizes, simplify the mark rather than adding detail.
- **D-15:** Phase 82 must record final disposition for monochrome use,
  reversed/dark-background use, favicon use, and social avatar use.
- **D-16:** Monochrome assets should use simple `currentColor` construction
  where possible so they remain flexible for stamps, print, compact docs, and
  single-color contexts.

### Brand And Token Alignment

- **D-17:** Preserve the approved brand center: "Mailglass makes email visible,"
  "Mail you can see through," and "glass is a metaphor, not a visual excuse."
- **D-18:** Preserve the Phase 81 visual discipline: restrained Glass accent,
  flat panes, modest radius, border-first construction, visible focus posture,
  no glassmorphism, no bevels, no glossy depth, no heavy shadows, and no
  decorative gradient or blob language.
- **D-19:** Use `brandbook/tokens.json` and `brandbook/tokens.css` as source
  color/type guidance for brandbook assets, without implying that product admin
  UI should consume those files directly.

### the agent's Discretion

- Planner may choose the exact format for the logo-option review artifact, as
  long as it gives the maintainer a clear comparison of multiple credible
  directions and records the final selected/refined direction.
- Planner may choose whether final assets replace the existing files directly
  or add temporary option files first, as long as final committed assets satisfy
  LOGO-01 through LOGO-04 and the temporary review material remains
  source-control-friendly.
- Planner may choose exact SVG dimensions and viewBox values, but must keep
  assets simple, editable, parseable, and practical for README/docs/social/icon
  uses.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md`
- `.planning/phases/81-brandbook-source-and-token-system/81-CONTEXT.md`
- `brandbook/brand-audit.md`
- `brandbook/brand-book.md`
- `brandbook/index.html`
- `brandbook/README.md`
- `brandbook/tokens.json`
- `brandbook/tokens.css`
- `brandbook/assets/logo-primary.svg`
- `brandbook/assets/logo-mark.svg`
- `brandbook/assets/logo-monochrome.svg`
- `brandbook/assets/favicon.svg`
- `brandbook/assets/social-avatar.svg`
- `mailglass_admin/docs/design-system.md`
- `mailglass_admin/priv/static/mailglass-logo.svg`
- `mailglass_admin/mix.exs`
- `mix.exs`
- `prompts/mailglass-brand-book.md`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `brandbook/assets/logo-primary.svg`, `logo-mark.svg`,
  `logo-monochrome.svg`, `favicon.svg`, and `social-avatar.svg` already provide
  one simple pane/message-fold SVG direction.
- Current SVG asset files are small, source-control-friendly, and parse as XML.
  They contain no raster images, embedded fonts, scripts, or external
  references.
- `brandbook/brand-book.md` already states Mailglass is wordmark-first and the
  mark is secondary.
- `brandbook/index.html` already displays the current logo assets while naming
  them draft evidence until Phase 82 completes.
- `mailglass_admin/priv/static/mailglass-logo.svg` is an older placeholder
  wordmark that explicitly says a future brand-book glyph should supersede it.

### Established Patterns

- Phase 80 established `BRAND-GAP-04`, `BRAND-GAP-05`, and `BRAND-GAP-06` as
  the logo/SVG handoff rows for multiple-option review, small-mark ambiguity,
  and duplicate SVG accessibility IDs.
- Phase 81 established that brandbook artifacts stay honest about draft versus
  approved status and that `mailglass_admin/docs/design-system.md` remains the
  implemented product UI source of truth.
- The repo favors Markdown, static HTML, JSON, CSS, and SVG over heavy binaries,
  screenshots, PNG packs, PDFs, font files, and vendor design assets.
- Package files use explicit file allowlists. Broad `brandbook/` inclusion is
  not part of this phase.

### Integration Points

- Phase 82 output feeds Phase 83 by giving copy/specimen work an approved logo
  and mark system to reference.
- Phase 82 output feeds Phase 84 by giving validation work concrete SVG
  metadata, ID, safety, size, and reference expectations to enforce.
- If a future ExDoc, package, or launch surface needs a logo asset, it should
  deliberately copy or whitelist the smallest exact asset instead of including
  all of `brandbook/`.
</code_context>

<specifics>
## Specific Ideas

The assumptions were presented to the maintainer and confirmed with option 1:
"Yes, proceed." No corrections were requested.

Recommended implementation posture:

- Keep A-F as rejected option evidence.
- Use G-R as the active first-principles option set, prioritizing email-source
  cues such as headers, source rows, cursor/diff notation, and source-native
  verification.
- Select or refine the final G-R direction based on small-size clarity,
  wordmark-first fit, brand-center alignment, ownability, and avoidance of
  forbidden email tropes.
- Update final SVG assets with unique accessible IDs and keep the final file set
  lightweight.
- Record the logo-option review in a durable brandbook artifact so LOGO-02 is
  auditable without requiring a human to reconstruct the comparison from git
  diff alone.
</specifics>

<deferred>
## Deferred Ideas

- README/Hex.pm/HexDocs/landing/social/launch copy blocks: Phase 83.
- Visual specimens, real Mailglass snippet replacement, and non-color UI-state
  specimen cues: Phase 83.
- JSON/CSS/SVG/HTML/file-size/contrast/package/git-cleanliness validation:
  Phase 84.
- PNG social cards, conference-slide template, reusable diagram component set,
  automated contrast-report script, and trademark/name strategy: future-only
  unless a concrete launch, repeated diagram need, token churn, or legal review
  justifies it.

### Reviewed Todos (not folded)

None. `gsd-sdk query todo.match-phase "82"` returned no matched pending todos.
</deferred>
