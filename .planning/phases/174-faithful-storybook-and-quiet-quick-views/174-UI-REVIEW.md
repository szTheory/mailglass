# Phase 174 — UI Review

**Audited:** 2026-10-27
**Baseline:** Abstract six-pillar standards; no UI-SPEC.md exists for this phase.
**Candidate:** fbf7d791f4f489db8a5d344455a33f0942a434d4
**Screenshots:** Reviewed retained CI captures under reference/demo_app/tmp/demo_browser_evidence/ci/40491221303-attempt-1/phase174/warm/. No new screenshots were captured.
**Interaction captures:** off (workflow.ui_interaction_capture is false). Interaction assessment below uses source and retained browser receipts; no interaction state is represented as a screenshot.

## Assessment Summary

The retained Delivery and Inbound quick views show a clear subject and outcome, with named navigation controls and a restrained detail hierarchy in the sampled light and dark views. Narrow captures wrap long content without visible horizontal spill; the wide Inbound capture keeps the panel readable. The retained connected and fidelity receipts support the planned route, focus, theme, font, and target-size behavior.

One low-priority review-surface issue is visible: the Storybook review-theme control crowds the top of the narrow iframe. No production task-completion blocker was found in the inspected evidence. This is a bounded review of synthetic Chromium captures and source; it is not an aesthetic score, cross-browser/device or zoom certification, or owner approval.

## Priority Fixes

1. **INFO — Give the Storybook review-theme control more room at narrow widths.** Its fixed top-left fieldset sits immediately above the quick-view heading in the 320px boundary capture. Reserve a toolbar row or move the control outside the component canvas so reviewers can distinguish the Storybook chrome from the quick view.

No additional priority fixes were supported by the inspected evidence.

## Pillar Assessments

### Pillar 1: Copywriting

The component uses task-specific control names and actions: “Previous delivery,” “Next delivery,” “Previous inbound record,” “Close quick view,” and “Open full detail” (operator/quick_view.ex:71-89, 169-175; inbound/quick_view.ex:64-85, 155-162). Error copy names the unavailable record and its Account context; Delivery exposes “Retry details” for its temporary-unavailable branch (operator/quick_view.ex:106-113, 229-240; inbound/quick_view.ex:205-214). No generic Submit, OK, or Cancel labels appear in these quick-view surfaces. No copy defect was found.

### Pillar 2: Visuals

The subject and outcome badge lead the panel, followed by recipient/time and scoped Account/provider or mailbox information. Navigation position and Close remain grouped in the header. This hierarchy is visible in the retained delivery-light.png, delivery-dark.png, delivery-320-boundary-dark.png, and inbound-1440-boundary-dark.png captures.

**INFO — Review chrome crowding:** Both retained stories place the review-theme fieldset at fixed top/left coordinates with a high stacking order (delivery.story.exs:12-19; inbound.story.exs:12-19). The narrow capture shows it close to the quick-view heading. This finding is limited to Storybook review chrome; the sampled quick-view content remains visible and usable.

### Pillar 3: Color

The sampled light and dark views retain the Ink/Paper surfaces, subtle borders, and a focused outcome color. The quick-view components use semantic theme classes such as base-content, base-300, primary, error, and secondary rather than adding a second product palette (operator/quick_view.ex:56, 101; inbound/quick_view.ex:49, 94). The shared stylesheet maps these roles to the brand tokens and defines separate light/dark values (mailglass_admin/assets/css/app.css:28-50, 66-87).

**INFO — Storybook shadow is a literal:** The reviewer-only fieldset sets its shadow with a hard-coded Ink RGB value rather than a shared shadow token (delivery.story.exs:13; inbound.story.exs:13). The hue is on-brand, but routing it through an existing shadow token would keep review chrome on the same token source.

**INFO — Contrast evidence remains incomplete:** The cold and warm selected Axe reports each retain 50 incomplete findings. Their triage and the zero-violation, zero-unapproved, zero-untriaged results do not convert those incomplete machine checks into passes. This audit makes no blanket contrast-compliance claim.

### Pillar 4: Typography

The rendered hierarchy separates the bold subject, compact field labels, normal body copy, and monospaced technical identifiers. The component uses shared typography roles, and the stylesheet declares Inter, Inter Tight, and IBM Plex Mono at weights 400 and 700 (components.ex:563-579; app.css:146-186). The retained fidelity receipts record successful responses and loaded faces for all six files across the two stories; the narrow capture shows long subject and timestamp text wrapping instead of clipping. No typography defect was found in the sampled cases.

### Pillar 5: Spacing

The panel uses the shared spacing tokens: p-lg, gap-sm, mt-md, and space-y-md. The production panel becomes a bottom sheet on compact screens and a right-side panel capped at 42rem from the 768px breakpoint (app.css:322-361). The quick-view controls retain minimum 44px dimensions (operator/quick_view.ex:89, 195, 210; inbound/quick_view.ex:82, 184, 198); the phase’s geometry checks cover the selected connected states. The sampled 320px boundary captures wrap vertically without visible horizontal spill. No product-layout spacing defect was found.

### Pillar 6: Experience Design

Delivery boundaries render as inert spans with screen-reader text and no link/button role; Inbound boundaries remain native disabled buttons (operator/quick_view.ex:189-200; inbound/quick_view.ex:176-188). This is the intentional distinction recorded by the phase. The selected connected checks cover keyboard traversal, Escape, focus return, Account/filter/selection preservation, and truthful empty/unavailable states. The Delivery route renders from its existing row projection; explicit error branches provide contextual recovery copy.

The retained exact-head hosted run 40491221303 completed all 26 jobs successfully. The strict evidence checker passed for cold and warm conditions, each with 148/148 selected cases (98 Demo, 6 hooks, 26 fidelity, 18 Axe). This supports the tested flows; it does not replace the bounded visual review above. Interaction screenshots were off, so no focus-ring appearance or post-interaction visual state is claimed from captures.

## Evidence Boundaries

- The quick-view visual captures are synthetic Chromium renderings from the selected candidate. The responsive receipt covers 320, 375, 768, 1280, and 1440 CSS-pixel landmarks; it is not a full browser/device Cartesian grid.
- The Axe reports have 50 incomplete findings per condition. They were triaged against the independent before report, but remain incomplete, not passing results.
- The descriptorless transparency prohibition remains flagged-unverified. No check descriptor exists in the evidence contract; this review does not invent one or infer owner approval.
- The serif StatCard/catalogue work, real browser zoom, and final STORY-07 reconciliation belong to Phase 178 and are outside this phase’s acceptance.
- The candidate review and its CI evidence are not a merge, release, deployment, or owner-approval decision.

## Files Audited

- mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
- mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex
- mailglass_admin/lib/mailglass_admin/components.ex
- mailglass_admin/assets/css/app.css
- reference/demo_app/storybook/quick_views/delivery.story.exs
- reference/demo_app/storybook/quick_views/inbound.story.exs
- reference/demo_app/dev/mailglass_demo_web/storybook.ex
- reference/demo_app/assets/e2e/quick-views.spec.js
- reference/demo_app/assets/e2e/storybook-fidelity.spec.js
- reference/demo_app/assets/e2e/storybook-hooks.spec.js
- mailglass_admin/docs/phase174-review.md
- reference/demo_app/tmp/demo_browser_evidence/ci/40491221303-attempt-1/phase174/{cold,warm}/{execution,fidelity,hooks,axe}.json and retained warm PNG captures
