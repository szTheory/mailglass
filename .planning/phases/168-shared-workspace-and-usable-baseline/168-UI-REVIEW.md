# Phase 168 — UI Review

**Audited:** 2026-10-08
**Baseline:** Approved `168-UI-SPEC.md`; current implementation after Plan 09 and commit `b5b2de00`.
**Screenshots:** The post-change focused Playwright run generated and the audit inspected `artifacts/gap-closure/delivery-200-browser-zoom.png`, including the combined 320 CSS px layout at actual 200% zoom. The audit's standard CLI captures were unavailable: ports 3000 and 5173 had no server, and 8080 served the Traefik Proxy dashboard.
**Interaction captures:** off (`workflow.ui_interaction_capture=false`); the delayed Account-switch interaction is covered by Playwright assertions.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | The unselected-state overview still sends users to Deliveries; the shared shell separately exposes the required “Choose Account” action. |
| 2. Visuals | 4/4 | The updated browser run proves the controls and exact Delivery values reflow at true 200% zoom with a 320 CSS px viewport and no page-level horizontal overflow. |
| 3. Color | 3/4 | Semantic colors and restrained surfaces remain consistent, but informational cues still use the accent reserved for selected/focus/primary roles. |
| 4. Typography | 4/4 | The 14/16/20/28px role tokens, 400/700 weights, and minimum status/navigation sizes remain aligned with the approved contract. |
| 5. Spacing | 3/4 | Thirteen half-step spacing uses and an undefined `gap-2xs` utility remain outside the declared spacing scale. |
| 6. Experience Design | 4/4 | A delayed Account switch now exposes visible polite status and retains old-scope data until the server patch commits. |

**Overall: 21/24**

## Top 3 Priority Fixes

1. **WARNING — Use only the declared spacing scale** — Replace the 13 `mt-0.5`/`gap-0.5` uses with approved spacing or document narrow optical exceptions; replace `gap-2xs` with a built token such as `gap-xs`.
2. **WARNING — Keep informational cues off the reserved accent** — Change supporting/help/info `text-primary` uses to semantic info or neutral roles; retain accent for primary actions, selection, active navigation/timeline, and focus.
3. **WARNING — Make the unselected-state CTA select an Account** — The shared shell exposes “Choose Account,” but the overview CTA still navigates to Deliveries without selecting scope.

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The no-Account overview presents “Go to Deliveries” at `mailglass_admin/lib/mailglass_admin/operator_live.ex:932-934`, which navigates surfaces without selecting scope. The shared shell still exposes “Choose Account” at `mailglass_admin/lib/mailglass_admin/operator/shell.ex:421-422`, so account selection remains reachable. Prefer making the overview CTA select an available Account or label it as a navigation action rather than the primary unselected-state action.
- The shell distinguishes the selected Account, stable ID, and “Choose Account” state. The Account chooser shows the host label and ID. No generic retry/error copy regression was found in the audited phase screens.
- `No data yet` remains a generic default in reusable/gallery components, but the operator working-screen consumers use cause-specific copy; it is not an active working-screen defect.

### Pillar 2: Visuals (4/4)

- **PASS — actual 200% zoom at both tested widths:** `mailglass_admin/e2e/flows.spec.js:778-800` proves tab zoom is exactly `2` and checks the full 720 CSS px layout. The added combined case at `flows.spec.js:875-919` changes the Playwright viewport to 640 device pixels at 2x scale and asserts both `window.innerWidth` and `document.documentElement.clientWidth` equal 320 while `chrome.tabs.getZoom()` remains exactly `2`.
- At the combined 320 CSS px / 200% condition, the test checks geometry and clipping for Account context, Account switcher, Appearance, and the System/Light/Dark radios via `assertZoomReachableControl`; it also verifies complete Delivery ID, Mailable, provider, provider-message ID, timeline event ID, recorded timestamp, and description text via exact fixture strings and line/final-character geometry. It asserts document width is at most 320px. The post-change focused operator-browser run passed **2/2**, and the newly generated `artifacts/gap-closure/delivery-200-browser-zoom.png` shows the narrow, vertically reflowed state. The prior 320px/200% evidence ambiguity is **resolved**.
- Standard audit CLI captures were unavailable because 8080 served Traefik Proxy rather than Mailglass, and ports 3000/5173 had no server. The test-generated true-zoom screenshot and existing 320, 720, and 1440 CSS specimens provide rendered evidence; no visual clipping defect was found.

### Pillar 3: Color (3/4)

- The semantic light/dark tokens remain centralized in `mailglass_admin/assets/css/app.css:25-77`. Existing Deliveries specimens show neutral page/surface colors, explicit status text, and restrained accent use on active navigation and primary actions.
- **WARNING:** The accent remains on informational/supporting elements despite the UI-SPEC reserving it for primary action, selection, active navigation/timeline, and focus. Examples include the info severity class at `mailglass_admin/lib/mailglass_admin/components.ex:804`, help/account cues at `operator/shell.ex:384,400,452`, and Preview informational labels at `preview/sidebar.ex:52,114`. The source contains 11 `text-primary` uses total, including legitimate primary-action uses; the count alone is not treated as an area-ratio measure.
- A precise 60/30/10 rendered pixel-area ratio was not measured. The contract describes approximate screen surface area, so this remains a qualitative design check rather than a numeric pass/fail assertion.

### Pillar 4: Typography (4/4)

- `mailglass_admin/assets/css/app.css:118-126` defines the approved label/body/heading/display roles at 14/16/20/28px (0.875/1/1.25/1.75rem) with the specified line heights. UI source uses the approved 400/700 weights; IBM Plex Mono remains used for exact identifiers.
- The operator-browser role-size assertions still cover body copy and minimum badge/navigation text. The new zoom case also checks complete identifier and timestamp text without relying on title-only access.

### Pillar 5: Spacing (3/4)

- The declared 4px-grid tokens remain `xs` 4px through `3xl` 64px in `mailglass_admin/assets/css/app.css:108-116`; regular numeric utilities such as `p-4` are not counted as violations because they map to the grid.
- **WARNING:** Thirteen source occurrences of `mt-0.5`/`gap-0.5` use 2px spacing outside the scale. Examples include status-icon alignment and Preview sidebar rows (`components.ex:773`, `preview/sidebar.ex:173,212,226`). Replace them or document optical-alignment exceptions.
- **WARNING:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:49` uses `gap-2xs`, but `mailglass_admin/priv/static/app.css` contains no generated rule for it. Replace it with a declared spacing token or define and build the intended token.

### Pillar 6: Experience Design (4/4)

- **PASS — pending Account switch:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex:281-309` gives each option/status pair a safe numeric index target. The pending region uses `role="status"`, `aria-live="polite"`, `aria-atomic="true"`, visible “Switching to {Account}…” copy, and `JS.show` before the patch completes. The test at `mailglass_admin/e2e/flows.spec.js:1249-1293` asserts the ID is numeric (not derived from user-controlled Account ID), status visibility/semantics, prior Account and row retention while held, then new URL/scope and status removal after release.
- Quick-view and replay focus, disabled pending actions, scope isolation, theme behavior, reduced motion, and cause-specific empty/error handling retain the previously recorded focused coverage. A distinct denied-switch state remains inapplicable to this host integration because its Account options are activity-derived and no distinct denied-switch result is exposed.
- Registry audit was skipped: the UI-SPEC says shadcn is not initialized and there is no `components.json`/third-party registry inventory.

## Human Judgment

No owner decision or UAT is required for the actual-zoom geometry or delayed-switch behavior; both have deterministic browser assertions. Accent-area balance and overall visual emphasis remain qualitative reviewer judgments, but they do not require an owner checkpoint. No `needs_human_review: true` issue remains as a shipping gate.

## Files Audited

- `.planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md`, prior `168-UI-REVIEW.md`, `168-09-PLAN.md`, `168-09-SUMMARY.md`, `168-UAT.md`, `168-VERIFICATION.md`, and `168-VALIDATION.md`
- `mailglass_admin/lib/mailglass_admin/admin_shell.ex`, `components.ex`, `operator/shell.ex`, `operator_live.ex`, `operator/detail_header.ex`, `operator/timeline.ex`, `inbound/evidence_card.ex`, `preview/sidebar.ex`, and `preview_live.ex`
- `mailglass_admin/assets/css/app.css`, `mailglass_admin/priv/static/app.css`, and `mailglass_admin/e2e/flows.spec.js`
- Existing specimens under `artifacts/gap-closure/` and `artifacts/after/`
