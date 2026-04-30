defmodule Mailglass.Publish.InstallerGoldenCheckTest do
  use ExUnit.Case, async: true

  alias Mailglass.Publish.InstallerGoldenCheck
  alias Mailglass.PublishError

  test "returns :ok on zero status" do
    runner = fn "mix", ["test", "test/mailglass/install" | _], opts ->
      assert opts[:cd] == "/tmp/repo"
      assert opts[:env] == [{"MIX_ENV", "test"}]
      assert opts[:stderr_to_stdout] == true
      {"", 0}
    end

    assert :ok = InstallerGoldenCheck.run("/tmp/repo", runner)
  end

  test "returns PublishError with exact remediation command on non-zero status" do
    runner = fn "mix", _, _opts ->
      {"snapshot mismatch", 2}
    end

    assert {:error, %PublishError{type: :publish_blocked_golden_drift} = error} =
             InstallerGoldenCheck.run("/tmp/repo", runner)

    message = Exception.message(error)
    assert message =~ "MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors"
    assert message =~ "snapshot mismatch"
  end
end
