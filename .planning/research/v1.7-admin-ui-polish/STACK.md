# Design-System Tooling Stack — mailglass_admin UI/UX Polish v2 (v1.7)

**Project:** mailglass_admin  
**Researched:** 2026-06-03  
**Milestone scope:** v1.7 Admin UI — IA & Design-System Polish v2 (Phases 74–79)  
**Confidence:** HIGH (all claims verified against live source files and Context7 LV docs)

---

## Verdict: No New Dependencies Required

The existing toolchain — Tailwind v4.1.12 standalone binary, daisyUI 5 vendor JS, Phoenix LiveView 1.1.x — already supplies every mechanism needed for Phases 74–79. This is a **pure application milestone**: correct application of the shipped v1 design system, not a system extension.

No new Hex packages. No new vendor JS files. No new tooling. The `tailwind` Hex package (0.4.1) and its downloaded binary (4.1.12) cover all token and JIT work. daisyUI 5 covers all component classes. Phoenix LiveView JS covers all motion orchestration. This conclusion is stated explicitly because the blueprint asks for it explicitly.

---

## Tooling In Use (Confirmed Versions)

| Tool | Version | Role in v1.7 | Config location |
|------|---------|--------------|-----------------|
| `tailwind` Hex package | 0.4.1 | Downloads + invokes the standalone Tailwind v4 binary | `mailglass_admin/mix.exs` dep; `mix mailglass_admin.assets.build` task |
| Tailwind CSS standalone binary | 4.1.12 | JIT compilation of `assets/css/app.css` → `priv/static/app.css` | `config/config.exs` `config :tailwind, version: "4.1.12"` |
| daisyUI 5 | 5.x (fetched 2026-04-24 from latest release) | Semantic component classes (`badge`, `btn`, `card`, `rounded-box/field`) + `@plugin "daisyui"` and `@plugin "daisyui-theme"` integration | `assets/vendor/daisyui.js`, `assets/vendor/daisyui-theme.js` |
| Phoenix LiveView | ~> 1.1 (1.1.x) | `Phoenix.LiveView.JS` commands; `phx-mounted` / `phx-remove` bindings | `mailglass_admin/mix.exs` |
| `agent-browser` CLI | ad-hoc (not pinned, not in CI) | Screenshot capture for the visual audit loop | `mailglass_admin/scripts/ui-audit.sh` |

---

## Section 1 — Phoenix LiveView Motion Mechanics

### How `phx-mounted` works (confirmed, HIGH confidence)

`phx-mounted` is a LiveView binding that executes a JS command exactly once: when the element is **first inserted into the DOM**. It does not re-fire on LiveView diff patches. This is the correct mechanism for entrance animations.

```heex
<div phx-mounted={JS.transition("motion-reveal", time: 220)}>
  …content…
</div>
```

`JS.transition/2` adds the given class(es) temporarily (for `time` ms) then removes them. For the design system's `@keyframes`-backed classes (`motion-reveal`, `motion-overlay`, `motion-tab-swap`), the animation fires and the class is removed — leaving no residual state.

### The mount-vs-patch bug (confirmed, HIGH confidence)

The bug the blueprint flags exists today in `operator_live.ex`. The detail pane renders:

```heex
<% true -> %>
  <div class="motion-reveal space-y-4">
    …
  </div>
```

This `<div>` has **no `id` attribute**. LiveView's DOM differ identifies elements by their `id`. Without an `id`, the differ treats this div as a stable, persistent element and patches it in place when the selected delivery changes — meaning `motion-reveal` fires the CSS animation only when this branch is first entered (nil → delivery), not on every delivery switch. That is arguably correct behavior, but it means the animation will NOT re-fire when the user clicks a different row.

If the intent is "animate on each new selection," add a delivery-keyed `id`:

```heex
<div id={"delivery-detail-#{@selected_delivery.id}"} class="motion-reveal space-y-4">
```

LiveView will destroy and re-create this element on each delivery switch, firing `motion-reveal` each time. Use `phx-mounted` instead of relying on CSS-only if the JS command is needed for cross-browser reliability:

```heex
<div id={"delivery-detail-#{@selected_delivery.id}"}
     phx-mounted={JS.transition("motion-reveal", time: 220)}
     class="space-y-4">
```

The existing `preview/tabs.ex` demonstrates the correct pattern already:

```heex
<div id={"preview-tab-" <> Atom.to_string(@active_tab)} class="motion-tab-swap">
```

The tab content re-mounts on each tab switch because the `id` changes — `motion-tab-swap` fires for each genuine selection. This is the model to follow for detail-pane and orientation transitions.

### `Phoenix.LiveView.JS` transitions vs CSS-only (HIGH confidence)

Two distinct approaches; understanding when to use each matters for Phase 76 (motion polish):

| Approach | Mechanism | Use when |
|----------|-----------|----------|
| CSS-only (class on element) | `@keyframes` fires when class is present; class stays permanently | Element is always in the DOM; animation fires on first mount via CSS `animation:` property; `motion-reveal` on a div that appears via `:if` |
| `phx-mounted` + `JS.transition` | LV fires JS command at mount; class added temporarily, then removed | Need re-fire on re-mount; want explicit control; combining with `:if` or dynamic ids |
| `JS.show` / `JS.hide` with `transition:` option | LV controls visibility; adds/removes CSS classes during show/hide | Modal/overlay enter and exit; flash toast |

For the design system's six named motions, the CSS-only approach works for one-shot entrance animations on elements controlled by `:if`. The `phx-mounted` + `JS.transition` approach is needed when an element stays in the DOM but should re-animate on data changes (e.g., detail pane keyed by delivery id).

The `motion-tab-swap` pattern (CSS class `animation:` on an element whose `id` changes) is idiomatic and should be the reference pattern for the Operator Overview landing.

### `prefers-reduced-motion` — how it is handled (HIGH confidence)

The existing `app.css` contains a global override block:

```css
@media (prefers-reduced-motion: reduce) {
  *, ::before, ::after {
    animation-duration: 0.01ms !important;
    animation-delay: 0ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

This is the correct Node-free Tailwind v4 pattern. It:

- Collapses all animations and transitions to effectively instant (0.01ms, not 0ms — `0ms` has browser-specific bugs in some contexts)
- Zeros animation delays so staggered timelines snap
- Preserves opacity crossfades (they still execute, just instantly) — opacity changes remain meaningful for screen readers and for the visual distinction between states
- Requires no Tailwind plugin, no PostCSS, no JavaScript — pure CSS

No changes to this block are needed for v1.7. New motion classes added in Phase 76 are automatically covered. The `!important` overrides take precedence over any animation specified inline via `JS.transition`, because JS.transition ultimately sets CSS properties that the media query overrides.

There is no `motion-safe:` / `motion-reduce:` Tailwind utility needed here — the global `@media` block is simpler, more reliable in a standalone-binary setup (no PostCSS variants to configure), and already in production.

---

## Section 2 — Tailwind v4 Standalone Binary Mechanics

### Binary vs Node-based (HIGH confidence)

The `tailwind` Hex package (0.4.x) downloads a platform-specific Tailwind v4 standalone binary to `_build/tailwind-macos-arm64` (or equivalent). The binary is self-contained: no Node, no npm, no PostCSS chain. It reads `assets/css/app.css` directly and writes `priv/static/app.css`.

The binary is invoked via `mix mailglass_admin.assets.build` which runs:

```
tailwind --input=assets/css/app.css --output=priv/static/app.css
```

from `mailglass_admin/` as the working directory.

### How `@theme` custom token scales work (HIGH confidence, directly verified)

`@theme` in Tailwind v4 declares CSS custom properties that are *simultaneously* CSS variables and Tailwind utility classes. The binary generates both a `:root {}` block with the variable and a utility class that references it. There is no separate configuration file — everything lives in `app.css`.

Example from the shipped `app.css`:

```css
@theme {
  --spacing-xs: 4px;
  --text-body: 14px;
}
```

This makes `p-xs`, `gap-xs`, `m-xs`, `text-body` etc. available as utilities in HEEx. The generated utility uses `var(--spacing-xs)` internally, so the token is a single source of truth.

**For Phase 75 (component hardening / token migration):** The tokens already exist. Migration is strictly substitution work — replacing `text-sm` with `text-body`, `gap-3` with `gap-sm`, `text-xs` with `text-label`, etc. No new `@theme` declarations needed unless Phase 0 audit finds a genuinely missing scale step.

Current token inventory confirmed in `app.css`:

| Scale | Available tokens | Corresponding utilities |
|-------|-----------------|------------------------|
| Spacing | `xs`/`sm`/`md`/`lg`/`xl`/`2xl`/`3xl` = 4/8/16/24/32/48/64px | `p-xs`, `gap-sm`, `px-lg`, etc. |
| Type size | `label`/`body`/`heading`/`display` = 12/14/20/28px | `text-label`, `text-body`, `text-heading`, `text-display` |
| Elevation | `flat`/`raised`/`overlay` | `shadow-flat`, `shadow-raised`, `shadow-overlay` |
| Easing | `out`/`in-out` | `ease-out`, `ease-in-out` |
| Motion duration | `instant`/`fast`/`reveal`/`flash` = 90/150/220/200ms | `duration-(--duration-instant)` etc. (v4 arbitrary value syntax) |

### What breaks the JIT scan (HIGH confidence, confirmed in design-system.md)

The JIT scanner reads source files specified in `app.css`:

```css
@source "../css";
@source "../../lib";
```

It scans `assets/css/` and `lib/` for class name strings. The scanner uses static string matching — it does not execute Elixir or evaluate expressions.

**Breaking patterns (confirmed footguns):**

1. **Dynamic class construction** — `"text-#{size}"` or `"gap-#{n}"` produces a string the scanner never sees as a complete class name. The class is silently omitted from the bundle. Use static strings; pick the class name with a `case` or function that returns full strings:

   ```elixir
   # WRONG — scanner sees "text-#{level}" which is not a real class
   class={"text-#{level}"}
   
   # CORRECT — scanner sees the full string in the source
   defp size_class(:sm), do: "text-label"
   defp size_class(:md), do: "text-body"
   ```

2. **Classes only in `@apply`** — `@apply` is explicitly forbidden in the design system and should not be introduced. This also avoids a related footgun where `@apply` in a CSS file gets scanned but HEEx consumers still need the base class present.

3. **Classes constructed in runtime-evaluated strings** — LiveView `assigns` that produce class strings at render time from dynamic data are fine only if the class strings themselves are literal in a pattern-match branch, a lookup table, or a function that returns static strings. The three `badge_class/1` functions in the existing codebase are already correct patterns.

4. **New utility classes from other CSS files** — only `@source` paths are scanned. If a new HEEx file is added in a directory outside `lib/`, it won't be scanned. All admin components live under `lib/` so this is not a current risk.

### daisyUI 5 component-class availability under standalone binary (HIGH confidence)

daisyUI 5 ships as a Tailwind v4 `@plugin`, loaded from the vendored JS file:

```css
@plugin "../vendor/daisyui" { themes: false; }
@plugin "../vendor/daisyui-theme" { name: "mailglass-light"; … }
```

The plugin approach (v5's replacement for v3's `require('daisyui')` in `tailwind.config.js`) is **natively supported by the standalone binary**. The standalone binary understands `@plugin` and executes the JS plugin file. No Node is involved.

All daisyUI 5 semantic component classes are available: `badge`, `badge-sm`, `badge-success`, `badge-warning`, `badge-error`, `badge-outline`, `btn`, `card`, `rounded-box`, `rounded-field`, etc. These are stable v5 names.

The `rounded-box` and `rounded-field` utilities come from daisyUI's theme variables, not from Tailwind's own radius scale. They are set in the `@plugin "daisyui-theme"` block via `--radius-box: 0.5rem` and `--radius-field: 0.25rem` — one definition controls both the CSS variable and the component class. This is why the conformance rubric says "use `rounded-box` / `rounded-field` only" — changing radius everywhere requires changing only two lines in `app.css`.

**For Phase 75 (unified status badge atom):** The `badge` + `badge-{variant}` + `badge-sm` classes are all daisyUI 5 component classes, statically scannable, and already used in the three `badge_class/1` functions. The unified `status_badge` component in `components.ex` should return static class strings from pattern-matched functions — same pattern already used.

---

## Section 3 — Visual Audit Tooling

### What `scripts/ui-audit.sh` is (HIGH confidence, directly verified)

`mailglass_admin/scripts/ui-audit.sh` is a bash script that:

1. Takes `PORT`, `TENANT`, and `OUT` env vars (defaults: 4015, northstar, `tmp/ui-audit/`)
2. Calls `agent-browser open <url>` + `agent-browser screenshot --full <path>` for each URL
3. Writes full-page PNGs to `tmp/ui-audit/` (gitignored — never enters `priv/static/`)
4. Covers: Preview mount root, operator landing (light/dark), inbound (light/dark)

State is URL-driven: `?tenant_id=&delivery_id=&theme=dark` query params reproduce any screen state without click simulation. This makes the script robust even when the LiveView socket is not connected under the screenshot tool.

The `agent-browser` CLI is a separate tool on `PATH` — it is not a Hex package and not in `mix.exs`. It is an external, ad-hoc utility expected to be present in the developer's environment. No version is pinned. This is intentional.

### The screenshot→LLM-critique loop (HIGH confidence from blueprint)

The loop is:

1. Boot the reference demo app with seeded data: `mix ecto.create && mix ecto.migrate && mix run priv/repo/seeds.exs && mix phx.server`
2. Run `mailglass_admin/scripts/ui-audit.sh` to capture PNGs into `tmp/ui-audit/`
3. Pass PNGs to a multimodal LLM (e.g., Claude with image input) with `mailglass_admin/docs/design-system.md` as the rubric
4. LLM produces critique: accent overuse? faux-bold? off-grid spacing? non-flat shadow? contrast ≥ 4.5:1?
5. Apply fixes in HEEx → rebuild bundle → re-shoot only affected URLs → iterate

For Phase 74 (systematic audit): run the full matrix (surface × light/dark × 390/768/1440 × state) and produce the scored gap register. For inner-loop work in Phases 75–78: re-shoot only the URLs affected by the current change.

### Why it must stay local/ad-hoc and never in CI (HIGH confidence)

Three hard reasons:

1. **Non-deterministic pixel output** — font rendering, anti-aliasing, sub-pixel differences across OS/GPU/display-scale combinations mean PNG diffs are not reproducible across CI runners. A pixel-diff gate will have random failures.

2. **`agent-browser` is not in the Hex/npm dependency graph** — it is an external CLI with no pinned version, no lockfile entry, no reproducible install command in CI. Adding it would require either vendoring a browser binary (enormous, Node-adjacent) or requiring a specific installed tool on CI runners (fragile, not declared).

3. **CI is already deterministic** — `e2e/operator.spec.js` (Playwright) asserts structure, testids, text, and order without pixel comparison. The conformance grep (`zero raw text-sm/base/xs`, `zero faux-bold`, etc.) catches token drift mechanically. `git diff --exit-code priv/static/` catches uncommitted bundle changes. These three gates cover what matters without screenshot fragility.

The screenshot loop is explicitly a **Phase 74 audit ritual and Phase 79 closeout ritual**, not a per-PR gate. The design-system.md and blueprint are aligned on this.

---

## Section 4 — Bundle Rebuild Discipline

### The CI gate (HIGH confidence, confirmed in design-system.md and CLAUDE.md)

CI runs `git diff --exit-code priv/static/` after every build. Any change to:
- `assets/css/app.css` (new tokens, new motion classes, new `@source` paths)
- Any HEEx file that introduces a new class not previously in the JIT output

...must be followed by `mix mailglass_admin.assets.build` and committing the updated `priv/static/app.css` in the same change. Failing to do so causes the gate to fail.

**Correct commit discipline:**
```
1. Edit HEEx / app.css
2. mix mailglass_admin.assets.build
3. git add mailglass_admin/priv/static/app.css mailglass_admin/assets/css/app.css <heex-files>
4. commit
```

**Footgun:** Running `mix mailglass_admin.assets.build` from the repo root instead of with the correct working directory. The tailwind config specifies `cd: Path.expand("..", __DIR__)` which resolves to the `mailglass_admin/` directory — the Mix task handles this correctly. Running the raw binary manually from the wrong directory will use the wrong `@source` paths.

### What does and does not require a rebuild

| Action | Rebuild required? |
|--------|------------------|
| Adding a new HEEx file with existing token classes | YES — JIT must scan the new file |
| Renaming/removing a class from a HEEx file | YES — JIT must drop the orphaned class |
| Changing a `:root` custom property value (e.g., motion duration) | YES — variable value changes |
| Changing only Elixir logic (no class string changes) | NO |
| Changing `data-testid` attributes | NO |
| Adding new `@keyframes` in `app.css` | YES |

---

## Section 5 — What NOT to Add

| What | Why not |
|------|---------|
| New Hex CSS/animation library | All motion vocabulary already defined; new lib would create competing systems and is expressly forbidden by design-system.md ("No second CSS file, no @apply, no CSS-in-JS") |
| `heroicons` Hex package as a dep (vs current vendor JS) | Already vendored as `assets/vendor/heroicons.js`; adding the Hex package would be redundant |
| Tailwind CSS IntelliSense or other Node tooling | Zero-Node constraint is absolute; IDE tooling is a developer preference, not a project dep |
| PostCSS | The standalone binary does not use PostCSS; introducing it would require Node |
| Any pixel-diff CI tool (Percy, Chromatic, BackstopJS) | Node-dependent; screenshot comparison is ad-hoc local ritual only |
| Upgrade daisyUI to a newer 5.x patch | The vendor JS files are frozen snapshots. "Latest" is the fetch strategy at install time; re-fetching should only happen deliberately. No version bump is needed for v1.7 work. |
| Upgrade Tailwind binary beyond 4.1.12 | 4.1.12 is locked via `config :tailwind, version: "4.1.12"`. No token API changes justify a bump for v1.7. |
| New LiveView hooks (phx-hook JS) | There is no client JS bundle to add hooks to; all needed motion is handled by `Phoenix.LiveView.JS` + CSS |
| `@apply` directives | Expressly forbidden in design-system.md |

---

## Section 6 — Integration Points for Roadmap Consumers

### Phase 74 (Audit + UI-SPEC) — tooling actions

- Run `scripts/ui-audit.sh` after booting the demo app with current seeds
- Add the `tmp/ui-audit/` directory to `.gitignore` if not already there (it should be)
- Pass PNGs to a multimodal critique with `docs/design-system.md` as rubric
- Run the static conformance grep:

  ```bash
  grep -rn "text-sm\|text-base\|text-xs\|gap-3\|gap-6\|font-medium\|font-semibold" \
    mailglass_admin/lib/ --include="*.ex"
  ```

- No bundle rebuild needed for Phase 74 (audit only, no HEEx changes)

### Phase 75 (Component Hardening / Token Migration)

- Every HEEx edit requires a bundle rebuild at end-of-phase
- The unified `status_badge` component belongs in `components.ex` and must use static pattern-matched class strings (not dynamic construction)
- Token migration is class substitution only: `text-sm` → `text-body`, `text-xs` → `text-label`, `gap-3` → `gap-sm`, `gap-6` → `gap-lg`
- No new `@theme` tokens expected unless Phase 0 gap register identifies a missing scale step

### Phase 76 (Motion Polish)

- Motion fire-on-mount-not-patch fix: add delivery-keyed `id` to the `motion-reveal` detail pane div in `operator_live.ex`; model on the `preview-tab-#{tab}` pattern in `preview/tabs.ex`
- `phx-mounted` + `JS.transition` is available for explicit mount-time animation if CSS-only re-fire is insufficient
- No new `@keyframes` expected unless a genuinely new motion is identified; the six named motions cover all current UI patterns
- `prefers-reduced-motion` is globally handled; no per-component `motion-reduce:` variants needed

### Phase 79 (Verification Closeout)

- Re-run full `scripts/ui-audit.sh` matrix → before/after PNG diff vs Phase 74 baseline
- Final conformance grep (same command as Phase 74, expect zero hits)
- `git diff --exit-code priv/static/` as final bundle clean gate

---

## Sources

- `mailglass_admin/assets/css/app.css` — confirmed token scales, motion keyframes, reduced-motion block, `@plugin` integration, `@source` paths (HIGH confidence, direct read)
- `mailglass_admin/docs/design-system.md` — conformance rubric, audit loop mechanics, known limitations (HIGH confidence, direct read)
- `mailglass_admin/scripts/ui-audit.sh` — audit tool mechanics confirmed (HIGH confidence, direct read)
- `mailglass_admin/config/config.exs` — Tailwind binary version 4.1.12, standalone binary invocation (HIGH confidence, direct read)
- `mailglass_admin/mix.exs` — `tailwind ~> 0.4`, `phoenix_live_view ~> 1.1` (HIGH confidence, direct read)
- `mailglass_admin/mix.lock` — `tailwind 0.4.1` pinned (HIGH confidence, direct read)
- `assets/vendor/daisyui.js`, `assets/vendor/daisyui-theme.js` — daisyUI 5 vendor files with `@layer daisyui.l1` patterns confirming v5 (HIGH confidence, direct read)
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` lines 285–348 — confirmed `motion-reveal` div lacks delivery-keyed id (HIGH confidence, direct read)
- `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` line 84 — confirmed correct id-keyed `motion-tab-swap` pattern (HIGH confidence, direct read)
- Context7 `/phoenixframework/phoenix_live_view` — `phx-mounted` fires on DOM insertion not on patches; `phx-remove` fires on removal; `JS.transition` adds class temporarily for `time` ms (HIGH confidence, verified against live docs)
- `/Users/jon/.claude/plans/mailglass-context-handoff-serene-noodle.md` — blueprint constraints, phase breakdown, fork decisions (HIGH confidence, source of record)
