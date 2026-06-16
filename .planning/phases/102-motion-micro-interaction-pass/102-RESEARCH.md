# Phase 102: Motion + Micro-interaction Pass - Research

**Researched:** 2026-06-16
**Domain:** CSS motion / Phoenix.LiveView.JS micro-interactions on a server-rendered, WebSocket-patched admin UI
**Confidence:** HIGH (all findings grounded in repo files + LiveView 1.1.28 docs + W3C/MDN/Chrome VT specs)

## Summary

Phase 102 is a **global motion uplift constrained on every axis** by the Phase 96 MOTION dossier (MOTION-LD-01..14, LOCKED — do not re-derive). The locked vocabulary already names six motions with their easing, durations, properties, mount triggers, reduced-motion behavior, and the entrance/exit ratio. The genuinely-open work this research fills is the *mechanics*: how to wire enter/exit asymmetry and first-mount stagger with `Phoenix.LiveView.JS`, what "loading skeletons" can honestly mean in a synchronous server-rendered LiveView, whether the CSS View Transitions API is achievable under the no-client-JS-hook constraint, how to add a token-named focus transition, and exactly how to extend the conformance gate + structural Playwright spec for a reduced-motion *structural* assertion.

Three findings change what the planner can promise:
1. **The app renders synchronously** (`mount/3` assigns data inline; no `assign_async`; the structural spec *asserts* inbound stays synchronous — `structural.spec.js:558-564`). There is no real client-perceived "loading window" to fill on initial mount or on patch. The honest implementation of "loading skeletons" is a **`phx-connected`/`phx-disconnected` connection-state placeholder** (CSS-only) plus reuse of `.motion-reveal` on content arrival — NOT a shimmer over a fetch that doesn't exist.
2. **Cross-document View Transitions cannot apply to in-app LiveView navigation.** `@view-transition { navigation: auto }` fires only on full same-origin document navigations; LiveView `live_patch`/`live_navigate` patch the DOM over WebSocket and never trigger it. Same-document VT requires a JS `startViewTransition()` call, which needs a client hook (banned). VT is therefore **scoped to hard-navigation entry only**, as pure progressive enhancement, gated behind `prefers-reduced-motion`.
3. **The named motions today are `@keyframes`/`animation`, not CSS `transition`s** (`app.css:241-288`). MOTION-LD-08/P-EK-08 (interruptibility) and the enter/exit asymmetry of MOTION-LD-02/04/13 are most cleanly expressed with `Phoenix.LiveView.JS` transition tuples + CSS classes. The planner must decide per-motion whether to keep the keyframe form (fine for first-mount entrances) or convert to transitions (required for JS-driven exits).

**Primary recommendation:** Implement enter/exit asymmetry and stagger with `Phoenix.LiveView.JS` time/transition tuples + new CSS state classes; implement "skeletons" as a CSS-only `phx-disconnected` connection placeholder, not a fetch shimmer; scope View Transitions to a CSS-only cross-document `@view-transition` block wrapped in `@media (prefers-reduced-motion: no-preference)` for hard-navigation entry only, and document explicitly that in-app live navigation cannot use VT without a banned hook; add a `transition-colors`-based focus transition token; and extend `structural.spec.js` with a reduced-motion *structural* assertion (computed `animation-duration`/`transition-duration` ≈ 0) plus a new conformance grep gate that bans layout-property transitions.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Enter/exit transition timing | CSS (`app.css` motion classes + `@theme` tokens) | LiveView.JS (trigger on mount/remove) | Durations/easing are token-owned; JS only fires class add/remove |
| First-mount stagger | CSS (`.motion-timeline > *:nth-child`) | — | Already pure-CSS `nth-child` delays; no JS needed (`app.css:278-288`) |
| Loading placeholder | CSS (`phx-disconnected`/`phx-connected` utility classes) | LiveView (connection state, framework-owned) | No async data layer exists; only connection state is a real "loading" signal |
| Focus ring transition | CSS (`transition-colors` + focus-visible utilities) | — | Paint-step color transition; no JS |
| View Transitions | Browser / CSS (`@view-transition` cross-document) | — | Same-document VT needs banned JS hook; only cross-document CSS path is reachable |
| Reduced-motion enforcement | CSS (`@media (prefers-reduced-motion: reduce)`) | Playwright (verifies via `emulateMedia`) | Global CSS block is the mechanism; Playwright is the gate |
| Conformance gate | Bash grep (`check-conformance.sh`) + Playwright (`structural.spec.js`) | ExUnit (advisory) | Existing two-layer pattern; extend both |

## Standard Stack

No new packages. This phase is CSS + HEEx + `Phoenix.LiveView.JS` only — consistent with the zero-Node-toolchain, no-client-JS-hook constraints.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | 1.1.28 | `JS.transition/1`, `JS.show/2`, `JS.hide/2`, `JS.add_class/2`, `JS.remove_class/2`, `phx-mounted`, `phx-remove` | Already a dep; the only sanctioned motion-trigger mechanism (`mix.lock` `[VERIFIED: mix.lock]`) |
| `phoenix` | 1.8.5 | LiveView host | Already a dep `[VERIFIED: mix.lock]` |
| Tailwind v4.1.12 (standalone binary) + vendored daisyUI | n/a | Compiles `app.css` → `priv/static/app.css` | Zero-Node build per `design-system.md:17` `[VERIFIED: app.css:6, design-system.md]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@playwright/test` | (e2e dir) | Structural assertions incl. reduced-motion via `page.emulateMedia({ reducedMotion: "reduce" })` | Extending `structural.spec.js` FACT 4 `[VERIFIED: structural.spec.js:1,749-772]` |

**Installation:** None. `mix deps.get` already resolves these.

## Package Legitimacy Audit

Not applicable — this phase installs **no external packages**. All work is in-repo CSS, HEEx, and Playwright spec edits. No registry verification needed.

## User Constraints (Hard Design Constraints — bind every task)

Copied from `.planning/STATE.md:71-77` (v1.11 Scope Locks) and the MOTION dossier. These are LOCKED:

- Motion **≤300ms per individual transition**, **ease-out only** (the single `tab-swap` crossfade exception uses `--ease-in-out`/`--ease-symmetric`), **transform/opacity only** (color/background/border-color permitted at fast token ≤100ms for state layers only — MOTION-LD-06/10).
- **No springs / no overshoot / no layout-property animation** (no height/width/max-height/padding/margin/top/left/font-size/border-width — MOTION-LD-10).
- **`prefers-reduced-motion` collapses ALL motion to instant** (MOTION-LD-09).
- **CSS + `Phoenix.LiveView.JS` only — NO client JS hook** (`design-system.md:99`; there is no client JS build).
- Entrance fires on **mount** (`phx-mounted` / element insertion), never on every patch (MOTION-LD-11/14).
- Type weights 400/700 only; semantic tokens only; flat elevation; 10%-accent rule; bundle rebuilt + committed (`git diff --exit-code priv/static/` — `design-system.md:19-23`).

### Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MOTION-01 | Micro-animations upgraded within hard constraints: token-named easing, real enter/exit asymmetry, first-mount stagger, loading skeletons, focus transitions, View-Transitions PE — no springs/overshoot, no layout-property animation, no client JS hook | §"Architecture Patterns" (enter/exit + stagger mechanics), §"Loading Skeletons", §"View Transitions", §"Focus Transitions" below; all grounded in `app.css`/LiveView.JS/VT specs |
| MOTION-02 | `prefers-reduced-motion` collapses all motion AND the motion conformance gate stays green | §"Conformance Gate" + §"Validation Architecture"; existing `@media` block at `app.css:292-300`, gate at `check-conformance.sh`, structural reduced-motion at `structural.spec.js:749-772` |

## Architecture Patterns

### System Architecture Diagram — motion trigger flow

```
                         ┌──────────────────────────────────────────┐
   Browser hard-nav ──▶  │  @view-transition { navigation: auto }    │  (cross-doc VT,
   (entry to /dev/mail   │  wrapped in @media prefers-reduced-motion │   entry only —
    or /ops/mail)        │  : no-preference  — app.css               │   CANNOT fire on
                         └──────────────────────────────────────────┘   live_patch)
                                          │
   WebSocket connect ──▶  phx-disconnected (CSS placeholder shown)  ──▶  phx-connected
   (LiveView mount)        │  body[phx-disconnected] .skeleton { … }      (placeholder hidden,
                           │  — framework-toggled, CSS-only               real content visible)
                           ▼
   Server render (sync)  ──▶  HEEx with element-level motion triggers:
   assigns inline             │
   (NO assign_async)          ├─ phx-mounted={JS.transition(...)}  ──▶ .motion-reveal entrance
                              │   (detail pane, cards, flash — fires ONCE on insertion)
                              │
                              ├─ .motion-timeline > * :nth-child   ──▶ staggered entrance
                              │   (40ms × index, capped 8 — pure CSS)
                              │
                              ├─ phx-remove={JS.hide(transition: {…})} ──▶ exit (150ms, before
                              │   DOM removal — faster than 220ms entrance per MOTION-LD-13)
                              │
                              └─ transition-colors duration-(--duration-fast) ──▶ focus/hover
                                  state layer (≤100ms, MOTION-LD-06)
                                          │
                                          ▼
              @media (prefers-reduced-motion: reduce)  *,::before,::after {
                animation-duration: .01ms; transition-duration: .01ms; … }  ──▶ ALL snap
```

### Component Responsibilities

| File | Carries motion | Current state | Phase 102 action |
|------|----------------|---------------|------------------|
| `assets/css/app.css:241-300` | All keyframes, motion classes, easing tokens, reduced-motion block | `@keyframes`+`animation:both` for reveal/timeline/overlay/fade; reduced-motion present | Add exit classes / convert to transitions for JS-driven exits; add focus-transition token; add VT block; add skeleton/connection-state rules; **rebuild + commit bundle** |
| `lib/mailglass_admin/components.ex:104` | `.motion-reveal` on flash | Static class, fires on mount via keyframe | Confirm reduced-motion inheritance; no exit (MOTION-LD-07 dismiss is instant) |
| `lib/mailglass_admin/operator_live.ex:466`, `inbound_live.ex:389` | `.motion-reveal` on detail pane (`id`-keyed) | Keyframe entrance on `id` change | Optionally add `phx-remove` exit; id-keying already re-triggers entrance |
| `operator/timeline.ex:30`, `inbound/timeline.ex:32` | `.motion-timeline` stagger | Pure-CSS nth-child stagger, cap 8 | Conformant as-is (MOTION-LD-03/08); verify reduced-motion |
| `operator/replay_modal.ex:18,26`, `inbound/replay_modal.ex:22,27` | `.motion-tab-swap` backdrop + `.motion-overlay` panel | Keyframe entrance; "exit stays instant (server-side :if removal)" per `app.css:270` | Optionally add `phx-remove` exit transition (MOTION-LD-04: 150ms scale-down) |
| `preview/tabs.ex:104` | `.motion-tab-swap` | id-keyed crossfade 150ms | Conformant (MOTION-LD-05); confirm `--ease-symmetric` token exists (see Pitfall 4) |
| `operator/shell.ex:207,231,287,295` | `transition-colors`, `.motion-reveal` flash | nav row-state + flash | Add focus-transition; verify |
| `preview_live.ex:404-409` | `.link` "Preview the first Mailable" CTA | Has focus-visible ring; GAP-02 already fixed (Phase 100) | Add `.motion-reveal` entrance per MOTION-LD-12 (currently no motion class) |

### Pattern 1: Enter/exit asymmetry with Phoenix.LiveView.JS (MOTION-LD-02/04/13)

**What:** Entrance fires on mount (220ms); exit fires before DOM removal (150ms). LiveView 1.1's `JS.transition/1`, `JS.show/2`, `JS.hide/2` accept a `{transition_classes, from_classes, to_classes}` tuple and a `time:` so the server can drive a CSS transition with no client hook.

**When to use:** Any element that both enters and leaves (detail pane, modal overlay, drawer). For entrance-only elements that simply re-key (detail pane `id`), the existing keyframe `.motion-reveal` is sufficient.

**Mechanics (LiveView 1.1.28):**
- `phx-mounted={JS.transition("motion-reveal", time: 220)}` — fires the entrance once on insertion (NOT on patch). Already the sanctioned pattern; the codebase uses `phx-mounted={JS.focus_first(...)}` at `operator_live.ex:497`. `[VERIFIED: operator_live.ex:497]`
- `phx-remove={JS.hide(transition: {"transition-all duration-150 ease-out", "opacity-100 translate-y-0", "opacity-0 translate-y-1"}, time: 150)}` — fires the exit before LiveView removes the node. `[CITED: hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html]`
- Durations come from `:root` tokens (`--duration-reveal: 220ms`, `--duration-fast: 150ms` — `app.css:197-198`), but `JS.hide(time: ...)` takes a literal integer ms; keep them numerically in sync with the tokens or the node is removed before/after the visual transition completes.

**Example:**
```elixir
# Source: operator_live.ex:466 pattern + Phoenix.LiveView.JS docs (LiveView 1.1.28)
# Entrance — already conformant (keyframe form), fires on id re-key:
<div id={"delivery-detail-#{@selected_delivery.id}"} class="motion-reveal space-y-4">

# Exit asymmetry (MOTION-LD-13, 150ms < 220ms) — add phx-remove:
<div
  id={"delivery-detail-#{@selected_delivery.id}"}
  class="motion-reveal space-y-4"
  phx-remove={JS.hide(time: 150, transition: {"ease-out duration-150", "opacity-100", "opacity-0"})}
>
```

**Pitfall:** `JS.hide` exit ONLY runs when LiveView removes the element itself (the element must leave the DOM as part of a diff). The current modals use `:if` removal, where LiveView removes the node and **does** run `phx-remove` — but `app.css:270` documents the *current* behavior as "Exit stays instant." Adding the exit is an MOTION-LD-04 upgrade, not a bug fix; the planner should scope it explicitly.

### Pattern 2: First-mount stagger (MOTION-LD-03/08) — already conformant, pure CSS

**What:** `.motion-timeline > *:nth-child(N)` applies `animation-delay: 40ms × (N-1)` capped at the 8th child (`app.css:281-288`). Each child's own animation is 220ms (`mg-timeline-in`). This is exactly MOTION-LD-03 + MOTION-LD-08.

**When to use:** Chronological event lists (`operator/timeline.ex:30`, `inbound/timeline.ex:32`). No JS — pure CSS sequence per P-EK-08 (predetermined → keyframes).

**Action for Phase 102:** Verify, don't rebuild. Confirm the cap-at-8 holds and reduced-motion neutralizes it (it does — the global `@media` block at `app.css:292` zeroes `animation-delay` and `animation-duration`).

### Pattern 3: Focus transitions (MOTION-LD-06)

**What:** A token-named color transition on focus rings, ≤100ms, paint-step only.

**Current state:** `transition-colors` is already present on nav rows, tabs, sidebar, and list rows (`shell.ex:207,231`, `tabs.ex:53`, `deliveries_list.ex:58`, `gallery_live.ex:174,199`). Some carry `duration-(--duration-fast)` (150ms), some carry bare `transition-colors` (browser default ~150ms), and `gallery_live.ex:174` carries `transition-colors ease-out` with no duration.

**Action:** Standardize on `transition-colors ease-out duration-(--duration-instant)` (90ms, `app.css:195`) OR `duration-(--duration-fast)` (150ms) per MOTION-LD-06's "≤100ms" target — note `--duration-fast` is 150ms, which exceeds 100ms. The planner must reconcile: either MOTION-LD-06's ≤100ms means `--duration-instant` (90ms) for focus/hover, with `--duration-fast` reserved for row-state background swaps. **Recommendation:** focus rings use `duration-(--duration-instant)` (90ms, within ≤100ms); row background/color hover uses `duration-(--duration-fast)` (150ms). Cite this as the resolution of the MOTION-LD-06 "≤100ms" vs `--duration-fast`=150ms tension.

### Anti-Patterns to Avoid
- **Animating a layout property to fake a skeleton "collapse"** (e.g. `max-height` accordion) — banned by MOTION-LD-10. Use opacity/transform only.
- **`startViewTransition()` via a client hook** — banned (no client JS hook). Only the CSS-only cross-document `@view-transition` path is permitted.
- **Re-triggering `.motion-reveal` on every patch** — MOTION-LD-11. Entrance must be mount-gated (id-keyed element or `phx-mounted`), never applied to a stable element that re-renders on filter keystrokes.
- **Adding a shimmer skeleton over synchronous content** — there is no fetch; a shimmer would animate forever over instantly-available data. Dishonest and likely an infinite animation (reduced-motion violation risk).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Exit animation before DOM removal | A JS `MutationObserver` hook | `phx-remove={JS.hide(transition: …)}` | Framework primitive; no client hook; LiveView coordinates removal timing |
| Entrance-on-insert | A custom mount hook | `phx-mounted={JS.transition(...)}` or id-keyed `.motion-reveal` | MOTION-LD-11; framework-native |
| Stagger sequencing | JS `setTimeout` loop | `nth-child` animation-delay (already in `app.css:281-288`) | Pure CSS, interruptible, reduced-motion-safe |
| Connection-state placeholder | Custom WebSocket-state JS | `phx-disconnected`/`phx-connected` CSS selectors (LiveView sets `body[phx-disconnected]`) | Framework toggles these classes; CSS-only styling |
| Reduced-motion gating | Per-component JS check | Global `@media (prefers-reduced-motion: reduce)` block (`app.css:292`) | One source of truth; MOTION-LD-09 |

**Key insight:** Every motion mechanic this phase needs already has a Phoenix/CSS primitive. The no-client-JS-hook constraint is not a limitation here — it forces the *correct* (interruptible, framework-coordinated) implementation per P-EK-07/08.

## Loading Skeletons — concrete recommendation

**The honest finding:** the admin LiveViews render **synchronously**. `preview_live.ex` `mount/3` assigns inline (`preview_live.ex:64-84`); operator/inbound do the same; there is **no `assign_async`** and the structural spec actively asserts inbound stays synchronous (`structural.spec.js:558-564`: `expect(source).not.toContain("assign_async")`). There is therefore **no data-fetch loading window** to fill with a shimmer skeleton. A shimmer would animate over content that is already present — dishonest and an infinite-animation reduced-motion risk.

**What IS a real loading window:** the brief gap between the *static* (dead-render) HTML and the *connected* LiveView socket. LiveView toggles `phx-loading` on elements with in-flight events, and sets `phx-connected`/`phx-disconnected` body-level state (`LiveSocket` adds these classes). `[CITED: hexdocs.pm/phoenix_live_view — JS Interop / "phx-" loading classes]`

**Recommended approach (CSS-only, fits every constraint):**
1. A **connection-state placeholder**: a static, low-fidelity placeholder block shown while `body` carries `phx-disconnected`, hidden once `phx-connected`. Pure CSS:
   ```css
   /* app.css — connection-state placeholder; opacity-only, no layout animation */
   .mg-skeleton { opacity: 0; }
   [phx-connected] .mg-skeleton { display: none; }
   [phx-disconnected] .mg-skeleton { opacity: 1; }
   ```
   No pulse/shimmer keyframe — a static placeholder + the existing `.motion-reveal` on the real content's arrival IS the idiomatic answer for a server-rendered LiveView. This satisfies MOTION-01's "loading skeletons" deliverable honestly.
2. If a subtle "pulse" is wanted, it MUST be opacity-only (`opacity: .6 ↔ 1`), ease-out, and the reduced-motion block already zeroes it. But the static-placeholder + reveal-on-arrival is the recommended, lower-risk path — a pulsing skeleton implies an ongoing fetch that does not exist.
3. **Where it belongs:** only surfaces where the dead-render shows a structural shell before hydration benefit. Given relative-asset-URL behavior (`design-system.md:162-178`), deep-link hard refreshes can load unstyled — a skeleton would be unstyled too. **Recommendation:** keep skeletons minimal and scoped; do not over-invest. Document in the plan that "loading skeleton" = connection-state placeholder, and that the reveal-on-arrival motion (`.motion-reveal`) is the primary "content settled into place" signal.

**Reduced-motion:** any pulse animation is auto-neutralized by `app.css:292-300`. A static placeholder needs no special handling.

**COPY tie-in:** COPY-LD-15 already specifies loading-label copy ("Loading Deliveries…") "if explicit loading states are added." If the planner adds a connection placeholder with text, use that copy.

## View Transitions — what is and isn't possible

**Conclusion: VT is achievable ONLY as a CSS-only cross-document enhancement on hard navigation entry. In-app LiveView navigation cannot use VT without a banned client JS hook. Scope accordingly.**

**Why:**
- **Cross-document VT** (`@view-transition { navigation: auto }`) fires only on **full same-origin document navigations** — the browser snapshots the old document, navigates, and cross-fades. `[CITED: developer.chrome.com/docs/web-platform/view-transitions/cross-document; MDN @view-transition]`
- **LiveView `live_patch`/`live_navigate` patch the DOM over WebSocket (morphdom-style diff)** — they do NOT perform a document navigation, so `@view-transition { navigation: auto }` **never fires** for in-app navigation. This is the central interaction fact. `[VERIFIED: LiveView 1.1.28 patches DOM via WS; W3C VT spec requires document navigation for the declarative path]`
- **Same-document VT** (`document.startViewTransition(() => domUpdate())` + `view-transition-name`) is the only way to animate an in-app DOM patch — but it requires a JS call wrapping the DOM mutation. LiveView owns the DOM mutation inside its client runtime; intercepting it requires a **client JS hook** (`phx-hook`/`startViewTransition`), which is **banned** by the hard constraint. There is no `Phoenix.LiveView.JS` primitive that wraps a patch in `startViewTransition`.
- **It does not break LiveView either way.** A bare `@view-transition { navigation: auto }` CSS rule is inert for WS patches and harmless on unsupported browsers (graceful degradation — Chrome/Edge 126+, Safari 18.2+, Firefox flagged). It will produce a cross-fade only on the *first* hard load / full reload of an admin page.

**Recommended scope for Phase 102:**
1. Add a CSS-only cross-document opt-in, gated on motion preference:
   ```css
   @media (prefers-reduced-motion: no-preference) {
     @view-transition { navigation: auto; }
   }
   ```
   This is pure progressive enhancement: cross-fades full-document entry into the admin, no-ops for live navigation, no-ops on unsupported browsers, and is disabled under reduced-motion. `[CITED: MDN @view-transition; css-tricks @view-transition almanac]`
2. **Do NOT** attempt same-document VT or per-element `view-transition-name` choreography — it cannot be triggered without a hook. The plan must state this limitation explicitly so it isn't treated as an unmet deliverable.
3. **Reduced-motion:** the `@media (prefers-reduced-motion: no-preference)` wrapper is the correct disable mechanism (VT is added only when motion is allowed). Belt-and-suspenders: the global reduce block (`app.css:292`) does not auto-cover VT pseudo-elements, so the `no-preference` gate on the `@view-transition` rule is **required**, not optional.

**Honest caveat:** because deep-link hard refresh can load unstyled (`design-system.md:162-178`), and because in-app navigation can't use VT, the *visible* VT surface area is small (full reload of a mounted admin page). It is a legitimate MOTION-01 deliverable but a minor one — set expectations in the plan.

## Conformance Gate — exactly what exists today

MOTION-02 requires "the motion conformance gate stays green" and (per the objective) a structural reduced-motion assertion. Here is precisely what the gates assert now, so the planner can extend without guessing.

### Layer 1 — `scripts/check-conformance.sh` (grep over `lib/**/*.ex`, fail-on-match)
Five gates, **none motion-specific** (`check-conformance.sh:27-82`):
- BADGE-GATE: bans `defp badge_class`
- TYPE-GATE: bans `text-sm|text-xs|text-base` (size utilities)
- BOLD-GATE: bans `font-medium|font-semibold`
- GAP-GATE: bans `gap-3|gap-4|gap-6`
- HEX-GATE: bans `color…#hex`

### Layer 1b — `scripts/check-conformance-advisory.sh` (now fail-closed per [99-05])
- TYPE-GATE: bans `text-lg|xl|2xl|3xl|4xl|5xl`
- TRACK-GATE: bans `tracking-[`

**Gap:** there is **no grep gate that bans layout-property transitions** (MOTION-LD-10) or non-token easing. The planner should **add a MOTION-GATE** to `check-conformance.sh` that bans the prohibited animated properties, e.g. fail on `transition-\[?(height|width|padding|margin|top|left|right|bottom|max-height)` and on `ease-in\b` outside the documented `--ease-symmetric` exception. This is the cleanest machine-checkable enforcement of MOTION-LD-01/10.

### Layer 2 — `e2e/structural.spec.js` (Playwright, fail-on-violation)
Six "D-01 pillar facts." **FACT 4 is the motion fact** (`structural.spec.js:749-772`):
- Sets `page.emulateMedia({ reducedMotion: "reduce" })` **before** navigation (the required order).
- Asserts only that primary content is **visible and stable** under reduced-motion on each of the three surfaces (operator deliveries list, inbound heading, preview-orientation). It does **NOT** assert that animation/transition durations are actually collapsed.

**What a structural reduced-motion assertion should add (MOTION-02):** under `emulateMedia({reducedMotion:"reduce"})`, query a known motion-carrying element's computed style and assert the duration is effectively zero:
```javascript
// Source: extends structural.spec.js FACT 4 pattern (emulateMedia before nav)
await page.emulateMedia({ reducedMotion: "reduce" });
await openOperator(page);
const el = page.locator(".motion-reveal").first(); // or .motion-timeline > *
const dur = await el.evaluate(e => getComputedStyle(e).animationDuration);
// app.css:294 sets animation-duration: .01ms !important under reduce
expect(parseFloat(dur)).toBeLessThanOrEqual(0.05); // ≤ 50ms ≈ instant
const tdur = await el.evaluate(e => getComputedStyle(e).transitionDuration);
expect(parseFloat(tdur)).toBeLessThanOrEqual(0.05);
```
Note: `app.css:294,297` uses `0.01ms !important` (not `0ms`), so assert `≤ ~0.05` not `=== 0`. The structural FACT 5 already reads `getComputedStyle(...).outlineWidth` for focus rings (`structural.spec.js:786`), so the codebase pattern for computed-style assertions is established.

**Also note FACT 5 (focus rings)** asserts `outlineWidth > 0` on focus. If Phase 102 adds a `transition-colors` to focus rings, FACT 5 still passes (transition doesn't change the focused steady-state width). No regression risk there.

## Runtime State Inventory

Not a rename/refactor/migration phase — CSS + HEEx motion uplift only. **None — verified:** no datastore keys, no live-service config, no OS-registered state, no secrets/env vars, and no build artifacts beyond the committed `priv/static/app.css` bundle (which IS the one artifact that must be rebuilt + committed — see Pitfall 1).

## Common Pitfalls

### Pitfall 1: Forgetting to rebuild + commit the bundle
**What goes wrong:** Any edit to `app.css` (new motion class, VT block, skeleton rule, focus token) changes the source but not `priv/static/app.css`; CI `git diff --exit-code priv/static/` fails.
**Why it happens:** The build is manual (`mix mailglass_admin.assets.build`); executors only rebuild if the plan task lists it (see project memory "Admin UI phase verification gaps").
**How to avoid:** Every task that touches `app.css` or adds a literal new class string to HEEx MUST end with `cd mailglass_admin && mix mailglass_admin.assets.build` and commit `priv/static/app.css`. Verify with `mix verify.preview` (which runs the build + `git diff --exit-code`, `mix.exs:183-188`).
**Warning signs:** Local pass, CI red on bundle drift.

### Pitfall 2: Tailwind tree-shakes dynamically-built class names
**What goes wrong:** `class={"duration-#{ms}"}` emits nothing — Tailwind's scanner only keeps literal strings (`design-system.md:28`).
**How to avoid:** All motion utilities must be literal static strings (`duration-(--duration-fast)`, `ease-out`, `motion-reveal`). JS transition tuples in `JS.hide(transition: {...})` are runtime values pushed to the client, not Tailwind-scanned — those classes (`opacity-0`, `translate-y-1`, `duration-150`) must still appear as literals *somewhere* the scanner sees, or be standard utilities Tailwind always generates. Prefer the named `.motion-*` classes (authored directly in `app.css`, not scanned) for exit transitions to avoid tree-shaking surprises.

### Pitfall 3: `JS.hide(time:)` desync removes the node mid-animation
**What goes wrong:** If `JS.hide(time: 150)` but the CSS transition is 220ms, LiveView removes the DOM node at 150ms and the last 70ms of the visual exit is cut.
**How to avoid:** Keep `time:` numerically equal to the CSS transition duration (150ms for exits per MOTION-LD-13). Document the literal-ms ↔ token coupling.

### Pitfall 4: `--ease-symmetric` token may not exist yet
**What goes wrong:** MOTION-LD-05 references `var(--ease-symmetric)` for the tab-swap crossfade, but `app.css:138` defines `--ease-in-out` (not `--ease-symmetric`), and `.motion-tab-swap` currently uses `var(--ease-out)` (`app.css:266`), not in-out.
**Why it matters:** The dossier names a token that isn't in `app.css`; the current crossfade isn't even using the in-out curve the dossier prescribes.
**How to avoid:** The planner must reconcile: either (a) add `--ease-symmetric` aliasing `--ease-in-out` and switch `.motion-tab-swap` to it, or (b) treat `--ease-in-out` as the symmetric token and update the dossier reference. **Recommendation:** add `--ease-symmetric: var(--ease-in-out)` to `@theme` so the LD-05 reference resolves, and switch `.motion-tab-swap` to use it. This is the one place the locked dossier and the current code disagree — flag it for a discuss/plan decision (it is a public-CSS-token naming question, but reversible, so research-and-lock per the decision policy).

### Pitfall 5: Named motions are keyframes, not transitions — exits need a different mechanism
**What goes wrong:** `.motion-reveal` etc. are `animation: <keyframes> both` (`app.css:259-273`). You cannot "reverse" a keyframe entrance into an exit by removing a class; the element just snaps. P-EK-08/MOTION-LD-08 want interruptible CSS *transitions* for exits.
**How to avoid:** For exits, use `JS.hide(transition: {...})` with transition utilities (opacity/transform), not a reversed keyframe. Entrances can stay as keyframes (fire-once-on-mount is exactly what `animation: both` does). The planner should treat entrance (keyframe, keep) and exit (transition via JS, add) as different mechanisms.

### Pitfall 6: `voice_test.exs` "Oops" dep-JS false positive
**What goes wrong:** The voice test substring-matches "n**oops**" in inlined Phoenix dep JS (project memory). Unrelated to motion but runs in `mix test`.
**How to avoid:** Exclude from phase pass/fail; don't weaken the test. Use scoped test commands per the Validation Architecture below, not bare `mix test`.

## Code Examples

### Entrance (keep) — id-keyed reveal, fires once
```elixir
# Source: operator_live.ex:466 (current, conformant with MOTION-LD-02/11)
<div id={"delivery-detail-#{@selected_delivery.id}"} class="motion-reveal space-y-4">
```

### Exit asymmetry (add) — 150ms < 220ms (MOTION-LD-13)
```elixir
# Source: Phoenix.LiveView.JS 1.1.28 — JS.hide/2 with transition tuple + time
phx-remove={JS.hide(time: 150, transition: {"ease-out duration-150", "opacity-100", "opacity-0 translate-y-1"})}
```

### CSS-only cross-document View Transition (add, reduced-motion gated)
```css
/* Source: MDN @view-transition + Chrome cross-document VT docs */
@media (prefers-reduced-motion: no-preference) {
  @view-transition { navigation: auto; }
}
```

### Connection-state skeleton (add, opacity-only, no fetch shimmer)
```css
/* Source: LiveView phx-connected/phx-disconnected body classes */
.mg-skeleton { opacity: 1; }
[phx-connected] .mg-skeleton { display: none; }
```

### Focus transition token (standardize)
```heex
<%!-- focus ring ≤100ms (MOTION-LD-06) — use --duration-instant (90ms) --%>
class="… transition-colors ease-out duration-(--duration-instant) focus-visible:ring-2 focus-visible:ring-primary"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| JS animation libs (Framer Motion) for enter/exit | `Phoenix.LiveView.JS` transition tuples (server-driven CSS) | LiveView 0.18+ (`JS` module), stable in 1.x | No client JS build needed; exactly the constraint here |
| `startViewTransition()` JS for SPA transitions | CSS-only `@view-transition { navigation: auto }` for cross-document | CSS View Transitions L2; Chrome/Edge 126, Safari 18.2 (2024-2025) | Lets MPAs cross-fade without JS — but only on document nav, not WS patch |
| Shimmer skeletons over async fetches | Connection-state placeholders for server-rendered LiveView | n/a | Skeleton semantics differ when there's no client fetch |

**Deprecated/outdated:** Treating "loading skeleton" as a fetch shimmer in a synchronous LiveView — there is no fetch to shim.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `body[phx-connected]`/`[phx-disconnected]` are set by LiveView 1.1.28's LiveSocket and usable as CSS hooks without a custom hook | Loading Skeletons | LOW — documented LiveView behavior; if absent, fall back to static placeholder + reveal-on-arrival (no connection gating). Planner should confirm the exact attribute form (`phx-connected` class vs attribute) against the running `phoenix_live_view.js` before authoring CSS selectors. |
| A2 | `--ease-symmetric` does not exist in `app.css` and must be added/reconciled | Pitfall 4 | LOW — verified by reading `app.css:107-139`; only `--ease-out`/`--ease-in-out` present. |
| A3 | A bare `@view-transition { navigation: auto }` is inert for LiveView WS patches and harmless on unsupported browsers | View Transitions | LOW — follows directly from W3C VT spec (declarative path requires document navigation) + graceful-degradation guarantee; confirm visually on one hard-load during execution. |

## Open Questions

1. **MOTION-LD-06 "≤100ms" vs `--duration-fast`=150ms.**
   - What we know: dossier says row-state ≤100ms; `--duration-fast` is 150ms, `--duration-instant` is 90ms.
   - What's unclear: which token the planner should bind to focus vs hover.
   - Recommendation: focus rings → `--duration-instant` (90ms, satisfies ≤100ms); row background/color hover → `--duration-fast` (150ms). Lock this in the plan.

2. **`--ease-symmetric` naming (Pitfall 4).**
   - Recommendation: add `--ease-symmetric: var(--ease-in-out)` to `@theme`; switch `.motion-tab-swap` to it. Reversible public-CSS-token decision → research-and-lock, no escalation.

3. **How much skeleton to ship.**
   - What we know: no async data layer; deep-link hard refresh can load unstyled.
   - Recommendation: ship a minimal connection-state placeholder + reveal-on-arrival; do not build pulsing shimmers. Treat this as a deliberately small deliverable and say so in the plan.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `phoenix_live_view` | JS.transition/hide, phx-mounted/remove | ✓ | 1.1.28 | — |
| Tailwind standalone binary | bundle rebuild | ✓ (zero-Node, vendored) | 4.1.12 | — |
| `@playwright/test` | structural reduced-motion assertion | ✓ | e2e/ committed | — |
| Browser with VT support | visible cross-document VT | partial (Chrome/Edge 126+, Safari 18.2+, FF flagged) | — | graceful no-op; not a build blocker |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** VT visible only on supporting browsers; degrades to no animation everywhere else (intended).

## Validation Architecture

> nyquist_validation is not disabled in config — section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) + Playwright (`@playwright/test`) for structural/browser facts |
| Config file | `mailglass_admin/mix.exs` (aliases), `mailglass_admin/e2e/` (Playwright) |
| Quick run command | `cd mailglass_admin && scripts/check-conformance.sh && scripts/check-conformance-advisory.sh` |
| Full suite command | `cd mailglass_admin && mix verify.preview` (compile + test + assets.build + bundle-diff) |

### Phase Requirements → Test Map
| Req | Behavior | Test Type | Automated Command | File Exists? |
|-----|----------|-----------|-------------------|-------------|
| MOTION-01 | Token-named easing / transform-opacity only / no layout-property transitions | conformance grep (NEW MOTION-GATE) | `cd mailglass_admin && scripts/check-conformance.sh` | ⚠️ gate exists; MOTION-GATE rule ❌ Wave 0 |
| MOTION-01 | Enter/exit asymmetry present (exit class/`phx-remove` on detail/overlay) | structural Playwright (computed transition-duration / DOM attr) | `cd mailglass_admin && npx playwright test e2e/structural.spec.js` | ⚠️ spec exists; asymmetry assertion ❌ Wave 0 |
| MOTION-01 | First-mount stagger (cap 8) intact | already conformant — verify | grep `.motion-timeline > \*:nth-child` in `app.css` | ✅ `app.css:281-288` |
| MOTION-01 | Focus transition token applied | structural Playwright FACT 5 (`outlineWidth > 0` on focus) + grep `transition-colors` literal | `npx playwright test e2e/structural.spec.js -g "focus"` | ✅ FACT 5 `structural.spec.js:779-824` |
| MOTION-01 | Loading skeleton = connection-state placeholder (opacity-only, no layout anim) | grep: `.mg-skeleton` is opacity-only + MOTION-GATE bans layout props | `scripts/check-conformance.sh` (post-MOTION-GATE) | ❌ Wave 0 |
| MOTION-01 | View Transitions = CSS-only `@view-transition`, reduced-motion gated | grep `app.css` for `@view-transition` inside `prefers-reduced-motion: no-preference`; manual visual on one hard-load | `grep -A2 'no-preference' mailglass_admin/assets/css/app.css` | ❌ Wave 0 (manual visual = single hard-load check) |
| MOTION-02 | reduced-motion collapses ALL motion (computed duration ≈ 0) | structural Playwright (NEW assertion, `emulateMedia` before nav) | `npx playwright test e2e/structural.spec.js -g "reduced-motion"` | ⚠️ FACT 4 exists (visibility only); duration assertion ❌ Wave 0 |
| MOTION-02 | conformance gate stays green | conformance grep (all gates) | `cd mailglass_admin && scripts/check-conformance.sh && scripts/check-conformance-advisory.sh` | ✅ |

### Sampling Rate
- **Per task commit:** `cd mailglass_admin && scripts/check-conformance.sh && scripts/check-conformance-advisory.sh` (fast, no boot)
- **Per wave merge:** `cd mailglass_admin && npx playwright test e2e/structural.spec.js` (FACT 4 + new reduced-motion + asymmetry assertions)
- **Phase gate:** `cd mailglass_admin && mix verify.preview` green (compile + scoped test + assets.build + `git diff --exit-code priv/static/`) before `/gsd:verify-work`. Use scoped Playwright/conformance commands, NOT bare `mix test` (project memory: ~57 unrelated Oban failures + `voice_test` "Oops" dep-JS false positive in worktrees).

### Wave 0 Gaps
- [ ] `scripts/check-conformance.sh` — add **MOTION-GATE**: ban `transition-(height|width|padding|margin|top|left|right|bottom|max-height)` and arbitrary `transition-[...]` of layout props; ban `ease-in\b` (except documented `--ease-symmetric`). Validate by running it, not by grep proof (project memory).
- [ ] `e2e/structural.spec.js` — extend FACT 4: under `emulateMedia({reducedMotion:"reduce"})`, assert computed `animationDuration`/`transitionDuration` ≤ ~0.05 on a `.motion-reveal` / `.motion-timeline > *` element (MOTION-02 structural proof).
- [ ] `e2e/structural.spec.js` — add enter/exit asymmetry assertion (exit class or `phx-remove` attr present on detail/overlay; or computed exit transition-duration = 150ms).
- [ ] `app.css` — add `--ease-symmetric` token (Pitfall 4) + focus `--duration-instant` standardization; rebuild + commit bundle.

## Security Domain

`security_enforcement` not set to false, but this phase is **CSS/HEEx motion + Playwright spec only** — no auth, session, access-control, input-validation, or cryptography surface is touched.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | no | No new inputs; motion is presentational |
| V6 Cryptography | no | none |
| All others | no | Motion uplift introduces no new trust boundary |

**Preserved invariants (do not regress):** PII minimization (`mask_recipient/1`) and multi-tenant scoping are untouched by motion classes; motion never carries data. The View Transitions and skeleton work introduce no new routes, no new data exposure.

## Sources

### Primary (HIGH confidence)
- `mailglass_admin/assets/css/app.css:107-300` — easing tokens, named motions (keyframes), reduced-motion block
- `mailglass_admin/docs/design-system.md:79-178` — motion vocabulary, conformance checklist, asset-URL limitation
- `mailglass_admin/scripts/check-conformance.sh`, `check-conformance-advisory.sh` — current grep gates
- `mailglass_admin/e2e/structural.spec.js:249-957` — six pillar facts incl. FACT 4 (reduced-motion) + FACT 5 (focus)
- `mailglass_admin/lib/mailglass_admin/preview_live.ex`, `operator_live.ex:466,494-498`, `inbound_live.ex:36,298,389` — synchronous render, existing JS usage
- `mailglass_admin/mix.lock` — phoenix_live_view 1.1.28, phoenix 1.8.5
- `.planning/research/v1.11/MOTION.md` + `SUMMARY.md` — MOTION-LD-01..14 (LOCKED, binding)
- `.planning/STATE.md:71-77` — hard design constraints

### Secondary (MEDIUM confidence)
- [Chrome cross-document view transitions](https://developer.chrome.com/docs/web-platform/view-transitions/cross-document) — `navigation: auto`, browser support
- [MDN @view-transition at-rule](https://developer.mozilla.org/en-US/docs/Web/CSS/@view-transition) — declarative cross-document opt-in semantics
- [MDN Using the View Transition API](https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API/Using) — same-document requires `startViewTransition()`
- [CSS-Tricks @view-transition almanac](https://css-tricks.com/almanac/rules/v/view-transition/) — usage + reduced-motion gating
- Phoenix.LiveView.JS docs (1.1.28) — `JS.transition/1`, `JS.hide/2` transition tuple + time; `phx-connected`/`phx-disconnected`/`phx-loading` classes

### Tertiary (LOW confidence)
- None — all motion mechanics cross-verified against repo or official docs.

## Metadata

**Confidence breakdown:**
- Loading skeletons: HIGH — synchronous render verified in source; structural spec asserts no `assign_async`.
- View Transitions scope: HIGH — VT spec + LiveView patching model are unambiguous; in-app VT requires a banned hook.
- Enter/exit + stagger mechanics: HIGH — LiveView.JS primitives confirmed; stagger already in CSS.
- Conformance gate extension: HIGH — exact gate contents read; gap (no motion grep, visibility-only reduced-motion) confirmed.
- `--ease-symmetric` reconciliation: MEDIUM — dossier/code mismatch is real; resolution is a small reversible token decision.

**Research date:** 2026-06-16
**Valid until:** 2026-07-16 (stable; VT browser support trending wider, LiveView 1.1.x stable)

## RESEARCH COMPLETE
