# Phase 172 — UI Review

**Audited:** 2026-10-09  
**Baseline:** Phase 172 UI-SPEC.md and Mailglass brandbook  
**Screenshots:** Captured. Invoice preview crops are 375×600px (`invoice-preview-375.png`) and 320×600px (`invoice-preview-320.png`). Unsubscribe valid, invalid, and expired views are each captured at 1280×900px and 320×900px.  
**Interaction captures:** off (workflow.ui_interaction_capture is false)

This review covers browser-rendered generated email markup and the server-rendered unsubscribe pages. The invoice captures are cropped to the email iframe, so the preview shell no longer competes with the message. The former 320px filename mismatch is resolved: the image itself is 320px wide. These captures do not establish rendering in Gmail, Outlook, Apple Mail, or any delivered-email client, nor image-blocking or client dark-mode behavior.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | “Review invoice” is specific and stays on one line at 320px; unsubscribe copy remains state-specific and truthful. |
| 2. Visuals | 4/4 | Email-only crops show a clear heading, image, copy, and CTA hierarchy at both widths; unsubscribe pages have a single focal reading column. |
| 3. Color | 4/4 | Accent is limited to the primary action/link treatment; explicit invalid and expired state text accompanies the destructive color cue. |
| 4. Typography | 4/4 | The captured email and pages follow the contracted type sizes, weights, and safe font stacks. |
| 5. Spacing | 4/4 | The 16px image-to-copy spacing is visible in both invoice crops and matches the UI-SPEC body rhythm. |
| 6. Experience Design | 4/4 | The narrow CTA is visible and the browser check enforces at least 44×44px while capping height at 52px. |

**Overall: 24/24**

---

## Top Priority Fixes

No priority visual or copy defect was evident in the supplied browser captures. The E2E browser check now enforces the primary action's 44×44px minimum and 52px maximum height at the 320px email width.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- The primary invoice CTA is the scenario-specific `Review invoice`, not a generic label, at [component_mailer.ex](/Users/jon/projects/mailglass/reference/demo_app/lib/mailglass_demo_web/mailers/component_mailer.ex:53). It remains unwrapped in the 320px crop. Invoice identity and amount remain live text; the secondary link is descriptive.
- The valid unsubscribe page says that visiting did not unsubscribe the recipient and provides the supported next step. Invalid and expired states have distinct headings and recovery copy in [state.html.heex](/Users/jon/projects/mailglass/lib/mailglass/compliance/unsubscribe_html/state.html.heex:41).

### Pillar 2: Visuals (4/4)

- Both invoice artifacts show only the email iframe. At 375px the title fits on one line; at 320px it wraps naturally, the CTA label remains on one line, and the explanatory copy remains readable. The image is visually separated from its explanatory paragraph.
- The valid/invalid/expired pages at 1280px and 320px use a quiet centered reading column and one clear state heading. Narrow state headings wrap without clipping in the supplied images.
- Evidence files: `invoice-preview-{375,320}.png` and `unsubscribe-{valid,invalid,expired}-{1280,320}.png`.

### Pillar 3: Color (4/4)

- **Finding:** Email action uses the restrained Glass accent, while the download link uses readable accent text; the captures show no accent wash competing with content. Theme-aware component styling is in [components.ex](/Users/jon/projects/mailglass/lib/mailglass/components.ex:337).
- The page uses Paper `#F8FBFD`, Ink `#0D1B2A`, muted Slate `#5C6B7A`, and destructive `#B42318` for invalid/expired headings. Explicit state wording accompanies color, so color is not the sole state cue at [state.html.heex](/Users/jon/projects/mailglass/lib/mailglass/compliance/unsubscribe_html/state.html.heex:9).

### Pillar 4: Typography (4/4)

- **Finding:** Email text uses the contracted 14px supporting label, 16px body, and 20px/700 heading; the CTA is 16px/700 with an Arial/Helvetica fallback at [components.ex](/Users/jon/projects/mailglass/lib/mailglass/components.ex:267).
- Unsubscribe pages use the Inter/system-ui stack, 16px body, and 28px/700 title at [state.html.heex](/Users/jon/projects/mailglass/lib/mailglass/compliance/unsubscribe_html/state.html.heex:9). The 320px captures remain legible with natural wrapping.

### Pillar 5: Spacing (4/4)

- **Finding:** The earlier image-to-copy crowding is resolved. The invoice example applies `margin-top:16px` to the fallback/explanatory paragraph at [component_mailer.ex](/Users/jon/projects/mailglass/reference/demo_app/lib/mailglass_demo_web/mailers/component_mailer.ex:48); the separation is visible in both 320px and 375px crops.
- The browser check asserts at least 12px between the image and the explanatory copy and checks 12px between invoice content blocks at [demo.spec.js](/Users/jon/projects/mailglass/reference/demo_app/assets/e2e/demo.spec.js:169). The authored 16px margin satisfies the UI-SPEC grid and body rhythm. Email section padding remains 24px; unsubscribe pages use 24px wide-screen and 16px narrow-screen padding.

### Pillar 6: Experience Design (4/4)

- The browser case verifies `Review invoice` is visible, at least 44px wide and high, and no taller than 52px at 320px at [demo.spec.js](/Users/jon/projects/mailglass/reference/demo_app/assets/e2e/demo.spec.js:206). The current screenshot shows a single-line action with adequate touch area.
- The unsubscribe evidence shows distinct valid, invalid, and expired messages at both 1280px and 320px. The valid view is informational; invalid/expired views remain explicit and private. No controls or loading states are required by the contract.
- **Evidence boundary:** These invoice screenshots show a browser render of generated markup. They do not validate any recipient email client, delivered message, image-disabled presentation, or client dark mode. Interaction capture is off; no post-interaction state is claimed.

---

## Files Audited

- `lib/mailglass/components.ex`
- `lib/mailglass/components/theme.ex`
- `reference/demo_app/lib/mailglass_demo_web/mailers/component_mailer.ex`
- `lib/mailglass/compliance/unsubscribe_controller.ex`
- `lib/mailglass/compliance/unsubscribe_html/state.html.heex`
- `.planning/phases/172-recipient-output-and-built-in-pages/172-UI-SPEC.md`
- `brandbook/brand-book.md`
- `brandbook/tokens.css`
- `reference/demo_app/assets/e2e/demo.spec.js`
- `.planning/phases/172-recipient-output-and-built-in-pages/artifacts/browser-evidence/invoice-preview-{375,320}.png`
- `.planning/phases/172-recipient-output-and-built-in-pages/artifacts/browser-evidence/unsubscribe-{valid,invalid,expired}-{1280,320}.png`
