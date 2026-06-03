# UI/UX & IA Pattern Research — mailglass_admin Polish v2

**Domain:** Operator/forensic admin dashboard — transactional email delivery & inbound observability
**Milestone:** v1.7 Admin UI — IA & Design-System Polish v2 (phases 74–79)
**Researched:** 2026-06-03
**Confidence:** HIGH (design-system tokens/motion/brand locked in existing sources; HIGH on operator IA and status taxonomy from Carbon/PatternFly/Vercel primary sources; MEDIUM on motion specifics from emilkowal.ski direct; MEDIUM on empty-state patterns from Vercel Geist direct)

---

## Executive Context

This research answers five concrete questions for the Phase-74 UI-SPEC author and roadmapper:
1. How do best-in-class operator/forensic dashboards structure their landing so a cold, time-pressured user knows "what do I do"?
2. What is the canonical status→color taxonomy for delivery/event/inbound states (to replace three disagreeing private copies)?
3. How do you turn a flat 2×2 card grid into a primary/secondary hierarchy?
4. What does a complete state inventory look like for empty/error/loading, and how does "joy + orientation" appear without noise?
5. What motion principles produce "pop/joy" within a restrained 6-motion vocabulary?

All recommendations are constrained by the locked brand book: flat (no shadows beyond `shadow-overlay`), Glass accent ≤ 10%, type weights 400/700 only, motion ease-out ≤ 300ms transform+opacity only.

---

## Feature Landscape

### Table Stakes (Operators Expect These — Missing = Feels Incomplete)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Symptom-first orientation on every mount root | Operators arrive time-pressured; if the default landing doesn't answer "is everything OK?" in one scan they distrust the tool | LOW | Already exists on Deliveries; missing on Inbound and Preview. Generalizing `orientation_strip` is the minimum. |
| Consistent status-badge color taxonomy | Operators read color as forensic signal. Three disagreeing copies means the same state reads differently on different screens — trust-destroying | MEDIUM | One unified atom in `components.ex` routing all three call sites. |
| Primary/secondary card hierarchy | A flat 2×2 grid of co-equal cards gives no triage signal. Zero-count cards consume identical visual weight as actionable ones | MEDIUM | Non-zero/actionable states prominent; zero-states demoted to compact summary row. See §Hierarchy Patterns. |
| Non-empty states for every screen | Each screen must have a reachable, legible path for: loading, empty-filtered, blank-slate (no data), error-load, and cleared/success. Missing any = UI feels broken | MEDIUM | Phase 4 seed expansion + Phase 0 state inventory unlock this. |
| Reduced-motion compliance | Users with vestibular disorders rely on `prefers-reduced-motion`. A broken reduced-motion path is an accessibility regression | LOW | `@media (prefers-reduced-motion: reduce)` neutralizes movement; crossfades snap. Already in design-system.md spec, not yet fully applied. |
| Orientation strip on Inbound surface | Inbound operators have the same incident mindset as Outbound operators. Parity is expected. | LOW | Direct extension of existing `orientation_strip/1` component. |
| Token-conformant spacing and type on all components | Operators notice when `support_cards.ex` uses raw `text-sm/base` while the rest of the UI uses `text-body/label`. Off-grid gaps make the UI feel unfinished | MEDIUM | `support_cards.ex` + operator/inbound render bodies need migration. |

### Differentiators (Not Expected, but Produce "Insane Polish")

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Operator Overview landing inside the library (Fork A) | A cold operator landing on `/ops/mail/` gets a single screen answering "orphan backlog / recent failures / suppression count" without needing to navigate first. No other Phoenix email lib ships this. | MEDIUM | New route at operator-mount index. At-a-glance health cards: orphan backlog (unmatched inbound), recent outbound failures, suppression count. Routes to Deliveries/Inbound. |
| Expressive seed data covering every screen state | A demo that exercises every badge color, every support-card branch, every empty/error state makes the library self-documenting. Competitors (Postmark, SendGrid) show only happy-path screenshots. | MEDIUM | Phase 4: 6→all delivery statuses, accept/no_match/reject/bounce/ignore inbound outcomes, orphan-backlog row, empty-tenant, long-text truncation stress. |
| Motion as confirmation — subtle entrance/row-state changes that "feel inevitable" | When a delivery detail pane appears with a `reveal` animation, operators register the system responded. When a row flashes on state change, it confirms an action landed. This is perceptible confidence, not decoration. | LOW | Applying the existing 6-motion vocabulary consistently. No new primitives needed. |
| Page-title/subtitle IA vocabulary | Deliberate hierarchy: `display` → page name, `heading` → section, `body` → context, `label` → metadata. Operators orient by text shape, not just position. | LOW | Pure token-application work. High ROI per line changed. |
| Orientation strips on all 3 surfaces | Preview, Deliveries, and Inbound all use the same orientation pattern with surface-specific copy. Operators who context-switch between surfaces get the same UX contract everywhere. | LOW | Generalize `orientation_strip/1` out of `operator_live.ex:362` into shell-level. |
| Canonical empty states with direct action copy | Empty states that name the next action ("No deliveries yet. Send your first email.") convert from dead ends into onboarding. Vercel Geist's "Verb + Noun" CTA pattern is the bar. | LOW | Copy + icon + single CTA. Per Vercel Geist pattern; no illustration required. |

### Anti-Features (Explicitly NOT to Build)

| Anti-Feature | Why Requested | Why Problematic | What to Do Instead |
|--------------|---------------|-----------------|--------------------|
| Single global "home" collapsing Preview + Deliveries + Inbound into one dashboard | "Everything in one place" sounds efficient | Collapses the two mental models (build-time vs run-time). Authors don't want suppression counts; operators don't want a mailable list. The mount split is the feature — threading it undoes the IA | Keep Author/Operator deliberately unthreaded. The cross-mount Northstar Ops home lives in the demo app only, not the library. |
| Glassmorphism, frosted-glass effects, backdrop-blur | "The brand is called Mailglass" | Literally the first anti-pattern in the brand book. Makes the UI feel consumer-SaaS, not infrastructure. Destroys the "well-lit workbench" feeling. | Use the Glass metaphor through color + clarity, never through translucency filters. `border border-base-300` + flat surfaces are the materiality. |
| Decorative motion (entrance animations on static content, loading spinners on fast loads) | "It feels more polished" | Decorative motion trains users to wait. On keyboard-triggered actions, it forces 220ms of lag on every repeat. Disrespects time-pressured operators. Per Emil Kowalski: never animate keyboard-repeatable actions. | Motion only on: state transitions (row-state), content reveals (detail pane open), timeline events (staggered entry), flash confirmation. Instant for everything else. |
| Animated height/width expansion | "Smooth accordion" | Triggers full layout pipeline (reflow). Causes jank on mobile and low-power hardware. Against the existing design-system.md spec. | Animate opacity + translateY only. Use `reveal` for panels that appear/disappear; never `max-height` transitions. |
| Rich SVG illustrations in empty states | "Makes it feel alive and friendly" | Off-brand (illustrations should be "diagrammatic, not whimsical" per brand book). Adds SVG bundle weight. Hard to maintain dark-mode variants. | Icon (from existing icon vocabulary) + `text-heading` copy + one `text-body` description + one primary CTA button. That's the complete empty state. No illustrations. |
| Rainbow/multi-color badge palette | "Shows all the distinct states" | Makes the UI feel like an "analytics casino" (brand book anti-pattern). Operators stop reading color as signal when there are >5 colors in play. | Six semantic colors max: Glass/primary (in-flight), Pine/success (terminal-good), Amber/warning (deferred/soft), Crimson/error (terminal-bad), Ink/neutral (internal/unknown), Slate/muted (void/empty). See §Status Taxonomy below. |
| Folding everything into one mega-overview screen | "Operators want less navigation" | The overwhelm trap. Operators cannot hold a 40-row delivery list + inbound records + suppression list + health stats in one cognitive frame. | Symptom-first summary (4–5 health numbers) → filter + list → selected-record detail → timeline → action. Each step is a screen transition, not a nested accordion. |
| `font-medium` / `font-semibold` (500/600) for hierarchy | "Makes headings stand out more" | The browser synthesizes faux-bold when those weights aren't loaded. Renders as blurry, uneven strokes. The design system explicitly prohibits it (conformance failure). | Use `font-bold` (700) for headings and emphasis. Default weight (400) for body. No intermediate weights. |
| Ad-hoc z-index values | "My modal needs to be on top" | Creates stacking-context chaos across LiveView patches. Hard to reason about and breaks in edge cases. | Use the named z-index tier tokens: sticky (10) / dropdown (20) / overlay (30) / modal (40) / toast (50). |

---

## Pattern Recommendations (Opinionated, Implementation-Ready)

### 1. Operator Dashboard IA — The Cold-Start Contract

**The question an operator arrives with, by surface:**
- `/ops/mail/` (new Operator Overview): "Is anything broken right now? Where do I go?"
- `/ops/mail/deliveries` (Deliveries): "Prove what happened to this specific send / why did it fail?"
- `/ops/mail/inbound` (Inbound): "Why did this inbound message route the way it did?"
- `/dev/mail/` (Preview): "What does this email look like before it ships?"

**The landing answer must come from the default screen itself.** If a user needs to click to answer their arrival question, the IA has failed.

**Operator Overview (Fork A) — recommended structure:**

```
[Orientation strip: "Operator overview. Monitor delivery health and inbound routing."]

[Health summary row — 4 cards, each one number + label + status dot]
  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐
  │ Recent failures │  │ Orphan backlog  │  │ Active           │  │ Suppressions   │
  │ 3               │  │ 1               │  │ suppressions 47  │  │ last 7d  12    │
  │ [Crimson dot]   │  │ [Amber dot]     │  │ [Ink dot]        │  │ [Slate dot]    │
  └─────────────────┘  └─────────────────┘  └──────────────────┘  └────────────────┘

[Two primary navigation cards — full-width, not stats]
  ┌───────────────────────────────┐  ┌───────────────────────────────┐
  │ Deliveries                    │  │ Inbound                       │
  │ Search and audit outbound...  │  │ Inspect inbound routing...    │
  │         [View Deliveries →]   │  │         [View Inbound →]      │
  └───────────────────────────────┘  └───────────────────────────────┘
```

**Sources:** PatternFly "details + performance at top" principle; Grafana "answer one question" principle; Datadog email delivery dashboard structure (bounce rate + volume + drill-down by type).

**Confidence:** MEDIUM — pattern derived from observability dashboard conventions applied to the mailglass domain. No direct prior art for this exact surface.

---

### 2. Canonical Status → Color Taxonomy

This table is the single source of truth to replace `operator/deliveries_list.ex:80`, `operator/timeline.ex`, and `inbound/records_list.ex:97`. All three copies should be deleted and routed through a single `badge_class/1` or `status_badge/1` component atom in `components.ex`.

#### Outbound Delivery Statuses (Anymail taxonomy)

| Status | Semantic | Badge bg | Badge text | Icon | Rationale |
|--------|----------|----------|------------|------|-----------|
| `:dispatched` | In-flight — handed to provider, outcome unknown | `bg-primary/10 text-primary` (Glass tint) | Glass | `→` arrow or clock | "In progress" — not success, not error. Glass is the only in-flight signal. |
| `:queued` | In-flight — queued at provider | `bg-primary/10 text-primary` | Glass | clock | Same in-flight family as dispatched |
| `:sent` | In-flight — provider accepted | `bg-primary/10 text-primary` | Glass | check-circle outline | Accepted ≠ delivered. Still in-flight. |
| `:delivered` | Terminal good — recipient server accepted | `bg-success/10 text-success` (Pine tint) | Pine | check-circle filled | Terminal success. Brightest positive signal. |
| `:deferred` | Warning — temporary retry, not yet final | `bg-warning/10 text-warning` (Amber tint) | Amber | refresh/retry | Time-bounded risk. Not a failure yet. |
| `:bounced` | Terminal bad — hard bounce, address invalid | `bg-error/10 text-error` (Crimson tint) | Crimson | x-circle filled | Terminal failure. |
| `:failed` | Terminal bad — delivery failure | `bg-error/10 text-error` | Crimson | x-circle filled | Terminal failure, same weight as bounced. |
| `:rejected` | Terminal bad — provider rejected | `bg-error/10 text-error` | Crimson | ban/block icon | Terminal rejection. |
| `:complained` | Terminal bad — spam complaint | `bg-error/10 text-error` | Crimson | flag icon | Triggers suppression. High-severity signal. |
| `:unsubscribed` | Terminal / suppression event | `bg-warning/10 text-warning` | Amber | minus-circle | Not a delivery failure per se; a consent event. Amber distinguishes from hard failures. |
| `:opened` / `:clicked` | Positive engagement (if tracking on) | `bg-success/10 text-success` | Pine | eye / cursor | Positive signals when tracking is enabled. |
| `:autoresponded` | Neutral — out-of-office / bot reply | `bg-base-200 text-secondary` | Slate | reply icon | System-generated; not operator-actionable. |
| `:unknown` | Neutral / needs investigation | `bg-base-200 text-secondary` | Slate | question-mark | Default until more data. Not an error. |

#### Inbound Message Statuses (Mailbox outcomes)

| Status | Semantic | Badge bg | Badge text | Icon | Rationale |
|--------|----------|----------|------------|------|-----------|
| `:accepted` | Terminal good — processed by mailbox | `bg-success/10 text-success` | Pine | check-circle filled | Successful routing and processing. |
| `:no_match` | Warning — no route matched | `bg-warning/10 text-warning` | Amber | route-off icon | Not an error (message received fine) but needs investigation if unexpected. |
| `:rejected` | Terminal bad — mailbox rejected | `bg-error/10 text-error` | Crimson | x-circle | Deliberate rejection by mailbox logic. |
| `:bounced` | Terminal bad — bounced via mailbox | `bg-error/10 text-error` | Crimson | arrow-return | Sent a bounce back to sender. |
| `:ignore` | Neutral / intentional discard | `bg-base-200 text-secondary` | Slate | archive icon | Intentional no-op, not a failure. |
| `:failed_ingest` | Error — ingress processing failure | `bg-error/10 text-error` | Crimson | alert-triangle | Provider signature failure or normalization error. Operator must investigate. |

#### Replay Statuses

| Status | Semantic | Badge bg | Badge text |
|--------|----------|----------|------------|
| `:replayed` | Replay succeeded | `bg-success/10 text-success` | Pine |
| `:replay_noop` | Replay was idempotent no-op (already processed) | `bg-base-200 text-secondary` | Slate |
| `:replay_failed` | Replay failed | `bg-error/10 text-error` | Crimson |

#### Support Card / Health Count Colors

| Signal | Color | Trigger |
|--------|-------|---------|
| Orphan backlog > 0 | `text-warning` (Amber) | Non-zero unmatched inbound |
| Recent failures > 0 | `text-error` (Crimson) | Bounced/failed/rejected in last 24h |
| Suppression count > 0 | `text-secondary` (Slate) | Suppressions exist (informational, not alarming) |
| All clear | `text-success` (Pine) | Zero failures, zero orphans |

**Colorblind-safety rules (mandatory):**
- Never rely on color alone. Every badge carries an icon (status category) AND a text label.
- Red/green pair (error/success) is distinguishable by deuteranopes because they map to different icon shapes (x-circle vs check-circle) and different text.
- Amber/Pine/Crimson opacity tints (`/10` background) maintain 4.5:1 contrast against their text colors when using the semantic token values specified.
- Dark mode: daisyUI semantic tokens invert correctly; opacity tints maintain legibility. No additional dark-mode overrides needed if tokens are used.

**Sources:** Carbon Design System status color taxonomy (red=error, green=success, amber/yellow=warning, blue=in-progress, slate/gray=neutral/draft); Clarity Design System status types; WCAG 2.1 AA contrast requirements; Anymail taxonomy verbatim; brand book semantic colors.

**Confidence:** HIGH — taxonomy derived from Carbon/Clarity primary sources, mapped to existing brand semantic tokens. The specific token names match the existing `design-system.md` token layer.

---

### 3. Support-Card Hierarchy Redesign

**Current state:** 2×2 flat grid, four cards with identical visual weight regardless of count.

**Problem:** A flat grid gives no triage signal. Zero-count cards consume the same space and prominence as cards with 10 actionable items. Operators cannot pre-attentively distinguish "all clear" from "things need attention."

**Recommended pattern — two-tier hierarchy:**

**Tier 1 (primary): Actionable / non-zero cards**
- Full `card bg-base-200 border border-base-300` container
- Large `text-display font-bold` count number in semantic color (Crimson for failures, Amber for orphans)
- `text-body` label below
- `motion-reveal` entrance when count changes from 0→non-zero
- Link/button to filtered list view

**Tier 2 (secondary): Zero-state / all-clear cards**
- Compact single-row layout: icon + label + "0" in `text-secondary`
- No card container — just a horizontal rule separator row
- `text-label` size
- No entrance motion (already visible, just quiet)

**Implementation sketch:**
```
[Non-zero cards render as full cards — same row as today, but with visual weight]
  ┌────────────────────────────────────────────────────────────────┐
  │ 3 failed deliveries (last 24h)              [View failures →]  │
  └────────────────────────────────────────────────────────────────┘

[Zero-state items collapse to a compact summary row below]
  ── No orphan backlog · No active retries ──
```

**Key decision:** restructure-first, then tokenize. Change the HTML structure in Phase 2 before applying token classes. Avoids re-touch.

**Sources:** PatternFly "only include non-zero items" aggregate status card guideline; dashboard design principle of organizing from "most critical / most actionable" at top (Grafana, UXPin); progressive disclosure "hover reveals secondary detail" pattern.

**Confidence:** MEDIUM — pattern synthesized from PatternFly + dashboard conventions applied to the specific support-cards structure. No exact prior art for this component shape.

---

### 4. Empty / Error / Loading State Inventory and Design

#### Complete State Taxonomy (for Phase 0 inventory)

Every screen has five possible data states. The Phase 0 audit must verify each is reachable and designed:

| State | Trigger | Pattern |
|-------|---------|---------|
| **Loading** | Data fetch in-flight | Skeleton component (text-line + heading placeholders). Never a spinner on < 200ms loads. |
| **Blank slate** | New context, no data ever created (fresh tenant) | Icon + `text-heading` title + `text-body` description + primary CTA. Copy names the next action. |
| **No results** | Filter combination returns zero matches | Icon + quote the filter value + "No [deliveries] match [filter]" + "Clear filters" CTA. |
| **Error** | Data fetch failed | Icon (alert-triangle) + specific error description + retry CTA. Include error code if available. Never blame user. |
| **Cleared** | User completed all actionable items (e.g., processed all inbound) | Positive confirmation. Can use Pine/success tint. Brief, not celebratory. |

#### Per-Surface State Matrix (seed for Phase 0 gap register)

| Surface | Loading | Blank slate | No results | Error | Cleared |
|---------|---------|-------------|------------|-------|---------|
| Operator Overview | Skeleton health row | "No data yet. Send your first email." | N/A | "Overview unavailable. [Retry]" | All-clear health cards in Pine |
| Deliveries list | Skeleton rows | "No deliveries yet." + link to docs | "No deliveries match [filter]. [Clear filters]" | "Failed to load deliveries. [Retry]" | N/A |
| Delivery detail / timeline | Skeleton timeline | N/A | N/A | "Timeline unavailable. [Retry]" | N/A |
| Inbound records | Skeleton rows | "No inbound messages received." | "No messages match [filter]. [Clear filters]" | "Failed to load records. [Retry]" | N/A |
| Inbound detail / routing trace | Skeleton | N/A | N/A | "Routing trace unavailable. [Retry]" | N/A |
| Preview sidebar | Skeleton | "No mailables found. Define a mailable in your app." | N/A | "Preview unavailable. [Retry]" | N/A |
| Support cards | Skeleton count | All-zero state (compact row) | N/A | Individual card error state | All-clear row |

#### Empty State Copy Rules

From Vercel Geist + brand book:
1. Title: "No [noun] yet" or "[Noun] not found". Title Case. State the condition.
2. Description: Sentence case. One sentence. Explain *why* or *what to do next* — provide new information, do not repeat the title.
3. CTA: Title Case, Verb + Noun structure. One primary action max. "View Documentation", "Send Test Email", "Clear Filters". Never "Get Started" or "Continue" (too generic per Geist rules).
4. Icon: Use the relevant domain icon (delivery, envelope, route, shield). Outline style, `text-secondary` color. No illustrations.

**Joy + orientation in empty states:** "Joy" in this brand is not confetti — it is specificity. An empty state that says exactly *why* there's nothing and *exactly* what to do next is more joyful (and more trustworthy) than a generic "No results" with a cute illustration. The brand promise "Delivery blocked: recipient is on the suppression list" extends directly to empty states.

**Sources:** Vercel Geist empty-state pattern (blank-slate/no-results/error/cleared taxonomy, Verb+Noun CTA rule, quote-the-filter rule); Agriculture Design System loading/error/empty pattern (skeleton loading, specific error copy, trigger scenarios); brand book "calm under failure" and "generous with context" principles.

**Confidence:** HIGH for copy rules (direct from Geist + brand book). MEDIUM for skeleton loading guidance (design-system.md is silent on skeleton; adding per this research).

---

### 5. Motion as Polish — Principles and Phase-3 Assignments

#### Core Principles (from emilkowal.ski, enforced by design-system.md)

1. **Ease-out only.** Never ease-in. Ease-out feels like a quick response that settles naturally. Ease-in feels like something waiting to happen — builds tension that resolves wrong.
2. **Exits faster than entrances.** Leaving should be instant (100ms or less). Arriving can take up to 220ms. Asymmetry creates a feeling of responsiveness — the UI got out of the way quickly, and the new thing arrived deliberately.
3. **Transform + opacity only.** Never animate height/width/padding/margin. These trigger layout recalculation (reflow) on every frame and cause jank. The translateY + opacity combo is hardware-accelerated.
4. **Entrance fires on mount, not on every patch.** In LiveView, `phx-mounted` triggers on element insertion. Patch-triggered class changes do not re-run entrance animations. This is correct — operators should not see a `reveal` flash on every periodic data update.
5. **Never animate keyboard-repeatable actions.** If an operator presses a key to page through records, they do it 20 times in 30 seconds. A 220ms animation on every keypress is 4 seconds of forced waiting. Instant state for keyboard navigation.
6. **Interruptibility.** If a new LiveView message arrives mid-animation, the animation must not fight it. LiveView's diff-patching handles this naturally when animations are CSS-only; no JS state machine needed.
7. **Reduced motion:** The existing `@media (prefers-reduced-motion: reduce)` block in the design system neutralizes movement, letting crossfades snap. Verify this is applied to all six named motions.

#### Recommended Motion Assignment Matrix (for Phase 3 / UI-SPEC)

| Motion | Token | Duration | Where to apply | Where NOT to apply |
|--------|-------|----------|----------------|---------------------|
| `reveal` | `motion-reveal` (opacity + translateY 6px) | 220ms | Detail pane opening, card appearing, flash toast | Filter changes, list row selection, pagination |
| `timeline-in` | `motion-timeline > *` (staggered 40ms, cap 8) | 220ms + stagger | Event timeline items on initial mount | On every timeline patch/update |
| `tab-swap` | `motion-tab-swap` (crossfade 150ms, id-keyed) | 150ms | Preview tab switch, modal backdrop | Nav between pages (full LiveView navigation is fast enough) |
| `overlay` | `motion-overlay` (scale 0.98→1 + opacity) | 220ms | Modal/dialog open | Modal close (use instant or 100ms reverse) |
| `row-state` | `transition-colors duration-fast` | 100ms | Row hover, row selected, active nav item, badge state change | Row removal (use instant) |
| `flash` | `motion-reveal` on toast region | 220ms entry, 100ms exit | Success/error flash after action | Informational banners (static) |

**"Pop/joy" via motion — specific to mailglass_admin:**
- The timeline-in stagger on the delivery event timeline is the single highest-joy motion in the product. A forensic operator watching timeline events appear in sequence perceives the system "showing them the story". This stagger should be reliable on every detail-pane open (mount), not intermittent.
- The `row-state` color transition on row hover is the most-seen motion in the product (operators hover over 20+ rows per session). It must be imperceptibly fast (100ms) and smooth. If it's janky or slow, it undermines confidence in the whole UI.
- The `reveal` on the detail pane is the most emotionally significant motion — it signals "the system responded to my click". It should fire exactly once per detail open, not on every update.

**What NOT to do with motion (anti-features restated):**
- No `motion-reveal` on the orientation strip (it's always visible, not triggered by an action)
- No animated height/width on support card collapse/expand
- No bounce/spring easing (brand: "ease-out only")
- No staggered entrance on the delivery list rows (the list updates too frequently)
- No loading spinners that animate when data arrives in < 200ms

**Sources:** emilkowal.ski/ui/great-animations (ease-out, transform+opacity, exits faster, keyboard actions); emilkowal.ski/ui/good-vs-great-animations (origin awareness, easing mastery, no decorative animation in functional contexts); design-system.md motion vocabulary (existing implementation spec); brand book motion guidance (short fades, pane reveals, state transitions; no bounce/elastic/confetti).

**Confidence:** HIGH (design-system.md is the authority; these are application rules, not new spec). MEDIUM on "exits faster" and "origin awareness" (direct from emilkowal.ski, confirmed in design-system.md direction).

---

## Feature Dependencies

```
Canonical status taxonomy (Phase 2 badge atom)
    └──required by──> Orientation strip on all 3 surfaces (Phase 1)
    └──required by──> Operator Overview health cards (Phase 1)
    └──required by──> Support card hierarchy redesign (Phase 2)

Phase 0 gap register + state inventory
    └──gates──> All build phases (1, 2, 3, 4, 5)

Support card hierarchy redesign (structure)
    └──must precede──> Token migration of support_cards.ex
    (restructure-then-tokenize order prevents re-touch)

Seed data expansion (Phase 4)
    └──required for──> Every empty/error/loading state reachable
    └──parallel with──> Phase 2 and Phase 3 (no blocking dependency)

Motion assignments (Phase 3)
    └──must wait for──> Phase 2 structure settling
    (motion fires on the right elements only after restructure)
```

---

## Implementation Priority for UI-SPEC

### Phase 74 (Audit + UI-SPEC) Must Produce

- [ ] Gap register with severity scores (surface × component × pillar)
- [ ] **Canonical status taxonomy table** (the table in §2 above, plus the token names from `design-system.md`) — freeze this before Phase 75 to prevent re-touch of badge logic
- [ ] **Support card hierarchy redesign sketch** — two-tier layout with HTML structure spec
- [ ] **State inventory** — per-surface × per-state matrix (the table in §4 above)
- [ ] **Motion assignment matrix** — which named motion fires on which mount/interaction (the table in §5 above)
- [ ] Before/after screenshot baseline committed to `tmp/ui-audit/` (gitignored)
- [ ] Inventory of all demo/e2e assertions that phases 75–78 will ripple

### Phase 75 (IA + Navigation)

- [ ] `orientation_strip/1` generalized to shell-level, applied to all 3 surfaces
- [ ] Operator Overview route at mount index (`/ops/mail/`)
- [ ] Page title/subtitle vocabulary applied via token hierarchy

### Phase 76 (Component Hardening)

- [ ] `status_badge/1` unified atom in `components.ex`
- [ ] Three `badge_class/1` copies deleted
- [ ] `support_cards.ex` restructured to two-tier hierarchy
- [ ] Token migration: `text-body/label/heading` throughout

### Phase 77 (Motion)

- [ ] Six named motions applied per assignment matrix
- [ ] Reduced-motion compliance verified on all six
- [ ] Entrance fires on mount only, not on patch

### Phase 78 (Seed Data)

- [ ] Every delivery status seeded (all 14 Anymail states)
- [ ] All inbound outcomes seeded (accept/no_match/reject/bounce/ignore/failed_ingest)
- [ ] Empty-tenant seeded for blank-slate states
- [ ] Long-text truncation stress rows

---

## Confidence Assessment

| Area | Confidence | Source | Notes |
|------|------------|--------|-------|
| Operator IA / cold-start pattern | MEDIUM | Grafana, PatternFly, Datadog email blog | Synthesized from observability conventions; no exact prior art for this surface |
| Status taxonomy — outbound | HIGH | Carbon Design System, Anymail taxonomy (already in PROJECT.md), brand semantic tokens | Direct mapping of canonical sources |
| Status taxonomy — inbound | HIGH | Anymail taxonomy + mailbox locked outcomes (PROJECT.md) | Well-specified in existing project |
| Support card hierarchy | MEDIUM | PatternFly aggregate status cards + UXPin dashboard principles | Pattern is well-established; specific layout extrapolated |
| Empty state copy rules | HIGH | Vercel Geist (direct), Agriculture DS (direct), brand book | Multiple concordant authoritative sources |
| Empty state taxonomy | HIGH | Vercel Geist (blank-slate/no-results/cleared/error/permission) | Direct from official design system |
| Motion principles | HIGH | design-system.md (project authority) + emilkowal.ski (direct) | Already specced in project; this research confirms alignment |
| Motion assignments | MEDIUM | design-system.md motion vocabulary applied | Application rules derived from spec; final assignments need Phase 0 audit |
| Colorblind safety | HIGH | WCAG 2.1, Carbon DS accessibility guidance, brand book §12 | Standard; icon+text pairing rule is non-negotiable |

---

## Sources

- [Emil Kowalski — Great animations](https://emilkowal.ski/ui/great-animations)
- [Emil Kowalski — Good vs Great animations](https://emilkowal.ski/ui/good-vs-great-animations)
- [Carbon Design System — Status indicator pattern](https://carbondesignsystem.com/patterns/status-indicator-pattern/)
- [PatternFly — Dashboard design guidelines](https://www.patternfly.org/patterns/dashboard/design-guidelines/)
- [Vercel Geist — Empty state pattern](https://vercel.com/geist/empty-state)
- [Agriculture Design System — Loading, error, empty states](https://design-system.agriculture.gov.au/patterns/loading-error-empty-states)
- [Grafana — Dashboard best practices](https://grafana.com/docs/grafana/latest/visualizations/dashboards/build-dashboards/best-practices/)
- [Datadog — Internal monitoring of email delivery](https://www.datadoghq.com/blog/internal-monitoring-email-delivery/)
- [Postmark — Redesigned statistics and activity updates](https://postmarkapp.com/blog/redesigned-statistics-and-activity-updates)
- [Designing Engineering Dashboards for Incident Response](https://medium.com/@dennishenry/designing-engineering-dashboards-for-incident-response-the-good-the-bad-and-the-ugly-f784bb17c4ee)
- `mailglass_admin/docs/design-system.md` — existing motion vocabulary and token spec (project authority)
- `prompts/mailglass-brand-book.md` — visual identity, voice, anti-patterns (project authority)

---

*UI/UX & IA pattern research for: mailglass_admin polish v2 (phases 74–79)*
*Researched: 2026-06-03*
*Do NOT overwrite `.planning/research/FEATURES.md` — this is a milestone-scoped file only.*
