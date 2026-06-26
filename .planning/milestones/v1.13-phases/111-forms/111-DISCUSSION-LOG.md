# Phase 111: Forms - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-19
**Phase:** 111-forms
**Mode:** assumptions
**Areas analyzed:** Shared Primitive Ownership, Form Surface Scope, Accessibility And Recovery
Contract, State And Patch Verification

## Assumptions Presented

### Shared Primitive Ownership

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| `filter_field` / `filter_section` belong in `MailglassAdmin.Components`, with operator, inbound, and gallery consuming the same public primitives instead of retaining separate `FiltersForm.fields` markup. | Confident | `.planning/phases/110-primitives/110-CONTEXT.md`; `.planning/ROADMAP.md`; `mailglass_admin/lib/mailglass_admin/components.ex`; `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex`; `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex`; `.planning/research/v1.13/ARCHITECTURE.md` |

### Form Surface Scope

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| FORM-02/FORM-03 apply to admin/demo form controls in `mailglass_admin`, with filter forms as the mandatory extraction target and existing non-filter controls audited or explicitly certified. | Likely | `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`; `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex`; `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` |

### Accessibility And Recovery Contract

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Shared primitives should make label, help, error, and validation metadata explicit at the control level, rather than relying on placeholder text, wrapper-only labels, or silent normalization. | Likely, raised to High after research | `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex`; `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex`; `mailglass_admin/lib/mailglass_admin/operator_live.ex`; `mailglass_admin/lib/mailglass_admin/inbound_live.ex`; WHATWG HTML and WAI-ARIA references |

### State And Patch Verification

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Disabled, read-only, focus, and post-patch behavior should be verified through existing gallery/Playwright/conformance machinery, not pixel diffs or new runtime dependencies. | Likely, raised to High after research | `.planning/phases/109-foundations-gate-tightening/109-CONTEXT.md`; `.planning/phases/110-primitives/110-CONTEXT.md`; `mailglass_admin/e2e/structural.spec.js`; Phoenix LiveView 1.1.28 docs |

## Corrections Made

No corrections - all assumptions confirmed.

## External Research

- Phoenix LiveView 1.1 focus retention: `push_patch` updates the current LiveView and invokes
  `handle_params/3` without remounting; only a minimal diff is sent. LiveView treats the
  JavaScript client as the source of truth for focused input values and restores the last focused
  input after submit unless another input has received focus. Use stable ids/names/types for
  ordinary filter patches; reserve `JS.focus*` helpers for intentional element removal/recreation.
  Source: `https://hexdocs.pm/phoenix_live_view/1.1.28/form-bindings.html#javascript-client-specifics`,
  `https://hexdocs.pm/phoenix_live_view/1.1.28/live-navigation.html`,
  `https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.JS.html`.

- Read-only equivalents for unsupported controls: native `readonly` is text-control-only; it does
  not apply to controls such as checkboxes, buttons, or selects. Disabled controls are a different
  semantic state: they generally do not function as controls and are not submitted. For read-only
  non-text form values, use a non-editable display and a hidden input if submission is required.
  Source: `https://html.spec.whatwg.org/multipage/input.html#attr-input-readonly`,
  `https://html.spec.whatwg.org/multipage/form-elements.html#the-select-element`,
  `https://www.w3.org/TR/wai-aria-1.2/#aria-readonly`.
