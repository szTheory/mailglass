# Pitfalls Research — v1.13 Admin Design-System Stress Test & UX Uplift

**Domain:** `mailglass_admin` mountable Phoenix LiveView dashboard — design-system overhaul, usability-bug sweep, idempotent meet-or-beat quality ratchet (Operator `/ops/mail`, Inbound `/ops/mail/inbound`, Preview `/dev/mail`).
**Researched:** 2026-06-18
**Confidence:** HIGH (project artifacts + grounded codebase grep + WCAG 2.2 / WAI-ARIA APG / Emil Kowalski / GOV.UK convergence)

> **Scope note.** This file EXTENDS the v1.11 dossiers (`.planning/research/v1.11/MOTION.md`,
> `DARK-MODE.md`, `COMPONENT-STATES.md`, `IA.md`, `MICROCOPY.md`) and the armed v1.11 ratchet
> (`.planning/RATCHET-GAP-REGISTER.md`, `mailglass_admin/e2e/structural.spec.js`,
> `mailglass_admin/scripts/check-conformance.sh`, `scripts/check_motion_conformance.sh`). It does
> NOT redo them. The root foundational `.planning/research/PITFALLS.md` (v1.3 trust-proof) is
> untouched. Where an existing guard already covers a pitfall, this file says so and proposes the
> *delta* guard the widened v1.13 matrix needs (system theme, WCAG 2.2 AA, new viewports, stress
> fixtures).

## Fractal Phase Vocabulary (for phase mapping)

The milestone is fractal: **foundations → primitives → forms → app-shell → data-display →
component-groups → pages/flows**, plus a cross-cutting **ratchet/verification** level and a
**fixture-cohort** level. Pitfalls below map to one of these levels (the synthesizer assigns the
actual phase number, continuing from 108 → 109+):

| Level (L) | Owns |
|-----------|------|
| **L0 Foundations** | semantic tokens, z-index layer system, focus rings, overlays, motion/theme tokens |
| **L1 Primitives** | buttons, badges, inputs, icons, links — every state |
| **L2 Forms** | filter forms, inputs, controls, disabled/enabled affordance |
| **L3 App-Shell** | nav, tabs, theme picker, orientation strips, layout chrome |
| **L4 Data-Display** | tables-vs-cards, stat cards, timelines, pagination, empty/error states |
| **L5 Component-Groups** | meta-components, spacing/hierarchy, box-in-box discipline |
| **L6 Pages/Flows** | per-persona JTBD happy/error/boundary/edge paths, least-surprise |
| **LF Fixtures** | multi-tenant cohort + stress fixtures (no-data/one/many/long/non-ASCII/null/error) |
| **LR Ratchet** | GAP register, structural/a11y/motion gates, idempotent re-run, axe scan |

---

## Bucket A — The Maintainer's Concrete Usability-Bug List

Each is treated as a pitfall to **hunt → prevent → lock with a guard**. The "lab-passes-but-ugly"
gap (Bucket C) is the meta-reason these survived v1.11: most are *interaction/visual* defects that
substring ExUnit tests and even structural Playwright assertions can miss unless the assertion is
written to catch them. Every row below proposes a concrete catch.

### A1: Modal/drawer behind the scrim (or screen darkened with an inaccessible overlay)

**What goes wrong:** the scrim paints *over* the dialog (or the dialog's z-index is below the
backdrop), so the operator sees a darkened, frozen screen with no usable dialog — or the scrim is a
dead non-dismissible layer.
**Why it happens:** hard-coded ad-hoc z-index values with no layer system. Today `replay_modal.ex`
uses a literal `z-40` on the scrim and the panel has *no* explicit z — it works by source order
only, which is exactly the fragility a formal layer system removes. There are **no z-index tokens
in `app.css`** (verified by grep).
**Warning sign:** any `z-NN` literal in `lib/`; a new overlay (drawer, popover, toast) added
without a token; backdrop and panel on the same stacking context.
**Prevention:** L0 formal z-index layer system (`--z-base / --z-dropdown / --z-overlay-scrim /
--z-overlay-panel / --z-toast`), scrim strictly below panel, every overlay consumes a token.
**Phase to address:** **L0 Foundations** (define tokens) → **L1/L4** (migrate modal/drawer/toast).
**Guard/test:**
- Grep gate (extend `check-conformance.sh` **Z-GATE**): fail on raw `z-[0-9]` / `z-\[` in `lib/`
  outside an allowlist.
- Playwright structural: open replay modal, assert the dialog panel is the top hit-test target at
  its centroid (`page.evaluate` `elementFromPoint`) and the scrim does **not** intercept clicks on
  the panel; assert panel `getBoundingClientRect` is inside viewport. (Extends the existing
  "replay modal focus-management parity" test.)

### A2: Scroll bugs / nested-scroll traps / awkward scrollbars

**What goes wrong:** a modal body and the page both scroll (scroll-chaining), the operator gets
trapped in an inner scroll region, or double scrollbars appear; body scroll isn't locked while an
overlay is open.
**Why it happens:** `overflow-y-auto` applied at multiple nesting levels (replay modal already has
`overflow-y-auto` on the scrim wrapper); no `overscroll-behavior: contain`; no body-scroll-lock on
overlay open.
**Warning sign:** two visible scrollbars at once; background scrolls under an open modal; an inner
panel that scrolls when the user expected the page to.
**Prevention:** single owning scroll container per overlay, `overscroll-behavior: contain` on
overlay bodies, lock body scroll while an overlay is open, avoid nested `overflow-auto`.
**Phase to address:** **L0** (scroll-lock + overscroll utility convention) → **L4** (apply to
modal/drawer/long tables).
**Guard/test:** Playwright: with replay modal open at 390px and a tall list behind it, scroll the
modal to its end and assert `window.scrollY` of the background did not change (no scroll-chaining);
assert at most one element has a vertical scrollbar in the overlay subtree.

### A3: Hover states on non-interactive empty-state heroes/cards

**What goes wrong:** an empty-state hero or a read-only stat card lifts/shadows/changes color on
hover, implying it's clickable when it isn't — a false affordance.
**Why it happens:** a shared card component applies `hover:` styling unconditionally; empty-state
heroes reuse the interactive card.
**Warning sign:** `hover:` utilities on elements that are not `<a>`/`<button>`/`[role=button]`/
`[phx-click]`.
**Prevention:** hover affordance is reserved for interactive elements. Empty-state heroes and
read-only cards use a non-interactive variant (no hover transform/shadow, default cursor).
**Phase to address:** **L1 Primitives** (card variants) → **L4** (empty-state heroes, stat cards).
**Guard/test:** Playwright structural: enumerate elements carrying a `hover:`-derived transition;
assert each is interactive (has one of `a,button,[role=button],[phx-click],[tabindex]`). Run on the
no-data fixture so empty-state heroes are present.

### A4: Floating/hovering elements in the wrong spot covering other content

**What goes wrong:** a tooltip, popover, sticky toolbar, or theme menu floats over and obscures the
control it describes or the operator's next action; origin-unaware popovers appear detached.
**Why it happens:** no positioning discipline; `position: fixed/absolute` without anchor; toasts
that overlap action buttons (see A23).
**Warning sign:** a floating element whose bounding box overlaps an interactive control; a popover
that doesn't visually connect to its trigger.
**Prevention:** origin-aware overlays (Emil Kowalski — `transform-origin` matches the trigger, not
the default `center`), collision-aware placement, reserve space so floats never cover primary
actions.
**Phase to address:** **L0** (overlay positioning convention) → **L3/L4** (theme menu, tooltips,
sticky toolbars).
**Guard/test:** Playwright: for each open floating element, assert its rect does not overlap the
rect of any `btn-primary` / primary CTA in view.

### A5: Misaligned elements (not pleasingly)

**What goes wrong:** labels, icons, and values in a row don't share a baseline/center; columns
don't line up across cards; ragged left edges.
**Why it happens:** mixing `items-start`/`items-center` ad hoc; icon + text without
`items-center gap`; per-card padding drift.
**Warning sign:** visual jitter scanning down a list; icons floating above/below their labels.
**Prevention:** L0 alignment conventions (icon+label always `inline-flex items-center gap-xs`),
shared row primitives, consistent grid columns across sibling cards.
**Phase to address:** **L5 Component-Groups** (alignment across sibling components) with **L1**
primitives establishing the icon+label baseline.
**Guard/test:** Playwright structural: in a list, assert sibling rows share the same `left` x-offset
for their leading element (±1px); in a stat-card group assert all cards share the same top y for
their label and value (catches A5 + A11). This is a **structural-assertion** the LLM-scored PNG
matrix should also flag visually.

### A6: Awkward padding with content chopped off one side

**What goes wrong:** asymmetric padding (e.g. `pl-4` with no `pr`), or a long value overflows its
container and is clipped on the right (the clipped stat-card label the maintainer hit on the real
demo).
**Why it happens:** single-side padding utilities; fixed-width containers with no `min-w-0` /
`truncate`; content assumed short.
**Warning sign:** text touching or clipped at a container edge; one-sided breathing room.
**Prevention:** symmetric padding tokens by default; `min-w-0` on flex children that hold text;
explicit `truncate` + `title`/tooltip for genuinely long values; test with long-content fixtures.
**Phase to address:** **L4 Data-Display** (stat cards, tables) + **LF Fixtures** (long-ID, non-ASCII,
high-count).
**Guard/test:** Playwright on the **long-ID / non-ASCII fixture**: assert no element's
`scrollWidth > clientWidth + 1` without an explicit `truncate`/overflow strategy (catches
chopped/overflowing content); assert stat-card label fully renders (no clip) at 320px.

### A7: Inconsistent / accidental spacing (or zero spacing that looks accidental)

**What goes wrong:** gaps vary between sibling sections (12px here, 19px there), or zero gap makes
two distinct things look like one.
**Why it happens:** off-grid one-off values; mixing `gap-3`/`gap-4`/`gap-6` with semantic tokens.
**Warning sign:** any off-grid spacing utility; visually unequal sibling gaps.
**Prevention:** 4px grid + semantic spacing tokens only (`gap-sm/md/lg`), already partly enforced.
**Phase to address:** **L0 Foundations** (spacing scale) — the existing **GAP-GATE** already bans
`gap-3/4/6`; v1.13 extends it to `space-y/space-x/p*/m*` off-grid tokens.
**Guard/test:** Extend `check-conformance.sh` **GAP-GATE** to cover `(space-[xy]|p[xytrbl]?|m[xytrbl]?)-(3|5|7|9|...)`
off-grid numerics in `lib/` (allowlist documented grid tokens). Already a grep gate — widen the
pattern.

### A8: Elements flush inside containers with no breathing room

**What goes wrong:** content sits hard against the card/panel border (no inner padding), feels
cramped and unfinished.
**Why it happens:** a container with a border/background but no padding token; nesting that drops
the inner padding.
**Warning sign:** text/controls touching a bordered container edge.
**Prevention:** every bordered/surface container carries a padding token; a "surface" primitive that
bundles border+radius+padding so flush-content can't happen by omission.
**Phase to address:** **L1 Primitives** (surface/card primitive) → **L5** (verify in groups).
**Guard/test:** Playwright: for each `.card`/surface element, assert computed `padding` ≥ token
floor (e.g. ≥12px) on all four sides.

### A9: Cards nested in cards = accidental "box prison"

**What goes wrong:** a bordered card inside a bordered card inside a bordered panel — visual nesting
noise, the "box prison." (The support-cards Tier1/Tier2 hierarchy from v1.7 is a known hotspot.)
**Why it happens:** reaching for a card whenever grouping is needed, regardless of depth.
**Warning sign:** ≥2 levels of bordered/elevated containers in one subtree.
**Prevention:** elevation/border discipline — only one bordered surface level per region; inner
groupings use spacing or dividers, not nested borders. Tie to the L0 elevation tier system (only N
tiers exist).
**Phase to address:** **L5 Component-Groups** (the box-in-box rule lives at the group level).
**Guard/test:** Playwright structural: assert max nesting depth of elements carrying a visible
border-or-shadow surface class is ≤ 2 within any page region (`data-region`); run across all three
surfaces.

### A10: Squished / unreadable table columns

**What goes wrong:** at 320–768px, table columns crush long values to 1–2 chars/line or overflow
horizontally with an ugly scroll.
**Why it happens:** native `<table>` forced into narrow viewports; no responsive card fallback.
**Warning sign:** table cell text wrapping to many short lines; horizontal scroll on a data table at
mobile width.
**Prevention:** the **tables-vs-cards discipline** (A11) — collapse tables to stacked cards/lists
below a breakpoint, or make the table horizontally scrollable *intentionally* with a sticky first
column and a visible scroll affordance.
**Phase to address:** **L4 Data-Display** (responsive table/card pattern).
**Guard/test:** Playwright at 320/390px: assert no data table overflows the viewport
(`scrollWidth ≤ clientWidth`) OR the table is wrapped in an intentional `overflow-x` container with
`role`/affordance; assert min cell content width readable (no cell `clientWidth < 40px` with wrapped
text).

### A11: Overuse of tables where cards/lists fit better

**What goes wrong:** a 2-column key/value set or a short status list rendered as a heavyweight
table, adding chrome and harming mobile.
**Why it happens:** table is the default mental model for "data."
**Warning sign:** `<table>` with ≤2 data columns, or used for non-tabular key/value content.
**Prevention:** GOV.UK-style discipline — tables only for genuinely tabular multi-column comparison;
key/value uses description lists, status uses cards/lists. Document the decision rule in the
component-lab.
**Phase to address:** **L4 Data-Display** (codify tables-vs-cards rule + audit each `<table>`).
**Guard/test:** Audit checklist row in GAP register per `<table>` ("justified as tabular? Y/N");
grep inventory gate: count `<table` occurrences in `lib/` and require each to map to a GAP register
justification line (meet-or-beat: count must not increase without justification).

### A12: Inconsistent stat-card design

**What goes wrong:** stat cards differ in label position, number size, padding, icon presence across
the Operator overview / support cards / inbound tiers.
**Why it happens:** stat cards authored per-surface instead of one primitive.
**Warning sign:** two stat cards with different internal layout on different surfaces.
**Prevention:** one `stat_card` primitive with fixed slots (label / value / optional delta / optional
icon); every stat card routes through it (the v1.7 `status_badge` consolidation is the precedent).
**Phase to address:** **L1 Primitives** (define `stat_card`) → **L4** (migrate all call sites).
**Guard/test:** Grep gate **STATCARD-GATE**: no ad-hoc stat markup; all stat cards use the
`stat_card` component (ban divergent local stat helpers, mirror BADGE-GATE). Gallery renders all
stat-card variants in one row for visual parity (LLM PNG cell).

### A13: Disabled controls that look enabled & enabled controls that look disabled

**What goes wrong:** a disabled button has full-contrast text (looks clickable, then does nothing),
or an enabled secondary button is so muted it reads as disabled.
**Why it happens:** disabled styling not tied to a token; ghost/secondary variants too low-contrast.
**Warning sign:** disabled element without reduced opacity/`aria-disabled`; an enabled control below
the interactive-contrast floor.
**Prevention:** L1 mandatory disabled state token (reduced opacity + `cursor-not-allowed` +
`disabled`/`aria-disabled`); enabled controls meet 3:1 non-text contrast (WCAG 1.4.11) so they never
read as disabled. **Never rely on color alone** to signal disabled (WCAG 1.4.1).
**Phase to address:** **L1 Primitives** + **L2 Forms** (control states).
**Guard/test:** Playwright structural: every `[disabled]`/`[aria-disabled=true]` has opacity < 1 and
`cursor: not-allowed`; every enabled `button`/`a` meets the contrast floor (extend the existing
contrast matrix test to assert disabled≠enabled appearance). Add a gallery cell showing
enabled vs disabled side-by-side per control.

### A14: Weird focus / hover states

**What goes wrong:** focus ring clipped by `overflow-hidden`, invisible on a colored surface, or
hover and focus styles fight; focus lost after a LiveView patch.
**Why it happens:** `overflow-hidden` on focus-ring ancestors; focus ring color same as surface;
patch re-renders the focused node.
**Warning sign:** Tab moves but nothing visibly changes; ring half-clipped; focus jumps to top after
an action.
**Prevention:** L0 focus-ring token with 3:1 contrast against ALL surfaces (WCAG 2.4.13 Focus
Appearance, ≥2px perimeter), never clipped; for LiveView, preserve focus across patches
(`phx-update` / stable DOM ids) — covered partly by the v1.11 "visible focus rings" tests.
**Phase to address:** **L0 Foundations** (focus token) → **L6** (post-patch focus persistence).
**Guard/test:** Extend the existing "visible focus rings" Playwright tests: after a `phx-click`
that patches the list, assert focus is on a sensible element (not `<body>`); assert focus ring not
clipped (ring rect within an `overflow:visible` ancestor). Add WCAG 2.4.13 perimeter/contrast check.

### A15: Unreadable button text (same color font + background)

**What goes wrong:** button label and fill are near-identical (e.g. ghost button on a same-tone
surface, or a token regression makes `btn-primary` text == fill).
**Why it happens:** token role mix-up; dark-mode desaturation collapsing text/fill contrast.
**Warning sign:** a button whose text contrast < 4.5:1 against its own background in light OR dark.
**Prevention:** every button variant proven ≥4.5:1 text-on-fill in light + dark (DARK-MODE.md accent
desaturation rule applies).
**Phase to address:** **L1 Primitives** (button variants) verified in **LR** contrast matrix.
**Guard/test:** Extend the existing WCAG AA contrast matrix Playwright test to explicitly sample
each button variant's label-vs-own-background ratio in light + dark (currently the matrix samples
text-on-surface; add button-on-fill).

### A16: Poor dark-mode contrast

**What goes wrong:** muted text, borders, or accents fall below AA on dark surfaces; elevation
inverts; pure-black surfaces.
**Why it happens:** light tokens reused on dark; accent not desaturated. (v1.11 DARK-MODE.md fixed
the known cases; v1.13 widens to *system* theme and new components.)
**Warning sign:** any dark-mode cell < 4.5:1 (text) / 3:1 (non-text) in the matrix.
**Prevention:** apply DARK-MODE.md LOCKED DECISIONS to all new/changed components; verify under the
**system** theme too (system resolving to dark must match explicit-dark exactly).
**Phase to address:** **L0** (tokens) + every level's dark verification; **LR** matrix widened to
light/dark/**system**.
**Guard/test:** Existing contrast-matrix tests already cover light/dark at 390/768/1440 — **extend
to system theme** (set `prefers-color-scheme: dark` via emulation with theme=system and assert
parity with explicit dark).

### A17: NO system / light / dark picker (system default missing)

**What goes wrong:** today the admin has only a **binary light↔dark toggle** driven by a URL query
param (`?theme=dark`, `dark_chrome` boolean) — **no "System" option and system is not the default**
(verified in `shell.ex` `theme_toggle/1` and `operator_live.ex` `toggle_theme`). The operator's OS
preference is ignored.
**Why it happens:** the toggle predates the requirement; URL-param theme was the cheapest path.
**Warning sign:** no three-way control; no `prefers-color-scheme` consumption; theme lost on a fresh
URL.
**Prevention:** L3 three-way **System / Light / Dark** picker with **System as default**; resolve
system via `prefers-color-scheme`; persist explicit choice (cookie/session for SSR — see A18/B-T2),
treat absence-of-choice as "follow system" (do NOT persist "system" as an explicit dark/light — see
B-T2).
**Phase to address:** **L3 App-Shell** (theme picker) on top of **L0** theme tokens.
**Guard/test:** Playwright: assert a 3-option theme control exists with `aria` reflecting the active
choice; with no stored preference and `prefers-color-scheme: dark`, assert the shell renders dark;
selecting Light then reloading keeps Light; selecting System then changing OS preference flips the
shell.

### A18: Tabs not showing selected / active state

**What goes wrong:** the active tab (preview `tabs.ex`, nav pills) looks the same as inactive ones,
or relies on color alone.
**Why it happens:** `aria-selected`/`aria-current` set but no distinct visual; color-only active
cue.
**Warning sign:** active tab indistinguishable at a glance or for color-blind users.
**Prevention:** active tab carries `aria-selected`/`aria-current=page` **and** a non-color cue
(weight/underline/background) ≥3:1; never color alone (WCAG 1.4.1). The accent-allowlist test
already *permits* accent on `[aria-selected=true]`/`[aria-current=page]` — v1.13 asserts the cue is
actually *present and non-color-only*.
**Phase to address:** **L3 App-Shell** (tabs, nav pills).
**Guard/test:** Playwright: assert exactly one tab has `aria-selected=true`/`aria-current=page` AND
its computed style differs from siblings in a non-color property (font-weight or border/underline,
not just color).

### A19: Weird pagination affordances when there's nothing to paginate

**What goes wrong:** prev/next or page numbers render (often disabled-looking) when there's a single
page or zero rows.
**Why it happens:** pagination rendered unconditionally.
**Warning sign:** pagination control visible with ≤1 page of data.
**Prevention:** honest pagination — render only when `total_pages > 1`; on empty data show the
empty-state, never an inert pager.
**Phase to address:** **L4 Data-Display** (pagination) + **LF Fixtures** (no-data/one/many).
**Guard/test:** Playwright on **no-data** and **one-page** fixtures: assert pagination control is
absent; on **many** fixture: assert it's present and functional.

### A20: Icons that don't semantically "read"

**What goes wrong:** an icon's meaning doesn't match its action (e.g. a generic dot for "bounced",
wrong heroicon for an action), or a decorative icon is announced to AT.
**Why it happens:** nearest-available heroicon picked; missing `aria-hidden` on decorative icons;
the hand-maintained `heroicons-inline.js` only renders embedded SVGs (a new `hero-*` renders
invisible — a known footgun).
**Warning sign:** icon-meaning mismatch in review; decorative icon without `aria-hidden`; a
`hero-*` name with no SVG in the inline plugin.
**Prevention:** L1 icon semantics review (each icon maps to its domain meaning, documented in the
gallery); decorative icons `aria-hidden=true`; meaningful icons have an accessible label.
**Phase to address:** **L1 Primitives** (icon audit) — gallery is the audit surface.
**Guard/test:** Grep: every `name="hero-X"` used in `lib/` has a matching SVG in
`heroicons-inline.js` (prevents the invisible-icon footgun). Gallery renders every icon with its
label so meaning mismatches are reviewable in the PNG matrix.

### A21: Loading states that jump layout (CLS)

**What goes wrong:** a spinner/skeleton has a different size than the loaded content, so content
jumps when it arrives.
**Why it happens:** loading placeholder not sized to match final content.
**Warning sign:** visible reflow/jump when data loads; CLS on patch.
**Prevention:** skeletons/placeholders reserve the final content's box (same height/width); motion
tokens already require transform/opacity only (no layout-thrash) — MOTION.md.
**Phase to address:** **L4 Data-Display** (loading states) + **LR** motion gate.
**Guard/test:** Playwright: capture a content region's `getBoundingClientRect` height in loading
state and after load; assert delta ≤ small threshold (no jump). The inbound "loading contract
remains synchronous" test is a precedent to extend.

### A22: Skeleton overuse / misleading skeletons

**What goes wrong:** skeletons shown for instant/synchronous content, or skeleton shapes don't
resemble the real content (misleading), or they persist too long.
**Why it happens:** skeleton applied as a default decoration.
**Warning sign:** skeleton on a synchronously-rendered region; skeleton shape unlike final content.
**Prevention:** skeletons only for genuinely async/slow regions; shape must approximate real
content; prefer no skeleton for synchronous LiveView mounts (the inbound surface is synchronous).
**Phase to address:** **L4 Data-Display** (loading discipline).
**Guard/test:** Audit/GAP-register row enumerating each skeleton use with an async justification;
Playwright assert synchronous surfaces (inbound) show no skeleton on mount.

### A23: Toasts obscuring controls

**What goes wrong:** a flash/toast covers the primary action button or important content, or blocks
operator feedback under stress.
**Why it happens:** toast positioned over content; no safe zone.
**Warning sign:** toast rect overlaps an interactive control or the operator's next action.
**Prevention:** toasts in a reserved region that never overlaps primary actions; auto-dismiss +
manual dismiss; never block operator feedback (MOTION research: motion must not obscure feedback).
**Phase to address:** **L0** (toast z-token + region) → **L3** (flash placement).
**Guard/test:** Playwright: trigger a flash; assert its rect does not overlap any `btn-primary` or
the focused element's rect; assert it's above content via the z-token (not a literal).

### A24: "All-clear" / placeholder cards rendering bare "—" / "___"

**What goes wrong:** an empty metric or missing value renders a bare em-dash/underscore with no
context, looking like a rendering bug rather than a deliberate "nothing here" state.
**Why it happens:** `value || "—"` fallback with no surrounding microcopy.
**Warning sign:** a lone `—`/`-`/`___`/empty cell with no label or explanation.
**Prevention:** deliberate empty/all-clear microcopy ("No failures in the last 24h", "Not yet
sent") instead of bare punctuation; MICROCOPY.md "thoughtful maintainer" voice; em-dash only with an
adjacent label.
**Phase to address:** **L4 Data-Display** (empty/all-clear states) + **L6** microcopy pass.
**Guard/test:** Playwright on **no-data / null-field** fixtures: assert no visible text node is
exactly `—`/`-`/`–`/`___` without an adjacent descriptive label; voice_test-style grep that bare
placeholder glyphs aren't the sole content of a card.

---

## Bucket B — Discipline Footguns (a11y / motion / theme / host-collision)

### a11y (WCAG 2.2 AA + WAI-ARIA APG)

**B-A1: Focus not restored to the trigger on overlay close.**
*Warning sign:* closing the replay modal/drawer drops focus to `<body>` or top of page.
*Prevention:* on close, return focus to the element that opened the dialog (APG Dialog pattern —
"the user's point of regard is maintained by returning focus to the trigger"). Prefer native
`<dialog>`+`showModal()` semantics where the zero-JS constraint allows; otherwise restore focus
server-side via a stable trigger id.
*Phase:* **L4** (overlays) / **LR**.
*Guard:* The existing structural test already asserts replay-modal Escape-to-close + role/aria;
**extend** it to assert focus returns to the opening trigger after close (capture trigger id, close,
assert `document.activeElement` matches).

**B-A2: Focus trap missing or one-way.**
*Warning sign:* Tab from inside the open modal reaches the page/URL bar behind the scrim.
*Prevention:* trap Tab/Shift+Tab within the dialog while open (APG); initial focus to first
interactive element, not the container.
*Phase:* **L4**. *Guard:* Playwright: with modal open, Tab N times and assert focus never lands on
an element outside `[role=dialog]`.

**B-A3: Escape doesn't close / wrong Escape scope.**
*Warning sign:* Escape ignored, or Escape closes the whole page state.
*Prevention:* Escape closes the topmost overlay only (APG). *Phase:* **L4**.
*Guard:* already partially covered ("Escape-to-close"); assert Escape closes only the overlay,
leaving the underlying view intact.

**B-A4: APG misuse — faking native semantics on custom widgets.**
*Warning sign:* `role="button"` on a `<div>` without keyboard handlers; `role="tab"` without the
full tablist keyboard model; ARIA added where a native element would do.
*Prevention:* **First rule of ARIA — use native elements** (`<button>`, `<a>`, `<dialog>`); only
adopt an APG pattern in full (all required roles/states/keys) or not at all. Don't half-implement a
tablist.
*Phase:* **L1/L3**. *Guard:* Grep gate **ARIA-GATE**: flag `role="button"`/`role="tab"`/
`role="dialog"` on non-native elements for manual justification; Playwright: any `role=tab` set
implies arrow-key navigation works.

**B-A5: Reliance on color alone.**
*Warning sign:* status conveyed only by badge color; active tab only by color; error only red.
*Prevention:* always pair color with text/icon/shape (WCAG 1.4.1). status_badge already carries
text; verify tabs (A18), disabled (A13), errors.
*Phase:* **L1/L2/L4**. *Guard:* Playwright: render a status group under a grayscale filter
(`filter: grayscale(1)`) and assert states remain distinguishable (text/icon present).

**B-A6: Target sizes below WCAG 2.2 2.5.8 (24×24) / project floor 44px.**
*Warning sign:* icon-only buttons or dense list controls under the floor.
*Prevention:* interactive targets ≥24×24 CSS px (WCAG 2.2 AA) — project already enforces a stronger
≥44px floor; keep it and apply to new controls (theme picker, pagination, table-row actions).
*Phase:* **L1/L3/L4**. *Guard:* existing "touch targets ≥44px" structural tests — **extend** to the
new theme picker, pagination, and table-row action controls.

**B-A7: Focus obscured after open (WCAG 2.2 2.4.11 Focus Not Obscured).**
*Warning sign:* a sticky header/toast covers the focused element when tabbing.
*Prevention:* ensure the focused element is never fully hidden by sticky/floating chrome
(scroll-padding, z-order). *Phase:* **L0/L3**.
*Guard:* Playwright: Tab through a long list under a sticky header; assert each focused element's
rect is fully within the unobscured viewport.

**B-A8: Focus Appearance below 2.4.13 (perimeter/contrast).**
*Warning sign:* 1px low-contrast ring. *Prevention:* ring ≥2px-equivalent area, ≥3:1 contrast vs
both focused/unfocused and adjacent colors. *Phase:* **L0**.
*Guard:* extend "visible focus rings" tests to assert outline width and contrast meet 2.4.13.

**B-A9: Visible focus lost after a LiveView patch.**
*Warning sign:* operator action re-renders the list and focus jumps to `<body>`.
*Prevention:* stable DOM ids + `phx-update="stream"`/keyed children so the focused node survives;
restore focus to a sensible target after destructive patches.
*Phase:* **L6 Pages/Flows**. *Guard:* Playwright: focus a row, trigger a filter patch, assert focus
is still on a meaningful element (covered as A14's delta).

### motion (Emil Kowalski)

**B-M1: Animating from `scale(0)`.**
*Warning sign:* overlays/popovers pop from nothing. *Prevention:* start from a higher value
(≈`scale(0.95–0.96)`) so the element "never disappears completely" (Emil Kowalski) — already in
MOTION.md LOCKED DECISION; verify new overlays comply. *Phase:* **L0/L4**.
*Guard:* extend motion gate to flag `scale(0)` / `scale-0` keyframe origins in `lib/`+`app.css`.

**B-M2: Layout-thrashing properties.**
*Warning sign:* transitions on height/width/top/left/margin/padding. *Prevention:* transform/opacity
only — **already enforced** by MOTION-GATE / `check_motion_conformance.sh`. *Phase:* **LR**. Keep
gate; widen to any new component.

**B-M3: Sluggish-after-first tooltip.**
*Warning sign:* every tooltip waits the full delay. *Prevention:* first tooltip has the safety
delay; subsequent hovers within the group open instantly with no animation (Emil Kowalski).
*Phase:* **L1/L3**. *Guard:* manual gallery review (zero-JS constraint may limit tooltip grouping —
document the decision in MOTION delta).

**B-M4: Motion blocking/obscuring operator feedback.**
*Warning sign:* a transition delays or hides a critical status/flash under stress.
*Prevention:* feedback (flash/status) appears immediately; motion never gates the operator seeing an
outcome; ≤300ms cap (MOTION.md). *Phase:* **L0/L3**.
*Guard:* Playwright: assert flash content is in the DOM and visible within the duration cap after the
triggering event.

**B-M5: Parallax / decorative motion in an admin.**
*Warning sign:* scroll-linked parallax, ambient animation. *Prevention:* none — admin motion is
functional only (origin-aware overlays, reveals, crossfades); no parallax. *Phase:* **L0**.
*Guard:* motion gate bans scroll-linked/parallax utilities; reduced-motion collapses everything
(existing reduced-motion tests).

### theme

**B-T1: FOUC / flash of inaccurate theme on first paint.**
*Warning sign:* page flashes light then dark (or vice-versa) on load. *Prevention:* resolve theme
**before first paint**. For this SSR LiveView, render `data-theme` server-side from the persisted
cookie/session on the `<html>` element (today `root.html.heex` sets `data-theme={root_theme(...)}`
server-side — good for explicit choice; the gap is the **System** branch, which needs a tiny
render-blocking head script reading `prefers-color-scheme` when no explicit cookie exists, since the
server can't know the OS preference).
*Phase:* **L0/L3**. *Guard:* Playwright: load with `theme=system` + emulated dark and assert the
`<html data-theme>` is dark on the **first** painted frame (no light→dark transition observed); CLS/
no-flash check.

**B-T2: Conflating "system default" with an explicit user choice in persistence.**
*Warning sign:* selecting "System" stores `"dark"`/`"light"`, so later OS changes don't follow.
*Prevention:* persist three distinct states — *unset → follow system*, *light*, *dark*. "System"
means **clear the stored preference**, not store the current resolved value (matches the
"perfect theme switch" guidance). *Phase:* **L3**.
*Guard:* Playwright: pick System → assert no explicit theme cookie/value is stored → change OS pref →
shell follows.

**B-T3: URL-param theme is fragile / not durable.**
*Warning sign:* today theme rides on `?theme=dark` query param; a fresh URL or shared link loses it
and there's no system mode. *Prevention:* move durable theme to a host-safe cookie/session
(namespaced, see B-H*), keep URL param only as an override for deterministic tests. *Phase:* **L3**.
*Guard:* Playwright: set theme, navigate to a param-less URL, assert theme persists.

### host-app CSS/JS collisions (mountable library)

**B-H1: Global styles leaking into the host app.**
*Warning sign:* admin CSS sets bare-element rules (`button {}`, `a {}`, `:root` resets) that bleed
into the host. *Prevention:* scope all admin styles under a mount root class/`@scope`; no global
element resets; the bundle must not redefine host `:root` tokens.
*Phase:* **L0 Foundations**. *Guard:* Grep gate **SCOPE-GATE**: ban bare-element selectors and
unscoped `:root` in `app.css`; assert tokens are namespaced (`--mg-*`).

**B-H2: z-index wars with the host.**
*Warning sign:* admin overlays use huge arbitrary z (`z-[9999]`) that fights or loses to host
chrome. *Prevention:* the L0 z-token scale (A1) uses a documented, bounded range under a scoped
stacking context (`isolation: isolate` on the mount root) so admin overlays stack correctly without
escalating against the host. *Phase:* **L0**. *Guard:* Z-GATE (A1) + assert mount root sets
`isolation: isolate`.

**B-H3: Hijacking the host theme / `data-theme`.**
*Warning sign:* admin sets `data-theme` on `<html>` and overrides the host's theme globally.
*Prevention:* admin theming scoped to the admin mount subtree, not `<html>`, OR clearly documented
as owning its own routes only; never mutate host global theme attributes outside admin routes.
*Phase:* **L3**. *Guard:* assert `data-theme` is set only on the admin layout root within admin
routes; host pages unaffected (reference/demo host-app smoke).

**B-H4: JS hook / asset collisions.**
*Warning sign:* admin ships global JS hooks or vendor scripts that clash with host hooks; duplicate
daisyUI/vendor globals. *Prevention:* zero-Node constraint already limits JS; namespace any hook;
keep `heroicons-inline.js`/`daisyui*.js` self-contained and non-global. *Phase:* **L3**.
*Guard:* bundle-clean grep gate (existing) + assert no global window pollution introduced.

---

## Bucket C — Process Footguns (the idempotent ratchet)

These address the **"passes the lab but ugly in the real demo"** gap — the exact trigger for v1.13.
v1.11 armed a strong ratchet yet the maintainer still hit lived-experience rough edges, because the
ratchet measured *structure and tokens*, not *lived interaction quality on realistic data*.

**B-C1: Overfitting to screenshots instead of real interaction quality.**
*Warning sign:* PNG-matrix cells score high but clicking the real app feels wrong (modal-behind-
scrim, scroll trap — none visible in a static PNG). *Prevention:* the ratchet must include
**interaction** assertions (hit-testing A1, scroll-chaining A2, focus-restore B-A1, layout-jump
A21), not just static PNG scoring; drive Playwright through real flows on real fixtures.
*Phase:* **LR Ratchet**. *Guard:* add the interaction-class Playwright tests above to
`structural.spec.js`; meet-or-beat includes an "interaction" pillar, not only visual.

**B-C2: Aesthetics-over-usability regressions.**
*Warning sign:* a prettier card loses its hover affordance or contrast; motion added that delays
feedback. *Prevention:* usability assertions (contrast, target size, focus, feedback latency) are
**hard gates** that a visual improvement can't trade away; the GAP register requires every visual
change to keep usability cells meet-or-beat. *Phase:* **LR**. *Guard:* contrast/target/focus tests
are blocking; PNG aesthetic score is advisory only (it must never be allowed to override a failing
a11y assertion).

**B-C3: Fixing one page while leaving component-level inconsistency.**
*Warning sign:* the Operator overview looks great but the same stat card / badge / table looks
different on Inbound. *Prevention:* fractal **bottom-up** order — fix the primitive/component once
(L1), then every page inherits it; the gallery/component-lab is the parity surface across all
surfaces. *Phase:* **L1 → L5 → L6** ordering (foundations/primitives before pages).
*Guard:* gallery renders each shared component once; structural test asserts a given component
(e.g. `stat_card`, `status_badge`) is byte-identical in class across surfaces (single-source-of-
truth, mirrors BADGE-GATE).

**B-C4: "Passes the lab but ugly in the real demo."**
*Warning sign:* CI green on `host_app`/seeded fixtures, but `make demo` (the rich `demo_app`) looks
rough — the literal v1.13 trigger. *Prevention:* run the ratchet's visual + interaction matrix
against the **rich `demo_app` realistic data**, not only the minimal seeded host_app; close the gap
between the lab fixture and the demo experience. *Phase:* **LF Fixtures** + **LR**.
*Guard:* point at least one Playwright matrix run at `reference/demo_app` realistic data (the demo
hot-reload DX already supports this); add a demo-data visual cell to the matrix.

**B-C5: States that only work with perfect seed data.**
*Warning sign:* layouts break on empty/one/many/long-ID/non-ASCII/null/high-count/error — the real
world. *Prevention:* the **multi-tenant fixture cohort + stress fixtures** (no-data/one/many/long/
non-ASCII/high-count/null/error/boundary) are first-class; every usability assertion above runs
against them. The "No tenant selected" dead-end and single-tenant pointless picker are the canonical
failures this kills. *Phase:* **LF Fixtures** (cohort) feeding **LR**.
*Guard:* parameterize the structural/contrast/overflow tests across the fixture cohort (loop over
no-data/one/many/long-ID/non-ASCII tenants); assert no overflow/clip/empty-bug in any combination
(ties to A6, A10, A19, A24).

**B-C6: Idempotent re-run drift / silent baseline erosion.**
*Warning sign:* the meet-or-beat baseline is quietly lowered to make a run pass; GAP rows deleted
instead of `downgraded`. *Prevention:* keep v1.11's stable-ID, never-renumber, never-delete contract
(`RATCHET-GAP-REGISTER.md`); a regression **reopens** its row; baseline scores only ratchet upward.
*Phase:* **LR**. *Guard:* CI asserts no GAP row was deleted/renumbered vs `git` history; baseline
file diff must be additive or improving (a lowered score fails the gate).

---

## "Looks Done But Isn't" Checklist (v1.13)

- [ ] **Theme picker:** has **System** option AND System is default AND no FOUC under system→dark — verify A17/B-T1.
- [ ] **Every overlay:** panel above scrim, focus trapped, Escape closes, focus restored to trigger — verify A1/B-A1..3.
- [ ] **Every stat card / badge / table cell:** identical across all 3 surfaces — verify A12/B-C3.
- [ ] **Every disabled control:** visibly disabled + `aria-disabled`; every enabled control reads enabled — verify A13.
- [ ] **Every empty/all-clear state:** descriptive microcopy, never a bare `—`/`___`; pagination absent when ≤1 page — verify A19/A24.
- [ ] **Every data table:** justified as tabular, readable at 320px (or intentional scroll), not overusing tables — verify A10/A11.
- [ ] **Dark + System parity:** all contrast cells AA in light/dark/system at 320/390/768/1440 — verify A16/B-T1.
- [ ] **Stress fixtures:** every state survives no-data/one/many/long-ID/non-ASCII/null/high-count/error — verify B-C5.
- [ ] **Real demo:** the rich `demo_app` (not just seeded host_app) passes the matrix — verify B-C4.
- [ ] **Host safety:** no global CSS leak, scoped stacking context, host theme/hooks untouched — verify B-H1..4.

## Pitfall-to-Fractal-Level Mapping (summary)

| Level | Owns these pitfalls | Headline guard delta |
|-------|---------------------|----------------------|
| **L0 Foundations** | A1,A2,A4,A5,A7,A8(part),A14,A23,B-M1,B-M5,B-T1,B-H1,B-H2 | Z-GATE, SCOPE-GATE, focus-token contrast, scoped `isolation` |
| **L1 Primitives** | A3,A8,A12,A13,A15,A20,B-A4,B-A5,B-M3 | STATCARD-GATE, icon-SVG-exists grep, disabled/enabled structural test |
| **L2 Forms** | A13,B-A5 | enabled/disabled contrast + affordance test |
| **L3 App-Shell** | A4,A17,A18,A23,B-T1,B-T2,B-T3,B-H3,B-H4 | 3-way theme picker test, tab active-state non-color test |
| **L4 Data-Display** | A6,A9(part),A10,A11,A19,A21,A22,A24,B-A1..3 | overflow/clip test, tables-vs-cards justification, focus-restore |
| **L5 Component-Groups** | A5,A9 | box-in-box depth ≤2 structural test, alignment x/y test |
| **L6 Pages/Flows** | A14(patch focus),A24,B-A9 | post-patch focus, least-surprise JTBD flows |
| **LF Fixtures** | B-C5, feeds A6/A10/A19/A24 | multi-tenant cohort + stress fixtures parameterizing the matrix |
| **LR Ratchet** | A11,A16,A21,B-M2,B-C1..6 | interaction pillar in matrix, demo_app run, non-erodable baseline |

## Sources

- `.planning/PROJECT.md` (v1.13 target features + scope locks + usability-bug list)
- `.planning/research/v1.11/MOTION.md`, `DARK-MODE.md`, `COMPONENT-STATES.md`, `IA.md`, `MICROCOPY.md` (extended, not redone)
- `.planning/RATCHET-GAP-REGISTER.md`, `mailglass_admin/e2e/structural.spec.js`, `mailglass_admin/scripts/check-conformance.sh`, `scripts/check_motion_conformance.sh` (existing guards; deltas proposed)
- Codebase grep: `mailglass_admin/lib/mailglass_admin/operator/shell.ex` (binary theme_toggle), `operator_live.ex` (`toggle_theme`/`dark_chrome` URL-param theme), `replay_modal.ex` (literal `z-40`, no z-token), `layouts/root.html.heex` (server `data-theme`) — confirms A1/A17/B-T1/B-T3
- [W3C WAI-ARIA APG — Dialog (Modal) Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) — focus trap, focus restore to trigger, Escape, initial focus
- [W3C WAI — What's New in WCAG 2.2](https://www.w3.org/WAI/standards-guidelines/wcag/new-in-22/) and [Deque — WCAG 2.2](https://dequeuniversity.com/resources/wcag-2.2/) — 2.5.8 Target Size (24px), 2.4.11 Focus Not Obscured, 2.4.13 Focus Appearance
- [Emil Kowalski — Good vs Great Animations](https://emilkowal.ski/ui/good-vs-great-animations) and [7 Practical Animation Tips](https://emilkowal.ski/ui/7-practical-animation-tips) — origin-aware, scale(0) anti-pattern, tooltip delay-then-instant
- [Aleksandr Hovhannisyan — The Perfect Theme Switch](https://www.aleksandrhovhannisyan.com/blog/the-perfect-theme-switch/) and [CSS-Tricks — Flash of inAccurate coloR Theme](https://css-tricks.com/flash-of-inaccurate-color-theme-fart/) — FOUC prevention, system-vs-explicit persistence
- GOV.UK Design System discipline (tables-vs-cards, honest pagination, least-surprise IA) — convergent with v1.11 IA.md

---
*Pitfalls research for: mailglass_admin v1.13 design-system stress-test & UX uplift*
*Researched: 2026-06-18*
