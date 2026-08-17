defmodule Mailglass.MigrationConcurrencySourceTest do
  use ExUnit.Case, async: true

  @v06_path Path.expand("../../lib/mailglass/migrations/postgres/v06.ex", __DIR__)

  test "V06 restores nontransactional connection settings when a concurrent step raises" do
    source = File.read!(@v06_path)

    assert source =~ "configure_timeouts(concurrent_indexes)"
    assert source =~ "try do"
    assert source =~ "after\n      # The concurrent path is intentionally outside a transaction"
    assert source =~ "reset_timeouts(concurrent_indexes)"
  end
end
