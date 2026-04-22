defmodule Mailglass.EventsTest do
  use Mailglass.DataCase, async: true

  alias Mailglass.Events
  alias Mailglass.Events.Event
  alias Mailglass.TestRepo

  describe "append/1" do
    test "inserts an event and returns {:ok, %Event{}}" do
      assert {:ok, %Event{id: id, type: :queued, tenant_id: "test-tenant"}} =
               Events.append(%{type: :queued, occurred_at: DateTime.utc_now()})

      assert is_binary(id)
    end

    test "auto-stamps tenant_id from Mailglass.Tenancy.current/0 when absent" do
      Mailglass.Tenancy.put_current("auto-stamped")

      assert {:ok, %Event{tenant_id: "auto-stamped"}} =
               Events.append(%{type: :queued, occurred_at: DateTime.utc_now()})
    end

    test "accepts explicit tenant_id that overrides the current stamp" do
      Mailglass.Tenancy.put_current("process-tenant")

      assert {:ok, %Event{tenant_id: "explicit-tenant"}} =
               Events.append(%{
                 type: :queued,
                 tenant_id: "explicit-tenant",
                 occurred_at: DateTime.utc_now()
               })
    end

    test "auto-stamps occurred_at when absent" do
      assert {:ok, %Event{occurred_at: ts}} = Events.append(%{type: :queued})
      assert %DateTime{} = ts
    end

    test "idempotency replay: same key returns the ORIGINAL row, not id: nil" do
      key = "postmark:webhook:unique-abc-123"

      {:ok, first} = Events.append(%{type: :delivered, idempotency_key: key})
      {:ok, second} = Events.append(%{type: :delivered, idempotency_key: key})

      # Replay returns the existing row (not {:ok, %Event{id: nil}} footgun).
      assert first.id == second.id
      refute is_nil(second.id)

      # Assert only one row exists.
      assert [_only_one] =
               TestRepo.all(
                 from(e in Event, where: e.idempotency_key == ^key)
               )
    end

    test "different idempotency_keys produce distinct rows" do
      {:ok, a} = Events.append(%{type: :queued, idempotency_key: "key-a"})
      {:ok, b} = Events.append(%{type: :queued, idempotency_key: "key-b"})
      assert a.id != b.id
    end

    test "no idempotency_key → always a fresh insert" do
      {:ok, a} = Events.append(%{type: :queued})
      {:ok, b} = Events.append(%{type: :queued})
      assert a.id != b.id
    end

    test "invalid attrs return {:error, changeset}" do
      assert {:error, %Ecto.Changeset{valid?: false}} =
               Events.append(%{type: :teleported, occurred_at: DateTime.utc_now()})
    end
  end

  describe "append/1 — telemetry" do
    test "emits :start + :stop span on successful insert" do
      handler = self()
      ref = make_ref()

      :telemetry.attach_many(
        "events-append-test-#{inspect(ref)}",
        [
          [:mailglass, :events, :append, :start],
          [:mailglass, :events, :append, :stop]
        ],
        fn event, meas, meta, _cfg ->
          send(handler, {ref, event, meas, meta})
        end,
        nil
      )

      {:ok, _} = Events.append(%{type: :queued, idempotency_key: "tele-key-1"})

      assert_receive {^ref, [:mailglass, :events, :append, :start], _,
                      %{tenant_id: _, idempotency_key_present?: true}},
                     500

      assert_receive {^ref, [:mailglass, :events, :append, :stop], _,
                      %{tenant_id: _, idempotency_key_present?: true} = meta},
                     500

      # T3 mitigation — metadata must never leak PII
      refute Map.has_key?(meta, :recipient)
      refute Map.has_key?(meta, :email)
      refute Map.has_key?(meta, :to)
      refute Map.has_key?(meta, :subject)
      refute Map.has_key?(meta, :body)
      refute Map.has_key?(meta, :html_body)
      refute Map.has_key?(meta, :headers)
      refute Map.has_key?(meta, :from)

      :telemetry.detach("events-append-test-#{inspect(ref)}")
    end

    test "emits metadata with idempotency_key_present?: false for keyless inserts" do
      handler = self()
      ref = make_ref()

      :telemetry.attach(
        "events-append-noid-#{inspect(ref)}",
        [:mailglass, :events, :append, :stop],
        fn _, _, meta, _ -> send(handler, {ref, meta}) end,
        nil
      )

      {:ok, _} = Events.append(%{type: :queued})

      assert_receive {^ref, %{idempotency_key_present?: false}}, 500
      :telemetry.detach("events-append-noid-#{inspect(ref)}")
    end
  end

  describe "append_multi/3" do
    test "appends an insert step to an Ecto.Multi" do
      multi =
        Ecto.Multi.new()
        |> Events.append_multi(:my_event, %{
          type: :queued,
          tenant_id: "test-tenant",
          occurred_at: DateTime.utc_now()
        })

      # Happy-path only — Multi error paths (4-tuple {:error, name, reason, changes})
      # are exercised in Plan 06 integration test via a normalized-return wrapper.
      {:ok, %{my_event: event}} = TestRepo.transaction(multi)

      assert %Event{type: :queued} = event
    end

    test "supports caller-observed replay via Multi.run step" do
      key = "multi-idem-key-1"

      run_once = fn ->
        Ecto.Multi.new()
        |> Events.append_multi(:event, %{
          type: :delivered,
          tenant_id: "test-tenant",
          occurred_at: DateTime.utc_now(),
          idempotency_key: key
        })
        |> TestRepo.transaction()
      end

      {:ok, %{event: first}} = run_once.()
      {:ok, %{event: second}} = run_once.()

      # On replay, Ecto returns a struct whose DB-defaulted columns
      # (inserted_at) are nil — the row was skipped by ON CONFLICT DO
      # NOTHING and RETURNING yielded nothing. The id field IS
      # populated (UUIDv7 autogenerate is client-side), so the
      # replay-detection sentinel for UUIDv7 schemas is inserted_at,
      # not id. See moduledoc "The replay-detection sentinel" in
      # Mailglass.Events.
      refute is_nil(first.inserted_at)
      assert is_nil(second.inserted_at)

      # Only one row persisted.
      assert [_only_one] =
               TestRepo.all(from(e in Event, where: e.idempotency_key == ^key))
    end

    test "Multi.run can detect replay and fetch the canonical row" do
      key = "multi-replay-detected"

      multi_with_observer =
        Ecto.Multi.new()
        |> Events.append_multi(:event, %{
          type: :delivered,
          tenant_id: "test-tenant",
          occurred_at: DateTime.utc_now(),
          idempotency_key: key
        })
        |> Ecto.Multi.run(:replay_status, fn _repo, %{event: e} ->
          if is_nil(e.inserted_at), do: {:ok, :replay}, else: {:ok, :insert}
        end)

      {:ok, result_first} = TestRepo.transaction(multi_with_observer)
      {:ok, result_second} = TestRepo.transaction(multi_with_observer)

      assert result_first.replay_status == :insert
      assert result_second.replay_status == :replay
    end
  end
end
