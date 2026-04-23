defmodule Mailglass.TelemetryPhase03Test do
  use ExUnit.Case, async: true

  alias Mailglass.Telemetry

  @moduletag :phase_03_uat

  setup do
    # Detach any handlers we attach so tests don't leak
    on_exit(fn ->
      :telemetry.detach("test-send-span")
      :telemetry.detach("test-dispatch-span")
      :telemetry.detach("test-persist-span")
    end)

    :ok
  end

  describe "send_span/2" do
    test "emits [:mailglass, :outbound, :send, :start] and [:stop] with meta attached" do
      test_pid = self()

      :telemetry.attach_many(
        "test-send-span",
        [
          [:mailglass, :outbound, :send, :start],
          [:mailglass, :outbound, :send, :stop]
        ],
        fn event, measurements, metadata, _config ->
          send(test_pid, {:telemetry_event, event, measurements, metadata})
        end,
        []
      )

      meta = %{tenant_id: "acme", mailable: MyMailer, delivery_id: "d1"}
      result = Telemetry.send_span(meta, fn -> :ok end)

      assert result == :ok
      assert_received {:telemetry_event, [:mailglass, :outbound, :send, :start], _, received_meta}
      assert received_meta.tenant_id == "acme"

      assert_received {:telemetry_event, [:mailglass, :outbound, :send, :stop], _, _}
    end
  end

  describe "dispatch_span/2" do
    test "emits [:mailglass, :outbound, :dispatch, :start] and [:stop]" do
      test_pid = self()

      :telemetry.attach_many(
        "test-dispatch-span",
        [
          [:mailglass, :outbound, :dispatch, :start],
          [:mailglass, :outbound, :dispatch, :stop]
        ],
        fn event, _measurements, _metadata, _config ->
          send(test_pid, {:telemetry_event, event})
        end,
        []
      )

      Telemetry.dispatch_span(%{tenant_id: "acme"}, fn -> :dispatched end)

      assert_received {:telemetry_event, [:mailglass, :outbound, :dispatch, :start]}
      assert_received {:telemetry_event, [:mailglass, :outbound, :dispatch, :stop]}
    end
  end

  describe "persist_outbound_multi_span/2" do
    test "emits [:mailglass, :persist, :outbound, :multi, :start] and [:stop]" do
      test_pid = self()

      :telemetry.attach_many(
        "test-persist-span",
        [
          [:mailglass, :persist, :outbound, :multi, :start],
          [:mailglass, :persist, :outbound, :multi, :stop]
        ],
        fn event, _measurements, _metadata, _config ->
          send(test_pid, {:telemetry_event, event})
        end,
        []
      )

      Telemetry.persist_outbound_multi_span(%{step_name: :persist_queued}, fn -> :persisted end)

      assert_received {:telemetry_event, [:mailglass, :persist, :outbound, :multi, :start]}
      assert_received {:telemetry_event, [:mailglass, :persist, :outbound, :multi, :stop]}
    end
  end
end
