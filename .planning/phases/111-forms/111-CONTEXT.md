# Phase 111: Forms - Context

**Gathered:** 2026-06-19 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Third implementation phase of milestone v1.13 (Admin Design-System Stress Test & UX Uplift).
Scope: the admin form-control layer inherits the Phase 109 token/focus substrate and the Phase
110 shared primitive ownership pattern. The two divergent `filters_form` copies become one shared
`filter_field` / `filter_section` primitive set, filter controls get explicit label/help/error
semantics, disabled/read-only states are honest and visually distinct, and normal filter patches
preserve keyboard focus.

Hard scope line: Phase 111 does not own shell-level tenant listing, theme persistence/no-FOUC,
navigation/pagination, responsive table/card data-display work, demo stress-fixture expansion, axe
JSON baselining, or full matrix re-scoring. Those remain in phases 112-116.

Requirements: FORM-01, FORM-02, FORM-03.
</domain>

<decisions>
## Implementation Decisions

### Shared Primitive Ownership

- **D-01:** `filter_field` and `filter_section` belong in `MailglassAdmin.Components`, matching the
  Phase 110 rule that shared admin primitives live in the public component module. Operator,
  inbound, and gallery must consume those same public primitives instead of keeping divergent
  HEEx bodies.

- **D-02:** The existing `MailglassAdmin.Operator.FiltersForm` and
  `MailglassAdmin.Inbound.FiltersForm` modules may remain only as thin composition wrappers if that
  keeps call-site churn low. They must not retain duplicate label/control markup. A deterministic
  guard should fail if duplicated filter-field markup is reintroduced outside the shared primitive
  implementation.

### Form Surface Scope

- **D-03:** The mandatory implementation target is the duplicated operator/inbound filter forms.
  FORM-02 and FORM-03 also require auditing and either updating or explicitly certifying other
  authored admin form controls already in `mailglass_admin`, including Preview assigns controls and
  replay target radios where applicable. This is certification of the current admin form surface,
  not permission to redesign non-filter workflows.

### Accessibility And Recovery Contract

- **D-04:** Shared form primitives must make semantics explicit at the control level: stable `id`
  values, visible labels associated by `for`, optional help text, optional error text,
  `aria-describedby`, and `aria-invalid` when invalid. Do not rely on placeholder text, label
  wrapping alone, color alone, or silent normalization as the accessibility/recovery contract.

- **D-05:** Filter recovery copy should be specific and action-oriented. Invalid filter values that
  are currently normalized away or dropped should surface recovery text where the user can correct
  them, without changing the tenant/data trust boundary.

### Disabled, Read-Only, And Focus Semantics

- **D-06:** `disabled` means unavailable/inoperable. It must be visually and programmatically
  distinct and should not be used as a fake read-only state. Native `readonly` is valid only for
  text controls. For read-only select/radio/checkbox-style values, render a non-editable display of
  the selected value and include a hidden input only if the value must submit.

- **D-07:** For ordinary URL-param filter patches, preserve focus by keeping the same form/control
  DOM identity: stable form ids, stable control ids/names/types, and stable order/keys for repeated
  controls. Use LiveView `JS.focus*` helpers only when a patch intentionally removes or recreates
  the focused element and focus must move to a defined target.

### Verification Strategy

- **D-08:** Verification extends the existing non-pixel machinery: component tests for primitive
  HTML contracts, gallery specimens for form states, Playwright structural assertions for
  focus/target-size/disabled-readonly behavior across light/dark/system and 320->wide, and a
  conformance grep guard for duplicated filter markup. Do not add a runtime dependency, screenshot
  diff, or pixel-diff workflow in this phase.

### Claude's Discretion

- Exact attr names for `filter_field` / `filter_section`, as long as they support label, help,
  error, disabled, readonly/display-only, control type, options, and global attrs cleanly.
- Whether operator/inbound modules remain thin wrappers or call sites invoke `Components`
  primitives directly.
- Exact guard implementation, provided it is deterministic, repo-local, and follows the existing
  `check-conformance.sh` / structural-test style.

### Folded Todos

None - `todo.match-phase 111` returned 0 matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` - Phase 111 goal and success criteria.
- `.planning/REQUIREMENTS.md` - FORM-01..03 acceptance text and v1.13 scope locks.
- `.planning/PROJECT.md` - v1.13 milestone intent, scope locks, release posture, D-23/D-28/D-29.
- `.planning/STATE.md` - current milestone state and carried decisions from phases 109-110.
- `.planning/phases/109-foundations-gate-tightening/109-CONTEXT.md` - inherited token, focus-ring,
  z-layer, system-theme, and structural-gate decisions.
- `.planning/phases/110-primitives/110-CONTEXT.md` - inherited public primitive ownership and
  gallery/structural proof decisions.
- `.planning/research/v1.13/SUMMARY.md` - Phase C forms synthesis; plan-direct signal.
- `.planning/research/v1.13/ARCHITECTURE.md` - duplicated `filters_form.ex` diagnosis and shared
  form primitive target.
- `.planning/research/v1.13/PITFALLS.md` - focus/hover pitfalls, especially A14 and B-A9.
- `.planning/research/v1.13/STACK.md` - zero-Node asset boundary and structural/axe context.
- `mailglass_admin/lib/mailglass_admin/components.ex` - public primitive home.
- `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex` - current operator duplicate.
- `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex` - current inbound duplicate.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - operator filter form integration and
  URL-patch events.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - inbound filter form integration and
  URL-patch events.
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` - component-lab specimens and current
  filter form gallery entry.
- `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` - existing non-filter authored
  form controls requiring audit/certification.
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` and
  `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` - replay target form controls and
  existing focus-management patterns.
- `mailglass_admin/e2e/structural.spec.js` - focus, target-size, contrast, disabled, and gallery
  structural proof machinery.
- Phoenix LiveView 1.1.28 form bindings:
  `https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html#javascript-client-specifics`.
- Phoenix LiveView 1.1.28 live navigation:
  `https://hexdocs.pm/phoenix_live_view/1.1.28/live-navigation.html`.
- Phoenix LiveView 1.1.28 JS focus helpers:
  `https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.JS.html`.
- WHATWG HTML `readonly` attribute:
  `https://html.spec.whatwg.org/multipage/input.html#attr-input-readonly`.
- WHATWG HTML `select` element:
  `https://html.spec.whatwg.org/multipage/form-elements.html#the-select-element`.
- WAI-ARIA 1.2 `aria-readonly`:
  `https://www.w3.org/TR/wai-aria-1.2/#aria-readonly`.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `MailglassAdmin.Components` already contains the public primitive pattern from Phase 110:
  `nav_link`, `nav_pill`, `tenant_chip`, `theme_picker`, `stat_card`, `icon`, `flash`,
  `status_badge`, and shared helper conventions.
- `operator/filters_form.ex` and `inbound/filters_form.ex` are small, isolated components with
  similar `fields/1` markup, making extraction to shared primitives low-risk.
- Both `operator_live.ex` and `inbound_live.ex` already wrap filters in stable `<.form>` ids
  (`operator-filters`, `inbound-filters`) with `phx-change="validate_filters"` and
  `phx-submit="apply_filters"`.
- `gallery_live.ex` already has a `:filters_form` specimen path; it can be widened to certify the
  real shared primitives and relevant states.
- `structural.spec.js` already provides helper functions for touch target size, focus appearance,
  focus-not-obscured, text/non-text contrast, programmatic disabled behavior, and gallery state
  iteration.

### Established Patterns

- Shared reusable admin atoms live in `MailglassAdmin.Components`; page/surface modules should
  compose them rather than duplicating markup.
- Structural proof is Playwright assertions and component tests, not screenshots or pixel diffs.
- Shipped admin CSS remains a zero-Node asset artifact; rebuild and commit `priv/static/app.css`
  when class changes affect the bundle.
- Phase 109 focus-ring work established `mg-focus-ring` and focus-not-obscured proof as the default
  focus pattern.
- Phase 110 gallery certification uses real public components rather than gallery-only copies.

### Integration Points

- Primitive extraction touches `mailglass_admin/lib/mailglass_admin/components.ex`,
  `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex`,
  `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex`,
  `mailglass_admin/lib/mailglass_admin/operator_live.ex`,
  `mailglass_admin/lib/mailglass_admin/inbound_live.ex`, and `gallery_live.ex`.
- Tests likely extend `mailglass_admin/test/mailglass_admin/components_test.exs`,
  `mailglass_admin/test/mailglass_admin/inbound/components_test.exs`,
  `mailglass_admin/test/mailglass_admin/operator_live_test.exs`,
  `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`, and
  `mailglass_admin/e2e/structural.spec.js`.
- Conformance work plugs into the existing `mailglass_admin/scripts/check-conformance.sh` pattern.
</code_context>

<specifics>
## Specific Ideas

- Prefer explicit `id` + `<label for>` over wrapper-only labels so help/error text can target the
  same control id predictably.
- Treat placeholder text as an example only, never as the label.
- Use `aria-describedby` to join help and error ids when both are present.
- For read-only non-text controls, render the value as text/chip plus hidden input if submit
  semantics require it; do not put `readonly` on native `select` or radio controls.
- Normal filter patches should preserve focus by preserving element identity. Add JS focus helpers
  only for intentional remove/recreate cases.
</specifics>

<deferred>
## Deferred Ideas

- Tenant auto-select, tenant listing/switcher, and tenant-scope persistence - Phase 112.
- Theme persistence, host-scoped cookie naming, and no-FOUC first paint - Phase 112.
- Data-display table/card transformations, KPI cleanup, long-value display patterns beyond form
  controls - Phase 113.
- Axe JSON baseline, interaction pillar expansion, rich demo fixture run, and full matrix re-score
  - Phase 116.
- Recipient-facing email templates and `brandbook/` token changes - out of milestone scope.

### Reviewed Todos (not folded)

None - `todo.match-phase 111` returned 0 matches.
</deferred>
