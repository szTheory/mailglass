# Phase 168 — UI Review

**Audited:** 2026-10-08
**Baseline:** Approved `168-UI-SPEC.md`; refreshed after Plan 10 and commit `6f15e8c8` (current checkout also includes `26ca2294`).
**Screenshots:** Not captured. The standard CLI probe reached `http://localhost:8080`, but all three captures failed; that endpoint serves the Traefik Proxy dashboard. No app screenshot is claimed for this refresh. Existing Plan 09 browser artifacts remain available as prior rendered evidence.
**Interaction captures:** off (`workflow.ui_interaction_capture=false`); interaction findings are based on source and existing deterministic Playwright evidence.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | The no-Account overview still prioritizes “Go to Deliveries” even though the shared shell offers “Choose Account.” |
| 2. Visuals | 4/4 | Existing true-200% browser evidence covers the 320px layout, and Plan 10's computed-style check confirms the Preview/operator spacing renders as intended. |
| 3. Color | 3/4 | Semantic tokens and restrained surfaces remain, but informational/help cues still use the accent color. |
| 4. Typography | 4/4 | The 14/16/20/28px roles and 400/700 weights remain consistent with the contract and the existing zoom checks preserve complete values. |
| 5. Spacing | 3/4 | Plan 10 removes all 13 half-step classes; `gap-2xs` remains undefined in the built CSS in an inbound evidence card. |
| 6. Experience Design | 4/4 | Pending Account switching, exact-target overlays, and the Plan 10 rendered spacing assertion have deterministic existing-stack coverage. |

**Overall: 21/24**

## Top 3 Priority Fixes

1. **WARNING — Replace the undefined `gap-2xs` utility** — The Inbound evidence reveal controls may render without their intended vertical separation; use a declared spacing token such as `gap-xs` and rebuild the bundle.
2. **WARNING — Move informational cues off the reserved accent** — Use semantic info or neutral colors for supporting/help cues while retaining accent for primary actions, selection, active navigation/timeline, and focus.
3. **WARNING — Clarify the no-Account overview action** — Make the unselected-state CTA choose an available Account or label it as navigation so it does not imply scoped Deliveries are ready.

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The no-Account overview presents “Go to Deliveries” at `mailglass_admin/lib/mailglass_admin/operator_live.ex:932-934`, which navigates surfaces without selecting scope. The shared shell exposes “Choose Account” at `mailglass_admin/lib/mailglass_admin/operator/shell.ex:421-422`, so Account selection remains reachable. Prefer making the overview CTA select an available Account or label it as a navigation action rather than the primary unselected-state action.
- The shell distinguishes the selected Account, stable ID, and “Choose Account” state. The Account chooser shows the host label and ID. No generic retry/error copy regression was found in the audited phase screens.
- `No data yet` remains a generic default in reusable/gallery components, but current operator working-screen consumers pass cause-specific copy; this is not an active working-screen defect.

### Pillar 2: Visuals (4/4)

- **PASS — actual 200% zoom:** Existing Plan 09 evidence and `mailglass_admin/e2e/flows.spec.js:875-919` prove a combined 320 CSS px layout at actual Chromium tab zoom 2, with Account/Appearance controls and full Delivery values checked for reachability and document overflow. The prior review inspected `artifacts/gap-closure/delivery-200-browser-zoom.png`; this refresh did not capture a new image.
- **PASS — Plan 10 rendered spacing:** `flows.spec.js:614-629` checks computed `marginTop` of 4px on a rendered Inbound Quick view error icon and a 4px Preview scenario-list `rowGap` from the served UI fixtures. Plan 10 reports this focused case passed 1/1.
- Standard audit CLI captures were unavailable: ports 3000 and 5173 had no app server, while 8080 served Traefik Proxy. The existing Plan 09 rendered evidence and deterministic Plan 10 geometry/style assertions found no current clipping or spacing-render defect. Visual focal balance remains covered by the retained color and CTA findings below.

### Pillar 3: Color (3/4)

- Semantic light/dark tokens remain centralized in `mailglass_admin/assets/css/app.css:25-77`. Existing Deliveries specimens show neutral page/surface colors, explicit status text, and restrained accent use on active navigation and primary actions.
- **WARNING:** The accent remains on informational/supporting elements despite the UI-SPEC reserving it for primary action, selection, active navigation/timeline, and focus. Examples include the info severity class at `mailglass_admin/lib/mailglass_admin/components.ex:804`, help/account cues at `operator/shell.ex:384,400,452`, and Preview informational labels at `preview/sidebar.ex:52,114`. The previous source audit counted 11 `text-primary` uses total, including legitimate primary-action uses; the count alone is not treated as a rendered area-ratio measure.
- A precise 60/30/10 rendered pixel-area ratio was not measured. The contract describes approximate screen surface area, so this remains a qualitative design check rather than a numeric pass/fail assertion.

### Pillar 4: Typography (4/4)

- `mailglass_admin/assets/css/app.css:118-126` defines the approved label/body/heading/display roles at 14/16/20/28px (0.875/1/1.25/1.75rem) with the specified line heights. UI source uses the approved 400/700 weights; IBM Plex Mono remains used for exact identifiers.
- Existing operator-browser role-size assertions cover body copy and minimum badge/navigation text. The actual-zoom case checks complete identifier and timestamp text without relying on title-only access.

### Pillar 5: Spacing (3/4)

- The approved scale remains `xs` 4px through `3xl` 64px in `mailglass_admin/assets/css/app.css:108-116`; ordinary numeric Tailwind utilities such as `p-4` map to 4px-grid multiples.
- **Resolved by Plan 10:** The six protected templates are `operator/shell.ex`, `components.ex`, `operator/quick_view.ex`, `inbound/quick_view.ex`, `preview_live.ex`, and `preview/sidebar.ex`. All 13 prior `mt-0.5`/`gap-0.5` occurrences now use `mt-xs`/`gap-xs`; source inspection found no remaining half-step classes in this set. `token_parity_test.exs:108-136` guards half-step margin/padding/gap/space utilities and verifies `--spacing-xs: 4px` plus generated `.mt-xs` and `.gap-xs` rules. The built `priv/static/app.css` contains both rules, each resolving through `var(--spacing-xs)`.
- **WARNING:** `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex:49` still uses `gap-2xs`, but no `.gap-2xs` rule exists in `mailglass_admin/priv/static/app.css`. Replace it with a declared token or define/build the intended spacing utility; this is a distinct remaining issue from the fixed 13-class finding.

### Pillar 6: Experience Design (4/4)

- **PASS — pending Account switch:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex:281-309` gives each option/status pair a safe numeric index target. The pending region uses `role="status"`, `aria-live="polite"`, `aria-atomic="true"`, visible “Switching to {Account}…” copy, and `JS.show` before the patch completes. `flows.spec.js:1249-1293` asserts status semantics, old Account/row retention while held, then new URL/scope and status removal after release.
- Quick view and replay focus, disabled pending actions, scope isolation, theme behavior, reduced motion, and cause-specific empty/error handling retain the existing focused coverage. Plan 10 adds a source/bundle guard and a served computed-style assertion for the two changed spacing patterns; no interaction semantics changed.
- A distinct denied-switch state remains inapplicable to this host integration because its Account options are activity-derived and no distinct denied-switch result is exposed.
- Registry audit was skipped: the UI-SPEC says shadcn is not initialized and there is no `components.json`/third-party registry inventory.

## Human Judgment

No owner decision or UAT is required for the machine-observable spacing, actual-zoom geometry, or delayed-switch behavior; they have deterministic assertions under D-52. Accent-area balance and overall visual emphasis remain qualitative reviewer judgments, without an owner checkpoint. No `needs_human_review: true` issue remains as a shipping gate.

## Files Audited

- `.planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md`, `168-BASELINE.md`, prior `168-UI-REVIEW.md`, all Phase 168 `PLAN` and `SUMMARY` files (Plans 01–10), `168-UAT.md`, `168-VERIFICATION.md`, and `168-VALIDATION.md`
- `mailglass_admin/lib/mailglass_admin/admin_shell.ex`, `components.ex`, `operator/shell.ex`, `operator_live.ex`, `operator/detail_header.ex`, `operator/timeline.ex`, `operator/quick_view.ex`, `inbound/quick_view.ex`, `inbound/evidence_card.ex`, `preview/sidebar.ex`, and `preview_live.ex`
- `mailglass_admin/assets/css/app.css`, `mailglass_admin/priv/static/app.css`, `mailglass_admin/test/mailglass_admin/token_parity_test.exs`, and `mailglass_admin/e2e/flows.spec.js`
- Existing specimens under `artifacts/gap-closure/` and `artifacts/after/`
