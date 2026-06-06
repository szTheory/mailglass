# Phase 80: Brand Audit and Gap Register - Research

**Researched:** 2026-06-06  
**Domain:** Repo-grounded brand audit, row-addressable gap register, source-native brand artifacts  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Audit Posture
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

#### Brand Center
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

#### Visual System And Tokens
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

#### Logo And SVG Assets
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

#### Surface Stress Tests
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

#### Repo Hygiene And DX
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

#### External Lessons Applied
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

### Deferred Ideas (OUT OF SCOPE)
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

#### Reviewed Todos (not folded)

None. `gsd-sdk query todo.match-phase "80"` returned no matched pending todos.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRAND-01 | Maintainer can review a critical brand audit that classifies existing material as `KEEP`, `TIGHTEN`, `REWORK`, `ADD`, or `REMOVE`, with a direct judgment on distinctiveness, implementation readiness, accessibility, and repo fit. | Use the current `brandbook/brand-audit.md` narrative as draft input, then harden it into a stable row-addressable register with severity, evidence, rationale, target phase, and closeout cue. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `brandbook/brand-audit.md`] |
| BRAND-02 | The audit pressure-tests real surfaces: GitHub, README, Hex.pm, HexDocs, docs UI, code/terminal snippets, landing page, social preview, favicon, small monochrome mark, dark/light mode, diagrams, and UI states. | Require one explicit stress-test row or matrix entry for every named surface, including downstream handoff targets for Phases 81-84. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md`] |
</phase_requirements>

## Summary

Phase 80 should be planned as an evidence and decision artifact, not an implementation pass. The existing `brandbook/` directory is useful draft material, but it already speaks as if Phase 81-84 outputs are complete; the plan should revise `brandbook/brand-audit.md` into a candid audit and stable register that future phases can cite row by row. [VERIFIED: `brandbook/brand-audit.md`; VERIFIED: `.planning/STATE.md`; VERIFIED: `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md`]

The recommended output shape is one Markdown artifact at `brandbook/brand-audit.md` with: executive judgment, brand DNA, scorecard, required-surface stress test matrix, row-addressable gap register, prioritized action plan, downstream handoff map, validation expectations, and final quality gate. If the planner chooses a companion register section/file, it must keep stable IDs and easy citations for Phases 81-84. [VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`; VERIFIED: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`]

Primary recommendation: preserve the brand center and tighten the artifact into a register; do not churn the palette, voice, product positioning, logo direction, package code, admin UI, or release workflow in Phase 80. [VERIFIED: `.planning/PROJECT.md`; VERIFIED: `prompts/mailglass-brand-book.md`; VERIFIED: `mailglass_admin/docs/design-system.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Critical brand judgment | Planning artifact | `brandbook/brand-audit.md` | The decision is consumed by GSD plans and later brandbook edits; no runtime tier owns it. [VERIFIED: `.planning/ROADMAP.md`] |
| Gap register and row IDs | Planning artifact | Markdown under `brandbook/` | Stable row IDs are the anti-churn mechanism used successfully by Phase 74 and Phase 79. [VERIFIED: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`; VERIFIED: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`] |
| Token principles | Static brand artifacts | Admin design-system docs | Phase 80 ratifies principles; Phase 81 owns token file edits; admin mechanics remain governed by `mailglass_admin/docs/design-system.md`. [VERIFIED: `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md`; VERIFIED: `mailglass_admin/docs/design-system.md`] |
| Logo criteria | Static brand artifacts | Phase 82 plan | Current SVGs are one draft direction; option comparison and final mark decisions are Phase 82 responsibilities. [VERIFIED: `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md`; VERIFIED: `brandbook/assets/*.svg`] |
| Surface copy/specimens | Static brand artifacts | Phase 83 plan | Phase 80 should classify current readiness and hand off concrete copy/specimen rows; it should not refresh README, Hex.pm, HexDocs, or landing copy itself. [VERIFIED: `.planning/ROADMAP.md`] |
| Repo hygiene validation | Package config / static assets | Phase 84 plan | Core and admin package `files:` allowlists do not include `brandbook/`; Phase 84 owns executable JSON/SVG/HTML/package checks. [VERIFIED: `mix.exs`; VERIFIED: `mailglass_admin/mix.exs`; VERIFIED: `.planning/ROADMAP.md`] |

## Project Constraints

- No `AGENTS.md` was found at the repo root and no project-local `.codex/skills/` or `.agents/skills/` directories were found, so there are no extra project-local agent directives to include. [VERIFIED: `find . -maxdepth 3 ...`]
- `.planning/config.json` has `workflow.nyquist_validation: true`, so the plan needs a Validation Architecture section and Wave 0 gaps. [VERIFIED: `.planning/config.json`]
- `.planning/config.json` does not explicitly disable security enforcement, so this research includes a Security Domain section. [VERIFIED: `.planning/config.json`]
- `commit_docs` is true in `gsd-sdk query init.phase-op "80"`, so the research artifact should be committed after writing. [VERIFIED: `gsd-sdk query init.phase-op "80"`]

## Standard Stack

### Core

| Artifact / Tool | Version / Status | Purpose | Why Standard |
|-----------------|------------------|---------|--------------|
| Markdown | Existing repo convention | Audit narrative, register rows, final gate, and handoff map | Diffable, source-native, and consistent with GSD artifacts. [VERIFIED: `.planning/phases/*/*.md`; VERIFIED: `brandbook/brand-audit.md`] |
| Static HTML | `brandbook/index.html`, direct-open draft | Brandbook preview and source-native guide | The milestone explicitly avoids a build step, PDF, or vendor design tool. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `brandbook/index.html`] |
| JSON tokens | `brandbook/tokens.json`, valid JSON | Machine-readable token source for Phase 81/84 | Existing draft includes palette, light/dark roles, state, callout, code, type, spacing, radius, border, shadow, focus, and motion groups. [VERIFIED: `jq -e . brandbook/tokens.json`; VERIFIED: `brandbook/tokens.json`] |
| CSS custom properties | `brandbook/tokens.css` | Direct-open HTML tokens and docs/marketing prototypes | Existing draft maps token names to CSS variables and includes `prefers-reduced-motion`. [VERIFIED: `brandbook/tokens.css`] |
| SVG | `brandbook/assets/*.svg`, `brandbook/examples/*.svg` | Logo drafts and specimens | Existing SVGs parse as XML and are source-control friendly. [VERIFIED: `xmllint --noout brandbook/assets/*.svg brandbook/examples/*.svg`] |
| Elixir/Mix package allowlists | `mix.exs`, `mailglass_admin/mix.exs` | Package hygiene verification inputs | Current `files:` lists exclude `brandbook/`, so Phase 80 should preserve that policy and Phase 84 should verify it. [VERIFIED: `mix.exs`; VERIFIED: `mailglass_admin/mix.exs`] |

### Supporting

| Tool | Available | Version | Use in Planning |
|------|-----------|---------|-----------------|
| `jq` | yes | `jq-1.7.1-apple` | Fast token JSON parse check. [VERIFIED: command availability audit] |
| `xmllint` | yes | `libxml 2.9.13` | Fast SVG XML parse and HTML smoke parse. [VERIFIED: command availability audit] |
| `rg` | yes | `ripgrep 15.1.0` | Grep for required register rows, unsafe SVG patterns, package allowlist drift, and surface coverage. [VERIFIED: command availability audit] |
| `mix` | yes | `Mix 1.19.5` | Existing project verification and future package checks. [VERIFIED: command availability audit] |
| `node` | yes | `v22.14.0` | Optional ad hoc contrast math in research; do not add a Node dependency for Phase 80. [VERIFIED: command availability audit] |

### Package Legitimacy Audit

Not applicable. Phase 80 should install no external packages and should not add npm, Hex, Python, or other package dependencies. [VERIFIED: `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md`; VERIFIED: `.planning/REQUIREMENTS.md`]

## Architecture Patterns

### Pattern 1: Frozen Register With Separate Closeout

Use stable row IDs in the audit register and treat them as downstream citation anchors. Phase 74 used stable `GAP-NN` IDs as an anti-churn gate, and Phase 79 closed rows in a separate closeout artifact without editing the frozen register. [VERIFIED: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`; VERIFIED: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`]

Recommended row schema for Phase 80:

| Column | Purpose |
|--------|---------|
| `BRAND-GAP-NN` | Stable ID, never renumber after publication. [VERIFIED: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`] |
| `classification` | One of `KEEP`, `TIGHTEN`, `REWORK`, `ADD`, `REMOVE`. [VERIFIED: CONTEXT D-02] |
| `severity` | 1-5, with 4-5 requiring explicit closure or documented deferral before Phase 84 closeout. [VERIFIED: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`; VERIFIED: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`] |
| `surface` | One required BRAND-02 surface or `Cross-surface`. [VERIFIED: `.planning/REQUIREMENTS.md` BRAND-02] |
| `evidence` | Local artifact path and line, command output, or cited external source. [VERIFIED: GSD researcher instructions] |
| `rationale` | Why this affects readiness, accessibility, consistency, repo hygiene, or handoff. [VERIFIED: CONTEXT D-03] |
| `target phase` | `81`, `82`, `83`, `84`, or `future/deferred`. [VERIFIED: `.planning/ROADMAP.md` Phases 81-84] |
| `acceptance / closeout cue` | The concrete signal later agents can cite to close the row. [VERIFIED: CONTEXT D-02] |

### Pattern 2: Required-Surface Stress Matrix

Create one matrix row for every BRAND-02 surface before writing detailed gaps. This prevents the audit from over-focusing on the current draft HTML/SVGs while skipping Hex.pm, HexDocs, README, terminal snippets, dark/light modes, and UI states. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `brandbook/brand-audit.md`]

Recommended columns: `surface`, `current evidence`, `brand risk`, `classification`, `target phase`, `closeout cue`. [ASSUMED]

Required surfaces:

| Surface | Current Evidence | Planning Note |
|---------|------------------|---------------|
| GitHub | Root README, badges, repo description copy exists in draft audit | Audit should classify description/avatar/header readiness; Phase 83 owns copy refresh. [VERIFIED: `README.md`; VERIFIED: `brandbook/brand-audit.md`] |
| README | Root README and `examples/readme-header.svg` exist | Specimen uses generic `phx_new` text, so seed a `REWORK` row. [VERIFIED: `README.md`; VERIFIED: `brandbook/examples/readme-header.svg`] |
| Hex.pm | Package descriptions in `mix.exs` / admin `mix.exs` and draft copy block exist | Phase 80 should flag copy harmonization for Phase 83, not edit packages. [VERIFIED: `mix.exs`; VERIFIED: `mailglass_admin/mix.exs`; VERIFIED: `brandbook/brand-audit.md`] |
| HexDocs | ExDoc extras configured in core/admin mix files | If future logo/favicon is needed, use narrow copy/whitelist instead of importing all `brandbook/`. [VERIFIED: `mix.exs`; VERIFIED: `mailglass_admin/mix.exs`; CITED: https://hexdocs.pm/ex_doc/ExDoc.Formatter.html] |
| Docs UI | `examples/docs-page.svg` and admin design-system docs exist | Stress test docs layout against brand roles and admin constraints. [VERIFIED: `brandbook/examples/docs-page.svg`; VERIFIED: `mailglass_admin/docs/design-system.md`] |
| Code / terminal snippets | README quickstart and SVG specimens include code/terminal examples | Audit should reject generic Phoenix setup and prefer Mailglass flows. [VERIFIED: `README.md`; VERIFIED: `brandbook/examples/readme-header.svg`] |
| Landing page | Draft blueprint exists | Phase 80 can judge architecture; Phase 83 owns copy/specimen implementation. [VERIFIED: `brandbook/brand-audit.md`] |
| Social preview | `social-avatar.svg` exists and README header specimen exists | PNG exports remain deferred until release need. [VERIFIED: `brandbook/assets/social-avatar.svg`; VERIFIED: `.planning/REQUIREMENTS.md`] |
| Favicon | `assets/favicon.svg` exists | Legibility and fold ambiguity are Phase 82 criteria. [VERIFIED: `brandbook/assets/favicon.svg`; VERIFIED: CONTEXT D-13] |
| Small monochrome mark | `assets/logo-monochrome.svg` exists | CurrentColor construction is promising; small-size proof remains Phase 82. [VERIFIED: `brandbook/assets/logo-monochrome.svg`] |
| Dark/light mode | `tokens.css` includes `:root` and `[data-theme="dark"]` roles | Audit should require contrast and role review; Phase 81/84 own token edits/scripts. [VERIFIED: `brandbook/tokens.css`] |
| Diagrams | Docs-page and UI primitives specimens exist | Audit should define diagram principles, not create a diagram library. [VERIFIED: `brandbook/examples/*.svg`; VERIFIED: `.planning/REQUIREMENTS.md`] |
| UI states | Token state group and UI primitives specimen exist | Audit should call out state semantics and non-color indicators. [VERIFIED: `brandbook/tokens.json`; VERIFIED: `brandbook/examples/ui-primitives.svg`; CITED: https://www.w3.org/TR/WCAG22/#use-of-color] |

### Pattern 3: Handoff By Target Phase

Group actions by target phase after the register so later agents can plan Phases 81-84 without reopening the full audit. [VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md`]

Recommended handoff map:

| Target | Owns | Examples |
|--------|------|----------|
| Phase 81 | Source brandbook and token system | Remove completion overclaims, refine role token guidance, document dark/light/system behavior. [VERIFIED: `.planning/ROADMAP.md`] |
| Phase 82 | Logo and SVG asset system | Compare logo options, resolve favicon/monochrome/reversed/text-outline/title-ID questions. [VERIFIED: `.planning/ROADMAP.md`; VERIFIED: CONTEXT D-13] |
| Phase 83 | Visual specimens and copy blocks | Replace generic `phx_new` snippet, align "Delivered" and other domain wording, prepare README/Hex/HexDocs/landing/social copy. [VERIFIED: CONTEXT D-15; VERIFIED: `brandbook/examples/readme-header.svg`] |
| Phase 84 | Quality gate and repo hygiene | Commit validation scripts/checks for JSON, CSS token groups, SVG XML/accessibility/safety, HTML refs, file sizes, package allowlists, and git cleanliness. [VERIFIED: CONTEXT D-19; VERIFIED: `.planning/ROADMAP.md`] |

## Seed Register Findings

These are recommended starting rows for the planner to include or refine. They are evidence-backed and scoped to Phase 80's audit output, not implementation. [VERIFIED: repo file reads]

| Proposed ID | Classification | Sev | Surface | Evidence | Rationale | Target | Closeout Cue |
|-------------|----------------|-----|---------|----------|-----------|--------|--------------|
| BRAND-GAP-01 | REWORK | 5 | Cross-surface audit | `brandbook/brand-audit.md` says token/SVG/specimen assets are implemented and "yes" in final quality gate lines 174-207 and 378-387 | Draft overclaims completion before Phases 81-84 run, contradicting locked context. | 81 | `brandbook/brand-audit.md` clearly labels current assets as draft inputs and all later-phase work as handoff. |
| BRAND-GAP-02 | ADD | 5 | Gap register | Current audit has gaps/risks, but no stable row IDs or closeout schema | BRAND-01 requires critical classification; D-02 requires actionable row fields. | 80 | Register contains stable IDs, classification, severity, surface, evidence, rationale, target phase, and closeout cue. |
| BRAND-GAP-03 | ADD | 4 | Required surfaces | Current stress test table has many surfaces but not a strict BRAND-02 coverage contract | Missing one named surface would make BRAND-02 unverifiable. | 80 | Stress matrix includes GitHub, README, Hex.pm, HexDocs, docs UI, code/terminal snippets, landing page, social preview, favicon, small monochrome mark, dark/light mode, diagrams, and UI states. |
| BRAND-GAP-04 | ADD | 4 | Logo system | Current SVGs are one direction; context says Phase 82 must compare multiple options | Avoid premature final logo approval and brand churn. | 82 | Phase 82 plan cites this row and compares multiple credible mark directions before selection/refinement. |
| BRAND-GAP-05 | REWORK | 4 | Favicon / small mark | `favicon.svg` uses a lower triangular fold at 32x32; context flags possible document-corner/envelope/send-arrow ambiguity | Small-size ambiguity can weaken the mark and should be judged before approval. | 82 | Phase 82 includes small-size visual review and disposition for fold ambiguity. |
| BRAND-GAP-06 | TIGHTEN | 4 | SVG accessibility / safety | All draft SVGs use `id="title"` and `id="desc"`; repeated IDs collide if multiple SVGs are inlined in one document | Standalone SVGs are valid, but inline composition can break `aria-labelledby` references. | 82 / 84 | Phase 82 decides ID strategy; Phase 84 validates unique IDs or documented non-inline usage. |
| BRAND-GAP-07 | REWORK | 4 | README / terminal snippet | `examples/readme-header.svg` shows `mix archive.install hex phx_new`, not a Mailglass-specific flow | Generic Phoenix setup weakens the brand and contradicts context D-15. | 83 | Specimen or audit row uses a real Mailglass flow such as `mix deps.get`, `mix mailglass.install`, or a Mailglass preview/send command. |
| BRAND-GAP-08 | TIGHTEN | 3 | Tokens / callouts | Token check found `state.info` on `callout.infoBackground` at 4.37:1; WCAG AA normal text target is 4.5:1 | Pair may be fine for borders/non-text at 3:1 but should not be used for normal body text without guidance. | 81 / 84 | Token guidance distinguishes info border/accent usage from body-text usage, and Phase 84 contrast checks encode allowed pairs. |
| BRAND-GAP-09 | TIGHTEN | 3 | UI states | `ui-primitives.svg` uses color-coded status examples such as success/warning badges | WCAG 2.2 says color cannot be the only visual means of conveying information. | 83 / 84 | Specimens include text/icon/label state cues and audit guidance names non-color indicators. |
| BRAND-GAP-10 | TIGHTEN | 3 | Hex package hygiene | Core/admin `package()` files lists exclude `brandbook/`; context says brand assets stay out of tarballs by default | Prevent accidental package bloat and docs asset leakage. | 84 | Package validation confirms no broad `brandbook/` inclusion; only deliberate exact asset copies are allowed. |
| BRAND-GAP-11 | ADD | 3 | Name risk | Prompt and context mention Mailglass Lite as public collision signal | This is a brand risk note, not legal clearance or rename work. | Future / deferred | Audit records risk and deferral language without triggering rename/trademark scope. |
| BRAND-GAP-12 | KEEP | 2 | Brand center | Prompt, project, and draft audit align on "Mailglass makes email visible" and "glass is a metaphor, not a visual excuse" | Preserve strong existing strategy and avoid churn. | 81-83 | Later copy/specimens cite this row when preserving core concept. |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Brand audit structure | A free-form essay with untraceable recommendations | Stable Markdown register with row IDs and closeout cues | Later phases need citation targets and verification pressure. [VERIFIED: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`; VERIFIED: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`] |
| Token theory | A new design-system philosophy | Role-based token principles already locked in context and reflected in Carbon/Primer/Atlassian guidance | Role tokens are easier to theme and maintain than raw hex usage. [VERIFIED: CONTEXT D-08; CITED: https://carbondesignsystem.com/elements/color/overview/; CITED: https://primer.style/product/getting-started/foundations/color-usage/; CITED: https://atlassian.design/foundations/design-tokens] |
| Accessibility rules | Custom contrast/focus thresholds | WCAG 2.2 AA floor and WAI image/SVG guidance | WCAG and WAI are authoritative floors for contrast, non-text contrast, use of color, and image alternatives. [CITED: https://www.w3.org/TR/WCAG22/; CITED: https://www.w3.org/WAI/tutorials/images/; CITED: https://www.w3.org/TR/SVG/struct.html] |
| SVG safety checks | Visual review only | XML parse plus denylist for script/image/foreignObject/data/base64/external hrefs | SVG can reference external resources and scripts; file content validation needs defense in depth. [CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/href; CITED: https://developer.mozilla.org/en-US/docs/Web/API/SVGScriptElement/href; CITED: https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html] |
| Package hygiene | Manual eyeballing only | Mix package `files:` review and future Hex package diff/check | Hex provides package fetch/diff commands; local `files:` allowlists already exclude `brandbook/`. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Package.html; VERIFIED: `mix.exs`; VERIFIED: `mailglass_admin/mix.exs`] |

## Common Pitfalls

### Pitfall 1: Treating The Draft Brandbook As Approved

What goes wrong: The plan merely pretties `brandbook/brand-audit.md` and leaves "implemented" language that implies Phase 81-84 assets are complete. [VERIFIED: `brandbook/brand-audit.md`; VERIFIED: CONTEXT D-01]

How to avoid: Make "draft inputs, not approved outputs" explicit in the executive judgment and seed at least one high-severity row for completion overclaim. [VERIFIED: CONTEXT D-01]

### Pitfall 2: Register Without Stable Closeout Pressure

What goes wrong: Recommendations are present but cannot be cited by later phase plans, so Phase 81-84 agents reopen taste debates. [VERIFIED: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`; VERIFIED: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`]

How to avoid: Use stable IDs and a severity rubric that forces explicit closure or deferral for high-severity rows. [VERIFIED: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`; VERIFIED: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`]

### Pitfall 3: Taste Rows With No Downstream Action

What goes wrong: The audit becomes subjective critique and violates D-03. [VERIFIED: CONTEXT D-03]

How to avoid: Add rows only for required surfaces, later phase handoff, brand consistency, accessibility, repo hygiene, or future verification. [VERIFIED: CONTEXT D-03]

### Pitfall 4: Accidental Admin UI Framework Fork

What goes wrong: Brandbook token guidance contradicts the shipped Tailwind/daisyUI admin design-system mechanics. [VERIFIED: CONTEXT D-10; VERIFIED: `mailglass_admin/docs/design-system.md`]

How to avoid: State that `mailglass_admin/docs/design-system.md` governs implemented product UI; brandbook tokens govern docs, marketing, future collateral, and prototypes unless a future product phase deliberately maps them. [VERIFIED: CONTEXT D-10]

### Pitfall 5: SVG Accessibility IDs Look Fine In Isolation

What goes wrong: Standalone SVGs with `id="title"` / `id="desc"` parse and expose text, but multiple inline SVGs can duplicate IDs and confuse `aria-labelledby`. [VERIFIED: `brandbook/assets/*.svg`; CITED: https://www.w3.org/TR/SVG/struct.html]

How to avoid: Register the issue for Phase 82/84; do not solve it in Phase 80. [VERIFIED: CONTEXT D-13]

### Pitfall 6: Contrast Checks Stop At The Happy Path

What goes wrong: The known admin contrast tests pass, but brandbook token pairs and callout usages are not executable yet. [VERIFIED: `mailglass_admin/test/mailglass_admin/accessibility_test.exs`; VERIFIED: token contrast command]

How to avoid: Record the 4.37:1 `state.info` on `infoBackground` pair as usage guidance or a Phase 81/84 validation row; distinguish normal text from non-text/border use. [VERIFIED: token contrast command; CITED: https://www.w3.org/TR/WCAG22/#contrast-minimum; CITED: https://www.w3.org/TR/WCAG22/#non-text-contrast]

### Pitfall 7: Source-Native Drifts Into Asset Pipeline

What goes wrong: The plan asks for screenshots, PDFs, fonts, PNG batches, or design-vendor files in Phase 80. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: CONTEXT D-16]

How to avoid: Keep Phase 80 to Markdown audit/register edits only; route scripts to Phase 84 and PNG exports to future release needs. [VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `.planning/REQUIREMENTS.md`]

## Code Examples

### Register Row Skeleton

```markdown
| BRAND-GAP-07 | REWORK | 4 | README / terminal snippet | `brandbook/examples/readme-header.svg:18` shows generic `phx_new` setup | README specimen should demonstrate Mailglass value, not Phoenix bootstrap | 83 | Specimen uses a Mailglass install, preview, send, or doctor flow |
```

Source: Phase 74 row-addressable gap register pattern and Phase 80 context D-02/D-15. [VERIFIED: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`; VERIFIED: CONTEXT D-02; VERIFIED: CONTEXT D-15]

### Fast Local Validation Commands

```bash
jq -e . brandbook/tokens.json
xmllint --noout brandbook/assets/*.svg brandbook/examples/*.svg
xmllint --html --noout brandbook/index.html
rg -n '<script|foreignObject|<image|href=|xlink:href|data:|base64' brandbook/assets brandbook/examples
rg -n 'GitHub|README|Hex.pm|HexDocs|docs UI|code|terminal|landing|social|favicon|monochrome|dark|light|diagram|UI states' brandbook/brand-audit.md
```

Source: commands ran successfully for JSON/XML/HTML parse in this session; unsafe-pattern grep is a proposed Phase 84-style check, not an existing committed gate. [VERIFIED: command output; ASSUMED]

## State Of The Art

| Topic | Current External Posture | Impact For Phase 80 |
|-------|--------------------------|---------------------|
| Accessibility floor | WCAG 2.2 requires text contrast, non-text contrast, visible focus, target-size, and no color-only meaning in relevant contexts. [CITED: https://www.w3.org/TR/WCAG22/] | Audit must treat accessibility as brand-readiness, not optional polish. |
| Image alternatives | WAI image guidance ties text alternatives to image purpose: informative, decorative, functional, images of text, complex diagrams, and grouped images. [CITED: https://www.w3.org/WAI/tutorials/images/] | SVG specimens and README/docs images need context-appropriate alt/description guidance. |
| SVG title/desc | SVG 2 makes selected `title`/`desc` text available to platform accessibility APIs and warns against empty text. [CITED: https://www.w3.org/TR/SVG/struct.html] | Phase 80 should require accessible metadata but hand off duplicate-ID and inline-use policy. |
| Role-based tokens | Carbon, Primer, and Atlassian document role/semantic tokens instead of raw value usage. [CITED: https://carbondesignsystem.com/elements/color/overview/; CITED: https://primer.style/product/getting-started/foundations/color-usage/; CITED: https://atlassian.design/foundations/design-tokens] | Phase 80 should ratify small role-based token principles, not rewrite token files. |
| Security for authored files | OWASP file guidance recommends allowlists, file size limits, file content validation, and defense in depth for retrievable files; MDN documents SVG `href` as capable of loading image or script resources. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html; CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/href] | Phase 80 should name SVG/HTML safety gates for Phase 84. |
| Hex package audit | Hex provides package fetch/diff commands; local package `files:` allowlists determine included package contents. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Package.html; VERIFIED: `mix.exs`; VERIFIED: `mailglass_admin/mix.exs`] | Phase 80 should preserve "brandbook out of tarballs by default" and route executable proof to Phase 84. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `mix` / Elixir | Existing project verification and package checks | yes | Mix 1.19.5 / Elixir 1.19.5 | None needed for planning. [VERIFIED: command availability audit] |
| `jq` | JSON token parse check | yes | 1.7.1-apple | Use `node -e` JSON parse if unavailable. [VERIFIED: command availability audit] |
| `xmllint` | SVG/XML/HTML parse check | yes | libxml 2.9.13 | Use Elixir XML/HTML parser or browser smoke in Phase 84 if unavailable. [VERIFIED: command availability audit] |
| `rg` | Surface coverage and safety grep | yes | ripgrep 15.1.0 | Use `grep -R` if unavailable. [VERIFIED: command availability audit] |
| `node` | Optional ad hoc contrast math | yes | v22.14.0 | Use Elixir test helper or shell script in Phase 84. [VERIFIED: command availability audit] |

Missing dependencies with no fallback: none for Phase 80 planning. [VERIFIED: command availability audit]

Missing dependencies with fallback: no committed contrast checker exists; planner should not require a new package install in Phase 80. [VERIFIED: local search; VERIFIED: CONTEXT D-19]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Ad hoc fast checks: `jq`, `xmllint`, `rg`, plus manual Markdown review. Existing admin tests cover admin palette/contrast but not `brandbook/`. [VERIFIED: command output; VERIFIED: `mailglass_admin/test/mailglass_admin/accessibility_test.exs`] |
| Config file | None for brandbook validation yet. [VERIFIED: local search] |
| Quick run command | `jq -e . brandbook/tokens.json && xmllint --noout brandbook/assets/*.svg brandbook/examples/*.svg && xmllint --html --noout brandbook/index.html` [VERIFIED: command output] |
| Full suite command | No committed Phase 80 brandbook suite exists; use quick checks plus Markdown criteria review for Phase 80, and create executable gates in Phase 84. [VERIFIED: local search; VERIFIED: `.planning/ROADMAP.md`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| BRAND-01 | Audit includes critical judgment and classifies material as `KEEP`, `TIGHTEN`, `REWORK`, `ADD`, `REMOVE`. | grep + manual review | `rg -n 'KEEP|TIGHTEN|REWORK|ADD|REMOVE|BRAND-GAP-[0-9]+' brandbook/brand-audit.md` | Partial today; row IDs missing, Wave 0 gap. [VERIFIED: `brandbook/brand-audit.md`] |
| BRAND-01 | Actionable rows include severity, surface, evidence, rationale, target phase, and closeout cue. | manual schema review | Review register table columns in `brandbook/brand-audit.md` | Missing today; Wave 0 gap. [VERIFIED: `brandbook/brand-audit.md`] |
| BRAND-02 | Required surfaces are all represented. | grep + manual review | `rg -n 'GitHub|README|Hex.pm|HexDocs|docs UI|code|terminal|landing|social|favicon|monochrome|dark|light|diagram|UI states' brandbook/brand-audit.md` | Partial today; stress test table exists but needs strict coverage. [VERIFIED: `brandbook/brand-audit.md`] |
| BRAND-02 | Accessibility and token stress risks are captured. | command + manual review | Token contrast command from this research, then audit rows for any failing/borderline pairs | No committed script; Wave 0 gap. [VERIFIED: token contrast command] |
| BRAND-02 | SVG safety/accessibility risks are captured. | XML parse + grep | `xmllint --noout brandbook/assets/*.svg brandbook/examples/*.svg && rg -n '<script|foreignObject|<image|href=|xlink:href|data:|base64' brandbook/assets brandbook/examples` | Parser available; no committed script. [VERIFIED: command output; VERIFIED: local search] |

### Sampling Rate

- Per task commit: run the quick JSON/XML/HTML parse command and Markdown grep for required classifications/surfaces. [VERIFIED: command output; ASSUMED]
- Per wave merge: review the register manually against BRAND-01/02 and ensure every severity 4-5 row has a target phase and closeout cue. [VERIFIED: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`; VERIFIED: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`]
- Phase gate: no source brand artifacts besides the Phase 80 audit/register should be changed; `git diff -- brandbook/brand-book.md brandbook/index.html brandbook/tokens.json brandbook/tokens.css brandbook/assets brandbook/examples README.md mix.exs mailglass_admin/mix.exs` should show no unintended implementation edits. [VERIFIED: CONTEXT phase boundary; ASSUMED]

### Wave 0 Gaps

- [ ] No committed brandbook validation script exists for JSON/SVG/HTML/file-size/package checks; Phase 84 owns it. [VERIFIED: local search; VERIFIED: `.planning/ROADMAP.md`]
- [ ] No committed brandbook contrast checker exists; Phase 80 should only identify required pairs and gaps. [VERIFIED: local search; VERIFIED: CONTEXT D-19]
- [ ] No automated Markdown schema test exists for the audit register; Phase 80 can use manual review and grep. [VERIFIED: local search]
- [ ] No package tarball check currently proves `brandbook/` exclusion; local `package()` allowlists exclude it, and Phase 84 should make this executable. [VERIFIED: `mix.exs`; VERIFIED: `mailglass_admin/mix.exs`]
- [ ] No local HTML link checker exists for `brandbook/index.html`; `xmllint --html --noout` only proves parse, not link reachability. [VERIFIED: command output]

## Security Domain

### Applicable ASVS Categories

OWASP ASVS 5.0 is the current stable version as of May 2025, and OWASP's ASVS index lists categories including encoding/sanitization, validation/business logic, web frontend security, and files/resources. [CITED: https://github.com/OWASP/ASVS; CITED: https://cheatsheetseries.owasp.org/IndexASVS.html]

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V1 Encoding and Sanitization | yes | Treat authored SVG/HTML as parseable content and reject active/external constructs in later validation. [CITED: https://cheatsheetseries.owasp.org/IndexASVS.html; CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/href] |
| V2 Validation and Business Logic | yes | Validate register schema and artifact policy against locked decisions; do not add rows without downstream action. [VERIFIED: CONTEXT D-02/D-03; CITED: https://cheatsheetseries.owasp.org/IndexASVS.html] |
| V3 Web Frontend Security | yes, limited | Direct-open HTML and SVG specimens should avoid external assets/scripts and unsafe SVG constructs. [VERIFIED: `brandbook/index.html`; CITED: https://developer.mozilla.org/en-US/docs/Web/API/SVGScriptElement/href] |
| V4 Access Control | no | Phase 80 does not add app routes, auth, or user data access. [VERIFIED: CONTEXT phase boundary] |
| V5 Legacy ASVS validation/sanitization framing | yes, for compatibility with existing GSD templates | Use input/file validation thinking for SVG/JSON/HTML authored artifacts. [ASSUMED]; [CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| V12 Files and Resources | yes | Keep brand assets allowlisted, small, source-native, and out of package tarballs by default. [CITED: https://github.com/OWASP/ASVS/blob/master/4.0/en/0x20-V12-Files-Resources.md; VERIFIED: CONTEXT D-16/D-18] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Supply-chain expansion through "just install a checker" | Tampering / Elevation of Privilege | No package installs in Phase 80; use existing `jq`, `xmllint`, `rg`, manual review. [VERIFIED: CONTEXT phase boundary; VERIFIED: command availability audit] |
| Active SVG content sneaks into committed assets | Tampering / Information Disclosure | Phase 80 names Phase 84 gates rejecting `<script>`, `<image>`, `foreignObject`, `data:`, `base64`, and external `href`/`xlink:href`. [VERIFIED: CONTEXT D-19; CITED: https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/href; CITED: https://developer.mozilla.org/en-US/docs/Web/API/SVGScriptElement/href] |
| Duplicate SVG `title`/`desc` IDs break inline accessibility | Spoofing / Repudiation of accessible names | Register as Phase 82/84 issue; standalone parse is not enough. [VERIFIED: `brandbook/assets/*.svg`; CITED: https://www.w3.org/TR/SVG/struct.html] |
| Package tarball bloat or accidental collateral publishing | Information Disclosure / Denial of Service | Preserve package `files:` allowlists excluding `brandbook/`; Phase 84 should prove tarball contents. [VERIFIED: `mix.exs`; VERIFIED: `mailglass_admin/mix.exs`; CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Package.html] |
| Trademark/name-risk overreach | Repudiation / Legal risk | Record `Mailglass Lite` as risk note only; defer legal clearance or rename work. [VERIFIED: CONTEXT D-21; VERIFIED: `prompts/mailglass-brand-book.md`] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The exact stress matrix columns can be `surface`, `current evidence`, `brand risk`, `classification`, `target phase`, and `closeout cue`. | Architecture Patterns | Low; planner may choose another Markdown layout if D-02 fields remain present. |
| A2 | The quick grep commands are adequate as Phase 80 feedback, with real executable checks deferred to Phase 84. | Validation Architecture | Medium; if planner wants stricter verification in Phase 80, it must still avoid installing packages or implementing Phase 84. |
| A3 | Existing GSD security templates may still refer to ASVS v4-style V5 categories, so the Security Domain includes both current ASVS 5 category mapping and a compatibility note. | Security Domain | Low; it only affects terminology, not the phase's concrete controls. |

## Open Questions (RESOLVED)

1. Should `brandbook/brand-audit.md` embed the register or link to a companion section/file?
   - What we know: Context allows either shape if success criteria and citations are reliable. [VERIFIED: CONTEXT the agent's Discretion]
   - What's unclear: The planner's preferred artifact organization. [ASSUMED]
   - RESOLVED: Keep it embedded in `brandbook/brand-audit.md` for Phase 80; `80-01-PLAN.md` makes `brandbook/brand-audit.md` the only source artifact modified and requires stable `BRAND-GAP-NN` IDs. [VERIFIED: `.planning/phases/80-brand-audit-and-gap-register/80-01-PLAN.md`]

2. What severity threshold should block later phase closeout?
   - What we know: Phase 74/79 used severity 4-5 as closeout blockers, with severity 3 requiring explicit disposition. [VERIFIED: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`; VERIFIED: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`]
   - What's unclear: Whether brand rows should use the same exact closeout threshold. [ASSUMED]
   - RESOLVED: Reuse the Phase 74/79 semantics; `80-01-PLAN.md` requires severity 4-5 rows to have explicit closure or documented deferral before Phase 84 closeout. [VERIFIED: `.planning/phases/80-brand-audit-and-gap-register/80-01-PLAN.md`]

3. Should current SVG live text be allowed in distribution assets?
   - What we know: Current primary SVG uses live `<text>`; context defers live-text vs outlined distribution files to Phase 82. [VERIFIED: `brandbook/assets/logo-primary.svg`; VERIFIED: CONTEXT D-13]
   - What's unclear: Final distribution policy. [VERIFIED: CONTEXT D-13]
   - RESOLVED: Phase 80 registers this as a Phase 82/84 decision and does not resolve distribution policy; `80-01-PLAN.md` includes `BRAND-GAP-06` and Phase 82/84 handoff coverage. [VERIFIED: `.planning/phases/80-brand-audit-and-gap-register/80-01-PLAN.md`]

## Sources

### Primary - Repo (HIGH confidence)

- `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md` - locked decisions, scope, canonical references, deferred items. [VERIFIED: repo file read]
- `.planning/REQUIREMENTS.md` - BRAND-01 and BRAND-02 requirements. [VERIFIED: repo file read]
- `.planning/ROADMAP.md` - Phase 80-84 goals and success criteria. [VERIFIED: repo file read]
- `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/METHODOLOGY.md` - milestone history, scope locks, and decisive-by-default posture. [VERIFIED: repo file read]
- `brandbook/brand-audit.md`, `brandbook/brand-book.md`, `brandbook/README.md`, `brandbook/index.html`, `brandbook/tokens.json`, `brandbook/tokens.css`, `brandbook/assets/*.svg`, `brandbook/examples/*.svg` - draft brand inputs. [VERIFIED: repo file read]
- `prompts/mailglass-brand-book.md` - prompt-era source brand strategy. [VERIFIED: repo file read]
- `mailglass_admin/docs/design-system.md`, `mailglass_admin/test/mailglass_admin/accessibility_test.exs`, `mailglass_admin/scripts/check-conformance.sh` - implemented admin UI constraints and existing verification pattern. [VERIFIED: repo file read]
- `README.md`, `mix.exs`, `mailglass_admin/mix.exs` - public copy and package/docs allowlist inputs. [VERIFIED: repo file read]

### Primary - Official External (HIGH confidence)

- W3C WCAG 2.2 - contrast, non-text contrast, use of color, focus, target-size baseline. https://www.w3.org/TR/WCAG22/ [CITED]
- W3C WAI Images Tutorial - image alternative text by purpose. https://www.w3.org/WAI/tutorials/images/ [CITED]
- W3C SVG 2 `title`/`desc` - descriptive text and accessibility API mapping. https://www.w3.org/TR/SVG/struct.html [CITED]
- Carbon Design System color overview - role-based token model. https://carbondesignsystem.com/elements/color/overview/ [CITED]
- GitHub Primer color usage - functional/component tokens, color modes, and semantic roles. https://primer.style/product/getting-started/foundations/color-usage/ [CITED]
- Atlassian Design Tokens - tokens as named design decisions and meaning-based selection. https://atlassian.design/foundations/design-tokens [CITED]
- GOV.UK content guidance - user needs, clear structure, clear language, and tone. https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/tone-of-voice/ [CITED]
- Hex `mix hex.package` docs - package fetch/diff behavior. https://hexdocs.pm/hex/Mix.Tasks.Hex.Package.html [CITED]
- ExDoc formatter docs - logo/favicon/assets copy support exists in ExDoc formatters. https://hexdocs.pm/ex_doc/ExDoc.Formatter.html [CITED]
- OWASP File Upload Cheat Sheet and ASVS materials - defense-in-depth file validation and ASVS categories. https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html, https://github.com/OWASP/ASVS, https://cheatsheetseries.owasp.org/IndexASVS.html [CITED]
- MDN SVG `href` and `SVGScriptElement.href` - SVG resource/script references. https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/href, https://developer.mozilla.org/en-US/docs/Web/API/SVGScriptElement/href [CITED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - Phase installs no packages; repo artifacts and tools were read/probed directly. [VERIFIED: repo file reads; VERIFIED: command availability audit]
- Architecture: HIGH - Follows locked Phase 80 scope and proven Phase 74/79 register pattern. [VERIFIED: `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md`; VERIFIED: `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md`; VERIFIED: `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md`]
- Pitfalls: HIGH - Seed rows are grounded in current files and locked context. [VERIFIED: repo file reads]
- External standards: MEDIUM-HIGH - Official sources were checked, but Phase 80 only needs audit guidance, not implementation. [CITED: official sources]
- Validation: MEDIUM - Fast checks are available, but committed brandbook-specific gates are intentionally Wave 0 gaps for Phase 84. [VERIFIED: command output; VERIFIED: local search]

**Research date:** 2026-06-06  
**Valid until:** 2026-07-06 for repo-scoped planning; re-check official accessibility/security docs if Phase 84 validation design is delayed beyond this date. [ASSUMED]
