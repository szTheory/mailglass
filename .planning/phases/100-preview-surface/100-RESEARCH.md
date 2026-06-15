# Phase 100: Preview Surface - Research

**Researched:** 2026-06-15  
**Domain:** Phoenix LiveView admin UI, Preview IA/responsive/dark-mode uplift  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Build on the existing `MailglassAdmin.PreviewLive` mounted by
  `mailglass_admin_routes/2` at `/dev/mail` plus the existing
  `mailglass_admin/lib/mailglass_admin/preview/*` components. Do not add a
  sibling LiveView, new route, production operator surface, auth path, public API,
  or core `mailglass` recipient-facing email component change.
- **D-02:** Treat Phase 97 Preview component work as settled. `DeviceFrame`,
  `Tabs`, `Sidebar`, and shared `orientation_strip` should be composed into the
  page-level Preview IA instead of being re-uplifted from scratch. Fix only the
  component details that are necessary for Phase 100 acceptance, such as touch
  target parity, mobile reachability, group hooks, and dark-mode inheritance.
- **D-03:** `?theme=dark|light` is the Preview **admin chrome** theme, matching
  Operator and Inbound URL-state semantics. Preview must apply this theme on both
  `:index` and `:show` routes; the current show-route behavior is insufficient
  because the audit script captures `/dev/mail/?theme=dark` as a Preview cell.
- **D-04:** Do not conflate admin chrome dark mode with the previewed Message's
  own dark/frame state. If implementation needs a separate previewed-message
  theme or frame toggle, it must use a distinct assign/param name and affect only
  the preview pane/frame, not the sidebar, page background, form controls, or
  route shell. The admin chrome state continues to drive the page-level
  `data-theme`.
- **D-05:** Fix the root-layout and inner-wrapper theme interaction so there is
  no split-brain state. `root.html.heex` currently falls back to
  `mailglass-light` when no root `:dark_chrome` assign exists, and
  `PreviewLive` currently assigns `dark_chrome: false` on mount. Phase 100 must
  ensure explicit `?theme=dark` produces a dark root/page, and OS dark preference
  is not defeated by an unconditional light theme when no explicit theme param is
  present. Prefer the CSS/daisyUI `prefersdark: true` path over a client JS hook.
- **D-06:** No child Preview component may set its own unrelated `data-theme`
  wrapper. Children inherit the page-level admin chrome theme unless they are
  explicitly rendering the independent previewed-message/frame theme from D-04.
- **D-07:** Preserve `Preview.Sidebar`'s native `<details>/<summary>` mailable to
  scenario hierarchy from `IA-LD-08`. Do not replace it with a flat list or custom
  JavaScript accordion.
- **D-08:** Make the Mailables/scenario navigation reachable at 390px. The current
  sidebar is `hidden md:block`, so mobile Preview cannot complete the
  preview-a-message-before-send JTBD. Add a mobile-first disclosure, inline panel,
  or equivalent responsive placement that reuses the same sidebar semantics and
  links. Avoid a new route; use CSS and LiveView.JS only if interaction is needed.
- **D-09:** Add stable Preview group test ids following the existing kebab pattern
  so the structural layer can assert the page shape without pixel diffing. At
  minimum, cover the Preview shell/root, mobile Mailables navigation, start/empty
  state, header controls, assigns form, tab strip, and preview pane.
- **D-10:** The Preview page should use the same token rhythm as Phases 98 and 99:
  outer page padding on `px-md/py-lg` to `md:px-lg/md:py-xl`, inter-group
  `gap-lg`, in-group `gap-md/gap-sm`, flat elevation (`bg-base-200 border
  border-base-300 rounded-box`), semantic tokens only, and no arbitrary spacing,
  raw hex, or off-scale type.
- **D-11:** Apply the Preview-specific Phase 96 copy locks now:
  - Start heading: "Render a real Message before you send it" (`COPY-LD-04`).
  - Start sub-copy: "Pick a Mailable from the sidebar to render it through the
    same pipeline your production sends use." (`COPY-LD-04`).
  - Start CTA: "Preview the first Mailable" (`COPY-LD-05`).
  - No-Mailables heading/sub-copy: "No Mailables discovered" and the locked
    `COPY-LD-06` explanation.
  This is not the global Phase 101 copy pass; it is the Preview requirement work
  already named by `COPY-LD-04..06` and `GAP-02`.
- **D-12:** Close `GAP-02` by ensuring the Preview index is keyboard-actionable in
  both branches. When mailables exist, render the first-previewable CTA as a
  real focusable link. When no Mailables exist, keep a real focusable setup/help
  action; do not render a bogus first-Mailable link when no previewable target
  exists. All CTA controls need visible focus rings and `min-h-11` or equivalent
  44px touch target.
- **D-13:** Bring Preview action controls up to the same touch-target floor:
  the header theme button and `AssignsForm` action buttons should use `min-h-11`
  or drop `btn-sm` where compiled CSS proves it suppresses the 44px floor. This
  mirrors the Phase 97 resolution for `DeviceFrame` and `theme_toggle`.
- **D-14:** Keep explicit loading UI out of scope unless implementation adopts
  async assigns. Preview discovery and rendering are synchronous today; adding
  loading skeletons belongs to Phase 102 unless needed to represent a real async
  state introduced by Phase 100.
- **D-15:** Extend existing ExUnit and Playwright lanes rather than adding a new
  harness. Direct `/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default`
  scenario URLs are already available in the synthetic test router; use them for
  real Preview JTBD coverage instead of relying only on `/ops/browser-preview-empty`.
- **D-16:** Structural browser coverage for Preview must include light and dark
  themes at 390, 768, and 1440 widths; exactly one `h1`; mobile Mailables
  navigation; scenario selection; header controls; assigns form; tab/pane
  visibility; focus rings; >=44px target checks for primary controls; and WCAG AA
  text/non-text contrast on real Preview groups.
- **D-17:** Update `mailglass_admin/scripts/ui-audit.sh` so its Preview comments
  and capture behavior no longer document dark mode as absent. The `preview-*-dark`
  cells must use a URL with `?theme=dark` and produce visibly dark Preview chrome
  (Ink background, Ice accent, Mist text), distinct from `preview-*-light`.
- **D-18:** Rebuild and commit `mailglass_admin/priv/static/app.css` after any
  class changes. `mix verify.preview` includes the bundle-clean gate, so an
  uncommitted CSS rebuild is a CI failure.

### the agent's Discretion

- Exact internal assign names for separating admin chrome theme from previewed
  Message/frame theme, provided `?theme=` remains admin chrome and the two states
  do not couple.
- Exact mobile placement for Mailables navigation, provided the native
  `<details>/<summary>` hierarchy remains the core IA and the navigation is
  reachable at 390px.
- Exact set of `data-testid` names, provided they follow the Preview kebab
  convention and cover the groups named in D-09.
- Exact Playwright assertion layout, provided D-16 is covered in the existing
  `operator_browser_gate` lane.

### Deferred Ideas (OUT OF SCOPE)

- Global microcopy sweep across Operator, Inbound, and Preview remains Phase 101.
  Phase 100 only applies Preview-specific locked copy needed for PAGE-03/GAP-02.
- Global motion and micro-interaction upgrades remain Phase 102. Phase 100 should
  not add decorative motion beyond what is necessary to preserve existing locked
  state/motion behavior.
- Brandbook/token authoring remains out of scope. Phase 100 consumes the existing
  token system.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAGE-03 | The Preview chrome gains full dark-mode support at parity with Operator and Inbound while the previewed email keeps an independent dark-chrome toggle. [VERIFIED: `.planning/REQUIREMENTS.md`] | Use URL-driven admin chrome theme in `PreviewLive.handle_params/3`, keep a separate previewed-message/frame state, remove root/inner forced-light fallback, and extend ExUnit plus Playwright structural coverage. [VERIFIED: codebase grep + official LiveView docs] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

No `./AGENTS.md` file exists in `/Users/jon/projects/mailglass`; no additional root-level agent directives were found. [VERIFIED: codebase grep]

No project-local `.codex/skills/` or `.agents/skills/` directory was found, so there are no project-local skill rules to load. [VERIFIED: codebase grep]

## Summary

Phase 100 should be planned as a narrowly scoped `mailglass_admin` Preview LiveView uplift, not a new feature or route. [VERIFIED: `.planning/phases/100-preview-surface/100-CONTEXT.md`] The core implementation is to split Preview admin chrome theme state from the previewed Message/frame theme state, apply `?theme=dark|light` on both index and show routes, make the existing Sidebar reachable at 390px, add stable structural hooks, and rebuild the committed CSS bundle after class changes. [VERIFIED: codebase grep]

The most important technical risk is split-brain theming. [VERIFIED: codebase grep] `PreviewLive.mount/3` currently assigns `dark_chrome: false`, the root layout renders `data-theme="mailglass-light"` when no root `:dark_chrome` assign exists, and `PreviewLive` uses `@dark_chrome` for the page wrapper and the preview dark toggle. [VERIFIED: `mailglass_admin/lib/mailglass_admin/preview_live.ex` + `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex`] daisyUI already has a `mailglass-dark` theme with `prefersdark: true`, so planning should prefer fixing forced theme attributes and URL-state parsing over adding JavaScript hooks. [VERIFIED: `mailglass_admin/assets/css/app.css`; CITED: https://daisyui.com/docs/themes/?lang=en]

Primary recommendation: implement Phase 100 in three waves: theme-state separation + root/index route correctness, Preview IA/mobile/group composition, then ExUnit/Playwright/audit-script/bundle verification. [VERIFIED: codebase grep; ASSUMED: wave sequencing judgement]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Admin chrome theme URL state | Frontend Server / LiveView | Browser / CSS | `handle_params/3` owns `?theme=` validation and assigns, while daisyUI/Tailwind CSS variables render the theme. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html; VERIFIED: codebase grep] |
| Previewed Message dark/frame toggle | Frontend Server / LiveView | Browser iframe | The state belongs to PreviewLive controls but must affect only the message frame/pane, not page chrome. [VERIFIED: `.planning/phases/100-preview-surface/100-CONTEXT.md`] |
| Mobile Mailables navigation | Browser / CSS | Frontend Server / LiveView | The existing Sidebar component already renders links; Phase 100 should alter responsive placement/visibility, using LiveView.JS only if disclosure behavior is needed. [VERIFIED: codebase grep; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html] |
| Scenario render pipeline | API / Backend | Frontend Server / LiveView | `PreviewLive.rerender/1` calls `Mailglass.Renderer.render/1`; Phase 100 should not change the production render pipeline. [VERIFIED: codebase grep] |
| Structural/a11y validation | Test / Tooling | Browser | Existing ExUnit and Playwright lanes already cover Preview; Phase 100 extends them rather than adding a harness. [VERIFIED: codebase grep] |
| CSS bundle generation | Build / Tooling | Static assets | `mix verify.preview` runs `mailglass_admin.assets.build` and then asserts `priv/static/` is clean. [VERIFIED: `mailglass_admin/mix.exs`] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Phoenix | 1.8.5 | Router/layout/endpoint foundation for the admin LiveView surfaces. [VERIFIED: `mix deps`] | Existing project dependency; no route expansion is in scope. [VERIFIED: codebase grep] |
| Phoenix LiveView | 1.1.28 | URL-state LiveView rendering, `handle_params/3`, `push_patch/2`, and optional LiveView.JS disclosure. [VERIFIED: `mix deps`; CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html] | Official docs state `handle_params/3` runs after mount and on patches, which matches Preview width/theme URL state. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html] |
| Tailwind standalone via `tailwind` Hex package | 0.4.1 | Zero-Node CSS compilation for `mailglass_admin/assets/css/app.css`. [VERIFIED: `mix deps`] | Project hard constraint requires standalone-binary Tailwind and committed bundle output. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| vendored daisyUI + `daisyui-theme` plugin | vendored in `mailglass_admin/assets/vendor` | Semantic component/theme tokens, including `mailglass-light` and `mailglass-dark`. [VERIFIED: codebase grep] | Existing CSS defines custom daisyUI themes with `mailglass-dark` marked `prefersdark: true`. [VERIFIED: `mailglass_admin/assets/css/app.css`; CITED: https://daisyui.com/docs/config/?lang=en] |
| Playwright Test | 1.59.1 | Browser structural assertions for 390/768/1440, theme contrast, focus, and JTBD flow. [VERIFIED: `mailglass_admin/package-lock.json`] | Existing `operator_browser_gate` and `structural.spec.js` use Playwright locators/assertions. [VERIFIED: codebase grep; CITED: https://playwright.dev/docs/test-assertions] |
| ExUnit + Phoenix.LiveViewTest | bundled with Elixir/Phoenix | Unit/integration checks for Preview URL state, events, and rendered DOM. [VERIFIED: codebase grep] | Existing `preview_live_test.exs` already covers width/theme params, dark toggle, tabs, assigns, and reload. [VERIFIED: codebase grep] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Phoenix.LiveView.JS | 1.1.28 via LiveView | Optional mobile disclosure without custom client hooks. [VERIFIED: `mix deps`; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html] | Use only if mobile Mailables navigation needs show/hide behavior; pure CSS responsive placement is also acceptable. [VERIFIED: `.planning/phases/100-preview-surface/100-CONTEXT.md`] |
| W3C WCAG 2.2 / WAI contrast guidance | Current W3C recommendation | Text contrast and non-text contrast acceptance thresholds. [CITED: https://www.w3.org/TR/WCAG22/; CITED: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html] | Use in Playwright contrast assertions for real Preview groups in both themes. [VERIFIED: existing `structural.spec.js`] |
| `agent-browser` | external CLI, availability not probed | Local PNG capture via `scripts/ui-audit.sh`. [VERIFIED: codebase grep] | Needed for manual 18-cell audit capture, not for automated Playwright gate. [VERIFIED: `mailglass_admin/scripts/ui-audit.sh`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| URL-state theme in `handle_params/3` | localStorage/client JS theme hook | Rejected by project constraints: no client JS hook, and Operator/Inbound already use `?theme=dark`. [VERIFIED: `.planning/REQUIREMENTS.md` + `.planning/phases/100-preview-surface/100-CONTEXT.md`] |
| Native `<details>/<summary>` Sidebar | Custom accordion component | Rejected by locked IA decision; native hierarchy is already implemented and should be preserved. [VERIFIED: `.planning/research/v1.11/SUMMARY.md` + codebase grep] |
| Existing Playwright structural lane | New visual-regression or pixel-diff harness | Rejected by project scope; structural assertions and LLM-score PNG cells are the ratchet pattern. [VERIFIED: `.planning/REQUIREMENTS.md`] |

**Installation:** No new external packages should be installed for Phase 100. [VERIFIED: `.planning/phases/100-preview-surface/100-CONTEXT.md`; VERIFIED: `mailglass_admin/package.json`]

**Version verification:** Current versions were verified with `mix deps`, `elixir --version`, `mix --version`, `node --version`, and `mailglass_admin/package-lock.json`. [VERIFIED: local commands]

## Package Legitimacy Audit

No new external packages are recommended or required for Phase 100. [VERIFIED: codebase grep]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| None | — | — | — | — | — | No install planned |

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: no package recommendations]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no package recommendations]

## Architecture Patterns

### System Architecture Diagram

```text
Browser request
  |
  v
/dev/mail or /dev/mail/:mailable/:scenario?width=...&theme=...
  |
  v
MailglassAdmin.Router.mailglass_admin_routes/2
  |
  v
MailglassAdmin.Preview.Mount discovers/assigns mailables
  |
  v
PreviewLive.mount/3 initializes stable defaults
  |
  v
PreviewLive.handle_params/3 validates URL state
  |-- index route: apply admin chrome theme, clear scenario, show start/empty IA
  |-- show route: apply admin chrome theme + width, load scenario defaults, rerender
  |
  v
Preview chrome
  |-- root/layout data-theme: admin chrome theme only
  |-- Sidebar: native details/summary Mailables navigation
  |-- header controls: device + independent message/frame theme toggle
  |-- AssignsForm: synchronous rerender controls
  |-- Tabs: HTML iframe/Text/Raw/Headers panes
  |
  v
Mailglass.Renderer.render/1 for selected scenario
  |
  v
ExUnit + Playwright + ui-audit matrix verify URL state, mobile reachability, a11y, contrast, and bundle cleanliness
```

### Recommended Project Structure

```text
mailglass_admin/
├── lib/mailglass_admin/preview_live.ex          # page IA, URL state, admin vs message theme split
├── lib/mailglass_admin/layouts/root.html.heex   # root data-theme fallback behavior
├── lib/mailglass_admin/preview/sidebar.ex       # preserved Mailables details/summary navigation
├── lib/mailglass_admin/preview/assigns_form.ex  # action touch-target parity
├── lib/mailglass_admin/preview/tabs.ex          # preview pane/test ids/iframe frame state if needed
├── test/mailglass_admin/preview_live_test.exs   # LiveView URL/event/render assertions
├── e2e/structural.spec.js                       # responsive/dark/a11y/JTBD browser assertions
├── scripts/ui-audit.sh                          # 18-cell audit capture comments and URLs
└── priv/static/app.css                          # committed regenerated CSS bundle
```

### Pattern 1: URL State Belongs in `handle_params/3`

**What:** Parse and validate `width` and `theme` query params in `handle_params/3`; use `push_patch/2` when user controls change URL-backed state. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]  
**When to use:** Use for Preview admin chrome theme and device width because both must survive direct URLs and audit capture URLs. [VERIFIED: codebase grep]  
**Example:**

```elixir
# Source: Phoenix LiveView live-navigation docs + existing PreviewLive pattern.
def handle_params(params, _uri, socket) do
  theme =
    case params["theme"] do
      value when value in ["dark", "light"] -> value
      _ -> nil
    end

  {:noreply, assign(socket, :admin_chrome_theme, theme)}
end
```

### Pattern 2: Theme Scope Must Be Single-Owner

**What:** The root/page `data-theme` represents admin chrome only; child Preview components inherit it unless they render the independent message/frame theme. [VERIFIED: `.planning/phases/100-preview-surface/100-CONTEXT.md`]  
**When to use:** Use on the outer Preview shell and root layout; do not add child `data-theme` wrappers to Sidebar, AssignsForm, DeviceFrame, or Tabs. [VERIFIED: codebase grep]  
**Example:**

```heex
<!-- Source: daisyUI data-theme docs + Phase 100 context. -->
<div data-testid="preview-shell" data-theme={@admin_chrome_data_theme} class="min-h-screen bg-base-100">
  ...
</div>
```

### Pattern 3: Native Sidebar IA With Responsive Placement

**What:** Reuse `Preview.Sidebar.sidebar/1` in desktop and mobile placement, keeping its `<details>/<summary>` semantics and relative scenario links. [VERIFIED: codebase grep]  
**When to use:** Use a mobile disclosure or inline panel above the main content at 390px; keep the desktop aside at `md` and above. [VERIFIED: `.planning/phases/100-preview-surface/100-CONTEXT.md`]  
**Example:**

```heex
<!-- Source: existing Sidebar component and Phase 100 D-08. -->
<section data-testid="preview-mobile-mailables" class="md:hidden">
  <Sidebar.sidebar
    mailables={@mailables}
    current_mailable={@current_mailable}
    current_scenario={@current_scenario}
    device_width={@device_width}
    dark_chrome={@admin_chrome_dark?}
  />
</section>
```

### Anti-Patterns to Avoid

- **Changing Preview route shape:** Adds scope and breaks adopter mount-path assumptions. Use existing `/dev/mail` and relative Sidebar links. [VERIFIED: `.planning/phases/100-preview-surface/100-CONTEXT.md`]
- **Using one `dark_chrome` assign for both admin chrome and previewed Message/frame:** This couples two independent user intents and directly violates PAGE-03. [VERIFIED: `.planning/REQUIREMENTS.md`]
- **Forcing `mailglass-light` when no explicit theme param exists:** This defeats daisyUI `prefersdark: true` and OS dark preference. [VERIFIED: `mailglass_admin/assets/css/app.css`; CITED: https://daisyui.com/docs/config/?lang=en]
- **Replacing Sidebar with custom accordion JavaScript:** Locked IA requires native details/summary hierarchy. [VERIFIED: `.planning/research/v1.11/SUMMARY.md`]
- **Adding loading skeletons without async assigns:** Preview render path is currently synchronous; explicit loading UI is deferred unless implementation introduces async state. [VERIFIED: codebase grep + Phase 100 context]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| URL state sync | Custom query parser/state store | `handle_params/3`, `<.link patch>`, `push_patch/2` | Official LiveView navigation already invokes `handle_params/3` for patches and initial render. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html] |
| Mobile disclosure | Client hook / custom JS state machine | CSS responsive placement or `Phoenix.LiveView.JS.toggle` | LiveView.JS commands are DOM-patch aware and avoid new hooks. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html] |
| Dark-mode token system | New CSS variables or raw hex classes | Existing daisyUI themes + brand tokens | Existing `mailglass-light`/`mailglass-dark` themes are already tokenized and verified. [VERIFIED: `mailglass_admin/assets/css/app.css`] |
| Contrast math from scratch in app code | Runtime contrast checker | Existing Playwright helper functions in `structural.spec.js` | Test layer already has `contrastRatio`, `assertTextContrastAA`, and `assertNonTextContrastAA`. [VERIFIED: codebase grep] |
| Visual regression | Pixel-diff screenshots | Structural assertions + gitignored PNG audit matrix | Pixel-diff is explicitly out of scope. [VERIFIED: `.planning/REQUIREMENTS.md`] |

**Key insight:** The hard parts are state ownership and verification coverage, not new library selection. [VERIFIED: codebase grep; ASSUMED: synthesis judgement]

## Common Pitfalls

### Pitfall 1: Index Route Ignores `?theme=dark`

**What goes wrong:** `/dev/mail/?theme=dark` still renders light Preview chrome, so audit dark cells are identical to light cells. [VERIFIED: `PreviewLive.handle_params/2` index branch + `ui-audit.sh`]  
**Why it happens:** The current index `handle_params/3` branch clears scenario state but does not parse the theme param. [VERIFIED: codebase grep]  
**How to avoid:** Parse admin chrome theme on both index and show route branches. [VERIFIED: official LiveView docs]  
**Warning signs:** `preview-390-dark.png` has Paper background instead of Ink; ExUnit cannot find `mailglass-dark` on index route. [VERIFIED: `ui-audit.sh` + Phase 100 context]

### Pitfall 2: Root Layout and Inner Wrapper Disagree

**What goes wrong:** The root `<html>` gets `mailglass-light` while an inner wrapper gets dark, or vice versa. [VERIFIED: codebase grep]  
**Why it happens:** `root.html.heex` defaults to light without a root assign, and `PreviewLive` currently controls an inner wrapper with `@dark_chrome`. [VERIFIED: codebase grep]  
**How to avoid:** Make admin chrome theme a single route-derived owner and avoid forced root light when theme is unspecified. [VERIFIED: Phase 100 context; CITED: https://daisyui.com/docs/config/?lang=en]  
**Warning signs:** Computed CSS variables or backgrounds differ between `html` and Preview shell. [ASSUMED]

### Pitfall 3: Admin Chrome and Message Frame Theme Coupling

**What goes wrong:** Toggling Preview message dark mode also darkens Sidebar/page controls, or `?theme=dark` changes only the email preview. [VERIFIED: PAGE-03 requirement]  
**Why it happens:** Current `toggle_dark` and `dark_chrome` naming are ambiguous and already drive wrapper `data-theme`. [VERIFIED: codebase grep]  
**How to avoid:** Rename/split assigns, params, event handlers, and tests so admin chrome and message/frame theme have separate state. [VERIFIED: Phase 100 context]  
**Warning signs:** One Playwright action changes both `data-testid="preview-shell"` theme and iframe/frame styling. [ASSUMED]

### Pitfall 4: Mobile Cannot Reach Mailables

**What goes wrong:** At 390px the desktop sidebar is hidden, so users cannot select a scenario from Preview index/show. [VERIFIED: `PreviewLive.render/1`]  
**Why it happens:** Sidebar aside is `hidden md:block` and no mobile equivalent exists. [VERIFIED: codebase grep]  
**How to avoid:** Render a mobile Mailables disclosure/section reusing `Sidebar.sidebar/1` and assert it at 390px. [VERIFIED: Phase 100 context]  
**Warning signs:** Playwright can only test empty route, not real `/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default` flow. [VERIFIED: existing `structural.spec.js`]

### Pitfall 5: H1 Duplication

**What goes wrong:** Adding mobile navigation with Sidebar duplicates the Sidebar `h1 "Mailers"` and page `h1`, violating the one-`h1` requirement. [VERIFIED: `Preview.Sidebar.sidebar/1` + Phase 100 D-16]  
**Why it happens:** `Sidebar.sidebar/1` currently renders an `h1`; Preview scenario branch also renders an `h1`. [VERIFIED: codebase grep]  
**How to avoid:** Plan a component API or wrapper strategy that preserves semantics without multiple page-level `h1`s. [ASSUMED: implementation strategy]  
**Warning signs:** `page.getByRole("heading", { level: 1 })` count exceeds 1 in Playwright. [VERIFIED: existing Playwright assertion style]

### Pitfall 6: Bundle Drift

**What goes wrong:** HEEx class changes pass tests locally but `mix verify.preview` fails because `priv/static/app.css` was not rebuilt/committed. [VERIFIED: `mailglass_admin/mix.exs`]  
**Why it happens:** `verify.preview` includes `mailglass_admin.assets.build` and `git diff --exit-code priv/static/`. [VERIFIED: `mailglass_admin/mix.exs`]  
**How to avoid:** Always run the asset build after class changes and include `priv/static/app.css` in the implementation commit. [VERIFIED: Phase 100 D-18]  
**Warning signs:** Git diff under `mailglass_admin/priv/static/` after the verify alias runs. [VERIFIED: `mailglass_admin/mix.exs`]

## Code Examples

Verified patterns from official and local sources:

### LiveView URL Param Validation

```elixir
# Source: https://phoenix-live-view.hexdocs.pm/live-navigation.html
def handle_params(params, _uri, socket) do
  socket =
    case params["theme"] do
      "dark" -> assign(socket, :admin_chrome_theme, :dark)
      "light" -> assign(socket, :admin_chrome_theme, :light)
      _ -> assign(socket, :admin_chrome_theme, nil)
    end

  {:noreply, socket}
end
```

### Playwright Contrast/Responsive Matrix Shape

```javascript
// Source: existing mailglass_admin/e2e/structural.spec.js + https://playwright.dev/docs/test-assertions
const themes = [
  { name: "light", query: "", expectedTheme: "mailglass-light" },
  { name: "dark", query: "theme=dark", expectedTheme: "mailglass-dark" }
];
const viewports = [
  { width: 390, height: 844 },
  { width: 768, height: 900 },
  { width: 1440, height: 1000 }
];
```

### daisyUI Theme Selection

```css
/* Source: https://daisyui.com/docs/themes/?lang=en and local app.css */
@plugin "../vendor/daisyui-theme" {
  name: "mailglass-dark";
  prefersdark: true;
  color-scheme: "dark";
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Preview dark mode absent/ignored | URL-driven Preview admin chrome dark mode with independent message/frame toggle | Phase 100 target, after Phase 96 `DARK-LD-06` | Planner must treat `?theme=` as chrome state and keep email preview state separate. [VERIFIED: `.planning/research/v1.11/SUMMARY.md`] |
| Pixel-diff visual regression | Structural Playwright assertions plus gitignored 18-cell PNG audit | Phase 95 ratchet | Planner should extend `structural.spec.js` and `ui-audit.sh`, not add screenshot diff tooling. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| Sidebar desktop-only | Responsive Mailables navigation reusing native details/summary | Phase 100 target | Planner must add a 390px path to scenario selection. [VERIFIED: Phase 100 context] |
| `btn-sm` accepted on controls | 44px touch target floor for primary controls | Phase 97+ | Planner must audit header theme button and AssignsForm buttons. [VERIFIED: `.planning/STATE.md` + codebase grep] |

**Deprecated/outdated:**

- `ui-audit.sh` comments claiming Preview has no effective theme param are stale for Phase 100 and must be updated. [VERIFIED: `mailglass_admin/scripts/ui-audit.sh`]
- `PreviewLive` copy "Preview the first one" and "mailer" wording is superseded by `COPY-LD-04..06`. [VERIFIED: `.planning/research/v1.11/SUMMARY.md` + codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Three implementation waves are the best sequencing. | Summary | Planner may choose a different wave split; low risk if dependencies are preserved. |
| A2 | Root/inner computed-style disagreement can be detected by comparing CSS variables/backgrounds. | Common Pitfalls | Test may need adjustment to actual DOM shape. |
| A3 | The cleanest H1 fix may require a Sidebar API/wrapper strategy. | Common Pitfalls | Planner must inspect exact component tradeoff before editing. |

## Open Questions

1. **What exact assign names should replace `dark_chrome`?**
   - What we know: `?theme=` must remain admin chrome, and message/frame theme must be separate. [VERIFIED: Phase 100 context]
   - What's unclear: Whether to rename the existing event `toggle_dark` or keep it for the independent message/frame toggle. [ASSUMED]
   - Recommendation: Planner should allocate an early task to rename/split assigns and update tests before layout work. [ASSUMED]

2. **Should mobile Mailables navigation be duplicated DOM or a shared component with heading-level control?**
   - What we know: Desktop Sidebar currently includes an `h1`, and D-16 requires exactly one `h1`. [VERIFIED: codebase grep + Phase 100 context]
   - What's unclear: The smallest clean API to preserve semantics across desktop/mobile without duplicate page `h1`s. [ASSUMED]
   - Recommendation: Add a `heading_level`/`heading_tag` or `labelled_by` option to `Sidebar.sidebar/1` if direct reuse creates H1 duplication. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit, Mix aliases | yes | 1.19.5 / OTP 28 | None needed. [VERIFIED: local command] |
| Mix | Build/test aliases | yes | 1.19.5 | None needed. [VERIFIED: local command] |
| Node.js | Playwright browser tests | yes | 22.14.0 | None needed. [VERIFIED: local command] |
| npm | Existing Playwright package scripts | yes | 11.1.0 | Use existing `node_modules` if install is not needed. [VERIFIED: local command] |
| Playwright Test | `operator_browser_gate` / structural tests | yes | 1.59.1 | None needed. [VERIFIED: `package-lock.json`] |
| Tailwind standalone binary | CSS build | yes | vendored `tailwind-macos-arm64`; Hex `tailwind` 0.4.1 | None needed. [VERIFIED: codebase grep + `mix deps`] |
| `agent-browser` | Manual `ui-audit.sh` PNG capture | not probed | — | Playwright structural tests remain automated; audit capture may require local install. [VERIFIED: `ui-audit.sh`; ASSUMED: availability] |
| Context7 CLI | Docs lookup fallback | no | — | Official docs were fetched via web. [VERIFIED: local command] |

**Missing dependencies with no fallback:** none for planning and automated validation. [VERIFIED: local commands]  
**Missing dependencies with fallback:** Context7 CLI missing; official docs were accessed directly. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest; Playwright Test 1.59.1. [VERIFIED: codebase grep + package-lock] |
| Config file | `mailglass_admin/playwright.config.cjs`; ExUnit via Mix project/test support. [VERIFIED: codebase grep] |
| Quick run command | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` [VERIFIED: existing test file] |
| Browser run command | `cd mailglass_admin && npm run test:operator-browser -- --grep Preview` [VERIFIED: `package.json`; ASSUMED: grep exactness] |
| Full suite command | `cd mailglass_admin && mix verify.preview` [VERIFIED: `mailglass_admin/mix.exs`] |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PAGE-03 | Index and scenario routes apply `?theme=dark|light` to Preview admin chrome. [VERIFIED: requirement] | ExUnit + Playwright | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | yes |
| PAGE-03 | Previewed Message/frame dark toggle remains independent of admin chrome theme. [VERIFIED: requirement] | ExUnit + Playwright | `cd mailglass_admin && npm run test:operator-browser -- --grep Preview` | needs extension |
| PAGE-03 | Mailables navigation reachable at 390px and real scenario flow works. [VERIFIED: Phase 100 context] | Playwright | `cd mailglass_admin && npm run test:operator-browser -- --grep Preview` | needs extension |
| PAGE-03 | Preview has exactly one `h1`, visible focus rings, >=44px primary controls, and WCAG AA contrast in light/dark at 390/768/1440. [VERIFIED: Phase 100 context; CITED: W3C WCAG docs] | Playwright | `cd mailglass_admin && npm run test:operator-browser -- --grep Preview` | needs extension |
| PAGE-03 | CSS bundle is regenerated and clean after class changes. [VERIFIED: Phase 100 context] | Mix alias | `cd mailglass_admin && mix verify.preview` | yes |

### Sampling Rate

- **Per task commit:** `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` for LiveView-only changes. [VERIFIED: codebase grep]
- **Per wave merge:** `cd mailglass_admin && npm run test:operator-browser -- --grep Preview` after browser-facing layout/theme changes. [VERIFIED: `package.json`; ASSUMED: grep exactness]
- **Phase gate:** `cd mailglass_admin && mix verify.preview`, plus broad browser gate when structural spec changes. [VERIFIED: `mailglass_admin/mix.exs`]

### Wave 0 Gaps

- [ ] Extend `mailglass_admin/test/mailglass_admin/preview_live_test.exs` to cover index `?theme=dark`, root/page theme behavior, and admin/message theme separation. [VERIFIED: existing file lacks index-theme coverage]
- [ ] Extend `mailglass_admin/e2e/structural.spec.js` with real Preview scenario helper and 390/768/1440 light/dark assertions. [VERIFIED: existing file only checks empty Preview in broad structural facts]
- [ ] Update `mailglass_admin/scripts/ui-audit.sh` comments and Preview capture contract. [VERIFIED: stale comments found]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | `/dev/mail` Preview is dev surface; Phase 100 adds no auth path. [VERIFIED: Phase 100 context] |
| V3 Session Management | low | Preserve existing preview session handling; do not add new session keys except explicit Preview state if already route/session-safe. [VERIFIED: `Router.__preview_session__` context via codebase grep] |
| V4 Access Control | no | Do not add production operator route or public API. [VERIFIED: Phase 100 context] |
| V5 Input Validation | yes | Continue validating URL params and atom conversion through existing safe helpers; treat params as untrusted. [VERIFIED: codebase grep; CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html] |
| V6 Cryptography | no | No cryptographic behavior in scope. [VERIFIED: Phase 100 context] |

### Known Threat Patterns for Phoenix LiveView Preview

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Atom exhaustion from user params | Denial of Service | Keep `String.to_existing_atom/1` style safe conversion; never create atoms from route params. [VERIFIED: codebase grep] |
| Preview route expansion into production surface | Information Disclosure | Do not add new route/auth path; stay inside existing dev preview mount. [VERIFIED: Phase 100 context] |
| PII leakage in fixture/seed/browser proof | Information Disclosure | Preserve existing fixture/masking discipline; do not alter production render pipeline or send path. [VERIFIED: `.planning/REQUIREMENTS.md` + codebase grep] |
| Unsafe iframe relaxation | Tampering / Information Disclosure | Keep Preview HTML iframe sandboxed; avoid broadening sandbox permissions for UI chrome work. [VERIFIED: `Preview.Tabs`] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/100-preview-surface/100-CONTEXT.md` - locked Phase 100 decisions, scope, verification requirements. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - PAGE-03 and cross-cutting constraints. [VERIFIED: local file]
- `.planning/STATE.md` - milestone locks, prior decisions, current position. [VERIFIED: local file]
- `.planning/ROADMAP.md` - Phase 100 description, success criteria, dependencies. [VERIFIED: local file]
- `.planning/research/v1.11/SUMMARY.md` - locked IA, dark-mode, motion, copy decisions. [VERIFIED: local file]
- `.planning/RATCHET-GAP-REGISTER.md` - GAP-02/GAP-03 anti-churn anchors. [VERIFIED: local file]
- `mailglass_admin/lib/mailglass_admin/preview_live.ex` - current Preview state/render behavior. [VERIFIED: local file]
- `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` - root `data-theme` behavior. [VERIFIED: local file]
- `mailglass_admin/e2e/structural.spec.js` - structural browser assertion pattern. [VERIFIED: local file]
- Phoenix LiveView live navigation docs - `handle_params/3`, patch behavior. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]
- Phoenix.LiveView.JS docs - DOM-patch-aware JS commands. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html]
- daisyUI theme/config docs - `data-theme`, `--default`, `--prefersdark`. [CITED: https://daisyui.com/docs/themes/?lang=en; CITED: https://daisyui.com/docs/config/?lang=en]
- W3C WCAG 2.2 / WAI non-text contrast - AA contrast thresholds. [CITED: https://www.w3.org/TR/WCAG22/; CITED: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html]
- Playwright assertions docs - async assertions and URL/locator checks. [CITED: https://playwright.dev/docs/test-assertions]

### Secondary (MEDIUM confidence)

- `mix deps`, `elixir --version`, `mix --version`, `node --version`, `npm --version` command output - environment versions. [VERIFIED: local command]

### Tertiary (LOW confidence)

- None used as authoritative sources. [VERIFIED: source review]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - current dependencies and scripts verified locally; no new packages recommended. [VERIFIED: local commands]
- Architecture: HIGH - implementation boundaries are locked by Phase 100 context and existing code. [VERIFIED: local files]
- Pitfalls: HIGH - main pitfalls are directly visible in current Preview/root/test/audit code. [VERIFIED: codebase grep]
- Browser audit availability: MEDIUM - Playwright is available; `agent-browser` was not probed during research. [VERIFIED: local commands; ASSUMED: fallback assessment]

**Research date:** 2026-06-15  
**Valid until:** 2026-07-15 for codebase-specific planning; re-check official docs if dependencies change. [ASSUMED]
