# Phase 172: Recipient Output and Built-in Pages - Context

**Gathered:** 2026-10-09 (assumptions mode)
**Status:** Ready for UI design contract and planning
**Direction:** The owner asked for a broad, evidence-based synthesis and authorized following the resulting recommendations without routine confirmation.

<domain>
## Phase Boundary

Improve readable output through Mailglass's public transactional email components, demonstrate that authoring path separately from the AtlasDesk HTML renderer, retain essential meaning and links in generated plaintext, and make the built-in unsubscribe GET and invalid/expired pages truthful, accessible, and useful. Preserve configured redirects and the existing unsubscribe POST contract. Phase 172 owns MAILUX-01 through MAILUX-04.

This phase does not add an unsubscribe browser form, preference center, mail-client emulator, provider/MIME serialization, new public rendering API, new dependency, or a claim that generated markup has been verified in all recipient clients.
</domain>

<decisions>
## Implementation Decisions

### Public component output and email-client constraints
- **D-01:** Improve heading, body, action, link, image fallback, narrow-width, and long-content behavior within the existing `Mailglass.Components` API and adopter theme contract. Keep important copy as ordinary live HTML text; keep descriptive link text and meaningful image alternatives. Make layouts fluid with email-safe table/width fallbacks and inline styles, and avoid fixed-height treatments around variable content.
- **D-02:** Preserve HEEx escaping, existing inline style and CSS-inliner behavior, presentation-table semantics, and the existing surgical MSO/VML paths and HTML fallbacks. Do not add a dependency or replace the current component/rendering architecture. Treat successful component rendering and markup preservation as evidence about Mailglass output, not a certification of Gmail, Outlook, or other recipient-client behavior.

### Representative examples and sender identity
- **D-03:** Keep AtlasDesk's bespoke HTML renderer explicit and intact. Add a named, inspectable reference-demo scenario that uses the public `Mailglass.Components` path, with the same sender identity and visual language as representative AtlasDesk scenarios. The examples must make their authoring path clear; do not convert every existing scenario or make the public-component example merely a static guide snippet.
- **D-04:** Update the relevant guides/example copy to show supported Mailable and component usage accurately. Use the existing brandbook's calm, exact voice and current brand tokens; the current `brandbook/brand-book.md` supersedes older prompt drafts.

### Plaintext meaning and links
- **D-05:** Keep `Mailglass.Renderer`'s generated-plaintext pipeline as the current supported behavior. Fix extraction so meaningful anchor URLs survive when links are nested inside text content or appear as ordinary unmarked anchors, while button/link components retain their existing useful label-and-URL meaning without duplicate URLs. Preserve readable order, paragraphs, headings, non-ASCII content, and essential action context.
- **D-06:** Do not silently change whether caller-supplied `text_body` is replaced by generated plaintext in this phase; the current renderer documentation and implementation define generated plaintext as the renderer output. If a public explicit-text contract is found during planning, treat it as a compatibility question to resolve before implementation rather than changing it incidentally.

### Built-in unsubscribe GET and recovery pages
- **D-07:** Valid GET remains informational and does not mutate subscription state or claim completion. Do not add a browser submission form or preference UI. Give recipients a clear next step within the supported product boundary: use their mail app's unsubscribe control when available, or contact the sender through the contact details in the message.
- **D-08:** Keep invalid and expired GET states distinguishable with their existing 404 and 410 responses. Replace the minimal, raw failure bodies with accessible, escaped HTML and concise recovery guidance that does not expose recipient data. Keep configured redirect behavior and POST response, event, and idempotency semantics unchanged.
- **D-09:** Use the existing lightweight HEEx/Phoenix rendering path and Mailglass brand voice/tokens for the built-in pages. Use semantic document structure, readable narrow layouts, sufficient contrast, and explicit state text; add no frontend framework or extra dependency.

### Shift-left acceptance and evidence boundaries
- **D-10:** Automate machine-observable component structure, escaping, plaintext links/content, example-path distinction, unsubscribe copy/status/redirect behavior, and preservation of POST semantics using existing ExUnit and browser/capture tooling. Run the existing focused regression gate and relevant checks; do not add a test framework or promote an advisory lane to required CI. Passing automation closes machine-observable acceptance without owner UAT.
- **D-11:** Keep evidence claims bounded. Automated HTML and browser renders can establish renderer/page behavior and responsive structure; they do not prove delivered-message rendering in Gmail/Outlook or image-enabled/disabled behavior across clients. Do not require manual inbox-client review or claim it occurred as part of this phase.

### the agent's Discretion
- Choose exact component spacing, type scale, inline styles, and short page copy within the current brandbook, semantic theme, and existing component contracts.
- Choose a representative public-component Mailable and fixture values that demonstrate narrow, long, non-ASCII, image-alt, and meaningful-link behavior while keeping AtlasDesk's separate renderer visible.
- Choose the smallest sufficient test additions and browser captures in existing lanes; keep responsive cases representative rather than multiplying a full theme/client/viewport matrix.

### Folded Todos
None. Phase 172 had no matching pending todos.
</decisions>

<specifics>
## Specific Ideas

- A dedicated named public-component scenario alongside unchanged AtlasDesk-rendered scenarios makes the distinction inspectable and preserves both authoring paths for evaluators.
- For generated plaintext, represent actionable anchors with readable label plus destination, including nested and unmarked links; keep the CTA's meaning understandable even when styles and images are absent.
- For the valid unsubscribe GET, say plainly that visiting the page did not unsubscribe the recipient. Offer only a next step that is available without adding new browser actions. Invalid/expired pages should explain how to recover without echoing tokens or recipient data.
- Email compatibility research: [Google's Gmail CSS support](https://developers.google.com/workspace/gmail/design/css) documents supported properties and media queries but also states unsupported CSS may be ignored. Microsoft's [email rendering guidance](https://learn.microsoft.com/en-us/troubleshoot/dynamics-365/customer-insights/journeys/email/email-troubleshoot-rendering) describes Classic Outlook's Word-based renderer, spacing limitations, mobile table reflow issues, and VML caveats. Use table width fallbacks and inline styles, keep essential content in ordinary HTML, and avoid fixed-height VML around dynamic text.
- Accessibility guidance: W3C [presentation-role guidance](https://www.w3.org/WAI/ARIA/apg/practices/hiding-semantics/), [link-purpose technique](https://www.w3.org/WAI/WCAG21/Techniques/html/H30.html), and [images tutorial](https://www.w3.org/WAI/tutorials/images/) support presentation semantics for layout tables, descriptive link purpose, and meaningful alternatives for informative or linked images.
- Secondary compatibility matrices at [Can I Email: max-width](https://www.caniemail.com/features/css-max-width/), [word-wrap](https://www.caniemail.com/features/css-word-wrap/), and [HTML table](https://www.caniemail.com/features/html-table/) are useful test evidence but include older, non-market-share-weighted client samples; they are not a guarantee for current recipients.
</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** Paths are relative to the repository root.

### Product boundary and acceptance
- `PRODUCT.md` — durable product truth, audiences, and package boundaries.
- `.planning/PROJECT.md` — active milestone goals, product principles, and D-52 automation preference.
- `.planning/ROADMAP.md` §Phase 172 — fixed phase boundary, success criteria, and acceptance focus.
- `.planning/REQUIREMENTS.md` — MAILUX-01 through MAILUX-04.
- `.planning/research/v2.9/SCOPE.md` — approved v2.9 scope and deferred work.
- `.planning/METHODOLOGY.md` — recommendation-first synthesis, dependency restraint, and shift-left verification.

### Inherited design and voice
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-CONTEXT.md` — inherited interaction, accessibility, and design decisions.
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md` — typography, semantic color, spacing, responsive, and accessibility contract.
- `.planning/phases/171-developer-preview/171-CONTEXT.md` — recent implementation boundaries and automated-evidence posture.
- `brandbook/brand-book.md` — current Mailglass identity, tokens, and voice; supersedes older prompt drafts.
- `brandbook/copy/microcopy.md` and `brandbook/tokens.css` — canonical copy and rendered color tokens.

### Public components, renderer, and examples
- `lib/mailglass/components.ex` — public email components, markup, VML, and plaintext strategies.
- `lib/mailglass/components/theme.ex` and `lib/mailglass/components/css.ex` — adopter theme and inline style helpers.
- `lib/mailglass/renderer.ex` — HTML processing, generated plaintext, CSS inlining, and output semantics.
- `lib/mailglass/mailable.ex` — supported Mailable contract.
- `guides/components.md` and `guides/authoring-mailables.md` — public authoring and rendering guidance.
- `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex`, `billing_mailer.ex`, and `operations_mailer.ex` — representative named transactional examples.
- `reference/demo_app/lib/mailglass_demo_web/mailers/atlas_desk_email.ex` — AtlasDesk's separate HTML-rendering path.

### Unsubscribe and automated evidence
- `lib/mailglass/compliance/unsubscribe_controller.ex` — token lookup, GET/redirect/failure and POST contract.
- `lib/mailglass/compliance/unsubscribe_html.ex` and `lib/mailglass/compliance/unsubscribe_html/confirm.html.heex` — current embedded page template.
- `guides/unsubscribe.md` — adopter-facing unsubscribe semantics.
- `test/mailglass/components/button_test.exs`, `test/mailglass/components/row_test.exs`, and `test/mailglass/components/vml_preservation_test.exs` — existing component/VML checks.
- `test/mailglass/renderer_test.exs` — existing renderer and plaintext behavior.
- `test/mailglass/compliance/unsubscribe_controller_test.exs` — GET statuses, configured redirect, POST behavior, and idempotency.
- `.github/workflows/ci.yml` and `scripts/gsd-regression-gate.sh` — current required/advisory CI topology and focused regression gate.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Components` already provides HEEx layout/content components, adopter-aware theme resolution, email-specific table structure, inline styles, and surgical MSO/VML button and row/column fallbacks.
- `Mailglass.Renderer` already generates plaintext from pre-inlined HTML, applies CSS inlining, and removes internal `data-mg-*` markers; existing renderer tests cover strategy markers and output normalization.
- AtlasDesk's named Mailables and `atlas_desk_email.ex` provide an existing bespoke-renderer example that can remain side-by-side with one public-component Mailable.
- The unsubscribe controller already separates GET from POST, verifies tokens, supports a configured redirect escape hatch, and preserves idempotent POST semantics; HEEx template embedding is already configured.
- Existing ExUnit suites, browser capture support, and the focused regression gate can cover this phase without a new test framework or dependency.

### Established Patterns
- Public authoring uses HEEx components; themes resolve through Mailglass tokens; email compatibility is encoded in table markup, inline styles, VML conditional blocks, and explicit fallbacks.
- The renderer derives plaintext before CSS inlining. Current `text` extraction can flatten a nested anchor to its label, and an unmarked anchor may omit its URL; link handling must avoid losing or duplicating destinations.
- AtlasDesk scenarios currently use a separate HTML helper, so those examples must be identified accurately rather than represented as public-component output.
- Unsubscribe GET verifies and reads state; POST performs the mutation. The page must retain that distinction, and host redirects remain adopter-controlled.
- Mailglass's current brandbook and the accepted Phase 168 UI contract govern visual decisions. Keep product-specific claims restrained and use no additional dependencies by default.

### Integration Points
- Component changes feed `Mailglass.Renderer`, which also serves the outbound content-rendering stage; preserve sanitizer/escaping, inliner, VML, and plaintext contracts.
- The public-component example belongs in the reference demo Mailable/scenario path; AtlasDesk's separate renderer remains an explicitly labeled comparison.
- GET failure templates connect controller status handling to accessible browser pages; valid GET and configured redirects must remain separate from the unchanged protocol POST flow.
- CI should extend existing test/capture surfaces and accurately retain current required-versus-advisory lane boundaries.

</code_context>

<deferred>
## Deferred Ideas

- Delivered inbox verification across Gmail, Outlook, Apple Mail, image-loading states, and dark-mode variants; this requires separate client-specific evidence and is not covered by generated HTML or browser previews.
- Interactive browser unsubscribe confirmation, a preference center, or any additional unsubscribe state transition.
- Provider/MIME serialization, send-to-self, or broader outbound pipeline changes.
- New email-rendering libraries, frontend frameworks, test frameworks, or additional required CI lanes.

</deferred>

---

*Phase: 172-recipient-output-and-built-in-pages*
*Context gathered: 2026-10-09*
