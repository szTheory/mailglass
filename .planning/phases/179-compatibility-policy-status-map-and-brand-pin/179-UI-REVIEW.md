# Phase 179 — UI Review

**Audited:** 2026-11-17
**Baseline:** Abstract 6-pillar standards; no UI-SPEC.md exists. The four Phase 179 plan/summary pairs cover the status vocabulary and compatibility/brand artifacts.
**Screenshots:** Not captured (source-only audit; the existing favicon source-hash safety stop remains in force. No browser or server was started or probed.)
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Status words are centralized and recovery copy names a clear next step. |
| 2. Visuals | 3/4 | Badge and pane-mark sizing now follow the requested size; rendered page hierarchy remains unverified. |
| 3. Color | 3/4 | Status colors use semantic roles and token variables; on-screen color balance was not observable. |
| 4. Typography | 3/4 | Four named sizes and two weights are used; font loading and wrapping remain unverified. |
| 5. Spacing | 3/4 | Mobile delivery cards now use the 8px `space-y-sm` rhythm; rendered balance remains unverified. |
| 6. Experience Design | 3/4 | Loading, error, empty, and retry states are represented in source; live interaction was not captured. |

**Overall: 19/24**

---

## Top 3 Priority Fixes

1. **Complete responsive visual review after the favicon safety stop is cleared** — screenshots are needed to check hierarchy and clipping at 1440×900, 768×1024, and 375×812 — capture those three sizes and inspect the operator Activity view.
2. **Verify rendered color distribution** — source tokens establish roles but not the 60/30/10 balance on a page — inspect both themes in the approved captures and adjust only if the rendered distribution is out of balance.
3. **Verify actual font rendering and wrapping** — source classes cannot confirm font loading, narrow-screen line breaks, or focus appearance — review the delivery list and detail view in those captures.

These are deferred visual-evidence recommendations. The safety stop remains active, so none requires browser or server work in this refresh.

---

## Resolved Since the Previous Review

- **Delivery badge size:** `status_badge/1` maps `:sm` to `badge-sm` and a `:row` mark (17×20), and `:md` to `badge-md` and a `:detail` mark (37×44) in `components.ex:1571-1577,1614-1615,2079-2080`. Focused render assertions check both badge classes and SVG dimensions in `components_test.exs:95-121`.
- **Mobile card rhythm:** each delivery card now applies `space-y-sm` to its sibling content blocks in `deliveries_list.ex:248-253`; the LiveView render test asserts that class on the rendered card in `operator_live_test.exs:4857-4865`.

The source and tests were inspected; this refresh did not execute tests or a browser.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- **Finding:** Status label, icon, and badge-class strings have one owner in `MailglassAdmin.Copy` (`copy.ex:25-81`); the shared component reads those values at `components.ex:2082-2084`. The fallback is explicit (`Unknown`), while strict readers reject unmapped states (`copy.ex:8-12,81`).
- **Finding:** Error copy is actionable rather than generic: invalid and unavailable delivery details direct the operator back to Activity, and transient failures offer a retry (`quick_view.ex:109-117,238-248`). Activity empty states are separately titled for an empty page, filtered results, and an empty time window (`deliveries_list.ex:107-140`).
- **Finding:** The scanned UI modules contain no generic `Submit`, `Click Here`, `OK`, `Cancel`, or `Save` labels in the status and delivery flows.

### Pillar 2: Visuals (3/4)

- **Resolved finding:** Delivery class badges now use the caller's small/detail size for both the badge shell and its mark. The map is explicit at `components.ex:1614-1615,2079-2080`; the SVG sizes are defined at `components.ex:192-194`. Render-contract assertions cover both sizes at `components_test.exs:95-121`.
- **Positive evidence:** The class word remains visible next to a decorative `aria-hidden` mark (`components.ex:1571-1577,226-232`), and five mark shapes distinguish statuses without color alone (`components.ex:205-213`). Delivery cards order identity, outcome, stable ID, metadata, and update time (`deliveries_list.ex:252-335`).
- **WARNING — visual evidence unavailable:** The full page hierarchy, clipping, and card composition at the target widths cannot be judged from markup. The favicon source-hash safety stop prevented all browser/server work, so this score remains provisional.

### Pillar 3: Color (3/4)

- **Finding:** Status words and marks use semantic color roles (`components.ex:1593-1601,1575`); light and dark theme slots reference brand tokens (`assets/css/app.css:30-54,70-91`). The four scanned UI templates contain five `text-primary`/`bg-primary`/`border-primary` class matches, used for selected navigation, selected rows, filter borders, an info severity, and a focused link; color is not the only status signal.
- **Finding:** No raw hex or `rgb()` literals appear in the scanned status and operator rendering modules. The CSS theme is token-backed; this does not prove how much screen area each color occupies.
- **WARNING — rendered distribution unverified:** The 60/30/10 balance and actual contrast across complete light/dark screens need visual evidence. No screenshots were captured.

### Pillar 4: Typography (3/4)

- **Finding:** The scanned components use four named type sizes: `label` (46 matches), `body` (45), `heading` (4), and `display` (1); weights are `font-bold` (38) and `font-normal` (2). The token definitions establish 4 sizes and the 400/600 weight pair in `assets/css/app.css:123-136`.
- **Finding:** Long identifiers and verdict text have explicit wrapping rules (`deliveries_list.ex:295-304`; `components.ex:1710-1756`).
- **WARNING — rendered typography unverified:** Source inspection cannot establish that the intended font loads or how long copy wraps at narrow widths.

### Pillar 5: Spacing (3/4)

- **Resolved finding:** Mobile delivery list items now use `space-y-sm` (8px) between direct content blocks (`deliveries_list.ex:248-253`), with a focused rendered-class assertion (`operator_live_test.ex:4863-4865`). The previous no-gap finding is closed.
- **Finding:** The spacing scale is defined on a 4px grid (`assets/css/app.css:107-121`); delivery cards use `px-4 py-4`, `space-y-sm`, and named `gap-sm`/`gap-md` tokens (`deliveries_list.ex:252,270,306,333`). The scoped templates show no arbitrary `px` or `rem` spacing values.
- **WARNING — rendered balance unverified:** The new gap is present in markup, but its visual density and behavior with long values remain unobserved without a capture.

### Pillar 6: Experience Design (3/4)

- **Finding:** The delivery list distinguishes loading errors, empty pages, filtered-empty results, and a truly empty time window, and offers retry actions for load failures (`deliveries_list.ex:75-140`). Shared data-state and stat components model empty, error, permission-denied, stale, loading, and unavailable conditions (`components.ex:557-603,912-956`).
- **Finding:** Quick view has an unavailable-details retry action (`quick_view.ex:99-117`); replay actions expose pending/consumed disabled states and confirmation copy (`operator/replay_modal.ex:152-186`). Help triggers include `aria-describedby`, keyboard Escape, click-away, and focusable controls (`components.ex:1245-1255`).
- **WARNING — interaction evidence unavailable:** `workflow.ui_interaction_capture` is off, and the favicon source-hash safety stop prevented browser work. Keyboard, tap, focus, and pending-state behavior is code-derived only; no live interaction state is claimed.

---

## Files Audited

- `.planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-01-PLAN.md` through `179-04-PLAN.md`
- `.planning/phases/179-compatibility-policy-status-map-and-brand-pin/179-01-SUMMARY.md` through `179-04-SUMMARY.md`
- `mailglass_admin/lib/mailglass_admin/status_map.ex`
- `mailglass_admin/lib/mailglass_admin/copy.ex`
- `mailglass_admin/lib/mailglass_admin/components.ex`
- `mailglass_admin/lib/mailglass_admin/operator_live.ex`
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`
- `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex`
- `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex`
- `mailglass_admin/lib/mailglass/operator/deliveries.ex`
- `mailglass_admin/assets/css/app.css`
- `mailglass_admin/test/mailglass_admin/components_test.exs`
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs`
