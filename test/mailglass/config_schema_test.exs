defmodule Mailglass.ConfigSchemaTest do
  # async: false — mutates the global :mailglass app env and :persistent_term.
  use ExUnit.Case, async: false

  alias Mailglass.Config
  alias Mailglass.ConfigError

  @schema_key {Mailglass.Config, :schema}

  setup do
    prior = Application.fetch_env(:mailglass, :schema)

    on_exit(fn ->
      :persistent_term.erase(@schema_key)

      case prior do
        {:ok, value} -> Application.put_env(:mailglass, :schema, value)
        :error -> Application.delete_env(:mailglass, :schema)
      end
    end)

    :ok
  end

  describe "schema/0 default + override" do
    test "returns \"mailglass\" when no app env is set" do
      Application.delete_env(:mailglass, :schema)
      :persistent_term.erase(@schema_key)

      assert Config.schema() == "mailglass"
    end

    test "self-heals from app env on a cold cache miss" do
      Application.put_env(:mailglass, :schema, "analytics")
      :persistent_term.erase(@schema_key)

      assert Config.schema() == "analytics"
    end

    test "accepts the \"public\" opt-out" do
      Application.put_env(:mailglass, :schema, "public")
      :persistent_term.erase(@schema_key)

      assert Config.schema() == "public"
    end

    test "caches the validated string in :persistent_term after a read" do
      Application.put_env(:mailglass, :schema, "analytics")
      :persistent_term.erase(@schema_key)

      assert Config.schema() == "analytics"
      assert :persistent_term.get(@schema_key, :__miss__) == "analytics"
    end
  end

  describe "validate_at_boot!/0 warms + validates :schema" do
    test "returns :ok and warms the cache with the validated string on a valid identifier" do
      Application.put_env(:mailglass, :schema, "analytics")
      :persistent_term.erase(@schema_key)

      assert Config.validate_at_boot!() == :ok
      assert :persistent_term.get(@schema_key, :__miss__) == "analytics"
    end

    test "raises %ConfigError{type: :invalid} on a malformed identifier" do
      Application.put_env(:mailglass, :schema, "has-dash")
      :persistent_term.erase(@schema_key)

      err =
        assert_raise ConfigError, fn ->
          Config.validate_at_boot!()
        end

      assert %ConfigError{type: :invalid} = err
    end
  end
end
