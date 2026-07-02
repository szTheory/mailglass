defmodule Mailglass.IdentifierTest do
  use ExUnit.Case, async: true

  alias Mailglass.ConfigError
  alias Mailglass.Identifier

  describe "validate!/2 — valid identifiers" do
    test "returns the string for a plain lowercase identifier" do
      assert Identifier.validate!("mailglass", :schema) == "mailglass"
    end

    test "accepts the \"public\" opt-out identifier" do
      assert Identifier.validate!("public", :schema) == "public"
    end

    test "accepts a leading underscore with digits" do
      assert Identifier.validate!("_lead_underscore1", :schema) == "_lead_underscore1"
    end

    test "accepts a 63-byte all-`a` identifier (NAMEDATALEN boundary)" do
      value = String.duplicate("a", 63)
      assert Identifier.validate!(value, :schema) == value
    end
  end

  describe "validate!/2 — regex rejection" do
    test "rejects a dash and carries key + regex reason" do
      err =
        assert_raise ConfigError, fn ->
          Identifier.validate!("has-dash", :schema)
        end

      assert %ConfigError{type: :invalid, context: context} = err
      assert context.key == :schema
      assert context.reason =~ "must match"
    end

    test "rejects a leading digit" do
      err =
        assert_raise ConfigError, fn ->
          Identifier.validate!("1leading_digit", :schema)
        end

      assert %ConfigError{type: :invalid} = err
    end
  end

  describe "validate!/2 — 63-byte NAMEDATALEN guard" do
    test "rejects a 64-byte all-`a` identifier and names the 63-byte limit" do
      value = String.duplicate("a", 64)

      err =
        assert_raise ConfigError, fn ->
          Identifier.validate!(value, :schema)
        end

      assert %ConfigError{type: :invalid, context: context} = err
      assert context.key == :schema
      assert context.reason =~ "63"
    end
  end

  describe "validate!/2 — non-binary rejection" do
    test "rejects a non-binary value and names the binary requirement" do
      err =
        assert_raise ConfigError, fn ->
          Identifier.validate!(:not_a_binary, :schema)
        end

      assert %ConfigError{type: :invalid, context: context} = err
      assert context.key == :schema
      assert context.reason =~ "must be a binary"
    end
  end
end
