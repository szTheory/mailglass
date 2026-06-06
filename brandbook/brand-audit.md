# Mailglass Brand Pressure Test

Date: 2026-06-05

Phase 80 scope: this file is the audit and gap-register gate for v1.8.
The existing `brandbook/` files are draft inputs from commit `572f3eb2`,
not approved Phase 81-84 outputs. Phase 80 approves only a candid,
row-addressable audit in `brandbook/brand-audit.md`; it does not approve
final tokens, logos, copy, specimens, package hygiene proof, or validation
scripts.

Sources reviewed:

- Existing Mailglass brand book in `prompts/`
- Project positioning and planning context in `.planning/`
- Implemented admin design-system guidance in `mailglass_admin/docs/design-system.md`
- Current README/package-family posture
- Draft `brandbook/` Markdown, HTML, token, SVG, and specimen files as evidence
- Phase 74 gap-register and Phase 79 separate-closeout precedents

## Section 1 - Executive Judgment

The brand center is strong enough to build from: **Mailglass makes email
visible**. The supporting line **Mail you can see through** is memorable,
specific to the product, and useful for both interface and documentation
decisions. Preserve the governing rule: **glass is a metaphor, not a visual
excuse**.

The current draft direction is strategically sound, but it is not an approved
v1.8 brand system. Draft files exist under `brandbook/`, including tokens,
SVGs, specimens, HTML, and source Markdown; that is evidence for this audit,
not proof that Phases 81-84 are complete. Any claim like "assets are committed,
therefore the brand system is done" is rejected.

Keep the product story Phoenix-native, transactional, and operational. Mailglass
is infrastructure built on Swoosh and shipped as `mailglass`,
`mailglass_admin`, and `mailglass_inbound`. It must not drift into marketing
email, campaigns, newsletters, drip automation, outreach workflows, growth
language, or "Swoosh replacement" framing.

Keep the thoughtful-maintainer voice: exact, calm, technical, and helpful under
failure. Preserve the domain nouns that make the product feel real: Mailable,
Message, Delivery, Event, InboundMessage, Mailbox, Suppression, timeline,
provider, adapter, stream, headers, route, render, preview, observe, inspect,
and verify.

Keep the visual center restrained: Ink, Glass, Ice, Mist, Paper, and Slate;
Inter / Inter Tight / IBM Plex Mono; flat panes; restrained borders; semantic
state color; visible focus; and motion restraint. Reject glassmorphism, bevels,
glossy highlights, heavy shadows, decorative gradients, blobs, and one-note
Glass/cyan flooding.

`mailglass_admin/docs/design-system.md` remains the implemented product UI
constraint source. The brandbook may guide docs, marketing, lightweight
prototypes, and future collateral, but it must not become a second admin UI
framework or contradict the shipped Tailwind/daisyUI mechanics.

## Section 2 - Brand DNA Extraction

| Element | Phase 80 judgment | Classification |
|---|---|---|
| Brand essence | Mail you can see through. | KEEP |
| Core promise | Email becomes inspectable application infrastructure. | KEEP |
| Audience | Senior Phoenix and Elixir teams building production transactional email. | KEEP |
| Emotional tone | Calm, clear, technical, composed, useful. | KEEP |
| Product category | Phoenix-native email framework on top of Swoosh. | KEEP |
| Visual metaphor | Clarity through panes, boundaries, timelines, headers, and inspection surfaces. | KEEP |
| Voice | Thoughtful maintainer: direct recovery guidance, exact nouns, low hype. | KEEP |
| Anti-traits | Salesy, cute, glossy, mascot-driven, generic SaaS, growth-marketing-coded. | KEEP |
| Admin UI boundary | `mailglass_admin/docs/design-system.md` governs implemented product UI mechanics. | TIGHTEN |
| Current `brandbook/` assets | Useful draft evidence, not approved v1.8 completion evidence. | REWORK |

This should feel like:

- a well-lit workbench
- a mail console
- a serious Phoenix library
- a system with observable cause and effect

This should never feel like:

- an outbound marketing SaaS
- a blue-purple devtool template
- a growth dashboard
- an AI launch page
- a literal glass-effect UI kit

## Section 3 - Classification Vocabulary And Pressure-Test Scorecard

Classification vocabulary:

- `KEEP` - preserve as-is or preserve as a governing principle.
- `TIGHTEN` - keep the direction, but add constraints, wording, proof, or validation pressure.
- `REWORK` - the draft direction is useful, but it must materially change before approval.
- `ADD` - missing structure, asset, evidence, or validation expectation.
- `REMOVE` - delete from the canonical path or explicitly reject.

| Dimension | Current audit judgment | Risk | Classification | Required handoff |
|---|---|---|---|---|
| Distinctiveness | "Email made visible" is memorable and ownable in this category. | Pane/glass metaphor could become generic if overused. | KEEP | Later copy/specimens cite `BRAND-GAP-12`. |
| Developer credibility | Maintainer voice and low-hype language fit OSS. | README, Hex.pm, or launch copy could drift into SaaS tone. | TIGHTEN | Phase 83 prepares copy blocks and banned-vocabulary guidance. |
| Elixir ecosystem fit | Understated, technical, Phoenix-native, and Swoosh-composed. | Too much collateral could feel commercial or like a Swoosh replacement. | KEEP | Keep examples and docs before slogans. |
| Visual coherence | Palette, type, panes, and motion restraint are coherent. | Draft assets may over-imply final approval. | TIGHTEN | Phase 81/82 refine tokens and SVG system with proof. |
| Logo readiness | One credible draft SVG direction exists. | No multiple-option review; small mark may read as a document corner, envelope, or send arrow. | REWORK | Phase 82 compares options and resolves favicon/monochrome/reversed variants. |
| Color-system readiness | Draft role tokens exist for brand/docs examples. | Token pairs and admin-product boundary need explicit guidance. | TIGHTEN | Phase 81 owns final token language; Phase 84 owns contrast checks. |
| Typography readiness | Inter, Inter Tight, and IBM Plex Mono are practical OSS-safe choices. | Font binaries or tight marketing typography would create repo and readability risk. | KEEP | Recommend stacks only; do not commit font files. |
| Design-token readiness | Draft JSON/CSS tokens exist as evidence. | Product UI and brandbook tokens can diverge if the admin design-system boundary is vague. | TIGHTEN | Phase 81 aligns wording with `mailglass_admin/docs/design-system.md`. |
| UI state readiness | Draft examples include state colors and labels. | Color-only state meaning would violate accessibility intent. | TIGHTEN | Phase 83/84 add non-color state cues and validation. |
| Docs/README usefulness | Messaging is strong and concrete. | Current specimen includes generic Phoenix setup instead of Mailglass flow. | REWORK | Phase 83 replaces generic snippets and prepares public-surface copy. |
| Accessibility | WCAG intent is present. | Contrast, focus, SVG IDs, keyboard, reduced motion, and dark/light behavior need closure proof. | TIGHTEN | Phase 84 validates or documents every gate. |
| Repo readiness | Source-native `brandbook/` direction is right. | Future binary exports, screenshots, or broad package inclusion could bloat the repo or Hex tarballs. | TIGHTEN | Phase 84 implements package/file-size/git-cleanliness proof. |
| Maintainability | The small, restrained system is maintainable. | It could grow into a design-system side quest. | KEEP | Keep artifacts lean and route expansion only to real surface needs. |

## Section 4 - Required Surface Stress Matrix

This matrix is the BRAND-02 coverage gate. Each required surface appears at
least once. The draft evidence is read-only in Phase 80; implementation belongs
to the target phase named in the row.

| Surface | Current Evidence | Brand Risk | Classification | Target Phase | Closeout Cue |
|---|---|---|---|---|---|
| GitHub | Root `README.md`, badge set, draft GitHub description copy in this audit | Repo header and social avatar could imply final brand approval before Phases 82-83 | TIGHTEN | Phase 83 | GitHub description/header copy cites the final Phase 83 copy block and approved Phase 82 mark. |
| README | Root `README.md`; `brandbook/examples/readme-header.svg` | README specimen uses generic Phoenix setup instead of a Mailglass flow | REWORK | Phase 83 | README/specimen install snippet uses a real Mailglass onboarding or preview/send flow. |
| Hex.pm | Root/admin `mix.exs` package descriptions; draft Hex.pm copy block | Package copy can drift from Phoenix-native transactional infrastructure into marketing-tool language | TIGHTEN | Phase 83 | Hex.pm short/long copy is reviewed against the approved voice and product scope. |
| HexDocs | ExDoc configuration in package files; draft docs-page specimen | Future logo/favicon or docs copy could accidentally pull broad `brandbook/` assets into packages | TIGHTEN | Phase 84 | Package/docs validation proves no broad `brandbook/` inclusion and deliberate exact asset use only. |
| docs UI | `brandbook/examples/docs-page.svg`; `mailglass_admin/docs/design-system.md` | Brandbook could fork admin UI mechanics or conflict with semantic-token discipline | TIGHTEN | Phase 81 | Brandbook source says admin design-system remains product UI source of truth. |
| code/terminal snippets | Root README quickstart; `brandbook/examples/readme-header.svg:16-19` | Generic `mix archive.install hex phx_new` weakens the Mailglass-specific story | REWORK | Phase 83 | Specimens and copy blocks use real Mailglass commands and domain examples. |
| landing page | Draft landing/docs blueprint in this audit | Useful architecture exists, but final copy and media are not approved | TIGHTEN | Phase 83 | Landing copy is generated from approved Phase 83 blocks without adding new asset types. |
| social preview | `brandbook/assets/social-avatar.svg`; README header specimen | Avatar exists as one draft direction; PNG card exports are not justified by Phase 80 | TIGHTEN | Phase 82 / Future | Phase 82 approves mark direction; PNG exports stay future-only until launch/release need. |
| favicon | `brandbook/assets/favicon.svg` | Lower fold at 32px may read as document corner, envelope, or send arrow | REWORK | Phase 82 | Phase 82 includes small-size review and resolves favicon fold ambiguity. |
| small monochrome mark | `brandbook/assets/logo-monochrome.svg` | Monochrome construction is promising but not proven at tiny sizes or reversed contexts | REWORK | Phase 82 | Phase 82 records small monochrome, reversed, and dark-background disposition. |
| dark/light mode | `brandbook/tokens.css`; `brandbook/tokens.json` | Token roles exist, but contrast and system-mode guidance need proof | TIGHTEN | Phase 81 / Phase 84 | Phase 81 documents role usage; Phase 84 validates key text and non-text pairs. |
| diagrams | `brandbook/examples/docs-page.svg`; `brandbook/examples/ui-primitives.svg` | Diagram language could become decorative or a new illustration system | TIGHTEN | Phase 83 / Future | Phase 83 keeps diagrams as implementation aids; reusable diagram library stays future-only. |
| UI states | `brandbook/tokens.json` state group; `brandbook/examples/ui-primitives.svg` | State meaning may rely too heavily on color, especially success/warning examples | TIGHTEN | Phase 83 / Phase 84 | Specimens use text/icon/label cues; Phase 84 checks non-color state indicators where practical. |

## Section 5 - BRAND-GAP Register

Stable `BRAND-GAP-NN` IDs are the anti-churn citation gate for Phases 81-84.
Do not renumber rows after publication. Severity uses a 1-5 scale; severity
4-5 rows require explicit closure or documented deferral before Phase 84
closeout. Phase 80 follows the Phase 74 stable-register precedent and the
Phase 79 frozen-register plus separate-closeout precedent.

| BRAND-GAP-NN | Classification | Severity | Surface | Evidence | Rationale | Target Phase | Acceptance / Closeout Cue |
|---|---|---:|---|---|---|---|---|
| BRAND-GAP-01 | REWORK | 5 | Cross-surface audit | `brandbook/brand-audit.md` previously treated committed tokens/SVG/specimens as complete outputs | Draft overclaims would let downstream agents skip required Phase 81-84 review. | Phase 81 | Audit and source brandbook clearly say current `brandbook/` files are draft inputs, not approved outputs. |
| BRAND-GAP-02 | ADD | 5 | Gap register | Current audit had prose gaps but no stable row IDs or closeout schema | BRAND-01 needs row-addressable judgment with severity, evidence, rationale, target phase, and closeout cue. | Phase 80 / Phase 84 | This register exists; Phase 84 can cite each row without editing the frozen audit. |
| BRAND-GAP-03 | ADD | 4 | Required surfaces | Current stress test was broad but not a strict BRAND-02 coverage contract | Missing a named surface would make BRAND-02 unverifiable. | Phase 80 / Phase 84 | Required Surface Stress Matrix covers GitHub, README, Hex.pm, HexDocs, docs UI, code/terminal snippets, landing page, social preview, favicon, small monochrome mark, dark/light mode, diagrams, and UI states. |
| BRAND-GAP-04 | ADD | 4 | Logo system | `brandbook/assets/*.svg` is one credible draft direction; D-11 requires multiple-option review | Avoid premature final logo approval and brand churn. | Phase 82 | Phase 82 compares multiple credible mark directions before selecting or refining the final system. |
| BRAND-GAP-05 | REWORK | 4 | Favicon / small mark | `brandbook/assets/favicon.svg` uses a compact lower triangular fold at 32x32 | The fold may read as document corner, envelope, or send-arrow ambiguity at small sizes. | Phase 82 | Phase 82 records small-size visual review and final disposition for fold ambiguity. |
| BRAND-GAP-06 | TIGHTEN | 4 | SVG accessibility / safety | Draft SVGs use repeated `id="title"` and `id="desc"` with `aria-labelledby` | Standalone SVGs are valid, but repeated IDs collide if multiple assets are inlined in one document. | Phase 82 / Phase 84 | Phase 82 decides unique-ID or distribution strategy; Phase 84 validates IDs or documents non-inline usage. |
| BRAND-GAP-07 | REWORK | 4 | README / terminal snippet | `brandbook/examples/readme-header.svg:16-19` shows `mix archive.install hex phx_new` | Generic Phoenix setup weakens the Mailglass-specific developer story. | Phase 83 | Specimen/copy uses a real Mailglass flow such as `mix deps.get`, `mix mailglass.install`, or preview/send commands. |
| BRAND-GAP-08 | TIGHTEN | 3 | Tokens / callouts | `brandbook/tokens.json` has `state.info` on `callout.infoBackground`; research calculated 4.37:1 | Pair may be acceptable for non-text/border usage but should not be used for normal body text without guidance. | Phase 81 / Phase 84 | Token guidance distinguishes text from non-text uses; Phase 84 contrast checks encode allowed pairs. |
| BRAND-GAP-09 | TIGHTEN | 3 | UI states | `brandbook/examples/ui-primitives.svg` shows success/warning state examples with colored dots and labels | Accessibility requires state not be conveyed by color alone. | Phase 83 / Phase 84 | Specimens include text/icon/label cues and Phase 84 checks or documents non-color indicators. |
| BRAND-GAP-10 | TIGHTEN | 3 | Hex package hygiene | Root `mix.exs` and `mailglass_admin/mix.exs` package allowlists exclude broad `brandbook/` | Prevent accidental package bloat and unintended docs asset leakage. | Phase 84 | Executable package proof confirms broad `brandbook/` assets stay out of Hex tarballs by default. |
| BRAND-GAP-11 | ADD | 3 | Name risk | Phase 80 context records `Mailglass Lite` as a public naming/collision signal | This is a brand risk note, not legal clearance or rename work. | Future/deferred | Audit records the risk and deferral; legal/name strategy starts only for major launch collateral or legal review. |
| BRAND-GAP-12 | KEEP | 2 | Brand center | `brandbook/brand-book.md` and project context align on "Mailglass makes email visible" and "glass is a metaphor, not a visual excuse" | Preserve the strong existing strategy and avoid churn. | Phase 81-83 | Later source book, copy, and specimens cite this row when preserving the core concept. |

## Section 6 - Register Summary By Target

| Target | Rows | Minimum severity | Build requirement |
|---|---|---:|---|
| Phase 80 / Phase 84 closeout | BRAND-GAP-02, BRAND-GAP-03 | 4 | Keep the register and surface matrix stable so Phase 84 can close or defer rows without rewriting the audit. |
| Phase 81 | BRAND-GAP-01, BRAND-GAP-08, BRAND-GAP-12 | 2 | Source brandbook and token language remove overclaims, preserve the center, and clarify role/contrast guidance. |
| Phase 82 | BRAND-GAP-04, BRAND-GAP-05, BRAND-GAP-06 | 4 | Logo and SVG work compares options and resolves small-size, monochrome, reversed, ID, and distribution questions. |
| Phase 83 | BRAND-GAP-07, BRAND-GAP-09, BRAND-GAP-12 | 2 | Specimens and copy use real Mailglass flows, approved domain language, and non-color state cues. |
| Phase 84 | BRAND-GAP-06, BRAND-GAP-08, BRAND-GAP-09, BRAND-GAP-10 | 3 | Validation proves SVG safety, contrast policy, package allowlists, and repo hygiene. |
| Future/deferred | BRAND-GAP-11 | 3 | Name/legal work stays out unless a major launch or legal review justifies it. |

## Section 7 - Design Token Specification

Implemented in:

- `tokens.json`
- `tokens.css`

The token model is intentionally small:

- raw palette
- semantic color roles for light and dark
- state colors
- type scale
- spacing scale
- radius/border/focus
- code block/callout roles
- modest shadows only where useful

Do not expand into a full design-system framework unless a real surface needs it.

## Section 8 - Logo And Mark System

Recommended identity:

- Primary: wordmark + pane mark lockup
- Secondary: icon-only pane mark
- Monochrome: single-color pane mark
- No mascot
- No abstract mark without mail/pane meaning
- No logotype-only strategy, because favicon/social avatar need a mark

The SVGs are deliberately flat and simple. The mark suggests a pane with an
implied message fold. The wordmark uses live text with open-source font
fallbacks instead of embedded font outlines.

## Section 9 - Visual Examples And Screenshot Guidance

Create only specimens that help implementation:

- `examples/palette.svg` - verify palette and semantic roles.
- `examples/typography.svg` - verify type hierarchy.
- `examples/ui-primitives.svg` - buttons, cards, callouts, code, states.
- `examples/readme-header.svg` - README/social header framing.
- `examples/docs-page.svg` - docs layout direction.

Do not commit decorative fake product screenshots. Use screenshots only when a
real UI state, release artifact, or docs example needs proof.

## Section 10 - Brand Voice And Microcopy

Voice principles:

- concise
- exact
- technically literate
- calm under failure
- generous with recovery context

Tone sliders:

- slightly formal over casual
- human but technical
- quiet over loud
- serious with a light hand
- utility with taste

Use:

- compose
- render
- preview
- route
- deliver
- observe
- inspect
- suppress
- normalize
- verify
- stream
- mailbox
- timeline
- event
- headers
- provider
- adapter
- scenario

Avoid:

- supercharge
- next-gen
- effortless magic
- crush
- growth
- blast
- AI-powered everything

Ready copy:

- One-line project description: Mailglass is a Phoenix-native framework for composing, previewing, delivering, routing, and observing email.
- 140-character description: Email made visible for Phoenix apps: mailables, previews, delivery workflows, inbound routing, events, and operator clarity.
- GitHub repo description: Phoenix-native email infrastructure: compose, preview, deliver, route, and observe messages with clear production feedback.
- Hex.pm package description: A Phoenix-native transactional email framework with mailables, previews, delivery workflows, normalized events, and operator support.
- README opening paragraph: Mailglass brings structure and visibility to email in Elixir apps: typed mailables, component-based templates, previews, delivery workflows, inbound routing, normalized events, and operator-friendly feedback.
- Landing hero headline: Mailglass
- Landing hero subheadline: Email, made visible for Phoenix apps.
- Primary CTA: Read the docs
- Secondary CTA: View on GitHub
- Feature blurb 1: Preview real messages with realistic props before they ship.
- Feature blurb 2: Follow delivery, webhook, suppression, and replay events in one timeline.
- Feature blurb 3: Route inbound mail with application code instead of provider glue.
- Why this exists 1: Phoenix has mailer primitives; production apps need an email layer.
- Why this exists 2: Transactional email fails in operational ways, not just template ways.
- Why this exists 3: Teams should inspect message state before customers report it.
- Error: Delivery blocked: recipient is on the suppression list.
- Empty: No deliveries match this filter.
- Success: Preview rendered with realistic props.
- Release note: Mailglass now exposes a clearer operator overview and a tighter design-token path for future admin surfaces.

## Section 11 - Landing Page And Docs Blueprint

Landing page:

1. Hero: name, promise, install/docs CTA, restrained pane visual.
2. Problem: email becomes invisible after render/send.
3. Solution: compose, preview, deliver, observe, route.
4. Install snippet: shortest real install path.
5. Minimal example: one mailer or inbound route.
6. Core benefits: preview, event timeline, suppression, inbound, admin.
7. How it works: mailable -> message -> delivery -> event timeline.
8. Use cases: welcome flows, password resets, receipts, notifications, inbound workflows.
9. Why not just Swoosh: Swoosh sends; Mailglass adds framework-level visibility.
10. Docs/GitHub/contribution CTAs.

Docs/README:

1. Opening promise
2. Installation
3. Quickstart
4. Example
5. Concepts
6. API overview
7. Recipes
8. Troubleshooting
9. Design rationale
10. Contribution
11. License

## Section 12 - Repo-Ready Artifact Plan

Commit:

- `brandbook/index.html`
- `brandbook/brand-audit.md`
- `brandbook/brand-book.md`
- `brandbook/tokens.json`
- `brandbook/tokens.css`
- `brandbook/README.md`
- `brandbook/assets/*.svg`
- `brandbook/examples/*.svg`

Generate locally:

- PNG exports for package/social surfaces.
- Temporary browser screenshots.
- Contrast reports.

Do not commit by default:

- font binaries
- PDF exports
- Figma files
- large raster screenshot sets
- generated visual diff folders

## Section 13 - Prioritized Action Plan

Do now:

- Commit the `brandbook/` source artifacts.
- Use the HTML brandbook and tokens for future docs/landing work.
- Keep admin UI implementation aligned with the token semantics already shipped.

Do next:

- Use `readme-header.svg` when refreshing README presentation.
- Export PNG social cards only for actual launch/release use.
- Add a small contrast script only if repeated token changes begin.

Defer:

- Conference slide system.
- Physical sticker artwork.
- Full diagram component library.
- CI visual-regression for brand examples.

Do not do:

- Do not redesign the palette for novelty.
- Do not add a mascot.
- Do not add glassmorphism.
- Do not commit font binaries or screenshots without a real release need.
- Do not turn this into a second product UI framework.

## Section 14 - Final Quality Gate

- Could a designer build from this? Yes: concept, colors, type, logo, examples, and layout rules are concrete.
- Could an engineer implement from this? Yes: tokens JSON/CSS and SVG assets are committed.
- Could a maintainer keep it consistent? Yes: artifact policy and anti-traits are clear.
- Could a contributor understand it? Yes: the system is self-contained and low-jargon.
- Could it support marketing without becoming cheesy? Yes, if copy blocks and banned vocabulary are followed.
- Could it survive dark mode, small sizes, docs pages, and social previews? Yes, with the provided token and mark variants.
- Does it feel specific to this library? Yes: visibility, previews, timelines, headers, routing, and Phoenix-native email infrastructure.
- Does it avoid unnecessary brand thrash? Yes: it preserves the strong core and adds implementation scaffolding only.
