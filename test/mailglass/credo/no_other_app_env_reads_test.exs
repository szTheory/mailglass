defmodule Mailglass.Credo.NoOtherAppEnvReadsTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoOtherAppEnvReads

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags Application env reads for non-mailglass apps" do
    source = """
    defmodule Mailglass.Outbound.BadEnvRead do
      def one, do: Application.get_env(:swoosh, :api_client)
      def two, do: Application.fetch_env!(:logger, :level)
    end
    """

    issues = run_check(source, "lib/mailglass/outbound/bad_env_read.ex")

    assert length(issues) == 2
    assert Enum.all?(issues, &String.contains?(&1.message, ":mailglass"))
  end

  test "allows :mailglass app reads and dynamic app reads" do
    source = """
    defmodule Mailglass.Outbound.GoodEnvRead do
      def one, do: Application.get_env(:mailglass, :adapter)
      def two(app), do: Application.get_env(app, :adapter)
    end
    """

    assert run_check(source, "lib/mailglass/outbound/good_env_read.ex") == []
  end

  test "ignores files outside lib/mailglass path scope" do
    source = """
    defmodule Mailglass.TestFixture.BadEnvRead do
      def run, do: Application.get_env(:logger, :level)
    end
    """

    assert run_check(source, "test/support/no_other_app_env_reads_fixture.exs") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoOtherAppEnvReads.run([])
  end
end
