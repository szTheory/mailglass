defmodule Mailglass.Install.CompileTest do
  # async: false — run_install!/2 uses File.cd!/2 (process-global cwd), matching
  # the other installer tests.
  use ExUnit.Case, async: false

  import Mailglass.Test.InstallerFixtureHelpers

  @moduletag timeout: 120_000

  # The sibling installer tests assert that snippets are inserted and that a
  # golden hash matches, but never compile the generated output — which is how
  # the endpoint anchor-split and the escaped `<%%=` HEEx layout both shipped.
  # These tests parse every generated `.ex`/`.exs` and compile every `.heex` so
  # any codegen that produces uncompilable Elixir/HEEx fails before merge.

  test "every generated/edited artifact from a default install parses/compiles" do
    fixture_root = new_fixture_root!("compile-default")
    run_install!(fixture_root, [])
    assert_generated_artifacts_compile!(fixture_root)
  end

  test "every generated/edited artifact from a --no-admin install parses/compiles" do
    fixture_root = new_fixture_root!("compile-no-admin")
    run_install!(fixture_root, ["--no-admin"])
    assert_generated_artifacts_compile!(fixture_root)
  end
end
