# Phase 110: Primitives - Research

**Researched:** 2026-06-18
**Domain:** Phoenix LiveView admin primitive components, design-system conformance, WCAG 2.2 AA/APG semantics
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for every copied constraint in this section: `.planning/phases/110-primitives/110-CONTEXT.md` [VERIFIED: repo]

### Locked Decisions

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

### the agent's Discretion

- Exact component attr names and helper names, as long as shell/gallery call the same public
  component functions.
- Exact segmented-radio visual treatment for the theme picker, provided APG radio semantics and
  target-size constraints hold.
- Exact STATCARD and icon-exists gate implementation, provided it is deterministic, repo-local,
  and follows existing no-pixel-diff/zero-runtime-dependency constraints.

### Deferred Ideas (OUT OF SCOPE)

- Theme persistence, host-scoped cookie naming, and no-FOUC first paint — Phase 112.
- Tenant auto-select, tenant listing/switcher, and tenant-scope persistence — Phase 112.
- Form-control primitive consolidation — Phase 111.
- Data-display table/card transformations and all-surface KPI cleanup beyond primitive migration —
  Phase 113.
- Axe JSON baseline, interaction pillar expansion, rich demo fixture run, and full matrix
  re-score — Phase 116.
- Any recipient-facing email template or `brandbook/` token changes — out of milestone scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PRIM-01 | Promote gallery-inlined atoms to single public components rendered identically in shell and gallery. | `operator/shell.ex` has private `nav_link`, `nav_pill`, `tenant_chip`, and `theme_toggle`; `gallery_live.ex` duplicates their HEEx instead of calling the real components. [VERIFIED: rg codebase] |
| PRIM-02 | Every primitive renders in interaction states across light/dark/system at 320 to wide, meeting WCAG 2.2 AA and APG. | Gallery already has stable `gallery-{component}-{state}` cells and twin light/dark wrappers; structural tests already exercise target-size, focus, system root behavior, and gallery cells. [VERIFIED: repo] |
| PRIM-03 | Disabled controls are visually and programmatically distinct. | Existing inbound tests cover disabled replay semantics, and Phase 110 should add component-level disabled-vs-enabled assertions to `ComponentsTest` and structural gallery checks. [VERIFIED: repo] |
| PRIM-04 | Canonical `stat_card` primitive with truncating label, no-wrap tabular value, and severity icon+label+color. | Operator overview has ad hoc stat card markup, and inbound overview has a private `defp stat/1`; neither is currently canonical. [VERIFIED: rg codebase] |
| PRIM-05 | 3-way system/light/dark theme-picker primitive exists; `system` is absence of explicit choice. | Current operator shell exposes a private binary `theme_toggle` and `dark_chrome?` boolean; Phase 109 already proved default/system means no explicit `data-theme`. [VERIFIED: repo] |
| PRIM-06 | Interactive targets meet 44px floor by default and 24px WCAG minimum only with explicit exception. | Phase 109 added structural 44px target-size assertions and fixed preview icon buttons by adding `min-w-11`; WCAG 2.2 SC 2.5.8 requires at least 24 by 24 CSS px unless an exception applies. [VERIFIED: repo] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html] |
| PRIM-07 | Every `hero-*` icon used renders a real embedded SVG and is not sole meaning. | A Node inventory found all 23 used `hero-*` names present in `heroicons-inline.js`; Phase 110 should convert that into a committed guard. [VERIFIED: node inventory] |
</phase_requirements>

## Summary

Phase 110 should be a narrow primitive-layer extraction and guard phase: move `nav_link`, `nav_pill`, `tenant_chip`, the 3-way theme picker, and `stat_card` into `MailglassAdmin.Components`, make shell and gallery call those public functions, and add deterministic gates that prevent future copies. [VERIFIED: `.planning/phases/110-primitives/110-CONTEXT.md`] The implementation should not add dependencies, shell persistence, tenant listing, axe JSON baselines, full matrix re-scoring, or data-display table/card transformations. [VERIFIED: `.planning/REQUIREMENTS.md`]

The highest-risk seam is the theme primitive: the planner must model it as a 3-option radio group, not as three independent pressed buttons, and must preserve `:system` as absence of explicit theme value. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/radio/] [VERIFIED: `.planning/phases/110-primitives/110-CONTEXT.md`] The second highest-risk seam is `stat_card`: current stat cards are page-local and inconsistent, so a grep-only STATCARD gate must be paired with focused component tests and structural overflow/no-wrap proof. [VERIFIED: rg codebase]

**Primary recommendation:** Execute Phase 110 in this order: component API tests -> move primitives into `MailglassAdmin.Components` -> migrate shell/gallery/stat call sites -> add copy-drift, STATCARD, and icon-exists gates -> extend gallery/Playwright assertions for state, system, target-size, focus, and overflow. [VERIFIED: repo]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Public primitive components | Frontend Server (Phoenix.Component HEEx) | Browser / Client for rendered interaction states | Components are stateless Phoenix function components rendered by LiveView, with interaction facts verified in browser tests. [VERIFIED: repo] |
| Copy-drift prevention | CI / Test gate | Frontend Server source layout | Existing design-system gates live in `mailglass_admin/scripts/check-conformance.sh` and scan `lib/**/*.ex`. [VERIFIED: repo] |
| Theme picker primitive | Frontend Server | Browser / Client for radio keyboard/focus behavior | Phase 110 owns markup/semantics only; Phase 112 owns persistence and no-FOUC wiring. [VERIFIED: `110-CONTEXT.md`] |
| `stat_card` primitive | Frontend Server | Browser / Client for overflow/target visual proof | The canonical shape is a component contract, while long-content/no-wrap behavior needs rendered DOM proof. [VERIFIED: repo] |
| Icon existence validation | CI / Test gate | Static asset pipeline | `heroicons-inline.js` is the source of compiled `hero-*` names, and the asset build consumes it via the Tailwind plugin. [VERIFIED: repo] |
| WCAG/APG conformance | Browser / Client structural tests | Frontend Server markup | APG roles and WCAG target/focus/contrast requirements must be visible in rendered DOM and computed styles. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/radio/] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html] |

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists at the project root, so there are no additional AGENTS directives to carry into planning. [VERIFIED: `ls AGENTS.md`]

No project-local `.codex/skills/` or `.agents/skills/` directory exists, so there are no project skill rules to load for this research. [VERIFIED: `find .codex/skills` and `find .agents/skills`]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| `phoenix_live_view` | 1.1.28 locked in `mailglass_admin/mix.lock`; Hex release date 2026-03-27. | Renders LiveViews and Phoenix function components. | Existing admin surfaces and gallery are LiveView/Phoenix.Component based. [VERIFIED: Hex registry] [VERIFIED: repo] |
| `tailwind` Hex package | 0.4.1 locked in `mailglass_admin/mix.lock`; Hex release date 2025-10-17. | Builds `assets/css/app.css` to committed `priv/static/app.css`. | Existing zero-Node asset pipeline uses the Hex Tailwind task. [VERIFIED: Hex registry] [VERIFIED: repo] |
| Tailwind CSS standalone output | 4.1.12 observed during `npm run test:operator-browser`. | Emits the utility classes used by HEEx and component primitives. | Existing asset build already compiles Tailwind v4 utility classes. [VERIFIED: command output] |
| daisyUI vendored plugins | 5.5.19 observed during `npm run test:operator-browser`; vendor files fetched 2026-04-24. | Provides theme tokens and component classes. | Existing `app.css` loads vendored `daisyui` and `daisyui-theme` plugins. [VERIFIED: repo] |
| `@playwright/test` | 1.59.1 installed locally; package currently declares `^1.59.1`. | Browser structural/a11y-adjacent verification. | Existing `structural.spec.js` and CI browser lane use it. [VERIFIED: npm registry] [VERIFIED: repo] |
| Vendored Heroicons inline plugin | Heroicons source tag v2.2.0 embedded in `heroicons-inline.js`. | Compiles `hero-*` classes to inline SVG masks. | Existing asset build uses the vendored plugin and current icon inventory is complete. [VERIFIED: repo] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `Floki` via existing tests | Existing test dependency. | Parse rendered component HTML for structural ExUnit assertions. | Use for `ComponentsTest` / `ShellTest` component contracts where browser layout is not needed. [VERIFIED: repo] |
| Node one-liner or ExUnit parser | Node 22.14.0 available locally. | Compare `hero-*` usages against `heroicons-inline.js`. | Use for icon-exists guard if implemented in shell script; ExUnit is better if planner wants package-local tests. [VERIFIED: environment] |
| `mailglass_admin/scripts/check-conformance.sh` | Existing script. | Deterministic grep gates. | Extend for COPY-DRIFT, STATCARD, and ICON-EXISTS if implemented as shell gates. [VERIFIED: repo] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Public `MailglassAdmin.Components` primitives | Keep private shell helpers and gallery copies | Recreates the current drift seam and cannot certify real shell markup from gallery tests. [VERIFIED: repo] |
| Native radios / APG radiogroup for theme picker | Three `aria-pressed` toggle buttons | Toggle buttons model independent pressed states; the requirement is one-of-three selection. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/radio/] |
| Structural/computed-style tests | Pixel screenshots | Project scope explicitly rejects pixel-diff regression; current lanes already use structural tests. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| Existing gallery | PhoenixStorybook | PhoenixStorybook is out of scope for this milestone; current gallery already provides repo-local component cells. [VERIFIED: `.planning/REQUIREMENTS.md`] |

**Installation:**

```bash
# Phase 110 installs no new packages. [VERIFIED: 110-CONTEXT.md]
```

**Version verification performed:**

```bash
cd mailglass_admin && mix deps | rg 'phoenix_live_view|tailwind'
mix hex.info phoenix_live_view 1.1.28
mix hex.info tailwind 0.4.1
cd mailglass_admin && npm exec -- playwright --version
```

## Package Legitimacy Audit

Phase 110 should not install external packages, so the package-legitimacy gate is not applicable. [VERIFIED: `.planning/phases/110-primitives/110-CONTEXT.md`]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | - | - | - | - | N/A | No install in this phase. [VERIFIED: repo] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no new package recommendation]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no new package recommendation]

## Architecture Patterns

### System Architecture Diagram

```text
LiveView render entry
  -> MailglassAdmin.Operator.Shell.shell / GalleryLive / overview surfaces
  -> public MailglassAdmin.Components primitives
       -> nav_link/nav_pill/tenant_chip/theme_picker/stat_card/icon/status_badge
       -> semantic CSS utilities from app.css and vendored heroicons-inline.js
  -> rendered DOM in light/dark/system
       -> ExUnit component tests for markup contracts
       -> check-conformance.sh grep gates for drift
       -> Playwright structural tests for target size, focus, system theme, overflow
  -> committed priv/static/app.css bundle-clean proof
```

The diagram maps data flow from LiveView render call sites through public primitives into rendered DOM and existing verification gates. [VERIFIED: repo]

### Recommended Project Structure

```text
mailglass_admin/
├── lib/mailglass_admin/components.ex        # public primitive source of truth
├── lib/mailglass_admin/operator/shell.ex    # shell consumer, no private primitive copies
├── lib/mailglass_admin/gallery_live.ex      # gallery consumer, no inlined primitive copies
├── lib/mailglass_admin/operator_live.ex     # operator stat_card consumer
├── lib/mailglass_admin/inbound/overview.ex  # inbound stat_card consumer
├── scripts/check-conformance.sh             # copy-drift/stat/icon deterministic gates
├── test/mailglass_admin/components_test.exs # component contracts
├── test/mailglass_admin/operator/shell_test.exs # shell path/nav regression contracts
└── e2e/structural.spec.js                   # rendered target-size/focus/system/overflow proof
```

This structure follows existing ownership: shared atoms in `Components`, page/shell modules as consumers, shell-script gates in `scripts`, and rendered proofs in Playwright. [VERIFIED: repo]

### Pattern 1: Public Primitive Extraction

**What:** Move reusable HEEx out of private shell/gallery functions into `MailglassAdmin.Components`, then call the same functions from shell and gallery. [VERIFIED: repo]

**When to use:** Use for `nav_link`, `nav_pill`, `tenant_chip`, `theme_picker`, and `stat_card`; do not use for page-local helpers that are not reusable primitives. [VERIFIED: `110-CONTEXT.md`]

**Example:**

```elixir
# Source: repo pattern in MailglassAdmin.Components.status_badge/1 and Shell.shell/1
<Components.nav_link
  label="Deliveries"
  icon="hero-paper-airplane"
  href={@deliveries_path}
  active={@active == :deliveries}
/>
```

### Pattern 2: Segmented Radio Theme Picker

**What:** Model the three choices as one radio group with exactly one checked value and labels for each option. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/radio/]

**When to use:** Use for `:system`, `:light`, and `:dark`; `:system` emits no explicit theme value and no `data-theme="system"`. [VERIFIED: `110-CONTEXT.md`]

**Example:**

```elixir
# Source: WAI-ARIA APG radio group role/aria-checked semantics.
<fieldset class="join" aria-label="Theme">
  <legend class="sr-only">Theme</legend>
  <label :for={choice <- [:system, :light, :dark]} class="join-item min-h-11">
    <input
      type="radio"
      name="theme"
      value={to_string(choice)}
      checked={@theme == choice}
    />
    <span>{theme_label(choice)}</span>
  </label>
</fieldset>
```

### Pattern 3: Deterministic Guard Before Broad Migration

**What:** Add focused grep/ExUnit guards that fail on reintroduced private primitive definitions and non-canonical stat markup. [VERIFIED: repo]

**When to use:** Use after migrating the current copies so gates start green. [VERIFIED: Phase 109 gate pattern]

**Example:**

```bash
# Source: existing check-conformance.sh shared-counter pattern.
if grep -rEn 'defp (nav_link|nav_pill|tenant_chip|theme_toggle|stat)\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: PRIMITIVE-DRIFT-GATE - private primitive copy found" >&2
  errors=$((errors + 1))
fi
```

### Anti-Patterns to Avoid

- **Gallery-only primitives:** A gallery copy cannot certify shell behavior; it already duplicates shell HEEx today. [VERIFIED: repo]
- **Theme persistence in Phase 110:** Cookie/localStorage/no-FOUC wiring belongs to Phase 112. [VERIFIED: `110-CONTEXT.md`]
- **`aria-pressed` tri-state picker:** The phase requires one-of-three radio semantics, not independent toggle state. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/radio/]
- **Color-only severity:** Severity must include icon, label, and color. [VERIFIED: `.planning/REQUIREMENTS.md`]
- **Screenshot/pixel-diff proof:** The milestone explicitly rejects pixel-diff regression tooling. [VERIFIED: `.planning/REQUIREMENTS.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tri-state theme selection | Custom independent toggle-button state machine | Native radio inputs or APG radiogroup semantics | Radio groups define one checked option and keyboard behavior for one-of-many choices. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/radio/] |
| Visual regression | Screenshot diff runner | Existing Playwright structural/computed-style assertions | Project scope rejects pixel-diff and existing suite is structural. [VERIFIED: repo] |
| Icon availability | Manual comments or review-only checklist | Parser comparing `hero-*` usage to `heroicons-inline.js` keys | Current icon inventory can be machine-compared and starts with zero missing icons. [VERIFIED: node inventory] |
| Stat card consistency | Page-local stat helpers | `Components.stat_card/1` plus STATCARD gate | Current operator/inbound stat markup is divergent and page-local. [VERIFIED: rg codebase] |
| Copy drift detection | Broad style lint | Narrow `defp`/inline primitive gate | Phase context asks for concrete gate against the named copies. [VERIFIED: `110-CONTEXT.md`] |

**Key insight:** Phase 110 is valuable only if the gallery and shell render the same functions; otherwise the test surface can pass while the real shell drifts. [VERIFIED: `.planning/research/v1.13/SUMMARY.md`]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None for primitive names; `rg` found `nav_link`, `nav_pill`, `tenant_chip`, `theme_toggle`, and `stat_card` in source/tests/planning artifacts, not in database migration data. [VERIFIED: rg codebase] | No data migration. [VERIFIED: repo] |
| Live service config | None found in repo-scoped service/config files for these primitive names; Phase 110 does not alter routes, external services, or tenant data. [VERIFIED: rg codebase] | No API or service patch. [VERIFIED: repo] |
| OS-registered state | None found; no launchd/systemd/pm2/task registration files reference the primitive names in the repo. [VERIFIED: rg codebase] | No re-registration. [VERIFIED: repo] |
| Secrets/env vars | None for primitive names; `.env.example` only contains demo port variables, and no `MAILGLASS_*THEME` primitive env var was found. [VERIFIED: rg codebase] | No secret/env update. [VERIFIED: repo] |
| Build artifacts | `_build`, `deps`, `mailglass_admin/node_modules`, and `priv/static/app.css` exist; only `priv/static/app.css` is a committed artifact that must be rebuilt if class strings change. [VERIFIED: find and repo] | Rebuild CSS after HEEx class changes and require `git diff --exit-code priv/static/`. [VERIFIED: `mix help mailglass_admin.assets.build`] |

**Nothing found in category:** all five runtime-state categories were checked explicitly. [VERIFIED: commands above]

## Common Pitfalls

### Pitfall 1: Certifying A Copy Instead Of The Real Primitive

**What goes wrong:** Gallery tests pass because they render copied HEEx, while shell behavior drifts. [VERIFIED: `gallery_live.ex`]

**Why it happens:** `gallery_live.ex` currently re-implements `nav_link`, `nav_pill`, `tenant_chip`, and `theme_toggle` instead of calling shell or shared components. [VERIFIED: rg codebase]

**How to avoid:** Move the primitives first, then make both shell and gallery call `MailglassAdmin.Components`. [VERIFIED: `110-CONTEXT.md`]

**Warning signs:** `defp render_specimen(%{component: :nav_link})` contains full HEEx markup, or `operator/shell.ex` still contains `defp nav_link`. [VERIFIED: repo]

### Pitfall 2: Pulling Theme Persistence Into The Primitive Phase

**What goes wrong:** A primitive task adds cookies, localStorage, matchMedia scripts, or no-FOUC root behavior, overlapping Phase 112. [VERIFIED: `110-CONTEXT.md`]

**Why it happens:** The current binary `theme_toggle` is coupled to `toggle_theme_path/2`, so it is tempting to solve the whole theme system at once. [VERIFIED: `operator/shell.ex`]

**How to avoid:** Phase 110 produces a semantic 3-option primitive and test specimens only; Phase 112 wires persistence/no-FOUC. [VERIFIED: `110-CONTEXT.md`]

**Warning signs:** New `localStorage`, `sessionStorage`, `window.matchMedia`, `phx-hook`, or `data-theme="system"` appears in `mailglass_admin/lib`. [VERIFIED: Phase 109 TOKEN-SCOPE-GATE]

### Pitfall 3: Passing WCAG 2.5.8 By Weakening The Project Floor

**What goes wrong:** A dense control passes the WCAG 24px minimum but silently weakens the roadmap's 44px admin floor. [VERIFIED: `.planning/REQUIREMENTS.md`] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html]

**Why it happens:** WCAG 2.2 AA minimum target size is 24 by 24 CSS pixels with exceptions, while this project has a stricter default comfort floor for normal controls. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html] [VERIFIED: `110-CONTEXT.md`]

**How to avoid:** Keep normal primitives at 44px, and document/gate any dense 24px exception explicitly. [VERIFIED: `110-CONTEXT.md`]

**Warning signs:** Icon buttons with only `btn-square btn-sm` or only `min-h-11` and no width floor. [VERIFIED: Phase 109 summary]

### Pitfall 4: Stat Card Shape Proved Only By Grep

**What goes wrong:** All call sites use `<Components.stat_card>`, but labels still clip or values wrap at 320px. [VERIFIED: v1.13 research]

**Why it happens:** A grep gate can prove usage, not computed layout. [VERIFIED: repo test pattern]

**How to avoid:** Pair STATCARD-GATE with ExUnit assertions for markup shape and Playwright assertions for `scrollWidth`, `white-space`, and target rows at narrow viewport. [VERIFIED: existing structural test approach]

**Warning signs:** `break-words` or page-local `text-display` stat markup remains after migration. [VERIFIED: rg codebase]

### Pitfall 5: Invisible Icons After Adding A New `hero-*` Name

**What goes wrong:** HEEx contains a `hero-*` class that is not embedded in `heroicons-inline.js`, so the compiled bundle has no SVG for it. [VERIFIED: Phase 76 precedent]

**Why it happens:** The icon set is intentionally vendored and finite. [VERIFIED: `heroicons-inline.js`]

**How to avoid:** Add an icon-exists gate that compares every `hero-*` name in `lib/**/*.ex` to the vendored `icons` object. [VERIFIED: node inventory]

**Warning signs:** A new `Components.icon name="hero-..."` appears without a corresponding vendor entry and bundle rebuild. [VERIFIED: repo]

## Code Examples

Verified patterns from existing repo sources:

### Component Contract Test

```elixir
# Source: mailglass_admin/test/mailglass_admin/components_test.exs
html = render_component(&Components.status_badge/1, status: :delivered, size: :sm)
assert html =~ "badge-success"
assert html =~ "hero-check-circle"
assert html =~ "Delivered"
```

Use the same direct `render_component/2` pattern for `nav_link`, `nav_pill`, `tenant_chip`, `theme_picker`, and `stat_card`. [VERIFIED: repo]

### Structural Target-Size Assertion

```javascript
// Source: mailglass_admin/e2e/structural.spec.js
async function assertTouchTarget(locator, label) {
  await expect(locator.first(), label).toBeVisible();
  const box = await locator.first().boundingBox();
  expect(Math.round(box.width), `${label} target-size width`).toBeGreaterThanOrEqual(44);
  expect(Math.round(box.height), `${label} target-size height`).toBeGreaterThanOrEqual(44);
}
```

Use the existing helper for normal admin primitives, and add explicit exception tests only when a dense 24px case is documented. [VERIFIED: repo] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html]

### Icon Inventory Guard Shape

```javascript
// Source: research Node inventory against repo files.
const used = new Set([...source.matchAll(/hero-[a-z0-9-]+/g)].map(match => match[0].slice(5)));
const available = new Set([...vendor.matchAll(/"([a-z0-9-]+)":\s*"<svg/g)].map(match => match[1]));
const missing = [...used].filter(name => !available.has(name));
if (missing.length) throw new Error(`Missing heroicons: ${missing.join(", ")}`);
```

Current inventory result: `missing: []` across all 23 used icons. [VERIFIED: node inventory]

## State of the Art

| Old Approach | Current Approach | When Changed / Observed | Impact |
|--------------|------------------|--------------------------|--------|
| Private shell primitives plus gallery copies | Public shared primitives consumed by shell and gallery | Required by Phase 110. [VERIFIED: `110-CONTEXT.md`] | Removes copy drift and lets gallery certify real components. [VERIFIED: repo] |
| Binary light/dark toggle | 3-way system/light/dark picker primitive with radio semantics | Required by PRIM-05. [VERIFIED: `.planning/REQUIREMENTS.md`] | Models one-of-three choice and preserves `system` as no explicit theme. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/radio/] |
| Page-local stat cards | Canonical `Components.stat_card/1` | Required by PRIM-04. [VERIFIED: `.planning/REQUIREMENTS.md`] | Prevents clipped labels and inconsistent KPI design. [VERIFIED: v1.13 research] |
| Manual icon review | Deterministic icon-exists guard | Required by PRIM-07. [VERIFIED: `.planning/REQUIREMENTS.md`] | Prevents invisible `hero-*` icons in the standalone Tailwind pipeline. [VERIFIED: repo] |
| Pixel or visual review only | Structural/computed-style Playwright proof | Existing repo pattern. [VERIFIED: `structural.spec.js`] | Keeps proof screenshot-free and deterministic. [VERIFIED: `.planning/REQUIREMENTS.md`] |

**Deprecated/outdated:**

- Private `defp nav_link`, `defp nav_pill`, `defp tenant_chip`, and `defp theme_toggle` in shell are now known drift points for Phase 110. [VERIFIED: rg codebase]
- Gallery-inline primitive HEEx is now known insufficient as certification evidence. [VERIFIED: `.planning/research/v1.13/SUMMARY.md`]
- `theme_toggle` as a binary button is superseded by the 3-way theme-picker primitive. [VERIFIED: `.planning/REQUIREMENTS.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All claims in this research are sourced from repo-local artifacts, commands run in this session, npm/Hex registry checks for existing tools, or official W3C documentation; no `[ASSUMED]` claims are intentionally present. [VERIFIED: research process]

## Open Questions (RESOLVED)

1. **Exact public component attr names**
   - What we know: The context grants discretion on attr/helper names as long as shell and gallery call the same public functions. [VERIFIED: `110-CONTEXT.md`]
   - What's unclear: Whether planner wants `theme_picker` to emit `patch`, `href`, or `event` attrs. [VERIFIED: code inspection]
   - Recommendation: Keep attrs close to current shell needs: `label`, `icon`, `href`, `active`; `tenant`; `theme`, `options`, and path/event assigns. [VERIFIED: repo]
   - RESOLVED: Plans 110-01 through 110-03 use attr-declared public Phoenix components in `MailglassAdmin.Components`; shell and gallery call the same public functions, `theme_picker` emits the selected value through the public component API, and Phase 112 remains responsible for persistence/no-FOUC wiring. [VERIFIED: PLAN.md alignment]

2. **Dense-control exceptions**
   - What we know: Normal admin primitives should meet 44px; WCAG 2.2 AA minimum is 24px with exceptions. [VERIFIED: `110-CONTEXT.md`] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html]
   - What's unclear: Whether any Phase 110 primitive needs a dense exception. [VERIFIED: code inspection]
   - Recommendation: Plan for no dense exceptions in Phase 110; document any exception as a GAP if discovered by structural tests. [VERIFIED: phase scope]
   - RESOLVED: Phase 110 plans require zero dense-control exceptions; normal interactive primitives must meet the 44px by 44px default in the compiled bundle, and any failure is fixed in the primitive rather than weakening the contract. [VERIFIED: PLAN.md alignment]

3. **STATCARD severity taxonomy**
   - What we know: Shape requires icon+label+color and meaningful placeholders. [VERIFIED: `110-CONTEXT.md`]
   - What's unclear: Exact severity atoms and icon mapping for neutral/success/warning/error/info stat cards. [VERIFIED: code inspection]
   - Recommendation: Define a small closed atom set in `Components.stat_card/1`, and test each atom like `status_badge/1`. [VERIFIED: repo pattern]
   - RESOLVED: Plans 110-01 and 110-02 lock `stat_card` to the closed severity atom set `:neutral`, `:info`, `:success`, `:warning`, and `:error`; every state requires a visible severity label, semantic color, and adjacent icon, with empty/loading/unavailable states using meaningful text. [VERIFIED: PLAN.md alignment]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit and Mix verification | yes | 1.19.5 / OTP 28 | none needed. [VERIFIED: command] |
| Mix | package tests and asset build | yes | 1.19.5 / OTP 28 | none needed. [VERIFIED: command] |
| Node.js | Playwright and icon guard scripts | yes | 22.14.0 | ExUnit parser could replace Node guard. [VERIFIED: command] |
| npm | browser test package scripts | yes | 11.1.0 | none needed. [VERIFIED: command] |
| ripgrep | conformance and research scans | yes | 15.1.0 | grep, but rg is preferred. [VERIFIED: command] |
| Playwright | structural browser tests | yes | 1.59.1 installed locally | none needed. [VERIFIED: command] |
| GSD helper CLI | research-plan/cache/classify seams | no | present but errors on missing `../../../package.json` | Use repo-local evidence and official docs; note unavailability. [VERIFIED: command] |

**Missing dependencies with no fallback:**
- None for Phase 110 implementation/verification. [VERIFIED: environment audit]

**Missing dependencies with fallback:**
- GSD helper CLI is unavailable for research cache/classify only; Phase planning can proceed from local artifacts and official docs. [VERIFIED: command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5 and Playwright 1.59.1. [VERIFIED: command] |
| Config file | `mailglass_admin/playwright.config.cjs` for browser tests; Mix aliases in `mailglass_admin/mix.exs`. [VERIFIED: repo] |
| Quick run command | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs --warnings-as-errors`. [VERIFIED: command] |
| Full suite command | `bash mailglass_admin/scripts/check-conformance.sh && cd mailglass_admin && mix verify.support_contract.admin && mix verify.preview && npm run test:operator-browser`. [VERIFIED: repo] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PRIM-01 | Shell and gallery call public primitives; no private/inlined copies remain. | unit + grep | `bash mailglass_admin/scripts/check-conformance.sh` plus focused `mix test test/mailglass_admin/operator/shell_test.exs --warnings-as-errors` | yes; extend gate/test. [VERIFIED: repo] |
| PRIM-02 | Primitive state cells render across light/dark/system and interaction states. | e2e structural | `cd mailglass_admin && npm run test:operator-browser -- --grep "gallery"` | yes; extend gallery block. [VERIFIED: repo] |
| PRIM-03 | Disabled controls are visually/programmatically distinct. | unit + e2e structural | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors` and Playwright disabled/enabled computed-style check | yes; add tests. [VERIFIED: repo] |
| PRIM-04 | Canonical stat_card shape and usage. | unit + grep + e2e overflow | `bash mailglass_admin/scripts/check-conformance.sh` and `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors` | yes; add STATCARD rows. [VERIFIED: repo] |
| PRIM-05 | 3-way theme picker with radio semantics and no `data-theme="system"`. | unit + e2e structural | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors` and Playwright system/default grep | yes; add theme picker tests. [VERIFIED: repo] |
| PRIM-06 | Target-size floor verified in compiled bundle. | e2e structural + bundle-clean | `cd mailglass_admin && npm run test:operator-browser -- --grep "touch targets"` and `mix mailglass_admin.assets.build && git diff --exit-code priv/static/` | yes; extend selectors. [VERIFIED: repo] |
| PRIM-07 | All `hero-*` names exist in `heroicons-inline.js`; icons not sole meaning. | grep/script + unit review | node/ExUnit icon inventory guard plus component tests for adjacent labels/access names | gap; add guard. [VERIFIED: repo] |

### Sampling Rate

- **Per task commit:** `bash mailglass_admin/scripts/check-conformance.sh` plus focused ExUnit for touched component. [VERIFIED: repo]
- **Per wave merge:** `cd mailglass_admin && mix verify.support_contract.admin` and focused `npm run test:operator-browser -- --grep "gallery|touch targets|system|focus"`. [VERIFIED: command]
- **Phase gate:** `cd mailglass_admin && mix verify.preview && npm run test:operator-browser`, with `git diff --exit-code priv/static/` after any class change. [VERIFIED: repo]

### Wave 0 Gaps

- [ ] Extend `mailglass_admin/test/mailglass_admin/components_test.exs` for `nav_link`, `nav_pill`, `tenant_chip`, `theme_picker`, and `stat_card`. [VERIFIED: repo]
- [ ] Extend `mailglass_admin/scripts/check-conformance.sh` with PRIMITIVE-DRIFT, STATCARD, and ICON-EXISTS gates. [VERIFIED: repo]
- [ ] Extend `mailglass_admin/e2e/structural.spec.js` gallery block for system wrapper/emulation, target-size on new primitives, disabled/enabled distinction, and stat-card overflow/no-wrap proof. [VERIFIED: repo]
- [ ] Add gallery specimens for `stat_card` and 3-way theme picker; replace copied nav/tenant/theme specimens with public component calls. [VERIFIED: repo]

### Verified Baseline During Research

- `bash mailglass_admin/scripts/check-conformance.sh` -> `OK: design-system conformance clean.` [VERIFIED: command]
- `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` -> 45 tests, 0 failures. [VERIFIED: command]
- `cd mailglass_admin && npm run test:operator-browser -- --grep "gallery renders nav_link|gallery twin-theme|touch targets|system/default"` -> 8 tests, 0 failures. [VERIFIED: command]

## Security Domain

Security enforcement is treated as enabled because `.planning/config.json` does not set `security_enforcement: false`. [VERIFIED: repo]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 110 does not change auth; existing operator mount/auth remains the boundary. [VERIFIED: phase scope] |
| V3 Session Management | no | Theme persistence/cookies are deferred to Phase 112. [VERIFIED: `110-CONTEXT.md`] |
| V4 Access Control | yes, indirectly | Components must not create tenant listing or cross-tenant behavior; tenant seam remains Phase 112/core read model. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| V5 Input Validation | yes | Component attrs should use Phoenix `attr` declarations and closed atom values where practical. [VERIFIED: existing `Components.status_badge/1` pattern] |
| V6 Cryptography | no | No cryptographic behavior in primitive components. [VERIFIED: phase scope] |

### Known Threat Patterns for Phoenix/LiveView Primitives

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Icon class injection or invisible icon from unvalidated `hero-*` name | Tampering / Information disclosure by misleading UI | Closed icon inventory guard against `heroicons-inline.js`, plus adjacent text/access names for meaning. [VERIFIED: repo] |
| Disabled-looking-enabled or enabled-looking-disabled controls | Spoofing / Repudiation of user intent | Programmatic disabled state plus visible disabled styling tests. [VERIFIED: PRIM-03] |
| Theme primitive accidentally writes global storage or root script | Tampering with host app UI | Phase 110 must not add storage/hook/no-FOUC wiring; Phase 109 TOKEN-SCOPE-GATE already blocks theme creep in `lib`. [VERIFIED: repo] |
| Tenant chip becoming an unscoped tenant selector early | Information disclosure | Keep `tenant_chip` read-only in Phase 110; tenant listing and switching remain Phase 112 via scoped core read model. [VERIFIED: `110-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/110-primitives/110-CONTEXT.md` - locked decisions, discretion, deferred scope, canonical refs. [VERIFIED: repo]
- `.planning/REQUIREMENTS.md` - PRIM-01..07 and v1.13 scope locks. [VERIFIED: repo]
- `.planning/ROADMAP.md` - Phase 110 success criteria and sequencing. [VERIFIED: repo]
- `.planning/STATE.md` - Phase 109 inherited decisions and current milestone state. [VERIFIED: repo]
- `.planning/phases/109-foundations-gate-tightening/*-SUMMARY.md` - completed foundation gates, system proof, and target-size findings. [VERIFIED: repo]
- `.planning/research/v1.13/SUMMARY.md`, `ARCHITECTURE.md`, `PITFALLS.md`, `STACK.md` - convergent v1.13 research. [VERIFIED: repo]
- `mailglass_admin/lib/mailglass_admin/components.ex` - current shared atoms and `status_badge/1` precedent. [VERIFIED: repo]
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` - current private primitive copies and binary theme toggle. [VERIFIED: repo]
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` - current inlined gallery primitive copies and specimen matrix. [VERIFIED: repo]
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` and `mailglass_admin/lib/mailglass_admin/inbound/overview.ex` - current stat-card call sites. [VERIFIED: repo]
- `mailglass_admin/assets/vendor/heroicons-inline.js` - vendored icon source of truth. [VERIFIED: repo]
- `mailglass_admin/scripts/check-conformance.sh` and `mailglass_admin/e2e/structural.spec.js` - existing guard/test lanes. [VERIFIED: repo]

### Secondary (MEDIUM/HIGH confidence)

- WAI-ARIA APG Radio Group Pattern - radio group semantics, keyboard behavior, roles, `aria-checked`, and labeling. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/radio/]
- WCAG 2.2 Understanding SC 2.5.8 Target Size Minimum - 24 by 24 CSS px minimum and exceptions. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html]
- WCAG 2.2 Understanding SC 2.4.11 Focus Not Obscured - focused component not entirely hidden by author-created content. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html]
- WCAG 2.2 Understanding SC 2.4.13 Focus Appearance - focus indicator contrast/area requirements. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html]
- WCAG 2.2 Understanding SC 1.4.11 Non-text Contrast - 3:1 contrast for meaningful UI visual cues. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html]
- Hex registry for `phoenix_live_view` 1.1.28 and `tailwind` 0.4.1. [VERIFIED: Hex registry]
- npm registry/local install checks for `@playwright/test` 1.59.1. [VERIFIED: npm registry]

### Tertiary (LOW confidence)

- None. [VERIFIED: source list]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - all recommendations use existing locked packages/tools and no new installs. [VERIFIED: repo]
- Architecture: HIGH - primitive seams and call sites were inspected directly. [VERIFIED: rg codebase]
- Pitfalls: HIGH - each pitfall maps to current code or official W3C semantics. [VERIFIED: repo] [CITED: W3C]
- External docs: MEDIUM/HIGH - official W3C pages were opened directly; no non-official a11y sources were needed. [CITED: W3C]
- GSD seam: LOW for cache/classification - `gsd-tools.cjs` failed due missing `../../../package.json`, so research cache/classify could not be used. [VERIFIED: command]

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 for repo-local implementation seams; revisit official W3C/package details if planning is delayed beyond 30 days. [VERIFIED: date]
