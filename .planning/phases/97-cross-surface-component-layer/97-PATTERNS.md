# Phase 97: Cross-Surface Component Layer — Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 18 (1 new + 17 modified)
**Analogs found:** 18 / 18

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass_admin/gallery_live.ex` (NEW) | LiveView | request-response | `lib/mailglass_admin/preview_live.ex` | exact |
| `lib/mailglass_admin/router.ex` | config/macro | request-response | self (existing `live_session` block, lines 219-225) | exact |
| `lib/mailglass_admin/components.ex` | component | transform | self (existing `status_badge`, lines 196-280) | exact |
| `lib/mailglass_admin/operator/shell.ex` | component | request-response | self (existing `nav_link`/`nav_pill`/`theme_toggle`) | exact |
| `lib/mailglass_admin/operator/deliveries_list.ex` | component | CRUD | self (existing row button pattern, lines 29-61) | exact |
| `lib/mailglass_admin/operator/detail_header.ex` | component | request-response | self (line 21 `text-xl`) | exact |
| `lib/mailglass_admin/inbound/detail_header.ex` | component | request-response | self (line 38 `text-xl`) | exact |
| `lib/mailglass_admin/operator/filters_form.ex` | component | request-response | self (existing label spans, lines 16/28/41/58/75) | exact |
| `lib/mailglass_admin/operator/support_cards.ex` | component | CRUD | self (existing `btn-sm btn-primary` buttons, lines 56/102/152/204) | exact |
| `lib/mailglass_admin/operator/timeline.ex` | component | event-driven | self (existing `motion-timeline` container, line 30) | exact |
| `lib/mailglass_admin/operator/replay_modal.ex` | component | request-response | self (existing `role="dialog"` div, lines 19-25) | exact |
| `lib/mailglass_admin/inbound/routing_trace.ex` | component | event-driven | self (existing `border-l-4 border-error`, line 64) | exact |
| `lib/mailglass_admin/inbound/evidence_card.ex` | component | request-response | self (existing `btn-sm min-h-11` button, lines 38-45) | exact |
| `lib/mailglass_admin/preview/device_frame.ex` | component | request-response | self (existing `btn btn-sm join-item` buttons, lines 29-55) | exact |
| `lib/mailglass_admin/preview/tabs.ex` | component | request-response | self (existing `role="tab"` buttons, lines 39-81) | exact |
| `lib/mailglass_admin/preview/sidebar.ex` | component | request-response | self (existing `<summary>` and `<.link>`, lines 75/82) | exact |
| `e2e/structural.spec.js` | test | request-response | self (`openPreview` helper, lines 38-42; skipped block, lines 421-428) | exact |
| `.planning/RATCHET-GAP-REGISTER.md` | config | — | self (GAP-05 row, line 138) | exact |

---

## Pattern Assignments

### `lib/mailglass_admin/gallery_live.ex` (NEW — LiveView, request-response)

**Primary analog:** `lib/mailglass_admin/preview_live.ex`

**Module header + use pattern** (preview_live.ex lines 1-55 structure):
```elixir
defmodule MailglassAdmin.GalleryLive do
  @moduledoc """
  Dev-only component gallery at /dev/mail/gallery.
  ...
  """

  use MailglassAdmin, :live_view

  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.Shell
  # ... alias other component modules as needed for specimens
```

**Mount pattern** (preview_live.ex:57-83 — no session reads, pure assign initialization):
```elixir
@impl true
def mount(_params, _session, socket) do
  socket =
    socket
    |> assign(:page_title, "mailglass — Component Gallery")
    |> assign(:specimens, specimens())   # in-code list, no DB, no mailables

  {:ok, socket}
end
```

**No handle_params needed** — gallery is `:index` only, no URL params drive state.

**In-code specimen list pattern** (module attribute of `[{component_atom, state_label, assigns_map}]` tuples):
```elixir
@specimens [
  # One entry per STATE-LD row × state atom
  {:status_badge, "dispatched", %{status: :dispatched, size: :sm}},
  {:status_badge, "delivered",  %{status: :delivered,  size: :sm}},
  # ... all 22 status atoms + phantom fallback
  {:nav_link, "active",   %{label: "Deliveries", icon: "hero-paper-airplane", href: "#", active: true}},
  {:nav_link, "inactive", %{label: "Deliveries", icon: "hero-paper-airplane", href: "#", active: false}},
  # ... one tuple per component × state per UI-SPEC Per-Component State Contract table
]

defp specimens, do: @specimens
```

**data-theme twin-wrapper pattern** (the established mechanism from shell.ex:119 and preview_live.ex:225):

The gallery render wraps each specimen cell in BOTH themes side-by-side:
```heex
<div data-testid={"gallery-#{component}-#{state}"} class="...cell container...">
  <div data-theme="mailglass-light" class="...">
    <!-- rendered specimen with light theme -->
  </div>
  <div data-theme="mailglass-dark" class="...">
    <!-- same specimen with dark theme -->
  </div>
</div>
```

The `data-theme` attribute is the established mechanism (shell.ex:119):
```elixir
# shell.ex:119
data-theme={if @dark_chrome, do: "mailglass-dark", else: "mailglass-light"}
```
And preview_live.ex:225:
```elixir
# preview_live.ex:225
data-theme={if @dark_chrome, do: "mailglass-dark", else: "mailglass-light"}
```
Gallery uses twin static wrappers, not a conditional — one `data-theme="mailglass-light"` div and one `data-theme="mailglass-dark"` div side-by-side within the same cell.

**render structure** (preview_live.ex:222-228 as structural reference):
```elixir
@impl true
def render(assigns) do
  ~H"""
  <div class="min-h-screen bg-base-100 text-base-content px-md py-xl">
    <h1 class="text-display font-bold tracking-tight text-base-content mb-lg">
      Component Gallery
    </h1>

    <div class="space-y-3xl">
      <%= for {component, states} <- grouped_specimens(@specimens) do %>
        <section>
          <h2 class="text-heading font-bold tracking-tight text-base-content mb-lg">
            {component_label(component)}
          </h2>
          <div class="grid gap-lg">
            <%= for {state, assigns_map} <- states do %>
              <div
                data-testid={"gallery-#{component}-#{state}"}
                class="rounded-box border border-base-300 bg-base-200 p-md space-y-sm"
              >
                <p class="text-label font-bold text-secondary">
                  {component_label(component)} — {state}
                </p>
                <div class="flex gap-md flex-wrap">
                  <div data-theme="mailglass-light" class="rounded-field border border-base-300 bg-base-100 p-sm">
                    <.render_specimen component={component} assigns_map={assigns_map} />
                  </div>
                  <div data-theme="mailglass-dark" class="rounded-field border border-base-300 bg-base-100 p-sm">
                    <.render_specimen component={component} assigns_map={assigns_map} />
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </section>
      <% end %>
    </div>
  </div>
  """
end
```

**File location:** `lib/mailglass_admin/gallery_live.ex` (flat next to `preview_live.ex`, consistent with sibling pattern — no subdirectory needed since it has no sub-components).

---

### `lib/mailglass_admin/router.ex` (config/macro modification)

**Analog:** self (lines 87-95 for `@compile` list; lines 219-225 for `live_session` block)

**`@compile` no_warn_undefined addition** (router.ex:87-95 — add `MailglassAdmin.GalleryLive`):
```elixir
# router.ex:87-95 current
@compile {:no_warn_undefined,
          [
            MailglassAdmin.PreviewLive,
            MailglassAdmin.Preview.Mount,
            MailglassAdmin.OperatorLive,
            MailglassAdmin.Operator.Mount,
            MailglassAdmin.InboundLive,
            MailglassAdmin.Controllers.Assets
          ]}
```
Add `MailglassAdmin.GalleryLive` to this list.

**`live_session` block addition** (router.ex:219-225 — add ONE line inside existing block):
```elixir
# router.ex:219-225 current
live_session session_name,
  session: {MailglassAdmin.Router, :__preview_session__, [opts]},
  on_mount: on_mount_hooks,
  root_layout: {MailglassAdmin.Layouts, :root} do
  live "/", MailglassAdmin.PreviewLive, :index
  live "/:mailable/:scenario", MailglassAdmin.PreviewLive, :show
end
```
Add after the existing two `live` lines:
```elixir
  live "/gallery", MailglassAdmin.GalleryLive, :index
```
Route resolves to `/dev/mail/gallery`. No segment collision: `/gallery` (1 segment) vs `/:mailable/:scenario` (2 segments).

---

### `lib/mailglass_admin/operator/shell.ex` — nav_link focus ring (lines 201-219)

**Action:** ADD `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1` — currently absent (STATE-LD-06).

**Current nav_link class list** (shell.ex:206-213):
```elixir
class={[
  "flex min-h-11 items-center gap-sm rounded-field border-l-2 px-sm text-body transition-colors ease-out",
  "duration-(--duration-fast)",
  if(@active,
    do: "border-primary bg-base-100 font-bold text-base-content",
    else: "border-transparent text-secondary hover:bg-base-100/60 hover:text-base-content"
  )
]}
```

**After uplift** — add focus ring to the static class string (line 207):
```elixir
"flex min-h-11 items-center gap-sm rounded-field border-l-2 px-sm text-body transition-colors ease-out focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1",
```

**Verify:** `aria-current={@active && "page"}` already present at shell.ex:205 — do not regress.

---

### `lib/mailglass_admin/operator/shell.ex` — nav_pill focus ring (lines 225-241)

**Action:** ADD `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1` — currently absent (STATE-LD-06).

**Current nav_pill class list** (shell.ex:231):
```elixir
class={[
  "flex min-h-11 items-center rounded-field px-sm text-body transition-colors ease-out duration-(--duration-fast)",
  if(@active,
    do: "bg-primary/10 font-bold text-base-content",
    else: "text-secondary hover:text-base-content"
  )
]}
```

**After uplift** — add focus ring to the static class string (line 231):
```elixir
"flex min-h-11 items-center rounded-field px-sm text-body transition-colors ease-out duration-(--duration-fast) focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1",
```

**Verify:** `aria-current={@active && "page"}` already present at shell.ex:229 — do not regress.

---

### `lib/mailglass_admin/operator/shell.ex` — theme_toggle min-h-11 (line 266)

**Action:** VERIFY that `min-h-11` wins over `btn-sm` at compiled CSS level. If `btn-sm` sets `min-height` and overrides `min-h-11`, drop `btn-sm` (STATE-LD-08).

**Current** (shell.ex:264-267):
```elixir
class="btn btn-ghost btn-sm btn-square min-h-11"
```

**Resolution rule:** `min-h-11` is a Tailwind utility that sets `min-height: 2.75rem` (44px). daisyUI `btn-sm` sets `min-height: 2rem` (32px). In Tailwind v4 / daisyUI v5, specificity of the later utility wins. Verify by inspecting computed `min-height` in the browser or checking `app.css` generated output. If `btn-sm` wins: change to `class="btn btn-ghost btn-square min-h-11"` (drop `btn-sm`, keep `btn-square` for icon sizing).

**Verify:** `aria-label={if @dark_chrome, ...}` already present at shell.ex:265 — do not regress.

---

### `lib/mailglass_admin/operator/shell.ex` — orientation_strip copy (lines 339, 341, 348)

**Action:** Replace three copy strings per COPY-LD-11/12.

**Current → Correct** (shell.ex:339):
```elixir
# Current
"Email never arrived? Start here."
# Correct
"Delivery never arrived? Start here."
```

**Current → Correct** (shell.ex:341):
```elixir
# Current
"Address keeps getting blocked? Check suppressions."
# Correct
"Address keeps getting blocked? Review the Suppression list."
```

**Current → Correct** (shell.ex:348):
```elixir
# Current
"Message didn't route as expected? Inspect the routing trace."
# Correct
"InboundMessage didn't route as expected? Inspect the routing trace."
```

---

### `lib/mailglass_admin/operator/deliveries_list.ex` — row button focus ring (lines 29-61)

**Action:** ADD `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-inset` to row button class list (STATE-LD-11). Use `ring-inset` (not `ring-offset`) because the button fills the full list item width — an offset ring would clip at the `<li>` boundary.

**Current row button classes** (deliveries_list.ex:37-40):
```elixir
class={[
  "flex min-h-11 w-full flex-col gap-sm px-4 py-4 text-left transition-colors",
  row_classes(@selected_delivery, delivery)
]}
```

**After uplift** — add focus ring to the static string (line 38):
```elixir
"flex min-h-11 w-full flex-col gap-sm px-4 py-4 text-left transition-colors focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-inset",
```

**Existing a11y to verify:** `aria-current` and `aria-selected` at lines 35-36 — do not regress.

---

### `lib/mailglass_admin/operator/detail_header.ex` — text-xl → text-heading (line 21)

**Action:** Replace `text-xl` with `text-heading` (STATE-LD-12, COPY-LD-07).

**Current** (detail_header.ex:21):
```elixir
<h2 class="text-xl font-bold text-base-content">{@delivery.recipient}</h2>
```

**After uplift:**
```elixir
<h2 class="text-heading font-bold text-base-content">{@delivery.recipient}</h2>
```

`text-xl` is a banned raw Tailwind size class (UI-SPEC Typography constraint). `text-heading` resolves to 20px/700 via `app.css` `@theme` `--text-heading` token.

---

### `lib/mailglass_admin/inbound/detail_header.ex` — text-xl → text-heading (line 38)

**Action:** Replace `text-xl` with `text-heading` (STATE-LD-12).

**Current** (inbound/detail_header.ex:37-39):
```elixir
<h2 class="text-xl font-bold text-base-content">
  {Components.mask_recipient(@record.envelope_recipient)}
</h2>
```

**After uplift:**
```elixir
<h2 class="text-heading font-bold text-base-content">
  {Components.mask_recipient(@record.envelope_recipient)}
</h2>
```

---

### `lib/mailglass_admin/operator/filters_form.ex` — remove tracking-[0.08em] from labels

**Action:** Remove `tracking-[0.08em]` from ALL five label `<span>` elements and replace the class list (STATE-LD-13, GAP-04). Arbitrary `tracking-[…]` values are banned by the conformance gate.

**Current label pattern** (filters_form.ex:16-17, repeated at lines 28-29, 41-42, 58-59, 75-76):
```elixir
<span class="mb-1 text-label font-bold uppercase tracking-[0.08em] text-secondary">
  Tenant
</span>
```

**After uplift** — remove `tracking-[0.08em]` (heading tracking is handled by the global `h1,h2,h3` rule; label spans are not headings and should carry no explicit tracking):
```elixir
<span class="mb-1 text-label font-bold uppercase text-secondary">
  Tenant
</span>
```

Apply identically to all five label spans (Tenant, Provider, Status, Event, Window).

---

### `lib/mailglass_admin/operator/support_cards.ex` — btn-sm removal (lines 56, 102, 152, 204)

**Action:** Remove `btn-sm` from three tier-1 action buttons and one tier-2 button; replace with correct class sets (STATE-LD-14, GAP-01).

**Current pattern at lines 56-58** (repeated at 102, 152):
```elixir
class="btn btn-sm btn-primary mt-sm"
```

**After uplift** (lines 56, 102, 152 — tier-1 primary actions):
```elixir
class="btn btn-primary px-md mt-sm min-h-11"
```

**Current at line 204** (tier-2 ghost):
```elixir
class="btn btn-ghost btn-sm px-3"
```

**After uplift** (line 204 — tier-2 ghost):
```elixir
class="btn btn-ghost px-sm min-h-11"
```

`btn-sm` sets `min-height: 2rem` (32px) which fails the 44px touch-target floor. Removing it lets `min-h-11` (44px) apply uncontested.

---

### `lib/mailglass_admin/operator/timeline.ex` — verify motion-timeline and dot classes

**Action:** Verify `motion-timeline` stagger class on `<ol>` container (line 30) and highlighted event border classes (STATE-LD-16).

**Current container** (timeline.ex:30):
```elixir
<ol class="motion-timeline space-y-4">
```
`motion-timeline` is correct — the stagger animation is already wired.

**Highlighted event container pattern** — verify `event_container_class/2` returns `border-primary ring-1 ring-primary/40` when highlighted. Locate that private function and confirm. If missing, add:
```elixir
defp event_container_class(highlight_id, event_id) when highlight_id == event_id,
  do: "border-primary ring-1 ring-primary/40"
defp event_container_class(_highlight_id, _event_id),
  do: "border-base-300"
```

**Dot class pattern** (timeline.ex:41) — verify `event_dot_class/1` returns semantic color per status group:
- Success events: `bg-success`
- Error events: `bg-error`
- Warning events: `bg-warning`
- In-flight: `bg-primary`
- Neutral: `bg-base-300`

---

### `lib/mailglass_admin/operator/replay_modal.ex` — a11y additions (lines 18-25)

**Action:** ADD `id` to modal `h2`, ADD `aria-labelledby` to dialog div, ADD `phx-key="Escape" phx-window-keydown="close_replay"`, ADD `JS.focus_first` on open / `JS.focus` back on close (STATE-LD-17).

**Current dialog div** (replay_modal.ex:20-24):
```elixir
<div
  data-testid="operator-replay-modal"
  role="dialog"
  aria-modal="true"
  class="motion-overlay w-full max-w-2xl rounded-box border border-base-300 bg-base-100 p-6 shadow-overlay"
>
```

**After uplift:**
```elixir
<div
  data-testid="operator-replay-modal"
  role="dialog"
  aria-modal="true"
  aria-labelledby="replay-modal-title"
  phx-key="Escape"
  phx-window-keydown="close_replay"
  class="motion-overlay w-full max-w-2xl rounded-box border border-base-300 bg-base-100 p-6 shadow-overlay"
>
```

**Current h2** (replay_modal.ex:27-29):
```elixir
<h2 class="text-lg font-bold text-base-content">
  Replay webhook for {@delivery.recipient}
</h2>
```

**After uplift** — add `id` + fix typography token:
```elixir
<h2 id="replay-modal-title" class="text-heading font-bold text-base-content">
  Replay webhook for {@delivery.recipient}
</h2>
```

**Copy uplift** (replay_modal.ex:29-32, COPY-LD-13):
```elixir
# Current
<p class="text-body text-secondary">
  Replay is delivery-detail initiated, tenant-scoped, and recorded in the append-only ledger.
</p>
# Correct
<p class="text-body text-secondary">
  Re-dispatches the stored webhook request through Mailbox routing and records a new Event in the append-only ledger. Confirm to replay.
</p>
```

**Confirm button** (replay_modal.ex:100-103) — already `"Confirm replay"` and `btn btn-error` — keep as-is per COPY-LD-07.

**Focus trap:** `JS.focus_first` on modal open (triggered from `detail_header`'s `phx-click="open_replay"`) and `JS.focus` back to the replay-open button on `close_replay`. These are LiveView.JS operations passed via the parent LiveView's event handler, not in the modal component itself. The modal component owns the `aria-labelledby` and keyboard dismiss; the parent LiveView owns the JS focus commands.

---

### `lib/mailglass_admin/inbound/routing_trace.ex` — verify state classes (line 64)

**Action:** Verify all three routing trace states per STATE-LD-18. All required classes are already present in the current code — verify only.

**Empty state** (routing_trace.ex:43-45) — already: `<p class="text-body text-secondary">No inbound routes...`

**First-failing clause** (routing_trace.ex:62-65) — already:
```elixir
class={[
  "space-y-1 rounded-box",
  verdict.first_failing? && "border-l-4 border-error px-3"
]}
```

**Route-level badge** (routing_trace.ex:55) — already: `<span class="badge badge-outline badge-error">No match</span>`. The UI-SPEC calls for `badge-outline badge-error` on the per-route-card badge — present and correct.

No code changes needed — verify only.

---

### `lib/mailglass_admin/inbound/evidence_card.ex` — btn-sm / min-h-11 (lines 38-45)

**Action:** VERIFY `min-h-11` overrides `btn-sm` on the reveal button; if not, drop `btn-sm` (STATE-LD-19).

**Current reveal button** (evidence_card.ex:38-45):
```elixir
<button
  :if={@evidence && @reveal_state != :revealed}
  type="button"
  phx-click="reveal_raw"
  data-testid="inbound-evidence-reveal"
  class="btn btn-ghost btn-sm min-h-11 px-4"
>
  Reveal raw source
</button>
```

Same resolution rule as `theme_toggle`: if `btn-sm` overrides `min-h-11` at compiled CSS level, change to:
```elixir
class="btn btn-ghost min-h-11 px-4"
```

**Revealed `<pre>` pattern** (STATE-LD-19) — add if not already present:
```elixir
<pre class="max-h-80 overflow-auto rounded-box border border-base-300 bg-base-100 text-label text-base-content">{@evidence.raw_payload}</pre>
```

---

### `lib/mailglass_admin/preview/device_frame.ex` — min-h-11 on all buttons (lines 29-55)

**Action:** ADD `min-h-11` to all three buttons alongside existing `btn-sm` (STATE-LD-20); verify compiled min-height.

**Current button class** (device_frame.ex:34, 43, 52):
```elixir
class={["btn btn-sm join-item", button_classes(@device_width == 375)]}
```

**After uplift:**
```elixir
class={["btn btn-sm min-h-11 join-item", button_classes(@device_width == 375)]}
```

Apply to all three buttons (375, 768, 1024). `aria-pressed` already implemented — do not regress.

Same compiled-CSS verification as theme_toggle: if `btn-sm` wins, drop `btn-sm`.

---

### `lib/mailglass_admin/preview/tabs.ex` — focus ring, ARIA, empty pane (lines 35-97)

**Action:** ADD focus ring to four tab buttons; ADD `aria-controls` + `role="tabpanel"` + `aria-labelledby`; ADD empty HTML body placeholder (STATE-LD-21).

**Current tab button class** (tabs.ex:45, 55, 65, 76):
```elixir
class={["px-4 py-2 min-h-10 text-body transition-colors", tab_classes(@active_tab == :html)]}
```

**After uplift** — fix `min-h-10` → `min-h-11` (44px floor) and add focus ring and `aria-controls`:
```elixir
<button
  role="tab"
  type="button"
  phx-click="set_tab"
  phx-value-tab="html"
  id="tab-btn-html"
  aria-selected={to_string(@active_tab == :html)}
  aria-controls="tab-panel-html"
  class={["px-4 py-2 min-h-11 text-body transition-colors focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-inset", tab_classes(@active_tab == :html)]}
>
  HTML
</button>
```

Repeat for `text`, `raw`, `headers` tabs with matching `id="tab-btn-{tab}"` and `aria-controls="tab-panel-{tab}"`.

**Content div** (tabs.ex:84) — add `role="tabpanel"` and `aria-labelledby`:
```elixir
<div
  id={"tab-panel-" <> Atom.to_string(@active_tab)}
  role="tabpanel"
  aria-labelledby={"tab-btn-" <> Atom.to_string(@active_tab)}
  class="motion-tab-swap"
>
```

Note: rename outer `id` from `"preview-tab-..."` to `"tab-panel-..."` to match `aria-controls`.

**Empty HTML body placeholder** — in `tab_content(%{active_tab: :html})` (tabs.ex:107-120), add conditional:
```elixir
def tab_content(%{active_tab: :html} = assigns) do
  ~H"""
  <div class="overflow-auto">
    <%= if @html_body == "" do %>
      <p class="text-body text-secondary py-lg text-center">
        No HTML body — this Mailable's template returned empty content.
      </p>
    <% else %>
      <iframe
        srcdoc={@html_body}
        sandbox="allow-same-origin"
        style={"width: #{@device_width}px; height: 600px; border: 1px solid var(--color-base-300); border-radius: var(--radius-box); background: var(--color-base-100);"}
        phx-update="ignore"
        id={"preview-iframe-" <> Integer.to_string(@render_nonce)}
        title="Email HTML preview"
      />
    <% end %>
  </div>
  """
end
```

---

### `lib/mailglass_admin/preview/sidebar.ex` — focus rings, border-l assessment (lines 40-152)

**Action:** ADD `focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1` to `<summary>` and scenario `<.link>`; ASSESS `border-l-[3px]` → `border-l-2` (STATE-LD-22).

**Current `<summary>` class** (sidebar.ex:75):
```elixir
<summary class="flex items-center gap-2 px-3 py-2 min-h-11 text-body font-bold text-base-content cursor-pointer hover:bg-base-200 rounded transition-colors">
```

**After uplift:**
```elixir
<summary class="flex items-center gap-2 px-3 py-2 min-h-11 text-body font-bold text-base-content cursor-pointer hover:bg-base-200 rounded transition-colors focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1">
```

**Current `<.link>` class** (sidebar.ex:82-86 via `scenario_classes/4`):
```elixir
defp scenario_classes(current_mod, current_scenario, mod, scenario)
     when current_mod == mod and current_scenario == scenario do
  "border-l-[3px] border-primary bg-base-200 text-base-content font-normal"
end

defp scenario_classes(_current_mod, _current_scenario, _mod, _scenario) do
  "border-l-[3px] border-transparent text-secondary hover:bg-base-200"
end
```

**After uplift** — the `<.link>` itself (sidebar.ex:81) needs focus ring added to the static class attribute, AND `border-l-[3px]` → `border-l-2` in `scenario_classes/4`:
```elixir
<.link
  patch={...}
  class={[
    "flex items-center gap-2 px-3 py-2 min-h-11 text-body truncate transition-colors focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1",
    scenario_classes(@current_mailable, @current_scenario, @mod, scenario_name)
  ]}
>
```

And update `scenario_classes/4`:
```elixir
defp scenario_classes(...) when active,
  do: "border-l-2 border-primary bg-base-200 text-base-content font-normal"

defp scenario_classes(...),
  do: "border-l-2 border-transparent text-secondary hover:bg-base-200"
```

`border-l-[3px]` is an arbitrary value; `border-l-2` (2px) is the closest Tailwind scale value and aligns with `nav_link`'s `border-l-2` (shell.ex:207).

---

### `e2e/structural.spec.js` — un-skip gallery block (lines 421-428)

**Analog:** `openPreview` helper (structural.spec.js:38-42) for the new `openGallery` helper; existing `getByTestId` + `toBeVisible` pattern throughout the file for structural assertions.

**Current skipped block** (structural.spec.js:421-428):
```javascript
test.describe.skip("gallery surface — deferred to Phase 97", () => {
  test("gallery structural assertions", async () => {
    test.skip(
      true,
      "gallery at /dev/mail/gallery does not exist yet; RATCHET-GAP-REGISTER.md GAP row tracks this"
    );
  });
});
```

**openPreview pattern to copy** (structural.spec.js:38-42):
```javascript
async function openPreview(page) {
  await page.goto("/ops/browser-preview-empty");
  await expect(page.getByTestId("preview-orientation")).toBeVisible();
}
```

**After uplift** — add `openGallery` helper (mirroring `openPreview` but direct GET, no session needed):
```javascript
// Opens the Gallery surface via the dev route — no auth, no session setup
async function openGallery(page) {
  await page.goto("/dev/mail/gallery");
  await expect(page.getByRole("heading", { name: "Component Gallery", level: 1 })).toBeVisible();
}
```

**Replace the skipped block** with real assertions:
```javascript
test.describe("gallery surface — Phase 97", () => {
  test("gallery renders status_badge specimens for all status groups", async ({ page }) => {
    await openGallery(page);

    // Verify a specimen from each daisyUI badge group
    await expect(page.getByTestId("gallery-status_badge-delivered")).toBeVisible();
    await expect(page.getByTestId("gallery-status_badge-dispatched")).toBeVisible();
    await expect(page.getByTestId("gallery-status_badge-bounced")).toBeVisible();
    await expect(page.getByTestId("gallery-status_badge-deferred")).toBeVisible();
    await expect(page.getByTestId("gallery-status_badge-autoresponded")).toBeVisible();
  });

  test("gallery renders nav_link active + inactive states", async ({ page }) => {
    await openGallery(page);

    await expect(page.getByTestId("gallery-nav_link-active")).toBeVisible();
    await expect(page.getByTestId("gallery-nav_link-inactive")).toBeVisible();
  });

  test("gallery twin-theme wrappers present on each cell", async ({ page }) => {
    await openGallery(page);

    // Each cell has both data-theme wrappers
    const cell = page.getByTestId("gallery-status_badge-delivered");
    await expect(cell.locator('[data-theme="mailglass-light"]')).toBeVisible();
    await expect(cell.locator('[data-theme="mailglass-dark"]')).toBeVisible();
  });

  test("gallery: accent color confined to allowlisted elements", async ({ page }) => {
    await openGallery(page);

    // Check that non-active badge cells don't carry the accent color outside the allowlist
    // (mirrors the accent-allowlist assertion pattern from FACT 2 in this file)
    const lightCell = page.getByTestId("gallery-status_badge-delivered")
      .locator('[data-theme="mailglass-light"]');
    // badge-success should not be accent-colored
    const badge = lightCell.getByRole("status").first();
    // ...assertion using isAccentAllowlisted per existing pattern
  });
});
```

---

## Shared Patterns

### focus-visible ring pattern
**Source:** established project convention (semantic token, no arbitrary values)
**Apply to:** nav_link, nav_pill (shell.ex:206-213, 231), deliveries_list row button, tabs tab buttons, sidebar `<summary>` and scenario `<.link>`

```elixir
# For elements with external borders (most cases):
"focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1"

# For elements that fill a container (list rows, tab buttons):
"focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-inset"
```

`ring-primary` resolves to Glass #277B96 in light theme and Ice #A6EAF2 in dark theme (DARK-LD-03) via semantic token — never hardcoded color.

### min-h-11 touch target enforcement
**Source:** UI-SPEC Global Rules (44px floor), existing pattern at shell.ex:207, deliveries_list.ex:38, replay_modal.ex:92
**Apply to:** theme_toggle (shell.ex:266), device_frame buttons (device_frame.ex:34/43/52), evidence_card reveal button (evidence_card.ex:43), support_cards tier-1 buttons (support_cards.ex:56/102/152), tabs tab buttons
**Rule:** `min-h-11` must appear on the same element as `btn-sm` — verify at runtime that it wins; if not, drop `btn-sm`.

### btn-sm removal
**Source:** STATE-LD-08, STATE-LD-14, STATE-LD-19, STATE-LD-20
**Apply to:** support_cards.ex lines 56/102/152, evidence_card.ex line 43
**Rule:** `btn-sm` is banned wherever it would reduce min-height below 44px. Replace `btn btn-sm btn-primary` → `btn btn-primary px-md min-h-11`; `btn btn-ghost btn-sm` → `btn btn-ghost px-sm min-h-11`.

### tracking-[0.08em] removal (arbitrary value ban)
**Source:** UI-SPEC Typography, GAP-04
**Apply to:** filters_form.ex label spans (5 occurrences); also note in replay_modal.ex target_card `dt` at line 133 and detail_header.ex `dt` at lines 32/36/41/45 — those are `tracking-[0.08em]` on `dt` elements which are also banned; assess each for replacement with the global heading tracking or removal.

**Pattern to check:** `tracking-[0.08em]` appears on `dt` labels throughout detail_header, support_cards, timeline, and evidence_card. Phase 97 scope is filters_form labels (STATE-LD-13 / GAP-04 explicitly). The other `dt` occurrences should be noted for Phase 98/101 but NOT changed in Phase 97 (out of scope).

### text-xl ban (typography token enforcement)
**Source:** UI-SPEC Typography, STATE-LD-12
**Apply to:** operator/detail_header.ex:21, inbound/detail_header.ex:38
**Replacement:** `text-xl` → `text-heading` (20px token, defined in `app.css` `@theme` block)

### data-theme wrapping (established theme mechanism)
**Source:** shell.ex:119, preview_live.ex:225
**Apply to:** `GalleryLive` render (twin static wrappers per cell)
```elixir
# Shell sets theme on the root div dynamically:
data-theme={if @dark_chrome, do: "mailglass-dark", else: "mailglass-light"}

# Gallery uses twin static wrappers to show both themes simultaneously:
<div data-theme="mailglass-light">...</div>
<div data-theme="mailglass-dark">...</div>
```

### data-testid kebab naming
**Source:** structural.spec.js:29, shell.ex:320
**Apply to:** all gallery specimens
```
gallery-{component}-{state}     # e.g. gallery-status_badge-delivered
{surface}-{component}           # existing pattern for non-gallery (operator-delivery-row)
```

### motion class application
**Source:** app.css (motion-reveal, motion-timeline, motion-overlay, motion-tab-swap)
**Apply to:** verify existing classes — `motion-reveal` on flash (components.ex:105), `motion-timeline` on timeline ol (timeline.ex:30), `motion-overlay` on replay_modal dialog (replay_modal.ex:23). No new motion classes added in Phase 97.

---

## No Analog Found

All Phase 97 files have direct analogs or are self-referential modifications. No files require fallback to RESEARCH.md patterns.

---

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/`, `mailglass_admin/e2e/`, `.planning/`
**Files scanned:** 18 source files read in full or in targeted sections
**Key insight:** Every modification is an in-place uplift of existing components. The one new file (`GalleryLive`) maps cleanly to `PreviewLive` for mount/render structure, and to the twin `data-theme` wrapper pattern already established in `shell.ex` and `preview_live.ex`. No new patterns are invented — all patterns are extracted from the existing codebase.
