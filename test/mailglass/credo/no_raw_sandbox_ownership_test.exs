defmodule Mailglass.Credo.NoRawSandboxOwnershipTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoRawSandboxOwnership

  # HARNESS-01: the prevention half of the two-layer recurrence guard (see
  # `Mailglass.TestSupport.SuiteTruthFormatter` for the detection half).
  #
  # `mix credo --strict`'s reach over `test/**/*.exs` and `test/support/*.ex`
  # was demonstrated, not assumed, before this check was built on top of that
  # assumption — see the "Task 1" section of
  # `.planning/phases/143-test-harness-truth/143-08-SUMMARY.md` for the exact
  # scratch-file experiment and reported output.

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  @forbidden_functions ~w(mode start_owner! stop_owner checkout checkin)

  for function_name <- @forbidden_functions do
    test "flags a fully-qualified Ecto.Adapters.SQL.Sandbox.#{function_name} call" do
      function_name = unquote(function_name)

      source = """
      defmodule Mailglass.SomeTest do
        def run do
          Ecto.Adapters.SQL.Sandbox.#{function_name}(TestRepo)
        end
      end
      """

      issues = run_check(source, "test/mailglass/some_test.exs")

      assert length(issues) == 1,
             "expected exactly one issue for Ecto.Adapters.SQL.Sandbox.#{function_name}, got #{length(issues)}"

      assert String.contains?(hd(issues).message, "Sandbox.#{function_name}")
    end
  end

  # Anti-vacuity guard, in the `required_checks_test.exs:30-34` shape: if an
  # Elixir AST-shape change ever made the check's traversal silently stop
  # matching, every fully-qualified positive case above would drop to zero
  # issues one at a time — this pins a floor across ALL of them at once, named
  # to the check, so a systemic regression is caught even if a single test's
  # own assertion were ever weakened.
  test "the fully-qualified fixture corpus produces at least one issue per forbidden function" do
    total_issues =
      Enum.reduce(@forbidden_functions, 0, fn function_name, acc ->
        source = """
        defmodule Mailglass.SomeTest do
          def run do
            Ecto.Adapters.SQL.Sandbox.#{function_name}(TestRepo)
          end
        end
        """

        acc + length(run_check(source, "test/mailglass/some_test.exs"))
      end)

    assert total_issues == length(@forbidden_functions),
           "Mailglass.Credo.NoRawSandboxOwnership fired #{total_issues} issue(s) across " <>
             "#{length(@forbidden_functions)} forbidden-function fixtures — expected exactly one per fixture"
  end

  test "flags an aliased bare-tail Sandbox.mode call" do
    source = """
    defmodule Mailglass.SomeTest do
      alias Ecto.Adapters.SQL.Sandbox

      def run do
        Sandbox.mode(TestRepo, :manual)
      end
    end
    """

    issues = run_check(source, "test/mailglass/some_test.exs")

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Sandbox.mode")
  end

  test "flags an `as:`-renamed alias Sandbox call" do
    source = """
    defmodule Mailglass.SomeTest do
      alias Ecto.Adapters.SQL.Sandbox, as: PoolSandbox

      def run do
        PoolSandbox.mode(TestRepo, :manual)
      end
    end
    """

    issues = run_check(source, "test/mailglass/some_test.exs")

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "Sandbox.mode")
  end

  test "allows a call from inside Mailglass.TestSupport.SandboxOwnership" do
    source = """
    defmodule Mailglass.TestSupport.SandboxOwnership do
      def checkout! do
        Ecto.Adapters.SQL.Sandbox.start_owner!(TestRepo, [])
      end
    end
    """

    assert run_check(source, "test/support/sandbox_ownership.ex") == []
  end

  test "allows a call from inside Mailglass.TestSupport.SandboxOwnershipTest" do
    source = """
    defmodule Mailglass.TestSupport.SandboxOwnershipTest do
      use ExUnit.Case

      test "checks out a real owner" do
        Ecto.Adapters.SQL.Sandbox.start_owner!(TestRepo, [])
      end
    end
    """

    assert run_check(source, "test/mailglass/test_support/sandbox_ownership_test.exs") == []
  end

  test "ignores a call in a file whose path is outside test/" do
    source = """
    defmodule Mailglass.SomeLibModule do
      def run do
        Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
      end
    end
    """

    assert run_check(source, "lib/mailglass/some_lib_module.ex") == []
  end

  test "does not flag an unrelated module whose tail is Sandbox called without an Ecto alias" do
    source = """
    defmodule Mailglass.SomeTest do
      alias Mailglass.TestSupport.CitextProbe, as: Sandbox

      def run do
        Sandbox.mode(TestRepo, :manual)
      end
    end
    """

    assert run_check(source, "test/mailglass/some_test.exs") == []
  end

  test "does not flag Sandbox.allow/3, which is not forbidden" do
    source = """
    defmodule Mailglass.SomeTest do
      alias Ecto.Adapters.SQL.Sandbox

      def run do
        Sandbox.allow(TestRepo, self(), pid())
      end
    end
    """

    assert run_check(source, "test/mailglass/some_test.exs") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoRawSandboxOwnership.run([])
  end
end
