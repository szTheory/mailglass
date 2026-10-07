# Phase 168 — UI Review

**Audited:** 2026-10-07  
**Baseline:** Approved `168-UI-SPEC.md`, reconciled with `168-BASELINE.md` rendered evidence and current source  
**Screenshots:** not captured (server answered on `localhost:4015`, but Playwright CLI capture failed at desktop 1440×900, mobile 375×812, and tablet 768×1024). Existing authored screenshots were inspected.  
**Interaction captures:** off (`workflow.ui_interaction_capture=false`)

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Approved shared Account and error/empty copy is present; the stat card's reusable default still says generic “No data yet.” |
| 2. Visuals | 3/4 | Shell and task hierarchy read clearly in rendered captures; the no-selection chooser truncates Account names with hover-only full text. |
| 3. Color | 3/4 | Semantic light/dark palette and limited accent use are consistent; selected-row edge and other primary cues use the accent, but source-level usage counts look broader than the reserved 10% role set. |
| 4. Typography | 3/4 | Main content uses the 14/16/20/28px token roles; legacy compact badges/navigation and helper text still use 12px sizing below the contract's essential-label floor. |
| 5. Spacing | 2/4 | The core scale is used throughout, but numerous arbitrary Tailwind spacing values conflict with the explicit no-off-grid contract. |
| 6. Experience Design | 3/4 | Main account, theme, filter, Quick view, and replay states have focused rendered coverage; account switch pending/error browser states remain unproven, though no behavior defect was established. |

**Overall: 17/24**

## Top 3 Priority Fixes

1. **WARNING — Replace the no-selection chooser's truncated Account label** — Long names are incomplete for keyboard and touch users because the complete value exists only in a `title`; render the name wrapping and expose `tenant_id` alongside it, as the shared shell already does.
2. **WARNING — Bring remaining spacing utilities onto the 4px scale** — `mt-1`, `mt-2`, `gap-1`, `space-y-3/4`, `p-4`, and `px-5` bypass the declared tokens; replace with the nearest named scale utilities and retain only non-spacing dimensional values such as control heights.
3. **WARNING — Remove 12px essential-label and helper text** — The contract calls for 14px labels and a 16px running-copy floor; replace `text-xs`/`text-label` use for essential meanings with declared tokens, especially stat labels, badges, and helper text.

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** [components.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex:434) exposes a generic `empty_text` default of `No data yet`. Current operator surfaces supply cause-specific copy (for example the no-activity chooser and filtered-empty Deliveries), so this is a component fallback risk, not evidence that the reviewed screens currently show the generic line. Give the default a domain-specific safe value or require callers to pass copy.
- The shared account chooser and no-activity distinction match the contract in [shell.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:371); unavailable/stale Delivery copy is cause-specific in [deliveries_list.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex:58). Replay actions distinguish pending, unavailable, and completion, with “Cancel” only on the explicit confirmation dialog ([replay_modal.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:109)).

### Pillar 2: Visuals (3/4)

- **WARNING:** The no-selection account-option row truncates its label and makes the full value available only through a title attribute ([shell.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:397)). This violates the long-label accessible detail requirement and is distinct from the selected shared-shell label, which wraps.
- The inspected 390px Health after capture has a legible order (brand/account, appearance, section navigation, page title, then metric cards). The 1440px Deliveries capture places the collection ahead of filters and uses the sidebar consistently. Quick view captures exist at 320/390/768/1440; plan summaries document dialog focus containment/return and exact-target replay confirmation. No capture in this audit independently re-tested interaction states.
- **WARNING:** `stat_card` truncates long labels and values while relying on `title` for complete content ([components.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex:467)); the UI-SPEC requires long labels/identifiers be fully available without hover-only access. Current metric labels are short, but the reusable component contract is too weak.

### Pillar 3: Color (3/4)

- The component-level source contains 24 lines with `text-primary`, `bg-primary`, or `border-primary` across 18 distinct semantic accent references; reviewed surfaces use the accent for selected navigation, account action, theme selection/focus, and primary CTA. This is not an element-area measurement, so it cannot substantiate the approximate 60/30/10 surface ratio by itself.
- **WARNING:** Accent also appears on neutral informational/brand icons and focusable action text (e.g. [shell.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:368), `:384`, `:403`). Compare those uses against the contract's reserved accent roles; keep informational meaning on semantic info colors and use the visible-focus treatment for focus emphasis rather than coloring routine supporting copy.
- The inspected Light capture shows Paper ground, white grouped surfaces, neutral borders, and status colors paired with explicit text/icons. Dark theme and System transition/reload were emulated per Plan 03 evidence. `components.json` is absent; registry audit is not applicable.

### Pillar 4: Typography (3/4)

- Source role tokens are present for body, label, heading, and display; Inter/Inter Tight/IBM Plex Mono are declared in the stylesheet and the phase summary records fallback-font blocking without lost labels or controls.
- **WARNING:** The shared component library still uses daisyUI's compact `badge-sm` and compact navigation utilities for status/section labels (for example [components.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex:209), `:1028`). These can render below the contract's 14px essential-label floor even though the custom `text-label` token is 14px. Confirm/override the computed size for essential labels and helper text; preserve the token scale for body copy. The authored captures show current short labels remain legible, so this is a contract compliance issue rather than an observed unreadable screen.
- Weights include 400 and 700 as requested. Rendered evidence shows readable current short labels; no enlarged-text setting was separately emulated.

### Pillar 5: Spacing (2/4)

- **WARNING:** The implementation includes many non-token utilities across operator, inbound, and shared components. Examples include `mt-0.5`, `mt-1`, `mt-2`, `gap-1`, `space-y-3`, `space-y-4`, `p-4`, `px-5`, and `py-2` ([replay_modal.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:93), [components.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/components.ex:965)). The UI-SPEC says not to introduce off-grid spacing; use `xs/sm/md/lg/xl/2xl/3xl` tokens (or named 4px-grid utilities) for these gaps and padding.
- Arbitrary `max-w-[18rem]` and viewport-bounded account-menu widths in [shell.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:253) and `:279` are dimensions/constraints rather than spacing tokens and are appropriate to prevent overflow. Control min-heights are likewise separate from spacing and match the 44px hit-target requirement.
- Rendered review documents multiple responsive passes, 200% zoom, and zero horizontal overflow on key routes; the exception recorded in early evidence (tooltip overflow) was corrected and rechecked.

### Pillar 6: Experience Design (3/4)

- **WARNING — evidence gap, no confirmed behavior defect:** E2 account switch pending/rejection states remain marked Pending in the 52-state inventory. The contract requires the old Account and data to remain committed until a new scope succeeds, plus an announced failure. Source implements navigation patching and shared status feedback, but the AtlasDesk live review did not hold/reject the switch response. Add focused browser evidence for delayed and rejected account switching before treating these two rows as verified. This is not classified as a BLOCKER because no incorrect rendered behavior was observed.
- The 52-state inventory's other notable Partial/Pending rows are largely coverage gaps, not product defects: nav full-outage failure cannot render app recovery without a document; theme persistence failure and cold-load latency were not injected; enlarged-text was not separately emulated; nil-value and maximum-length specimens were not all seeded. Plan 03's blocked-font test is valid fallback evidence, not a defect; actual local file removal is unnecessary to prove the browser behavior. Non-ASCII Delivery IDs are inapplicable because Delivery IDs are UUIDs. Long failure copy is separately exercised in the gallery and replay/error paths, so E7 long-copy rows should be upgraded from Partial where that evidence satisfies the specimen.
- Quick view/replay source includes named dialog semantics, Escape/close behavior, focus containment/return, pending disable state, and reduced-motion handling; the summary records browser checks. Feedback has explicit alert/status live regions, dismiss labels and stable IDs ([shell.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/shell.ex:301)).
- Full browser and ExUnit results are reported by the completed plans (183 passed/0 failed/1 guarded skip; focused ExUnit 302/0 failures/1 excluded). Tests were not rerun for this audit.

## Files Audited

- `.planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md`
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-CONTEXT.md`
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-BASELINE.md` and plan 01–04 summaries
- Rendered `artifacts/after/health-390.png`, `artifacts/after/deliveries-1440.png`, `artifacts/plan02/` light/dark responsive captures, and `artifacts/plan04/quick-view-*.png`
- `mailglass_admin/lib/mailglass_admin/components.ex`
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex`
- `mailglass_admin/lib/mailglass_admin/operator/{deliveries_list,quick_view,replay_modal}.ex`
- `mailglass_admin/lib/mailglass_admin/inbound/{filters_form,detail_header,records_list,replay_modal}.ex`
- `mailglass_admin/assets/css/app.css` and `mailglass_admin/priv/static/app.css`
