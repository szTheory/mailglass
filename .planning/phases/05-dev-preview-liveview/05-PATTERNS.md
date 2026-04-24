# Phase 5: Dev Preview LiveView — Pattern Map

**Mapped:** 2026-04-24
**Files analyzed:** ~26 new files (mailglass_admin sibling Hex package) + 1 modified (PROJECT.md / REQUIREMENTS.md / ROADMAP.md doc-fix sweep counted as one)
**Analogs found:** 22 / 26

## Scope context

Phase 5 stands up a brand-new sibling Hex package at `mailglass_admin/` (nested-sibling directory inside the same git repo per CONTEXT D-01 — **NOT** a Mix umbrella, **NOT** a separate git repo). Phases 1–4 shipped under `lib/mailglass/`; Phase 5 introduces `mailglass_admin/lib/mailglass_admin/`. The plan must follow mailglass conventions ported from the existing tree (errors-as-structs, prefixed PubSub topics, no `name: __MODULE__` singletons, telemetry whitelist, optional-dep gateway pattern) and copy the Phoenix LiveDashboard / Oban Web router-macro signature for the public mount point.

**Critical analog finding:** Sigra has *no* `lib/sigra/admin/router.ex` — its admin routing is install-template injection, not a router macro. ROADMAP.md's claim about prototyping against `~/projects/sigra` is partially incorrect (research already corrected this in `05-RESEARCH.md` §"Router Macro Pattern (from sigra)" lines 720–735). The correct prior art is `Phoenix.LiveDashboard.Router.live_dashboard/2` and `Oban.Web.Router.oban_dashboard/2` — neither lives in the local `deps/` tree, so the planner consumes their patterns from the verbatim excerpts in `05-RESEARCH.md` §"Pattern 1" (lines 348–453) and §"Pattern 2" (lines 455–536). Those excerpts ARE the analog for Plan 5's router/assets work; this PATTERNS.md cites them as the canonical source.

**Available local analogs we DO reuse:**
- `lib/mailglass/mailable.ex` — module-doc style, behaviour declaration, `__using__/1` AST budget pattern, `@before_compile` marker (the discovery seam)
- `lib/mailglass/error.ex` + `lib/mailglass/errors/config_error.ex` — error-struct hierarchy, closed `:type` atom set, pattern-match-by-struct discipline
- `lib/mailglass/optional_deps.ex` + `lib/mailglass/optional_deps/sigra.ex` — optional-dep gateway pattern (Phase 5 uses it for `phoenix_live_reload`)
- `lib/mailglass/pub_sub/topics.ex` — `mailglass:`-prefixed topic builder (LINT-06 contract)
- `lib/mailglass/telemetry.ex` — `:telemetry.span/3` wrapper pattern + named-span helpers (Phase 5 LiveView emits an admin-discovery span)
- `lib/mailglass/renderer.ex` — pure-function pipeline with whitelisted telemetry metadata, no PII (consumed unchanged by PreviewLive)
- `lib/mailglass/components.ex` — `use Phoenix.Component` + `attr` declarations + brand-aware HEEx (the only existing Phoenix.Component in the repo; mailglass_admin's UI atoms copy this style)
- `lib/mailglass/application.ex` — `Code.ensure_loaded?/1` gating, `:persistent_term` boot warnings (mailglass_admin needs no application supervisor at v0.1, but the gating discipline applies to the LiveReload subscriber)
- `lib/mix/tasks/mailglass.reconcile.ex` — Mix task structure with `use Boundary, classify_to:`, `@shortdoc`, `@compile {:no_warn_undefined, ...}` for conditional dispatch
- `mix.exs` — Hex package metadata, `package[:files]` whitelist, `boundary` compiler, deps shape
- `~/projects/sigra/lib/sigra/admin/live/users_index_live.ex` — concrete Phoenix.LiveView implementation pattern (`use Phoenix.LiveView`, `mount/3`, `handle_params/3`, `handle_event/3`, `render/1` returning `~H` with daisyUI classes); admin-shell three-column layout reference
- `~/projects/sigra/lib/sigra/live_view/admin_scope.ex` — `on_mount/4` callback pattern with explicit `{:cont, ...}` / `{:halt, ...}` returns
- `deps/swoosh/lib/plug/mailbox_preview.ex` — **counter-example only** (Plug-based, not LiveView; do NOT copy)

---

## File Classification

### `mailglass_admin/` package metadata + config

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `mailglass_admin/mix.exs` | config | n/a | `/Users/jon/projects/mailglass/mix.exs` | exact |
| `mailglass_admin/config/config.exs` | config | n/a | `05-RESEARCH.md` §"config/config.exs" lines 942-956 | exact (research excerpt) |
| `mailglass_admin/.formatter.exs` | config | n/a | `/Users/jon/projects/mailglass/.formatter.exs` (if exists; otherwise stock Phoenix shape) | partial |

### Router macro + session callback

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `mailglass_admin/lib/mailglass_admin/router.ex` | macro / route DSL | request-response (compile-time AST) | `05-RESEARCH.md` §"Pattern 1" lines 348-453 (verbatim Phoenix LiveDashboard + Oban Web) | exact (research excerpt) |

### Asset controller + Mix tasks

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` | controller | request-response (compile-time bytes) | `05-RESEARCH.md` §"Pattern 2" lines 455-536 (verbatim LiveDashboard) | exact (research excerpt) |
| `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex` | Mix task | batch | `lib/mix/tasks/mailglass.reconcile.ex` | role-match |
| `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.watch.ex` | Mix task | streaming | `lib/mix/tasks/mailglass.reconcile.ex` | role-match |
| `mailglass_admin/lib/mix/tasks/mailglass_admin.daisyui.update.ex` | Mix task | file I/O | `lib/mix/tasks/mailglass.reconcile.ex` + research §"Mix tasks" lines 958-1002 | role-match |

### LiveView + components

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `mailglass_admin/lib/mailglass_admin/preview_live.ex` | LiveView | event-driven (PubSub + form events) | `~/projects/sigra/lib/sigra/admin/live/users_index_live.ex` | role-match (good) |
| `mailglass_admin/lib/mailglass_admin/preview/mount.ex` | LiveView on_mount hook | request-response | `~/projects/sigra/lib/sigra/live_view/admin_scope.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/preview/discovery.ex` | service / reflection | request-response | `05-RESEARCH.md` §"Pattern 3" lines 537-616 + `lib/mailglass/mailable.ex` `__mailglass_mailable__/0` marker (line 154) | exact (research excerpt) |
| `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` | component | n/a | `lib/mailglass/components.ex` (Phoenix.Component style) + `~/projects/sigra/lib/sigra/admin/live/users_index_live.ex` `summary_chip/1` private component (lines 296-303) | role-match |
| `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` | component | n/a | `lib/mailglass/components.ex` + `05-UI-SPEC.md` §"Tab bar" + §"HTML preview iframe" | role-match |
| `mailglass_admin/lib/mailglass_admin/preview/device_frame.ex` | component | n/a | `05-UI-SPEC.md` §"Device toggle button group" lines 267-280 + `05-UI-SPEC.md` §"HTML preview iframe" lines 295-306 | exact (UI-SPEC excerpt) |
| `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` | component / form renderer | request-response | `05-RESEARCH.md` §"Type-inferred form renderer" line 1470 + `05-UI-SPEC.md` §"Assigns form — type-inferred fields" lines 354-368 | exact (UI-SPEC excerpt) |
| `mailglass_admin/lib/mailglass_admin/components.ex` | component library | n/a | `lib/mailglass/components.ex` (module structure, `use Phoenix.Component`, `@doc since:`, `attr` blocks) | exact (style) |
| `mailglass_admin/lib/mailglass_admin/layouts.ex` | layouts | n/a | `~/projects/sigra/priv/templates/sigra.install/admin/layouts_admin_injection.ex` (referenced; not directly read — see Open Items) | partial |
| `mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex` | gateway | n/a | `lib/mailglass/optional_deps/sigra.ex` + `lib/mailglass/optional_deps.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/error.ex` (if any admin-specific errors needed) | error namespace | n/a | `lib/mailglass/error.ex` + `lib/mailglass/errors/config_error.ex` | exact |

### Asset source (vendored / committed)

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `mailglass_admin/assets/css/app.css` | stylesheet | n/a | `05-RESEARCH.md` §"app.css" lines 810-940 (verbatim Phoenix 1.8 installer + brand book §7.3) | exact (research excerpt) |
| `mailglass_admin/assets/vendor/daisyui.js` | vendored binary | n/a | curled from upstream (Phoenix 1.8 installer pattern) | exact |
| `mailglass_admin/assets/vendor/daisyui-theme.js` | vendored binary | n/a | curled from upstream | exact |
| `mailglass_admin/priv/static/app.css` | compiled bundle | n/a | `mix mailglass_admin.assets.build` output; CI gate enforces fresh | exact |
| `mailglass_admin/priv/static/fonts/*.woff2` | font files | n/a | pre-subset by maintainer; committed | exact |
| `mailglass_admin/priv/static/mailglass-logo.svg` | static asset | n/a | brand book §7 logo glyph (TBD by maintainer) | partial |

### Tests + harness

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `mailglass_admin/test/mailglass_admin/router_test.exs` | test | request-response | `test/mailglass/mailable_test.exs` (style) + `05-RESEARCH.md` §"Test asserting isolation" lines 760-775 | exact (research excerpt) |
| `mailglass_admin/test/mailglass_admin/preview_live_test.exs` | test (LiveViewTest) | event-driven | `~/projects/sigra/lib/sigra/admin/live/users_index_live.ex` (mount/handle_event shape) + `Phoenix.LiveViewTest` idioms | role-match |
| `mailglass_admin/test/mailglass_admin/discovery_test.exs` | test | request-response | `test/mailglass/mailable_test.exs` (`defmodule SampleMailer ... use Mailglass.Mailable` fixture pattern, lines 7-27) | exact |
| `mailglass_admin/test/support/endpoint_case.ex` | test harness | n/a | `test/support/mailer_case.ex` (ExUnit case template style; setup blocks; tag handling) | role-match |
| `mailglass_admin/test/test_helper.exs` | bootstrap | n/a | `test/test_helper.exs` | exact |

### Doc-fix sweep (Phase 5 Plan 01 per CONTEXT specifics line 207)

| Modified File | Role | Change | Source |
|---------------|------|--------|--------|
| `.planning/PROJECT.md` line 52 | doc | `preview_props/1` → `preview_props/0` | CONTEXT D-10 |
| `.planning/REQUIREMENTS.md` line 130 (PREV-03) | doc | `preview_props/1` → `preview_props/0` | CONTEXT D-10 |
| `.planning/ROADMAP.md` lines 22, 114, 119 | doc | `preview_props/1` → `preview_props/0` | CONTEXT D-10 |

---

## Pattern Assignments

### `mailglass_admin/mix.exs` (config)

**Analog:** `/Users/jon/projects/mailglass/mix.exs`

**Project block pattern** (lines 1–26 of analog):

```elixir
defmodule Mailglass.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/szTheory/mailglass"

  def project do
    [
      app: :mailglass,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: elixirc_options(),
      compilers: [:boundary | Mix.compilers()],
      ...
      package: package(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls]
    ]
  end
```

**Application block** (lines 28–33 of analog) — mailglass_admin needs **no** `mod:` entry at v0.1 (no supervision tree of its own; reuses adopter PubSub):

```elixir
def application do
  [extra_applications: [:logger]]
end
```

**Optional-dep `:no_warn_undefined`** (lines 38–57 of analog) — mailglass_admin only adds `Phoenix.LiveReloader` to its list:

```elixir
defp elixirc_options do
  [no_warn_undefined: [Phoenix.LiveReloader]]
end
```

**Local-dev path-vs-Hex switch** (CONTEXT D-02 — NOT in analog because mailglass has no sibling); concrete shape:

```elixir
defp deps do
  [
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:phoenix_html, "~> 4.1"},
    {:plug, "~> 1.18"},
    {:nimble_options, "~> 1.1"},
    {:tailwind, "~> 0.4", only: :dev, runtime: false},
    {:phoenix_live_reload, "~> 1.5", optional: true, only: :dev},
    # Local dev: path dep so changes in ../lib/mailglass/ are picked up.
    # Published Hex tarball: pinned version match (linked-versions per D-03).
    mailglass_dep()
  ]
end

defp mailglass_dep do
  if System.get_env("MIX_PUBLISH") == "true" do
    {:mailglass, "== #{@version}"}
  else
    {:mailglass, path: "..", override: true}
  end
end
```

**Package files whitelist** (CONTEXT D-04; analog lines 156–162 keeps `lib priv/gettext mix.exs LICENSE README.md CHANGELOG.md`). For mailglass_admin, swap to:

```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => @source_url},
    files: ~w(lib priv/static .formatter.exs mix.exs README* CHANGELOG* LICENSE*)
  ]
end
```

Note: `assets/` is **excluded** from the tarball (CONTEXT D-04). `priv/static/` is **included** (compiled CSS + fonts + logo).

---

### `mailglass_admin/lib/mailglass_admin/router.ex` (macro / route DSL)

**Analog:** `05-RESEARCH.md` §"Pattern 1: Router macro — LiveDashboard/Oban Web signature" lines 348–453 (verbatim Phoenix.LiveDashboard.Router.live_dashboard/2 + Oban.Web.Router.oban_dashboard/2 patterns).

**Module doc style:** copy from `lib/mailglass/mailable.ex` lines 1–83 — opening `## Usage` block with literal adopter-side code snippet, sections `## use opts`, `## Adopter convention`, etc.

**Public macro signature:**

```elixir
defmacro mailglass_admin_routes(path, opts \\ []) do
  opts = validate_opts!(opts)
  session_name = opts[:live_session_name]

  quote bind_quoted: [path: path, opts: opts, session_name: session_name] do
    scope path, alias: false, as: false do
      get "/css-:md5", MailglassAdmin.Controllers.Assets, :css
      get "/js-:md5", MailglassAdmin.Controllers.Assets, :js
      get "/fonts/:name", MailglassAdmin.Controllers.Assets, :font
      get "/logo.svg", MailglassAdmin.Controllers.Assets, :logo

      on_mount_hooks = opts[:on_mount] ++ [MailglassAdmin.Preview.Mount]

      live_session session_name,
        session: {MailglassAdmin.Router, :__session__, [opts]},
        on_mount: on_mount_hooks,
        root_layout: {MailglassAdmin.Layouts, :root} do
        live "/", MailglassAdmin.PreviewLive, :index
        live "/:mailable/:scenario", MailglassAdmin.PreviewLive, :show
      end
    end
  end
end
```

**Whitelisted `__session__/2` callback** (Oban Web pattern — CONTEXT D-08 lock; the load-bearing security seam):

```elixir
@doc false
def __session__(_conn, opts) do
  %{
    "mailables" => opts[:mailables],
    "live_session_name" => opts[:live_session_name]
    # Add keys here ONLY when intentionally surfacing them to PreviewLive.
    # NEVER pass conn.private.plug_session through.
  }
end
```

**Opts validation via NimbleOptions** (the project already has `{:nimble_options, "~> 1.1"}` in mix.exs line 71). Schema in research §"Pattern 1" lines 372–393:

```elixir
@opts_schema [
  mailables: [type: {:or, [{:in, [:auto_scan]}, {:list, :atom}]}, default: :auto_scan, ...],
  on_mount: [type: {:list, :atom}, default: [], ...],
  live_session_name: [type: :atom, default: :mailglass_admin_preview, ...],
  as: [type: :atom, default: :mailglass_admin, ...]
]

defp validate_opts!(opts) do
  case NimbleOptions.validate(opts, @opts_schema) do
    {:ok, validated} -> validated
    {:error, %NimbleOptions.ValidationError{message: msg}} ->
      raise ArgumentError, "invalid opts for mailglass_admin_routes/2: #{msg}"
  end
end
```

**AST budget:** ≤20 top-level forms in the macro `quote` block — same target as `Mailglass.Mailable.__using__/1` (which hits 15; see `lib/mailglass/mailable.ex` lines 122–144). Research §"Pattern 1" line 451 confirms 8 forms.

**CRITICAL — what NOT to do** (CLAUDE.md "Things Not To Do" + research §"Anti-Patterns to Avoid"):
- No `Mix.env()` check inside the macro body — adopter owns dev/prod gating via their own `if Application.compile_env(:my_app, :dev_routes) do ... end` wrapper (CONTEXT D-06).
- No `name: __MODULE__` GenServer/Registry registration (CLAUDE.md pitfall #8 / LINT-07 enforces in Phase 6).

---

### `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` (controller)

**Analog:** `05-RESEARCH.md` §"Pattern 2: Compile-time asset serving (LiveDashboard pattern)" lines 455–536 (verbatim `Phoenix.LiveDashboard.Controllers.Assets`).

**Compile-time read pattern** (research lines 467–479):

```elixir
defmodule MailglassAdmin.Controllers.Assets do
  @moduledoc false
  import Plug.Conn

  @css_path Path.join([:code.priv_dir(:mailglass_admin), "static", "app.css"])
  @external_resource @css_path
  @css File.read!(@css_path)
  @css_hash Base.encode16(:crypto.hash(:md5, @css), case: :lower)

  @phoenix_js Application.app_dir(:phoenix, "priv/static/phoenix.js")
  @phoenix_live_view_js Application.app_dir(:phoenix_live_view, "priv/static/phoenix_live_view.js")
  @external_resource @phoenix_js
  @external_resource @phoenix_live_view_js
  @js Enum.map_join([@phoenix_js, @phoenix_live_view_js], "\n", &File.read!/1)
  @js_hash Base.encode16(:crypto.hash(:md5, @js), case: :lower)
```

**Plug controller dispatch + immutable cache headers** (research lines 493–516):

```elixir
def init(action) when action in [:css, :js, :font, :logo], do: action

def call(conn, :css), do: serve(conn, @css, "text/css; charset=utf-8")
def call(conn, :js),  do: serve(conn, @js,  "application/javascript; charset=utf-8")
def call(conn, :logo), do: serve(conn, @logo, "image/svg+xml")

defp serve(conn, body, content_type) do
  conn
  |> put_resp_header("content-type", content_type)
  |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
  |> send_resp(200, body)
  |> halt()
end
```

**Font allowlist (path-traversal defense)** — research lines 518–526:

```elixir
@allowed_fonts ~w(
  inter-400.woff2 inter-700.woff2
  inter-tight-400.woff2 inter-tight-700.woff2
  ibm-plex-mono-400.woff2 ibm-plex-mono-700.woff2
)
defp resolve_font(name) when name in @allowed_fonts do
  {:ok, Path.join([:code.priv_dir(:mailglass_admin), "static", "fonts", name])}
end
defp resolve_font(_), do: :error
```

**Note:** UI-SPEC §"Font loading" lines 71–79 collapses to **2 weights per family** (400 + 700); update the allowlist accordingly. Research's earlier list with `500/600` is stale per UI-SPEC revision log.

---

### `mailglass_admin/lib/mailglass_admin/preview_live.ex` (LiveView)

**Primary analog:** `~/projects/sigra/lib/sigra/admin/live/users_index_live.ex` (concrete LiveView with `mount/3`, `handle_params/3`, `handle_event/3`, `render/1` returning `~H` with daisyUI utility classes).

**Imports + use pattern** (sigra lines 1–11):

```elixir
defmodule MailglassAdmin.PreviewLive do
  @moduledoc """
  The single dev-preview LiveView surface (PREV-01..PREV-06).

  ...adopter-facing usage block...
  """

  use Phoenix.LiveView

  alias Mailglass.Renderer
  alias MailglassAdmin.Preview.Discovery
  alias MailglassAdmin.PubSub.Topics
end
```

**`mount/3` pattern** (sigra lines 12–32, plus research §"Pattern 4" lines 645–668 for PubSub subscription):

```elixir
@impl true
def mount(_params, session, socket) do
  if connected?(socket) and live_reload_available?() do
    Phoenix.PubSub.subscribe(adopter_pubsub(socket), Topics.admin_reload())
  end

  mailables = Discovery.discover(session["mailables"])

  {:ok,
   socket
   |> assign(:mailables, mailables)
   |> assign(:current_mailable, nil)
   |> assign(:current_scenario, nil)
   |> assign(:current_assigns, %{})
   |> assign(:device_width, 768)
   |> assign(:dark_chrome, false)
   |> assign(:active_tab, :html)
   |> assign(:render_nonce, System.unique_integer([:positive]))
   |> assign(:page_title, "Preview")}
end
```

**`handle_params/3` for routing** (sigra lines 34–61) — wire `/:mailable/:scenario` URL → assigns:

```elixir
@impl true
def handle_params(%{"mailable" => mod_str, "scenario" => name_str}, _uri, socket) do
  with {:ok, mailable} <- safe_atom(mod_str),
       {:ok, scenario} <- safe_atom(name_str),
       %{} = defaults <- find_scenario(socket.assigns.mailables, mailable, scenario) do
    {:noreply,
     socket
     |> assign(:current_mailable, mailable)
     |> assign(:current_scenario, scenario)
     |> assign(:current_assigns, defaults)
     |> rerender()}
  else
    _ -> {:noreply, put_flash(socket, :error, "Scenario not found")}
  end
end
```

**`handle_event/3` for assigns-form / device toggle / dark toggle / tab switch / reset** (UI-SPEC §"Interaction Contract" lines 484–503):

```elixir
@impl true
def handle_event("assigns_changed", %{"assigns" => params}, socket), do: ...
def handle_event("set_device", %{"width" => w}, socket), do: ...
def handle_event("toggle_dark", _, socket), do: ...
def handle_event("set_tab", %{"tab" => t}, socket), do: ...
def handle_event("reset_assigns", _, socket), do: ...
def handle_event("render_preview", _, socket), do: ...
```

**`handle_info/2` for LiveReload** (research §"Pattern 4" lines 661–669):

```elixir
@impl true
def handle_info({:phoenix_live_reload, _topic, path}, socket) do
  mailables = Discovery.discover(socket_mailables(socket))
  socket = socket |> assign(:mailables, mailables) |> rerender()
  {:noreply, put_flash(socket, :info, "Reloaded: #{Path.basename(path)}")}
end
```

**Render-pipeline call** — copy direct invocation pattern from `lib/mailglass/renderer.ex` lines 63–85 — use the **same** `Mailglass.Renderer.render/1` production uses (PREV-03 "no placeholder shape divergence"). Wrap in `try/rescue` to convert raises into in-pane error cards (UI-SPEC §"Error card" lines 386–404).

**Error handling discipline** — match by struct, never by message string (CLAUDE.md "Things Not To Do" #7; `lib/mailglass/error.ex` lines 25–32):

```elixir
defp rerender(socket) do
  msg = build_message(socket.assigns.current_mailable, socket.assigns.current_assigns)

  case Renderer.render(msg) do
    {:ok, rendered} ->
      socket
      |> assign(:html_body, rendered.swoosh_email.html_body)
      |> assign(:text_body, rendered.swoosh_email.text_body)
      |> assign(:headers, rendered.swoosh_email.headers)
      |> assign(:raw_envelope, render_envelope(rendered.swoosh_email))
      |> assign(:render_nonce, System.unique_integer([:positive]))

    {:error, %Mailglass.TemplateError{} = err} ->
      assign(socket, :render_error, Exception.message(err))
  end
end
```

**Render template** — UI-SPEC §"Component Inventory" lines 232–443 contains every HEEx snippet (sidebar item, badges, device toggle, theme toggle, iframe, text/raw/headers tabs, assigns form, error card, empty state card, flash, top bar). Copy verbatim into `render/1` and split into private function components.

**No PII in telemetry** — if PreviewLive emits any telemetry, metadata is restricted to `mailable: module, scenario: atom, render_ms: integer` — never assign values, recipient addresses, or HTML bodies (CLAUDE.md "Things Not To Do" #3 / `lib/mailglass/renderer.ex` line 64–66 metadata pattern).

---

### `mailglass_admin/lib/mailglass_admin/preview/mount.ex` (on_mount hook)

**Analog:** `/Users/jon/projects/sigra/lib/sigra/live_view/admin_scope.ex` (full file, 53 lines).

**Pattern** (sigra lines 12–33):

```elixir
defmodule MailglassAdmin.Preview.Mount do
  @moduledoc false

  alias MailglassAdmin.Preview.Discovery

  def on_mount(:default, _params, session, socket) do
    mailables = Discovery.discover(session["mailables"])
    {:cont, Phoenix.Component.assign(socket, :mailables, mailables)}
  end
end
```

**Return contract:** `{:cont, socket}` to proceed, `{:halt, socket}` to short-circuit (sigra lines 21, 25, 28, 31).

---

### `mailglass_admin/lib/mailglass_admin/preview/discovery.ex` (service / reflection)

**Analog:** `05-RESEARCH.md` §"Pattern 3: Mailable auto-discovery" lines 537–616 + `lib/mailglass/mailable.ex` lines 150–156 (the `__mailglass_mailable__/0` marker).

**Module doc style:** copy from `lib/mailglass/mailable.ex` lines 1–83 (sectioned with `## Discovery modes`, `## Graceful failures`).

**Public function with typespec** (research lines 562–565):

```elixir
@spec discover(:auto_scan | [module()]) :: [
        {module(), [{atom(), map()}] | :no_previews | {:error, String.t()}}
      ]
def discover(:auto_scan) do
  loaded_apps()
  |> Enum.flat_map(&modules_for_app/1)
  |> Enum.filter(&mailable?/1)
  |> Enum.map(&reflect/1)
end
```

**Marker check** (research lines 593–599 — references `__mailglass_mailable__/0` from `lib/mailglass/mailable.ex` line 154):

```elixir
defp mailable?(mod) do
  Code.ensure_loaded?(mod) and
    function_exported?(mod, :__mailglass_mailable__, 0) and
    mod.__mailglass_mailable__() == true
rescue
  _ -> false
end
```

**Graceful-failure reflection** (research lines 601–614, CONTEXT D-13):

```elixir
defp reflect(mod) do
  cond do
    not function_exported?(mod, :preview_props, 0) ->
      {mod, :no_previews}

    true ->
      try do
        {mod, mod.preview_props()}
      rescue
        e ->
          {mod, {:error, Exception.format(:error, e, __STACKTRACE__)}}
      end
  end
end
```

**Arity locked at /0** — see `lib/mailglass/mailable.ex` line 111 (`@optional_callbacks preview_props: 0`) + line 112 (`@callback preview_props() :: [{atom(), map()}]`).

---

### `mailglass_admin/lib/mailglass_admin/preview/{sidebar,tabs,device_frame,assigns_form}.ex` (function components)

**Analog:** `lib/mailglass/components.ex` (the only existing `Phoenix.Component` module in the repo) + `~/projects/sigra/lib/sigra/admin/live/users_index_live.ex` private components (lines 296–321 — `summary_chip/1`, `quick_filter/1`).

**Module skeleton** (mailglass/components.ex lines 1–40):

```elixir
defmodule MailglassAdmin.Preview.Sidebar do
  @moduledoc """
  Sidebar component: mailable list with collapsible scenario groups.

  Renders the structure documented in 05-UI-SPEC.md §Sidebar structure.
  """

  use Phoenix.Component

  alias MailglassAdmin.Preview.Discovery

  attr :mailables, :list, required: true
  attr :current_mailable, :atom, default: nil
  attr :current_scenario, :atom, default: nil

  @doc "Renders the mailable sidebar with scenario sub-items and status badges."
  @doc since: "0.1.0"
  def sidebar(assigns) do
    ~H"""
    ...
    """
  end
end
```

**`attr` declarations** (mailglass/components.ex lines 45–47, 72–76 — note the use of `:any`, `:string`, `values: ~w(...)`, `default:`):

```elixir
attr :text, :string, required: true
attr :class, :any, default: nil
attr :rest, :global, include: ~w(id)
```

**HEEx body shapes** — copy verbatim from UI-SPEC component inventory:
- Sidebar items: UI-SPEC lines 234–248
- Badges: UI-SPEC lines 250–263
- Device toggle: UI-SPEC lines 265–280
- Theme toggle: UI-SPEC lines 282–292
- HTML iframe: UI-SPEC lines 294–306 (note the `phx-update="ignore"` + nonce-based `id` discipline at lines 307)
- Text/Raw/Headers tabs: UI-SPEC lines 312–352

**Assigns-form type-inference table** — UI-SPEC §"Assigns form — type-inferred fields" lines 354–366. Render strategy:

```elixir
defp render_field(assigns) when is_binary(assigns.value), do: ~H|<input type="text" .../>|
defp render_field(assigns) when is_integer(assigns.value), do: ~H|<input type="number" step="1" .../>|
defp render_field(assigns) when is_boolean(assigns.value), do: ~H|<input type="checkbox" .../>|
defp render_field(%{value: %DateTime{}} = assigns), do: ~H|<input type="datetime-local" .../>|
defp render_field(%{value: %{__struct__: _}} = assigns), do: ~H|<textarea>...</textarea>|
defp render_field(assigns), do: ~H|<textarea>...</textarea>|
```

---

### `mailglass_admin/lib/mailglass_admin/components.ex` (shared UI atoms)

**Analog:** `/Users/jon/projects/mailglass/lib/mailglass/components.ex` (the EXISTING components module — 18707 bytes; structure + style is the contract).

**What to copy:** module-doc shape (lines 1–32), `use Phoenix.Component` (line 34), `alias` block (line 36), `@global_includes` whitelist pattern (lines 38–39), `attr` blocks per component (lines 45–47, 72–76), `@doc since: "0.1.0"` discipline (line 58), HEEx sigil bodies with brand-aware classes.

**What atoms to ship:** `<.icon name="hero-...">` (UI-SPEC requires Heroicons throughout), `<.logo>` (UI-SPEC top-bar line 442), `<.badge>` (UI-SPEC §Badge variants), `<.flash>` (UI-SPEC §Flash message lines 421–428).

---

### `mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex` (gateway)

**Analog:** `/Users/jon/projects/mailglass/lib/mailglass/optional_deps/sigra.ex` (full file, 33 lines — closest match because both gate compile-time module presence).

**Pattern** (sigra.ex lines 1–33):

```elixir
# Conditionally compiled — the entire defmodule is elided when
# :phoenix_live_reload is absent. Callers must guard via
# `Code.ensure_loaded?(MailglassAdmin.OptionalDeps.PhoenixLiveReload)` before
# referencing it.
if Code.ensure_loaded?(Phoenix.LiveReloader) do
  defmodule MailglassAdmin.OptionalDeps.PhoenixLiveReload do
    @moduledoc """
    Gateway for the optional `{:phoenix_live_reload, "~> 1.5"}` dep.

    When live_reload is loaded, PreviewLive subscribes to the adopter's
    LiveReload PubSub topic (CONTEXT D-24). When absent, PreviewLive still
    works — adopter just refreshes manually.
    """

    @compile {:no_warn_undefined, [Phoenix.LiveReloader]}

    @doc since: "0.1.0"
    @spec available?() :: boolean()
    def available?, do: true
  end
end
```

**Lint-enforcement note** (`lib/mailglass/optional_deps.ex` lines 36–40): the gateway is the single authorized callsite. PreviewLive references `Phoenix.LiveReloader` only via the gateway.

---

### `mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex` (typed topic builder)

**Analog:** `/Users/jon/projects/mailglass/lib/mailglass/pub_sub/topics.ex` (full file, 36 lines).

**Pattern** (full analog file):

```elixir
defmodule MailglassAdmin.PubSub.Topics do
  @moduledoc """
  Typed topic builder for mailglass_admin PubSub broadcasts. Every topic is
  prefixed `mailglass:` — Phase 6 LINT-06 PrefixedPubSubTopics enforces.

  ## Topics emitted

  - `admin_reload/0` — `"mailglass:admin:reload"` — adopter's LiveReload notify
    target; PreviewLive subscribes; broadcasts come from the adopter's
    `:phoenix_live_reload` config (D-24).
  """

  @doc "Returns the LiveReload broadcast topic for admin auto-refresh."
  @doc since: "0.1.0"
  @spec admin_reload() :: String.t()
  def admin_reload, do: "mailglass:admin:reload"
end
```

**CRITICAL — research §"Anti-Patterns to Avoid" line 699 caught a research-internal contradiction:** the earlier example used `mailglass_admin_reload` (NO prefix). The corrected topic is `mailglass:admin:reload` (with prefix). The plan must use the prefixed form to satisfy LINT-06 / CLAUDE.md pitfall #3 / `lib/mailglass/pub_sub/topics.ex` lines 17–28.

---

### `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.{build,watch}.ex` + `daisyui.update.ex` (Mix tasks)

**Analog:** `/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.reconcile.ex` (style + structure).

**Module skeleton** (analog lines 1–37):

```elixir
defmodule Mix.Tasks.MailglassAdmin.Assets.Build do
  use Boundary, classify_to: MailglassAdmin

  @shortdoc "Build mailglass_admin CSS bundle (production, minified)"

  @moduledoc """
  Compiles mailglass_admin/assets/css/app.css → mailglass_admin/priv/static/app.css
  via the `tailwind` Hex package (no Node toolchain).

  ## Usage

      mix mailglass_admin.assets.build

  Run after editing assets/css/app.css or touching any HEEx source under
  lib/mailglass_admin/. CI runs this then `git diff --exit-code priv/static/`
  (DIST-02 / CONTEXT D-04 gate).
  """

  use Mix.Task

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("tailwind", ["default", "--minify"])
  end
end
```

**Watch task** — same shape, body is `Mix.Task.run("tailwind", ["default", "--watch"])` (research lines 970–977).

**daisyui.update task** — research lines 979–1002 ships the body (curls latest releases via `:httpc.request/4`, prepends pin comment with date, writes to `assets/vendor/`).

---

### `mailglass_admin/test/mailglass_admin/router_test.exs`

**Analog:** `/Users/jon/projects/mailglass/test/mailglass/mailable_test.exs` lines 1–82 (test style — `use ExUnit.Case, async: true`, `defmodule SampleX do ... use ... end` fixtures inside the test module, descriptive `test "Test N: ..."` names).

**Test asserting session isolation** (research §"Test asserting isolation" lines 760–775):

```elixir
test "__session__/2 never returns adopter session keys" do
  conn =
    Plug.Test.conn(:get, "/")
    |> Plug.Test.init_test_session(%{
      "current_user_id" => 42,
      "csrf_token" => "secret"
    })

  session = MailglassAdmin.Router.__session__(conn, mailables: :auto_scan, live_session_name: :test)

  refute Map.has_key?(session, "current_user_id")
  refute Map.has_key?(session, "csrf_token")
  assert Enum.sort(Map.keys(session)) == ["live_session_name", "mailables"]
end
```

---

### `mailglass_admin/test/mailglass_admin/discovery_test.exs`

**Analog:** `test/mailglass/mailable_test.exs` lines 5–27 (in-test fixture mailable modules).

**Pattern:**

```elixir
defmodule MailglassAdmin.DiscoveryTest do
  use ExUnit.Case, async: true

  alias MailglassAdmin.Preview.Discovery

  defmodule HappyMailer do
    use Mailglass.Mailable, stream: :transactional
    def preview_props, do: [welcome: %{name: "Ada"}]
  end

  defmodule StubMailer do
    use Mailglass.Mailable, stream: :transactional
    # No preview_props/0 defined.
  end

  defmodule BrokenMailer do
    use Mailglass.Mailable, stream: :transactional
    def preview_props, do: raise("boom")
  end

  test "explicit list returns scenarios for healthy mailable" do
    assert [{HappyMailer, [welcome: %{name: "Ada"}]}] = Discovery.discover([HappyMailer])
  end

  test "stub mailable yields :no_previews sentinel" do
    assert [{StubMailer, :no_previews}] = Discovery.discover([StubMailer])
  end

  test "raising preview_props/0 yields {:error, formatted_stacktrace}" do
    assert [{BrokenMailer, {:error, msg}}] = Discovery.discover([BrokenMailer])
    assert msg =~ "boom"
  end
end
```

---

## Shared Patterns

### Module documentation style

**Source:** `/Users/jon/projects/mailglass/lib/mailglass/mailable.ex` lines 1–83
**Apply to:** every public module under `mailglass_admin/lib/`

Pattern: opening `@moduledoc` paragraph, `## Usage` block with literal adopter-side code, `## use opts` / `## Options`, `## Adopter convention`, `## Does NOT inject` / `## Does NOT do`. Reference docs/api_stability.md when defining a public contract.

### Function-level docs

**Source:** `/Users/jon/projects/mailglass/lib/mailglass/renderer.ex` lines 40–60
**Apply to:** every public function in mailglass_admin

Pattern:
```elixir
@doc """
[One-line summary.]

[Multi-paragraph body.]

## Examples

    iex> ...
"""
@doc since: "0.1.0"
@spec name(args) :: return_type
def name(args), do: ...
```

### Errors as structs (no message-string matching)

**Source:** `/Users/jon/projects/mailglass/lib/mailglass/error.ex` lines 22–32 + `lib/mailglass/errors/config_error.ex` lines 1–40
**Apply to:** any place mailglass_admin produces or pattern-matches errors (e.g., PreviewLive's `rerender/1`, Discovery's `reflect/1`, the assets controller's font path resolver)

Pattern excerpt (from error.ex lines 22–32):

```elixir
case result do
  {:error, %Mailglass.SuppressedError{type: :address}} -> ...
  {:error, %Mailglass.RateLimitError{retry_after_ms: ms}} -> ...
  {:error, %Mailglass.SendError{}} -> ...
end
```

mailglass_admin should NOT introduce its own error-struct hierarchy at v0.1 unless a NEW error class is required (e.g., `MailglassAdmin.AssetError` for missing/corrupt bundle — only if the planner deems it). If introduced, follow `lib/mailglass/errors/config_error.ex` shape:
- `@behaviour Mailglass.Error`
- `@types [...]` closed atom set
- `@derive {Jason.Encoder, only: [:type, :message, :context]}` (excluding `:cause` for PII safety, per error.ex lines 33–37)

### PubSub topic prefix (`mailglass:`)

**Source:** `/Users/jon/projects/mailglass/lib/mailglass/pub_sub/topics.ex` lines 17–34
**Apply to:** every `Phoenix.PubSub.broadcast/3` and `Phoenix.PubSub.subscribe/2` call in mailglass_admin

Pattern: build topics through a typed builder module (`MailglassAdmin.PubSub.Topics`), never inline strings. CLAUDE.md "Things Not To Do" implicitly covers; LINT-06 (Phase 6) AST-checks for the prefix.

### Telemetry whitelist (no PII in metadata)

**Source:** `/Users/jon/projects/mailglass/lib/mailglass/telemetry.ex` lines 96–104 + `lib/mailglass/renderer.ex` lines 64–69
**Apply to:** any telemetry mailglass_admin emits (none required at v0.1, but the discovery scan or render-on-edit may opt into a span)

Pattern (renderer.ex lines 64–69):

```elixir
metadata = %{
  tenant_id: message.tenant_id || "single_tenant",
  mailable: message.mailable
}

Telemetry.render_span(metadata, fn -> ... end)
```

**Whitelisted keys for PreviewLive telemetry:** `mailable`, `scenario`, `render_ms`, `mailables_count`, `live_reload_available`. **Forbidden:** `assigns` values, `to`, `from`, `subject`, `html_body`, `text_body`, `recipient`, `email`, `headers` (CLAUDE.md "Things Not To Do" #3 + research line 169).

### Optional-dep gateway

**Source:** `/Users/jon/projects/mailglass/lib/mailglass/optional_deps/sigra.ex` lines 1–33 + `lib/mailglass/optional_deps.ex` lines 13–40
**Apply to:** `mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex` (and any other optional dep added later)

Pattern: gateway module is the single authorized reference site; the rest of the codebase calls `Code.ensure_loaded?(MailglassAdmin.OptionalDeps.X)` to gate behavior. `@compile {:no_warn_undefined, [...]}` declared inside the gateway scoped to exactly the wrapped modules.

### `:persistent_term` once-per-BEAM gating (if needed)

**Source:** `/Users/jon/projects/mailglass/lib/mailglass/application.ex` lines 44–69
**Apply to:** any once-per-boot warning mailglass_admin needs to emit (e.g., a one-shot LiveReload-not-configured info log per UI-SPEC line 476)

Pattern (application.ex lines 46–69):

```elixir
already_warned? = :persistent_term.get({:mailglass_admin, :live_reload_warning}, false)

if not already_warned? and not Code.ensure_loaded?(Phoenix.LiveReloader) do
  Logger.info("[mailglass_admin] phoenix_live_reload not loaded; ...")
  :persistent_term.put({:mailglass_admin, :live_reload_warning}, true)
end
```

### Boundary declaration

**Source:** `/Users/jon/projects/mailglass/lib/mailglass.ex` lines 32–51
**Apply to:** the top of mailglass_admin's namespace (typically `mailglass_admin/lib/mailglass_admin.ex`)

Pattern:

```elixir
defmodule MailglassAdmin do
  use Boundary,
    deps: [Mailglass],  # mailglass_admin reads Renderer + Mailable; nothing else
    exports: [Router]   # only the router macro is public; everything else is internal
end
```

The renderer-purity rule (CORE-07) means PreviewLive may only call `Mailglass.Renderer.render/1` and `Mailglass.Message.*` builders — NOT `Mailglass.Outbound.deliver/2` (CLAUDE.md "Things Not To Do" #4 — preview NEVER sends).

### Mix task structure

**Source:** `/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.reconcile.ex` lines 1–72
**Apply to:** all three `mix mailglass_admin.*` tasks

Pattern: `use Boundary, classify_to: MailglassAdmin`, `@shortdoc`, full `@moduledoc` with `## Usage` and `## Options`, `use Mix.Task`, `@impl Mix.Task` on `run/1`.

### Hex package conventions

**Source:** `/Users/jon/projects/mailglass/mix.exs` lines 1–171
**Apply to:** `mailglass_admin/mix.exs`

Pattern: `@version` module attribute, `@source_url`, `name:` + `description:`, `package:` block with explicit `:files` whitelist, `docs:` block with `main:` + `source_ref:`. Add the path-vs-Hex `mailglass` dep switch (CONTEXT D-02) — this is the ONE pattern that has no analog in the existing tree.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `mailglass_admin/assets/vendor/daisyui.js` | vendored binary | n/a | Curled from upstream; no analog needed (Phoenix 1.8 installer convention) |
| `mailglass_admin/assets/vendor/daisyui-theme.js` | vendored binary | n/a | Same as above |
| `mailglass_admin/priv/static/mailglass-logo.svg` | static asset | n/a | Brand book §7 logo glyph; maintainer-produced |
| `mailglass_admin/priv/static/fonts/*.woff2` | font files | n/a | Pre-subset by maintainer (`glyphhanger`/`fonttools`) — research §"Don't Hand-Roll" line 713 explicitly defers to maintainer dev-time |
| `mailglass_admin/lib/mailglass_admin/layouts.ex` | layouts | n/a | mailglass core has no layout module (no LiveView surface yet); plan should follow stock Phoenix 1.8 `MyAppWeb.Layouts` shape — `embed_templates` or inline `~H` for `:root` and `:app` with the `<.live_title>` + `<link rel="stylesheet" href={~p"/css-#{Assets.css_hash()}"}/>` pattern |

---

## Open Items for Planner

1. **Layouts module shape:** No mailglass-internal analog exists. The planner should consult `~/projects/sigra/priv/templates/sigra.install/admin/layouts_admin_injection.ex` (referenced in CONTEXT canonical_refs but is install-template HTML, not a Phoenix.Component module). Default to stock Phoenix 1.8 generated `Layouts` module shape with two embedded HEEx templates (`root.html.heex`, `app.html.heex`).

2. **`MailglassAdmin` root module + Boundary decl:** `mailglass_admin/lib/mailglass_admin.ex` is not in the file list above but is the conventional namespace anchor and `use Boundary` site. Plan should include it.

3. **Logo SVG content:** Brand book §7 specifies a logo but no concrete SVG path is shipped in `prompts/`. Maintainer-produced asset; should not block Plan 5.

4. **`mailglass_admin` README + CHANGELOG:** Not in file list but required by `package[:files]` whitelist.

5. **Wave-0 `verify.phase05` Mix alias** in root `mix.exs`: follow the `verify.phase_03` / `verify.phase_04` pattern (mix.exs lines 117–132). The `mailglass_admin/` package will need its OWN `verify.phase_05` alias defined inside `mailglass_admin/mix.exs` (since mailglass core doesn't compile mailglass_admin).

6. **Tailwind 4.1.12 vs 4.x latest at plan time:** Pin per CONTEXT D-22; verify `{:tailwind, "~> 0.4"}` (which bundles Tailwind v4) version remains accurate at plan execution.

---

## Metadata

- **Analog search scope:** `/Users/jon/projects/mailglass/lib/`, `/Users/jon/projects/mailglass/test/`, `/Users/jon/projects/mailglass/deps/{phoenix_live_view,swoosh}/`, `/Users/jon/projects/sigra/lib/sigra/{admin,live_view}/`, research excerpts in `05-RESEARCH.md`, UI specs in `05-UI-SPEC.md`.
- **Files scanned (Read tool):** 12 (mailable.ex, error.ex, config_error.ex, optional_deps.ex, optional_deps/sigra.ex, pub_sub.ex, pub_sub/topics.ex, application.ex, message.ex, renderer.ex, components.ex header, telemetry.ex relevant range, mailglass.ex, mix.exs, mailable_test.exs header, mailer_case.ex header, sigra/admin/live/{index_live,users_index_live}.ex, sigra/live_view/admin_scope.ex, sigra/priv/templates/sigra.install/admin/router_injection.ex, swoosh/lib/plug/mailbox_preview.ex, mailglass.reconcile.ex, plus directory listings).
- **External analogs (NOT in deps/):** Phoenix LiveDashboard router + assets, Oban Web router — sourced from `05-RESEARCH.md` patterns 1 and 2 (verbatim research excerpts).
- **Pattern extraction date:** 2026-04-24
