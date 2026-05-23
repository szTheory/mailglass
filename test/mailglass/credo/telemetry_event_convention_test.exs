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

  test "generalizes to a span_with_enrichment/3 wrapper (webhook package shape)" do
    # The webhook package's wrapper is named `span_with_enrichment` (a `span`-
    # PREFIXED name), not `span`. It carries the full literal prefix too, so it
    # must be covered by the same wrapper clause. Wrong root -> one issue.
    source = """
    defmodule Demo do
      def ingest_span(metadata, fun) do
        span_with_enrichment([:my_app, :webhook, :ingest], metadata, fun)
      end

      defp span_with_enrichment(event_prefix, metadata, fun) do
        :telemetry.span(event_prefix, metadata, fun)
      end
    end
    """

    assert length(run_check(source, @configured)) == 1
  end

  test "does not flag a *_span helper carrying a partial suffix (outbound persist_span shape)" do
    # Outbound `persist_span([:delivery, :update_projections], ...)` passes a
    # partial SUFFIX (not a full prefix) that the wrapper prepends
    # `[:mailglass, :persist]` onto. A `*_span`-suffix match would false-positive
    # here; the `span`-PREFIX match correctly leaves it alone.
    source = """
    defmodule Demo do
      def run do
        persist_span([:delivery, :update_projections], %{}, fn -> :ok end)
      end

      def persist_span(suffix, metadata, fun) do
        span([:mailglass, :persist] ++ suffix, metadata, fun)
      end

      defp span(event_prefix, metadata, fun) do
        :telemetry.span(event_prefix, metadata, fun)
      end
    end
    """

    assert run_check(source, @configured) == []
  end

  # --- WR-02 real-inbound proof -------------------------------------------------
  #
  # The charter requires the check to demonstrably cover REAL inbound code, not
  # just isolated fixtures. We parse the live `mailglass_inbound` telemetry module
  # (the source of the four real literal event prefixes at its `span([...], ...)`
  # wrapper call sites) and assert:
  #   * unmodified source -> zero issues (the real prefixes are correct AND are
  #     now SEEN by the check at the span/3 wrapper call site); and
  #   * a mutated copy with one real literal list made wrong -> an issue (proving
  #     the coverage is real and not vacuous: correct -> clean, mutated -> flagged).

  @inbound_telemetry_path "mailglass_inbound/lib/mailglass_inbound/telemetry.ex"

  test "real mailglass_inbound telemetry.ex event names are validated by the span/3 wrapper clause" do
    source = File.read!(@inbound_telemetry_path)

    issues =
      source
      |> SourceFile.parse(@inbound_telemetry_path)
      |> TelemetryEventConvention.run(@configured)

    assert issues == [],
           "unmodified real inbound telemetry.ex should be clean, got: #{inspect(issues)}"

    # Mutate ONE real literal prefix to a wrong (non-mailglass) root. The real
    # source contains `[:mailglass_inbound, :ingress, :request]`; flip the root.
    assert String.contains?(source, "[:mailglass_inbound, :ingress, :request]"),
           "expected real inbound source to contain the ingress span literal — update the mutation if the source moved"

    mutated =
      String.replace(
        source,
        "[:mailglass_inbound, :ingress, :request]",
        "[:wrong_app, :ingress, :request]"
      )

    mutated_issues =
      mutated
      |> SourceFile.parse(@inbound_telemetry_path)
      |> TelemetryEventConvention.run(@configured)

    assert length(mutated_issues) == 1,
           "mutating a real inbound event prefix to a wrong root should be flagged, got: #{inspect(mutated_issues)}"
  end

  test "passes a full real-shaped inbound *_span/2 helper forwarding a correct literal" do
    # Full real shape: a `*_span/2` public helper forwarding to a private `span/3`
    # wrapper carrying the literal prefix. The literal is correct -> zero issues.
    source = """
    defmodule Demo do
      def execution_span(metadata, fun) do
        span([:mailglass_inbound, :execution, :run], metadata, fun)
      end

      defp span(event_prefix, metadata, fun) do
        :telemetry.span(event_prefix, metadata, fun)
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
