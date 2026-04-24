defmodule Mailglass.Credo.NoFullResponseInLogsTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoFullResponseInLogs

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags inspect(response) in Logger.error" do
    source = """
    defmodule Mailglass.Webhook.BadLog do
      require Logger

      def run(response) do
        Logger.error("provider error: \#{inspect(response)}")
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/bad_log.ex")

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Logger.error")
  end

  test "flags interpolation of payload-like vars at warning level" do
    source = """
    defmodule Mailglass.Webhook.PayloadLog do
      require Logger

      def run(payload) do
        Logger.warning("payload=\#{payload}")
      end
    end
    """

    issues = run_check(source, "lib/mailglass/webhook/payload_log.ex")

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Logger.warning")
  end

  test "does not flag debug-level logs or non-response variables" do
    source = """
    defmodule Mailglass.Webhook.SafeLog do
      require Logger

      def run(response, status) do
        Logger.debug("response=\#{inspect(response)}")
        Logger.error("status=\#{status}")
      end
    end
    """

    assert run_check(source, "lib/mailglass/webhook/safe_log.ex") == []
  end

  test "ignores files outside lib/mailglass path scope" do
    source = """
    defmodule Mailglass.TestFixture.BadLog do
      require Logger

      def run(response) do
        Logger.error("provider error: \#{inspect(response)}")
      end
    end
    """

    assert run_check(source, "test/support/no_full_response_in_logs_fixture.exs") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoFullResponseInLogs.run([])
  end
end
