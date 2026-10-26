# Phase 168 — UI Review

**Audited:** 2026-10-08
**Baseline:** Approved `168-UI-SPEC.md`; fresh audit after the Phase 10 Inbound spacing correction.
**Screenshots:** Not captured. The standard CLI probe found `http://localhost:8080`, but its HTML title and metadata identify Traefik Proxy, not Mailglass Admin. Ports 3000 and 5173 did not provide an app capture target. No app screenshot is claimed. Existing Plan 09 browser artifacts and current automated rendered assertions are referenced as prior/current test evidence, not as new screenshots.
**Interaction captures:** off (`workflow.ui_interaction_capture=false`); interaction findings are code-derived and supported by existing deterministic Playwright coverage.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | The no-Account overview still says “Go to Deliveries” while shared context offers “Choose Account.” |
| 2. Visuals | 4/4 | Existing 200% zoom evidence and current computed-style regressions cover key narrow layout and spacing behavior; this refresh could not capture the live app. |
| 3. Color | 3/4 | Semantic tokens and restrained surfaces remain, but informational/help cues still use the accent outside the contract's allowed roles. |
| 4. Typography | 4/4 | Shared workspace role sizes and weights match the declared 14/16/20/28px and 400/700 system. |
| 5. Spacing | 4/4 | Inbound evidence now uses `gap-xs`; template guard and computed-style checks cover its emitted 4px alongside operator and Preview. |
| 6. Experience Design | 4/4 | Account-switch pending feedback, overlay/control state coverage, and deterministic regression coverage remain in place. |

**Overall: 22/24**

## Top 3 Priority Fixes

1. **WARNING — Clarify the no-Account overview action** — “Go to Deliveries” navigates without selecting scope; make the action select an available Account or explain it as navigation while preserving the Choose Account path.
2. **WARNING — Move informational cues off the reserved accent** — Use semantic info or neutral color for help/support cues; reserve accent for primary action, selection, active navigation/timeline, and focus.
3. **WARNING — Capture a current app render in the next visual pass** — The standard port probe resolves to a Traefik dashboard rather than the app; point the capture command at the actual app port to validate the current visual composition directly.

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The no-Account overview at `mailglass_admin/lib/mailglass_admin/operator_live.ex:932-934` presents “Go to Deliveries,” which changes surfaces without selecting scope. The shared shell provides “Choose Account” at `mailglass_admin/lib/mailglass_admin/operator/shell.ex:421-422`, and the overview copy otherwise matches the contract's “Choose an Account” heading and scoped-data explanation. Make the overview action select an available Account, or make its navigation purpose explicit.
- The shell distinguishes the selected Account, host label, stable ID, and chooser state. Cause-specific operator empty/error copy remains present; no generic retry/error regression was found in the audited screens.
- Reusable/gallery defaults still include “No data yet,” but active operator consumers provide cause-specific copy; not elevated as a working-screen defect.

### Pillar 2: Visuals (4/4)

- Existing Plan 09 browser evidence and `mailglass_admin/e2e/flows.spec.js:875-919` cover the combined 320 CSS px layout at actual Chromium 200% zoom, including Account/Appearance access and complete Delivery values without document overflow. This refresh inspected no new screenshot.
- Current spacing regression at `flows.spec.js:614-638` verifies the rendered operator error icon margin, Inbound evidence reveal stack row gap, and Preview scenario-list row gap are all `4px`.
- The new static capture attempt is explicitly limited: port 8080 serves a document with `<title>Traefik Proxy</title>`; 3000 and 5173 did not yield an app server. Visual composition is therefore supported by existing artifacts and rendered assertions, not a fresh screenshot review.

### Pillar 3: Color (3/4)

- Light/dark semantic tokens remain centralized in `mailglass_admin/assets/css/app.css:25-87`; working surfaces use neutral page/surface colors and status roles.
- **WARNING:** Accent is still used for informational/supporting elements despite the UI-SPEC reserving it for primary actions, selection, active navigation/timeline, and focus. Examples: info severity `components.ex:804`, Account/help cues `operator/shell.ex:384,400,452`, and Preview labels `preview/sidebar.ex:52,114`. The previous source pass counted 11 `text-primary` occurrences total, including valid action/selection uses; this is not treated as a rendered area-ratio measurement.
- A numeric 60/30/10 rendered pixel-area ratio was not measured; the spec describes approximate screen surface proportions, so this remains a qualitative judgment.

### Pillar 4: Typography (4/4)

- `mailglass_admin/assets/css/app.css:118-126` defines the contract's label/body/heading/display roles at 14/16/20/28px with the specified line heights. UI roles use installed 400/700 weights, and IBM Plex Mono remains assigned to exact identifiers/code.
- Existing browser assertions cover body and minimum label/badge/navigation sizes; prior actual-zoom evidence checks full identifiers and timestamps without title-only access.

### Pillar 5: Spacing (4/4)

- The declared scale remains `xs` 4px through `3xl` 64px in `mailglass_admin/assets/css/app.css:108-116`; numeric Tailwind spacing utilities stay on the 4px grid.
- **RESOLVED:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:49` now uses `gap-xs` on the evidence reveal stack. `mailglass_admin/test/mailglass_admin/token_parity_test.exs:31-40` includes this template in `@shared_spacing_template_paths`; test `:109-145` rejects half-step and unsupported `2xs` spacing classes and asserts the source/bundle define `--spacing-xs: 4px` plus `.gap-xs`/`.mt-xs` mappings.
- **RENDERED REGRESSION:** `mailglass_admin/e2e/flows.spec.js:614-638` checks computed 4px spacing for the operator error icon, the Inbound evidence reveal stack, and Preview scenario list. The full Admin suite (551 passed, 1 excluded) and full operator browser suite (199 passed, 1 existing guarded skip) were reported passing immediately before this fresh audit.
- No audited protected-template half-step or undefined `gap-2xs` finding remains.

### Pillar 6: Experience Design (4/4)

- Pending Account switching in `operator/shell.ex:281-309` retains the prior selection while announcing `Switching to {Account}…` through a polite atomic live status. `flows.spec.js:1249-1293` verifies retained rows/scope during the pending interval and new URL/scope after completion.
- Quick view/replay focus and dismissal, disabled pending actions, scope isolation, theme persistence, reduced motion, and cause-specific empty/error handling retain existing focused coverage. The spacing correction does not alter interaction semantics.
- Interaction capture was configured off; this refresh makes no claims about newly captured interaction states.
- Registry audit skipped per `168-UI-SPEC.md`: shadcn is not initialized and no third-party registries are listed; no `components.json` is present.

## Human Judgment

No owner decision or UAT checkpoint is needed for the machine-observable spacing correction, zoom geometry, or delayed-switch behavior; deterministic assertions cover those behaviors. Accent distribution and overall visual emphasis remain qualitative reviewer judgments, with no owner checkpoint requested.

## Files Audited

- `.planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md`, `168-CONTEXT.md`, existing `168-UI-REVIEW.md`, all Phase 168 `PLAN` and `SUMMARY` files (Plans 01–10)
- `mailglass_admin/lib/mailglass_admin/admin_shell.ex`, `components.ex`, `operator/shell.ex`, `operator_live.ex`, `operator/detail_header.ex`, `operator/timeline.ex`, `operator/quick_view.ex`, `inbound/quick_view.ex`, `inbound/evidence_card.ex`, `preview/sidebar.ex`, and `preview_live.ex`
- `mailglass_admin/assets/css/app.css`, `mailglass_admin/priv/static/app.css`, `mailglass_admin/test/mailglass_admin/token_parity_test.exs`, and `mailglass_admin/e2e/flows.spec.js`
- Existing rendered specimens under `.planning/phases/168-shared-workspace-and-usable-baseline/artifacts/`
