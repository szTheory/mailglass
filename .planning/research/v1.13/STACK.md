# Stack Research — v1.13 Admin Design-System Stress Test & UX Uplift (v3)

**Domain:** Mountable Phoenix LiveView dashboard library (`mailglass_admin`) — design-system tooling/mechanics
**Researched:** 2026-06-18
**Confidence:** HIGH
**Downstream consumers:** v1.13 requirements + roadmap
**Relationship to prior research:** EXTENDS v1.11 (`MOTION.md`, `DARK-MODE.md`). Does NOT redo or overwrite the root `.planning/research/STACK.md` (foundational optional-dep/CI-lane research).

---

## TL;DR — Recommendation Headlines

| Brief item | Recommendation | Add to deps? |
|------------|----------------|--------------|
| (a) Component lab | **EXTEND the in-house `/dev/mail/gallery` LiveView** into a component × state × theme × viewport matrix. **Do NOT add `phoenix_storybook`.** | NO new Hex dep |
| (b) Theme system | **Build system/light/dark in-house**: keep `?theme=` URL param as server state, add `system` as the default, persist via a tiny **localStorage + cookie inline `<script>`** (no client JS *hook*), use daisyUI `prefersdark` + a no-FOUC head snippet. **Add NO library.** | NO new dep |
| (c) A11y testing | **Add `@axe-core/playwright` 4.11.x** to the EXISTING `package.json` devDependencies (Node is already used by the Playwright runner — this is NOT an asset-pipeline Node dep). Scan with `wcag22aa` tags; assert on opened dialogs/popovers. Keep manual review for what axe can't catch. | YES — 1 **devDependency** (test-only) |
| (d) Visual/interaction regression | **No screenshots.** Extend the existing structural/computed-style Playwright assertions + the committed score baseline + GAP register. axe results JSON becomes the new idempotent ratchet artifact. **Add NO pixel-diff tool.** | NO new dep |
| (e) Motion | **No new mechanics.** v1.11 MOTION.md is complete. v1.13 adds only: (1) `system`-theme transition must not animate, (2) `target-size` 24px floor reconciled with the 44px touch rule, (3) gallery viewport cells must not multiply motion. | NO new dep |

**Net new dependencies for the entire milestone: exactly one test-only npm devDependency (`@axe-core/playwright`). Zero new Hex deps. Zero new asset-pipeline tooling. Zero Node added to the build.**

---

## The Load-Bearing Distinction (read first)

The "ZERO Node toolchain" constraint in CLAUDE.md is about the **CSS/asset build pipeline**: `mix mailglass_admin.assets.build` shells the standalone `tailwind` binary (`{:tailwind, "~> 0.4"}`) to inline `brandbook/tokens.css` + daisyUI into a committed `priv/static/app.css`. Adopters get a precompiled bundle. No `npm install`, no `node_modules`, no esbuild in the ship path or the adopter's path.

**The dev/CI test harness is a different surface and already uses Node.** `mailglass_admin/package.json` declares `@playwright/test ^1.59.1`; CI runs `npm ci` + `npx playwright install --with-deps chromium` + `npm run test:operator-browser`. This Node usage:
- never ships in the Hex tarball (`mix.exs :files` lists `lib priv/static docs …` — not `package.json`, not `e2e/`, not `node_modules`),
- never touches the adopter (host apps consume the precompiled CSS),
- is invisible to `mix compile --no-optional-deps`.

So: **adding a test-only npm devDependency does NOT violate "zero Node toolchain."** It extends an existing, already-sanctioned dev harness. This is why (c) is a "yes" and everything else is "extend in-house." Conflating the two surfaces is the central footgun this brief exists to prevent.

---

## (a) Component Lab — Storybook Lens

### Decision: EXTEND the in-house `/dev/mail/gallery` LiveView. Do NOT add `phoenix_storybook`.

PROJECT.md line 41–43 already states the lean ("leaning in-house under the zero-Node rule"); this brief confirms it with current data and makes it a locked decision rather than a lean.

### Current state (what already exists)
`lib/mailglass_admin/gallery_live.ex` is a dev-only LiveView at `/dev/mail/gallery` that renders **every shared component (STATE-LD-01..22) × every state × BOTH themes** side-by-side from an in-code `@specimens` list. Each cell carries a stable `data-testid="gallery-{component}-{state}"` and twin `data-theme="mailglass-light"`/`"mailglass-dark"` wrappers. Five Playwright structural tests already assert against it (`structural.spec.js` lines 999–1040). It is a working "storybook" — it just lacks the **viewport** axis and a **system-theme** column.

### `phoenix_storybook` 1.2.0 (Jun 11, 2026) — feasibility under the constraints

| Dimension | Finding | Verdict |
|-----------|---------|---------|
| Asset pipeline | Storybook ships its own LiveView app with **its own JS + CSS entrypoints** that you wire into your bundler. Its docs route you through `esbuild`/`tailwind` config + a `storybook.js` entrypoint + a sandbox CSS file. This repo has **no esbuild and no JS entrypoint at all** (pure LiveView, `app.css` only — `mix.exs` line 98 comment: "No :esbuild at v0.1"). Adopting Storybook means standing up a JS build surface the project deliberately never created. | **Conflicts** with zero-Node-asset-pipeline |
| Dep weight | Adds `phoenix_storybook` + its ~6 transitive deps to a package whose dep list is currently tight and intentionally curated. It is a `:dev`-only concern but still expands the lockfile and the CI compile surface. | **Net negative** |
| Host-app-friendliness | Storybook is normally mounted by the *host app's* router as its own `live_session`/scope with its own static path + its own sandboxed asset namespace. For a **mountable library** whose entire identity is "don't make the host stand up extra infrastructure," shipping a second mountable surface (or telling adopters to mount Storybook) is off-brand and off-scope. | **Conflicts** with mountable-lib goal |
| Theme/token reuse | Storybook's sandbox has its own CSS isolation model; getting `brandbook/tokens.css` + the two daisyUI theme blocks to resolve identically inside the Storybook sandbox is non-trivial and duplicates what the gallery already does for free (the gallery renders the *real* components in the *real* `app.css`). | **Net negative** |
| Fit for a *fractal audit* | The audit goal is "component × state × theme × **viewport**, meet-or-beat scored, structurally asserted." The gallery already nails component × state × theme and is already wired into Playwright + the score baseline + GAP register. Storybook would *replace* that proven harness with a parallel one and *still* need custom viewport handling. | **In-house wins** |

### What to BUILD into the gallery for v1.13 (the actual work)
1. **Viewport axis.** Add a viewport switcher (390 / 768 / 1440) — either as `?w=390` URL state driving a max-width wrapper, or stacked labelled frames per breakpoint. Playwright already sets `page.setViewportSize`, so the structural suite can iterate the gallery at each width with zero new tooling.
2. **System-theme column.** Add a third theme wrapper (or a `prefers-color-scheme`-driven cell) alongside the existing light/dark twins so the gallery audits the `system` default, not just explicit light/dark.
3. **Coverage parity.** Ensure every new/changed component and every new fixture-cohort state (long IDs, non-ASCII, high-count, null/error/boundary from the multi-tenant fixture work) appears as a specimen — the gallery's value is that it is the single enumerated census of the design system.
4. **Stable testids preserved.** Keep the `gallery-{component}-{state}` contract; add `-{viewport}` / `-{theme}` suffixes only where a structural assertion needs to disambiguate.

### What NOT to add
- **Do NOT add `phoenix_storybook`** (any version, including 1.2.0). It imports a JS build surface this project intentionally lacks and a second mountable surface a library should not impose.
- **Do NOT add `surface` / `ex_unit_notifier` / screenshot-storybook plugins.**
- **Do NOT introduce a JS entrypoint or esbuild** to make any "lab" work — the gallery needs neither.

---

## (b) Theme System — system / light / dark with SYSTEM default + persistence

### Decision: Build in-house. Keep server-side `?theme=`, add `system` as the default, persist with a tiny inline localStorage+cookie script. Add NO library.

### Current state
Theme is **URL-param-only** today (`shell.ex`: `dark_chrome?/1` reads `?theme=dark`; `toggle_theme_path/2` flips it via `push_patch`). There is no `system` option, no persistence across visits, and the default is hard light (`dark_chrome` defaults to `false`). daisyUI is configured with `mailglass-light { default: true }` and `mailglass-dark { prefersdark: true }` (app.css lines 26/63) — so the **CSS layer can already follow the OS** when no `data-theme` is force-set, but the LiveView currently *always* force-sets `data-theme`, defeating it (the exact split-brain DARK-LD-08 flagged).

### The three sub-problems and their in-house answers

**1. `prefers-color-scheme` + daisyUI mechanics (the "system" mode).**
daisyUI 5's `prefersdark: true` on `mailglass-dark` means: when the element does **not** carry an explicit `data-theme`, the browser's `prefers-color-scheme: dark` selects the dark theme automatically. So "system" mode = **emit no `data-theme` attribute** (or emit `data-theme` only for explicit light/dark choices). This is a pure-CSS capability already present in the bundle — no Tailwind v4 `@theme` runtime layer change needed; the two daisyUI theme blocks already define the full token sets.

**2. No-FOUC on first paint inside a mountable lib.**
First-paint theme must be decided **before** the LiveView mounts, or there's a flash. The host owns `<head>`, so the library cannot guarantee a blocking head script. Resolution that stays host-friendly:
- For **explicit** light/dark: the server already knows the choice (URL param, and now also a cookie — see below) at `mount/3`, so it renders the correct `data-theme` server-side. No flash.
- For **system**: emit **no** `data-theme`; daisyUI `prefersdark` resolves it in CSS at parse time (no JS, no flash).
- A **tiny inline `<script>`** (≤10 lines, no external file, no hook, no `app.js`) injected by the library's own rendered root *only on the library's own surfaces* may read the stored preference and set `data-theme` early. This is allowed because it is (i) scoped to the admin's own DOM subtree, (ii) inline (ships in the precompiled HEEx, not a JS build artifact), (iii) not a `phx-hook` (no client JS build). It is **not** a global head injection into the host.

**3. WHERE to store the preference without hijacking the host.**
- **Primary: a namespaced cookie** (`mailglass_admin_theme`) set with `path` scoped to the mount path the adopter chose. The server reads it in `mount/3` so the FIRST server render is already correct (true no-FOUC for explicit choices). Namespacing the cookie name prevents collision with host auth/session cookies (the session-cookie-collision pitfall called out in CLAUDE.md Phase-5 notes).
- **Secondary: `localStorage` under a namespaced key** (`mailglass_admin:theme`) for the inline early-set script.
- **Do NOT** write to the host's session, the host's `app` cookie, or any global `localStorage` key. **Do NOT** flip a global `<html data-theme>` — scope `data-theme` to the admin shell wrapper (already the pattern: `shell.ex` line 119, `preview_live.ex` line 247).

### Integration points
- `shell.ex` / `preview_live.ex`: extend `dark_chrome?/1` → a tri-state `theme_choice/1` returning `:system | :light | :dark`; `:system` emits no `data-theme`.
- `mount/3`: read the namespaced cookie to seed the choice (currently nothing is read; `dark_chrome` just defaults false — fixes DARK-LD-08's split-brain).
- Theme control: replace the 2-state toggle (`theme_toggle/1`) with a 3-option control (system/light/dark); the gallery already has a `theme_toggle` specimen (STATE-LD-08) to extend.
- daisyUI blocks: no change needed — `prefersdark: true` is already set.

### What NOT to add
- **Do NOT add a theme library** (no `phoenix_storybook` theme switcher, no JS theme package). daisyUI + a cookie + 10 lines of inline JS is the whole solution.
- **Do NOT add a `phx-hook`** for theme (would require a client JS build — banned). Inline `<script>` for early-set is permitted; a compiled hook is not.
- **Do NOT force-set `data-theme` for system mode** — that re-creates the DARK-LD-08 split-brain and defeats `prefersdark`.
- **Do NOT persist into host-owned storage** (host session, host cookie, un-namespaced localStorage).

---

## (c) Accessibility Testing — WCAG 2.2 AA

### Decision: Add `@axe-core/playwright` 4.11.x to the EXISTING `package.json` devDependencies. Scan with `wcag22aa` tags, including opened dialogs/popovers. Keep manual review for the rest.

### Why axe-core/playwright (not Pa11y, not manual-only)

| Option | Fit for THIS repo | Verdict |
|--------|-------------------|---------|
| **`@axe-core/playwright` 4.11.2** (axe-core ≥4.10 bundled) | Drops into the **existing** Playwright runner as a library call: `new AxeBuilder({ page }).withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa']).analyze()`. Reuses the already-authenticated `openOperator`/`openInbound`/`openPreview*` helpers and the already-provisioned Chromium. Can scan **after** opening a modal/popover (analyzes live DOM, so opened dialogs are in scope). Zero new infrastructure. | **RECOMMENDED** |
| **Pa11y / pa11y-ci** | A separate Node CLI + its own headless-Chrome driver + its own URL list + its own auth story. It would **duplicate** the Playwright browser harness and re-solve login. It also historically mishandles tag/standard selection (pa11y#666). No benefit over axe-in-Playwright here. | **Reject** (duplicate harness) |
| **Manual-only** | Required as a *complement* (see below) but insufficient alone for an idempotent ratchet — not repeatable, not CI-gating. | **Complement, not substitute** |

axe-core gained first WCAG 2.2 support in 4.5 and the bundled 4.10/4.11 line ships `wcag22aa` rules including **2.5.8 Target Size (Minimum, 24px)**. The `withTags(['wcag22aa'])` selector pins scans to the 2.2 AA rule set.

### What automated axe CAN catch (gate on these)
Color-contrast (text + non-text, complementing the existing hand-rolled contrast math in `structural.spec.js`), missing/`aria-*` correctness, roles, accessible names, label/control association, `aria-modal`/dialog structure, duplicate ids, landmark issues, and the 2.2 target-size rule.

### What automated axe CANNOT catch (keep manual review)
Per Deque's own guidance, automated rules catch roughly a third of WCAG issues. Reserve human review for: focus-**order** sanity, keyboard-trap-free traversal of the full flow, that focus is **visibly** placed (vs merely present), reading order, meaningful-sequence, error-recovery copy quality (the microcopy pass), motion-discomfort judgment, and whether an empty-state/CTA is actually *useful* (semantics axe can't judge). These map to existing manual GAP-register entries and the v1.11 structural facts (focus rings, reduced-motion, ARIA).

### Scanning opened dialogs/popovers (explicit requirement)
The structural suite already opens the replay modal (`inbound-replay-open`, asserts `role=dialog`/`aria-modal`) and the evidence reveal. Pattern: open the overlay → `await new AxeBuilder({ page }).include('[role=dialog]').withTags(['wcag22aa']).analyze()` → assert `violations` empty (or meet-or-beat). Because axe analyzes the **current** DOM, the opened overlay is in scope; no special config needed beyond opening it first.

### Integration points
- `package.json`: add `"@axe-core/playwright": "^4.11.2"` to `devDependencies` (alongside `@playwright/test`). CI `npm ci` already installs it; no workflow change beyond the new spec.
- New `e2e/a11y.spec.js` (or extend `structural.spec.js`) iterating the 3 surfaces × {light, dark, system} × {390, 768, 1440} × {default state, opened-modal state}.
- Optionally run axe against `/dev/mail/gallery` cells for fast per-component coverage.

### What NOT to add
- **Do NOT add Pa11y / pa11y-ci** (duplicate browser harness, weaker tag handling).
- **Do NOT add `axe-playwright`** (the third-party wrapper) — use Deque's first-party `@axe-core/playwright`.
- **Do NOT add a hosted a11y SaaS / Lighthouse-CI / `jest-axe`** (wrong runner, new infra).
- **Do NOT treat axe green as "fully accessible"** — it's ~⅓ coverage; the manual pass stays.

---

## (d) Visual / Interaction Regression — respecting "PNGs gitignored / no pixel-diff"

### Decision: No screenshots. Keep idempotency via structural/computed-style assertions + committed score baseline + GAP register, and add the axe results JSON as the new ratchet artifact.

The v1.11 precedent is deliberate: PNGs are gitignored, there is **no** pixel-diff visual regression; quality is enforced by (1) a committed **score baseline** (meet-or-beat), (2) a **GAP-NN register**, (3) **Playwright structural assertions** (computed `grid-template-columns`, `font-weight`, `outlineWidth`, contrast ratios, `data-theme` attributes), and (4) conformance/motion grep gates. This already *is* idempotent regression without images, and it must be extended, not replaced.

### How to keep improvements idempotent without committing screenshots
1. **Extend the structural matrix** to the new axes: system theme + new viewports + opened-overlay states. Every assertion is a computed value or DOM fact, diff-free across runs.
2. **axe violation counts become a ratchet artifact.** Commit a small JSON baseline of allowed (known/tracked) violations per surface; the gate fails if violations *increase* (meet-or-beat), mirroring the score baseline. This is text, deterministic, and reviewable — the no-PNG analogue of visual regression.
3. **Interaction regression = behavioral assertions, not frames.** Continue asserting interaction outcomes structurally (modal opens → `role=dialog` present; Escape → `count(0)`; row click → `aria-selected=true`; detail pane carries `phx-remove`). These already exist (`structural.spec.js`) and catch interaction breakage without a single image.
4. **Computed-style motion checks** (already present: reduced-motion collapses `animation-duration`/`transition-duration` to ≤0.05s) stay as the motion-regression mechanism.

### What NOT to add
- **Do NOT add `@playwright/test` `toHaveScreenshot()` / pixel snapshots**, Percy, Chromatic, `pixelmatch`, `BackstopJS`, `reg-suit`, or any image-diff tool. They violate the gitignored-PNG precedent and introduce flaky, environment-sensitive, binary-committing baselines.
- **Do NOT commit screenshots** as fixtures or baselines. Capture for human review only, gitignored, as v1.11 did.

---

## (e) Motion — deltas beyond v1.11 MOTION.md only

### Decision: No new motion mechanics. v1.11 MOTION-LD-01..14 is complete and binding. v1.13 adds only three reconciliations.

MOTION.md already locks: ease-out only (`--ease-out` token), ≤300ms, transform/opacity only (+ color at fast token for state layers), no springs/overshoot, `prefers-reduced-motion` snap, mount-trigger via `phx-mounted`/LiveView.JS, CSS+LiveView.JS only (no client JS hook), entrance/exit ratio, View Transitions for full-document nav only. The implementation in `app.css` (lines 236–350) matches. Nothing about View Transitions API, LiveView.JS commands, transform/opacity, or reduced-motion needs to change.

### The only v1.13 motion deltas
1. **Theme switch must not animate (and must respect the system delta).** When the user flips system/light/dark or the OS changes `prefers-color-scheme`, the resulting color change is a `transition-colors` repaint at most — never an entrance/exit motion, and under `prefers-reduced-motion` it snaps (already covered by the global reduce block, MOTION-LD-09). Add a one-line confirmation rather than new mechanics: a theme flip is a state-layer color change, not a `reveal`.
2. **`target-size` (WCAG 2.2 2.5.8, 24px) vs the existing 44px touch floor.** No conflict — the design system's 44px control floor (`--size-control-md`, MOTION/STATE precedent) already exceeds the 24px 2.5.8 minimum. v1.13 only needs to ensure *dense* controls (e.g. small replay/sort buttons currently advisory-only in `structural.spec.js`) clear 24px; the axe `target-size` rule (c) enforces this automatically. This is an a11y delta, not a motion delta — noted here because it touches the same Motion+A11y pillar.
3. **Gallery viewport axis must not multiply motion.** When the gallery renders the same component across 3 viewports × 3 themes, entrance motions still fire on mount per MOTION-LD-11 — fine for a static audit surface, but the gallery must NOT add re-trigger-on-patch motion (it already absorbs interactions as no-ops, `gallery_live.ex` line 78). No change; just a constraint to preserve.

### What NOT to add
- **Do NOT add a JS animation library** (Framer-Motion-style, GSAP, Motion One, `@vueuse`-anything). LiveView.JS + CSS is the only sanctioned mechanism (MOTION-LD-11) and there is no client JS build to host a library.
- **Do NOT introduce springs/overshoot, `ease-in`, or new keyframes** beyond the four already in `app.css`.
- **Do NOT animate the theme switch** as an entrance/exit; it is a color repaint.

---

## Recommended Stack (summary table)

### Core Technologies (unchanged — confirm, don't touch)

| Technology | Version | Purpose | Why (this context) |
|------------|---------|---------|--------------------|
| standalone `tailwind` binary via `{:tailwind, "~> 0.4"}` | Tailwind v4.1.x | Compile `app.css` (tokens + daisyUI) to committed `priv/static/app.css` | Zero-Node asset pipeline; the whole brand depends on it. **No change.** |
| daisyUI 5 (vendored plugin) | 5.x | Theme token mapping (light/dark blocks) + `prefersdark` system mode | Already supplies system-mode CSS for free (b). **No change.** |
| `phoenix_live_view` | `~> 1.1` | All surfaces + gallery + LiveView.JS motion | Motion + theme are LiveView/CSS-native. **No change.** |
| `@playwright/test` | `^1.59.1` | Existing dev/CI browser harness (structural gates) | The host for the a11y additions. **No change.** |

### New Supporting Library (the ONLY addition)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@axe-core/playwright` | `^4.11.2` (bundles axe-core ≥4.10, `wcag22aa` rules) | Automated WCAG 2.2 AA scans inside the existing Playwright runner, incl. opened dialogs/popovers | Test-only devDependency in `mailglass_admin/package.json`. Never ships (excluded from Hex `:files`). |

### Development Tools (mechanics — no installs)

| Tool | Purpose | Notes |
|------|---------|-------|
| In-house gallery LiveView | Component × state × theme × **viewport** audit matrix | Extend `gallery_live.ex`; add viewport + system-theme axes |
| Committed score baseline + GAP-NN register | Idempotent meet-or-beat quality ratchet | Widen to new axes; add axe-violation JSON baseline |
| Structural/computed-style Playwright assertions | Visual/interaction regression without screenshots | Extend `structural.spec.js`; add `a11y.spec.js` |
| Namespaced cookie + `localStorage` + inline early-set `<script>` | system/light/dark persistence + no-FOUC | Scoped to admin DOM; not a `phx-hook`; not host-global |

## Installation

```bash
# In mailglass_admin/ — the ONLY new install for v1.13 (test harness, never shipped):
npm install -D @axe-core/playwright@^4.11.2
# (CI already runs `npm ci` + `npx playwright install --with-deps chromium`; no workflow change beyond the new devDependency.)

# NOTHING added to mix.exs. NO Hex dep. NO asset-pipeline tooling. NO esbuild. NO phoenix_storybook.
```

## Alternatives Considered

| Recommended | Alternative | When the alternative would win |
|-------------|-------------|--------------------------------|
| In-house gallery | `phoenix_storybook` 1.2.0 | If the project already had an esbuild JS entrypoint AND wanted a host-mounted component explorer as a shipped feature. Neither is true here. |
| `@axe-core/playwright` | Pa11y / pa11y-ci | If there were no existing browser harness and you wanted a standalone URL-list CLI. Here it would only duplicate Playwright + re-solve auth. |
| `@axe-core/playwright` | `axe-playwright` (3rd-party wrapper) | Never preferred over Deque's first-party package; no upside. |
| Structural + score baseline + axe-JSON ratchet | Pixel-diff (Percy/Chromatic/`toHaveScreenshot`) | Only if the team reversed the "no-PNG / gitignored screenshots" precedent — a deliberate policy change, out of scope. |
| Cookie + inline script theme persistence | A theme JS library / `phx-hook` | Never — would require a client JS build (banned) for a 10-line problem. |

## What NOT to Use

| Avoid | Why (this context) | Use instead |
|-------|--------------------|-------------|
| `phoenix_storybook` (incl. 1.2.0) | Imports a JS/esbuild build surface this project deliberately lacks; second mountable surface a library shouldn't impose; duplicates the gallery | Extend `/dev/mail/gallery` |
| Pa11y / pa11y-ci | Duplicate headless-Chrome harness; re-solves auth; weaker tag/standard handling | `@axe-core/playwright` in the existing runner |
| Pixel-diff tools (Percy, Chromatic, BackstopJS, `toHaveScreenshot`, pixelmatch) | Violate gitignored-PNG precedent; flaky, env-sensitive, binary baselines | Structural/computed-style assertions + score baseline + GAP register + axe-JSON ratchet |
| JS animation libraries (GSAP, Motion One, Framer-style) | No client JS build exists; violates MOTION-LD-11 | LiveView.JS + CSS (already locked) |
| `phx-hook` for theme | Requires a compiled client JS bundle (banned) | Inline early-set `<script>` (scoped, not a hook) + server cookie read |
| Host-global theme storage (host session/cookie, `<html data-theme>`, un-namespaced localStorage) | Hijacks the host app; violates mountable-lib host-friendliness | Namespaced cookie + namespaced localStorage; `data-theme` only on the admin shell wrapper |
| Force-setting `data-theme` for system mode | Re-creates the DARK-LD-08 split-brain; defeats daisyUI `prefersdark` | Emit NO `data-theme` for system; let `prefersdark` resolve in CSS |
| New Hex deps of any kind | Bundle/lockfile/compile-surface cost with no long-term payoff (PROJECT.md host-friendly lock) | Nothing — all in-house |

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `@axe-core/playwright@^4.11.2` | `@playwright/test@^1.59.1` | axe runs as a library against an existing `page`; matches the installed Playwright. |
| `@axe-core/playwright@4.11.x` | axe-core ≥4.10 (bundled) | Ships `wcag22aa` rules incl. 2.5.8 target-size; select via `.withTags(['wcag22aa'])`. |
| daisyUI 5 `prefersdark` | Tailwind v4.1.x standalone binary | System mode is a CSS capability already in the committed bundle; no rebuild semantics change beyond emitting/omitting `data-theme`. |
| Inline theme `<script>` | Phoenix LiveView 1.1 | Must be inline (not a `phx-hook`); scoped to admin DOM; safe with the no-client-JS-build constraint. |

## Open Questions / Flags for Roadmap

- **axe-JSON baseline format** — decide the shape of the committed allowed-violations artifact (per-surface counts vs rule-id allowlist) during requirements; it is the new ratchet primitive and should match the existing score-baseline ergonomics.
- **System-mode no-FOUC for *explicit* dark on first paint** — confirm the cookie is readable in `mount/3` for the chosen mount path so the server's first render is already correct (the only fully flash-free path inside a mountable lib).
- **Dense-control 24px audit** — the `target-size` rule will surface dense replay/sort buttons currently advisory-only; requirements should decide gate-now vs GAP-record per the v1.11 split.

## Sources

- `mailglass_admin/package.json`, `mailglass_admin/playwright.config.cjs`, `e2e/structural.spec.js`, `.github/workflows/ci.yml` (lines 700–740, 809–813) — confirmed the **existing Node-based Playwright dev/CI harness** (`@playwright/test ^1.59.1`, `npm ci`, `npx playwright install`); the load-bearing zero-Node-asset vs Node-test distinction. HIGH.
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` — existing component × state × twin-theme gallery (STATE-LD-01..22). HIGH.
- `mailglass_admin/assets/css/app.css` — daisyUI light/`mailglass-light{default}` + `mailglass-dark{prefersdark}`, `@theme` tokens, motion vocabulary, reduced-motion block. HIGH.
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex`, `preview_live.ex` — current URL-param-only theme model (`dark_chrome?/1`, `toggle_theme_path/2`); no persistence/system. HIGH.
- `mailglass_admin/mix.exs` — `:files` whitelist proves `package.json`/`e2e/` never ship; `{:tailwind, "~> 0.4"}` zero-Node asset pipeline; "No :esbuild" note. HIGH.
- `.planning/research/v1.11/MOTION.md` (MOTION-LD-01..14) and `DARK-MODE.md` (DARK-LD-01..08) — extended, not redone. HIGH.
- `.planning/PROJECT.md` (lines 41–43 in-house lean; 532+ Out of Scope; D-18 "no Node"; host-friendly scope lock) — project-own steer. HIGH.
- [hex.pm/packages/phoenix_storybook](https://hex.pm/packages/phoenix_storybook) — latest **1.2.0**, released 2026-06-11. HIGH (version); MEDIUM (asset-pipeline detail corroborated via Storybook setup docs requiring esbuild/JS entrypoint).
- [npmjs.com/package/@axe-core/playwright](https://www.npmjs.com/package/@axe-core/playwright) — latest **4.11.2**. HIGH.
- [Axe-core 4.5: First WCAG 2.2 Support (Deque)](https://www.deque.com/blog/axe-core-4-5-first-wcag-2-2-support-and-more/) and [axe-core rule-descriptions](https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md) — `wcag22aa` tag + 2.5.8 target-size; automated ≈⅓ coverage. HIGH.
- [Playwright Accessibility Testing docs](https://playwright.dev/docs/accessibility-testing) — `AxeBuilder.withTags` / `.include` opened-overlay scanning pattern. HIGH.
- [pa11y#666](https://github.com/pa11y/pa11y/issues/666) — Pa11y tag/standard handling weakness. MEDIUM.

---
*Stack research for: mailglass_admin v1.13 design-system stress-test tooling*
*Researched: 2026-06-18*
