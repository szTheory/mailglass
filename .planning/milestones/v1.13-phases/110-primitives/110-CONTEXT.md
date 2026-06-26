# Phase 110: Primitives - Context

**Gathered:** 2026-06-18 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Second implementation phase of milestone v1.13 (Admin Design-System Stress Test & UX Uplift).
Scope: the **admin primitive layer** becomes the single reusable source for shared atoms before
forms, shell, data-display, groups, pages, fixtures, and the final ratchet inherit it.

This phase owns: public admin primitives for `nav_link`, `nav_pill`, `tenant_chip`, the 3-way
theme picker, and `stat_card`; primitive state coverage in the dev gallery; WCAG 2.2 AA/APG
semantics for these primitives; compiled-bundle target-size proof; and an icon-exists guard for
all `<.icon name="hero-*">` usage.

Hard scope line: Phase 110 **does not** own shell-level theme persistence/no-FOUC plumbing,
tenant listing/auto-select behavior, forms, responsive table/card transforms, fixture cohort
expansion, axe JSON baselining, or full matrix re-scoring. Those remain in phases 111-116.

Requirements: PRIM-01, PRIM-02, PRIM-03, PRIM-04, PRIM-05, PRIM-06, PRIM-07.
</domain>

<decisions>
## Implementation Decisions

### Public Primitive Ownership

- **D-01:** Promote `nav_link`, `nav_pill`, `tenant_chip`, the 3-way theme picker, and
  `stat_card` into `MailglassAdmin.Components` as the single exported admin primitive surface.
  The operator shell and dev gallery must render these components directly instead of keeping
  private or inlined copies.

- **D-02:** The copy-drift guard should be a concrete gate against private/inlined definitions for
  the named primitives, not a broad style lint. It should allow one implementation in
  `MailglassAdmin.Components` and fail on reintroduced shell/gallery copies.

- **D-03:** Primitive state coverage should be widened in `GalleryLive` by adding specimens for
  the real public components, not by building a parallel gallery-only component API. State rows
  should cover the phase's named states where they make sense for each primitive
  (active/selected, disabled, loading, error/empty/long-content, hover/focus-ready structure).

### Theme Picker Boundary

- **D-04:** The theme picker primitive models exactly three choices: `:system`, `:light`, and
  `:dark`. `:system` means **no explicit theme value**. The primitive may emit paths/events for
  a selected value, but it must not write `data-theme="system"`.

- **D-05:** Theme picker semantics are a **radio group visually styled as a segmented control**.
  Prefer native radios inside a `fieldset`/`legend`; if implementation needs custom markup, use
  `role="radiogroup"`, child `role="radio"`, and `aria-checked`. Do not model the three choices
  as independent `aria-pressed` toggle buttons.

- **D-06:** Phase 110 provides only the primitive. It does **not** own host-scoped persistence,
  cookie naming, first-paint no-FOUC behavior, root theme resolution, `localStorage`, `matchMedia`
  scripts, or a LiveView hook. Phase 112 wires the shell/persistence behavior on top of this
  primitive.

### Stat Card And Icon Guards

- **D-07:** Add a canonical `stat_card` primitive to `MailglassAdmin.Components` and migrate the
  existing operator overview and inbound overview stat cards to it. `stat_card` is the primitive
  Phase 113 data-display work inherits; do not leave page-local `defp stat/1` copies behind.

- **D-08:** `stat_card` shape is locked: label truncates with a tooltip/title, value uses
  tabular numerals and never wraps, severity is expressed by **icon + label + color** and never
  by color alone, and placeholder states read as meaningful states rather than bare glyphs where
  runtime data has resolved.

- **D-09:** Add a STATCARD gate that enforces canonical usage/shape without inventing a screenshot
  or pixel-diff dependency. Use the existing conformance-gate pattern where practical, and back it
  with focused component/structural assertions for behavior the grep gate cannot prove.

- **D-10:** Add an icon-exists guard against the vendored `mailglass_admin/assets/vendor/heroicons-inline.js`
  map. Every `hero-*` class referenced through `<Components.icon>` or `status_badge/1` helpers must
  exist in that embedded icon set before the CSS bundle can be considered valid.

- **D-11:** Icon usage must remain non-color-alone and non-icon-alone for meaningful states. Icons
  can stay decorative (`aria-hidden`) when adjacent text carries meaning; if an icon-only control
  remains, its accessible name and target-size proof are mandatory.

### Target Size And Accessibility Gates

- **D-12:** For WCAG 2.2 AA, gate all authored pointer targets at **at least 24px by 24px CSS
  pixels** or require a documented WCAG SC 2.5.8 exception with evidence. Dense controls do not
  receive a blanket exception.

- **D-13:** The roadmap's stricter **44px by 44px comfort floor** remains the default for normal
  admin primitives. If a dense-control 24px exception is chosen, it must be explicitly documented
  as a GAP/exception with the applicable WCAG exception and must not silently weaken the primitive
  contract.

### Claude's Discretion

- Exact component attr names and helper names, as long as shell/gallery call the same public
  component functions.
- Exact segmented-radio visual treatment for the theme picker, provided APG radio semantics and
  target-size constraints hold.
- Exact STATCARD and icon-exists gate implementation, provided it is deterministic, repo-local,
  and follows existing no-pixel-diff/zero-runtime-dependency constraints.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 110 goal and success criteria.
- `.planning/REQUIREMENTS.md` — PRIM-01..07 acceptance text and v1.13 scope locks.
- `.planning/PROJECT.md` — v1.13 milestone intent, scope locks, release posture, D-23/D-28/D-29.
- `.planning/STATE.md` — current milestone state and carried decisions from phase 109.
- `.planning/phases/109-foundations-gate-tightening/109-CONTEXT.md` — token/focus/z-index/system-theme
  decisions Phase 110 inherits.
- `.planning/research/v1.13/SUMMARY.md` — convergent v1.13 research synthesis.
- `.planning/research/v1.13/ARCHITECTURE.md` — component-lab/ratchet and token architecture.
- `.planning/research/v1.13/PITFALLS.md` — named v1.13 usability defects and lab-passes-but-ugly traps.
- `.planning/research/v1.13/STACK.md` — zero-Node asset pipeline and test-only dependency boundaries.
- `mailglass_admin/lib/mailglass_admin/components.ex` — target home for public primitives and existing
  `icon/1` / `status_badge/1`.
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` — current private shell primitive copies.
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` — current gallery-inline primitive copies and
  specimen matrix.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — current operator overview stat cards.
- `mailglass_admin/lib/mailglass_admin/inbound/overview.ex` — current private inbound `defp stat/1`.
- `mailglass_admin/assets/vendor/heroicons-inline.js` — source of truth for compiled `hero-*` icon names.
- `mailglass_admin/scripts/check-conformance.sh` — existing gate pattern for deterministic design-system checks.
- `mailglass_admin/e2e/structural.spec.js` — existing target-size, system-theme, gallery, and structural checks.
- `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` — shell component path/nav behavior tests.
- WAI-ARIA APG Radio Group Pattern: `https://www.w3.org/WAI/ARIA/apg/patterns/radio/`.
- WCAG 2.2 Target Size Minimum: `https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html`.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `MailglassAdmin.Components` already centralizes reusable atoms (`icon/1`, `logo/1`, `flash/1`,
  `badge/1`, `status_badge/1`) and is the natural home for Phase 110 primitives.
- `operator/shell.ex` contains working implementations of the shell primitives, including the
  Phase 109 `mg-focus-ring` and `min-h-11` patterns.
- `GalleryLive` already provides stable `data-testid="gallery-{component}-{state}"` cells and is
  the existing primitive stress surface.
- `heroicons-inline.js` embeds the actual icon universe used by the Tailwind standalone build.
- `structural.spec.js` already has touch-target, focus-not-obscured, system-theme, and gallery
  test scaffolding that Phase 110 can extend.

### Established Patterns

- Shared admin visual primitives live in `MailglassAdmin.Components`; page-local helpers are
  allowed only when they are not reusable atoms.
- Conformance gates are deterministic shell-script/grep checks scoped to `mailglass_admin/lib`.
- Structural proofs are Playwright assertions, not pixel diffs.
- Shipped admin CSS is a zero-Node asset artifact; bundle rebuilds are committed after class
  changes.
- System theme remains root/CSS-layer behavior: explicit `light`/`dark`, absent value for
  `system`.

### Integration Points

- Shell usage changes land in `operator/shell.ex`.
- Gallery specimen changes land in `gallery_live.ex` and structural gallery tests.
- Current stat migrations touch `operator_live.ex` and `inbound/overview.ex`.
- Icon guard reads `components.ex`/status helper usages and compares them to `heroicons-inline.js`.
- Target-size proof extends `structural.spec.js`; compiled-bundle proof likely runs after
  `mix mailglass_admin.assets.build` / existing verify lanes.
</code_context>

<specifics>
## Specific Ideas

- Treat the theme picker as a radio group with segmented styling: one-of-three choice, not three
  toggle buttons.
- Preserve `:system` as absence of explicit theme value end to end; any `data-theme="system"` is a
  regression.
- Use the existing shell primitive markup as the migration seed, but move ownership to
  `MailglassAdmin.Components`.
- Make `stat_card` a small primitive with explicit `severity`/`status` metadata rather than a
  generic card slot that cannot enforce icon+label+color.
- Gate WCAG 2.2 AA at 24x24 with documented exceptions, while preserving the roadmap's 44x44
  default for ordinary controls.
</specifics>

<deferred>
## Deferred Ideas

- Theme persistence, host-scoped cookie naming, and no-FOUC first paint — Phase 112.
- Tenant auto-select, tenant listing/switcher, and tenant-scope persistence — Phase 112.
- Form-control primitive consolidation — Phase 111.
- Data-display table/card transformations and all-surface KPI cleanup beyond primitive migration —
  Phase 113.
- Axe JSON baseline, interaction pillar expansion, rich demo fixture run, and full matrix
  re-score — Phase 116.
- Any recipient-facing email template or `brandbook/` token changes — out of milestone scope.

### Reviewed Todos (not folded)

None — `todo.match-phase 110` returned 0 matches.
</deferred>
