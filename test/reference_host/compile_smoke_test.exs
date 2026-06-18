defmodule Mailglass.ReferenceHost.CompileSmokeTest do
  use ExUnit.Case, async: false

  # Requires the full repo workspace (reference/host_app with fetched deps +
  # sibling MailglassInbound compiled), unavailable in the isolated-core Core
  # Full Suite Advisory lane. Excluded there via `--exclude requires_workspace`;
  # reference-host behavior is covered in CI by the Trust Lane / Installer lanes.
  @moduletag :requires_workspace

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
