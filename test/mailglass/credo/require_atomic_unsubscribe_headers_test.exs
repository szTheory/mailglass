defmodule Mailglass.Credo.RequireAtomicUnsubscribeHeadersTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.RequireAtomicUnsubscribeHeaders

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags an unsubscribe-header write outside the sanctioned injector" do
    source = """
    defmodule Mailglass.Mailers.RogueUnsubscribe do
      def add_header(email, value) do
        put_header_if_absent("List-Unsubscribe", value)
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 1

    assert String.contains?(
             hd(issues).message,
             "Mailglass.Compliance.inject_unsubscribe_headers"
           )
  end

  test "does not flag the sanctioned injector when it writes both headers atomically" do
    source = """
    defmodule Mailglass.Compliance do
      def inject_unsubscribe_headers(email, opts) do
        email
        |> put_header_if_absent("List-Unsubscribe", opts[:unsubscribe_url])
        |> put_header_if_absent("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
      end
    end
    """

    assert run_check(source) == []
  end

  test "does not flag a write of an unrelated header" do
    source = """
    defmodule Mailglass.Mailers.CustomHeader do
      def add_header(email, value) do
        put_header("X-Custom", value)
      end
    end
    """

    assert run_check(source) == []
  end

  defp run_check(source) do
    source
    |> SourceFile.parse("test/mailglass/credo/require_atomic_unsubscribe_headers_fixture.ex")
    |> RequireAtomicUnsubscribeHeaders.run([])
  end
end
