defmodule Mailglass.ConfigTest do
  use ExUnit.Case, async: true

  # CORE-02: Mailglass.Config is the sole caller of Application.compile_env*.
  # It validates the :mailglass Application env against a NimbleOptions schema
  # at boot and caches the brand theme keyword list in :persistent_term for
  # O(1) read access during rendering (D-19).

  describe "new!/1" do
    test "accepts empty opts and uses all defaults" do
      assert config = Mailglass.Config.new!([])
      assert Keyword.get(config, :adapter) == {Mailglass.Adapters.Fake, []}
    end

    test "accepts valid opts unchanged and fills defaults" do
      config = Mailglass.Config.new!(renderer: [css_inliner: :none, plaintext: false])
      renderer = Keyword.fetch!(config, :renderer)
      assert Keyword.fetch!(renderer, :css_inliner) == :none
      assert Keyword.fetch!(renderer, :plaintext) == false
    end

    test "invalid key raises NimbleOptions.ValidationError" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Mailglass.Config.new!(unknown_garbage_key: "value")
      end
    end

    test "invalid type raises NimbleOptions.ValidationError" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Mailglass.Config.new!(renderer: [css_inliner: :invalid_backend])
      end
    end
  end

  describe "validate_at_boot!/0" do
    test "returns :ok with valid Application env" do
      assert :ok = Mailglass.Config.validate_at_boot!()
    end

    test "caches theme in :persistent_term after validation" do
      :ok = Mailglass.Config.validate_at_boot!()
      theme = Mailglass.Config.get_theme()
      assert is_list(theme)
      # Theme keys are :colors and :fonts per D-19; both maps.
      assert %{} = Keyword.fetch!(theme, :colors)
      assert %{} = Keyword.fetch!(theme, :fonts)
    end
  end

  describe "get_theme/0" do
    test "returns the cached theme list after validate_at_boot!/0" do
      :ok = Mailglass.Config.validate_at_boot!()
      theme = Mailglass.Config.get_theme()
      assert Keyword.keyword?(theme)
    end
  end
end
