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

  test "flags bare CATEGORY-NN REQ-IDs in docstrings only" do
    source = """
    defmodule Mailglass.Outbound.ReqIdDoc do
      @moduledoc \"\"\"
      Rate-limiter facade (RATE-01).
      \"\"\"

      def run, do: :ok
    end
    """

    issues = run_check(source, "lib/mailglass/outbound/req_id_doc.ex")

    assert length(issues) == 1
    assert hd(issues).trigger == "RATE-01"
  end

  test "keeps CATEGORY-NN REQ-IDs allowed in source comments (maintainer traceability)" do
    source = """
    defmodule Mailglass.Outbound.ReqIdComment do
      # RATE-01: bucket refill is continuous, not windowed.
      def run, do: :ok
    end
    """

    assert run_check(source, "lib/mailglass/outbound/req_id_comment.ex") == []
  end

  test "does not flag real-world tokens (SHA-256, UTF-8) in docstrings" do
    source = """
    defmodule Mailglass.Outbound.RealTokens do
      @moduledoc \"\"\"
      Signs with SHA-256 over UTF-8 bytes.
      \"\"\"

      def run, do: :ok
    end
    """

    assert run_check(source, "lib/mailglass/outbound/real_tokens.ex") == []
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
