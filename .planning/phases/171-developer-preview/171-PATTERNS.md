# Phase 171: Developer Preview - Pattern Map

**Mapped:** 2026-10-09
**Files analyzed:** 9 existing files expected to be modified
**Analogs found:** 9 / 9 (browser keyboard implementation has no exact existing tabs analog; use the existing JS hook registry as the closest client-side pattern)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mailglass_admin/lib/mailglass_admin/preview_live.ex` | controller / LiveView | request-response, event-driven | same file; `mailglass_admin/lib/mailglass_admin/preview/discovery.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` | component | request-response | same file | exact |
| `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` | component | request-response, event-driven | same file | exact |
| `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` | component | request-response, event-driven | same file | exact |
| `mailglass_admin/lib/mailglass_admin/preview/device_frame.ex` | component | event-driven | same file | exact |
| `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` | config / client bootstrap | request-response, event-driven | same file | role-match; no existing tab keyboard hook |
| `mailglass_admin/test/mailglass_admin/preview_live_test.exs` | test | request-response, event-driven | same file | exact |
| `mailglass_admin/e2e/structural.spec.js` | test | event-driven, request-response | same file | exact |
| `guides/preview.md` | documentation | request-response (adopter setup) | same file; `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex` for scenario sample | exact |

`preview/discovery.ex` is a strong supporting analog, but the research structure lists it as existing safe discovery and does not anticipate changing it. Reuse its validation/resolution contract rather than adding another scenario registry. Paths in this map were verified with `git ls-files` and are tracked sources.

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/preview_live.ex` (controller / LiveView, request-response and event-driven)

**Analog:** `mailglass_admin/lib/mailglass_admin/preview_live.ex` (tracked, 935 lines; targeted excerpts below).

**Imports and component composition** (lines 47-57):
```elixir
  use Phoenix.LiveView

  alias MailglassAdmin.AdminShell
  alias MailglassAdmin.Components
  alias MailglassAdmin.Preview.AssignsForm
  alias MailglassAdmin.Preview.DeviceFrame
  alias MailglassAdmin.Preview.Discovery
  alias MailglassAdmin.Preview.Sidebar
  alias MailglassAdmin.Preview.Tabs
```

**Safe route selection** (lines 97-129 and 549-565): route strings become existing atoms, then must resolve in the discovered scenario list before state changes. Keep this closed-world flow and mount-aware URL handling:
```elixir
      with {:ok, mailable} <- safe_mailable_atom(mod_str),
           {:ok, scenario} <- safe_scenario_atom(name_str),
           {:ok, defaults} <-
             lookup_scenario_defaults(socket.assigns.mailables, mailable, scenario) do
        current_assigns =
          if socket.assigns.current_mailable == mailable and
               socket.assigns.current_scenario == scenario do
            socket.assigns.current_assigns
          else
            defaults
          end

        socket
        |> assign(:current_mailable, mailable)
        |> assign(:current_scenario, scenario)
        |> assign(:current_assigns, current_assigns)
        |> rerender()
      end
```
The actual function also normalizes URL state and handles discovery/error fallbacks; see lines 97-155. Do not use `String.to_atom/1` on route or event input.

**Event/update pattern** (lines 189-193, 227-232):
```elixir
  def handle_event("assigns_changed", %{"assigns" => params}, socket) do
    merged = merge_assigns(socket.assigns.current_assigns, params)
    {:noreply, socket |> assign(:current_assigns, merged) |> rerender()}
  end

  def handle_event("set_tab", %{"tab" => t}, socket) do
    case safe_tab_atom(t) do
      {:ok, tab} -> {:noreply, assign(socket, :active_tab, tab)}
      :error -> {:noreply, socket}
    end
  end
```

**Error and successful-render state** (lines 806-846): the existing `rerender/1` retains prior artifact assigns when rendering fails, while setting `:render_error`; the view currently selects an error branch that omits the form. Preserve this render boundary but retain raw drafts separately, keep the correction controls visible, associate field errors with controls, and explicitly label any retained artifacts stale. Renderer invocation pattern:
```elixir
  defp rerender(socket) do
    mod = socket.assigns.current_mailable
    scenario = socket.assigns.current_scenario
    assigns_map = socket.assigns.current_assigns

    try do
      case build_and_render(mod, scenario, assigns_map) do
        {:ok, rendered} ->
          email = rendered.swoosh_email

          socket
          |> assign(:html_body, email.html_body || "")
          |> assign(:text_body, email.text_body || "")
          |> assign(:raw_envelope, raw_envelope(email))
          |> assign(:headers, swoosh_headers(email))
          |> assign(:render_error, nil)

        {:error, %Mailglass.TemplateError{} = err} ->
          assign(socket, :render_error, Exception.message(err))
      end
    rescue
      e -> assign(socket, :render_error, Exception.format(:error, e, __STACKTRACE__))
    end
  end

  defp build_and_render(mod, scenario, assigns_map)
       when is_atom(mod) and is_atom(scenario) and is_map(assigns_map) do
    msg = apply(mod, scenario, [assigns_map])
    Mailglass.Renderer.render(msg)
  end
```

**Assign-key and scalar-input boundary** (lines 758-802): current code restricts keys to the existing-atom and current-default set. Keep that allowlist. The integer/float `coerce/2` below is specifically the behavior to replace: it partially accepts numeric suffixes and silently returns defaults on parse failure. Return typed parse errors while retaining submitted strings instead.
```elixir
  defp merge_assigns(current, params) when is_map(params) do
    Enum.reduce(params, current, fn {k, v}, acc ->
      key = safe_key_atom(k)

      if key && Map.has_key?(acc, key) do
        Map.put(acc, key, coerce(acc[key], v))
      else
        acc
      end
    end)
  end

  defp safe_key_atom(k) when is_binary(k) do
    String.to_existing_atom(k)
  rescue
    ArgumentError -> nil
  end
```

**Output semantics** (lines 848-875, 894-933): `raw_envelope/1` manually assembles an illustrative envelope and `swoosh_headers/1` adds preview-generated Message-ID/Date. Keep those distinctions in display text; these are not encoded wire bytes or provider facts. The `PreviewLive` moduledoc at lines 33-41 also needs correction: shared Renderer telemetry still occurs, and the documented host dev-route guard—not a structural package boundary—controls exposure.

### `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` (component, request-response)

**Analog:** same file (tracked, 423 lines).

**Imports and input contract** (lines 23-33):
```elixir
  use Phoenix.Component

  alias MailglassAdmin.Components

  attr(:mailables, :list, required: true)
  attr(:current_mailable, :atom, default: nil)
  attr(:current_scenario, :atom, default: nil)
  attr(:device_width, :integer, default: 768)
  attr(:admin_chrome_theme, :atom, default: nil)
  attr(:mount_path, :string, default: nil)
```

**Compact active selection and responsive disclosure** (lines 94-154): `menu/1` computes current Mailable/scenario labels, exposes the selected scenario in a native `<details>/<summary>`, and wraps the options in a bounded scroll region. This is the pattern to retain at narrow widths. Relevant mount-aware scenario link (lines 273-285):
```heex
<.link
  patch={scenario_path(@mount_path, @mod, scenario_name, @device_width, @admin_chrome_theme)}
  class={["mg-focus-ring flex items-center gap-2 px-3 py-2 min-h-11 text-body truncate transition-colors",
    scenario_classes(@current_mailable, @current_scenario, @mod, scenario_name)]}
>
  {Atom.to_string(scenario_name)}
</.link>
```
`scenario_path/5` delegates to `scenario_base_path/3` and appends width (lines 375-400); preserve mount awareness and active Mailable-plus-scenario identity. Keep the distinct zero-Mailables and Mailables-with-no-scenarios states in `PreviewLive` (lines 435-499).

### `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` (component, request-response and event-driven)

**Analog:** same file (tracked, 337 lines).

**Imports and form pattern** (lines 34-63):
```elixir
  use Phoenix.Component

  attr :scenario_assigns, :map, required: true

  def assigns_form(assigns) do
    ~H"""
    <form
      phx-change="assigns_changed"
      data-testid="preview-assigns-form"
      class="assigns-form space-y-4 rounded-box border border-base-300 bg-base-200 p-md"
    >
      <%= for {key, value} <- Enum.sort_by(@scenario_assigns, fn {k, _} -> Atom.to_string(k) end) do %>
        <.field key={key} value={value} />
      <% end %>
    </form>
    """
  end
```
Keep fields in a stable form with a stable `id` and use built-in `phx-debounce` for free text. Maintain component ownership of labels/control markup; send field drafts and parse feedback as explicit assigns.

**Typed control and accessibility patterns** (lines 68-153, 255-308): type-dispatched `field/1` clauses preserve the original scalar control type; the checkbox pairs a hidden false value with checked true. `field_label/1`, `field_help/1`, `assign_control_metadata/1` generate per-field label and help IDs. Extend this shape with `aria-invalid`, a field error ID, and visible error text. Current nested map/struct textareas at lines 196-239 use Elixir `inspect` but call it JSON in help text (lines 310-324); replace that path with accurate read-only display/guidance. DateTime roundtrip should likewise be read-only unless its timezone semantics are established.

### `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` (component, request-response and event-driven)

**Analog:** same file (tracked, 213 lines).

**Imports, closed tab set, and current HEEx relations** (lines 21-36):
```elixir
  use Phoenix.Component

  attr(:active_tab, :atom, values: [:html, :text, :raw, :headers], default: :html)
  attr(:html_body, :string, default: "")
  attr(:text_body, :string, default: "")
  attr(:raw_envelope, :string, default: "")
  attr(:headers, :list, default: [])
```
Each button currently has `role="tab"`, `aria-selected`, `aria-controls`, and `phx-click="set_tab"` (lines 45-104). The active panel is rendered once with `id="tab-panel-<active>"` and `aria-labelledby="tab-btn-<active>"` (lines 107-127). Complete this structure with `tabindex` roving focus, focus-visible styling, consistent panel visibility/relations, and manual APG activation behavior. Use CSS wrapping at narrow widths.

**Output pane pattern** (lines 140-195): HTML uses `srcdoc` in an iframe with `sandbox="allow-same-origin"` and no `allow-scripts`; text wraps with `whitespace-pre-wrap`; raw and headers scroll inside their own bounded panes. Preserve full content and iframe behavior. Copy should describe browser rendering only; sandboxing here is not HTML sanitization or network isolation.

### `mailglass_admin/lib/mailglass_admin/preview/device_frame.ex` (component, event-driven)

**Analog:** same file (tracked, 62 lines).

**Imports and allowlisted controls** (lines 18-56):
```elixir
  use Phoenix.Component

  attr :device_width, :integer, values: [375, 768, 1024], default: 768

  def device_frame(assigns) do
    ~H"""
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
    """
  end
```
The source repeats this for 768 and 1024. Keep the constrained width values, pressed state, and 44px target styling; revise labels to express CSS pixel widths, not device identities.

### `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` (config / client bootstrap, request-response and event-driven)

**Analog:** same file (tracked). Research mentions `assets/js/app.js`, but no such tracked source exists in this repository; assets are compiled/embedded by this controller. This is the closest project-native location for the small tab keyboard handler.

**Hook registry and LiveSocket registration** (lines 64-106):
```javascript
  const Hooks = {
    ModalFocusTrap: {
      mounted() {
        this.handleFocusIn = (event) => {
          const sentinel = event.target.closest?.("[data-focus-trap]")
          if (!sentinel || !this.el.contains(sentinel)) return
          // Existing hook keeps its listener scoped to the mounted element.
        }
        this.el.addEventListener("focusin", this.handleFocusIn)
      },
      destroyed() {
        this.el.removeEventListener("focusin", this.handleFocusIn)
      }
    }
  }

  const liveSocket = new LiveView.LiveSocket("/live", Phoenix.Socket, {
    params: csrfToken ? { _csrf_token: csrfToken } : {},
    hooks: Hooks
  })
```
For tabs, follow the scoped listener cleanup and existing hooks registration. Arrow/Home/End should only move DOM focus; activation should use the existing LiveView click event on Enter/Space/click, avoiding a server event for every focus move. Do not add a general JS framework. The file is an embedded JS template; its asset-build path and checked-in generated CSS/bundle rules are project-specific.

### `mailglass_admin/test/mailglass_admin/preview_live_test.exs` (test, request-response and event-driven)

**Analog:** same file (tracked, 707 lines).

**Imports and fixture setup** (lines 13-29):
```elixir
  use MailglassAdmin.LiveViewCase, async: false

  alias MailglassAdmin.Fixtures.{HappyMailer, StubMailer, BrokenMailer}
  alias MailglassAdmin.Preview.{AssignsForm, Discovery, Sidebar}

  @fixture_mailables [HappyMailer, StubMailer, BrokenMailer]

  setup %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, %{"mailables" => @fixture_mailables})
    {:ok, conn: conn}
  end
```

**Contract assertions** (lines 359-412): current tests mount a real LiveView, switch with `render_click/3`, assert HTML iframe/text/raw/header output, and verify width changes. Follow this style for typed success, invalid draft retention, render failure recovery, stale labels, empty/no-scenario distinction, raw/header truth, IDs and tab relationship attributes. Keep browser-only focus and layout behaviors in Playwright.

### `mailglass_admin/e2e/structural.spec.js` (test, event-driven and request-response)

**Analog:** same file (tracked, 3353 lines; targeted region below).

**Existing browser conventions** (lines 1439-1488):
```javascript
  test.describe("preview state coverage, responsive theme matrix, and contrast", () => {
    test("Preview: 390px mobile email picker reaches a real scenario link", async ({ page }) => {
      await page.setViewportSize({ width: 390, height: 844 });
      await openPreviewIndex(page, "theme=dark");

      const mailablesPicker = page.getByTestId("preview-mailables-picker");
      const menuTrigger = page.getByTestId("preview-email-menu-trigger");
      await expect(mailablesPicker).toBeVisible();
      await expect(mailablesPicker).toHaveAttribute("data-picker-variant", "menu");
      await expect(menuTrigger).toContainText("HappyMailer");
      await expect(menuTrigger).toContainText("welcome_default");
    });
  });
```
Use `page`, role/testid locators, `expect`, and the existing `openPreviewScenario` helpers. Add genuine keyboard/focus proof for Left/Right wrapping, Home/End, Enter/Space activation, panel focus/scroll, 320/390px reflow, and no page-level overflow; do not treat a LiveView HTML assertion as proof of focus behavior.

### `guides/preview.md` (documentation, request-response / adopter setup)

**Analog:** same guide (tracked, 95 lines), plus `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex` for an adopter Mailable example.

**Host-owned route guard** (lines 13-27):
```elixir
  if Application.compile_env(:my_app, :dev_routes) do
    scope "/dev" do
      pipe_through :browser
      mailglass_admin_routes "/mail"
    end
  end
```
Preserve the fact that the host configuration owns this dev-only condition. The preview router macro itself does not provide auth or environment restriction.

The `preview_props/0` sample at lines 36-47 is stale: it returns one flat keyword map. Replace it with the supported ordered named-scenario-to-map shape. The guide opening at lines 1-6 also overstates parity (“exactly”/“consistent with real delivery”); use the renderer-stage distinction from `PreviewLive` and identify browser-only, illustrative raw/header output. Mention the documented remote-resource boundary without implying that sandboxing sanitizes or blocks requests.

## Shared Patterns

### LiveView owns state; function components own markup
**Sources:** `preview_live.ex:189-249, 322-433`; `preview/assigns_form.ex:34-63`; `preview/tabs.ex:32-129`; `preview/device_frame.ex:22-58`.
Keep discovery/selection, draft and parsed assigns, render artifacts/errors, active tab, width and backdrop in LiveView state. Components render the controls and panes and emit named events. Use the single existing Renderer call in `PreviewLive`; do not route preview through outbound preflight, deliver, or provider adapters.

### Closed-world untrusted input handling
**Sources:** `preview_live.ex:549-577, 742-802`; `preview/discovery.ex:63-74, 96-138`; `preview/tabs.ex:23`.
Resolve Mailable/scenario against discovery; use existing-atom conversion, validate only the closed tab and width sets, and limit submitted assign keys to known defaults. Preserve these guards while adding strict parse results.

### Honest failure and output state
**Sources:** `preview_live.ex:806-875, 894-933`; `preview/assigns_form.ex:255-308`; `preview_live_test.exs:359-392`.
Preserve attempted strings independently from successfully parsed assigns and last-successful rendered artifacts. On validation/render failure, keep the editor usable, associate an error to the field or render failure, announce once, and make any retained output explicitly stale. Identify raw output as illustrative and injected Message-ID/Date as preview-generated.

### Accessibility and semantic styling
**Sources:** `preview/assigns_form.ex:68-153, 255-308`; `preview/tabs.ex:39-127`; `preview/device_frame.ex:28-55`; `mailglass_admin/e2e/structural.spec.js:1474-1525`.
Reuse visible focus classes, label/help associations, text status, `aria-pressed`, and `min-h-11` targets. Complete the existing horizontal tab widget with APG manual activation, roving tabindex, keyboard support, focusable panel as needed, and valid relationships. Keep body/long output readable and own-scrollable.

### Responsive and host evidence boundaries
**Sources:** `preview/sidebar.ex:103-154`; `preview_live.ex:195-224, 375-431`; `guides/preview.md:13-27, 55-95`; existing browser test above.
Keep picker disclosure, width/backdrop/Admin appearance as independent concerns, call widths CSS pixels, and explain that captures prove only the browser preview pipeline. Preserve host dev-route guarding and existing no-dependency posture.

## No Analog Found

| File/behavior | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| Manual APG keyboard logic for preview tabs | client-side behavior | event-driven | No existing tab widget keyboard implementation was found. Use the small scoped-hook pattern in `mailglass_admin/lib/mailglass_admin/controllers/assets.ex:64-106`; expose no new framework or generic widget abstraction. |

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/preview*`, `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`, `mailglass_admin/test/mailglass_admin/preview_live_test.exs`, `mailglass_admin/e2e/structural.spec.js`, `guides/preview.md`, `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex`.
**Files scanned:** 9 direct target files plus supporting discovery, fixtures, renderer and current test helpers.
**Pattern extraction date:** 2026-10-09
