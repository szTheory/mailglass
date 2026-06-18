defmodule Mailglass.DemoDataTest do
  use ExUnit.Case, async: false

  # Shells out to reference/demo_app (needs its deps fetched), unavailable in the
  # isolated-core Core Full Suite Advisory lane. Excluded there via
  # `--exclude requires_workspace`; demo fixtures are covered in CI by the
  # Demo Browser Evidence lane.
  @moduletag :requires_workspace

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

    demo_tests =
      @demo_app
      |> Path.join("test/mailglass_demo/*.exs")
      |> Path.wildcard()
      |> Enum.map(&Path.relative_to(&1, @demo_app))
      |> Enum.sort()

    {test_output, test_exit} =
      System.cmd("mix", ["test" | demo_tests] ++ ["--warnings-as-errors"],
        cd: @demo_app,
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    assert test_exit == 0,
           "reference demo app fixture tests failed:\n#{test_output}"
  end
end
