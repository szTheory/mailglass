defmodule Mailglass.Credo.NoPiiInTelemetryMetaTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoPiiInTelemetryMeta

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags blocked pii keys in telemetry execute metadata" do
    source = """
    defmodule Demo do
      def run do
        :telemetry.execute([:mailglass, :outbound, :send, :stop], %{latency_ms: 1}, %{to: "a@example.com", subject: "reset"})
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 2
    assert Enum.any?(issues, &String.contains?(&1.message, ":to"))
    assert Enum.any?(issues, &String.contains?(&1.message, ":subject"))
  end

  test "flags blocked pii keys in telemetry span metadata" do
    source = """
    defmodule Demo do
      def run do
        :telemetry.span([:mailglass, :outbound, :send], %{email: "a@example.com"}, fn -> {:ok, %{status: :ok}} end)
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, ":email")
  end

  test "flags blocked pii keys when telemetry metadata uses string keys" do
    source = """
    defmodule Demo do
      def run do
        :telemetry.execute([:mailglass, :outbound, :send, :stop], %{latency_ms: 1}, %{"email" => "a@example.com", "subject" => "reset"})
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 2
    assert Enum.any?(issues, &String.contains?(&1.message, "\"email\""))
    assert Enum.any?(issues, &String.contains?(&1.message, "\"subject\""))
  end

  test "does not flag non-pii metadata keys" do
    source = """
    defmodule Demo do
      def run do
        :telemetry.execute([:mailglass, :outbound, :send, :stop], %{latency_ms: 1}, %{tenant_id: "t-1", status: :ok})
      end
    end
    """

    assert run_check(source) == []
  end

  test "does not flag dynamic map construction" do
    source = """
    defmodule Demo do
      def run(meta) do
        metadata = Map.put(meta, :to, "a@example.com")
        :telemetry.execute([:mailglass, :outbound, :send, :stop], %{latency_ms: 1}, metadata)
      end
    end
    """

    assert run_check(source) == []
  end

  defp run_check(source) do
    source
    |> SourceFile.parse("test/mailglass/credo/no_pii_in_telemetry_meta_fixture.ex")
    |> NoPiiInTelemetryMeta.run([])
  end
end
