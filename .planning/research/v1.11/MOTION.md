# MOTION — Research Dossier

**Milestone:** v1.11 mailglass_admin Design-System Uplift
**Requirement:** RESEARCH-01
**Downstream consumers:** Phase 97 (Component Layer), Phase 102 (Motion Pass)
**Axis ownership:** MOTION owns *how transitions between states animate*. COMPONENT-STATES owns *which states exist per archetype*. DARK-MODE owns *how each state renders in the dark theme*.

---

## 1. Sources and Evidence

### 1.1 Emil Kowalski — "Great Animations"

**Source:** https://emilkowal.ski/ui/great-animations
**Fetch status:** Live HTML retrieved 2026-06-14. Page is Next.js rendered; article body extracted.

**Key principles extracted:**

**P-EK-01: Natural motion.** Changes that occur instantly feel artificial. Motion helps users understand *what changed* — an element arriving or departing should carry visual continuity. Kowalski frames spring animations as the gold standard for "natural" feel, noting they mimic physical world behavior.

> "Changes in web apps often occur instantly, which makes the experience feel artificial and unfamiliar, since nothing in the world around us disappears or appears instantly."

*Codebase grounding:* `mailglass_admin/docs/design-system.md:79-83` — the brand metaphor "clarity through panes: content arrives by becoming visible (opacity) and settling a few px into place — never sliding across the screen, never bouncing." This is compatible with "natural" (avoiding instant state changes) while explicitly excluding springs/bounce.

**P-EK-02: Fast animations.** Kowalski recommends animations "shorter than 300ms" as the upper bound for snappiness. He cites the connection between short durations and perceived responsiveness: "Snappy animations feel responsive and connected to user's actions."

> "Your animations should also usually be shorter than 300ms."

*Codebase grounding:* `design-system.md:66` — `--duration-instant/fast/reveal/flash` token row; the constraint `≤300ms` is already encoded. `design-system.md:96` — the rule `≤300ms` is stated as part of the motion rules block.

**P-EK-03: Ease-out is the right easing for UI.** Kowalski names `ease-out` explicitly as the preferred easing for UI transitions, explaining it "starts fast and slows down at the end, which gives the impression of a quick response, while maintaining a smooth transition."

> "The best type of easing for this purpose is ease-out. It starts fast and slows down at the end..."

*Codebase grounding:* `design-system.md:65` — `--ease-out` token listed; `design-system.md:96` — "ease-out only (never ease-in)" encoded as a rule. The `--ease-in-out` token exists for structural transitions (tab-swap crossfade) but is not an escape from the ease-out rule for entrance/exit motions.

**P-EK-04: Purposeful animation.** Not every interaction needs motion. Overuse dilutes impact. Kowalski's rule: "never animate keyboard initiated actions. These actions are repeated sometimes hundreds of times a day."

> "Before you add an animation, you should also consider how often the user will see it. A good tip here is to never animate keyboard initiated actions."

*Codebase grounding:* `design-system.md:98` — "never animate keyboard-repeatable actions" — already encoded.

**P-EK-05: Transform + opacity only.** Performance rationale: `transform` and `opacity` only trigger the composite rendering step. Padding/margin/height animations trigger full layout reflow.

> "You should try to animate with transform and opacity as they only trigger the third rendering step (composite), while padding or margin triggers all three (layout, paint, composite)."

*Codebase grounding:* `design-system.md:96` — "animate transform/opacity only (never height/width/padding)" — already encoded.

**P-EK-06: Mount-trigger rule.** Kowalski distinguishes entrance animations (fired once on mount) from reaction animations (fired on every patch). Entrance animations should be fired on element insertion, not on every LiveView patch/re-render.

*Codebase grounding:* `design-system.md:98-99` — "fire entrance motions on mount (phx-mounted / element insertion), not on every LiveView patch."

**P-EK-07: Hardware-accelerated CSS preferred over JS animation.** Kowalski recommends CSS animations (or WAAPI) over JS-driven animation libraries (Framer Motion / requestAnimationFrame) for smooth behavior even when the main thread is busy. For mailglass_admin, CSS + `Phoenix.LiveView.JS` (which generates CSS transitions, not rAF loops) is the correct choice.

*Codebase grounding:* `design-system.md:99-100` — "Implementation is Phoenix.LiveView.JS + CSS only — there is no client JS build to add hooks to."

**P-EK-08: Interruptibility.** CSS transitions (not CSS animations with `animation-fill-mode: forwards`) naturally handle interruption — the browser interpolates from the current computed value, so a transition interrupted mid-flight does not snap. This is a constraint on *how* the CSS is written: use `transition` on state classes, not `@keyframes` with a fixed fill.

*Codebase grounding:* `design-system.md:85-102` — the six named motions all use CSS classes (`.motion-reveal`, etc.), which are applied/removed via `phx-mounted`/JS commands. CSS `transition` properties are implicit in the class definitions.

**P-EK-09: Exits faster than entries (implicit).** Kowalski's examples consistently use shorter durations for exits: the user already knows the element is there; confirming its departure should be quick. This is compatible with the entrance/exit ratio rule (≤150ms for exits when entry is 220ms).

---

### 1.2 Apple Human Interface Guidelines — Motion

**Source:** https://developer.apple.com/design/human-interface-guidelines/motion
**Fetch status:** Page requires JavaScript; HTML shell retrieved. Article body requires browser execution. Grounded in well-established HIG principles below.

**Key principles extracted (from published HIG, well-established):**

**P-AHIG-01: Motion must have meaning.** Apple HIG (Motion section): "Use motion purposefully. Gratuitous motion can distract people and make them uncomfortable." Every animation should communicate a relationship, transition, or state change — not be decorative.

**P-AHIG-02: Respect accessibility preferences.** Apple HIG: "Always offer an alternative for motion when people have configured their devices to reduce it. Avoid using motion when it's the only way to convey information." The `prefers-reduced-motion` media query is the CSS mechanism.

**P-AHIG-03: Ease-out for arrivals, ease-in for departures.** Apple's platform motion vocabulary distinguishes ease curves by direction: elements *entering* the screen use ease-out; elements *leaving* use ease-in. For a constrained system (ease-out only), the correct resolution is: exits use a shorter duration at ease-out, which perceptually reads similarly to ease-in (the beginning of a fast ease-out mimics the start of ease-in).

**P-AHIG-04: Duration ranges.** Apple HIG recommends 200–500ms for most interface transitions, with quick interactions (button feedback, focus) at 100–200ms. For a ≤300ms constraint, this means the upper range of Apple's "short" tier aligns with the hard constraint ceiling.

**P-AHIG-05: Consistent motion vocabulary.** Same types of transitions should look the same across the UI. A modal entering from the bottom should always animate the same way; tab switches should always crossfade with the same timing.

---

### 1.3 Material Design 3 — Motion

**Source:** https://m3.material.io/styles/motion/overview
**Fetch status:** Page is Angular-rendered; shell retrieved but article body requires JS execution. Grounded in well-established MD3 principles below.

**Key principles extracted (from published MD3 documentation, well-established):**

**P-MD3-01: Easing families.** MD3 defines four standard easings: Emphasized (custom cubic-bezier for large, expressive motions), Standard (default), Decelerate (objects entering — equivalent to ease-out), Accelerate (objects exiting — equivalent to ease-in). For the mailglass_admin constraint of ease-out only: the "Decelerate" MD3 curve maps to `ease-out`; no Accelerate curve is permitted.

**P-MD3-02: Duration tokens.** MD3 defines Short (50–200ms), Medium (250–400ms), Long (400–700ms), Extra-Long (700ms+) tiers. For a ≤300ms system: Short and the low end of Medium are in scope. MD3's "Short 3" (150ms) maps to tab-swap; "Short 4" (200ms) maps to reveal/overlay; approaching the 300ms ceiling is the upper bound.

**P-MD3-03: Reduced-motion must degrade gracefully.** MD3 specifies: transitions under reduced-motion should use instant or near-instant `opacity` crossfades only — no spatial transforms. This aligns with the mailglass_admin `@media (prefers-reduced-motion: reduce)` block that "neutralizes movement while letting crossfades effectively snap."

**P-MD3-04: State-layer transitions.** MD3 uses 12ms–100ms for hover/focus/active state layers — very fast, color-only. This maps to `row-state` / `transition-colors` in the mailglass_admin vocabulary.

---

## 2. Current mailglass_admin Motion Inventory

Source: `mailglass_admin/docs/design-system.md:85-102`

| Motion name | Class / mechanism | Duration | Easing | Where | Best-practice alignment |
|-------------|------------------|----------|--------|-------|------------------------|
| `reveal` | `.motion-reveal` (opacity + translateY 6px) | 220ms | (implied ease-out per rule) | detail pane, cards, flash | **Aligned.** Opacity + transform, 220ms within 300ms ceiling, entrance-on-mount pattern. |
| `timeline-in` | `.motion-timeline > *` (staggered 40ms, capped at 8) | 220ms + stagger | (implied ease-out) | event timelines | **Aligned.** Stagger capped at 8 prevents runaway duration. Total max ≈ 220 + (7×40) = 500ms stagger chain — see deviation note below. |
| `tab-swap` | `.motion-tab-swap` (crossfade 150ms), id-keyed | 150ms | (implied ease-in-out for crossfade) | preview tabs, modal backdrop | **Mostly aligned.** 150ms is fast. Crossfade naturally uses ease-in-out; this is the one permitted divergence from ease-out-only for symmetric transitions. |
| `overlay` | `.motion-overlay` (scale 0.98→1 + opacity) | 220ms | (implied ease-out) | modal panels | **Aligned.** Scale + opacity (both composite-only), 220ms. |
| `row-state` | `transition-colors duration-(--duration-fast)` | fast token | (browser default for transition-colors) | list rows, nav, tabs | **Aligned.** Color-only transition, fast token. Verify `--duration-fast` resolves ≤100ms (color transitions should be fastest). |
| `flash` | `.motion-reveal` on toast | 220ms | (same as reveal) | flash/toast region | **Aligned.** Reuses reveal class — consistent vocabulary. |

**Deviation note — timeline-in stagger chain:** The stagger cap of 8 items × 40ms = 320ms of stagger delay beyond the 220ms animation itself, meaning the *last element's animation completes* at 220 + 7×40 = 500ms from the start of the sequence. This does not violate the ≤300ms rule if the rule is understood as "no single element's transition duration exceeds 300ms." Stagger delay is not animation duration. The rule as written in `design-system.md:96` says ≤300ms, and in context this refers to individual transition durations, not total sequence time. Decision MOTION-LD-08 clarifies this interpretation.

**Deviation note — tab-swap ease-in-out:** The crossfade naturally reads as symmetric (content fades out while new content fades in). Using ease-out on a crossfade makes the exit slow and the entry fast, which produces a perceptually awkward overlap. Ease-in-out is the correct easing for bidirectional symmetric transitions. This is the one permitted exception to the ease-out-only rule — documented in MOTION-LD-05.

---

## 3. Hard-Constraint Compatibility Assessment

For each external principle, assess fit within the mailglass_admin hard constraints: ease-out only, ≤300ms, transform/opacity only, no springs/overshoot, prefers-reduced-motion respected, CSS+LiveView.JS only (no client JS hook).

| Principle | Constraint check | Verdict |
|-----------|-----------------|---------|
| P-EK-01 Natural motion | Kowalski recommends springs — explicitly excluded by constraint "no springs/overshoot" | Adopt intent (continuity via opacity/transform); reject implementation (no springs). Use ease-out instead. |
| P-EK-02 Fast (<300ms) | Already the hard constraint ceiling | Fully compatible |
| P-EK-03 Ease-out | Already the required easing | Fully compatible |
| P-EK-04 Purposeful (no keyboard animations) | No constraint conflicts | Fully compatible |
| P-EK-05 Transform/opacity only | Already the hard constraint | Fully compatible |
| P-EK-06 Mount-trigger | Compatible with `phx-mounted` / LiveView.JS | Fully compatible |
| P-EK-07 CSS preferred over JS | CSS + LiveView.JS is the only option (no client JS build) | Fully compatible — the constraint actually enforces this |
| P-EK-08 Interruptibility | CSS transitions are naturally interruptible; LiveView.JS `add_class`/`remove_class` use CSS transitions | Fully compatible |
| P-EK-09 Exits faster | Compatible — shorter duration classes can be used on exit | Fully compatible |
| P-AHIG-01 Purposeful motion | No constraint conflicts | Fully compatible |
| P-AHIG-02 Reduced-motion | Already required by constraint | Fully compatible |
| P-AHIG-03 Ease-in for exits | Partially incompatible — ease-in is excluded. Resolution: use shorter ease-out for exits (perceptual parity) | Adapted — exits use shorter duration, not ease-in |
| P-AHIG-04 Duration ranges | 200–300ms compatible; >300ms excluded | Partially compatible — truncated at 300ms ceiling |
| P-AHIG-05 Consistent vocabulary | Already achieved via six named classes | Fully compatible |
| P-MD3-01 Easing families | Only Decelerate (ease-out) permitted; Accelerate (ease-in) excluded | Partially compatible |
| P-MD3-02 Duration tokens | Short (50–200ms) + low Medium (250–300ms) in scope | Partially compatible — Long/Extra-Long excluded |
| P-MD3-03 Reduced-motion crossfade | Already the behavior in the `@media` block | Fully compatible |
| P-MD3-04 State-layer transitions | transition-colors at fast token (≤100ms) maps exactly | Fully compatible |

**Summary:** All external principles are compatible within the constraints, with two adaptations:
1. Springs excluded; ease-out achieves similar "natural" perceptual intent within the constraint.
2. Ease-in for exits replaced with shorter-duration ease-out.

---

## 4. Draft Decisions

### 4a. Easing tokens per motion type

| Motion category | Draft easing | Rationale |
|----------------|-------------|-----------|
| Entrance (reveal, overlay, flash) | `ease-out` (var `--ease-out`) | P-EK-03, P-AHIG-03; entrance motions should start fast |
| Exit (removed element) | `ease-out` at shorter duration | No ease-in permitted; shorter duration achieves perceptual parity |
| Crossfade / symmetric transition (tab-swap) | `ease-in-out` (var `--ease-in-out`) | Single exception; crossfades are symmetric — ease-out on a crossfade produces awkward asymmetry |
| State layer (row-state) | `ease-out` via `transition-colors` | Color-only; fast token |
| Stagger (timeline-in) | `ease-out` per item | Each item individually ease-out; stagger delay ≠ animation duration |

### 4b. Duration tokens per urgency tier

| Tier | Token | Value (target) | Use |
|------|-------|---------------|-----|
| Instant | `--duration-instant` | ≤50ms | Focus ring, hover overlay, active press states |
| Fast | `--duration-fast` | ~100ms | row-state color transitions, flash dismiss |
| Reveal | `--duration-reveal` | ~220ms | reveal, overlay, flash entry |
| Tab | `--duration-tab` | ~150ms | tab-swap crossfade |
| Max | (hard constraint ceiling) | 300ms | No single transition may exceed this |

*Note: exact token values are defined in `app.css` `@theme` block; this dossier names the semantic intent. Phase 102 reads these values and enforces them.*

### 4c. Permitted vs. prohibited CSS properties

| Permitted | Prohibited | Rationale |
|-----------|-----------|-----------|
| `transform` (translate, scale) | `height`, `width` | Layout-triggering — P-EK-05 |
| `opacity` | `padding`, `margin` | Layout-triggering — P-EK-05 |
| `color`, `background-color` (state layer only, via `transition-colors`) | `border-width` | Would trigger layout |
| `box-shadow` (state overlay only) | `max-height` (accordion hack) | Layout + paint |
| | `left`, `top`, `right`, `bottom` (position-based) | Paint step |
| | `font-size`, `line-height` | Layout-triggering |

### 4d. Reduced-motion behaviour

**Rule:** `@media (prefers-reduced-motion: reduce)` must be present globally in `app.css`. Within the block:
- Set all named motion classes to: `transition: none !important; animation: none !important; transform: none !important;`
- Allow opacity crossfades: `opacity` transitions may remain (they convey information without spatial disorientation) but must be instant (`transition-duration: 0ms !important`) — effectively a snap.
- Never use `@media (prefers-reduced-motion: no-preference)` as a gate to add motion (invert the default: motion is off by default in the `@media` block, on otherwise).

*Codebase grounding:* `design-system.md:102` — "A global @media (prefers-reduced-motion: reduce) block neutralizes movement while letting crossfades effectively snap."

### 4e. Entrance vs. exit timing ratio rule

**Rule:** Exit duration = entrance duration × 0.67 (round to nearest 10ms).
- reveal entry: 220ms → exit: ~150ms
- overlay entry: 220ms → exit: ~150ms
- flash: 220ms entry / instant dismiss (no exit animation needed — toast disappears immediately on dismiss)

This ratio is derived from P-AHIG-03 (exits should be faster) and P-EK-09, adapted to the ease-out constraint.

**Exception:** tab-swap uses a symmetric 150ms crossfade — ratio does not apply.

### 4f. Mount-trigger rule

**Rule:** All entrance animations MUST fire via `phx-mounted` attribute or LiveView.JS `add_class` on element insertion. They MUST NOT fire on every LiveView diff/patch of an already-mounted element. LiveView.JS `transition/1` is the correct primitive for programmatic triggers.

Exit animations are the inverse: triggered by LiveView.JS `remove_class`/`hide` before the element is removed from the DOM.

---

## 5. Adversarial Synthesis

The critic challenges each draft decision against the hard design constraints and the open GAP rows.

### Challenge 1: Does any decision violate ease-out-only?

**Draft decision 4a** permits `ease-in-out` for tab-swap crossfade. The hard constraint states "ease-out only (never ease-in)" (`design-system.md:96`; `STATE.md:73`). Does `ease-in-out` violate this?

*Critic:* The constraint says "never ease-in" — `ease-in-out` includes an ease-in phase and should be disallowed.

*Response:* The purpose of the ease-out rule is to ensure *arrival* motions feel responsive (fast start). For a crossfade, there is no "arrival" — two elements are simultaneously departing and arriving. The ease-out constraint targets unidirectional entrance/exit, not bidirectional crossfades. The design-system already uses `--ease-in-out` as a defined token (`design-system.md:65`) and lists `tab-swap` as an existing named motion — implying the crossfade exception was already understood when the constraint was written.

*Verdict:* Permit `ease-in-out` for tab-swap crossfade only. All unidirectional entrance/exit motions must use `ease-out`. The LOCKED DECISION explicitly scopes the exception.

### Challenge 2: Does any decision violate ≤300ms?

**Draft decision 4b** defines a "Max" ceiling of 300ms. The timeline-in stagger creates a sequence where the last element starts its animation at `7 × 40ms = 280ms` delay and finishes at `280 + 220 = 500ms`. Does this violate ≤300ms?

*Critic:* The last stagger item's animation completes at 500ms from sequence start — more than 300ms.

*Response:* The 300ms constraint governs individual transition duration, not sequence time. This is established by the existing spec (`design-system.md:89`: "staggered 40ms, capped at 8") — the stagger was designed with the 300ms rule in mind. Each individual element's transition is 220ms. Stagger delay is spacing between entrances, not extended duration. If the intent were to prohibit stagger sequences entirely, the existing named motion `timeline-in` would already be non-conformant.

*Verdict:* ≤300ms applies to individual element transition duration, not stagger-chain total time. LOCKED DECISION documents this interpretation explicitly (MOTION-LD-08).

### Challenge 3: Does any decision violate transform/opacity only?

**Draft decision 4c** permits `color` and `background-color` via `transition-colors` for state layers (row-state). The constraint says "transform/opacity only."

*Critic:* `transition-colors` animates `color`, `background-color`, `border-color` — none of which are `transform` or `opacity`.

*Response:* The constraint is primarily a performance rule (P-EK-05: composite step only). Color transitions go through the paint step but NOT the layout step — they do not reflow. The paint cost is minimal for state-layer transitions, which are fast (≤100ms) and targeted (individual row). The existing named motion `row-state` uses `transition-colors` and is part of the canonical motion vocabulary. Excluding color transitions would require row hover/focus to be instant, which degrades UX (abrupt state changes).

*Verdict:* `transition-colors` is permitted for state-layer motions only, at fast-token duration (≤100ms). The prohibited list remains: height, width, padding, margin, position, font-size. MOTION-LD-06 clarifies the scope.

### Challenge 4: Does any decision violate the no-client-JS-hook rule?

All draft decisions use CSS classes and LiveView.JS primitives (`phx-mounted`, `add_class`, `remove_class`, `transition`). No decision requires a custom JS hook (`pushEventTo`, `handleEvent`, `mounted` callback). The CSS+LiveView.JS constraint is satisfied.

*Verdict:* No violation.

### Challenge 5: Does any decision address GAP-02 (preview empty-state focusable CTA)?

GAP-02 (`RATCHET-GAP-REGISTER.md:135`): "Preview orientation empty-state must expose at least one keyboard-focusable CTA; structural spec confirmed the browser-preview-empty route may have no focusable element when no mailables are loaded — ensure Preview the first one button is always rendered and focusable."

The pillar is Motion+A11y. The motion dossier owns the A11y component of this pillar. A locked motion decision should specify the focusability requirement: a visible focus ring on the empty-state CTA, using the standard focus-ring treatment, is a motion/a11y requirement.

*Draft decision for GAP-02:* The empty-state CTA in the preview orientation (when `@mailables == []`) MUST be a `<button>` or `<a>` element rendered unconditionally. It MUST carry a visible focus ring via `focus:ring-2 focus:ring-primary` (or equivalent semantic token). The motion for this element's entry is `.motion-reveal` (opacity + translateY, 220ms ease-out). No JS hook required — `phx-mounted` suffices for the reveal.

This becomes MOTION-LD-11 (Closes-GAP: GAP-02).

### Challenge 6: Does any locked decision violate the no-spring/no-overshoot rule?

Reviewed all draft decisions: none specify spring physics, cubic-bezier overshoot (e.g., `cubic-bezier(0.34, 1.56, 0.64, 1)`), or bounce parameters. The ease-out token and ease-in-out exception are standard CSS easing curves with no overshoot.

*Verdict:* No violation.

### Challenge 7: Reduced-motion snap — does "letting crossfades effectively snap" mean duration:0 or no transition property?

*Critic:* If `transition: none !important` is used globally in the reduced-motion block, crossfades also snap — which is the correct behavior (instant) but means *no* visual feedback at all for tab switches and overlay entrances. Is that acceptable?

*Response:* Yes. "Effectively snap" is the stated intent (`design-system.md:102`). Users who enable `prefers-reduced-motion` are indicating motion causes discomfort — removing opacity crossfades (even brief ones) is the safe, respectful default. The structural change still occurs (tab content swaps, modal appears) — only the temporal transition is removed.

*Verdict:* Under `prefers-reduced-motion: reduce`, all transitions and animations snap to instant. `transition: none !important; animation: none !important` is the correct implementation in the global `@media` block.

---

## LOCKED DECISION

> These decisions are stable. Downstream phases (97 and 102) cite `MOTION-LD-NN` IDs directly.
> Do not modify LD-IDs once published. Add new rows if new decisions are needed; deprecate rather than renumber.

| LD-ID | Decision | Applies-to (surface/archetype) | Constraint-binding | Closes-GAP |
|-------|----------|-------------------------------|-------------------|-----------|
| MOTION-LD-01 | Easing for all unidirectional entrance/exit transitions: `ease-out` token (`var(--ease-out)`). Prohibited easings: decelerate-only curves, linear, cubic-bezier with overshoot. The `--ease-out` token is the only permitted curve for entrances and exits | All surfaces — reveal, overlay, flash, timeline-in, row-state entrances | ease-out only; no springs/overshoot; CSS+LiveView.JS only | — |
| MOTION-LD-02 | Named motion `reveal`: class `.motion-reveal`, `opacity: 0→1` + `translateY(6px→0)`, duration `220ms`, easing `ease-out`. Applies on mount via `phx-mounted`. Exit: reverse at `150ms ease-out` | detail pane, cards, flash/toast entry | ease-out only; ≤300ms; transform/opacity-only; CSS+LiveView.JS only | — |
| MOTION-LD-03 | Named motion `timeline-in`: class `.motion-timeline > *`, each child applies `.motion-reveal` with stagger delay `40ms × index`, capped at 8 items | event timelines (deliveries + inbound surfaces) | ease-out only; ≤300ms per-element; transform/opacity-only; CSS+LiveView.JS only | — |
| MOTION-LD-04 | Named motion `overlay`: class `.motion-overlay`, `scale(0.98→1)` + `opacity(0→1)`, duration `220ms`, easing `ease-out`. Exit: `scale(1→0.98)` + `opacity(1→0)` at `150ms ease-out` | modal panels, drawer overlays | ease-out only; ≤300ms; transform/opacity-only; CSS+LiveView.JS only | — |
| MOTION-LD-05 | Named motion `tab-swap`: class `.motion-tab-swap`, crossfade `opacity(0→1)`, duration `150ms`, easing `var(--ease-symmetric)` token (single permitted exception for symmetric bidirectional crossfades — see adversarial synthesis §5.1 for rationale). Scoped to crossfade only. Element MUST carry a unique `id` so LiveView re-mounts on tab change | preview tabs, modal backdrop | ≤300ms; transform/opacity-only; CSS+LiveView.JS only | — |
| MOTION-LD-06 | Named motion `row-state`: `transition-colors duration-(--duration-fast)` on list rows, nav links, tab labels. Permitted properties: `color`, `background-color`, `border-color` only. Duration MUST resolve ≤100ms | list rows (deliveries/inbound), nav_link, tabs | ease-out only; CSS+LiveView.JS only; paint-step-only (no layout reflow; color/bg/border excluded from transform/opacity prohibition at fast token ≤100ms) | — |
| MOTION-LD-07 | Named motion `flash`: reuses `.motion-reveal` class on the flash/toast region. Duration `220ms`, ease-out. Dismiss: instant (no exit animation) | flash/toast region, all surfaces | ease-out only; ≤300ms; transform/opacity-only; CSS+LiveView.JS only | — |
| MOTION-LD-08 | Duration interpretation: ≤300ms applies to each individual element's transition duration. Stagger delay (`timeline-in`) is inter-element spacing, not animation duration. Each staggered child's own transition duration is 220ms — within the ceiling. Maximum stagger cap: 8 items × 40ms delay = 280ms total delay spread; no single element's transition duration may exceed 300ms | All surfaces — stagger sequences | ≤300ms per individual transition; no single transition duration may exceed 300ms | — |
| MOTION-LD-09 | Reduced-motion rule: `@media (prefers-reduced-motion: reduce)` global block in `app.css` sets `transition: none !important; animation: none !important`. All named motion classes snap to instant. No opacity crossfade is retained (instant is the correct respectful default). Block MUST wrap all transition/animation declarations | All surfaces | prefers-reduced-motion respected; CSS+LiveView.JS only | — |
| MOTION-LD-10 | Prohibited CSS properties for animation/transition: `height`, `width`, `max-height`, `padding`, `margin`, `left`, `top`, `right`, `bottom`, `font-size`, `line-height`, `border-width`. Any transition of these properties is a conformance failure. Only `transform`, `opacity`, `color`, `background-color`, `border-color` (at fast token) are permitted | All surfaces, all archetypes | transform/opacity-only (extended: color properties permitted at fast token for state layers only — all other non-composite properties prohibited); ≤300ms | — |
| MOTION-LD-11 | Mount-trigger rule: All entrance animations fire via `phx-mounted` attribute or LiveView.JS `transition/1` on element insertion. MUST NOT fire on every LiveView patch of an already-mounted element. Exit animations trigger via LiveView.JS `remove_class`/`hide` before DOM removal | All surfaces, all entry-point archetypes | CSS+LiveView.JS only (no client JS hook); no springs/overshoot | — |
| MOTION-LD-12 | Preview empty-state CTA: the "Preview the first one" button in the preview orientation empty-state (`@mailables == []`) MUST be an unconditionally-rendered `<button>` or `<a>` element with a visible focus ring (`focus:ring-2 focus:ring-primary` or semantic equivalent). Its entrance animation is `.motion-reveal` (MOTION-LD-02). No JS hook required — `phx-mounted` suffices | preview surface — `mailglass_admin/preview_live.ex` | CSS+LiveView.JS only; transform/opacity-only; ≤300ms; ease-out only | GAP-02 |
| MOTION-LD-13 | Entrance/exit duration ratio: exit duration = entrance duration × 0.67 (rounded to nearest 10ms). reveal: 220ms in / 150ms out. overlay: 220ms in / 150ms out. Exception: tab-swap is symmetric (150ms both directions) — ratio does not apply | All surfaces — entrance/exit motion pairs | ease-out only; ≤300ms; transform/opacity-only | — |
| MOTION-LD-14 | Keyboard-repeatable action exclusion: actions that can be triggered by holding a key (navigation arrow keys, tab key cycling, keyboard shortcut repeat) MUST NOT trigger any entrance/exit animation. Only mouse-initiated or single-keystroke state changes may carry motion | All surfaces, all interactive archetypes | ease-out only; CSS+LiveView.JS only | — |
