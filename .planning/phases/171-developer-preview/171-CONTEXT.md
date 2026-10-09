# Phase 171: Developer Preview - Context

**Gathered:** 2026-10-09 (assumptions and recommendation synthesis)
**Status:** Ready for UI design contract and planning
**Direction:** The owner asked for a broad, evidence-based synthesis and said to follow the resulting recommendations.

<domain>
## Phase Boundary

Improve Mailglass's existing developer preview so email authors can find a Mailable and named scenario, edit supported inputs, and inspect truthful HTML, plaintext, raw-preview, and header representations. Preserve the existing Mailable/scenario and rendering contracts. Phase 171 owns PRVUX-01 through PRVUX-04.

This phase does not add a template editor, new public preview API, outbound send action, provider/MIME serialization, production preview authorization, account-scoped preview, email-client emulator, or new dependency. A browser rendering is evidence about this preview pipeline, not proof of email-client or dark-mode compatibility.
</domain>

<decisions>
## Implementation Decisions

### Scenario discovery and author orientation
- **D-01:** Keep the existing Mailglass.Mailable and optional preview_props/0 contract. Discovery exposes ordered named scenarios with default assigns; the selected scenario invokes the existing Mailable function. Preserve auto-discovery, explicit Mailable lists, custom mount paths, and safe resolution against discovered modules/scenarios. Do not add a separate scenario registry or public API.
- **D-02:** Keep the compact picker and make the selected Mailable and scenario legible at narrow widths. Reuse the current mobile disclosure rather than adding a second sidebar. Preserve two distinct setup states: no Mailables discovered (generator and discovery guidance) and Mailables present but no preview scenarios (how to add a scenario). Use the current brandbook's plain copy and proper code markup. Correct guides/preview.md so its preview_props example matches the supported named-scenario-to-assigns-map shape.
- **D-03:** Use Mailable, preview scenario, and assigns consistently. Keep selection links mount-aware and do not convert module/scenario strings into atoms from untrusted URL or event data.

### Live editing, input fidelity, and recovery
- **D-04:** Retain live preview updates when scenario inputs change; this matches the existing LiveView behavior and test coverage. Avoid a second always-visible Render preview action that repeats the same event; offer a retry action only in a failure state if it performs a real retry. Use built-in LiveView debounce on free-text fields to avoid unnecessary render work per keystroke while keeping the preview responsive. Do not introduce a separate manual draft/commit workflow without measured need.
- **D-05:** Preserve attempted input separately from the last successful render. On validation or rendering failure, keep the editor and correction path available, show a useful field or render error, and retain useful input. If prior output remains visible, label it clearly as the last successful preview and not current; never style stale output as the result of the failed attempt.
- **D-06:** Make editing truthful for each value type. Parse and validate supported scalar inputs without silently replacing invalid numeric/date values with defaults. Keep the user's draft visible on invalid input. Do not label Elixir inspect output as JSON or imply that arbitrary nested maps/structs are editable when submissions are passed as strings. Present values without a safe, lossless editor contract (including nested structures and timezone-sensitive DateTime values unless their round-trip semantics are explicitly established) as read-only with accurate guidance to edit the Mailable scenario. Do not add a general schema or dynamic struct reconstruction contract.
- **D-07:** Announce state changes once and associate validation feedback with its field. Do not nest duplicate live/status announcements inside an alert. Keep diagnostic render errors useful to the developer preview job, with the documented dev-only mount boundary in force.

### Rendering semantics and output truth
- **D-08:** Render the selected Mailable through Mailglass.Renderer, the same content-rendering stage used by outbound preflight. Do not call outbound preflight, Outbound.deliver/2, or a provider adapter from Preview. Describe this accurately as using Mailglass's delivery rendering pipeline; do not claim that the preview is exactly what a recipient or provider receives.
- **D-09:** Keep HTML and plaintext as renderer outputs. Keep Raw as the existing best-effort, MIME-shaped preview envelope, not serialized wire bytes. Identify it as illustrative preview output. In Headers, identify preview-generated Message-ID and Date values so they cannot be mistaken for provider-bound facts. Do not add transport serialization or an adapter dependency.
- **D-10:** Correct preview page and guide copy that currently overstates delivery equivalence. Distinguish renderer output from outbound preflight, final adapter encoding, tracking/compliance transformations, and delivery. Keep preview free of a send action. State that this code path does not call Outbound.deliver; do not claim a package boundary structurally makes such a call impossible.
- **D-11:** Correct PreviewLive documentation that says no telemetry is emitted: Preview adds no preview-specific telemetry, while the shared Renderer emits its normal render lifecycle telemetry. Preserve the telemetry contract and do not add recipient/body data to preview-specific metadata. Do not broaden this phase into telemetry redesign absent a reproduced privacy defect.

### Accessible output inspection and responsive design
- **D-12:** Complete the existing single-select horizontal tab pattern using the W3C APG convention: one tab stop, Left/Right navigation with wrapping, Home/End support, visible focus on the focused tab, and manual activation with Space/Enter or click. Manual activation avoids a LiveView event on every arrow-key focus move. Keep aria-selected, aria-controls, labelled panel IDs, and panel visibility consistent; every control relationship must resolve. Make a panel keyboard-focusable when its content has no focusable descendant so keyboard users can reach and scroll long output.
- **D-13:** Keep long plaintext readable with wrapping and keep raw/header content within its own scroll region. Preserve full non-ASCII and long values; do not clip essential output or make hover the only way to inspect it. Let tabs and preview controls wrap at narrow widths without page-level horizontal scrolling.
- **D-14:** Preserve Phase 168's accepted Mailglass visual/accessibility contract: current semantic tokens and brand, flat surfaces, 16px body and 14px labels, visible focus, reduced-motion behavior, and 44px minimum interaction targets. Keep empty/setup copy, input errors, and output labels plain and specific.

### Preview framing, host boundary, and evidence limits
- **D-15:** Keep Admin chrome appearance (persisted System/Light/Dark) independent from the preview backdrop and selected CSS-pixel width. Label 375, 768, and 1024 as pixel widths, not physical device types. The backdrop applies only to browser preview surfaces and must not imply the email content supports dark mode.
- **D-16:** State plainly that the iframe and backdrop show browser rendering only; they do not certify Gmail, Outlook, Apple Mail, or other email clients. Capture artifacts establish preview-pipeline confidence only. Do not add a client-emulation matrix or visual judge.
- **D-17:** Preserve the host-owned dev-only mount contract. MailglassAdmin.Router.mailglass_admin_routes/2 does not enforce a dev environment or add preview authorization; adopter configuration must guard the route (as the documented compile-time dev_routes example does). Do not add account scoping, auth policy, or a production preview surface in this phase.
- **D-18:** Keep iframe scripts disabled and do not describe sandboxing as HTML sanitization or a network/privacy boundary. Preserve supported email rendering; do not change same-origin/resource behavior without a demonstrated compatibility need. Use synthetic, non-sensitive preview assigns and treat local screenshot captures as potentially sensitive. Rendered remote image URLs may make browser requests; document this boundary instead of promising that Preview blocks them.

### Shift-left acceptance and dependency posture
- **D-19:** Convert every machine-observable PRVUX criterion into deterministic coverage. Use existing Admin LiveView/ExUnit coverage for discovery, typed edits, failure recovery, stale-output truth, renderer output, empty/setup states, and framing semantics. Use the existing browser suite for actual tab keyboard/focus behavior and representative narrow/zoom/long-content layout. Reuse current fixtures and capture tooling; do not add a test framework or dependency.
- **D-20:** Run the relevant existing checks and report their merge-gating status accurately. Support Contract Admin is a required leaf behind CI Green; Operator Browser Gate and Preview Capture Advisory are outside the CI Green aggregate and are advisory in the current workflow. Do not present their green result as merge-blocking proof or create/promote a required lane for this phase. Follow D-52: passing automated evidence closes machine-observable acceptance without owner UAT; retain only bounded rendered review for genuinely visual questions.

### the agent's Discretion
- Choose the exact compact picker arrangement, spacing, error placement, and status wording within the Phase 168 UI contract and current brandbook.
- Set the smallest practical built-in LiveView debounce and choose the scalar field types to edit only where parsing preserves their type and semantics.
- Choose representative fixtures that cover valid, invalid, long, non-ASCII, and unsupported structured values without creating an exhaustive viewport/theme cross-product.
- Keep the approved one-batch rendered review bounded to one corrective pass and one confirmation round unless a concrete unresolved blocker appears.
</decisions>

<specifics>
## Specific Ideas

- Keep the preview useful and fast like a named scenario gallery with live input updates; do not copy another ecosystem's separate preview class or port unrelated job conventions. Rails Action Mailer previews and React Email are reference points for discoverable examples/live editing; Swoosh MailboxPreview is a locally delivered-message inbox and does not replace this scenario-driven workflow.
- The current code invokes Mailglass.Renderer, while outbound preflight adds other behavior before delivery. Raw uses a fixed illustrative boundary, and Headers includes generated values. The existing minimal representation is the recommended contract; exact MIME bytes would be a separate compatibility decision.
- The current mobile picker already uses a compact disclosure. Keep that mental model and expose the active scenario before opening it. For the empty state, distinguish “no Mailable exists” from “no scenario is configured,” and render generator commands as code rather than literal backtick punctuation.
- The tab decision follows the official W3C APG horizontal-tabs pattern and its activation-latency guidance: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/. APG is informative guidance; WCAG 2.2 requires keyboard access and no keyboard trap, while WAI-ARIA defines tab/tablist relationships. Manual activation is selected because tab changes use a LiveView event.
- Current implementation evidence reviewed: PreviewLive has separate device, backdrop, and Admin-theme state; rerender retains prior successful artifacts on failure, but the error branch hides the editor; the assigns form renders some inspect output as if JSON and type coercion is incomplete; inactive tab aria-controls targets and tab keyboard behavior need correction.
- Security review found that the route macro relies on the adopter's dev-only guard, the iframe has no allow-scripts permission but can load remote resources, and standard Renderer telemetry still runs. These are documented accurately without adding auth, sanitization, telemetry, or network-blocking dependencies.
- Research used current source and selected prompt materials. The active brandbook at brandbook/brand-book.md and approved Phase 168 UI-SPEC govern over the older working draft at prompts/mailglass-brand-book.md. No live visual inspection, app boot, test run, or CI run occurred during discussion.
- Primary sources consulted include Phoenix LiveView 1.1.33 form/event docs, Phoenix component docs, Swoosh.Email docs, the Phoenix LiveView security guide, W3C APG Tabs/WAI-ARIA/WCAG 2.2, MDN iframe/srcdoc references, and Rails Action Mailer preview docs. They informed design choices; project scope and current code remain authoritative.
</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** Repository paths are relative to the root.

### Product scope and acceptance
- PRODUCT.md — durable product truth, audiences, and package boundaries.
- .planning/PROJECT.md — active v2.9 goals, prior milestone state, and D-52.
- .planning/ROADMAP.md — Phase 171 boundary, success criteria, and UI acceptance focus.
- .planning/REQUIREMENTS.md — PRVUX-01 through PRVUX-04.
- .planning/research/v2.9/SCOPE.md — approved scope, design posture, bounded acceptance, and deferred work.
- .planning/METHODOLOGY.md — recommendation-first synthesis, honest surface area, dependency restraint, and shift-left verification.

### Inherited interface and brand
- .planning/phases/168-shared-workspace-and-usable-baseline/168-CONTEXT.md — locked shared navigation, theme, accessibility, and appearance separation.
- .planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md — current responsive, typography, motion, 44px target, and rendered acceptance contract.
- brandbook/brand-book.md — current Mailglass identity and brand voice; it supersedes the prompt working draft.
- brandbook/copy/microcopy.md — canonical empty/setup and product copy.
- brandbook/tokens.css — current brand tokens.
- mailglass_admin/docs/design-system.md — Admin semantic tokens and component patterns.

### Preview and rendering contracts
- lib/mailglass/mailable.ex — Mailable and preview scenario callback contract.
- mailglass_admin/lib/mailglass_admin/preview/discovery.ex — auto/explicit discovery and scenario resolution.
- mailglass_admin/lib/mailglass_admin/preview_live.ex — preview state, events, renderer call, errors, generated output, and copy.
- mailglass_admin/lib/mailglass_admin/preview/sidebar.ex — selected Mailable/scenario picker and mount-aware links.
- mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex — field types, input labels/help, and current edit behavior.
- mailglass_admin/lib/mailglass_admin/preview/tabs.ex — output tabs, iframe sandbox, and output panes.
- mailglass_admin/lib/mailglass_admin/preview/device_frame.ex — width controls.
- mailglass_admin/lib/mailglass_admin/preview/mount.ex and mailglass_admin/lib/mailglass_admin/router.ex — discovery mount and adopter-owned dev-only route boundary.
- lib/mailglass/renderer.ex and lib/mailglass/outbound/preflight.ex — shared content rendering versus later delivery preparation.
- guides/preview.md and guides/authoring-mailables.md — adopter preview setup, supported scenario examples, and rendering claims.
- mailglass_admin/README.md — documented dev-only installation and route guard.

### Automated evidence and research background
- mailglass_admin/test/mailglass_admin/preview_live_test.exs — current LiveView contract tests.
- mailglass_admin/test/support/fixtures/mailables.ex — valid, empty, and failing preview scenarios.
- mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex — deterministic preview capture workflow.
- .github/workflows/ci.yml — required Admin contract leaf and advisory browser/capture lanes.
- .planning/phases/170-inbound-investigation-and-recovery/170-VALIDATION.md — current report on required versus advisory CI evidence.
- prompts/mailer-domain-language-deep-research.md — Mailable, scenario, message, and preview domain language.
- prompts/phoenix-live-view-best-practices-deep-research.md — LiveView state, event, and test guidance.
- prompts/phoenix-best-practices-deep-research.md and prompts/elixir-oss-libs-best-practices-deep-research.md — Phoenix/Elixir package boundaries and dependency posture.
- prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md and prompts/Phoenix needs an email framework not another mailer.md — ecosystem context; approved roadmap and current source take precedence over broad/older proposals.
- reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex — an adopter-style named scenario and assigns-map example.

### External primary guidance
- W3C APG Tabs: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
- W3C APG manual tabs example: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/examples/tabs-manual/
- WAI-ARIA 1.2 tab and tablist roles: https://www.w3.org/TR/wai-aria/#tab and https://www.w3.org/TR/wai-aria/#tablist
- WCAG 2.2 keyboard, no-keyboard-trap, reflow, status-message, and target-size guidance: https://www.w3.org/WAI/WCAG22/quickref/
- Phoenix LiveView 1.1.33 and form bindings: https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html and https://phoenix-live-view.hexdocs.pm/form-bindings.html
- Phoenix LiveView security model: https://phoenix-live-view.hexdocs.pm/security-model.html
- MDN iframe and srcdoc: https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/iframe and https://developer.mozilla.org/en-US/docs/Web/API/HTMLIFrameElement/srcdoc
- Swoosh.Email and Rails Action Mailer previews: https://swoosh.hexdocs.pm/Swoosh.Email.html and https://guides.rubyonrails.org/action_mailer_basics.html#previewing-emails
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- MailglassAdmin.PreviewLive owns scenario state, LiveView events, renderer invocation, and page branches.
- Preview.Discovery, Sidebar, AssignsForm, Tabs, and DeviceFrame are existing focused function components/modules; use them rather than adding a frontend framework or second picker.
- Mailglass.Renderer is already the shared content renderer used by outbound preflight.
- Existing fixtures cover happy, stub/no-preview, and broken Mailables; existing LiveView tests cover discovery, output tabs, width/theme controls, and basic assign changes.
- The preview capture task and Playwright/browser support already provide real-browser and artifact paths.

### Established Patterns
- Preview state belongs in LiveView; function components own reusable HEEx markup; core rendering remains in mailglass.
- Scenario selection is based on a discovered Mailable and a named scenario; event and route inputs must remain constrained to discovered values.
- Admin chrome theme, preview backdrop, and frame width are already separate state; preserve that separation and existing URL/mount behavior.
- The current renderer call does not deliver mail. Full outbound preparation happens later in Outbound.Preflight.
- Admin uses current semantic theme tokens, 16px body and 14px label text, visible focus, and minimum 44px controls.
- LiveView ExUnit is already in required Support Contract Admin; browser rendering is available in Operator Browser Gate, which is not included in CI Green. Preview Capture Advisory is also not a required CI Green leaf.

### Integration Points
- mailglass_admin_routes/2 is mounted by adopters. Its compile-time dev_routes guard is host configuration, not enforced by the router macro; keep that contract explicit.
- Preview output originates from Mailable scenario functions, flows through Mailglass.Renderer, and is projected into four browser tabs. It does not represent all preflight, adapter encoding, or delivery effects.
- Browser captures can contain message data and rendered HTML may request remote images; use synthetic fixtures and treat captures as potentially sensitive.
- Any automation should extend current Admin tests/browser suites and state the CI lane status. No test, screenshot, app startup, or remote CI verification was performed during discussion.
</code_context>

<deferred>
## Deferred Ideas

- Byte-exact RFC/MIME or provider-adapter serialization and provider-specific delivery proof.
- Actual Gmail/Outlook/Apple Mail or dark-mode emulation and any paid visual judge.
- Production-shared preview access, new authorization/account scope, send-to-self, or preview send actions.
- A generalized schema/API for arbitrary nested maps and structs, native authoring editor, or framework migration.
- New dependencies, new required CI lane, or branch-protection changes.
- Broad exception telemetry redesign or remote-resource blocking absent a reproduced, in-scope privacy defect.

</deferred>

---

*Phase: 171-developer-preview*
*Context gathered: 2026-10-09*
