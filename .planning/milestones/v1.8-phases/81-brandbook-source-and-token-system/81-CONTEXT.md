# Phase 81: Brandbook Source and Token System - Context

**Gathered:** 2026-06-06 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 81 revises the source brandbook and implementation token artifacts that
future maintainers, designers, engineers, and agents can use without reopening
prompt history.

In scope:

- `brandbook/index.html`
- `brandbook/brand-book.md`
- `brandbook/tokens.json`
- `brandbook/tokens.css`

This phase must satisfy BOOK-01, BOOK-02, BOOK-03, TOKEN-01, TOKEN-02, and
TOKEN-03. It must remove draft/final overclaims from source brandbook and token
language, preserve the approved brand center, clarify semantic token usage, and
align token language with the implemented admin UI design-system discipline.

Out of scope: final logo selection, SVG logo option review, visual specimens,
README/Hex/HexDocs/landing copy blocks, validation scripts, package allowlist
proof, product UI code, public APIs, release workflow changes, font binaries,
PDFs, raster exports, and vendor design files. Those belong to Phases 82-84 or
future launch-specific work.
</domain>

<decisions>
## Implementation Decisions

### Phase Boundary

- **D-01:** Phase 81 should only revise the source brandbook and token system:
  `brandbook/index.html`, `brandbook/brand-book.md`,
  `brandbook/tokens.json`, and `brandbook/tokens.css`.
- **D-02:** Do not change logo assets, SVG specimens, README/package/docs copy,
  repo-hygiene scripts, package allowlists, product UI code, public APIs, or
  release workflow in this phase.
- **D-03:** Phase 81 must cite the Phase 80 audit/register, especially
  `BRAND-GAP-01`, `BRAND-GAP-08`, and `BRAND-GAP-12`, and should leave
  later-phase gaps to their assigned phases rather than closing them early.

### Draft Artifact Treatment

- **D-04:** Treat the existing `brandbook/` files as useful draft inputs, not
  approved final v1.8 outputs. Phase 81 should remove or soften any wording in
  source brandbook, token, and static HTML artifacts that implies Phases 82-84
  are already complete.
- **D-05:** Preserve the value of the draft files where they match the Phase 80
  audit. The work is source-hardening and token-language tightening, not a
  blank-slate rewrite.

### Brand Center

- **D-06:** Preserve the current conceptual center: "Mailglass makes email
  visible," "Mail you can see through," and "glass is a metaphor, not a visual
  excuse."
- **D-07:** Keep Mailglass positioned as Phoenix-native transactional and
  operational email infrastructure built on Swoosh and shipped as the sibling
  packages `mailglass`, `mailglass_admin`, and `mailglass_inbound`.
- **D-08:** Keep marketing email, campaigns, newsletters, drip automation,
  outbound-sales language, growth/outreach language, "AI magic" positioning,
  and "Swoosh replacement" framing out of the source brandbook.
- **D-09:** Preserve the thoughtful-maintainer voice: exact, calm, technical,
  direct, helpful under failure, and warm without cuteness.

### Token System

- **D-10:** Keep tokens small, role-based, and brandbook-scoped. Required token
  groups are raw palette, light/dark semantic color roles, state roles, callout
  roles, code roles, typography, spacing, radius, border, shadow, focus, and
  motion.
- **D-11:** Token guidance should prefer semantic roles over raw hex usage. Raw
  palette tokens exist as source values; implementation examples should route
  through roles such as background, surface, border, text, link, focus, state,
  callout, and code.
- **D-12:** Add explicit text versus non-text guidance for state and callout
  colors. In particular, `BRAND-GAP-08` means the info callout/background
  relationship should be documented as appropriate for border/non-text use
  unless contrast validation later proves a safe text pair.
- **D-13:** Preserve the brand palette direction: Ink, Glass, Ice, Mist, Paper,
  Slate, plus semantic Pine/Amber/Crimson. Glass remains a restrained accent,
  not the default background or border flood.
- **D-14:** Preserve practical type and structure primitives: Inter Tight for
  display, Inter for UI/body, IBM Plex Mono for code; 400 and 700 weights;
  letter spacing `0`; 4px spacing grid; modest radius; border-first surfaces;
  shadows only where they serve overlay/elevation semantics.
- **D-15:** Motion tokens stay restrained: transform/opacity-friendly durations,
  no motion above 300ms, and reduced-motion behavior encoded in CSS.

### Admin Design-System Boundary

- **D-16:** `mailglass_admin/docs/design-system.md` remains the implemented
  product UI constraint source. The brandbook may guide docs, marketing,
  examples, lightweight prototypes, and future collateral, but must not become
  a second admin UI framework.
- **D-17:** Brandbook token language should align with the admin discipline:
  semantic roles over raw hex, restrained Glass accent, flat panes, visible
  focus, non-color state cues, reduced-motion posture, no glassmorphism, no
  bevels, no glossy depth, no heavy shadows, no decorative gradients or blobs.
- **D-18:** Do not require or imply that product admin UI should consume
  `brandbook/tokens.css` directly. If product UI later needs brand tokens, that
  should be a deliberate future mapping into the existing Tailwind/daisyUI
  mechanics.

### Static HTML

- **D-19:** Keep `brandbook/index.html` direct-open from disk. No build step,
  Node toolchain, external asset service, PDF export, font binary, or vendor
  design tool should be introduced.
- **D-20:** The static HTML should reflect Phase 80's audit/register posture:
  the brand center is approved, but final tokens/logos/specimens/copy/proof are
  completed only by their assigned phases.
- **D-21:** Static HTML may use the committed token CSS and local SVG assets as
  draft display evidence, but it must not present the Phase 82 logo system or
  Phase 83 specimens/copy as already approved.

### the agent's Discretion

- Planner may choose whether to make the Phase 80 handoff explicit through a
  short status note, a dedicated "Phase status" section, or inline wording in
  affected sections, as long as overclaiming is removed.
- Planner may choose exact token descriptions and JSON metadata wording, as
  long as the required token groups remain present and the admin boundary is
  explicit.
- Planner may improve small source-only consistency issues discovered in the
  four Phase 81 files, but should defer logo, specimen, copy-block, and
  validation work to the assigned phases.
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
- `brandbook/brand-audit.md`
- `brandbook/brand-book.md`
- `brandbook/index.html`
- `brandbook/tokens.json`
- `brandbook/tokens.css`
- `brandbook/README.md`
- `prompts/mailglass-brand-book.md`
- `prompts/Phoenix needs an email framework not another mailer.md`
- `prompts/mailer-domain-language-deep-research.md`
- `prompts/mailglass-engineering-dna-from-prior-libs.md`
- `mailglass_admin/docs/design-system.md`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `brandbook/brand-audit.md` is the Phase 80 frozen audit/register gate and
  contains the Phase 81 handoff rows.
- `brandbook/brand-book.md` already contains the right conceptual center,
  voice, positioning, visual principles, color/type guidance, UI guidance,
  microcopy examples, artifact rules, and trademark note. It needs Phase 80
  alignment and source-of-truth tightening.
- `brandbook/tokens.json` already includes the required token families:
  palette, light/dark roles, state, callout, code, typography, space, radius,
  border, shadow, focus, and motion.
- `brandbook/tokens.css` already mirrors the practical CSS custom properties,
  including dark-theme overrides, focus-visible helper, and reduced-motion
  media query.
- `brandbook/index.html` already opens as a static page and consumes local
  `tokens.css` plus local SVG assets.

### Established Patterns

- Phase 80 established stable `BRAND-GAP-*` row IDs as downstream citation
  anchors. Phase 81 should cite and satisfy its assigned rows without
  renumbering or rewriting the frozen audit.
- The repo favors source-native artifacts: Markdown, static HTML, JSON, CSS,
  and SVG. Heavy binaries, generated screenshot sets, PDFs, font binaries, and
  vendor design files are out by default.
- Product UI mechanics are documented separately in
  `mailglass_admin/docs/design-system.md`; this project prefers one source of
  truth per layer rather than competing styling systems.
- Existing admin design-system rules emphasize semantic tokens, 4px grid,
  400/700 type weights, flat border-first surfaces, restrained motion,
  visible focus, and no Node toolchain.

### Integration Points

- Phase 81 output feeds Phase 82 logo work by making clear that current SVGs
  remain draft evidence until option review.
- Phase 81 output feeds Phase 83 copy/specimen work by preserving brand center,
  domain vocabulary, voice, and token/state guidance.
- Phase 81 output feeds Phase 84 validation by clarifying token groups,
  allowed color usage, contrast expectations, static HTML locality, and the
  admin/product UI boundary.
</code_context>

<specifics>
## Specific Ideas

The assumptions were presented to the maintainer and confirmed with option 1:
"Yes, proceed." No corrections were requested.

Recommended implementation posture:

- Tighten the four Phase 81 files rather than replacing the whole draft.
- Make any "source-controlled brand system" wording careful enough that it does
  not imply logos, specimens, copy blocks, validation, or package hygiene proof
  are complete before Phases 82-84.
- Use Phase 80's register rows as explicit planning anchors:
  `BRAND-GAP-01`, `BRAND-GAP-08`, and `BRAND-GAP-12`.
- Keep token language practical and consumable, but avoid growing it into a
  full design-system framework.
- Keep the direct-open HTML artifact boring and durable.
</specifics>

<deferred>
## Deferred Ideas

- Final logo option review, favicon/small-mark ambiguity, SVG accessibility ID
  and distribution strategy, monochrome/reversed variants: Phase 82.
- Visual specimens, README/Hex.pm/HexDocs/landing/social/launch copy blocks,
  real Mailglass snippet replacement, and non-color UI-state specimen cues:
  Phase 83.
- JSON/CSS/SVG/HTML/file-size/contrast/package/git-cleanliness validation:
  Phase 84.
- PNG social cards, conference-slide template, reusable diagram component set,
  automated contrast-report script, and trademark/name strategy: future-only
  unless a concrete launch, repeated diagram need, token churn, or legal review
  justifies it.

### Reviewed Todos (not folded)

None. `gsd-sdk query todo.match-phase "81"` returned no matched pending todos.
</deferred>
