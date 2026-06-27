# Phase 120: Deliveries surface redesign - Context

**Gathered:** 2026-06-26 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Redesign the **Deliveries surface** — the core operator JTBD — from an info-dump into a
streamlined, focused, least-surprise interaction model, **inheriting the Phase 119 keystone
patterns** (cleaned-up shell/nav/IA, empty-pane-only orientation, triage microcopy, motion
tokens). This is surface #2 in the v1.14 biggest-impact-first order (119 → **120** → 121 → 122).

**In scope (DELIV-01 + cross-cutting matrix):** the Deliveries branch of `operator_live.ex`
(the `@view != :overview` render branch), the filters card + "Open delivery" CTA gating, the
`orientation_strip surface={:deliveries}` placement, the master-detail empty/populated states,
the `deliveries_list` no-data/no-match + `data_state` wiring, and the paired Playwright/ExUnit
gate updates. Full matrix applies: 320→wide responsive (tables → cards/lists < 768, graceful
long IDs/UUIDs/module-names/non-ASCII/high-counts/nulls), light/dark/system,
happy/empty/loading/error/permission-denied/boundary/disconnected-reconnect, WCAG 2.2 AA + APG,
Emil-Kowalski-grade transform/opacity motion, on-brand recovery-oriented microcopy.

**Out of scope (later phases / locked):** Inbound surface (Phase 121), Preview surface
(Phase 122), cross-surface coherence + arming new judgment gates into the ratchet floor +
pillar re-score (Phase 123). No new product capability, providers, transports, or routes (D-23).
Recipient-facing email HEEx + `brandbook/` tokens are OUT (brand book is source of truth).
Zero-Node *shipped* asset pipeline preserved. No new orientation copy (119 froze it). No new
motion keyframes / bespoke motion CSS (119 D-11 / v1.13 MOTION locks). No pillar re-score here.
</domain>

<decisions>
## Implementation Decisions

### Empty-state IA — gate filters / open-CTA / orientation by no-data vs no-match vs populated (D-FILTERS-ON-EMPTY)
- **D-01:** Drive the Deliveries branch off the **existing** state discriminator — do NOT invent a
  new flag. Genuine **no-data** = `@deliveries == [] and not filters_active?(@filter_params)`;
  **no-match-for-filters** = `@deliveries == [] and filters_active?`; otherwise **populated**.
  `filters_active?/1` already exists (`operator_live.ex:684-687`) and `deliveries_list` already
  branches on `@filters_active?` (`deliveries_list.ex:68-99`, emitting `operator-empty-truly` vs
  `operator-empty-filtered`).
- **D-02:** Render the **FILTERS card + "Open delivery" CTA** (`operator_live.ex:489-526`, submit
  button `:519`) only in the **populated OR no-match** states. **Withhold** them entirely in
  genuine no-data (filters/open-CTA can only act on an empty set). In no-match, keep the toolbar so
  the operator retains the **"Clear filters"** escape.
- **D-03:** In genuine no-data, show a **single onboarding/empty pane** (the
  `operator-empty-truly` "No deliveries have been recorded yet." copy is correct) — not
  filters + empty + double orientation.
- **D-04:** **Preserve the tenant-scope boundary** (security-reviewer flag, DEFECT-REGISTER):
  withholding the toolbar in no-data removes the only scope-widening vector; in no-match the
  prefilled single-tenant `tenant_id` stays scoped — `FiltersForm.fields` (`:510-516`) only
  exposes status/event/window, never a tenant-widening control. Any fix that lets the empty/no-data
  state widen tenant scope is a regression.

### Orientation-strip placement + label-tripling resolution (D-ORIENT-REDUNDANT, D-LABEL-TRIPLING)
- **D-05:** Make `orientation_strip surface={:deliveries}` **empty-pane-only** — render it ONLY in
  the genuine no-data pane (alongside `operator-empty-truly`), and **remove it from the detail
  column's `is_nil(@selected_delivery)` branch** (`operator_live.ex:581`) where it currently fires
  on every populated-but-unselected view (i.e., below a populated table). This applies the Phase 119
  D-07 empty-pane-only pattern to Deliveries.
- **D-06:** **Keep the "Select a delivery…" master-detail helper** (`operator-empty-detail`,
  `operator_live.ex:582-594`) for the populated-but-unselected case — it is the correct
  column-fill affordance, not redundant orientation. Do not delete it.
- **D-07:** **Orientation copy stays byte-frozen** (`shell.ex:382-424`) — only its render
  *condition* changes (mirrors 119 D-10). Do NOT rewrite the strip text.
- **D-08:** **D-LABEL-TRIPLING resolves as a side-effect** of D-05: removing the strip from
  populated views drops the third "Deliveries" heading, leaving the **nav item + page `<h1>`** as
  the two canonical instances. No separate edit needed.

### Cross-cutting matrix via existing capabilities + paired-test updates (DELIV-01 matrix)
- **D-09:** Route **error / permission-denied / stale / disconnected** states through the
  **existing** `deliveries_list` `data_state` capability (`deliveries_list.ex:37-67`) + the
  existing detail-column `@detail_error` branch (`operator_live.ex:568-579`). Responsive
  (<768 cards, 320→wide), long-ID/UUID/module-name/non-ASCII truncation, null handling
  (`format_datetime(nil) → "Pending"`), high-count, and masking are already implemented in
  `deliveries_list.ex` — **verify against the matrix, do not rebuild**. Building net-new
  error/permission-denied UI would duplicate a tested primitive and risk diverging from the locked
  `data_state` voice tests.
- **D-10:** **Paired test updates (mandatory, same phase — Pitfall-2 / the D-09 trap that bit 119):**
  update the suites that assert the OLD always-visible orientation before they go red on the
  green-only-forward floor — `operator.spec.js:83-115` (mobile "orientation before list" over a
  populated list), `operator.spec.js:26-32` / `:113-114`, and `operator_live_test.exs:37`
  (asserts `deliveries-orientation` present on a populated view). Add an **empty-pane-only judgment
  assertion** for Deliveries mirroring the Overview gate (`operator.spec.js:382-395`).
- **D-11:** **Motion is locked (119 D-11):** reuse existing token classes (`motion-reveal`,
  `transition-colors ease-out duration-(--duration-fast)`) — transform/opacity only, instant under
  reduced-motion. **No new keyframes / bespoke motion CSS** (protects v1.13 MOTION locks).
- **D-12:** **Microcopy is on-brand + recovery-oriented; "Oops" banned.** Empty/no-data and
  no-match copy already reads well (`deliveries_list.ex`) — keep the thoughtful-maintainer voice;
  do not introduce boilerplate or duplicate the always-visible nav.
- **D-13:** **Asset landmine (119 D-12):** any Tailwind class change to these templates requires
  `mix assets.build` + a committed `mailglass_admin/priv/static/app.css`. Watch the
  **TokenParityTest landmine** — a fresh `mix assets.build` emits raw-inline daisyUI theme blocks
  that BREAK TokenParityTest; the committed bundle is canonical. Hold the v1.13 ratchet floor +
  D-THEME-PARITY (light/dark/system) green **only-forward** — no pillar re-score here (Phase 123).

### Claude's Discretion
- Exact onboarding-pane layout/spacing in the genuine no-data state (single calm pane vs. a brief
  "what gets recorded here" hint) — pick the least-surprise, Apple-deliberate option guided by the
  plan-phase IA research and the 119-UI-SPEC patterns.
- Whether the no-match state needs any micro-affordance beyond the existing
  `operator-empty-filtered` + reset link — planner's call; default to reusing what ships.
- Precise placement/order of the master-detail columns on the populated-unselected view at the
  responsive breakpoints — inherit the 119 patterns; resolve toward least-surprise.

### Folded Todos
None — no pending todos matched Phase 120.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/v1.14/DEFECT-REGISTER.md` — the prioritized, screenshot-backed hit-list.
  Phase 120 owns **D-ORIENT-REDUNDANT**, **D-FILTERS-ON-EMPTY**, **D-LABEL-TRIPLING**; holds the
  **D-THEME-PARITY** guardrail. See the "Phase consumption guide" + the Deliveries coverage cells.
- `.planning/research/v1.14/STRESS-TEST-PROMPT.md` — the binding Apple-like deliberate-IA judgment
  rubric (redundancy / earns-its-place / least-surprise / info-dump-vs-streamlined / hierarchy /
  microcopy / semantic-icons / cross-surface-consistency). Do not dilute.
- `.planning/phases/119-app-shell-nav-overview-redesign/119-CONTEXT.md` — inherited locked
  decisions: D-07 (empty-pane-only orientation pattern Phase 120 applies), D-10 (byte-frozen
  copy — render condition only), D-11 (motion tokens, no new keyframes), D-12 (asset build +
  TokenParityTest landmine). Do not re-decide these.
- `.planning/phases/119-app-shell-nav-overview-redesign/119-UI-SPEC.md` — the Phase 119 design
  contract; extract the IA / component / spacing / motion patterns Phase 120 inherits.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — the Deliveries branch is the
  `@view != :overview` else branch in `render/1` (~488-647): filters card (`489-526`, "Open
  delivery" submit `:519`), master-detail grid (`528+`), detail-column orientation strip (`:581`)
  + "Select a delivery…" helper (`582-594`), `@detail_error` branch (`568-579`); helpers
  `filters_active?/1` (`:684`), `all_clear?/1` (`:1172`), `empty_page_meta/0` (`:1000`),
  `@status_values` (`:34`), `build_path` / `build_path_with_view`.
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` — ALREADY distinguishes
  no-data vs no-match (`68-99`: `operator-empty-truly` vs `operator-empty-filtered` + reset),
  supports `data_state` (empty/error/permission_denied/stale, `37-67`), table+card responsive
  duality, null/long-value/masking/pagination handling, `result_count_label`.
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` — `orientation_strip/1` (attr surface,
  `382-424`, byte-frozen copy); shell is already correct on active-state (fixed in 119).
- `mailglass_admin/lib/mailglass_admin/components.ex` — `stat_card` primitive, `aria-current`
  emission (wrap, never mutate the primitive).
- `mailglass_admin/e2e/operator.spec.js` — paired-test updates MANDATORY (`83-115`, `26-32`,
  `113-114`); model the empty-pane-only judgment assertion on the Overview gate (`382-395`).
- `mailglass_admin/test/.../operator_live_test.exs:37` — asserts `deliveries-orientation` on a
  populated view; MUST be updated when the strip becomes empty-pane-only.
- `reference/demo_app/assets/e2e/persona-screenshots.spec.js` — the re-shootable persona seam;
  re-shoot the Deliveries cells (`deliveries-{northstar,fjordline-aps,helios-void}-{375,1440}-{light,dark}`)
  for only-forward proof after the redesign.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The **no-data vs no-match distinction already exists and is tested** —
  `deliveries_list.ex:68-99` + `filters_active?/1` (`operator_live.ex:684`). Phase 120 *gates on*
  this truth rather than inventing a flag.
- The **`data_state` capability is already built** (empty/error/permission_denied/stale,
  `deliveries_list.ex:37-67`) — error/permission-denied/stale matrix states are a wiring +
  verification exercise, not new UI.
- **Responsive / long-value / null / masking / pagination** are already implemented in
  `deliveries_list.ex` (table+card duality, `format_datetime(nil) → "Pending"`, truncate+title,
  mask_recipient) — verify against the matrix, don't rebuild.
- The **empty-pane-only orientation pattern** was established in Phase 119 (D-07) on the Overview;
  Phase 120 applies the same render-condition gate to Deliveries.
- **Motion tokens** (`motion-reveal`, `transition-colors duration-(--duration-fast)`) already on
  the relevant elements — no new motion CSS needed.

### Established Patterns
- The byte-frozen `orientation_strip` changes render *condition*, never copy (119 D-10).
- `stat_card` is presentational — wrap in a link for interactivity, never mutate the primitive
  (nested-interactive a11y).
- Committed `priv/static/app.css` is canonical; a fresh `mix assets.build` regenerates raw-inline
  daisyUI theme blocks that trip TokenParityTest — only commit a rebuild that survives the gate.
- Paired-test trap (Pitfall-2 / 119 D-09): deleting/relocating an always-visible block on a
  green-only-forward floor REQUIRES updating the specs that assert it, in the same phase.

### Integration Points
- `operator_live.ex` Deliveries branch → `deliveries_list.ex` (`data_state` + `filters_active?`) —
  the empty-state gating seam.
- `operator_live.ex` → `shell.ex` (`orientation_strip`) — the empty-pane-only relocation seam.
- The redesign → `operator.spec.js` / `operator_live_test.exs` (paired updates) +
  `persona-screenshots.spec.js` (re-shoot Deliveries cells for only-forward proof).
</code_context>

<specifics>
## Specific Ideas

No new specific references introduced during analysis — all three assumptions were confirmed
as-is. The redesign is anchored to the DEFECT-REGISTER fix-directions and the Phase 119 patterns.
</specifics>

<deferred>
## Deferred Ideas

- **D-STORYBOOK-BRAND / D-STORYBOOK-STALE-BOOT** (Low, dev-only review surfaces) — Phase 123
  finalize / docs note, not Phase 120.
- Inbound (Phase 121) and Preview (Phase 122) inherit Phase 120's cleaned-up patterns — out of
  scope here.
- Arming new judgment gates into the ratchet floor + pillar re-score — Phase 123.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 120.
</deferred>
