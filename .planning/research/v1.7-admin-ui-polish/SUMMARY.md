# Research Summary — mailglass_admin UI/UX & IA Polish v2 (v1.7)

**Project:** mailglass_admin
**Domain:** Node-free Phoenix LiveView operator/preview dashboard — IA, design-system hardening, motion, seed data
**Researched:** 2026-06-03
**Confidence:** HIGH

---

## Executive Summary

This is an application-of-existing-system milestone, not a system-extension milestone. The toolchain (Tailwind v4.1.12 standalone binary, daisyUI 5 vendor JS, Phoenix LiveView 1.1.x) already supplies every mechanism needed across all six phases. No new Hex packages, no new vendor JS, no new tooling. The entire v1.7 surface area is: apply the shipped design system correctly, consolidate three diverging badge copies into one canonical atom, generalize the orientation strip to all three surfaces, add an Operator Overview landing route, fix the motion-reveal re-fire bug, and expand seed data to cover every reachable state.

The single highest-risk item in the milestone is the badge taxonomy consolidation. Three existing `badge_class/1` copies in `deliveries_list.ex`, `timeline.ex`, and `records_list.ex` genuinely disagree on at least one status atom (notably `:suppressed`). Consolidation will silently change at least one badge color unless Phase 74 inventories all three implementations side-by-side and makes explicit decisions per conflict before any code changes. This is the reason the canonical status taxonomy table must be frozen at the end of Phase 74 — every subsequent phase consumes it.

The critical path is 74 → 75 → 76 → 79. Phase 77 (motion) can begin after Phase 76's structural changes settle. Phase 78 (seed data) runs parallel from Phase 74 onward. The anti-churn contract is the governing discipline: freeze IA vocabulary and status taxonomy at the end of Phase 74; merge Phase 75 before Phase 76 implementation begins; restructure support cards before tokenizing them. Linked-version release mechanics mean an admin-only minor bump will produce matched `1.5.0` releases across `mailglass`, `mailglass_admin`, and `mailglass_inbound` — this is expected and correct, but must be acknowledged in the milestone scope.

---

## Key Findings

### Recommended Stack

No dependency changes. The milestone is fully served by the existing toolchain. Tailwind v4.1.12 standalone binary provides the JIT scanner and token system via `@theme` in `app.css`. daisyUI 5 (vendored) provides all semantic component classes including `badge`, `badge-outline`, `badge-success`, `badge-warning`, `badge-error`, `badge-sm`, `card`, `rounded-box`, and `rounded-field`. Phoenix LiveView 1.1.x provides `Phoenix.LiveView.JS`, `phx-mounted`, and `phx-remove` for all motion orchestration. The `prefers-reduced-motion` global override block in `app.css` already covers all six named motion vocabulary classes with no per-component work needed.

**Core technologies (versions frozen, no bumps needed for v1.7):**
- `tailwind` Hex 0.4.1 / binary 4.1.12: JIT compilation, token scales, `@plugin` support — no Node required
- daisyUI 5 (vendored JS): semantic component classes; v5 renamed several classes from v4 (`badge-outline` not `badge-ghost`); verify all class names against the installed plugin, not web search results
- Phoenix LiveView ~> 1.1: `phx-mounted` fires on DOM insertion (not on patches); `JS.transition` adds class temporarily for `time` ms; detail-pane motion fix requires a delivery-keyed `id` attribute
- `agent-browser` CLI (local/ad-hoc, not pinned): screenshot capture for the Phase 74 audit ritual and Phase 79 closeout; must never be added to CI (non-deterministic pixel output, not in dependency graph)

**What NOT to add:** new Hex CSS/animation libraries, PostCSS, pixel-diff CI tools (Percy/Chromatic), LiveView `phx-hook` JS, `@apply` directives, or any second CSS file. The design-system.md constraint is absolute.

### Expected Features

**Must have (table stakes — missing = feels incomplete):**
- Symptom-first orientation strip on all three surfaces (Preview, Deliveries, Inbound) — operators arrive time-pressured; a surface without orientation feels broken
- Consistent status-badge color taxonomy across all surfaces — three disagreeing copies are trust-destroying for forensic users
- Primary/secondary card hierarchy on support cards — flat 2x2 grid with equal visual weight gives no triage signal
- Non-empty states for every screen (loading, blank-slate, no-results, error, cleared) — missing any makes the UI feel unfinished
- Token-conformant spacing and type throughout — operators notice off-grid gaps between components

**Should have (differentiators — produce "insane polish"):**
- Operator Overview landing inside the library (`/ops/mail/` index route) — no other Phoenix email lib ships this; answers "is anything broken?" on cold landing
- Expressive seed data covering every screen state — demo that exercises every badge color and every empty/error state is self-documenting
- Motion as confirmation — timeline-in stagger on delivery detail is the highest-joy motion; `row-state` transition on hover is the most-seen motion; `reveal` on detail pane signals "the system responded"
- Page-title/subtitle IA vocabulary applied via token hierarchy — operators orient by text shape, not just position
- Canonical empty states with direct-action copy (Vercel Geist "Verb + Noun" CTA pattern)

**Explicitly out of scope / anti-features:**
- Single global home collapsing Preview + Deliveries + Inbound — collapses two mental models (build-time vs run-time); the mount split is the feature
- Glassmorphism, frosted-glass effects, backdrop-blur — first anti-pattern in the brand book
- Decorative motion on static content or keyboard-repeatable actions
- Animated height/width/padding — layout jank; opacity + translateY only
- Rich SVG illustrations in empty states — off-brand; icon + copy + CTA is complete
- Rainbow/multi-color badge palette — six semantic colors max

### Architecture Approach

The entire structural surface of v1.7 fits within existing modules with no new compilation units and no router macro changes. The Overview is a new `:overview` action on the existing `OperatorLive` (handled in `handle_params`), not a new `live` route. `orientation_strip/1` moves from a private `defp` in `operator_live.ex` to a public function component in `shell.ex` (chrome module). `status_badge/1` is a new public component in `components.ex` (brand atoms module). All three `badge_class/1` private functions are deleted after migration. The stable router macro seam (`mailglass_operator_routes/2`) is untouched.

**Major components and their v1.7 changes:**

1. `MailglassAdmin.Operator.Shell` (`shell.ex`) — ADD public `orientation_strip/1` component; shell's `:active` atom values stay as-is (Overview passes `active={:deliveries}`)
2. `MailglassAdmin.Components` (`components.ex`) — ADD public `status_badge/1` component with private `status_class/1` and `status_label/1` driven by the Phase 74 canonical taxonomy table
3. `MailglassAdmin.OperatorLive` (`operator_live.ex`) — ADD `:overview` action render branch; REMOVE private `orientation_strip/1` defp (line 362); fix motion-reveal div with delivery-keyed `id`
4. `MailglassAdmin.InboundLive` (`inbound_live.ex`) — ADD `orientation_strip` call in empty-detail branch
5. `MailglassAdmin.Operator.SupportCards` (`operator/support_cards.ex`) — RESTRUCTURE to primary/secondary grid hierarchy (non-zero cards prominent, zero-state cards compact), then token-migrate
6. Three badge callers — REMOVE `badge_class/1` from `deliveries_list.ex`, `timeline.ex`, `records_list.ex`; replace with `<Components.status_badge />`

**Health data:** Operator Overview reuses the existing `Mailglass.Operator.SupportSummary.summarize_tenant/1` seam already called by `OperatorLive.load_support_summary/2`. Suppression count for the Overview requires confirming whether `Suppressions.count_active_suppressions/1` exists or needs to be added as a small core function (inference — not yet verified).

**Build order within phases:** `status_badge/1` in `components.ex` must land before deleting any `badge_class/1` copy and before Phase 75 finalizes Inbound orientation. Within Phase 76: restructure support-card layout first, then token-migrate — never the reverse.

### Critical Pitfalls

1. **Badge taxonomy consolidation silently changes a status's color** (Pitfall 5, CRITICAL) — the three `badge_class/1` copies disagree on at least one status; Phase 74 must compare all three implementations side-by-side and make an explicit decision per conflict before Phase 76 touches any badge code. Add a regression test that asserts the exact CSS class for every atom in the taxonomy.

2. **Tailwind JIT silently drops dynamically constructed class names** (Pitfall 1, CRITICAL) — `"badge-#{status}"` produces a string the scanner never sees; the badge renders unstyled with no error anywhere. Every badge helper must return only literal complete strings from pattern-matched functions.

3. **Entrance motion fires on every LiveView patch instead of only on mount** (Pitfall 6, HIGH) — the existing `motion-reveal` div in `operator_live.ex:332` has no `id`; LiveView patches it in place rather than replacing it, so the animation does not re-fire on delivery selection. Fix: add `id={"delivery-detail-#{@selected_delivery.id}"}`. Model on the existing `preview-tab-#{tab}` pattern in `tabs.ex`.

4. **`demo.spec.js` and `operator.spec.js` exact-string assertions break from IA or seed changes** (Pitfall 10, HIGH) — Phase 74 must inventory every heading and count assertion in both spec files; Phase 75 heading changes and Phase 78 seed-count changes must update the corresponding assertion in the same commit. Do NOT bump frozen `reference/host_app` or `reference/demo_app` version pins.

5. **Restructure-then-tokenize order inverted** (Pitfall 4, HIGH) — tokenizing `support_cards.ex` before redesigning the primary/secondary grid structure causes two churn passes. The Phase 74 UI-SPEC must specify the final layout structure before Phase 76 begins; Phase 76 step order is: (1) redesign grid structure, (2) token-migrate final markup.

6. **Deep-link unstyled CSS bug disposition left ambiguous** (Pitfall 16, MEDIUM) — Phase 75 must make an explicit in-scope / explicitly-deferred decision and record it. Phase 79's success criterion is zero open sev-4/5 gap-register rows; an undispositioned deep-link bug blocks closeout.

---

## Implications for Roadmap

Based on combined research, the canonical phase structure is:

### Phase 74 — Systematic Audit + UI-SPEC (evidence gate, no code)

**Rationale:** Every subsequent phase consumes a deliverable from Phase 74. Building on an unfrozen IA or an unresolved badge taxonomy causes re-touch. This phase blocks all others.

**Delivers:**
- Gap register with severity scores (surface x component x pillar)
- Canonical status taxonomy table — 6 semantic buckets, all three `badge_class/1` copies compared side-by-side, every conflict explicitly resolved; token names verified against daisyUI 5 installed plugin (not web search)
- Support-card hierarchy layout spec — primary/secondary grid with HTML structure
- Per-surface empty/error/loading state inventory matrix
- Motion assignment matrix — which of the 6 named motions fires on which interaction
- Assertion inventory — every exact-string heading and count assertion in `demo.spec.js` and `operator.spec.js` that phases 75–78 will ripple
- Before-baseline screenshots at 390px / 768px / 1440px for all three surfaces and light/dark
- Explicit in/out decision for deep-link unstyled bug
- Milestone scope note: linked-version release will produce matched `1.5.0` across all three packages

**Avoids:** Pitfall 5 (silent color change), Pitfall 3 (daisyUI v4 class drift), Pitfall 4 (restructure order), Pitfall 13 (IA freeze violation), Pitfall 16 (deep-link ambiguity)

**Research flag:** Standard patterns — audit is procedural; run `scripts/ui-audit.sh` + static conformance grep + three-way badge diff. No additional research needed.

**Three open questions to resolve in Phase 74:**
1. Does `preview_live.ex` have a zero-mailables empty state suitable for `orientation_strip` (not yet read)?
2. Does `Mailglass.Operator.Suppressions` expose a tenant-scoped active count, or does a new `count_active_suppressions/1` function need to be added to core?
3. Deep-link unstyled bug: in-scope fix in Phase 75 or explicitly deferred to Phase 79?

---

### Phase 75 — Information Architecture, Navigation & Orientation

**Rationale:** IA decisions (route paths, heading strings, orientation content) are consumed by Phase 76's badge atom and support-card links. Phase 75 must merge before Phase 76 implementation begins.

**Delivers:**
- `Shell.orientation_strip/1` public function component (extracts from `operator_live.ex:362` private defp)
- `orientation_strip` applied to Deliveries, Inbound, and Preview surfaces with surface-specific symptom-first copy
- Operator Overview: new `:overview` action on `OperatorLive` (zero router macro change); renders orientation strip + 4 at-a-glance health cards (orphan backlog, recent failures, suppression count, all-clear) + two primary navigation cards routing to Deliveries and Inbound; reuses `SupportSummary.summarize_tenant/1` via existing `support_summary_module()` indirection
- Page-title/subtitle IA vocabulary applied (`text-display`/`text-heading`/`text-body`/`text-label` hierarchy)
- Updated `operator.spec.js` and `demo.spec.js` heading assertions in the same commit

**Architecture note:** The Operator Overview passes `active={:deliveries}` to the shell — no new `:overview` atom needed in shell's `:active` attribute. The Overview IS the Deliveries surface root.

**Avoids:** Pitfall 13 (IA freeze violation — merge before Phase 76), Pitfall 10 (spec assertions in same commit), Pitfall 11 (do not touch reference app version pins)

**Research flag:** Standard patterns — well-specified in ARCHITECTURE.md with concrete file:line references. No additional research needed.

---

### Phase 76 — Component-Library / Design-System Hardening

**Rationale:** Badge atom must land before any badge_class deletion; restructure must precede token migration. This phase has the most internal sequencing constraints.

**Delivers:**
- `Components.status_badge/1` unified atom in `components.ex` — consumes the Phase 74 canonical taxonomy table; `status_class/1` and `status_label/1` return only literal complete strings (never interpolated)
- All three `badge_class/1` private copies deleted from `deliveries_list.ex`, `timeline.ex`, `records_list.ex`
- `support_cards.ex` restructured to primary/secondary hierarchy (non-zero-count cards as full cards; zero-state as compact summary row); then token-migrated
- Token migration across `operator_live.ex`, `inbound_live.ex`, `deliveries_list.ex`, `timeline.ex`, `records_list.ex`, `support_cards.ex`: `text-sm` -> `text-body`, `text-xs` -> `text-label`, `gap-3` -> `gap-sm`, `gap-6` -> `gap-lg`, `font-medium`/`font-semibold` -> `font-bold` or removed
- Regression test covering every atom in the taxonomy table with an assertion on the exact expected CSS class
- Bundle rebuilt and committed (`priv/static/app.css`) in the same PR as every HEEx change

**Internal step order (strict):** (1) add `status_badge/1` to `components.ex`, (2) migrate badge callers, (3) delete `badge_class/1` copies, (4) restructure support-card grid, (5) token-migrate support cards, (6) token-migrate remaining render bodies, (7) rebuild bundle

**Avoids:** Pitfall 1 (JIT dynamic class names), Pitfall 2 (missing bundle rebuild), Pitfall 3 (daisyUI v4 class drift), Pitfall 4 (restructure-then-tokenize order), Pitfall 5 (silent color change), Pitfall 7 (no height/width animation on support card state changes)

**Research flag:** Standard patterns — all implementation details are concretely specified in ARCHITECTURE.md. No additional research needed.

---

### Phase 77 — Motion & Microinteraction Polish

**Rationale:** Runs after Phase 76's structural changes settle; motion must fire on the correct elements after restructure. Can begin once Phase 76 is merged.

**Delivers:**
- Delivery detail pane motion-reveal fix: add `id={"delivery-detail-#{@selected_delivery.id}"}` to the motion-bearing div at `operator_live.ex:332`; use `phx-mounted={JS.transition("motion-reveal", time: 220)}`
- Motion assignment matrix from Phase 74 applied: `motion-reveal` on detail pane opens and flash toasts; `motion-timeline` stagger on timeline mount (not on patches); `motion-tab-swap` on preview tab switches; `motion-overlay` on modal open; `row-state` on row hover/selection
- Verification that entrance motion fires once per record selection, not on every filter patch
- No motion on orientation strip (always visible), no animated height/width on support card collapse
- `prefers-reduced-motion` compliance verified: all new motion restricted to the six named vocabulary classes; tested under Playwright `reducedMotion: 'reduce'`
- Duration/easing conformance grep: zero `duration-300+`, zero `ease-in-out`, zero `ease-linear`

**Avoids:** Pitfall 6 (entrance motion on every patch), Pitfall 7 (layout jank), Pitfall 8 (prefers-reduced-motion gaps), Pitfall 9 (duration > 300ms or non-ease-out), Pitfall 17 (no PII in new telemetry)

**Research flag:** Standard patterns — motion vocabulary is fully specified in `design-system.md` and STACK.md. The `preview/tabs.ex` id-keyed pattern is the concrete reference. No additional research needed.

---

### Phase 78 — Seed-Data Expressiveness

**Rationale:** Runs in parallel from Phase 74 onward (no blocking dependency on Phases 75–77). Seed expansion is required for every empty/error/loading state to be reachable, and for badge color coverage in the Phase 79 visual audit.

**Delivers:**
- All 14 Anymail outbound delivery statuses seeded (`:dispatched`, `:queued`, `:sent`, `:delivered`, `:deferred`, `:bounced`, `:failed`, `:rejected`, `:complained`, `:unsubscribed`, `:opened`, `:clicked`, `:autoresponded`, `:unknown`)
- All inbound outcomes seeded (`:accepted`, `:no_match`, `:rejected`, `:bounced`, `:ignore`, `:failed_ingest`)
- Orphan backlog row (unmatched inbound)
- Empty-tenant row (blank-slate state)
- Long-text truncation stress rows (subject, recipient address)
- Updated `demo.spec.js` and `operator.spec.js` count assertions in the same commit as seed changes

**Constraint:** Do NOT touch `reference/demo_app/mix.exs` or `reference/host_app/mix.exs` version pins. Only `seeds.exs` and `demo.spec.js` (e2e assertions) are in scope.

**Avoids:** Pitfall 10 (spec assertions in same commit), Pitfall 11 (frozen baseline version pins)

**Research flag:** Standard patterns. No additional research needed.

---

### Phase 79 — Verification & Visual-Regression Hardening (closeout)

**Rationale:** Final gate. Depends on all prior phases. Closes the milestone.

**Delivers:**
- Full `scripts/ui-audit.sh` matrix re-run at 390px / 768px / 1440px across all three surfaces, light and dark; before/after PNG comparison vs Phase 74 baseline
- Token conformance grep gate: zero `text-sm`, `text-base`, `text-xs`, `font-medium`, `font-semibold`, `gap-3`, `gap-4`, `gap-6`, ad-hoc `z-[0-9]+`, hex colors in HEEx
- Motion conformance grep: zero `duration-300+`, zero `ease-in-out`, zero `ease-linear`, zero `transition-height/max-height/padding/all`
- `git diff --exit-code priv/static/` bundle clean gate
- `mix credo --strict` clean (includes LINT-05 `NoTelemetryPII`)
- Extended `operator.spec.js` structural coverage for new Operator Overview and orientation strips
- Zero open sev-4/5 gap-register rows (deep-link bug must be explicitly dispositioned)
- Release ceremony acknowledgment: matched `1.5.0` bump across all three packages; administrative CHANGELOG entries for core and inbound

**Avoids:** Pitfall 2 (bundle committed), Pitfall 12 (linked-version release surprise), Pitfall 15 (390px audit gap), Pitfall 16 (undispositioned deep-link bug), Pitfall 17 (PII conformance)

**Research flag:** Standard patterns — verification procedures are fully specified in STACK.md and PITFALLS.md. No additional research needed.

---

### Phase Ordering Rationale

- **74 blocks all** because the canonical status taxonomy table, assertion inventory, support-card layout spec, and deep-link decision are consumed by every subsequent phase. Building without these outputs causes re-touch.
- **75 before 76** because IA headings and route paths are referenced by Phase 76 components. The anti-churn contract requires 75 merged before 76 implementation begins.
- **76 before 77** because motion must fire on the correctly-structured elements. Specifically, the delivery detail pane must have a record-keyed `id` (a Phase 76/77 concern) before motion is considered correct.
- **77 and 78 parallel** because neither blocks the other. Phase 78 seed work can start from Phase 74's state inventory output.
- **79 last** because it validates the complete system; it needs the Phase 74 baseline to diff against and needs all build phases merged.

### Research Flags

All phases can plan directly from this synthesis — no `/gsd:plan-phase --research-phase` needed. The four research files contain implementation-ready specifications:
- ARCHITECTURE.md provides concrete file:line references for every structural change
- STACK.md provides exact Tailwind/LiveView mechanics with verified code patterns
- FEATURES.md provides the canonical status taxonomy table and empty-state copy rules
- PITFALLS.md provides 17 pitfalls with phase-specific prevention strategies

The only open technical questions requiring validation during Phase 74 planning/execution are identified under the Phase 74 section above (three open questions).

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack / tooling | HIGH | All claims verified against live source files: `app.css`, `config.exs`, `mix.exs`, `mix.lock`, vendor JS files, Context7 LiveView docs |
| Features / UX patterns | HIGH (table stakes) / MEDIUM (IA) | Status taxonomy: HIGH (Carbon DS + Anymail + brand tokens). Empty-state copy rules: HIGH (Vercel Geist + brand book). Operator IA / cold-start pattern: MEDIUM (synthesized from observability conventions; no exact prior art for this surface) |
| Architecture | HIGH | All structural claims mapped to concrete file:line. Three inferences explicitly flagged: Preview orientation_strip trigger condition; suppression count API availability; exact `handle_params` dispatch implementation |
| Pitfalls | HIGH | Grounded in actual source files and confirmed blueprint constraints. All 17 pitfalls have phase-to-prevention mappings and "looks done but isn't" checklist items |

**Overall confidence:** HIGH

### Gaps to Address

- **Preview orientation_strip trigger condition** — `preview_live.ex` was not read during research. Phase 74 audit must confirm whether a zero-mailables empty state exists and where the trigger condition is. This does not block any other planning.
- **Suppression count API** — whether `Mailglass.Operator.Suppressions` exposes a tenant-scoped active count is inferred but not confirmed. Phase 74 must read the Suppressions module. If no such function exists, add `count_active_suppressions/1` to core as a small additive change before Phase 75 implementation.
- **Deep-link unstyled bug disposition** — the fix touches asset-serving strategy (a stable seam concern). Phase 75 must make the explicit in/out decision with reasoning. If deferred, record the sev-downgrade rationale in the Phase 74 gap register.
- **230 raw type-token violations in `mailglass_admin/lib/`** — this is the confirmed token-migration surface. Phase 74 conformance grep will produce the exact file distribution; Phase 76 consumes that output.

---

## Sources

### Primary (HIGH confidence)

- `mailglass_admin/assets/css/app.css` — confirmed token scales, motion keyframes, reduced-motion block, `@plugin` integration, `@source` paths
- `mailglass_admin/docs/design-system.md` — conformance rubric, motion vocabulary, audit loop mechanics, known limitations
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` (lines 71, 227, 254-256, 332, 362-392, 660-670) — current orientation_strip, motion-reveal bug, support summary seam
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` (lines 102-193) — chrome layer structure, `:active` attr values
- `mailglass_admin/lib/mailglass_admin/components.ex` (lines 91-115) — existing badge/atom structure
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` (lines 49, 80-84) — badge_class divergence confirmed
- `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` (lines 52-53, 131-135) — badge_class structural difference confirmed
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` (lines 55, 97-101) — badge_class divergence confirmed
- `mailglass_admin/lib/mailglass_admin/router.ex` (lines 247-275) — stable seam confirmed untouched
- `lib/mailglass/operator/support_summary.ex` (lines 21-35) — health data seams confirmed
- `mailglass_admin/scripts/ui-audit.sh` — audit tooling mechanics confirmed
- `mailglass_admin/config/config.exs` — Tailwind binary version 4.1.12
- `assets/vendor/daisyui.js`, `assets/vendor/daisyui-theme.js` — daisyUI 5 confirmed
- `mailglass_admin/e2e/operator.spec.js`, `reference/demo_app/assets/e2e/demo.spec.js` — exact-match assertions inventoried
- Context7 `/phoenixframework/phoenix_live_view` — `phx-mounted` fires on DOM insertion not patches; `JS.transition` adds class temporarily for `time` ms
- `/Users/jon/.claude/plans/mailglass-context-handoff-serene-noodle.md` — approved milestone blueprint

### Secondary (MEDIUM confidence)

- Carbon Design System status indicator pattern — status color taxonomy mapping
- PatternFly dashboard design guidelines — primary/secondary card hierarchy pattern
- Vercel Geist empty-state pattern — blank-slate/no-results/error/cleared taxonomy, Verb+Noun CTA rule
- Emil Kowalski great animations / good vs great animations — ease-out only, exits faster, keyboard action rules
- Grafana dashboard best practices — "answer one question" principle
- Agriculture Design System loading/error/empty states — skeleton loading, specific error copy
- `prompts/mailglass-brand-book.md` — visual palette, typography, motion guidance, anti-patterns

---

*Research completed: 2026-06-03*
*Ready for roadmap: yes*
