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
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {MailglassAdmin.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/dev" do
    pipe_through(:browser)

    mailglass_admin_routes("/mail",
      mailables: [
        :"Elixir.MailglassAdmin.Fixtures.HappyMailer",
        :"Elixir.MailglassAdmin.Fixtures.StubMailer",
        :"Elixir.MailglassAdmin.Fixtures.BrokenMailer"
      ],
      navigation: [
        overview_path: "/ops/mail?tenant_id=browser-tenant",
        deliveries_path: "/ops/mail?tenant_id=browser-tenant&view=deliveries",
        inbound_path: "/ops/mail/inbound?tenant_id=browser-tenant"
      ]
    )
  end

  scope "/alt/dev" do
    pipe_through(:browser)

    mailglass_admin_routes("/console",
      live_session_name: :mailglass_admin_preview_alt,
      mailables: [
        :"Elixir.MailglassAdmin.Fixtures.HappyMailer",
        :"Elixir.MailglassAdmin.Fixtures.StubMailer",
        :"Elixir.MailglassAdmin.Fixtures.BrokenMailer"
      ]
    )
  end

  scope "/ops" do
    pipe_through(:browser)

    get("/browser-ready", MailglassAdmin.TestAdopter.BrowserSessionController, :ready)
    get("/browser-reset", MailglassAdmin.TestAdopter.BrowserSessionController, :reset)
    get("/browser-auth-log", MailglassAdmin.TestAdopter.BrowserSessionController, :auth_log)
    post("/browser-mutate", MailglassAdmin.TestAdopter.BrowserSessionController, :mutate)
    get("/browser-login", MailglassAdmin.TestAdopter.BrowserSessionController, :create)

    get(
      "/browser-preview-empty",
      MailglassAdmin.TestAdopter.BrowserSessionController,
      :preview_empty
    )

    mailglass_operator_routes("/mail",
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
      inbound_router: MailglassAdmin.TestSupport.InboundTestRouter,
      navigation: [
        preview_path: "/dev/mail"
      ]
    )
  end

  scope "/secure" do
    pipe_through(:browser)

    mailglass_operator_routes("/console",
      live_session_name: :mailglass_admin_operator_alt,
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
    )
  end
end

defmodule MailglassAdmin.TestAdopter.BrowserSessionController do
  use Phoenix.Controller, formats: [:html]

  alias MailglassAdmin.TestSupport.OperatorFixtures

  def ready(conn, _params) do
    text(conn, "ok")
  end

  def reset(conn, _params) do
    conn = Plug.Conn.fetch_query_params(conn)

    result =
      case conn.query_params["scenario"] do
        nil ->
          {:ok, OperatorFixtures.seed_browser_scenario!()}

        "default" ->
          {:ok, OperatorFixtures.seed_browser_scenario!()}

        "sole" ->
          {:ok, OperatorFixtures.seed_browser_scenario!(deny_reveal?: false)}

        "accounts" ->
          {:ok, OperatorFixtures.seed_persona_cohort!()}

        "phase169-exact" ->
          {:ok, OperatorFixtures.seed_phase169_scenario!()}

        scenario
        when scenario in ["phase169-replay-zero", "phase169-replay-one", "phase169-replay-many"] ->
          variant = scenario |> String.replace_prefix("phase169-replay-", "")
          {:ok, OperatorFixtures.seed_phase169_replay!(variant)}

        "phase169-timeline-101" ->
          {:ok, OperatorFixtures.seed_phase169_timeline_101!()}

        "phase169-suppression" ->
          case conn.query_params["variant"] || "one" do
            variant when variant in ["empty", "one", "many"] ->
              {:ok, OperatorFixtures.seed_phase169_suppression!(variant)}

            _ ->
              :unknown
          end

        "phase169-health-partial" ->
          {:ok, OperatorFixtures.seed_phase169_health_partial!()}

        "phase169-support-empty" ->
          {:ok, OperatorFixtures.seed_phase169_support_empty!()}

        _ ->
          :unknown
      end

    case result do
      {:ok, payload} ->
        MailglassAdmin.TestOperatorAuth.reset_destructive_calls!()
        json(conn, payload)

      :unknown ->
        conn |> put_status(:bad_request) |> text("unknown browser scenario")
    end
  end

  def auth_log(conn, _params) do
    json(conn, %{destructive_actions: MailglassAdmin.TestOperatorAuth.destructive_calls()})
  end

  def mutate(conn, params) do
    conn = Plug.Conn.fetch_query_params(conn)
    params = Map.merge(conn.query_params, params)
    session_key = get_session(conn, "current_user_id")

    operation = Map.get(params, "operation")
    action = Map.get(params, "action")

    kind =
      case action do
        "arm-known-read-failure" -> :known
        "arm-unexpected-read-failure" -> :unexpected
        _ -> nil
      end

    if is_binary(session_key) and action == "phase169-replay-mutate" do
      try do
        result = OperatorFixtures.mutate_phase169_scenario!(Map.get(params, "mutation"))
        json(conn, %{mutated: true, result: result})
      rescue
        ArgumentError -> conn |> put_status(:bad_request) |> text("unsupported test mutation")
      end
    else
      if is_binary(session_key) and is_binary(operation) and kind do
        try do
          OperatorFixtures.arm_reader_fault!(session_key, operation, kind)
          json(conn, %{armed: true, operation: operation, action: action})
        rescue
          ArgumentError -> conn |> put_status(:bad_request) |> text("unsupported test mutation")
        end
      else
        conn |> put_status(:bad_request) |> text("unsupported test mutation")
      end
    end
  end

  def create(conn, params) do
    conn = Plug.Conn.fetch_query_params(conn)
    params = Map.merge(conn.query_params, params)

    tenant_id = Map.get(params, "tenant_id", "browser-tenant")
    return_to = Map.get(params, "return_to", "/ops/mail?tenant_id=#{tenant_id}")
    subject_id = Map.get(params, "subject_id", "operator-1")
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    recent_auth_at = Map.get(params, "recent_auth_at", now)

    conn
    |> Plug.Conn.put_session("current_user_id", subject_id)
    |> Plug.Conn.put_session("subject_id", subject_id)
    |> Plug.Conn.put_session("tenant_id", tenant_id)
    |> Plug.Conn.put_session("auth_method", "password")
    |> Plug.Conn.put_session("recent_auth_at", recent_auth_at)
    |> Plug.Conn.put_resp_header("cache-control", "no-store")
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

  def on_mount(:audit, _params, session, socket) do
    requested_fault =
      case Map.get(session, "auth_method") do
        "fault:" <> fault -> fault
        _ -> nil
      end

    fault =
      if requested_fault in ["deliveries", "exact_delivery", "replay_history", "replay_targets"],
        do: requested_fault,
        else: nil

    session_key = Map.get(session, "current_user_id")

    callback = fn operation ->
      if fault == Atom.to_string(operation) do
        raise DBConnection.ConnectionError, message: "synthetic transient operator read failure"
      end

      case MailglassAdmin.TestSupport.OperatorFixtures.take_reader_fault(session_key, operation) do
        :known ->
          raise DBConnection.ConnectionError, message: "synthetic transient operator read failure"

        :unexpected ->
          raise ArgumentError, "synthetic unexpected operator read failure"

        nil ->
          :ok
      end
    end

    {:cont,
     socket
     |> assign(:operator_hook, :audit)
     |> assign(:operator_read_fault, callback)}
  end
end

defmodule MailglassAdmin.TestOperatorAuth do
  @moduledoc false

  @behaviour MailglassAdmin.Auth

  @max_age_seconds 900

  def reset_destructive_calls!, do: :persistent_term.put({__MODULE__, :destructive_calls}, [])
  def destructive_calls, do: :persistent_term.get({__MODULE__, :destructive_calls}, [])
  def reset_inbound_replay_calls!, do: :persistent_term.put({__MODULE__, :inbound_replay_calls}, [])

  def inbound_replay_calls do
    {__MODULE__, :inbound_replay_calls}
    |> :persistent_term.get([])
    |> Enum.reverse()
  end

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

  def authorize(
        :destructive_action,
        %{
          actor: %{recent_auth_at: recent_auth_at},
          delivery: delivery,
          replay_target: target
        }
      )
      when is_struct(recent_auth_at, DateTime) do
    record_destructive_call(delivery.id, target.webhook_event_id)

    if DateTime.diff(DateTime.utc_now(), recent_auth_at, :second) <= @max_age_seconds do
      {:ok, %{subject_id: "operator-1", recent_auth_at: recent_auth_at}}
    else
      {:error, :stale_auth, %{message: "Recent authentication is required."}}
    end
  end

  # Inbound replay capability (D-48-09 — rides the existing atom() action type, no
  # new auth surface). Denied for the sentinel actor so denial-path tests drive the
  # gate via the session-controlled subject_id; granted otherwise.
  def authorize(
        :replay_inbound,
        %{actor: %{subject_id: "deny-replay"}, inbound_record: record}
      ) do
    record_inbound_replay_call(record.id)

    {:error, :unauthorized,
     %{message: "Replay blocked: this action is not authorized for the current operator."}}
  end

  def authorize(:replay_inbound, %{actor: actor, inbound_record: record}) do
    record_inbound_replay_call(record.id)
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

  def authorize(:reveal_raw, %{actor: %{tenant_id: "deny-reveal"}}) do
    {:error, :unauthorized,
     %{
       message:
         "Raw source not revealed: the reveal_raw capability is not granted for this operator."
     }}
  end

  def authorize(:reveal_raw, %{actor: actor}) do
    {:ok, %{actor: actor}}
  end

  defp record_inbound_replay_call(record_id) do
    key = {__MODULE__, :inbound_replay_calls}
    :persistent_term.put(key, [record_id | :persistent_term.get(key, [])])
  end

  defp record_destructive_call(delivery_id, webhook_event_id) do
    calls = destructive_calls()

    :persistent_term.put(
      {__MODULE__, :destructive_calls},
      [
        %{delivery_id: delivery_id, webhook_event_id: webhook_event_id, at: DateTime.utc_now()}
        | calls
      ]
    )
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

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options], check_origin: false]
  )

  plug(Plug.Session, @session_options)

  plug(MailglassAdmin.TestAdopter.Router)
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
