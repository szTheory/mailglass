defmodule Mailglass.DemoDataTest do
  use ExUnit.Case, async: false

  @demo_app Path.expand("../../reference/demo_app", __DIR__)

  test "demo app fixture suite passes from repo root" do
    {create_output, create_exit} =
      System.cmd("mix", ["ecto.create"],
        cd: @demo_app,
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    assert create_exit == 0,
           "reference demo app ecto.create failed:\n#{create_output}"

    {migrate_output, migrate_exit} =
      System.cmd("mix", ["ecto.migrate"],
        cd: @demo_app,
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    assert migrate_exit == 0,
           "reference demo app ecto.migrate failed:\n#{migrate_output}"

    {test_output, test_exit} =
      System.cmd("sh", ["-lc", "mix test test/mailglass_demo/*.exs --warnings-as-errors"],
        cd: @demo_app,
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    assert test_exit == 0,
           "reference demo app fixture tests failed:\n#{test_output}"
  end
end
