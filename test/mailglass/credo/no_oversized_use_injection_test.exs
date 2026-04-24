defmodule Mailglass.Credo.NoOversizedUseInjectionTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoOversizedUseInjection

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags Mailglass __using__/1 macros that exceed the injection budget" do
    source = """
    defmodule Mailglass.BigMacro do
      defmacro __using__(_opts) do
        quote do
          @behaviour Mailglass.Mailable
          import Swoosh.Email
          def f1, do: :ok
          def f2, do: :ok
          def f3, do: :ok
          def f4, do: :ok
          def f5, do: :ok
          def f6, do: :ok
          def f7, do: :ok
          def f8, do: :ok
          def f9, do: :ok
          def f10, do: :ok
          def f11, do: :ok
          def f12, do: :ok
          def f13, do: :ok
          def f14, do: :ok
          def f15, do: :ok
          def f16, do: :ok
          def f17, do: :ok
          def f18, do: :ok
          def f19, do: :ok
          def f20, do: :ok
        end
      end
    end
    """

    issues = run_check(source)

    assert length(issues) == 1
    assert String.contains?(hd(issues).message, "exceeding max 20")
  end

  test "does not flag oversized non-Mailglass modules" do
    source = """
    defmodule MyApp.BigMacro do
      defmacro __using__(_opts) do
        quote do
          @behaviour Mailglass.Mailable
          import Swoosh.Email
          def f1, do: :ok
          def f2, do: :ok
          def f3, do: :ok
          def f4, do: :ok
          def f5, do: :ok
          def f6, do: :ok
          def f7, do: :ok
          def f8, do: :ok
          def f9, do: :ok
          def f10, do: :ok
          def f11, do: :ok
          def f12, do: :ok
          def f13, do: :ok
          def f14, do: :ok
          def f15, do: :ok
          def f16, do: :ok
          def f17, do: :ok
          def f18, do: :ok
          def f19, do: :ok
          def f20, do: :ok
        end
      end
    end
    """

    assert run_check(source) == []
  end

  test "counts returned quote body without macro expansion tricks" do
    source = """
    defmodule Mailglass.SpliceMacro do
      defmacro __using__(_opts) do
        defs =
          for n <- 1..40 do
            quote do
              def unquote(:"f\#{n}")(), do: :ok
            end
          end

        quote do
          unquote_splicing(defs)
        end
      end
    end
    """

    assert run_check(source) == []
  end

  defp run_check(source) do
    source
    |> SourceFile.parse("lib/mailglass/credo/no_oversized_use_injection_fixture.ex")
    |> NoOversizedUseInjection.run([])
  end
end
