# Requirements: mailglass v2.9

**Milestone:** Operator, Preview & Email UI Refinement
**Defined:** 2026-10-07
**Status:** Approved 2026-10-07; implementation pending
**Core value:** Email you can see, audit, and trust before it ships.

## v2.9 Requirements

### Shared workspace and interaction

- [x] **UXF-01**: The maintainer can reproduce the current and refined primary workflows from a documented source, route, fixture, theme, and viewport, with a compact inventory of components/states and observed issues.
- [x] **UXF-02**: An operator can identify the current surface and selected account and navigate the existing workspace without losing the intended account scope or encountering misleading active navigation.
- [x] **UXF-03**: A user can read essential labels, values, headings, and supporting text with a coherent shared type/spacing hierarchy at supported narrow and desktop widths and at browser zoom.
- [x] **UXF-04**: A user can recognize and operate shared controls with consistent default, focus, hover, pressed, selected, disabled, busy, and validation states where applicable.
- [x] **UXF-05**: A user can choose Light, Dark, or System with one unambiguous selected preference and consistent appearance across navigation, reload, and OS changes while System is selected.
- [x] **UXF-06**: A user encounters consistent domain names, action labels, explanations, and recovery copy across the workspace, with exact technical detail available where it supports investigation.
- [x] **UXF-07**: A user can complete shared navigation and overlay interactions by keyboard or touch, with meaningful names, visible focus, correct focus containment/return, usable targets, and status cues beyond color.
- [x] **UXF-08**: A user receives prompt, understandable interaction feedback without repeated or blocking motion during routine investigation, including under reduced motion and LiveView updates.

### Outbound investigation and recovery

- [x] **OUTUX-01**: An operator can understand scoped Email health observations and reach the relevant affected work while distinguishing absent, stale, or unavailable evidence from a confirmed healthy outcome.
- [x] **OUTUX-02**: An operator can find/filter/select a delivery, inspect it, and return to the list with relevant account and filter context preserved, including empty, filtered-empty, and invalid-selection states.
- [x] **OUTUX-03**: An operator can read a delivery's recorded provider/events timeline, identifiers, and exact times and distinguish dispatch from downstream delivery without relying on color or ambiguous status labels.
- [x] **OUTUX-04**: An operator can understand existing suppression and webhook-failure/unmatched evidence, its relationship to the selected delivery, and the supported next investigation step without implying an unavailable repair action.
- [x] **OUTUX-05**: An authorized operator can review one exact eligible stored replay target, confirm its consequence, and understand requested/new-work/no-change/failure outcomes while preserving action-time authorization and account scope.

### Inbound investigation and recovery

- [ ] **INUX-01**: An operator can find and inspect an inbound record and return to the same account/filter context, including no records, no filter matches, and unavailable selections.
- [ ] **INUX-02**: An operator can follow an inbound record's routing and execution evidence and distinguish a matched mailbox, no match, failed execution, and missing history without invented certainty.
- [ ] **INUX-03**: An authorized operator can inspect available inbound evidence through readable progressive disclosure while preserving existing redaction and reveal permissions.
- [x] **INUX-04**: An operator can understand replay eligibility and perform a permitted inbound replay with clear confirmation and truthful outcomes, including disabled, denied, busy, no-change, and failure states.

### Developer preview

- [ ] **PRVUX-01**: An author can find a Mailable/scenario and retain a clear sense of the selected preview, including narrow layouts and the no-Mailables/setup state.
- [ ] **PRVUX-02**: An author can edit scenario inputs, render through the supported pipeline, and recover from validation/render failures without losing useful input or mistaking stale output for the new result.
- [ ] **PRVUX-03**: An author can inspect HTML, plaintext, raw output, and headers with readable long content and clear tab/selection behavior while preserving the same supported rendering semantics used for delivery.
- [ ] **PRVUX-04**: An author can change device framing and preview appearance independently of admin appearance and understand the limits of what those controls demonstrate about actual email clients.

### Recipient output and built-in pages

- [ ] **MAILUX-01**: An author using the public email components can produce readable transactional messages with coherent heading/body/action hierarchy and usable long-content, narrow-width, link, and image-fallback behavior while preserving email-specific markup support.
- [ ] **MAILUX-02**: An evaluator can review representative existing transactional scenarios with consistent sender branding and explicit coverage of both the public components and AtlasDesk's separate renderer; examples accurately demonstrate supported authoring paths.
- [ ] **MAILUX-03**: A recipient can understand the message and its essential action from plaintext output as well as HTML, with meaningful links and content preserved through the renderer.
- [ ] **MAILUX-04**: A recipient visiting the built-in unsubscribe GET page or an invalid/expired link sees readable, accessible, truthful state and next-step copy; configured host redirects and the existing protocol POST contract remain intact, with no unsupported confirmation or completion claim.

### Consistency, evidence, and delivery

- [ ] **UIQ-01**: A maintainer can find the delivered shared patterns and applicable states in the existing gallery/Storybook and current design-system documentation, with clear ownership of tokens and no obsolete implementation left competing with the new patterns.
- [ ] **UIQ-02**: A maintainer can reproduce focused automated checks and inspect source-identified before/after renders covering the changed primary flows and relevant adverse states, with email-client and other evidence limits stated explicitly.
- [ ] **UIQ-03**: The owner can review the completed milestone in a documented working preview, with required CI passing on the delivery candidate, task-owned changes committed, generated assets current, and temporary artifacts/services disposed of or explicitly retained for feedback.

## Acceptance applying to every delivery slice

Apply the shared accessibility, responsive, copy, state, and motion requirements whenever that slice changes a pattern. Each requirement has one owning phase; later phases demonstrate that their workflows preserve the shared contract. Follow the bounded inspection/check strategy in [SCOPE.md](research/v2.9/SCOPE.md). No requirement is complete merely because an artifact exists or a historical rating is unchanged.

## Future requirements

Sent-message retention (SEED-004), native assigns/rendering API changes (SEED-005), and proactive delivery-absence/provider-preflight detection (SEED-008) remain separate future capability work. An interactive built-in browser unsubscribe submission/confirmation journey remains deferred pending a compatibility-aware product decision.

## Out of scope

| Item | Reason |
| --- | --- |
| New delivery/provider features, notification channels, preference center, template editor | Expands product semantics beyond existing-journey refinement. |
| Framework replacement or speculative component-library dependency | Existing LiveView/HEEx components support this work. |
| Broad website/HexDocs redesign | Update affected UI examples and guidance; keep the milestone focused. |
| New required AI judge, recurring paid visual service, inflated aesthetic scores | Use bounded direct visual inspection and existing deterministic checks. |
| CI architecture/speed campaign or historical archive rewrite | Address only a concrete blocker to delivering the scoped work. |
| Automatic Hex version bump or publication | Determine package release scope from actual changes through the release workflow. |

## Traceability

The approved [roadmap](ROADMAP.md) assigns each of the 28 v2.9 requirements to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| UXF-01 | Phase 168 | Complete |
| UXF-02 | Phase 168 | Complete |
| UXF-03 | Phase 168 | Complete |
| UXF-04 | Phase 168 | Complete |
| UXF-05 | Phase 168 | Complete |
| UXF-06 | Phase 168 | Complete |
| UXF-07 | Phase 168 | Complete |
| UXF-08 | Phase 168 | Complete |
| OUTUX-01 | Phase 169 | Complete |
| OUTUX-02 | Phase 169 | Complete |
| OUTUX-03 | Phase 169 | Complete |
| OUTUX-04 | Phase 169 | Complete |
| OUTUX-05 | Phase 169 | Complete |
| INUX-01 | Phase 170 | Pending |
| INUX-02 | Phase 170 | Pending |
| INUX-03 | Phase 170 | Pending |
| INUX-04 | Phase 170 | Complete |
| PRVUX-01 | Phase 171 | Pending |
| PRVUX-02 | Phase 171 | Pending |
| PRVUX-03 | Phase 171 | Pending |
| PRVUX-04 | Phase 171 | Pending |
| MAILUX-01 | Phase 172 | Pending |
| MAILUX-02 | Phase 172 | Pending |
| MAILUX-03 | Phase 172 | Pending |
| MAILUX-04 | Phase 172 | Pending |
| UIQ-01 | Phase 173 | Pending |
| UIQ-02 | Phase 173 | Pending |
| UIQ-03 | Phase 173 | Pending |

**Coverage:** 28/28 mapped; no duplicate or orphaned requirement IDs.

---
*Last updated: 2026-10-07 after Phase 168 verification; UXF-01–08 complete.*
