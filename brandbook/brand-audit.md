# Mailglass Brand Pressure Test

Date: 2026-06-05

Sources reviewed:

- Existing Mailglass brand book in `prompts/`
- Project positioning and planning context in `.planning/`
- Implemented admin design-system guidance
- Current README/package-family posture

## Section 1 - Executive Judgment

The current brand book is strong enough to build from. It has a real conceptual
center: **Mailglass makes email visible**. That center is specific to the
product, easy to remember, and useful for both visual and UX decisions.

It is distinct enough from common email/devtool tropes because it avoids paper
planes, delivery-company metaphors, outbound-sales language, mascot energy,
purple gradients, fake futurism, and generic "powerful/simple" positioning.

It was not fully implementation-ready. The prompt-era brand book named good raw
colors, voice, and visual instincts, but it lacked repo-ready tokens, component
state roles, concrete SVG assets, artifact policy, and enough ready-to-use copy
for README, Hex.pm, landing pages, and social previews.

It is slightly under-specified for buildout, but not strategically weak.

Highest-leverage improvement: convert the strong strategy into a small
source-controlled system: HTML brandbook, audit, semantic tokens, logo SVGs,
specimens, and copy blocks.

Do not change the core idea, palette direction, restrained tone, Inter/Inter
Tight/IBM Plex Mono stack, or "glass is a metaphor, not a visual excuse."

## Section 2 - Brand DNA Extraction

- Brand essence: mail you can see through
- Audience: senior Phoenix and Elixir teams building production transactional email
- Emotional tone: calm, clear, technical, composed
- Technical promise: email becomes inspectable application infrastructure
- Visual metaphor: clarity through panes
- Personality traits: precise, warm, confident, quiet, useful, maintainer-like
- Anti-traits: flashy, salesy, cute, glossy, vague, mascot-driven, corporate
- Design principles: flat panes, readable hierarchy, limited Glass accent, semantic state color, no ornament for its own sake
- Voice principles: explain plainly, recover helpfully, avoid hype, use exact domain nouns

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

## Section 3 - Pressure-Test Scorecard

| Dimension | Score | Why | Risk | Recommended fix |
|---|---:|---|---|---|
| Distinctiveness | 8 | "Email made visible" is memorable and ownable in this category. | Pane/glass metaphor could become generic if overused. | Keep glass conceptual, not decorative. |
| Developer credibility | 9 | Maintainer voice and low-hype language fit OSS. | Marketing pages could still drift into SaaS tone. | Use approved copy blocks and banned vocabulary. |
| Elixir ecosystem fit | 9 | Understated, technical, Phoenix-native. | Too much launch collateral could feel commercial. | Keep docs/examples before slogans. |
| Visual coherence | 8 | Palette and metaphor are coherent. | Prompt had few concrete layout/component constraints. | Token and specimen files now fill this. |
| Logo readiness | 6 -> 8 | Direction was good, but no assets existed. | Mark could look like a generic envelope. | Use pane-first mark with implied fold only. |
| Color-system readiness | 6 -> 8 | Raw palette existed and admin mapped it. | Missing semantic roles for marketing/docs. | Commit `tokens.json` and `tokens.css`. |
| Typography readiness | 8 | Practical OSS-safe type choices. | Font binaries should not be committed. | Recommend stacks only; use fallbacks. |
| Design-token readiness | 5 -> 8 | Admin had product tokens; brand book did not. | Divergence between product UI and marketing. | Align brand tokens with admin semantics. |
| UI component readiness | 5 -> 7 | General component direction existed. | Not enough state/component examples. | Add specimens and component rules. |
| Docs/README usefulness | 7 -> 8 | Messaging is strong. | Needed ready-to-use blocks. | Add copy library. |
| Marketing usefulness | 6 -> 8 | Strong promise, light on page architecture. | Could under-sell value. | Add landing/docs blueprint. |
| Voice/microcopy usefulness | 7 -> 8 | Good "say/not" examples. | Needed more state-specific examples. | Add UX microcopy patterns. |
| Accessibility | 6 -> 8 | WCAG intent was present. | Need explicit semantic states and contrast checks. | Token roles and QA checklist. |
| Repo readiness | 4 -> 9 | Prompt file was not a build artifact. | Random future assets could bloat repo. | Self-contained `brandbook/` and export policy. |
| Maintainability | 8 | Small, restrained system. | Could grow into a design-system side quest. | Keep artifacts lean; do not add binary packs. |

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
