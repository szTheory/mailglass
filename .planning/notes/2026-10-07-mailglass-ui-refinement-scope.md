---
date: "2026-10-07"
promoted: false
---

# Mailglass operator, preview, and email UI refinement

Status: historical stocktake and adapted prompt, consumed by the approved v2.9 milestone on 2026-10-07. [SCOPE.md](../research/v2.9/SCOPE.md), [REQUIREMENTS.md](../REQUIREMENTS.md), and [ROADMAP.md](../ROADMAP.md) now own scope and phase decisions; the exploratory language below records the original input. Impeccable initialization is complete. No implementation or current visual verification is claimed.

Confirmed during init: engineers and support/on-call operators are equal primary Admin users, with technical detail available for investigation. The owner selected code-first; `.impeccable/config.json` owns that workflow setting. Root `PRODUCT.md` now records the product context. Live mode has a configured HEEx root-layout target and a completed static CSP check; no live session or runtime validation was performed.

## Intent

Bring Mailglass's existing operator workspace, developer preview, and recipient-facing output to a coherent, polished baseline that the owner can review after implementation. Make ordinary tasks obvious, investigation precise, and every surface feel deliberately designed. Automate routine verification and visual inspection, with bounded effort and optional owner feedback rather than repeated manual UAT.

Working title: **Operator, Preview & Email UI Refinement**. Set the milestone number and actual phase boundaries during milestone initialization.

## What the stocktake established

- Mailglass is a transactional email framework embedded in Phoenix applications. `mailglass_admin` supplies production operator and development preview surfaces; optional inbound functionality belongs to `mailglass_inbound`. Host applications own authentication, authorization policy, and mounting.
- Existing operator surfaces cover Email health/overview, Deliveries, and Inbound. Their components already include account selection, filters, quick views, timelines, support/suppression information, routing evidence, and replay confirmation. Preview includes mailable/scenario selection, editable assigns, HTML/Text/Raw/Headers, device framing, and theme controls. Gallery and dev Storybook provide component review surfaces.
- The established identity lives in `brandbook/`; admin implementation guidance lives in `mailglass_admin/docs/design-system.md`. Existing tokens, HEEx components, Tailwind/daisyUI, and LiveView interactions are the starting point. Documentation has historical assumptions: validate it against current source when touching a pattern.
- The current admin type tokens include 12px labels and 14px body text. Inspect actual readability, contrast, density, and zoom before deciding where to change them. A blanket size increase is not a substitute for hierarchy.
- There is substantial existing conformance, accessibility, LiveView, browser, mounted-asset, and fixture coverage. `mailglass_admin/docs/ui-baseline-scores.json` records June 2026 ratings, with all current cells at 4/4. Its ExUnit test checks the recorded scores and their progression; that does not establish the appearance or usability of today's rendered UI.
- Mailglass's v1.14 seed itself records that earlier UI milestones and checks had missed visible information-architecture problems. Those historical defects are not automatically current defects. Reuse the lesson and the existing inventories; reproduce problems before reopening work.
- Recipient-facing work has several implementations: public HEEx email components/layout, their theme resolver, the AtlasDesk demo's separate HTML helper, a brandbook example, and the built-in unsubscribe page. Polishing only AtlasDesk would not prove the public components improved.
- The built-in unsubscribe GET page currently announces an impending unsubscribe without rendering an action. Invalid/expired GET responses are minimal HTML; the protocol POST returns an empty response. Treat the browser journey as an explicit product/contract question during planning, preserving the existing protocol and host redirect semantics.

Evidence limits: this stocktake inspected source, documentation, planning records, and recent commits. The default demo URL at `http://127.0.0.1:4015` was unavailable; no current browser render, build, or test suite was run. The inspected UI implementation paths match the prior cleanup checkout. The main working directory still contains pre-existing local changes and stale remote-tracking state; begin execution by safely reconciling that workspace with the merged cleanup, preserving local work and recording the source actually served.

## Lessons to carry from the sibling projects

Scrypath's current v1.43 UI refinement is planned and ready for its first execution phase. Its useful lessons come from the existing UI and owner feedback; the new milestone's outcome is not yet proven. Accrue has a product record and a proposed UI brief, also without implementation evidence for that proposed work.

| Before / observed pattern | After / proposed Mailglass practice | Why |
| --- | --- | --- |
| Passing component checks alongside awkward overall workflows | Inspect real task sequences and before/after renders as part of each delivery slice | Hierarchy, redundancy, and confusing handoffs need direct review. |
| Repeated containers, competing controls, decorative status treatment in Scrypath feedback | Give each group a clear purpose; use restrained state cues and an obvious next action | Operators need to understand and act quickly. Reproduce any equivalent Mailglass defect before fixing it. |
| Shared token changes treated as isolated page tweaks | Settle representative shared patterns, then apply them across related workflows | Reduces inconsistent fixes and CSS override accumulation. |
| Large matrices and historical scores treated as quality verdicts | Reuse deterministic coverage and supplement it with bounded inspection of current output | Keeps useful automation while making the evidence honest. |
| Project-specific design choices carried between repos | Transfer workflow lessons; use Mailglass's product semantics and established identity | Accrue's billing audiences and Scrypath's search state model do not define Mailglass. |

Sources: Scrypath `.planning/reference/OPERATOR-UI-REFINEMENT.md`, `OPERATOR-UI-QUALITY.md`, `.planning/research/v1.43/SCOPE.md`, recent phase-173 commits; Accrue `PRODUCT.md` and `.planning/notes/2026-10-07-accrue-ui-refinement-scope.md`. Their comp-first/code-first decisions are not consent for a Mailglass workflow choice.

## Proposed coverage

Confirmed audience model: engineers and support/on-call operators are equal primary Admin users. Phoenix integrators/email authors and recipients have distinct preview/composition and message-reading needs. See root `PRODUCT.md` for the durable product record.

| Surface | User job and intended outcome |
| --- | --- |
| Shared shell, navigation, account selection, theme | Know where I am, which account is selected, and how to reach the task; retain relevant context through navigation and refresh. |
| Email health / overview | Understand scoped observations and reach affected work; make unknown/stale information distinguishable from a confirmed healthy state. |
| Deliveries | Find a delivery, inspect recipient/provider facts, distinguish dispatch from downstream delivery, understand failures/suppressions, and inspect events without losing list/filter context. |
| Replay and related operator feedback | Understand the exact stored target and consequence, perform an eligible action, and distinguish requested work, new work, no change, and failure. Keep replay and reconcile distinct; avoid implying that webhook replay resends an email. |
| Inbound | Find a received message, understand routing and execution history, inspect no-match/error evidence, and use supported replay with clear outcomes. |
| Developer preview | Find a Mailable/scenario, edit inputs, render, compare HTML and plaintext, and inspect technical output. Keep admin theme, frame theme, and actual email rendering behavior understandable. |
| Public email components and examples | Compose readable transactional messages with coherent type, spacing, links, buttons, preheaders, images, and plaintext output. Include common auth, receipt, failure, alert, and support scenarios where existing fixtures support them. |
| Built-in recipient web pages | Make unsubscribe copy, valid/invalid/expired states, and any supported next step understandable. Establish the intended browser journey before adding an action. |
| Demo, gallery, Storybook, relevant usage examples | Provide realistic review paths and examples of the actual shipped components. Keep examples and component states current. |

Embedded states are part of coverage: zero/one/many records, first setup, empty versus filtered-empty, invalid selections, render failures, missing optional inbound support, permissions, recent-auth requirements, disabled/busy actions, stale/disconnected observations, long subjects and identifiers, non-ASCII text, keyboard use, narrow screens, and reduced motion. The inventory must cover interactions as well as routes.

Email has a distinct rendering contract. Preserve supported inline styles, presentation tables, MSO/VML handling, plaintext extraction, escaping, URLs, and adopter theming. The current public document layout declares a light color scheme; a dark preview frame does not prove client dark-mode support. Keep the fictional AtlasDesk sender identity distinct from Mailglass's tool branding. Document which shared principles map to email-safe output instead of forcing browser CSS into email HTML.

Broad website/HexDocs redesign is not proposed by this stocktake. Update UI examples and documentation where implementation changes make them stale. New delivery capabilities, a template editor, a new auth product, or a framework replacement need a separate rationale.

## Adapted prompt for the future milestone

> Refine Mailglass's existing admin/operator UI, developer email preview, and applicable recipient-facing email components, templates, and built-in web pages into a polished, coherent baseline. Use Impeccable with the product context established during init, and use Emil Kowalski's skills for interaction quality and purposeful motion.
>
> Start from the current implementation and a runnable, deterministic demo. Inventory the surfaces, components, states, and end-to-end jobs; capture representative current renders. Reuse previous inventories and checks, verifying their relevance. Distinguish observed defects from improvement hypotheses and historical issues already fixed.
>
> Design around real jobs: preview a message before it ships; answer what happened to a delivery; explain a failure or suppression; inspect inbound routing; perform supported recovery and understand the result. Keep account, selection, filters, and relevant evidence intact between steps. Serve support/on-call users and technical investigators with clear common actions and accessible deeper detail.
>
> Aim for an idiomatic, calm, readable interface that follows the principle of least surprise. Choose lists, tables, timelines, detail views, forms, and disclosures because they fit the task. Give headings and groups a clear reading order. Avoid cramped columns, tiny essential text, excessive card nesting, redundant navigation, and controls hidden without a reason. Keep desktop investigation efficient and narrow-screen use complete and comfortable.
>
> Strengthen the existing design system. Use coherent typography, spacing, padding, color semantics, borders, radii, shadows, layers, iconography, and interaction states. Fix shared components and tokens where the problem is shared; remove superseded rules and temporary wrappers. Preserve Mailglass's identity while improving demonstrated weaknesses. Use a small number of relevant first-party UI references to inform specific decisions, and explain the pattern being borrowed.
>
> Make the microcopy direct, consistent, and useful. Maintain a concise glossary connecting user-facing labels to Mailable, Message, Delivery, Event, InboundMessage, Mailbox, and Suppression. “Account” may be the appropriate visible label for a tenant, while exact identifiers remain available for investigation. Explain action consequences and recovery paths. Keep factual distinctions intact: dispatch is not downstream delivery; accepted work is not completed work; unavailable evidence is not success; replay is not reconcile. Review existing locked wording explicitly where it obstructs clarity, preserving its semantic guarantees and updating the associated contract with any approved change.
>
> Complete each component's applicable focus, hover, pressed, selected, disabled, busy, validation, and error states. Exercise long and missing data, zero/one/many results, permissions, stale/disconnected states, and actual navigation. Ensure keyboard order, overlay stacking, focus containment/return, zoom, touch targets, and light/dark/System behavior work in the rendered UI. Status must remain understandable without color.
>
> Use motion only where it clarifies feedback or a state change. Frequent navigation and investigation must stay immediate. Prefer the existing LiveView/CSS implementation, with reduced-motion support and behavior that survives LiveView patches. Audit existing timeline staggering and repeated reveal effects as well as opportunities for better feedback. Apply Kowalski's judgment to Mailglass's stack; do not import React-specific libraries or decorative choreography by default.
>
> Include recipient-facing output as a deliberate workstream. Inspect public component output as well as demo templates; ensure examples demonstrate the library accurately. Improve subject/preheader/body/action hierarchy, reading width, responsive behavior, plain text, long content, and useful fallbacks. Preserve sender branding and rendering compatibility. Keep browser-preview evidence distinct from actual email-client evidence, and state any untested clients or dark-mode behavior honestly. Preserve unsubscribe protocol and host integration semantics while resolving the intended browser experience.
>
> Drive routine decisions and fixes autonomously using product evidence. Use focused expertise when a real uncertainty warrants it, consolidate findings, and avoid repeated broad review loops. Reuse existing tests and capture tools. Inspect representative desktop/mobile and theme renders together, fix the observed issues in one batch, then perform one confirmation round. Continue beyond that bound only for a concrete unresolved blocker, explaining the added work. Avoid recurring paid visual judges, new AI services, arbitrary aesthetic scores, and routine owner approval for individual fixes.
>
> Finish with a working preview, a concise before/after walkthrough, completed workflow/state coverage, updated shared-system documentation, focused regression proof, and green required CI through the existing PR process. Reconcile task-owned files and generated bundles; remove superseded styles and temporary artifacts. Document any preview intentionally retained for feedback. Make remaining limitations explicit. The owner can then review the coherent result and give optional feedback for another pass.

## Suggested sequence after init

These are candidate workstreams, not approved phases:

1. **Current baseline and shared direction.** Reconcile served source, reuse the demo fixtures, identify concrete defects, and settle representative shell/control/typography patterns. Build a compact flow/state inventory and a terminology map.
2. **Operator investigation and recovery.** Apply those patterns through overview, delivery investigation, inbound routing, and existing recovery flows. Treat context retention, truthful feedback, and accessibility as part of each slice.
3. **Preview and recipient output.** Complete scenario editing and inspection, then public email components, sample output, and the agreed unsubscribe browser journey. Include public components and AtlasDesk's separate renderer in the evidence.
4. **Consistency and delivery.** Consolidate patterns demonstrated in the preceding slices; update gallery/Storybook and relevant docs, finish scoped regression proof, and provide the feedback preview. Each earlier slice includes its own acceptance rather than postponing all review to this step.

The owner selected code-first during init; `.impeccable/config.json` is the authority for that default. Use current source and rendered comparisons, with a small visual comparison when a substantial structural choice remains unresolved.

## Verification and clean delivery

- Reuse `mailglass_admin/e2e/`, component/LiveView checks, token parity and conformance checks, and the reference demo's browser scenarios. Add focused coverage for demonstrated gaps rather than another parallel harness or blanket screenshot matrix.
- Record a small screenshot matrix tied to source, route, fixture, theme, and viewport. Inspect actual images; file existence and historical scores do not prove visual quality. Keep wider captures advisory and use existing CI lanes for reproducible behavior, layout, accessibility, and integration checks.
- Preserve substantive regression protection. When an assertion encodes a deliberately replaced presentation, update it with the implemented behavior and rationale. Do not manufacture new 4/4 scores or weaken an unrelated safety check to make a change pass.
- Keep admin asset regeneration with the source changes. Verify a fresh mounted entry and deep link use the intended assets; preserve custom mount paths and the adopter-facing prebuilt asset model.
- Use disposable data for mutating checks; preserve a feedback preview's state. Do not send real mail, change provider configuration, or reset unrelated sibling-project services for UI proof.
- Run rendering/HTML/plaintext checks for affected public email components and scenarios. Report browser capture coverage separately from client compatibility; commission paid client testing only if its need and cost are explicitly accepted later.
- PR delivery and package publication are distinct. This proposed milestone does not itself authorize a new merge or Hex release. Determine release scope from actual package changes during delivery.

## Handoff after Impeccable init

Use root `PRODUCT.md`, this note, `.planning/PROJECT.md`, `guides/jobs.md`, `brandbook/brand-book.md`, `mailglass_admin/docs/operator-trust.md`, and current source to avoid repeating discovery. Audience priority and the workflow default are settled. Resolve the intended unsubscribe browser journey and final recipient-output scope during milestone planning. Carry the owner's preferences for automation, conventional controls, coherent language, mobile usability, and bounded cost forward.

Product initialization is complete. Establish the design contract and formal requirements/roadmap next. Reconcile new design documentation with the existing brandbook and admin design-system reference so future agents know which source owns product facts, identity, and implemented patterns.

Installed guidance consulted: `/Users/jon/.agents/skills/impeccable/SKILL.md` (especially Operate mode and bounded verification), its init/shape references, and `/Users/jon/.agents/skills/emil-design-eng/SKILL.md`. The official [Kowalski skills repository](https://github.com/emilkowalski/skills) and [skill overview](https://emilkowal.ski/skill) were also inspected; the installed skill catalog includes `animate`, `review-animations`, `improve-animations`, and `find-animation-opportunities` for targeted later use.
