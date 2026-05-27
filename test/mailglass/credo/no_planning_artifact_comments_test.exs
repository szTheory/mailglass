defmodule Mailglass.Credo.NoPlanningArtifactCommentsTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoPlanningArtifactComments

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags planning artifact tokens in comments" do
    source = """
    defmodule Mailglass.Outbound.CommentArtifact do
      # D-20
      def run, do: :ok
    end
    """

    issues = run_check(source, "lib/mailglass/outbound/comment_artifact.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "D-20"
  end

  test "flags planning artifact tokens in moduledoc/docstring text" do
    source = """
    defmodule MailglassAdmin.DocArtifact do
      @moduledoc \"\"\"
      Phase 50.7 tightened this boundary.
      \"\"\"

      def run, do: :ok
    end
    """

    issues = run_check(source, "mailglass_admin/lib/mailglass_admin/doc_artifact.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "Phase 50.7"
  end

  test "ignores executable string literals outside comments and docstrings" do
    source = """
    defmodule MailglassInbound.LiteralString do
      def run do
        IO.puts("Phase 50")
      end
    end
    """

    assert run_check(source, "mailglass_inbound/lib/mailglass_inbound/literal_string.ex") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoPlanningArtifactComments.run([])
  end
end
