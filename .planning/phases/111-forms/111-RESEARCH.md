# Phase 111: Forms - Research

**Researched:** 2026-06-19  
**Domain:** Phoenix LiveView admin form primitives, accessibility semantics, and URL-patch focus persistence  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Shared Primitive Ownership

- **D-01:** `filter_field` and `filter_section` belong in `MailglassAdmin.Components`, matching the
  Phase 110 rule that shared admin primitives live in the public component module. Operator,
  inbound, and gallery must consume those same public primitives instead of keeping divergent
  HEEx bodies.

- **D-02:** The existing `MailglassAdmin.Operator.FiltersForm` and
  `MailglassAdmin.Inbound.FiltersForm` modules may remain only as thin composition wrappers if that
  keeps call-site churn low. They must not retain duplicate label/control markup. A deterministic
  guard should fail if duplicated filter-field markup is reintroduced outside the shared primitive
  implementation.

#### Form Surface Scope

- **D-03:** The mandatory implementation target is the duplicated operator/inbound filter forms.
  FORM-02 and FORM-03 also require auditing and either updating or explicitly certifying other
  authored admin form controls already in `mailglass_admin`, including Preview assigns controls and
  replay target radios where applicable. This is certification of the current admin form surface,
  not permission to redesign non-filter workflows.

#### Accessibility And Recovery Contract

- **D-04:** Shared form primitives must make semantics explicit at the control level: stable `id`
  values, visible labels associated by `for`, optional help text, optional error text,
  `aria-describedby`, and `aria-invalid` when invalid. Do not rely on placeholder text, label
  wrapping alone, color alone, or silent normalization as the accessibility/recovery contract.

- **D-05:** Filter recovery copy should be specific and action-oriented. Invalid filter values that
  are currently normalized away or dropped should surface recovery text where the user can correct
  them, without changing the tenant/data trust boundary.

#### Disabled, Read-Only, And Focus Semantics

- **D-06:** `disabled` means unavailable/inoperable. It must be visually and programmatically
  distinct and should not be used as a fake read-only state. Native `readonly` is valid only for
  text controls. For read-only select/radio/checkbox-style values, render a non-editable display of
  the selected value and include a hidden input only if the value must submit.

- **D-07:** For ordinary URL-param filter patches, preserve focus by keeping the same form/control
  DOM identity: stable form ids, stable control ids/names/types, and stable order/keys for repeated
  controls. Use LiveView `JS.focus*` helpers only when a patch intentionally removes or recreates
  the focused element and focus must move to a defined target.

#### Verification Strategy

- **D-08:** Verification extends the existing non-pixel machinery: component tests for primitive
  HTML contracts, gallery specimens for form states, Playwright structural assertions for
  focus/target-size/disabled-readonly behavior across light/dark/system and 320->wide, and a
  conformance grep guard for duplicated filter markup. Do not add a runtime dependency, screenshot
  diff, or pixel-diff workflow in this phase.

### the agent's Discretion

- Exact attr names for `filter_field` / `filter_section`, as long as they support label, help,
  error, disabled, readonly/display-only, control type, options, and global attrs cleanly.
- Whether operator/inbound modules remain thin wrappers or call sites invoke `Components`
  primitives directly.
- Exact guard implementation, provided it is deterministic, repo-local, and follows the existing
  `check-conformance.sh` / structural-test style.

### Deferred Ideas (OUT OF SCOPE)

- Tenant auto-select, tenant listing/switcher, and tenant-scope persistence - Phase 112.
- Theme persistence, host-scoped cookie naming, and no-FOUC first paint - Phase 112.
- Data-display table/card transformations, KPI cleanup, long-value display patterns beyond form
  controls - Phase 113.
- Axe JSON baseline, interaction pillar expansion, rich demo fixture run, and full matrix re-score
  - Phase 116.
- Recipient-facing email templates and `brandbook/` token changes - out of milestone scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FORM-01 | Unify the two divergent filter form copies into shared `filter_field` / `filter_section` primitives. | The duplicated implementations are `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex` and `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex`; `MailglassAdmin.Components` is the locked primitive home. [VERIFIED: repo] |
| FORM-02 | Ensure every form control has visible labels, programmatic help/error associations, recovery-oriented error copy, and non-color-only validation state. | Current filter, Preview assigns, and operator replay radio controls do not consistently expose explicit `for`/`id`, help/error IDs, or non-color validation cues; WAI and WCAG require labels/instructions, text error identification, and non-color-only status. [VERIFIED: repo] [CITED: https://www.w3.org/WAI/tutorials/forms/labels/] [CITED: https://www.w3.org/WAI/tutorials/forms/instructions/] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/error-identification.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html] |
| FORM-03 | Make disabled/read-only states visually distinct and preserve focus across LiveView patches. | Existing filter forms already use stable form IDs with `phx-change` and `phx-submit`; LiveView keeps focused input values as client source-of-truth during patches, and same-LiveView `push_patch` updates params without remounting. [VERIFIED: repo] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html#javascript-client-specifics] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/live-navigation.html] |
</phase_requirements>

## Summary

Phase 111 should extract the duplicated operator and inbound filter markup into public `MailglassAdmin.Components.filter_field/1` and `MailglassAdmin.Components.filter_section/1` primitives, then keep `Operator.FiltersForm` and `Inbound.FiltersForm` only as thin composition wrappers if doing so minimizes call-site churn. [VERIFIED: repo] The current duplicate filter modules use wrapper labels with visible text, but they lack explicit stable control IDs, `label for`, help/error descriptions, `aria-describedby`, and `aria-invalid`; the same audit must include Preview assigns controls and operator replay target radios because the phase context explicitly includes those existing admin form surfaces. [VERIFIED: repo]

The implementation should use Phoenix form field metadata instead of inventing ID/name parsing: `Phoenix.HTML.Form` exposes `form[field]` as a `Phoenix.HTML.FormField` with `id`, `name`, `value`, and `errors`, and Phoenix.HTML also exposes `input_id/2`, `input_name/2`, and `input_value/2` helpers. [CITED: https://hexdocs.pm/phoenix_html/4.3.0/Phoenix.HTML.Form.html] LiveView form recovery and focus behavior depend on stable DOM identity: forms with `phx-change` and an `id` are replayed for recovery after remount, focused input values are not overwritten by patches, and same-LiveView patches call `handle_params/3` without remounting. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/live-navigation.html]

**Primary recommendation:** implement the shared primitives in `MailglassAdmin.Components`, pass field/error/help metadata from the existing LiveViews/wrappers, extend gallery specimens and structural tests for valid/invalid/disabled/read-only/focus-persistence states, and add a conformance guard that fails if old duplicated filter-field markup returns outside `components.ex`. [VERIFIED: repo]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Shared form primitives | Frontend Server / Phoenix.Component | Browser / DOM | `MailglassAdmin.Components` owns reusable admin primitives and renders the HEEx that creates label/control/help/error semantics. [VERIFIED: repo] |
| Filter recovery metadata | LiveView server process | Browser / DOM | `operator_live.ex` and `inbound_live.ex` currently normalize URL/form params before assigning `to_form`; recovery copy must be computed before rendering fields. [VERIFIED: repo] |
| URL-backed filter patching | LiveView server process | Browser / DOM | Existing `apply_filters` handlers use `push_patch` and `handle_params/3`; LiveView patching updates params without remounting the current LiveView. [VERIFIED: repo] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/live-navigation.html] |
| Focus preservation | Browser / DOM | LiveView JS diffing | Focus survives ordinary patches when the same focused element identity remains stable; LiveView also provides `JS.focus*` helpers for deliberate focus moves. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html#javascript-client-specifics] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.JS.html] |
| Duplicate-markup prevention | Repository tooling / CI | Frontend Server | `mailglass_admin/scripts/check-conformance.sh` already enforces primitive drift and other design-system gates, making it the standard place for a deterministic duplicate-filter guard. [VERIFIED: repo] |

## Project Constraints (from CLAUDE.md / AGENTS.md)

- No `AGENTS.md` file exists at the repository root; no `.kimi-code/CLAUDE.md` file exists in the checked project path. [VERIFIED: repo]
- `CLAUDE.md` states the admin/demo work must not add new runtime dependencies, and the v1.13 state repeats that the only net-new dependency in the milestone is test-only `@axe-core/playwright`. [VERIFIED: repo]
- `CLAUDE.md` states the admin CSS pipeline is a zero-Node runtime asset flow and committed `mailglass_admin/priv/static/app.css` must be regenerated when class changes affect the bundle. [VERIFIED: repo]
- `CLAUDE.md` prohibits screenshot/pixel-diff workflows for this milestone and directs verification toward structural tests. [VERIFIED: repo]
- `CLAUDE.md` requires recovery copy to avoid generic phrasing like "Oops" and instead explain what happened and how to recover. [VERIFIED: repo]
- `.planning/STATE.md` limits the current v1.13 scope to admin and demo surfaces. [VERIFIED: repo]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | 1.1.28 | Live-rendered filter forms, `phx-change`, `phx-submit`, `push_patch`, and JS focus helpers. | Existing project dependency; official docs define form recovery, focused input patch behavior, live navigation, and focus helpers. [VERIFIED: repo] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html] |
| Phoenix.HTML | 4.3.0 | Form field metadata and input helper functions. | Existing project dependency; `form[field]` supplies the stable `id`, `name`, `value`, and `errors` needed by the primitive. [VERIFIED: repo] [CITED: https://hexdocs.pm/phoenix_html/4.3.0/Phoenix.HTML.Form.html] |
| Phoenix.Component / HEEx | Phoenix 1.8.5 | Function-component primitives in `MailglassAdmin.Components`. | Existing shared primitive pattern from Phase 110 uses public function components in `components.ex`. [VERIFIED: repo] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| ExUnit + Phoenix.LiveViewTest | Elixir 1.19.5 / project test stack | Component and LiveView contract tests. | Use for primitive HTML contracts, filter URL behavior, and Preview/replay form certification. [VERIFIED: repo] |
| Floki | 0.38.4 | HTML parsing in component tests. | Use for asserting label/control/help/error relationships without a browser. [VERIFIED: repo] |
| `@playwright/test` | 1.59.1 | Browser structural tests. | Use for focus persistence, disabled/read-only behavior, target size, and viewport/theme matrix assertions. [VERIFIED: repo] |
| `mailglass_admin/scripts/check-conformance.sh` | repo script | Grep-based design-system gates. | Add the FORM-01 duplicate-markup guard here. [VERIFIED: repo] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `MailglassAdmin.Components.filter_field/1` | Keep page-local filter markup | Rejected by locked D-01/D-02 because duplicate label/control HEEx must not remain. [VERIFIED: repo] |
| Phoenix.HTML field metadata | Manually concatenate input IDs and names | Rejected because Phoenix.HTML already exposes field IDs/names/values/errors and the current forms already use `to_form`. [VERIFIED: repo] [CITED: https://hexdocs.pm/phoenix_html/4.3.0/Phoenix.HTML.Form.html] |
| Structural Playwright assertions | Screenshot or pixel diff | Rejected by locked D-08 and project instructions. [VERIFIED: repo] |

**Installation:**
```bash
# No package install is recommended for this phase.
```

**Version verification performed:**
```bash
cd mailglass_admin && mix deps | rg 'phoenix_live_view|phoenix_html|floki|phoenix'
node --version
npm --version
cd mailglass_admin && npm exec -- playwright --version
```

## Package Legitimacy Audit

No external packages are recommended or required for this phase. [VERIFIED: repo]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| N/A | N/A | N/A | N/A | N/A | N/A | No install |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Browser form input
  -> LiveView phx-change / phx-submit
  -> operator_live.ex or inbound_live.ex normalizes params and computes recovery errors
  -> Phoenix.HTML.to_form assigns stable field metadata
  -> thin FiltersForm wrapper, if retained
  -> MailglassAdmin.Components.filter_section/filter_field
  -> explicit label/control/help/error DOM
  -> browser keeps focus when IDs/names/types/order remain stable across patch
```

```text
Gallery specimen / component test / LiveView test / Playwright test
  -> real MailglassAdmin.Components primitive
  -> valid, invalid, disabled, readonly/display-only, light/dark/system, mobile/wide states
  -> conformance guard rejects reintroduced duplicate filter markup
```

### Recommended Project Structure

```text
mailglass_admin/
├── lib/mailglass_admin/components.ex                 # add public filter_field/filter_section primitives
├── lib/mailglass_admin/operator/filters_form.ex      # thin wrapper only, or removed from call path
├── lib/mailglass_admin/inbound/filters_form.ex       # thin wrapper only, or removed from call path
├── lib/mailglass_admin/operator_live.ex              # pass operator filter help/error/recovery metadata
├── lib/mailglass_admin/inbound_live.ex               # pass inbound filter help/error/recovery metadata
├── lib/mailglass_admin/gallery_live.ex               # certify real shared primitive states
├── lib/mailglass_admin/preview/assigns_form.ex       # audit/update/certify non-filter controls
├── lib/mailglass_admin/operator/replay_modal.ex      # audit/update/certify replay target radios
├── test/mailglass_admin/components_test.exs          # primitive contract tests
├── test/mailglass_admin/operator_live_test.exs       # operator filter recovery and URL behavior
├── test/mailglass_admin/inbound_live_test.exs        # inbound filter recovery and URL behavior
├── test/mailglass_admin/preview_live_test.exs        # Preview assigns certification
├── e2e/structural.spec.js                            # browser focus/disabled/readonly/label assertions
└── scripts/check-conformance.sh                      # duplicate filter markup guard
```

### Pattern 1: Shared Field Primitive Contract

**What:** `filter_field/1` should accept a Phoenix form field and render one labeled control with optional help and error text. [VERIFIED: repo] [CITED: https://hexdocs.pm/phoenix_html/4.3.0/Phoenix.HTML.Form.html]

**When to use:** Use for every operator/inbound filter control and for gallery specimens that certify the primitive itself. [VERIFIED: repo]

**Example:**
```elixir
# Source: proposed implementation shape from Phase 111 context and Phoenix.HTML.Form docs.
<Components.filter_field
  field={@form[:provider]}
  label="Provider"
  help="Filter by provider key, for example postmark."
  error={@filter_errors["provider"]}
  placeholder="postmark"
/>
```

Implementation details the planner should require: the control ID should come from `field.id` or an explicit deterministic override; `<label for={id}>` should be visible; help/error elements should have stable IDs; `aria-describedby` should include all rendered description IDs; and `aria-invalid="true"` should appear when the field has an error. [CITED: https://www.w3.org/WAI/tutorials/forms/labels/] [CITED: https://www.w3.org/WAI/tutorials/forms/instructions/] [CITED: https://www.w3.org/TR/wai-aria-1.2/#aria-invalid]

### Pattern 2: Filter Section Primitive

**What:** `filter_section/1` should group related filter fields and expose a section/fieldset-level label without duplicating individual field markup. [VERIFIED: repo]

**When to use:** Use in operator/inbound filter forms and gallery specimens where several filter controls are rendered as one filter surface. [VERIFIED: repo]

**Example:**
```elixir
# Source: proposed implementation shape from D-01/D-04.
<Components.filter_section title="Filters">
  <:field>
    <Components.filter_field field={@form[:tenant]} label="Tenant" />
  </:field>
</Components.filter_section>
```

Use a real `fieldset`/`legend` when the grouping label conveys a relationship among controls; WAI labels guidance treats grouped controls as needing group context in addition to individual labels. [CITED: https://www.w3.org/WAI/tutorials/forms/labels/]

### Pattern 3: Recovery Metadata for Normalized Filters

**What:** Preserve the current tenant/data trust boundary while surfacing invalid URL/form values as field-level recovery text. [VERIFIED: repo]

**When to use:** Use when `status`, `event`, `outcome`, or `window_hours` params fail the existing allowlist/integer normalization paths. [VERIFIED: repo]

**Example:**
```elixir
# Source: proposed implementation shape from current normalizers and D-05.
%{
  "window_hours" => "Time window was not applied. Choose one of the listed windows.",
  "status" => "Status was not applied. Choose a listed status."
}
```

Current operator normalization silently falls back or drops invalid `status`, `event`, and `window_hours` values, and current inbound normalization silently drops invalid `outcome` and defaults invalid `window_hours`. [VERIFIED: repo] Recovery copy should be specific, action-oriented, and connected to the relevant control by the primitive. [VERIFIED: repo]

### Pattern 4: Stable DOM Identity for Focus Persistence

**What:** Keep form ID, control ID, name, type, and order stable across ordinary filter URL patches. [VERIFIED: repo]

**When to use:** Use for `validate_filters`, `apply_filters`, and `handle_params` rendering on both operator and inbound pages. [VERIFIED: repo]

**Example:**
```elixir
# Source: existing LiveView pattern plus LiveView form docs.
<.form for={@filter_form} id="operator-filters" phx-change="validate_filters" phx-submit="apply_filters">
  <Operator.FiltersForm.fields form={@filter_form} errors={@filter_errors} />
</.form>
```

LiveView documents that focused input values are treated as client source-of-truth during patches, and the existing operator/inbound forms already have stable form IDs. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html#javascript-client-specifics] [VERIFIED: repo] Use `JS.focus`, `JS.focus_first`, `JS.push_focus`, or `JS.pop_focus` only for deliberate focus moves when an element is intentionally removed or recreated. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.JS.html]

### Pattern 5: Honest Disabled and Read-Only Rendering

**What:** Use native `disabled` only when the control is unavailable, native `readonly` only where HTML supports it, and display-only markup plus hidden input for read-only select/radio/checkbox values that still need submission. [CITED: https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attr-fe-disabled] [CITED: https://html.spec.whatwg.org/multipage/input.html#attr-input-readonly] [CITED: https://html.spec.whatwg.org/multipage/form-elements.html#the-select-element]

**When to use:** Use in shared primitives, Preview assigns controls, and replay target control certification. [VERIFIED: repo]

Disabled controls are omitted from form data construction and barred from constraint validation, so disabled is not a safe fake read-only representation when a value must submit. [CITED: https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attr-fe-disabled]

### Anti-Patterns to Avoid

- **Duplicate filter field HEEx in operator/inbound wrappers:** violates D-01/D-02 and prevents one contract from covering both pages. [VERIFIED: repo]
- **Wrapper-only labels as the accessibility contract:** the current duplicate forms use label wrappers, but explicit `for`/`id` is the more robust pattern for associating help/error descriptions. [VERIFIED: repo] [CITED: https://www.w3.org/WAI/tutorials/forms/labels/]
- **Placeholder-as-label:** HTML explicitly warns not to use placeholder instead of a label. [CITED: https://html.spec.whatwg.org/multipage/input.html#attr-input-placeholder]
- **Silent invalid filter normalization:** D-05 requires recovery copy where invalid values are currently normalized away or dropped. [VERIFIED: repo]
- **Color-only validation or selection state:** WCAG 2.2 SC 1.4.1 requires information not be conveyed by color alone. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html]
- **Using `disabled` for read-only values:** disabled controls are unavailable and omitted from submission; D-06 requires a different read-only/display-only pattern. [VERIFIED: repo] [CITED: https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attr-fe-disabled]
- **Recreating focused controls on normal patches:** LiveView focus preservation relies on stable DOM identity for ordinary patches. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html#javascript-client-specifics]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Form field IDs/names/values | Custom string concatenation for input metadata | `Phoenix.HTML.FormField` / Phoenix.HTML helpers | Existing `to_form` fields already expose `id`, `name`, `value`, and `errors`. [CITED: https://hexdocs.pm/phoenix_html/4.3.0/Phoenix.HTML.Form.html] |
| Browser focus movement | Custom JavaScript focus manager | Stable LiveView DOM identity; LiveView `JS.focus*` only for intentional moves | LiveView already defines patch-time focus behavior and DOM-patch-aware JS commands. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html#javascript-client-specifics] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.JS.html] |
| Accessible label/error semantics | Ad hoc `data-*` conventions | Native `<label for>`, `aria-describedby`, `aria-invalid`, visible text | WAI/WCAG/ARIA define interoperable form semantics. [CITED: https://www.w3.org/WAI/tutorials/forms/labels/] [CITED: https://www.w3.org/WAI/tutorials/forms/instructions/] [CITED: https://www.w3.org/TR/wai-aria-1.2/#aria-invalid] |
| Duplicate prevention | Manual code review only | `check-conformance.sh` guard plus component tests | The repo already uses conformance gates for primitive drift and design-system constraints. [VERIFIED: repo] |

**Key insight:** this phase is a primitive-contract extraction, not a visual redesign; the hard parts are stable semantics, recovery behavior, and regression gates. [VERIFIED: repo]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None for component/module names; the phase changes admin UI primitives and does not rename persisted database keys. Existing filter state is URL/form params such as `tenant_id`, `provider`, `status`, `event`, `outcome`, `window_hours`, and `search`. [VERIFIED: repo] | No data migration. Preserve existing URL param names unless an explicit compatibility task is added. [VERIFIED: repo] |
| Live service config | None found; no external service/UI configuration stores `filters_form`, `filter_field`, or `filter_section`. [VERIFIED: repo] | No live-service migration. [VERIFIED: repo] |
| OS-registered state | None found; no launchd/systemd/OS registration is implicated by this UI component extraction. [VERIFIED: repo] | No OS action. [VERIFIED: repo] |
| Secrets/env vars | None found; the phase does not rename secret or environment variable names. [VERIFIED: repo] | No secret/env migration. [VERIFIED: repo] |
| Build artifacts | CSS output may change if implementation changes Tailwind/daisyUI class usage; committed `priv/static/app.css` is part of the project contract. [VERIFIED: repo] | Run `mix mailglass_admin.assets.build` through `mix verify.preview` and commit static drift during implementation if CSS changes. [VERIFIED: repo] |

## Common Pitfalls

### Pitfall 1: Certifying Only the Operator Form

**What goes wrong:** `gallery_live.ex` currently renders the operator `FiltersForm.fields/1` for the `:filters_form` specimen, so inbound-specific controls can remain unproven. [VERIFIED: repo]  
**Why it happens:** the existing gallery path predates the shared primitive extraction. [VERIFIED: repo]  
**How to avoid:** add primitive-level gallery specimens and include option sets/states that cover both operator and inbound field shapes. [VERIFIED: repo]  
**Warning signs:** structural tests still mention only `:filters_form` or `Operator.FiltersForm` after the extraction. [VERIFIED: repo]

### Pitfall 2: Invalid URL Params Disappear Without Recovery

**What goes wrong:** invalid `window_hours`, `status`, `event`, or `outcome` values are normalized away before the user gets field-level feedback. [VERIFIED: repo]  
**Why it happens:** current normalizers prioritize safe filtering defaults and do not carry invalid raw values into render metadata. [VERIFIED: repo]  
**How to avoid:** compute a field-error/recovery map alongside normalized filter params and render it through `filter_field/1`. [VERIFIED: repo]  
**Warning signs:** tests can submit `/ops/mail?...&window_hours=bogus` or equivalent form values and see no visible recovery text. [VERIFIED: repo]

### Pitfall 3: Validation State Depends on Color

**What goes wrong:** a red border or background indicates invalid/selected state without text, iconography, or programmatic state. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html]  
**Why it happens:** existing card/radio visual states already use border/background classes, and form errors can easily follow that pattern. [VERIFIED: repo]  
**How to avoid:** include visible error text, `aria-invalid`, and a non-color visual cue such as an icon or text token in invalid/selected states. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/error-identification.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html]  
**Warning signs:** tests assert only CSS classes and never assert text or ARIA state. [VERIFIED: repo]

### Pitfall 4: Read-Only Implemented as Disabled

**What goes wrong:** a value appears preserved, but disabled controls are unavailable and omitted from submitted form data. [CITED: https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attr-fe-disabled]  
**Why it happens:** disabled inputs are visually convenient, and current Preview assigns fallback uses disabled inputs for unsupported values. [VERIFIED: repo]  
**How to avoid:** use native `readonly` for text inputs, display-only text/chips for non-text controls, and hidden inputs only when the value must submit. [VERIFIED: repo] [CITED: https://html.spec.whatwg.org/multipage/input.html#attr-input-readonly]  
**Warning signs:** `readonly` appears on `select`/radio markup or disabled controls are used for submitted read-only values. [CITED: https://html.spec.whatwg.org/multipage/form-elements.html#the-select-element]

### Pitfall 5: Focus Lost Across `push_patch`

**What goes wrong:** typing into a filter field or submitting a filter patch moves focus to `<body>` or a different control. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html#javascript-client-specifics]  
**Why it happens:** IDs, names, input type, order, or conditional wrapper identity changes during render. [VERIFIED: repo]  
**How to avoid:** derive stable IDs from field metadata, keep field ordering stable, and avoid conditional replacement of focused controls during ordinary filter patches. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html#javascript-client-specifics]  
**Warning signs:** Playwright sees `document.activeElement` change after `phx-change` or `push_patch`. [VERIFIED: repo]

## Code Examples

Verified patterns from official sources and repository context:

### Control-Level Description Composition

```elixir
# Source: WAI form instructions, WAI-ARIA aria-invalid, and Phoenix.HTML.Form field metadata.
control_id = field.id
help_id = "#{control_id}-help"
error_id = "#{control_id}-error"
described_by = Enum.join(Enum.filter([help && help_id, error && error_id]), " ")
```

Render the control with a visible `<label for={control_id}>`, `aria-describedby={described_by}` when descriptions exist, and `aria-invalid="true"` when an error is rendered. [CITED: https://www.w3.org/WAI/tutorials/forms/labels/] [CITED: https://www.w3.org/WAI/tutorials/forms/instructions/] [CITED: https://www.w3.org/TR/wai-aria-1.2/#aria-invalid]

### LiveView Focus-Persistence Assertion

```javascript
// Source: proposed Playwright assertion over existing structural test stack.
await page.getByLabel("Provider").focus();
await page.getByLabel("Provider").fill("postmark");
const before = await page.evaluate(() => document.activeElement && document.activeElement.id);
await page.getByRole("button", { name: "Apply filters" }).click();
await expect.poll(() => page.evaluate(() => document.activeElement && document.activeElement.id)).toBe(before);
```

The exact selector names depend on the implemented visible labels, but the assertion should verify that focus remains on the same control after the ordinary filter patch. [VERIFIED: repo] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html#javascript-client-specifics]

### Duplicate-Markup Guard Shape

```bash
# Source: proposed check-conformance.sh gate using existing repo-local conformance style.
rg -n '<label class="form-control"|defp label\\(' mailglass_admin/lib/mailglass_admin/operator/filters_form.ex mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
```

The final guard should be deterministic but not brittle: it should allow thin wrappers and fail when duplicated label/control HEEx returns outside `MailglassAdmin.Components`. [VERIFIED: repo]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Page-local duplicated filter form markup | Public `MailglassAdmin.Components` primitives consumed by operator, inbound, and gallery | Locked for Phase 111 after Phase 110 primitive ownership decision | One component contract can satisfy FORM-01 and prevent drift. [VERIFIED: repo] |
| Placeholder/wrapper label as enough | Visible explicit labels, control IDs, help/error descriptions, and ARIA invalid state | Locked for Phase 111 and aligned with WAI/WCAG form guidance | Screen reader, recovery, and testability behavior becomes explicit. [VERIFIED: repo] [CITED: https://www.w3.org/WAI/tutorials/forms/labels/] |
| Silent filter normalization | Recovery-oriented field text for dropped/defaulted invalid values | Locked for Phase 111 | Invalid URL/form values stay safe while becoming correctable. [VERIFIED: repo] |
| Pixel/screenshot verification | Component tests, Playwright structural assertions, and conformance grep | Milestone v1.13 constraint | Verification stays deterministic and host-app-friendly. [VERIFIED: repo] |

**Deprecated/outdated:**
- Duplicated `filters_form` label/control bodies in operator and inbound modules are outdated for Phase 111 because D-01/D-02 require shared primitives. [VERIFIED: repo]
- Placeholder text as a substitute for labels is invalid for this phase and discouraged by HTML/WAI guidance. [VERIFIED: repo] [CITED: https://html.spec.whatwg.org/multipage/input.html#attr-input-placeholder]
- Disabled controls as fake read-only display are invalid for this phase because disabled controls are inoperable and omitted from submission. [VERIFIED: repo] [CITED: https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attr-fe-disabled]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact primitive attr names shown in examples are proposed shapes, not locked names. | Architecture Patterns / Code Examples | Low; D-08 leaves exact attr names to implementation discretion as long as required semantics are supported. |

## Open Questions

1. **Should recovery errors live in a side map or be converted into form errors?**
   - What we know: current filter data is map-backed `to_form`, and Phoenix form fields expose `errors`. [VERIFIED: repo] [CITED: https://hexdocs.pm/phoenix_html/4.3.0/Phoenix.HTML.Form.html]
   - What's unclear: the cleanest code shape for invalid URL params may be a separate `%{field => message}` map or a form-compatible error structure. [ASSUMED]
   - Recommendation: choose the smallest shape that keeps primitive calls explicit and tests straightforward. [ASSUMED]

2. **Should filter wrappers remain?**
   - What we know: D-02 allows `MailglassAdmin.Operator.FiltersForm` and `MailglassAdmin.Inbound.FiltersForm` to remain as thin wrappers only. [VERIFIED: repo]
   - What's unclear: direct `Components` calls would remove wrapper indirection but increase call-site churn. [ASSUMED]
   - Recommendation: keep wrappers if they only assemble field specs/options and all label/control markup is in `Components`. [ASSUMED]

3. **How much Preview assigns/replay markup should be changed versus certified?**
   - What we know: D-03 requires auditing and either updating or explicitly certifying Preview assigns controls and replay target radios where applicable. [VERIFIED: repo]
   - What's unclear: some controls may pass after documentation/tests, while others likely need markup changes. [ASSUMED]
   - Recommendation: planner should create explicit audit tasks with pass/fix outcomes, not a vague sweep task. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit, Phoenix compilation | yes | 1.19.5 | none needed. [VERIFIED: repo] |
| Erlang/OTP | Elixir runtime | yes | 28 | none needed. [VERIFIED: repo] |
| Mix | test and verification aliases | yes | 1.19.5 | none needed. [VERIFIED: repo] |
| Phoenix LiveView | form behavior | yes | 1.1.28 | no new dependency; use existing. [VERIFIED: repo] |
| Phoenix.HTML | form fields | yes | 4.3.0 | no new dependency; use existing. [VERIFIED: repo] |
| Node.js | Playwright runner | yes | v22.14.0 | none needed for browser tests. [VERIFIED: repo] |
| npm | Playwright command runner | yes | 11.1.0 | none needed. [VERIFIED: repo] |
| Playwright | structural browser tests | yes | 1.59.1 | use ExUnit/conformance for non-browser checks, but focus persistence needs browser coverage. [VERIFIED: repo] |

**Missing dependencies with no fallback:** none. [VERIFIED: repo]  
**Missing dependencies with fallback:** none. [VERIFIED: repo]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit / Phoenix.LiveViewTest plus Playwright 1.59.1. [VERIFIED: repo] |
| Config file | `mailglass_admin/test/test_helper.exs`, `mailglass_admin/playwright.config.cjs`, `mailglass_admin/package.json`, and `mailglass_admin/scripts/check-conformance.sh`. [VERIFIED: repo] |
| Quick run command | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` [VERIFIED: repo] |
| Full suite command | `cd mailglass_admin && mix verify.preview && ./scripts/check-conformance.sh && npm run test:operator-browser` [VERIFIED: repo] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FORM-01 | No duplicate operator/inbound filter label/control markup remains; shared primitives exist in `MailglassAdmin.Components`. | component + conformance | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors && ./scripts/check-conformance.sh` | yes, extend files. [VERIFIED: repo] |
| FORM-01 | Operator and inbound filter forms still submit URL-backed filters. | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | yes, extend files. [VERIFIED: repo] |
| FORM-02 | Each filter primitive renders visible explicit label, connected help/error text, `aria-describedby`, and `aria-invalid` when invalid. | component | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors` | yes, add cases. [VERIFIED: repo] |
| FORM-02 | Invalid normalized-away filters surface recovery text without changing data trust boundary. | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | yes, add cases. [VERIFIED: repo] |
| FORM-02 | Validation state has text/programmatic indicators and does not rely on color alone. | component + Playwright structural | `cd mailglass_admin && npm run test:operator-browser` | yes, extend `e2e/structural.spec.js`. [VERIFIED: repo] |
| FORM-03 | Disabled and read-only/display-only states are visually and programmatically distinct. | component + Playwright structural | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors && npm run test:operator-browser` | yes, extend files. [VERIFIED: repo] |
| FORM-03 | Focus remains on the same control across ordinary `phx-change` and `push_patch` filter updates. | Playwright structural | `cd mailglass_admin && npm run test:operator-browser` | yes, extend `e2e/structural.spec.js`. [VERIFIED: repo] |
| FORM-02/03 | Preview assigns controls and replay radios are updated or explicitly certified. | LiveView/component + Playwright structural | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/inbound/components_test.exs --warnings-as-errors && npm run test:operator-browser` | yes, extend files. [VERIFIED: repo] |

### Sampling Rate

- **Per task commit:** run the narrow ExUnit file touched plus `cd mailglass_admin && ./scripts/check-conformance.sh` when markup/primitive files change. [VERIFIED: repo]
- **Per wave merge:** run `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/preview_live_test.exs --warnings-as-errors` and `cd mailglass_admin && npm run test:operator-browser`. [VERIFIED: repo]
- **Phase gate:** run `cd mailglass_admin && mix verify.preview && ./scripts/check-conformance.sh && npm run test:operator-browser`. [VERIFIED: repo]

### Wave 0 Gaps

- [ ] `mailglass_admin/test/mailglass_admin/components_test.exs` - add `filter_field/1` and `filter_section/1` contract tests for label/help/error/invalid/disabled/readonly states. [VERIFIED: repo]
- [ ] `mailglass_admin/e2e/structural.spec.js` - add form gallery state coverage and focus-persistence checks across `phx-change`/`push_patch`. [VERIFIED: repo]
- [ ] `mailglass_admin/scripts/check-conformance.sh` - add FORM-01 duplicate-filter-markup guard. [VERIFIED: repo]
- [ ] `mailglass_admin/test/mailglass_admin/operator_live_test.exs` and `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - add invalid-param recovery assertions. [VERIFIED: repo]
- [ ] `mailglass_admin/test/mailglass_admin/preview_live_test.exs` and replay-related tests - certify or update Preview assigns controls and replay target radios. [VERIFIED: repo]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | This phase does not change authentication flows. [VERIFIED: repo] |
| V3 Session Management | no | This phase does not change session management. [VERIFIED: repo] |
| V4 Access Control | yes | Preserve existing tenant/data trust boundary while changing filter UI and recovery copy. [VERIFIED: repo] |
| V5 Input Validation | yes | Keep allowlists and integer parsing for filter params; render rejected values as recovery errors instead of trusting them. [VERIFIED: repo] |
| V6 Cryptography | no | This phase does not change cryptography. [VERIFIED: repo] |

### Known Threat Patterns for Phoenix LiveView Form Filters

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| URL/form param tampering for enum and window filters | Tampering | Allowlist enum values and parse positive integer windows before query/read-model use; display recovery text for rejected values. [VERIFIED: repo] |
| Tenant filter widening data visibility | Information Disclosure | Do not change the existing tenant/data trust boundary while adding recovery copy; keep tenant-scoped tests green. [VERIFIED: repo] |
| Disabled-looking but operable controls | Spoofing / UX integrity | Use real `disabled` only for unavailable controls and assert programmatic disabled state in Playwright. [VERIFIED: repo] |
| Color-only error/selected state | Information Disclosure / Accessibility failure | Pair color with visible text, programmatic state, and/or iconography. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html] |
| Focus loss during filter patches | Denial of Service / UX integrity | Preserve DOM identity and assert active element after ordinary LiveView patches. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html#javascript-client-specifics] |

## Sources

### Primary (HIGH confidence)

- `.planning/STATE.md` - current v1.13 scope, dependency, and Phase 110 carry-forward decisions. [VERIFIED: repo]
- `.planning/ROADMAP.md` - Phase 111 goal and success criteria. [VERIFIED: repo]
- `.planning/REQUIREMENTS.md` - FORM-01, FORM-02, FORM-03 and milestone scope locks. [VERIFIED: repo]
- `.planning/phases/111-forms/111-CONTEXT.md` - locked decisions, discretion, deferred work, and canonical refs. [VERIFIED: repo]
- `mailglass_admin/lib/mailglass_admin/components.ex` - existing shared primitive home. [VERIFIED: repo]
- `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex` and `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex` - divergent filter form implementations. [VERIFIED: repo]
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` and `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - form integration, normalization, and patch behavior. [VERIFIED: repo]
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` - current gallery specimen path. [VERIFIED: repo]
- `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` and `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` - non-filter form controls requiring audit/certification. [VERIFIED: repo]
- `mailglass_admin/e2e/structural.spec.js` and `mailglass_admin/scripts/check-conformance.sh` - existing validation machinery. [VERIFIED: repo]
- Phoenix LiveView 1.1.28 form bindings - `https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html`. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html]
- Phoenix LiveView 1.1.28 live navigation - `https://hexdocs.pm/phoenix_live_view/1.1.28/live-navigation.html`. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/live-navigation.html]
- Phoenix LiveView 1.1.28 JS helpers - `https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.JS.html`. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.JS.html]
- Phoenix.HTML.Form 4.3.0 - `https://hexdocs.pm/phoenix_html/4.3.0/Phoenix.HTML.Form.html`. [CITED: https://hexdocs.pm/phoenix_html/4.3.0/Phoenix.HTML.Form.html]
- WAI form labels/instructions/validation tutorials and WCAG 2.2 understanding docs. [CITED: https://www.w3.org/WAI/tutorials/forms/labels/] [CITED: https://www.w3.org/WAI/tutorials/forms/instructions/] [CITED: https://www.w3.org/WAI/tutorials/forms/validation/] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/error-identification.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html]
- WAI-ARIA 1.2 states/properties for `aria-invalid`, `aria-describedby`, and `aria-errormessage`. [CITED: https://www.w3.org/TR/wai-aria-1.2/#aria-invalid] [CITED: https://www.w3.org/TR/wai-aria-1.2/#aria-describedby] [CITED: https://www.w3.org/TR/wai-aria-1.2/#aria-errormessage]
- WHATWG HTML form control infrastructure, input readonly, placeholder, and select element docs. [CITED: https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#attr-fe-disabled] [CITED: https://html.spec.whatwg.org/multipage/input.html#attr-input-readonly] [CITED: https://html.spec.whatwg.org/multipage/input.html#attr-input-placeholder] [CITED: https://html.spec.whatwg.org/multipage/form-elements.html#the-select-element]

### Secondary (MEDIUM confidence)

- None; implementation recommendations are based on repository inspection and official docs. [VERIFIED: repo]

### Tertiary (LOW confidence)

- Assumptions in the Open Questions section only. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were read from installed dependencies and local tool commands. [VERIFIED: repo]
- Architecture: HIGH - target ownership and files are locked by Phase 111 context and confirmed in source. [VERIFIED: repo]
- Pitfalls: HIGH - current gaps were found in source and mapped to official LiveView/WAI/WCAG/HTML behavior. [VERIFIED: repo]

**Research date:** 2026-06-19  
**Valid until:** 2026-07-19 for repo-local architecture; re-check package/tool versions before implementation if dependency files change. [ASSUMED]
