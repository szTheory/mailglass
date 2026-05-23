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

  # WR-02 regression: inbound events are `:telemetry.span/3`, whose prefix is one
  # segment shorter than the emitted event (runtime appends :start/:stop/:exception),
  # so it is validated against `min_segments - 1`. These cases run with the CONFIGURED
  # params (matching real .credo.exs) — the check's DEFAULT root is the bare
  # `:mailglass` atom, so an inbound-rooted case run with defaults would fail for the
  # wrong reason. Passing the configured root proves the widened config — not the
  # default — is what makes an inbound prefix pass.
  @configured [required_root: [:mailglass, :mailglass_inbound], min_segments: 4]

  test "passes a 3-segment :mailglass_inbound span prefix (runtime appends a 4th)" do
    source = """
    defmodule Demo do
      def run do
        :telemetry.span([:mailglass_inbound, :ingress, :request], %{}, fn -> {:ok, %{}} end)
      end
    end
    """

    assert run_check(source, @configured) == []
  end

  test "flags a 2-segment :mailglass_inbound span prefix (one short of threshold)" do
    source = """
    defmodule Demo do
      def run do
        :telemetry.span([:mailglass_inbound, :ingress], %{}, fn -> {:ok, %{}} end)
      end
    end
    """

    assert length(run_check(source, @configured)) == 1
  end

  test "flags a non-mailglass span root even at the right length" do
    source = """
    defmodule Demo do
      def run do
        :telemetry.span([:my_app, :ingress, :request], %{}, fn -> {:ok, %{}} end)
      end
    end
    """

    assert length(run_check(source, @configured)) == 1
  end

  test "flags an under-segmented :telemetry.execute event under configured params" do
    source = """
    defmodule Demo do
      def run do
        :telemetry.execute([:mailglass, :a, :b], %{latency_ms: 1}, %{})
      end
    end
    """

    assert length(run_check(source, @configured)) == 1
  end

  test "passes a 4-segment :telemetry.execute event under configured params" do
    source = """
    defmodule Demo do
      def run do
        :telemetry.execute([:mailglass, :a, :b, :stop], %{latency_ms: 1}, %{})
      end
    end
    """

    assert run_check(source, @configured) == []
  end

  defp run_check(source) do
    source
    |> SourceFile.parse("test/mailglass/credo/telemetry_event_convention_fixture.ex")
    |> TelemetryEventConvention.run([])
  end

  defp run_check(source, params) do
    source
    |> SourceFile.parse("test/mailglass/credo/telemetry_event_convention_fixture.ex")
    |> TelemetryEventConvention.run(params)
  end
end
