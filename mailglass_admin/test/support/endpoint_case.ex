# Requires mailglass_admin/config/test.exs to set :mailglass_admin, MailglassAdmin.TestAdopter.Endpoint secret_key_base (Plan 02).
#
# Module order is load-bearing: MailglassAdmin.TestAdopter.Router is defined
# BEFORE MailglassAdmin.TestAdopter.Endpoint because the Endpoint pipes
# through the Router as a compile-time `plug`, and Plug.Builder calls
# `init/1` on each plug during its `__before_compile__` expansion — the
# plug module MUST already exist at that point. (Plan 01 landed these in
# the reverse order; Plan 02 corrected it so the test suite compiles.)
defmodule MailglassAdmin.TestAdopter.Router do
  @moduledoc """
  Synthetic adopter router that imports `MailglassAdmin.Router` and invokes
  `mailglass_admin_routes "/mail"` inside a `/dev` scope — the same shape
  the real-world adopter CONTEXT §specifics (lines 196-206) documents.

  Session isolation tests (Plan 03) and LiveView mount tests (Plan 06)
  both drive request flow through this router.
  """

  use Phoenix.Router
  import Phoenix.LiveView.Router
  import MailglassAdmin.Router

  # Force the optional-inbound gateway to compile + load BEFORE the
  # `mailglass_operator_routes` macro expands below. That macro gates the
  # `/inbound` route on `Code.ensure_loaded?(MailglassAdmin.OptionalDeps.MailglassInbound)`,
  # which is reliable in real adopter apps (mailglass_admin is a fully-compiled
  # dependency before the adopter router compiles) but RACES here: this synthetic
  # router lives in mailglass_admin's own test/support and compiles in the SAME
  # run as the gateway, with no tracked compile-time ordering between them. The
  # `ensure_compiled!/1` reference (the sanctioned gateway, never the MailglassInbound
  # dep — D-48-02) establishes that ordering so the route is emitted deterministically.
  Code.ensure_compiled!(MailglassAdmin.OptionalDeps.MailglassInbound)

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MailglassAdmin.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/dev" do
    pipe_through :browser
    mailglass_admin_routes "/mail",
      mailables: [
        :"Elixir.MailglassAdmin.Fixtures.HappyMailer",
        :"Elixir.MailglassAdmin.Fixtures.StubMailer",
        :"Elixir.MailglassAdmin.Fixtures.BrokenMailer"
      ]
  end

  scope "/ops" do
    pipe_through :browser

    get "/browser-ready", MailglassAdmin.TestAdopter.BrowserSessionController, :ready
    get "/browser-reset", MailglassAdmin.TestAdopter.BrowserSessionController, :reset
    get "/browser-login", MailglassAdmin.TestAdopter.BrowserSessionController, :create
    get "/browser-preview-empty", MailglassAdmin.TestAdopter.BrowserSessionController, :preview_empty

    mailglass_operator_routes "/mail",
      auth: MailglassAdmin.TestOperatorAuth,
      session: [
        subject_id: "current_user_id",
        tenant_id: "tenant_id",
        auth_method: "auth_method",
        recent_auth_at: "recent_auth_at"
      ],
      on_mount: [{MailglassAdmin.TestOperatorHook, :audit}],
      unauthorized_path: "/login",
      # CONTEXT D-48-07: thread the synthetic inbound router so Wave 2's
      # routing-trace card has declared inbound routes to reflect.
      inbound_router: MailglassAdmin.TestSupport.InboundTestRouter
  end
end

defmodule MailglassAdmin.TestAdopter.BrowserSessionController do
  use Phoenix.Controller, formats: [:html]

  alias MailglassAdmin.TestSupport.OperatorFixtures

  def ready(conn, _params) do
    text(conn, "ok")
  end

  def reset(conn, _params) do
    OperatorFixtures.seed_browser_scenario!()
    text(conn, "ok")
  end

  def create(conn, params) do
    tenant_id = Map.get(params, "tenant_id", "browser-tenant")
    return_to = Map.get(params, "return_to", "/ops/mail?tenant_id=#{tenant_id}")
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    conn
    |> Plug.Conn.put_session("current_user_id", "operator-1")
    |> Plug.Conn.put_session("tenant_id", tenant_id)
    |> Plug.Conn.put_session("auth_method", "password")
    |> Plug.Conn.put_session("recent_auth_at", now)
    |> Phoenix.Controller.redirect(to: return_to)
  end

  # Sets the preview mailables session key to [] so the preview surface renders its
  # orientation strip (the empty-mailables state). Used by the VERIF-02 orientation
  # strip e2e test, which must reach preview-orientation without real mailables in scope.
  def preview_empty(conn, _params) do
    conn
    |> Plug.Conn.put_session("mailables", [])
    |> Phoenix.Controller.redirect(to: "/dev/mail/")
  end
end

defmodule MailglassAdmin.TestOperatorHook do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  def on_mount(:audit, _params, _session, socket) do
    {:cont, assign(socket, :operator_hook, :audit)}
  end
end

defmodule MailglassAdmin.TestOperatorAuth do
  @moduledoc false

  @behaviour MailglassAdmin.Auth

  @max_age_seconds 900

  def authorize(:operator_access, %{actor: %{subject_id: nil}}) do
    {:error, :unauthorized, %{message: "Operator access requires a signed-in actor.", to: "/login"}}
  end

  def authorize(:operator_access, %{actor: %{subject_id: "blocked"}}) do
    {:error, :unauthorized, %{message: "Operator access denied.", to: "/login"}}
  end

  def authorize(:operator_access, %{actor: actor}) do
    {:ok,
     %{
       actor: Map.put_new(actor, :auth_method, actor[:auth_method] || "password"),
       assigns: %{operator_access_checked?: true}
     }}
  end

  def authorize(:destructive_action, %{actor: %{subject_id: nil}}) do
    {:error, :unauthorized, %{message: "Operator access requires a signed-in actor."}}
  end

  def authorize(:destructive_action, %{actor: %{recent_auth_at: nil}}) do
    {:error, :stale_auth, %{message: "Recent authentication is required."}}
  end

  def authorize(:destructive_action, %{actor: %{recent_auth_at: recent_auth_at}})
      when is_struct(recent_auth_at, DateTime) do
    if DateTime.diff(DateTime.utc_now(), recent_auth_at, :second) <= @max_age_seconds do
      {:ok, %{subject_id: "operator-1", recent_auth_at: recent_auth_at}}
    else
      {:error, :stale_auth, %{message: "Recent authentication is required."}}
    end
  end

  # Inbound replay capability (D-48-09 — rides the existing atom() action type, no
  # new auth surface). Denied for the sentinel actor so denial-path tests drive the
  # gate via the session-controlled subject_id; granted otherwise.
  def authorize(:replay_inbound, %{actor: %{subject_id: "deny-replay"}}) do
    {:error, :unauthorized,
     %{message: "Replay blocked: this action is not authorized for the current operator."}}
  end

  def authorize(:replay_inbound, %{actor: actor, inbound_record: _record}) do
    {:ok, %{actor: actor}}
  end

  # Evidence reveal capability (D-48-09). Denied for the sentinel actor; granted
  # otherwise.
  def authorize(:reveal_raw, %{actor: %{subject_id: "deny-reveal"}}) do
    {:error, :unauthorized,
     %{
       message:
         "Raw source not revealed: the reveal_raw capability is not granted for this operator."
     }}
  end

  def authorize(:reveal_raw, %{actor: actor}) do
    {:ok, %{actor: actor}}
  end
end

defmodule MailglassAdmin.TestAdopter.Endpoint do
  @moduledoc """
  Synthetic adopter Phoenix.Endpoint exercised by router + LiveView tests.

  Exists so the test suite can mount the real `MailglassAdmin.Router.mailglass_admin_routes/2`
  macro output without needing a full adopter Phoenix app. The endpoint is
  intentionally minimal: a session cookie (to assert `__session__/2`
  isolation against), a browser pipeline, and the macro call itself inside
  a `/dev` scope.

  Plan 02 is responsible for adding the `config :mailglass_admin, MailglassAdmin.TestAdopter.Endpoint`
  block to `mailglass_admin/config/test.exs` with a `secret_key_base` so
  this endpoint can boot under test.
  """

  use Phoenix.Endpoint, otp_app: :mailglass_admin

  @session_options [
    store: :cookie,
    key: "_mailglass_admin_test_session",
    signing_salt: "test-salt-01234567",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options], check_origin: false]

  plug Plug.Session, @session_options

  plug MailglassAdmin.TestAdopter.Router
end

defmodule MailglassAdmin.TestAdopter.ErrorHTML do
  @moduledoc false

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

defmodule MailglassAdmin.EndpointCase do
  @moduledoc """
  ConnTest harness wrapping the synthetic adopter endpoint.

  Tests using this template get `@endpoint MailglassAdmin.TestAdopter.Endpoint`,
  Plug.Conn + Phoenix.ConnTest imports, and a per-test `conn:` fixture. The
  synthetic endpoint is started once per suite via `setup_all`.

  Use this template for router macro expansion tests, asset controller
  tests, and `__session__/2` isolation tests — any test that needs a real
  `conn` routed through the macro-expanded router.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      alias MailglassAdmin.TestAdopter.Router.Helpers, as: Routes
      @endpoint MailglassAdmin.TestSupport.AdminBootstrap.endpoint()
    end
  end

  setup_all do
    MailglassAdmin.TestSupport.AdminBootstrap.setup_all()
  end

  setup do
    {:ok, conn: MailglassAdmin.TestSupport.AdminBootstrap.build_conn()}
  end
end
