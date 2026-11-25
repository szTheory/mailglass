defmodule MailglassAdmin.TestSupport.AdminBootstrapTest do
  use ExUnit.Case, async: false

  alias MailglassAdmin.TestRepo
  alias MailglassAdmin.TestSupport.AdminBootstrap

  test "test endpoint binds only to loopback" do
    endpoint = AdminBootstrap.endpoint()
    previous_endpoint_config = Application.get_env(:mailglass_admin, endpoint)

    on_exit(fn ->
      if previous_endpoint_config do
        Application.put_env(:mailglass_admin, endpoint, previous_endpoint_config)
      else
        Application.delete_env(:mailglass_admin, endpoint)
      end
    end)

    AdminBootstrap.configure_endpoint(port: 49123)

    assert Application.get_env(:mailglass_admin, endpoint)[:http] ==
             [ip: {127, 0, 0, 1}, port: 49123]
  end

  test "start_server_owner!/1 grants shared sandbox access to spawned work" do
    owner = AdminBootstrap.start_server_owner!(ownership_timeout: 60_000)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(owner)
    end)

    task =
      Task.async(fn ->
        result = Ecto.Adapters.SQL.query!(TestRepo, "SELECT 1", [])
        [[value]] = result.rows
        value
      end)

    assert Task.await(task) == 1
  end
end
