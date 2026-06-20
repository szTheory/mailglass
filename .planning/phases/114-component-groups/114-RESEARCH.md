# Phase 114: Component Groups - Research

**Researched:** 2026-06-20
**Domain:** Phoenix function-component design-system uplift (zero-Node admin); structural proof machinery (Floki ExUnit, scoped Playwright geometry, conformance grep gates)
**Confidence:** HIGH — every claim verified against live source this session; all CONTEXT.md canonical refs re-anchored.

## Summary

Phase 114 is a fractal design-system uplift of three composed component groups in `mailglass_admin`. CONTEXT.md already locks all twelve decisions (D-01..D-12) with deep per-area research; the `what` is settled. This research de-risks the `how` for the planner by verifying every line-number anchor against live source, inventorying the real spacing-token sweep, surfacing the SPACE-GATE scoping footgun in concrete terms, and confirming the verification substrate (Floki 0.38.4, Playwright geometry helpers, conformance grep idiom) is fully present and usable as locked.

The single most important de-risking finding: **all the CSS primitives the phase relies on already exist** — `shadow-raised` (app.css:132), the 4px-grid `--spacing-*` tokens (app.css:110-116), and the `base-100`/`base-200`/`base-300` surface tones (app.css:31-33 / 68-70). No new CSS utility is required for D-04/D-05, so the committed-bundle-rebuild step in D-12 is likely a no-op (confirm during execution; if no `@theme`/utility line is added, skip the rebuild). The box-prison fix and elevation rule are pure HEEx class swaps.

The second de-risking finding: the SPACE-GATE **must** be scoped to an explicit eight-file list. Seventeen other `lib/` files use the same numeric spacing tokens (`p-6`, `mt-1`, `space-y-1`, `gap-2`), and `mt-0.5` is legitimately used in shell/preview/components for icon alignment — a repo-wide ban would false-fail massively and a too-greedy regex would catch `mt-0.5`, `h-3`, `min-h-11`, and `border-l-4`. This is exactly the boundary-regex footgun the existing GAP-GATE (WR-04) and SIZE-GATE already document.

**Primary recommendation:** Extract a thin `<.card>` shell into `Components` (≤20 lines, one `padding` attr, one `inner_block`); swap it into the 8 surfaces; sweep the 93 raw off-grid spacing tokens in those 8 files to semantic tokens; fix the 3 `support_cards.ex` inner cards to borderless `bg-base-100` insets + add `shadow-raised` to the outer section; add a file-scoped SPACE-GATE + GROUP tripwire + extend PRIMITIVE-DRIFT-GATE; add a Floki ancestor-depth ExUnit test and scoped `[data-group-card]` Playwright geometry assertions, both targeting three new composed-group gallery specimens that call the live-view group-assembly functions.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Extract a single, deliberately thin card shell primitive (`<.card>`/`<.panel>`) into `MailglassAdmin.Components` and render the group surfaces through it. The shell `card rounded-box border border-base-300 bg-base-200` is currently hand-rolled across ~8 surfaces; leaving 8 copies is non-conformant (Phase 110 PRIMITIVE-DRIFT-GATE). Idiomatic Phoenix, consistent with `stat_card/1`, `filter_section/1`, `data_state/1`.
- **D-02:** The card primitive stays thin — extract ONLY the shell (border + radius + surface + outer padding), exposing one `padding: :md | :lg` attr and one `<:inner_block>`, ≤20 lines. Do NOT absorb inter-card vertical rhythm, detail-header `dl` grids, timeline `<ol>` spacing, or routing-trace nested wells into the primitive — those stay as semantic spacing utilities at call sites.
- **D-03:** Sweep the ~190 raw off-grid spacing tokens (`p-6`, `mt-1`, `space-y-1`, `gap-2`) across the group files with 4px-grid semantic tokens. Add a **SPACE-GATE** in `check-conformance.sh` banning raw numeric padding/margin/`space-y` literals, modeled on GAP-GATE, scoped carefully to avoid false-positives on unrelated `lib/` files (mind the boundary-regex footgun GAP/SIZE gates exhibit).
- **D-04:** Single milestone elevation rule: outer composed group = `bg-base-200` raised card with `shadow-raised`; nested content = borderless `bg-base-100` sunken inset; never two `bg-base-200` fills stacked in one group.
- **D-05:** `support_cards.ex` is the lone offender (3 inner `<article>` `bg-base-200 border border-base-300 rounded-box p-lg` cards = same-tone card-in-card). Fix: demote inner Tier-1 containers to borderless `bg-base-100` sunken inset; give the outer `<section>` `shadow-raised`. Depth becomes section → inset (≤2).
- **D-06:** Primary/Secondary emphasis carried by content weight, not nesting: Tier-1 inset leads with a `text-display font-bold` status-colored count + one `btn btn-primary`; Tier-2 a lighter borderless divider row. Optional 3px status left-rule (`border-l-4 border-error|warning`) — always paired with the colored count + label (WCAG 1.4.1). Other named groups need no hierarchy change.
- **D-07:** GROUP-02 nesting depth ≤2 proven by a **Floki ExUnit ancestor-count check** (render composed group HEEx in-process, count border/shadow surface ancestors within a `data-region`, assert ≤2). Grep is only a cheap tripwire (ban raw `p-6` + same-tone card-in-card signature), not the depth authority.
- **D-08:** GROUP-03 alignment proven with Playwright geometry reusing existing substrate (`boundingBox().x`, `assertNoElementHorizontalOverflow`, `PRIMITIVE_VIEWPORTS = [320, 768, 1280]`): shared left-edge x equality (±1px, integer-rounded) across sibling group cards + no-horizontal-overflow at 320 and 1280. Assertions MUST be scoped to `[data-group-card]` **direct siblings only**.
- **D-09:** GROUP-01 coherent-spacing / next-action-obvious proven with Playwright computed padding-floor (rendered padding ≥ semantic token, covering GROUP-02 "no flush-to-edge") + sibling-x equality.
- **D-10:** Both render-time proofs target new composed-group gallery specimens in `gallery_live.ex` — the three groups assembled exactly as `operator_live.ex` / `inbound_live.ex` compose them, data-free, with stable `data-testid`. Bind specimen↔reality with one thin live-view smoke assertion; specimen must call the same group-assembling function the live view calls, not a hand-copied tree.
- **D-11:** Verification stays entirely within the Phase 113 substrate — ExUnit (Floki/component/live), Playwright structural/geometry, `check-conformance.sh` grep gates, committed CSS bundle cleanliness. No pixel-diff, screenshot baseline, new asset pipeline, or runtime dependency. Zero-Node.
- **D-12:** Phase 114 touches exactly: the six group component modules; the `operator_live.ex` / `inbound_live.ex` detail-column composition blocks (incl. `space-y-4` inter-card rhythm); `components.ex` (new `<.card>` shell); `gallery_live.ex` (composed-group specimens); `check-conformance.sh` (SPACE-GATE + GROUP tripwire, extend PRIMITIVE-DRIFT-GATE); `structural.spec.js` (geometry assertions); a new Floki ExUnit test; and the committed CSS bundle if a new utility is added. Does NOT touch deliveries/inbound lists, overview/stat-card strips, nav/shell, or preview.

### Claude's Discretion
- Exact name/signature of the card shell primitive (`card` vs `panel`) and whether it carries an optional header slot, provided it stays thin per D-02 and reuses existing component precedent.
- Exact SPACE-GATE regex and which directories/files it scopes to, provided it bans raw off-grid spacing in the group surfaces without false-positives on unrelated `lib/`.
- Exact surface-class set the Floki depth check counts as "elevation" ancestors, co-located with the token/elevation definitions.
- Whether the optional 3px status left-rule (D-06) ships, provided hierarchy holds at 320px and wide and status is never color-alone.

### Deferred Ideas (OUT OF SCOPE)
- Full whole-surface IA / flows / micro-animation / microcopy → Phase 115 (FLOW-01..04).
- Multi-tenant stress-fixture cohort, full gallery matrix, interaction pillar + axe-JSON baseline, `current → prior` re-score → Phase 116 (RATCHET-01..05).
- Any broadening of the SPACE-GATE / token sweep beyond the group surfaces into lists/overviews/shell.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GROUP-01 | Composed component groups have coherent, intentional spacing and visual hierarchy that makes the next action obvious | Token sweep (D-03) to the 4px grid + content-weight emphasis (D-06); proven by Playwright padding-floor + sibling-x equality (D-09) on the three composed-group specimens (D-10). The "next action obvious" anchor is the `text-display font-bold` status-colored count + single `btn btn-primary` in `support_cards.ex`. |
| GROUP-02 | Card nesting depth ≤2 (no box prison); content has intentional breathing room (no flush-to-container edges) | Box-prison fix in `support_cards.ex` (D-05) demoting 3 inner cards to borderless `bg-base-100` insets; proven authoritatively by the Floki ancestor-count ExUnit check (D-07) + Playwright padding-floor (no flush-to-edge). Grep tripwire bans `p-6` + same-tone card-in-card. |
| GROUP-03 | Elements align on a consistent x/y grid across each group at narrow and wide widths | Scoped `[data-group-card]` direct-sibling `boundingBox().x` equality (±1px, integer-rounded) + `assertNoElementHorizontalOverflow` at 320 and 1280 (D-08), reusing `PRIMITIVE_VIEWPORTS`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Card shell primitive (`<.card>`) | Frontend (Phoenix function component) | — | Pure presentational atom; lives in `MailglassAdmin.Components` per Phase 110 ownership rule. |
| Composed-group assembly | Frontend (LiveView render) | — | `operator_live.ex` / `inbound_live.ex` own the `space-y-4` inter-card rhythm; group modules own internal layout. |
| Spacing-token discipline enforcement | Build/CI (grep gate) | — | `check-conformance.sh` runs in CI; structural lint, not runtime. |
| Nesting-depth proof | Test (ExUnit/Floki, in-process) | — | Tree-structural; runs in the fast `mix test` lane, Node-free. |
| Alignment/overflow proof | Test (Playwright, browser geometry) | — | Rendered-fact proof requiring a real layout engine; reuses existing e2e substrate. |
| Specimen↔reality binding | Frontend (gallery) + Test (live-view smoke) | — | Gallery hosts data-free specimens; one live-view assertion binds them to production composition. |

## Standard Stack

This is internal design-system work. **No new packages.** Everything is already in `mix.lock` / the e2e toolchain.

### Core (already present — verified)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` (Phoenix.Component) | in-tree | Function-component shell + slot/attr | The module's own precedent (`stat_card`, `filter_section`, `data_state`) [VERIFIED: components.ex] |
| `floki` | 0.38.4 | In-process HTML tree parse for depth proof | Already used in `operator/shell_test.exs` [VERIFIED: mix.lock + shell_test.exs:138] |
| `@playwright/test` | in e2e | Browser geometry (`boundingBox`, viewport) | Existing `structural.spec.js` substrate [VERIFIED: structural.spec.js:1,19-23,496] |

**Installation:** None. No `mix deps.get`, no `npm install`. Zero-Node holds (D-11).

## Architecture Patterns

### System Architecture Diagram

```
                       PRODUCTION RENDER PATH
operator_live.ex (detail column)          inbound_live.ex (detail column)
  <div class="motion-reveal space-y-4">     <div class="motion-reveal space-y-4">
    DetailHeader.detail_header                DetailHeader.detail_header
    SupportCards.support_cards   ◄── box     Timeline.timeline
    OperatorTimeline.timeline        prison  RoutingTrace.routing_trace
    SuppressionCard.suppression_card  fix    EvidenceCard.evidence_card
       │                                         │
       └──────────────┬──────────────────────────┘
                      ▼
        Six group modules each render <.card>  (NEW thin shell, D-01)
          card rounded-box border border-base-300 bg-base-200 (p-md|p-lg)
          + outer <section>/<article> carries data-group-card (NEW, for geometry)
          + composed-group root carries data-region (NEW, for depth proof)
          internal: bg-base-100 borderless insets only (D-04 elevation rule)

                       PROOF PATH (all reference the SAME assembly fns)
  ┌────────────────────────┬─────────────────────────┬──────────────────────┐
  ▼                        ▼                         ▼                      ▼
gallery_live.ex      Floki ExUnit            Playwright              check-conformance.sh
3 NEW composed-      (new test file)         (structural.spec.js)    SPACE-GATE (file-scoped)
group specimens →    parse fragment →        goto gallery →          GROUP tripwire
call live-view       count elevation         [data-group-card]       PRIMITIVE-DRIFT (extended)
group-assembly fns   ancestors per           direct-sibling x ==     (CI lint, no render)
(D-10)               data-region ≤2 (D-07)   + no-overflow (D-08)
       │
       └── one live-view smoke assertion binds specimen ↔ reality
```

### Recommended Project Structure
```
mailglass_admin/
├── lib/mailglass_admin/
│   ├── components.ex                 # NEW <.card> shell (alongside stat_card etc.)
│   ├── operator/
│   │   ├── support_cards.ex          # box-prison fix + <.card> + token sweep
│   │   ├── suppression_card.ex       # <.card> + token sweep
│   │   ├── detail_header.ex          # <.card> + token sweep
│   │   └── timeline.ex               # <.card> + token sweep
│   ├── inbound/
│   │   ├── routing_trace.ex          # <.card> + token sweep
│   │   ├── evidence_card.ex          # <.card> + token sweep
│   │   ├── detail_header.ex          # <.card> + token sweep
│   │   └── timeline.ex               # <.card> + token sweep
│   ├── operator_live.ex              # data-region on detail column; space-y-4 owned here
│   ├── inbound_live.ex               # data-region on detail column
│   └── gallery_live.ex               # 3 NEW composed-group specimens + dispatcher entries
├── scripts/check-conformance.sh      # SPACE-GATE + GROUP tripwire + PRIMITIVE-DRIFT extension
├── e2e/structural.spec.js            # [data-group-card] geometry assertions
└── test/mailglass_admin/             # NEW Floki depth test (e.g. group_nesting_test.exs)
```

### Pattern 1: Thin card shell (D-01/D-02)
**What:** A presentational shell extracting ONLY border + radius + surface + outer padding.
**When to use:** Every one of the 8 group surfaces' outermost `<article>`/`<section>`.
**Example (recommended shape — mirrors `stat_card/1`):**
```elixir
# Source: pattern derived from MailglassAdmin.Components.stat_card/1 (components.ex:358-408)
attr :padding, :atom, values: [:md, :lg], default: :md
attr :rest, :global, default: %{}
slot :inner_block, required: true

@doc since: "1.13.0"
def card(assigns) do
  ~H"""
  <div class={["rounded-box border border-base-300 bg-base-200", card_padding(@padding)]} {@rest}>
    {render_slot(@inner_block)}
  </div>
  """
end

defp card_padding(:md), do: "p-md"
defp card_padding(:lg), do: "p-lg"
```
Notes:
- The current hand-rolled shells use the literal `card rounded-box border border-base-300 bg-base-200 p-6`. The `card` DaisyUI class is decorative here (no DaisyUI card layout is relied on) — dropping it is safe, but keeping it is also fine; pick one and let the GROUP tripwire enforce it. The `p-6` becomes `p-md` (or `p-lg` for the larger surfaces).
- Use a plain `<div>` in the shell and let call sites pass `data-testid`, `data-group-card`, and the semantic tag via `{@rest}` — OR keep the semantic element (`<article>`/`<section>`) at the call site wrapping `<.card>`. The simpler path: shell renders the element and call sites pass `data-testid` through `@rest` (works because `:global` includes data-* by default).
- `shadow-raised` is **not** baked into the shell — only `support_cards.ex`'s outer section needs it (D-05). Pass it via `class` override at that one call site, or add a `raised: boolean` attr if you prefer (still ≤20 lines).

### Pattern 2: Elevation rule (D-04/D-05)
**What:** Outer group = `bg-base-200` + `shadow-raised`; nested = borderless `bg-base-100`.
**Reference implementations already correct** (do NOT change their tonal treatment, only sweep spacing tokens):
- `inbound/evidence_card.ex:56,62,66,78` — inner `rounded-box border border-base-300 bg-base-100 px-2 py-1` wells.
- `inbound/routing_trace.ex:51` — `rounded-box border border-base-300 bg-base-100 p-4` route cards.
- `operator/timeline.ex:46` + `inbound/timeline.ex:43` — `min-w-0 flex-1 rounded-box border bg-base-100 p-4` event cards.

**The lone offender** — `operator/support_cards.ex` inner cards at lines **38, 84, 130**:
```
class="card bg-base-200 border border-base-300 rounded-box p-lg"   ← same-tone card-in-card
```
Fix: change each to a borderless sunken inset, e.g. `class="rounded-box bg-base-100 p-lg"` (drop `border border-base-300` and the `bg-base-200`/`card`), and add `shadow-raised` to the outer `<section>` at line 20-23. Optionally add `border-l-4 border-error`/`border-warning` to the failure/orphan insets (D-06), paired with the existing colored count.

### Anti-Patterns to Avoid
- **Over-slotting the card into a layout engine** (shadcn/GOV.UK footgun, D-02). Resist adding header/footer/grid slots — the inter-card rhythm (`space-y-4`), `dl` grids, and `<ol>` spacing genuinely differ per surface and stay as call-site utilities.
- **Repo-wide SPACE-GATE.** 17 other `lib/` files use the same numeric tokens; a global ban breaks them all (see Pitfall 1).
- **Floki parent-walking.** Floki 0.38.4 has no parent-pointer API. Count depth top-down (see Code Examples).
- **Descendant-sweep geometry.** Asserting x-equality on all descendants false-fails on legitimately-indented children (timeline rail `mt-1`/`mt-2` nodes, `border-l-4` clauses). Scope to `[data-group-card]` direct siblings only (D-08).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Repeated card shell | 8 copies of `card rounded-box border …` | One `<.card>` in Components | Phase 110 PRIMITIVE-DRIFT-GATE treats repeated hand-rolled primitives as drift |
| Spacing scale | Ad-hoc `p-6`/`mt-1` numerics | `--spacing-*` semantic tokens (p-md/gap-md/space-y-sm) | Already defined app.css:110-116; doubles as Tailwind utility |
| Elevation shadow | New CSS shadow utility | `shadow-raised` (app.css:132) | Already exists — bundle rebuild likely a no-op |
| HTML tree depth count | Regex over multiline HEEx | Floki `parse_fragment` + top-down recursion | Grep cannot count tree depth across composed HEEx (D-07) |
| Alignment proof | Pixel-diff / screenshot baseline | Playwright `boundingBox().x` + `Math.round` | Deterministic, Node-free-at-runtime, zero new deps (D-11) |

**Key insight:** Every primitive this phase needs (shell pattern, spacing tokens, shadow, surface tones, Floki, Playwright geometry) already exists in the repo. The phase is a disciplined application of existing pieces, not new construction. The only genuinely net-new artifacts are: the `<.card>` function, three gallery specimens, one ExUnit test file, the `data-region`/`data-group-card` attributes, and the SPACE-GATE/GROUP-tripwire shell additions.

## Common Pitfalls

### Pitfall 1: SPACE-GATE boundary-regex false-positives (the documented footgun)
**What goes wrong:** A naive `grep -rEn 'p-[0-9]|mt-[0-9]|space-y-[0-9]|gap-[0-9]' "$LIB"` either (a) fires on 17 out-of-scope files, or (b) wrongly catches legitimate non-spacing tokens.
**Why it happens:** Verified facts this session —
- `mt-0.5` is used legitimately for icon baseline alignment in `components.ex:652`, `preview_live.ex:370/381/451`, `operator/shell.ex:300/308/326/377`. A `mt-[0-9]` pattern without a fractional guard catches `mt-0.5`.
- Sizing tokens look numeric: `min-h-11` (63 uses), `h-3`/`w-3` (8 uses), `border-l-4` (5 uses), `w-px`, `h-full`. These are NOT spacing and must never trip the gate.
- 17 `lib/` files contain `p-6`/`mt-1`/`space-y-1`/`gap-2` (preview_live, sidebar, replay_modal×2, overview, assigns_form, etc.) — all OUT of this phase's slice (D-12).
**How to avoid:**
1. **Scope to an explicit eight-file array** (like FORM-DRIFT-GATE's `FILTER_WRAPPERS` and STATCARD-GATE's named files), NOT `$LIB` recursively.
2. **Anchor with word boundaries** so fractional and sizing tokens can't match. Recommended pattern, modeled on GAP-GATE's `([^0-9a-z-]|$)` boundary (check-conformance.sh:201):
   ```bash
   GROUP_SURFACES=(
     "${LIB}/mailglass_admin/operator/support_cards.ex"
     "${LIB}/mailglass_admin/operator/suppression_card.ex"
     "${LIB}/mailglass_admin/operator/detail_header.ex"
     "${LIB}/mailglass_admin/operator/timeline.ex"
     "${LIB}/mailglass_admin/inbound/routing_trace.ex"
     "${LIB}/mailglass_admin/inbound/evidence_card.ex"
     "${LIB}/mailglass_admin/inbound/detail_header.ex"
     "${LIB}/mailglass_admin/inbound/timeline.ex"
   )
   # Ban raw off-grid padding/margin/space-y/gap numerics. Word-boundary BEFORE the
   # prefix prevents min-h-11/border-l-4/h-3 from matching; the (\.| ...) guard and the
   # [0-9] after the dash with a trailing [^0-9.] boundary excludes mt-0.5 (the dot fails
   # the trailing boundary) while still catching mt-1, p-6, space-y-1, gap-2.
   if grep -rEn '(^|[^a-z-])(p[trblxy]?|m[trblxy]?|space-[xy]|gap)-[0-9]+([^0-9.a-z-]|$)' "${GROUP_SURFACES[@]}" 2>/dev/null; then
     echo "FAIL: SPACE-GATE — raw off-grid spacing literal in a group surface (use xs..3xl / p-md/p-lg / gap-md / space-y-sm)" >&2
     errors=$((errors + 1))
   fi
   ```
   The trailing `[^0-9.a-z-]|$` boundary: rejects `mt-0.5` (next char is `.`), `gap-32`/`gap-3xl` (next char is digit/letter), and lets `mt-1"` / `p-6 ` / `space-y-1"` through. The leading `(^|[^a-z-])` prevents `min-h-11` and `border-l-4` from matching the `h-11`/`l-4` tail.
**Warning signs:** The gate fails on a file not in `GROUP_SURFACES`, or fails on a line containing only `mt-0.5`/`min-h-11`/`h-3`/`border-l-4`. **Validate per MEMORY:** run `bash scripts/check-conformance.sh` after editing — do not trust the regex by inspection. Confirm it (a) catches a deliberately re-introduced `p-6` in a group file and (b) stays green on `preview_live.ex`.

### Pitfall 2: Sweep count expectation mismatch (D-03 "~190")
**What goes wrong:** Planner sizes the sweep at 190 tokens and the executor finds fewer, or vice versa.
**Why it happens:** Verified inventory this session of the 8 group surfaces = **93** raw off-grid spacing tokens (padding/margin/space-y/gap numerics). The "~190" figure in CONTEXT/discussion likely also counted the two live-view detail blocks (17 each = +34) and/or broader token families (sizing `h-`/`w-`, arbitrary brackets). Per-token breakdown of the 93 in the 8 group files:
```
mt-1: 22   space-y-1: 11   py-1: 7   px-2: 7   p-6: 7   mb-4: 7   gap-2: 6
space-y-2: 5   space-y-4: 3   p-4: 3   p-3: 3   space-y-3: 2   pt-4: 2
mt-6: 2   mt-2: 2   px-4: 1   px-3: 1   mt-4: 1   mb-3: 1
```
**How to avoid:** Plan the sweep at "~90 spacing tokens across 8 group module files" as the authoritative scope. The `space-y-4` inter-card rhythm in the two live views (D-12 explicitly names it) is the one live-view-owned token and is separate. Note `gap-2` (6 uses) is currently NOT caught by GAP-GATE (which only bans gap-3/4/6) — the new SPACE-GATE closes that hole.
**Warning signs:** A post-sweep `grep` in the 8 files still returns spacing numerics → sweep incomplete.

### Pitfall 3: Floki has no parent API (D-07)
**What goes wrong:** Executor reaches for `Floki.parent/1` or an ancestor helper that doesn't exist in 0.38.4.
**Why it happens:** Floki models HTML as nested `{tag, attrs, children}` tuples with no upward pointers. Verified helpers in use: `parse_fragment`, `find`, `attribute`, `text`, `children`.
**How to avoid:** Count depth top-down. Parse the rendered group fragment, locate the `data-region` subtree, then recurse counting how many nested "elevation surface" nodes appear along any root-to-leaf path; assert the max ≤2 (see Code Examples).
**Warning signs:** `UndefinedFunctionError` for `Floki.parent`.

### Pitfall 4: Geometry flake at narrow widths (D-08)
**What goes wrong:** `boundingBox().x` differs by sub-pixel between siblings, or a transient pre-font-load measurement.
**Why it happens:** Fractional layout rounding; measuring before the page settles.
**How to avoid:** The substrate already integer-rounds with `Math.round(box.width)` (structural.spec.js:306) and measures after `page.goto` + a visible-heading `expect` (the existing `openOperator`/`openInbound` settling idiom, structural.spec.js:47-56). Apply `Math.round(box.x)` and assert equality with a ±1 tolerance: `expect(Math.abs(Math.round(a.x) - Math.round(b.x))).toBeLessThanOrEqual(1)`. Reuse `assertNoElementHorizontalOverflow` (line 496, already tolerates ≤1px) for the overflow leg at 320 and 1280.
**Warning signs:** Intermittent 1-2px x deltas → ensure measurement happens after the gallery route's heading is visible.

### Pitfall 5: Specimen drifts from reality (D-10)
**What goes wrong:** A hand-copied HEEx tree in the gallery specimen diverges from the live view's actual composition, so the proof passes on a lie.
**Why it happens:** Copy-paste instead of calling the real assembly.
**How to avoid:** The specimen must call the **same group component functions** the live view calls (`DetailHeader.detail_header`, `SupportCards.support_cards`, `OperatorTimeline.timeline`, `SuppressionCard.suppression_card`, etc.) inside the same `data-region` + `space-y-4` wrapper. The existing per-component specimens already do this (gallery_live.ex:332-382). Add one live-view smoke ExUnit assertion that the production detail column renders the `data-region` + the group testids, binding specimen structure to production. Consider extracting the detail-column inner assembly into a shared private function both `operator_live.ex` and the specimen call — but only if it stays within D-12's named files; otherwise keep the specimen as a faithful re-assembly and lean on the smoke test for the binding.

## Code Examples

### Floki ancestor-depth proof (D-07)
```elixir
# Source: pattern built on Floki precedent in operator/shell_test.exs:137-144 (Floki 0.38.4)
# Counts the deepest chain of "elevation surface" nodes within each data-region subtree.
# Co-locate @elevation_classes near where you document the elevation rule (a module attr in
# the test, or — per CONTEXT discretion — alongside the token/elevation definitions).

@elevation_classes ~w(bg-base-200 bg-base-100 shadow-raised)

defp max_elevation_depth(html) do
  {:ok, doc} = Floki.parse_fragment(html)

  doc
  |> Floki.find("[data-region]")
  |> Enum.map(&deepest_chain/1)
  |> Enum.max(fn -> 0 end)
end

# Recurse the tuple tree; increment when a node is an elevation surface.
defp deepest_chain({_tag, attrs, children}) do
  bump = if elevation?(attrs), do: 1, else: 0
  child_max =
    children
    |> Enum.filter(&is_tuple/1)
    |> Enum.map(&deepest_chain/1)
    |> Enum.max(fn -> 0 end)

  bump + child_max
end

defp deepest_chain(_text_node), do: 0

defp elevation?(attrs) do
  class = attrs |> List.keyfind("class", 0, {"class", ""}) |> elem(1)
  Enum.any?(@elevation_classes, &String.contains?(class, &1))
end

test "support-cards composed group nests at most 2 elevation surfaces" do
  html = render_component(&MailglassAdmin.GalleryLive.composed_support_triage/1, %{})
  assert max_elevation_depth(html) <= 2
end
```
Decision for the discretion item (which classes count as elevation): the outer raised card is identified by `shadow-raised` (or `bg-base-200`), and a sunken inset by `bg-base-100`. Counting any of `bg-base-200 | bg-base-100 | shadow-raised` as one elevation step gives section(`bg-base-200`+`shadow-raised`→counts once per node) → inset(`bg-base-100`) = depth 2. **Recommendation:** count a node once if it carries ANY elevation class (so the outer node with both `bg-base-200` and `shadow-raised` is depth 1, not 2). The example above does exactly this.

### Scoped Playwright sibling-x equality (D-08/D-09)
```js
// Source: pattern on structural.spec.js boundingBox + Math.round (lines 302-307, 857-861)
test("Group: composed-group cards share a left edge at 320 and 1280", async ({ page }) => {
  for (const vp of [320, 1280]) {
    await page.setViewportSize({ width: vp, height: 900 });
    await page.goto("/dev/mail/gallery");
    await expect(page.getByRole("heading", { name: "Component Gallery", level: 1 })).toBeVisible();

    const region = page.getByTestId("gallery-composed-support-triage");
    // DIRECT siblings only — never a descendant sweep (timeline rail / border-l-4 children).
    const cards = region.locator(":scope > [data-region] > [data-group-card]");
    const count = await cards.count();
    expect(count).toBeGreaterThan(1);

    const xs = [];
    for (let i = 0; i < count; i++) {
      const box = await cards.nth(i).boundingBox();
      expect(box).not.toBeNull();
      xs.push(Math.round(box.x));
    }
    const minX = Math.min(...xs);
    for (const x of xs) {
      expect(Math.abs(x - minX), `card left-edge x at ${vp}px`).toBeLessThanOrEqual(1);
    }
    await assertNoElementHorizontalOverflow(region, `composed-support-triage @${vp}`);
  }
});
```
The `:scope > [data-region] > [data-group-card]` chain is the literal "direct siblings only" scoping CONTEXT D-08 requires — adjust the intermediate selector to match wherever you place `data-region` (the detail-column wrapper) and `data-group-card` (each group's outer shell).

### Extending PRIMITIVE-DRIFT-GATE + GROUP tripwire (check-conformance.sh)
```bash
# 1. Add `card` to the public-definition loop (currently line 53):
for primitive in nav_link nav_pill tenant_chip theme_picker stat_card card; do ...

# 2. GROUP tripwire — cheap signal, NOT the depth authority (Floki owns depth, D-07).
#    Ban the same-tone card-in-card signature + raw p-6 in the group surfaces.
if grep -En 'card bg-base-200 border border-base-300 rounded-box|bg-base-200 border border-base-300 rounded-box p-lg' "${GROUP_SURFACES[@]}" 2>/dev/null; then
  echo "FAIL: GROUP-GATE — same-tone (bg-base-200) card-in-card signature found; nested content must be borderless bg-base-100 inset" >&2
  errors=$((errors + 1))
fi
```
Note: the `card` public-def loop also asserts the GalleryLive dispatcher calls `Components.card` — only add the dispatcher `awk` check if you register `card` as a normal gallery specimen. The three composed-group specimens are a different shape (they assemble multiple components), so they may need their own dispatcher branch or a relaxed check; mirror the existing `support_cards`/`timeline` dispatcher entries (gallery_live.ex:332-355) rather than the per-primitive `awk` assertion.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-rolled `card rounded-box …` shell ×8 | Single `<.card>` primitive | This phase (D-01) | Removes drift surface; PRIMITIVE-DRIFT-GATE covers it |
| Raw numeric spacing (`p-6`, `mt-1`) | Semantic 4px-grid tokens | This phase (D-03) | Coherent rhythm; SPACE-GATE locks it |
| `support_cards` same-tone card-in-card | Raised section / sunken `bg-base-100` inset | This phase (D-05) | Eliminates box prison; depth ≤2 |
| GAP-GATE bans only gap-3/4/6 | SPACE-GATE additionally bans gap-2 + all off-grid p/m/space-y | This phase | Closes the `gap-2` (6 uses) hole |

**Deprecated/outdated:** None relevant — all referenced tokens/utilities are current.

## Runtime State Inventory

Not applicable — this is a greenfield-within-existing-code design-system phase touching only HEEx classes, a new function component, gallery specimens, a test, and a CI script. No stored data, live service config, OS-registered state, secrets, or build artifacts carry semantics that this phase renames or migrates. The only build artifact is the committed CSS bundle, and per the app.css verification it likely needs **no** rebuild (no new utility added; `shadow-raised` and `--spacing-*` already exist). If the executor adds any new `@theme` line or `@utility`, rebuild and commit per the `priv/static` rule (CLAUDE.md "Things Not To Do" #6).

## Common Pitfalls (verification-step checklist for the planner)

- [ ] SPACE-GATE scoped to the 8-file `GROUP_SURFACES` array, NOT `$LIB` recursive.
- [ ] SPACE-GATE regex validated by running the script (catches a planted `p-6`, stays green on `preview_live.ex` + on `mt-0.5`/`min-h-11`/`h-3`/`border-l-4`).
- [ ] `support_cards.ex` lines 38/84/130 inner cards demoted to borderless `bg-base-100`; outer section gets `shadow-raised`.
- [ ] Floki depth test uses top-down recursion (no `Floki.parent`).
- [ ] Playwright assertion scoped to `[data-group-card]` direct siblings; integer-rounded ±1px; measured after heading visible.
- [ ] Three composed-group specimens call the real group component functions (no hand-copied trees).
- [ ] One live-view smoke assertion binds specimen `data-region`/testids to production.
- [ ] Committed CSS bundle: rebuild ONLY if a new utility/`@theme` line was added; else confirm no diff.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix + Phoenix | `<.card>`, Floki test | ✓ (project toolchain) | in-tree | — |
| `floki` | depth proof | ✓ | 0.38.4 | — |
| Playwright + browser server | geometry proof | ✓ (e2e lane) | in `e2e/` | — |
| Node toolchain (asset build) | only if new CSS utility added | n/a by design | — | Zero-Node: bundle likely unchanged; no new utility needed |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None — zero-Node holds because `shadow-raised` and `--spacing-*` already exist (app.css:110-116,132), so no asset rebuild is anticipated.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (in-tree) + Floki 0.38.4 + Playwright (`e2e/`) |
| Config file | `mailglass_admin/test/` (ExUnit); `mailglass_admin/e2e/` (Playwright) |
| Quick run command | `cd mailglass_admin && mix test test/mailglass_admin/<new-depth-test>.exs` |
| Full suite command | `cd mailglass_admin && mix test` + `bash scripts/check-conformance.sh` + e2e structural run |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GROUP-01 | Coherent spacing, next-action obvious | e2e geometry (padding-floor + sibling-x) | `npx playwright test e2e/structural.spec.js -g "Group"` | ❌ Wave 0 (add assertions) |
| GROUP-01 | Token discipline | grep gate | `bash scripts/check-conformance.sh` | ✅ extend (SPACE-GATE) |
| GROUP-02 | Nesting depth ≤2 | unit (Floki) | `mix test test/mailglass_admin/group_nesting_test.exs` | ❌ Wave 0 (new file) |
| GROUP-02 | No flush-to-edge | e2e geometry (padding-floor) | `npx playwright test e2e/structural.spec.js -g "Group"` | ❌ Wave 0 |
| GROUP-02 | Box-prison tripwire | grep gate | `bash scripts/check-conformance.sh` | ✅ extend (GROUP-GATE) |
| GROUP-03 | x/y grid alignment at 320/1280 | e2e geometry (sibling-x + overflow) | `npx playwright test e2e/structural.spec.js -g "Group"` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bash scripts/check-conformance.sh` (fast, deterministic) + the new Floki test.
- **Per wave merge:** full `mix test` (admin) + e2e structural lane.
- **Phase gate:** all three green before `/gsd-verify-work`. Per MEMORY: bare `mix test` has ~57 unrelated Oban failures in worktrees and a known `voice_test` dep-JS "Oops" false-positive — scope to the named files; do not weaken those tests.

### Wave 0 Gaps
- [ ] `test/mailglass_admin/group_nesting_test.exs` — Floki ancestor-depth proof (GROUP-02)
- [ ] `e2e/structural.spec.js` — new `Group:` describe block with sibling-x + padding-floor + overflow (GROUP-01/03)
- [ ] `gallery_live.ex` — three composed-group specimens + dispatcher entries + `data-region`/`data-group-card` attributes
- [ ] `scripts/check-conformance.sh` — SPACE-GATE + GROUP-GATE + `card` in PRIMITIVE-DRIFT loop
- [ ] one live-view smoke assertion (in an existing or new live-view test) binding specimen↔reality

## Security Domain

Not applicable in the threat-modeling sense — this phase renders no new data, adds no input handling, auth surface, crypto, or storage. PII discipline is unchanged: `routing_trace.ex` and the inbound `detail_header.ex` already mask via `Components.mask_recipient/1` and this phase only changes their spacing/elevation classes, not their data paths. ASVS V5 (input validation) and V6 (crypto) are out of scope for a CSS-class + test phase. The relevant locked floor is brand/accessibility: status must never be color-alone (WCAG 1.4.1) — D-06's left-rule must always pair with the colored count + label.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The "~190" token figure in D-03 conflates group modules (93) + live views (34) + broader families; the authoritative group-surface sweep is ~93 tokens in 8 files | Pitfall 2 | Low — sweep is scoped by file list (D-12), not by a count; the count is informational |
| A2 | No new CSS utility is needed (shadow-raised + spacing tokens exist), so the committed-bundle rebuild in D-12 is a no-op | Summary / Runtime State | Low — verified app.css:110-116,132; if executor adds a left-rule utility class it would rebuild, but `border-l-4`/`border-error` are stock Tailwind/DaisyUI, not new utilities |

**Note:** Both assumptions are low-risk and self-correcting at execution (the file-scoped plan and the `git diff --exit-code` bundle check catch any deviation). All other claims are [VERIFIED] against live source.

## Open Questions

1. **Where exactly do `data-region` and `data-group-card` attach?**
   - What we know: `data-region` belongs on the composed-group root (the `motion-reveal space-y-4` detail-column wrapper, operator_live.ex:564 / inbound_live.ex:476, and the gallery specimen's equivalent). `data-group-card` belongs on each group module's outermost shell element.
   - What's unclear: whether the shell `<.card>` emits `data-group-card` itself (via `@rest`) or each call site adds it. Both work.
   - Recommendation: add `data-group-card` at each call site through `@rest` for explicitness; add `data-region` on the detail-column wrapper in the two live views + the three specimens. This keeps the `<.card>` primitive generic (it shouldn't assume it's always a group card).

2. **Does the `card` DaisyUI class stay or go from the shell?**
   - What we know: the current literal includes a leading `card` DaisyUI class that isn't relied on for layout (the surfaces use flex/grid utilities directly).
   - Recommendation: drop `card` from the new `<.card>` shell for cleanliness, but it's cosmetic — let the GROUP/PRIMITIVE-DRIFT signature you choose dictate it. Whichever you pick, make the tripwire match it.

## Sources

### Primary (HIGH confidence — verified live this session)
- `mailglass_admin/lib/mailglass_admin/components.ex` — `stat_card/1` (358-408), `filter_section/1` (506-516), `data_state/1` (431-449), `mt-0.5` at 652; `<.card>` precedent shape.
- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex` — box-prison inner cards at lines 38, 84, 130 (`card bg-base-200 border border-base-300 rounded-box p-lg`); outer section 20-23; `space-y-1`/`mt-1` etc.
- `mailglass_admin/lib/mailglass_admin/operator/{suppression_card,detail_header,timeline}.ex`, `inbound/{routing_trace,evidence_card,detail_header,timeline}.ex` — all 8 shells use `card rounded-box border border-base-300 bg-base-200 p-6`; reference insets use `bg-base-100`.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex:564-593` / `inbound_live.ex:476-501` — `motion-reveal space-y-4` detail-column composition.
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex:1-160,332-382` — specimen dispatcher + stable `gallery-{component}-{state}` testids; existing per-component group specimens.
- `mailglass_admin/scripts/check-conformance.sh` — PRIMITIVE-DRIFT-GATE (35-78), STATCARD-GATE (118-136), GAP-GATE (194-204, boundary footgun WR-04), SIZE-GATE (311-317), FORM-DRIFT file-scoping precedent (83-116).
- `mailglass_admin/test/mailglass_admin/operator/shell_test.exs:137-157` — Floki `parse_fragment`/`find`/`attribute`/`text` precedent.
- `mailglass_admin/e2e/structural.spec.js:19-23` (PRIMITIVE_VIEWPORTS), 47-56 (settling idiom), 302-307 (`Math.round`), 496-501 (`assertNoElementHorizontalOverflow`), 857-861 (`boundingBox`).
- `mailglass_admin/assets/css/app.css:31-33,68-70` (surface tones), 110-116 (`--spacing-*` 4px grid), 132 (`--shadow-raised`).
- `mailglass_admin/mix.lock` — floki 0.38.4.
- Tool inventory: 93 off-grid spacing tokens across 8 group files (per-token breakdown verified); 17 other `lib/` files use the same numerics (scope risk); `data-region`/`data-group-card` do not yet exist.

### Secondary / Tertiary
- None — all findings verified against repo source; no external/web research needed (internal design-system work).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all deps present and verified in mix.lock / e2e.
- Architecture/patterns: HIGH — CONTEXT decisions confirmed against live source; shell shape mirrors verified existing primitives.
- Pitfalls: HIGH — SPACE-GATE footgun, Floki parent-API absence, and geometry-flake idiom all verified by direct inspection + the documented WR-04 GAP-GATE precedent.
- Line-number anchors: HIGH — all CONTEXT `<canonical_refs>` re-anchored; minor drift noted (support_cards inner cards at 38/84/130 per current source vs "~38/84/130" in CONTEXT — match; live-view wrappers at 564/476 — match).

**Research date:** 2026-06-20
**Valid until:** 2026-07-20 (stable internal codebase; re-verify line anchors if the 8 group files change before planning).
