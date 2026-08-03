defmodule Mix.Tasks.Mailglass.PreflightTest do
  use ExUnit.Case, async: false

  test "returns a nonzero status when production prerequisites fail without emitting secrets" do
    Application.put_env(:mailglass, :postmark, basic_auth: {"operator", "task-secret"})
    Application.put_env(:mailglass, :async_adapter, :task_supervisor)

    output = ExUnit.CaptureIO.capture_io(:stderr, fn ->
      assert catch_exit(Mix.Tasks.Mailglass.Preflight.run([])) == {:shutdown, 1}
    end)

    assert output =~ "[fail]"
    refute output =~ "task-secret"
  end
end
