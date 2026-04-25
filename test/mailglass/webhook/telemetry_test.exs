defmodule Mailglass.Webhook.TelemetryTest do
  use ExUnit.Case, async: true

  alias Mailglass.Webhook.Telemetry, as: WebhookTelemetry

  # D-23 forbidden keys — asserted absent in EVERY describe block's metadata
  # (T-04-07 mitigation: centralized whitelist enforcement).
  @forbidden_keys [
    :ip,
    :remote_ip,
    :user_agent,
    :to,
    :from,
    :subject,
    :body,
    :html_body,
    :headers,
    :recipient,
    :email,
    :raw_payload,
    :raw_body
  ]

  setup do
    handler_id = "mailglass-webhook-telemetry-test-#{System.unique_integer([:positive])}"
    {:ok, handler_id: handler_id}
  end

  describe "ingest_span/2" do
    test "emits :start and :stop events with whitelist-conformant metadata", %{
      handler_id: handler_id
    } do
      test_pid = self()

      :telemetry.attach_many(
        handler_id,
        [
          [:mailglass, :webhook, :ingest, :start],
          [:mailglass, :webhook, :ingest, :stop]
        ],
        fn event, measurements, metadata, _ ->
          send(test_pid, {:tel, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      meta = %{
        provider: :postmark,
        tenant_id: "t1",
        status: :ok,
        event_count: 1,
        duplicate: false
      }

      result = WebhookTelemetry.ingest_span(meta, fn -> :the_result end)
      assert result == :the_result

      assert_receive {:tel, [:mailglass, :webhook, :ingest, :start], start_measurements, start_meta}

      assert_receive {:tel, [:mailglass, :webhook, :ingest, :stop], stop_measurements, stop_meta}

      assert is_integer(Map.fetch!(start_measurements, :monotonic_time))
      assert is_integer(Map.fetch!(stop_measurements, :duration))

      # Input metadata is carried through on both :start and :stop events.
      Enum.each(meta, fn {key, value} ->
        assert Map.fetch!(start_meta, key) == value
        assert Map.fetch!(stop_meta, key) == value
      end)

      refute_pii(start_meta)
      refute_pii(stop_meta)
    end
  end

  describe "verify_span/2" do
    test "emits :start and :stop events with whitelist-conformant metadata", %{
      handler_id: handler_id
    } do
      test_pid = self()

      :telemetry.attach_many(
        handler_id,
        [
          [:mailglass, :webhook, :signature, :verify, :start],
          [:mailglass, :webhook, :signature, :verify, :stop]
        ],
        fn event, _measurements, metadata, _ ->
          send(test_pid, {:tel, event, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      meta = %{provider: :sendgrid, status: :ok, failure_reason: nil}

      :ok = WebhookTelemetry.verify_span(meta, fn -> :ok end)

      assert_receive {:tel, [:mailglass, :webhook, :signature, :verify, :start], start_meta}
      assert_receive {:tel, [:mailglass, :webhook, :signature, :verify, :stop], stop_meta}

      Enum.each(meta, fn {key, value} ->
        assert Map.fetch!(start_meta, key) == value
        assert Map.fetch!(stop_meta, key) == value
      end)

      refute_pii(start_meta)
      refute_pii(stop_meta)
    end
  end

  describe "normalize_emit/1" do
    test "fires single :stop event with provider, event_type, mapped", %{
      handler_id: handler_id
    } do
      test_pid = self()

      :telemetry.attach(
        handler_id,
        [:mailglass, :webhook, :normalize, :stop],
        fn event, measurements, metadata, _ ->
          send(test_pid, {:tel, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      meta = %{provider: :postmark, event_type: :delivered, mapped: true}

      assert :ok = WebhookTelemetry.normalize_emit(meta)

      assert_receive {:tel, [:mailglass, :webhook, :normalize, :stop], measurements, stop_meta}

      assert measurements == %{count: 1}
      assert stop_meta == meta

      refute_pii(stop_meta)
    end

    test "does NOT fire :start or :exception events (single-emit contract)", %{
      handler_id: handler_id
    } do
      test_pid = self()

      :telemetry.attach_many(
        handler_id,
        [
          [:mailglass, :webhook, :normalize, :start],
          [:mailglass, :webhook, :normalize, :exception]
        ],
        fn event, _, _, _ -> send(test_pid, {:unexpected, event}) end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      :ok = WebhookTelemetry.normalize_emit(%{provider: :postmark, event_type: :delivered})

      refute_receive {:unexpected, _}, 50
    end
  end

  describe "orphan_emit/1" do
    test "fires single :stop event with provider, event_type, tenant_id, age_seconds", %{
      handler_id: handler_id
    } do
      test_pid = self()

      :telemetry.attach(
        handler_id,
        [:mailglass, :webhook, :orphan, :stop],
        fn event, measurements, metadata, _ ->
          send(test_pid, {:tel, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      meta = %{
        provider: :sendgrid,
        event_type: :delivered,
        tenant_id: "t1",
        age_seconds: 30
      }

      assert :ok = WebhookTelemetry.orphan_emit(meta)

      assert_receive {:tel, [:mailglass, :webhook, :orphan, :stop], measurements, stop_meta}

      assert measurements == %{count: 1}
      assert stop_meta == meta

      refute_pii(stop_meta)
    end
  end

  describe "duplicate_emit/1" do
    test "fires single :stop event with provider, event_type", %{handler_id: handler_id} do
      test_pid = self()

      :telemetry.attach(
        handler_id,
        [:mailglass, :webhook, :duplicate, :stop],
        fn event, measurements, metadata, _ ->
          send(test_pid, {:tel, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      meta = %{provider: :postmark, event_type: :delivered}

      assert :ok = WebhookTelemetry.duplicate_emit(meta)

      assert_receive {:tel, [:mailglass, :webhook, :duplicate, :stop], measurements, stop_meta}

      assert measurements == %{count: 1}
      assert stop_meta == meta

      refute_pii(stop_meta)
    end
  end

  describe "reconcile_span/2" do
    test "emits :start and :stop events with reconcile metadata", %{handler_id: handler_id} do
      test_pid = self()

      :telemetry.attach_many(
        handler_id,
        [
          [:mailglass, :webhook, :reconcile, :start],
          [:mailglass, :webhook, :reconcile, :stop]
        ],
        fn event, _, metadata, _ -> send(test_pid, {:tel, event, metadata}) end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      meta = %{
        tenant_id: "t1",
        scanned_count: 5,
        linked_count: 3,
        remaining_orphan_count: 2,
        status: :ok
      }

      assert :ok = WebhookTelemetry.reconcile_span(meta, fn -> :ok end)

      assert_receive {:tel, [:mailglass, :webhook, :reconcile, :start], start_meta}
      assert_receive {:tel, [:mailglass, :webhook, :reconcile, :stop], stop_meta}

      Enum.each(meta, fn {key, value} ->
        assert Map.fetch!(start_meta, key) == value
        assert Map.fetch!(stop_meta, key) == value
      end)

      refute_pii(start_meta)
      refute_pii(stop_meta)
    end
  end

  describe "exception path" do
    test "ingest_span propagates raised exceptions and emits :exception event", %{
      handler_id: handler_id
    } do
      test_pid = self()

      :telemetry.attach(
        handler_id,
        [:mailglass, :webhook, :ingest, :exception],
        fn event, _, metadata, _ -> send(test_pid, {:tel_exception, event, metadata}) end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      meta = %{provider: :postmark, status: :pending}

      assert_raise RuntimeError, "boom", fn ->
        WebhookTelemetry.ingest_span(meta, fn -> raise "boom" end)
      end

      assert_receive {:tel_exception, [:mailglass, :webhook, :ingest, :exception], exception_meta}

      # Input metadata is merged with :telemetry.span's kind/reason/stacktrace.
      assert Map.fetch!(exception_meta, :provider) == :postmark
      assert Map.fetch!(exception_meta, :status) == :pending

      refute_pii(exception_meta)
    end

    test "verify_span propagates raised exceptions and emits :exception event", %{
      handler_id: handler_id
    } do
      test_pid = self()

      :telemetry.attach(
        handler_id,
        [:mailglass, :webhook, :signature, :verify, :exception],
        fn event, _, metadata, _ -> send(test_pid, {:tel_exception, event, metadata}) end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      meta = %{provider: :sendgrid, status: :pending}

      assert_raise RuntimeError, "verify boom", fn ->
        WebhookTelemetry.verify_span(meta, fn -> raise "verify boom" end)
      end

      assert_receive {:tel_exception, [:mailglass, :webhook, :signature, :verify, :exception],
                      exception_meta}

      assert Map.fetch!(exception_meta, :provider) == :sendgrid

      refute_pii(exception_meta)
    end

    test "reconcile_span propagates raised exceptions and emits :exception event", %{
      handler_id: handler_id
    } do
      test_pid = self()

      :telemetry.attach(
        handler_id,
        [:mailglass, :webhook, :reconcile, :exception],
        fn event, _, metadata, _ -> send(test_pid, {:tel_exception, event, metadata}) end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      meta = %{tenant_id: "t1", status: :pending}

      assert_raise RuntimeError, "reconcile boom", fn ->
        WebhookTelemetry.reconcile_span(meta, fn -> raise "reconcile boom" end)
      end

      assert_receive {:tel_exception, [:mailglass, :webhook, :reconcile, :exception],
                      exception_meta}

      assert Map.fetch!(exception_meta, :tenant_id) == "t1"

      refute_pii(exception_meta)
    end
  end

  # ---- Helper: assert no forbidden D-23 PII keys leak into metadata ----

  defp refute_pii(meta) when is_map(meta) do
    Enum.each(@forbidden_keys, fn key ->
      refute Map.has_key?(meta, key),
             "D-23 forbidden PII key #{inspect(key)} found in telemetry metadata: #{inspect(meta)}"
    end)
  end
end
