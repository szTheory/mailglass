defmodule Mailglass.ConfigTest do
  use Mailglass.DataCase, async: false

  # CORE-02: Mailglass.Config is the sole caller of Application.compile_env*.
  # It validates the :mailglass Application env against a NimbleOptions schema
  # at boot and caches the brand theme keyword list in :persistent_term for
  # O(1) read access during rendering (D-19).

  describe "new!/1" do
    @tag phase_151_task: "t151_05_01"
    test "validates finite outbound payload retention defaults and overrides" do
      config = Mailglass.Config.new!()

      assert Keyword.fetch!(config, :outbound_payload_retention) ==
               [terminal_days: 14, uncertain_days: 30, legacy_days: 14, prune_batch_size: 500]

      assert Mailglass.Config.new!(
               outbound_payload_retention: [
                 terminal_days: 1,
                 uncertain_days: 2,
                 legacy_days: 3,
                 prune_batch_size: 4
               ]
             )

      for invalid <- [0, -1, :infinity, "14"] do
        assert_raise NimbleOptions.ValidationError, fn ->
          Mailglass.Config.new!(outbound_payload_retention: [terminal_days: invalid])
        end
      end

      assert_raise NimbleOptions.ValidationError, fn ->
        Mailglass.Config.new!(outbound_payload_retention: [unknown: 1])
      end
    end
    test "accepts empty opts and uses all defaults" do
      assert config = Mailglass.Config.new!([])
      assert Keyword.get(config, :adapter) == {Mailglass.Adapters.Fake, []}
      assert Keyword.get(config, :adapters) == []
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

    test "accepts a valid mailgun subtree" do
      config =
        Mailglass.Config.new!(
          mailgun: [
            enabled: true,
            signing_key: "mailgun-signing-key",
            timestamp_tolerance_seconds: 28_800,
            future_skew_seconds: 300,
            replay_cache_ttl_seconds: 28_800
          ]
        )

      mailgun = Keyword.fetch!(config, :mailgun)
      assert Keyword.fetch!(mailgun, :signing_key) == "mailgun-signing-key"
      assert Keyword.fetch!(mailgun, :future_skew_seconds) == 300
      assert Keyword.fetch!(mailgun, :replay_cache_ttl_seconds) == 28_800
    end

    test "normalizes named adapter registry entries" do
      config =
        Mailglass.Config.new!(
          adapters: [
            {"tenant-b", {Mailglass.Adapters.Fake, api_key: "secret"}},
            tenant_a: Mailglass.Adapters.Fake
          ]
        )

      assert Keyword.fetch!(config, :adapters) == [
               {"tenant-b", {Mailglass.Adapters.Fake, [api_key: "secret"]}},
               {:tenant_a, {Mailglass.Adapters.Fake, []}}
             ]
    end

    test "rejects invalid adapter refs in the named registry" do
      assert_raise NimbleOptions.ValidationError, ~r/adapter refs must be atoms or strings/, fn ->
        Mailglass.Config.new!(adapters: [{123, Mailglass.Adapters.Fake}])
      end
    end

    test "rejects malformed named adapter entries" do
      assert_raise NimbleOptions.ValidationError,
                   ~r/adapter entries must be a module or \{module, keyword_opts\}/,
                   fn ->
                     Mailglass.Config.new!(adapters: [tenant_a: {"not a module", []}])
                   end
    end

    test "rejects malformed default adapter entries" do
      assert_raise NimbleOptions.ValidationError,
                   ~r/adapter entries must be a module or \{module, keyword_opts\}/,
                   fn ->
                     Mailglass.Config.new!(adapter: {Mailglass.Adapters.Fake, [:not, :keyword]})
                   end
    end

    test "rejects unknown keys in the mailgun subtree" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Mailglass.Config.new!(mailgun: [unknown_key: true])
      end
    end

    test "rejects invalid mailgun signing_key types" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Mailglass.Config.new!(mailgun: [signing_key: 123])
      end
    end

    test "rejects invalid mailgun future skew types" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Mailglass.Config.new!(mailgun: [future_skew_seconds: "300"])
      end
    end

    test "rejects invalid mailgun replay cache ttl types" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Mailglass.Config.new!(mailgun: [replay_cache_ttl_seconds: "28_800"])
      end
    end

    test "rejects mailgun replay cache ttl shorter than timestamp tolerance" do
      assert_raise NimbleOptions.ValidationError,
                   ~r/replay_cache_ttl_seconds must be greater than or equal to :timestamp_tolerance_seconds/,
                   fn ->
                     Mailglass.Config.new!(
                       mailgun: [
                         timestamp_tolerance_seconds: 300,
                         replay_cache_ttl_seconds: 60
                       ]
                     )
                   end
    end

    test "accepts a valid ses subtree" do
      config =
        Mailglass.Config.new!(
          ses: [
            enabled: true,
            cert_cache_ttl_seconds: 86_400
          ]
        )

      ses = Keyword.fetch!(config, :ses)
      assert Keyword.fetch!(ses, :enabled) == true
      assert Keyword.fetch!(ses, :cert_cache_ttl_seconds) == 86_400
    end

    test "accepts a valid resend subtree" do
      config =
        Mailglass.Config.new!(
          resend: [
            enabled: true,
            secret: "whsec_123",
            timestamp_tolerance_seconds: 300
          ]
        )

      resend = Keyword.fetch!(config, :resend)
      assert Keyword.fetch!(resend, :enabled) == true
      assert Keyword.fetch!(resend, :secret) == "whsec_123"
      assert Keyword.fetch!(resend, :timestamp_tolerance_seconds) == 300
    end

    test "rejects unknown keys in the ses subtree" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Mailglass.Config.new!(ses: [unknown_key: true])
      end
    end

    test "rejects unknown keys in the resend subtree" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Mailglass.Config.new!(resend: [unknown_key: true])
      end
    end

    test "rejects invalid resend timestamp_tolerance_seconds type" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Mailglass.Config.new!(resend: [timestamp_tolerance_seconds: "300"])
      end
    end

    test "normalizes nil ses and resend subtrees to default values" do
      config = Mailglass.Config.new!(ses: nil, resend: nil)
      assert Keyword.fetch!(config, :ses)[:enabled] == true
      assert Keyword.fetch!(config, :resend)[:enabled] == true
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

  describe "production_readiness/0" do
    setup do
      prior_async_adapter = Application.get_env(:mailglass, :async_adapter)

      on_exit(fn ->
        if is_nil(prior_async_adapter) do
          Application.delete_env(:mailglass, :async_adapter)
        else
          Application.put_env(:mailglass, :async_adapter, prior_async_adapter)
        end
      end)

      :ok
    end

    @tag phase_150_task: "t150_04_01"
    test "rejects the explicit non-durable Task.Supervisor adapter without requiring Oban" do
      Application.put_env(:mailglass, :async_adapter, :task_supervisor)

      assert {:error,
              %Mailglass.ConfigError{
                type: :invalid,
                context: %{key: :async_adapter, reason_class: :non_durable_async_adapter}
              }} = Mailglass.Config.production_readiness()
    end

    @tag phase_150_task: "t150_04_01"
    test "maps an unavailable default Oban instance to a bounded readiness error" do
      Application.put_env(:mailglass, :async_adapter, :oban)

      assert {:error,
              %Mailglass.ConfigError{
                type: :invalid,
                context: %{key: :async_adapter, reason_class: :instance_unavailable}
              }} = Mailglass.Config.production_readiness()
    end

    @tag phase_150_task: "t150_04_01"
    test "accepts a running default Oban with the canonical outbound queue" do
      if Code.ensure_loaded?(Oban) do
        Application.put_env(:mailglass, :async_adapter, :oban)

        start_supervised!(
          {Oban, testing: :disabled, repo: Mailglass.TestRepo, queues: [mailglass_outbound: 10]}
        )

        assert :ok = Mailglass.Config.production_readiness()
      else
        :skip
      end
    end

    @tag phase_150_task: "t150_04_01"
    test "rejects an empty queue configuration" do
      if Code.ensure_loaded?(Oban) do
        Application.put_env(:mailglass, :async_adapter, :oban)
        start_supervised!({Oban, testing: :disabled, repo: Mailglass.TestRepo, queues: []})

        assert {:error,
                %Mailglass.ConfigError{
                  type: :invalid,
                  context: %{key: :async_adapter, reason_class: :canonical_queue_unavailable}
                }} = Mailglass.Config.production_readiness()
      else
        :skip
      end
    end

    @tag phase_150_task: "t150_04_01"
    test "rejects a wrong canonical queue configuration" do
      if Code.ensure_loaded?(Oban) do
        Application.put_env(:mailglass, :async_adapter, :oban)

        start_supervised!(
          {Oban, testing: :disabled, repo: Mailglass.TestRepo, queues: [other_queue: 10]}
        )

        assert {:error,
                %Mailglass.ConfigError{
                  type: :invalid,
                  context: %{key: :async_adapter, reason_class: :canonical_queue_unavailable}
                }} = Mailglass.Config.production_readiness()
      else
        :skip
      end
    end

    @tag phase_150_task: "t150_04_01"
    test "boot validation permits explicit Task.Supervisor without invoking production readiness" do
      Application.put_env(:mailglass, :async_adapter, :task_supervisor)

      assert :ok = Mailglass.Config.validate_at_boot!()
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
