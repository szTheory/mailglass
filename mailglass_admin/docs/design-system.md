# mailglass_admin Design System

This guide explains the current implementation mechanics for Mailglass Admin.
brandbook/brand-book.md owns identity and voice; brandbook/tokens.css owns
canonical brand values; assets/css/app.css maps those values to the semantic
roles and utilities used by Admin. Keep examples here aligned with the shipped
source CSS and committed bundle.

> Ownership: brand values live in the brandbook. Admin CSS owns their
> implementation mapping. Components use the semantic roles and scales defined
> by that mapping.

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

The brandbook defines values; Admin CSS maps them into implementation roles. It
is the source for the Admin semantic mapping:

### 1. Color — daisyUI theme blocks (`@plugin "daisyui-theme"` in `app.css`)

The **only** place light and dark diverge. Brand palette mapped to daisyUI
semantic tokens. Use the semantic names, never raw Tailwind palette
(`text-gray-500`) and never hex in HEEx.

| Semantic | Light | Dark | Use |
|---|---|---|---|
| base-100 | Paper #F8FBFD | Ink #0D1B2A | app/detail surface |
| base-200 | White #FFFFFF | Ink-raised #152538 | raised surfaces |
| base-300 | Mist-edge #C7DCE5 | Ink-edge #315069 | borders |
| base-content | Ink #0D1B2A | Mist #EAF6FB | primary text |
| primary / accent | Glass #277B96 | Ice #A6EAF2 | accent and focus emphasis |
| secondary / neutral | Slate #5C6B7A | Mist-soft #B8CAD4 | secondary text |
| success / warning / error | Pine / Amber / Crimson | Pine-bright / Amber-bright / Crimson-bright | status only |

**Accent discipline (the 10% rule):** `primary`/Glass appears only on the
selected-row border, the primary CTA, the active nav/timeline node, and focus
emphasis. It is never the default border or badge color. Status tints use
opacity (`bg-warning/10`), not new tokens.

### 2. Structure — `@theme` block + `:root` tokens (theme-independent)

Each `@theme` token is simultaneously a CSS variable and a Tailwind utility.

| Scale | Tokens | Utilities |
|---|---|---|
| Spacing (4px grid) | `--spacing-xs…3xl` (4/8/16/24/32/48/64) | `p-md`, `gap-sm`, `px-lg`, … |
| Type (400/700 only) | --text-label/body/heading/display (14/16/20/28px) | text-label, text-body, … |
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

## Review surfaces

The broad, interactive component and state inventory is the Admin Gallery at
/dev/mail/gallery. The reference demo's /dev/storybook is a curated explorer
for reusable primitives and representative examples; it intentionally does not
duplicate every Gallery state. Shared examples such as navigation and theme
selection should remain consistent in both places. Both surfaces use the
versioned Admin CSS bundle rather than maintaining a second stylesheet.

These routes are examples for the default development mount. Host applications
choose the Admin mount path, so use the path configured by that application
when opening the Gallery or Preview.

## Review workflow

Use the Gallery for broad component/state coverage and Storybook for the
curated primitive examples. For repeatable browser evidence, run the focused
existing browser specs and record the candidate, route, theme, viewport, state,
and served stylesheet identity with the captures. Screenshots help compare
rendered output; semantic, accessibility, interaction, and layout assertions
remain the machine-verifiable behavior checks.

Historical screenshots and visual scores describe their original review only.
They are not current acceptance criteria. Browser-rendered Preview output also
does not certify Gmail, Outlook, Apple Mail, remote image loading, or delivered
email dark-mode behavior.

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

## Contextual help and copy controls

Use `Components.field_help` for optional explanations and full module identities.
Keep text triggers within their container and allow long names to wrap. Help panels
are positioned relative to the viewport. Reveal, overlay, and timeline containers
with help use opacity-only entry animations: transforms change the coordinate
origin of fixed descendants and can push a tooltip outside a narrow viewport.

Use `Components.timestamp` and `Components.copy_value` for dates and identifiers.
The displayed value is the copy control; the shared toast confirms success. Dates
show local time and expose the exact UTC value on hover and copy. Native controls
inside quick views own Enter, so keyboard copying or opening a link must not also
invoke the global full-detail shortcut.

## Investigation controls and health signals

The observation period and the last-checked timestamp are both observation basis:
group them left-aligned as one wrapping group, with Refresh adjacent to the
timestamp rather than distributed across a toolbar. Other context, such as a
section title, stays outside the group.

Delivery and inbound filters follow task order in the DOM and visually: Search,
Time window, latest event or mailbox outcome, then Provider. Keep the distinct
meaning of delivery events and mailbox outcomes in their labels and help.

Health answers whether recorded problems need investigation. Show only nonzero
failed/bounced/rejected/delayed deliveries, inbound processing failures/unrouted messages,
and failed/unmatched webhook processing. Use compact issue rows with scoped
investigation links, not a permanent grid of zero-count KPI cards. Intentional
suppression policy, replay history, and reconciliation activity belong to record
investigation and are neither fetched nor displayed on this overview.

When all checks are current, active mail with no recorded problems shows “No issues
found”, explicitly limited to the observation period. No activity shows a neutral
“No mail activity in this period”. Stale or unavailable reads must never produce an
all-clear; retain known problems and identify the data that could not be refreshed.
Small outbound/inbound activity counts provide context without implying successful
delivery. Health ignores provider, status, search, and paging parameters inherited
from investigation links. Hide inbound activity and checks when inbound is absent.

All custom help, stat hints, and copyable timestamp tooltips use the shared
`mg-field-help` implementation. Help belongs to its icon/label trigger rather than
the whole card. Tooltips open 8px below their trigger, centered where space permits.
They flip above near the bottom edge and shift inward to retain a 12px viewport
margin. Their arrow points toward the trigger after that adjustment. The shared
observer repairs placement after LiveView patches and viewport changes; only
changed styles are written to avoid an observer feedback loop. A tooltip stays
hidden until it has a calculated position. Escape dismisses help, including UTC
copy hints. Keep accessible descriptions independently available to assistive
technology. Do not nest a help button inside a clickable card or link.

Desktop section navigation uses the brand accent on the current icon and a short
underline beneath its bold label. Avoid combining an accent rail, filled tile,
and bold text for one selection. Mobile tabs use a matching underline and no
filled selection tile. Keep the 44px targets and visible keyboard focus.
