# Phase 23: Production Mount + Step-Up Auth - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 9
**Analogs found:** 8 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/router.ex` | router | request-response | `mailglass_admin/lib/mailglass_admin/router.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/mount.ex` | hook / middleware | request-response | `mailglass_admin/lib/mailglass_admin/preview/mount.ex` + `lib/mailglass/tenancy.ex` | partial |
| `mailglass_admin/lib/mailglass_admin/operator/session.ex` or router-owned session shaping in `router.ex` | utility / router seam | request-response | `mailglass_admin/lib/mailglass_admin/router.ex::__session__/2` | exact |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | LiveView page | request-response | `mailglass_admin/lib/mailglass_admin/operator_live.ex` | exact |
| `mailglass_admin/lib/mailglass_admin/optional_deps/*.ex` for auth helper | optional-dependency gateway | request-response | `lib/mailglass/optional_deps/sigra.ex` + `mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex` | strong |
| `mailglass_admin/test/mailglass_admin/router_test.exs` | router test | request-response | `mailglass_admin/test/mailglass_admin/router_test.exs` | exact |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | LiveView test | request-response | `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | exact |
| `mailglass_admin/test/support/live_view_case.ex` and/or `mailglass_admin/test/support/endpoint_case.ex` | test support | request-response | same files | exact |
| `mailglass_admin/README.md` | docs / config contract | request-response | `mailglass_admin/README.md` | exact |

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/router.ex` (router, request-response)

**Analog:** `mailglass_admin/lib/mailglass_admin/router.ex`

**Macro opts + live_session pattern** ([mailglass_admin/lib/mailglass_admin/router.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:68)):
```elixir
@opts_schema [
  on_mount: [
    type: {:list, :atom},
    default: [],
    doc: "Extra on_mount hooks appended BEFORE the internal Preview.Mount."
  ],
  live_session_name: [
    type: :atom,
    default: :mailglass_admin_preview,
    doc: "Name of the library-owned live_session. Rename to resolve collisions."
  ]
]
```

**Route expansion + hook ordering** ([mailglass_admin/lib/mailglass_admin/router.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:116)):
```elixir
scope path, alias: false, as: false do
  ...
  on_mount_hooks = opts[:on_mount] ++ [MailglassAdmin.Preview.Mount]

  live_session session_name,
    session: {MailglassAdmin.Router, :__session__, [opts]},
    on_mount: on_mount_hooks,
    root_layout: {MailglassAdmin.Layouts, :root} do
    live "/", MailglassAdmin.PreviewLive, :index
    live "/:mailable/:scenario", MailglassAdmin.PreviewLive, :show
    live "/operator", MailglassAdmin.OperatorLive, :index
  end
end
```

**Whitelisted session shaping** ([mailglass_admin/lib/mailglass_admin/router.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:137)):
```elixir
def __session__(conn, opts) do
  mailables =
    case Plug.Conn.get_session(conn, "mailables") do
      modules when is_list(modules) -> modules
      _ -> opts[:mailables]
    end

  %{
    "mailables" => mailables,
    "live_session_name" => opts[:live_session_name]
  }
end
```

**Planner notes**
- Evolve the macro by adding explicit prod/operator opts; do not fork a second mount macro unless the public API really diverges.
- Keep adopter-owned auth outside the macro body; the existing contract explicitly avoids `Mix.env()` enforcement and treats router wrapping as adopter responsibility.
- Any session additions for operator auth should stay whitelisted and minimal, likely a small auth context map instead of raw session passthrough.

---

### `mailglass_admin/lib/mailglass_admin/operator/mount.ex` (hook, request-response)

**Analog:** `mailglass_admin/lib/mailglass_admin/preview/mount.ex`

**Existing internal on_mount contract** ([mailglass_admin/lib/mailglass_admin/preview/mount.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/preview/mount.ex:8)):
```elixir
## Order (Phoenix LiveView 1.1)

    session callback (MailglassAdmin.Router.__session__/2)
      -> opts[:on_mount] hooks (adopter-provided, in order given)
      -> MailglassAdmin.Preview.Mount (this module)
      -> MailglassAdmin.PreviewLive.mount/3
```

**Current always-cont implementation** ([mailglass_admin/lib/mailglass_admin/preview/mount.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/preview/mount.ex:44)):
```elixir
@spec on_mount(atom(), map() | :not_mounted_at_router, map(), Phoenix.LiveView.Socket.t()) ::
        {:cont, Phoenix.LiveView.Socket.t()}
def on_mount(:default, _params, session, socket) do
  mailables_opt = Map.get(session, "mailables", :auto_scan)
  mailables = Discovery.discover(mailables_opt)

  {:cont, assign(socket, :mailables, mailables)}
end
```

**Closest adopter-owned identity handoff pattern** ([lib/mailglass/tenancy.ex](/Users/jon/projects/mailglass/lib/mailglass/tenancy.ex:26)):
```elixir
def on_mount(_name, _params, _session, socket) do
  scope = socket.assigns.current_scope
  Mailglass.Tenancy.put_current(scope.organization.id)
  {:cont, socket}
end
```

**Planner notes**
- The new operator mount hook should copy the `on_mount/4` shape and `{:cont, socket}` / `{:halt, socket}` control flow from `Preview.Mount`, but use an adopter-supplied auth context rather than discovery.
- The repo already documents `%Phoenix.Scope{}` interop as an adopter concern; Phase 23 should keep that boundary and consume stamped scope/auth state instead of pattern-matching adopter structs inside mailglass_admin.
- There is no existing in-repo auth gate module; this file is the main “new seam” for Phase 23.

---

### `mailglass_admin/lib/mailglass_admin/operator/session.ex` or `router.ex::__session__/2` changes (utility, request-response)

**Analog:** `mailglass_admin/lib/mailglass_admin/router.ex::__session__/2`

**Minimal explicit map return** ([mailglass_admin/lib/mailglass_admin/router.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:146)):
```elixir
def __session__(conn, opts) do
  ...
  %{
    "mailables" => mailables,
    "live_session_name" => opts[:live_session_name]
    # Add keys here ONLY when intentionally surfacing them to PreviewLive.
    # NEVER pass conn.private.plug_session through wholesale.
  }
end
```

**Planner notes**
- Keep session shaping in one explicit function, even if Phase 23 extracts it into a helper module.
- The key pattern to preserve is “derive exact fields, return a small map, never forward opaque session state”.
- Recent-auth freshness should likely be represented as a library-neutral boolean/timestamp contract, not direct adopter session internals.

---

### `mailglass_admin/lib/mailglass_admin/operator_live.ex` (LiveView page, request-response)

**Analog:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`

**Mount assign initialization** ([mailglass_admin/lib/mailglass_admin/operator_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:29)):
```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:deliveries, [])
   |> assign(:selected_delivery, nil)
   |> assign(:timeline_events, [])
   |> assign(:suppression_state, nil)
   |> assign(:detail_error, nil)
   |> assign(:base_path, "/operator")
   |> assign(:filter_params, default_filter_params())
   |> assign(:filter_form, to_form(default_filter_params(), as: :filters))}
end
```

**URL-backed state + push_patch flow** ([mailglass_admin/lib/mailglass_admin/operator_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:47)):
```elixir
def handle_params(params, uri, socket) do
  filter_params = normalize_filter_params(params)
  deliveries = load_deliveries(filter_params)
  selected_delivery_id = blank_to_nil(params["delivery_id"])
  ...
  {:noreply,
   socket
   |> assign(:base_path, URI.parse(uri).path || "/operator")
   |> assign(:deliveries, deliveries)
   |> assign(:filter_params, filter_params)
   |> assign(:filter_form, to_form(filter_params, as: :filters))}
end
```

**Current read-only boundary in render tree** ([mailglass_admin/lib/mailglass_admin/operator_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:151)):
```elixir
<%= cond do %>
  <% @detail_error -> %>
    ...
  <% is_nil(@selected_delivery) -> %>
    ...
  <% true -> %>
    <DetailHeader.detail_header delivery={@selected_delivery} />
    <OperatorTimeline.timeline timeline_events={@timeline_events} />
    <SuppressionCard.suppression_card suppression_state={@suppression_state} />
<% end %>
```

**Planner notes**
- Preserve the existing URL-state model. Destructive controls and step-up prompts should patch/navigate through this same `base_path` flow rather than introducing hidden state.
- Keep operator data reads behind the existing core operator modules; auth additions should gate actions, not re-embed data access logic into the LiveView.
- Phase 22 intentionally left this page read-only; Phase 23 should add auth/session wiring first, not jump to replay/unsuppress execution semantics from Phase 24.

---

### `mailglass_admin/lib/mailglass_admin/optional_deps/*.ex` (optional-dependency gateway, request-response)

**Analog 1:** `lib/mailglass/optional_deps/sigra.ex`

**Conditional compile pattern** ([lib/mailglass/optional_deps/sigra.ex](/Users/jon/projects/mailglass/lib/mailglass/optional_deps/sigra.ex:1)):
```elixir
if Code.ensure_loaded?(Sigra) do
  defmodule Mailglass.OptionalDeps.Sigra do
    @compile {:no_warn_undefined, [Sigra]}

    @spec available?() :: true
    def available?, do: true
  end
end
```

**Analog 2:** `mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex`

**Package-local mirror of the same seam** ([mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex:1)):
```elixir
if Code.ensure_loaded?(Phoenix.LiveReloader) do
  defmodule MailglassAdmin.OptionalDeps.PhoenixLiveReload do
    @compile {:no_warn_undefined, [Phoenix.LiveReloader]}

    @spec available?() :: boolean()
    def available?, do: true
  end
end
```

**Fallback-bearing variant** ([lib/mailglass/webhook/pruner.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/pruner.ex:117)):
```elixir
else
  defmodule Mailglass.Webhook.Pruner do
    @spec available?() :: false
    def available?, do: false
  end
end
```

**Planner notes**
- If Phase 23 introduces optional Sigra integration, follow the conditional-compile gateway pattern and require callers to guard with `Code.ensure_loaded?/1`.
- If the operator auth helper needs a usable fallback when the dep is missing, copy the `Pruner` stub approach instead of exposing bare third-party references.
- Keep all third-party auth references behind a mailglass-owned gateway module.

---

### `mailglass_admin/test/mailglass_admin/router_test.exs` (router test, request-response)

**Analog:** `mailglass_admin/test/mailglass_admin/router_test.exs`

**Macro route assertions** ([mailglass_admin/test/mailglass_admin/router_test.exs](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/router_test.exs:14)):
```elixir
routes = MailglassAdmin.TestAdopter.Router.__routes__()

assert Enum.any?(routes, fn r ->
         r.verb == :get and r.path == "/dev/mail/css-:md5"
       end)
...
assert Enum.any?(routes, fn r ->
         r.verb == :get and r.path == "/dev/mail/:mailable/:scenario"
       end)
```

**Session isolation assertions** ([mailglass_admin/test/mailglass_admin/router_test.exs](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/router_test.exs:50)):
```elixir
session =
  MailglassAdmin.Router.__session__(conn,
    mailables: :auto_scan,
    live_session_name: :test_session
  )

refute Map.has_key?(session, "current_user_id")
refute Map.has_key?(session, "csrf_token")
assert Enum.sort(Map.keys(session)) == ["live_session_name", "mailables"]
```

**Planner notes**
- Extend this file for new route shapes and session keys.
- The important pattern is literal verification of public macro output and exact allowed session keys.

---

### `mailglass_admin/test/mailglass_admin/operator_live_test.exs` (LiveView test, request-response)

**Analog:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs`

**URL-backed interaction assertions** ([mailglass_admin/test/mailglass_admin/operator_live_test.exs](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/operator_live_test.exs:32)):
```elixir
{:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id}))

view
|> form("#operator-filters", filters: %{...})
|> render_submit()

assert_patch(view, operator_path(%{...}))
```

**Current phase-boundary assertions** ([mailglass_admin/test/mailglass_admin/operator_live_test.exs](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/operator_live_test.exs:142)):
```elixir
refute html =~ "Replay"
refute html =~ "Remove suppression"
refute html =~ "recent-auth"
refute html =~ "recent auth"
```

**Planner notes**
- Replace the Phase 22 “absence” assertions with Phase 23 auth/mount assertions incrementally; keep the same literal-string style.
- This file is the right place to prove step-up prompts, blocked destructive controls, and recently-authenticated happy paths without inventing a second test style.

---

### `mailglass_admin/test/support/live_view_case.ex` and `mailglass_admin/test/support/endpoint_case.ex` (test support, request-response)

**Analog:** existing admin test harness

**LiveView harness** ([mailglass_admin/test/support/live_view_case.ex](/Users/jon/projects/mailglass/mailglass_admin/test/support/live_view_case.ex:17)):
```elixir
using opts do
  quote do
    use ExUnit.Case, unquote(opts)
    import Plug.Conn
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest
    @endpoint MailglassAdmin.TestSupport.AdminBootstrap.endpoint()
  end
end
```

**Per-test repo + tenant setup** ([mailglass_admin/test/support/live_view_case.ex](/Users/jon/projects/mailglass/mailglass_admin/test/support/live_view_case.ex:33)):
```elixir
setup do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MailglassAdmin.TestRepo, shared: true)
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

  Mailglass.Tenancy.put_current("test-tenant")

  {:ok, conn: MailglassAdmin.TestSupport.AdminBootstrap.build_conn()}
end
```

**Synthetic adopter endpoint/router seam** ([mailglass_admin/test/support/endpoint_case.ex](/Users/jon/projects/mailglass/mailglass_admin/test/support/endpoint_case.ex:9)):
```elixir
defmodule MailglassAdmin.TestAdopter.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  import MailglassAdmin.Router

  scope "/dev" do
    pipe_through :browser
    mailglass_admin_routes "/mail", ...
  end
end
```

**Planner notes**
- Put production-mount router contract tests through the synthetic adopter router first; that already mirrors real adopter macro usage.
- If Phase 23 needs fake auth freshness/session data, inject it through `build_conn()` / test-session setup here rather than bypassing the router.

---

### `mailglass_admin/README.md` (docs, request-response)

**Analog:** existing mount contract docs

**Current install/mount instructions** ([mailglass_admin/README.md](/Users/jon/projects/mailglass/mailglass_admin/README.md:20)):
```md
import MailglassAdmin.Router

if Application.compile_env(:my_app, :dev_routes) do
  scope "/dev" do
    pipe_through :browser
    mailglass_admin_routes "/mail"
  end
end
```

**Current explicit non-goal text** ([mailglass_admin/README.md](/Users/jon/projects/mailglass/mailglass_admin/README.md:91)):
```md
- Any prod-mountable admin surface ... That lands at v0.5.
- Authentication or step-up protection. Dev-only mount relies on the
  adopter's `:dev_routes` wrapper — do not mount this in production.
```

**Planner notes**
- Phase 23 needs to rewrite these sections, not append contradictory docs.
- Keep the README style concrete and adopter-oriented: exact router snippet, exact optional deps/setup snippet, and exact responsibility split.

## Shared Patterns

### Router Macro Evolution
**Source:** [mailglass_admin/lib/mailglass_admin/router.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:68)
```elixir
@opts_schema [...]
opts = validate_opts!(opts)
live_session session_name,
  session: {MailglassAdmin.Router, :__session__, [opts]},
  on_mount: on_mount_hooks,
  root_layout: {MailglassAdmin.Layouts, :root} do
```
Apply to all router/mount work. Add opts via `NimbleOptions`, preserve compile-time validation, and keep all public mount behavior visible in the macro contract.

### Adopter-Owned Auth / Scope Hand-off
**Source:** [lib/mailglass/tenancy.ex](/Users/jon/projects/mailglass/lib/mailglass/tenancy.ex:28)
```elixir
def on_mount(_name, _params, _session, socket) do
  scope = socket.assigns.current_scope
  Mailglass.Tenancy.put_current(scope.organization.id)
  {:cont, socket}
end
```
Apply to new operator auth hooks. Mailglass should consume a small, explicit auth/scope seam; it should not own the adopter identity model.

### Session Whitelisting
**Source:** [mailglass_admin/lib/mailglass_admin/router.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:147)
```elixir
%{
  "mailables" => mailables,
  "live_session_name" => opts[:live_session_name]
}
```
Apply to operator auth/session shaping. Extend by adding specific keys only; never tunnel raw `plug_session`.

### Optional Dependency Gateway
**Source:** [lib/mailglass/optional_deps/sigra.ex](/Users/jon/projects/mailglass/lib/mailglass/optional_deps/sigra.ex:1), [mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/optional_deps/phoenix_live_reload.ex:1)
```elixir
if Code.ensure_loaded?(DepModule) do
  defmodule ... do
    @compile {:no_warn_undefined, [DepModule]}
    def available?, do: true
  end
end
```
Apply to Sigra or any optional step-up provider seam.

### Admin Test Harness
**Source:** [mailglass_admin/test/support/live_view_case.ex](/Users/jon/projects/mailglass/mailglass_admin/test/support/live_view_case.ex:33), [mailglass_admin/test/support/endpoint_case.ex](/Users/jon/projects/mailglass/mailglass_admin/test/support/endpoint_case.ex:9)
```elixir
pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MailglassAdmin.TestRepo, shared: true)
Mailglass.Tenancy.put_current("test-tenant")
{:ok, conn: MailglassAdmin.TestSupport.AdminBootstrap.build_conn()}
```
Apply to all new operator auth tests; keep exercising the real macro-expanded router and LiveView endpoint.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/operator/auth.ex` or any dedicated recent-auth verifier module | service / hook | request-response | The repo has no existing production admin auth or step-up verification implementation. The closest seams are `Preview.Mount`, `Mailglass.Tenancy`'s adopter-owned `on_mount` example, and the optional-deps gateways. Planner should use those seams plus Phase 23 research for the actual recent-auth contract. |

## Metadata

**Analog search scope:** `mailglass_admin/lib`, `mailglass_admin/test`, `lib/mailglass`, `test/support`, `.planning`

**Files scanned:** 14 primary files plus targeted `rg` searches

**Pattern extraction date:** 2026-05-01
