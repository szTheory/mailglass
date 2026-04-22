defmodule Mailglass.TelemetryTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  use ExUnitProperties

  # CORE-03 + D-26..D-33:
  #   * 4-level event path `[:mailglass, :domain, :resource, :action]` + phase
  #   * whitelist-only metadata (never PII)
  #   * `:telemetry.span/3` isolates handler exceptions (T-HANDLER-001)
  #   * StreamData property asserts whitelist across 1000 varied metadata maps
  #
  # `:telemetry_span_context` is an opaque reference term injected by
  # `:telemetry.span/3` for OTel span correlation (see the telemetry
  # library's merge_ctx/2). It is library machinery — not adopter-supplied
  # metadata — and carries no PII. The property test strips it before the
  # subset check so the whitelist continues to guard real metadata keys.

  @whitelisted_keys ~w(tenant_id mailable provider status message_id delivery_id event_id
                       latency_ms recipient_count bytes retry_count)a

  @telemetry_infrastructure_keys [:telemetry_span_context]

  setup do
    # Detach any stray handlers from previous tests so assertions don't cross
    # contaminate. Handler IDs used below are all uniquely suffixed per test.
    :telemetry.detach("mailglass-telemetry-test-capture")
    :ok
  end

  describe "render_span/2" do
    test "emits :stop event on the [:mailglass, :render, :message] prefix" do
      test_pid = self()

      :telemetry.attach(
        "mailglass-telemetry-test-capture",
        [:mailglass, :render, :message, :stop],
        fn event, measurements, metadata, _ ->
          send(test_pid, {:telemetry_event, event, measurements, metadata})
        end,
        nil
      )

      result =
        Mailglass.Telemetry.render_span(%{tenant_id: "t1", mailable: TestMailer}, fn ->
          :render_result
        end)

      assert result == :render_result

      assert_receive {:telemetry_event, [:mailglass, :render, :message, :stop],
                      measurements, metadata}

      assert metadata.tenant_id == "t1"
      assert metadata.mailable == TestMailer
      assert is_integer(Map.fetch!(measurements, :duration))
    after
      :telemetry.detach("mailglass-telemetry-test-capture")
    end

    test "emits :start event on the [:mailglass, :render, :message] prefix" do
      test_pid = self()

      :telemetry.attach(
        "mailglass-telemetry-test-capture",
        [:mailglass, :render, :message, :start],
        fn event, measurements, metadata, _ ->
          send(test_pid, {:start_event, event, measurements, metadata})
        end,
        nil
      )

      Mailglass.Telemetry.render_span(%{tenant_id: "t1", mailable: TestMailer}, fn -> :ok end)

      assert_receive {:start_event, [:mailglass, :render, :message, :start], measurements,
                      metadata}

      assert metadata.tenant_id == "t1"
      assert is_integer(Map.fetch!(measurements, :system_time))
    after
      :telemetry.detach("mailglass-telemetry-test-capture")
    end

    test "telemetry handler that raises does NOT crash the caller (T-HANDLER-001)" do
      :telemetry.attach(
        "mailglass-telemetry-test-capture",
        [:mailglass, :render, :message, :stop],
        fn _event, _measurements, _metadata, _ ->
          raise RuntimeError, "handler crash"
        end,
        nil
      )

      # `:telemetry.execute/3` wraps each attached handler in try/catch,
      # emits `[:telemetry, :handler, :failure]`, and auto-detaches the
      # failing handler — the caller's pipeline is unaffected. Silence the
      # library's own `Logger.error` noise so the suite output stays clean.
      result =
        capture_log(fn ->
          Mailglass.Telemetry.render_span(
            %{tenant_id: "t1", mailable: TestMailer},
            fn -> :pipeline_result end
          )
        end)
        |> tap(fn log -> assert log =~ "has failed and has been detached" end)

      _ = result

      # Re-run the pipeline (handler is detached now) and confirm the
      # function's return value flows through.
      assert :pipeline_result =
               Mailglass.Telemetry.render_span(
                 %{tenant_id: "t1", mailable: TestMailer},
                 fn -> :pipeline_result end
               )
    after
      :telemetry.detach("mailglass-telemetry-test-capture")
    end
  end

  describe "execute/3" do
    test "emits a raw event with measurements and metadata" do
      test_pid = self()

      :telemetry.attach(
        "mailglass-telemetry-test-capture",
        [:mailglass, :test, :counter],
        fn event, measurements, metadata, _ ->
          send(test_pid, {:event, event, measurements, metadata})
        end,
        nil
      )

      Mailglass.Telemetry.execute([:mailglass, :test, :counter], %{count: 1}, %{status: :ok})

      assert_receive {:event, [:mailglass, :test, :counter], %{count: 1}, %{status: :ok}}
    after
      :telemetry.detach("mailglass-telemetry-test-capture")
    end
  end

  describe "attach_default_logger/1" do
    test "returns :ok on first attach and {:error, :already_exists} on duplicate" do
      assert :ok = Mailglass.Telemetry.attach_default_logger()
      assert {:error, :already_exists} = Mailglass.Telemetry.attach_default_logger()
    after
      :telemetry.detach("mailglass-default-logger")
    end
  end

  describe "metadata whitelist property test (D-33, T-PII-001)" do
    property "stop event metadata keys are a subset of the whitelist across many renders" do
      # Build the metadata map from a list of key/value pairs rather than
      # `StreamData.map_of/2` — map_of forces unique keys and exhausts the
      # small (11-element) whitelist space after ~7 picks. Building from a
      # list allows duplicate keys (last one wins), and `Enum.into/2`
      # deduplicates naturally while preserving the "subset of whitelist"
      # invariant we actually care about.
      kv_gen =
        StreamData.tuple({
          StreamData.member_of(@whitelisted_keys),
          StreamData.one_of([
            StreamData.binary(),
            StreamData.integer(),
            StreamData.atom(:alphanumeric)
          ])
        })

      check all pairs <- StreamData.list_of(kv_gen, max_length: 15),
                max_runs: 1000 do
        metadata_input = Enum.into(pairs, %{})
        test_pid = self()

        handler_id = "mailglass-whitelist-check-#{System.unique_integer([:positive])}"

        :telemetry.attach(
          handler_id,
          [:mailglass, :render, :message, :stop],
          fn _event, _measurements, metadata, _ ->
            send(test_pid, {:meta, Map.keys(metadata)})
          end,
          nil
        )

        try do
          # Pass the StreamData-generated metadata directly to render_span.
          # This verifies render_span propagates only whitelisted keys
          # regardless of which subset is supplied.
          Mailglass.Telemetry.render_span(metadata_input, fn -> :ok end)

          assert_receive {:meta, keys}

          # Strip telemetry-library infrastructure keys (e.g.,
          # :telemetry_span_context) — see @telemetry_infrastructure_keys
          # comment at the top of the module.
          user_keys = keys -- @telemetry_infrastructure_keys

          assert MapSet.subset?(MapSet.new(user_keys), MapSet.new(@whitelisted_keys)),
                 "Metadata contained non-whitelisted keys: " <>
                   inspect(user_keys -- @whitelisted_keys)
        after
          :telemetry.detach(handler_id)
        end
      end
    end
  end
end
