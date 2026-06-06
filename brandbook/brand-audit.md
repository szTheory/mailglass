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

## Section 4 - Stress Tests

| Surface | Enough guidance? | Needed addition |
|---|---|---|
| GitHub repo header | Mostly | Primary lockup, one-line description, social avatar. |
| README hero section | Mostly | README header specimen and restrained CTA pattern. |
| README badges | Partial | Use monochrome/Ink badges with sparse Glass accent. |
| Hex.pm package page | Partial | Short and long package blurbs. |
| HexDocs page | Partial | Docs intro and code/callout tokens. |
| Docs sidebar | Partial | Active/hover/focus token roles. |
| Code block styling | Partial | Code block token group. |
| Terminal snippet | Partial | Terminal copy and color guidance. |
| API reference page | Yes | Keep examples before slogans. |
| Landing page hero | Partial | Hero architecture and copy blocks. |
| Feature section | Partial | Feature blurbs tied to real technical value. |
| Comparison section | Partial | "Why not just Swoosh?" framing without dunking. |
| Blog post header | Partial | Social/blog specimen and headline style. |
| Release announcement | Partial | Release-note style and example. |
| Social preview card | No | SVG social framing added. |
| Favicon | No | Simple mark added. |
| App icon | No | Mark can scale, but do not over-polish into SaaS icon. |
| Small monochrome logo | No | Monochrome SVG added. |
| Dark-mode page | Partial | Dark semantic tokens added. |
| Light-mode page | Yes | Palette already supports it. |
| Conference slide | Partial | Use large wordmark + pane diagram, no gradient hero. |
| Diagram/architecture illustration | Partial | Diagram style rules added. |
| Error/empty/success states | Partial | Microcopy and semantic state tokens added. |
| Example UI component library | Partial | Specimen covers primitives, not full component system. |
| Mobile landing page | Partial | HTML must be responsive and text must not overlap. |
| Printed sticker/swag | Nice-to-have | Monochrome mark only; defer physical artwork. |

## Section 5 - Gaps And Risks

Critical:

- No source-controlled brand artifacts existed outside prompt history.
- No committed logo system existed.
- No semantic token file existed for non-admin surfaces.

Important:

- Marketing copy needed ready-to-use technical phrasing.
- The logo direction needed scale and monochrome constraints.
- Palette needed explicit dark/light roles beyond raw colors.
- Repo artifact policy needed to prevent binary bloat.

Nice-to-have:

- PNG exports for social cards.
- Conference slide template.
- Additional diagram library.
- Automated contrast report.

## Section 6 - Recommended Brand Book Upgrades

Keep:

- Mailglass makes email visible.
- The clear email framework for Phoenix.
- The Ink/Glass/Ice/Mist/Paper/Slate palette.
- Inter, Inter Tight, IBM Plex Mono.
- Thoughtful-maintainer voice.
- "Glass is a metaphor, not a visual excuse."

Tighten:

- Define semantic token roles, not only raw colors.
- Add component-state guidance.
- Add concrete logo usage rules.
- Add ready-to-use copy blocks.

Rework:

- Any future use of heavy glass effects.
- Any logo that reads as a paper plane or generic envelope.
- Any marketing line that could belong to an ESP or outbound sales tool.

Add:

- Static HTML brandbook.
- Token JSON/CSS.
- SVG logo set.
- SVG specimens.
- Repo artifact policy.
- QA checklist.

Remove:

- Prompt artifacts from the canonical use path. Preserve them historically, but
  do not make future maintainers mine prompts for production guidance.

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
