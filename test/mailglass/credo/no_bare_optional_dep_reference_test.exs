defmodule Mailglass.Credo.NoBareOptionalDepReferenceTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoBareOptionalDepReference

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags direct optional dependency call outside gateway module" do
    source = """
    defmodule Mailglass.Outbound.BadCall do
      def run(job) do
        Oban.insert(job)
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Mailglass.OptionalDeps.Oban")
  end

  test "does not flag calls inside the configured gateway module" do
    source = """
    defmodule Mailglass.OptionalDeps.Oban do
      def run(job) do
        Oban.insert(job)
      end
    end
    """

    assert run_check(source) == []
  end

  test "does not flag non-gated module calls" do
    source = """
    defmodule Mailglass.Outbound.GoodCall do
      def run(job) do
        Phoenix.PubSub.broadcast(job, "mailglass:events", :ok)
      end
    end
    """

    assert run_check(source) == []
  end

  defp run_check(source) do
    source
    |> SourceFile.parse("test/mailglass/credo/no_bare_optional_dep_reference_fixture.ex")
    |> NoBareOptionalDepReference.run([])
  end
end
