defmodule Mailglass.TemplateEngine.HEExTest do
  use ExUnit.Case, async: true

  import Phoenix.Component, only: [sigil_H: 2]

  alias Mailglass.TemplateEngine.HEEx
  alias Mailglass.TemplateError

  setup do
    Mailglass.Config.validate_at_boot!()
    :ok
  end

  describe "compile/2" do
    test "returns {:ok, :heex_native} for any source (HEEx is compile-time)" do
      assert {:ok, :heex_native} = HEEx.compile("any source", [])
    end
  end

  describe "render/3 with function component" do
    test "renders a simple function component to HTML iodata" do
      component = fn assigns ->
        ~H|<p>Hello {@name}</p>|
      end

      assert {:ok, iodata} = HEEx.render(component, %{name: "World"}, [])

      html = IO.iodata_to_binary(iodata)
      assert String.contains?(html, "Hello World")
    end

    test "returns {:error, %TemplateError{type: :missing_assign}} for missing key" do
      component = fn assigns ->
        # Force a KeyError on a genuinely missing assign.
        _ = Map.fetch!(assigns, :missing_key)
        ~H|<p>unreachable</p>|
      end

      assert {:error, err} = HEEx.render(component, %{}, [])
      assert err.__struct__ == TemplateError
      assert err.type == :missing_assign
    end

    test "returns {:error, %TemplateError{type: :heex_compile}} for runtime crashes" do
      component = fn _assigns -> raise "unexpected crash" end

      assert {:error, err} = HEEx.render(component, %{}, [])
      assert err.__struct__ == TemplateError
      assert err.type == :heex_compile
    end

    test "returns {:error, %TemplateError{type: :heex_compile}} for non-function compiled form" do
      assert {:error, err} = HEEx.render(:not_a_function, %{}, [])

      assert err.__struct__ == TemplateError
      assert err.type == :heex_compile
    end
  end
end
