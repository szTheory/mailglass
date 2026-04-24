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

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
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
