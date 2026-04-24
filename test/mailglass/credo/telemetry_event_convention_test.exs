defmodule Mailglass.Credo.TelemetryEventConventionTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.TelemetryEventConvention

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags telemetry event with wrong root segment" do
    source = """
    defmodule Demo do
      def run do
        :telemetry.execute([:my_app, :outbound, :send, :stop], %{latency_ms: 1}, %{})
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, ":mailglass")
  end

  test "flags telemetry event with too few segments" do
    source = """
    defmodule Demo do
      def run do
        :telemetry.execute([:mailglass, :outbound, :send], %{latency_ms: 1}, %{})
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 1
  end

  test "does not flag valid literal event names or dynamic event variables" do
    source = """
    defmodule Demo do
      def good do
        :telemetry.execute([:mailglass, :outbound, :send, :stop], %{latency_ms: 1}, %{})
      end

      def dynamic(event) do
        :telemetry.execute(event, %{latency_ms: 1}, %{})
      end
    end
    """

    assert run_check(source) == []
  end

  defp run_check(source) do
    source
    |> SourceFile.parse("test/mailglass/credo/telemetry_event_convention_fixture.ex")
    |> TelemetryEventConvention.run([])
  end
end
