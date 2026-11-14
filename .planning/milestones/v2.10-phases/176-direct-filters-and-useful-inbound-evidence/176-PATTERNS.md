# Phase 176: Direct Filters and Useful Inbound Evidence - Pattern Map

**Mapped:** 2026-10-28
**Files/seams classified:** 30 (all under `mailglass_admin/` unless noted; 4 NEW production/test files, 1 NEW spec pair)
**Analogs found:** 29 / 30 (one seam, the `FilterSearchSync` Back/Forward sync behavior, has a structural analog only)
**Tracked-source gate (#3645):** every analog path below was verified with `git ls-files --error-unmatch`; none is a gitignored capability/runtime mirror.

All paths are relative to the repo root `/Users/jon/projects/mailglass`. Line numbers were read on 2026-10-28 at `main` (`bf74494a`) and are the anchors the plans should cite.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | LiveView controller | event-driven + request-response | same module (`apply_filters`/`validate_filters`/`assign_delivery_state`) | exact (self) |
| `mailglass_admin/lib/mailglass_admin/inbound_live.ex` | LiveView controller | event-driven + request-response | `operator_live.ex` (sibling clone, see its own "cloned from OperatorLive" comment :1795) | exact (sibling) |
| `mailglass_admin/lib/mailglass_admin/operator/filter_commit.ex` (NEW, `@moduledoc false`) | utility (pure policy) | transform | `operator/repair_state.ex` (pure presenter, `@spec` + multi-clause) | role-match |
| `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex` | component | transform | same file | exact (self) |
| `mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex` | component | transform | `operator/filters_form.ex` | exact (sibling) |
| `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` | component | transform | same file (stale panel outside the `cond`, :57-62) | exact (self) |
| `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` | component | transform | `operator/deliveries_list.ex` | exact (sibling) |
| `mailglass_admin/lib/mailglass_admin/components.ex` (`collection_header`, `message_identity`) | component | transform | same file | exact (self) |
| `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex` | component | transform | same file + `Components.technical_details`/`copy_value` | exact (self) |
| `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex` | component | transform | same file (:114-121) | exact (self) |
| `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` | component | transform | same file | exact (self) |
| `mailglass_admin/priv/static/hooks.js` (+`FilterSearchSync`) | hook (client JS) | event-driven | `ModalFocusTrap` / `PreviewTabs` (same file) | structural |
| `mailglass_admin/lib/mailglass_admin/gallery_live.ex` (:597, :1279-1311) | component fixtures | transform | same file | exact (self) |
| `reference/persona_spec/quick_view_scenarios.ex` + `.json` | config / fixture manifest | transform | `inbound/1` + `delivery_investigation/1` builders | exact (self) |
| `reference/demo_app/storybook/inbound_evidence.story.exs` (NEW) | story | transform | `reference/demo_app/storybook/delivery_investigation.story.exs` | role-match |
| `mailglass_admin/test/mailglass_admin/operator/filter_commit_test.exs` (NEW) | test (unit) | transform | `test/mailglass_admin/operator/repair_state_test.exs` | exact |
| `mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs` (NEW) | test (contract) | transform | `test/mailglass_admin/phase175_prohibition_contract_test.exs` | exact |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | test (LiveView) | request-response | same file (:2379-2390 fault; :529-533 one-shot arm; :200-209 patch) | exact (self) |
| `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` | test (LiveView) | request-response | same file (:377-388 repo swap; :740-805 invalid filters) | exact (self) |
| `mailglass_admin/test/mailglass_admin/inbound/components_test.exs` (:327-374) | test (component) | transform | same file | exact (self) |
| `mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs` | test (component) | transform | same file | exact (self) |
| `mailglass_admin/test/support/operator_fixtures.ex` (:628-637 whitelist) | test support | event-driven | same file | exact (self) |
| `mailglass_admin/e2e/phase176-filters.spec.js` (NEW, advisory) | test (browser) | event-driven | `e2e/phase169-journey.spec.js` ("filter history") + `e2e/phase175-inbound.spec.js` helpers | role-match |
| `reference/demo_app/assets/e2e/phase176-*.spec.js` (NEW, advisory, LV 1.1.33) | test (browser) | event-driven | `reference/demo_app/assets/e2e/delivery-investigation.spec.js` | role-match |
| coupled e2e updates: `inbound-layout.spec.js`, `phase175-inbound.spec.js`, `phase169-journey.spec.js`, `structural.spec.js`, `phase168-plan03-acceptance.spec.js`, `phase170-journey.spec.js`, `flows.spec.js`, `operator.spec.js` (all under `mailglass_admin/e2e/`) | test (browser) | event-driven | self | exact (self) |

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/operator_live.ex` (LiveView, event-driven + request-response)

**Analog:** itself. Phase 176 rewires existing handlers; it adds no new module-level pattern.

**Existing commit handler to restructure into the shared `commit_filters/3`** (`operator_live.ex:248-274`). This is today's Enter/Apply path. Its normalize -> canonical path -> `same_location?` -> `push_patch` spine is the exact shape D-01 wants on `phx-change`:

```elixir
  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    {normalized, filter_errors} = normalize_filter_params_with_errors(filters)

    if map_size(filter_errors) == 0 do
      path =
        if socket.assigns[:view] == :deliveries do
          build_path_with_view(socket.assigns.base_path, normalized, socket.assigns.dark_chrome)
        else
          build_path(socket.assigns.base_path, normalized, nil, socket.assigns.dark_chrome)
        end

      if same_location?(socket.assigns.page_uri, path) do
        {:noreply, socket}
      else
        {:noreply, push_patch(socket, to: path)}
      end
    else
      {:noreply,
       socket
       |> assign(:filter_form, to_form(filter_draft_params(filters, normalized), as: :filters))
       |> assign(:filter_errors, filter_errors)}
    end
  end
```

**Current draft-only change handler that becomes the commit point** (`:283-291`). Note the `load_provider_options` line is the one D-04 deletes (`handle_params` :172 already loads it):

```elixir
  def handle_event("validate_filters", %{"filters" => filters}, socket) do
    {normalized, filter_errors} = normalize_filter_params_with_errors(filters)

    {:noreply,
     socket
     |> assign(:filter_form, to_form(filter_draft_params(filters, normalized), as: :filters))
     |> assign(:filter_errors, filter_errors)
     |> assign(:provider_options, load_provider_options(normalized))}
  end
```

**Tenant back-trap site (D-07)**, currently a bare `push_patch` that pushes a history entry (`:222-229`); add `replace: true`:

```elixir
  def handle_info(:canonicalize_tenant, %{assigns: %{tenant_state: :auto_select}} = socket) do
    [tenant] = socket.assigns.tenant_options

    {:noreply,
     push_patch(socket,
       to: MailglassAdmin.Operator.Shell.tenant_switch_path(socket.assigns.page_uri, tenant.id)
     )}
  end
```

**Clear filters** (`:347-357`) builds from the server-held tenant already, which is the D-09 pattern to copy for commits:

```elixir
  def handle_event("clear_filters", _params, socket) do
    filter_params = %{
      "tenant_id" => socket.assigns.selected_tenant_id || "",
      "view" => "deliveries"
    }

    {:noreply,
     push_patch(socket,
       to: build_path(socket.assigns.base_path, filter_params, nil, socket.assigns.dark_chrome)
     )}
  end
```

**Draft vs committed split (D-12)**. Operator already does both: `handle_params` builds the form from raw params (`:181`) and the helper keeps the raw invalid `event`/`window_hours` (`:1273-1279`):

```elixir
        |> assign(:filter_params, filter_params)
        |> assign(:filter_form, to_form(filter_draft_params(params, filter_params), as: :filters))
        |> assign(:filter_errors, filter_errors)
```
```elixir
  defp filter_draft_params(params, normalized) do
    Enum.reduce(["event", "window_hours"], normalized, fn key, draft ->
      if Map.has_key?(params, key),
        do: Map.put(draft, key, normalize_string(Map.get(params, key))),
        else: draft
    end)
  end
```

**Stale vs error read classification (D-14/D-15)** (`:1554-1565`, loaded_for tracking `:1650-1656`, key `:1778-1780`). `page` is part of the key, so a page change reads as a new query (-> `:error`, not `:stale`):

```elixir
    {deliveries, page_meta, deliveries_read_state} =
      case read_deliveries_page(filter_params, socket.assigns[:operator_read_fault]) do
        {:ok, deliveries_page} ->
          {deliveries_page.entries, page_meta_without_entries(deliveries_page), :ready}

        {:error, :unavailable}
        when socket.assigns.deliveries != [] and socket.assigns.deliveries_loaded_for == query_key ->
          {socket.assigns.deliveries, socket.assigns.deliveries_page_meta, :stale}

        {:error, :unavailable} ->
          {[], page_meta_without_entries(empty_page_meta()), :error}
      end
```
```elixir
    |> assign(
      :deliveries_loaded_for,
      if(deliveries_read_state == :ready,
        do: query_key,
        else: socket.assigns[:deliveries_loaded_for]
      )
    )
```
```elixir
  defp delivery_query_key(filter_params),
    do:
      Map.take(filter_params, ["tenant_id", "provider", "event", "search", "window_hours", "page"])
```
Add a sibling `deliveries_loaded_at` assign (UTC `DateTime`) set only on `:ready` (Open Question 3 / A7) for the "Showing results from HH:MM; refresh failed" title.

**Retry without history (D-14)**: `retry_deliveries` re-runs `assign_delivery_state` against committed `filter_params` and never patches (`:433-442`). Keep it exactly; only the copy around it changes.

**Canonical path + no-op guard (D-08)** (`:2208-2229` and `:2320-2326`). The selection drop is already implicit (`delivery_id` is the 3rd arg = nil) and page=1 is dropped; make the `page` drop explicit in the commit function (`Map.put(normalized, "page", "1")`) rather than relying on `normalize_page` of whatever the form sent:

```elixir
  defp build_path(base_path, filter_params, delivery_id, _dark_chrome,
         support_state \\ default_support_state()) do
    params =
      filter_params
      |> Map.merge(%{"delivery_id" => delivery_id})
      |> Map.merge(support_state_to_params(support_state))
      |> Enum.reject(fn
        {"page", "1"} -> true
        {_key, value} -> is_nil(blank_to_nil(value))
      end)
      |> Map.new()

    case URI.encode_query(params) do
      "" -> base_path
      query -> base_path <> "?" <> query
    end
  end
```
```elixir
  defp same_location?(current_uri, target_path) do
    current = URI.parse(current_uri)
    target = URI.parse(target_path)

    (current.path || "/") == (target.path || "/") and
      URI.decode_query(current.query || "") == URI.decode_query(target.query || "")
  end
```
Landmines the planner should assign explicitly:
- `build_path` ends in `|> Map.new()` then `URI.encode_query(map)`. Key order is only incidentally sorted (small-map iteration). D-08 wants a *sorted keyword list*: insert `|> Enum.sort()` before `URI.encode_query/1` (in both LiveViews) and pin it in `filter_commit_test.exs`.
- Open Question 2 (support_state): `build_path/5` already takes `support_state` as an optional 5th arg, but `build_path_with_view/3` (`:2328-2331`) calls `build_path/4`, so carrying `socket.assigns.support_state` through commits needs `build_path_with_view` to gain an arity (or pass the 5th arg through). `e2e/phase168-plan03-acceptance.spec.js:171` depends on that decision.
- Open Question 1: existing test `operator_live_test.exs:200-209` asserts `"window_hours" => "168"` is **in** the patched URL. Do not drop `window_hours` as a "default" without a deliberate URL-contract note.

**Mount defaults to extend** (`:60-80`): new assigns (`:pending_commit_kind`, `:last_commit_kind`, `:deliveries_loaded_at`, and any `:filter_announcement`) belong next to `|> assign(:deliveries_loaded_for, nil)` (`:73`); `clear_surface_state/1` (`:1215-1241`) is where they reset for the no-Account states.

**Form markup to change** (`:941-978`): remove `type="submit"` + `phx-disable-with` (`:963-969`), remove the hidden tenant input (`:948-953`, D-09), add `phx-auto-recover="recover_filters"`, drop `w-40`. Mobile toggle (`:931-938`) lacks `aria-controls`/`aria-expanded`; copy Inbound's toggle (`inbound_live.ex:689-701`).

---

### `mailglass_admin/lib/mailglass_admin/inbound_live.ex` (LiveView, event-driven + request-response)

**Analog:** `operator_live.ex` (above). Inbound is the *less* evolved sibling; it needs three ports, each with a located Operator source:

| Gap in Inbound | Inbound site | Operator source to copy |
|---|---|---|
| draft form built from normalized params only | `:210` `|> assign(:filter_form, to_form(filter_params, as: :filters))`; `:265`, `:282` | `operator_live.ex:181`, `:1273-1279` (`filter_draft_params`) |
| no same-query stale retention; no `loaded_for` | `assign_inbound_state/4` `:896-968` assigns rows unconditionally; mount defaults `:94-103` | `operator_live.ex:1554-1565`, `:1650-1656`, `:1778-1780`, mount `:73` |
| no Retry | none | `operator_live.ex:433-442` (`retry_deliveries`) |

**Inbound's handlers today** (these are the lines to rewrite):

```elixir
  def handle_event("apply_filters", %{"filters" => filters}, socket) do        # :249
    {normalized, filter_errors} = normalize_filter_params_with_errors(filters)
    if map_size(filter_errors) == 0 do
      path = build_path(socket.assigns.base_path, normalized, nil, socket.assigns.dark_chrome)
      if same_location?(socket.assigns.page_uri, path) do ... else push_patch ...
```
```elixir
  def handle_event("validate_filters", %{"filters" => filters}, socket) do     # :277
    ...
     |> assign(:filter_form, to_form(normalized, as: :filters))
     |> assign(:filter_errors, filter_errors)
     |> assign_provider_options(normalized)}                                    # D-04: remove (:284)
```
Canonicalize site to add `replace: true` (`:506-513`); Clear (`:349-360`); form + Apply button to remove (`:703-748`, button `:733-739`); hidden tenant input (`:718-723`).

**Records-state mapping that Retry/stale must extend** (`:1736-1738`). `data_state` only ever carries `nil | :package_unavailable | :read_unavailable` today (the `:error`/`:stale` branches of `RecordsList` are never set by Inbound), so the new failed-read states route through `:read_unavailable`:

```elixir
  defp records_data_state(:ok), do: nil
  defp records_data_state(:package_unavailable), do: :package_unavailable
  defp records_data_state(:read_unavailable), do: :read_unavailable
```

**Normalization asymmetry (Pitfall 4)**: Inbound search is not trimmed (`:1823` `"search" => normalize_string(Map.get(params, "search", defaults["search"]))`), Operator's is (`operator_live.ex:1260-1261` `|> String.trim()`). Add the trim at commit time in both, keep the draft untrimmed.

**Reveal auth and PII-free telemetry stay byte-identical (D-27)**:

```elixir
  def handle_event("reveal_raw", _params, socket) do                           # :432
    reveal_state = authorize_reveal(socket)
    emit_reveal_telemetry(socket, reveal_outcome(reveal_state))
    {:noreply, assign(socket, :reveal_state, reveal_state)}
  end

  def handle_event("re_redact_raw", _params, socket) do                        # :449
    {:noreply, socket |> assign(:reveal_state, :redacted) |> assign(:focus_reveal_after_redact, true)}
  end
```
```elixir
  defp emit_reveal_telemetry(socket, outcome) do                               # :1780
    :telemetry.execute(
      [:mailglass_admin, :inbound, :reveal_raw, :stop],
      %{count: 1},
      %{
        tenant_id: blank_to_nil(socket.assigns.filter_params["tenant_id"]),
        record_id: reveal_record_id(socket.assigns.detail),
        outcome: outcome
      }
    )
  end
```
INUX-06's single toggle button needs the *one* button to dispatch `reveal_raw` when collapsed and `re_redact_raw` when revealed (switch `phx-click` on `@reveal_state`; do not add a third event or state atom). `focus_reveal_after_redact` is an existing assign (set `:116`, `:453`, `:915`, `:997`) consumed by a focus sentinel at `inbound_live.ex:870` (`:if={@focus_reveal_after_redact}`); once the single persistent toggle button keeps focus by itself, decide deliberately whether the sentinel is still needed rather than leaving it dangling.

**Filter-region read pipeline** (`:896-968`): `load_inbound_records_page/1` (`:1564-1583`) returns `{page, :ok | :read_unavailable | :package_unavailable}`; stale retention slots in right after `empty_state_for/3` (`:900-901`) and before the `assign(:records, ...)` pipeline.

---

### `mailglass_admin/lib/mailglass_admin/operator/filter_commit.ex` (NEW pure module, transform)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex` (pure presenter: module-level attrs, `@spec` per public function, many small pattern-matched clauses, no process state).

**Shape to copy** (`repair_state.ex:1-17`):
```elixir
defmodule MailglassAdmin.Operator.RepairState do
  @moduledoc """
  Shared presenter for operator-facing replay availability and outcome wording.
  """

  @spec availability_label(map() | atom() | nil) :: String.t() | nil
  def availability_label(nil), do: nil
  def availability_label(%{status: status}), do: availability_label(status)
  def availability_label(:exact), do: "ready"
```

**Content to write** (RESEARCH Pattern 2; locked by D-06): `@moduledoc false`, `@type kind :: :search | :select | :enter | :clear | :page | :recover | :canonicalize`, and `history_kind/2`:
```elixir
  def history_kind(:search, :search), do: :replace   # continue an in-progress search edit
  def history_kind(:search, _other), do: :push       # first commit of a search edit
  def history_kind(kind, _last) when kind in [:recover, :canonicalize], do: :replace
  def history_kind(_kind, _last), do: :push          # select, enter, clear, page
```
RESEARCH A5 recommends `history_kind(:enter, :search) -> :replace` (Enter finalizing an in-flight search edit adds no second entry). That departs from D-06's literal text; surface it in the plan as an explicit decision rather than implementing silently. Put the shared `canonical_path/3` here only if both LiveViews' `build_path` can be unified; they differ (Operator has `support_state`/`view`, Inbound does not), so the safe minimum is the history policy plus a shared `drop_selection/1` / `commit_params/2`.

---

### `mailglass_admin/lib/mailglass_admin/operator/filters_form.ex` and `inbound/filters_form.ex` (component, transform)

**Analog:** each other. Both wrap `Components.filter_field`; the search field is the only change (`phx-debounce="300"`, `phx-hook`, `data-committed`, `autocomplete="off"`, `enterkeyhint="search"`). Existing search field (`operator/filters_form.ex:23-29`, `inbound/filters_form.ex:27-34`):

```elixir
      <Components.filter_field
        field={@form[:search]}
        label="Search"
        help="Find deliveries by recipient email address or subject."
        help_display={:tooltip}
        placeholder="Subject or recipient"
      />
```
Add `attr(:committed_search, :string, default: "")` (alongside the existing `attr(:errors, :map, default: %{})`, `operator/filters_form.ex:14`). `filter_field` forwards `:rest` onto the `<input>` (`components.ex:933-935` declares `include: ~w(autocomplete inputmode list max min pattern placeholder step)`; `phx-*`/`data-*` are in Phoenix's default global set per RESEARCH A4, pin with one component test).

**Keep a raw invalid value visible in a select (D-12)**: Operator already does this for the time window and Inbound does not.
```elixir
  # operator/filters_form.ex:38,66-74
        options={window_options(@window_options, @form[:window_hours].value)}
  defp window_options(options, value) do
    value = to_string(value || "")
    if Enum.any?(options, fn {_label, hours} -> to_string(hours) == value end) do
      options
    else
      [{"Custom period (#{value} hours)", value} | options]
    end
  end
```
Inbound passes `options={@window_options}` raw (`inbound/filters_form.ex:43`). Port `window_options/2` into the Inbound wrapper. Also: `FORM-DRIFT-GATE` (inside the required `conformance_gates` lane) rejects direct `<input|select|label|textarea>` in these two wrappers, so the "previous filters" note and everything else must live in the LiveViews, not here.

**Error copy to reword (UI-SPEC)**: Operator's `@event_filter_error` (`operator_live.ex:~51`) currently reads "Status was not applied. Choose a listed status."; UI-SPEC rewrites it to "Latest recorded event was not applied. Choose a listed event." `e2e/structural.spec.js:~2330` asserts the old copy.

---

### `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` and `inbound/records_list.ex` (component, transform)

**Analog for the stale/error layout:** `operator/deliveries_list.ex:56-72`. The stale panel is a sibling *above* the `cond`, so rows still render; the error branch pairs the `data_state` panel with a sibling Retry button:

```heex
    <div class="min-w-0 overflow-hidden rounded-box border border-base-300 bg-base-200">
    <Components.data_state
      :if={@data_state == :stale}
      kind={:stale}
      title="This view may be out of date."
      body="The latest read was unavailable. Showing the last results loaded for this Account."
    />
    <%= cond do %>
      <% @data_state == :error -> %>
        <Components.data_state
          kind={:error}
          title="This view could not be updated."
          body="Refresh to try again. If it continues, contact your Mailglass host administrator."
        />
        <button type="button" phx-click={@retry_event} class="btn btn-ghost min-h-11 mx-auto block">
          Retry deliveries
        </button>
```
(`retry_event` attr already exists, `:46`; `data_state` has no action slot, so Retry stays a sibling per UI-SPEC.)

**Inbound defect to fix (Pitfall 7)**: `records_list.ex:94-99` places `:stale` *inside* the `cond`, so a stale Inbound page replaces the rows:
```heex
        <% @data_state == :stale -> %>
          <Components.data_state kind={:stale} title="This view may be out of date." body="Refresh the view to check for updates." />
```
Move to the Operator layout (panel above the `cond`, rows still rendered). Inbound's failure path today is `@data_state == :read_unavailable` (`:80-87`, testid `inbound-read-unavailable`, title "Inbound records unavailable"); `inbound_live_test.exs:376-392` asserts that testid/copy and the absence of `inbound-result-count` / `inbound-overview-total`. UI-SPEC rewords to "Couldn't load inbound messages for these filters" with Retry; keep the testid so those assertions only need their copy strings updated.

**Collection count on error (D-15)**: `deliveries_list.ex:50-55` passes `count={Map.get(@page_meta, :total_count, 0)}` unconditionally, producing "0 deliveries" on `:error`. The Inbound sibling already guards it (`records_list.ex:57-63`):
```heex
    <Components.collection_header
      :if={@heading || is_nil(@data_state)}
      title={@heading}
      count={if(is_nil(@data_state), do: Map.get(@page_meta, :total_count, 0))}
      count_label={if(is_nil(@data_state), do: result_count_label(@page_meta))}
```
Copy this guard to Operator, but gate on `@data_state in [nil, :ready]` (Operator passes `:ready`, not `nil`, for success: `operator_live.ex:1032` `data_state={@deliveries_read_state}`). A `nil`-only guard would hide the count on every successful Operator read.

**Status region (D-16)**: one `<div role="status" aria-live="polite" aria-atomic="true" class="sr-only">` per collection, always rendered. Structural analog for an always-present live region with conditional visibility: `inbound/evidence_card.ex:140-147` (`role="status" aria-live="polite"`, `sr-only` toggled via class). Text per settled state is tabulated in UI-SPEC "Result status region".

---

### `mailglass_admin/lib/mailglass_admin/components.ex` (component, transform)

**`collection_header/1`** (`:528-552`): already supports `count: nil` (renders nothing) — callers pass nil when not ready. No change to the component beyond making the callers correct. `attr(:count_testid)` is already there.

**`message_identity/1`** (`:554-582`) — the hard-coded "To" label at `:577`; add an attr (for example `recipient_label`, default `"To"`) driven by `@context`, with callers `inbound/detail_header.ex:37-43` and `inbound/quick_view.ex:114-121` passing `context={:inbound}` already:
```heex
      <p :if={not is_nil(@subject)} class="text-body text-secondary [overflow-wrap:anywhere]">
        To <span class="text-base-content">{@recipient || "Recipient not recorded"}</span>
      </p>
```
Existing test to extend, not replace: `test/mailglass_admin/components_test.exs:396` (`render_component(&Components.message_identity/1, ...)`). The operator callers (`operator/detail_header.ex:22`, `operator/quick_view.ex:119`) must keep "To".

**Keep (D-23)**: `mask_recipient/1` (`:1751-1758`), `mask_email/2`, `mask_value/1` (`:1779-1786`) are public with `@doc since: "0.2.0"`; still called from `inbound/routing_trace.ex:239,247` (`Components.mask_recipient(value)` / `Components.mask_value(value)`). Do not delete or re-scope them.

**Reusable primitives for the new address list**:
- Per-address copy: `Components.copy_value` (`:1592-1609`), attrs `value`, `label`; renders a `button[data-copy-value]` with `mono max-w-full break-all`.
- Native disclosure summary classes (copy verbatim for "Show N more"): `technical_details` (`:597-602`) `class="mg-focus-ring min-h-11 cursor-pointer content-center rounded-field text-label font-bold text-secondary"`.
- Failed/stale/error panel: `Components.data_state` (`:767-806`) kinds `:empty | :error | :permission_denied | :stale`; no slot, no new kind.

---

### `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex` (component, transform)

**Analog:** itself, plus `Components.technical_details` for a `<dl>` with `copy_value`.

**Masked-From site to replace (INUX-05)** — the whole `sender_display/1` masking path (`:125-141`) and the From cell (`:52-55`):
```heex
          <div>
            <dt class="text-label font-bold">From</dt>
            <dd class="mt-xs text-base-content">{sender_display(@record)}</dd>
          </div>
```
```elixir
  defp sender_display(record) do
    record
    |> Map.get(:from, [])
    |> List.wrap()
    |> Enum.map(&address_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> case do
      [] -> "Unavailable"
      addresses -> addresses |> Enum.map(&Components.mask_recipient/1) |> Enum.join(", ")
    end
  end

  defp address_value(%{address: address}) when is_binary(address), do: address
  defp address_value(%{"address" => address}) when is_binary(address), do: address
  defp address_value(address) when is_binary(address), do: address
  defp address_value(_other), do: nil
```
**Keep `address_value/1`'s dual-key (atom + string) reading** (JSONB round-trips string keys; fresh structs use atom keys) and extend it to a `name_value/1` with the same two clauses. Retire only the `mask_recipient` call. The surrounding grid classes stay (`:51`): `grid min-w-0 gap-md text-body text-secondary sm:grid-cols-2 lg:grid-cols-3 [&>div]:min-w-0 [&_dd]:[overflow-wrap:anywhere]`.

**Data source**: `detail.record` is the full `%InboundRecord{}` in production (`from/to/cc/bcc/reply_to` arrays of `%{address, name?}`, `envelope_recipient` string; `inbound_record.ex:46-51`), but tests pass plain maps — read with `Map.get(record, :to, [])`, never dot-access (the module's own Pitfall 2 comment at `:9-14` is the project precedent). Bind "Delivered to" to `envelope_recipient` and "To" to header `to` and nothing else (D-30 contract test).

**Copy-value row pattern to reuse** (`:87-96`, technical details block):
```heex
          <div>
            <dt class="text-label font-bold text-secondary">Record ID</dt>
            <dd class="mt-xs"><Components.copy_value value={@record.id} label="Record ID" /></dd>
          </div>
```
This file is one of the eight conformance group-surface files (Pitfall 13): use token utilities only (`gap-sm`, `space-y-sm`, `mt-xs`), no `text-sm`, no `font-medium/semibold`, no `gap-3/4/6`.

---

### `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex` (component, transform)

**Analog:** itself. Only the `message_identity` call needs the new label (`:114-121`); keep `recipient={Map.get(@record, :envelope_recipient)}`. Do NOT widen the `mailglass_inbound` list projection.

---

### `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` (component, transform)

**Analog:** itself. Stable `data-testid`/ids to retain: `inbound-evidence-card`, `inbound-evidence-reveal` (+ `id="inbound-evidence-reveal-btn"`), `inbound-evidence-raw`, `inbound-evidence-denied`, `inbound-evidence-status`.

**Header region being collapsed to one disclosure group (D-24)** (`:38-66`): remove the locked badge (`:46-48`), the `flex-col` caption wrapper (`:49-64`) and fold the caption into the heading group; the single button keeps `id`, `aria-expanded`, `aria-controls` (`:50-58`):
```heex
            <button
              id="inbound-evidence-reveal-btn"
              type="button"
              phx-click="reveal_raw"
              data-testid="inbound-evidence-reveal"
              aria-expanded={if @reveal_state == :revealed, do: "true", else: "false"}
              aria-controls="inbound-evidence-raw"
              class="mg-focus-ring btn btn-ghost min-h-11 px-md"
            >
              {if @reveal_state == :revealed, do: "Raw source revealed", else: "Reveal raw source"}
            </button>
```
Label flips to "Hide raw source" when revealed and `phx-click` flips to `re_redact_raw` (see inbound_live note). The `<pre>` currently lacks `id`/`tabindex`/`aria-label` (`:116-119`); `aria-controls="inbound-evidence-raw"` targets an id that does not exist on the `<pre>` today (it is only a `data-testid`), so add `id="inbound-evidence-raw"` as UI-SPEC specifies.

**Truth fixes (D-26)**. Current helpers (`:153-174`):
```elixir
  defp payload_byte_size(%{raw_payload: payload}) when is_map(payload) do
    payload |> Jason.encode!() |> byte_size()
  rescue
    _ -> 0
  end

  defp payload_byte_size(%{raw_mime: mime}) when is_binary(mime), do: byte_size(mime)
  defp payload_byte_size(_evidence), do: 0

  defp header_count(%{raw_headers: headers}) when is_map(headers), do: map_size(headers)
  defp header_count(_evidence), do: 0

  defp raw_payload_text(...) ... defp raw_payload_text(_evidence), do: "(empty)"
```
Two bugs (not just the `0 -> nil` change): (1) the `raw_payload` map clause matches first and `raw_payload` defaults to `%{}` (`inbound_evidence.ex:38`), so MIME-backed evidence reports 2 bytes (Pitfall 9) — order clauses by "what actually holds the bytes": non-empty `raw_mime` -> `byte_size/1`; non-empty map -> encoded size; known-empty -> `0`; encode failure / neither field -> `nil` ("Unavailable"); (2) the `rescue _ -> 0` is the unknown-as-zero lie. `raw_payload_text/1` fallback `"(empty)"` becomes "Provider sent an empty payload." Add a table test including a `raw_mime`-backed row.

**Remove**: the dead `attr(:can_reveal?, :boolean, default: true)` (`:29`); callers (`inbound_live.ex:664-667`) never pass it. `Received` fact needs a new attr (`received_at`) passed from `inbound_live.ex:664` because evidence has no timestamp.

**Existing denied/redacted copy is byte-frozen by tests** (`test/mailglass_admin/inbound/evidence_card_test.exs`): "You do not have permission to reveal raw source." (note "do not") becomes "You don't have permission to reveal raw source."; "No raw provider source has been stored for this message." becomes "No raw provider source was stored for this message."; `inbound-evidence-redacted` paragraph is removed. Update the test file's module doc and assertions in the same plan.

---

### `mailglass_admin/priv/static/hooks.js` (hook, client JS, event-driven)

**Analog:** `ModalFocusTrap` (`hooks.js:2-26`) and `PreviewTabs` (`:38-92`). The file is **hand-maintained** (no build step): one `window.MailglassAdminHooks = { Name: { mounted() {...}, updated() {...}, destroyed() {...} } }` object; handlers are stored on `this` in `mounted()` and removed in `destroyed()`.

**Conventions to copy** (from `PreviewTabs`, `:38-92`): handler stored as `this.handleX = (event) => {...}`; listeners attached on `this.el` (or `window` for `popstate`); `destroyed()` removes exactly what `mounted()` added; early-`return` guards; `updated()` re-syncs. Pattern to insert after `PreviewPanelScroll` (the last entry, no trailing comma today):

```javascript
      FilterSearchSync: {
        mounted() {
          this.pending = false
          this.clearPending = () => { this.pending = false }
          this.handlePopstate = () => {
            this.pending = true
            clearTimeout(this.pendingTimer)
            this.pendingTimer = setTimeout(this.clearPending, 1500)
          }
          window.addEventListener("popstate", this.handlePopstate)
          this.el.addEventListener("input", this.clearPending)
        },
        updated() {
          if (!this.pending) return
          this.pending = false
          const committed = this.el.dataset.committed ?? ""
          if (this.el.value !== committed) {
            this.el.value = committed
            this.el.setSelectionRange?.(committed.length, committed.length)
          }
        },
        destroyed() {
          window.removeEventListener("popstate", this.handlePopstate)
          this.el.removeEventListener("input", this.clearPending)
          clearTimeout(this.pendingTimer)
        }
      }
```
Pitfall 3 is the design driver: the flag MUST disarm on next `updated()`, on any `input`, and on a timer, or a stale `popstate` flag clobbers typing 300ms after a Back press. Rename `onPop` -> `handlePopstate` to match the file's `handle*` convention.

**Delivery mechanics (no rebuild)**: `controllers/assets.ex:64-69` reads `hooks.js` at compile time (`@external_resource @hooks_path`, `@hooks File.read!(@hooks_path)`); `test/mailglass_admin/assets_test.exs:110-135` asserts it is served exactly once and the hash matches. So: edit, commit, run the assets test. **Do not blind-rebuild `app.css`** (token-parity landmine); run `mix mailglass_admin.assets.build` only after HEEx edits that add new Tailwind utilities, then `git diff --exit-code priv/static/` and `TokenParityTest` (currently idempotent per RESEARCH Pitfall 8).

---

### `mailglass_admin/lib/mailglass_admin/gallery_live.ex` (component fixtures)

**Analog:** itself. Replace masked fixtures at `:597` (`envelope_recipient: "a****@e******.com"` inside `composed_detail_timeline/1`) and `:1279-1311` (`records_list` fixtures `"s*@m***.io"`, `"b*@e******.com"`, `"b*****@enterprise-example-company-name.co.uk"`) with synthetic worst-case data from UI-SPEC "Retained-scenario fixture content" (reserved example domains only). `composed_detail_timeline` feeds a plain map to `DetailHeader.detail_header/1`; add `from`/`to`/`cc` keys there.

---

### `reference/persona_spec/quick_view_scenarios.ex` + `.json` and `reference/demo_app/storybook/inbound_evidence.story.exs` (NEW story)

**Analog:** the `inbound/1` builder (`quick_view_scenarios.ex:60-91`) for manifest-driven assigns, and `reference/demo_app/storybook/delivery_investigation.story.exs` for a composed multi-component production story. The builder pattern:
```elixir
  def inbound(scenario_id) when is_atom(scenario_id) do
    variation_id = Atom.to_string(scenario_id)
    scenario =
      Enum.find(@manifest["scenarios"], fn entry ->
        entry["rendered"] == true and entry["variation_id"] == variation_id and
          String.starts_with?(entry["id"], "qv-inbound-")
      end)
    if is_nil(scenario), do: raise(ArgumentError, "unknown retained Inbound scenario #{variation_id}")
    projection = scenario["projection"]
    ...
```
and the story's variations are generated from ids (`delivery_investigation.story.exs:35-49`):
```elixir
  def variations do
    for id <- [:northstar_complete, :fjordline_long_unicode, ...] do
      %Variation{id: id, attributes: QuickViewScenarios.delivery_investigation(id)}
    end
  end
```
Follow the same shape: a new `inbound_evidence/1` builder keyed by a scenario-id prefix (for example `"inbound-evidence-"`), `container: :iframe`, theme-owner wrapper template, `render_case/1` composing the production `MailglassAdmin.Inbound.DetailHeader.detail_header/1` and `MailglassAdmin.Inbound.EvidenceCard.evidence_card/1` with no invented props. The existing `inbound_record/1` (`:223-233`) projects only list fields (`envelope_recipient`, no `from/to/cc`), so the DetailHeader scenario needs its own projection helper that adds `from/to/cc/reply_to`, and a datetime parse via the existing `datetime/1` helper.

**Coupled gates when editing the manifest**: `node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs` and `mix test test/mailglass_admin/quick_view_projection_test.exs` (RESEARCH Wave 0). The demo e2e asserts exact scenario counts (`delivery-investigation.spec.js:30-40`: `expect(selectedAxeCases).toBe(8)`, `RETAINED_IDS`); a new prefix avoids disturbing the Phase 175 inventory.

---

### `mailglass_admin/test/mailglass_admin/operator/filter_commit_test.exs` (NEW, unit)

**Analog:** `test/mailglass_admin/operator/repair_state_test.exs` — `use ExUnit.Case, async: true`, `alias` the module, one `test` per truth-table row, plain `assert Mod.fun(...) == expected`:
```elixir
defmodule MailglassAdmin.Operator.RepairStateTest do
  use ExUnit.Case, async: true
  alias MailglassAdmin.Operator.RepairState
  test "replay evidence distinguishes a request, new work and a completed no-op" do
    assert RepairState.effect_label(%{outcome: :replayed}) == "new work"
```
Add `@tag :phase176`. Cover the full `history_kind/2` truth table including `(:search, :search)`, `(:search, nil)`, `(:search, :select)`, `(:enter, :search)` (whichever the plan locks), and canonical-path sort/blank/`page=1` dropping.

---

### `mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs` (NEW, contract)

**Analog:** `phase175_prohibition_contract_test.exs` (457 lines) — copy its *structure*:
1. `use ExUnit.Case, async: true`; `import Phoenix.LiveViewTest`; module-level regex lists (`@receipt_claims` etc., `:25-72`) for forbidden wording.
2. A **"detectors have teeth (fail-first proof)"** describe block (`:74-98`) that feeds each pattern set a known violation and asserts it is caught — so a green pass is not vacuous. This is what "mutation-proven" means here; every Phase 176 prohibition needs a paired known-violating input.
3. One describe per prohibition id with `assert_clean(corpus, patterns, label)`.
4. Helpers at the bottom (`:426-456`) to reuse verbatim:
```elixir
  defp visible_text(html) do
    html |> Floki.parse_fragment!() |> Floki.filter_out("script") |> Floki.text(sep: " ") |> String.replace(~r/\s+/, " ")
  end

  defp control_labels(html) do
    html |> Floki.parse_fragment!() |> Floki.find("button, a, [phx-click]")
    |> Enum.map(fn node ->
      events = node |> Floki.attribute("phx-click") |> Enum.reject(&String.starts_with?(&1, "["))
      [Floki.text(node) | events] |> Enum.join(" ")
    end)
  end

  defp violations(text, patterns), do: Enum.filter(patterns, &Regex.match?(&1, text))
  defp assert_clean(corpus, patterns, label) do ... end
```
It also demonstrates the source-scan style for "no LiveView does X" (`:269-277`, `File.read!` + `refute source =~ ...`) — reuse for "no `phx-disable-with` on the filter forms" / "no `type=\"submit\"` in the filter form".

**Phase 176 prohibition set (D-30), mapped to renderers already present in the repo**:
- no visible Apply button / no `type="submit"` / no `phx-disable-with` in `#operator-filters` and `#inbound-filters` (live render + `control_labels/1`);
- routing trace still masks (`render_component(&MailglassAdmin.Inbound.RoutingTrace.routing_trace/1, ...)` and the existing trace-masked contracts at `inbound_live_test.exs:1220-1246,2259-2287` stay);
- "Delivered to" bound to `envelope_recipient` and "To" to header `to` (swap the two values in a fixture and assert the label/value pairing does not move);
- denied/unauthorized renders never contain a raw-payload sentinel (existing sentinel pattern: `evidence_card_test.exs` uses `"secret-raw-payload-121-02"` and `refute html =~ ...`);
- telemetry metadata keys are exactly `[:tenant_id, :record_id, :outcome]` (attach with `:telemetry.attach/4` to `[:mailglass_admin, :inbound, :reveal_raw, :stop]`, `inbound_live.ex:1780-1790`);
- unknown size/count never renders "0" (nil evidence fields -> "Unavailable");
- a failed *new-query* read never renders empty-state copy or a count (fault-injected, see operator_live_test below).

Tag everything `@tag :phase176`. Do not add tests above any `@tag :skip` that is registered in `config/test_exceptions.exs` (line-number keyed; `test/scripts/test_exceptions_contract_test.exs`).

---

### `mailglass_admin/test/mailglass_admin/operator_live_test.exs` (LiveView test)

**Analog:** itself.

**Persistent-fault page load -> error panel** (`:2379-2390`):
```elixir
      conn = operator_conn(conn, %{"auth_method" => "fault:deliveries"})
      {:ok, _view, html} =
        live(conn, operator_path(%{"tenant_id" => @tenant_id, "view" => "deliveries"}))

      assert html =~ "This view could not be updated."
      assert html =~ "Retry deliveries"
      refute html =~ "No deliveries in this time window"
      refute html =~ "synthetic transient operator read failure"
```
**One-shot arming for same-query-stale vs new-query-error** (`:529-533`, mechanism in `test/support/operator_fixtures.ex:628-637` and `test/support/endpoint_case.ex:310-345`, `TestOperatorHook`):
```elixir
      OperatorFixtures.arm_reader_fault!("operator-1", "delivery_suppression", :known)
      view |> element(~s([data-testid="operator-suppression-refresh"])) |> render_click()
```
**Wave 0 seam change (verified)**: the `arm_reader_fault!/3` whitelist at `operator_fixtures.ex:630` does NOT contain `"deliveries"`; it must be added (the permanent `fault:deliveries` session auth at `endpoint_case.ex:318-321` already accepts it). Stale test = load OK page, arm `"deliveries"` once, `render_hook(view, "retry_deliveries", %{})`, assert stale title + retained rows; new-query-error test = arm, then change a filter.

**Patch-kind assertion (probe-verified in RESEARCH)** — `assert_patch/2` cannot see `kind`:
```elixir
{ref, topic, _pid} = view.proxy
render_hook(view, "clear_filters", %{})
assert_receive {^ref, {:patch, ^topic, %{kind: :push, to: to}}}   # or kind: :replace
```
Share this as a helper between both live test files (RESEARCH Wave 0 gap). Back-navigation is modeled with `render_patch(view, operator_path(...))` (precedent `:1320`).

**Existing assertions this phase invalidates (D-31 + inventory)**:
- `:184-186` `assert html =~ "Apply filters"`, `phx-disable-with="Applying filters…"`, `"w-40"`;
- `:187-205` the `form(...) |> render_submit()` + `assert_patch` flow still works through Enter/`phx-submit`; keep one such test;
- `:318-334` "invalid submitted filters ... do not push a patch" — `assert html =~ "Status was not applied. Choose a listed status."` (reword per UI-SPEC) and `assert_raise ArgumentError, fn -> assert_patch(view, 0) end` stays valid for an invalid commit;
- `:363`/`:380` `render_hook(view, "validate_filters", ...)` for an invalid window: still no commit (draft only) — keep, plus add the "previous filters" note assertion.
- Helper `selected_filter_value/2` (`:2756-2765`) is the idiom for asserting a select's selected raw value; reuse it for Inbound's new draft retention.

Gotcha (Pitfall 11): two buttons share `phx-click="clear_filters"` (toolbar + empty-state); `element(view, "[phx-click=clear_filters]")` raises "got 2". Scope with `#operator-filters [phx-click=clear_filters]` or use `render_hook(view, "clear_filters", %{})`.

---

### `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` (LiveView test)

**Analog:** itself. **Inbound fault injection is a repo swap, not the Operator seam** (`:377-388`):
```elixir
      previous_repo = Application.fetch_env!(:mailglass_inbound, :repo)
      Application.put_env(:mailglass_inbound, :repo, MailglassAdmin.InboundUnavailableRepo)
      on_exit(fn -> Application.put_env(:mailglass_inbound, :repo, previous_repo) end)
```
Support repos live at the top of the file (`:1-60`: `InboundUnavailableRepo`, `InboundTimelineFailingRepo`, `InboundListFailingRepo`). Same-query-stale for Inbound needs a *load OK, then swap repo, then re-read* ordering (swap after `live/2`, restore in `on_exit`). `clear_filters_count/1` (`:2491-2496`, counts "Clear filters" occurrences) is the existing idiom for the two-button situation.

**Assertions that conflict with Inbound draft retention (planner decision)**: the URL-invalid test at `:740-777` asserts `~s(value="168" selected)` and `Floki.find(document, "#filters_window_hours option[value='bogus']") == []`; the form-invalid test at `:778-805` asserts `option[value='not-real'] == []` and `assert_raise ArgumentError, fn -> assert_patch(view, 0) end`. Porting Operator's `filter_draft_params` into Inbound's `handle_params` (`inbound_live.ex:210`) changes the first (a `bogus` "Custom period" option appears, as in Operator `operator_live_test.exs:360`). Decide whether URL-invalid draft retention is ported to `handle_params` or only to form events, and update the two asserts deliberately. `:786` is the D-31-listed Apply/invalid-submit assertion.

Reveal/evidence assertions to update (~`:1259-1285`, `:2211-2227`, `:2359` per RESEARCH): `inbound-evidence-redacted`, "Raw source is hidden by default", "You do not have permission to reveal", `inbound-evidence-re-redact`, "Raw source revealed". Keep trace-masked contracts (`:1220-1246`, `:2259-2287`) unchanged.

---

### `mailglass_admin/test/mailglass_admin/inbound/components_test.exs` (:327-374) and `inbound/evidence_card_test.exs`

**Analog:** themselves. The masked-From tests render `DetailHeader.detail_header/1` via `render_component(&DetailHeader.detail_header/1, detail: detail)` with a plain-map `record` (atom-keyed `from: [%{address: "bob@sender.test"}]` at `:327-345`, string-keyed `%{"address" => ..., "name" => "Carol"}` at `:354-372`). Flip these (not delete): assert the *unmasked* address and name render, and add rows for the D-19..D-22 matrix — long local part, Unicode (`用户@例子.广告`), missing -> "No From header", multiple, >5 -> `<details>` "Show N more", exact-duplicate collapse, spoof (`"billing@paypal.example" <sender@mailer.example>` + cue text), unparseable, and a `<script>` display name (XSS guard: assert escaped text, no `<script>` element). Keep the dual atom/string key coverage.

`evidence_card_test.exs` uses a module-attribute `@evidence` map and a `render_state/1` helper (`:19-33`); extend it with `raw_mime`-backed, empty-payload, and nil-field evidence variants.

---

### `mailglass_admin/e2e/phase176-filters.spec.js` (NEW, advisory) and coupled e2e updates

**Analog:** `e2e/phase169-journey.spec.js` "Phase 169 filter history restores committed URL state" (`:~563-585`) for the history/Back/Forward style, and `e2e/phase175-inbound.spec.js:1-17` for the Inbound login helper:

```javascript
async function openInbound(page) {
  await page.context().clearCookies();
  const reset = await page.request.get("/ops/browser-reset");
  expect(reset.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  ...
  await page.goto(new URL(`/ops/mail/inbound?tenant_id=${tenantId}`, baseURL).toString());
  await expect(page.getByTestId("inbound-records-list-card")).toBeVisible();
}
```
```javascript
    await page.locator("#filters_event").selectOption("failed");
    await expect(page).not.toHaveURL(/event=failed/);      // <- INVERTS after this phase
    await page.getByRole("button", { name: "Apply filters" }).click();   // <- remove
    await page.waitForURL(url => new URL(url).searchParams.get("event") === "failed");
    await page.goBack();
```
Boilerplate: `const { test, expect } = require("@playwright/test")`, `tenantId = "browser-tenant"`, `baseURL` from `OPERATOR_BASE_URL`/`BROWSER_SERVER_PORT` (default 4101), run via `npm --prefix mailglass_admin run test:operator-browser -- phase176-filters.spec.js` (`package.json`: rebuilds assets first, `--workers=1`; server self-boots from `playwright.config.cjs`). Test naming follows `"Phase NNN ..."` (also watch `bucket_a_coverage_test.exs`, which fails closed on renamed cited e2e titles; re-grep before renaming any existing title).

**Behavior rules the spec must encode (RESEARCH Pitfalls 1, 3, 6)**: assert `history.length` *deltas* per intent; "Clear during pending debounce" ends in the cleared state with a delta of 2 in Chromium (blur flushes the debounce, then Clear), so assert end state only; Back-then-type must not lose typed characters (hook disarm case); invalid draft is unreachable via select clicks, so cover invalid URL with `page.goto(...?event=bogus)`.

**Coupled existing specs to rewrite (remove the Apply click, remove inverted-URL assertions)**:
- `e2e/inbound-layout.spec.js:173,181,184` (three `getByRole("button", { name: "Apply filters", exact: true }).click()`);
- `e2e/phase175-inbound.spec.js:137` (Apply click after `selectOption`); the `toHaveURL(/outcome=accept/)` asserts after it stay valid and now prove auto-apply;
- `e2e/phase169-journey.spec.js:569-571` (also `not.toHaveURL(/event=failed/)`);
- `e2e/structural.spec.js:~2330` (old copy) and `:~2344-2362` (`requestSubmit()` semantics);
- `e2e/phase168-plan03-acceptance.spec.js:171` (depends on the support_state decision);
- `phase170-journey.spec.js`, `flows.spec.js`, `operator.spec.js` assert evidence-card strings/testids (grep for `Raw source locked`, `inbound-evidence-redacted`, `You do not have permission`).

### `reference/demo_app/assets/e2e/phase176-*.spec.js` (NEW, advisory, LV 1.1.33)

**Analog:** `reference/demo_app/assets/e2e/delivery-investigation.spec.js`. Pattern: login helper `loginTo(page, target)` going through `/demo/login?return_to=...` then `await page.locator("[data-phx-main].phx-connected").waitFor()` (`:15-18`), manifest-driven scenario inventory against `../../../persona_spec/quick_view_scenarios.json` (`:5`). Its job is the A3 spike: prove `updated()` fires for the focused search input and `data-committed` re-sync works under LiveView 1.1.33 (the admin gate runs 1.2.13). Run: `npm --prefix reference/demo_app/assets run test:e2e -- --grep "Phase 176"`.

---

## Shared Patterns

### Server-held Account on every commit (D-09) / tenant-tamper safety
**Source:** `operator_live.ex:347-357` (`clear_filters` reads `socket.assigns.selected_tenant_id`) and `handle_params` `:166` (`selected_tenant_id = blank_to_nil(filter_params["tenant_id"])`, the URL authorization gate).
**Apply to:** the one commit function in both LiveViews, covering `validate_filters`, `apply_filters` and `recover_filters`.
```elixir
filters = Map.put(filters, "tenant_id", socket.assigns.selected_tenant_id || "")   # BEFORE normalize
```
Removing the hidden input without this line silently commits a URL with no Account (Pitfall 10: `normalize_filter_params_with_errors` defaults `tenant_id` to `""`). Contract-test with a foreign tenant id in the payload.

### Fire-and-forget PII-free telemetry
**Source:** `inbound_live.ex:1780-1790` (metadata exactly `tenant_id`, `record_id`, `outcome`).
**Apply to:** anything new that emits telemetry. Phase 176 should add **none** (RESEARCH: "no new telemetry"); the only action is a contract test pinning the existing three keys. Never put address, subject, search term or filter values in metadata or logs.

### Error handling / read failure classification
**Source:** `operator_live.ex:1686-1694` (`read_deliveries_page/2`) and `:1761-1771` (`transient_read_error?/1`).
```elixir
  defp read_deliveries_page(filter_params, read_fault) do
    run_read_fault(read_fault, :deliveries)
    {:ok, load_deliveries_page(filter_params)}
  rescue
    error ->
      if transient_read_error?(error),
        do: {:error, :unavailable},
        else: reraise(error, __STACKTRACE__)
  end
```
**Apply to:** Inbound uses `ReadResult.fetch/1` (`inbound/read_result.ex`, called at `inbound_live.ex:181,1297,1515,1646`) -> `{:ok, v} | {:error, :read_unavailable}`; keep that wrapper, do not introduce the Operator rescue form into Inbound. Never string-match error messages (CLAUDE.md #7); the tests assert `refute html =~ "synthetic ..."` to prove failure detail does not leak.

### Components: tokens, targets and conformance
**Source:** `mailglass_admin/scripts/check-conformance.sh` (merge-blocking inside `conformance_gates`).
**Apply to:** every HEEx edit, especially `inbound/detail_header.ex` and `inbound/evidence_card.ex` (group-surface files). Use `gap-sm`/`gap-md`, `space-y-sm`, `mt-xs`, `px-md`, `text-label`/`text-body`/`text-heading`, `font-bold`; no `text-sm`, `font-medium`, `gap-3/4/6`, hard-coded hex, or same-tone card signatures. Interactive controls `min-h-11`; focus ring class `mg-focus-ring`. No new `hero-*` icons (invisible unless embedded in `heroicons-inline.js`; `ICON-EXISTS-GATE`).

### Voice
**Source:** `voice_test.exs` bans `oops`, `whoops`, `uh oh`, `something went wrong` across rendered surfaces; CLAUDE.md "Brand & Voice". New copy must be the UI-SPEC strings verbatim ("Couldn't load deliveries for these filters", "Showing results for your previous filters until the highlighted field is fixed.", etc.).

### Validation (input allow-lists, escaping)
**Source:** `inbound_live.ex:1961-1970` (`cast_enum/2`, `String.to_existing_atom` + closed-set check) and `normalize_enum_filter`/`normalize_window_filter`/`parse_positive_integer` in both LiveViews.
**Apply to:** unchanged. All address/name rendering goes through HEEx `{...}` interpolation (auto-escaped); no `raw/1`, no `Phoenix.HTML.raw`.

### Shift-left test lane & tagging
**Source:** `phase175_prohibition_contract_test.exs` plus Phase 175 `@tag :phase175` usage (`operator_live_test.exs:554`) and `175-VALIDATION.md` commands.
**Apply to:** tag all new ExUnit with `@tag :phase176`; quick run (RESEARCH, 236 tests, ~3.5s): `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --seed 0`. Full: `mix verify.support_contract.admin`. Prefer ExUnit DOM-contract pins for everything server-observable; the Playwright lanes (Operator Browser Gate, demo e2e) are advisory per D-29 and sit outside `ci_green.needs`.

## No Analog Found

| File / seam | Role | Data Flow | Reason |
|---|---|---|---|
| `FilterSearchSync` value-restore-on-popstate behavior (`hooks.js`) | hook | event-driven | Structural analogs exist (`ModalFocusTrap`, `PreviewTabs` lifecycle shape) but no existing hook listens on `window` `popstate` or mutates an input `value` in `updated()`; the algorithm comes from RESEARCH Pattern 3 and LiveView's focused-input merge semantics (`dom_patch.ts` in the pinned deps). Needs the Wave 0 browser spike (A3) against both LV 1.2.13 and 1.1.33. |

Everything else has an in-repo analog; the new `filter_commit.ex` module is a small pure policy function with a close structural match.

## Planner Landmines (collected while reading analogs)

1. **`build_path_with_view/3` drops `support_state`** (`operator_live.ex:2328-2331`) — resolve Open Question 2 before wiring the commit path; `phase168-plan03-acceptance.spec.js:171` encodes the opposite of "drop it".
2. **Operator `collection_header` guard must be `@data_state in [nil, :ready]`**, not `nil` only (Operator passes `:ready` on success).
3. **Inbound `RecordsList` `:error`/`:stale` branches are dead today** (`records_data_state/1` never returns them); wire failures through `:read_unavailable` and keep `data-testid="inbound-read-unavailable"` so `inbound_live_test.exs:376-392` only changes copy.
4. **`aria-controls="inbound-evidence-raw"` points at a non-existent id** today (it is only a `data-testid` on the `<pre>`).
5. **Two "Clear filters" buttons** per collection share `phx-click="clear_filters"`; scope selectors.
6. **`render_change`/`render_hook` bypass debounce and blur**; pin the DOM contract (`phx-debounce="300"` on search only, exactly one text-like input per form, no submit control) in ExUnit and leave timing to Playwright.
7. **Trim asymmetry** (Operator trims search, Inbound does not) will produce different canonical URLs for `"foo "` — fix at commit time in both.
8. **Do not add tests above a registered `@tag :skip`** (`config/test_exceptions.exs` is line-number keyed; a full `mix test` catches what scoped lanes miss).
9. **Commit conventions**: admin UI changes must not use a `feat(...)` scope that the root release-please path claims unintentionally; follow Phase 175's commit-type precedent. `.planning/` edits use `docs(...)`.

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/{,operator/,inbound/}`, `mailglass_admin/priv/static/hooks.js`, `mailglass_admin/test/{mailglass_admin/,support/}`, `mailglass_admin/e2e/`, `reference/persona_spec/`, `reference/demo_app/{storybook/,assets/e2e/}`, `mailglass_inbound/lib/.../inbound_records/` (schema only), `.planning/phases/175-*` (process precedent).
**Files read:** 24 (LiveViews and components read in the cited ranges only; `operator_live.ex` 2825 lines and `inbound_live.ex` 2048 lines were Grep-located then read in non-overlapping slices).
**Pattern extraction date:** 2026-10-28
