defmodule Mailglass.SuppressionTest do
  use Mailglass.DataCase, async: false

  alias Mailglass.{Message, Suppression, SuppressedError}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.AutoSuppress
  alias Mailglass.Suppression.Entry
  alias Mailglass.SuppressionStore.ETS
  alias Mailglass.TestRepo

  defmodule AutoSuppressRepoStub do
    def insert(changeset, _opts) do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end
  end

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

  defp build_message(attrs) do
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
      expires_at = DateTime.add(DateTime.utc_now(), 3_600, :second)

      {:ok, _} =
        ETS.record(
          %{
            tenant_id: "tenant-test",
            address: "blocked@example.com",
            scope: :address,
            reason: :manual,
            source: "test",
            expires_at: expires_at
          },
          []
        )

      msg = build_message(to: "blocked@example.com")
      result = Suppression.check_before_send(msg)

      assert {:error,
              %SuppressedError{
                type: :address,
                context: %{
                  tenant_id: "tenant-test",
                  stream: :transactional,
                  reason: :manual,
                  source: "test",
                  expires_at: ^expires_at
                }
              }} = result
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
          %{
            tenant_id: "tenant-test",
            address: "dispatch@example.com",
            scope: :address,
            reason: :manual,
            source: "test"
          },
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

    test "emits [:mailglass, :suppression, :pre_send_blocked, :stop] with whitelist-safe metadata" do
      {:ok, _} =
        ETS.record(
          %{
            tenant_id: "tenant-blocked",
            address: "blocked-telemetry@example.com",
            scope: :address,
            reason: :manual,
            source: "ops",
            expires_at: nil
          },
          []
        )

      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:mailglass, :suppression, :pre_send_blocked, :stop]
        ])

      msg =
        build_message(
          to: "blocked-telemetry@example.com",
          tenant_id: "tenant-blocked",
          stream: :operational
        )

      assert {:error, %SuppressedError{}} = Suppression.check_before_send(msg)

      assert_receive {[:mailglass, :suppression, :pre_send_blocked, :stop], ^ref,
                      %{duration_us: _}, meta}

      assert meta.tenant_id == "tenant-blocked"
      assert meta.scope == :address
      assert meta.reason == :manual
      assert meta.source == "ops"
      assert meta.expires_at? == false
      refute Map.has_key?(meta, :address)
      refute Map.has_key?(meta, :recipient)
      refute Map.has_key?(meta, :email)

      :telemetry.detach(ref)
    end

    test "emits [:mailglass, :suppression, :auto_added, :stop] with whitelist-safe metadata" do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:mailglass, :suppression, :auto_added, :stop]
        ])

      delivery = %Delivery{
        id: Ecto.UUID.generate(),
        tenant_id: "tenant-auto",
        recipient: "auto@example.com",
        stream: :bulk
      }

      event = %Event{
        id: Ecto.UUID.generate(),
        type: :unsubscribed,
        metadata: %{"provider" => "sendgrid", "provider_event_id" => "evt_123"}
      }

      assert {:ok, :inserted} =
               AutoSuppress.apply(AutoSuppressRepoStub, {:matched, delivery, event})

      assert_receive {[:mailglass, :suppression, :auto_added, :stop], ^ref, %{duration_us: _},
                      meta}

      assert meta.tenant_id == "tenant-auto"
      assert meta.scope == :address_stream
      assert meta.reason == :unsubscribe
      assert meta.source == "webhook:auto_suppress"
      assert meta.expires_at? == false
      refute Map.has_key?(meta, :address)
      refute Map.has_key?(meta, :recipient)
      refute Map.has_key?(meta, :email)

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
      assert Map.has_key?(ctx, :reason)
      assert Map.has_key?(ctx, :source)
      assert Map.has_key?(ctx, :expires_at)

      # Must NOT contain PII
      refute Map.has_key?(ctx, :to)
      refute Map.has_key?(ctx, :from)
      refute Map.has_key?(ctx, :email)
      refute Map.has_key?(ctx, :recipient)
      refute Map.has_key?(ctx, :address)
    end
  end

  describe "remove/2" do
    test "rejects complaint removal with a structured rejection error" do
      entry =
        insert_entry(%{
          tenant_id: "tenant-remove",
          address: "complaint@example.com",
          scope: :address,
          reason: :complaint,
          source: "webhook:auto_suppress"
        })

      assert {:error, %Mailglass.SendError{type: :preflight_rejected, context: context}} =
               Suppression.remove(entry.id, tenant_id: entry.tenant_id)

      assert context.reason == :complaint
      assert context.tenant_id == "tenant-remove"
      assert context.removable == false
      assert TestRepo.get(Entry, entry.id)
    end

    test "rejects unsubscribe removal with a structured rejection error" do
      entry =
        insert_entry(%{
          tenant_id: "tenant-remove",
          address: "unsubscribe@example.com",
          scope: :address_stream,
          stream: :bulk,
          reason: :unsubscribe,
          source: "webhook:auto_suppress"
        })

      assert {:error, %Mailglass.SendError{type: :preflight_rejected, context: context}} =
               Suppression.remove(entry.id, tenant_id: entry.tenant_id)

      assert context.reason == :unsubscribe
      assert context.removable == false
      assert TestRepo.get(Entry, entry.id)
    end

    test "deletes removable reasons" do
      for reason <- [:hard_bounce, :manual, :policy] do
        entry =
          insert_entry(%{
            tenant_id: "tenant-remove",
            address: "#{reason}@example.com",
            scope: :address,
            reason: reason,
            source: "ops"
          })

        entry_id = entry.id
        assert {:ok, %Entry{id: ^entry_id}} = Suppression.remove(entry_id, tenant_id: entry.tenant_id)
        refute TestRepo.get(Entry, entry_id)
      end
    end
  end

  defp insert_entry(attrs) do
    attrs
    |> Entry.changeset()
    |> TestRepo.insert!()
  end
end
