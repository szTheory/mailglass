# Phase 75: Information Architecture, Navigation and Orientation — Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 6 (5 modified, 1 new function in existing module)
**Analogs found:** 6 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/operator/shell.ex` (add `orientation_strip/1`) | component (public function component) | request-response (pure render, no data) | `shell.ex` own `defp flash_region/1` (same file, same placement pattern); `operator_live.ex:362` (source content) | exact |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` (modify `handle_params/3`, add Overview branch, remove `defp orientation_strip/1`) | controller / LiveView | request-response, CRUD | existing `handle_params/3` at line 71; `defp assign_delivery_state/3` at line 491; `defp support_summary_module/0` at line 670 | exact |
| `lib/mailglass/operator/suppressions.ex` (add `count_active_suppressions/1`) | service / read-model | CRUD (aggregate count) | `get_delivery_suppression_state/2` lines 17–53 in same file; `SupportSummary.summarize_tenant/1` (same package/tier) | exact |
| `mailglass_admin/lib/mailglass_admin/inbound_live.ex` (add orientation strip call) | controller / LiveView | request-response | `operator_live.ex:254-256` (existing trigger + call pattern) | role-match |
| `mailglass_admin/lib/mailglass_admin/preview_live.ex` (add orientation strip call) | controller / LiveView | request-response | `operator_live.ex:254-256`; `preview_live.ex:291-323` (existing empty-state structure to supplement) | role-match |
| `mailglass_admin/e2e/operator.spec.js` + `reference/demo_app/assets/e2e/demo.spec.js` (update heading assertions) | test (Playwright e2e) | request-response | existing tests in same files | exact |

---

## Pattern Assignments

### 1. `shell.ex` — new public `Shell.orientation_strip/1`

**Role:** public function component
**Analog (source content):** `mailglass_admin/lib/mailglass_admin/operator_live.ex:362-392`
**Analog (placement shape):** `mailglass_admin/lib/mailglass_admin/operator/shell.ex:276-302` (`defp flash_region/1`)
**Analog (attr discriminator precedent):** `shell.ex:102`

**What to copy:** the HEEx structure from `operator_live.ex:362-392` verbatim as the skeleton; replace `data-testid` and copy with the discriminated surface values; use `flash_region/1`'s `attr` + `defp` placement pattern for the public component definition.

**What to change:**
- `defp` → `def` (public component)
- Add `attr :surface, :atom, values: [:deliveries, :inbound, :preview], required: true` before the function
- Replace hardcoded `data-testid="operator-orientation"` with `data-testid={"#{@surface}-orientation"}`
- Replace heading `"Start from the customer symptom"` with per-surface frozen copy from UI-SPEC (see copy table below)
- Replace `<ul>` bullet content with frozen symptom-first bullets per surface
- Replace raw `text-sm` (line 372) with `text-label` so the shared component is born token-clean
- Placement: inserted **after** `defp flash_region(assigns)` at line 302, before the closing `end` of the module

**Attr discriminator precedent** (`shell.ex:102`):
```elixir
attr :active, :atom, values: [:deliveries, :inbound], required: true
```

**Source private component to extract** (`operator_live.ex:362-392`):
```elixir
defp orientation_strip(assigns) do
  ~H"""
  <div
    class="rounded-box border border-base-300 bg-base-200 p-md"
    data-testid="operator-orientation"
  >
    <div class="flex items-start gap-sm">
      <Components.icon name="hero-lifebuoy" class="mt-0.5 h-5 w-5 shrink-0 text-primary" />
      <div class="min-w-0">
        <h2 class="text-body font-bold text-base-content">Start from the customer symptom</h2>
        <ul class="mt-2 grid gap-1 text-sm text-secondary">
          <li>
            <span class="font-bold text-base-content">Email never arrived?</span>
            Filter by tenant, then open the delivery to read its timeline.
          </li>
          <li>
            <span class="font-bold text-base-content">Replay changed nothing?</span>
            Check whether the outcome was <span class="mono">new work</span>
            or <span class="mono">no change</span>
            on the selected delivery.
          </li>
          <li>
            <span class="font-bold text-base-content">Address keeps getting blocked?</span>
            Open the delivery and review its suppression state.
          </li>
        </ul>
      </div>
    </div>
  </div>
  """
end
```

**Placement anchor — `flash_region/1` ends at line 302** (`shell.ex:276-302`):
```elixir
attr :flash, :map, default: %{}

defp flash_region(assigns) do
  ~H"""
  <div
    :if={Phoenix.Flash.get(@flash, :info) || Phoenix.Flash.get(@flash, :error)}
    class="mb-lg space-y-sm"
  >
    ...
  </div>
  """
end
```
New `orientation_strip/1` goes directly after this `end` (before the module's closing `end`).

**Frozen per-surface copy table (verbatim from UI-SPEC, do not paraphrase):**

| Surface | heading | tip bullets |
|---------|---------|-------------|
| `:deliveries` | `"Deliveries"` | `"Email never arrived? Start here."` / `"Replay changed nothing? View the event timeline."` / `"Address keeps getting blocked? Check suppressions."` |
| `:inbound` | `"Inbound"` | `"Message didn't route as expected? Inspect the routing trace."` / `"No mailbox matched? Check the no-match record."` / `"Failed ingest? Review the provider signature log."` |
| `:preview` | `"Preview"` | `"No mailables found? Define a mailable module in your app."` / `"Mailable not showing? Ensure it's compiled."` / `"Preview not rendering? Check your template syntax."` |

**Root testids (D-03):** `deliveries-orientation`, `inbound-orientation`, `preview-orientation`.

**Token-clean rule:** the `<ul>` class must be `text-label` (NOT `text-sm`). The existing source has `text-sm` at line 372 — this is the one intentional content change during extraction.

---

### 2. `operator_live.ex` — `handle_params/3` Overview branch + remove private `orientation_strip/1`

**Role:** LiveView controller
**Analog:** existing `handle_params/3` at lines 71-85 (structure to extend); `assign_delivery_state/3` at lines 491-510 (pattern for a new `assign_overview_state`); `support_summary_module/0` at line 670 (indirection seam to mirror)

**What to copy:** the existing `handle_params/3` pipe chain shape; the `defp support_summary_module` pattern for the new `defp suppression_count_module`; the `try/rescue` + `apply/3` pattern from `load_support_summary/2` for the new suppression count call.

**What to change:**
- Add `view = params["view"]` extraction and `:view` assign to `handle_params/3`
- Replace `|> assign_delivery_state(filter_params, blank_to_nil(params["delivery_id"]))` with a branch: when `view == "deliveries"` (or `delivery_id` present) → `assign_delivery_state`; otherwise → `assign_overview_state`
- Add `defp assign_overview_state/2` that conditionally calls `summarize_tenant` directly (not via the 2-clause `load_support_summary` which returns nil with no selected delivery) and the new suppression count indirection
- Add `defp suppression_count_module, do: :"Elixir.Mailglass.Operator.Suppressions"` alongside `support_summary_module/0`
- Remove `defp orientation_strip(assigns)` (lines 362-392) — extracted to `shell.ex`
- Replace the `<.orientation_strip />` call site (line 255) with `<Shell.orientation_strip surface={:deliveries} />`

**Existing `handle_params/3` to extend** (lines 71-85):
```elixir
@impl true
def handle_params(params, uri, socket) do
  filter_params = normalize_filter_params(params)
  support_state = normalize_support_state(params)

  {:noreply,
   socket
   |> assign(:base_path, URI.parse(uri).path || "/operator")
   |> assign(:page_uri, uri)
   |> assign(:dark_chrome, MailglassAdmin.Operator.Shell.dark_chrome?(params))
   |> assign(:filter_params, filter_params)
   |> assign(:filter_form, to_form(filter_params, as: :filters))
   |> assign(:support_state, support_state)
   |> assign_delivery_state(filter_params, blank_to_nil(params["delivery_id"]))
   |> close_replay_modal()}
end
```
The `view` discriminator is added here. The last two pipe steps become conditional on `view`.

**Existing orientation render trigger to update** (lines 254-256):
```elixir
<div :if={is_nil(@selected_delivery)} class="mb-lg">
  <.orientation_strip />
</div>
```
Change call to: `<Shell.orientation_strip surface={:deliveries} />`
(The `:if` condition and wrapping `div` remain unchanged.)

**Indirection seam pattern to mirror** (`support_summary_module/0` at line 670):
```elixir
defp support_summary_module, do: :"Elixir.Mailglass.Operator.SupportSummary"
```
New peer:
```elixir
defp suppression_count_module, do: :"Elixir.Mailglass.Operator.Suppressions"
```

**`load_support_summary/2` pattern for the Overview variant** (lines 658-668):
```elixir
defp load_support_summary(_filter_params, nil), do: nil

defp load_support_summary(filter_params, _selected_delivery) do
  apply(support_summary_module(), :summarize_tenant, [
    %{
      tenant_id: filter_params["tenant_id"],
      window_hours:
        parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
    }
  ])
end
```
The new `assign_overview_state/2` calls `summarize_tenant` directly (not gated on a `selected_delivery` arg). For the suppression count, wrap the `apply/3` in `try/rescue` that degrades to `nil` (renders as `—`).

**`assign_delivery_state/3` structure to mirror for `assign_overview_state/2`** (lines 491-510):
```elixir
defp assign_delivery_state(socket, filter_params, selected_delivery_id) do
  deliveries = load_deliveries(filter_params)
  selected_delivery = find_selected_delivery(deliveries, selected_delivery_id)
  replay_targets = load_replay_targets(filter_params, selected_delivery)
  replay_history = load_replay_history(filter_params, selected_delivery)

  socket
  |> assign(:deliveries, deliveries)
  |> assign(:selected_delivery, selected_delivery)
  |> assign(:timeline_events, load_timeline(filter_params, selected_delivery))
  |> assign(:suppression_state, load_suppression(filter_params, selected_delivery))
  |> assign(:support_summary, load_support_summary(filter_params, selected_delivery))
  |> assign(:detail_error, detail_error_for(selected_delivery_id, selected_delivery))
  |> assign(:replay_targets, replay_targets)
  |> assign(:replay_history, replay_history)
  |> assign(
    :replay_selected_target_id,
    preserve_replay_selection(replay_targets, socket.assigns[:replay_selected_target_id])
  )
end
```
`assign_overview_state/2` follows the same pipe-assign shape but only populates the assigns the Overview render needs (`:view`, `:support_summary`, `:suppression_count`). It does NOT call `load_deliveries`, `load_replay_targets`, etc. — those remain in `assign_delivery_state`.

**`build_path/4` signature for the "View Deliveries" CTA** (lines 559-578):
```elixir
defp build_path(
       base_path,
       filter_params,
       delivery_id,
       dark_chrome,
       support_state \\ default_support_state()
     ) do
  params =
    filter_params
    |> Map.merge(%{"delivery_id" => delivery_id})
    |> Map.merge(support_state_to_params(support_state))
    |> maybe_put_theme(dark_chrome)
    |> Enum.reject(fn {_key, value} -> is_nil(blank_to_nil(value)) end)
    |> Map.new()

  case URI.encode_query(params) do
    "" -> base_path
    query -> base_path <> "?" <> query
  end
end
```
The "View Deliveries" CTA path appends `&view=deliveries` to whatever `build_path/4` produces for the current `filter_params` (preserving `tenant_id`, `theme`, etc.).

---

### 3. `suppressions.ex` — new `count_active_suppressions/1`

**Role:** service / read-model function
**Analog:** `get_delivery_suppression_state/2` lines 17-53 in the same file (filter clauses to mirror)

**What to copy:** the two `where` clauses at lines 27-28, the `Tenancy.scope/2` call at line 50, and the `Repo.aggregate` pattern (instead of `Repo.one` as in the source).

**What to change:**
- New function; no existing function modified
- Replace the `Entry |> where |> where |> where_matches |> order_by |> limit(1) |> Tenancy.scope |> Repo.one` chain with `Entry |> where |> where |> Tenancy.scope |> Repo.aggregate(:count, :id)`
- No `where_matches/4` call (no recipient/stream filter needed — count ALL active entries for tenant)
- Use `Clock.utc_now()` for `now` — same as existing function (line 24)
- Guard clause `when is_binary(tenant_id) and tenant_id != ""` mirrors `fetch_tenant_id!/1` guard at line 58

**Active-entry filter pattern to mirror** (`suppressions.ex:26-51`):
```elixir
Entry
|> where([entry], entry.tenant_id == ^tenant_id)
|> where([entry], is_nil(entry.expires_at) or entry.expires_at > ^now)
|> where_matches(recipient, recipient_domain, stream)
|> order_by([entry], ...)
|> limit(1)
|> Tenancy.scope(tenant_id)
|> Repo.one()
```

**Module-level aliases already present (lines 6-11)**:
```elixir
import Ecto.Query

alias Mailglass.Clock
alias Mailglass.Outbound.Delivery
alias Mailglass.Suppression.Entry
alias Mailglass.{Repo, Tenancy}
```
All aliases needed by the new function are already imported. No new imports.

**Spec pattern to mirror** (line 17):
```elixir
@spec get_delivery_suppression_state(context(), keyword()) :: map() | nil
```
New spec:
```elixir
@spec count_active_suppressions(String.t()) :: non_neg_integer()
```

**`summarize_tenant/1` as structural reference** (`support_summary.ex:21-35`):
```elixir
@spec summarize_tenant(filters()) :: map()
def summarize_tenant(filters) do
  normalized = normalize_filters(filters)
  tenant_id = fetch_tenant_id!(normalized)
  window_hours = window_hours_from(normalized)
  window_started_at = DateTime.add(Clock.utc_now(), -window_hours, :hour)
  ...
end
```
`count_active_suppressions/1` is simpler: takes `tenant_id :: String.t()` directly (no filter normalization needed — tenant_id is the only argument).

---

### 4. `inbound_live.ex` — add orientation strip call

**Role:** LiveView render modification
**Analog:** `operator_live.ex:254-256` (existing trigger + call site pattern)

**What to copy:** the `:if` trigger + shell component call pattern; the `is_nil(@detail)` branch structure already present at line 330.

**What to change:**
- Inside the `is_nil(@detail)` branch (line 330-338), add `<Shell.orientation_strip surface={:inbound} />` alongside the existing `inbound-empty-detail` div (or replace the existing empty-detail div's content — planner's call)
- Do NOT modify the `is_nil(@detail) -> %>` branch condition itself

**Existing empty-detail branch to modify** (`inbound_live.ex:330-338`):
```elixir
<% is_nil(@detail) -> %>
  <div
    data-testid="inbound-empty-detail"
    class="card rounded-box border border-base-300 bg-base-200 p-6"
  >
    <h2 class="text-base font-bold text-base-content">
      Select an inbound record to inspect its routing, execution timeline, and raw source.
    </h2>
  </div>
```
The orientation strip is added BEFORE this div (orientation strip above, existing empty-detail below), or the existing div's content is kept while prepending the strip — planner to decide. The `inbound-empty-detail` testid is not asserted in current Playwright tests (unlike `operator-empty-detail`); removal is safe if needed, but preservation avoids any breakage risk.

---

### 5. `preview_live.ex` — add orientation strip call alongside existing empty state

**Role:** LiveView render modification
**Analog:** `preview_live.ex:291-323` (existing empty state to supplement, NOT replace)

**What to copy:** the existing `@mailables == []` branch structure; D-06 mandate — orientation strip supplements, does not replace.

**What to change:**
- Inside the `@mailables == []` branch (line 291), add `<Shell.orientation_strip surface={:preview} />` BEFORE the existing `preview-empty-mailables` div (orientation strip on top, existing card below)
- Do NOT change the existing `data-testid="preview-empty-mailables"` (line 293) — preserved verbatim per D-06
- Do NOT change the existing heading `"No mailables discovered"` (line 297) — preserved verbatim per D-06 / Pitfall 5

**Existing empty state to supplement (preserve verbatim)** (`preview_live.ex:291-323`):
```elixir
<% @mailables == [] -> %>
  <div
    data-testid="preview-empty-mailables"
    class="card mx-auto max-w-prose rounded-box border border-base-300 bg-base-200 p-8"
  >
    <Components.icon name="hero-magnifying-glass" class="mb-3 h-10 w-10 text-secondary" />
    <h2 class="mb-2 text-heading font-bold text-base-content">No mailables discovered</h2>
    <p class="text-body text-secondary">
      Preview scans loaded modules that <code class="mono text-xs">use Mailglass.Mailable</code>.
      Nothing was found yet.
    </p>
    <ul class="mt-4 grid gap-2 text-sm text-secondary">
      <li class="flex items-start gap-2">
        <Components.icon name="hero-check-circle" class="mt-0.5 h-4 w-4 shrink-0 text-primary" />
        <span>Confirm the module calls <code class="mono text-xs">use Mailglass.Mailable</code> and is compiled and loaded.</span>
      </li>
      <li class="flex items-start gap-2">
        <Components.icon name="hero-check-circle" class="mt-0.5 h-4 w-4 shrink-0 text-primary" />
        <span>Or pass an explicit list to the router: <code class="mono text-xs">mailglass_admin_routes "/mail", mailables: [MyApp.UserMailer]</code>.</span>
      </li>
    </ul>
  </div>
```
Result structure:
```heex
<% @mailables == [] -> %>
  <Shell.orientation_strip surface={:preview} />
  <div data-testid="preview-empty-mailables" ...>
    ...preserved verbatim...
  </div>
```

---

### 6. `operator.spec.js` + `demo.spec.js` — heading assertion updates (same commit)

**Role:** Playwright e2e test
**Analog:** existing tests in the same files

**Critical rule (IA-03, Pitfall 1):** these updates MUST ship in the SAME COMMIT as the `handle_params/3` Overview branch change. All 5 `operator.spec.js` tests call `openOperator()` (lines 13-21), which asserts the `"Deliveries"` heading at line 19. After Phase 75 the bare root lands on the Overview.

**`openOperator` helper — current (lines 13-21)**:
```javascript
async function openOperator(page) {
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();

  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Deliveries", exact: true })).toBeVisible();
  await expect(page.getByTestId("operator-deliveries-list")).toBeVisible();
}
```

**Required change — recommended strategy (Option A from RESEARCH.md §M-3):**
Update `openOperator` to assert the Overview heading on landing, then `push_patch` to `?view=deliveries` so delivery-centric assertions continue to work:
```javascript
async function openOperator(page) {
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();

  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();
  // Navigate to Deliveries view before delivery-centric assertions
  await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
  await expect(page.getByRole("heading", { name: "Deliveries", exact: true })).toBeVisible();
  await expect(page.getByTestId("operator-deliveries-list")).toBeVisible();
}
```

**`operator.spec.js:32-34` `operator-empty-detail` assertion** — remains valid if `openOperator` navigates to `?view=deliveries` first. No change needed to the assertion itself:
```javascript
const emptyDetail = page.getByTestId("operator-empty-detail");
await expect(emptyDetail).toBeVisible();
```

**390px test (lines 64-89)** — extend with orientation strip visibility assertion. Current test ends at line 89 without an orientation strip check. Add after the existing stacking assertions:
```javascript
// Existing assertions (lines 64-89)...
await page.setViewportSize({ width: 390, height: 844 });
await openOperator(page);
// ... existing stacking assertions ...
// NEW: assert orientation strip visible at 390px
await expect(page.getByTestId("deliveries-orientation")).toBeVisible();
```

**`demo.spec.js` — "outbound operator" test (lines 23-35)**:
```javascript
// Current lines 25-28:
await page.getByRole("link", { name: /outbound operator/i }).click();
await expect(page).toHaveURL(/\/ops\/mail\?tenant_id=northstar/);
await expect(page.getByRole("heading", { name: "Deliveries", exact: true })).toBeVisible();
await expect(page.getByTestId("operator-deliveries-list")).toBeVisible();
```
After Phase 75, the link navigates to bare `/ops/mail?tenant_id=northstar` → Overview. Update:
```javascript
await page.getByRole("link", { name: /outbound operator/i }).click();
await expect(page).toHaveURL(/\/ops\/mail\?tenant_id=northstar/);
await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();
// Navigate to Deliveries to assert the list
await page.goto("/ops/mail?tenant_id=northstar&view=deliveries");
await expect(page.getByTestId("operator-deliveries-list")).toBeVisible();
```

**`demo.spec.js:41` "Inbound records" heading** — NOT affected. That test navigates to `/ops/mail/inbound?tenant_id=northstar` (InboundLive, separate route), which still renders `title="Inbound records"`. No change needed.

---

## Shared Patterns

### `attr` discriminator for function components
**Source:** `shell.ex:102`
**Apply to:** the new `Shell.orientation_strip/1` attr declaration
```elixir
attr :active, :atom, values: [:deliveries, :inbound], required: true
```
New peer:
```elixir
attr :surface, :atom, values: [:deliveries, :inbound, :preview], required: true
```

### Runtime-module indirection seam (graceful degradation)
**Source:** `operator_live.ex:658-670`
**Apply to:** new `defp suppression_count_module/0` and its call site in `assign_overview_state/2`
```elixir
defp load_support_summary(_filter_params, nil), do: nil

defp load_support_summary(filter_params, _selected_delivery) do
  apply(support_summary_module(), :summarize_tenant, [
    %{
      tenant_id: filter_params["tenant_id"],
      window_hours:
        parse_positive_integer(filter_params["window_hours"]) || @default_window_hours
    }
  ])
end

defp support_summary_module, do: :"Elixir.Mailglass.Operator.SupportSummary"
```
Mirror for suppression count — wrap `apply/3` in `try/rescue` so errors degrade to `nil` (renders as `—` per D-12). The `support_summary` call on the Overview branch does NOT need `try/rescue` (SupportSummary is always present in the core package) but the suppression count does because it's the cross-package optional touch.

### Token-clean class discipline
**Source:** UI-SPEC § Spacing Scale + Typography
**Apply to:** all new HEEx in Phase 75
- Use `gap-sm/md/lg`, `p-md` — NOT `gap-3/4/6`, `p-4/5/6`
- Use `text-label` for meta/tip lists — NOT `text-sm`
- Use `text-body` for body text — NOT `text-base`
- Use `text-heading` for section headings — NOT raw font-size utilities
- Weight: `font-bold` only — never `font-medium` or `font-semibold` (not loaded)

### `aria-current="page"` — already handled, do not duplicate
**Source:** `shell.ex:205` (`nav_link/1`) and `shell.ex:229` (`nav_pill/1`)
```elixir
aria-current={@active && "page"}
```
When the Overview passes `active={:deliveries}` to `Shell.shell`, the Deliveries nav item already gets `aria-current="page"` via `nav_link/1` and `nav_pill/1`. No custom aria work is needed on the Overview render for D-16.

### `hero-lifebuoy` icon usage
**Source:** `operator_live.ex:369`
```elixir
<Components.icon name="hero-lifebuoy" class="mt-0.5 h-5 w-5 shrink-0 text-primary" />
```
Carries unchanged into the new public `Shell.orientation_strip/1`. Icon, size classes, color, and `mt-0.5` offset are all frozen by the existing markup.

---

## No Analog Found

None — all files have direct analogs in the codebase.

---

## Anti-Patterns (explicitly documented in RESEARCH.md, repeated here for planner)

| Anti-pattern | Why it fails | Correct approach |
|---|---|---|
| Adding `:overview` to `shell.ex attr :active` values | Overview IS the Deliveries surface root — creating a ghost nav concept | Pass `active={:deliveries}` from the Overview render; never add `:overview` |
| Splitting e2e update into a separate commit from the IA change | All 5 tests call `openOperator()` which asserts `"Deliveries"` at line 19 — CI fails between commits | Same commit: HEEx change + both spec updates |
| Changing `preview_live.ex:297` heading `"No mailables discovered"` | D-06: preserve existing empty state verbatim | Leave heading unchanged; orientation strip goes above the existing card |
| Calling `load_deliveries` on the Overview branch | Wastes a DB round-trip for data not shown | Branch in `handle_params/3`: skip `assign_delivery_state` when `view != "deliveries"` |
| Touching `support_cards.ex` | Phase 76 GAP-13 support-card hierarchy restructure | Do not touch; Overview health-count cards are new compact cards, not support cards |
| Adding `motion-reveal` or `phx-mounted` to orientation strip | D-05: always-visible, not action-triggered | No motion classes; strip is statically rendered |

---

## Metadata

**Analog search scope:** `mailglass_admin/lib/`, `lib/mailglass/operator/`, `mailglass_admin/e2e/`, `reference/demo_app/assets/e2e/`
**Files read:** 9 source files (operator_live.ex, shell.ex, suppressions.ex, support_summary.ex, inbound_live.ex, preview_live.ex, operator.spec.js, demo.spec.js, 75-UI-SPEC.md)
**Pattern extraction date:** 2026-06-04
