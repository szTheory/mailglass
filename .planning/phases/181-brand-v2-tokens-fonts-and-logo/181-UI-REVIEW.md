# Phase 181 — UI Review

**Audited:** 2026-11-17  
**Baseline:** No Phase 181 UI-SPEC.md; abstract 6-pillar standards, 181-CONTEXT/plans, and the pinned brand v2 book. Source reviewed at Phase 181 completion (`da57ad40`) to keep later uncommitted work out of scope.  
**Screenshots:** Not captured (source-only scope; the favicon producer-SHA stop forbids browser/server probes).  
**Interaction captures:** Skipped (favicon producer-SHA stop; browser/server use prohibited). Current visual and interaction evidence is unavailable.

The orchestrator reports a current Admin suite run of 1,824 tests with one `FaviconCatalogTest` producer-SHA mismatch. This audit did not run the suite or inspect the browser. No source or tests were changed.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | No generic CTA copy was introduced; the phase kept its no-copy-change boundary and existing data states are distinct. |
| 2. Visuals | 3/4 | Theme-aware inline logo and clear heading/body/code roles are present, but rendered hierarchy and responsive composition were not observed. |
| 3. Color | 2/4 | Tokens cover the planned theme roles, but the filter placeholder remains about 3.1:1 against light surfaces, below 4.5:1. |
| 4. Typography | 3/4 | Six local font faces and explicit role/weight mapping match the plan; actual rendering is unobserved in this audit. |
| 5. Spacing | 3/4 | Utilities stay on a 4px grid, but the brandbook and admin utility scales assign different values to `xl` and `2xl`. |
| 6. Experience Design | 3/4 | Accessible logo/icon markup and explicit data states are present; no current interaction state was captured. |

**Overall: 18/24**

---

## Top 3 Priority Fixes

1. **Raise the filter placeholder contrast** — the “Subject or recipient” hint is about 3.1:1 on light surfaces, making it hard to read — give `::placeholder` an explicit audited text color/opacity and remove its contrast-test exemption after both themes pass 4.5:1.
2. **Resolve the duplicate semantic spacing scales** — `xl` and `2xl` mean different values in the brandbook and admin utilities — align the values or rename/document the separate scales so shared design tokens have one unambiguous meaning.
3. **Complete a visual and keyboard pass after the favicon SHA stop clears** — this audit cannot establish the rendered logo, font loading, responsive layout, focus appearance, or interaction states — capture 1440×900, 768×1024, and 375×812 plus one keyboard-focus/interactive state then.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

No generic “Submit”, “Click Here”, “OK”, “Cancel”, or bare “Save” labels were found in the Phase 181 admin source scan. The phase context explicitly held copy and status-word changes for Phase 182; Phase 181 changed separators and replaced unsupported arrow glyphs with icons. Existing state copy is separated by meaning: stat cards have explicit empty/loading/unavailable labels (`components.ex:401-404`), while data states distinguish empty, error, permission-denied, and stale conditions (`components.ex:736-754`). No copywriting defect is evidenced in this phase’s source.

### Pillar 2: Visuals (3/4)

**WARNING — rendered visual evidence unavailable.** The implementation gives the header a consistent focal mark (`admin_shell.ex:34-40`): the inline SVG word inherits `currentColor`, while panes and overlap use separate theme roles (`components.ex:73-100`; `app.css:297-305`). The header uses `h-6 w-auto`; the phase plan records the mark at about 117px wide, above its 96px minimum. Source also defines display, body, and code roles (`app.css:537-550`). Without current captures, the visual balance, font swap, logo appearance in both themes, and mobile/tablet composition cannot be confirmed; this score is capped at 3 on source evidence.

### Pillar 3: Color (2/4)

**WARNING — text contrast exception remains.** `tokens.css` declares 39 color roles plus two logo roles in the light, dark, and system blocks; the bundle therefore carries 123 role declarations. The two daisyUI theme maps each connect 20 slots to 15 color roles (`app.css:30-54`, `70-91`). However, `contrast_contract_test.exs:288-302` deliberately exempts `::placeholder`; the recorded light-theme ratio is about 3.1:1 for the “Subject or recipient” hint at `inbound/filters_form.ex:34`, below the 4.5:1 text target. The phase summary says axe does not evaluate placeholder pseudo-text, so the clean axe baseline does not close this gap.

There are 22 source-level `primary` utility references across nine UI files. That count includes functional focus, selected-state, and icon uses; it does not establish a 60/30/10 rendered area ratio. Because screenshots are unavailable, accent distribution cannot be visually verified.

### Pillar 4: Typography (3/4)

**WARNING — current rendered font behavior unverified.** The source declares six local faces with `font-display: swap` (`app.css:156-205`), maps Tailwind bold to the shipped 600 face (`app.css:123-126`), and assigns Funnel Display to headings, Atkinson Hyperlegible Next to UI text, and Atkinson Hyperlegible Mono to code with ligatures disabled (`app.css:537-550`). The admin source uses five named size classes (`text-label`, `text-body`, `text-heading`, `text-display`, and `text-base`) and only `font-normal`/`font-bold`. This is a coherent role system; the score stays at 3 because the current face rendering and fallback transition were not observed.

### Pillar 5: Spacing (3/4)

**WARNING — two semantic scales disagree.** The brand tokens set `--mg-space-xl: 40px` and `--mg-space-2xl: 64px` (`brandbook/tokens.css:87-92`), while the admin utility theme sets `--spacing-xl: 32px`, `--spacing-2xl: 48px`, and `--spacing-3xl: 64px` (`app.css:113-121`). Both scales use 4px increments, and the source scan found no arbitrary pixel/rem spacing utilities. The shared `xl`/`2xl` names still make the intended value unclear to maintainers and adopters.

### Pillar 6: Experience Design (3/4)

**WARNING — interaction evidence unavailable.** Source inspection shows explicit empty/error/permission/stale templates (`components.ex:742-790`), focus-ring rules (`app.css:276-295`), an accessible logo name (`components.ex:75-82`), and arrow icons rendered as decorative elements inside text-labeled links (`operator_live.ex:832-838`; `operator/quick_view.ex:177-183`). Font serving uses an explicit compile-time allowlist (`controllers/assets.ex:337-353`). These support usable states and keyboard structure, but no current interaction capture was permitted, so focus, theme-toggle behavior, and resulting user flows remain unobserved here.

---

## Files Audited

- Design sources: `brandbook/tokens.json`, `brandbook/tokens.css`, `brandbook/v2/brand.json`.
- Styles/assets: `mailglass_admin/assets/css/app.css`, `mailglass_admin/assets/vendor/heroicons-inline.js`, `mailglass_admin/priv/static/app.css`, `mailglass_admin/priv/static/favicon.svg`, `mailglass_admin/priv/static/mailglass-logo.svg`.
- Admin surfaces: `components.ex`, `admin_shell.ex`, `controllers/assets.ex`, `gallery_live.ex`, `layouts/root.html.heex`, `inbound/filters_form.ex`, `inbound/quick_view.ex`, `inbound/records_list.ex`, `operator_live.ex`, `operator/deliveries_list.ex`, `operator/quick_view.ex`, `operator/repair_state.ex`, `operator/support_cards.ex`, `operator/suppression_card.ex`, and `operator/timeline.ex`.
- Contract evidence: `mailglass_admin/test/mailglass_admin/contrast_contract_test.exs`, `font_assets_contract_test.exs`, `glyph_contract_test.exs`, and `logo_assets_contract_test.exs`; Phase 181 plans and summaries.
