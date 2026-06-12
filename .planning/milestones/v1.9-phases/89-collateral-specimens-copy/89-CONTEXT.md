# Phase 89: Collateral, Specimens, and Copy Library - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Approved milestone plan + 85-differentiation-brief manifest + 87-decision-record + Phase 88 shell

<domain>
## Phase Boundary

Phase 89 fills the manifest's `examples/` and `copy/` directories and slots
the specimens into the Phase 88 book's prepared Specimens grid. Every
artifact maps to a real surface the maintainer will ship.

</domain>

<decisions>
## Implementation Decisions

### examples/ (COLL-01..03)
- `landing-page.html` — full self-contained landing blueprint: hero (with
  the canonical lockup per usage rules), install snippet (`{:mailglass,
  "~> 1.5"}` + `mix mailglass.install`), feature grid, real code block
  (HEEx/Elixir, honest API surface from guides — verify any API named
  actually exists), comparison row ("why not just Swoosh?" framing per the
  positioning thesis: composes ON Swoosh, doesn't replace), footer.
  Deployable with find-and-replace. Uses tokens.css relatively; light/dark
  via the same toggle pattern as the book.
- `email-template.html` — email-client-safe branded transactional specimen
  per PITFALLS email rules: table layout, inline styles, no SVG (email
  clients don't render it — use no logo image at all OR document the
  PNG-export note; prefer a type-only masthead in brand colors), 600px,
  bulletproof buttons, dark-mode meta hints where safe. Content: a real
  mailglass-flavored transactional email (e.g. magic-link style WITHOUT
  tracking — auth context rules) written in brand voice.
- `readme-header.svg` — GitHub README hero: canonical lockup + one-line
  positioning, outlined paths only, GitHub-img-sandbox-safe (no external
  refs, no font-family), works on light AND dark GitHub themes (use the
  mono/currentColor strategy or a dark-safe palette — GitHub renders SVG in
  an img sandbox where currentColor goes black; pick colors that read on
  both, per PITFALLS).
- `docs-page.svg` — HexDocs-style page framing specimen.
- `og-card.svg` — 1200×630 social-card TEMPLATE (documented as source for
  local PNG export; crawlers don't render SVG og:images).
- `diagram-language.svg` — worked example of the diagram style: node
  shapes, stroke weights, arrowheads, the pane/light motif, one real
  mailglass flow (Mailable → Message → Delivery → Events) using exact
  domain nouns.

### copy/ (COPY-01..02)
- `copy-blocks.md` — paste-ready, no placeholders: GitHub About (≤350
  chars), Hex.pm description, HexDocs intro paragraph, landing hero
  headline + subhead + 3 feature blurbs, primary/secondary CTA, social/
  launch post, release-note voice template. Voice: thoughtful maintainer,
  no hype words (no "blazingly", "supercharge", "10x", "magic").
- `microcopy.md` — UX strings keyed to the SEVEN domain nouns (Mailable,
  Message, Delivery, Event, InboundMessage, Mailbox, Suppression) ×
  error/empty/success/warning, consistent with the Anymail event taxonomy
  and the brand error style ("Delivery blocked: recipient is on the
  suppression list" — specific, composed, never "Oops"). Use exact domain
  vocabulary; dispatch ≠ delivered distinction respected.

### Integration
- Slot the specimens into the Phase 88 index.html Specimens grid (the grid
  shipped slot-ready with no examples/ paths — now add them). This is the
  ONLY index.html change; re-run its gates after (sizes, external URLs,
  denylist).

### Hygiene
- All facts checkable: package names, version pins, mix task names, module
  names must match the real codebase (spot-check against README/guides).
- Zero process vocabulary anywhere in brandbook-fable/.
- Email template is the one artifact allowed to deviate from tokens.css
  mechanics (inline styles required) but colors must be the token hexes.

### Claude's Discretion
- Specimen visual design within the brand system.
- Copy phrasing within voice rules.

</decisions>

<canonical_refs>
## Canonical References

- `.planning/phases/85-research-and-differentiation-brief/85-differentiation-brief.md` — manifest + budgets
- `.planning/phases/87-logo-tournament/87-decision-record.md` — asset usage rules (primary never on dark; GitHub strategy)
- `.planning/research/v1.9-brandbook-fable/PITFALLS-PORTABILITY.md` — GitHub SVG rules, email HTML rules, og-card reality
- `prompts/mailer-domain-language-deep-research.md` — the seven nouns + event taxonomy (verbatim vocabulary)
- `prompts/mailglass-brand-book.md` + `prompts/Phoenix needs an email framework not another mailer.md` — voice + positioning
- `brandbook-fable/tokens.css`, `assets/`, `index.html` (the shell to slot into)
- `README.md` (repo root) + `guides/jobs.md` — real API/feature facts for honest copy
- `.planning/REQUIREMENTS.md` — COLL-01..03, COPY-01..02

</canonical_refs>

<specifics>
## Specific Ideas

- The email specimen is the most on-product collateral possible — the
  product sends email; the brand must prove itself inside one.
- No tracking pixels or open/click anything in the email specimen (brand +
  product rule: tracking off by default, never on auth-context messages).

</specifics>

<deferred>
## Deferred Ideas

- PNG export pipeline — explicitly out of scope (documented policy only).
- Final gate scripts — Phase 90.

</deferred>

---

*Phase: 89-collateral-specimens-copy*
*Context gathered: 2026-06-11 via approved-plan express path*
