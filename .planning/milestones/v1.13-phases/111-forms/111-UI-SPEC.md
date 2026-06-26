---
phase: 111
slug: forms
status: draft
shadcn_initialized: false
preset: none
created: 2026-06-19
---

# Phase 111 - UI Design Contract

> Visual and interaction contract for Phase 111: Forms. Generated retroactively for the UI safety gate during `/gsd-execute-phase 111`.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none - in-house Phoenix.Component + Tailwind v4 standalone + daisyUI 5 token system |
| Preset | not applicable |
| Component library | Phoenix.Component function components; daisyUI semantic utilities; no Radix/Base UI/shadcn |
| Icon library | Vendored Heroicons via `mailglass_admin/assets/vendor/heroicons-inline.js` and `<Components.icon name="hero-*">` |
| Font | Inter for UI/body, Inter Tight for headings/display, IBM Plex Mono for code/IDs |

Source notes: `components.json` is absent and this is a Phoenix LiveView stack, so the shadcn initialization gate is not applicable. Phase 111 must not initialize shadcn, add a UI registry block, add a runtime dependency, introduce a second styling system, or add screenshot/pixel-diff tooling.

Visual hierarchy: the first attention anchor on filter surfaces is the section legend plus the first actionable control row, on Preview assigns it is the input grid, and on replay modals it is the confirmation target/content block before any secondary dismissal action.

---

## Spacing Scale

Declared values from `mailglass_admin/assets/css/app.css`:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, error icon/text gap, compact inline pairs |
| sm | 8px | Field gaps, button groups, replay radio card internals |
| md | 16px | Default form/card padding, filter section gap, preview assigns form padding |
| lg | 24px | Major surface gaps around filter panels and detail areas |
| xl | 32px | Large specimen groups only |
| 2xl | 48px | Page-level section breaks only |
| 3xl | 64px | Gallery/page-level spacing only |

Exceptions: no visual-spacing exceptions. Normal interactive controls use the 44px floor through `min-h-11`; controls that can collapse horizontally also need a width floor such as `min-w-11`. Native checkbox/radio glyphs may be visually smaller, but the clickable label/card area or containing row must preserve a 44px target. No off-grid values, arbitrary spacing utilities, raw pixel style attributes, or dynamic class construction are permitted for Phase 111 form surfaces.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Label | 12px | 700 | 1.5 |
| Body | 14px | 400 | 1.5 |
| Heading | 20px | 700 | 1.2 |
| Display | 28px | 700 | 1.2 |

Only weights 400 and 700 are permitted. `font-medium` and `font-semibold` remain banned because loaded font files do not provide 500/600. Form surfaces must use `text-label`, `text-body`, `text-heading`, or `text-display`; raw Tailwind type utilities such as `text-sm`, `text-lg`, and `text-xl` are violations.

Form typography rules:

| Surface | Type Contract |
|---------|---------------|
| `filter_section/1` | legend `text-label font-bold uppercase text-secondary`; description `text-body text-secondary` |
| `filter_field/1` | label `text-label font-bold text-base-content`; help `text-label text-secondary`; error `text-label text-error` with bold `Action needed:` lead-in |
| Preview assigns | field labels `text-label font-bold`; help `text-label text-secondary`; code/JSON values may use IBM Plex Mono through existing mono/font-mono treatment |
| Replay modal targets | target label `text-body font-bold`; target descriptions and IDs `text-label`; modal title `text-heading font-bold` |

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Light: Paper `#F8FBFD` via `--color-base-100`; Dark/System-dark: Ink `#0D1B2A` via `--color-base-100` | Page background, modal panel background, default form background |
| Secondary (30%) | Light: White `#FFFFFF` / Mist-edge `#C7DCE5` via `--color-base-200/300`; Dark: Ink-raised `#152538` / Ink-edge `#315069` via `--color-base-200/300` | Filter panels, preview assigns panel, replay target cards, borders, read-only displays |
| Accent (10%) | Light: Glass `#277B96`; Dark/System-dark: Ice `#A6EAF2` via `--color-primary` / `--color-accent` | Focus ring, primary form action, current/selected controls where already established |
| Destructive | Light: Crimson `#B42318`; Dark: Crimson-bright `#E29089` via `--color-error` | Error text, invalid control state, replay confirmation action, selected replay target cue only because replay target selection precedes a destructive replay action |

Accent reserved for: `.mg-focus-ring`, `.btn-primary` form actions (`Open delivery`, `Open record`, `Render preview`), selected/active primitives inherited from Phase 110, and system-established focus emphasis. Accent is not a decorative border, default icon color, or generic hover color.

Validation and status color rules: invalid fields use semantic error color plus visible text and icon; selected replay targets use visible `Selected target` copy plus icon and color. Color alone is never sufficient for validation, selection, severity, or disabled/read-only meaning.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | Operator filters: `Open delivery`; Inbound filters: `Open record`; Preview assigns: `Render preview`; replay modal: `Confirm replay` |
| Secondary CTA | Filter forms: `Clear filters`; Preview assigns: `Reset assigns`; replay modal: `Dismiss replay` and `Close` |
| Empty state heading | Not introduced by Phase 111. Existing downstream empty states remain owned by later data-display/page phases. |
| Empty state body | Not introduced by Phase 111. Gallery empty form specimens may show blank controls, but must not invent product empty-state copy. |
| Error state | `Action needed: {field-specific recovery copy}` rendered inside the field error element. |
| Destructive confirmation | Operator replay and inbound replay: `Confirm replay`; dismissal is `Dismiss replay`; closing is `Close`. No additional destructive action is introduced. |

Field-level recovery copy is locked:

| Field | Copy |
|-------|------|
| Operator status | `Status was not applied. Choose a listed status.` |
| Operator event | `Event was not applied. Choose a listed event.` |
| Operator time window | `Time window was not applied. Choose a positive listed time window.` |
| Inbound mailbox outcome | `Mailbox outcome was not applied. Choose a listed outcome.` |
| Inbound time window | `Time window was not applied. Choose a positive listed time window.` |

Voice restrictions: `Oops`, `Whoops`, `Uh oh`, `Something went wrong`, placeholder-only labels, and silent invalid normalization are not allowed. Error copy must name the field problem and the next recovery action without echoing raw tenant data, recipient values, message bodies, or payloads.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable - no shadcn/components registry; Phoenix/Tailwind/daisyUI stack confirmed, `components.json` absent - 2026-06-19 |

No third-party UI registry blocks are approved for this phase.

---

## Phase Scope Contract

| Item | Contract |
|------|----------|
| Phase boundary | Form-control layer only: shared filter primitives, operator/inbound filter wrappers, Preview assigns controls, replay modal target controls, gallery specimens, conformance guard, and browser structural proof. |
| Out of scope | Tenant listing/auto-select, theme persistence/no-FOUC, navigation/pagination, table/card data-display transforms, rich stress-fixture cohort, axe JSON baseline, full ratchet re-score, recipient-facing email templates, brandbook token changes. |
| Public ownership | `filter_field/1` and `filter_section/1` live in `MailglassAdmin.Components` as the single shared admin form primitive implementation. |
| Wrapper rule | `MailglassAdmin.Operator.FiltersForm` and `MailglassAdmin.Inbound.FiltersForm` may remain only as thin composition wrappers. They must call `Components.filter_field/1` and `filter_section/1` and must not own duplicate label/control/help/error HEEx. |
| Bundle discipline | Any class-string change that affects compiled CSS must rebuild and commit `mailglass_admin/priv/static/app.css`; unbundled utilities are not allowed. |
| Proof discipline | Verification is component tests, LiveView tests, conformance grep, and Playwright structural assertions. No screenshots, `toHaveScreenshot`, Percy, Chromatic, BackstopJS, committed PNGs, or pixel-diff regression workflow. |

---

## Form Primitive Contracts

| Primitive | Required Shape | Required States | A11y Contract |
|-----------|----------------|-----------------|---------------|
| `filter_section/1` | Native `fieldset` with visible `legend`, optional description, tokenized grid gap, and slot-rendered fields | default section, section with description, operator wrapper section, inbound wrapper section | Grouping label must be visible and meaningful; do not replace with div-only wrappers when the fields are related |
| `filter_field/1` text/number | Visible `label for`, stable `id`, stable `name`, value from `Phoenix.HTML.FormField` metadata unless explicitly overridden, `input-sm min-h-11`, `mg-focus-ring` | empty, filled, disabled, native readonly, invalid, help-only, help+error | `aria-describedby` includes help and error IDs; `aria-invalid="true"` only when invalid; native `readonly` only for text/number/textarea |
| `filter_field/1` select | Visible label, stable select ID/name, prompt when needed, closed options, selected value from normalized form value | empty/prompt, filled, disabled, invalid, display-only readonly | Never use `readonly` on `select`; readonly select-style values render display-only text with `aria-readonly` and hidden input only when `submit_readonly` is true |
| `filter_field/1` textarea | Visible label, stable textarea ID/name, tokenized height/spacing, help/error wiring | editable, native readonly, disabled, invalid | Native `readonly` is valid; help/error IDs must remain stable |
| `filter_field/1` checkbox | Hidden false input plus native checkbox when editable; visible label remains associated by ID; min-height container | checked, unchecked, disabled, invalid, display-only readonly | Checkbox glyph is not the whole target; containing row/label must meet target-size proof |
| Invalid state | Existing control plus `role="alert"` error text with `hero-exclamation-circle` and bold `Action needed:` prefix | all invalid field types used by filters and gallery | Error state must be visible, programmatic, and non-color-only |
| Display-only readonly | Focusable read-only display row with `role="textbox"`, `aria-readonly="true"`, semantic border/surface, optional hidden input | readonly select, readonly checkbox, preview atom/unsupported values | Does not look disabled, does not expose an enabled control, and does not submit type-eroding hidden values unless explicitly required |

Implementation contract: default IDs/names/values derive from `Phoenix.HTML.FormField` metadata. Explicit `id`, `name`, and `value` overrides are allowed for gallery and certification surfaces. Ordinary LiveView filter patches must preserve form ID, control ID, name, type, and order.

---

## Filter Wrapper Contracts

| Surface | Form ID | Fields In Stable Order | Submit / Clear Copy | Contract |
|---------|---------|------------------------|---------------------|----------|
| Operator Deliveries | `operator-filters` | Tenant, Provider, Status, Event, Time window | `Open delivery` / `Clear filters` | Wrapped in the existing filter panel; every field rendered through `Components.filter_field/1`; invalid `status`, `event`, and `window_hours` render recovery copy; invalid submit does not `push_patch` |
| Inbound Records | `inbound-filters` | Tenant, Provider, Mailbox outcome, Time window, Search | `Open record` / `Clear filters` | Wrapped in the existing filter panel; every field rendered through `Components.filter_field/1`; invalid `outcome` and `window_hours` render recovery copy; invalid submit does not `push_patch` |

Filter wrapper visual contract:

- Filter panel surface uses `card rounded-box border border-base-300 bg-base-200` or equivalent semantic tokens.
- Mobile filter toggles remain visible controls with `min-h-11`; labels are text, not icon-only.
- Field layout may collapse to one column at narrow widths and expand at `md`/`xl`, but fields must not overflow or reorder unpredictably.
- `filter_errors` is a `%{"field" => "message"}` side map computed before normalization; raw invalid values must not reach read-model filters.
- Tenant/data trust boundaries remain unchanged; recovery UI is feedback only, not broader querying.

Focus contract: after ordinary `validate_filters` or valid `apply_filters`/`push_patch`, focus remains on the same focused control when the control still exists. Use LiveView `JS.focus*` only for intentional focus moves when an element is removed or recreated.

---

## Preview Assigns Contract

| Assign Value Type | Control Contract |
|-------------------|------------------|
| String | `input type="text"` with stable `assigns-{key}` ID, visible `label for`, `name="assigns[{key}]"`, and help connected by `aria-describedby` |
| Integer | `input type="number" step="1"` with stable ID/label/help wiring |
| Float | `input type="number" step="any"` with stable ID/label/help wiring |
| Boolean | Native checkbox plus hidden false input, stable ID, visible associated label, help connected by `aria-describedby` |
| DateTime | `input type="datetime-local"` with stable ID/label/help wiring |
| Date | `input type="date"` with stable ID/label/help wiring |
| Map / struct | `textarea` with stable ID/label/help wiring; mono text is allowed for inspected data |
| Atom / unsupported | Display-only row with `data-readonly-display` and `aria-readonly`; no fake disabled text input and no hidden submitted value unless PreviewLive explicitly needs it |

Preview form surface:

- The form keeps `data-testid="preview-assigns-form"` and `phx-change="assigns_changed"`.
- Buttons keep `Render preview` and `Reset assigns` with `min-h-11`.
- Existing `assigns_changed`, `render_preview`, and `reset_assigns` behavior must remain intact.
- Read-only display rows must be visually distinct from disabled controls and from editable inputs.

---

## Replay Modal Controls Contract

| Surface | Contract |
|---------|----------|
| Operator exact replay | Modal has `role="dialog"`, `aria-modal="true"`, stable `aria-labelledby="replay-modal-title"`; exact target renders a target card without unnecessary radio choices; `Confirm replay` is enabled for exact target |
| Operator ambiguous replay | Form ID `operator-replay-targets`; each candidate is a native radio named `webhook_event_id`; ID is `operator-replay-target-{sanitized_webhook_event_id}`; visible `label for` and description ID connect through `aria-describedby` |
| Operator selected target | Selected state renders visible `Selected target` text plus `hero-check-circle` and semantic color; border/background color alone is not sufficient |
| Operator unavailable replay | No enabled confirmation target; message starts with `Replay unavailable` and gives a reason without adding extra controls |
| Inbound replay | Single-target confirmation modal with `id="inbound-replay-modal"`, `role="dialog"`, `aria-modal="true"`, `aria-labelledby="inbound-replay-modal-title"`; no replay target radio group because inbound replay has no ambiguous target branch |

Button targets: `Close`, `Dismiss replay`, and `Confirm replay` must meet 44x44. Destructive replay confirmation uses `.btn-error`; no additional destructive pattern is introduced.

---

## Gallery And Browser Structural Proof

The dev gallery and browser tests certify the real public components, not copies.

| Requirement | Contract |
|-------------|----------|
| Gallery components | Add real `:filter_field` and `:filter_section` specimen branches that call `MailglassAdmin.Components.filter_field/1` and `filter_section/1` directly. |
| Gallery states | Required stable anchors: `gallery-filter_field-text-empty`, `gallery-filter_field-select-filled`, `gallery-filter_field-invalid`, `gallery-filter_field-disabled`, `gallery-filter_field-readonly-text`, `gallery-filter_field-readonly-select-display`, and `gallery-filter_section-section`. |
| Migrated wrappers | Existing `gallery-filters_form-empty` and `gallery-filters_form-filled` remain reachable and render migrated shared-primitive wrappers. Add an invalid wrapper state through an `errors` map. |
| Theme coverage | Form primitive and wrapper specimens render in light, dark, and system. System specimens omit explicit `data-theme`; do not fake system with `data-theme="system"`. |
| Viewport coverage | Structural tests cover 320px/390px through wide widths already used by the admin matrix. Controls must not overflow at 320px, labels/help/error must not overlap, and buttons remain usable. |
| Browser semantics | Playwright asserts explicit labels, help/error IDs, `aria-describedby`, `aria-invalid`, visible recovery copy, invalid non-color cue, disabled state, native readonly state, and display-only readonly state. |
| Focus persistence | Playwright records `document.activeElement.id` inside `operator-filters` and `inbound-filters`, applies ordinary filter patches through `Open delivery` / `Open record`, and asserts the same ID remains focused when the element remains present. |
| Preview/replay proof | Playwright asserts `preview-assigns-form` label/help wiring and operator replay target radio IDs, labels, descriptions, selected text, and inbound no-radio dialog contract. |

No pixel-diff requirement exists for Phase 111. Browser proof is DOM, computed style, target-size, focus, and accessibility structure only.

---

## Accessibility Contract

| Area | Contract |
|------|----------|
| WCAG target | Phase 111 targets WCAG 2.2 AA. Normal interactive controls are at least 44x44 in the compiled bundle; WCAG 2.2 SC 2.5.8 24x24 dense exceptions are not expected for forms. |
| Labels | Every authored form control has a visible label associated by `for`/`id`; wrapper-only labels and placeholder-as-label are not acceptable. |
| Instructions | Help and error text use stable IDs and are connected through `aria-describedby`; when both help and error exist, both IDs appear in the attribute. |
| Errors | Invalid controls expose `aria-invalid="true"`, visible recovery text, and a non-color cue. Error text uses `role="alert"` when rendered by `filter_field/1`. |
| Disabled | `disabled` means unavailable/inoperable and must be programmatically disabled and visually distinct; disabled must not be used as fake read-only. |
| Read-only | Native `readonly` only appears on supported text-like controls. Select/radio/checkbox-style read-only values render display-only rows with `aria-readonly`. |
| Focus | Use shared `mg-focus-ring` / `mg-focus-ring-inset`; focus must be visible in light/dark/system, not obscured, and preserved across ordinary LiveView patches. |
| Contrast | Text meets 4.5:1 AA; meaningful non-text indicators, borders, selected cues, focus indicators, and icons meet 3:1. Disabled inactive controls remain visibly disabled without masquerading as enabled controls. |
| Keyboard | All filters, preview controls, modal buttons, and replay radio choices are reachable and operable by keyboard. Modal Escape close behavior remains intact. |
| Motion | Existing Phase 109 motion constraints apply: transform/opacity only, ease-out, <=300ms, reduced motion snaps/neutralizes movement. Theme changes are not introduced here. |

---

## Light / Dark / System Contract

| Theme | Contract |
|-------|----------|
| Light | Uses `mailglass-light` semantic tokens; form panels, inputs, help text, invalid state, and focus ring pass contrast on Paper/White/Mist surfaces. |
| Dark | Uses `mailglass-dark` semantic tokens; invalid/error, focus, borders, and read-only displays remain readable against Ink/Ink-raised surfaces. |
| System | System remains absence of an explicit theme value and resolves through `prefersdark`; Phase 111 must not emit `data-theme="system"`, add localStorage/cookies, add `matchMedia`, or own no-FOUC behavior. |

Phase 111 browser proof must include light, dark, and system coverage for gallery form specimens and the changed real surfaces where the existing structural matrix supports it.

---

## Responsive Behavior Contract

| Width | Contract |
|-------|----------|
| 320-390px | Filter panels collapse to one column; mobile filter toggles are visible where already present; fields, labels, help, and error copy wrap without overlap; buttons wrap with `gap-sm` and retain 44px height. |
| 768px | Filter controls may use two-column layouts; focus order follows DOM order; labels remain near controls and descriptions remain connected. |
| 1440px+ | Wider layouts may distribute filters across more columns, but field order remains stable and no control becomes detached from its label/help/error. |

No form surface may introduce horizontal page overflow, clipped labels, hidden error text, or mobile-only inaccessible controls.

---

## Conformance And Gate Contracts

| Gate | Required Delta |
|------|----------------|
| FORM-DRIFT-GATE | `mailglass_admin/scripts/check-conformance.sh` fails if public `Components.filter_field/1` or `filter_section/1` disappear, if operator/inbound filter wrappers stop calling the shared primitives, or if duplicate native label/control markup returns to those wrapper files. |
| FOCUS-RING-GATE | Existing focus gate remains enforced: raw focus-ring idioms are rejected; form controls use shared focus utilities. |
| TYPE-GATE | Raw type utilities remain rejected; form surfaces use `text-label`, `text-body`, `text-heading`, and `text-display`. |
| ICON-EXISTS-GATE | `hero-exclamation-circle` and `hero-check-circle` must exist in the vendored Heroicon inventory; icons are never the only carrier of meaning. |
| TARGET-SIZE proof | Playwright verifies changed form buttons/controls meet 44px target expectations in the compiled bundle. |
| BROWSER-STRUCTURAL proof | Playwright verifies gallery form semantics, preview assigns labels/read-only display, replay radios/dialog labelling, and operator/inbound focus persistence. |
| NO-PIXEL-DIFF | No screenshot or pixel-diff assertion is required or allowed for this phase. |

Final Phase 111 gate remains:

```bash
cd mailglass_admin && mix verify.preview && ./scripts/check-conformance.sh && npm run test:operator-browser
```

---

## Source Traceability

| Contract Area | Source |
|---------------|--------|
| Phase goal and scope | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md` FORM-01..03 |
| Locked form decisions | `.planning/phases/111-forms/111-CONTEXT.md` D-01 through D-08 |
| Technical patterns | `.planning/phases/111-forms/111-RESEARCH.md` Standard Stack and Architecture Patterns |
| Primitive implementation outcome | `.planning/phases/111-forms/111-01-SUMMARY.md`; `mailglass_admin/lib/mailglass_admin/components.ex` |
| Wrapper/recovery outcome | `.planning/phases/111-forms/111-02-SUMMARY.md`; operator/inbound filter modules and LiveViews |
| Preview/replay outcome | `.planning/phases/111-forms/111-03-SUMMARY.md`; Preview assigns and replay modal modules |
| Remaining guard/browser proof | `.planning/phases/111-forms/111-04-PLAN.md`; `.planning/phases/111-forms/111-VALIDATION.md` |
| Token, color, typography, spacing baseline | `.planning/phases/110-primitives/110-UI-SPEC.md`; `mailglass_admin/assets/css/app.css`; `mailglass_admin/docs/design-system.md` |
| Project constraints | `CLAUDE.md`; `.planning/STATE.md`; v1.13 no-pixel-diff and zero-runtime-dependency scope locks |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
