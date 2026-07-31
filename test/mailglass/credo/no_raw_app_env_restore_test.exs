defmodule Mailglass.Credo.NoRawAppEnvRestoreTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoRawAppEnvRestore

  # D-31 Class D: the prevention half of the recurrence guard for the
  # Application-env restore defect. `Application.put_all_env/1` MERGES, so it
  # can never remove a key a test ADDED — which is what made seven test modules
  # leak `config :mailglass, :compliance` (declared in no `config/*.exs`) into
  # every module that ran after them, and, on the runs where the key ordering
  # lined up, a tenancy resolver binding `as: :scoped` that then collided with
  # `Mailglass.Operator.SupportSummary`'s `as: :orphan`. CI run 30571989203
  # failed the mailglass gating leg on a DOCS-ONLY commit for exactly that
  # reason and was green two commits later with `lib/` byte-identical.
  #
  # The detection half is the seam's own mechanism test
  # (`sandbox_ownership_test.exs`, "the D-31 Class D mutation"), which
  # reinstates the merging idiom and proves it still leaks.

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  describe "positive cases" do
    test "flags a fully-qualified Application.put_all_env/1 call in a test file" do
      source = """
      defmodule Mailglass.SomeTest do
        def setup_env do
          prior = Application.get_all_env(:mailglass)
          on_exit(fn -> Application.put_all_env(mailglass: prior) end)
        end
      end
      """

      assert [issue] = run_check(source, "test/mailglass/some_test.exs")
      assert issue.trigger == "Application.put_all_env"
      assert issue.message =~ "MERGES"
      assert issue.message =~ "with_app_env!/2"
    end

    test "flags it in the mailglass_inbound test tree too, which has zero instances today" do
      source = """
      defmodule MailglassInbound.SomeTest do
        def setup_env do
          Application.put_all_env(mailglass_inbound: [])
        end
      end
      """

      assert [_issue] =
               run_check(source, "mailglass_inbound/test/mailglass_inbound/some_test.exs")
    end

    test "flags it inside test/support/, not only in *_test.exs files" do
      source = """
      defmodule Mailglass.SomeCase do
        def restore(prior) do
          Application.put_all_env(mailglass: prior)
        end
      end
      """

      assert [_issue] = run_check(source, "test/support/some_case.ex")
    end

    test "flags every occurrence, not just the first" do
      source = """
      defmodule Mailglass.SomeTest do
        def a(prior), do: Application.put_all_env(mailglass: prior)
        def b(prior), do: Application.put_all_env(mailglass: prior)
      end
      """

      assert length(run_check(source, "test/mailglass/some_test.exs")) == 2
    end
  end

  describe "negative cases — each names the specific false positive it rules out" do
    test "does not flag the sanctioned door, whose @doc must quote the banned idiom" do
      source = """
      defmodule Mailglass.TestSupport.SandboxOwnership do
        def explain(prior) do
          Application.put_all_env(mailglass: prior)
        end
      end
      """

      assert run_check(source, "test/support/sandbox_ownership.ex") == []
    end

    test "does not flag the seam's own mechanism test, which must reproduce the leak" do
      source = """
      defmodule Mailglass.TestSupport.SandboxOwnershipTest do
        def mutation(prior) do
          Application.put_all_env(mailglass: prior)
        end
      end
      """

      assert run_check(source, "test/mailglass/test_support/sandbox_ownership_test.exs") == []
    end

    test "does not lint lib/ — the check is about TEST restore hygiene" do
      source = """
      defmodule Mailglass.SomeLibModule do
        def configure(config), do: Application.put_all_env(config)
      end
      """

      assert run_check(source, "lib/mailglass/some_lib_module.ex") == []
    end

    test "does not flag Application.put_env/3, which CAN express a correct restore" do
      source = """
      defmodule Mailglass.SomeTest do
        def restore(prior), do: Application.put_env(:mailglass, :tracking, prior)
      end
      """

      assert run_check(source, "test/mailglass/some_test.exs") == []
    end

    test "does not flag Application.get_all_env/1 — reading a snapshot is fine" do
      source = """
      defmodule Mailglass.SomeTest do
        def capture, do: Application.get_all_env(:mailglass)
      end
      """

      assert run_check(source, "test/mailglass/some_test.exs") == []
    end

    # No bare-tail fallback, deliberately — the same decision (and the same
    # reasoning) as `Mailglass.Credo.NoRawSandboxOwnership`'s. A locally
    # defined helper that happens to be named `put_all_env/1` is not this bug,
    # and flagging it would teach maintainers to distrust the check.
    test "does not flag a local put_all_env/1 helper called without a module" do
      source = """
      defmodule Mailglass.SomeTest do
        def restore(prior), do: put_all_env(mailglass: prior)
        defp put_all_env(_), do: :ok
      end
      """

      assert run_check(source, "test/mailglass/some_test.exs") == []
    end
  end

  # Anti-vacuity floor, in the shape the sibling Credo check tests use: if an
  # AST-shape change ever made the traversal silently stop matching, every
  # positive case above would drop to zero issues one at a time. This pins a
  # floor across all of them at once, so a systemic regression is caught even
  # if a single test's own assertion were later weakened.
  test "the positive corpus produces at least one issue per fixture" do
    fixtures = [
      {"test/mailglass/a_test.exs", "Application.put_all_env(mailglass: prior)"},
      {"test/support/b_case.ex", "Application.put_all_env(mailglass: prior)"},
      {"mailglass_inbound/test/c_test.exs", "Application.put_all_env(mailglass_inbound: prior)"}
    ]

    total =
      Enum.reduce(fixtures, 0, fn {filename, call}, acc ->
        source = """
        defmodule Mailglass.SomeTest do
          def restore(prior), do: #{call}
        end
        """

        acc + length(run_check(source, filename))
      end)

    assert total >= length(fixtures)
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoRawAppEnvRestore.run([])
  end
end
