defmodule Mailglass.RuntimeTest do
  use ExUnit.Case, async: false

  alias Mailglass.ConfigError
  alias Mailglass.Runtime

  setup do
    prior = Application.fetch_env(:mailglass, :schema)

    on_exit(fn ->
      Runtime.reset_for_test!()

      case prior do
        {:ok, value} -> Application.put_env(:mailglass, :schema, value)
        :error -> Application.delete_env(:mailglass, :schema)
      end
    end)

    :ok
  end

  test "bootstraps the default schema into an opaque runtime value" do
    Application.delete_env(:mailglass, :schema)
    Runtime.reset_for_test!()

    assert %Runtime{} = Runtime.current()
    assert Runtime.schema() == "mailglass"
    assert :persistent_term.get({Mailglass.Config, :schema}) == "mailglass"
  end

  test "reloads an explicit schema override after an explicit reset" do
    Application.put_env(:mailglass, :schema, "analytics")
    Runtime.reset_for_test!()

    assert Runtime.schema() == "analytics"
    assert Mailglass.Config.schema() == "analytics"
  end

  test "rejects an invalid schema instead of serving a stale runtime value" do
    Application.put_env(:mailglass, :schema, "has-dash")
    Runtime.reset_for_test!()

    assert_raise ConfigError, fn ->
      Runtime.current()
    end
  end
end
