defmodule Mailglass.Credo.NoDefaultModuleNameSingletonTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoDefaultModuleNameSingleton

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "flags default singleton names for start_link calls" do
    source = """
    defmodule Mailglass.Runtime.BadSingleton do
      def one, do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
      def two, do: Agent.start_link(fn -> %{} end, [name: __MODULE__])
      def three, do: Registry.start_link(keys: :unique, name: __MODULE__)
    end
    """

    issues = run_check(source, "lib/mailglass/runtime/bad_singleton.ex")

    assert length(issues) == 3
    assert Enum.all?(issues, &String.contains?(&1.message, ":name"))
  end

  test "does not flag explicit non-module names or dynamic opts" do
    source = """
    defmodule Mailglass.Runtime.GoodSingleton do
      def run(name, opts) do
        GenServer.start_link(__MODULE__, %{}, name: name)
        Agent.start_link(fn -> %{} end, opts)
      end
    end
    """

    assert run_check(source, "lib/mailglass/runtime/good_singleton.ex") == []
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoDefaultModuleNameSingleton.run([])
  end
end
