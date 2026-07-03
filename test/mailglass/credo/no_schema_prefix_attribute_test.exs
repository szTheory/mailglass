defmodule Mailglass.Credo.NoSchemaPrefixAttributeTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoSchemaPrefixAttribute

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  # Assemble the forbidden attribute literal at runtime so no bare
  # `@schema_prefix "..."` assignment appears verbatim in this source file — the
  # check under test is AST-based, but keeping the literal out of source keeps
  # any future negative-grep gate from tripping on the test itself.
  @attr "@" <> "schema" <> "_prefix"

  test "flags a @schema-prefix attribute in a module under lib/mailglass/" do
    source = """
    defmodule Mailglass.Outbound.BadSchema do
      #{@attr} "mailglass"
    end
    """

    issues = run_check(source, "lib/mailglass/outbound/bad_schema.ex")

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, @attr)
  end

  test "allows a module with no @schema-prefix attribute" do
    source = """
    defmodule Mailglass.Outbound.Ok do
      @moduledoc false
      def schema, do: Mailglass.Config.schema()
    end
    """

    assert run_check(source, "lib/mailglass/outbound/ok.ex") == []
  end

  test "ignores a @schema-prefix attribute in a file outside lib/mailglass path scope" do
    source = """
    defmodule Mailglass.TestFixture.BadSchema do
      #{@attr} "mailglass"
    end
    """

    assert run_check(source, "test/support/no_schema_prefix_attribute_fixture.exs") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoSchemaPrefixAttribute.run([])
  end
end
