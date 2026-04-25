defmodule Mailglass.Credo.NoDirectDateTimeNowTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoDirectDateTimeNow

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags DateTime.utc_now/0 call outside Mailglass.Clock namespace" do
    source = """
    defmodule Mailglass.Outbound.BadClockUse do
      def run do
        DateTime.utc_now()
      end
    end
    """

    issues = run_check(source, "lib/mailglass/outbound/no_direct_date_time_now_bad.ex")

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Mailglass.Clock.utc_now/0")
  end

  test "flags captured DateTime.utc_now/0 function outside Mailglass.Clock namespace" do
    source = """
    defmodule Mailglass.Outbound.BadClockCapture do
      def run do
        Enum.map([1], fn _ -> (&DateTime.utc_now/0).() end)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/outbound/no_direct_date_time_now_capture_bad.ex")

    refute Enum.empty?(issues)
  end

  test "does not flag DateTime.utc_now/0 inside Mailglass.Clock namespace" do
    source = """
    defmodule Mailglass.Clock.Frozen do
      def run do
        DateTime.utc_now()
      end
    end
    """

    assert run_check(source, "lib/mailglass/clock/no_direct_date_time_now_good.ex") == []
  end

  test "ignores files outside lib/mailglass path scope" do
    source = """
    defmodule Mailglass.Support.BadClockUse do
      def run do
        DateTime.utc_now()
      end
    end
    """

    assert run_check(source, "test/support/no_direct_date_time_now_fixture.ex") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoDirectDateTimeNow.run([])
  end
end
