defmodule Mailglass.ReferenceHost.CompileSmokeTest do
  use ExUnit.Case, async: false

  @host_app Path.expand("../../reference/host_app", __DIR__)

  test "reference host compiles with warnings-as-errors" do
    {output, exit_code} =
      System.cmd("mix", ["compile", "--warnings-as-errors"],
        cd: @host_app,
        env: [{"MIX_ENV", "dev"}],
        stderr_to_stdout: true
      )

    assert exit_code == 0,
           "reference host compile smoke failed:\n#{output}"
  end
end
