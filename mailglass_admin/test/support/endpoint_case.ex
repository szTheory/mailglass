# Requires mailglass_admin/config/test.exs to set :mailglass_admin, MailglassAdmin.TestAdopter.Endpoint secret_key_base (Plan 02).
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

  plug Plug.Session,
    store: :cookie,
    key: "_mailglass_admin_test_session",
    signing_salt: "test-salt-01234567",
    same_site: "Lax"

  plug MailglassAdmin.TestAdopter.Router
end

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
    mailglass_admin_routes "/mail"
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
      @endpoint MailglassAdmin.TestAdopter.Endpoint
    end
  end

  setup_all do
    {:ok, _} = Application.ensure_all_started(:phoenix)
    _ = MailglassAdmin.TestAdopter.Endpoint.start_link()
    :ok
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
