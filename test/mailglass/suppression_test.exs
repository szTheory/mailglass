defmodule Mailglass.SuppressionTest do
  use ExUnit.Case, async: false

  alias Mailglass.{Suppression, SuppressedError, Message}
  alias Mailglass.SuppressionStore.ETS

  setup do
    prev_store = Application.get_env(:mailglass, :suppression_store)

    Application.put_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.ETS)

    on_exit(fn ->
      if prev_store do
        Application.put_env(:mailglass, :suppression_store, prev_store)
      else
        Application.delete_env(:mailglass, :suppression_store)
      end
    end)

    ETS.reset()
    :ok
  end

  defp build_message(attrs \\ []) do
    to_addr = Keyword.get(attrs, :to, "recipient@example.com")
    stream = Keyword.get(attrs, :stream, :transactional)
    tenant_id = Keyword.get(attrs, :tenant_id, "tenant-test")

    %Message{
      tenant_id: tenant_id,
      stream: stream,
      swoosh_email: Swoosh.Email.new(to: to_addr)
    }
  end

  describe "check_before_send/1 — clean address" do
    test "Test 7: returns :ok when address is not suppressed" do
      msg = build_message(to: "clean@example.com")
      assert :ok = Suppression.check_before_send(msg)
    end
  end

  describe "check_before_send/1 — suppressed address" do
    test "Test 7 (suppressed): returns {:error, %SuppressedError{type: scope}} when suppressed" do
      {:ok, _} =
        ETS.record(
          %{tenant_id: "tenant-test", address: "blocked@example.com", scope: :address, reason: :manual, source: "test"},
          []
        )

      msg = build_message(to: "blocked@example.com")
      result = Suppression.check_before_send(msg)
      assert {:error, %SuppressedError{type: :address}} = result
    end
  end

  describe "check_before_send/1 — store dispatch via config" do
    test "Test 8: reads :suppression_store from config (ETS in test, Ecto in prod)" do
      # The setup already sets the store to ETS; verify it dispatches correctly
      msg = build_message(to: "dispatch@example.com")
      assert :ok = Suppression.check_before_send(msg)

      # Record in ETS and verify the dispatch reads it
      {:ok, _} =
        ETS.record(
          %{tenant_id: "tenant-test", address: "dispatch@example.com", scope: :address, reason: :manual, source: "test"},
          []
        )

      result = Suppression.check_before_send(msg)
      assert {:error, %SuppressedError{}} = result
    end
  end

  describe "check_before_send/1 — telemetry" do
    test "Test 9: emits [:mailglass, :outbound, :suppression, :stop] with :hit and :tenant_id" do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:mailglass, :outbound, :suppression, :stop]
        ])

      msg = build_message(to: "telemetry@example.com")
      Suppression.check_before_send(msg)

      assert_receive {[:mailglass, :outbound, :suppression, :stop], ^ref, %{duration_us: _}, meta}
      assert Map.has_key?(meta, :hit)
      assert Map.has_key?(meta, :tenant_id)
      # No PII
      refute Map.has_key?(meta, :to)
      refute Map.has_key?(meta, :recipient)
      refute Map.has_key?(meta, :email)
      refute Map.has_key?(meta, :address)

      :telemetry.detach(ref)
    end
  end

  describe "check_before_send/1 — PII refutation (T-3-03-02, Test 10)" do
    test "SuppressedError context contains only :tenant_id and :stream — no PII keys" do
      {:ok, _} =
        ETS.record(
          %{
            tenant_id: "tenant-pii",
            address: "pii@example.com",
            scope: :address,
            reason: :manual,
            source: "test"
          },
          []
        )

      msg = build_message(to: "pii@example.com", tenant_id: "tenant-pii", stream: :operational)
      result = Suppression.check_before_send(msg)
      assert {:error, %SuppressedError{context: ctx}} = result

      # Context must only contain :tenant_id and :stream
      assert Map.has_key?(ctx, :tenant_id)
      assert Map.has_key?(ctx, :stream)

      # Must NOT contain PII
      refute Map.has_key?(ctx, :to)
      refute Map.has_key?(ctx, :from)
      refute Map.has_key?(ctx, :email)
      refute Map.has_key?(ctx, :recipient)
      refute Map.has_key?(ctx, :address)
    end
  end
end
