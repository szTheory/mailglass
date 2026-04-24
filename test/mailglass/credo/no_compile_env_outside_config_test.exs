defmodule Mailglass.Credo.NoCompileEnvOutsideConfigTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoCompileEnvOutsideConfig

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags compile_env calls outside Mailglass.Config" do
    source = """
    defmodule Mailglass.Outbound.BadCompileEnv do
      @value Application.compile_env(:mailglass, :adapter, :fallback)
    end
    """

    issues = run_check(source, "lib/mailglass/outbound/bad_compile_env.ex")

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Mailglass.Config")
  end

  test "allows compile_env calls in Mailglass.Config namespace" do
    source = """
    defmodule Mailglass.Config.Runtime do
      @value Application.compile_env!(:mailglass, :adapter)
    end
    """

    assert run_check(source, "lib/mailglass/config/runtime.ex") == []
  end

  test "ignores files outside lib/mailglass path scope" do
    source = """
    defmodule Mailglass.TestFixture.BadCompileEnv do
      @value Application.compile_env(:mailglass, :adapter, :fallback)
    end
    """

    assert run_check(source, "test/support/no_compile_env_outside_config_fixture.exs") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoCompileEnvOutsideConfig.run([])
  end
end
