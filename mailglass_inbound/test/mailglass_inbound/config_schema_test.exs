defmodule MailglassInbound.ConfigSchemaTest do
  # async: false — mutates the global :mailglass_inbound app env and :persistent_term.
  use ExUnit.Case, async: false

  alias Mailglass.ConfigError
  alias MailglassInbound.Config

  @schema_key {MailglassInbound.Config, :schema}

  setup do
    prior = Application.fetch_env(:mailglass_inbound, :schema)

    on_exit(fn ->
      :persistent_term.erase(@schema_key)

      case prior do
        {:ok, value} -> Application.put_env(:mailglass_inbound, :schema, value)
        :error -> Application.delete_env(:mailglass_inbound, :schema)
      end
    end)

    :ok
  end

  describe "schema/0 default + override" do
    test "returns \"mailglass\" when no app env is set" do
      Application.delete_env(:mailglass_inbound, :schema)
      :persistent_term.erase(@schema_key)

      assert Config.schema() == "mailglass"
    end

    test "self-heals from the :mailglass_inbound app env on a cold cache miss" do
      Application.put_env(:mailglass_inbound, :schema, "analytics")
      :persistent_term.erase(@schema_key)

      assert Config.schema() == "analytics"
    end

    test "reads from :mailglass_inbound env, never core :mailglass env" do
      # Boundary law: a core :mailglass schema must NOT leak into inbound.
      Application.delete_env(:mailglass_inbound, :schema)
      prior_core = Application.fetch_env(:mailglass, :schema)
      Application.put_env(:mailglass, :schema, "core_only")
      :persistent_term.erase(@schema_key)

      on_exit(fn ->
        case prior_core do
          {:ok, value} -> Application.put_env(:mailglass, :schema, value)
          :error -> Application.delete_env(:mailglass, :schema)
        end
      end)

      assert Config.schema() == "mailglass"
    end

    test "accepts the \"public\" opt-out" do
      Application.put_env(:mailglass_inbound, :schema, "public")
      :persistent_term.erase(@schema_key)

      assert Config.schema() == "public"
    end

    test "caches the validated string in :persistent_term after a read" do
      Application.put_env(:mailglass_inbound, :schema, "analytics")
      :persistent_term.erase(@schema_key)

      assert Config.schema() == "analytics"
      assert :persistent_term.get(@schema_key, :__miss__) == "analytics"
    end
  end

  describe "validate_at_boot!/0 warms + validates :schema" do
    test "returns :ok and warms the cache with the validated string on a valid identifier" do
      Application.put_env(:mailglass_inbound, :schema, "analytics")
      :persistent_term.erase(@schema_key)

      assert Config.validate_at_boot!() == :ok
      assert :persistent_term.get(@schema_key, :__miss__) == "analytics"
    end

    test "raises %ConfigError{type: :invalid} on a malformed identifier" do
      Application.put_env(:mailglass_inbound, :schema, "has-dash")
      :persistent_term.erase(@schema_key)

      err =
        assert_raise ConfigError, fn ->
          Config.validate_at_boot!()
        end

      assert %ConfigError{type: :invalid} = err
    end
  end

  describe "retention/0 and rate_limit/0 remain uncached (cold path)" do
    test "retention/0 works and is NOT cached in :persistent_term" do
      :persistent_term.erase({MailglassInbound.Config, :retention})

      assert is_list(Config.retention())
      assert :persistent_term.get({MailglassInbound.Config, :retention}, :__miss__) == :__miss__
    end

    test "rate_limit/0 works and is NOT cached in :persistent_term" do
      :persistent_term.erase({MailglassInbound.Config, :rate_limit})

      assert is_list(Config.rate_limit())
      assert :persistent_term.get({MailglassInbound.Config, :rate_limit}, :__miss__) == :__miss__
    end
  end
end
