# Phase 113: Data-Display - Pattern Map

**Mapped:** 2026-06-19
**Files analyzed:** 8 (2 primary list modules + components + 2 LiveViews + gallery + structural spec + 3 test/gate surfaces)
**Analogs found:** 8 / 8 (every file is a MODIFY of an existing module — zero greenfield files)

> Phase 113 is a presentation-contract phase, not a data-layer phase. Every target file already
> exists. The dominant pattern is **extend in place**, not create. Page-local duplicate stat/status/
> mask primitives are treated as drift by `check-conformance.sh` — route everything through
> `MailglassAdmin.Components`. The one optional new public function is `Components.data_state/1`,
> and only if ≥2 surfaces share the identical four-state taxonomy (D-05 / UI-SPEC Public ownership).

---

## File Classification

| Target File (all MODIFY) | Role | Data Flow | Closest Analog | Match Quality |
|--------------------------|------|-----------|----------------|---------------|
| `lib/mailglass_admin/operator/deliveries_list.ex` | component (list) | request-response / read-render | itself (current list-only markup) + `inbound/records_list.ex` | exact (self) |
| `lib/mailglass_admin/inbound/records_list.ex` | component (list) | request-response / read-render | itself + `operator/deliveries_list.ex` (declared sibling clone) | exact (self) |
| `lib/mailglass_admin/components.ex` | component (shared primitives) | transform (atom→icon/label/class) | existing `stat_card/1`, `status_badge/1`, `filter_field/1` (new helper apes these attr/private-helper conventions) | exact (self) |
| `lib/mailglass_admin/operator_live.ex` | live (page integration) | request-response | itself (`DeliveriesList.deliveries_list/1` + `stat_card` call sites) | exact (self) |
| `lib/mailglass_admin/inbound_live.ex` | live (page integration) | request-response | itself + `operator_live.ex` | exact (self) |
| `lib/mailglass_admin/gallery_live.ex` | live (component lab) | read-render | itself (`render_specimen/1` dispatcher + `@specimens` list) | exact (self) |
| `e2e/structural.spec.js` | test (browser structural) | event-driven (Playwright) | itself (`assertNoElementHorizontalOverflow`, `assertStatCardShape`, gallery theme-wrapper helpers) | exact (self) |
| `test/mailglass_admin/{components,operator_live,inbound_live}_test.exs` | test (ExUnit) | request-response | itself (`render_component/2` + `element(...)|> render()` patterns) | exact (self) |
| `scripts/check-conformance.sh` | config (drift gate) | batch grep | itself (STATCARD-GATE / PRIMITIVE-DRIFT-GATE / FORM-DRIFT-GATE) | exact (self) |

**Read-model field sets the lists render (verified):**
- Deliveries projection (`lib/mailglass/operator/deliveries.ex`): `id, tenant_id, recipient, provider, provider_message_id, status, last_event_type, last_event_at`
- Inbound records projection (`mailglass_inbound/.../internal/operator/records.ex`): `id, tenant_id, provider, provider_message_id, envelope_recipient, received_at, outcome, mailbox` (outcome/mailbox may be absent — `record_outcome/1` and `matched_mailbox_label/1` read defensively)

---

## Pattern Assignments

### `lib/mailglass_admin/operator/deliveries_list.ex` (component, request-response)

**Analog:** itself — upgrade the current `<ul>`-of-buttons into dual table + cards from the same `@deliveries`.

**Imports / module shape pattern** (lines 1-19) — keep verbatim, do not add deps:
```elixir
defmodule MailglassAdmin.Operator.DeliveriesList do
  use Phoenix.Component
  alias MailglassAdmin.Components

  attr(:deliveries, :list, required: true)
  attr(:page_meta, :map, default: %{total_count: 0, total_pages: 0, has_previous?: false, has_next?: false})
  attr(:previous_page_path, :string, default: nil)
  attr(:next_page_path, :string, default: nil)
  attr(:selected_delivery, :map, default: nil)
  attr(:filters_active?, :boolean, default: false)
```

**Result-count header pattern — ALWAYS visible, never faked from list length** (lines 23-28). Keep this block above both presentations:
```elixir
<div data-testid="operator-result-count" class="border-b border-base-300 px-4 py-3 text-body text-secondary">
  {result_count_label(@page_meta)}
</div>
```
`result_count_label/1` (lines 168-173) reads `@page_meta.total_count` only — D-02 forbids deriving count from `length(@deliveries)`.

**Selection semantics that BOTH new presentations must carry** (lines 62-73) — this is the contract that must not drift between table `<tr>` and card `<button>`:
```elixir
data-testid="operator-delivery-row"
data-selected={if selected?(@selected_delivery, delivery), do: "true", else: "false"}
phx-click="select_delivery"
phx-value-id={delivery.id}
aria-current={if selected?(@selected_delivery, delivery), do: "true", else: "false"}
aria-selected={if selected?(@selected_delivery, delivery), do: "true", else: "false"}
class={["mg-focus-ring-inset flex min-h-11 ...", row_classes(@selected_delivery, delivery)]}
```
`row_classes/2` (lines 178-182) encodes the non-color selected cue: `border-l-4 border-primary` (selected) vs `border-l-4 border-transparent` (unselected) + a `bg-` shift. Reuse this exact border-width-change cue in the card and as `border-l`/border-top accent in the table row (UI-SPEC "Selected row/card contract").

**Status / mask / long-value rendering — already routes through `Components`** (lines 77-92). Carry these into table cells and card fields per the UI-SPEC long-value table:
```elixir
<Components.status_badge status={delivery.status} size={:sm} />        # status: icon+label+color
{Components.mask_recipient(delivery.recipient)}                         # PII mask — NEVER raw recipient
<p class="mono mt-1 text-label text-secondary">{delivery.id}</p>       # add min-w-0 truncate + title={delivery.id}
<span class="mono">{format_datetime(delivery.last_event_at)}</span>    # add whitespace-nowrap + title
```
`format_datetime(nil)` → `"Pending"`, `label(nil)` → `"Unknown"` (lines 184-196) — these are the meaningful text states the UI-SPEC requires (no bare dash).

**New testids to add (UI-SPEC Data-Display Patterns Contract):** `operator-deliveries-table` (wrapper `hidden md:block`), `operator-deliveries-cards` (wrapper `md:hidden`). Current `operator-deliveries-list` / `operator-deliveries-list-card` testids are referenced by `operator_live.ex` and `structural.spec.js` — preserve or migrate them deliberately (see "Cross-file coupling" below).

**Pagination pattern** (lines 111-166) — `pagination_controls/1` renders chrome only when `total_pages > 1`, disabled boundary links get a `-disabled` testid suffix + `aria-disabled="true"`. Leave unchanged; it sits below both presentations.

---

### `lib/mailglass_admin/inbound/records_list.ex` (component, request-response)

**Analog:** `operator/deliveries_list.ex` — the moduledoc (lines 5-10) declares it a "sibling … clone, not a refactor." Apply the identical table+card upgrade with inbound nouns.

**Differences from the deliveries analog the planner must preserve:**
```elixir
# Outcome (not status) is read defensively + normalized before the badge:
<Components.status_badge
  status={Components.normalize_inbound_outcome(record_outcome(record))}  # :accept→:accepted etc (lines 197-200, components 797-800)
  size={:sm}
/>
{Components.mask_recipient(record.envelope_recipient)}   # envelope_recipient, not recipient
{matched_mailbox_label(record)}                          # "no match" fallback (lines 202-207)
{format_datetime(record.received_at)}                    # received_at, not last_event_at
```

**Empty-state branch already has the seed taxonomy** (lines 26-29, 39-54, 178-190). The `empty_state` atom `[:no_tenant, :truly_empty, :filtered]` plus `empty_heading/1` + `empty_body/1` are the no-data variants D-05 says can seed the four-template set. The planner adds `:error`, `:permission_denied`, `:stale` as DISTINCT templates — they must NOT collapse into these.

**Inbound column order (UI-SPEC):** Outcome → Mailbox → Tenant → Provider → Received timestamp. Card field order: Outcome badge (first) → Mailbox → Tenant → Provider → Received.

**New testids:** `inbound-records-table`, `inbound-records-cards`. Per-badge testid `inbound-outcome-{outcome}` (UI-SPEC DATA-04). Note `structural.spec.js noMatchRow()` (line 549) filters `inbound-record-row` by `.badge-warning` "No match" — keep `inbound-record-row` reachable on both presentations or update that helper.

---

### `lib/mailglass_admin/components.ex` (shared primitives)

**Analog:** existing `stat_card/1`, `status_badge/1`, `filter_field/1` — any new `data_state/1` clones their `attr` + private-helper-clause style.

**`stat_card/1` REAL signature (lines 358-408)** — the planner and UI-SPEC must use THESE values; the UI-SPEC's prose `state` list (`:ok/:warning/:error/...`) is loose:
```elixir
attr :label, :string, required: true
attr :value, :any, default: nil
attr :severity, :atom, values: [:neutral, :info, :success, :warning, :error], default: :neutral
attr :severity_label, :string, default: nil
attr :state, :atom, values: [:ready, :empty, :loading, :unavailable], default: :ready   # NOT :ok
attr :empty_text, :string, default: "No data yet"
attr :loading_text, :string, default: "Resolving"
attr :unavailable_text, :string, default: "Unavailable"
```
`state` is `:ready` (not `:ok`); there is no `:warning`/`:error` *state* — severity carries that. Meaningful text is already guaranteed: `stat_display_value/1` (605-612) maps `:empty`→empty_text, `:loading`→loading_text, `:unavailable`→unavailable_text, `value: nil`→empty_text. Severity always renders icon + label + color via `stat_severity_icon/class/label` (614-630). "All clear" is the `:neutral` default label (line 620). **Certify call sites; do not change the public contract.**

**`status_badge/1` (lines 802-847)** — sole owner of status→icon/label/color. The base `badge` class is emitted here; call sites must NOT prepend `badge`. Closed atom set + fallback clauses (`status_class/icon/label(_status)` → outline / question-mark / "Unknown") at lines 876/902/928 already handle phantom/nil. Extend the `attr :status` `values` list only if a genuinely new atom appears.

**`mask_recipient/1` (lines 943-950)** — the ONE audited mask. `nil` → `"Unavailable"`. Never add a second mask in a list module.

**New `data_state/1` (optional) — follow the RESEARCH Pattern 2 shape, matching `stat_card`/`filter_field` conventions:**
```elixir
attr :kind, :atom, values: [:empty, :error, :permission_denied, :stale], required: true
attr :title, :string, required: true
attr :body, :string, required: true
attr :icon, :string, default: nil
attr :rest, :global, default: %{}
# render: <section> with aria-hidden icon + visible <h3> + <p>; private kind→icon/color clauses
# like stat_severity_icon/1. Distinct testids per UI-SPEC: data-state-empty / -error /
# -permission-denied / -stale. Icons: hero-inbox / hero-exclamation-circle / hero-lock-closed / hero-clock.
```
Gate the decision on the Open Question 1 rule: add to `Components` only if ≥2 surfaces use the identical taxonomy; otherwise keep state markup local and certify with tests.

---

### `lib/mailglass_admin/operator_live.ex` (live, request-response)

**Analog:** itself — preserve every assign and the `deliveries_list/1` call site.

**`deliveries_list/1` integration (lines 504-524)** — pass-through contract the new dual presentation must keep working unchanged:
```elixir
<aside data-testid="operator-deliveries-list-card" class={["card ... md:block", @selected_delivery && "max-md:hidden"]}>
  <DeliveriesList.deliveries_list
    deliveries={@deliveries}
    page_meta={@deliveries_page_meta}
    previous_page_path={pagination_path(@base_path, @filter_params, @dark_chrome, :previous)}
    next_page_path={pagination_path(@base_path, @filter_params, @dark_chrome, :next)}
    selected_delivery={@selected_delivery}
    filters_active?={filters_active?(@filter_params)}
  />
</aside>
```

**Canonical `stat_card/1` call sites to CERTIFY (lines 372-403)** — four KPI tiles. The "All-clear status" tile (396-403) is the proof that all-clear renders as a real value:
```elixir
<Components.stat_card label="All-clear status"
  value={all_clear_label(@support_summary)}        # "All clear" | "Needs attention" | "Unavailable" (lines 1115-1119)
  state={all_clear_state(@support_summary)}          # nil→:unavailable, else :ready (1112-1113)
  severity={all_clear_severity(@support_summary)}    # :neutral | :success | :warning
  severity_label={all_clear_label(@support_summary)}
  data-testid="operator-overview-health-allclear" />
```
DATA-02 = ensure every KPI on this surface routes through `Components.stat_card` (STATCARD-GATE already enforces presence; widen call-site coverage). Do NOT introduce page-local card markup — `class="card bg-base-200 border border-base-300 rounded-box p-md"` raw-stat shape is gate-banned (conformance line 133).

---

### `lib/mailglass_admin/inbound_live.ex` (live, request-response)

**Analog:** `operator_live.ex` + itself.

**`records_list/1` integration (lines 432-438)** passes `empty_state={@empty_state}`. The state machine `empty_state_for/2` (lines 639-650) yields `:no_tenant | :filtered | :truly_empty`, and `detail_error_for/2` (906-908) yields `:not_found | nil` rendered at `data-testid="inbound-detail-error"` (line 453). These are the existing no-data + error seams DATA-03 unifies. The four distinct templates (`:empty/:error/:permission_denied/:stale`) extend this; `:permission_denied` must be distinct from `:no_tenant`/`:truly_empty` (security: permission-denied rendered as no-data is an Information-Disclosure regression — RESEARCH Security Domain).

**Synchronous-loading invariant (locked by an existing test):** `structural.spec.js` line 937-943 asserts `inbound_live.ex` contains no `assign_async`, no `inbound-loading` testid, no "Loading InboundMessages...". D-06 stale-data is a render-time state, NOT polling/streams — do not add async machinery.

---

### `lib/mailglass_admin/gallery_live.ex` (live, component lab)

**Analog:** itself — the `render_specimen/1` clause-per-component dispatcher + `@specimens` list.

**Specimen dispatcher pattern (lines 181-242)** — add new clauses the same way:
```elixir
defp render_specimen(%{component: :status_badge} = assigns) do
  ~H"""<Components.status_badge status={@assigns_map[:status]} size={@assigns_map[:size] || :sm} />"""
end
defp render_specimen(%{component: :stat_card} = assigns) do
  ~H"""<Components.stat_card label={...} value={...} severity={...} state={...} .../>"""
end
```

**Theme-wrapper harness (lines 97-146)** — every specimen cell is auto-wrapped in `data-testid="gallery-{component}-{state}"` with light, dark, and a system (no `data-theme`) sub-wrapper. `structural.spec.js` `assertPrimitiveThemeWrappers/3` (line 348) asserts all three. Phase 113 specimens (table, cards, data-state, long-value stress) inherit light/dark/system coverage for free by being added to `@specimens` (lines 394+) with new `render_specimen` clauses. Add long-value stress states (`long-label`, `long-value` already exist for `stat_card` — line 30-41) for the new list specimens.

---

### `e2e/structural.spec.js` (test, browser structural)

**Analog:** itself — reuse the existing helper library; add new `data-testid` targets.

**Overflow proof helper to call for all four new testids (lines 494-499):**
```javascript
async function assertNoElementHorizontalOverflow(locator, label) {
  const overflow = await locator.first().evaluate(el => el.scrollWidth - el.clientWidth);
  expect(overflow, `${label} horizontal overflow`).toBeLessThanOrEqual(1);
}
```
OVERFLOW-GATE (UI-SPEC) = call this for `operator-deliveries-table`, `operator-deliveries-cards`, `inbound-records-table`, `inbound-records-cards`, and page body at 320px and 768px.

**Stat-card shape proof (lines 501-524)** `assertStatCardShape/2` asserts label `title`, non-empty value, severity icon + text, `white-space: nowrap`, `tabular-nums`. Reuse for DATA-02 / DATA-04 certification.

**Responsive breakpoint pattern** — `setViewportSize({width: 768|390})` then assert table visible / cards hidden (and vice-versa). Mirror the existing `operator-master-detail` grid assertions (lines 829-858) and `openOperator`/`openInbound` fixtures (lines 47-85). Selected-row a11y: assert `aria-selected="true"` after click on BOTH presentations (existing pattern lines 614-626).

---

### `test/mailglass_admin/{components,operator_live,inbound_live}_test.exs` (test, ExUnit)

**Analog:** itself.

**Component contract via `render_component/2` (components_test.exs:26-119 pattern):**
```elixir
html = render_component(&Components.status_badge/1, status: :delivered, size: :sm)
assert html =~ "badge-success"
assert html =~ "hero-check-circle"
```
Use the same for any new `data_state/1` and for stat_card severity certification (RESEARCH Code Examples).

**Live list/state regression (operator_live_test.exs:264-266 pattern)** — scope to a testid then render:
```elixir
list_html = view |> element("[data-testid='operator-deliveries-list']") |> render()
```
Add assertions for the new `operator-deliveries-table` / `-cards` testids, the four data-state testids, and that recipients stay masked (existing masking assertion at line 247+ must hold for both presentations).

---

### `scripts/check-conformance.sh` (config, drift gate)

**Analog:** itself — STATCARD-GATE / PRIMITIVE-DRIFT-GATE / FORM-DRIFT-GATE clauses (lines 35-134).

**Existing STATCARD-GATE (lines 118-134)** already greps that `operator_live.ex` + `inbound/overview.ex` call `Components.stat_card`, bans `defp stat(`, and bans the raw `class="card bg-base-200 ..."` / `text-display font-bold` / `do: "—"` shape. **Extend, do not weaken.** Per UI-SPEC Conformance section, add Phase 113 deltas ONLY AFTER the intended selectors/component names exist (RESEARCH Wave 0 Gaps): STATUS-BADGE-GATE (no badge-class/severity-icon outside `status_badge/1` in list modules), DATA-STATE-GATE (distinct testids, no merged generic branch), and the ICON-EXISTS check for the four data-state heroicons.

**Validate by running, not grepping** (project memory): `bash scripts/check-conformance.sh` and the scoped `mix test` lanes — do not prove gate behavior by inspection.

---

## Shared Patterns

### Status / Severity encoding (DATA-04)
**Source:** `Components.status_badge/1` (`components.ex:802-928`) and `Components.stat_card/1` severity helpers (`components.ex:614-630`).
**Apply to:** every status/outcome cell in deliveries table + cards, inbound table + cards, every KPI tile, every gallery specimen.
Icon + visible label + semantic color, always — never icon-only or color-only under space pressure. Base `badge` class is owned by the component; call sites pass `status` + `size` only.

### Recipient masking / PII (cross-cutting security)
**Source:** `Components.mask_recipient/1` (`components.ex:943-950`).
**Apply to:** any delivery/record row or card rendering a recipient. `nil` → `"Unavailable"`. One definition only.

### Non-color selected cue (a11y)
**Source:** `row_classes/2` in both list modules (`deliveries_list.ex:178-182`, `records_list.ex:192-196`).
**Apply to:** table rows and mobile card buttons. `border-l-4 border-primary` (or border-top width change) + `aria-selected`/`aria-current` + `bg-base-200` shift. Color is never the sole cue.

### Long-value handling (DATA-05)
**Source:** `tenant_chip/1` (`components.ex:297-309` → `mono min-w-0 truncate` + `title`) and `stat_card/1` value (`mono truncate tabular-nums whitespace-nowrap` + `title`).
**Apply to:** IDs/tenant/provider/module names → `mono min-w-0 truncate` + `title`; timestamps → `mono whitespace-nowrap` + `title`; URLs/subjects/non-ASCII → `min-w-0 overflow-wrap-anywhere` (or `break-all`). Flex/grid cells need `min-w-0` for truncation to engage. No page-level horizontal scroll.

### Result-count + pagination (DATA-01 / D-02)
**Source:** `result_count_label/1` + `pagination_controls/1` (`deliveries_list.ex:111-173`, identical in `records_list.ex`).
**Apply to:** keep the count header above both presentations and pagination below both; read from `@page_meta` only. Never derive count/pages from list length.

### Brand voice / copy (cross-cutting)
**Source:** `components.ex` moduledoc (lines 17-30) + `voice_test.exs`.
**Apply to:** all data-state copy. Banned: "Oops", "Whoops", "Uh oh", "Something went wrong", bare-dash placeholders. Use domain nouns (Delivery / InboundMessage / Mailbox, not "email"). Do not echo raw UUIDs/tenant/provider IDs in user-facing copy.

---

## Cross-file coupling (do not break in isolation)

- **Testid migration:** `operator_live.ex` uses `operator-deliveries-list-card`; `structural.spec.js` asserts `operator-deliveries-list`, `operator-deliveries-list-card`, `inbound-records-list-card`, and `noMatchRow()` filters `inbound-record-row`. Adding `-table`/`-cards` testids means updating these consumers in the same wave or keeping the old testids alongside the new ones. Decide deliberately; do not orphan the existing Playwright fixtures.
- **Asset bundle:** any new Tailwind class → rebuild + commit `priv/static/app.css` via `mix mailglass_admin.assets.build` (CI `git diff --exit-code`). New `hero-*` icons (`hero-inbox`, `hero-exclamation-circle`, `hero-lock-closed`, `hero-clock`) must be embedded in the vendored `heroicons-inline.js` and bundled, or they render invisible (project memory: Heroicons inline plugin).
- **Synchronous LiveView invariant:** stale-data must stay render-time; `structural.spec.js:937` will fail on any `assign_async`/`inbound-loading` addition.

---

## No Analog Found

None. Every Phase 113 target is a modification of an existing module with a strong in-repo analog (usually itself or its declared sibling). The only optional NEW symbol is `Components.data_state/1`, whose attr/private-helper shape is fully templated by the existing `stat_card/1` and `filter_field/1` primitives in the same file — so even that has an exact local analog.

---

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/`, `mailglass_admin/test/mailglass_admin/`, `mailglass_admin/e2e/`, `mailglass_admin/scripts/`, plus read-model sources `lib/mailglass/operator/deliveries.ex` and `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex`.
**Files scanned:** 11 (all canonical refs named in CONTEXT.md that bear on file creation/modification).
**Pattern extraction date:** 2026-06-19
