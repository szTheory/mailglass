# Phase 168: Shared Workspace and Usable Baseline - Context

**Gathered:** 2026-10-07 (assumptions mode)
**Status:** Ready for UI design contract and planning
**Confirmation:** Owner accepted the recommendation set: “follow ur rec above”.

<domain>
## Phase Boundary

Operators can use a coherent, readable shared workspace for real tasks, and maintainers can reproduce its baseline and improvements. Phase 168 owns UXF-01 through UXF-08: shell/navigation/Account context, typography and spacing, shared controls and copy, appearance preference, accessible interactions, and purposeful feedback.

Deliver these foundations on representative working screens. The inventory supports the usable result. Complete outbound, inbound, developer-preview, and recipient journeys retain their ownership in Phases 169–172; final consolidation and delivery evidence belong to Phase 173. Shared changes may affect those surfaces, but this phase does not absorb their full workflow redesigns.
</domain>

<decisions>
## Implementation Decisions

### Navigation and Account context

- **D-01:** Keep familiar section navigation and make the selected Account and its switcher visible in the shared operator context on desktop and narrow screens. Account scope must remain apparent when page filters are collapsed. Preserve meaningful active navigation and show destinations only when configured and available for the current mount.
- **D-02:** Present host-supplied Account names with stable scope underneath. Preserve `tenant_id` URL identity and the existing switching semantics: retain compatible filters and clear selections belonging to the previous Account. Moving the selector does not broaden authorization or make developer preview an account-scoped production surface.

### Reading hierarchy and domain language

- **D-03:** Establish comfortable shared typography and spacing for essential labels, headings, values, and supporting text. Adapt composition to available width and zoom; choose layout according to the task and content. The current 12px label and 14px body tokens are source observations to evaluate, not approved target sizes.
- **D-04:** Lead with clear names and essential facts. Keep exact identifiers and diagnostic values available in readable investigation detail without requiring hover. Truncation must have an accessible way to obtain the full value on touch and keyboard; summaries need not repeat raw IDs everywhere.
- **D-05:** Use coherent domain nouns, action labels, and specific recovery copy across shared patterns. Carry forward the equal engineer/support audience and the product distinctions between dispatch and delivery, requested and completed work, replay and resend. Exact technical evidence remains available where it helps the task.

### Appearance preference

- **D-06:** Carry forward one unambiguous Light, Dark, or System preference across Admin and preview chrome, navigation, and reload. System remains the selected preference when OS appearance changes; effective light/dark appearance must not silently replace that selection. Email content/device appearance remains a separate concern owned by the preview and recipient phases.

### Shared controls and feedback

- **D-07:** Consolidate applicable default, hover, focus, pressed, selected, disabled, busy, and validation states through existing shared components. Make status understandable beyond color and retain discoverable common actions with usable keyboard and touch targets.
- **D-08:** Establish consistent overlay behavior, including meaningful names, focus containment where required, dismissal, and return of focus. Inspect representative current Quick view and confirmation interactions before changing presentation. Preserve exact-target, action-time authorization, recent-auth, and confirmation semantics.
- **D-09:** Give prompt feedback with restrained, purposeful motion. Routine investigation and LiveView updates must not replay decorative entrances or block work. Honor reduced motion and keep essential status understandable without animation. Apply relevant Kowalski guidance within the existing stack.

### Reproducible baseline and acceptance

- **D-10:** Before UI edits, reconcile the preserved local workspace with the previously merged cleanup source, retaining unrelated work. Identify the checkout/revision and assets actually served by the preview. Build a compact before/after inventory naming route, fixture, theme, viewport, interaction state, and observed issue. Reuse deterministic demo/browser fixtures; source inspection and historical screenshots are not current rendered proof.
- **D-11:** Carry the milestone's bounded acceptance into this phase: representative desktop/mobile, light/dark/System, keyboard/touch, zoom, reduced motion, and applicable adverse/long-content states. Use existing focused checks and direct rendered inspection, with one batched review, corrective batch, and confirmation round per coherent slice; extend for a concrete unresolved blocker. Keep generated assets with their source and correct obsolete presentation assertions alongside their replacement behavior.

### Agent's Discretion

- The owner accepted the recommendations without corrections. Determine exact type sizes, spacing, breakpoints, Account placement within the shared frame, control composition, and motion values in the UI design contract, guided by working rendered screens.
- Reuse and consolidate existing components/tokens. Remove superseded rules when replacing them. Quick view styling kept outside the primary stylesheet to avoid a parity check is a consolidation candidate; the acceptance check should describe the intended behavior.
- Continue code-first with Impeccable in Operate mode, existing Mailglass branding, LiveView/HEEx, and the prebuilt asset model. Reuse existing research; perform targeted research only for a concrete unresolved implementation question.
- Routine reversible implementation choices follow the project's decisive research posture. Scope, public contracts, and user trust boundaries remain governed by the approved milestone.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** Paths are relative to the repository root.

- `PRODUCT.md` — audiences, product truth, brand, accessibility, and host ownership.
- `.planning/ROADMAP.md` — Phase 168 goal, five success criteria, and later-phase boundaries.
- `.planning/REQUIREMENTS.md` — exact UXF-01 through UXF-08 statements and traceability.
- `.planning/research/v2.9/SCOPE.md` — approved code-first direction, workspace reconciliation, bounded acceptance, and scope limits.
- `.planning/METHODOLOGY.md` — decisive research posture, recommendation-first synthesis, honest surface area, and compatibility ergonomics.
- `brandbook/brand-book.md` and `brandbook/copy/microcopy.md` — established identity and voice.
- `mailglass_admin/docs/design-system.md` — current shared patterns and token guidance; reconcile with source where changed.
- `mailglass_admin/docs/operator-trust.md` — router, host authorization, session, scope, and action contracts.
- `guides/jobs.md` and `guides/run-the-demo.md` — real user jobs and reproducible evaluation host.
- `.planning/notes/2026-10-07-mailglass-ui-refinement-scope.md` — source-backed stocktake and sibling-project lessons; historical input, not current verification.
- `.planning/milestones/v1.13-phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md` — prior theme preference decision; current approved v2.9 scope governs conflicts.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `mailglass_admin/lib/mailglass_admin/admin_shell.ex` provides the shared topbar, optional desktop sidebar, mobile navigation row, and content frame.
- `mailglass_admin/lib/mailglass_admin/surface_nav.ex` provides configured Health/Preview/Deliveries/Inbound destinations and active navigation.
- `mailglass_admin/lib/mailglass_admin/components.ex` provides shared controls, navigation, theme selection, and focus/selection patterns.
- `mailglass_admin/lib/mailglass_admin/operator/accounts.ex` maps human-readable Account labels to stable IDs; `operator/shell.ex` owns shared operator scope/switching behavior.
- `mailglass_admin/lib/mailglass_admin/theme.ex`, `controllers/theme_controller.ex`, and `layouts.ex` implement theme choice and persistence.
- `mailglass_admin/assets/css/app.css` owns the current type, spacing, theme, and motion rules. `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` also contains Quick view positional styling.

### Established Patterns

- Existing shell/navigation supports desktop sidebar and a narrow-screen navigation row. Refine these familiar patterns against real content rather than prescribing columns for every task.
- Account selection is currently part of filters in `mailglass_admin/lib/mailglass_admin/operator_live.ex` and `mailglass_admin/lib/mailglass_admin/inbound_live.ex`; those filters can collapse on mobile.
- Some truncated diagnostic values rely on `title` attributes in `mailglass_admin/lib/mailglass_admin/operator/shell.ex` and `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex`.
- Dialog/focus patterns exist in `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex` and `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex`. Their actual behavior requires rendered acceptance.
- Existing System preference uses a shared persisted choice and no explicit light/dark override; the theme CSS supplies system-dark behavior.

### Integration Points

- Shared components feed operator, inbound, and preview LiveViews; apply foundation changes in representative real consumers and account for effects on later-phase screens.
- Preserve custom mount paths, configured destinations, host access control, and the adopter asset-serving model through router/mount/layout integration.
- `reference/demo_app` and `mailglass_admin/e2e/operator.spec.js` provide existing evaluation fixtures. Record the chosen host/persona and served source rather than assuming those fixture sets are interchangeable.
- Gallery/Storybook and current component, LiveView, browser, token/conformance, and mounted-asset checks are reusable acceptance assets. Full milestone consolidation remains Phase 173.
</code_context>

<specifics>
## Specific Ideas

- The owner wants a strong baseline with minimal babysitting: idiomatic controls, readable text, deliberate hierarchy, coherent microcopy, responsive composition, and predictable interactions.
- Preserve the established brand and sender identity. Avoid a new visual identity exercise or unnecessary replacement of familiar components.
- Source analysis found a usable shared foundation. The next deliverable is a UI design contract that applies these decisions, followed by an implementation plan.
- Discussion performed source review only. No app boot, current browser capture, UI implementation, product test, email-client run, or current remote CI verification is claimed.
</specifics>

<deferred>
## Deferred Ideas

No new ideas were introduced during confirmation. No pending todos matched this phase.

Existing milestone boundaries remain: full outbound/inbound/preview/recipient slices belong to Phases 169–172; interactive browser unsubscribe submission, retention, native HEEx assigns changes, absence detection, and CI redesign remain deferred as recorded in the approved scope.
</deferred>
