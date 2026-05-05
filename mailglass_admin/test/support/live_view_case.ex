defmodule MailglassAdmin.LiveViewCase do
  @moduledoc """
  Phoenix.LiveViewTest wrapper around the synthetic `MailglassAdmin.TestAdopter.Endpoint`.

  Tests using this template get `@endpoint MailglassAdmin.TestAdopter.Endpoint`,
  Plug.Conn + Phoenix.ConnTest + Phoenix.LiveViewTest imports, and a per-test
  `conn:` fixture. The synthetic endpoint is started once per suite via
  `setup_all` (mirroring `MailglassAdmin.EndpointCase`).

  Use this template for any test that calls `live/2`, `render_click/2`,
  `render_change/2`, or otherwise exercises `MailglassAdmin.PreviewLive`
  mounted by the macro-expanded router.
  """

  use ExUnit.CaseTemplate

  using opts do
    quote do
      use ExUnit.Case, unquote(opts)
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      alias MailglassAdmin.TestAdopter.Router.Helpers, as: Routes
      alias MailglassAdmin.TestRepo
      @endpoint MailglassAdmin.TestSupport.AdminBootstrap.endpoint()
    end
  end

  setup_all do
    MailglassAdmin.TestSupport.AdminBootstrap.setup_all()
  end

  setup do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MailglassAdmin.TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    MailglassAdmin.TestSupport.CitextProbe.run(repo: MailglassAdmin.TestRepo)
    Mailglass.Tenancy.put_current("test-tenant")

    {:ok, conn: MailglassAdmin.TestSupport.AdminBootstrap.build_conn()}
  end
end
