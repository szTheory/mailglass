# Phase 168 — UI Review

**Audited:** 2026-10-08
**Baseline:** Approved `168-UI-SPEC.md`, the current implementation, all eight PLAN/SUMMARY pairs, UAT and verification records.
**Screenshots:** captured and inspected from the current Playwright run: 320, 720 and 1440 CSS-pixel Deliveries views, 720 CSS-pixel Health, and a true 200% Chromium tab-zoom capture.
**Interaction captures:** off (`workflow.ui_interaction_capture=false`); interaction findings below are derived from current source and Playwright assertions.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | The unselected-Account overview offers “Go to Deliveries” instead of making Account selection its primary action. |
| 2. Visuals | 1/4 | The actual-zoom screenshot shows the right side of the topbar and Delivery detail cut off, despite a passing check limited to two text elements. |
| 3. Color | 3/4 | The semantic palette and restrained overall accent balance are sound, but informational content still uses the reserved primary accent. |
| 4. Typography | 4/4 | Current source and browser assertions support the specified 14/16/20/28px roles, 400/700 weights, and status/navigation minimums. |
| 5. Spacing | 3/4 | The old numeric-class count was a false positive, but 13 two-pixel spacing uses and an undefined `gap-2xs` utility remain. |
| 6. Experience Design | 2/4 | Scope is retained during delayed Account patches, but the user receives no visible pending announcement; the Preview flash-key defect is fixed and covered. |

**Overall: 16/24**

## Top 3 Priority Fixes

1. **BLOCKER — Reconcile and correct the 200% layout clipping** — At true Chromium zoom, the retained capture shows Change Account cut off, Appearance outside the frame, and long detail text clipped; expand browser assertions to all required shell controls and rendered detail fields, then correct any actual clipping.
2. **WARNING — Announce an Account switch while it is pending** — The delayed-switch regression proves Northstar remains committed while the response is held, but does not show the “pending work” cue required by E2; add a visible, live-region status and assert it in that same regression.
3. **WARNING — Make Account selection the unselected-state action** — Replace or rework the overview’s “Go to Deliveries” CTA so a user with no selected Account can choose one directly, as the contract specifies.

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The no-Account overview uses the correct “Choose an Account” heading and “Select an Account to see scoped operator data.” body, but then presents “Go to Deliveries” as its CTA ([operator_live.ex:921](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:921)). The contract’s primary CTA is `Choose Account`; the current link changes surface without selecting scope. Make the available Account choices actionable in this state or change the CTA to the actual selection action.
- The shared chooser preserves the required distinction between `Choose Account`, `Choose an Account`, and `No Accounts with mail activity` ([shell.ex:264](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:264), [shell.ex:370](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:370)). Error and retry copy names the failure and recovery action.
- `No data yet` remains a generic default in the reusable stat component and Gallery ([components.ex:435](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex:435), [gallery_live.ex:267](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/gallery_live.ex:267)); current operator consumers supply cause-specific copy, so this is not counted as an active working-screen defect.

### Pillar 2: Visuals (1/4)

- **BLOCKER:** The current [200% Chromium screenshot](artifacts/gap-closure/delivery-200-browser-zoom.png) visibly clips the topbar at its right edge: `Change Account` is cut off and the Appearance control is absent. Long Delivery detail text, the provider name, and the event ID/time also continue beyond the captured right edge. The 320/720 CSS-pixel captures show those controls and fields in-frame, so the actual-zoom artifact conflicts with the resized-viewport evidence.
- The Playwright case sets and reads back zoom factor `2`, but checks geometry and final-character bounds only for the page description and one Mailable string ([flows.spec.js:676](/Users/jon/projects/mailglass/mailglass_admin/e2e/flows.spec.js:676), [flows.spec.js:717](/Users/jon/projects/mailglass/mailglass_admin/e2e/flows.spec.js:717)). It does not assert that Account switching, Appearance, the full record identity, provider details, or timeline content remain visible. Expand the automated bounds/accessibility checks to the contract’s essential controls and values; the retained screenshot cannot be reconciled with a blanket “200% content fits” claim yet.
- Desktop composition, active-section cue, account identity, surface hierarchy, and card grouping are otherwise clear in the 1440px capture. The current screenshot is also a useful example of what the test needs to cover, not a reason to soften this score.

### Pillar 3: Color (3/4)

- Semantic light/dark tokens remain centralized in [app.css:25](/Users/jon/projects/mailglass/mailglass_admin/assets/css/app.css:25); the inspected light views keep Paper as the dominant ground, white task cards secondary, and the active Deliveries cue restrained. Status still has explicit text/icon semantics.
- **WARNING:** Informational icons and the information severity use `text-primary`, mapping them to the accent reserved by the contract for selection, primary actions, active navigation/timeline cues, and focus. Examples include the no-Account/help icons ([shell.ex:367](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:367), [shell.ex:383](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:383)) and `stat_severity_class(:info)` ([components.ex:804](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex:804)); `preview/sidebar.ex:52` also uses primary for the informational “Email previews” label. Use semantic info or neutral tokens for these supporting cues.
- The source scan found no hard-coded hex/RGB color in HEEx/Elixir files. Utility counts alone do not establish a 60/30/10 pixel-area split; current screenshots support the overall restrained distribution.

### Pillar 4: Typography (4/4)

- The stylesheet defines the approved label/body/heading/display roles as 14/16/20/28px rem values ([app.css:117](/Users/jon/projects/mailglass/mailglass_admin/assets/css/app.css:117)); implementation class scans found only those named sizes and normal/bold weights. IBM Plex Mono is used for exact identifiers.
- The current browser regression measures body, badge, and navigation sizes and requires the badge/navigation minimum of 14px ([flows.spec.js:1136](/Users/jon/projects/mailglass/mailglass_admin/e2e/flows.spec.js:1136)). The earlier concern about `badge-sm` is stale: the class is present, but the live computed-size check confirms status text clears the label floor.

### Pillar 5: Spacing (3/4)

- **WARNING:** The previous review’s “114 numeric spacing utilities” finding was incorrect: `mt-1`, `p-4`, and similar values can map exactly to the approved 4px grid. That count is withdrawn.
- **WARNING:** Thirteen remaining `mt-0.5`/`gap-0.5` usages apply 2px spacing, outside the declared grid; examples are icon alignment in [shell.ex:314](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:314) and Preview sidebar rows ([sidebar.ex:173](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/preview/sidebar.ex:173)). Replace with an approved value or document a narrowly justified optical alignment exception.
- **WARNING:** `gap-2xs` is used for the Inbound evidence controls ([evidence_card.ex:49](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:49)) but is absent from the generated `priv/static/app.css`; no spacing is applied between those children. Use an existing `gap-xs` token or define/build the intended token. The named 4px-grid scale itself remains correct ([app.css:109](/Users/jon/projects/mailglass/mailglass_admin/assets/css/app.css:109)).

### Pillar 6: Experience Design (2/4)

- **WARNING:** Account switching is a real URL-backed LiveView patch ([shell.ex:280](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:280)). The current delayed-response case holds the server reply and asserts the previously committed Account and Delivery row remain visible until the response commits ([flows.spec.js:1114](/Users/jon/projects/mailglass/mailglass_admin/e2e/flows.spec.js:1114)). It does not present or assert a pending status, although the UI-SPEC requires pending work to be identified and announced. Add a visible shared live-region status and assert the busy and settled states in this regression.
- A distinct rejected-switch message remains `N/A` for this host integration: Account options are activity-derived and do not authorize access, and the read routes expose no distinct denied-switch result. Do not infer denial from the option list or invent a product error state.
- **Resolved in current code and evidence:** the shared flash component now accepts a backing `flash_key` separate from presentation `kind`, and Preview passes `flash_key={:info}` while retaining success styling ([components.ex:142](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex:142), [components.ex:176](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex:176), [preview_live.ex:505](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/preview_live.ex:505)). Tagged LiveView test `g_168_8` triggers the actual Preview message, clicks its dismiss control, and verifies it disappears ([preview_live_test.exs:652](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/preview_live_test.exs:652)); no flash-key finding remains.
- Quick view/replay focus, disabled pending action, scope isolation, theme selection, reduced motion, and cause-specific empty/error handling have focused coverage. The full Playwright result is **198 passed, 0 failed, 1 existing guarded skip**; ExUnit is **550 tests, 0 failures, 1 excluded**. These are current suite results recorded in `168-08-SUMMARY.md` and `168-VERIFICATION.md`.

## Irreducible Visual Judgment

The screenshot-based 200% clipping above is an observable acceptance defect, not a request for owner taste. Beyond that, no unresolved subjective design choice blocks this review: the D-52 contract leaves machine-observable criteria to automated evidence and does not leave owner UAT when current evidence covers them. The active findings are concrete, fixable contract gaps.

## Files Audited

- `.planning/phases/168-shared-workspace-and-usable-baseline/168-01-PLAN.md` through `168-08-PLAN.md` and all eight matching `*-SUMMARY.md` files
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md`, `168-CONTEXT.md`, `168-UAT.md`, `168-VERIFICATION.md`, `168-VALIDATION.md`, `168-BASELINE.md`, and the previous `168-UI-REVIEW.md`
- Current screenshots: `artifacts/gap-closure/{delivery-200-browser-zoom,delivery-320-css,delivery-720-css,delivery-1440-css,health-720-css}.png`
- `mailglass_admin/lib/mailglass_admin/admin_shell.ex`, `components.ex`, `operator/shell.ex`, `operator_live.ex`, `operator/deliveries_list.ex`, `operator/timeline.ex`, `operator/support_cards.ex`, `inbound/evidence_card.ex`, `preview/sidebar.ex`, and `preview_live.ex`
- `mailglass_admin/assets/css/app.css`, `mailglass_admin/priv/static/app.css`, `mailglass_admin/e2e/flows.spec.js`, and `mailglass_admin/test/mailglass_admin/preview_live_test.exs`
