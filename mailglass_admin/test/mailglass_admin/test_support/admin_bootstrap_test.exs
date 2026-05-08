defmodule MailglassAdmin.TestSupport.AdminBootstrapTest do
  use ExUnit.Case, async: false

  alias MailglassAdmin.TestRepo
  alias MailglassAdmin.TestSupport.AdminBootstrap

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
