# Phase 120: Deliveries surface redesign - Pattern Map

**Mapped:** 2026-06-26
**Files analyzed:** 5 (4 modified + 1 re-run/no-edit) + 1 supporting verification
**Analogs found:** 5 / 5 (all in-repo; the direct analog is the Phase 119 Overview gating, same file)

> **Edit-heavy redesign, not a rebuild.** Every primitive Phase 120 needs already exists.
> The work is *render-condition gating* (cond/if wrappers) + *paired test updates*. The single
> strongest analog is the Phase 119 Overview empty-pane-only orientation gate — it lives in the
> **same file** (`operator_live.ex:461-469`) as the Deliveries branch being changed, so the
> pattern can be copied almost verbatim into the Deliveries branch.

---

## File Classification

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` (Deliveries branch, ~488-647) | LiveView render branch (template) | request-response (URL-backed state → conditional render) | **Same file, Overview branch `461-469`** (Phase 119 empty-pane-only orientation gate) | exact (in-file precedent) |
| `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` (no edit — verify) | component (presentational) | transform (assigns → table/card/empty panes) | itself (`68-99` no-data/no-match already branches) | verify-only |
| `mailglass_admin/lib/mailglass_admin/operator/shell.ex` `orientation_strip/1` (no edit — byte-frozen) | component (presentational) | transform | itself (`384-403`) | no-edit (copy frozen, condition lives in caller) |
| `mailglass_admin/e2e/operator.spec.js` (modify `83-115`, `26-32`/`113-114`; add new) | test (Playwright e2e) | request-response assertion | **Same file, Overview gate `382-396`** (empty-pane-only count assertion) | exact (in-file precedent) |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs:37` (modify) | test (ExUnit / LiveViewTest) | request-response assertion | itself (`40-52` empty-state test) | exact |
| `reference/demo_app/assets/e2e/persona-screenshots.spec.js` (re-run, no code edit) | test (screenshot seam) | batch (parametric capture) | itself (`60-189` parametric loop) | re-run-only |

---

## Pattern Assignments

### `operator_live.ex` Deliveries branch (LiveView template, request-response)

**Analog:** the Overview branch **in the same file** (`operator_live.ex:461-469`) — the Phase 119
D-07 empty-pane-only orientation gate. This is the canonical "render orientation strip ONLY in the
calm/empty pane" pattern, already proven on Overview, and Phase 120 (D-05) ports it to Deliveries.

**Analog: Overview empty-pane-only orientation gate** (`operator_live.ex:461-469`):
```elixir
<div
  :if={
    @support_summary && all_clear?(@support_summary) &&
      @suppression_count in [0, nil]
  }
  data-testid="operator-overview-orientation"
>
  <MailglassAdmin.Operator.Shell.orientation_strip surface={:deliveries} />
</div>
```
Copy the shape: the strip is wrapped in a `:if`/`cond` keyed on the calm-pane predicate, NOT
rendered unconditionally. For Deliveries the predicate is genuine-no-data
(`@deliveries == [] and not filters_active?(@filter_params)`), not all-clear.

**State discriminator already exists** (`operator_live.ex:684-687`) — reuse, do NOT invent a flag (D-01):
```elixir
defp filters_active?(filter_params) do
  Map.drop(filter_params, ["tenant_id", "window_hours", "page"]) !=
    Map.drop(default_filter_params(), ["tenant_id", "window_hours", "page"])
end
```
Three IA states: `genuine no-data = @deliveries == [] and not filters_active?(...)`;
`no-match = @deliveries == [] and filters_active?(...)`; `populated = otherwise`.

**FILTERS toolbar to gate** (`operator_live.ex:489-526`) — render this `<section>` ONLY in
populated OR no-match (D-02), withhold entirely in genuine no-data:
```elixir
<section
  data-testid="operator-filters"
  class="card rounded-box border border-base-300 bg-base-200 p-4 md:p-5"
>
  ...
  <div class="flex flex-wrap gap-2">
    <button type="submit" class="btn btn-primary min-h-11 px-5">Open delivery</button>
    <button type="button" phx-click="clear_filters" class="btn btn-ghost min-h-11 px-5">
      Clear filters
    </button>
  </div>
  ...
</section>
```
Wrap this whole `<section>` in the populated-or-no-match condition. The "Open delivery" submit
(`:519`) and toolbar "Clear filters" (`:520-522`) go with it. **Tenant-scope boundary (D-04):**
`FiltersForm.fields` (`:510-516`) exposes only status/event/window — never a tenant control;
withholding the toolbar in no-data is the security-correct move (removes the only scope-widening
vector). Any change letting no-data widen tenant scope is a regression.

**Orientation strip to RELOCATE** — remove from the populated-but-unselected detail column
(`operator_live.ex:580-581`) where it currently fires below a populated table (the
D-ORIENT-REDUNDANT defect):
```elixir
<% is_nil(@selected_delivery) -> %>
  <MailglassAdmin.Operator.Shell.orientation_strip surface={:deliveries} />   <%!-- DELETE this line (D-05) --%>
  <div
    data-testid="operator-empty-detail"
    class="card hidden rounded-box border border-base-300 bg-base-200 p-6 md:block"
  >
    ...
  </div>
```
Delete the `orientation_strip` line here; **keep `operator-empty-detail`** (`582-594`) — it is the
correct populated-unselected column-fill affordance, NOT redundant orientation (D-06). The strip
moves to the genuine-no-data pane only (single calm pane: `operator-empty-truly` + strip).

**Detail-column error branch (verify, do not rebuild — D-09)** (`operator_live.ex:568-579`):
```elixir
<% @detail_error -> %>
  <div
    data-testid="operator-detail-error"
    class="card rounded-box border border-error bg-base-100 p-6"
  >
    <div class="flex items-center gap-2">
      <Components.icon name="hero-exclamation-circle" class="h-5 w-5 text-error" />
      <h2 class="text-body font-bold text-base-content">
        Delivery data could not be loaded. Refresh the page or adjust the filters, then try again.
      </h2>
    </div>
  </div>
```
Existing semantic-error pattern (border-error/text-error/hero-exclamation-circle). Matrix
error/permission-denied/stale states route through this + `deliveries_list` `data_state` — verify, do not duplicate.

**Master-detail grid (preserve verbatim — no structural change)** (`operator_live.ex:528-536`):
```elixir
<section
  data-testid="operator-master-detail"
  class={[
    "mt-6 grid gap-lg",
    if(@selected_delivery,
      do: "md:grid-cols-[40%_60%] min-[1440px]:!grid-cols-[33%_67%]",
      else: "grid-cols-1"
    )
  ]}
>
```
Grid template + responsive ratios are already correct (inherited 119 master-detail). The redesign
is gating + strip relocation, NOT a layout rewrite.

---

### `deliveries_list.ex` (component, transform) — VERIFY, DO NOT REBUILD

**Analog:** itself. The no-data/no-match distinction and `data_state` are already built and tested.

**No-data vs no-match (already branches on `@filters_active?`)** (`deliveries_list.ex:68-99`):
```elixir
<% @data_state == :empty or (@data_state == nil and @deliveries == []) -> %>
  <%= if @filters_active? do %>
    <Components.data_state
      kind={:empty}
      title="No deliveries"
      body="No deliveries match the current filters."
      data-testid-override="operator-empty-filtered"
    />
    ...
    <button type="button" phx-click="clear_filters" data-testid="operator-empty-reset"
            class="btn btn-ghost min-h-11 mx-auto block">
      Clear filters
    </button>
  <% else %>
    <Components.data_state
      kind={:empty}
      title="No deliveries"
      body="No deliveries have been recorded yet."
      data-testid-override="operator-empty-truly"
    />
    ...
  <% end %>
```
The `operator-empty-truly` (no-data) and `operator-empty-filtered` + `operator-empty-reset`
(no-match) panes are correct copy and behavior. Phase 120 gates the *toolbar* (in `operator_live.ex`)
on this same truth — do NOT push toolbar gating into this file (it renders the empty *pane*, not the toolbar).

**`data_state` capability (error/permission_denied/stale — verify against matrix)**
(`deliveries_list.ex:37-67`): four kinds already wired with locked voice-tested copy. Building
net-new error/permission UI duplicates a tested primitive and diverges from locked voice tests.

**Responsive table↔card duality + masking** (`deliveries_list.ex:100-129+`): `md:block`
table / `<768` cards, `Components.status_badge` (color+label+icon), `Components.mask_recipient`,
truncate+title, `aria-current`/`aria-selected` (`:121-122`). Verify, do not restyle.

---

### `shell.ex` `orientation_strip/1` (component) — NO EDIT (copy byte-frozen, D-07)

**Analog:** itself (`shell.ex:384-403` + `copy_for(:deliveries)` `405-414`). The strip is a pure
presentational primitive; **only its render condition changes, in the caller** (`operator_live.ex`).
Do not touch copy or markup:
```elixir
def orientation_strip(assigns) do
  assigns = assign(assigns, :copy, copy_for(assigns.surface))
  ~H"""
  <div class="rounded-box border border-base-300 bg-base-200 p-md"
       data-testid={"#{@surface}-orientation"}>
    <div class="flex items-start gap-sm">
      <Components.icon name="hero-lifebuoy" class="mt-0.5 h-5 w-5 shrink-0 text-primary" />
      ...
```
`copy_for(:deliveries)` heading "Deliveries" + 3 symptom-first tips (`shell.ex:405-414`) are
byte-frozen (D-07). The `data-testid="deliveries-orientation"` is the seam every test keys on.

---

### `operator.spec.js` (Playwright e2e) — PAIRED UPDATE + NEW JUDGMENT GATE

**Analog for the new gate:** the Overview empty-pane-only judgment test **in the same file**
(`operator.spec.js:382-396`):
```javascript
test("operator overview orientation strip is empty-pane-only (all-clear vs attention)", async ({
  page
}) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await openOperator(page);
  await page.goto(`/ops/mail?tenant_id=${tenantId}`);
  await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();
  // ... attention state => strip absent
  await expect(page.getByTestId("operator-overview-orientation")).toHaveCount(0);
});
```
Model the new Deliveries judgment assertion on this: assert `deliveries-orientation` count 0 on a
populated Deliveries view AND count 1 on the genuine no-data view; assert `operator-filters` ABSENT
in genuine no-data but PRESENT in no-match (locks D-05/D-02 into the ratchet — D-10).

**Paired update 1 — mobile "orientation before list" over a POPULATED list** (`operator.spec.js:83-115`):
```javascript
test("mobile shows orientation before list and preserves detail section order", async ({ page }) => {
  ...
  const orientation = page.getByTestId("deliveries-orientation");
  ...
  expect(orientationBox.y).toBeLessThan(deliveriesBox.y);   // <-- goes RED: strip no longer above a populated list
  ...
  // Acceptance check for GAP-07 at 390px: orientation strip must be visible (deliveries-orientation)
  await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
  await expect(page.getByTestId("deliveries-orientation")).toBeVisible();   // <-- RED: populated view, strip gone
});
```
This asserts the strip above a populated list — must be updated/removed (the strip is empty-pane-only
now, D-05). This is the Pitfall-2 / 119-D-09 trap: relocating an always-visible block on a
green-only-forward floor REQUIRES updating its asserting specs in the SAME phase.

**Paired update 2 — `openOperator` helper comments + heading-ambiguity note** (`operator.spec.js:25-32`):
```javascript
// ... the Deliveries surface now also renders the orientation strip's <h2>Deliveries</h2>
// section heading, so an unqualified heading query is ambiguous ...
await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
await expect(
  page.getByRole("heading", { name: "Deliveries", exact: true, level: 1 })
).toBeVisible();
```
The `level: 1` qualifier was added precisely because the strip rendered an `<h2>Deliveries</h2>` on
populated views (the D-LABEL-TRIPLING third heading). After Phase 120 the strip is gone from
populated views, so the ambiguity note `:25-28` is now stale — update the comment (the `level: 1`
query stays valid and harmless). D-LABEL-TRIPLING resolves as a side-effect of D-05 (D-08).

---

### `operator_live_test.exs:37` (ExUnit / LiveViewTest) — PAIRED UPDATE

**Analog:** the adjacent empty-state test in the same file (`operator_live_test.exs:40-52`).

**Assertion to update** (`operator_live_test.exs:27-37`) — currently asserts the strip on a
**populated/unselected** view:
```elixir
{:ok, _view, html} =
  live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

assert html =~ "Recent deliveries"
assert html =~ ~s(data-testid="operator-master-detail")
...
assert html =~ "Select a delivery to inspect its event timeline and suppression state."
refute html =~ "Event timeline"
# Orientation strip: present when no delivery is selected (GAP-07)
assert html =~ ~s(data-testid="deliveries-orientation")    # <-- goes RED: strip now empty-pane-only
```
After Phase 120 the strip is NOT present on a populated/unselected view. Update this `assert` to a
`refute` (strip absent on populated) and rely on the empty-state test below. The adjacent empty-state
test (`:40-52`) is the analog for asserting the strip's NEW location (genuine no-data) — add a
`assert html =~ ~s(data-testid="deliveries-orientation")` there, and an
`assert html =~ ~s(data-testid="operator-empty-truly")` / `refute ... operator-filters` to lock
toolbar-withheld-in-no-data.

---

### `persona-screenshots.spec.js` (screenshot seam) — RE-RUN, NO CODE EDIT

**Analog:** itself (`persona-screenshots.spec.js:60-189`). The Deliveries cells are generated
**parametrically** — the surface is already registered (`:68`
`{ id: "deliveries", kind: "operator", suffix: "&view=deliveries", priority: 2 }`) and cells are
the cartesian product of `PERSONAS` (`:60` northstar/fjordline-aps/helios-void) × `cellsFor()`
(`:98-109`, anchor 375/1440 × light/dark + priority<=2 spot-checks). The cell name format
(`:169` `${surface.id}-${persona}-${vw}-${theme}`) produces exactly
`deliveries-{northstar,fjordline-aps,helios-void}-{375,1440}-{light,dark}`.

**No code change** — re-run the spec to re-shoot the Deliveries cells for only-forward proof
(D-THEME-PARITY hold). Requires `make demo` up + `DEMO_EVIDENCE_RESET_TOKEN` set (`:147-159`).

---

## Shared Patterns

### Empty-pane-only orientation gate (THE keystone pattern, inherited from Phase 119 D-07)
**Source:** `operator_live.ex:461-469` (Overview, same file)
**Apply to:** the Deliveries branch — render `orientation_strip surface={:deliveries}` ONLY inside
the calm/empty pane, wrapped in a `:if`/`cond` keyed on the no-data predicate. Never unconditionally.
```elixir
<div :if={<calm/empty predicate>} data-testid="<surface>-orientation">
  <MailglassAdmin.Operator.Shell.orientation_strip surface={:deliveries} />
</div>
```

### State discriminator reuse (no new flag — D-01)
**Source:** `operator_live.ex:684-687` (`filters_active?/1`) + `deliveries_list.ex:68-99`
**Apply to:** the toolbar gate AND the strip gate. Both key on
`{@deliveries == [], filters_active?(@filter_params)}`. Do not introduce a new assign.

### Render-condition-only change to byte-frozen copy (D-07 / 119 D-10)
**Source:** `shell.ex:384-414` (strip markup + `copy_for/1`), `deliveries_list.ex:68-99` (empty copy)
**Apply to:** every copy-bearing element touched. Change *where* it renders, never *what* it says.
"Oops" banned (CLAUDE.md / COPY-LD-01).

### Paired-test-update trap (Pitfall-2 / 119 D-09 — MANDATORY same phase)
**Source:** the Overview gate's own paired test (`operator.spec.js:382-396`)
**Apply to:** `operator.spec.js:83-115`, `:25-32`, and `operator_live_test.exs:37` — update BEFORE
they go red on the green-only-forward floor. Add the new Deliveries empty-pane-only judgment gate.

### Semantic status/error color (never accent — A11y, never color-alone)
**Source:** `operator_live.ex:568-579` (`border-error`/`text-error`/`hero-exclamation-circle`),
`deliveries_list.ex:50-67` (`data_state` kinds), `Components.status_badge` (color+label+icon)
**Apply to:** all matrix error/permission/stale verification — reuse, do not restyle.

### Motion tokens only — no new keyframes (D-11 / 119 D-11 / v1.13 MOTION locks)
**Source:** `operator_live.ex:599-605` (`.motion-reveal` + `phx-remove` JS.hide ease-out 150),
row `transition-colors` (`deliveries_list.ex:124`)
**Apply to:** nothing new. Empty/no-data panes + strip are born token-clean (no motion). Forbidden:
new `@keyframes`, height/width/padding transitions, ease-in, scale(0), JS animation hooks.

### Asset / TokenParity landmine (D-13 / 119 D-12)
**Source:** committed `mailglass_admin/priv/static/app.css` (canonical), TokenParityTest
**Apply to:** this phase SHOULD add zero new Tailwind classes (render-condition gating, not
restyling). If a class IS added: `mix assets.build` → run `token_parity_test.exs` → commit the
rebuilt bundle in the SAME commit ONLY if it survives the gate. A fresh build emits raw-inline
daisyUI 5.5.19 theme blocks that BREAK TokenParityTest — prefer NO new classes so the bundle is untouched.

---

## No Analog Found

None. Every file maps to an in-repo precedent — the strongest (the empty-pane-only orientation gate
and its judgment test) lives in the **same file** as the Deliveries branch being changed, ported
straight from the Phase 119 Overview work.

---

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/` (operator_live, operator/*, shell,
components), `mailglass_admin/e2e/`, `mailglass_admin/test/mailglass_admin/`,
`reference/demo_app/assets/e2e/`.
**Files scanned:** 6 source/test files at cited line ranges + 120-CONTEXT.md + 120-UI-SPEC.md.
**Pattern extraction date:** 2026-06-26
