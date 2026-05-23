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

  # WR-02 CHARTER: the real inbound emission shape is a `*_span/2` PUBLIC helper
  # (`(metadata, fun)`) that forwards to a PRIVATE `span([literal_prefix], ...)`
  # wrapper. The literal full event prefix lives at the `span([...], ...)` CALL
  # SITE inside each helper — NOT at the public `*_span` call site (which carries
  # no literal). So the convention is enforced at the `span/3` wrapper call site
  # (function named exactly `span`, first arg a literal atom list), validated
  # against the span threshold `min_segments - 1` (the runtime appends a 4th
  # segment). These cases mirror the real inbound module's structure.

  test "fires on an under-segmented literal at a span/3 wrapper call site" do
    # Mirrors `ingress_span/2` forwarding a 2-segment literal — one short.
    source = """
    defmodule Demo do
      def ingress_span(metadata, fun) do
        span([:mailglass_inbound, :ingress], metadata, fun)
      end

      defp span(event_prefix, metadata, fun) do
        :telemetry.span(event_prefix, metadata, fun)
      end
    end
    """

    assert length(run_check(source, @configured)) == 1
  end

  test "fires on a wrong-root literal at a span/3 wrapper call site" do
    source = """
    defmodule Demo do
      def persist_span(metadata, fun) do
        span([:my_app, :persist, :record], metadata, fun)
      end

      defp span(event_prefix, metadata, fun) do
        :telemetry.span(event_prefix, metadata, fun)
      end
    end
    """

    assert length(run_check(source, @configured)) == 1
  end

  test "passes a 3-segment :mailglass_inbound literal at a span/3 wrapper call site" do
    source = """
    defmodule Demo do
      def route_span(metadata, fun) do
        span([:mailglass_inbound, :route, :match], metadata, fun)
      end

      defp span(event_prefix, metadata, fun) do
        :telemetry.span(event_prefix, metadata, fun)
      end
    end
    """

    assert run_check(source, @configured) == []
  end

  test "does not flag a span/3 wrapper that forwards a variable prefix" do
    # The private wrapper itself forwards a VARIABLE `event_prefix` to
    # `:telemetry.span/3` — no literal, must NOT be flagged (false-positive
    # avoidance). The single `:telemetry.span(event_prefix, ...)` is a variable
    # prefix too, so the whole module is clean.
    source = """
    defmodule Demo do
      defp span(event_prefix, metadata, fun) do
        :telemetry.span(event_prefix, metadata, fun)
      end
    end
    """

    assert run_check(source, @configured) == []
  end

  test "validates a qualified Module.span([...]) wrapper call site" do
    # Outbound core uses `Mailglass.Telemetry.span([:mailglass, :render, :message], ...)`
    # — a remote/qualified call to a function named `span`. It must be validated too.
    source = """
    defmodule Demo do
      def run do
        Mailglass.Telemetry.span([:my_app, :render, :message], %{}, fn -> :ok end)
      end
    end
    """

    assert length(run_check(source, @configured)) == 1
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
