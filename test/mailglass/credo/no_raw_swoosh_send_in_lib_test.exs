defmodule Mailglass.Credo.NoRawSwooshSendInLibTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoRawSwooshSendInLib

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags Swoosh.Mailer deliver calls in lib/mailglass" do
    source = """
    defmodule Mailglass.Outbound.BadSend do
      def run(email) do
        Swoosh.Mailer.deliver(email)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/outbound/bad_send.ex")

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Mailglass.Outbound")
  end

  test "flags alias-based Swoosh.Mailer deliver calls in lib/mailglass" do
    source = """
    defmodule Mailglass.Outbound.BadAliasSend do
      alias Swoosh.Mailer

      def run(email) do
        Mailer.deliver(email)
      end
    end
    """

    issues = run_check(source, "lib/mailglass/outbound/bad_alias_send.ex")

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Swoosh.Mailer.deliver")
  end

  test "allows Swoosh bridge module" do
    source = """
    defmodule Mailglass.Adapters.Swoosh do
      def run(email) do
        Swoosh.Mailer.deliver_many(email)
      end
    end
    """

    assert run_check(source, "lib/mailglass/adapters/swoosh.ex") == []
  end

  test "ignores files outside lib/mailglass path scope" do
    source = """
    defmodule Mailglass.TestFixture.BadSend do
      def run(email) do
        Swoosh.Mailer.deliver!(email)
      end
    end
    """

    assert run_check(source, "test/support/no_raw_swoosh_send_in_lib_fixture.exs") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoRawSwooshSendInLib.run([])
  end
end
