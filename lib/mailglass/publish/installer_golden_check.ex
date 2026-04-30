defmodule Mailglass.Publish.InstallerGoldenCheck do
  @moduledoc false

  @doc """
  Runs the installer golden check and returns `:ok` or a typed publish error.
  """
  def run(repo_root, runner \\ &System.cmd/3) do
    {output, status} =
      runner.(
        "mix",
        ["test", "test/mailglass/install", "--warnings-as-errors", "--exclude", "flaky"],
        cd: repo_root,
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    if status == 0 do
      :ok
    else
      {:error,
       Mailglass.PublishError.new(:publish_blocked_golden_drift,
         context: %{
           output: output,
           command:
             "MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors"
         }
       )}
    end
  end
end
