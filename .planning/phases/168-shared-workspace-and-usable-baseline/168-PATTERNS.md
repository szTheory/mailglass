# Phase 168: Shared Workspace and Usable Baseline - Pattern Map

**Mapped:** 2026-10-07  
**Files analyzed:** 18 likely source, stylesheet, bundle, and acceptance touch points  
**Analogs found:** 18 / 18

Phase scope is a bounded refinement of the current Phoenix LiveView/HEEx UI. Preserve the existing stack and first complete the source/revision/served-asset reconciliation and rendered before-inventory required by CONTEXT D-10 and the UI-SPEC baseline prerequisite. The downstream plan should treat these as execution order constraints; this map does not claim that rendered evidence exists.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/admin_shell.ex` | component | request-response | same file; `AdminShellTest` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/shell.ex` | component | request-response | same file; `operator/shell_test.exs` | exact |
| `mailglass_admin/lib/mailglass_admin/surface_nav.ex` | component | request-response | same file; `components_test.exs` | exact |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | controller / LiveView | request-response | same file; `operator_live_test.exs` | exact |
| `mailglass_admin/lib/mailglass_admin/inbound_live.ex` | controller / LiveView | request-response | same file; `inbound_live_test.exs` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/accounts.ex` | utility | transform | same file; account/operator tests | exact |
| `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex` | component | request-response | same file; operator LiveView tests | exact |
| `mailglass_admin/lib/mailglass_admin/components.ex` | component | request-response | same file; `components_test.exs` | exact |
| `mailglass_admin/lib/mailglass_admin/theme.ex` | utility | transform | same file; theme/component tests | exact |
| `mailglass_admin/lib/mailglass_admin/controllers/theme_controller.ex` | controller | request-response | same file; theme controller tests | exact |
| `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex` | component | request-response | same file; `operator_live_test.exs`, browser flow | exact |
| `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` | component | request-response | same file; operator LiveView/browser flow | exact |
| `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` | component / layout | request-response | same file; `token_parity_test.exs` | exact |
| `mailglass_admin/assets/css/app.css` | config / stylesheet | transform | same file; token and bundle checks | exact |
| `mailglass_admin/priv/static/app.css` | generated asset | transform | source `assets/css/app.css`; `bundle_test.exs` | exact |
| `mailglass_admin/test/mailglass_admin/admin_shell_test.exs` | test | request-response | same file | exact |
| `mailglass_admin/test/mailglass_admin/components_test.exs` | test | request-response | same file | exact |
| `mailglass_admin/test/mailglass_admin/token_parity_test.exs`, `bundle_test.exs`, and existing focused LiveView/browser checks | test | transform / request-response | same test files and `mailglass_admin/e2e/flows.spec.js` | exact |

The test rows are candidate existing checks from RESEARCH, not a directive to create new tests. Reuse/update current assertions as needed. Keep full outbound, inbound, preview, and recipient workflow redesigns deferred to their roadmap phases.

## Pattern Assignments

### Shared Account control and navigation in the shell

**Files:** `admin_shell.ex`, `operator/shell.ex`, `surface_nav.ex`, with current consumers in `operator_live.ex` and `inbound_live.ex`.

**Shell seam:** `AdminShell.shell/1` already exposes topbar `:actions`, desktop `:sidebar`, and narrow `:mobile_nav` slots (`admin_shell.ex:29-74`). Operator shell composes theme and both navigation layouts there (`operator/shell.ex:173-216`). Place the selected Account and its switcher in the shared operator chrome through this seam; retain preview as a configured sibling surface, not an Account-scoped production surface. Use `SurfaceNav.nav/1` and its configured-path / inbound-availability filtering for active navigation (`surface_nav.ex:23-69`).

**Scope helper (retain):** `operator/shell.ex:97-115,150-158` parses the current URI, writes the chosen `tenant_id`, and carries only allowlisted compatible filters. Existing regression examples prove stale delivery/inbound record IDs are removed while compatible provider filters survive (`test/mailglass_admin/operator/shell_test.exs:81-95`). Reuse this helper for the moved control. Existing `operator_live.ex:123-166` resolves the selected tenant server-side before rendering scoped data; the option list is presentation only and must not become authorization.

```elixir
query =
  [{"tenant_id", tenant_id}] ++
    preserved_switch_query(parsed.query || "")

case URI.encode_query(query) do
  "" -> path
  encoded -> path <> "?" <> encoded
end
```

`operator/accounts.ex:24-45,47-75` maps host labels to stable IDs, falls back to the ID, and retains a selected permitted ID even if it is absent from the activity options. Keep the selected label and stable `tenant_id` visible; keep current zero/one/many and unselected-route behavior. `filters_form.ex:17-31` shows the current Account filter embedded in filters; `operator_live.ex:708-743` shows why it disappears on mobile. Refine both operator and inbound consumers consistently, preserving same-surface switching and cross-surface scope rules.

### Shared appearance and control tokens

**Files:** `components.ex`, `theme.ex`, `controllers/theme_controller.ex`, `layouts/root.html.heex`, `assets/css/app.css`, generated `priv/static/app.css`.

`Components.theme_picker/1` is a native three-radio control with per-choice events and checked state (`components.ex:347-397`); the operator shell passes the persisted selection and root theme attribute (`operator/shell.ex:173-186`). The current choice is held by `Theme` and persisted through the theme controller; `Theme.data_theme(:system)` intentionally returns `nil`, leaving system appearance to CSS (`theme.ex:31-63`). Expose visible System/Light/Dark labels and preserve this one-choice cookie/root mapping. Do not introduce another browser-storage preference.

`assets/css/app.css:107-144,192-210,257-276,483-492` is the source of semantic spacing/type, font, focus, control-size, motion, and reduced-motion tokens. Reuse these token families when tuning readability, control states, and motion. Keep exact token choices governed by the UI-SPEC, not the current 12/14px sizes by default. After source CSS changes run the existing `mix mailglass_admin.assets.build` task (`mix.exs:206-213`) and include its generated output; do not hand-edit the bundle. The static asset controller and existing bundle/parity checks preserve mountable serving and source/bundle consistency.

### Quick view and dialog behavior

**Files:** `operator/quick_view.ex`, `operator/replay_modal.ex`, shared consumers in `operator_live.ex` and `inbound_live.ex`, and `layouts/root.html.heex`.

Quick view is a URL-driven `role="dialog"` with a named title, Escape handling, two focus sentinels, and LiveView exit transition (`quick_view.ex:35-60,134-146`). Replay modal shows the existing modal pattern for keyboard dismissal, meaningful title, focus sentinels, and confirmation semantics (`replay_modal.ex:17-48,116-124`). Reuse LiveView.JS focus behavior; inspect current rendered focus containment/return and trigger return before changing presentation. Keep authorization, selected target, recent-auth, and confirmation behavior intact.

Quick view positioning currently lives in root-layout inline CSS: mobile bottom sheet and desktop right panel (`layouts/root.html.heex:24-48`). Consolidate the positioning rule in `assets/css/app.css` as scoped by the UI-SPEC, then update the old placement-only token parity assertion while retaining semantic theme/token coverage. Existing focus, reduced-motion, and overlay tokens belong to `app.css`.

### Tests and asset acceptance

`admin_shell_test.exs:9-45` is the component rendering pattern for shell slots and responsive chrome. `components_test.exs:476-548` checks theme radio semantics/states/events; update the obsolete hidden-label assertion when visible choice labels are introduced. `operator/shell_test.exs:81-95` protects URL switch behavior. Existing operator/inbound LiveView tests cover scope and filter state; Playwright `e2e/flows.spec.js` contains overlay and theme flows. `token_parity_test.exs:1-17,93-109` verifies compiled tokens, while `bundle_test.exs:20-34` checks shipped CSS/assets. Keep each safety and theme assertion that remains relevant and revise only the assertion whose expected presentation changed.

The source/revision and rendered baseline inventory is a prerequisite, not a source-pattern change: use the deterministic AtlasDesk/Northstar demo routes in the UI-SPEC after reconciling the preserved checkout, and record the actual preview-served source and assets before UI edits. Later before/after review should include the specified route, fixture, theme/OS scheme, viewport/zoom, and interaction state.

## Shared Patterns

### Host-owned scope and authorization

**Sources:** `operator/shell.ex:97-115,150-158`; `operator_live.ex:123-166`; `operator/accounts.ex:24-75`; `docs/operator-trust.md`.  
**Apply to:** Account chrome, same-surface switching, operator and inbound scope. Preserve URL identity and use server-resolved scope. UI options never grant access.

### Common UI semantics

**Sources:** `components.ex:333-397`; `admin_shell.ex:29-85`; `surface_nav.ex:23-69`.  
**Apply to:** shared Account, Appearance, and section navigation. Keep visible labels, semantic selected state, configured destinations, and the existing desktop/mobile slots.

### Motion, focus, and served assets

**Sources:** `quick_view.ex:46-60,134-146`; `replay_modal.ex:26-43,116-124`; `assets/css/app.css:197-210,257-276,483-492`; `mix.exs:206-213`.  
**Apply to:** overlays, visible keyboard focus, reduced motion, and every CSS refinement. Build the static bundle from source and keep generated assets with the stylesheet edit.

## No Analog Found

None for the bounded scope. The visible selected-Account switcher in shared operator chrome is a new composition of existing shell slots, label mapping, and URL helper; it has no existing equivalent as a single component. Use those analogs instead of inventing another scope mechanism.

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/`, `mailglass_admin/assets/css/`, `mailglass_admin/test/mailglass_admin/`, `mailglass_admin/e2e/`.  
**Tracked-source gate:** all named existing implementation/test analogs and the target generated stylesheet were checked with `git ls-files`; all are tracked.  
**Pattern extraction date:** 2026-10-07
