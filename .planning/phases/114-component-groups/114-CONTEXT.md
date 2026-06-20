# Phase 114: Component Groups - Context

**Gathered:** 2026-06-20 (assumptions mode + per-area research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Coherence across **composed component groups** — intentional spacing/hierarchy that makes
the next action obvious, bounded box-nesting (depth ≤2, no "box prison"), intentional
breathing room (no flush-to-container edges), and consistent x/y grid alignment that holds
at narrow (320px) and wide widths. This is a **fractal design-system uplift** of how already-built
primitives compose into groups — NOT new product capability.

The three named composed groups are the entire surface:
1. **support-cards triage** — `operator/support_cards.ex`, `operator/suppression_card.ex`
2. **routing-trace + evidence** — `inbound/routing_trace.ex`, `inbound/evidence_card.ex`
3. **detail + timeline** — `operator/detail_header.ex` + `operator/timeline.ex`,
   `inbound/detail_header.ex` + `inbound/timeline.ex`

Requirements: GROUP-01 (coherent spacing/hierarchy, next action obvious), GROUP-02 (nesting
depth ≤2, breathing room, no flush-to-edge), GROUP-03 (consistent x/y grid alignment at narrow
and wide widths).
</domain>

<decisions>
## Implementation Decisions

### Layout: Thin Shared Card Shell + Token Discipline

- **D-01:** Extract a single, deliberately thin card shell primitive (`<.card>`/`<.panel>`)
  into `MailglassAdmin.Components` and render the group surfaces through it. The shell
  `card rounded-box border border-base-300 bg-base-200` is currently hand-rolled across ~8
  surfaces; Phase 110 already locked "repeated hand-rolled primitive = drift" enforced by
  PRIMITIVE-DRIFT-GATE, so leaving 8 copies is non-conformant. A `<.card>` is idiomatic Phoenix
  and consistent with the module's own precedent (`stat_card/1`, `filter_section/1`, `data_state/1`).

- **D-02:** The card primitive stays thin — extract ONLY the shell (border + radius + surface +
  outer padding), exposing one `padding: :md | :lg` attr and one `<:inner_block>`, ≤20 lines.
  Do NOT absorb inter-card vertical rhythm, detail-header `dl` grids, timeline `<ol>` spacing, or
  routing-trace nested wells into the primitive — those stay as semantic spacing utilities at the
  call sites because they genuinely differ per surface. Over-slotting a card into a layout engine
  is the documented premature-abstraction footgun (shadcn/GOV.UK).

- **D-03:** Sweep the real consistency defect: replace the ~190 raw off-grid spacing tokens
  (`p-6`, `mt-1`, `space-y-1`, `gap-2` — which current GAP-GATE/SIZE-GATE miss) across the group
  files with the 4px-grid semantic tokens (`xs..3xl`, `p-md/p-lg`, `gap-md`, `space-y-*`). Add a
  **SPACE-GATE** in `check-conformance.sh` banning raw numeric padding/margin/`space-y` literals,
  modeled on the existing GAP-GATE. The gate must be scoped carefully to avoid false-positives on
  unrelated `lib/` files (a planning/authoring detail — mind the boundary-regex footgun the existing
  GAP/SIZE gates already exhibit).

### Hierarchy Without the Box Prison

- **D-04:** Single milestone rule for nested content: **outer composed group = `bg-base-200`
  raised card with `shadow-raised`; nested content = borderless `bg-base-100` sunken inset; never
  two `bg-base-200` fills stacked in one group.** This matches the brand's documented
  `surface-sunken`/well semantics and the reference groups that already do it right
  (`evidence_card`, `routing_trace`, both `timeline` modules).

- **D-05:** `support_cards.ex` is the lone offender (3 inner `<article class="card bg-base-200
  border border-base-300 rounded-box p-lg">` cards = same-tone card-in-card). Fix: demote the
  inner Tier-1 containers to a borderless `bg-base-100` sunken inset and give the outer `<section>`
  `shadow-raised` so the raised-outer / sunken-inner tonal step is unambiguous. Depth becomes
  section → inset (≤2).

- **D-06:** Primary/Secondary emphasis is carried by **content weight, not nesting**: the Tier-1
  inset leads with a `text-display font-bold` status-colored count (the F-pattern anchor and the
  single obvious "next action") plus one `btn btn-primary`; Tier-2 stays a lighter borderless
  divider row. Optionally layer a 3px status left-rule (`border-l-4 border-error|warning`, the brand
  Alert recipe) onto the inset for at-scan triage — always paired with the colored count + label so
  status is never color-alone (WCAG 1.4.1). The other named groups need no hierarchy change — they
  are the reference implementation.

### Proof: Floki Depth + Scoped Playwright Geometry + Composed-Group Gallery

- **D-07:** GROUP-02 nesting depth ≤2 is proven authoritatively by a **Floki ExUnit ancestor-count
  check** (render the composed group HEEx in-process, count border/shadow surface ancestors within a
  `data-region`, assert ≤2). Floki is already used in `operator/shell_test.exs`, so this adds no
  dependency, runs in the fast `mix test` lane, is Node-free and flake-free. Grep CANNOT count tree
  depth across multiline/composed HEEx — the new grep gate is only a cheap **tripwire** (ban raw
  `p-6` + the same-tone card-in-card class signature), not the depth authority.

- **D-08:** GROUP-03 alignment is proven with Playwright geometry reusing the existing substrate
  (`boundingBox().x`, `assertNoElementHorizontalOverflow`, `PRIMITIVE_VIEWPORTS = [320, 768, 1280]`):
  shared left-edge `boundingBox().x` equality (±1px, integer-rounded) across sibling group cards +
  no-horizontal-overflow at 320 and 1280. Assertions MUST be scoped to `[data-group-card]` **direct
  siblings only** — never a descendant sweep, or legitimately-indented children (timeline rail nodes,
  `border-l-4` clauses) false-fail. Contain known geometry flake with the substrate's existing
  tolerance + font/load settling.

- **D-09:** GROUP-01 coherent-spacing / next-action-obvious is proven with Playwright computed
  padding-floor (rendered padding ≥ the semantic token, also covering GROUP-02 "no flush-to-edge")
  + sibling-x equality. Visual hierarchy is a rendered fact, so it lives in the geometry lane.

- **D-10:** Both render-time proofs target new **composed-group gallery specimens** in
  `gallery_live.ex` — the three groups assembled exactly as `operator_live.ex` / `inbound_live.ex`
  compose them, data-free, with a stable `data-testid`. This closes the "lab renders components in
  isolation but never as the composed group" gap (the milestone's documented "lab-passes-but-ugly"
  trigger). Bind specimen↔reality with one thin live-view smoke assertion; the specimen must call
  the same group-assembling function the live view calls, not a hand-copied tree.

- **D-11:** Verification stays entirely within the locked Phase 113 substrate — ExUnit
  (Floki/component/live), Playwright structural/geometry assertions, `check-conformance.sh` grep
  gates, and committed CSS bundle cleanliness. **No** pixel-diff, screenshot baseline, new asset
  pipeline, or runtime dependency. Zero-Node.

### Scope

- **D-12:** Phase 114 touches exactly: the six group component modules; the `operator_live.ex` /
  `inbound_live.ex` detail-column composition blocks (including the `space-y-4` inter-card rhythm
  those live files own); `components.ex` (new `<.card>` shell); `gallery_live.ex` (composed-group
  specimens); `check-conformance.sh` (SPACE-GATE + GROUP tripwire, extend PRIMITIVE-DRIFT-GATE for
  the shell); `structural.spec.js` (geometry assertions); a new Floki ExUnit test; and the committed
  CSS bundle if a new utility is added. It does NOT touch deliveries/inbound lists, overview/stat-card
  strips, nav/shell, or preview — those carry their own locked gates and belong to Phases 110/112/113.

### Claude's Discretion

- Exact name/signature of the card shell primitive (`card` vs `panel`) and whether it carries an
  optional header slot, provided it stays thin per D-02 and reuses the existing component precedent.
- Exact SPACE-GATE regex and which directories/files it scopes to, provided it bans raw off-grid
  spacing in the group surfaces without false-positives on unrelated `lib/`.
- Exact surface-class set the Floki depth check counts as "elevation" ancestors, co-located with the
  token/elevation definitions.
- Whether the optional 3px status left-rule (D-06) ships, provided hierarchy holds at 320px and wide
  and status is never color-alone.

### Folded Todos

None — `todo.match-phase 114` returned 0 matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 114 goal and success criteria.
- `.planning/REQUIREMENTS.md` — GROUP-01..03 acceptance text and v1.13 scope locks.
- `.planning/PROJECT.md` — v1.13 milestone intent, scope locks, D-23/D-28/D-29, release posture.
- `.planning/STATE.md` — current milestone state and carried decisions from phases 109-113.
- `.planning/METHODOLOGY.md` — decisive-by-default, recommendation-first methodology.
- `.planning/phases/109-foundations-gate-tightening/109-CONTEXT.md` — inherited token, z-layer,
  focus-ring, system-theme, and structural-gate decisions (semantic spacing scale lives here).
- `.planning/phases/110-primitives/110-CONTEXT.md` — public primitive ownership (primitives live
  ONLY in `MailglassAdmin.Components`), PRIMITIVE-DRIFT-GATE, `stat_card`/`status_badge` shape,
  icon-exists guard, target-size gates.
- `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md` — tenant scope, theme,
  nav, pagination decisions (the live-view detail columns sit on this shell).
- `.planning/phases/113-data-display/113-CONTEXT.md` — locked verification substrate (ExUnit +
  Playwright structural + grep gate + committed CSS), no-pixel-diff/zero-Node constraint, data-state
  templates, long-value handling.
- `.planning/research/v1.13/SUMMARY.md` — v1.13 research synthesis.
- `.planning/research/v1.13/ARCHITECTURE.md` — component-lab/gallery and ratchet context.
- `.planning/research/v1.13/PITFALLS.md` — "lab-passes-but-ugly" and the 24 usability defects.
- `.planning/research/v1.13/STACK.md` — zero-Node asset boundary and structural-proof context.
- `brandbook/brand-book.md` — CURRENT brand source of truth: borders-first / `--depth:0` flat,
  surface tones (base-100 page ground / base-200 raised card / base-300 border), `surface-sunken`
  well semantics (lines ~105-112), Alert 3px left-edge recipe (~331-333), no glassmorphism/bevels.
- `brandbook/tokens.css`, `brandbook/tokens.json` — canonical brand tokens.
- `mailglass_admin/lib/mailglass_admin/components.ex` — where `<.card>` lives, alongside
  `stat_card/1`, `filter_section/1`, `data_state/1`, `status_badge/1`, `icon/1`.
- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex` — the box-prison offender
  (inner `bg-base-200` cards at lines ~38, 84, 130).
- `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex` — single non-nested card.
- `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`,
  `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` — detail+timeline group (operator).
- `mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex`,
  `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` — routing-trace+evidence group
  (reference inset implementations).
- `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex`,
  `mailglass_admin/lib/mailglass_admin/inbound/timeline.ex` — detail+timeline group (inbound).
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — operator detail-column composition
  (`motion-reveal space-y-4` wrapper ~line 564; group assembly ~579-593).
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` — inbound detail-column composition
  (wrapper ~476; group assembly ~491-500).
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` — per-component specimens (need composed
  GROUP specimens added); specimen dispatcher + stable `gallery-{component}-{state}` testids.
- `mailglass_admin/assets/css/app.css` — semantic spacing tokens (~107-116, 4px grid xs..3xl),
  surface tones (~31-33 light / 68-71 dark), `shadow-flat`/`shadow-raised` (~131-133).
- `mailglass_admin/scripts/check-conformance.sh` — grep-gate idiom (PRIMITIVE-DRIFT-GATE ~35-78,
  STATCARD-GATE ~133, GAP-GATE ~194) to extend with SPACE-GATE + GROUP tripwire.
- `mailglass_admin/e2e/structural.spec.js` — geometry substrate (`assertNoElementHorizontalOverflow`
  ~496, `boundingBox()` x/width ~857-861, `PRIMITIVE_VIEWPORTS` ~19-23).
- `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` — existing Floki precedent (~141)
  for the new nesting-depth ExUnit check.
- `prompts/phoenix-live-view-best-practices-deep-research.md`,
  `prompts/elixir-opensource-libs-best-practices-deep-research.md` — function-component / card-panel
  idiom and minimal-surface DNA.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `MailglassAdmin.Components` already ships slot/attr primitives (`stat_card/1`, `filter_section/1`,
  `data_state/1`, `status_badge/1`, `icon/1`) — the `<.card>` shell follows this established shape.
- The card shell `card rounded-box border border-base-300 bg-base-200 (p-6|p-md)` is hand-rolled
  across ~8 group surfaces — ripe for single-source extraction.
- Reference inset implementations already do outer `bg-base-200` / inner `bg-base-100`:
  `inbound/evidence_card.ex`, `inbound/routing_trace.ex`, `operator/timeline.ex`, `inbound/timeline.ex`.
- Verification substrate is fully present: Floki (used in `shell_test.exs`), Playwright geometry
  helpers + viewports in `structural.spec.js`, the conformance grep-gate idiom, and the gallery
  specimen dispatcher with stable testids.

### Established Patterns

- Public admin primitives live ONLY in `MailglassAdmin.Components`; page-local/hand-rolled copies
  are drift caught by PRIMITIVE-DRIFT-GATE (Phase 110).
- Spacing is a semantic 4px-grid token scale that doubles as Tailwind utilities; brand elevation is
  borders-first + faint Ink shadow, `--depth:0` flat, no glassmorphism/bevels.
- Surface tones: base-100 = page ground (sunken relative to a card), base-200 = raised card,
  base-300 = border. A `bg-base-100` inset inside a `bg-base-200` card is a genuine elevation step.
- Verification is structural/deterministic: ExUnit (Floki/component/live), Playwright structural
  geometry, conformance grep gates, committed CSS cleanliness — no pixel-diff, zero-Node.

### Integration Points

- `operator_live.ex` / `inbound_live.ex` detail columns (`motion-reveal space-y-4`) compose the
  group modules; the `space-y-4` inter-card rhythm is the one composition-level knob the live files own.
- The new `<.card>` shell plugs into all six group modules; their internal grids/rhythm stay as
  call-site utilities.
- New composed-group gallery specimens host the Floki depth check and Playwright geometry assertions
  against a stable, data-free tree, bound to reality by one live-view smoke assertion.
</code_context>

<specifics>
## Specific Ideas

- Single milestone elevation rule: outer group `bg-base-200` + `shadow-raised`; nested content
  borderless `bg-base-100` sunken inset; never two `bg-base-200` fills in one stack.
- `support_cards.ex` Primary/Secondary emphasis via content weight (display-bold status-colored
  count + one `btn-primary`) and an optional 3px status left-rule (brand Alert recipe), never
  color-alone.
- Card primitive must be thin (shell + `padding` variant only) — explicitly NOT a layout engine.
- Floki ExUnit ancestor-count is the authoritative depth-≤2 proof; grep is only a tripwire.
- Playwright sibling-x alignment must be scoped to `[data-group-card]` direct siblings only.
</specifics>

<deferred>
## Deferred Ideas

- Full whole-surface IA / flows / micro-animation / microcopy → Phase 115 (FLOW-01..04).
- Multi-tenant stress-fixture cohort, full gallery matrix, interaction pillar + axe-JSON baseline,
  `current → prior` re-score → Phase 116 (RATCHET-01..05).
- Any broadening of the SPACE-GATE / token sweep beyond the group surfaces into lists/overviews/shell
  — out of this phase's fractal slice.

### Reviewed Todos (not folded)

None — `todo.match-phase 114` returned 0 matches.
</deferred>
