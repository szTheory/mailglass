# Phase 114: Component Groups - Pattern Map

**Mapped:** 2026-06-20
**Files analyzed:** 14 (1 new component, 1 new test, 8 modified group modules, 2 modified live views, gallery, conformance script, e2e spec)
**Analogs found:** 14 / 14 (every artifact has an in-repo analog; this is a disciplined application of existing patterns, not new construction)

> This phase is a fractal design-system uplift. There is **no net-new domain capability**, so every
> file copies a pattern that already exists in `mailglass_admin`. The planner should reference the
> exact analog excerpts below; do not invent new shapes.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass_admin/components.ex` (`<.card>` shell) | component (primitive) | transform (assigns→HEEx) | `Components.stat_card/1` / `data_state/1` same module | exact (same module, same shape) |
| `test/mailglass_admin/group_nesting_test.exs` | test (unit/Floki) | transform (render→parse→assert) | `operator/shell_test.exs` `current_nav_labels/1` | role+flow match (same Floki API) |
| `operator/support_cards.ex` (box-prison fix) | component (group) | request-response (renders summary) | reference insets: `inbound/evidence_card.ex`, `operator/timeline.ex` | exact (in-repo correct elevation) |
| `operator/suppression_card.ex` | component (group) | request-response | `inbound/evidence_card.ex` shell | exact |
| `operator/detail_header.ex` | component (group) | request-response | `inbound/evidence_card.ex` shell | exact |
| `operator/timeline.ex` | component (group) | request-response | self (already correct inset; sweep only) | exact (reference impl) |
| `inbound/routing_trace.ex` | component (group) | request-response | self (already correct inset; sweep only) | exact (reference impl) |
| `inbound/evidence_card.ex` | component (group) | request-response | self (already correct inset; sweep only) | exact (reference impl) |
| `inbound/detail_header.ex` | component (group) | request-response | `inbound/evidence_card.ex` shell | exact |
| `inbound/timeline.ex` | component (group) | request-response | `operator/timeline.ex` | exact (sibling reference impl) |
| `operator_live.ex` (detail column) | live view (composition) | event-driven render | self ~564-594 (add `data-region`) | exact |
| `inbound_live.ex` (detail column) | live view (composition) | event-driven render | self ~474-501 (add `data-region`) | exact |
| `gallery_live.ex` (3 composed specimens) | live view (gallery) | transform (specimen dispatch) | `render_specimen(%{component: :support_cards})` ~332-382 | exact (same dispatcher) |
| `scripts/check-conformance.sh` (SPACE/GROUP gate) | config (CI lint) | batch (grep) | GAP-GATE ~201, FORM-DRIFT file-scope ~83-116, STATCARD ~133 | exact (same idiom) |
| `e2e/structural.spec.js` (`Group:` block) | test (e2e geometry) | request-response (browser geometry) | `assertNoElementHorizontalOverflow` ~496, `boundingBox` ~857-861 | exact (same substrate) |

## Pattern Assignments

### `lib/mailglass_admin/components.ex` — NEW `<.card>` shell (component, transform)

**Analog:** `Components.stat_card/1` (same module, `components.ex:358-408`) and `Components.data_state/1` (`components.ex:410-449`).

**Imports/declaration pattern** — copy the `attr`/`slot`/`@doc since`/`def` shape of `stat_card/1` exactly. Note `attr :rest, :global, default: %{}` followed by `{@rest}` on the root element — this is how `data-testid`, `data-group-card` flow through (`:global` includes `data-*` by default):
```elixir
# components.ex:358-391 (stat_card head — the shape to mirror)
attr :rest, :global, default: %{}
# ...
@doc since: "1.8.0"
def stat_card(assigns) do
  # ...
  ~H"""
  <article
    id={@id}
    class="min-w-0 rounded-box border border-base-300 bg-base-200 p-md"
    aria-busy={if @state == :loading, do: "true"}
    {@rest}
  >
```

**Recommended `<.card>` shape** (≤20 lines per D-02; one `padding` attr, one `inner_block`; `card_padding/1` helper mirrors `data_state_icon/1` arity-1 dispatch at `components.ex:451-464`):
```elixir
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

**What NOT to copy / anti-pattern (D-02):** Do not add header/footer/grid slots. The `space-y-4` rhythm, `dl` grids, and `<ol>` spacing stay at call sites. `shadow-raised` and `data-group-card` are NOT baked into the shell — passed via `class`/`@rest` at the one call site that needs them (`support_cards` outer section).

**Hand-rolled shell being replaced** (8 surfaces — 7 use literal `p-6`, support_cards uses `p-md`):
```
class="card rounded-box border border-base-300 bg-base-200 p-6"   ← timeline.ex:18, suppression_card.ex:12,
  detail_header.ex:17, inbound/routing_trace.ex:35, inbound/detail_header.ex:32,
  inbound/evidence_card.ex:33, inbound/timeline.ex:20
class="card rounded-box border border-base-300 bg-base-200 p-md"  ← support_cards.ex:22
```
Note the leading DaisyUI `card` class is decorative (no card layout relied on) — per RESEARCH Open Question 2, drop it from the shell; whatever you pick, the GROUP tripwire must match it.

---

### `operator/support_cards.ex` — box-prison fix (component, group) — THE LONE OFFENDER

**Analog (the correct pattern to copy FROM):** `inbound/evidence_card.ex:56-66` borderless `bg-base-100` wells; `operator/timeline.ex:45-48` `min-w-0 flex-1 rounded-box border bg-base-100 p-4` inset.

**The defect** — 3 inner `<article>` cards at `support_cards.ex:38, 84, 130` use the same tone as the outer card (box prison):
```elixir
# support_cards.ex:36-40 (and identical at :82-86, :128-132)
<article
  :if={@support_summary && @support_summary.failed_ingest.count > 0}
  class="card bg-base-200 border border-base-300 rounded-box p-lg"   ← SAME-TONE card-in-card
  data-testid="support-card-failed-ingest-tier1"
>
```

**The fix (D-04/D-05):** demote each inner card to a borderless `bg-base-100` sunken inset (drop `card`, `bg-base-200`, `border border-base-300`); add `shadow-raised` to the outer `<section>` (line 20-23). Optionally layer the brand Alert recipe `border-l-4 border-error`/`border-warning` (D-06) — see `routing_trace.ex:62-65` for the exact left-rule idiom already in-repo:
```elixir
# inbound/routing_trace.ex:62-65 — the border-l-4 status left-rule to copy for D-06
class={[
  "rounded-box",
  verdict.first_failing? && "border-l-4 border-error px-3"
]}
```
Target inner shape (mirrors timeline/evidence insets): `class="rounded-box bg-base-100 p-lg"` (+ optional `border-l-4 border-error` paired with the existing `text-display font-bold text-error` count at `support_cards.ex:41-43` — status never color-alone, WCAG 1.4.1).

**Content-weight emphasis (D-06)** — already present, keep it: the `text-display font-bold text-{error|warning}` count (`support_cards.ex:41, 87, 133`) is the F-pattern "next action" anchor; the single `btn btn-primary px-md mt-sm min-h-11` (`:56, :102, :152`) is the one CTA.

**Token sweep (D-03, ~35 tokens here):** replace `space-y-1` (`:25`), `mt-1` (`:68, 74, 114, 120`), `space-y-2` (`:46, 92, 140`) with semantic tokens (`space-y-sm`, `mt-xs`, etc.). `gap-sm`, `gap-lg`, `gap-md`, `mt-md` already correct.

---

### `operator/suppression_card.ex`, `operator/detail_header.ex`, `inbound/detail_header.ex` — shell swap + sweep (component, group)

**Analog:** the thin-shell call site of any reference module after the swap. These have no nesting issue — only swap the hand-rolled `<article class="card rounded-box border border-base-300 bg-base-200 p-6">` for `<.card padding={:lg} data-testid="..." data-group-card>` and sweep numerics. Confirm `data-testid` survives by passing it through `@rest`.

**Sweep targets** (~8/15/8 tokens): `p-6`→shell `:lg`/`:md`; `mb-4`, `space-y-1`, `px-2 py-1`, `mt-1` → semantic.

---

### `operator/timeline.ex`, `inbound/timeline.ex`, `inbound/routing_trace.ex`, `inbound/evidence_card.ex` — REFERENCE impls (sweep only)

**Analog:** themselves. **Do NOT change the tonal/elevation treatment** — these already do outer `bg-base-200` / inner `bg-base-100` correctly. Only (1) swap the outer `<article ...p-6>` shell for `<.card>` and (2) sweep numeric spacing.

Already-correct insets to preserve verbatim:
```elixir
# operator/timeline.ex:45-48
<div class={[
  "min-w-0 flex-1 rounded-box border bg-base-100 p-4",
  event_container_class(@highlight_event_id, event.id)
]}>
# inbound/routing_trace.ex:49-52
<section data-testid="inbound-route-card"
  class="rounded-box border border-base-300 bg-base-100 p-4">
# inbound/evidence_card.ex:56
<div class="rounded-box border border-base-300 bg-base-100 px-2 py-1">
```
Sweep: `p-4`→`p-md`, `px-2 py-1`→`px-sm py-xs`, `mb-4`→`mb-md`, `mb-3`→`mb-sm`, `space-y-1/2/3/4`→`space-y-xs/sm/...`, `gap-2`→`gap-sm`, `mt-1/mt-2`→`mt-xs/mt-sm`. (`gap-2` is NOT caught by current GAP-GATE — SPACE-GATE closes it.)

---

### `operator_live.ex` / `inbound_live.ex` — detail-column composition (live view)

**Analog:** themselves (`operator_live.ex:562-594`, `inbound_live.ex:474-501`). **Only change:** add `data-region` to the `motion-reveal space-y-4` wrapper div. `space-y-4` is the one live-view-owned inter-card rhythm (D-12) — keep it, it is NOT swept by SPACE-GATE.
```elixir
# operator_live.ex:562-571 — add data-region here (inbound_live.ex:474-482 identical shape)
<div
  id={"delivery-detail-#{@selected_delivery.id}"}
  class="motion-reveal space-y-4"
  data-region               <%!-- NEW: scopes the Floki ancestor-depth assertion --%>
  phx-remove={...}
>
  <DetailHeader.detail_header .../>
  <SupportCards.support_cards .../>   <%!-- each group's outer <.card> carries data-group-card --%>
```
The smoke-test binding (D-10): one ExUnit live-view assertion that the rendered detail column contains `data-region` + the group testids (`operator-support-cards`, `operator-timeline`, etc.).

---

### `gallery_live.ex` — 3 NEW composed-group specimens (live view, transform)

**Analog:** existing `render_specimen/1` dispatcher branches, `gallery_live.ex:332-382`. The composed specimens MUST call the **same group component functions** the live views call (no hand-copied tree, D-10/Pitfall 5):
```elixir
# gallery_live.ex:332-339 — the dispatcher branch shape to mirror
defp render_specimen(%{component: :support_cards} = assigns) do
  ~H"""
  <SupportCards.support_cards
    support_summary={@assigns_map[:support_summary]}
    support_state={@assigns_map[:support_state]}
    suppression_count={@assigns_map[:suppression_count]}
  />
  """
end
```
New composed branches wrap the SAME calls inside a `<div data-region class="space-y-4">` matching the live view's `space-y-4` wrapper, each group rendered through its `<.card ... data-group-card>` shell. Testid convention is `gallery-{component}-{state}` (`gallery_live.ex:109`) — use stable ids like `gallery-composed-support-triage`, `gallery-composed-routing-evidence`, `gallery-composed-detail-timeline`. Per RESEARCH, these are a different shape than per-primitive specimens, so they need their own dispatcher branch (do not force the per-primitive `awk` assertion onto them).

---

### `scripts/check-conformance.sh` — SPACE-GATE + GROUP tripwire + PRIMITIVE-DRIFT extension (config, batch)

**Analog 1 — file-scoped array** (copy FORM-DRIFT's `FILTER_WRAPPERS`, `check-conformance.sh:83-116`). SPACE-GATE MUST scope to an explicit 8-file `GROUP_SURFACES` array, NOT `$LIB` recursive (17 other lib files use the same numerics — Pitfall 1).

**Analog 2 — boundary regex** (copy GAP-GATE's trailing boundary, `check-conformance.sh:201`):
```bash
# GAP-GATE at :201 — the boundary idiom that prevents gap-32/gap-3xl false-positives
if grep -rEn 'gap-(3|4|6)([^0-9a-z-]|$)' "$LIB" --include="*.ex" 2>/dev/null; then
```
SPACE-GATE recommended pattern (from RESEARCH Pitfall 1 — validated word boundaries reject `mt-0.5`, `min-h-11`, `h-3`, `border-l-4`):
```bash
GROUP_SURFACES=( "${LIB}/.../operator/support_cards.ex" ... 8 files ... )
if grep -rEn '(^|[^a-z-])(p[trblxy]?|m[trblxy]?|space-[xy]|gap)-[0-9]+([^0-9.a-z-]|$)' "${GROUP_SURFACES[@]}" 2>/dev/null; then
  echo "FAIL: SPACE-GATE — raw off-grid spacing literal in a group surface ..." >&2
  errors=$((errors + 1))
fi
```

**Analog 3 — same-tone tripwire** (copy STATCARD-GATE's literal-class grep, `check-conformance.sh:133`):
```bash
# GROUP-GATE — ban the same-tone card-in-card signature (Floki owns real depth, D-07)
if grep -En 'card bg-base-200 border border-base-300 rounded-box|bg-base-200 border border-base-300 rounded-box p-lg' "${GROUP_SURFACES[@]}" 2>/dev/null; then
  echo "FAIL: GROUP-GATE — same-tone (bg-base-200) card-in-card signature found ..." >&2
fi
```

**Analog 4 — PRIMITIVE-DRIFT extension** (`check-conformance.sh:53`): add `card` to the public-definition loop so `Components.card/1` is enforced as the single shell source:
```bash
for primitive in nav_link nav_pill tenant_chip theme_picker stat_card card; do
```
Per RESEARCH, do NOT add the per-primitive gallery `awk` dispatcher assertion for `card` (composed specimens are a different shape). **Validate by running the script** (project MEMORY) — confirm it catches a planted `p-6` in a group file and stays green on `preview_live.ex` + `mt-0.5`.

---

### `e2e/structural.spec.js` — `Group:` describe block (test, geometry)

**Analog:** `PRIMITIVE_VIEWPORTS` (`structural.spec.js:19-23`), `assertNoElementHorizontalOverflow` (`:496-501`), `boundingBox()` + `Math.round` (`:857-861`, `:302-307`), and the heading-settle idiom (`openOperator` `:47-56`).

Scope to `[data-group-card]` **direct siblings only** (D-08, Pitfall 4 — never a descendant sweep, or timeline rail/`border-l-4` children false-fail):
```js
const region = page.getByTestId("gallery-composed-support-triage");
const cards = region.locator(":scope > [data-region] > [data-group-card]");
// integer-round x, assert |x - minX| <= 1 across siblings, then:
await assertNoElementHorizontalOverflow(region, `composed-support-triage @${vp}`);
```
Settle before measuring: `await expect(page.getByRole("heading", {name: "Component Gallery", level: 1})).toBeVisible();` (mirrors `:50-52`). Run at 320 and 1280 from `PRIMITIVE_VIEWPORTS`. Add a padding-floor leg (rendered padding ≥ semantic token) for GROUP-01/GROUP-02 no-flush-to-edge.

---

### `test/mailglass_admin/group_nesting_test.exs` — NEW Floki depth test (test, unit)

**Analog:** `operator/shell_test.exs:137-157` — the `Floki.parse_fragment/1` + `Floki.find/2` + `Floki.attribute/2` precedent. Floki 0.38.4 has **no parent API** (Pitfall 3) — count depth top-down via tuple recursion over `{tag, attrs, children}`. Render the composed specimen with `render_component(&GalleryLive.composed_*/1, %{})`, find each `[data-region]` subtree, count nodes carrying any of `~w(bg-base-200 bg-base-100 shadow-raised)`, assert max chain ≤2. (Full recursion example in RESEARCH "Code Examples".)

## Shared Patterns

### Thin presentational primitive (attr/slot/`@doc since`/`:global` rest)
**Source:** `components.ex:358-408` (`stat_card/1`), `:410-449` (`data_state/1`)
**Apply to:** the new `<.card>` shell. Use `attr :rest, :global, default: %{}` + `{@rest}` so call sites pass `data-testid`/`data-group-card`/`shadow-raised` without bloating the primitive.

### Elevation rule — raised outer / sunken inner (D-04)
**Source (correct in-repo):** `inbound/evidence_card.ex:56-66`, `operator/timeline.ex:45-48`, `inbound/routing_trace.ex:49-52`, `inbound/timeline.ex:43`
**Apply to:** every group's nested content. Outer `<.card>` = `bg-base-200` (+ `shadow-raised` only on `support_cards` section); inner = borderless `bg-base-100`. Never two `bg-base-200` fills stacked.

### Status never color-alone (WCAG 1.4.1)
**Source:** `support_cards.ex:41-44` (colored `text-display` count + label), `routing_trace.ex:62-65` (`border-l-4` paired with badge)
**Apply to:** D-06 optional left-rule — always paired with the colored count + label.

### File-scoped grep gate with boundary regex
**Source:** FORM-DRIFT `FILTER_WRAPPERS` (`check-conformance.sh:83-116`), GAP-GATE boundary `([^0-9a-z-]|$)` (`:201`), STATCARD literal-class grep (`:133`)
**Apply to:** SPACE-GATE + GROUP-GATE. Explicit 8-file array, word-boundary anchored, validated by running the script.

### Floki top-down tree walk (no parent API)
**Source:** `operator/shell_test.exs:137-157`
**Apply to:** the depth proof. `parse_fragment` → `find("[data-region]")` → recurse `{tag, attrs, children}`.

### Playwright geometry with integer-rounded tolerance + heading settle
**Source:** `structural.spec.js:19-23, 47-56, 302-307, 496-501, 857-861`
**Apply to:** the `Group:` block. `Math.round(box.x)`, ±1px, scoped to direct siblings, measured after the gallery heading is visible.

## No Analog Found

None. Every Phase 114 artifact has an exact or near-exact in-repo analog — the phase is a disciplined application of existing pieces (shell pattern, elevation tones, spacing tokens, `shadow-raised`, Floki, Playwright geometry, grep-gate idiom), not new construction. The only genuinely net-new bytes are: the `<.card>` function body, three gallery specimen branches, one ExUnit test file, the `data-region`/`data-group-card` attributes, and the SPACE/GROUP shell additions — all modeled above.

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/{,operator/,inbound/}*.ex`, `mailglass_admin/test/mailglass_admin/operator/shell_test.exs`, `mailglass_admin/e2e/structural.spec.js`, `mailglass_admin/scripts/check-conformance.sh`, `mailglass_admin/lib/mailglass_admin/gallery_live.ex`
**Files scanned:** 14 source files + 3 phase dossiers (CONTEXT/RESEARCH/UI-SPEC)
**Pattern extraction date:** 2026-06-20
