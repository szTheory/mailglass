# Phase 80: Brand Audit and Gap Register - Context

**Gathered:** 2026-06-05 (assumptions mode + subagent/web research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 80 is the audit and gap-register gate for v1.8. It decides what the
brand system should keep, tighten, rework, add, or remove before Phases 81-84
revise source artifacts.

This phase does **not** finalize the whole `brandbook/` system, approve the
current logo set, refresh README/Hex/HexDocs presentation, add product UI code,
change public APIs, alter package code, or run a broad brand-redesign exercise.
The existing commit `572f3eb2 docs: add mailglass brandbook` is useful draft
input, not milestone completion evidence.
</domain>

<decisions>
## Implementation Decisions

### Audit Posture
- **D-01:** Treat existing `brandbook/` files as draft inputs to audit, not as
  already-approved v1.8 outputs. Phase 80 may reuse strong draft material, but
  must remove any language that implies later-phase assets are complete before
  the normal GSD lifecycle runs.
- **D-02:** Phase 80 output should be a candid audit plus a traceable
  gap-register framing. It should classify findings as `KEEP`, `TIGHTEN`,
  `REWORK`, `ADD`, or `REMOVE`, and each actionable row should carry severity,
  surface, evidence, rationale, target phase, and acceptance/closeout cue.
- **D-03:** The register should stay focused. Add rows only when they affect a
  required surface, a later phase handoff, brand consistency, accessibility,
  repo hygiene, or future verification. Avoid taste-only rows with no downstream
  action.

### Brand Center
- **D-04:** Preserve the current conceptual center: "Mailglass makes email
  visible," "Mail you can see through," and "glass is a metaphor, not a visual
  excuse." This is a build-readiness milestone, not a redesign-for-novelty
  milestone.
- **D-05:** The canonical product story remains Phoenix-native transactional
  and operational email infrastructure built on Swoosh, shipped as
  `mailglass`, `mailglass_admin`, and `mailglass_inbound`. Marketing email,
  campaigns, newsletters, drip automation, growth/outreach language, and
  "Swoosh replacement" framing stay out.
- **D-06:** The voice stays "thoughtful maintainer": exact, calm, technical,
  helpful under failure, and warm without cuteness. Preserve domain nouns such
  as Mailable, Message, Delivery, Event, InboundMessage, Mailbox, Suppression,
  timeline, provider, adapter, stream, headers, route, render, preview,
  observe, inspect, verify.

### Visual System And Tokens
- **D-07:** Preserve the Ink/Glass/Ice/Mist/Paper/Slate palette direction,
  Inter / Inter Tight / IBM Plex Mono stack, flat pane metaphor, restrained
  borders, semantic state color, visible focus, and motion restraint. Do not
  introduce glassmorphism, bevels, glossy highlights, heavy shadows, decorative
  gradients, blobs, or a one-note Glass/cyan flood.
- **D-08:** Phase 80 should ratify token principles, not finalize token files.
  Phase 81 should prefer small role-based tokens over raw palette usage:
  background, surface, raised/subtle/selected surface, border, text, muted
  text, link, focus, state, callout, code, type, spacing, radius, border,
  shadow, and motion.
- **D-09:** Accessibility is part of the brand promise. Audit/token guidance
  must call out contrast, non-color state indicators, visible focus, keyboard
  reachability, hover/focus/active/selected/disabled states, reduced-motion
  posture, and dark/light/system behavior.
- **D-10:** `mailglass_admin/docs/design-system.md` remains the implemented
  product UI constraint source. The brandbook can inform docs/marketing/future
  collateral, but it must not become a second admin UI framework or contradict
  the shipped Tailwind/daisyUI admin token mechanics.

### Logo And SVG Assets
- **D-11:** Treat the current `brandbook/assets/*.svg` set as one credible draft
  logo direction, not as final approval. Phase 82 must compare multiple
  credible options before selecting or refining the final mark system.
- **D-12:** Keep Mailglass wordmark-first; the mark is secondary. The mark may
  explore pane/message-fold/inspectable-email semantics, but must avoid paper
  planes, mailbox-on-post imagery, chat bubbles, send arrows, glossy app-icon
  treatment, mascot logic, and unnecessary path complexity.
- **D-13:** Phase 82 should explicitly resolve small-size and distribution
  questions: favicon legibility, monochrome use, dark/reversed variants,
  repeated SVG `title`/`desc` IDs when inlined, live SVG text versus outlined
  distribution files, and whether the current triangular fold reads too much
  like a document corner, envelope, or send arrow.

### Surface Stress Tests
- **D-14:** Phase 80 should stress-test every required surface named in
  BRAND-02: GitHub, README, Hex.pm, HexDocs, docs UI, code/terminal snippets,
  landing page, social preview, favicon, small monochrome mark, dark/light
  mode, diagrams, and UI states.
- **D-15:** Seed likely audit rows include: draft audit overclaims completion;
  logo option review missing; current logo mark ambiguity at small sizes;
  duplicate SVG accessibility IDs if assets are inlined; README/specimen copy
  that uses generic `phx_new` instead of a Mailglass flow; specimen/domain
  wording such as "Delivered" needing domain review; and any prompt-era package
  or marketing language that conflicts with current scope.

### Repo Hygiene And DX
- **D-16:** Keep brand collateral self-contained under `brandbook/` by default.
  Commit Markdown, static HTML, JSON, CSS, and SVG. Do not commit PDFs, Figma
  or vendor design files, font binaries, large raster packs, PNG social-card
  batches, screenshot sets, or visual-regression artifacts unless a concrete
  release need justifies a narrow exception.
- **D-17:** Keep `brandbook/index.html` direct-open from disk with no Node,
  design-vendor, build, or asset-service dependency. Static HTML plus committed
  CSS is intentionally boring and durable.
- **D-18:** Brand assets should stay out of Hex package tarballs by default.
  If ExDoc later needs a logo/favicon, copy or whitelist the smallest exact
  asset deliberately rather than accidentally including all of `brandbook/`.
- **D-19:** Phase 84 should own executable validation, but Phase 80 should name
  the expected gates: parse `tokens.json`; check CSS/token semantic groups;
  validate token value shapes and key contrast pairs; parse SVG XML; require
  SVG title/desc/role/viewBox/size metadata; reject script/image/foreignObject/
  data/base64/external hrefs; verify local HTML refs; cap artifact sizes; and
  confirm git cleanliness.

### External Lessons Applied
- **D-20:** Mature systems converge on role-based tokens and accessibility:
  Carbon/Primer/Atlassian-style token roles, GOV.UK/Polaris-style task-first
  content and native interaction defaults, WCAG 2.2 as the accessibility floor,
  and ExDoc/HexDocs discipline for source-native library docs.
- **D-21:** The current `Mailglass Lite` web presence is a live naming/market
  collision signal. Phase 80 should log it as a brand-risk note, not attempt
  trademark/legal clearance or rename work. Legal/name clearance is deferred
  unless major launch collateral or package identity work makes it necessary.

### the agent's Discretion
- Planner may choose the exact Markdown layout for the audit and gap register,
  including whether the register is embedded in `brandbook/brand-audit.md` or
  split into a companion section/file, as long as Phase 80's success criteria
  are satisfied and later phases can cite rows reliably.
- Planner may choose exact severity scale wording, but severity must map to
  downstream closeout pressure: high-severity brand/readiness gaps cannot be
  left ambiguous for Phases 81-84.
- Planner may choose exact row IDs, but they must be stable enough for later
  phase plans and verification artifacts to cite.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `brandbook/brand-audit.md`
- `brandbook/brand-book.md`
- `brandbook/README.md`
- `brandbook/index.html`
- `brandbook/tokens.json`
- `brandbook/tokens.css`
- `brandbook/assets/logo-primary.svg`
- `brandbook/assets/logo-mark.svg`
- `brandbook/assets/logo-monochrome.svg`
- `brandbook/assets/favicon.svg`
- `brandbook/assets/social-avatar.svg`
- `brandbook/examples/palette.svg`
- `brandbook/examples/typography.svg`
- `brandbook/examples/ui-primitives.svg`
- `brandbook/examples/readme-header.svg`
- `brandbook/examples/docs-page.svg`
- `prompts/mailglass-brand-book.md`
- `prompts/Phoenix needs an email framework not another mailer.md`
- `prompts/mailer-domain-language-deep-research.md`
- `prompts/mailglass-engineering-dna-from-prior-libs.md`
- `prompts/elixir-opensource-libs-best-practices-deep-research.md`
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`
- `mailglass_admin/docs/design-system.md`
- `mailglass_admin/priv/static/mailglass-logo.svg`
- `README.md`
- `mix.exs`
- `mailglass_admin/mix.exs`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `brandbook/` already contains a useful draft set: static HTML brandbook,
  Markdown audit/source book, JSON/CSS tokens, SVG logo assets, SVG specimens,
  and artifact hygiene rules.
- `brandbook/brand-audit.md` already contains executive judgment, DNA
  extraction, scorecard, stress tests, gaps/risks, artifact plan, copy blocks,
  and final quality gate. It needs Phase 80 hardening into a traceable register
  and less completion-overclaiming.
- `mailglass_admin/docs/design-system.md` provides the implemented product UI
  token/motion/conformance discipline that brandbook work must respect.
- `mailglass_admin/priv/static/mailglass-logo.svg` is an older placeholder
  wordmark with a comment that a future brand-book glyph should supersede it.

### Established Patterns

- Mailglass planning artifacts prefer frozen evidence gates before build work
  begins, as in Phase 74's UI-SPEC/gap-register pattern.
- The repo favors source-native, deterministic artifacts and explicit package
  allowlists over heavy vendor assets or generated binaries.
- The project already treats docs as contract surfaces and uses docs-contract
  checks, stability-contract checks, and package publish checks to prevent drift.
- The admin UI uses Tailwind v4 + daisyUI semantic tokens, no Node toolchain,
  committed bundle output, literal utility strings, and strict conformance gates.

### Integration Points

- Phase 81 consumes the audit/token guidance and revises `brandbook/index.html`,
  `brandbook/brand-book.md`, `brandbook/tokens.json`, and `brandbook/tokens.css`.
- Phase 82 consumes the logo criteria and compares/refines SVG logo options.
- Phase 83 consumes voice/domain/copy and specimen guidance.
- Phase 84 consumes repo-hygiene and validation-gate decisions.
- No package code, public API, release workflow, or implemented admin UI changes
  should be introduced by Phase 80.
</code_context>

<specifics>
## Specific Ideas

The maintainer asked for a one-shot recommendation-first pass using subagents,
web research, local prompt synthesis, graphic design/branding principles,
UI/UX/DX lessons, and ecosystem examples, then stated they would follow the
recommendations. The recommendation set above is therefore treated as confirmed.

Research tracks run:

- Local prompts/codebase/planning synthesis.
- Brand/design-system and UI/UX lessons.
- Logo/visual identity stress test.
- Developer experience, repo hygiene, and OSS documentation ergonomics.

External sources considered included:

- W3C WCAG 2.2 for accessibility/focus/contrast framing.
- IBM Carbon, GitHub Primer, Atlassian Design, Shopify Polaris, GOV.UK Design
  System/content guidance, Tailwind, and daisyUI for token, accessibility,
  component, and content-design lessons.
- Hex, ExDoc, and Elixir documentation guidance for library-docs ergonomics.
- Current `Mailglass Lite` public web presence as a naming/collision signal.

Recommended current posture:

- Keep the brand center.
- Tighten the audit into a row-addressable register.
- Treat current SVGs as one draft direction.
- Keep tokens semantic, small, and accessibility-aware.
- Keep the brandbook source-native and out of package tarballs by default.
- Route implementation to Phases 81-84.
</specifics>

<deferred>
## Deferred Ideas

- Final token edits and contrast automation: Phase 81 / Phase 84.
- Final logo choice, outlined-vs-live-text distribution decision, and dark
  reversed variants: Phase 82.
- README/Hex.pm/HexDocs copy refresh, landing copy, launch copy, and microcopy
  library: Phase 83.
- JSON/SVG/HTML/file-size/package-hygiene validation scripts: Phase 84.
- PNG social cards, conference slide template, diagram component library, and
  automated contrast-report script: future requirements only if a real launch,
  repeated diagram need, or token churn justifies them.
- Trademark/legal clearance or rename strategy for `Mailglass`/`Mailglass Lite`:
  deferred unless major launch collateral or legal review requires it.

### Reviewed Todos (not folded)

None. `gsd-sdk query todo.match-phase "80"` returned no matched pending todos.
</deferred>
