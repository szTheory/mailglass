# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

- **Engineers and support/on-call operators are equal primary users of Mailglass Admin.** They investigate transactional email, explain failures or suppression, inspect inbound routing, and perform supported recovery. Routine tasks must be understandable without knowledge of internal modules, while precise identifiers and diagnostic evidence remain available to engineers.
- **Phoenix developers and email authors** integrate Mailglass, compose Mailables, preview scenarios, inspect rendered messages, and maintain the host application's email workflows.
- **Recipients of the host application's transactional messages** need to understand why a message arrived, read its content, and complete the intended action. Their needs and sender identity are distinct from those of an administrator using Mailglass.

## Product Purpose

Mailglass gives Phoenix applications a reusable framework for composing, previewing, sending, observing, and receiving transactional email. It builds on Swoosh and supplies the surrounding components, delivery records, normalized events, suppression handling, and operator interfaces that application teams would otherwise assemble themselves.

Success means an author can inspect a message before it ships, an operator can explain what is known about a delivery or received message and take an appropriate supported action, and a recipient can understand and use the resulting email. The outcome and any uncertainty should remain understandable afterward.

## Positioning

Mailglass is an open-source Elixir/Phoenix library integrated into a host application. Its distinguishing combination is HEEx-native email composition, a preview using the delivery renderer, provider event normalization, tenant-scoped records, and an append-only event ledger exposed through mountable operator interfaces.

Swoosh supplies the outbound transport abstraction. Providers supply delivery observations. Mailglass records and presents those facts without treating a local send attempt or an accepted command as proof of a downstream result. Marketing campaigns and multi-channel notifications are outside the product's established scope.

## Operating Context

- The repository contains `mailglass` for the core framework, `mailglass_admin` for development preview and production operator interfaces, and `mailglass_inbound` for receiving and routing email. The platform value describes the browser surfaces; the underlying product is an Elixir library.
- Host applications own their authentication, authorization policy, sessions, Repo, configuration, and route mounting. Admin access and sensitive action authorization are distinct checks. Mailglass does not supply a general login product.
- Developers define a **Mailable**, render a **Message**, and create a **Delivery** when sending. Provider observations become **Events**; policy records called **Suppressions** can block future sends. Received email is an **InboundMessage**, routed to a **Mailbox**.
- Operator work connects Email health, delivery investigation, suppression and webhook evidence, inbound routing history, and supported replay. Preserve relevant account, object, selection, and filter context between those tasks.
- Development preview offers mailable/scenario selection, editable inputs, HTML/Text/Raw/Headers inspection, device framing, and theme controls. It is mounted separately from the production operator surface.
- `reference/demo_app` is the local evaluation host. Its fictional AtlasDesk application and seeded Northstar Logistics account provide repeatable examples. The documented launcher is `make demo`, normally serving `http://localhost:4015`; preview is at `/dev/mail`, and the demo login leads to `/ops/mail` and `/ops/mail/inbound`. Mount paths and ports are configurable.

## Capabilities and Constraints

- Existing capabilities include email composition and rendering, background delivery, normalized provider events, suppression handling, signed unsubscribe links, multi-tenant routing, operator investigation, and optional inbound routing/replay. Availability depends on the host configuration and installed packages; do not imply unsupported provider parity or actions.
- **Dispatch and delivery are different facts.** A handoff to the provider does not establish that the recipient's mail server accepted the message. Use the recorded event evidence and retain uncertainty when it is absent, stale, or unavailable.
- **Replay and reconcile are distinct.** Operator replay resolves an exact stored target, stays tenant-scoped, checks action-time authorization, and records its outcome. It can produce new work, no change, or a failure. It is not a general resend-email action. Reconcile is background maintenance of unmatched webhook records.
- Preserve host authorization, session whitelisting, account scope, action eligibility, recent-auth requirements, and existing confirmation semantics. Make the affected object and action consequence understandable before execution. A successful action must not erase relevant failure history or imply unobserved downstream success.
- Use consistent domain terms across interfaces, documentation, and APIs. The UI may call a tenant an **Account**, including a host-supplied display name; the underlying `tenant_id` remains the scope and deep-link identity. Keep exact technical values accessible where they help investigation.
- The admin interface uses Phoenix LiveView/HEEx with existing shared components and prebuilt assets. Its stable router/auth/session semantics are documented in `mailglass_admin/docs/operator-trust.md`; internal DOM and CSS details are not the public compatibility contract. Preserve custom mount paths and the adopter-facing asset model.
- Email output has its own rendering constraints: inline styles, presentation tables, MSO/VML support, escaping, meaningful links/images, and plaintext extraction are part of the current implementation. Preserve adopter theming and the sender's identity. The AtlasDesk demo's separate HTML helper does not establish the behavior of the public email components.
- Browser preview evidence does not establish compatibility with every email client. Admin theme, preview frame appearance, and email-client dark-mode behavior are separate concerns. The current public email layout declares a light color scheme; broader compatibility claims require corresponding evidence.
- The built-in unsubscribe browser page, host redirect option, and protocol POST are separate parts of the existing integration. The approved v2.9 scope improves truthful, accessible GET and invalid/expired responses while preserving host redirects and protocol POST behavior. A new interactive browser submission/confirmation journey is deferred. Do not infer a new preference-management capability or alter protocol behavior from a visual refinement request.
- Refinement may correct demonstrated defects in existing supported workflows. New sending capabilities, provider support, a template editor, or new authorization policy require a separate product rationale.

## Brand Commitments

The product is **mailglass**, with the tagline **“Mail you can see through.”** The existing identity assets and brand reference live in `brandbook/`. The sealed-flap identity has a recorded maintainer decision; this product record does not replace that identity or establish a new visual system.

The established voice is clear, exact, confident, warm, and technical without being intimidating: a thoughtful maintainer. Use concrete domain nouns and actions, specific errors, and useful recovery guidance. Avoid hype, filler, cutesy failures, and implementation narration in ordinary operator tasks. Existing voice references include `brandbook/brand-book.md` and `brandbook/copy/microcopy.md`.

Mailglass's tool identity and a host application's sender identity have different roles. Recipient-facing examples should preserve the demonstrated sender's branding rather than imply every adopter sends Mailglass-branded email.

## Evidence on Hand

- `.planning/PROJECT.md`, `guides/jobs.md`, package READMEs, and the API/operator trust documents describe product and integration boundaries. Historical milestone summaries require comparison with current source before reuse as current facts.
- `reference/demo_app` supplies fictional transactional scenarios and seeded delivery, suppression, inbound, routing, and replay data. These are demonstrations, not testimonials or real customer evidence.
- Public email components live in `lib/mailglass/components.ex` and `lib/mailglass/components/`; demo templates live under `reference/demo_app/lib/mailglass_demo_web/mailers/`. The built-in unsubscribe page lives under `lib/mailglass/compliance/`.
- Admin gallery, dev Storybook, LiveView tests, browser flows, conformance and token checks, and deterministic preview capture already exist. Reuse their relevant coverage and inspect current rendered workflows. Historical aesthetic scores and screenshot manifests do not independently prove current visual quality.
- The pre-milestone stocktake is `.planning/notes/2026-10-07-mailglass-ui-refinement-scope.md`. It records proposed scope and evidence limits; it is not an implemented design or completed milestone. No current live UI review or email-client compatibility run was performed during initialization.

## Product Principles

1. **Make email understandable.** Connect the message or record, observed facts, appropriate next action, and resulting evidence.
2. **Fit the host application.** Preserve ownership of policy, account scope, integration, and sender identity.
3. **Serve routine work and deeper investigation together.** Make common actions discoverable and retain precise evidence without overwhelming the primary task.
4. **Reduce surprise and inconsistency.** Use familiar interactions, coherent domain language, and shared patterns that improve the whole experience.
5. **Earn confidence through visible results.** Use realistic scenarios, direct inspection, and bounded automated checks; let owner feedback refine a working baseline rather than substitute for routine verification.

## Accessibility & Inclusion

The existing admin accessibility target is WCAG AA, not a claim of fresh certification. Support keyboard navigation, assistive technology, touch, narrow viewports, and zoom. Maintain visible focus, meaningful names and labels, understandable validation and recovery, and status information that does not depend on color alone. Honor reduced-motion preferences and keep essential information available without hover or animation.

Recipient-facing messages need readable content, useful link text and image alternatives, and understandable plaintext output. Preserve long names, subjects, identifiers, and non-ASCII content without making essential information inaccessible.
