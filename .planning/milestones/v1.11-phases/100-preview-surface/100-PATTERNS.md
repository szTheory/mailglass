# Phase 100: Preview Surface - Pattern Map

**Mapped:** 2026-06-15
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mailglass_admin/lib/mailglass_admin/preview_live.ex` | controller/liveview | request-response + event-driven | `mailglass_admin/lib/mailglass_admin/inbound_live.ex` + current `preview_live.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` | layout/config | request-response | `mailglass_admin/lib/mailglass_admin/operator/shell.ex` | role-match |
| `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` | component | request-response | current `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` | component | event-driven form transform | current `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` + `operator_live.ex` filter controls | exact |
| `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` | component | request-response | current `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/preview/device_frame.ex` | component | event-driven controls | current `mailglass_admin/lib/mailglass_admin/preview/device_frame.ex` | exact |
| `mailglass_admin/e2e/structural.spec.js` | test | browser request-response | existing `structural.spec.js` inbound/operator sections | exact |
| `mailglass_admin/test/mailglass_admin/preview_live_test.exs` | test | LiveView request-response + event-driven | current `preview_live_test.exs` | exact |
| `mailglass_admin/test/support/endpoint_case.ex` | test/support route | request-response/session setup | current `endpoint_case.ex` preview empty route | role-match |
| `mailglass_admin/scripts/ui-audit.sh` | utility/script | batch file-I/O + browser capture | current `ui-audit.sh` deliveries/inbound loops | exact |
| `mailglass_admin/mix.exs` | config/build | batch | current `mix.exs` `verify.preview` alias | exact |
| `mailglass_admin/priv/static/app.css` | generated asset | file-I/O | `mailglass_admin/assets/css/app.css` + `mix.exs` build alias | generated |

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/preview_live.ex` (controller/liveview, request-response + event-driven)

**Analog:** `mailglass_admin/lib/mailglass_admin/inbound_live.ex` for URL-backed chrome theme; current `preview_live.ex` for Preview rendering and error handling.

**Imports pattern** (current Preview, lines 47-55):
```elixir
use Phoenix.LiveView

alias MailglassAdmin.Components
alias MailglassAdmin.Preview.AssignsForm
alias MailglassAdmin.Preview.DeviceFrame
alias MailglassAdmin.Preview.Discovery
alias MailglassAdmin.Preview.Sidebar
alias MailglassAdmin.Preview.Tabs
alias MailglassAdmin.PubSub.Topics
```

**URL theme + patch pattern** (Inbound, lines 117-149):
```elixir
def handle_params(params, uri, socket) do
  filter_params = normalize_filter_params(params)

  {:noreply,
   socket
   |> assign(:base_path, URI.parse(uri).path || "/inbound")
   |> assign(:page_uri, uri)
   |> assign(:dark_chrome, MailglassAdmin.Operator.Shell.dark_chrome?(params))
   |> assign(:filter_params, filter_params)
   |> assign(:filter_form, to_form(filter_params, as: :filters))
   |> assign_inbound_state(filter_params, blank_to_nil(params["inbound_id"]))
   |> close_replay_modal()}
end

def handle_event("toggle_theme", _params, socket) do
  {:noreply,
   push_patch(socket,
     to:
       MailglassAdmin.Operator.Shell.toggle_theme_path(
         socket.assigns.page_uri,
         socket.assigns.dark_chrome
       )
   )}
end
```

**Existing Preview URL-state pattern to preserve and split** (current Preview, lines 86-144):
```elixir
def handle_params(%{"mailable" => mod_str, "scenario" => name_str} = params, uri, socket) do
  {device_width, theme} = normalize_capture_url_state(params, socket)
  base_path = uri_path(uri)

  with {:ok, mailable} <- safe_mailable_atom(mod_str),
       {:ok, scenario} <- safe_scenario_atom(name_str),
       {:ok, defaults} <-
         lookup_scenario_defaults(socket.assigns.mailables, mailable, scenario) do
    socket =
      socket
      |> assign(:current_mailable, mailable)
      |> assign(:current_scenario, scenario)
      |> assign(:current_assigns, current_assigns)
      |> assign(:device_width, device_width)
      |> assign(:dark_chrome, theme == "dark")
      |> assign(:base_path, base_path)
      |> assign(:page_title, "mailglass - " <> to_string(scenario))
      |> rerender()

    {:noreply, socket}
  else
    {:error, {:preview_props_raised, msg}} ->
      {:noreply,
       socket
       |> assign(:current_mailable, mailable)
       |> assign(:current_scenario, :__error__)
       |> assign(:device_width, device_width)
       |> assign(:dark_chrome, theme == "dark")
       |> assign(:base_path, base_path)
       |> assign(:render_error, msg)
       |> assign(:page_title, "mailglass - error")}
  end
end

def handle_params(_params, _uri, socket) do
  {:noreply,
   socket
   |> assign(:current_mailable, nil)
   |> assign(:current_scenario, nil)
   |> assign(:base_path, nil)
   |> assign(:page_title, "mailglass - Preview")}
end
```

**Planner note:** Update the index-route `handle_params/3` branch to parse `?theme=dark|light` too. Do not leave dark handling only in the `:show` route.

**Core render composition pattern** (current Preview, lines 224-290):
```elixir
<div
  data-theme={if @dark_chrome, do: "mailglass-dark", else: "mailglass-light"}
  class="min-h-screen bg-base-100 flex"
>
  <aside class="w-80 bg-base-200 border-r border-base-300 p-6 hidden md:block">
    <Sidebar.sidebar
      mailables={@mailables}
      current_mailable={@current_mailable}
      current_scenario={@current_scenario}
      device_width={@device_width}
      dark_chrome={@dark_chrome}
    />
  </aside>

  <main class="flex-1 p-8">
    <%= cond do %>
      <% @current_scenario -> %>
        <header class="flex items-center justify-between mb-6 gap-md flex-wrap">
          <DeviceFrame.device_frame device_width={@device_width} />
          <button type="button" phx-click="toggle_dark" class="btn btn-ghost btn-sm btn-square">
            <Components.icon name={if @dark_chrome, do: "hero-sun", else: "hero-moon"} class="w-5 h-5" />
          </button>
        </header>

        <AssignsForm.assigns_form scenario_assigns={@current_assigns} />
        <Tabs.tabs active_tab={@active_tab} html_body={@html_body} text_body={@text_body} raw_envelope={@raw_envelope} headers={@headers} device_width={@device_width} render_nonce={@render_nonce} />
    <% end %>
  </main>
</div>
```

**Error handling pattern** (current Preview, lines 572-602):
```elixir
defp rerender(socket) do
  try do
    case build_and_render(mod, scenario, assigns_map) do
      {:ok, rendered} ->
        socket
        |> assign(:html_body, email.html_body || "")
        |> assign(:text_body, email.text_body || "")
        |> assign(:render_error, nil)

      {:error, %Mailglass.TemplateError{} = err} ->
        assign(socket, :render_error, Exception.message(err))

      {:error, other} ->
        assign(socket, :render_error, inspect(other))
    end
  rescue
    e ->
      assign(socket, :render_error, Exception.format(:error, e, __STACKTRACE__))
  end
end
```

### `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` (layout/config, request-response)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex`

**Current root behavior to fix** (root layout, lines 1-10):
```heex
<!DOCTYPE html>
<html lang="en" data-theme={if assigns[:dark_chrome], do: "mailglass-dark", else: "mailglass-light"}>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
    <.live_title suffix=" - mailglass">
      <%= assigns[:page_title] || "Preview" %>
    </.live_title>
```

**Theme owner pattern** (Operator shell, lines 118-120):
```heex
<div
  data-theme={if @dark_chrome, do: "mailglass-dark", else: "mailglass-light"}
  class="flex min-h-screen bg-base-100 text-base-content"
>
```

**Planner note:** Avoid a forced root `mailglass-light` fallback when no explicit `:dark_chrome` assign exists. The root/page theme must not fight daisyUI `prefersdark: true` from `assets/css/app.css` lines 61-63.

### `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` (component, request-response)

**Analog:** current `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex`

**Imports and attrs pattern** (lines 22-30):
```elixir
use Phoenix.Component

alias MailglassAdmin.Components

attr(:mailables, :list, required: true)
attr(:current_mailable, :atom, default: nil)
attr(:current_scenario, :atom, default: nil)
attr(:device_width, :integer, default: 768)
attr(:dark_chrome, :boolean, default: false)
```

**Native details/summary hierarchy** (lines 72-93):
```heex
<details open={@current_mailable == @mod}>
  <summary class="flex items-center gap-2 px-3 py-2 min-h-11 text-body font-bold text-base-content cursor-pointer hover:bg-base-200 rounded transition-colors focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1">
    <span class="truncate">{inspect(@mod)}</span>
  </summary>
  <ul class="mt-1 ml-2">
    <%= for {scenario_name, _defaults} <- @reflection do %>
      <li>
        <.link
          patch={scenario_path(@mod, scenario_name, @device_width, @dark_chrome)}
          class={[
            "flex items-center gap-2 px-3 py-2 min-h-11 text-body truncate transition-colors focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-1",
            scenario_classes(@current_mailable, @current_scenario, @mod, scenario_name)
          ]}
        >
          {Atom.to_string(scenario_name)}
        </.link>
      </li>
    <% end %>
  </ul>
</details>
```

**Relative scenario path pattern** (lines 121-132):
```elixir
defp scenario_path(mod, scenario, width, dark_chrome) do
  "./" <>
    inspect(mod) <>
    "/" <>
    Atom.to_string(scenario) <>
    "?width=" <>
    Integer.to_string(width) <>
    "&theme=" <>
    theme_param(dark_chrome)
end
```

**Planner note:** Keep the relative paths and native hierarchy. If mobile placement renders Sidebar twice, add stable wrapper `data-testid`s and avoid duplicate `h1` output.

### `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` (component, event-driven form transform)

**Analog:** current `assigns_form.ex`; Operator/Inbound filter controls for touch target floor.

**Form event pattern** (AssignsForm, lines 42-57):
```heex
<form phx-change="assigns_changed" class="assigns-form space-y-4">
  <%= for {key, value} <- Enum.sort_by(@scenario_assigns, fn {k, _} -> Atom.to_string(k) end) do %>
    <.field key={key} value={value} />
  <% end %>

  <div class="flex gap-2">
    <button type="button" class="btn btn-primary btn-sm" phx-click="render_preview">
      Render preview
    </button>
    <button type="button" class="btn btn-ghost btn-sm" phx-click="reset_assigns">
      Reset assigns
    </button>
  </div>
</form>
```

**Touch-target control pattern** (Operator, lines 397-400):
```heex
<div class="flex flex-wrap gap-2">
  <button type="submit" class="btn btn-primary min-h-11 px-5">Open delivery</button>
  <button type="button" phx-click="clear_filters" class="btn btn-ghost min-h-11 px-5">
    Clear filters
  </button>
</div>
```

**Field dispatch pattern** (AssignsForm, lines 64-89):
```elixir
def field(%{value: v} = assigns) when is_binary(v) do
  ~H"""
  <label class="form-control w-full">
    <span class="label-text text-body font-normal">{humanize(@key)}</span>
    <input
      type="text"
      name={"assigns[" <> Atom.to_string(@key) <> "]"}
      value={@value}
      class="input input-bordered input-sm w-full"
    />
  </label>
  """
end

def field(%{value: v} = assigns) when is_integer(v) do
  ~H"""
  <input type="number" step="1" name={"assigns[" <> Atom.to_string(@key) <> "]"} value={Integer.to_string(@value)} class="input input-bordered input-sm w-full" />
  """
end
```

### `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` (component, request-response)

**Analog:** current `tabs.ex`

**Tab ARIA pattern** (lines 35-60):
```heex
<div role="tablist" class="flex border-b border-base-300" aria-label="Preview format">
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

**Iframe preview pattern** (lines 120-135):
```heex
<iframe
  srcdoc={@html_body}
  sandbox="allow-same-origin"
  style={"width: #{@device_width}px; height: 600px; border: 1px solid var(--color-base-300); border-radius: var(--radius-box); background: var(--color-base-100);"}
  phx-update="ignore"
  id={"preview-iframe-" <> Integer.to_string(@render_nonce)}
  title="Email HTML preview"
/>
```

**Planner note:** Add `data-testid` hooks to the tab strip and preview pane, but do not add a child `data-theme` wrapper unless it represents the independent previewed-message/frame theme.

### `mailglass_admin/lib/mailglass_admin/preview/device_frame.ex` (component, event-driven controls)

**Analog:** current `device_frame.ex`

**Segmented control pattern** (lines 26-56):
```heex
<div class="join" role="group" aria-label="Preview device width">
  <button
    type="button"
    phx-click="set_device"
    phx-value-width="375"
    aria-pressed={to_string(@device_width == 375)}
    class={["btn btn-sm min-h-11 join-item", button_classes(@device_width == 375)]}
  >
    375
  </button>
</div>
```

### `mailglass_admin/e2e/structural.spec.js` (test, browser request-response)

**Analog:** existing `structural.spec.js` inbound contrast and responsive tests.

**Helper/open pattern** (lines 60-64):
```javascript
async function openPreview(page) {
  await page.goto("/ops/browser-preview-empty");
  await expect(page.getByTestId("preview-orientation")).toBeVisible();
}
```

**Contrast helper pattern** (lines 188-205):
```javascript
async function assertTextContrastAA(locator, label) {
  await expect(locator.first(), label).toBeVisible();
  const colors = await resolvedColors(locator);
  const foreground = parseRgbColor(colors.color);
  const background = parseRgbColor(colors.backgroundColor);
  expect(foreground, `${label} foreground color parses`).not.toBeNull();
  expect(background, `${label} background color parses`).not.toBeNull();
  expect(contrastRatio(foreground, background), `${label} text contrast`).toBeGreaterThanOrEqual(4.5);
}

async function assertNonTextContrastAA(locator, label) {
  await expect(locator.first(), label).toBeVisible();
  const colors = await resolvedColors(locator);
  const stroke = parseRgbColor(colors.outlineColor) || parseRgbColor(colors.borderColor);
  const background = parseRgbColor(colors.backgroundColor);
  expect(contrastRatio(stroke, background), `${label} non-text contrast`).toBeGreaterThanOrEqual(3);
}
```

**Responsive matrix pattern** (Inbound, lines 532-551):
```javascript
const themes = [
  { name: "light", query: "", expectedTheme: "mailglass-light" },
  { name: "dark", query: "theme=dark", expectedTheme: "mailglass-dark" }
];
const viewports = [
  { width: 390, height: 844 },
  { width: 768, height: 900 },
  { width: 1440, height: 1000 }
];

for (const theme of themes) {
  for (const viewport of viewports) {
    await page.setViewportSize(viewport);
    const query = `tenant_id=${tenantId}${theme.query ? `&${theme.query}` : ""}`;
    await openInbound(page, query);
    await expect(page.locator(`[data-theme="${theme.expectedTheme}"]`).first()).toBeVisible();
```

**Touch/focus patterns** (lines 305-332 and 661-680):
```javascript
test("Preview: any visible button or link >= 44px at 390px viewport", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/ops/browser-preview-empty");
  await expect(page.getByTestId("preview-orientation")).toBeVisible();

  const buttons = page.getByRole("button");
  const links = page.getByRole("link");
  const box = await links.first().boundingBox();
  expect(box.height).toBeGreaterThanOrEqual(44);
});

test("Preview: first link or button has non-zero outlineWidth on focus", async ({ page }) => {
  await openPreview(page);
  const focusable = linkCount > 0 ? links.first() : buttons.first();
  await focusable.focus({ timeout: 5000 });
  const outlineWidth = await focusable.evaluate(el => getComputedStyle(el).outlineWidth);
  expect(parseFloat(outlineWidth)).toBeGreaterThan(0);
});
```

**Planner note:** Replace broad "any visible" Preview assertions with named Preview group/test-id assertions for shell, mobile mailables navigation, header controls, assigns form, tab strip, and preview pane.

### `mailglass_admin/test/mailglass_admin/preview_live_test.exs` (test, LiveView request-response + event-driven)

**Analog:** current `preview_live_test.exs`

**Setup pattern** (lines 13-26):
```elixir
use MailglassAdmin.LiveViewCase, async: false

alias MailglassAdmin.Fixtures.{HappyMailer, StubMailer, BrokenMailer}

@fixture_mailables [HappyMailer, StubMailer, BrokenMailer]

setup %{conn: conn} do
  conn = Plug.Test.init_test_session(conn, %{"mailables" => @fixture_mailables})
  {:ok, conn: conn}
end
```

**URL-state tests** (lines 122-156):
```elixir
describe "URL capture state" do
  @tag :url_state
  test "width= and theme= URL params are applied on mount for scenario routes", %{conn: conn} do
    path = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default?width=375&theme=dark"
    {:ok, _view, html} = live(conn, path)

    assert html =~ "width: 375px"
    assert html =~ ~s|data-theme="mailglass-dark"|
  end

  test "set_device and toggle_dark keep canonical width/theme URL params", %{conn: conn} do
    base_path = "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default"
    {:ok, view, _html} = live(conn, base_path <> "?width=768&theme=light")

    render_click(view, "set_device", %{"width" => "375"})
    assert_patch(view, base_path <> "?width=375&theme=light")

    render_click(view, "toggle_dark", %{})
    assert_patch(view, base_path <> "?width=375&theme=dark")
  end
end
```

**Event/form test pattern** (lines 176-188):
```elixir
describe "assigns form" do
  @tag :assigns_form
  test "assigns form re-renders preview on change", %{conn: conn} do
    {:ok, view, _html} =
      live(conn, "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default")

    after_change =
      render_change(view, "assigns_changed", %{"assigns" => %{"user_name" => "Grace"}})

    assert after_change =~ "Hi Grace"
  end
end
```

**Planner note:** Add/adjust tests for `/dev/mail?theme=dark` index route, single `h1`, locked Preview copy, mobile nav test ids, and independent admin chrome vs previewed-message/frame state if that state is split.

### `mailglass_admin/test/support/endpoint_case.ex` (test/support route, request-response/session setup)

**Analog:** current preview-empty route helper.

**Existing route/session pattern** (grep-verified lines 63-65 and 118-124):
```elixir
# route shape includes "/browser-preview-empty", :preview_empty

# Sets the preview mailables session key to [] so the preview surface renders its
# empty state.
def preview_empty(conn, _params) do
  conn
  |> Plug.Conn.put_session("mailables", [])
  |> Phoenix.Controller.redirect(to: "/dev/mail/")
end
```

**Planner note:** Prefer direct `/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default` fixture URLs for real Preview JTBD coverage; keep `/ops/browser-preview-empty` for no-Mailables coverage.

### `mailglass_admin/scripts/ui-audit.sh` (utility/script, batch browser capture)

**Analog:** current deliveries/inbound loops and Preview loop.

**Matrix declaration pattern** (lines 4-12):
```bash
# Captures the full audit matrix:
#   Viewports : 390  768  1440 (px width)
#   Themes    : light  dark
#   Surfaces  : preview  deliveries  inbound
#
# Total cells: 3 viewports x 2 themes x 3 surfaces = 18 PNG files.
# PNGs are named deterministically:
#   {surface}-{viewport}-{theme}.png
```

**Preview loop to update** (lines 65-81):
```bash
# Preview surface (dev surface) - /dev/mail/
# Trailing slash keeps relative stylesheet resolving correctly.
# Preview has no theme param in the current routing contract; capture light
# only (the theme param has no effect on this surface). Dark is included so
# the gap register can note the absence if the surface ever gains dark support.
for vp in $VIEWPORTS; do
  for theme in light dark; do
    set_viewport "$vp"
    if [ "$theme" = "dark" ]; then
      shot "$BASE/dev/mail/?theme=dark" "preview-${vp}-dark"
    else
      shot "$BASE/dev/mail/" "preview-${vp}-light"
    fi
  done
done
```

**Deliveries/inbound dark URL pattern** (lines 93-115):
```bash
if [ "$theme" = "dark" ]; then
  shot "$BASE/ops/mail/?tenant_id=${TENANT}&theme=dark" "deliveries-${vp}-dark"
else
  shot "$BASE/ops/mail/?tenant_id=${TENANT}" "deliveries-${vp}-light"
fi

if [ "$theme" = "dark" ]; then
  shot "$BASE/ops/mail/inbound?tenant_id=${TENANT}&theme=dark" "inbound-${vp}-dark"
else
  shot "$BASE/ops/mail/inbound?tenant_id=${TENANT}" "inbound-${vp}-light"
fi
```

**Planner note:** Keep the behavior but update stale comments so they no longer say Preview dark mode is absent.

### `mailglass_admin/mix.exs` and `mailglass_admin/priv/static/app.css` (config/generated asset, batch file-I/O)

**Analog:** current `verify.preview` alias and CSS input theme config.

**Verification alias pattern** (mix.exs lines 180-188):
```elixir
defp aliases do
  [
    "verify.preview": [
      "compile --no-optional-deps --warnings-as-errors",
      "test --warnings-as-errors --exclude flaky",
      "mailglass_admin.assets.build",
      "cmd git diff --exit-code priv/static/"
    ],
```

**Theme config anchors** (`assets/css/app.css`, grep-verified lines 23-25 and 61-63):
```css
name: "mailglass-light";
prefersdark: false;

name: "mailglass-dark";
prefersdark: true;
```

**Planner note:** Any class changes require `mix mailglass_admin.assets.build` and committing the regenerated `mailglass_admin/priv/static/app.css`.

## Shared Patterns

### URL-Backed Admin Chrome Theme

**Source:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex` lines 59-83 and `inbound_live.ex` lines 117-149.
**Apply to:** `preview_live.ex`, root/layout theme interaction, structural tests, audit script.

```elixir
def dark_chrome?(params) when is_map(params),
  do: Map.get(params, "theme") in ["dark", "mailglass-dark"]

def dark_chrome?(_params), do: false

def toggle_theme_path(uri, currently_dark?) when is_binary(uri) do
  parsed = URI.parse(uri)
  query = URI.decode_query(parsed.query || "")

  query =
    if currently_dark?,
      do: Map.delete(query, "theme"),
      else: Map.put(query, "theme", "dark")

  path = parsed.path || "/"

  case URI.encode_query(query) do
    "" -> path
    encoded -> path <> "?" <> encoded
  end
end
```

### Tokenized Surface Rhythm

**Source:** `operator_live.ex` lines 367-410 and `inbound_live.ex` lines 292-334.
**Apply to:** Preview shell/root, mobile nav panel, empty/start groups, header controls, assigns group, tab/pane groups.

```heex
<section
  data-testid="operator-filters"
  class="card rounded-box border border-base-300 bg-base-200 p-4 md:p-5"
>
  <button
    type="button"
    phx-click={JS.toggle(to: "#operator-filter-panel")}
    data-testid="operator-filters-toggle"
    class="btn btn-ghost !h-11 min-h-11 md:hidden"
  >
    Filters <span aria-hidden="true">v</span>
  </button>
</section>

<section
  data-testid="operator-master-detail"
  class="mt-6 grid gap-lg md:grid-cols-[40%_60%] min-[1440px]:!grid-cols-[33%_67%]"
>
```

### Native Preview Navigation

**Source:** `preview/sidebar.ex` lines 72-93 and 121-132.
**Apply to:** mobile Mailables navigation and desktop sidebar.

Keep `<details>/<summary>`, `min-h-11`, focus rings, and relative `./Module/scenario?width=&theme=` links.

### Structural Test Ratchet

**Source:** `structural.spec.js` lines 532-598.
**Apply to:** Preview light/dark at 390/768/1440, one `h1`, group `data-testid`s, touch targets, focus rings, and WCAG AA contrast.

Use the existing Playwright helpers (`assertTextContrastAA`, `assertNonTextContrastAA`, `parseGridColumns`, `expectRatio`) instead of adding a new harness.

### Bundle Clean Gate

**Source:** `mix.exs` lines 183-187.
**Apply to:** any HEEx/class changes affecting generated CSS.

Run the existing build path and expect `git diff --exit-code priv/static/` to gate generated CSS drift.

## No Analog Found

No files are without a codebase analog. Phase 100 is an uplift of existing Preview, Operator/Inbound, and audit/test patterns.

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/{preview,operator,inbound}*`, `mailglass_admin/e2e`, `mailglass_admin/test`, `mailglass_admin/scripts`, `mailglass_admin/dev/mailglass_admin/preview`, `mailglass_admin/mix.exs`, `mailglass_admin/assets/css/app.css`.
**Files scanned:** 18
**Pattern extraction date:** 2026-06-15
