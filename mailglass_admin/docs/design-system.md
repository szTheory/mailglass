# mailglass_admin Design System

The reference for how the admin UI is built, so each component compounds the
same polish rather than re-deciding it. The voice and palette come from
`brandbook/brand-book.md`; this doc covers the *mechanics* — tokens, motion,
conformance, and how to audit them.

> **One rule above all:** there is a single source of truth for every visual
> decision. Color lives in the daisyUI theme blocks; size / type / elevation /
> motion live in the `@theme` block and `:root` tokens. Components compose those
> tokens — they never hardcode hex, pixels, or durations.

---

## CSS architecture

- **Tailwind v4 + daisyUI**, compiled by the standalone `tailwind` Hex binary —
  **zero Node toolchain**. Source: `assets/css/app.css`. Build:
  `mix mailglass_admin.assets.build`.
- The minified bundle `priv/static/app.css` is **committed**. CI runs the build
  then `git diff --exit-code priv/static/` — any edit to `app.css` or to HEEx
  class usage must be followed by a rebuild + commit of the bundle in the same
  change, or the gate fails.
- **No second CSS file, no `@apply`, no CSS-in-JS, no BEM.** Utilities + daisyUI
  semantic classes inline in HEEx. Stay on this path — do not introduce a
  competing styling system.
- **Footgun:** never construct class names dynamically (`"p-#{n}"`). Tailwind's
  scanner only emits utilities it finds as literal strings; a computed class is
  silently tree-shaken to nothing. Use static class strings.

## Token layers

Two layers that own disjoint namespaces, so they never collide:

### 1. Color — daisyUI theme blocks (`@plugin "daisyui-theme"` in `app.css`)

The **only** place light and dark diverge. Brand palette mapped to daisyUI
semantic tokens. Use the semantic names, never raw Tailwind palette
(`text-gray-500`) and never hex in HEEx.

| Semantic | Light (brand) | Use |
|---|---|---|
| `base-100` | Paper `#F8FBFD` | app/detail surface |
| `base-200` | Mist `#EAF6FB` | cards, list/filter panes, sidebar |
| `base-300` | Ice `#A6EAF2` | borders, hover/active |
| `base-content` | Ink `#0D1B2A` | primary text |
| `primary` | Glass `#277B96` | **accent — use sparingly** |
| `secondary` | Slate `#5C6B7A` | secondary text/meta |
| `success` / `warning` / `error` | Pine / Amber / Crimson | status only |

**Accent discipline (the 10% rule):** `primary`/Glass appears only on the
selected-row border, the primary CTA, the active nav/timeline node, and focus
emphasis. It is never the default border or badge color. Status tints use
opacity (`bg-warning/10`), not new tokens.

### 2. Structure — `@theme` block + `:root` tokens (theme-independent)

Each `@theme` token is simultaneously a CSS variable and a Tailwind utility.

| Scale | Tokens | Utilities |
|---|---|---|
| Spacing (4px grid) | `--spacing-xs…3xl` (4/8/16/24/32/48/64) | `p-md`, `gap-sm`, `px-lg`, … |
| Type (400/700 only) | `--text-label/body/heading/display` (12/14/20/28) | `text-body`, `text-heading`, … |
| Elevation | `--shadow-flat/raised/overlay` | `shadow-overlay` (modals only) |
| Easing | `--ease-out`, `--ease-in-out` | `ease-out` |
| Motion (≤300ms) | `--duration-instant/fast/reveal/flash` | `duration-(--duration-fast)` |
| Control size | `--size-control-sm/md/lg` (36/44/52) | maps to `min-h-9/11/13` |
| Z-index | `--z-sticky/dropdown/overlay/modal/toast` (10/20/30/40/50) | `z-10`…`z-50` |

**Type weights are exactly 400 and 700.** `font-medium` / `font-semibold`
(500/600) are NOT loaded — the browser synthesizes a fake bold. Use `font-bold`
or default; faux-bold is a conformance failure.

**Elevation is borders-first.** Default surfaces are `border border-base-300`
with no shadow (brand `--depth:0`, flat — no glassmorphism/bevels). Only
modals/popovers use `shadow-overlay` (a faint Ink-tinted shadow). Never
`shadow-2xl`/`-xl`/`-lg`.

## Motion vocabulary

Brand metaphor "clarity through panes": content **arrives by becoming visible**
(opacity) and settling a few px into place — never sliding across the screen,
never bouncing. Six named motions, deliberately restrained.

| Motion | Class / mechanism | Where |
|---|---|---|
| reveal | `.motion-reveal` (opacity + translateY 6px, 220ms) | detail pane, cards, flash |
| timeline-in | `.motion-timeline > *` (staggered 40ms, capped at 8) | event timelines |
| tab-swap | `.motion-tab-swap` (crossfade 150ms), id keyed so it re-mounts | preview tabs, modal backdrop |
| overlay | `.motion-overlay` (scale 0.98→1 + opacity, 220ms) | modal panels |
| row-state | `transition-colors duration-(--duration-fast)` | list rows, nav, tabs |
| flash | `.motion-reveal` on toast | flash region |

Rules (from [great-animations](https://emilkowal.ski/ui/great-animations),
reinforced by the brand): **ease-out only** (never ease-in), **≤300ms**, animate
**transform/opacity only** (never height/width/padding), **exits faster than
entries**, **no springs/overshoot**, never animate keyboard-repeatable actions,
and fire entrance motions on **mount** (`phx-mounted` / element insertion), not
on every LiveView patch. Implementation is **`Phoenix.LiveView.JS` + CSS only**
— there is no client JS build to add hooks to. A global
`@media (prefers-reduced-motion: reduce)` block neutralizes movement while
letting crossfades effectively snap.

## Per-component conformance checklist

A component passes only if all hold:

- **Spacing/size:** token utilities on the 4px grid; no arbitrary `p-[14px]`,
  no off-grid `gap-1.5`. Touch targets ≥ `min-h-11` (44px).
- **Radius:** `rounded-box` / `rounded-field` only (theme-driven).
- **Color:** semantic tokens + opacity tints only; no hex, no raw palette;
  accent obeys the 10% rule.
- **Type:** `text-label/body/heading/display`; weight `font-bold` or default
  only (no faux-bold).
- **Elevation/stacking:** border + `shadow-flat`; `shadow-overlay` for modals
  only; `z-*` from the named tier (no ad-hoc `z-50` except the toast tier).
- **Motion:** a named motion above, or intentionally instant; inherits reduced
  motion.
- **A11y:** selected state via `aria-current`/`aria-selected` (not color alone);
  semantic list/table markup; visible focus ring; `role="dialog"`/`aria-modal`
  on modals.

## Visual audit loop

Matrix: **screen × theme (light/dark) × viewport (390/768/1440) × state
(default / row-selected / modal-open / reduced-motion)**.

- **Ad-hoc (agent-browser):** `scripts/ui-audit.sh` boots the reference demo,
  walks the screens, and writes screenshots to the gitignored `tmp/ui-audit/`
  (never `priv/static/` — must not trip the bundle gate). Review the PNGs (or
  hand them to a multimodal model with this checklist as the rubric: accent
  overuse? faux-bold? non-flat shadow? off-grid spacing? contrast ≥ 4.5:1?).
- **Before/after LLM-critique ritual:** The Phase 74 baseline represents the
  pre-v1.7 state (PNG set captured to the maintainer's local `tmp/ui-audit/` at
  baseline time, or regenerated from the Phase 74 git state — do not commit
  either set). To run a comparison: open the Phase 74 baseline PNGs alongside the
  current `tmp/ui-audit/` run, then supply both sets to a multimodal model with
  the 6-pillar rubric above (Spacing/size, Radius, Color, Type, Elevation,
  Motion/A11y) as the scoring framework. Ask for a per-pillar before/after score
  and a list of remaining issues if any. The following GAP rows should show
  visible improvement in the comparison:
  - **GAP-01/03/05/06** — badge color consistency: colors now come from
    `Components.status_badge/1`; phantom `:suppressed` and blanket `:badge-error`
    for all replay types should be absent.
  - **GAP-13** — support-card hierarchy: Tier 1 full cards for non-zero/actionable
    states; Tier 2 compact border-t row for zero states.
  - **GAP-07** — 390px orientation strip visible on the deliveries surface.
  - **GAP-21** — single `h1` "Operator overview" heading on the landing screen.
  - **IA note:** `/ops/mail/` now lands on the Operator Overview, not the
    Deliveries list. A reviewer comparing deliveries-at-landing screenshots
    should expect a different page — this is intentional, not a regression.
- **CI regression net (Playwright):** `e2e/operator.spec.js` is the committed
  structural gate. The v2.1 Phase 139 admin asset gate separately proves hard
  refresh and deep-link styling, so this e2e still asserts
  structure/order/`data-testid`/text — not pixels.

State is URL-driven on every screen, so any state is reproducible by URL
(`?tenant_id=…&delivery_id=…&theme=dark`) — the audit script relies on this
rather than on driving clicks.

## Asset URL robustness

- **Admin asset hard-refresh proof.** The relative-asset hard-refresh issue was
  resolved and proven in v2.1 Phase 139. The current asset strategy keeps
  adopter mount-path portability by emitting mount-rooted stylesheet hrefs while
  preserving CSS-relative font URLs inside the committed bundle.

  Phase 139 verified first HTML, stylesheet responses, font responses, and
  token-backed computed styling across the route matrix: preview index,
  preview scenario routes, preview error routes, gallery, operator, inbound,
  query deep links, and alternate admin mount roots. If a future hard refresh or
  direct deep link loses styling, treat it as a regression and run the focused
  browser proof:

  ```bash
  cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset hard load"
  ```

  **Guardrails:** keep the selected mount-aware strategy
  (`MountPathHook` → `MountPath.base/1` → `Layouts.css_url/1`) unless new
  evidence proves it cannot satisfy the route matrix. Approaches B-D from the
  backlog remain rejected as primary fixes: duplicate nested asset routes,
  `<base>` tags, URL canonicalization redirects, CDN/host asset rewrites, and
  public router macro options add churn without being needed for the verified
  behavior.
