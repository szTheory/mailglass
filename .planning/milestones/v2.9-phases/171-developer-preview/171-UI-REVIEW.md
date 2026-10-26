# Phase 171 — UI Review

**Audited:** 2026-10-09  
**Baseline:** Approved [171-UI-SPEC.md](171-UI-SPEC.md), inherited Phase 168 interface contract, and current Mailglass brandbook  
**Screenshots:** Not captured by this audit: localhost:8080 responded, but the CLI capture failed at desktop, mobile, and tablet sizes. Existing Chromium evidence in [171-RENDERED-REVIEW.md](171-RENDERED-REVIEW.md) and its four temporary screenshots was inspected separately. That evidence is limited to browser preview rendering and does not certify recipient-client behavior.  
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | The empty heading uses lowercase “mailables” where the contract specifies the domain noun “Mailables.” |
| 2. Visuals | 3/4 | The workbench is clearly ordered, but `break-all` splits “HappyMailer” inside the active identity at 390 px. |
| 3. Color | 2/4 | Accent is used for the selected frame-width button and picker eyebrow labels outside the contract’s reserved accent roles. |
| 4. Typography | 4/4 | UI text uses the specified 14/16/20 px roles and only 400/700 weights. |
| 5. Spacing | 3/4 | The layout is orderly, but `p-3`/`px-3`/`px-5` use unlisted 12/20 px values instead of the named spacing tokens. |
| 6. Experience Design | 2/4 | Assign inputs render at 32 px and the checkbox at 20 px, below the required 44 px interaction target. |

**Overall: 17/24**

---

## Top 3 Priority Fixes

1. **Raise assign-field hit areas to at least 44 px** — short inputs and the 20 px checkbox are harder to operate by touch and do not meet the UI contract — add `min-h-11` to the text/date fields and a 44 px clickable checkbox wrapper.
2. **Keep accent to the approved roles** — the 768 px selection is shown as a filled primary action and picker eyebrow labels use accent text — use the semantic selected surface for the width toggle and neutral/muted text for those labels.
3. **Avoid breaking the active Mailable name inside words** — at 390 px, “HappyMailer” wraps as “HappyMaile” / “r” — allow breaks at namespace separators and underscores first, with emergency breaking only for unbroken segments.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING** — [preview_live.ex:555](../../../mailglass_admin/lib/mailglass_admin/preview_live.ex:555) says “No mailables discovered yet.” The approved contract specifies “No Mailables discovered yet.” Preserve the product noun’s capitalization in this user-facing empty state.
- **Evidence supporting the score:** The page intro, renderer labels, Raw-envelope warning, preview-header description, and browser-only limitation copy accurately distinguish Renderer output from provider/recipient output. Error recovery copy names the correction route, and the two empty/setup states are distinct and actionable.

### Pillar 2: Visuals (3/4)

- **WARNING** — [sidebar.ex:114](../../../mailglass_admin/lib/mailglass_admin/preview/sidebar.ex:114) applies `break-all` to the active Mailable identity. In the supplied 390 px light capture, `MailglassAdmin.Fixtures.HappyMailer` breaks within its final word (“HappyMaile” / “r”). Keep the namespace and scenario visible, but wrap at punctuation/underscores before breaking a long token.
- **Evidence supporting the score:** The stored 390 px, 1024 px, and zoomed Chromium captures show a clear page title, visible active scenario, secondary framing controls, renderer output as the work area, and the assigns editor below it. The wide capture keeps the active identity on one line. These are preview-browser observations only.

### Pillar 3: Color (2/4)

- **WARNING** — The contract reserves accent for the active output-tab cue, a real failure retry, and keyboard focus. The selected width uses `btn-primary` ([device_frame.ex:63](../../../mailglass_admin/lib/mailglass_admin/preview/device_frame.ex:63)); accent also colors the “Email previews”/“Email preview” eyebrows ([sidebar.ex:52](../../../mailglass_admin/lib/mailglass_admin/preview/sidebar.ex:52), [sidebar.ex:111](../../../mailglass_admin/lib/mailglass_admin/preview/sidebar.ex:111)) and discovery/setup decoration ([preview_live.ex:561](../../../mailglass_admin/lib/mailglass_admin/preview_live.ex:561), [preview_live.ex:572](../../../mailglass_admin/lib/mailglass_admin/preview_live.ex:572)). Use the selected-surface token for the width state and neutral text/decorative tokens for labels and setup marks.
- **Evidence supporting the score:** Semantic light/dark surfaces and borders dominate the supplied captures, and focus/active-tab cues remain legible. The accent-role drift is notable and occurs across multiple controls and labels, though it does not overwhelm the 60/30/10 surface balance.

### Pillar 4: Typography (4/4)

- **PASS evidence:** The audited preview components use `text-label` (14 px), `text-body` (16 px), and `text-heading` (20 px); the 28 px display role is unused. Weight classes are limited to `font-normal` (400) and `font-bold` (700). These match the Phase 171 scale, installed weights, and the legible hierarchy visible in the Chromium captures.

### Pillar 5: Spacing (3/4)

- **WARNING** — Several utilities use values absent from the named scale: `px-3`/`p-3` resolve to 12 px in [sidebar.ex:271](../../../mailglass_admin/lib/mailglass_admin/preview/sidebar.ex:271) and [assigns_form.ex:277](../../../mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex:277); `px-5` resolves to 20 px in [preview_live.ex:474](../../../mailglass_admin/lib/mailglass_admin/preview_live.ex:474). They remain on the 4 px grid, but are inconsistent with the specified named spacing tokens. Prefer named tokens or document a control-specific exception.
- **Evidence supporting the score:** Most structure uses `xs`/`sm`/`md`/`lg` tokens, narrow controls wrap, and the reviewed Chromium states show no page-level overflow at 390 px or at the tested 320 CSS px effective width under 200% zoom. The current CLI screenshot attempt failed, so the visual claim relies on the separately recorded phase evidence.

### Pillar 6: Experience Design (2/4)

- **WARNING** — [assigns_form.ex:91](../../../mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex:91) and the numeric/date fields use `input-sm` without a 44 px minimum; the served stylesheet sizes this control at 32 px. The checkbox at [assigns_form.ex:160](../../../mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex:160) uses `checkbox-sm` (20 px) without a 44 px clickable wrapper. Increase the hit areas while retaining the compact visual grouping.
- **Evidence supporting the score:** Source and recorded connected Chromium evidence cover live edits, preserved invalid drafts, stale-output labeling, render retry, four manual-activation tabs, keyboard scrolling, empty HTML, independent theme/backdrop/width state, and reduced motion. The required 44 px target-size contract is not met for the assign editor. Interaction capture was off for this audit, so these are code-derived checks plus the supplied Phase 171 evidence, not new interaction captures.

---

## Files Audited

- `.planning/phases/171-developer-preview/171-UI-SPEC.md`
- `.planning/phases/171-developer-preview/171-CONTEXT.md`
- `.planning/phases/171-developer-preview/171-01-SUMMARY.md` through `171-04-SUMMARY.md`
- `.planning/phases/171-developer-preview/171-01-PLAN.md` through `171-04-PLAN.md`
- `.planning/phases/171-developer-preview/171-RENDERED-REVIEW.md`
- `brandbook/brand-book.md`, `brandbook/copy/microcopy.md`, `brandbook/tokens.css`
- `mailglass_admin/docs/design-system.md`
- `mailglass_admin/lib/mailglass_admin/preview_live.ex`
- `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex`
- `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex`
- `mailglass_admin/lib/mailglass_admin/preview/tabs.ex`
- `mailglass_admin/lib/mailglass_admin/preview/device_frame.ex`
- `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`
- `mailglass_admin/priv/static/app.css`
- `mailglass_admin/tmp/mailglass_admin_preview_capture/phase171-390-light.png`
- `mailglass_admin/tmp/mailglass_admin_preview_capture/phase171-390-system-dark.png`
- `mailglass_admin/tmp/mailglass_admin_preview_capture/phase171-1024-dark.png`
- `mailglass_admin/tmp/mailglass_admin_preview_capture/phase171-320-actual-200-percent.png`
