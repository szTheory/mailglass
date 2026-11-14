defmodule MailglassAdmin.BrowserServerReadinessTest do
  use ExUnit.Case, async: false

  alias MailglassAdmin.TestAdopter.BrowserSessionController

  test "browser readiness stays unavailable until initial fixtures are seeded" do
    previous = Application.fetch_env(:mailglass_admin, :operator_browser_server_ready?)

    on_exit(fn ->
      case previous do
        {:ok, value} ->
          Application.put_env(:mailglass_admin, :operator_browser_server_ready?, value)

        :error ->
          Application.delete_env(:mailglass_admin, :operator_browser_server_ready?)
      end
    end)

    Application.put_env(:mailglass_admin, :operator_browser_server_ready?, false)
    starting = BrowserSessionController.ready(Plug.Test.conn(:get, "/ops/browser-ready"), %{})

    assert starting.status == 503
    assert starting.resp_body == "starting"

    Application.put_env(:mailglass_admin, :operator_browser_server_ready?, true)
    ready = BrowserSessionController.ready(Plug.Test.conn(:get, "/ops/browser-ready"), %{})

    assert ready.status == 200
    assert ready.resp_body == "ok"
  end
end
