# Phase 100: Preview Surface - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-15
**Phase:** 100-preview-surface
**Mode:** assumptions
**Areas analyzed:** Scope / Route Contract, Dark-Mode Model, Responsive IA / Groups, Preview Copy / Empty / Touch States, Verification

## Assumptions Presented

### Scope / Route Contract

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Build on the existing `/dev/mail` `MailglassAdmin.PreviewLive` and preview components. Do not add a new route, auth surface, product capability, or core email-template behavior. | Confident | `.planning/ROADMAP.md` Phase 100; `mailglass_admin/lib/mailglass_admin/router.ex`; `mailglass_admin/lib/mailglass_admin/preview_live.ex`; Phase 97 gallery route already settled. |

### Dark-Mode Model

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Treat `?theme=dark|light` as the admin chrome theme for Preview, consistent with Operator and Inbound. Separate it from any previewed-message/frame theme; fix root/layout and Preview wrapper behavior so explicit dark mode and OS dark preference are not forced back to light. | Likely | `mailglass_admin/lib/mailglass_admin/preview_live.ex` currently assigns `dark_chrome: false` on mount and only parses theme on scenario routes; `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` forces light without a root assign; `DARK-LD-06`; `DARK-LD-08`; `mailglass_admin/scripts/ui-audit.sh` captures `/dev/mail/?theme=dark`. |

### Responsive IA / Groups

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep the Preview sidebar's native `<details>/<summary>` hierarchy, but make the Preview surface usable at 390px by adding mobile-accessible Mailables navigation instead of leaving the sidebar desktop-only. Use stable `data-testid` hooks for Preview groups. | Confident | `IA-LD-08`; `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex`; `mailglass_admin/lib/mailglass_admin/preview_live.ex` hides the sidebar with `hidden md:block`; Phases 98 and 99 established responsive group/test patterns. |

### Preview Copy / Empty / Touch States

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Apply the preview-specific Phase 96 copy and a11y fixes now: `Message`, `Mailable`, `Preview the first Mailable`, and keyboard-focusable index actions. Add or verify 44px touch targets on Preview header/theme and assigns-form actions; keep the broader global copy sweep for Phase 101. | Likely | `COPY-LD-04..06`; `MOTION-LD-12`; `IA-LD-07`; `GAP-02`; `mailglass_admin/lib/mailglass_admin/preview_live.ex` still contains older copy; `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` and Preview header theme button still use `btn-sm` without explicit `min-h-11`. |

### Verification

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Extend existing ExUnit + Playwright lanes instead of creating a new harness: add real Preview scenario coverage using fixture routes, cover light/dark at 390/768/1440, assert accessibility/contrast/touch targets, update `ui-audit.sh`, then rebuild and commit the CSS bundle. | Confident | `mailglass_admin/test/mailglass_admin/preview_live_test.exs`; `mailglass_admin/test/support/endpoint_case.ex`; `mailglass_admin/e2e/structural.spec.js`; `mailglass_admin/dev/mailglass_admin/preview/capture_matrix.ex`; `mailglass_admin/dev/mailglass_admin/preview/capture_state.ex`; `mailglass_admin/mix.exs` `verify.preview` bundle-clean gate. |

## Corrections Made

No corrections - all assumptions confirmed.

## Methodology Applied

- **Decisive-By-Default Research Posture** - local code and Phase 96 locked decisions were enough to recommend a coherent default without external research.
- **Recommendation-First Synthesis** - surfaced a single implementation direction: existing Preview surface, URL-state dark chrome, mobile-reachable native sidebar IA, focused Preview copy/a11y, and existing verification lanes.

## External Research

No external research was performed. Phase 96 already produced the relevant external research dossiers and locked decisions.
