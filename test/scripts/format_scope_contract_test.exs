defmodule Mailglass.Scripts.FormatScopeContractTest do
  use ExUnit.Case, async: true

  @root_formatter Path.expand("../../.formatter.exs", __DIR__)
  @inbound_formatter Path.expand("../../mailglass_inbound/.formatter.exs", __DIR__)

  test "root formatter explicitly owns core and inbound source trees" do
    assert_formatter_scope!(File.read!(@root_formatter))
    assert_formatter_options_match!(File.read!(@root_formatter), File.read!(@inbound_formatter))
  end

  test "formatter scope contract rejects a missing inbound tree" do
    source = File.read!(@root_formatter)

    assert_raise ExUnit.AssertionError, fn ->
      assert_formatter_scope!(
        String.replace(source, "mailglass_inbound/{config,lib,test}", "removed/inbound")
      )
    end
  end

  defp assert_formatter_scope!(source) do
    assert source =~ "{config,lib,test}/**/*.{ex,exs}"
    assert source =~ "mailglass_inbound/{config,lib,test}/**/*.{ex,exs}"
  end

  defp assert_formatter_options_match!(root, inbound) do
    assert root =~ "line_length: 100"
    assert inbound =~ "line_length: 100"
  end
end
